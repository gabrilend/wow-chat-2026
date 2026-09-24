/*
 * basic_rules.cpp - server rules for the basic profile (issue 155) that need
 * compiled code: things the Lua engine cannot refuse or change.
 *
 * For a general audience: the basic profile is the level 1-60 game. Some of
 * its rules sit where only the server's own code can reach, such as deciding
 * whether a talent may be learned. This file holds those rules. It lives in
 * the project (src/cpp-basic/) and source patch B030 copies it into the
 * server's stock "Custom" scripts folder at build time, then removes it.
 *
 * Current rules:
 *   - Talent cap (issue 155g): no talent in tier 6 or deeper (30+ points in
 *     the tree), as vanilla-era trees ended around there. Covers the tier-6
 *     "capstones" (fire mage Combustion, retribution Repentance), the talents
 *     beside them, and every deeper row. The client still draws the whole
 *     tree (its data files can't be changed); the server refuses and says why.
 */

#include "Chat.h"
#include "DBCStructure.h"
#include "Player.h"
#include "ScriptMgr.h"

// -- {{{ talent cap
// Row index of the first refused tier. Row n needs 5n points in the tree, so
// row 6 is the "30 points spent" row: Combustion and Repentance live there
// (checked in the client's Talent.dbc, 2026-09-23).
static constexpr uint32 BASIC_FIRST_CAPPED_TALENT_ROW = 6;

class basic_rules_talent_cap : public PlayerScript
{
public:
    basic_rules_talent_cap() : PlayerScript("basic_rules_talent_cap", { PLAYERHOOK_CAN_LEARN_TALENT }) { }

    // Called by Player::LearnTalent before anything is spent. Returning false
    // refuses the talent. Bots learn through the same path, so they are
    // capped too; a refusal leaves their point unspent (their talent loops
    // are bounded, so nothing retries forever).
    bool OnPlayerCanLearnTalent(Player* player, TalentEntry const* talent, uint32 /*rank*/) override
    {
        if (talent->Row < BASIC_FIRST_CAPPED_TALENT_ROW)
            return true;

        // A real player gets told why; a bot has no one to read it.
        if (player->GetSession() && !player->GetSession()->IsBot())
            ChatHandler(player->GetSession()).SendSysMessage(
                "That talent is beyond this realm's limit: talents needing 30 or more points in a tree are sealed.");
        return false;
    }
};
// -- }}}

// -- {{{ AddSC_basic_rules
// Registered from src/server/scripts/Custom/custom_script_loader.cpp by B030.
void AddSC_basic_rules()
{
    new basic_rules_talent_cap();
}
// -- }}}
