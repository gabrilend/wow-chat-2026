
#include "buddies.h"
#include "buddies_follow.h"
#include "buddies_navmesh.h"
#include "buddies_roam.h"
#include "buddies_town.h"
#include "roam/buddy_follow_core.h"
#include "Chat.h"
#include "CommandScript.h"
#include "Config.h"
#include "GameTime.h"
#include "Log.h"
#include "Map.h"
#include "MovementActions.h"
#include "NonCombatStrategy.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Playerbots.h"
#include "PlayerbotAI.h"
#include "ScriptMgr.h"
#include <algorithm>
#include <cmath>
#include <mutex>
#include <set>
#include <unordered_map>

static constexpr float  FOLLOW_RELEVANCE = 3.0f;
static constexpr uint32 TRACK_EVERY_MS   = 250;
static constexpr float  SNAP_YARDS       = 2.0f;
static constexpr float  SNAP_RISE        = 4.0f;
static constexpr float  FACE_TURN        = 0.3f;

enum class RestActivity : uint8 { Wander, Chat, Look, Gesture, Sit };
struct RestWeight { RestActivity what; uint32 weight; };
static constexpr RestWeight REST_WEIGHTS[] = {
    { RestActivity::Wander,  4 },
    { RestActivity::Chat,    3 },
    { RestActivity::Look,    2 },
    { RestActivity::Gesture, 2 },
    { RestActivity::Sit,     1 },
};
static constexpr float  CHAT_YARDS = 6.0f;
static constexpr uint32 REST_GESTURES[] = { EMOTE_ONESHOT_LAUGH, EMOTE_ONESHOT_POINT, EMOTE_ONESHOT_CHEER, EMOTE_ONESHOT_BOW };

static RestActivity DrawRestActivity()
{
    uint32 total = 0;
    for (RestWeight const& w : REST_WEIGHTS)
        total += w.weight;
    uint32 pick = urand(1, total);
    for (RestWeight const& w : REST_WEIGHTS)
    {
        if (pick <= w.weight)
            return w.what;
        pick -= w.weight;
    }
    return RestActivity::Wander;
}
static BuddyFollow::Settings const SETTINGS;

struct OwnerTrack
{
    uint32             mapId = 0;
    BuddyFollow::Trail trail;
};
static std::mutex                                      sFollowLock;
static std::unordered_map<uint32, OwnerTrack>          sTrack;
static std::unordered_map<uint32, BuddyFollow::State>  sState;
static std::unordered_map<uint32, uint32>              sLeader;
static std::unordered_map<uint32, std::set<uint32>>    sRefused;
static std::set<uint32>                                 sRing;
static std::unordered_map<uint32, float>                sRingYards;
static std::unordered_map<uint32, bool>                 sLeaderInside;

void BuddyFollowSet(uint32_t buddy, uint32_t leader)
{
    std::lock_guard<std::mutex> lock(sFollowLock);
    sLeader[buddy] = leader;
    sState.erase(buddy);
}
void BuddyFollowStop(uint32_t buddy)
{
    std::lock_guard<std::mutex> lock(sFollowLock);
    sLeader.erase(buddy);
    sState.erase(buddy);
    sRing.erase(buddy);
}
void BuddyFollowSetRing(uint32_t buddy, bool ring)
{
    std::lock_guard<std::mutex> lock(sFollowLock);
    if (ring) sRing.insert(buddy); else sRing.erase(buddy);
}
bool BuddyFollowRing(uint32_t buddy)
{
    std::lock_guard<std::mutex> lock(sFollowLock);
    return sRing.count(buddy) > 0;
}
float BuddyFollowRingYards(uint32_t leader)
{
    std::lock_guard<std::mutex> lock(sFollowLock);
    auto it = sRingYards.find(leader);
    return it == sRingYards.end() ? SETTINGS.ringYards : it->second;
}
void BuddyFollowRefuse(uint32_t buddy, uint32_t leader)
{
    std::lock_guard<std::mutex> lock(sFollowLock);
    sRefused[buddy].insert(leader);
}
bool BuddyFollowRefused(uint32_t buddy, uint32_t leader)
{
    std::lock_guard<std::mutex> lock(sFollowLock);
    auto it = sRefused.find(buddy);
    return it != sRefused.end() && it->second.count(leader);
}
uint32_t BuddyFollowLeader(uint32_t buddy)
{
    std::lock_guard<std::mutex> lock(sFollowLock);
    auto it = sLeader.find(buddy);
    return it == sLeader.end() ? 0 : it->second;
}

