/*
 * buddies_loader.cpp - registers the buddy module's scripts (issue 617a1).
 *
 * For a general audience: the server finds each module through one
 * function named after the module's folder (mod-buddies ->
 * Addmod_buddiesScripts); the build generates the call. This file is that
 * function, and lists every script file of the module.
 */

// From the module's script files
void AddSC_buddies_roster();
void AddSC_buddies_clan();
void AddSC_buddies_create();
void AddSC_buddies_login();
void AddSC_buddies_clan_lock();
void AddSC_buddies_loyalty();
void AddSC_buddies_roam_strategy();
void AddSC_buddies_party();
void AddSC_buddies_xp();
void AddSC_buddies_beds();
void AddSC_buddies_explore();

// {{{ Addmod_buddiesScripts
void Addmod_buddiesScripts()
{
    AddSC_buddies_roster();
    AddSC_buddies_clan();
    AddSC_buddies_create();
    AddSC_buddies_login();
    AddSC_buddies_clan_lock();
    AddSC_buddies_loyalty();
    AddSC_buddies_roam_strategy();
    AddSC_buddies_party();
    AddSC_buddies_xp();
    AddSC_buddies_beds();
    AddSC_buddies_explore();
}
// }}}
