/*
 * buddies_kit.cpp - what a new buddy carries when it is made (issue 617a4).
 *
 * For a general audience: the owner's decision (2026-09-25): a buddy comes
 * "clad in all white quality gear. They have their level in silver, except
 * at level 1 they have none. They have the same number of bag slots as the
 * player they spawn with, choosing the lowest quality bags to match that
 * number, spread evenly as possible." And (2026-09-27): "they need real
 * food", so it also carries food, and drink if it uses mana.
 *
 * Everything is chosen from the world database when the buddy is made, not
 * from a hand-written list, and only from what some vendor sells, so a
 * buddy never carries an item a player couldn't get:
 *   gear   from the gearset profile "buddy-white" (issue 617r2): the
 *          record for its class and talent shape at the highest level at or
 *          below its own, read from the world database's gearset_item table
 *          (install step E052, written from
 *          src/lua-basic/data/gearsets/buddy-white.lua). Until 2026-10-05 the
 *          gear was chosen live here (white vendor items of its last five
 *          levels, heaviest armour, weapons by the plan); those rules now
 *          live in scripts/translate-buddy-kit-to-gearset, which wrote the
 *          profile, so the gear can be looked at and changed in one file
 *          (owner, 2026-10-05). A level-1 buddy has no record and keeps the
 *          game's own starting outfit (2026-10-03)
 *   food   the best food, and for mana users the best drink, it can eat at
 *          its level, MEALS of each
 *   money  level x 1 silver, none at level 1
 *   bags   the owner's bag slots (the backpack's 16 aside), split by
 *          buddies_kit_split.h over the lowest-quality bag of each size
 */

#include "buddies.h"
#include "buddies_kit.h"
#include "buddies_loot.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "ObjectAccessor.h"
#include "ScriptMgr.h"
#include "WorldSession.h"
#include "buddies_kit_split.h"
#include "DatabaseEnv.h"
#include "Item.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "QueryResult.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include <algorithm>
#include <map>
#include <vector>
#include <set>
#include <string>

using namespace Acore::ChatCommands;

// {{{ tuning
static char const* const KIT_GEARSET = "buddy-white";   // the gearset profile new buddies wear (617r2)
static constexpr uint32 GEARSET_SLOTS = EQUIPMENT_SLOT_END; // gearset_item slots 0-18 are equipment; 100+ bags, 200 ammo
static constexpr uint32 MEALS = 5;    // servings of food, and of drink, in the kit: a few, so it has something to buy (the owner, 2026-09-28)
// }}}

