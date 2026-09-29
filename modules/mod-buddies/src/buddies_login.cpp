/*
 * buddies_login.cpp - buddies come into the world with their owner (issue
 * 617c1).
 *
 * For a general audience: when a player logs in, each buddy already made
 * for that character logs in too, as the player's own bot, and appears
 * 20 to 30 yards away, facing them. When the player logs out, the bot
 * module logs its bots out with them (its own rule), so nothing is needed
 * here for that.
 *
 * How the bot module is persuaded: it lets a player control a bot only when
 * the bot is on the player's account, in their guild, or on an account
 * linked to theirs in its table playerbots_account_links. Buddies live on
 * the owner's hidden companion account (617a2), so that account is linked
 * to the owner's the moment the owner logs in; then the owner's bot manager
 * is asked to log each buddy in.
 *
 * Both steps wait a moment after a login: the owner's bot manager exists
 * only once the owner is in the world, and a buddy is placed only once it
 * has finished arriving. A world-update pass does the waiting.
 */

#include "buddies.h"
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
#include "Random.h"
#include "ScriptMgr.h"
#include "WorldSession.h"
#include <cmath>
#include <map>

// {{{ tuning (owner decisions, 617c)
static constexpr uint32 OWNER_SETTLE_MS  = 3000;   // after the owner's login, before its buddies are asked in
static constexpr uint32 BUDDY_SETTLE_MS  = 1000;   // after a buddy's login, before it is placed
static constexpr uint32 PASS_EVERY_MS    = 500;
static constexpr uint32 OWNER_TRIES      = 20;     // passes to wait for the bot manager or account (10 s)
static constexpr float  PLACE_MIN_YARDS  = 20.0f;  // "near the owner's area (not on top of the owner)"
static constexpr float  PLACE_MAX_YARDS  = 30.0f;
static constexpr int    PLACE_TRIES      = 6;      // directions tried for solid ground
// }}}

struct BuddyWait { uint64 dueMs; uint32 tries; };
static std::map<uint32, BuddyWait> sOwnersDue;     // owner guid -> when to log its buddies in
static std::map<uint32, BuddyWait> sBuddiesDue;    // buddy guid -> when to place it

// {{{ BuddyQueueLogin
// Log the owner's made buddies in soon (at the owner's login, and when a new
// buddy is made while the owner is online, 617a3).
void BuddyQueueLogin(uint32 ownerGuid)
{
    sOwnersDue[ownerGuid] = { uint64(GameTime::GetGameTimeMS().count()) + OWNER_SETTLE_MS, 0 };
}
// }}}

// {{{ LogInBuddies
// Returns true when done (or impossible, reported), false to try again.
static bool LogInBuddies(uint32 ownerGuid)
{
    Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(ownerGuid));
    if (!owner)
        return true;                                   // gone again: nothing to do
    if (!owner->IsInWorld())
        return false;
    PlayerbotMgr* mgr = GET_PLAYERBOT_MGR(owner);
    if (!mgr)
        return false;
    uint32 companion = BuddyCompanionAccountId(ownerGuid);
    if (!companion)
        return false;                                  // the account is still being written
    uint32 ownerAccount = owner->GetSession()->GetAccountId();

    // Written directly: the bot manager reads the link as soon as it is asked.
    PlayerbotsDatabase.DirectExecute("INSERT IGNORE INTO playerbots_account_links (account_id, linked_account_id) VALUES ({}, {})",
        companion, ownerAccount);

    QueryResult buddies = CharacterDatabase.Query("SELECT buddy FROM buddy_roster WHERE owner = {} AND buddy <> 0", ownerGuid);
    if (!buddies)
        return true;
    do
        mgr->AddPlayerBot(ObjectGuid::Create<HighGuid::Player>((*buddies)[0].Get<uint32>()), ownerAccount);
    while (buddies->NextRow());
    return true;
}
// }}}

