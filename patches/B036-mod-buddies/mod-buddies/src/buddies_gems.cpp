
#include "buddies.h"
#include "buddies_gems.h"
#include "buddies_loot.h"
#include "buddies_roam.h"
#include "AuctionHouseMgr.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "DatabaseEnv.h"
#include "Creature.h"
#include "DBCStores.h"
#include "GameTime.h"
#include "Item.h"
#include "ItemPackets.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Playerbots.h"
#include "ScriptMgr.h"
#include "StatsWeightCalculator.h"
#include "WorldSession.h"
#include <algorithm>
#include <array>
#include <cmath>
#include <map>
#include <mutex>
#include <set>
#include <unordered_map>
#include <vector>

using namespace Acore::ChatCommands;

static constexpr float  GAIN_AT_LEAST  = 0.01f;
static constexpr float  GEM_SPEND_SHARE  = 0.25f;
struct GemTier { uint32 itemLevel; uint32 quality; };
static constexpr GemTier GEM_TIERS[3] = { { 55, ITEM_QUALITY_NORMAL }, { 60, ITEM_QUALITY_UNCOMMON }, { 70, ITEM_QUALITY_RARE } };
static constexpr uint32 TIER_II_FROM   = 30;
static constexpr uint32 TIER_III_FROM  = 45;

struct Gem { uint32 entry; uint32 enchant; uint32 color; };

static std::once_flag    sTiersRead;
static std::vector<Gem>  sTierGems[3];

static bool GemOf(ItemTemplate const* proto, Gem& out)
{
    if (!proto || proto->Class != ITEM_CLASS_GEM || !proto->GemProperties)
        return false;
    GemPropertiesEntry const* props = sGemPropertiesStore.LookupEntry(proto->GemProperties);
    if (!props || !props->spellitemenchantement || props->color == SOCKET_COLOR_META)
        return false;
    out = { proto->ItemId, props->spellitemenchantement, props->color };
    return true;
}

static void ReadTiers()
{
    for (auto const& kv : *sObjectMgr->GetItemTemplateStore())
    {
        ItemTemplate const& p = kv.second;
        Gem g;
        if (!GemOf(&p, g) || p.HasFlag(ITEM_FLAG_UNIQUE_EQUIPPABLE) || p.ItemLimitCategory || p.RequiredSkill)
            continue;
        for (int t = 0; t < 3; ++t)
            if (p.ItemLevel == GEM_TIERS[t].itemLevel && p.Quality == GEM_TIERS[t].quality)
                sTierGems[t].push_back(g);
    }
    for (int t = 0; t < 3; ++t)
        if (sTierGems[t].empty())
            LOG_ERROR("module", "mod-buddies: no cut gems of item level {} and quality {} (gem tier {}, 155p); kit sockets of that "
                "tier stay empty", GEM_TIERS[t].itemLevel, GEM_TIERS[t].quality, t + 1);
}

static int TierOf(ItemTemplate const* item)
{
    return item->ItemLevel >= TIER_III_FROM ? 2 : (item->ItemLevel >= TIER_II_FROM ? 1 : 0);
}

class GemScorer
{
public:
    GemScorer(Player* bot, uint8 profile, uint8 role) : _bot(bot)
    {
        _plan = BuddyPlanShape(bot->getClass(), profile, role, _thirds, _types);
    }

    float Score(uint32 enchant)
    {
        if (!enchant)
            return 0.0f;
        auto it = _cache.find(enchant);
        if (it != _cache.end())
            return it->second;
        float s = 0.0f;
        if (!_plan)
        {
            StatsWeightCalculator c(_bot);
            c.SetOverflowPenalty(false);
            s = c.CalculateEnchant(enchant);
        }
        else
            for (int t = 0; t < 3; ++t)
            {
                if (!_thirds[t])
                    continue;
                StatsWeightCalculator part(_bot);
                part.SetSpecTab(t, _types[t]);
                part.SetOverflowPenalty(false);
                s += float(_thirds[t]) / 3.0f * part.CalculateEnchant(enchant);
            }
        _cache[enchant] = s;
        return s;
    }

private:
    Player*                            _bot;
    bool                               _plan = false;
    uint8                              _thirds[3] = { 0, 0, 0 };
    CollectorType                      _types[3]  = { CollectorType::MELEE_DMG, CollectorType::MELEE_DMG, CollectorType::MELEE_DMG };
    std::unordered_map<uint32, float>  _cache;
};

