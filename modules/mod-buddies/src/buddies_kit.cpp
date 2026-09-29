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
 *   gear   within a tier's ten levels (20 to 29 so far), the hand-chosen
 *          kit for its race and class (buddies_kit_tiers.h, generated from the
 *          vanilla profile's level-20 kit; the owner, 2026-09-28: "for the
 *          level 20 list, can you use the one we made for the starting gear
 *          in a different profile? Eventually we'll manually create each of
 *          the tiers."); every slot a tier leaves empty, and every slot
 *          below the first tier, gets the white (common) item of the
 *          highest required level at or below the buddy's that it can use
 *          (the game's own check: armour type, weapon skill, class, race)
 *   food   the best food, and for mana users the best drink, it can eat at
 *          its level, MEALS of each
 *   money  level x 1 silver, none at level 1
 *   bags   the owner's bag slots (the backpack's 16 aside), split by
 *          buddies_kit_split.h over the lowest-quality bag of each size
 */

#include "buddies_kit.h"
#include "buddies_kit_split.h"
#include "buddies_kit_tiers.h"
#include "DatabaseEnv.h"
#include "Item.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "QueryResult.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include <map>
#include <set>
#include <string>

// {{{ tuning
static constexpr uint8  KIT_TIER_SPAN = 10;  // a gear tier is worn for this many levels from its own
static constexpr uint32 MEALS = 5;    // servings of food, and of drink, in the kit: a few, so it has something to buy (the owner, 2026-09-28)
// }}}

// {{{ GiveGear
// Candidates: white armour and weapons some vendor sells, at or below the
// buddy's level, best first. Each goes to the slot the game would put it in;
// the first usable item for a slot wins, replacing the stock starting item.
static uint32 GiveGear(Player* buddy, std::string& problems)
{
    QueryResult rows = WorldDatabase.Query(
        "SELECT DISTINCT it.entry, it.RequiredLevel, it.ItemLevel FROM item_template it JOIN npc_vendor v ON v.item = it.entry "
        "WHERE it.Quality = 1 AND it.class IN (2, 4) AND it.RequiredLevel <= {} "
        "ORDER BY it.RequiredLevel DESC, it.ItemLevel DESC, it.entry", buddy->GetLevel());
    if (!rows)
    {
        problems += "no white gear found at vendors; ";
        return 0;
    }
    std::set<uint8> filled;
    uint32 worn = 0;

    // the tier's kit first, but only within its own ten levels: a kit is
    // chosen for characters of that level (the owner, 2026-09-28: "They
    // were just chosen for level 20 characters... Then for 30 and up we can
    // use the proposed system, where we select the one below"), so tier 20
    // is worn at 20 to 29, and every other level takes the vendor rule below
    uint8 tier = 0;
    for (BuddyKitTierItem const& k : sBuddyKitTiers)
        if (buddy->GetLevel() >= k.level && buddy->GetLevel() < k.level + KIT_TIER_SPAN)
            tier = k.level;
    if (tier)
        for (BuddyKitTierItem const& k : sBuddyKitTiers)
        {
            if (k.level != tier || k.race != buddy->getRace() || k.cls != buddy->getClass())
                continue;
            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(k.item);
            if (!proto)
            {
                problems += "tier " + std::to_string(tier) + " item " + std::to_string(k.item) + " is not in the world database; ";
                continue;
            }
            uint8 slot = buddy->FindEquipSlot(proto, NULL_SLOT, true);
            uint16 dest;
            if (slot != NULL_SLOT && !filled.count(slot))
            {
                if (buddy->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                    buddy->DestroyItem(INVENTORY_SLOT_BAG_0, slot, true);
                if (buddy->CanEquipNewItem(slot, dest, k.item, false) == EQUIP_ERR_OK)
                {
                    buddy->EquipNewItem(dest, k.item, true);
                    filled.insert(slot);
                    ++worn;
                    continue;
                }
            }
            // not worn (not gear, or a second of a slot already filled): carried
            if (!buddy->StoreNewItemInBestSlots(k.item, k.amount))
                problems += "no room for tier item " + std::to_string(k.item) + "; ";
        }

    // then every slot still empty, from what vendors sell
    do
    {
        uint32 entry = (*rows)[0].Get<uint32>();
        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(entry);
        if (!proto || buddy->CanUseItem(proto) != EQUIP_ERR_OK)
            continue;                                   // wrong armour, weapon skill, class or race
        uint8 slot = buddy->FindEquipSlot(proto, NULL_SLOT, true);
        if (slot == NULL_SLOT || filled.count(slot))
            continue;                                   // not wearable, or a better one is already on
        if (buddy->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            buddy->DestroyItem(INVENTORY_SLOT_BAG_0, slot, true);   // the stock starting item goes
        uint16 dest;
        if (buddy->CanEquipNewItem(slot, dest, entry, false) != EQUIP_ERR_OK)
            continue;                                   // e.g. an off hand while a two-hander is on
        buddy->EquipNewItem(dest, entry, true);
        filled.insert(slot);
        ++worn;
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
std::string BuddyGiveStartingKit(Player* buddy, uint32 ownerGuid)
{
    std::string problems;
    GiveBags(buddy, ownerGuid, problems);               // bags first, so the meals have room
    uint32 worn = GiveGear(buddy, problems);
    GiveMeals(buddy, problems);
    if (buddy->GetLevel() > 1)
        buddy->ModifyMoney(int32(buddy->GetLevel()) * 100);   // level x 1 silver
    if (!worn)
        problems += "wears nothing chosen for it; ";
    return problems;
}
// }}}