static constexpr size_t TRACK_AHEAD = 3;
bool BuddyFollowTrackAhead(uint32_t player, float x, float y, float& outX, float& outY, float& outZ)
{
    std::lock_guard<std::mutex> lock(sFollowLock);
    auto it = sTrack.find(player);
    if (it == sTrack.end() || it->second.trail.points.empty())
        return false;
    auto const& pts = it->second.trail.points;
    size_t nearest = 0;
    float best = 1e30f;
    for (size_t k = 0; k < pts.size(); ++k)
    {
        float d = std::hypot(pts[k].x - x, pts[k].y - y);
        if (d < best)
        {
            best = d;
            nearest = k;
        }
    }
    BuddyRoam::Point const& p = pts[std::min(nearest + TRACK_AHEAD, pts.size() - 1)];
    outX = p.x;
    outY = p.y;
    outZ = p.z;
    return true;
}

static Player* LeaderOf(Player* bot, PlayerbotAI* ai)
{
    if (uint32 told = BuddyFollowLeader(bot->GetGUID().GetCounter()))
        return ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(told));
    return ai->GetMaster();
}

class BuddyFollowStepAction : public MovementAction
{
public:
    BuddyFollowStepAction(PlayerbotAI* botAI) : MovementAction(botAI, "buddy follow step") { }

    bool isUseful() override
    {
        Player* owner = LeaderOf(bot, botAI);
        if (!owner || !owner->IsInWorld() || owner->GetMapId() != bot->GetMapId() || owner->IsInFlight())
            return false;
        return bot->IsAlive() && owner->IsAlive() && !bot->IsInCombat();
    }

    bool Execute(Event ) override
    {
        Player* owner = LeaderOf(bot, botAI);
        if (!owner)
            return false;
        uint32 me = bot->GetGUID().GetCounter();

        std::vector<Player*> followers;
        for (auto const& [buddyGuid, ownerGuid] : BuddyRosterPairs())
        {
            Player* b = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(buddyGuid));
            if (!b || !b->IsInWorld() || b->GetMapId() != owner->GetMapId() || !b->IsAlive())
                continue;
            PlayerbotAI* ai = GET_PLAYERBOT_AI(b);
            if (!ai || !ai->HasStrategy("buddy follow", BOT_STATE_NON_COMBAT) || LeaderOf(b, ai) != owner)
                continue;
            followers.push_back(b);
        }
        std::sort(followers.begin(), followers.end(), [](Player* a, Player* b) { return a->GetGUID() < b->GetGUID(); });
        auto mine = std::find(followers.begin(), followers.end(), bot);
        if (mine == followers.end())
            return false;