static uint32 ColorOfEnchant(uint32 enchant)
{
    SpellItemEnchantmentEntry const* e = enchant ? sSpellItemEnchantmentStore.LookupEntry(enchant) : nullptr;
    ItemTemplate const* proto = (e && e->GemID) ? sObjectMgr->GetItemTemplate(e->GemID) : nullptr;
    GemPropertiesEntry const* props = proto ? sGemPropertiesStore.LookupEntry(proto->GemProperties) : nullptr;
    return props ? props->color : 0;
}

static float ValueOf(GemScorer& scorer, ItemTemplate const* item, std::array<uint32, MAX_GEM_SOCKETS> const& gems)
{
    float v = 0.0f;
    bool bonus = item->socketBonus != 0;
    for (int i = 0; i < MAX_GEM_SOCKETS; ++i)
    {
        if (!item->Socket[i].Color)
            continue;
        v += scorer.Score(gems[i]);
        if (!(ColorOfEnchant(gems[i]) & item->Socket[i].Color))
            bonus = false;
    }
    return v + (bonus ? scorer.Score(item->socketBonus) : 0.0f);
}

static constexpr uint32 GEM_COLOURS[] = { 2, 4, 8, 6, 10, 12 };

static std::array<uint32, MAX_GEM_SOCKETS> Choose(GemScorer& scorer, ItemTemplate const* item, std::vector<Gem> const& choice)
{
    std::array<uint32, MAX_GEM_SOCKETS> gems {};
    for (int i = 0; i < MAX_GEM_SOCKETS; ++i)
    {
        uint32 socket = item->Socket[i].Color;
        if (!socket || socket == SOCKET_COLOR_META)
            continue;
        std::vector<uint32> fits;
        for (uint32 colour : GEM_COLOURS)
            if ((colour & socket) && std::any_of(choice.begin(), choice.end(), [colour](Gem const& g) { return g.color == colour; }))
                fits.push_back(colour);
        if (fits.empty())
            continue;
        uint32 drawn = fits[urand(0, uint32(fits.size()) - 1)];
        float bestScore = -1.0f;
        for (Gem const& g : choice)
            if (g.color == drawn)
                if (float sc = scorer.Score(g.enchant); sc > bestScore)
                    bestScore = sc, gems[i] = g.enchant;
    }
    return gems;
}

static void SetSlot(Player* buddy, Item* item, EnchantmentSlot slot, uint32 enchant)
{
    if (!buddy->IsInWorld())
    {
        item->SetUInt32Value(ITEM_FIELD_ENCHANTMENT_1_1 + slot * MAX_ENCHANTMENT_OFFSET + ENCHANTMENT_ID_OFFSET, enchant);
        return;
    }
    buddy->ApplyEnchantment(item, slot, false);
    item->SetEnchantment(slot, enchant, 0, 0, buddy->GetGUID());
    buddy->ApplyEnchantment(item, slot, true);
}

std::string BuddyGemKit(Player* buddy, uint8 profile, uint8 role)
{
    std::call_once(sTiersRead, ReadTiers);
    GemScorer scorer(buddy, profile, role);
    std::string problems;
    uint32 placed = 0;
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
    {
        Item* item = buddy->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        if (!item)
            continue;
        ItemTemplate const* proto = item->GetTemplate();
        if (!proto->Socket[0].Color && !proto->Socket[1].Color && !proto->Socket[2].Color)
            continue;
        std::vector<Gem> const& choice = sTierGems[TierOf(proto)];
        if (choice.empty())
        {
            problems += proto->Name1 + " has sockets but its gem tier has no gems; ";
            continue;
        }
        std::array<uint32, MAX_GEM_SOCKETS> gems = Choose(scorer, proto, choice);
        for (int i = 0; i < MAX_GEM_SOCKETS; ++i)
            if (gems[i])
            {
                SetSlot(buddy, item, EnchantmentSlot(SOCK_ENCHANTMENT_SLOT + i), gems[i]);
                ++placed;
            }
        SetSlot(buddy, item, BONUS_ENCHANTMENT_SLOT, item->GemsFitSockets() ? proto->socketBonus : 0);
    }
    LOG_INFO("module", "mod-buddies: buddy {} (plan {}) given {} gems for its kit's sockets", buddy->GetName(), profile, placed);
    return problems;
}

