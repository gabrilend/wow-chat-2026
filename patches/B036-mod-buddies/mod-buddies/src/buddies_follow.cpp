/*
 * buddies_follow.cpp - buddies follow their owner the owner's way: along
 * the owner's own track, side by side on a half circle behind, and at rest
 * until the owner walks off (issue 617e13; the design in
 * docs/pathfinding-questing-and-dungeons.md, "Following").
 *
 * For a general audience: the bot module's own "follow" puts every bot a
 * yard and a half behind its leader, each on its own straight line, so in
 * a dungeon's corridors buddies bunch up and cut the corners the owner
 * walked round. This file adds a behaviour of our own, "buddy follow", in
 * three parts:
 *   the track    - every quarter second, each owner's position is noted
 *                  (a point every 2 yards, the last 300 yards): the way the
 *                  owner came, which the owner's feet proved walkable;
 *   the places   - the following core (roam/buddy_follow_core.h) turns the
 *                  track and how many follow into one spot each, 1 to 2
 *                  yards back along the track and up to a yard to its
 *                  side, and shares the spots out so nobody crosses;
 *   the step     - each buddy, when the bot module runs the behaviour, asks
 *                  the core what to do: walk to its spot, rest facing the
 *                  owner, or mingle a little; it starts following again
 *                  only once the owner is more than 10 yards away.
 * Where it is on: in dungeons, raids and battlegrounds, in place of the bot
 * module's follow (the peace-time sets, buddies_roam_strategy.cpp). Its
 * spot is moved onto the navigation mesh before walking; a spot with no
 * mesh near (a wall beside a narrow passage) is replaced by the point of
 * the owner's own track it was measured from, which the owner stood on.
 */

#include "buddies.h"
#include "buddies_follow.h"
#include "buddies_navmesh.h"
#include "buddies_roam.h"
#include "roam/buddy_follow_core.h"
#include "GameTime.h"
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

// {{{ tuning
static constexpr float  FOLLOW_RELEVANCE = 3.0f;   // ranks with roaming (never both on at once), below fighting (4.0) and looting
static constexpr uint32 TRACK_EVERY_MS   = 250;    // how often each owner's position is noted
static constexpr float  SNAP_YARDS       = 2.0f;   // how far a spot may move sideways onto the mesh
static constexpr float  SNAP_RISE        = 4.0f;   // and up or down
static constexpr float  FACE_TURN        = 0.3f;   // radians: a smaller turn toward the owner isn't worth a turn
static BuddyFollow::Settings const SETTINGS;      // the owner's numbers (buddy_follow_core.h)
// }}}

// {{{ the tracks and the followers' states
// Written by the world update (the tracks) and by the bot module's threads
// (the states), so both behind one lock.
struct OwnerTrack
{
    uint32             mapId = 0;
    BuddyFollow::Trail trail;
};
static std::mutex                                      sFollowLock;
static std::unordered_map<uint32, OwnerTrack>          sTrack;   // owner guid -> track
static std::unordered_map<uint32, BuddyFollow::State>  sState;   // buddy guid -> rest or follow
static std::unordered_map<uint32, uint32>              sLeader;  // buddy guid -> the player it was told to follow
static std::unordered_map<uint32, std::set<uint32>>    sRefused; // buddy guid -> players it won't follow until they log out
// }}}

// {{{ the follow orders
void BuddyFollowSet(uint32_t buddy, uint32_t leader)
{
    std::lock_guard<std::mutex> lock(sFollowLock);
    sLeader[buddy] = leader;
    sState.erase(buddy);                               // a new follow: to its spot first
}
void BuddyFollowStop(uint32_t buddy)
{
    std::lock_guard<std::mutex> lock(sFollowLock);
    sLeader.erase(buddy);
    sState.erase(buddy);
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
// }}}

// {{{ BuddyFollowTrackAhead
// TRACK_AHEAD points on: 6 yards, far enough to pull the buddy along the
// track, near enough that the stretch between was walked by the player.
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
// }}}

// {{{ LeaderOf
// Whom a buddy follows: the player it was told to follow, else its owner
// (in a dungeon, where following is how a buddy goes about).
static Player* LeaderOf(Player* bot, PlayerbotAI* ai)
{
    if (uint32 told = BuddyFollowLeader(bot->GetGUID().GetCounter()))
        return ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(told));
    return ai->GetMaster();
}
// }}}

