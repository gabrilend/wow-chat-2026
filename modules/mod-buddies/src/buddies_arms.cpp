/*
 * buddies_arms.cpp - how a buddy carries its weapons, by where it is
 * (issue 617e4b).
 *
 * For a general audience: the owner, 2026-10-15: "when in town, they
 * shouldn't carry any weapons at all. While in the wilds, they should bear
 * their sword on their hip or back. When in danger, they should bear it in
 * hand. in town or at peace, they shouldn't bear the fishing pole - only
 * when they are fishing". And what danger is: "when they're questing in a
 * hostile place, or in a dungeon, or in a battleground or arena."
 *
 * So every couple of seconds each online buddy is looked at:
 *   in a town, out of a fight   - its main hand, off hand and ranged weapon
 *                                 go into its bags, and which items they
 *                                 were is written down (in the characters
 *                                 database, table buddy_stowed_weapon, so a
 *                                 restart in town forgets nothing: memory
 *                                 alone is what once left Mozonn's hammer
 *                                 in its backpack and a pole in its hand).
 *                                 The fishing pole stays in hand while the
 *                                 town visit is fishing (walking to the
 *                                 shore included), and goes too otherwise.
 *   anywhere else, or a fight   - the written-down weapons come back to
 *                                 their hands, then:
 *     in danger, or fighting    - drawn (the melee sheath state)
 *     in the wilds, at peace    - sheathed (on the back or hip)
 * Danger: inside a dungeon, raid, battleground or arena (an instanced map),
 * or in a zone that belongs to the other faction (the zone's team in
 * AreaTable.dbc). A contested zone is the wilds. A fight starting anywhere
 * brings the weapons back at once (the combat hook), not at the next look.
 *
 * A pole in hand outside town (the fishing visit was cut short when the
 * owner left town, or a restart) is swapped for its stowed weapons, or,
 * with none written down, for the best weapon in its bags.
 */

#include "buddies.h"
#include "buddies_arms.h"
#include "buddies_roam.h"
#include "buddies_town.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"
#include "Bag.h"
#include "Item.h"
#include "ItemPackets.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "QueryResult.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <array>
#include <mutex>
#include <set>
#include <unordered_map>

// {{{ tuning
static constexpr uint32 ARMS_PASS_MS = 2000;   // how often each buddy's way of carrying is looked at
// the hand slots, in the order they are put away and brought back: the main
// hand first back, so a two-hander is in place before an off hand is tried
static constexpr uint8 HAND_SLOTS[] = { EQUIPMENT_SLOT_MAINHAND, EQUIPMENT_SLOT_OFFHAND, EQUIPMENT_SLOT_RANGED };
// }}}

// {{{ the written-down weapons
// buddy guid -> item guid (low part) per hand slot, 0 for none; mirrors
// buddy_stowed_weapon, read once at the buddy's login.
static std::mutex sStowedLock;
static std::unordered_map<uint32, std::array<uint32, 3>> sStowed;

static uint8 HandIndex(uint8 slot)
{
    return slot == EQUIPMENT_SLOT_MAINHAND ? 0 : (slot == EQUIPMENT_SLOT_OFFHAND ? 1 : 2);
}

static void LoadStowed(uint32 buddy)
{
    std::array<uint32, 3> hands {};
    if (QueryResult rows = CharacterDatabase.Query("SELECT slot, item FROM buddy_stowed_weapon WHERE buddy = {}", buddy))
        do
            hands[HandIndex((*rows)[0].Get<uint8>())] = (*rows)[1].Get<uint32>();
        while (rows->NextRow());
    std::lock_guard<std::mutex> lock(sStowedLock);
    sStowed[buddy] = hands;
}

static void WriteStowed(uint32 buddy, uint8 slot, uint32 item)
{
    {
        std::lock_guard<std::mutex> lock(sStowedLock);
        sStowed[buddy][HandIndex(slot)] = item;
    }
    if (item)
        CharacterDatabase.Execute("REPLACE INTO buddy_stowed_weapon (buddy, slot, item) VALUES ({}, {}, {})", buddy, slot, item);
    else
        CharacterDatabase.Execute("DELETE FROM buddy_stowed_weapon WHERE buddy = {} AND slot = {}", buddy, slot);
}

static uint32 StowedIn(uint32 buddy, uint8 slot)
{
    std::lock_guard<std::mutex> lock(sStowedLock);
    auto it = sStowed.find(buddy);
    return it == sStowed.end() ? 0 : it->second[HandIndex(slot)];
}