struct Placing
{
    Player* holder   = nullptr;
    Item*   gem      = nullptr;
    Player* receiver = nullptr;
    Item*   item     = nullptr;
    int     socket   = -1;
    float   gain     = 0.0f;
};

static bool WearsGem(Player* bot, uint32 gemEntry)
{
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        if (Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            for (int i = 0; i < MAX_GEM_SOCKETS; ++i)
                if (SpellItemEnchantmentEntry const* e = sSpellItemEnchantmentStore.LookupEntry(
                        item->GetEnchantmentId(EnchantmentSlot(SOCK_ENCHANTMENT_SLOT + i))))
                    if (e->GemID == gemEntry)
                        return true;
    return false;
}

static void BestSocketFor(Player* member, GemScorer& scorer, Gem const& gem, ItemTemplate const* gemProto, Placing& out,
                          Player* holder, Item* gemItem)
{
    if (member->CanUseItem(gemProto) != EQUIP_ERR_OK)
        return;
    if (gemProto->HasFlag(ITEM_FLAG_UNIQUE_EQUIPPABLE) && WearsGem(member, gem.entry))
        return;
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
    {
        Item* item = member->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        if (!item)
            continue;
        ItemTemplate const* proto = item->GetTemplate();
        std::array<uint32, MAX_GEM_SOCKETS> now {};
        for (int i = 0; i < MAX_GEM_SOCKETS; ++i)
            now[i] = item->GetEnchantmentId(EnchantmentSlot(SOCK_ENCHANTMENT_SLOT + i));
        float before = ValueOf(scorer, proto, now);
        for (int i = 0; i < MAX_GEM_SOCKETS; ++i)
        {
            if (!proto->Socket[i].Color || proto->Socket[i].Color == SOCKET_COLOR_META || now[i] == gem.enchant)
                continue;
            std::array<uint32, MAX_GEM_SOCKETS> with = now;
            with[i] = gem.enchant;
            float gain = ValueOf(scorer, proto, with) - before;
            bool more = gain > out.gain + GAIN_AT_LEAST;
            bool tie  = gain > GAIN_AT_LEAST && std::fabs(gain - out.gain) <= GAIN_AT_LEAST && member == holder && out.receiver != holder;
            if (more || tie)
                out = { holder, gemItem, member, item, i, gain };
        }
    }
}

static bool Socket(Player* bot, Item* item, int socket, Item* gem)
{
    uint32 enchant = 0;
    if (GemPropertiesEntry const* props = sGemPropertiesStore.LookupEntry(gem->GetTemplate()->GemProperties))
        enchant = props->spellitemenchantement;
    WorldPacket packet(CMSG_SOCKET_GEMS);
    packet << item->GetGUID();
    for (int i = 0; i < MAX_GEM_SOCKETS; ++i)
        packet << (i == socket ? gem->GetGUID() : ObjectGuid::Empty);
    WorldPackets::Item::SocketGems request(std::move(packet));
    request.Read();
    bot->GetSession()->HandleSocketOpcode(request);
    return item->GetEnchantmentId(EnchantmentSlot(SOCK_ENCHANTMENT_SLOT + socket)) == enchant;
}

static void Place(Placing best)
{
    Item* gem = best.gem;
    uint32 entry = gem->GetEntry();
    if (best.receiver != best.holder)
    {
        ItemPosCountVec dest;
        if (best.receiver->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, entry, 1) != EQUIP_ERR_OK)
        {
            BuddyTrace(best.receiver, "gems: {}'s {} would gain me {:.1f}, but my bags are full", best.holder->GetName(),
                gem->GetTemplate()->Name1, best.gain);
            return;
        }
        uint32 one = 1;
        best.holder->DestroyItemCount(gem, one, true);
        gem = best.receiver->StoreNewItem(dest, entry, true);
        if (!gem)
        {
            LOG_ERROR("module", "mod-buddies: gem {} taken from {} could not be given to {}; it is lost", entry,
                best.holder->GetName(), best.receiver->GetName());
            return;
        }
    }
    std::string itemName = best.item->GetTemplate()->Name1;
    if (!Socket(best.receiver, best.item, best.socket, gem))
    {
        LOG_ERROR("module", "mod-buddies: the server refused buddy {} socketing gem {} into {} (socket {}); the gem stays in its bags",
            best.receiver->GetName(), entry, itemName, best.socket + 1);
        return;
    }
    LOG_INFO("module", "mod-buddies: buddy {} socketed gem {} into {} (socket {}, gain {:.1f}){}", best.receiver->GetName(), entry,
        itemName, best.socket + 1, best.gain, best.receiver == best.holder ? "" : " handed over by " + best.holder->GetName());
}

