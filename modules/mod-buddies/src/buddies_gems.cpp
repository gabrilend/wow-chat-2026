/*
 * buddies_gems.cpp - buddies gem their gear by their talent plan (issue
 * 617j2; the rules in plain words are in buddies_gems.h).
 *
 * Words used here:
 *   gem        a cut gem item: GemProperties points at the client's gem
 *              table, which gives its colour (1 meta, 2 red, 4 yellow,
 *              8 blue, or several) and the enchantment it puts on an item
 *   socket     up to three per item (ItemTemplate::Socket[i].Color, the
 *              same colour bits; basic's weapon sockets are 14, red,
 *              yellow and blue at once); a socketed gem is its enchantment
 *              in the item's enchantment slot SOCK_ENCHANTMENT_SLOT + i
 *   bonus      the item's socketBonus enchantment, earned while every
 *              socket holds a gem sharing a colour with it
 *   score      a gem's (or bonus's) stats times the buddy's stat weights:
 *              the bot module's weights for each tree of its plan, blended
 *              by the plan's thirds (as B046 scores items)
 */

#include "buddies.h"
#include "buddies_gems.h"
#include "buddies_loot.h"
#include "buddies_roam.h"
#include "AuctionHouseMgr.h"
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

// {{{ tuning
static constexpr float  GAIN_AT_LEAST  = 0.01f;   // a gain smaller than this is no gain (rounding)
static constexpr float  GEM_SPEND_SHARE  = 0.25f; // at most this share of its money on gems per visit (as meals, 617e4)
// The three tiers (155p) as the game's own cut gems: item level and
// quality of each tier's gems. I: Tourmaline, Zircon, Amber (+4). II:
// Outland's uncommon cuts (+6, +3/+3). III: Outland's rare cuts (+8, +4/+4).
struct GemTier { uint32 itemLevel; uint32 quality; };
static constexpr GemTier GEM_TIERS[3] = { { 55, ITEM_QUALITY_NORMAL }, { 60, ITEM_QUALITY_UNCOMMON }, { 70, ITEM_QUALITY_RARE } };
static constexpr uint32 TIER_II_FROM   = 30;      // an item of this item level or more takes tier II gems ...
static constexpr uint32 TIER_III_FROM  = 45;      // ... and of this or more, tier III
// }}}

// {{{ gems and scores
struct Gem { uint32 entry; uint32 enchant; uint32 color; };

// The kit's choice per tier: plain cut gems (no meta, no unique or limited
// ones, none needing a profession), read once from the item templates.
static std::once_flag    sTiersRead;
static std::vector<Gem>  sTierGems[3];

