/*
 * buddies_clan.cpp - each owner's companion account and owed buddy slots
 * (issue 617a2).
 *
 * For a general audience: every player character gets a hidden account of
 * its own to hold its buddies (Ritz, 2026-09-25: "one buddy bot account per
 * character created"). Nobody is told its password, so nobody can log into
 * it. The character is owed its first buddy when it is made and one more at
 * levels 10, 20, 30, 40, 50 and 60; each owed buddy is a row in the roster
 * waiting for the player's choice (617b). Deleting the character deletes
 * the hidden account, its buddies with it, and every roster row.
 *
 * Moments this file answers:
 *   character made      -> hidden account, clan row, slot 1 owed
 *                          (a death knight: the account and clan row only;
 *                          its four buddies come with the soul trade)
 *   level reached       -> the slots owed up to that level
 *   login               -> the same catch-up, for characters made before
 *                          this was installed (or if a step above failed)
 *   character deleted   -> hidden account and buddies deleted, rows removed;
 *                          a deleted buddy frees its slot to be chosen again
 *   account deleted     -> the same, for each of its characters
 * A buddy (a character on a companion account) gets none of this.
 */

#include "buddies.h"
#include "AccountMgr.h"
#include "CryptoRandom.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Util.h"
#include <array>

// Slot n is owed from this level: 1 at creation, then every tenth level.
// Seven slots reach 60, basic's cap.
static constexpr uint8 BUDDY_SLOTS = 7;
static uint8 BuddySlotLevel(uint8 slot) { return slot == 1 ? 1 : uint8((slot - 1) * 10); }

// {{{ BuddyCompanionAccountName
std::string BuddyCompanionAccountName(uint32 ownerGuid)
{
    return "BUDDY" + std::to_string(ownerGuid);
}
// }}}

// {{{ BuddyCompanionAccountId
// The account manager writes a new account through the login database's
// queue, so its id isn't known the moment it is created. The name is
// deterministic, so the id is looked up by name whenever it is needed and
// recorded in buddy_clan the first time it is found.
uint32 BuddyCompanionAccountId(uint32 ownerGuid)
{
    if (QueryResult r = CharacterDatabase.Query("SELECT companion_account FROM buddy_clan WHERE owner = {}", ownerGuid))
        if (uint32 id = (*r)[0].Get<uint32>())
            return id;

    uint32 id = AccountMgr::GetId(BuddyCompanionAccountName(ownerGuid));
    if (id)
        CharacterDatabase.Execute("UPDATE buddy_clan SET companion_account = {} WHERE owner = {}", id, ownerGuid);
    return id;
}
// }}}

// {{{ BuddyIsCompanionAccount
// A companion account is named BUDDY<owner guid> and that owner has a clan
// row. Both are checked: a player could register an account named BUDDY7
// through a website, but it would have no clan row behind it.
bool BuddyIsCompanionAccount(uint32 accountId)
{
    if (QueryResult r = CharacterDatabase.Query("SELECT 1 FROM buddy_clan WHERE companion_account = {}", accountId))
        return true;

    std::string name;
    if (!AccountMgr::GetName(accountId, name) || name.size() <= 5 || name.compare(0, 5, "BUDDY") != 0)
        return false;
    std::string digits = name.substr(5);
    if (digits.find_first_not_of("0123456789") != std::string::npos)
        return false;
    return CharacterDatabase.Query("SELECT 1 FROM buddy_clan WHERE owner = {}", digits) != nullptr;
}
// }}}

// {{{ EnsureCompanionAccount
// The owner's clan row and hidden account exist. Returns false (and says
// why) when the account can't be made; the next login tries again.
static bool EnsureCompanionAccount(uint32 ownerGuid)
{
    CharacterDatabase.DirectExecute("INSERT IGNORE INTO buddy_clan (owner) VALUES ({})", ownerGuid);

    std::string name = BuddyCompanionAccountName(ownerGuid);
    if (AccountMgr::GetId(name))
        return true;

    // A password nobody is told: 8 random bytes as 16 hex digits, the
    // account manager's longest.
    std::array<uint8, 8> bytes;
    Acore::Crypto::GetRandomBytes(bytes);
    AccountOpResult result = AccountMgr::instance()->CreateAccount(name, ByteArrayToHexStr(bytes));
    if (result != AOR_OK)
    {
        LOG_ERROR("module", "mod-buddies: could not create companion account {} for owner {} (account manager result {}); "
            "the clan row exists, the account does not; retried at the owner's next login",
            name, ownerGuid, uint32(result));
        return false;
    }
    LOG_INFO("module", "mod-buddies: companion account {} created for owner {}", name, ownerGuid);
    return true;
}
// }}}