        BuddyRoam::Point ownerAt{ owner->GetPositionX(), owner->GetPositionY(), owner->GetPositionZ() };
        BuddyFollow::Trail trail;
        {
            std::lock_guard<std::mutex> lock(sFollowLock);
            auto it = sTrack.find(owner->GetGUID().GetCounter());
            if (it != sTrack.end() && it->second.mapId == owner->GetMapId())
                trail = it->second.trail;
        }
        bool ring = BuddyFollowRing(me) || (owner->IsInCombat() && sConfigMgr->GetOption<int32>("Buddies.CloseFollow.InCombat", 0) == 1);
        if (ring)
        {
            std::vector<BuddyRoam::Point> at;
            int tank = -1;
            for (size_t i = 0; i < followers.size(); ++i)
            {
                at.push_back({ followers[i]->GetPositionX(), followers[i]->GetPositionY(), followers[i]->GetPositionZ() });
                if (tank < 0 && botAI->IsTank(followers[i]))
                    tank = int(i);
            }
            std::vector<BuddyFollow::Place> places = BuddyFollow::RingPlaces(ownerAt, owner->GetOrientation(), int(followers.size()),
                                                                                    BuddyFollowRingYards(owner->GetGUID().GetCounter()));
            std::vector<int> spotOf = BuddyFollow::AssignRing(at, places, tank);
            int spot = spotOf[size_t(mine - followers.begin())];
            if (spot < 0)
                return false;
            BuddyFollow::Place place = places[size_t(spot)];
            BuddyRoam::Point meAt = at[size_t(mine - followers.begin())];
            float off = std::sqrt((meAt.x - place.at.x) * (meAt.x - place.at.x) + (meAt.y - place.at.y) * (meAt.y - place.at.y));
            if (off > SETTINGS.ringSlack)
            {
                bool walk = owner->IsWalking();
                if (bot->IsWalking() != walk)
                    bot->SetWalk(walk);
                BuddyRoam::Point onMesh;
                if (!BuddyMeshSnap(bot->GetMap(), place.at, SNAP_YARDS, SNAP_RISE, onMesh))
                    onMesh = ownerAt;
                return MoveTo(bot->GetMapId(), onMesh.x, onMesh.y, onMesh.z);
            }
            float face = std::atan2(ownerAt.y - meAt.y, ownerAt.x - meAt.x);
            float turn = std::fabs(Position::NormalizeOrientation(face - bot->GetOrientation()));
            if (turn > FACE_TURN && turn < 2.0f * float(M_PI) - FACE_TURN)
                bot->SetFacingTo(face);
            return true;
        }

        BuddyFollow::Place middle = BuddyFollow::PlaceFor(trail, ownerAt, owner->GetOrientation(), 0.0f, SETTINGS);
        float wall = 0.0f;
        bool narrow = BuddyMeshWallDistance(bot->GetMap(), middle.at, SETTINGS.narrowYards * 2.0f, wall) && wall < SETTINGS.narrowYards;
        std::vector<BuddyFollow::Place> places = narrow
            ? BuddyFollow::ColumnPlaces(trail, ownerAt, owner->GetOrientation(), int(followers.size()), SETTINGS)
            : BuddyFollow::Places(trail, ownerAt, owner->GetOrientation(), int(followers.size()), SETTINGS);
        std::vector<BuddyRoam::Point> at;
        for (Player* f : followers)
            at.push_back({ f->GetPositionX(), f->GetPositionY(), f->GetPositionZ() });
        std::vector<int> spotOf = BuddyFollow::Assign(at, places);
        int spot = spotOf[size_t(mine - followers.begin())];
        if (spot < 0)
            return false;
        BuddyFollow::Place place = places[size_t(spot)];

        BuddyFollow::Decision d;
        {
            std::lock_guard<std::mutex> lock(sFollowLock);
            d = BuddyFollow::Decide(sState[me], at[size_t(mine - followers.begin())], ownerAt, place,
                                    uint64(GameTime::GetGameTimeMS().count()), rand_norm(), rand_norm(), SETTINGS);
        }