static std::map<Player*, GemScorer> ScorersFor(std::vector<Player*> const& clan)
{
    std::map<Player*, GemScorer> scorers;
    for (Player* m : clan)
    {
        QueryResult row = CharacterDatabase.Query("SELECT profile, role FROM buddy_roster WHERE buddy = {}", m->GetGUID().GetCounter());
        scorers.emplace(m, GemScorer(m, row ? (*row)[0].Get<uint8>() : 0, row ? (*row)[1].Get<uint8>() : 0));
    }
    return scorers;
}

static void PlaceGem(Player* holder, Item* gemItem, std::vector<Player*> const& clan, std::map<Player*, GemScorer>& scorers)
{
    Gem gem;
    if (!GemOf(gemItem->GetTemplate(), gem) || gemItem->GetTemplate()->ItemLimitCategory)
        return;
    Placing best;
    for (Player* m : clan)
        BestSocketFor(m, scorers.at(m), gem, gemItem->GetTemplate(), best, holder, gemItem);
    if (best.receiver && best.gain > GAIN_AT_LEAST)
        Place(best);
}

static void PlaceClanGems(std::vector<Player*> const& clan)
{
    std::map<Player*, GemScorer> scorers = ScorersFor(clan);
    for (Player* holder : clan)
    {
        std::vector<Item*> gems;
        for (uint8 bag = INVENTORY_SLOT_BAG_0; bag < INVENTORY_SLOT_BAG_END; ++bag)
        {
            if (bag != INVENTORY_SLOT_BAG_0 && bag < INVENTORY_SLOT_BAG_START)
                continue;
            uint32 first = bag == INVENTORY_SLOT_BAG_0 ? INVENTORY_SLOT_ITEM_START : 0;
            uint32 end   = bag == INVENTORY_SLOT_BAG_0 ? INVENTORY_SLOT_ITEM_END : 0;
            if (bag != INVENTORY_SLOT_BAG_0)
                if (Bag* b = holder->GetBagByPos(bag))
                    end = b->GetBagSize();
            for (uint32 s = first; s < end; ++s)
                if (Item* it = holder->GetItemByPos(bag, uint8(s)); it && it->GetTemplate()->Class == ITEM_CLASS_GEM)
                    gems.push_back(it);
        }
        for (Item* g : gems)
            PlaceGem(holder, g, clan, scorers);
    }
}

using ArrivalFn = void (*)(Player* buddy, Item* item, std::vector<Player*> const& clan);

static void GemArrived(Player* buddy, Item* item, std::vector<Player*> const& clan)
{
    std::map<Player*, GemScorer> scorers = ScorersFor(clan);
    PlaceGem(buddy, item, clan, scorers);
}

static void SocketedGearArrived(Player* , Item* item, std::vector<Player*> const& clan);

