
#include "buddies.h"
#include "buddies_steer.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Log.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Playerbots.h"
#include "PlayerbotAI.h"
#include "PlayerbotMgr.h"
#include "PlayerbotsDatabase.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "WorldSession.h"
#include <cmath>
#include <map>

static constexpr uint32 OWNER_SETTLE_MS  = 3000;
static constexpr uint32 BUDDY_SETTLE_MS  = 1000;
static constexpr uint32 PASS_EVERY_MS    = 500;
static constexpr uint32 OWNER_TRIES      = 20;
static constexpr float  PLACE_MIN_YARDS  = 20.0f;
static constexpr float  PLACE_MAX_YARDS  = 30.0f;
static constexpr int    PLACE_TRIES      = 6;
static constexpr uint32 KEEP_STEP_MIN_MS = 1000;
static constexpr uint32 KEEP_STEP_MAX_MS = 3000;
static constexpr uint32 KEEP_WATCH_MS    = 5000;

struct BuddyWait { uint64 dueMs; uint32 tries; };
static std::map<uint32, BuddyWait> sOwnersDue;
static std::map<uint32, BuddyWait> sBuddiesDue;
static std::map<uint32, uint64>    sKeepers;

void BuddyQueueLogin(uint32 ownerGuid)
{
    sOwnersDue[ownerGuid] = { uint64(GameTime::GetGameTimeMS().count()) + OWNER_SETTLE_MS, 0 };
}

static bool LogInBuddies(uint32 ownerGuid)
{
    Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(ownerGuid));
    if (!owner)
        return true;
    if (!owner->IsInWorld())
        return false;
    PlayerbotMgr* mgr = GET_PLAYERBOT_MGR(owner);
    if (!mgr)
        return false;
    uint32 companion = BuddyCompanionAccountId(ownerGuid);
    if (!companion)
        return false;
    uint32 ownerAccount = owner->GetSession()->GetAccountId();

    PlayerbotsDatabase.DirectExecute("INSERT IGNORE INTO playerbots_account_links (account_id, linked_account_id) VALUES ({}, {})",
        companion, ownerAccount);

    sKeepers[ownerGuid] = 0;
    return true;
}

static void KeepBuddies(uint64 now)
{
    for (auto it = sKeepers.begin(); it != sKeepers.end(); )
    {
        if (it->second > now) { ++it; continue; }
        Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(it->first));
        if (!owner)
        {
            it = sKeepers.erase(it);
            continue;
        }
        PlayerbotMgr* mgr = owner->IsInWorld() ? GET_PLAYERBOT_MGR(owner) : nullptr;
        if (!mgr)
        {
            it->second = now + KEEP_STEP_MIN_MS;
            ++it;
            continue;
        }
        uint32 missing = 0;
        QueryResult buddies = CharacterDatabase.Query("SELECT buddy FROM buddy_roster WHERE owner = {} AND buddy <> 0 AND stage IN (0, 3)", it->first);
        if (buddies)
            do
            {
                ObjectGuid buddy = ObjectGuid::Create<HighGuid::Player>((*buddies)[0].Get<uint32>());
                if (ObjectAccessor::FindConnectedPlayer(buddy))
                    continue;
                if (!missing++)
                {
                    LOG_INFO("module", "mod-buddies: {}'s buddy {} is not online; logging it in", owner->GetName(), buddy.GetCounter());
                    mgr->AddPlayerBot(buddy, owner->GetSession()->GetAccountId());
                }
            } while (buddies->NextRow());
        it->second = now + (missing > 0 ? urand(KEEP_STEP_MIN_MS, KEEP_STEP_MAX_MS) : KEEP_WATCH_MS);
        ++it;
    }
}