        if (d.act == BuddyFollow::Act::Mingle)
        {
            RestActivity what = DrawRestActivity();
            Player* mate = nullptr;
            if (what == RestActivity::Chat)
            {
                float best = CHAT_YARDS;
                for (Player* f : followers)
                    if (f != bot && bot->GetExactDist(f) <= best)
                    {
                        mate = f;
                        best = bot->GetExactDist(f);
                    }
                if (!mate)
                    what = RestActivity::Look;
            }
            switch (what)
            {
                case RestActivity::Wander:
                    break;
                case RestActivity::Chat:
                    bot->SetFacingToObject(mate);
                    bot->HandleEmoteCommand(EMOTE_ONESHOT_TALK);
                    return true;
                case RestActivity::Look:
                    bot->SetFacingTo(float(rand_norm() * 2.0 * M_PI));
                    return true;
                case RestActivity::Gesture:
                    bot->HandleEmoteCommand(REST_GESTURES[urand(0, std::size(REST_GESTURES) - 1)]);
                    return true;
                case RestActivity::Sit:
                    bot->SetStandState(UNIT_STAND_STATE_SIT);
                    return true;
            }
        }

        switch (d.act)
        {
            case BuddyFollow::Act::Walk:
            case BuddyFollow::Act::Mingle:
            {
                bool walk = d.act == BuddyFollow::Act::Mingle || owner->IsWalking();
                if (bot->IsWalking() != walk)
                    bot->SetWalk(walk);
                BuddyRoam::Point onMesh;
                if (!BuddyMeshSnap(bot->GetMap(), d.to, SNAP_YARDS, SNAP_RISE, onMesh))
                {
                    if (d.act == BuddyFollow::Act::Mingle)
                        return false;
                    BuddyFollow::Place onTrack = BuddyFollow::PlaceFor(trail, ownerAt, owner->GetOrientation(), 0.0f, SETTINGS);
                    if (!BuddyMeshSnap(bot->GetMap(), onTrack.at, SNAP_YARDS, SNAP_RISE, onMesh))
                        onMesh = ownerAt;
                }
                return MoveTo(bot->GetMapId(), onMesh.x, onMesh.y, onMesh.z);
            }
            case BuddyFollow::Act::Face:
            {
                float turn = std::fabs(Position::NormalizeOrientation(d.facing - bot->GetOrientation()));
                if (turn > FACE_TURN && turn < 2.0f * float(M_PI) - FACE_TURN)
                    bot->SetFacingTo(d.facing);
                return true;
            }
            case BuddyFollow::Act::Nothing:
                return true;
        }
        return false;
    }
};

class BuddyFollowDueTrigger : public Trigger
{
public:
    BuddyFollowDueTrigger(PlayerbotAI* botAI) : Trigger(botAI, "buddy follow due") { }
    bool IsActive() override { return true; }
};

class BuddyFollowStrategy : public NonCombatStrategy
{
public:
    BuddyFollowStrategy(PlayerbotAI* botAI) : NonCombatStrategy(botAI) { }
    std::string const getName() override { return "buddy follow"; }
    void InitTriggers(std::vector<TriggerNode*>& triggers) override
    {
        triggers.push_back(new TriggerNode("buddy follow due", { NextAction("buddy follow step", FOLLOW_RELEVANCE) }));
    }
};

Strategy* NewBuddyFollowStrategy(PlayerbotAI* ai)   { return new BuddyFollowStrategy(ai); }
Trigger*  NewBuddyFollowDueTrigger(PlayerbotAI* ai) { return new BuddyFollowDueTrigger(ai); }
Action*   NewBuddyFollowStepAction(PlayerbotAI* ai) { return new BuddyFollowStepAction(ai); }

class buddies_follow_world : public WorldScript
{
public:
    buddies_follow_world() : WorldScript("buddies_follow_world", { WORLDHOOK_ON_UPDATE }) { }