// {{{ BuddyFollowStepAction
class BuddyFollowStepAction : public MovementAction
{
public:
    BuddyFollowStepAction(PlayerbotAI* botAI) : MovementAction(botAI, "buddy follow step") { }

    // Worth a step when the owner is here (same map, in the world, alive,
    // not on a flight) and the buddy is alive and not fighting: a fight is
    // the bot module's, and the step comes back after it.
    bool isUseful() override
    {
        Player* owner = LeaderOf(bot, botAI);
        if (!owner || !owner->IsInWorld() || owner->GetMapId() != bot->GetMapId() || owner->IsInFlight())
            return false;
        return bot->IsAlive() && owner->IsAlive() && !bot->IsInCombat();
    }

    bool Execute(Event /*event*/) override
    {
        // "owner" below is whom this buddy follows: its owner, or the
        // player it was told to follow
        Player* owner = LeaderOf(bot, botAI);
        if (!owner)
            return false;
        uint32 me = bot->GetGUID().GetCounter();

        // who follows this leader here (any owner's buddies: a "follow me"
        // may gather several clans), in a fixed order (the guid), so every
        // follower works out the same sharing of the spots
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
            return false;                                // not listed (logged in this moment): next step

        BuddyRoam::Point ownerAt{ owner->GetPositionX(), owner->GetPositionY(), owner->GetPositionZ() };
        BuddyFollow::Trail trail;
        {
            std::lock_guard<std::mutex> lock(sFollowLock);
            auto it = sTrack.find(owner->GetGUID().GetCounter());
            if (it != sTrack.end() && it->second.mapId == owner->GetMapId())
                trail = it->second.trail;
        }
        // side by side, or single file where the way is narrower than the
        // formation (measured on the track where the formation's middle
        // stands; off the mesh there, or no mesh: side by side)
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
            return false;                                // more followers than spots: cannot happen (one spot each)
        BuddyFollow::Place place = places[size_t(spot)];

        BuddyFollow::Decision d;
        {
            std::lock_guard<std::mutex> lock(sFollowLock);
            d = BuddyFollow::Decide(sState[me], at[size_t(mine - followers.begin())], ownerAt, place,
                                    uint64(GameTime::GetGameTimeMS().count()), rand_norm(), rand_norm(), SETTINGS);
        }

        // each answer, and what it does:
        //   Walk    - to the spot, at the owner's pace (walking if the owner walks)
        //   Mingle  - a short walk near the spot, at a walk
        //   Face    - turn toward the owner, if the turn is worth making
        //   Nothing - no new order: whatever it does goes on
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
                        return false;                    // nowhere to wander there: stays put
                    // no mesh near the spot: the track point it was measured
                    // from (the spot less its sideways offset), which the
                    // owner stood on; failing that, the owner's own spot
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
// }}}

// {{{ the trigger and the strategy
// Always due: whether a step is worth taking is the action's own judgement
// (isUseful), which the bot module asks before running it.
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
// }}}

// {{{ the makers
Strategy* NewBuddyFollowStrategy(PlayerbotAI* ai)   { return new BuddyFollowStrategy(ai); }
Trigger*  NewBuddyFollowDueTrigger(PlayerbotAI* ai) { return new BuddyFollowDueTrigger(ai); }
Action*   NewBuddyFollowStepAction(PlayerbotAI* ai) { return new BuddyFollowStepAction(ai); }
// }}}

// {{{ the tracks: noted every TRACK_EVERY_MS
// Each owner with buddies, and each player a buddy was told to follow,
// online and in the world: its position added to
// its track (the trail keeps a point only every 2 yards, and starts again
// after a jump). A change of map starts a new track. Owners gone offline
// have their tracks dropped.
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
        // a leader logged out: its follows end, and the refusals of it with
        // them ("won't follow that person until they log out again")
        auto online = [](uint32 guid) { return ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid)) != nullptr; };
        for (auto it = sLeader.begin(); it != sLeader.end();)
            it = online(it->second) ? std::next(it) : sLeader.erase(it);
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
// }}}

// {{{ AddSC_buddies_follow
void AddSC_buddies_follow()
{
    new buddies_follow_world();
}
// }}}