static constexpr uint32 SARGOBRAS_VALLEY      = 6170001;
static constexpr uint32 SARGOBRAS_WANDERER    = 6170002;
static constexpr float  ENTRANCE_NEAR_YARDS   = 50.0f;
static constexpr float  ENTRANCE_BEHIND_YARDS = 4.5f;
static constexpr float  ENTRANCE_SIDE_YARDS   = 2.0f;
static constexpr float  ENTRANCE_STEP_YARDS   = 2.5f;
static constexpr uint32 ENTRANCE_ARRIVE_MS    = 1500;
static constexpr uint32 ENTRANCE_WALK_MS      = 1500;
static constexpr uint32 ENTRANCE_GIVE_UP_MS   = 10000;
static constexpr uint32 HANG_TICK_MS          = 250;
static constexpr uint32 GESTURE_PAUSE_MIN_MS  = 3000;
static constexpr uint32 GESTURE_PAUSE_MAX_MS  = 4000;

enum class Greeting : uint8 { None = 0, Wave = 1, Salute = 2, Bow = 3, Flex = 4, Nod = 5 };
static uint32 const GESTURE_EMOTE[] = { 0, EMOTE_ONESHOT_WAVE, EMOTE_ONESHOT_SALUTE, EMOTE_ONESHOT_BOW,
                                        EMOTE_ONESHOT_FLEX, EMOTE_ONESHOT_YES };

struct Entrance
{
    uint64   startMs, dueMs;
    uint8    stage;
    float    x, y, z;
    Greeting greeting;
    uint32   owner;
    float    ox, oy, oz;
};
static std::map<uint32, Entrance> sEntrances;

static bool BeginEntrance(Player* buddy, Player* owner, uint32 buddyGuid)
{
    QueryResult row = CharacterDatabase.Query("SELECT greeting FROM buddy_roster WHERE buddy = {}", buddyGuid);
    if (!row || (*row)[0].Get<uint8>() != uint8(Greeting::None))
        return false;

    Creature* s = owner->FindNearestCreature(SARGOBRAS_VALLEY, ENTRANCE_NEAR_YARDS);
    Creature* w = owner->FindNearestCreature(SARGOBRAS_WANDERER, ENTRANCE_NEAR_YARDS);
    if (!s || (w && owner->GetExactDist(w) < owner->GetExactDist(s)))
        s = w;
    if (!s)
        return false;

    float o    = s->GetOrientation();
    float side = urand(0, 1) ? 1.0f : -1.0f;
    float x    = s->GetPositionX() - std::cos(o) * ENTRANCE_BEHIND_YARDS + std::cos(o + side * float(M_PI) / 2.0f) * ENTRANCE_SIDE_YARDS;
    float y    = s->GetPositionY() - std::sin(o) * ENTRANCE_BEHIND_YARDS + std::sin(o + side * float(M_PI) / 2.0f) * ENTRANCE_SIDE_YARDS;
    float z    = s->GetMap()->GetHeight(s->GetPhaseMask(), x, y, s->GetPositionZ() + 5.0f, true, 20.0f);
    if (z <= INVALID_HEIGHT)
    {
        LOG_WARN("module", "mod-buddies: no ground behind Sargobras (guid {}) for buddy {}'s entrance; placed the ordinary way (617b1)",
            s->GetSpawnId(), buddy->GetName());
        return false;
    }

    float ox = owner->GetPositionX(), oy = owner->GetPositionY(), oz = owner->GetPositionZ();
    buddy->TeleportTo(s->GetMapId(), x, y, z + 0.5f, std::atan2(oy - y, ox - x));
    if (PlayerbotAI* ai = GET_PLAYERBOT_AI(buddy))
        ai->SetNextCheckDelay(ENTRANCE_ARRIVE_MS + ENTRANCE_WALK_MS + HANG_TICK_MS * 2);
    uint64 now = uint64(GameTime::GetGameTimeMS().count());
    sEntrances[buddyGuid] = { now, now + ENTRANCE_ARRIVE_MS, 1,
        x + std::cos(o) * ENTRANCE_STEP_YARDS, y + std::sin(o) * ENTRANCE_STEP_YARDS, z,
        Greeting(urand(uint32(Greeting::Wave), uint32(Greeting::Nod))),
        owner->GetGUID().GetCounter(), ox, oy, oz };
    return true;
}

