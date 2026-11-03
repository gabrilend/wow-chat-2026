
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

class buddies_reset_command : public CommandScript
{
public:
    buddies_reset_command() : CommandScript("buddies_reset_command") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "buddy reset", HandleReset, SEC_GAMEMASTER, Console::Yes },
        };
        return commandTable;
    }

    static bool HandleReset(ChatHandler* handler, std::string name)
    {
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

        uint32 items = BuddyMailOldGear(bot);
        sRandomPlayerbotMgr.LogoutPlayerBot(ObjectGuid::Create<HighGuid::Player>(guid));
        std::string placeholder = "Reset" + std::to_string(guid);
        CharacterDatabase.DirectExecute("UPDATE characters SET name = '{}' WHERE guid = {}", placeholder, guid);
        sCharacterCache->UpdateCharacterData(ObjectGuid::Create<HighGuid::Player>(guid), placeholder);
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

void AddSC_buddies_reset()
{
    new buddies_reset_command();
}
