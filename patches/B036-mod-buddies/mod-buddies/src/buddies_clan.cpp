
#include "buddies.h"
#include "AccountMgr.h"
#include "CryptoRandom.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Util.h"
#include <array>

static constexpr uint8 BUDDY_SLOTS = 26;
uint8 BuddySlotLevel(uint8 slot) { return slot == 1 ? 1 : uint8((slot - 1) * 10); }

std::string BuddyCompanionAccountName(uint32 ownerGuid)
{
    return "BUDDY" + std::to_string(ownerGuid);
}

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

static bool EnsureCompanionAccount(uint32 ownerGuid)
{
    CharacterDatabase.DirectExecute("INSERT IGNORE INTO buddy_clan (owner) VALUES ({})", ownerGuid);

    std::string name = BuddyCompanionAccountName(ownerGuid);
    if (AccountMgr::GetId(name))
        return true;

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

class buddies_clan_player : public PlayerScript
{
public:
    buddies_clan_player() : PlayerScript("buddies_clan_player",
        { PLAYERHOOK_ON_CREATE, PLAYERHOOK_ON_LEVEL_CHANGED, PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_DELETE }) { }

    void OnPlayerCreate(Player* player) override
    {
        if (!BuddiesEnabled() || BuddyIsNotAPlayer(player->GetSession()->GetAccountId()))
            return;
        uint32 owner = player->GetGUID().GetCounter();
        EnsureCompanionAccount(owner);
        OweSlotsUpTo(player);
    }

    void OnPlayerLevelChanged(Player* player, uint8 ) override
    {
        if (!BuddiesEnabled() || BuddyIsNotAPlayer(player->GetSession()->GetAccountId()))
            return;
        OweSlotsUpTo(player);
    }

    void OnPlayerLogin(Player* player) override
    {
        if (!BuddiesEnabled() || BuddyIsNotAPlayer(player->GetSession()->GetAccountId()))
            return;
        uint32 owner = player->GetGUID().GetCounter();
        EnsureCompanionAccount(owner);
        OweSlotsUpTo(player);
    }

    void OnPlayerDelete(ObjectGuid guid, uint32 accountId) override
    {
        if (!BuddiesEnabled())
            return;
        if (BuddyIsStandInAccount(accountId))
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

class buddies_clan_account : public AccountScript
{
public:
    buddies_clan_account() : AccountScript("buddies_clan_account", { ACCOUNTHOOK_ON_BEFORE_ACCOUNT_DELETE }) { }

    void OnBeforeAccountDelete(uint32 accountId) override
    {
        if (!BuddiesEnabled() || BuddyIsNotAPlayer(accountId))
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

void AddSC_buddies_clan()
{
    new buddies_clan_player();
    new buddies_clan_account();
}