static void StepEntrances(uint64 now)
{
    for (auto it = sEntrances.begin(); it != sEntrances.end(); )
    {
        Entrance& e = it->second;
        if (e.dueMs > now) { ++it; continue; }
        Player* buddy = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(it->first));
        if (!buddy)
        {
            it = sEntrances.erase(it);
            continue;
        }
        if (!buddy->IsInWorld() || buddy->IsBeingTeleported())
        {
            if (now - e.startMs > ENTRANCE_GIVE_UP_MS)
            {
                LOG_ERROR("module", "mod-buddies: buddy {}'s entrance abandoned: its teleport never settled in {} ms (617b1)",
                    buddy->GetName(), ENTRANCE_GIVE_UP_MS);
                it = sEntrances.erase(it);
                continue;
            }
            e.dueMs = now + PASS_EVERY_MS;
            ++it;
            continue;
        }
        PlayerbotAI* ai = GET_PLAYERBOT_AI(buddy);
        if (e.stage == 1)
        {
            buddy->SetWalk(true);
            buddy->GetMotionMaster()->MovePoint(0, e.x, e.y, e.z);
            if (ai)
                ai->SetNextCheckDelay(ENTRANCE_WALK_MS + HANG_TICK_MS * 2);
            e.stage = 2;
            e.dueMs = now + ENTRANCE_WALK_MS;
            ++it;
            continue;
        }
        Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(e.owner));
        bool ownerHere = owner && owner->IsInWorld() && owner->GetMapId() == buddy->GetMapId();
        if (e.stage == 2)
        {
            if (buddy->isMoving())
            {
                if (ai)
                    ai->SetNextCheckDelay(HANG_TICK_MS * 2);
                e.dueMs = now + HANG_TICK_MS;
                ++it;
                continue;
            }
            if (ownerHere)
                buddy->SetFacingToObject(owner);
            if (ai)
                ai->SetNextCheckDelay(HANG_TICK_MS * 4);
            e.stage = 3;
            e.dueMs = now + HANG_TICK_MS * 2;
            ++it;
            continue;
        }
        if (e.stage == 3)
        {
            buddy->HandleEmoteCommand(GESTURE_EMOTE[uint8(e.greeting)]);
            CharacterDatabase.Execute("UPDATE buddy_roster SET greeting = {} WHERE buddy = {}", uint8(e.greeting), it->first);
            uint32 pause = urand(GESTURE_PAUSE_MIN_MS, GESTURE_PAUSE_MAX_MS);
            if (ai)
                ai->SetNextCheckDelay(pause + HANG_TICK_MS * 4);
            e.stage = 4;
            e.dueMs = now + pause;
            ++it;
            continue;
        }
        if (e.stage == 4)
        {
            float heading = frand(0.0f, 2.0f * float(M_PI));
            BuddyTurnToward(buddy, heading);
            if (ai)
                ai->SetNextCheckDelay(HANG_TICK_MS * 4);
            e.stage = 5;
            e.dueMs = now + HANG_TICK_MS;
            ++it;
            continue;
        }
        if (BuddyTurnBusy(buddy))
        {
            if (ai)
                ai->SetNextCheckDelay(HANG_TICK_MS * 2);
            e.dueMs = now + HANG_TICK_MS;
            ++it;
            continue;
        }
        buddy->SetWalk(false);
        it = sEntrances.erase(it);
    }
}

