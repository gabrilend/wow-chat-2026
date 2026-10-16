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
 *   gear   from the gearset profile "buddy-white-<tier>" (issue 617r2): the
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
#include "buddies_spells.h"
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
#include "DBCStores.h"
#include "ReputationMgr.h"
#include "StatsWeightCalculator.h"
#include <algorithm>
#include <map>
#include <vector>
#include <set>
#include <string>

using namespace Acore::ChatCommands;

// {{{ tuning
// the gearset profiles new buddies wear (617r2): one per ten-level tier,
// "buddy-white-1" for levels 2-9, then "buddy-white-10", "-20" ... (the
// owner, 2026-10-05: "we're going to have one for each level tier")
static std::string KitGearset(uint8 level)
{
    return "buddy-white-" + std::to_string(level < 10 ? 1 : level / 10 * 10);
}
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
// Whether it can use the item (skill, level, class) is asked before the
// old item is destroyed: until 2026-10-15 the old one went first, so a
// refused weapon left empty hands, and the only weapon left in its bags,
// its fishing pole, was what the bot module then equipped (Montahmu, in
// Uldaman). A refusal now keeps what it wore. Returns the server's answer
// (EQUIP_ERR_OK when worn), for the caller to name in its problem line.
static InventoryResult Wear(Player* buddy, uint8 slot, uint32 entry)
{
    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(entry);
    if (!proto)
        return EQUIP_ERR_ITEM_NOT_FOUND;
    if (InventoryResult use = buddy->CanUseItem(proto); use != EQUIP_ERR_OK)
        return use;                                     // can't use it: the old item stays on
    if (buddy->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
        buddy->DestroyItem(INVENTORY_SLOT_BAG_0, slot, true);   // the stock (or an earlier kit's) item goes
    uint16 dest;
    if (InventoryResult equip = buddy->CanEquipNewItem(slot, dest, entry, false); equip != EQUIP_ERR_OK)
        return equip;
    buddy->EquipNewItem(dest, entry, true);
    return EQUIP_ERR_OK;
}
// The weapon a buddy is first made with, at each level tier it is made at,
// carries a permanent enchant from level 30, one of these four at random
// (owner, 2026-10-15: "totally random. this is a buff to melee combat";
// Crusader is "too strong"; and "only when they are instantiated for the
// first time. Their starting gear weapon, for each of their level tiers
// they spawn as, is enchanted ... But only after level 30."). So the
// starting kit enchants, a re-dress (".buddy kit", a stand-in's new level)
// does not. The numbers are SpellItemEnchantment ids, read from the game
// client's data files that day (issue 621). They are melee procs, so a
// caster's staff gets one too: when to swing it is the caster's own lesson
// to learn (622).
static constexpr uint8 ENCHANT_FROM_LEVEL = 30;   // owner, 2026-10-15: "above level 29, 30 and up"
static constexpr uint32 KIT_ENCHANTS[] = {
     803,   // Fiery Weapon:  now and then burns the target
    1894,   // Icy Chill:     now and then slows the target
    1898,   // Lifestealing:  now and then drains the target's life
    1899,   // Unholy Weapon: now and then curses the target's damage
};
static void Enchant(Player* buddy, uint8 slot, std::string& problems)
{
    Item* item = buddy->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
    if (!item || item->GetTemplate()->Class != ITEM_CLASS_WEAPON)
        return;                                         // a shield or held-in-hand item: no weapon enchant
    uint32 id = KIT_ENCHANTS[urand(0, std::size(KIT_ENCHANTS) - 1)];
    if (!sSpellItemEnchantmentStore.LookupEntry(id))
    {
        problems += "enchant " + std::to_string(id) + " is not in the server's SpellItemEnchantment table (are the client's "
            "data files extracted?); ";
        return;
    }
    buddy->ApplyEnchantment(item, PERM_ENCHANTMENT_SLOT, false);   // an earlier one's effects off (none on a new item)
    item->SetEnchantment(PERM_ENCHANTMENT_SLOT, id, 0, 0);
    buddy->ApplyEnchantment(item, PERM_ENCHANTMENT_SLOT, true);
}

// A kit weapon of a kind the buddy lacks is learned first ("That one they
// should know", 617n). `firstMaking`: the starting kit, whose hand weapons
// from ENCHANT_FROM_LEVEL are enchanted.
//
// "Neta, nothing eta" (owner, 2026-10-15: "if we're changing a level 57
// with trinkets to be level 1 and there's no level 1 trinkets, then we
// should say 'neta, nothing eta' because we have no capacity to
// deliver"): a slot whose worn item needs more than the buddy's level, and
// which the record has nothing for, is named as such in the problems. The
// item stays worn (inert until the level returns); nothing is made up to
// take its place.
static uint32 GiveGear(Player* buddy, uint8 shape, bool firstMaking, std::string& problems)
{
    if (buddy->GetLevel() <= 1)
        return 0;                                       // the stock starting outfit stays on
    if (shape < 1 || shape > 10)
    {
        problems += "no talent shape (buddy_roster.profile " + std::to_string(shape) + ") to look up its gear by; ";
        return 0;
    }
    uint32 key = uint32(buddy->getClass()) * 100 + shape;
    std::string const gearset = KitGearset(buddy->GetLevel());
    QueryResult rows = WorldDatabase.Query(
        "SELECT slot, item FROM gearset_item WHERE profile = '{}' AND key1 = {} AND slot < {} AND key2 = "
        "(SELECT MAX(key2) FROM gearset_item WHERE profile = '{}' AND key1 = {} AND key2 <= {}) ORDER BY slot",
        gearset, key, GEARSET_SLOTS, gearset, key, buddy->GetLevel());
    if (!rows)
    {
        problems += "no " + gearset + " record for shape key " + std::to_string(key) + " at or below level "
            + std::to_string(buddy->GetLevel()) + " (is install step E052 applied? does the profile have it?); ";
        return 0;
    }
    uint32 worn = 0;
    bool recordHas[GEARSET_SLOTS] = {};
    do
    {
        uint8 slot = (*rows)[0].Get<uint16>();
        recordHas[slot] = true;
        uint32 item = (*rows)[1].Get<uint32>();
        if (ItemTemplate const* proto = sObjectMgr->GetItemTemplate(item); proto && proto->Class == ITEM_CLASS_WEAPON)
        {
            std::string why;
            if (!BuddyLearnWeaponKind(buddy, proto->GetSkill(), why))
                problems += "slot " + std::to_string(slot) + " item " + std::to_string(item) + ": " + why + "; ";
        }
        // refused: the server's reason number (InventoryResult in
        // Item.h; 8 is "no required proficiency", a weapon kind not known)
        if (InventoryResult r = Wear(buddy, slot, item); r == EQUIP_ERR_OK)
        {
            ++worn;
            if (firstMaking && buddy->GetLevel() >= ENCHANT_FROM_LEVEL &&
                (slot == EQUIPMENT_SLOT_MAINHAND || slot == EQUIPMENT_SLOT_OFFHAND))
                Enchant(buddy, slot, problems);
        }
        else
            problems += "slot " + std::to_string(slot) + " refused item " + std::to_string(item) + " (reason "
                + std::to_string(uint32(r)) + ", what it wore there is kept); ";
    } while (rows->NextRow());
    for (uint8 slot = 0; slot < GEARSET_SLOTS; ++slot)
        if (Item* held = buddy->GetItemByPos(INVENTORY_SLOT_BAG_0, slot); held && !recordHas[slot] &&
            held->GetTemplate()->RequiredLevel > buddy->GetLevel())
            problems += "slot " + std::to_string(slot) + " (" + held->GetTemplate()->Name1 + ", needs level "
                + std::to_string(held->GetTemplate()->RequiredLevel) + "): neta, nothing eta at level "
                + std::to_string(buddy->GetLevel()) + "; ";
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

// {{{ GiveClassTools
// What a class can't fight without, found missing on Felicity's buddies in
// Uldaman, 2026-10-15 (the bot log: the shaman unable to drop a totem, the
// rogue failing to apply a poison forty thousand times, the hunter holding
// level-1 arrows and no bow): the owner wants the group "fully enabled".
//   shaman  the four totem items its totem spells need (3.3.5 asks for
//           them in the bags), each from the level its quest gives it at
//           (Earth 4, Fire 10, Water 20, Air 30: buddies_quest_spells.h)
//   rogue   the best Instant Poison and Deadly Poison a vendor sells for
//           its level (the two the bot module applies), POISON_DOSES each
//   hunter  ammunition that fits its ranged weapon (arrows for a bow or
//           crossbow, bullets for a gun), the best a vendor sells for its
//           level, AMMO_ROUNDS of it, put in use; and a quiver or ammo
//           pouch of the right kind in a free bag slot when it has none
// Only what is missing is given, so it is safe on every kit and re-dress.
// Nothing of its level found, or no room: named, never a near match.
static constexpr uint32 POISON_DOSES = 20;     // one stack of each poison
static constexpr uint32 AMMO_ROUNDS  = 1000;   // five stacks of 200
struct TotemItem { uint8 level; uint32 item; char const* name; };
static constexpr TotemItem SHAMAN_TOTEMS[] = {
    {  4, 5175, "Earth Totem" }, { 10, 5176, "Fire Totem" }, { 20, 5177, "Water Totem" }, { 30, 5178, "Air Totem" },
};

// The best vendor item matching `where` (an SQL condition on item_template
// it) that the buddy's level allows; 0 for none.
static uint32 BestVendorItem(Player* buddy, std::string const& where)
{
    QueryResult row = WorldDatabase.Query(
        "SELECT it.entry FROM item_template it JOIN npc_vendor v ON v.item = it.entry WHERE {} AND it.RequiredLevel <= {} "
        "ORDER BY it.RequiredLevel DESC, it.ItemLevel DESC, it.entry LIMIT 1", where, buddy->GetLevel());
    return row ? (*row)[0].Get<uint32>() : 0;
}

static void GiveClassTools(Player* buddy, std::string& problems)
{
    uint8 level = buddy->GetLevel();
    switch (buddy->getClass())
    {
        case CLASS_SHAMAN:
            for (TotemItem const& t : SHAMAN_TOTEMS)
                if (level >= t.level && !buddy->HasItemCount(t.item, 1, false) && !buddy->StoreNewItemInBestSlots(t.item, 1))
                    problems += std::string("no room for its ") + t.name + "; ";
            break;
        case CLASS_ROGUE:
            if (level < 20)
                break;                                  // the first poison needs level 20
            for (char const* family : { "Instant Poison%", "Deadly Poison%" })
            {
                uint32 entry = BestVendorItem(buddy, std::string("it.name LIKE '") + family + "' AND (it.AllowableClass & 8)");
                if (!entry)
                {
                    if (std::string(family) == "Instant Poison%")
                        problems += "no Instant Poison at vendors for its level; ";
                    continue;                           // Deadly Poison starts at 30: none below is no problem
                }
                uint32 have = buddy->GetItemCount(entry, false);
                if (have < POISON_DOSES && !buddy->StoreNewItemInBestSlots(entry, POISON_DOSES - have))
                    problems += "no room for its poison " + std::to_string(entry) + "; ";
            }
            break;
        case CLASS_HUNTER:
        {
            Item* ranged = buddy->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_RANGED);
            if (!ranged)
            {
                problems += "a hunter with no ranged weapon: no ammunition given; ";
                break;
            }
            uint32 sub = ranged->GetTemplate()->SubClass;
            uint32 ammoSub = (sub == ITEM_SUBCLASS_WEAPON_GUN) ? ITEM_SUBCLASS_BULLET
                           : (sub == ITEM_SUBCLASS_WEAPON_BOW || sub == ITEM_SUBCLASS_WEAPON_CROSSBOW) ? ITEM_SUBCLASS_ARROW : 0;
            if (!ammoSub)
                break;                                  // a thrown weapon or wand needs none
            uint32 ammo = BestVendorItem(buddy, "it.class = 6 AND it.subclass = " + std::to_string(ammoSub));
            if (!ammo)
            {
                problems += "no ammunition at vendors for its level and weapon; ";
                break;
            }
            uint32 have = buddy->GetItemCount(ammo, false);
            if (have < AMMO_ROUNDS && !buddy->StoreNewItemInBestSlots(ammo, AMMO_ROUNDS - have))
                problems += "no room for its ammunition " + std::to_string(ammo) + "; ";
            buddy->SetAmmo(ammo);
            // a quiver for arrows, a pouch for bullets (container subclass 2, 3)
            uint32 bagSub = ammoSub == ITEM_SUBCLASS_ARROW ? 2 : 3;
            bool hasIt = false;
            uint8 freeSlot = 0;
            for (uint8 b = INVENTORY_SLOT_BAG_START; b < INVENTORY_SLOT_BAG_END; ++b)
            {
                Item* bag = buddy->GetItemByPos(INVENTORY_SLOT_BAG_0, b);
                if (!bag && !freeSlot)
                    freeSlot = b;
                else if (bag && bag->GetTemplate()->Class == ITEM_CLASS_QUIVER && bag->GetTemplate()->SubClass == bagSub)
                    hasIt = true;
            }
            if (hasIt)
                break;
            uint32 container = BestVendorItem(buddy, "it.class = 11 AND it.subclass = " + std::to_string(bagSub));
            uint16 dest;
            if (!container || !freeSlot)
                problems += std::string("no ") + (bagSub == 2 ? "quiver" : "ammo pouch") + (container ? " (no free bag slot)" : " at vendors for its level") + "; ";
            else if (buddy->CanEquipNewItem(freeSlot, dest, container, false) == EQUIP_ERR_OK)
                buddy->EquipNewItem(dest, container, true);
            else
                problems += "could not put on its " + std::string(bagSub == 2 ? "quiver" : "ammo pouch") + "; ";
            break;
        }
        default:
            break;
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
    uint32 worn = GiveGear(buddy, shape, true, problems);
    GiveClassTools(buddy, problems);                     // totems, poisons, ammunition: after the gear (the ammo fits the ranged weapon)
    // then a random weapon kind for each its owner knows (617n); a
    // stand-in (made with ownerGuid 0) is nobody's buddy and learns none
    if (ownerGuid)
        BuddyFillWeaponKinds(buddy, BuddyWeaponAllowance(ownerGuid));
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

// {{{ BuddyGivePvpJewellery
// The neck, the two rings and the two trinkets: no white item exists for
// them, so a stand-in wears the best player-versus-player rewards of its
// level instead (617t: "when available give them PvP trinkets, rings, and
// necklaces, the best available at that level"; the owner, 2026-10-09:
// "let's do it now"). PvP rewards here are what a vendor sells for honor or
// arena points (the battleground medallions, insignia, the four kinds of
// ring, the faction Insignia trinkets: every ten levels from 18), its class
// and race allowed, at or below its level. Each is scored by its talent
// shape, tree by tree, as the gem step scores (buddies_gems.cpp): the best
// necklace, the two best rings and the two best trinkets (two different
// items each). Most need standing with a battleground's faction (the
// Warsong Outriders, the League of Arathor...): the stand-in is given that
// standing, as a veteran of the battles its gear comes from, or the server
// would refuse to let it wear them. Items wanting an old honor rank are left
// out (no rank can be given). What was in those slots is replaced.
std::string BuddyGivePvpJewellery(Player* who, uint8 shape, uint8 role)
{
    std::string problems;
    uint8 thirds[3];
    CollectorType types[3];
    bool plan = BuddyPlanShape(who->getClass(), shape, role, thirds, types);

    // candidates by kind (2 neck, 11 finger, 12 trinket), scored
    std::map<uint32, std::vector<std::pair<float, ItemTemplate const*>>> byKind;
    QueryResult rows = WorldDatabase.Query(
        "SELECT DISTINCT it.entry, v.ExtendedCost FROM item_template it JOIN npc_vendor v ON v.item = it.entry "
        "WHERE it.InventoryType IN (2, 11, 12) AND v.ExtendedCost > 0 AND it.RequiredLevel <= {} AND it.RequiredHonorRank = 0",
        who->GetLevel());
    std::set<uint32> seen;
    if (rows)
        do
        {
            uint32 entry = (*rows)[0].Get<uint32>();
            ItemExtendedCostEntry const* cost = sItemExtendedCostStore.LookupEntry((*rows)[1].Get<uint32>());
            if (!cost || (!cost->reqhonorpoints && !cost->reqarenapoints) || !seen.insert(entry).second)
                continue;                               // not bought with honor or arena points, or seen
            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(entry);
            if (!proto || !(proto->AllowableClass & who->getClassMask()) || !(proto->AllowableRace & who->getRaceMask()))
                continue;                               // another class's, or the other side's
            float score = 0.0f;
            if (plan)
                for (int t = 0; t < 3; ++t)
                {
                    if (!thirds[t])
                        continue;
                    StatsWeightCalculator part(who);
                    part.SetSpecTab(t, types[t]);
                    part.SetOverflowPenalty(false);
                    score += float(thirds[t]) / 3.0f * part.CalculateItem(entry);
                }
            else
            {
                StatsWeightCalculator c(who);
                c.SetOverflowPenalty(false);
                score = c.CalculateItem(entry);
            }
            byKind[proto->InventoryType].emplace_back(score, proto);
        } while (rows->NextRow());

    // the best (two for rings and trinkets), standing given, worn
    struct Kind { uint32 inventoryType; std::vector<uint8> slots; char const* name; };
    std::vector<Kind> const kinds = {
        { INVTYPE_NECK,    { EQUIPMENT_SLOT_NECK },                             "necklace" },
        { INVTYPE_FINGER,  { EQUIPMENT_SLOT_FINGER1, EQUIPMENT_SLOT_FINGER2 },   "ring" },
        { INVTYPE_TRINKET, { EQUIPMENT_SLOT_TRINKET1, EQUIPMENT_SLOT_TRINKET2 }, "trinket" },
    };
    for (Kind const& kind : kinds)
    {
        auto& list = byKind[kind.inventoryType];
        std::stable_sort(list.begin(), list.end(), [](auto const& a, auto const& b)
            { return a.first != b.first ? a.first > b.first : a.second->ItemLevel > b.second->ItemLevel; });
        size_t next = 0;
        for (uint8 slot : kind.slots)
        {
            if (next >= list.size())
            {
                problems += std::string("no PvP ") + kind.name + " at its level for slot " + std::to_string(slot) + "; ";
                continue;
            }
            ItemTemplate const* proto = list[next++].second;
            if (proto->RequiredReputationFaction)
                if (FactionEntry const* faction = sFactionStore.LookupEntry(proto->RequiredReputationFaction))
                    if (who->GetReputationMgr().GetRank(faction) < ReputationRank(proto->RequiredReputationRank))
                        who->GetReputationMgr().SetReputation(faction,
                            float(ReputationMgr::ReputationRankToStanding(ReputationRank(proto->RequiredReputationRank))));
            if (Wear(who, slot, proto->ItemId) != EQUIP_ERR_OK)
                problems += std::string("slot ") + std::to_string(slot) + " refused " + kind.name + " " + std::to_string(proto->ItemId) + "; ";
        }
    }
    return problems;
}
// }}}

// {{{ BuddyRegear and ".buddy kit <name>"
std::string BuddyRegear(Player* buddy, uint8 shape)
{
    std::string problems;
    GiveGear(buddy, shape, false, problems);
    GiveClassTools(buddy, problems);                     // a new ranged weapon may want other ammunition
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
        handler->PSendSysMessage("{} (level {}) re-kitted from {} by its talent shape {}{}{}", name, buddy->GetLevel(), KitGearset(buddy->GetLevel()),
            uint32(shape), problems.empty() ? "" : "; ", problems);
        return true;
    }
};

void AddSC_buddies_kit()
{
    new buddies_kit_command();
}
// }}}
