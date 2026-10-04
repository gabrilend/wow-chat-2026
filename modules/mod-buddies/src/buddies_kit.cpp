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
 *          highest required level that it can use (the game's own check:
 *          armour type, weapon skill, class, race), from the buddy's last
 *          five levels and never from required level 0 or 1; a level-1
 *          buddy keeps the game's own starting outfit (2026-10-03)
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
#include "buddies_kit_tiers.h"
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
static constexpr uint8  KIT_TIER_SPAN = 10;  // a gear tier is worn for this many levels from its own
static constexpr uint8  KIT_WINDOW_LEVELS = 5;  // vendor gear is chosen from this many levels, the buddy's own included (the owner, 2026-10-03)
static constexpr uint8  KIT_LOWEST_LEVEL  = 2;  // never required level 0 or 1: fishing poles, cosmetics, holiday items (the owner, 2026-10-03)
static constexpr uint32 MEALS = 5;    // servings of food, and of drink, in the kit: a few, so it has something to buy (the owner, 2026-09-28)
// }}}

// {{{ the weapons a plan wants (2026-10-03)
// The owner, 2026-10-03, on level-40 buddies: "none of them have weapons.
// They should have weapons appropriate to the talent set they were
// assigned at their creation." A kind of weapon, by what the game says
// about the item, and for each class and main talent tree (trees in the
// talent window's order) the kinds for the main hand, the off hand and
// the ranged slot, most wanted first. A two-hander in the main hand leaves
// the off hand empty; an off-hand weapon needs dual wield, which the game
// checks (a buddy without it takes the next kind).
enum Kind : uint8 { K_NONE, K_TWO_HAND, K_ONE_HAND, K_OFF_ONE, K_DAGGER, K_STAFF, K_SHIELD, K_HELD, K_SHOOTER, K_WAND };

static bool IsKind(ItemTemplate const* p, Kind k)
{
    bool weapon = p->Class == ITEM_CLASS_WEAPON;
    switch (k)
    {
        case K_TWO_HAND: return weapon && p->InventoryType == INVTYPE_2HWEAPON;
        case K_ONE_HAND: return weapon && (p->InventoryType == INVTYPE_WEAPON || p->InventoryType == INVTYPE_WEAPONMAINHAND);
        case K_OFF_ONE:  return weapon && (p->InventoryType == INVTYPE_WEAPON || p->InventoryType == INVTYPE_WEAPONOFFHAND);
        case K_DAGGER:   return weapon && p->SubClass == ITEM_SUBCLASS_WEAPON_DAGGER;
        case K_STAFF:    return weapon && p->SubClass == ITEM_SUBCLASS_WEAPON_STAFF;
        case K_SHIELD:   return p->Class == ITEM_CLASS_ARMOR && p->SubClass == ITEM_SUBCLASS_ARMOR_SHIELD;
        case K_HELD:     return p->InventoryType == INVTYPE_HOLDABLE;
        case K_SHOOTER:  return weapon && (p->SubClass == ITEM_SUBCLASS_WEAPON_BOW || p->SubClass == ITEM_SUBCLASS_WEAPON_GUN
                                           || p->SubClass == ITEM_SUBCLASS_WEAPON_CROSSBOW);
        case K_WAND:     return weapon && p->SubClass == ITEM_SUBCLASS_WEAPON_WAND;
        default:         return false;
    }
}