// {{{ OweSlotsUpTo
// Every slot whose level the owner has reached exists as a roster row;
// existing rows (owed or filled) are left alone. A death knight is owed
// nothing by level: it gets exactly four buddies when it accepts the soul
// trade in Acherus (owner, 2026-09-26; src/lua-basic/sargobras.lua).
static void OweSlotsUpTo(Player* owner)
{
    if (owner->getClass() == CLASS_DEATH_KNIGHT)
        return;
    uint32 ownerGuid = owner->GetGUID().GetCounter();
    uint8  level     = owner->GetLevel();
    for (uint8 slot = 1; slot <= BUDDY_SLOTS; ++slot)
        if (level >= BuddySlotLevel(slot))
            CharacterDatabase.Execute("INSERT IGNORE INTO buddy_roster (owner, slot) VALUES ({}, {})", ownerGuid, slot);
}
// }}}

// {{{ ForgetOwner
// Delete an owner's hidden account (which deletes its buddies, logging out
// any that are online) and every row naming the owner.
static void ForgetOwner(uint32 ownerGuid)
{
    if (uint32 account = BuddyCompanionAccountId(ownerGuid))
    {
        AccountOpResult result = AccountMgr::DeleteAccount(account);
        if (result != AOR_OK)
            LOG_ERROR("module", "mod-buddies: deleting owner {}'s companion account {} failed (account manager result {}); "
                "its buddies remain on that account", ownerGuid, account, uint32(result));
    }
    CharacterDatabase.Execute("DELETE FROM buddy_roster WHERE owner = {}", ownerGuid);
    CharacterDatabase.Execute("DELETE FROM buddy_clan WHERE owner = {}", ownerGuid);
}
// }}}

class buddies_clan_player : public PlayerScript
{
public:
    buddies_clan_player() : PlayerScript("buddies_clan_player",
        { PLAYERHOOK_ON_CREATE, PLAYERHOOK_ON_LEVEL_CHANGED, PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_DELETE }) { }

    // A new character: its hidden account and first owed slot. Characters
    // made on a companion account are buddies (617a3 makes them there).
    void OnPlayerCreate(Player* player) override
    {
        if (!BuddiesEnabled() || BuddyIsCompanionAccount(player->GetSession()->GetAccountId()))
            return;
        uint32 owner = player->GetGUID().GetCounter();
        EnsureCompanionAccount(owner);
        OweSlotsUpTo(player);
    }

    void OnPlayerLevelChanged(Player* player, uint8 /*oldLevel*/) override
    {
        if (!BuddiesEnabled() || BuddyIsCompanionAccount(player->GetSession()->GetAccountId()))
            return;
        OweSlotsUpTo(player);
    }

    // Catch-up for characters made before this was installed, or whose
    // account creation failed.
    void OnPlayerLogin(Player* player) override
    {
        if (!BuddiesEnabled() || BuddyIsCompanionAccount(player->GetSession()->GetAccountId()))
            return;
        uint32 owner = player->GetGUID().GetCounter();
        EnsureCompanionAccount(owner);
        OweSlotsUpTo(player);
    }

    // Fired just before the character is removed. An owner takes its clan
    // with it. A buddy deleted by other means (a game master) frees its
    // slot: the row goes back to owed, so its owner chooses again.
    void OnPlayerDelete(ObjectGuid guid, uint32 accountId) override
    {
        if (!BuddiesEnabled())
            return;
        if (BuddyIsCompanionAccount(accountId))
        {
            CharacterDatabase.Execute("UPDATE buddy_roster SET buddy = 0, class = 0, race = 0, profile = 0, role = 0, "
                "talents_reroll = 0, created = 0 WHERE buddy = {}", guid.GetCounter());
            return;
        }
        ForgetOwner(guid.GetCounter());
    }
};

// Deleting a whole player account deletes its characters without the
// character-delete event, so each of its owners is forgotten here first.
class buddies_clan_account : public AccountScript
{
public:
    buddies_clan_account() : AccountScript("buddies_clan_account", { ACCOUNTHOOK_ON_BEFORE_ACCOUNT_DELETE }) { }

    void OnBeforeAccountDelete(uint32 accountId) override
    {
        if (!BuddiesEnabled() || BuddyIsCompanionAccount(accountId))
            return;
        QueryResult owners = CharacterDatabase.Query(
            "SELECT c.owner FROM buddy_clan c JOIN characters ch ON ch.guid = c.owner WHERE ch.account = {}", accountId);
        if (!owners)
            return;
        do
            ForgetOwner((*owners)[0].Get<uint32>());
        while (owners->NextRow());
    }
};

// {{{ AddSC_buddies_clan
void AddSC_buddies_clan()
{
    new buddies_clan_player();
    new buddies_clan_account();
}
// }}}