struct Reader
{
    uint32 (*key)(ItemTemplate const*);
    std::unordered_map<uint32, std::vector<ArrivalFn>> table;
};
static uint32 KindOf(ItemTemplate const* p) { return p->Class; }
static std::vector<Reader> const& Readers()
{
    static std::vector<Reader> const readers = {
        { KindOf, {
            { ITEM_CLASS_GEM,    { GemArrived } },
            { ITEM_CLASS_ARMOR,  { SocketedGearArrived } },
            { ITEM_CLASS_WEAPON, { SocketedGearArrived } },
        } },
    };
    return readers;
}

static constexpr uint32 GEAR_SETTLE_MS = 5000;
static std::mutex sArrivalLock;
struct Arrival { uint32 buddy; ObjectGuid item; };
static std::vector<Arrival> sArrivals;
static std::map<uint32, uint64> sClanLooks;

static void SocketedGearArrived(Player* buddy, Item* item, std::vector<Player*> const& )
{
    ItemTemplate const* p = item->GetTemplate();
    if (!p->Socket[0].Color && !p->Socket[1].Color && !p->Socket[2].Color)
        return;
    for (auto const& [b, owner] : BuddyRosterPairs())
        if (b == buddy->GetGUID().GetCounter())
            sClanLooks.emplace(owner, uint64(GameTime::GetGameTimeMS().count()) + GEAR_SETTLE_MS);
}

void BuddyItemArrived(uint32 buddyGuid, ObjectGuid item)
{
    std::lock_guard<std::mutex> lock(sArrivalLock);
    sArrivals.push_back({ buddyGuid, item });
}

static std::vector<Player*> ClanOf(uint32 owner)
{
    std::vector<Player*> clan;
    for (auto const& [b, o] : BuddyRosterPairs())
        if (o == owner)
            if (Player* p = ObjectAccessor::FindPlayerByLowGUID(b))
                if (p->IsInWorld() && p->IsAlive() && !p->IsInCombat() && p->GetSession())
                    clan.push_back(p);
    return clan;
}

class buddies_gems_arrivals : public PlayerScript
{
public:
    buddies_gems_arrivals() : PlayerScript("buddies_gems_arrivals", { PLAYERHOOK_ON_STORE_NEW_ITEM }) { }

    void OnPlayerStoreNewItem(Player* player, Item* item, uint32 ) override
    {
        if (BuddiesEnabled() && item && GET_PLAYERBOT_AI(player))
            BuddyItemArrived(player->GetGUID().GetCounter(), item->GetGUID());
    }
};

class buddies_gems_world : public WorldScript
{
public:
    buddies_gems_world() : WorldScript("buddies_gems_world", { WORLDHOOK_ON_UPDATE }) { }

    void OnUpdate(uint32 ) override
    {
        std::vector<Arrival> work;
        {
            std::lock_guard<std::mutex> lock(sArrivalLock);
            work.swap(sArrivals);
        }
        for (Arrival const& a : work)
        {
            uint32 owner = 0;
            for (auto const& [b, o] : BuddyRosterPairs())
                if (b == a.buddy)
                    owner = o;
            if (!owner)
                continue;
            Player* buddy = ObjectAccessor::FindPlayerByLowGUID(a.buddy);
            Item* item = buddy ? buddy->GetItemByGuid(a.item) : nullptr;
            if (!item || item->IsEquipped())
                continue;
            std::vector<Player*> clan = ClanOf(owner);
            if (std::find(clan.begin(), clan.end(), buddy) == clan.end())
                continue;
            for (Reader const& r : Readers())
            {
                auto it = r.table.find(r.key(item->GetTemplate()));
                if (it == r.table.end())
                    continue;
                for (ArrivalFn fn : it->second)
                    if ((item = buddy->GetItemByGuid(a.item)))
                        fn(buddy, item, clan);
            }
        }
        if (sClanLooks.empty())
            return;
        uint64 now = uint64(GameTime::GetGameTimeMS().count());
        for (auto it = sClanLooks.begin(); it != sClanLooks.end(); )
        {
            if (it->second > now) { ++it; continue; }
            PlaceClanGems(ClanOf(it->first));
            it = sClanLooks.erase(it);
        }
    }
};


