
#include "buddies.h"
#include "buddies_arms.h"
#include "buddies_explore.h"
#include "buddies_spells.h"
#include "buddies_steer.h"
#include "MoveSpline.h"
#include "buddies_roam.h"
#include "buddies_gems.h"
#include "buddies_town.h"
#include "buddies_beds.h"
#include "buddies_crossing.h"
#include "buddies_follow.h"
#include "Bag.h"
#include "Containers.h"
#include "FishingAction.h"
#include "Spell.h"
#include "SpellMgr.h"
#include "StatsWeightCalculator.h"
#include "Timer.h"
#include "CellImpl.h"
#include "Creature.h"
#include "GameObject.h"
#include "GameTime.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "GridTerrainData.h"
#include "Item.h"
#include "ItemPackets.h"
#include "ItemUsageValue.h"
#include "Log.h"
#include "AuctionHouseMgr.h"
#include "Mail.h"
#include "Map.h"
#include "MovementActions.h"
#include "NewRpgBaseAction.h"
#include "NonCombatStrategy.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Playerbots.h"
#include "PlayerbotAI.h"
#include "Random.h"
#include "Trainer.h"
#include "TravelMgr.h"
#include "Trigger.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <list>
#include <mutex>
#include <set>
#include <unordered_map>
#include <unordered_set>

WorldPosition FindLandFromPosition(PlayerbotAI* botAI, float startDistance, float endDistance, float increment,
                                   float orientation, WorldPosition targetPos, float fishingSearchWindow, bool checkLOS);

static constexpr float  MAP_WALK_YARDS      = 20.0f;
static constexpr float  MAP_LOOKAHEAD_YARDS = 12.0f;
static constexpr float  TRAVEL_RELEVANCE    = 3.5f;
static constexpr float  TOWN_RELEVANCE      = 3.0f;
static constexpr float  TOWN_SCAN_YARDS     = 150.0f;
static constexpr float  LEISURE_SCAN_YARDS  = 60.0f;
static constexpr float  NPC_YARDS           = 2.5f;
static constexpr float  CHAIR_YARDS         = 1.5f;
static constexpr float  ARRIVED_YARDS       = 3.5f;
static constexpr float  SEAT_GROUP_YARDS    = 6.0f;
static constexpr float  CROWD_YARDS         = 8.0f;
static constexpr uint32 VISIT_MIN_MS        = 10000;
static constexpr uint32 VISIT_MAX_MS        = 25000;
static constexpr uint32 SIT_MIN_MS          = 60000;
static constexpr uint32 SIT_MAX_MS          = 180000;
static constexpr uint32 SLEEP_MIN_MS        = 60000;
static constexpr uint32 SLEEP_MAX_MS        = 240000;
static constexpr uint32 EMOTE_MIN_MS        = 3000;
static constexpr uint32 EMOTE_MAX_MS        = 7000;
static constexpr uint32 GAP_MIN_MS          = 3000;
static constexpr uint32 GAP_MAX_MS          = 8000;
static constexpr uint32 WALK_GIVE_UP_MS     = 60000;
static constexpr uint32 WEIGHT_VISIT        = 60;
static constexpr uint32 WEIGHT_SIT          = 30;
static constexpr uint32 WEIGHT_SLEEP        = 10;
static constexpr uint32 WEIGHT_FISH         = 15;
static constexpr float  BED_YARDS           = 1.0f;
static constexpr uint32 FISH_MIN_CASTS      = 10;
static constexpr uint32 FISH_MAX_CASTS      = 30;
static constexpr uint32 FISH_GIVE_UP_MS     = 900000;
static constexpr float  FISH_WATER_MIN      = 10.0f;
static constexpr float  FISH_WATER_MAX      = 20.0f;
static constexpr float  HELP_YARDS          = 40.0f;
static constexpr uint64 ERRAND_PATIENCE_MS  = 60000;
static constexpr float  NEXT_ERRAND_FAR_CAP = 4.0f;
static constexpr uint32 STUCK_MS            = 90000;
static constexpr float  PROGRESS_YARDS      = 10.0f;
static constexpr uint32 FAILS_BEFORE_REPORT = 3;
static constexpr float  ARRIVE_RADIUS       = 5.0f;
static constexpr float  ARRIVE_SPACING      = 4.0f;
static constexpr uint64 ARRIVE_CLAIM_MS     = 30000;
static constexpr float  WANDER_SCAN_YARDS   = 100.0f;
static constexpr float  WANDER_CONE         = 0.785f;
static constexpr float  FULL_BAGS_SHARE     = 0.9f;
static constexpr uint32 MEAL_STOCK          = 20;
static constexpr uint32 MEAL_LOW            = 10;
static constexpr float  MEAL_SPEND_SHARE    = 0.25f;

enum class Errand : uint8 { Train, Sell, Repair, Mail, Auction, Runeforge };
enum class Doing  : uint8 { Nothing, Errand, Visit, Sit, Sleep, Fish };

struct ErrandStop
{
    Errand     kind;
    ObjectGuid npc;
};

struct TownState
{
    uint32                  mapId    = 0;
    uint32                  areaId   = 0;
    std::vector<ErrandStop> todo;
    Doing                   doing    = Doing::Nothing;
    ObjectGuid              target;
    float                   spotX = 0, spotY = 0, spotZ = 0;
    bool                    there    = false;
    uint64                  began    = 0;
    uint64                  until    = 0;
    uint64                  nextEmote = 0;
    uint64                  idleUntil = 0;
    uint32                  bedId    = 0;
    float                   facing   = 0.0f;
    uint32                  castsLeft = 0;
    bool                    casting  = false;
    ObjectGuid              mainHand;
    ObjectGuid              offHand;
    ObjectGuid              lastVisit;
    uint64                  helpingSince = 0;
};

struct TravelProgress
{
    uint32 toArea  = 0;
    float  nearest = 0.0f;
    uint64 since   = 0;
    uint32 fails   = 0;
    uint32 reports = 0;
};
struct ArriveClaim { uint32 place = 0; uint64 at = 0; float x = 0.0f, y = 0.0f; };
static std::unordered_map<uint32, std::unordered_map<uint32, ArriveClaim>> sArrive;
static std::unordered_map<uint32, TravelProgress> sTravel;
struct CrossingProgress
{
    float  tx = 0.0f, ty = 0.0f;
    float  nearest = 0.0f;
    uint64 since   = 0;
    uint32 reports = 0;
};
static constexpr float LEG_YARDS = 5.0f;
static std::unordered_map<uint32, CrossingProgress> sCrossTravel;
static std::mutex sTownLock;
static std::unordered_map<uint32, TownState> sTown;

static TownState LoadTown(uint32 guid)
{
    std::lock_guard<std::mutex> lock(sTownLock);
    return sTown[guid];
}
static void StoreTown(uint32 guid, TownState const& s)
{
    std::lock_guard<std::mutex> lock(sTownLock);
    sTown[guid] = s;
}

bool BuddyTownErrandUnderway(uint32 buddyGuid)
{
    std::lock_guard<std::mutex> lock(sTownLock);
    auto it = sTown.find(buddyGuid);
    return it != sTown.end() && it->second.doing == Doing::Errand;
}

bool BuddyTownFishing(uint32 buddyGuid)
{
    std::lock_guard<std::mutex> lock(sTownLock);
    auto it = sTown.find(buddyGuid);
    return it != sTown.end() && it->second.doing == Doing::Fish;
}

static std::mutex sOtherMapLock;
static std::set<uint32> sOtherMapLogged;

static uint64 Now() { return uint64(GameTime::GetGameTimeMS().count()); }

static std::list<Unit*> UnitsNear(Player* bot, float yards)
{
    std::list<Unit*> units;
    Acore::AnyUnitInObjectRangeCheck check(bot, yards);
    Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> searcher(bot, units, check);
    Cell::VisitObjects(bot, searcher, yards);
    return units;
}

static bool InTown(WorldObject* o, uint32 town)
{
    if (o->GetAreaId() == town)
        return true;
    float x = o->GetPositionX(), y = o->GetPositionY();
    if (GridTerrainData* ground = o->GetMap()->GetGridTerrainData(x, y))
        return ground->getArea(x, y) == town;
    return false;
}

static uint32 BagSlots(Player* bot)
{
    uint32 total = INVENTORY_SLOT_ITEM_END - INVENTORY_SLOT_ITEM_START;
    for (uint8 i = INVENTORY_SLOT_BAG_START; i < INVENTORY_SLOT_BAG_END; ++i)
        if (Bag* bag = bot->GetBagByPos(i))
            total += bag->GetBagSize();
    return total;
}

static float BagFullness(Player* bot)
{
    uint32 total = BagSlots(bot);
    uint32 freeSlots = bot->GetFreeInventorySpace();
    return total ? float(total - std::min(freeSlots, total)) / float(total) : 0.0f;
}

