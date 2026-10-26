
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

static std::string KitGearset(uint8 level)
{
    return "buddy-white-" + std::to_string(level < 10 ? 1 : level / 10 * 10);
}
static constexpr uint32 GEARSET_SLOTS = EQUIPMENT_SLOT_END;
static constexpr uint32 MEALS = 5;

static InventoryResult Wear(Player* buddy, uint8 slot, uint32 entry)
{
    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(entry);
    if (!proto)
        return EQUIP_ERR_ITEM_NOT_FOUND;
    if (InventoryResult use = buddy->CanUseItem(proto); use != EQUIP_ERR_OK)
        return use;
    if (buddy->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
        buddy->DestroyItem(INVENTORY_SLOT_BAG_0, slot, true);
    uint16 dest;
    if (InventoryResult equip = buddy->CanEquipNewItem(slot, dest, entry, false); equip != EQUIP_ERR_OK)
        return equip;
    buddy->EquipNewItem(dest, entry, true);
    return EQUIP_ERR_OK;
}
static constexpr uint8 ENCHANT_FROM_LEVEL = 30;
static constexpr uint32 KIT_ENCHANTS[] = {
     803,
    1894,
    1898,
    1899,
};
static void Enchant(Player* buddy, uint8 slot, std::string& problems)
{
    Item* item = buddy->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
    if (!item || item->GetTemplate()->Class != ITEM_CLASS_WEAPON)
        return;
    uint32 id = KIT_ENCHANTS[urand(0, std::size(KIT_ENCHANTS) - 1)];
    if (!sSpellItemEnchantmentStore.LookupEntry(id))
    {
        problems += "enchant " + std::to_string(id) + " is not in the server's SpellItemEnchantment table (are the client's "
            "data files extracted?); ";
        return;
    }
    buddy->ApplyEnchantment(item, PERM_ENCHANTMENT_SLOT, false);
    item->SetEnchantment(PERM_ENCHANTMENT_SLOT, id, 0, 0);
    buddy->ApplyEnchantment(item, PERM_ENCHANTMENT_SLOT, true);
}

static uint32 GiveGear(Player* buddy, uint8 shape, bool firstMaking, std::string& problems)
{
    if (buddy->GetLevel() <= 1)
        return 0;
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

static constexpr uint32 POISON_DOSES = 20;
static constexpr uint32 AMMO_ROUNDS  = 1000;
struct TotemItem { uint8 level; uint32 item; char const* name; };
static constexpr TotemItem SHAMAN_TOTEMS[] = {
    {  4, 5175, "Earth Totem" }, { 10, 5176, "Fire Totem" }, { 20, 5177, "Water Totem" }, { 30, 5178, "Air Totem" },
};

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
                break;
            for (char const* family : { "Instant Poison%", "Deadly Poison%" })
            {
                uint32 entry = BestVendorItem(buddy, std::string("it.name LIKE '") + family + "' AND (it.AllowableClass & 8)");
                if (!entry)
                {
                    if (std::string(family) == "Instant Poison%")
                        problems += "no Instant Poison at vendors for its level; ";
                    continue;
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
                break;
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
        return;

    std::map<uint32, uint32> bagOfSize;
    if (QueryResult bags = WorldDatabase.Query(
            "SELECT DISTINCT it.entry, it.ContainerSlots, it.Quality, it.ItemLevel FROM item_template it JOIN npc_vendor v ON v.item = it.entry "
            "WHERE it.class = 1 AND it.subclass = 0 AND it.ContainerSlots > 0 "
            "ORDER BY it.Quality ASC, it.ItemLevel ASC, it.entry"))
        do
            bagOfSize.emplace((*bags)[1].Get<uint32>(), (*bags)[0].Get<uint32>());
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

std::string BuddyGiveStartingKit(Player* buddy, uint32 ownerGuid, uint8 shape)
{
    std::string problems;
    GiveBags(buddy, ownerGuid, problems);
    uint32 worn = GiveGear(buddy, shape, true, problems);
    GiveClassTools(buddy, problems);
    if (ownerGuid)
        BuddyFillWeaponKinds(buddy, BuddyWeaponAllowance(ownerGuid));
    GiveMeals(buddy, problems);
    if (buddy->GetLevel() > 1)
        buddy->ModifyMoney(int32(buddy->GetLevel()) * 100);
    if (!worn && buddy->GetLevel() > 1)
        problems += "wears nothing chosen for it; ";
    return problems;
}

std::string BuddyGivePvpJewellery(Player* who, uint8 shape, uint8 role)
{
    std::string problems;
    uint8 thirds[3];
    CollectorType types[3];
    bool plan = BuddyPlanShape(who->getClass(), shape, role, thirds, types);

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
                continue;
            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(entry);
            if (!proto || !(proto->AllowableClass & who->getClassMask()) || !(proto->AllowableRace & who->getRaceMask()))
                continue;
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

std::string BuddyRegear(Player* buddy, uint8 shape)
{
    std::string problems;
    GiveGear(buddy, shape, false, problems);
    GiveClassTools(buddy, problems);
    return problems;
}

class buddies_kit_command : public CommandScript
{
public:
    buddies_kit_command() : CommandScript("buddies_kit_command") { }

    ChatCommandTable GetCommands() const override
    {
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
        QueryResult row = CharacterDatabase.Query("SELECT profile, role FROM buddy_roster WHERE buddy = {}", buddy->GetGUID().GetCounter());
        uint8 shape = row ? (*row)[0].Get<uint8>() : 0;
        uint8 role  = row ? (*row)[1].Get<uint8>() : 0;
        std::string problems = BuddyRegear(buddy, shape);
        if (buddy->GetLevel() >= BUDDY_PVP_JEWELLERY_FROM)
            problems += BuddyGivePvpJewellery(buddy, shape, role);
        handler->PSendSysMessage("{} (level {}) re-kitted from {} by its talent shape {}{}{}", name, buddy->GetLevel(), KitGearset(buddy->GetLevel()),
            uint32(shape), problems.empty() ? "" : "; ", problems);
        return true;
    }
};

void AddSC_buddies_kit()
{
    new buddies_kit_command();
}