static bool GemOf(ItemTemplate const* proto, Gem& out)
{
    if (!proto || proto->Class != ITEM_CLASS_GEM || !proto->GemProperties)
        return false;
    GemPropertiesEntry const* props = sGemPropertiesStore.LookupEntry(proto->GemProperties);
    if (!props || !props->spellitemenchantement || props->color == SOCKET_COLOR_META)
        return false;                                  // meta gems: never (the owner, 2026-10-03)
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

// One buddy's scores, remembered for as long as the scorer lives (one kit,
// or one placing pass), since each costs three of the bot module's scorers.
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
            // no plan: as the bot module scores this buddy itself
            StatsWeightCalculator c(_bot);
            c.SetOverflowPenalty(false);
            s = c.CalculateEnchant(enchant);
        }
        else
            for (int t = 0; t < 3; ++t)
            {
                if (!_thirds[t])
                    continue;                          // no points in this tree: no say
                StatsWeightCalculator part(_bot);
                part.SetSpecTab(t, _types[t]);
                // hit and expertise caps are judged on the buddy's stats now,
                // which a gem choice should not chase: off
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

// The colour of the gem whose enchantment this is; 0 for none.
static uint32 ColorOfEnchant(uint32 enchant)
{
    SpellItemEnchantmentEntry const* e = enchant ? sSpellItemEnchantmentStore.LookupEntry(enchant) : nullptr;
    ItemTemplate const* proto = (e && e->GemID) ? sObjectMgr->GetItemTemplate(e->GemID) : nullptr;
    GemPropertiesEntry const* props = proto ? sGemPropertiesStore.LookupEntry(proto->GemProperties) : nullptr;
    return props ? props->color : 0;
}

// An item's gems and bonus, as the buddy scores them: `gems` the
// enchantment in each socket (0 empty). The bonus counts when every socket
// holds a gem sharing a colour with it (the server's rule, GemsFitSockets).
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

// The gems an item should hold, from `choice`: the best gem in each socket
// whatever its colour, or the best of each socket's own colour plus the
// bonus, whichever is worth more. Meta sockets stay empty.
static std::array<uint32, MAX_GEM_SOCKETS> Choose(GemScorer& scorer, ItemTemplate const* item, std::vector<Gem> const& choice)
{
    std::array<uint32, MAX_GEM_SOCKETS> best {}, matched {};
    bool allMatched = true;
    for (int i = 0; i < MAX_GEM_SOCKETS; ++i)
    {
        uint32 color = item->Socket[i].Color;
        if (!color || color == SOCKET_COLOR_META)
        {
            allMatched = allMatched && !color;         // a meta socket left empty earns no bonus
            continue;
        }
        float bestScore = -1.0f, matchedScore = -1.0f;
        for (Gem const& g : choice)
        {
            float s = scorer.Score(g.enchant);
            if (s > bestScore)
                bestScore = s, best[i] = g.enchant;
            if ((g.color & color) && s > matchedScore)
                matchedScore = s, matched[i] = g.enchant;
        }
        allMatched = allMatched && matched[i];
    }
    if (allMatched && ValueOf(scorer, item, matched) > ValueOf(scorer, item, best))
        return matched;
    return best;
}
// }}}

// {{{ putting gems in
// One enchantment slot of a worn item set. In the world, as the server's
// socketing does: the old enchantment's stats taken off, the new one's put
// on, and the item marked for saving. Not in the world (a buddy being
// made): written straight into the item's fields, since the item's own
// setter tells its owner's client and there is none; the new item is saved
// with them, and its stats are applied when the buddy first logs in.
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
// }}}

// {{{ the clan's placing
// A loose gem in some buddy's bags, and the best place found for it.
struct Placing
{
    Player* holder   = nullptr;
    Item*   gem      = nullptr;
    Player* receiver = nullptr;
    Item*   item     = nullptr;
    int     socket   = -1;
    float   gain     = 0.0f;
};

// Whether `bot` already has this unique-equipped gem socketed somewhere.
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

// The best socket for `gem` among `member`'s worn items, as a gain over
// what is there now; `out` is changed only for a better gain than it has.
static void BestSocketFor(Player* member, GemScorer& scorer, Gem const& gem, ItemTemplate const* gemProto, Placing& out,
                          Player* holder, Item* gemItem)
{
    if (member->CanUseItem(gemProto) != EQUIP_ERR_OK)
        return;                                        // a profession's gem it lacks the skill for
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
            // the most gained wins; a tie goes to the buddy already holding it
            bool more = gain > out.gain + GAIN_AT_LEAST;
            bool tie  = gain > GAIN_AT_LEAST && std::fabs(gain - out.gain) <= GAIN_AT_LEAST && member == holder && out.receiver != holder;
            if (more || tie)
                out = { holder, gemItem, member, item, i, gain };
        }
    }
}

// Through the server's own socketing, as a player's client asks for it.
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

// The best placing found, carried out: handed over first when another
// buddy holds the gem, then socketed through the server's own socketing.
static void Place(Placing best)
{
    Item* gem = best.gem;
    uint32 entry = gem->GetEntry();
    if (best.receiver != best.holder)
    {
        // handed over: one taken from the holder, one given to the receiver
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

// Scorers for a clan's buddies, made once per handling.
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

// One loose gem in `holder`'s bags: to the clan buddy it gains most (the
// holder itself on a tie), socketed at once; gaining nobody, it stays.
static void PlaceGem(Player* holder, Item* gemItem, std::vector<Player*> const& clan, std::map<Player*, GemScorer>& scorers)
{
    Gem gem;
    if (!GemOf(gemItem->GetTemplate(), gem) || gemItem->GetTemplate()->ItemLimitCategory)
        return;                                        // not a socketable gem; limited gems (a few epics) are left to the owner
    Placing best;
    for (Player* m : clan)
        BestSocketFor(m, scorers.at(m), gem, gemItem->GetTemplate(), best, holder, gemItem);
    if (best.receiver && best.gain > GAIN_AT_LEAST)
        Place(best);
}

// Every loose gem in the clan's bags, offered again (a socketed item has
// arrived, so a socket may be waiting for one of them).
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
            PlaceGem(holder, g, clan, scorers);        // each placing re-reads what is socketed: nothing stale
    }
}
// }}}

// {{{ arrivals: an item entered a buddy's bags
// The owner, 2026-10-03, replacing a check every 10 seconds: "How about we
// check whenever an item enters a buddy-bots bags, and depending on what it
// is, we have a dispatch table (with potentials for multiple types of
// functions, one after another) of things that we want to check or do?
// [...] we want to use as few if checks as possible, and route our
// decisions through data rather than run a bunch of checks if this, then
// that style. But once we're routed to a function, it's okay to have if
// checks there."
//
// An item entering a buddy's bags (the server's "a new item was stored"
// moment: loot, quest rewards, purchases, crafting, a hand-over; and the
// mail errand's collecting, buddies_town.cpp) is queued, and handled on
// the world's thread at its next update (the map threads are idle then, so
// the clan's bags and gear may be changed). Handling routes the item
// through the readers below in order: each reader turns the item into a
// key (its kind, ...), and every function listed under that key runs.
using ArrivalFn = void (*)(Player* buddy, Item* item, std::vector<Player*> const& clan);