struct Wants { Kind main[2]; Kind off[2]; Kind ranged; };
// [class][main tree]; classes by id (0 and 10 unused)
static Wants const WANTS[12][3] = {
    {},
    { { { K_TWO_HAND, K_ONE_HAND }, { K_NONE, K_NONE },   K_SHOOTER },     // warrior: arms
      { { K_ONE_HAND, K_TWO_HAND }, { K_OFF_ONE, K_NONE }, K_SHOOTER },    //          fury
      { { K_ONE_HAND, K_NONE },     { K_SHIELD, K_NONE },  K_SHOOTER } },  //          protection
    { { { K_ONE_HAND, K_NONE },     { K_SHIELD, K_HELD },  K_NONE },       // paladin: holy
      { { K_ONE_HAND, K_NONE },     { K_SHIELD, K_NONE },  K_NONE },       //          protection
      { { K_TWO_HAND, K_ONE_HAND }, { K_NONE, K_NONE },    K_NONE } },     //          retribution
    { { { K_TWO_HAND, K_ONE_HAND }, { K_NONE, K_NONE },    K_SHOOTER },    // hunter: all three
      { { K_TWO_HAND, K_ONE_HAND }, { K_NONE, K_NONE },    K_SHOOTER },
      { { K_TWO_HAND, K_ONE_HAND }, { K_NONE, K_NONE },    K_SHOOTER } },
    { { { K_DAGGER, K_ONE_HAND },   { K_DAGGER, K_OFF_ONE }, K_SHOOTER },  // rogue: assassination
      { { K_ONE_HAND, K_DAGGER },   { K_OFF_ONE, K_DAGGER }, K_SHOOTER },  //        combat
      { { K_DAGGER, K_ONE_HAND },   { K_DAGGER, K_OFF_ONE }, K_SHOOTER } },//        subtlety
    { { { K_STAFF, K_ONE_HAND },    { K_HELD, K_NONE },    K_WAND },       // priest: all three
      { { K_STAFF, K_ONE_HAND },    { K_HELD, K_NONE },    K_WAND },
      { { K_STAFF, K_ONE_HAND },    { K_HELD, K_NONE },    K_WAND } },
    { { { K_TWO_HAND, K_NONE },     { K_NONE, K_NONE },    K_NONE },       // death knight: blood
      { { K_ONE_HAND, K_TWO_HAND }, { K_OFF_ONE, K_NONE }, K_NONE },       //               frost
      { { K_TWO_HAND, K_NONE },     { K_NONE, K_NONE },    K_NONE } },     //               unholy
    { { { K_ONE_HAND, K_NONE },     { K_SHIELD, K_HELD },  K_NONE },       // shaman: elemental
      { { K_ONE_HAND, K_TWO_HAND }, { K_OFF_ONE, K_SHIELD }, K_NONE },     //         enhancement
      { { K_ONE_HAND, K_NONE },     { K_SHIELD, K_HELD },  K_NONE } },     //         restoration
    { { { K_STAFF, K_ONE_HAND },    { K_HELD, K_NONE },    K_WAND },       // mage: all three
      { { K_STAFF, K_ONE_HAND },    { K_HELD, K_NONE },    K_WAND },
      { { K_STAFF, K_ONE_HAND },    { K_HELD, K_NONE },    K_WAND } },
    { { { K_STAFF, K_ONE_HAND },    { K_HELD, K_NONE },    K_WAND },       // warlock: all three
      { { K_STAFF, K_ONE_HAND },    { K_HELD, K_NONE },    K_WAND },
      { { K_STAFF, K_ONE_HAND },    { K_HELD, K_NONE },    K_WAND } },
    {},
    { { { K_STAFF, K_ONE_HAND },    { K_HELD, K_NONE },    K_NONE },       // druid: balance
      { { K_TWO_HAND, K_STAFF },    { K_NONE, K_NONE },    K_NONE },       //        feral
      { { K_STAFF, K_ONE_HAND },    { K_HELD, K_NONE },    K_NONE } },     //        restoration
};

static bool IsHandItem(ItemTemplate const* p)
{
    return p->Class == ITEM_CLASS_WEAPON || IsKind(p, K_SHIELD) || IsKind(p, K_HELD);
}
// }}}

// {{{ GiveGear
// Candidates: white armour and weapons some vendor sells, the best of the
// last KIT_WINDOW_LEVELS levels up to the buddy's own first; a slot with
// nothing there is filled from lower levels (never required level 0 or 1).
//
// Why a window, and why never required level 0 or 1 (the owner,
// 2026-10-03): with no lower bound a level-1 buddy took a fishing pole
// (a white vendor "weapon" with no level requirement) as its weapon, and
// the no-requirement shelf is full of cosmetic and holiday items. A level-1
// buddy is given nothing here at all: it keeps the starting outfit the game
// dressed it in at creation, the same a new player of its race and class
// wears.
//
// Armour: the heaviest kind the buddy can wear first (plate before mail
// before leather before cloth), then the higher level: seen 2026-10-03,
// level-40 paladins in mail with a cloth hat (ties broken by item number,
// and plate not yet learned when the kit ran; creation now teaches first).
// Below the window: a slot that would otherwise stay empty, the cloak and
// the weapons most of all ("Can we make sure they have cloaks as well?").
// Weapons: by the plan's main tree (WANTS).
struct Candidate { ItemTemplate const* proto; uint32 req; uint32 ilvl; };

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