// {{{ the entrance (617b1)
// A buddy's first appearance, when a Sargobras stands near its owner: it
// appears about 5 yards behind him to one side, facing its owner, walks
// about 3 steps forward, and waves or salutes to the owner (owner,
// 2026-09-29: "not facing him, but facing you. She waves or salutes to
// *you*, not him"). The gesture goes in its roster row (greeting: 0 none
// yet, 1 wave, 2 salute), which also marks the entrance as done: "We
// should remember which one they did because it'll inform their
// personality later."
// Then it hangs out: it stands until the owner has moved 5 yards from
// where they stood when it appeared, then turns to face them every
// quarter second, and once the owner is 10 yards from that spot it
// "starts to run toward adventure" (its ordinary roaming and distance
// grouping). The bot module's AI is held off from the teleport to that
// moment, so nothing walks the buddy away early. No Sargobras near:
// placed the ordinary way, silently ("This should never happen").
static constexpr uint32 SARGOBRAS_VALLEY      = 6170001;  // 26-buddy-selector.sql
static constexpr uint32 SARGOBRAS_WANDERER    = 6170002;
static constexpr float  ENTRANCE_NEAR_YARDS   = 50.0f;   // a Sargobras this near the owner stages it
static constexpr float  ENTRANCE_BEHIND_YARDS = 4.5f;    // behind him ...
static constexpr float  ENTRANCE_SIDE_YARDS   = 2.0f;    // ... and to one side: about 5 yards from him
static constexpr float  ENTRANCE_STEP_YARDS   = 2.5f;    // "about 3 steps" forward, at walking pace
static constexpr uint32 ENTRANCE_ARRIVE_MS    = 1500;    // after the teleport, before the steps
static constexpr uint32 ENTRANCE_WALK_MS      = 1500;    // the steps
static constexpr uint32 ENTRANCE_GIVE_UP_MS   = 10000;   // a teleport that never settles: abandoned, logged
static constexpr uint32 HANG_TICK_MS          = 250;     // "turn every quarter second to them"
static constexpr float  HANG_TURN_YARDS       = 5.0f;    // the owner this far from their spot: it starts turning
static constexpr float  HANG_RELEASE_YARDS    = 10.0f;   // this far: it runs off to roam

enum class Greeting : uint8 { None = 0, Wave = 1, Salute = 2 };

// stage 1 arriving, 2 walking, 3 hanging out
struct Entrance
{
    uint64   startMs, dueMs;
    uint8    stage;
    float    x, y, z;                                  // where the steps end
    Greeting greeting;
    uint32   owner;                                    // the owner's guid ...
    float    ox, oy, oz;                               // ... and where they stood when it appeared
};
static std::map<uint32, Entrance> sEntrances;              // buddy guid -> its entrance under way

// Starts the entrance and returns true; false (the ordinary placing
// follows) when the buddy has greeted before, or no Sargobras is near.
static bool BeginEntrance(Player* buddy, Player* owner, uint32 buddyGuid)
{
    QueryResult row = CharacterDatabase.Query("SELECT greeting FROM buddy_roster WHERE buddy = {}", buddyGuid);
    if (!row || (*row)[0].Get<uint8>() != uint8(Greeting::None))
        return false;                                  // greeted before: placed the ordinary way

    Creature* s = owner->FindNearestCreature(SARGOBRAS_VALLEY, ENTRANCE_NEAR_YARDS);
    Creature* w = owner->FindNearestCreature(SARGOBRAS_WANDERER, ENTRANCE_NEAR_YARDS);
    if (!s || (w && owner->GetExactDist(w) < owner->GetExactDist(s)))
        s = w;                                         // the nearer of the two, when both are near
    if (!s)
        return false;                                  // none near: the ordinary placing

    float o    = s->GetOrientation();
    float side = urand(0, 1) ? 1.0f : -1.0f;           // left or right of him, at random
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
    // the steps go his way, "forward": out from behind him toward the
    // ground he faces, where the newcomers arrive
    sEntrances[buddyGuid] = { now, now + ENTRANCE_ARRIVE_MS, 1,
        x + std::cos(o) * ENTRANCE_STEP_YARDS, y + std::sin(o) * ENTRANCE_STEP_YARDS, z,
        urand(0, 1) ? Greeting::Wave : Greeting::Salute,
        owner->GetGUID().GetCounter(), ox, oy, oz };
    return true;
}

