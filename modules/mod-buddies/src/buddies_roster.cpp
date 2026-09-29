/*
 * buddies_roster.cpp - the buddy roster's server side (issue 617a).
 *
 * For a general audience: every player character on the basic profile is
 * owed up to seven "buddies", bot companions made for them one at a time.
 * Who they are lives in two characters-database tables (installed by
 * install step E042, sql/basic/db_characters.src/04-buddy-roster):
 *   buddy_clan    one row per owner: the owner's hidden companion account
 *   buddy_roster  one row per owed or filled slot: which character the buddy
 *                 is, its class, race, talent shape and role
 * The roster row is also the handoff between the Lua side (the selector
 * that asks the player what they want, 617b) and this C++ side (which
 * makes the character, 617a3): Lua writes the choice into the owed row,
 * this module sees it and acts. Neither calls the other.
 *
 * Built so far (617a1): only the startup check that both tables are there.
 * A missing table means E042 did not run; the module then reports it as an
 * error and does nothing, rather than making buddies nobody can find.
 * Coming: the companion account (617a2), creation (617a3), the kit (617a4).
 */

#include "buddies.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "ScriptMgr.h"
#include <initializer_list>

// {{{ BuddyTablesPresent
// Both roster tables exist in the characters database. Logged as an error
// (naming the install step) when either is missing.
static bool BuddyTablesPresent()
{
    bool ok = true;
    for (char const* table : { "buddy_clan", "buddy_roster" })
    {
        if (!CharacterDatabase.Query("SHOW TABLES LIKE '{}'", table))
        {
            LOG_ERROR("module", ">> mod-buddies: characters table {} is missing (install step E042 not run?); buddies are OFF", table);
            ok = false;
        }
    }
    return ok;
}
// }}}

// Whether the tables were found at startup; later parts of the module
// (617a2, 617a3) do nothing while this is false.
static bool sBuddiesEnabled = false;

// {{{ BuddiesEnabled
bool BuddiesEnabled() { return sBuddiesEnabled; }
// }}}

class buddies_roster_startup : public WorldScript
{
public:
    buddies_roster_startup() : WorldScript("buddies_roster_startup", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        sBuddiesEnabled = BuddyTablesPresent();
        if (sBuddiesEnabled)
            LOG_INFO("module", ">> mod-buddies: roster tables present; buddies are ON");
    }
};

// {{{ AddSC_buddies_roster
void AddSC_buddies_roster()
{
    new buddies_roster_startup();
}
// }}}
