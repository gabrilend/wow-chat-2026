/*
 * buddies_hidden.cpp - buddies are hidden and locked (issue 617a5).
 *
 * For a general audience: a buddy is a companion, not a stranger on the
 * server. The owner's decisions of 2026-09-25 (617a): a buddy never shows in
 * the /who list, nobody can add one as a friend, it ignores the bot
 * module's chat commands, and it can't be renamed or change faction or race.
 * The first three are checks inside the server and the bot module (source
 * patches B044 and B045) against one list: "these accounts are companion
 * accounts". This file keeps that list full, and keeps the rename flags off.
 *
 * Filling the list:
 *   startup    every companion account in buddy_clan (resolving the ones
 *              whose id was never recorded by their deterministic name)
 *   creation   a character made on a companion account (617a3 makes
 *              buddies there) marks its account at once
 *   login      a buddy's login marks its account, for accounts made after
 *              startup by an owner's first login (617a2)
 * The list is never shrunk: a deleted owner's companion account is deleted
 * with it (buddies_clan.cpp), and account ids are not reused.
 *
 * Rename, faction and race flags: a rename flag stops a character from
 * loading at all ("tried to login while forced to rename"), so a flag on a
 * buddy is cleared before it can bite: in the characters table at startup
 * and once a minute (a game master can set it on an offline buddy), and in
 * memory at every save of an online buddy (set on one that is logged in).
 * The faction and race change flags go with it: basic offers neither, and
 * a buddy never visits the character screen where they would act.
 *
 * Registered after the roster check in buddies_loader.cpp: the startup
 * fill reads BuddiesEnabled(), which the roster check sets in its own
 * startup hook.
 */

#include "buddies.h"
#include "CompanionAccounts.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldSession.h"

// The login flags no buddy may carry (Player.h, AtLoginFlags):
//   0x01 rename         blocks the character's load outright
//   0x40 change faction
//   0x80 change race
static constexpr uint32 BUDDY_REFUSED_LOGIN_FLAGS = AT_LOGIN_RENAME | AT_LOGIN_CHANGE_FACTION | AT_LOGIN_CHANGE_RACE;

static constexpr uint32 BUDDY_FLAG_SWEEP_MS       = 60 * IN_MILLISECONDS;   // characters-table sweep period

// {{{ BuddyClearRefusedFlagsSql
// The characters-table sweep: every filled roster slot's character loses
// the refused flags. Rows without them are left alone (the WHERE), so a
// quiet minute writes nothing.
static std::string BuddyClearRefusedFlagsSql()
{
    return "UPDATE characters c JOIN buddy_roster r ON r.buddy = c.guid "
           "SET c.at_login = c.at_login & ~" + std::to_string(BUDDY_REFUSED_LOGIN_FLAGS) +
           " WHERE r.buddy <> 0 AND (c.at_login & " + std::to_string(BUDDY_REFUSED_LOGIN_FLAGS) + ") <> 0";
}
// }}}

// {{{ BuddyMarkAllCompanionAccounts
// Every owner's companion account onto the list, with a log line of how
// many; owners whose account doesn't exist yet are counted apart (their
// first login makes it, and the buddy login hook below marks it).
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

            // id never recorded: look it up by its deterministic name (and
            // record it); still 0 means the account was never made
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
// }}}

class buddies_hidden_world : public WorldScript
{
public:
    buddies_hidden_world() : WorldScript("buddies_hidden_world", { WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_UPDATE }) { }

    // {{{ OnStartup
    // The list filled and the flags swept before anyone can log in. The
    // sweep is direct (not queued) so it lands before the first buddy load.
    void OnStartup() override
    {
        if (!BuddiesEnabled())
            return;                                         // roster tables missing: the roster check said so
        BuddyMarkAllCompanionAccounts();
        CharacterDatabase.DirectExecute(BuddyClearRefusedFlagsSql());
    }
    // }}}

    // {{{ OnUpdate
    // The once-a-minute sweep, queued: a flag set by a game master on an
    // offline buddy is gone before the owner's next login brings it in.
    void OnUpdate(uint32 diff) override
    {
        if (!BuddiesEnabled())
            return;
        _sinceSweep += diff;
        if (_sinceSweep < BUDDY_FLAG_SWEEP_MS)
            return;                                         // not yet a minute
        _sinceSweep = 0;
        CharacterDatabase.Execute(BuddyClearRefusedFlagsSql());
    }
    // }}}

private:
    uint32 _sinceSweep = 0;
};

class buddies_hidden_player : public PlayerScript
{
public:
    buddies_hidden_player() : PlayerScript("buddies_hidden_player",
        { PLAYERHOOK_ON_CREATE, PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_SAVE }) { }

    // {{{ OnPlayerCreate
    // A buddy just made (617a3): its account is hidden before it ever
    // logs in, so it can't be friended in the meantime.
    void OnPlayerCreate(Player* player) override
    {
        if (!BuddiesEnabled())
            return;
        uint32 account = player->GetSession()->GetAccountId();
        if (BuddyIsCompanionAccount(account))
            CompanionAccounts::Mark(account);               // a buddy; an owner's own character is left listed
    }
    // }}}

    // {{{ OnPlayerLogin
    // A buddy logging in: its account onto the list (already there unless
    // the account was made after startup).
    void OnPlayerLogin(Player* player) override
    {
        if (!BuddiesEnabled())
            return;
        uint32 account = player->GetSession()->GetAccountId();
        if (BuddyIsCompanionAccount(account))
            CompanionAccounts::Mark(account);
    }
    // }}}

    // {{{ OnPlayerSave
    // Runs just before the character row is written: an online buddy's
    // refused flags are dropped from memory, so the save never stores them.
    // Asks the in-memory list, not the database: this fires for every
    // player's every save.
    void OnPlayerSave(Player* player) override
    {
        if (!CompanionAccounts::Is(player->GetSession()->GetAccountId()))
            return;                                         // not a buddy: flags as they are
        player->RemoveAtLoginFlag(AT_LOGIN_RENAME);
        player->RemoveAtLoginFlag(AT_LOGIN_CHANGE_FACTION);
        player->RemoveAtLoginFlag(AT_LOGIN_CHANGE_RACE);
    }
    // }}}
};

// {{{ AddSC_buddies_hidden
void AddSC_buddies_hidden()
{
    new buddies_hidden_world();
    new buddies_hidden_player();
}
// }}}