bool BuddyIsStowedWeapon(Player* bot, Item* item)
{
    std::lock_guard<std::mutex> lock(sStowedLock);
    auto it = sStowed.find(bot->GetGUID().GetCounter());
    if (it == sStowed.end())
        return false;
    for (uint32 low : it->second)
        if (low && low == item->GetGUID().GetCounter())
            return true;
    return false;
}
// }}}

// {{{ moving an item between hand and bags
// Equip as the client asks to, so every rule the server has applies (the
// same request the town visit's fishing uses); what was in that slot goes
// to where this item was.
static void EquipInSlot(Player* bot, Item* item, uint8 slot)
{
    WorldPacket packet(CMSG_AUTOEQUIP_ITEM_SLOT, 9);
    packet << item->GetGUID() << slot;
    WorldPackets::Item::AutoEquipItemSlot request(std::move(packet));
    request.Read();
    bot->GetSession()->HandleAutoEquipItemSlotOpcode(request);
}

// Worn item in `slot` into the bags, as the client's "put it in my bags"
// does. False (nothing moved) when the bags have no room or it can't be
// taken off.
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

static bool IsPole(Item const* item)
{
    return item && item->GetTemplate()->Class == ITEM_CLASS_WEAPON &&
           item->GetTemplate()->SubClass == ITEM_SUBCLASS_WEAPON_FISHING_POLE;
}
// }}}

// {{{ the place
enum class Place : uint8 { Town, Wilds, Danger };

static Place PlaceOf(Player* bot)
{
    if (bot->GetMap()->Instanceable())
        return Place::Danger;                              // dungeon, raid, battleground, arena
    if (BuddyTownArea(bot))
        return Place::Town;                                // a town, its buildings too
    if (AreaTableEntry const* zone = sAreaTableStore.LookupEntry(bot->GetZoneId()))
        if ((zone->team == AREATEAM_ALLY && bot->GetTeamId() == TEAM_HORDE) ||
            (zone->team == AREATEAM_HORDE && bot->GetTeamId() == TEAM_ALLIANCE))
            return Place::Danger;                          // the other faction's land
    return Place::Wilds;                                   // own land, contested land, no-one's
}
// }}}

// {{{ Stow
// In town, out of a fight: hands emptied into the bags (the pole kept while
// fishing). Bags too full: that weapon stays worn, said once per town stay.
static std::mutex sToldFullLock;                           // the combat hook runs on map threads
static std::set<uint32> sToldFull;

static void Stow(Player* bot)
{
    uint32 guid = bot->GetGUID().GetCounter();
    bool fishing = BuddyTownFishing(guid);
    for (uint8 slot : HAND_SLOTS)
    {
        Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        if (!item || (IsPole(item) && fishing))
            continue;                                      // empty hand; the pole while it fishes
        uint32 low = IsPole(item) ? 0 : item->GetGUID().GetCounter();   // the pole is not a weapon to bring back
        if (!IntoBags(bot, slot))
        {
            bool first;
            {
                std::lock_guard<std::mutex> lock(sToldFullLock);
                first = sToldFull.insert(guid).second;
            }
            if (first)
                LOG_ERROR("module", "mod-buddies: buddy {} keeps {} in hand in town: no room in its bags (or it can't be taken "
                    "off). To debug: how full are its bags (.buddy trace)? Is it selling at vendors?",
                    bot->GetName(), item->GetTemplate()->Name1);
            continue;
        }
        if (low)
            WriteStowed(guid, slot, low);
        BuddyTrace(bot, "arms: {} put away in town", item->GetTemplate()->Name1);
    }
}
// }}}