static bool PlaceBuddy(uint32 buddyGuid)
{
    Player* buddy = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(buddyGuid));
    if (!buddy)
        return true;
    if (!buddy->IsInWorld())
        return false;
    QueryResult row = CharacterDatabase.Query("SELECT owner FROM buddy_roster WHERE buddy = {}", buddyGuid);
    if (!row)
        return true;
    Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>((*row)[0].Get<uint32>()));
    if (!owner || !owner->IsInWorld())
        return true;
    Map* map = owner->GetMap();
    if (map->Instanceable())
        return true;
    if (BeginEntrance(buddy, owner, buddyGuid))
        return true;

    float ox = owner->GetPositionX(), oy = owner->GetPositionY(), oz = owner->GetPositionZ();
    for (int attempt = 0; attempt < PLACE_TRIES; ++attempt)
    {
        float angle = frand(0.0f, 2.0f * float(M_PI));
        float dist  = frand(PLACE_MIN_YARDS, PLACE_MAX_YARDS);
        float x = ox + std::cos(angle) * dist;
        float y = oy + std::sin(angle) * dist;
        float z = map->GetHeight(owner->GetPhaseMask(), x, y, oz + 10.0f, true, 30.0f);
        if (z <= INVALID_HEIGHT || std::fabs(z - oz) > 15.0f)
            continue;
        buddy->TeleportTo(owner->GetMapId(), x, y, z + 0.5f, std::atan2(oy - y, ox - x));
        return true;
    }
    LOG_WARN("module", "mod-buddies: found no ground 20-30 yards around {} for buddy {}; it stays where it logged in",
        owner->GetName(), buddy->GetName());
    return true;
}

class buddies_login_player : public PlayerScript
{
public:
    buddies_login_player() : PlayerScript("buddies_login_player", { PLAYERHOOK_ON_LOGIN }) { }

    void OnPlayerLogin(Player* player) override
    {
        if (!BuddiesEnabled())
            return;
        uint64 now = uint64(GameTime::GetGameTimeMS().count());
        if (BuddyIsStandInAccount(player->GetSession()->GetAccountId()))
            return;
        if (BuddyIsCompanionAccount(player->GetSession()->GetAccountId()))
            sBuddiesDue[player->GetGUID().GetCounter()] = { now + BUDDY_SETTLE_MS, 0 };
        else
            BuddyQueueLogin(player->GetGUID().GetCounter());
    }
};

class buddies_login_world : public WorldScript
{
public:
    buddies_login_world() : WorldScript("buddies_login_world", { WORLDHOOK_ON_UPDATE }) { }

    void OnUpdate(uint32 diff) override
    {
        _sinceEntrances += diff;
        if (_sinceEntrances >= HANG_TICK_MS && !sEntrances.empty())
        {
            _sinceEntrances = 0;
            StepEntrances(uint64(GameTime::GetGameTimeMS().count()));
        }

        _sinceLast += diff;
        if (_sinceLast < PASS_EVERY_MS)
            return;
        _sinceLast = 0;
        uint64 now = uint64(GameTime::GetGameTimeMS().count());
        Run(sOwnersDue, now, LogInBuddies, "log in the buddies of owner");
        Run(sBuddiesDue, now, PlaceBuddy, "place buddy");
        KeepBuddies(now);
    }

private:
    static void Run(std::map<uint32, BuddyWait>& due, uint64 now, bool (*step)(uint32), char const* what)
    {
        for (auto it = due.begin(); it != due.end(); )
        {
            if (it->second.dueMs > now) { ++it; continue; }
            if (step(it->first)) { it = due.erase(it); continue; }
            if (++it->second.tries >= OWNER_TRIES)
            {
                LOG_ERROR("module", "mod-buddies: could not {} {} after {} tries (bot manager or companion account not ready)",
                    what, it->first, OWNER_TRIES);
                it = due.erase(it);
                continue;
            }
            it->second.dueMs = now + PASS_EVERY_MS;
            ++it;
        }
    }

    uint32 _sinceLast = 0;
    uint32 _sinceEntrances = 0;
};

void AddSC_buddies_login()
{
    new buddies_login_player();
    new buddies_login_world();
}
