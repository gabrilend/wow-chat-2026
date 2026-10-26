
#include "buddies.h"
#include "CompanionAccounts.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldSession.h"

static constexpr uint32 BUDDY_REFUSED_LOGIN_FLAGS = AT_LOGIN_RENAME | AT_LOGIN_CHANGE_FACTION | AT_LOGIN_CHANGE_RACE;

static constexpr uint32 BUDDY_FLAG_SWEEP_MS       = 60 * IN_MILLISECONDS;

static std::string BuddyClearRefusedFlagsSql()
{
    return "UPDATE characters c JOIN buddy_roster r ON r.buddy = c.guid "
           "SET c.at_login = c.at_login & ~" + std::to_string(BUDDY_REFUSED_LOGIN_FLAGS) +
           " WHERE r.buddy <> 0 AND (c.at_login & " + std::to_string(BUDDY_REFUSED_LOGIN_FLAGS) + ") <> 0";
}

static void BuddyMarkAllCompanionAccounts()
{
    uint32 marked  = 0;
    uint32 pending = 0;

    if (QueryResult r = CharacterDatabase.Query("SELECT owner, companion_account FROM buddy_clan"))
    {
        do
        {
            uint32 owner   = (*r)[0].Get<uint32>();
            uint32 account = (*r)[1].Get<uint32>();

            if (!account)
                account = BuddyCompanionAccountId(owner);

            if (account)
            {
                CompanionAccounts::Mark(account);
                ++marked;
            }
            else
                ++pending;
        } while (r->NextRow());
    }

    LOG_INFO("module", ">> mod-buddies: {} companion account(s) hidden from /who, friends and chat commands; "
        "{} owner(s) without an account yet (made at their next login)", marked, pending);
}

class buddies_hidden_world : public WorldScript
{
public:
    buddies_hidden_world() : WorldScript("buddies_hidden_world", { WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_UPDATE }) { }

    void OnStartup() override
    {
        if (!BuddiesEnabled())
            return;
        BuddyMarkAllCompanionAccounts();
        CharacterDatabase.DirectExecute(BuddyClearRefusedFlagsSql());
    }

    void OnUpdate(uint32 diff) override
    {
        if (!BuddiesEnabled())
            return;
        _sinceSweep += diff;
        if (_sinceSweep < BUDDY_FLAG_SWEEP_MS)
            return;
        _sinceSweep = 0;
        CharacterDatabase.Execute(BuddyClearRefusedFlagsSql());
    }

private:
    uint32 _sinceSweep = 0;
};

class buddies_hidden_player : public PlayerScript
{
public:
    buddies_hidden_player() : PlayerScript("buddies_hidden_player",
        { PLAYERHOOK_ON_CREATE, PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_SAVE,
          PLAYERHOOK_ON_BEFORE_CRITERIA_PROGRESS, PLAYERHOOK_ON_BEFORE_ACHI_COMPLETE }) { }

    void OnPlayerCreate(Player* player) override
    {
        if (!BuddiesEnabled())
            return;
        uint32 account = player->GetSession()->GetAccountId();
        if (BuddyIsNotAPlayer(account))
            CompanionAccounts::Mark(account);
    }

    void OnPlayerLogin(Player* player) override
    {
        if (!BuddiesEnabled())
            return;
        uint32 account = player->GetSession()->GetAccountId();
        if (BuddyIsNotAPlayer(account))
            CompanionAccounts::Mark(account);
    }

    void OnPlayerSave(Player* player) override
    {
        if (!CompanionAccounts::Is(player->GetSession()->GetAccountId()))
            return;
        player->RemoveAtLoginFlag(AT_LOGIN_RENAME);
        player->RemoveAtLoginFlag(AT_LOGIN_CHANGE_FACTION);
        player->RemoveAtLoginFlag(AT_LOGIN_CHANGE_RACE);
    }

    bool OnPlayerBeforeCriteriaProgress(Player* player, AchievementCriteriaEntry const* ) override
    {
        return !CompanionAccounts::Is(player->GetSession()->GetAccountId());
    }

    bool OnPlayerBeforeAchievementComplete(Player* player, AchievementEntry const* ) override
    {
        return !CompanionAccounts::Is(player->GetSession()->GetAccountId());
    }
};

void AddSC_buddies_hidden()
{
    new buddies_hidden_world();
    new buddies_hidden_player();
}