static std::vector<std::pair<Item*, int>> EmptySockets(Player* bot)
{
    std::vector<std::pair<Item*, int>> empty;
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        if (Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            for (int i = 0; i < MAX_GEM_SOCKETS; ++i)
            {
                uint32 color = item->GetTemplate()->Socket[i].Color;
                if (color && color != SOCKET_COLOR_META && !item->GetEnchantmentId(EnchantmentSlot(SOCK_ENCHANTMENT_SLOT + i)))
                    empty.push_back({ item, i });
            }
    return empty;
}

uint32 BuddyBuyGemsAtAuction(Player* bot, Creature* auctioneer)
{
    AuctionHouseObject* house = sAuctionMgr->GetAuctionsMap(auctioneer->GetFaction());
    if (!house)
        return 0;
    std::vector<std::pair<Item*, int>> empty = EmptySockets(bot);
    if (empty.empty())
        return 0;

    QueryResult row = CharacterDatabase.Query("SELECT profile, role FROM buddy_roster WHERE buddy = {}", bot->GetGUID().GetCounter());
    GemScorer scorer(bot, row ? (*row)[0].Get<uint8>() : 0, row ? (*row)[1].Get<uint8>() : 0);
    uint64 budget = uint64(float(bot->GetMoney()) * GEM_SPEND_SHARE);
    std::set<uint32> taken;
    uint32 bought = 0;
    for (auto const& [item, socket] : empty)
    {
        uint32 color = item->GetTemplate()->Socket[socket].Color;
        AuctionEntry const* pick = nullptr;
        float pickScore = 0.0f;
        for (auto const& [id, a] : house->GetAuctions())
        {
            Gem g;
            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(a->item_template);
            if (taken.count(id) || a->itemCount != 1 || !a->buyout || a->buyout > budget || a->owner == bot->GetGUID() ||
                !GemOf(proto, g) || proto->ItemLimitCategory || !(g.color & color) || bot->CanUseItem(proto) != EQUIP_ERR_OK)
                continue;
            float score = scorer.Score(g.enchant);
            if (!pick || score > pickScore + GAIN_AT_LEAST || (score >= pickScore - GAIN_AT_LEAST && a->buyout < pick->buyout))
                pick = a, pickScore = score;
        }
        if (!pick)
            continue;
        uint32 id = pick->Id, price = pick->buyout, entry = pick->item_template;
        WorldPacket req(CMSG_AUCTION_PLACE_BID);
        req << auctioneer->GetGUID() << id << price;
        bot->GetSession()->HandleAuctionPlaceBid(req);
        taken.insert(id);
        budget = budget > price ? budget - price : 0;
        ++bought;
        BuddyTrace(bot, "gems: bought gem {} at the auction house for {} copper", entry, price);
    }
    return bought;
}

class buddies_gems_command : public CommandScript
{
public:
    buddies_gems_command() : CommandScript("buddies_gems_command") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "buddy gems", HandleGems, SEC_GAMEMASTER, Console::Yes },
        };
        return commandTable;
    }

    static bool HandleGems(ChatHandler* handler, std::string name)
    {
        if (!normalizePlayerName(name))
        {
            handler->PSendSysMessage("Usage: .buddy gems <buddy name>");
            return false;
        }
        Player* buddy = ObjectAccessor::FindPlayerByName(name, true);
        if (!buddy || !BuddyIsCompanionAccount(buddy->GetSession()->GetAccountId()))
        {
            handler->PSendSysMessage("{} is not a buddy in the world (a buddy is in the world while its owner is online).", name);
            return false;
        }
        QueryResult row = CharacterDatabase.Query("SELECT profile, role FROM buddy_roster WHERE buddy = {}", buddy->GetGUID().GetCounter());
        uint8 profile = row ? (*row)[0].Get<uint8>() : 0;
        uint8 role    = row ? (*row)[1].Get<uint8>() : 0;
        std::string problems = BuddyGemKit(buddy, profile, role);
        handler->PSendSysMessage("{} re-gemmed by its plan {} (role {}){}{}", name, uint32(profile), uint32(role),
            problems.empty() ? "" : "; ", problems);
        return true;
    }
};

void AddSC_buddies_gems()
{
    new buddies_gems_arrivals();
    new buddies_gems_world();
    new buddies_gems_command();
}
