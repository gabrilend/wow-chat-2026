
#include "buddies.h"
#include "buddies_arms.h"
#include "buddies_roam.h"
#include "buddies_town.h"
#include "Bag.h"
#include "Item.h"
#include "ItemPackets.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Playerbots.h"
#include "PlayerbotAI.h"
#include "ScriptMgr.h"
#include "StatsWeightCalculator.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <mutex>
#include <set>
#include <unordered_map>
#include <vector>

static constexpr uint32 ARMS_LOOK_MS = 2000;
static constexpr uint8 HAND_SLOTS[] = { EQUIPMENT_SLOT_MAINHAND, EQUIPMENT_SLOT_OFFHAND, EQUIPMENT_SLOT_RANGED };

static bool IsPole(Item const* item)
{
    return item && item->GetTemplate()->Class == ITEM_CLASS_WEAPON &&
           item->GetTemplate()->SubClass == ITEM_SUBCLASS_WEAPON_FISHING_POLE;
}

static std::vector<Item*> Carried(Player* bot)
{
    std::vector<Item*> items;
    for (uint8 slot : HAND_SLOTS)
        if (Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            items.push_back(item);
    for (uint8 slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
        if (Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            items.push_back(item);
    for (uint8 b = INVENTORY_SLOT_BAG_START; b < INVENTORY_SLOT_BAG_END; ++b)
        if (Bag* bag = bot->GetBagByPos(b))
            for (uint32 j = 0; j < bag->GetBagSize(); ++j)
                if (Item* item = bag->GetItemByPos(uint8(j)))
                    items.push_back(item);
    return items;
}

static bool FitsSlot(Player* bot, ItemTemplate const* p, uint8 slot)
{
    if (p->Class == ITEM_CLASS_WEAPON && (p->SubClass == ITEM_SUBCLASS_WEAPON_FISHING_POLE || p->SubClass == ITEM_SUBCLASS_WEAPON_MISC))
        return false;
    switch (slot)
    {
        case EQUIPMENT_SLOT_MAINHAND:
            return p->InventoryType == INVTYPE_WEAPON || p->InventoryType == INVTYPE_2HWEAPON || p->InventoryType == INVTYPE_WEAPONMAINHAND;
        case EQUIPMENT_SLOT_OFFHAND:
            return p->InventoryType == INVTYPE_SHIELD || p->InventoryType == INVTYPE_HOLDABLE ||
                   p->InventoryType == INVTYPE_WEAPONOFFHAND || (p->InventoryType == INVTYPE_WEAPON && bot->CanDualWield());
        default:
            return p->InventoryType == INVTYPE_RANGED || p->InventoryType == INVTYPE_RANGEDRIGHT || p->InventoryType == INVTYPE_THROWN;
    }
}

struct Ranked { Item* best = nullptr; Item* next = nullptr; };

static Ranked RankFor(Player* bot, std::vector<Item*> const& items, uint8 slot, Item const* skip)
{
    StatsWeightCalculator scorer(bot);
    scorer.SetOverflowPenalty(false);
    Ranked r;
    float bestScore = -1.0f, nextScore = -1.0f;
    for (Item* item : items)
    {
        ItemTemplate const* p = item->GetTemplate();
        if (item == skip || !FitsSlot(bot, p, slot) || bot->CanUseItem(p) != EQUIP_ERR_OK)
            continue;
        float s = scorer.CalculateItem(p->ItemId);
        if (s > bestScore)
        {
            r.next = r.best, nextScore = bestScore;
            r.best = item, bestScore = s;
        }
        else if (s > nextScore)
            r.next = item, nextScore = s;
    }
    return r;
}

struct Arms { Ranked hand[3]; };

static Arms BestArms(Player* bot)
{
    std::vector<Item*> items = Carried(bot);
    Arms a;
    a.hand[0] = RankFor(bot, items, EQUIPMENT_SLOT_MAINHAND, nullptr);
    bool twoHanded = a.hand[0].best && a.hand[0].best->GetTemplate()->InventoryType == INVTYPE_2HWEAPON;
    if (!twoHanded)
        a.hand[1] = RankFor(bot, items, EQUIPMENT_SLOT_OFFHAND, a.hand[0].best);
    a.hand[2] = RankFor(bot, items, EQUIPMENT_SLOT_RANGED, nullptr);
    return a;
}

bool BuddyIsKeptWeapon(Player* bot, Item* item)
{
    Arms a = BestArms(bot);
    for (Ranked const& r : a.hand)
        if (item == r.best || item == r.next)
            return true;
    return false;
}

static void EquipInSlot(Player* bot, Item* item, uint8 slot)
{
    WorldPacket packet(CMSG_AUTOEQUIP_ITEM_SLOT, 9);
    packet << item->GetGUID() << slot;
    WorldPackets::Item::AutoEquipItemSlot request(std::move(packet));
    request.Read();
    bot->GetSession()->HandleAutoEquipItemSlotOpcode(request);
}

static bool IntoBags(Player* bot, uint8 slot)
{
    Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
    if (!item || bot->CanUnequipItem(item->GetPos(), false) != EQUIP_ERR_OK)
        return false;
    ItemPosCountVec dest;
    if (bot->CanStoreItem(NULL_BAG, NULL_SLOT, dest, item, false) != EQUIP_ERR_OK)
        return false;
    bot->RemoveItem(INVENTORY_SLOT_BAG_0, slot, true);
    bot->StoreItem(dest, item, true);
    return true;
}

enum class Place : uint8 { Town, Open, Danger };

struct Situation
{
    Place place;
    bool  fighting;
    bool  fishing;
    bool operator==(Situation const& o) const { return place == o.place && fighting == o.fighting && fishing == o.fishing; }
};

static bool OnTheWay(Player* bot)
{
    PlayerbotAI* ai = GET_PLAYERBOT_AI(bot);
    Player* owner = ai ? ai->GetMaster() : nullptr;
    return !owner || owner->GetMapId() != bot->GetMapId() || owner->GetAreaId() != bot->GetAreaId();
}

static Situation SituationOf(Player* bot)
{
    Place place = bot->GetMap()->Instanceable() ? Place::Danger
                : BuddyTownArea(bot) ? Place::Town
                : OnTheWay(bot) ? Place::Open
                : Place::Danger;
    return { place, bot->IsInCombat(), BuddyTownFishing(bot->GetGUID().GetCounter()) };
}

static char const* Words(Situation const& s)
{
    if (s.fighting)
        return "as a fight began";
    return s.place == Place::Town ? "in town" : (s.place == Place::Danger ? "questing or in danger" : "on the way");
}

static void Carry(Player* bot, Situation const& s)
{
    if (s.place == Place::Town && !s.fighting)
    {
        for (uint8 slot : HAND_SLOTS)
        {
            Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
            if (!item || (IsPole(item) && s.fishing))
                continue;
            if (IntoBags(bot, slot))
                BuddyTrace(bot, "arms: {} put away in town", item->GetTemplate()->Name1);
            else
                LOG_ERROR("module", "mod-buddies: buddy {} keeps {} in hand in town: no room in its bags (or it can't be taken "
                    "off). To debug: how full are its bags (.buddy trace {})? Is it selling at vendors?",
                    bot->GetName(), item->GetTemplate()->Name1, bot->GetName());
        }
        return;
    }
    Arms a = BestArms(bot);
    for (int i = 0; i < 3; ++i)
    {
        Item* want = a.hand[i].best;
        Item* held = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, HAND_SLOTS[i]);
        if (want && want != held)
        {
            EquipInSlot(bot, want, HAND_SLOTS[i]);
            BuddyTrace(bot, "arms: {} in hand {}", want->GetTemplate()->Name1, Words(s));
        }
        else if (!want && i == 0 && IsPole(held))
            LOG_ERROR("module", "mod-buddies: buddy {} holds a fishing pole {} and carries no weapon it can use, so the pole "
                "stays in hand. To debug: \".buddy kit {}\" gives its gearset's weapon (does the gearset record have slot 15? "
                "does it know that weapon's kind?)", bot->GetName(), Words(s), bot->GetName());
    }
    SheathState sheath = (s.fighting || s.place == Place::Danger) ? SHEATH_STATE_MELEE : SHEATH_STATE_UNARMED;
    if (bot->GetSheath() != sheath)
        bot->SetSheath(sheath);
}

static std::mutex sSeenLock;
static std::unordered_map<uint32, Situation> sSeen;

static void Look(Player* bot, bool force)
{
    Situation now = SituationOf(bot);
    {
        std::lock_guard<std::mutex> lock(sSeenLock);
        auto it = sSeen.find(bot->GetGUID().GetCounter());
        if (!force && it != sSeen.end() && it->second == now)
            return;
        sSeen[bot->GetGUID().GetCounter()] = now;
    }
    Carry(bot, now);
}

static bool IsBuddy(Player* p)
{
    return BuddiesEnabled() && p->GetSession() && BuddyIsCompanionAccount(p->GetSession()->GetAccountId());
}

class buddies_arms_player : public PlayerScript
{
public:
    buddies_arms_player() : PlayerScript("buddies_arms_player",
        { PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_PLAYER_ENTER_COMBAT }) { }

    void OnPlayerLogin(Player* player) override
    {
        if (IsBuddy(player))
            Look(player, true);
    }
    void OnPlayerLogout(Player* player) override
    {
        std::lock_guard<std::mutex> lock(sSeenLock);
        sSeen.erase(player->GetGUID().GetCounter());
    }
    void OnPlayerEnterCombat(Player* player, Unit* ) override
    {
        if (IsBuddy(player))
            Look(player, false);
    }
};

class buddies_arms_world : public WorldScript
{
public:
    buddies_arms_world() : WorldScript("buddies_arms_world", { WORLDHOOK_ON_UPDATE }) { }

    void OnUpdate(uint32 diff) override
    {
        _since += diff;
        if (_since < ARMS_LOOK_MS || !BuddiesEnabled())
            return;
        _since = 0;
        for (auto const& [buddyGuid, ownerGuid] : BuddyRosterPairs())
            if (Player* bot = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(buddyGuid)))
                if (bot->IsInWorld() && bot->IsAlive() && bot->GetSession())
                    Look(bot, false);
    }

private:
    uint32 _since = 0;
};

void AddSC_buddies_arms()
{
    new buddies_arms_player();
    new buddies_arms_world();
}
