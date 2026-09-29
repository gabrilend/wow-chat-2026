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
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Log.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Playerbots.h"
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
};

// {{{ AddSC_buddies_login
void AddSC_buddies_login()
{
    new buddies_login_player();
    new buddies_login_world();
}
// }}}