// One stage of each entrance that is due: 1 the steps, 2 the gesture,
// 3 the hang-out, a quarter second at a time.
static void StepEntrances(uint64 now)
{
    for (auto it = sEntrances.begin(); it != sEntrances.end(); )
    {
        Entrance& e = it->second;
        if (e.dueMs > now) { ++it; continue; }
        Player* buddy = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(it->first));
        if (!buddy)
        {
            it = sEntrances.erase(it);                 // logged out mid-entrance: it tries again next login
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
            e.dueMs = now + PASS_EVERY_MS;             // still arriving: next pass
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
            // the gesture, to the owner
            if (ownerHere)
                buddy->SetFacingToObject(owner);
            buddy->HandleEmoteCommand(e.greeting == Greeting::Wave ? EMOTE_ONESHOT_WAVE : EMOTE_ONESHOT_SALUTE);
            CharacterDatabase.Execute("UPDATE buddy_roster SET greeting = {} WHERE buddy = {}", uint8(e.greeting), it->first);
            e.stage = 3;
        }
        // the hang-out: the owner gone, or 10 yards from their spot, lets
        // it go; 5 yards and it turns to them; nearer, it stands
        float moved = ownerHere ? owner->GetExactDist(e.ox, e.oy, e.oz) : HANG_RELEASE_YARDS;
        if (moved >= HANG_RELEASE_YARDS)
        {
            buddy->SetWalk(false);                     // "starts to run toward adventure"
            it = sEntrances.erase(it);                 // the AI's next check picks roaming up
            continue;
        }
        if (moved > HANG_TURN_YARDS)
            buddy->SetFacingToObject(owner);
        if (ai)
            ai->SetNextCheckDelay(HANG_TICK_MS * 2);
        e.dueMs = now + HANG_TICK_MS;
        ++it;
    }
}
// }}}

// {{{ PlaceBuddy
// 20-30 yards from the owner, in a random direction with ground under it,
// facing the owner. Not inside a dungeon, raid or battleground: bringing a
// buddy into an instance is the dungeon draw's job (617c3); it stays where
// it logged in. Returns true when done, false to try again.
static bool PlaceBuddy(uint32 buddyGuid)
{
    Player* buddy = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(buddyGuid));
    if (!buddy)
        return true;
    if (!buddy->IsInWorld())
        return false;
    QueryResult row = CharacterDatabase.Query("SELECT owner FROM buddy_roster WHERE buddy = {}", buddyGuid);
    if (!row)
        return true;                                   // not a buddy (another character on the account)
    Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>((*row)[0].Get<uint32>()));
    if (!owner || !owner->IsInWorld())
        return true;
    Map* map = owner->GetMap();
    if (map->Instanceable())
        return true;
    if (BeginEntrance(buddy, owner, buddyGuid))
        return true;                                   // its first appearance, from behind Sargobras (617b1)

    float ox = owner->GetPositionX(), oy = owner->GetPositionY(), oz = owner->GetPositionZ();
    for (int attempt = 0; attempt < PLACE_TRIES; ++attempt)
    {
        float angle = frand(0.0f, 2.0f * float(M_PI));
        float dist  = frand(PLACE_MIN_YARDS, PLACE_MAX_YARDS);
        float x = ox + std::cos(angle) * dist;
        float y = oy + std::sin(angle) * dist;
        float z = map->GetHeight(owner->GetPhaseMask(), x, y, oz + 10.0f, true, 30.0f);
        if (z <= INVALID_HEIGHT || std::fabs(z - oz) > 15.0f)
            continue;                                  // a cliff, water or a wall: another direction
        buddy->TeleportTo(owner->GetMapId(), x, y, z + 0.5f, std::atan2(oy - y, ox - x));
        return true;
    }
    LOG_WARN("module", "mod-buddies: found no ground 20-30 yards around {} for buddy {}; it stays where it logged in",
        owner->GetName(), buddy->GetName());
    return true;
}
// }}}

class buddies_login_player : public PlayerScript
{
public:
    buddies_login_player() : PlayerScript("buddies_login_player", { PLAYERHOOK_ON_LOGIN }) { }

    // An owner's login queues its buddies; a buddy's login queues its
    // placement.
    void OnPlayerLogin(Player* player) override
    {
        if (!BuddiesEnabled())
            return;
        uint64 now = uint64(GameTime::GetGameTimeMS().count());
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
        // entrances on their own quarter-second clock (the hang-out's turns);
        // an empty map costs one comparison
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
    }

private:
    // Each due entry is tried; one not ready yet waits another pass, up to
    // OWNER_TRIES, then is dropped with an error naming it.
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

// {{{ AddSC_buddies_login
void AddSC_buddies_login()
{
    new buddies_login_player();
    new buddies_login_world();
}
// }}}