static std::vector<Item*> BagItems(Player* bot)
{
    std::vector<Item*> items;
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

static bool CantSpare(PlayerbotAI* ai, Item* item);
static bool TownHasAuctioneer(Player* bot, uint32 town);

static std::vector<ObjectGuid> Junk(PlayerbotAI* ai, Player* bot)
{
    uint32 town = BuddyTownArea(bot) ? BuddyTownArea(bot) : bot->GetAreaId();
    bool auctionHere = TownHasAuctioneer(bot, town);
    std::vector<ObjectGuid> junk;
    for (Item* item : BagItems(bot))
    {
        ItemTemplate const* proto = item->GetTemplate();
        if (!proto->SellPrice)
            continue;
        if (CantSpare(ai, item) || proto->Class == ITEM_CLASS_CONSUMABLE || proto->Class == ITEM_CLASS_TRADE_GOODS)
            continue;
        bool hasUse = false;
        for (auto const& s : proto->Spells)
            if (s.SpellId && s.SpellTrigger == ITEM_SPELLTRIGGER_ON_USE)
                hasUse = true;
        if (hasUse)
            continue;
        if (proto->Quality >= ITEM_QUALITY_UNCOMMON && !item->IsSoulBound())
            continue;
        if (auctionHere && proto->Quality != ITEM_QUALITY_POOR &&
            ai->GetAiObjectContext()->GetValue<ItemUsage>("item usage", item->GetEntry())->Get() == ITEM_USAGE_AH)
            continue;
        junk.push_back(item->GetGUID());
    }
    return junk;
}

static std::vector<Item*> Disposable(PlayerbotAI* ai, Player* bot)
{
    std::vector<Item*> out;
    for (Item* item : BagItems(bot))
    {
        ItemTemplate const* proto = item->GetTemplate();
        if (!proto->SellPrice)
            continue;
        ItemUsage usage = ai->GetAiObjectContext()->GetValue<ItemUsage>("item usage", item->GetEntry())->Get();
        if (proto->Quality == ITEM_QUALITY_POOR || usage == ITEM_USAGE_VENDOR || usage == ITEM_USAGE_AH)
            out.push_back(item);
    }
    return out;
}

static bool AnythingWorn(Player* bot)
{
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        if (Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            if (item->GetUInt32Value(ITEM_FIELD_MAXDURABILITY) &&
                item->GetUInt32Value(ITEM_FIELD_DURABILITY) < item->GetUInt32Value(ITEM_FIELD_MAXDURABILITY))
                return true;
    return false;
}

static Trainer::Trainer* ClassLessons(Creature* npc, Player* bot)
{
    if (!npc->IsTrainer())
        return nullptr;
    Trainer::Trainer* trainer = sObjectMgr->GetTrainer(npc->GetEntry());
    if (!trainer || trainer->GetTrainerType() != Trainer::Type::Class || !trainer->IsTrainerValidForPlayer(bot))
        return nullptr;
    for (Trainer::Spell const& spell : trainer->GetSpells())
        if (trainer->CanTeachSpell(bot, &spell))
            return trainer;
    return nullptr;
}

static bool Townsperson(Creature* c, Player* bot, uint32 areaId)
{
    if (c->IsInCombat() || c->IsHostileTo(bot) || c->IsCritter() || c->IsTotem() || c->IsPet() || c->IsGuardian())
        return false;
    if (!c->GetCharmerOrOwnerGUID().IsEmpty() || !InTown(c, areaId))
        return false;
    return c->GetCreatureType() == CREATURE_TYPE_HUMANOID || c->GetNpcFlags() != UNIT_NPC_FLAG_NONE;
}

static bool MailWaiting(Player* bot)
{
    time_t now = GameTime::GetGameTime().count();
    for (Mail const* m : bot->GetMails())
    {
        if (!m || m->state == MAIL_STATE_DELETED || m->deliver_time > now || m->COD != 0 || (m->items.empty() && !m->money))
            continue;
        if (m->money || m->sender != bot->GetGUID().GetCounter() || m->subject != "Kept for you")
            return true;
        for (MailItemInfo const& mi : m->items)
            if (Item* waiting = bot->GetMItem(mi.item_guid); waiting && bot->CanUseItem(waiting) == EQUIP_ERR_OK)
                return true;
    }
    return false;
}

static GameObject* NearestMailbox(Player* bot)
{
    std::list<GameObject*> objects;
    Acore::GameObjectInRangeCheck check(bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ(), TOWN_SCAN_YARDS);
    Acore::GameObjectListSearcher<Acore::GameObjectInRangeCheck> searcher(bot, objects, check);
    Cell::VisitObjects(bot, searcher, TOWN_SCAN_YARDS);
    GameObject* best = nullptr;
    for (GameObject* go : objects)
        if (go->GetGoType() == GAMEOBJECT_TYPE_MAILBOX && go->isSpawned() &&
            (!best || bot->GetDistance(go) < bot->GetDistance(best)))
            best = go;
    return best;
}

static constexpr uint32 RUNE_SPELLS[] = { 53323, 53331, 53341, 53342, 53343, 53344, 54446, 54447, 62158, 70164 };

static GameObject* NearestRuneforge(Player* bot)
{
    SpellInfo const* rune = sSpellMgr->GetSpellInfo(RUNE_SPELLS[0]);
    if (!rune || !rune->RequiresSpellFocus)
        return nullptr;
    std::list<GameObject*> objects;
    Acore::GameObjectInRangeCheck check(bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ(), TOWN_SCAN_YARDS);
    Acore::GameObjectListSearcher<Acore::GameObjectInRangeCheck> searcher(bot, objects, check);
    Cell::VisitObjects(bot, searcher, TOWN_SCAN_YARDS);
    GameObject* best = nullptr;
    for (GameObject* go : objects)
        if (go->GetGoType() == GAMEOBJECT_TYPE_SPELL_FOCUS && go->GetGOInfo()->spellFocus.focusId == rune->RequiresSpellFocus
            && go->isSpawned() && (!best || bot->GetDistance(go) < bot->GetDistance(best)))
            best = go;
    return best;
}

static void DoRuneforge(PlayerbotAI* ai, Player* bot, GameObject* )
{
    Player* owner = ai->GetMaster();
    for (uint8 slot : { uint8(EQUIPMENT_SLOT_MAINHAND), uint8(EQUIPMENT_SLOT_OFFHAND) })
    {
        Item* weapon = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        if (!weapon || weapon->GetTemplate()->Class != ITEM_CLASS_WEAPON)
            continue;
        uint32 kindBit = 1u << weapon->GetTemplate()->SubClass;
        uint32 current = weapon->GetEnchantmentId(PERM_ENCHANTMENT_SLOT);
        std::vector<std::pair<uint32, SpellInfo const*>> suits;
        for (uint32 id : RUNE_SPELLS)
            if (SpellInfo const* s = sSpellMgr->GetSpellInfo(id))
                if (s->EquippedItemClass == ITEM_CLASS_WEAPON && (s->EquippedItemSubClassMask & kindBit))
                    for (SpellEffectInfo const& e : s->GetEffects())
                        if (e.IsEffect(SPELL_EFFECT_ENCHANT_ITEM) && uint32(e.MiscValue) != current
                            && sSpellItemEnchantmentStore.LookupEntry(uint32(e.MiscValue)))
                            suits.push_back({ uint32(e.MiscValue), s });
        if (suits.empty())
        {
            LOG_INFO("module", "mod-buddies: buddy {} found no other rune to suit its {}", bot->GetName(), weapon->GetTemplate()->Name1);
            continue;
        }
        auto const& [enchant, spell] = suits[urand(0, uint32(suits.size()) - 1)];
        bot->ApplyEnchantment(weapon, PERM_ENCHANTMENT_SLOT, false);
        weapon->SetEnchantment(PERM_ENCHANTMENT_SLOT, enchant, 0, 0, bot->GetGUID());
        bot->ApplyEnchantment(weapon, PERM_ENCHANTMENT_SLOT, true);
        std::string line = "I switched to " + std::string(spell->SpellName[0]) + " on my " + weapon->GetTemplate()->Name1 + ".";
        if (owner && owner->IsInWorld())
            bot->Whisper(line, LANG_UNIVERSAL, owner);
        LOG_INFO("module", "mod-buddies: buddy {} runeforged its {} with {} (enchantment {})", bot->GetName(),
            weapon->GetTemplate()->Name1, spell->SpellName[0], enchant);
    }
}

static void CountAuctionMail(Player* bot, Mail const* m);
static void MailToOwner(PlayerbotAI* ai, Player* bot);
static void DoMail(PlayerbotAI* ai, Player* bot, GameObject* box)
{
    time_t now = GameTime::GetGameTime().count();
    std::vector<uint32> ids;
    for (Mail const* m : bot->GetMails())
        if (m && m->state != MAIL_STATE_DELETED && m->deliver_time <= now && m->COD == 0)
            ids.push_back(m->messageID);
    WorldSession* session = bot->GetSession();
    for (uint32 id : ids)
    {
        Mail* m = bot->GetMail(id);
        if (!m)
            continue;
        CountAuctionMail(bot, m);
        bool kept = m->sender == bot->GetGUID().GetCounter() && m->subject == "Kept for you";
        std::vector<ObjectGuid::LowType> items;
        for (MailItemInfo const& mi : m->items)
        {
            if (kept)
                if (Item* waiting = bot->GetMItem(mi.item_guid); waiting && bot->CanUseItem(waiting) != EQUIP_ERR_OK)
                    continue;
            items.push_back(mi.item_guid);
        }
        for (ObjectGuid::LowType low : items)
        {
            WorldPacket p(CMSG_MAIL_TAKE_ITEM);
            p << box->GetGUID() << id << uint32(low);
            session->HandleMailTakeItem(p);
            ObjectGuid taken = ObjectGuid::Create<HighGuid::Item>(low);
            if (bot->GetItemByGuid(taken))
                BuddyItemArrived(bot->GetGUID().GetCounter(), taken);
        }
        m = bot->GetMail(id);
        if (m && m->money)
        {
            WorldPacket p(CMSG_MAIL_TAKE_MONEY);
            p << box->GetGUID() << id;
            session->HandleMailTakeMoney(p);
        }
        m = bot->GetMail(id);
        if (m && m->items.empty() && !m->money)
        {
            WorldPacket p(CMSG_MAIL_DELETE);
            p << box->GetGUID() << id << uint32(0);
            session->HandleMailDelete(p);
        }
    }
    MailToOwner(ai, bot);
}

static constexpr uint32 AH_GLUT          = 5;
static constexpr float  AH_UNDERCUT_GEAR = 0.90f;
static constexpr float  AH_UNDERCUT_REST = 0.95f;
static constexpr float  AH_RISE          = 0.5f;
static constexpr uint32 AH_MIN_GEAR = 48 * 60, AH_MIN_GOODS = 12 * 60, AH_MIN_REST = 24 * 60;

enum class Fate : uint8 { Keep, Auction, Vendor, MailOwner };

static std::mutex sAuctionLock;
static std::unordered_map<uint32, std::set<ObjectGuid>> sToVendor;
static std::unordered_map<uint32, std::set<uint32>>     sMailSeen;

static bool IsGear(ItemTemplate const* p) { return p->Class == ITEM_CLASS_WEAPON || p->Class == ITEM_CLASS_ARMOR; }

static uint32 FixedPrice(uint32 entry)
{
    if (QueryResult r = CharacterDatabase.Query("SELECT price FROM buddy_fixed_price WHERE item = {}", entry))
        return (*r)[0].Get<uint32>();
    return 0;
}

static constexpr float OWNER_UPGRADE_MARGIN = 1.05f;
static bool OwnerUpgrade(PlayerbotAI* ai, Item* item)
{
    Player* owner = ai->GetMaster();
    ItemTemplate const* p = item->GetTemplate();
    if (!owner || !owner->IsInWorld() || !IsGear(p) || item->IsSoulBound())
        return false;
    if (owner->CanUseItem(p) != EQUIP_ERR_OK)
        return false;
    uint8 slot = owner->FindEquipSlot(p, NULL_SLOT, true);
    if (slot == NULL_SLOT)
        return false;
    Item* worn = owner->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
    if (!worn)
        return true;
    StatsWeightCalculator scorer(owner);
    scorer.SetOverflowPenalty(false);
    float mine = scorer.CalculateItem(p->ItemId, item->GetItemRandomPropertyId());
    float now  = scorer.CalculateItem(worn->GetEntry(), worn->GetItemRandomPropertyId());
    return mine > now * OWNER_UPGRADE_MARGIN;
}

static Fate FateOf(PlayerbotAI* ai, Item* item)
{
    ItemTemplate const* p = item->GetTemplate();
    if (p->Quality < ITEM_QUALITY_UNCOMMON)
        return Fate::Keep;
    if (p->Class == ITEM_CLASS_QUEST || p->Class == ITEM_CLASS_KEY || p->Class == ITEM_CLASS_CONTAINER)
        return Fate::Keep;
    ItemUsage u = ai->GetAiObjectContext()->GetValue<ItemUsage>("item usage", item->GetEntry())->Get();
    switch (u)
    {
        case ITEM_USAGE_EQUIP: case ITEM_USAGE_REPLACE: case ITEM_USAGE_BROKEN_EQUIP: case ITEM_USAGE_QUEST:
        case ITEM_USAGE_SKILL: case ITEM_USAGE_USE: case ITEM_USAGE_KEEP: case ITEM_USAGE_AMMO: case ITEM_USAGE_GUILD_TASK:
            return Fate::Keep;
        default:
            break;
    }
    if (OwnerUpgrade(ai, item))
        return Fate::MailOwner;
    if (p->Quality >= ITEM_QUALITY_EPIC && IsGear(p) && p->RequiredLevel > 0)
    {
        if (item->IsSoulBound())
            return Fate::Vendor;
        if (p->Bonding == BIND_WHEN_EQUIPPED)
            return Fate::MailOwner;
    }
    if (item->IsSoulBound())
        return Fate::Keep;
    if (!p->SellPrice && !FixedPrice(p->ItemId))
        return Fate::Keep;
    return Fate::Auction;
}

static std::vector<Item*> ItemsForOwner(PlayerbotAI* ai, Player* bot)
{
    std::vector<Item*> out;
    for (Item* item : BagItems(bot))
        if (FateOf(ai, item) == Fate::MailOwner)
            out.push_back(item);
    return out;
}

static bool AnythingToAuction(PlayerbotAI* ai, Player* bot)
{
    for (Item* item : BagItems(bot))
        if (FateOf(ai, item) == Fate::Auction)
            return true;
    return false;
}

static void DoAuction(PlayerbotAI* ai, Player* bot, Creature* npc)
{
    AuctionHouseEntry const* ahEntry = AuctionHouseMgr::GetAuctionHouseEntryFromFactionTemplate(npc->GetFaction());
    AuctionHouseObject* house = sAuctionMgr->GetAuctionsMap(npc->GetFaction());
    if (!ahEntry || !house)
        return;
    uint32 pool = ahEntry->houseId;
    uint32 guid = bot->GetGUID().GetCounter();

    struct Lot { uint32 entry = 0; int32 prop = 0; std::vector<std::pair<ObjectGuid, uint32>> items; uint32 total = 0; };
    std::map<std::pair<uint32, int32>, Lot> lots;
    std::set<ObjectGuid> toVendor;
    for (Item* item : BagItems(bot))
    {
        Fate f = FateOf(ai, item);
        if (f == Fate::Vendor)
            toVendor.insert(item->GetGUID());
        if (f != Fate::Auction)
            continue;
        Lot& lot = lots[{ item->GetEntry(), item->GetItemRandomPropertyId() }];
        lot.entry = item->GetEntry(), lot.prop = item->GetItemRandomPropertyId();
        lot.items.push_back({ item->GetGUID(), item->GetCount() });
        lot.total += item->GetCount();
    }

    bool broke = false;
    for (auto& [key, lot] : lots)
    {
        ItemTemplate const* p = sObjectMgr->GetItemTemplate(lot.entry);
        auto vendorLot = [&]() { for (auto const& it : lot.items) toVendor.insert(it.first); };
        if (broke)
        {
            vendorLot();
            continue;
        }
        uint32 listed = 0, lowest = 0;
        for (auto const& [id, a] : house->GetAuctions())
        {
            if (a->item_template != lot.entry)
                continue;
            Item* listedItem = sAuctionMgr->GetAItem(a->item_guid);
            if (listedItem && listedItem->GetItemRandomPropertyId() != lot.prop)
                continue;
            ++listed;
            if (a->buyout && a->itemCount)
                if (uint32 unit = a->buyout / a->itemCount; !lowest || unit < lowest)
                    lowest = unit;
        }
        bool epic = p->Quality >= ITEM_QUALITY_EPIC, gear = IsGear(p);
        uint32 price = 0;
        if (!p->SellPrice)
            price = FixedPrice(lot.entry);
        else
        {
            uint32 minimum = uint32(float(p->SellPrice) * (1.0f + 0.5f * float(p->Quality - ITEM_QUALITY_NORMAL)));
            if (listed >= AH_GLUT && !epic)
            {
                vendorLot();
                continue;
            }
            if (!lowest)
            {
                price = minimum;
                if (QueryResult r = CharacterDatabase.Query(
                        "SELECT steps, last_price FROM buddy_price WHERE pool = {} AND item = {}", pool, lot.entry))
                    if ((*r)[0].Get<uint32>() > 0)
                        price = std::max(minimum, (*r)[1].Get<uint32>());
            }
            else
            {
                uint32 under = uint32(float(lowest) * (gear ? AH_UNDERCUT_GEAR : AH_UNDERCUT_REST));
                if (under >= minimum)
                    price = under;
                else if ((epic || listed < AH_GLUT) && minimum < lowest)
                    price = minimum;
                else if (gear)
                {
                    vendorLot();
                    continue;
                }
                else
                    price = minimum;
            }
        }
        if (!price)
            continue;
        uint32 minutes = gear ? AH_MIN_GEAR : p->Class == ITEM_CLASS_TRADE_GOODS ? AH_MIN_GOODS : AH_MIN_REST;

        uint32 maxStack = std::max<uint32>(1, p->GetMaxStackSize());
        std::vector<uint32> stacks;
        for (uint32 left = lot.total; left; )
        {
            uint32 n = lot.total > maxStack ? std::min(left, urand(1, maxStack)) : left;
            stacks.push_back(n);
            left -= n;
        }
        size_t next = 0;
        uint32 usedOfNext = 0;
        for (uint32 n : stacks)
        {
            std::vector<std::pair<ObjectGuid, uint32>> parts;
            for (uint32 need = n; need && next < lot.items.size(); )
            {
                uint32 take = std::min(need, lot.items[next].second - usedOfNext);
                parts.push_back({ lot.items[next].first, take });
                need -= take, usedOfNext += take;
                if (usedOfNext == lot.items[next].second)
                    ++next, usedOfNext = 0;
            }
            Item* first = bot->GetItemByGuid(parts.front().first);
            if (!first)
                continue;
            uint32 deposit = AuctionHouseMgr::GetAuctionDeposit(ahEntry, minutes * MINUTE, first, n);
            if (!bot->HasEnoughMoney(deposit))
            {
                broke = true;
                vendorLot();
                break;
            }
            WorldPacket req(CMSG_AUCTION_SELL_ITEM);
            req << npc->GetGUID() << uint32(parts.size());
            for (auto const& part : parts)
                req << part.first << part.second;
            req << uint32(price * n) << uint32(price * n) << minutes;
            bot->GetSession()->HandleAuctionSellItem(req);
        }
        if (!broke)
            CharacterDatabase.Execute("INSERT INTO buddy_price (pool, item, steps, last_price, updated) VALUES ({}, {}, 0, {}, UNIX_TIMESTAMP()) "
                "ON DUPLICATE KEY UPDATE last_price = {}, updated = UNIX_TIMESTAMP()", pool, lot.entry, price, price);
    }
    BuddyBuyGemsAtAuction(bot, npc);
    std::lock_guard<std::mutex> lock(sAuctionLock);
    sToVendor[guid].insert(toVendor.begin(), toVendor.end());
}

static void CountAuctionMail(Player* bot, Mail const* m)
{
    if (m->messageType != MAIL_AUCTION)
        return;
    {
        std::lock_guard<std::mutex> lock(sAuctionLock);
        if (!sMailSeen[bot->GetGUID().GetCounter()].insert(m->messageID).second)
            return;
    }
    uint32 entry = 0, zero = 0, outcome = 0;
    if (std::sscanf(m->subject.c_str(), "%u:%u:%u", &entry, &zero, &outcome) != 3 || !entry)
        return;
    ItemTemplate const* p = sObjectMgr->GetItemTemplate(entry);
    if (!p)
        return;
    if (outcome == AUCTION_SUCCESSFUL || outcome == AUCTION_SALE_PENDING)
        CharacterDatabase.Execute("UPDATE buddy_price SET steps = 0 WHERE pool = {} AND item = {}", m->sender, entry);
    else if (outcome == AUCTION_EXPIRED)
        CharacterDatabase.Execute("UPDATE buddy_price SET steps = steps + 1, last_price = last_price + {}, updated = UNIX_TIMESTAMP() "
            "WHERE pool = {} AND item = {}", uint32(float(p->SellPrice) * AH_RISE), m->sender, entry);
}

static constexpr float  TREAT_CHANCE          = 0.10f;
static constexpr float  TREAT_PURSE_CHANCE    = 0.25f;
static constexpr uint32 TREAT_PURSE_PER_LEVEL2 = 28;
static char const* const PENNY_LINE = "I found a lucky penny for you.";
static char const* const TREAT_LINES[] = {
    "Some coin from the road. Spend it on something shiny.",
    "Took this off a brute who swung first. Buy yourself a whetstone.",
    "The Light provides, and today it provided this. Share it well.",
    "Found this in a nest my pet dug up. Don't ask what else was in there.",
    "this fell out of some rich guy's pocket while I was walking close behind him in Stormwind, don't worry about it",
    "An offering left at a shrine. I'm sure they meant it for you.",
    "The dead don't need it. I asked.",
    "The spirits pointed me to it under a stone. Thank them, not me.",
    "Conjured? No. Found. Probably. Enjoy it.",
    "A small contract, fulfilled. Your share.",
    "Squirrels hoard the strangest things.",
    "A bear was sitting on it. I asked nicely.",
};

static void MailToOwner(PlayerbotAI* ai, Player* bot)
{
    std::vector<Item*> items = ItemsForOwner(ai, bot);
    uint32 money = 0;
    std::string line = "Found this and thought of you.";
    if (rand_norm() < TREAT_CHANCE)
    {
        uint32 purse = bot->GetLevel() * bot->GetLevel() * TREAT_PURSE_PER_LEVEL2;
        if (rand_norm() < TREAT_PURSE_CHANCE && bot->GetMoney() >= purse)
        {
            money = purse;
            uint8 cls = bot->getClass();
            line = TREAT_LINES[cls < std::size(TREAT_LINES) ? cls : 0];
        }
        else
        {
            money = 1;
            line  = PENNY_LINE;
        }
    }
    if (items.empty() && !money)
        return;
    QueryResult row = CharacterDatabase.Query("SELECT owner FROM buddy_roster WHERE buddy = {}", bot->GetGUID().GetCounter());
    if (!row)
        return;
    ObjectGuid owner = ObjectGuid::Create<HighGuid::Player>((*row)[0].Get<uint32>());
    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    MailDraft draft("For the clan", line);
    if (money)
    {
        if (money > 1)
            bot->ModifyMoney(-int32(money));
        draft.AddMoney(money);
    }
    uint32 n = 0;
    for (Item* item : items)
    {
        if (n == MAX_MAIL_ITEMS)
            break;
        bot->MoveItemFromInventory(item->GetBagSlot(), item->GetSlot(), true);
        item->DeleteFromInventoryDB(trans);
        item->SetOwnerGUID(owner);
        item->SaveToDB(trans);
        draft.AddItem(item);
        ++n;
    }
    draft.SendMailTo(trans, MailReceiver(ObjectAccessor::FindConnectedPlayer(owner), owner.GetCounter()), MailSender(bot), MAIL_CHECK_MASK_COPIED);
    CharacterDatabase.CommitTransaction(trans);
}

struct MealKind { AuraType regen; bool manaOnly; };
static MealKind const MEAL_KINDS[] = {
    { SPELL_AURA_MOD_REGEN,       false },
    { SPELL_AURA_MOD_POWER_REGEN, true  },
};

static bool WantsMeal(Player* bot, MealKind const& k) { return !k.manaOnly || bot->getPowerType() == POWER_MANA; }

static bool IsMealFor(Player* bot, ItemTemplate const* p, AuraType regen)
{
    if (p->Class != ITEM_CLASS_CONSUMABLE || p->SubClass != ITEM_SUBCLASS_FOOD)
        return false;
    SpellInfo const* spell = sSpellMgr->GetSpellInfo(uint32(p->Spells[0].SpellId));
    return spell && spell->HasAura(regen) && bot->CanUseItem(p) == EQUIP_ERR_OK;
}

static uint32 MealsCarried(Player* bot, AuraType regen)
{
    uint32 n = 0;
    for (Item* item : BagItems(bot))
        if (IsMealFor(bot, item->GetTemplate(), regen))
            n += item->GetCount();
    return n;
}

static bool MealOnSale(Creature* npc, Player* bot, AuraType regen, uint32& slot, ItemTemplate const*& best)
{
    best = nullptr;
    VendorItemData const* items = npc->GetVendorItems();
    if (!items)
        return false;
    for (uint32 i = 0; i < items->GetItemCount(); ++i)
    {
        VendorItem const* v = items->GetItem(i);
        if (!v || v->ExtendedCost)
            continue;
        ItemTemplate const* p = sObjectMgr->GetItemTemplate(v->item);
        if (!p || !IsMealFor(bot, p, regen))
            continue;
        if (!best || p->ItemLevel > best->ItemLevel)
            best = p, slot = i;
    }
    return best != nullptr;
}

static bool HungryFor(Creature* npc, Player* bot, uint32 below)
{
    for (MealKind const& k : MEAL_KINDS)
    {
        uint32 slot = 0;
        ItemTemplate const* p = nullptr;
        if (WantsMeal(bot, k) && MealsCarried(bot, k.regen) < below && MealOnSale(npc, bot, k.regen, slot, p))
            return true;
    }
    return false;
}

static void BuyMeals(Player* bot, Creature* npc)
{
    if (!npc->IsVendor())
        return;
    uint32 budget = uint32(float(bot->GetMoney()) * MEAL_SPEND_SHARE);
    uint32 spent  = 0;
    float  discount = bot->GetReputationPriceDiscount(npc);
    for (MealKind const& k : MEAL_KINDS)
    {
        if (!WantsMeal(bot, k))
            continue;
        uint32 slot = 0;
        ItemTemplate const* p = nullptr;
        if (!MealOnSale(npc, bot, k.regen, slot, p))
            continue;
        uint32 have  = MealsCarried(bot, k.regen);
        uint32 price = uint32(std::floor(float(p->BuyPrice) * discount));
        uint32 per   = std::max<uint32>(1, p->BuyCount);
        while (have < MEAL_STOCK && spent + price <= budget)
        {
            if (!bot->BuyItemFromVendorSlot(npc->GetGUID(), slot, p->ItemId, 1, NULL_BAG, NULL_SLOT))
                break;
            spent += price;
            have  += per;
        }
    }
}

static constexpr uint32 HEARTHSTONE = 6948;

static bool SellItem(Player* bot, Creature* npc, Item* item)
{
    ObjectGuid itemGuid = item->GetGUID();
    WorldPacket p(CMSG_SELL_ITEM);
    p << npc->GetGUID() << itemGuid << uint32(item->GetCount());
    WorldPackets::Item::SellItem request(std::move(p));
    request.Read();
    bot->GetSession()->HandleSellItemOpcode(request);
    return bot->GetItemByGuid(itemGuid) == nullptr;
}

static bool CantSpare(PlayerbotAI* ai, Item* item)
{
    ItemTemplate const* p = item->GetTemplate();
    if (p->ItemId == HEARTHSTONE || p->TotemCategory)
        return true;
    if (p->Class == ITEM_CLASS_WEAPON && p->SubClass == ITEM_SUBCLASS_WEAPON_FISHING_POLE)
        return true;
    if (BuddyIsKeptWeapon(ai->GetBot(), item))
        return true;
    if (FateOf(ai, item) == Fate::MailOwner)
        return true;
    switch (ai->GetAiObjectContext()->GetValue<ItemUsage>("item usage", item->GetEntry())->Get())
    {
        case ITEM_USAGE_EQUIP: case ITEM_USAGE_REPLACE: case ITEM_USAGE_BROKEN_EQUIP:
        case ITEM_USAGE_QUEST: case ITEM_USAGE_AMMO:
            return true;
        default:
            return false;
    }
}

struct ClearRound { char const* name; bool (*maySell)(PlayerbotAI*, Item*); bool halfTheSpace; };
static bool RoundLowestHalf(PlayerbotAI*, Item* i) { uint32 c = i->GetTemplate()->Class; return c != ITEM_CLASS_CONSUMABLE && c != ITEM_CLASS_TRADE_GOODS; }
static bool RoundTradeGoods(PlayerbotAI*, Item* i) { return i->GetTemplate()->Class == ITEM_CLASS_TRADE_GOODS; }
static bool RoundConsumable(PlayerbotAI*, Item* i) { return i->GetTemplate()->Class == ITEM_CLASS_CONSUMABLE; }
static ClearRound const CLEAR_ROUNDS[] = {
    { "the lowest-value half", RoundLowestHalf, true  },
    { "trade goods",           RoundTradeGoods, false },
    { "consumables",           RoundConsumable, false },
};

static bool TownHasAuctioneer(Player* bot, uint32 town)
{
    for (Unit* u : UnitsNear(bot, TOWN_SCAN_YARDS))
        if (Creature* c = u->ToCreature())
            if (c->IsAuctioner() && !c->IsHostileTo(bot) && InTown(c, town))
                return true;
    return false;
}

static void ClearFullBags(PlayerbotAI* ai, Player* bot, Creature* npc, uint32 town)
{
    uint32 slots  = BagSlots(bot);
    float  before = BagFullness(bot);
    std::string done;
    for (ClearRound const& round : CLEAR_ROUNDS)
    {
        if (BagFullness(bot) < FULL_BAGS_SHARE)
            break;
        std::vector<Item*> pile;
        for (Item* item : BagItems(bot))
            if (item->GetTemplate()->SellPrice && !CantSpare(ai, item) && round.maySell(ai, item))
                pile.push_back(item);
        std::sort(pile.begin(), pile.end(), [](Item* a, Item* b)
        {
            uint64 va = uint64(a->GetTemplate()->SellPrice) * a->GetCount();
            uint64 vb = uint64(b->GetTemplate()->SellPrice) * b->GetCount();
            return va != vb ? va < vb : a->GetEntry() < b->GetEntry();
        });
        uint32 sold = 0, refused = 0;
        for (Item* item : pile)
        {
            if (round.halfTheSpace ? sold >= slots / 2 : BagFullness(bot) < FULL_BAGS_SHARE)
                break;
            if (SellItem(bot, npc, item))
                ++sold;
            else
                ++refused;
        }
        done += Acore::StringFormat("{}: {} sold{}, bags then {:.0f}% full; ", round.name, sold,
            refused ? Acore::StringFormat(" ({} refused by the vendor)", refused) : std::string(), BagFullness(bot) * 100.0f);
    }
    if (BagFullness(bot) < FULL_BAGS_SHARE)
        return;

    uint32 spared = 0, unsellable = 0, other = 0;
    for (Item* item : BagItems(bot))
    {
        if (CantSpare(ai, item))
            ++spared;
        else if (!item->GetTemplate()->SellPrice)
            ++unsellable;
        else
            ++other;
    }
    LOG_ERROR("module", "mod-buddies: buddy {} in town area {} (no auction house) could not clear its full bags at vendor {}. "
        "Done: bags were {:.0f}% full of {} slots; {}"
        "Not done: still {:.0f}% full, at or above the {:.0f}% line. Left: {} it can't spare (hearthstone, tools, gear and "
        "ammo in use, quest items, epics for its owner), {} no vendor buys, {} sellable that no round took. To debug: "
        "were sales refused (is the vendor still in reach; does the sell request reach it)? are the no-price items quest "
        "or mail leftovers (only a mailbox or the bin clears those)? are epics for its owner waiting because this town "
        "has no mailbox (they wait for the next town with one)? is 'sellable that no round took' above 0 (then a round's "
        "item rule misses a kind of item: which class are they)?",
        bot->GetName(), town, npc->GetName(), before * 100.0f, slots, done,
        BagFullness(bot) * 100.0f, FULL_BAGS_SHARE * 100.0f, spared, unsellable, other);
}

static constexpr float YELLOW_SHARE = 0.2f;

static bool WornAtMost(Player* bot, float share)
{
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        if (Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            if (uint32 max = item->GetUInt32Value(ITEM_FIELD_MAXDURABILITY))
                if (float(item->GetUInt32Value(ITEM_FIELD_DURABILITY)) <= share * float(max))
                    return true;
    return false;
}

static std::vector<ErrandStop> BuildTodo(PlayerbotAI* ai, Player* bot, uint32 areaId)
{
    Creature* trainer    = nullptr;
    Creature* vendor     = nullptr;
    Creature* repairer   = nullptr;
    Creature* auctioneer = nullptr;
    Creature* grocer     = nullptr;
    auto nearer = [&](Creature* best, Creature* c) { return !best || bot->GetDistance(c) < bot->GetDistance(best); };
    for (Unit* u : UnitsNear(bot, TOWN_SCAN_YARDS))
    {
        Creature* c = u->ToCreature();
        if (!c || c->IsHostileTo(bot) || !InTown(c, areaId))
            continue;
        if (ClassLessons(c, bot) && nearer(trainer, c))
            trainer = c;
        if (c->IsVendor() && nearer(vendor, c))
            vendor = c;
        if (c->IsVendor() && nearer(grocer, c) && HungryFor(c, bot, MEAL_LOW))
            grocer = c;
        if (c->IsArmorer() && nearer(repairer, c))
            repairer = c;
        if (c->IsAuctioner() && nearer(auctioneer, c))
            auctioneer = c;
    }
    std::vector<ErrandStop> todo;
    bool repairing = false;
    if (repairer && WornAtMost(bot, 0.0f))
        todo.push_back({ Errand::Repair, repairer->GetGUID() }), repairing = true;
    if (trainer)
        todo.push_back({ Errand::Train, trainer->GetGUID() });
    if (repairer && !repairing && WornAtMost(bot, YELLOW_SHARE))
        todo.push_back({ Errand::Repair, repairer->GetGUID() }), repairing = true;
    if (MailWaiting(bot) || !ItemsForOwner(ai, bot).empty())
        if (GameObject* box = NearestMailbox(bot))
            todo.push_back({ Errand::Mail, box->GetGUID() });
    if (bot->getClass() == CLASS_DEATH_KNIGHT)
        if (GameObject* forge = NearestRuneforge(bot))
            todo.push_back({ Errand::Runeforge, forge->GetGUID() });
    bool auctioning = auctioneer && AnythingToAuction(ai, bot);
    if (auctioning)
        todo.push_back({ Errand::Auction, auctioneer->GetGUID() });
    if (repairer && !repairing && AnythingWorn(bot))
        todo.push_back({ Errand::Repair, repairer->GetGUID() });
    bool vendorWork = false;
    {
        std::lock_guard<std::mutex> lock(sAuctionLock);
        auto it = sToVendor.find(bot->GetGUID().GetCounter());
        vendorWork = it != sToVendor.end() && !it->second.empty();
    }
    Creature* shop = grocer ? grocer : vendor;
    bool clearing  = !auctioneer && BagFullness(bot) >= FULL_BAGS_SHARE;
    if (shop && (grocer || clearing || (!Junk(ai, bot).empty() && rand_norm() < BagFullness(bot)) || auctioning || vendorWork))
        todo.push_back({ Errand::Sell, shop->GetGUID() });
    return todo;
}

static void DoTrain(PlayerbotAI* , Player* bot, Creature* npc)
{
    BuddyTrainAtTrainer(bot, npc);
}
static void DoSell(PlayerbotAI* ai, Player* bot, Creature* npc)
{
    std::vector<ObjectGuid> selling = Junk(ai, bot);
    {
        std::lock_guard<std::mutex> lock(sAuctionLock);
        auto it = sToVendor.find(bot->GetGUID().GetCounter());
        if (it != sToVendor.end())
        {
            for (ObjectGuid g : it->second)
                if (std::find(selling.begin(), selling.end(), g) == selling.end())
                    selling.push_back(g);
            sToVendor.erase(it);
        }
    }
    for (ObjectGuid itemGuid : selling)
        if (Item* item = bot->GetItemByGuid(itemGuid))
            SellItem(bot, npc, item);

    uint32 town = BuddyTownArea(bot) ? BuddyTownArea(bot) : bot->GetAreaId();
    if (BagFullness(bot) >= FULL_BAGS_SHARE && !TownHasAuctioneer(bot, town))
        ClearFullBags(ai, bot, npc, town);
    BuyMeals(bot, npc);
}
static void DoRepair(PlayerbotAI* , Player* bot, Creature* npc)
{
    bot->DurabilityRepairAll(true, bot->GetReputationPriceDiscount(npc), false);
    BuyMeals(bot, npc);
}
float BuddyBagFullness(Player* bot) { return BagFullness(bot); }
float BuddyFullBagsShare() { return FULL_BAGS_SHARE; }
void  BuddySellAtVendor(PlayerbotAI* ai, Player* bot, Creature* npc) { DoSell(ai, bot, npc); }
std::vector<Item*> BuddyDisposableItems(PlayerbotAI* ai, Player* bot) { return Disposable(ai, bot); }
std::vector<Item*> BuddyEarmarkedItems(PlayerbotAI* ai, Player* bot) { return ItemsForOwner(ai, bot); }
uint32 BuddyBagSlots(Player* bot) { return BagSlots(bot); }

using ErrandFn = void (*)(PlayerbotAI*, Player*, Creature*);
static std::unordered_map<uint8, ErrandFn> const sErrands = {
    { uint8(Errand::Train),  DoTrain  },
    { uint8(Errand::Sell),   DoSell   },
    { uint8(Errand::Repair), DoRepair },
    { uint8(Errand::Auction), DoAuction },
};

class BuddyTravelStepAction : public NewRpgBaseAction
{
public:
    BuddyTravelStepAction(PlayerbotAI* botAI) : NewRpgBaseAction(botAI, "buddy travel step") { }

    bool isUseful() override
    {
        Player* owner = botAI->GetMaster();
        if (!owner || !owner->IsInWorld() || !bot->IsAlive() || bot->IsInCombat())
            return false;
        if (BuddyCrossingWanted(bot, owner))
            return true;
        if (owner->GetMapId() != bot->GetMapId())
        {
            std::lock_guard<std::mutex> lock(sOtherMapLock);
            if (sOtherMapLogged.insert(bot->GetGUID().GetCounter()).second)
                LOG_INFO("module", "mod-buddies: buddy {} is on map {} and its owner {} on map {}, an instance or a crossing "
                    "paused after a failure (logged as an error then), so it stays for now",
                    bot->GetName(), bot->GetMapId(), owner->GetName(), owner->GetMapId());
            return false;
        }
        if (bot->GetMap()->Instanceable())
            return false;
        if (uint32 town = BuddyTownArea(owner))
            if (BuddyTownArea(bot) == town)
                return false;
        return bot->GetAreaId() != owner->GetAreaId();
    }

    bool Execute(Event ) override
    {
        Player* owner = botAI->GetMaster();
        if (!owner)
            return false;
        if (bot->IsWalking())
            bot->SetWalk(false);
        {
            std::lock_guard<std::mutex> lock(sOtherMapLock);
            sOtherMapLogged.erase(bot->GetGUID().GetCounter());
        }

        if (BuddyCrossingWanted(bot, owner))
        {
            BuddyCrossingMove move;
            if (!BuddyCrossingStep(bot, owner, move))
                return true;
            botAI->rpgInfo.stuckTs = getMSTime();
            botAI->rpgInfo.stuckAttempts = 0;
            if (move.straight)
            {
                bot->GetMotionMaster()->MovePoint(0, move.x, move.y, move.z, FORCED_MOVEMENT_NONE, 0.0f, 0.0f,
                     false,  false);
                return true;
            }
            if (move.mapId == bot->GetMapId())
            {
                uint32 guid = bot->GetGUID().GetCounter();
                uint64 now  = Now();
                float  dist = std::hypot(bot->GetPositionX() - move.x, bot->GetPositionY() - move.y);
                uint32 times = 0;
                {
                    std::lock_guard<std::mutex> lock(sTownLock);
                    CrossingProgress& c = sCrossTravel[guid];
                    if (c.since == 0 || std::hypot(c.tx - move.x, c.ty - move.y) > LEG_YARDS)
                        c = { move.x, move.y, dist, now, 0 };
                    else if (dist + PROGRESS_YARDS < c.nearest)
                    {
                        c.nearest = dist;
                        c.since   = now;
                        c.reports = 0;
                    }
                    else if (now - c.since >= STUCK_MS)
                    {
                        c.nearest = dist;
                        c.since   = now;
                        times = ++c.reports;
                    }
                }
                if (times)
                    ReportStuck("the crossing (a dock, portal or tower) on its way to its owner", move.mapId, move.x, move.y, move.z,
                        dist, "no 10-yard gain toward the crossing in 90 seconds", times);
            }
            return MoveFarTo(WorldPosition(move.mapId, move.x, move.y, move.z));
        }
        BuddyCrossingForget(bot);
        {
            std::lock_guard<std::mutex> lock(sTownLock);
            sCrossTravel.erase(bot->GetGUID().GetCounter());
        }

        uint32 guid = bot->GetGUID().GetCounter();
        uint64 now  = Now();
        float  dist = bot->GetExactDist(owner);
        bool   stuck = false;
        {
            std::lock_guard<std::mutex> lock(sTownLock);
            TravelProgress& p = sTravel[guid];
            if (p.toArea != owner->GetAreaId() || p.since == 0)
                p = { owner->GetAreaId(), dist, now };
            else if (dist + PROGRESS_YARDS < p.nearest)
            {
                p.nearest = dist;
                p.since = now;
            }
            else if (now - p.since >= STUCK_MS)
            {
                stuck = true;
                p.nearest = dist;
                p.since = now;
            }
        }
        if (stuck)
        {
            uint32 times;
            {
                std::lock_guard<std::mutex> lock(sTownLock);
                times = ++sTravel[guid].reports;
            }
            ReportStuck(owner, "no 10-yard gain toward its owner in 90 seconds", times);
        }

        botAI->rpgInfo.stuckTs = getMSTime();
        botAI->rpgInfo.stuckAttempts = 0;
        float ax, ay, az;
        ArrivalPlace(owner, ax, ay, az);
        bool walking = MoveFarTo(WorldPosition(owner->GetMapId(), ax, ay, az));
        if (!walking)
        {
            float tx, ty, tz;
            if (BuddyFollowTrackAhead(owner->GetGUID().GetCounter(), bot->GetPositionX(), bot->GetPositionY(), tx, ty, tz)
                && MoveFarTo(WorldPosition(owner->GetMapId(), tx, ty, tz)))
            {
                BuddyTrace(bot, "travel: no way to its owner's arc; along the owner's track to ({:.0f}, {:.0f})", tx, ty);
                walking = true;
            }
        }
        uint32 fails, times;
        {
            std::lock_guard<std::mutex> lock(sTownLock);
            TravelProgress& p = sTravel[guid];
            p.fails = walking ? 0 : p.fails + 1;
            if (walking)
                p.reports = 0;
            fails = p.fails;
            times = p.reports;
            if (fails >= FAILS_BEFORE_REPORT)
            {
                p.fails = 0;
                times = ++p.reports;
            }
        }
        if (!walking && fails >= FAILS_BEFORE_REPORT)
            ReportStuck(owner, "three long walks in a row found no way (to the owner's arc, nor along the owner's track)", times);
        return walking;
    }

    void ArrivalPlace(Player* owner, float& x, float& y, float& z)
    {
        uint32 me = bot->GetGUID().GetCounter(), boss = owner->GetGUID().GetCounter();
        uint64 now = Now();
        float ox = owner->GetPositionX(), oy = owner->GetPositionY(), oz = owner->GetPositionZ(), oo = owner->GetOrientation();
        std::lock_guard<std::mutex> lock(sTownLock);
        auto& claims = sArrive[boss];
        for (auto it = claims.begin(); it != claims.end();)
            it = (it->first != me && now - it->second.at > ARRIVE_CLAIM_MS) ? claims.erase(it) : std::next(it);
        ArriveClaim& mine = claims[me];
        mine.at = now;
        mine.x  = bot->GetPositionX();
        mine.y  = bot->GetPositionY();

        uint32 n = uint32(claims.size());
        float radius = std::max(ARRIVE_RADIUS, ARRIVE_SPACING * float(n) / (2.0f * float(M_PI)));
        float step   = std::min(ARRIVE_SPACING / radius, 2.0f * float(M_PI) / float(n));
        std::vector<std::pair<float, float>> places(n);
        for (uint32 k = 0; k < n; ++k)
        {
            float a = oo + (float(k) - float(n - 1) / 2.0f) * step;
            places[k] = { ox + std::cos(a) * radius, oy + std::sin(a) * radius };
        }
        struct Pair { float d; uint32 who; uint32 place; };
        std::vector<Pair> pairs;
        for (auto const& [who, c] : claims)
            for (uint32 k = 0; k < n; ++k)
                pairs.push_back({ std::hypot(places[k].first - c.x, places[k].second - c.y), who, k });
        std::sort(pairs.begin(), pairs.end(), [](Pair const& a, Pair const& b) { return a.d < b.d; });
        std::unordered_set<uint32> placed, used;
        for (Pair const& pr : pairs)
        {
            if (placed.count(pr.who) || used.count(pr.place))
                continue;
            claims[pr.who].place = pr.place;
            placed.insert(pr.who);
            used.insert(pr.place);
        }
        x = places[mine.place].first;
        y = places[mine.place].second;
        z = bot->GetMap()->GetHeight(bot->GetPhaseMask(), x, y, oz + 5.0f, true, 15.0f);
        if (z <= INVALID_HEIGHT)
            z = oz;
    }

private:
    void ReportStuck(Player* owner, char const* why, uint32 times)
    {
        std::string goingTo = "its owner " + owner->GetName() + " in area " + std::to_string(owner->GetAreaId());
        ReportStuck(goingTo.c_str(), owner->GetMapId(), owner->GetPositionX(), owner->GetPositionY(), owner->GetPositionZ(),
            bot->GetExactDist(owner), why, times);
    }
    void ReportStuck(char const* goingTo, uint32 mapId, float x, float y, float z, float left, char const* why, uint32 times)
    {
        LOG_ERROR("module", "mod-buddies: STUCK buddy {} on map {} zone {} area {} at ({:.1f}, {:.1f}, {:.1f}), going to {} "
            "on map {} at ({:.1f}, {:.1f}, {:.1f}), {:.0f} yards left: {} (report {} in a row); it stays and keeps trying",
            bot->GetName(), bot->GetMapId(), bot->GetZoneId(), bot->GetAreaId(),
            bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ(),
            goingTo, mapId, x, y, z, left, why, times);
        BuddyTrace(bot, "travel: STUCK, {} (report {} in a row)", why, times);
    }
};

class BuddyTownStepAction : public MovementAction
{
public:
    BuddyTownStepAction(PlayerbotAI* botAI) : MovementAction(botAI, "buddy town step") { }

    bool isUseful() override
    {
        Player* owner = botAI->GetMaster();
        if (!owner || !owner->IsInWorld() || !bot->IsAlive() || bot->IsInCombat())
            return false;
        if (owner->GetMapId() != bot->GetMapId() || bot->GetMap()->Instanceable())
            return false;
        if (bot->GetTransport())
            return false;
        uint32 town = BuddyTownArea(owner);
        return town && BuddyTownArea(bot) == town;
    }

    bool WalkTo(WorldObject* to, float nearYards)
    {
        if (bot->movespline->Finalized() && BuddyTurnToward(bot, bot->GetAngle(to)))
            return true;
        Player* owner = botAI->GetMaster();
        uint32 town = owner ? BuddyTownArea(owner) : 0;
        if (town && bot->GetDistance(to) > MAP_WALK_YARDS)
        {
            BuddyRoam::Point goal { to->GetPositionX(), to->GetPositionY(), to->GetPositionZ() }, next;
            if (BuddyExploreStepToward(bot, owner, town, goal, MAP_LOOKAHEAD_YARDS, next))
            {
                BuddyTrace(bot, "town: toward {} by the town's distance map, next ({:.1f}, {:.1f}, {:.1f})",
                    to->GetName(), next.x, next.y, next.z);
                return MoveTo(bot->GetMapId(), next.x, next.y, next.z);
            }
            BuddyTrace(bot, "town: toward {} by the bot module's walking (no distance map: the town's grid isn't ready, "
                "or {} is off it)", to->GetName(), to->GetName());
        }
        return MoveNear(to, nearYards);
    }

    bool Execute(Event ) override
    {
        uint32 guid   = bot->GetGUID().GetCounter();
        uint32 areaId = BuddyTownArea(bot) ? BuddyTownArea(bot) : bot->GetAreaId();
        uint64 now    = Now();
        TownState s   = LoadTown(guid);

        if (!bot->IsWalking())
            bot->SetWalk(true);

        if (s.areaId != areaId || s.mapId != bot->GetMapId())
        {
            StandUp();
            s = TownState();
            s.areaId = areaId;
            s.mapId  = bot->GetMapId();
            s.todo   = BuildTodo(botAI, bot, areaId);
        }

        if (HelpTheGuards(s, areaId, now))
        {
            StoreTown(guid, s);
            return true;
        }

        if (s.doing == Doing::Nothing)
        {
            if (now < s.idleUntil)
            {
                StoreTown(guid, s);
                return false;
            }
            if (!s.todo.empty())
            {
                NextErrandFirst(s);
                Begin(s, Doing::Errand, s.todo.front().npc, now);
            }
            else
                ChoosePastime(s, areaId, now);
        }

        bool acted = false;
        switch (s.doing)
        {
            case Doing::Errand: acted = RunErrand(s, now); break;
            case Doing::Visit:  acted = RunVisit(s, now);  break;
            case Doing::Sit:    acted = RunSit(guid, s, now); break;
            case Doing::Sleep:  acted = RunSleep(s, now);  break;
            case Doing::Fish:   acted = RunFish(s, now);   break;
            case Doing::Nothing: break;
        }
        StoreTown(guid, s);
        return acted;
    }

private:
    bool HelpTheGuards(TownState& s, uint32 areaId, uint64 now)
    {
        Creature* foe   = nullptr;
        float     foeD  = HELP_YARDS + 1.0f;
        for (Unit* u : UnitsNear(bot, HELP_YARDS))
        {
            Creature* c = u->ToCreature();
            if (!c || !c->IsAlive() || !c->IsInCombat() || !c->IsHostileTo(bot))
                continue;
            Unit* victim = c->GetVictim();
            if (!victim || victim->IsHostileTo(bot) || !InTown(c, areaId))
                continue;
            float d = bot->GetDistance(c);
            if (d < foeD)
            {
                foe  = c;
                foeD = d;
            }
        }
        if (!foe)
        {
            s.helpingSince = 0;
            return false;
        }

        bool errandsWaiting = !s.todo.empty();
        if (errandsWaiting && s.helpingSince && now - s.helpingSince > ERRAND_PATIENCE_MS)
            return false;
        if (errandsWaiting && !s.helpingSince)
            s.helpingSince = now;

        if (s.doing == Doing::Errand)
            s.began = now;
        else if (s.doing != Doing::Nothing)
            Finish(s, now);
        StandUp();

        bool melee = botAI->IsMelee(bot);
        bot->SetSelection(foe->GetGUID());
        context->GetValue<Unit*>("current target")->Set(foe);
        botAI->ChangeEngine(BOT_STATE_COMBAT);
        bot->Attack(foe, melee);
        if (melee)
            bot->GetMotionMaster()->MoveChase(foe);
        BuddyTrace(bot, "town: helping against {} ({:.0f} yards, fighting {})",
            foe->GetName(), foeD, foe->GetVictim()->GetName());
        return true;
    }

    void Begin(TownState& s, Doing what, ObjectGuid target, uint64 now)
    {
        s.doing = what;
        s.target = target;
        s.there = false;
        s.began = now;
        s.until = 0;
    }
    void Finish(TownState& s, uint64 now)
    {
        if (s.bedId)
            BuddyReleaseBed(s.bedId, bot->GetGUID().GetCounter());
        s.bedId = 0;
        if (s.doing == Doing::Fish)
            PutPoleAway(s);
        StandUp();
        s.doing = Doing::Nothing;
        s.target.Clear();
        s.there = false;
        s.idleUntil = now + urand(GAP_MIN_MS, GAP_MAX_MS);
    }
    void StandUp()
    {
        if (bot->getStandState() != UNIT_STAND_STATE_STAND)
            bot->SetStandState(UNIT_STAND_STATE_STAND);
    }
    bool TooLong(TownState const& s, uint64 now) { return !s.there && now - s.began > WALK_GIVE_UP_MS; }
    void Emote(TownState& s, uint64 now, uint32 emote)
    {
        if (now < s.nextEmote)
            return;
        bot->HandleEmoteCommand(emote);
        s.nextEmote = now + urand(EMOTE_MIN_MS, EMOTE_MAX_MS);
    }

    void NextErrandFirst(TownState& s)
    {
        if (s.todo.size() < 2)
            return;
        size_t nearI = 0, farI = 0;
        float  nearD = 1e30f, farD = -1.0f;
        for (size_t i = 0; i < s.todo.size(); ++i)
        {
            float d = ErrandYards(s.todo[i]);
            if (d < nearD) { nearD = d; nearI = i; }
            if (d > farD)  { farD  = d; farI  = i; }
        }
        size_t pick = (farD > NEXT_ERRAND_FAR_CAP * nearD || urand(0, 1) == 0) ? nearI : farI;
        std::rotate(s.todo.begin(), s.todo.begin() + pick, s.todo.begin() + pick + 1);
    }
    float ErrandYards(ErrandStop const& e)
    {
        if (e.kind == Errand::Mail || e.kind == Errand::Runeforge)
        {
            GameObject* box = ObjectAccessor::GetGameObject(*bot, e.npc);
            return box ? bot->GetDistance(box) : 0.0f;
        }
        Creature* npc = ObjectAccessor::GetCreature(*bot, e.npc);
        return npc ? bot->GetDistance(npc) : 0.0f;
    }

    bool RunErrand(TownState& s, uint64 now)
    {
        ErrandStop stop = s.todo.front();
        if (stop.kind == Errand::Mail || stop.kind == Errand::Runeforge)
        {
            GameObject* box = ObjectAccessor::GetGameObject(*bot, stop.npc);
            if (!box || TooLong(s, now))
            {
                s.todo.erase(s.todo.begin());
                Finish(s, now);
                return false;
            }
            if (bot->GetDistance(box) > ARRIVED_YARDS)
                return WalkTo(box, NPC_YARDS);
            bot->SetFacingToObject(box);
            if (stop.kind == Errand::Runeforge)
                DoRuneforge(botAI, bot, box);
            else
                DoMail(botAI, bot, box);
            s.todo.erase(s.todo.begin());
            Finish(s, now);
            return true;
        }
        Creature* npc = ObjectAccessor::GetCreature(*bot, stop.npc);
        if (!npc || !npc->IsAlive() || TooLong(s, now))
        {
            s.todo.erase(s.todo.begin());
            Finish(s, now);
            return false;
        }
        if (bot->GetDistance(npc) > ARRIVED_YARDS)
            return WalkTo(npc, NPC_YARDS);
        bot->SetFacingToObject(npc);
        bot->HandleEmoteCommand(EMOTE_ONESHOT_TALK);
        auto fn = sErrands.find(uint8(stop.kind));
        if (fn != sErrands.end())
            fn->second(botAI, bot, npc);
        s.todo.erase(s.todo.begin());
        Finish(s, now);
        return true;
    }

    void ChoosePastime(TownState& s, uint32 areaId, uint64 now)
    {
        uint32 roll = urand(1, WEIGHT_VISIT + WEIGHT_SIT + WEIGHT_SLEEP + WEIGHT_FISH);
        if (roll > WEIGHT_VISIT + WEIGHT_SIT + WEIGHT_SLEEP && ChooseFishing(s, areaId, now))
            return;
        if (roll > WEIGHT_VISIT + WEIGHT_SIT && roll <= WEIGHT_VISIT + WEIGHT_SIT + WEIGHT_SLEEP && ChooseSleep(s, areaId, now))
            return;
        if (roll > WEIGHT_VISIT && roll <= WEIGHT_VISIT + WEIGHT_SIT && ChooseChair(s, areaId, now))
            return;
        Creature* next = WanderTarget(s, areaId);
        if (!next)
        {
            s.idleUntil = now + urand(GAP_MIN_MS, GAP_MAX_MS);
            return;
        }
        Begin(s, Doing::Visit, next->GetGUID(), now);
        s.lastVisit = next->GetGUID();
    }

    using WayFn = Creature* (BuddyTownStepAction::*)(std::vector<Creature*> const&);

    Creature* WanderTarget(TownState const& s, uint32 areaId)
    {
        std::vector<Creature*> people;
        for (Unit* u : UnitsNear(bot, WANDER_SCAN_YARDS))
            if (Creature* c = u->ToCreature())
                if (c->GetGUID() != s.lastVisit && Townsperson(c, bot, areaId))
                    people.push_back(c);
        if (people.empty())
            return nullptr;
        static WayFn const ways[] = {
            &BuddyTownStepAction::TowardFarthest,
            &BuddyTownStepAction::TowardClassTrainer,
            &BuddyTownStepAction::AnyTownsperson,
        };
        std::vector<uint32> order = { 0, 1, 2 };
        Acore::Containers::RandomShuffle(order);
        for (uint32 i : order)
            if (Creature* c = (this->*ways[i])(people))
                return c;
        return nullptr;
    }

    Creature* NextToward(std::vector<Creature*> const& people, Creature* aim)
    {
        float bearing = bot->GetAngle(aim);
        Creature* best = nullptr;
        for (Creature* c : people)
        {
            if (bot->GetDistance(c) <= ARRIVED_YARDS)
                continue;
            float off = std::fabs(std::remainder(bot->GetAngle(c) - bearing, 2.0f * float(M_PI)));
            if (off > WANDER_CONE)
                continue;
            if (!best || bot->GetDistance(c) < bot->GetDistance(best))
                best = c;
        }
        return best;
    }

    Creature* TowardFarthest(std::vector<Creature*> const& people)
    {
        Creature* farthest = *std::max_element(people.begin(), people.end(),
            [this](Creature* a, Creature* b) { return bot->GetDistance(a) < bot->GetDistance(b); });
        return NextToward(people, farthest);
    }

    Creature* TowardClassTrainer(std::vector<Creature*> const& people)
    {
        std::vector<Creature*> trainers;
        for (Creature* c : people)
        {
            if (!c->IsTrainer())
                continue;
            Trainer::Trainer* t = sObjectMgr->GetTrainer(c->GetEntry());
            if (t && t->GetTrainerType() == Trainer::Type::Class && t->IsTrainerValidForPlayer(bot))
                trainers.push_back(c);
        }
        if (trainers.empty())
            return nullptr;
        return NextToward(people, trainers[urand(0, uint32(trainers.size()) - 1)]);
    }

    Creature* AnyTownsperson(std::vector<Creature*> const& people)
    {
        return people[urand(0, uint32(people.size()) - 1)];
    }

    bool ChooseChair(TownState& s, uint32 areaId, uint64 now)
    {
        std::list<GameObject*> objects;
        Acore::GameObjectInRangeCheck check(bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ(), LEISURE_SCAN_YARDS);
        Acore::GameObjectListSearcher<Acore::GameObjectInRangeCheck> searcher(bot, objects, check);
        Cell::VisitObjects(bot, searcher, LEISURE_SCAN_YARDS);
        std::vector<GameObject*> best;
        int32 bestCompany = -1;
        std::list<Unit*> units = UnitsNear(bot, LEISURE_SCAN_YARDS + CROWD_YARDS);
        for (GameObject* go : objects)
        {
            if (go->GetGoType() != GAMEOBJECT_TYPE_CHAIR || go->GetAreaId() != areaId || !go->isSpawned())
                continue;
            int32 company = 0;
            for (Unit* u : units)
                if (u != bot && u->GetDistance(go) <= CROWD_YARDS)
                    ++company;
            if (company > bestCompany)
            {
                best.clear();
                bestCompany = company;
            }
            if (company == bestCompany)
                best.push_back(go);
        }
        if (best.empty())
            return false;
        Begin(s, Doing::Sit, best[urand(0, uint32(best.size()) - 1)]->GetGUID(), now);
        return true;
    }

    bool ChooseSleep(TownState& s, uint32 areaId, uint64 now)
    {
        std::vector<BuddyBed> beds = BuddyBedsInArea(bot->GetMapId(), areaId);
        if (beds.empty())
            return false;
        Acore::Containers::RandomShuffle(beds);
        std::unordered_map<uint32, bool> emptyDouble;
        for (BuddyBed const& bed : beds)
            emptyDouble[bed.id] = BuddyBedIsEmptyDouble(bed);
        std::stable_sort(beds.begin(), beds.end(), [&emptyDouble](BuddyBed const& a, BuddyBed const& b)
        {
            if (a.tier != b.tier)
                return a.tier > b.tier;
            return emptyDouble[a.id] && !emptyDouble[b.id];
        });
        Player* owner = botAI->GetMaster();
        uint32 clan = owner ? owner->GetGUID().GetCounter() : 0;
        uint32 hold = WALK_GIVE_UP_MS + SLEEP_MAX_MS + 60000;
        for (BuddyBed const& bed : beds)
        {
            if (!BuddyClaimBed(bed.id, bot->GetGUID().GetCounter(), clan, hold))
                continue;
            Begin(s, Doing::Sleep, ObjectGuid::Empty, now);
            s.bedId  = bed.id;
            s.spotX  = bed.x;
            s.spotY  = bed.y;
            s.spotZ  = bed.z;
            s.facing = bed.facing;
            return true;
        }
        return false;
    }

    bool ChooseFishing(TownState& s, uint32 areaId, uint64 now)
    {
        if (!bot->HasSkill(SKILL_FISHING) || !PoleItem())
            return false;
        Map* map = bot->GetMap();
        WorldPosition water = FindWaterRadial(bot, bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ(),
            map, bot->GetPhaseMask(), FISH_WATER_MIN, LEISURE_SCAN_YARDS, 2.5f, false, 16);
        if (!water.IsValid())
            return false;
        if (map->GetAreaId(bot->GetPhaseMask(), water.GetPositionX(), water.GetPositionY(), water.GetPositionZ()) != areaId)
            return false;
        float angle = bot->GetAngle(water.GetPositionX(), water.GetPositionY());
        WorldPosition shore = FindLandFromPosition(botAI, 0.0f, FISH_WATER_MAX, 1.0f, angle, water, 1000.0f, false);
        if (!shore.IsValid())
            return false;
        Begin(s, Doing::Fish, ObjectGuid::Empty, now);
        s.spotX = shore.GetPositionX();
        s.spotY = shore.GetPositionY();
        s.spotZ = shore.GetPositionZ();
        s.castsLeft = urand(FISH_MIN_CASTS, FISH_MAX_CASTS);
        s.casting = false;
        return true;
    }

    bool RunVisit(TownState& s, uint64 now)
    {
        Creature* npc = ObjectAccessor::GetCreature(*bot, s.target);
        if (!npc || !npc->IsAlive() || npc->IsInCombat() || TooLong(s, now) || (s.there && now >= s.until))
        {
            Finish(s, now);
            return false;
        }
        if (!s.there)
        {
            if (bot->GetDistance(npc) > ARRIVED_YARDS)
                return WalkTo(npc, NPC_YARDS);
            s.there = true;
            s.until = now + urand(VISIT_MIN_MS, VISIT_MAX_MS);
        }
        bot->SetFacingToObject(npc);
        static uint32 const talk[] = { EMOTE_ONESHOT_TALK, EMOTE_ONESHOT_TALK, EMOTE_ONESHOT_QUESTION,
                                       EMOTE_ONESHOT_EXCLAMATION, EMOTE_ONESHOT_LAUGH, EMOTE_ONESHOT_YES, EMOTE_ONESHOT_NO };
        Emote(s, now, talk[urand(0, 6)]);
        return true;
    }

    bool RunSit(uint32 guid, TownState& s, uint64 now)
    {
        GameObject* chair = ObjectAccessor::GetGameObject(*bot, s.target);
        if (!chair || TooLong(s, now) || (s.there && now >= s.until))
        {
            Finish(s, now);
            return false;
        }
        if (!s.there)
        {
            if (bot->GetDistance(chair) > CHAIR_YARDS + chair->GetObjectSize())
                return MoveNear(chair, CHAIR_YARDS);
            chair->Use(bot);
            if (!bot->IsSitState())
            {
                Finish(s, now);
                return false;
            }
            s.there = true;
            s.spotX = bot->GetPositionX();
            s.spotY = bot->GetPositionY();
            s.spotZ = bot->GetPositionZ();
            s.until = now + urand(SIT_MIN_MS, SIT_MAX_MS);
            ShareSeatTimer(guid, s);
            return true;
        }
        if (!bot->IsSitState())
        {
            Finish(s, now);
            return false;
        }
        static uint32 const seated[] = { EMOTE_ONESHOT_TALK, EMOTE_ONESHOT_EAT, EMOTE_ONESHOT_EAT_NO_SHEATHE,
                                         EMOTE_ONESHOT_LAUGH, EMOTE_ONESHOT_TALK_NO_SHEATHE };
        Emote(s, now, seated[urand(0, 4)]);
        return true;
    }

    void ShareSeatTimer(uint32 guid, TownState const& s)
    {
        std::lock_guard<std::mutex> lock(sTownLock);
        for (auto& [otherGuid, other] : sTown)
        {
            if (otherGuid == guid || other.doing != Doing::Sit || !other.there || other.mapId != s.mapId)
                continue;
            float dx = other.spotX - s.spotX, dy = other.spotY - s.spotY;
            if (dx * dx + dy * dy <= SEAT_GROUP_YARDS * SEAT_GROUP_YARDS)
                other.until = s.until;
        }
    }

    bool RunSleep(TownState& s, uint64 now)
    {
        if (TooLong(s, now) || (s.there && now >= s.until))
        {
            Finish(s, now);
            return false;
        }
        if (!s.there)
        {
            if (bot->GetExactDist(s.spotX, s.spotY, s.spotZ) > BED_YARDS)
                return MoveTo(bot->GetMapId(), s.spotX, s.spotY, s.spotZ);
            bot->SetFacingTo(s.facing);
            bot->SetStandState(UNIT_STAND_STATE_SLEEP);
            s.there = true;
            s.until = now + urand(SLEEP_MIN_MS, SLEEP_MAX_MS);
            return true;
        }
        if (bot->getStandState() != UNIT_STAND_STATE_SLEEP)
        {
            Finish(s, now);
            return false;
        }
        return true;
    }

    bool RunFish(TownState& s, uint64 now)
    {
        if (now - s.began > FISH_GIVE_UP_MS)
        {
            Finish(s, now);
            return false;
        }
        if (!s.there)
        {
            if (TooLong(s, now))
            {
                Finish(s, now);
                return false;
            }
            if (bot->GetExactDist(s.spotX, s.spotY, s.spotZ) > 1.5f)
                return MoveTo(bot->GetMapId(), s.spotX, s.spotY, s.spotZ);
            if (!TakePole(s))
            {
                Finish(s, now);
                return false;
            }
            s.there = true;
        }

        if (GameObject* bobber = OwnBobber())
        {
            if (bobber->getLootState() == GO_READY)
                bobber->Use(bot);
            return true;
        }

        bool channelling = bot->GetCurrentSpell(CURRENT_CHANNELED_SPELL) != nullptr;
        if (s.casting && !channelling)
        {
            s.casting = false;
            if (s.castsLeft)
                --s.castsLeft;
        }
        if (channelling || s.casting)
            return true;
        if (!s.castsLeft)
        {
            Finish(s, now);
            return false;
        }

        WorldPosition water = FindWaterRadial(bot, bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ(),
            bot->GetMap(), bot->GetPhaseMask(), FISH_WATER_MIN, FISH_WATER_MAX, 2.5f, true, 32);
        if (!water.IsValid())
        {
            Finish(s, now);
            return false;
        }
        bot->SetFacingTo(bot->GetAngle(water.GetPositionX(), water.GetPositionY()));
        if (botAI->CastSpell(FISHING_SPELL, bot))
            s.casting = true;
        else if (s.castsLeft)
            --s.castsLeft;
        return true;
    }

    Item* PoleItem()
    {
        auto pole = [](Item* item)
        {
            return item && item->GetTemplate()->Class == ITEM_CLASS_WEAPON &&
                   item->GetTemplate()->SubClass == ITEM_SUBCLASS_WEAPON_FISHING_POLE;
        };
        if (Item* held = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_MAINHAND); pole(held))
            return held;
        for (Item* item : BagItems(bot))
            if (pole(item))
                return item;
        return nullptr;
    }

    bool TakePole(TownState& s)
    {
        Item* p = PoleItem();
        if (!p)
            return false;
        if (p->GetSlot() == EQUIPMENT_SLOT_MAINHAND && p->GetBagSlot() == INVENTORY_SLOT_BAG_0)
            return true;
        Item* main = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_MAINHAND);
        Item* off  = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_OFFHAND);
        s.mainHand = main ? main->GetGUID() : ObjectGuid::Empty;
        s.offHand  = off ? off->GetGUID() : ObjectGuid::Empty;
        EquipInSlot(p, EQUIPMENT_SLOT_MAINHAND);
        return true;
    }

    void PutPoleAway(TownState& s)
    {
        if (!s.mainHand.IsEmpty())
            if (Item* item = bot->GetItemByGuid(s.mainHand); item && !item->IsEquipped())
                EquipInSlot(item, EQUIPMENT_SLOT_MAINHAND);
        if (!s.offHand.IsEmpty())
            if (Item* item = bot->GetItemByGuid(s.offHand); item && !item->IsEquipped())
                EquipInSlot(item, EQUIPMENT_SLOT_OFFHAND);
        s.mainHand.Clear();
        s.offHand.Clear();
    }

    void EquipInSlot(Item* item, uint8 slot)
    {
        WorldPacket packet(CMSG_AUTOEQUIP_ITEM_SLOT, 9);
        packet << item->GetGUID() << slot;
        WorldPackets::Item::AutoEquipItemSlot request(std::move(packet));
        request.Read();
        bot->GetSession()->HandleAutoEquipItemSlotOpcode(request);
    }

    GameObject* OwnBobber()
    {
        std::list<GameObject*> objects;
        Acore::GameObjectInRangeCheck check(bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ(), FISH_WATER_MAX + 10.0f);
        Acore::GameObjectListSearcher<Acore::GameObjectInRangeCheck> searcher(bot, objects, check);
        Cell::VisitObjects(bot, searcher, FISH_WATER_MAX + 10.0f);
        for (GameObject* go : objects)
            if (go->GetEntry() == FISHING_BOBBER && go->GetOwnerGUID() == bot->GetGUID())
                return go;
        return nullptr;
    }
};