// {{{ Restore
// Out of town, or a fight: the written-down weapons back in hand. A pole
// still in the main hand with nothing written down: the best weapon in its
// bags (the highest item level main-hand, one-hand or two-hand weapon it
// can use, never a profession tool, weapon subclass 14); with none, the
// pole stays and the log says so (never a guess at something else).
static void BestWeaponForPole(Player* bot, char const* when)
{
    Item* best = nullptr;
    auto consider = [&](Item* item)
    {
        ItemTemplate const* p = item->GetTemplate();
        if (p->Class != ITEM_CLASS_WEAPON || IsPole(item) || p->SubClass == ITEM_SUBCLASS_WEAPON_MISC)
            return;                                        // poles and profession tools are not for fighting
        if (p->InventoryType != INVTYPE_WEAPON && p->InventoryType != INVTYPE_2HWEAPON && p->InventoryType != INVTYPE_WEAPONMAINHAND)
            return;                                        // off-hand-only, ranged and thrown go elsewhere
        if (bot->CanUseItem(p) != EQUIP_ERR_OK)
            return;                                        // a kind it doesn't know, a level it hasn't reached
        if (!best || p->ItemLevel > best->GetTemplate()->ItemLevel)
            best = item;
    };
    for (uint8 slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
        if (Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            consider(item);
    for (uint8 b = INVENTORY_SLOT_BAG_START; b < INVENTORY_SLOT_BAG_END; ++b)
        if (Bag* bag = bot->GetBagByPos(b))
            for (uint32 j = 0; j < bag->GetBagSize(); ++j)
                if (Item* item = bag->GetItemByPos(uint8(j)))
                    consider(item);
    if (!best)
    {
        LOG_ERROR("module", "mod-buddies: buddy {} holds a fishing pole {} and has no weapon in its bags it can use, so the pole "
            "stays in hand. To debug: \".buddy kit {}\" gives its gearset's weapon (does the gearset record have slot 15? "
            "does it know that weapon's kind?)", bot->GetName(), when, bot->GetName());
        return;
    }
    EquipInSlot(bot, best, EQUIPMENT_SLOT_MAINHAND);
    BuddyTrace(bot, "arms: pole put away {}: took {} in hand", when, best->GetTemplate()->Name1);
}

static void Restore(Player* bot, char const* when)
{
    uint32 guid = bot->GetGUID().GetCounter();
    {
        std::lock_guard<std::mutex> lock(sToldFullLock);
        sToldFull.erase(guid);                             // out of town: a full-bags note may be given again next stay
    }
    for (uint8 slot : HAND_SLOTS)
    {
        uint32 low = StowedIn(guid, slot);
        if (!low)
            continue;
        Item* item = bot->GetItemByGuid(ObjectGuid::Create<HighGuid::Item>(low));
        if (item && !item->IsEquipped())                   // in the backpack or a bag (the server's "in a bag" means
            EquipInSlot(bot, item, slot);                  // a bag only, not the backpack)
        else if (!item)
            LOG_ERROR("module", "mod-buddies: buddy {} put away item {} (slot {}) in town and no longer has it; its hand "
                "stays as it is. To debug: did a town vendor visit sell it (buddies_town.cpp, CantSpare keeps put-away "
                "weapons)? Was it traded or mailed?", bot->GetName(), low, slot);
        WriteStowed(guid, slot, 0);                        // brought back, or gone: either way no longer written down
        if (item)
            BuddyTrace(bot, "arms: {} back in hand {}", item->GetTemplate()->Name1, when);
    }
    if (IsPole(bot->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_MAINHAND)))
        BestWeaponForPole(bot, when);
}
// }}}

// {{{ Carry
// One look at one buddy: put away, or bring back and draw or sheathe.
static void Carry(Player* bot)
{
    bool fighting = bot->IsInCombat();
    Place place = PlaceOf(bot);
    if (place == Place::Town && !fighting)
    {
        Stow(bot);
        return;
    }
    Restore(bot, fighting ? "as it fights" : (place == Place::Danger ? "in danger" : "out of town"));
    SheathState want = (fighting || place == Place::Danger) ? SHEATH_STATE_MELEE : SHEATH_STATE_UNARMED;
    if (bot->GetSheath() != want)
        bot->SetSheath(want);
}
// }}}

// {{{ the scripts
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
        if (!IsBuddy(player))
            return;
        LoadStowed(player->GetGUID().GetCounter());
        Carry(player);                                     // no one fishes yet: a pole left in hand is put away now
    }
    void OnPlayerLogout(Player* player) override
    {
        if (!IsBuddy(player))
            return;
        std::lock_guard<std::mutex> lock(sStowedLock);
        sStowed.erase(player->GetGUID().GetCounter());     // the table keeps it; read again at the next login
    }
    void OnPlayerEnterCombat(Player* player, Unit* /*enemy*/) override
    {
        if (IsBuddy(player))
            Carry(player);                                 // weapons in hand at once, not at the next look
    }
};

class buddies_arms_world : public WorldScript
{
public:
    buddies_arms_world() : WorldScript("buddies_arms_world", { WORLDHOOK_ON_UPDATE }) { }

    void OnUpdate(uint32 diff) override
    {
        _since += diff;
        if (_since < ARMS_PASS_MS || !BuddiesEnabled())
            return;
        _since = 0;
        for (auto const& [buddyGuid, ownerGuid] : BuddyRosterPairs())
            if (Player* bot = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(buddyGuid)))
                if (bot->IsInWorld() && bot->IsAlive() && bot->GetSession())
                    Carry(bot);
    }

private:
    uint32 _since = 0;
};

void AddSC_buddies_arms()
{
    new buddies_arms_player();
    new buddies_arms_world();
}
// }}}