static void GemArrived(Player* buddy, Item* item, std::vector<Player*> const& clan)
{
    // "check to see if you need it, and if not, then check to see if any
    // of your clanmates needs it": the clan's best socket for it, the
    // holder winning a tie
    std::map<Player*, GemScorer> scorers = ScorersFor(clan);
    PlaceGem(buddy, item, clan, scorers);
}

static void SocketedGearArrived(Player* /*buddy*/, Item* item, std::vector<Player*> const& clan);

// The readers, in the order they are asked, each with its table. To route
// more kinds of item, add a key to a table, or a reader (an item's
// required level, quality, ...) with its own table.
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

// A gear item with sockets has arrived: the bot module equips an upgrade a
// moment later, so the clan's loose gems are offered again after
// GEAR_SETTLE_MS (one look per clan, however many items came).
static constexpr uint32 GEAR_SETTLE_MS = 5000;
static std::mutex sArrivalLock;
struct Arrival { uint32 buddy; ObjectGuid item; };
static std::vector<Arrival> sArrivals;                 // under sArrivalLock
static std::map<uint32, uint64> sClanLooks;            // owner -> when to offer its loose gems again (world thread only)

static void SocketedGearArrived(Player* buddy, Item* item, std::vector<Player*> const& /*clan*/)
{
    ItemTemplate const* p = item->GetTemplate();
    if (!p->Socket[0].Color && !p->Socket[1].Color && !p->Socket[2].Color)
        return;                                        // no sockets: nothing for gems
    for (auto const& [b, owner] : BuddyRosterPairs())
        if (b == buddy->GetGUID().GetCounter())
            sClanLooks.emplace(owner, uint64(GameTime::GetGameTimeMS().count()) + GEAR_SETTLE_MS);
}

void BuddyItemArrived(uint32 buddyGuid, ObjectGuid item)
{
    std::lock_guard<std::mutex> lock(sArrivalLock);
    sArrivals.push_back({ buddyGuid, item });
}

// The clan of a buddy: its owner's buddies in the world, alive and out of
// a fight (stage 0: with their owner).
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

    // Any thread: only queued here. Bots only (a cheap test); whether it is
    // a buddy is asked when it is handled.
    void OnPlayerStoreNewItem(Player* player, Item* item, uint32 /*count*/) override
    {
        if (BuddiesEnabled() && item && GET_PLAYERBOT_AI(player))
            BuddyItemArrived(player->GetGUID().GetCounter(), item->GetGUID());
    }
};

class buddies_gems_world : public WorldScript
{
public:
    buddies_gems_world() : WorldScript("buddies_gems_world", { WORLDHOOK_ON_UPDATE }) { }

    void OnUpdate(uint32 /*diff*/) override
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
                continue;                              // a bot, not a buddy
            Player* buddy = ObjectAccessor::FindPlayerByLowGUID(a.buddy);
            Item* item = buddy ? buddy->GetItemByGuid(a.item) : nullptr;
            if (!item || item->IsEquipped())
                continue;                              // gone (sold, socketed, handed on) or worn already
            std::vector<Player*> clan = ClanOf(owner);
            if (std::find(clan.begin(), clan.end(), buddy) == clan.end())
                continue;                              // fighting or dead: the next arrival brings it back
            for (Reader const& r : Readers())
            {
                auto it = r.table.find(r.key(item->GetTemplate()));
                if (it == r.table.end())
                    continue;
                for (ArrivalFn fn : it->second)
                    if ((item = buddy->GetItemByGuid(a.item)))   // a function before may have used it up
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
// }}}

// {{{ buying at the auction house
// The owner, 2026-10-03: gems are bought "from the auction house". On the
// town visit's auction errand (buddies_town.cpp), after its own listings:
// for each empty socket it wears, the best-scoring single gem listed for a
// buyout it can afford that fits the socket's colour (equal scores: the
// cheaper), bought through the server's own bid request at the buyout
// price, spending no more than GEM_SPEND_SHARE of its money. A bought gem
// comes by mail (the server's rule), so bag room matters only at the
// mailbox: waiting mail makes the mailbox an errand (617h's list), and
// whatever doesn't fit stays in the mail for the next visit. Collected,
// the gem arrives in its bags and is placed (the arrivals, above).

// The empty (non-meta) sockets of what the buddy wears.
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
    std::set<uint32> taken;                            // auctions already bought this visit
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
        // the request the auction window sends for a buyout
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
// }}}

// {{{ AddSC_buddies_gems
void AddSC_buddies_gems()
{
    new buddies_gems_arrivals();
    new buddies_gems_world();
}
// }}}