class BuddyTravelDueTrigger : public Trigger
{
public:
    BuddyTravelDueTrigger(PlayerbotAI* botAI) : Trigger(botAI, "buddy travel due") { }
    bool IsActive() override { return true; }
};
class BuddyTownDueTrigger : public Trigger
{
public:
    BuddyTownDueTrigger(PlayerbotAI* botAI) : Trigger(botAI, "buddy town due") { }
    bool IsActive() override { return true; }
};

class BuddyTravelStrategy : public NonCombatStrategy
{
public:
    BuddyTravelStrategy(PlayerbotAI* botAI) : NonCombatStrategy(botAI) { }
    std::string const getName() override { return "buddy travel"; }
    void InitTriggers(std::vector<TriggerNode*>& triggers) override
    {
        triggers.push_back(new TriggerNode("buddy travel due", { NextAction("buddy travel step", TRAVEL_RELEVANCE) }));
    }
};
class BuddyTownStrategy : public NonCombatStrategy
{
public:
    BuddyTownStrategy(PlayerbotAI* botAI) : NonCombatStrategy(botAI) { }
    std::string const getName() override { return "buddy town"; }
    void InitTriggers(std::vector<TriggerNode*>& triggers) override
    {
        triggers.push_back(new TriggerNode("buddy town due", { NextAction("buddy town step", TOWN_RELEVANCE) }));
    }
};

Strategy* NewBuddyTravelStrategy(PlayerbotAI* ai)   { return new BuddyTravelStrategy(ai); }
Trigger*  NewBuddyTravelDueTrigger(PlayerbotAI* ai) { return new BuddyTravelDueTrigger(ai); }
Action*   NewBuddyTravelStepAction(PlayerbotAI* ai) { return new BuddyTravelStepAction(ai); }
Strategy* NewBuddyTownStrategy(PlayerbotAI* ai)     { return new BuddyTownStrategy(ai); }
Trigger*  NewBuddyTownDueTrigger(PlayerbotAI* ai)   { return new BuddyTownDueTrigger(ai); }
Action*   NewBuddyTownStepAction(PlayerbotAI* ai)   { return new BuddyTownStepAction(ai); }