static uint32 GiveGear(Player* buddy, int8 mainTree, std::string& problems)
{
    if (buddy->GetLevel() <= 1)
        return 0;                                       // the stock starting outfit stays on
    uint32 lowest = std::max<int32>(KIT_LOWEST_LEVEL, int32(buddy->GetLevel()) - int32(KIT_WINDOW_LEVELS - 1));
    QueryResult rows = WorldDatabase.Query(
        "SELECT DISTINCT it.entry, it.RequiredLevel, it.ItemLevel FROM item_template it JOIN npc_vendor v ON v.item = it.entry "
        "WHERE it.Quality = 1 AND it.class IN (2, 4) AND it.RequiredLevel BETWEEN {} AND {}", KIT_LOWEST_LEVEL, buddy->GetLevel());
    if (!rows)
    {
        problems += "no white gear found at vendors; ";
        return 0;
    }
    std::vector<Candidate> all;
    do
        if (ItemTemplate const* proto = sObjectMgr->GetItemTemplate((*rows)[0].Get<uint32>()))
            if (buddy->CanUseItem(proto) == EQUIP_ERR_OK)  // armour kind, weapon skill, class, race
                all.push_back({ proto, (*rows)[1].Get<uint32>(), (*rows)[2].Get<uint32>() });
    while (rows->NextRow());
    // the window first, then heavier armour, then higher level and item level
    std::sort(all.begin(), all.end(), [lowest](Candidate const& a, Candidate const& b) {
        bool wa = a.req >= lowest, wb = b.req >= lowest;
        if (wa != wb) return wa;
        uint32 ha = a.proto->Class == ITEM_CLASS_ARMOR ? a.proto->SubClass : 0;
        uint32 hb = b.proto->Class == ITEM_CLASS_ARMOR ? b.proto->SubClass : 0;
        if (ha != hb && a.proto->InventoryType == b.proto->InventoryType) return ha > hb;
        if (a.req != b.req) return a.req > b.req;
        if (a.ilvl != b.ilvl) return a.ilvl > b.ilvl;
        return a.proto->ItemId < b.proto->ItemId;
    });
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
            if (slot != NULL_SLOT && !filled.count(slot) && Wear(buddy, slot, k.item))
            {
                filled.insert(slot);
                ++worn;
                continue;
            }
            // not worn (not gear, or a second of a slot already filled): carried
            if (!buddy->StoreNewItemInBestSlots(k.item, k.amount))
                problems += "no room for tier item " + std::to_string(k.item) + "; ";
        }

    // armour: every slot still empty, best first
    for (Candidate const& c : all)
    {
        if (IsHandItem(c.proto))
            continue;                                   // the hands are chosen by the plan, below
        uint8 slot = buddy->FindEquipSlot(c.proto, NULL_SLOT, true);
        if (slot == NULL_SLOT || filled.count(slot))
            continue;
        if (Wear(buddy, slot, c.proto->ItemId))
        {
            filled.insert(slot);
            ++worn;
        }
    }

    // weapons: the plan's kinds, main hand, then off hand, then ranged
    uint8 cls = buddy->getClass();
    if (cls < 12 && mainTree >= 0 && mainTree < 3)
    {
        Wants const& w = WANTS[cls][mainTree];
        auto take = [&](uint8 slot, Kind kind) -> ItemTemplate const* {
            if (kind == K_NONE || filled.count(slot))
                return nullptr;
            for (Candidate const& c : all)
                if (IsKind(c.proto, kind) && Wear(buddy, slot, c.proto->ItemId))
                {
                    filled.insert(slot);
                    ++worn;
                    return c.proto;
                }
            return nullptr;
        };
        ItemTemplate const* main = nullptr;
        for (Kind k : w.main)
            if (!main)
                main = take(EQUIPMENT_SLOT_MAINHAND, k);
        if (!main)
            problems += "no main-hand weapon for its plan; ";
        if (!main || main->InventoryType != INVTYPE_2HWEAPON)
            for (Kind k : w.off)
                if (!filled.count(EQUIPMENT_SLOT_OFFHAND))
                    take(EQUIPMENT_SLOT_OFFHAND, k);
        take(EQUIPMENT_SLOT_RANGED, w.ranged);
    }
    else
        problems += "no talent plan to choose weapons by; ";
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
std::string BuddyGiveStartingKit(Player* buddy, uint32 ownerGuid, int8 mainTree)
{
    std::string problems;
    GiveBags(buddy, ownerGuid, problems);               // bags first, so the meals have room
    uint32 worn = GiveGear(buddy, mainTree, problems);
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
std::string BuddyRegear(Player* buddy, int8 mainTree)
{
    std::string problems;
    GiveGear(buddy, mainTree, problems);
    return problems;
}

// ".buddy kit <buddy name>": a buddy in the world is given the kit's gear
// for its level now, by its talent plan (the owner, 2026-10-03, after
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
        int8 tree = row ? BuddyPlanMainTree((*row)[0].Get<uint8>()) : int8(-1);
        std::string problems = BuddyRegear(buddy, tree);
        handler->PSendSysMessage("{} (level {}) re-kitted by its plan's main tree {}{}{}", name, buddy->GetLevel(), int32(tree) + 1,
            problems.empty() ? "" : "; ", problems);
        return true;
    }
};

void AddSC_buddies_kit()
{
    new buddies_kit_command();
}
// }}}