// {{{ GiveGear
// The buddy's record in the "buddy-white" gearset: shape key = class x 100
// + its talent shape (1-10, buddy_roster.profile), and the record of the
// highest level at or below its own (the profile's second key is a level).
// Each item is equipped in its slot, replacing the stock (or an earlier
// kit's) item. Nothing found is a problem named in full, never filled
// with something close (the owner's rule: no fallbacks).
static bool Wear(Player* buddy, uint8 slot, uint32 entry)
{
    if (buddy->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
        buddy->DestroyItem(INVENTORY_SLOT_BAG_0, slot, true);   // the stock (or an earlier kit's) item goes
    uint16 dest;
    if (buddy->CanEquipNewItem(slot, dest, entry, false) != EQUIP_ERR_OK)
        return false;
    buddy->EquipNewItem(dest, entry, true);
    return true;
}
static uint32 GiveGear(Player* buddy, uint8 shape, std::string& problems)
{
    if (buddy->GetLevel() <= 1)
        return 0;                                       // the stock starting outfit stays on
    if (shape < 1 || shape > 10)
    {
        problems += "no talent shape (buddy_roster.profile " + std::to_string(shape) + ") to look up its gear by; ";
        return 0;
    }
    uint32 key = uint32(buddy->getClass()) * 100 + shape;
    QueryResult rows = WorldDatabase.Query(
        "SELECT slot, item FROM gearset_item WHERE profile = '{}' AND key1 = {} AND slot < {} AND key2 = "
        "(SELECT MAX(key2) FROM gearset_item WHERE profile = '{}' AND key1 = {} AND key2 <= {}) ORDER BY slot",
        KIT_GEARSET, key, GEARSET_SLOTS, KIT_GEARSET, key, buddy->GetLevel());
    if (!rows)
    {
        problems += "no " + std::string(KIT_GEARSET) + " record for shape key " + std::to_string(key) + " at or below level "
            + std::to_string(buddy->GetLevel()) + " (is install step E052 applied? does the profile have it?); ";
        return 0;
    }
    uint32 worn = 0;
    do
    {
        uint8 slot = (*rows)[0].Get<uint16>();
        uint32 item = (*rows)[1].Get<uint32>();
        if (Wear(buddy, slot, item))
            ++worn;
        else
            problems += "slot " + std::to_string(slot) + " refused item " + std::to_string(item) + "; ";
    } while (rows->NextRow());
    return worn;
}
// }}}
// {{{ GiveMeals
// The best food (health regeneration) and, for mana users, the best drink
// (mana regeneration) a vendor sells that the buddy can use at its level.
static void GiveMeals(Player* buddy, std::string& problems)
{
    QueryResult rows = WorldDatabase.Query(
        "SELECT DISTINCT it.entry, it.RequiredLevel, it.ItemLevel FROM item_template it JOIN npc_vendor v ON v.item = it.entry "
        "WHERE it.class = 0 AND it.subclass = 5 AND it.RequiredLevel <= {} "
        "ORDER BY it.RequiredLevel DESC, it.ItemLevel DESC, it.entry", buddy->GetLevel());
    bool wantDrink = buddy->getPowerType() == POWER_MANA;
    uint32 food = 0, drink = 0;
    if (rows)
        do
        {
            uint32 entry = (*rows)[0].Get<uint32>();
            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(entry);
            if (!proto || buddy->CanUseItem(proto) != EQUIP_ERR_OK)
                continue;
            SpellInfo const* spell = sSpellMgr->GetSpellInfo(uint32(proto->Spells[0].SpellId));
            if (!spell)
                continue;
            if (!food && spell->HasAura(SPELL_AURA_MOD_REGEN))
                food = entry;
            if (wantDrink && !drink && spell->HasAura(SPELL_AURA_MOD_POWER_REGEN))
                drink = entry;
        } while ((!food || (wantDrink && !drink)) && rows->NextRow());
    if (!food)
        problems += "no food found at vendors for its level; ";
    else if (!buddy->StoreNewItemInBestSlots(food, MEALS))
        problems += "no room for its food; ";
    if (wantDrink)
    {
        if (!drink)
            problems += "no drink found at vendors for its level; ";
        else if (!buddy->StoreNewItemInBestSlots(drink, MEALS))
            problems += "no room for its drink; ";
    }
}
// }}}

// {{{ GiveBags
// The owner's bag slots, read from the owner's equipped bags in the
// characters database (the owner may be offline), split over the
// lowest-quality vendor bag of each size.
static void GiveBags(Player* buddy, uint32 ownerGuid, std::string& problems)
{
    uint32 total = 0;
    if (QueryResult owned = CharacterDatabase.Query(
            "SELECT ii.itemEntry FROM character_inventory ci JOIN item_instance ii ON ii.guid = ci.item "
            "WHERE ci.guid = {} AND ci.bag = 0 AND ci.slot BETWEEN {} AND {}",
            ownerGuid, uint32(INVENTORY_SLOT_BAG_START), uint32(INVENTORY_SLOT_BAG_END - 1)))
        do
            if (ItemTemplate const* proto = sObjectMgr->GetItemTemplate((*owned)[0].Get<uint32>()))
                total += proto->ContainerSlots;
        while (owned->NextRow());
    if (!total)
        return;                                         // the owner carries only the backpack

    std::map<uint32, uint32> bagOfSize;                 // slots -> the lowest-quality bag of that size
    if (QueryResult bags = WorldDatabase.Query(
            "SELECT DISTINCT it.entry, it.ContainerSlots, it.Quality, it.ItemLevel FROM item_template it JOIN npc_vendor v ON v.item = it.entry "
            "WHERE it.class = 1 AND it.subclass = 0 AND it.ContainerSlots > 0 "
            "ORDER BY it.Quality ASC, it.ItemLevel ASC, it.entry"))
        do
            bagOfSize.emplace((*bags)[1].Get<uint32>(), (*bags)[0].Get<uint32>());   // first seen = lowest quality
        while (bags->NextRow());
    std::vector<uint32_t> sizes;
    for (auto const& s : bagOfSize) sizes.push_back(s.first);

    std::vector<uint32_t> split = BuddyKit::SplitBagSlots(total, sizes);
    uint8 slot = INVENTORY_SLOT_BAG_START;
    for (uint32_t size : split)
    {
        uint16 dest;
        uint32 entry = bagOfSize[size];
        if (buddy->CanEquipNewItem(slot, dest, entry, false) != EQUIP_ERR_OK)
        {
            problems += "could not put a " + std::to_string(size) + "-slot bag on; ";
            continue;
        }
        buddy->EquipNewItem(dest, entry, true);
        ++slot;
    }
}
// }}}

// {{{ BuddyGiveStartingKit
std::string BuddyGiveStartingKit(Player* buddy, uint32 ownerGuid, uint8 shape)
{
    std::string problems;
    GiveBags(buddy, ownerGuid, problems);               // bags first, so the meals have room
    uint32 worn = GiveGear(buddy, shape, problems);
    GiveMeals(buddy, problems);
    if (buddy->GetLevel() > 1)
        buddy->ModifyMoney(int32(buddy->GetLevel()) * 100);   // level x 1 silver
    // a level-1 buddy wears its stock starting outfit by design (GiveGear);
    // above that, nothing chosen is a problem worth logging
    if (!worn && buddy->GetLevel() > 1)
        problems += "wears nothing chosen for it; ";
    return problems;
}
// }}}

// {{{ BuddyRegear and ".buddy kit <name>"
std::string BuddyRegear(Player* buddy, uint8 shape)
{
    std::string problems;
    GiveGear(buddy, shape, problems);
    return problems;
}

// ".buddy kit <buddy name>": a buddy in the world is given the kit's gear
// for its level now, by its talent shape (the owner, 2026-10-03, after
// levelling Feldowinn's buddy Matis to 46 for Zul'Farrak: "My buddybot
// Mathis will need gear and abilities too"). What it wore is replaced.
class buddies_kit_command : public CommandScript
{
public:
    buddies_kit_command() : CommandScript("buddies_kit_command") { }

    ChatCommandTable GetCommands() const override
    {
        // multi-word names join the ".buddy" table the beds file starts
        static ChatCommandTable commandTable =
        {
            { "buddy kit", HandleKit, SEC_GAMEMASTER, Console::Yes },
        };
        return commandTable;
    }

    static bool HandleKit(ChatHandler* handler, std::string name)
    {
        if (!normalizePlayerName(name))
        {
            handler->PSendSysMessage("Usage: .buddy kit <buddy name>");
            return false;
        }
        Player* buddy = ObjectAccessor::FindPlayerByName(name, true);
        if (!buddy || !BuddyIsCompanionAccount(buddy->GetSession()->GetAccountId()))
        {
            handler->PSendSysMessage("{} is not a buddy in the world (a buddy is in the world while its owner is online).", name);
            return false;
        }
        QueryResult row = CharacterDatabase.Query("SELECT profile FROM buddy_roster WHERE buddy = {}", buddy->GetGUID().GetCounter());
        uint8 shape = row ? (*row)[0].Get<uint8>() : 0;
        std::string problems = BuddyRegear(buddy, shape);
        handler->PSendSysMessage("{} (level {}) re-kitted from {} by its talent shape {}{}{}", name, buddy->GetLevel(), KIT_GEARSET,
            uint32(shape), problems.empty() ? "" : "; ", problems);
        return true;
    }
};

void AddSC_buddies_kit()
{
    new buddies_kit_command();
}
// }}}