    void OnUpdate(uint32 diff) override
    {
        _since += diff;
        if (_since < TRACK_EVERY_MS)
            return;
        _since = 0;
        std::unordered_map<uint32, OwnerTrack> seen;
        for (auto const& [buddyGuid, ownerGuid] : BuddyRosterPairs())
        {
            if (seen.count(ownerGuid))
                continue;
            Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(ownerGuid));
            if (!owner || !owner->IsInWorld())
                continue;
            seen[ownerGuid].mapId = owner->GetMapId();
        }
        {
            std::vector<uint32> leaders;
            {
                std::lock_guard<std::mutex> lock(sFollowLock);
                for (auto const& [buddy, leader] : sLeader)
                    leaders.push_back(leader);
            }
            for (uint32 leaderGuid : leaders)
                if (!seen.count(leaderGuid))
                    if (Player* leader = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(leaderGuid)))
                        if (leader->IsInWorld())
                            seen[leaderGuid].mapId = leader->GetMapId();
        }
        std::lock_guard<std::mutex> lock(sFollowLock);
        for (auto it = sTrack.begin(); it != sTrack.end();)
            it = seen.count(it->first) ? std::next(it) : sTrack.erase(it);
        auto online = [](uint32 guid) { return ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid)) != nullptr; };
        std::set<uint32> steppedIn;
        for (auto const& [buddy, leaderGuid] : sLeader)
        {
            Player* leader = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(leaderGuid));
            if (!leader || !leader->IsInWorld())
                continue;
            bool inside = leader->GetMap()->Instanceable() || BuddyTownArea(leader) != 0;
            auto was = sLeaderInside.find(leaderGuid);
            if (inside && was != sLeaderInside.end() && !was->second)
                steppedIn.insert(leaderGuid);
            sLeaderInside[leaderGuid] = inside;
        }
        for (auto it = sLeader.begin(); it != sLeader.end();)
        {
            if (!online(it->second))
                it = sLeader.erase(it);
            else if (steppedIn.count(it->second))
            {
                LOG_INFO("module", "mod-buddies: buddy {} stops following player {}: they stepped into a town or a dungeon",
                    it->first, it->second);
                sRing.erase(it->first);
                sState.erase(it->first);
                it = sLeader.erase(it);
            }
            else
                it = std::next(it);
        }
        for (auto it = sLeaderInside.begin(); it != sLeaderInside.end();)
        {
            bool stillLeads = false;
            for (auto const& [buddy, leaderGuid] : sLeader)
                stillLeads = stillLeads || leaderGuid == it->first;
            it = stillLeads ? std::next(it) : sLeaderInside.erase(it);
        }
        for (auto& [buddy, refused] : sRefused)
            for (auto r = refused.begin(); r != refused.end();)
                r = online(*r) ? std::next(r) : refused.erase(r);
        for (auto const& [ownerGuid, fresh] : seen)
        {
            Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(ownerGuid));
            if (!owner)
                continue;
            OwnerTrack& t = sTrack[ownerGuid];
            if (t.mapId != fresh.mapId)
            {
                t.trail.points.clear();
                t.mapId = fresh.mapId;
            }
            t.trail.Add({ owner->GetPositionX(), owner->GetPositionY(), owner->GetPositionZ() }, SETTINGS);
        }
    }

private:
    uint32 _since = 0;
};

using namespace Acore::ChatCommands;

class buddies_ring_command : public CommandScript
{
public:
    buddies_ring_command() : CommandScript("buddies_ring_command") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "buddy wider",  HandleWider,  SEC_PLAYER, Console::No },
            { "buddy closer", HandleCloser, SEC_PLAYER, Console::No },
        };
        return commandTable;
    }

    static bool Set(ChatHandler* handler, bool wider)
    {
        uint32 me = handler->GetPlayer()->GetGUID().GetCounter();
        float yards = BuddyFollow::RingRadius(BuddyFollowRingYards(me), wider, SETTINGS);
        {
            std::lock_guard<std::mutex> lock(sFollowLock);
            sRingYards[me] = yards;
        }
        handler->PSendSysMessage("Your buddies' ring: {} yards round you (\"circle me\" to form it).", uint32(yards));
        return true;
    }
    static bool HandleWider(ChatHandler* handler)  { return Set(handler, true); }
    static bool HandleCloser(ChatHandler* handler) { return Set(handler, false); }
};

void AddSC_buddies_follow()
{
    new buddies_ring_command();
    new buddies_follow_world();
}
