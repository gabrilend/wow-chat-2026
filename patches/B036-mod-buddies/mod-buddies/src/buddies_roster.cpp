
#include "buddies.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "ScriptMgr.h"
#include <initializer_list>

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

static bool sBuddiesEnabled = false;

bool BuddiesEnabled() { return sBuddiesEnabled; }

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

void AddSC_buddies_roster()
{
    new buddies_roster_startup();
}
