/*
 * buddies_reset.cpp - a game master resets a buddy: it is made again as a
 * class its owner chooses at Sargobras, keeping its name, gender and race
 * (issue 617a7).
 *
 * For a general audience: the owner, 2026-10-25: "the players cannot do
 * this. Sargobras shouldn't know about it, not really. It's for the GMs to
 * use. We should have it usable as either a GM command or a bash script".
 * ".buddy reset <name>" (in game, or from a shell through the server's
 * console: scripts/gm-command ".buddy reset <name>") does it in two halves:
 *   now      - the buddy, which must be in the world, mails everything it
 *              wears and carries and its money to itself ("Kept for you",
 *              as a remade buddy does, 617a6), leaves the world, and gives
 *              up its name (renamed to a placeholder, so its new self can
 *              take it); its roster slot is owed again, its race kept, with
 *              the name and gender to make it with;
 *   later    - the owner speaks to Sargobras, who offers only the classes
 *              that race can play (no death knight); the buddy module makes
 *              the new buddy with the kept name and gender, hands it the
 *              old one's "Kept for you" mail, and deletes the old character
 *              (BuddyFinishReset, called by buddies_create.cpp).
 * A new character rather than the old one changed (2026-10-25: "we can
 * replace it's history. The way that it functions behind the scenes
 * shouldn't be relevant to the player.").
 */

#include "buddies.h"
#include "CharacterCache.h"
#include "Chat.h"
#include "CommandScript.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Playerbots.h"
#include "RandomPlayerbotMgr.h"
#include "ScriptMgr.h"
#include <string>

using namespace Acore::ChatCommands;

// {{{ BuddyFinishReset
// The new buddy is saved: the old one's mail is moved to it (the mails,
// their items' records and the items' keeper), then the old character is
// deleted for good. Both are out of the world: the old since its reset, the
// new not yet logged in.
void BuddyFinishReset(uint32 oldGuid, uint32 newGuid, uint32 account)
{
    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    trans->Append("UPDATE item_instance ii JOIN mail_items mi ON mi.item_guid = ii.guid SET ii.owner_guid = {} WHERE mi.receiver = {}",
        newGuid, oldGuid);
    trans->Append("UPDATE mail_items SET receiver = {} WHERE receiver = {}", newGuid, oldGuid);
    trans->Append("UPDATE mail SET receiver = {} WHERE receiver = {}", newGuid, oldGuid);
    CharacterDatabase.CommitTransaction(trans);
    Player::DeleteFromDB(oldGuid, account, true, true);
    LOG_INFO("module", "mod-buddies: reset finished: buddy {} made, its old self {} deleted, its mail handed on", newGuid, oldGuid);
}
// }}}

// {{{ .buddy reset
class buddies_reset_command : public CommandScript
{
public:
    buddies_reset_command() : CommandScript("buddies_reset_command") { }

    ChatCommandTable GetCommands() const override
    {
        // multi-word names join the ".buddy" table the beds file starts
        static ChatCommandTable commandTable =
        {
            { "buddy reset", HandleReset, SEC_GAMEMASTER, Console::Yes },
        };
        return commandTable;
    }

    // ".buddy reset <buddy name>". Each refusal, and why:
    //   no such buddy           - the name is no buddy on any roster
    //   not in the world        - its belongings can only be mailed while it
    //                             is in (its owner online, the buddy with them)
    //   a reset already waiting - the slot is owed already
    static bool HandleReset(ChatHandler* handler, std::string name)
    {
        // the name as the game keeps names (first letter capital), then
        // escaped for the query
        if (!normalizePlayerName(name))
        {
            handler->PSendSysMessage("\"{}\" is not a character name.", name);
            return false;
        }
        CharacterDatabase.EscapeString(name);
        QueryResult row = CharacterDatabase.Query(
            "SELECT r.owner, r.slot, c.guid, c.race, c.gender, c.account FROM characters c "
            "JOIN buddy_roster r ON r.buddy = c.guid WHERE c.name = '{}'", name);
        if (!row)
        {
            handler->PSendSysMessage("No buddy is named {}.", name);
            return false;
        }
        uint32 owner  = (*row)[0].Get<uint32>();
        uint8  slot   = (*row)[1].Get<uint8>();
        uint32 guid   = (*row)[2].Get<uint32>();
        uint8  race   = (*row)[3].Get<uint8>();
        uint8  gender = (*row)[4].Get<uint8>();
        Player* bot = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid));
        if (!bot || !bot->IsInWorld())
        {
            handler->PSendSysMessage("{} is not in the world: its belongings can only be kept for it while it is (its owner online, "
                "it beside them). Nothing was changed.", name);
            return false;
        }

        // now: its belongings mailed to itself, out of the world, its name freed
        uint32 items = BuddyMailOldGear(bot);
        sRandomPlayerbotMgr.LogoutPlayerBot(ObjectGuid::Create<HighGuid::Player>(guid));
        std::string placeholder = "Reset" + std::to_string(guid);
        CharacterDatabase.DirectExecute("UPDATE characters SET name = '{}' WHERE guid = {}", placeholder, guid);
        sCharacterCache->UpdateCharacterData(ObjectGuid::Create<HighGuid::Player>(guid), placeholder);
        // the slot owed again, its race kept, the name and gender waiting
        CharacterDatabase.DirectExecute("UPDATE buddy_roster SET buddy = 0, class = 0, profile = 0, role = 0, stage = 0, "
            "reset_name = '{}', reset_gender = {}, reset_from = {} WHERE owner = {} AND slot = {}",
            name, uint32(gender), guid, owner, uint32(slot));
        LOG_INFO("module", "mod-buddies: {} reset by {}: {} items and its money kept for it; owner {}'s slot {} owed again, race {}",
            name, handler->GetNameLink(), items, owner, uint32(slot), uint32(race));
        handler->PSendSysMessage("{} is reset: {} items and its money kept for it by mail. Its owner chooses its new class at Sargobras "
            "(only the classes its race can play); it comes back with the same name and looks.", name, items);
        return true;
    }
};
// }}}

// {{{ AddSC_buddies_reset
void AddSC_buddies_reset()
{
    new buddies_reset_command();
}
// }}}
