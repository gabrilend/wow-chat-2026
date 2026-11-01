/*
 * buddies_town.cpp - buddies go where their owner goes, and in a town they
 * run their errands and then take their ease (issue 617e4).
 *
 * For a general audience: the owner's words (617e, 2026-09-23 to -27): the
 * buddies "will move to whatever area you're in and explore there. So if you
 * move to town, then they move there as well." In a town they are
 * ungrouped, walk rather than run, first do what the town lets them do
 * (learn at their class trainer, sell to a vendor all it can spare, repair), and then
 * "chat with NPCs" (talking animations only, "No chat messages are ever sent
 * to the chat window"), "sit on chairs and chat for a long period of time
 * with other NPCs if any are near, including other buddy bots", eat, drink
 * and laugh there, and "sometimes they'll sleep on beds". Buddies seated
 * together leave together: "they'll both leave when the latest-to-join's
 * timer expires. Sometimes, a third might join, and it resets the timer for
 * all of them."
 *
 * Two behaviours for the bot module ("playerbots"), each a strategy with one
 * trigger and one action, taught to it by buddies_roam_strategy.cpp:
 *   buddy travel - when a buddy stands in a different named area from its
 *                  owner (on the same map), it walks there, by the bot
 *                  module's own long-distance walking (routed on the server's
 *                  navigation mesh; see the note at TravelStep on its one
 *                  teleport). On arrival the area's own behaviour takes over:
 *                  roaming outside towns, the town visit inside. With the
 *                  owner on another continent it walks where the crossing
 *                  says (buddies_crossing.cpp, 617e8): to a dock or portal,
 *                  onto a deck and off it.
 *   buddy town   - in a town: the to-do list, then leisure.
 *
 * Decisions of 2026-09-27 built here: sleeping only on beds placed by hand
 * (buddies_beds.cpp; "proper beds. But we can manually place those"), no
 * sleeping where a town has none; fishing as a pastime where the town has
 * water ("They'll do at least 10 casts before moving on, up to 30"); a
 * buddy stuck on a long walk is reported loudly, never moved (until
 * 2026-10-30 it was hopped to a random spot within 30 yards, "like the
 * unstuck command"; removed as a fallback that hid the fault, 617e4);
 * training paid from the buddy's own money ("make them earn it": no gold
 * cheat is given).
 *
 * The errands are done here, not by the bot module's own sell / repair /
 * trainer actions: those report every step to the owner in a whisper
 * ("Selling [item]", "Repair: 1g 20s", "--- Can learn from ..."), and the
 * owner wants no chat. The same server calls they use are made silently.
 *
 * Built 2026-10-02 from the owner's town design (617h): after the errands
 * a buddy wanders the town from townsperson to townsperson, each next one
 * picked one of three ways (toward the town's farthest townsperson, toward
 * one of its class trainers, or anyone at random); at a vendor or repair
 * stop it buys the food (and, using mana, the drink) its meal eats; and in
 * a town with no auction house, bags at or past nine tenths full are
 * cleared at the vendor in three rounds, then an error if still full.
 */

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

// The bot module's shore finder (FishingAction.cpp): defined there without a
// header declaration, so declared here. From `targetPos` (water), steps back
// toward the bot along `orientation` to the first dry, standable point.
WorldPosition FindLandFromPosition(PlayerbotAI* botAI, float startDistance, float endDistance, float increment,
                                   float orientation, WorldPosition targetPos, float fishingSearchWindow, bool checkLOS);

// {{{ tuning
static constexpr float  MAP_WALK_YARDS      = 20.0f;   // a walk longer than this crosses town by the distance map (617o3)
static constexpr float  MAP_LOOKAHEAD_YARDS = 12.0f;   // each stretch of it reaches about this far
// First guesses; when tuned in game they are logged in docs/balance-updates.md.
static constexpr float  TRAVEL_RELEVANCE    = 3.5f;    // above roaming (3.0), below fighting (4.0) and looting (5-8)
static constexpr float  TOWN_RELEVANCE      = 3.0f;    // the town visit ranks with roaming (never both on at once)
static constexpr float  TOWN_SCAN_YARDS     = 150.0f;  // the town's services are looked for this far round the buddy
static constexpr float  LEISURE_SCAN_YARDS  = 60.0f;   // townspeople, chairs and the inn this far
static constexpr float  NPC_YARDS           = 2.5f;    // how near a buddy stands to someone it talks to
static constexpr float  CHAIR_YARDS         = 1.5f;    // how near a chair before sitting on it
static constexpr float  ARRIVED_YARDS       = 3.5f;    // near enough to count as there (inside the server's 5-yard
                                                       // interaction reach, so selling and training are allowed)
static constexpr float  SEAT_GROUP_YARDS    = 6.0f;    // buddies seated this near each other share one timer
static constexpr float  CROWD_YARDS         = 8.0f;    // townspeople and buddies this near a chair make it sociable
static constexpr uint32 VISIT_MIN_MS        = 10000;   // at a townsperson
static constexpr uint32 VISIT_MAX_MS        = 25000;
static constexpr uint32 SIT_MIN_MS          = 60000;   // "chat for a long period of time"
static constexpr uint32 SIT_MAX_MS          = 180000;
static constexpr uint32 SLEEP_MIN_MS        = 60000;
static constexpr uint32 SLEEP_MAX_MS        = 240000;
static constexpr uint32 EMOTE_MIN_MS        = 3000;    // between talking (or eating, laughing) animations
static constexpr uint32 EMOTE_MAX_MS        = 7000;
static constexpr uint32 GAP_MIN_MS          = 3000;    // a pause between one pastime and the next
static constexpr uint32 GAP_MAX_MS          = 8000;
static constexpr uint32 WALK_GIVE_UP_MS     = 60000;   // a pastime or errand not reached by then is dropped
static constexpr uint32 WEIGHT_VISIT        = 60;      // the pastimes' odds (out of their sum)
static constexpr uint32 WEIGHT_SIT          = 30;
static constexpr uint32 WEIGHT_SLEEP        = 10;
static constexpr uint32 WEIGHT_FISH         = 15;      // only where the town has water it can reach
static constexpr float  BED_YARDS           = 1.0f;    // how near the recorded spot before lying down
static constexpr uint32 FISH_MIN_CASTS      = 10;      // "at least 10 casts before moving on, up to 30"
static constexpr uint32 FISH_MAX_CASTS      = 30;
static constexpr uint32 FISH_GIVE_UP_MS     = 900000;  // a fishing visit ends by now whatever the count (15 min)
static constexpr float  FISH_WATER_MIN      = 10.0f;   // the cast reaches water this far ...
static constexpr float  FISH_WATER_MAX      = 20.0f;   // ... to this (the bot module's own fishing limits)
static constexpr float  HELP_YARDS          = 40.0f;   // a monster fighting the town's people this near is joined (617e12)
static constexpr uint64 ERRAND_PATIENCE_MS  = 60000;   // helping longer than this with errands waiting: errands first
static constexpr float  NEXT_ERRAND_FAR_CAP = 4.0f;   // the farthest errand is chosen only within this many times
                                                       // the nearest's distance (the owner, 2026-10-30: "unless the
                                                       // farthest is more than 4x the distance to the nearest")
static constexpr uint32 STUCK_MS            = 90000;   // no progress on a long walk for this long: reported stuck
static constexpr float  PROGRESS_YARDS      = 10.0f;   // what counts as progress toward the owner
// 617e13 (2026-10-27, from the first measured walk; tuned in docs/balance-updates.md):
static constexpr uint32 FAILS_BEFORE_REPORT = 3;       // long walks in a row that found no way: reported stuck at once
static constexpr float  ARRIVE_RADIUS       = 5.0f;    // the arc a travelling buddy ends on, round its owner
static constexpr float  ARRIVE_SPACING      = 4.0f;    // yards between neighbouring places on it
static constexpr uint64 ARRIVE_CLAIM_MS     = 30000;   // a place not walked to again for this long is free
static constexpr float  WANDER_SCAN_YARDS   = 100.0f;  // the wander's townspeople this far: a walk of about 40 s,
                                                       // inside WALK_GIVE_UP_MS (150 yards would be the whole 60 s)
static constexpr float  WANDER_CONE         = 0.785f;  // "the general direction": within 45 degrees either side
static constexpr float  FULL_BAGS_SHARE     = 0.9f;    // bags this full in a town without an auction house: cleared
static constexpr uint32 MEAL_STOCK          = 20;      // servings of food (and drink) bought up to: one stack, under
                                                       // the bot module's 2-stack line, so its judgement never sells them
static constexpr uint32 MEAL_LOW            = 10;      // fewer than this: it looks for a vendor that sells its meal
static constexpr float  MEAL_SPEND_SHARE    = 0.25f;   // at most this share of its money on meals per stop (repairs
                                                       // and training need the rest: "make them earn it")
// }}}

// {{{ each buddy's town state
// Kept per buddy (character guid, low part), locked because bots run on
// their map's update thread and maps update in parallel. A buddy's entry is
// copied out, worked on and written back; the seat-timer sharing (below)
// reads the others' entries under the same lock.
enum class Errand : uint8 { Train, Sell, Repair, Mail, Auction, Runeforge };   // Mail, Runeforge: at an object, not an NPC
enum class Doing  : uint8 { Nothing, Errand, Visit, Sit, Sleep, Fish };

struct ErrandStop
{
    Errand     kind;
    ObjectGuid npc;
};

struct TownState
{
    uint32                  mapId    = 0;
    uint32                  areaId   = 0;        // the town this state belongs to; another town starts afresh
    std::vector<ErrandStop> todo;                // the errands still to run (built in priority order, run ping-pong: NextErrandFirst)
    Doing                   doing    = Doing::Nothing;
    ObjectGuid              target;              // who or what the current pastime is about
    float                   spotX = 0, spotY = 0, spotZ = 0; // where to sleep; where it sat (for the seat groups)
    bool                    there    = false;    // arrived at the pastime
    uint64                  began    = 0;        // game-time ms the current pastime or errand began
    uint64                  until    = 0;        // game-time ms it ends (once there)
    uint64                  nextEmote = 0;
    uint64                  idleUntil = 0;       // a pause between pastimes
    uint32                  bedId    = 0;        // the bed claimed for sleeping (buddies_beds.cpp)
    float                   facing   = 0.0f;     // the way to lie on it
    uint32                  castsLeft = 0;       // fishing: casts still to make
    bool                    casting  = false;    // fishing: a cast is out (counted when it ends)
    ObjectGuid              mainHand;            // fishing: what it held before the pole, put back after
    ObjectGuid              offHand;
    ObjectGuid              lastVisit;           // the wander's last townsperson, so the next is someone else
    uint64                  helpingSince = 0;    // game-time ms it began helping the guards with errands waiting (0: not)
};

// Each buddy's long walk toward its owner's area: the nearest it has come
// and when, for the stuck rule.
struct TravelProgress
{
    uint32 toArea  = 0;
    float  nearest = 0.0f;
    uint64 since   = 0;
    uint32 fails   = 0;      // long walks in a row that found no way (617e13)
    uint32 reports = 0;      // stuck reports in a row without progress (named in each report)
};
// {{{ the arrival arc (617e13)
// Where a travelling buddy walks to: a place on an arc in front of its
// owner, not the owner's own spot (2026-10-27, three followers stood
// within 3 yards of their owner a third of the time). The owner: "the
// circular position arc we always always use when targeting the player
// ... the position on the arc closest to the buddy-bot, and shifting
// others around if they're already there or have been assigned there and
// are walking toward", and of a place another is heading for: "not
// skipped. We should move the other buddy to a different part of the arc,
// even as they're in motion. We can do this by moving the waypoint they're
// moving toward". Each owner's travellers: buddy -> where it last stood,
// when, and the place it was given; the places are shared out again at
// each step (ArrivalPlace), and a buddy whose place changed walks to its
// new one from its next step, its waypoint moved.
struct ArriveClaim { uint32 place = 0; uint64 at = 0; float x = 0.0f, y = 0.0f; };
static std::unordered_map<uint32, std::unordered_map<uint32, ArriveClaim>> sArrive;   // under sTownLock
// }}}
static std::unordered_map<uint32, TravelProgress> sTravel;   // under sTownLock
// The same measure on the way to a crossing (a dock, a portal, a zeppelin
// tower: 617e8), where the owner's distance says nothing: progress is
// toward the crossing's own place. A place moved more than LEG_YARDS is a
// new leg, measured afresh.
struct CrossingProgress
{
    float  tx = 0.0f, ty = 0.0f;   // the place walked to (the crossing's step)
    float  nearest = 0.0f;
    uint64 since   = 0;
    uint32 reports = 0;
};
static constexpr float LEG_YARDS = 5.0f;
static std::unordered_map<uint32, CrossingProgress> sCrossTravel;   // under sTownLock
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

// {{{ BuddyTownErrandUnderway
// Whether this buddy is partway through a town errand (walking to a
// trainer, a vendor, the mailbox, the auctioneer). The crossing (617e8)
// waits for it before sending the buddy to the dock: "finish the current
// task first" (617h). Pastimes (sitting, sleeping, fishing, wandering) are
// not errands and give way at once; each notices it was interrupted and
// tidies up (stands, puts the pole away) the next time it runs.
bool BuddyTownErrandUnderway(uint32 buddyGuid)
{
    std::lock_guard<std::mutex> lock(sTownLock);
    auto it = sTown.find(buddyGuid);
    return it != sTown.end() && it->second.doing == Doing::Errand;
}
// }}}

// {{{ BuddyTownFishing
// Whether this buddy's town visit is fishing (walking to the shore
// included): the weapons pass leaves its pole in hand then (617e4b).
bool BuddyTownFishing(uint32 buddyGuid)
{
    std::lock_guard<std::mutex> lock(sTownLock);
    auto it = sTown.find(buddyGuid);
    return it != sTown.end() && it->second.doing == Doing::Fish;
}
// }}}

// Buddies left on another map than their owner, reported once each: an
// instance (the dungeon draw's, 617c3), or a crossing between continents
// paused after a failure (buddies_crossing.cpp, 617e8, logs its own error).
static std::mutex sOtherMapLock;
static std::set<uint32> sOtherMapLogged;
// }}}

// {{{ small helpers
static uint64 Now() { return uint64(GameTime::GetGameTimeMS().count()); }

// The creatures round `bot` within `yards`, alive (the grid searcher the
// server uses for such questions).
static std::list<Unit*> UnitsNear(Player* bot, float yards)
{
    std::list<Unit*> units;
    Acore::AnyUnitInObjectRangeCheck check(bot, yards);
    Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> searcher(bot, units, check);
    Cell::VisitObjects(bot, searcher, yards);
    return units;
}

// Whether `o` stands in the town `town`: in the town's own area, or in a
// building or district of it, where the ground under it (the terrain map
// beneath the building) is the town's. The same reading BuddyTownArea
// gives a player (buddies_roam_ground.cpp), for an NPC: a trainer indoors
// counts as being in the town.
//   own area      - yes
//   ground's area - yes when it is the town (a building in it)
//   otherwise     - no (another place, or no terrain loaded under it)
static bool InTown(WorldObject* o, uint32 town)
{
    if (o->GetAreaId() == town)
        return true;
    float x = o->GetPositionX(), y = o->GetPositionY();
    if (GridTerrainData* ground = o->GetMap()->GetGridTerrainData(x, y))
        return ground->getArea(x, y) == town;
    return false;
}

// The buddy's bag slots in all: the backpack's 16 and every bag's.
static uint32 BagSlots(Player* bot)
{
    uint32 total = INVENTORY_SLOT_ITEM_END - INVENTORY_SLOT_ITEM_START;
    for (uint8 i = INVENTORY_SLOT_BAG_START; i < INVENTORY_SLOT_BAG_END; ++i)
        if (Bag* bag = bot->GetBagByPos(i))
            total += bag->GetBagSize();
    return total;
}

// How full the buddy's bags are, 0..1. "merchants, with priority equal to
// how full the buddy's bags are (half-full bags: 50% priority)" (617e,
// 2026-09-23).
static float BagFullness(Player* bot)
{
    uint32 total = BagSlots(bot);
    uint32 freeSlots = bot->GetFreeInventorySpace();
    return total ? float(total - std::min(freeSlots, total)) / float(total) : 0.0f;
}

// Every item in the backpack and bags (not what is worn).
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

static bool CantSpare(PlayerbotAI* ai, Item* item);        // below, with the full-bags rounds
static bool TownHasAuctioneer(Player* bot, uint32 town);

// What to sell at a vendor: everything a vendor pays for, every visit
// (owner, 2026-10-13: "we should sell all we are able every time we are at
// a vendor"; until then only greys and what the bot module judged surplus
// went, and the rest waited until the bags were nine tenths full). Kept,
// each for its reason:
//   what it can't spare (CantSpare)  - the hearthstone, its tools and
//                                      fishing pole, gear and ammo in use,
//                                      quest items, an epic for its owner
//   consumables                      - its food, drink and potions: sold
//                                      here, they'd be bought back at the
//                                      same stop (BuyMeals) or missed in
//                                      the next fight
//   trade goods                      - owner, 2026-09-24: "For trade goods
//                                      they will list it" (the auction
//                                      house), and 2026-09-26: kept "like
//                                      hearthstone, consumables, tradegoods
//                                      for their profession", sold only
//                                      when the bags stay 90% full ("then
//                                      they sell all the tradegoods as
//                                      well"): the full-bags rounds below
//   anything with a "Use:"           - owner, 2026-10-13: "any item with a
//                                      'use' should be kept to be used when
//                                      required" (a scroll, a trinket, a
//                                      bag of something to open)
//   unbound greens and better        - owner, 2026-10-13: "Green and blue
//                                      items should be sold on the AH
//                                      instead of vendored": kept for the
//                                      auction errand (617h), in this town
//                                      or the next one with an auction
//                                      house. Bound ones can't be auctioned
//                                      and are sold here. (Full bags in a
//                                      town without an auction house still
//                                      clear them, by the rounds below.)
//   what the bot module would rather - a white or grey it judges worth an
//   auction, in an auction town        auction there
static std::vector<ObjectGuid> Junk(PlayerbotAI* ai, Player* bot)
{
    uint32 town = BuddyTownArea(bot) ? BuddyTownArea(bot) : bot->GetAreaId();
    bool auctionHere = TownHasAuctioneer(bot, town);
    std::vector<ObjectGuid> junk;
    for (Item* item : BagItems(bot))
    {
        ItemTemplate const* proto = item->GetTemplate();
        if (!proto->SellPrice)
            continue;                                  // a vendor pays nothing for it (quest items, and the like)
        if (CantSpare(ai, item) || proto->Class == ITEM_CLASS_CONSUMABLE || proto->Class == ITEM_CLASS_TRADE_GOODS)
            continue;
        bool hasUse = false;
        for (auto const& s : proto->Spells)
            if (s.SpellId && s.SpellTrigger == ITEM_SPELLTRIGGER_ON_USE)
                hasUse = true;
        if (hasUse)
            continue;                                  // kept to be used
        if (proto->Quality >= ITEM_QUALITY_UNCOMMON && !item->IsSoulBound())
            continue;                                  // for an auction house
        if (auctionHere && proto->Quality != ITEM_QUALITY_POOR &&
            ai->GetAiObjectContext()->GetValue<ItemUsage>("item usage", item->GetEntry())->Get() == ITEM_USAGE_AH)
            continue;                                  // for the auction house here
        junk.push_back(item->GetGUID());
    }
    return junk;
}

// What the buddy would part with for money (617h1's dungeon rule): every
// grey, and what the bot module judges it would sell to a vendor or put up
// at auction; only items a vendor pays for.
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

// Whether anything worn is worn down.
static bool AnythingWorn(Player* bot)
{
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        if (Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            if (item->GetUInt32Value(ITEM_FIELD_MAXDURABILITY) &&
                item->GetUInt32Value(ITEM_FIELD_DURABILITY) < item->GetUInt32Value(ITEM_FIELD_MAXDURABILITY))
                return true;
    return false;
}

// The class trainer's lesson list for this buddy, or null: a class trainer
// for its class with at least one spell it can learn now.
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

// A townsperson worth visiting: alive, not in a fight, not hostile to the
// buddy, not a critter or anyone's pet, and a person (humanoid) or someone
// with a service (a vendor gnome counts, a stray cat does not). In the
// town, indoors included (InTown).
static bool Townsperson(Creature* c, Player* bot, uint32 areaId)
{
    if (c->IsInCombat() || c->IsHostileTo(bot) || c->IsCritter() || c->IsTotem() || c->IsPet() || c->IsGuardian())
        return false;
    if (!c->GetCharmerOrOwnerGUID().IsEmpty() || !InTown(c, areaId))
        return false;
    return c->GetCreatureType() == CREATURE_TYPE_HUMANOID || c->GetNpcFlags() != UNIT_NPC_FLAG_NONE;
}
// }}}

// {{{ the mail
// Mail it can collect now: delivered, not deleted, not cash-on-delivery,
// with items or money in it. Its own old gear (617a6's "Kept for you")
// counts only while some of it is usable now, so gear it hasn't levelled
// into doesn't send it to the mailbox every visit.
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

// The nearest mailbox within the town's reach.
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

// {{{ the runeforge (633)
// The owner, 2026-10-30: "If there is a runeforge in the list of tasks they
// could do in town, then they will reforge their gear with a new
// runeforge." and "every visit. And they send a message to their owner
// saying "I switched to [rune] on my [weapon]"". A rune is the buddy's own
// choice ("nope. it's a personal choice."): drawn at random among those
// that suit the weapon, never the one it has.
//
// The runes, read from the game's spell file on 2026-10-30: the spells
// named "Rune of ...", each enchanting a weapon (effect 53) with the
// enchantment it names. Which weapons each suits is the spell's own
// weapon-kind mask (two-handers only: Swordshattering, Spellshattering,
// Stoneskin Gargoyle; one-handers only: Swordbreaking, Spellbreaking,
// Nerubian Carapace; any: the rest), read from the spell as it is used.
static constexpr uint32 RUNE_SPELLS[] = { 53323, 53331, 53341, 53342, 53343, 53344, 54446, 54447, 62158, 70164 };

// A runeforge near the buddy: a spell focus object of the kind the rune
// spells need (their own RequiresSpellFocus), in reach of a town scan.
static GameObject* NearestRuneforge(Player* bot)
{
    SpellInfo const* rune = sSpellMgr->GetSpellInfo(RUNE_SPELLS[0]);
    if (!rune || !rune->RequiresSpellFocus)
        return nullptr;                                // no focus named: no runeforge to look for
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

// At the runeforge: each hand's weapon gets a new rune, drawn among those
// that suit it, never the one it wears; the owner is told each. Each path
// per hand:
//   no weapon in that hand              - nothing
//   no rune suits it but its own        - nothing (logged)
//   otherwise                           - the new rune put on, the owner whispered
static void DoRuneforge(PlayerbotAI* ai, Player* bot, GameObject* /*forge*/)
{
    Player* owner = ai->GetMaster();
    for (uint8 slot : { uint8(EQUIPMENT_SLOT_MAINHAND), uint8(EQUIPMENT_SLOT_OFFHAND) })
    {
        Item* weapon = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        if (!weapon || weapon->GetTemplate()->Class != ITEM_CLASS_WEAPON)
            continue;
        uint32 kindBit = 1u << weapon->GetTemplate()->SubClass;
        uint32 current = weapon->GetEnchantmentId(PERM_ENCHANTMENT_SLOT);
        std::vector<std::pair<uint32, SpellInfo const*>> suits;     // enchantment, its rune spell
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
        bot->ApplyEnchantment(weapon, PERM_ENCHANTMENT_SLOT, false);   // the old rune's effects off
        weapon->SetEnchantment(PERM_ENCHANTMENT_SLOT, enchant, 0, 0, bot->GetGUID());
        bot->ApplyEnchantment(weapon, PERM_ENCHANTMENT_SLOT, true);
        std::string line = "I switched to " + std::string(spell->SpellName[0]) + " on my " + weapon->GetTemplate()->Name1 + ".";
        if (owner && owner->IsInWorld())
            bot->Whisper(line, LANG_UNIVERSAL, owner);
        LOG_INFO("module", "mod-buddies: buddy {} runeforged its {} with {} (enchantment {})", bot->GetName(),
            weapon->GetTemplate()->Name1, spell->SpellName[0], enchant);
    }
}
// }}}

// At the mailbox: every item and all the money out of each collectable
// mail, then the emptied mail thrown away, through the same server
// requests a player's clicks send (they check the mailbox is in reach, the
// bags have room, and save). An item that doesn't fit stays in the mail
// for the next visit.
static void CountAuctionMail(Player* bot, Mail const* m);   // the auction house section, below (617h)
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
        CountAuctionMail(bot, m);                     // sold / expired: the rising price (617h)
        // its own old gear, mailed when it was made again at a lower level
        // (617a6, buddies_stage.cpp): only what it can use now comes out;
        // the rest waits in the mail until it has levelled into it
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
            // into its bags, if it fit: an arrival, as loot is (617j2's gems)
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
            p << box->GetGUID() << id << uint32(0);   // the last field is a mail template, unused here
            session->HandleMailDelete(p);
        }
    }
    MailToOwner(ai, bot);                             // bind-on-equip epics it has no use for: the owner's (617h)
}
// }}}

// {{{ the auction house (617h)
// The owner's rules (2026-09-24/25), for a buddy at a town's auctioneer:
//   - what goes: green quality and up, not bound, and nothing it has a use
//     for (the bot module's item judgement: an upgrade, a quest item, a
//     skill's or a consumable it uses is kept); whites and greys are the
//     vendor's (Junk above);
//   - epics: an upgrade is kept (it equips it, 617j); gear with a required
//     level that is bind-on-equip and not an upgrade is never sold: it is
//     mailed to the owner at a mailbox; soulbound such gear is vendored;
//     other epics (no required level, not gear) are auctioned;
//   - the minimum, per unit: the vendor price times 1.5 (green), 2 (blue),
//     2.5 (epic); an item with no vendor price is listed at the owner's
//     fixed price (buddy_fixed_price) or not at all;
//   - undercut: the lowest competing listing (same item, same random
//     enchantment) minus 10% for gear, 5% for the rest; when that would
//     fall below the minimum the competition counts as at the minimum: an
//     epic, or an item with fewer than 5 listed, still posts at the minimum
//     if that is below the competitor; otherwise gear is vendored and the
//     rest listed at the minimum;
//   - glut: 5 or more listings of it and not an epic: vendored;
//   - rising: with nothing of it listed, after unsold expiries its price is
//     its last price plus half the vendor price per expiry, with no
//     ceiling, until a copy sells (buddy_price, per auction house; updated
//     from its auction mail at the mailbox, DoMail);
//   - stacks: more than a full stack's worth goes up in random-sized
//     stacks, each 1 to the stack limit; otherwise all at once;
//   - durations: gear 48 hours, trade goods 12, the rest 24;
//   - no money for the deposit: the rest goes to the vendor this visit.
// The bid equals the buyout (the rules name one price).
static constexpr uint32 AH_GLUT          = 5;
static constexpr float  AH_UNDERCUT_GEAR = 0.90f;
static constexpr float  AH_UNDERCUT_REST = 0.95f;
static constexpr float  AH_RISE          = 0.5f;   // x the vendor price, per unsold expiry
static constexpr uint32 AH_MIN_GEAR = 48 * 60, AH_MIN_GOODS = 12 * 60, AH_MIN_REST = 24 * 60;   // minutes

enum class Fate : uint8 { Keep, Auction, Vendor, MailOwner };

static std::mutex sAuctionLock;
static std::unordered_map<uint32, std::set<ObjectGuid>> sToVendor;   // buddy -> items the auction rules sent to the vendor
static std::unordered_map<uint32, std::set<uint32>>     sMailSeen;   // buddy -> auction mails already counted

static bool IsGear(ItemTemplate const* p) { return p->Class == ITEM_CLASS_WEAPON || p->Class == ITEM_CLASS_ARMOR; }

// {{{ FixedPrice
static uint32 FixedPrice(uint32 entry)
{
    if (QueryResult r = CharacterDatabase.Query("SELECT price FROM buddy_fixed_price WHERE item = {}", entry))
        return (*r)[0].Get<uint32>();
    return 0;
}
// }}}

// {{{ OwnerUpgrade (623)
// Whether `item` is earmarked for the owner: gear the owner can wear now
// that scores higher, by the owner's own stat weights (the bot module's
// scorer, asked for the owner as for any player), than what the owner
// wears in the slot it would go to, by at least OWNER_UPGRADE_MARGIN. The
// owner, 2026-10-30: "buddy-bots should mail upgrades to you." Each path:
//   owner offline or away (no master)    - no (judged again at the next stop)
//   not gear, or soulbound (can't mail)  - no
//   the owner can't use it (level, kind) - no
//   the slot it would go to is empty     - yes
//   otherwise                            - yes when it scores higher by the margin
// For rings and trinkets the slot is the one the server would equip into
// (the first empty, else the first of the pair).
static constexpr float OWNER_UPGRADE_MARGIN = 1.05f;   // 5% better than what the owner wears: not a sidegrade
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
        return false;                                  // no slot of the owner's takes it
    Item* worn = owner->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
    if (!worn)
        return true;
    StatsWeightCalculator scorer(owner);
    scorer.SetOverflowPenalty(false);
    float mine = scorer.CalculateItem(p->ItemId, item->GetItemRandomPropertyId());
    float now  = scorer.CalculateItem(worn->GetEntry(), worn->GetItemRandomPropertyId());
    return mine > now * OWNER_UPGRADE_MARGIN;
}
// }}}

// {{{ FateOf
static Fate FateOf(PlayerbotAI* ai, Item* item)
{
    ItemTemplate const* p = item->GetTemplate();
    if (p->Quality < ITEM_QUALITY_UNCOMMON)
        return Fate::Keep;                             // whites and greys: the vendor's own rules (Junk)
    if (p->Class == ITEM_CLASS_QUEST || p->Class == ITEM_CLASS_KEY || p->Class == ITEM_CLASS_CONTAINER)
        return Fate::Keep;                             // quest items, keys; bags are a clan upgrade (617k)
    ItemUsage u = ai->GetAiObjectContext()->GetValue<ItemUsage>("item usage", item->GetEntry())->Get();
    switch (u)
    {
        case ITEM_USAGE_EQUIP: case ITEM_USAGE_REPLACE: case ITEM_USAGE_BROKEN_EQUIP: case ITEM_USAGE_QUEST:
        case ITEM_USAGE_SKILL: case ITEM_USAGE_USE: case ITEM_USAGE_KEEP: case ITEM_USAGE_AMMO: case ITEM_USAGE_GUILD_TASK:
            return Fate::Keep;                         // it has a use for it
        default:
            break;
    }
    if (OwnerUpgrade(ai, item))
        return Fate::MailOwner;                        // earmarked: an upgrade for the owner (623)
    if (p->Quality >= ITEM_QUALITY_EPIC && IsGear(p) && p->RequiredLevel > 0)
    {
        if (item->IsSoulBound())
            return Fate::Vendor;                       // bound, and no use to it
        if (p->Bonding == BIND_WHEN_EQUIPPED)
            return Fate::MailOwner;                    // never sold: the owner's
    }
    if (item->IsSoulBound())
        return Fate::Keep;                             // bound: can't be auctioned (the vendor's rules decide)
    if (!p->SellPrice && !FixedPrice(p->ItemId))
        return Fate::Keep;                             // no vendor price and no fixed price: nothing to go by
    return Fate::Auction;
}
// }}}

// {{{ ItemsForOwner
static std::vector<Item*> ItemsForOwner(PlayerbotAI* ai, Player* bot)
{
    std::vector<Item*> out;
    for (Item* item : BagItems(bot))
        if (FateOf(ai, item) == Fate::MailOwner)
            out.push_back(item);
    return out;
}
// }}}

// {{{ AnythingToAuction
static bool AnythingToAuction(PlayerbotAI* ai, Player* bot)
{
    for (Item* item : BagItems(bot))
        if (FateOf(ai, item) == Fate::Auction)
            return true;
    return false;
}
// }}}

// {{{ DoAuction
static void DoAuction(PlayerbotAI* ai, Player* bot, Creature* npc)
{
    AuctionHouseEntry const* ahEntry = AuctionHouseMgr::GetAuctionHouseEntryFromFactionTemplate(npc->GetFaction());
    AuctionHouseObject* house = sAuctionMgr->GetAuctionsMap(npc->GetFaction());
    if (!ahEntry || !house)
        return;
    uint32 pool = ahEntry->houseId;
    uint32 guid = bot->GetGUID().GetCounter();

    // the lots: same item and same random enchantment together
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

    bool broke = false;                                // no money for a deposit: the rest to the vendor
    for (auto& [key, lot] : lots)
    {
        ItemTemplate const* p = sObjectMgr->GetItemTemplate(lot.entry);
        auto vendorLot = [&]() { for (auto const& it : lot.items) toVendor.insert(it.first); };
        if (broke)
        {
            vendorLot();
            continue;
        }
        // the competition: listings of this item with this enchantment
        uint32 listed = 0, lowest = 0;                 // lowest: per unit, buyout
        for (auto const& [id, a] : house->GetAuctions())
        {
            if (a->item_template != lot.entry)
                continue;
            Item* listedItem = sAuctionMgr->GetAItem(a->item_guid);
            if (listedItem && listedItem->GetItemRandomPropertyId() != lot.prop)
                continue;                              // "of the Tiger" doesn't compete with "of the Whale"
            ++listed;
            if (a->buyout && a->itemCount)
                if (uint32 unit = a->buyout / a->itemCount; !lowest || unit < lowest)
                    lowest = unit;
        }
        bool epic = p->Quality >= ITEM_QUALITY_EPIC, gear = IsGear(p);
        uint32 price = 0;                              // per unit
        if (!p->SellPrice)
            price = FixedPrice(lot.entry);             // the owner's hand-kept price, as it is
        else
        {
            uint32 minimum = uint32(float(p->SellPrice) * (1.0f + 0.5f * float(p->Quality - ITEM_QUALITY_NORMAL)));
            if (listed >= AH_GLUT && !epic)
            {
                vendorLot();                           // a glut
                continue;
            }
            if (!lowest)
            {
                price = minimum;                       // nothing to compete with: the minimum, or the risen price
                if (QueryResult r = CharacterDatabase.Query(
                        "SELECT steps, last_price FROM buddy_price WHERE pool = {} AND item = {}", pool, lot.entry))
                    if ((*r)[0].Get<uint32>() > 0)
                        price = std::max(minimum, (*r)[1].Get<uint32>());
            }
            else
            {
                uint32 under = uint32(float(lowest) * (gear ? AH_UNDERCUT_GEAR : AH_UNDERCUT_REST));
                if (under >= minimum)
                    price = under;                     // the undercut
                else if ((epic || listed < AH_GLUT) && minimum < lowest)
                    price = minimum;                   // near the minimum, still below the competitor
                else if (gear)
                {
                    vendorLot();                       // only minimum-price gear listed: vendored
                    continue;
                }
                else
                    price = minimum;                   // trade goods and the rest: listed at the minimum
            }
        }
        if (!price)
            continue;
        uint32 minutes = gear ? AH_MIN_GEAR : p->Class == ITEM_CLASS_TRADE_GOODS ? AH_MIN_GOODS : AH_MIN_REST;

        // the stacks: random sizes when there is more than a full stack
        uint32 maxStack = std::max<uint32>(1, p->GetMaxStackSize());
        std::vector<uint32> stacks;
        for (uint32 left = lot.total; left; )
        {
            uint32 n = lot.total > maxStack ? std::min(left, urand(1, maxStack)) : left;
            stacks.push_back(n);
            left -= n;
        }
        size_t next = 0;                               // the lot's item being drawn from
        uint32 usedOfNext = 0;
        for (uint32 n : stacks)
        {
            // the items (and how many of each) that make up this stack
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
                // "They need the coin, and they need it now!"
                broke = true;
                vendorLot();
                break;
            }
            // the request the auction window sends
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
    // gems for its empty sockets, while it has spare bag slots (617j2)
    BuddyBuyGemsAtAuction(bot, npc);
    std::lock_guard<std::mutex> lock(sAuctionLock);
    sToVendor[guid].insert(toVendor.begin(), toVendor.end());
}
// }}}

// {{{ CountAuctionMail
// An auction mail, read before it is collected: "sold" resets the item's
// rising price; "expired" raises it by half the vendor price (the next
// listing uses it when nothing of the item is listed). The subject is the
// server's own "item:0:outcome:auction:count"; the sender, the auction
// house. Each mail counted once, even if it has to wait for bag room.
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
// }}}

// {{{ the treat (623)
// Now and then a mail carries a little money with a line in the buddy's
// own voice (the owner, 2026-10-30: "maybe once or twice as a treat. Every
// once in a while. They'll usually just send like 1c and say "I found a
// lucky penny for you." or 10g pieces for a level 60 and say "this fell
// out of some rich guy's pocket while I was walking close behind him in
// Stormwind, don't worry about it" says the rogue, that sort of thing.").
// At each mailbox stop: TREAT_CHANCE of a treat; of treats, TREAT_PURSE_CHANCE
// are a purse (its level squared times TREAT_PURSE_PER_LEVEL2 copper: 10
// gold at level 60), the rest the lucky penny. A purse comes out of the
// buddy's own money; one it can't afford is a penny instead. The purse's
// line is its class's (TREAT_LINES, by class id; the rogue's is the
// owner's own words).
static constexpr float  TREAT_CHANCE          = 0.10f;
static constexpr float  TREAT_PURSE_CHANCE    = 0.25f;
static constexpr uint32 TREAT_PURSE_PER_LEVEL2 = 28;     // copper x level^2: 60 -> 100800, about 10 gold
static char const* const PENNY_LINE = "I found a lucky penny for you.";
static char const* const TREAT_LINES[] = {
    "Some coin from the road. Spend it on something shiny.",                                  //  0 (none)
    "Took this off a brute who swung first. Buy yourself a whetstone.",                       //  1 warrior
    "The Light provides, and today it provided this. Share it well.",                         //  2 paladin
    "Found this in a nest my pet dug up. Don't ask what else was in there.",                  //  3 hunter
    "this fell out of some rich guy's pocket while I was walking close behind him in Stormwind, don't worry about it", //  4 rogue
    "An offering left at a shrine. I'm sure they meant it for you.",                          //  5 priest
    "The dead don't need it. I asked.",                                                       //  6 death knight
    "The spirits pointed me to it under a stone. Thank them, not me.",                        //  7 shaman
    "Conjured? No. Found. Probably. Enjoy it.",                                               //  8 mage
    "A small contract, fulfilled. Your share.",                                               //  9 warlock
    "Squirrels hoard the strangest things.",                                                  // 10 (none)
    "A bear was sitting on it. I asked nicely.",                                              // 11 druid
};
// }}}

// {{{ MailToOwner
// Its earmarked items go to its owner (OwnerUpgrade, and bind-on-equip
// epics it has no use for, never sold), with a treat now and then; a
// treat alone is mailed too.
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
            money = 1;                                 // the lucky penny (a copper, conjured: it never left a purse)
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
            bot->ModifyMoney(-int32(money));           // a purse is the buddy's own
        draft.AddMoney(money);
    }
    uint32 n = 0;
    for (Item* item : items)
    {
        if (n == MAX_MAIL_ITEMS)
            break;                                     // a mail holds twelve; the rest go next visit
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
// }}}
// }}}

// {{{ the meals (617h)
// "At a repair or vendor stop the buddy may also buy consumables it will
// actually use in the field" (the owner, 2026-09-24). What a buddy eats is
// what the roam action's meal eats (buddies_roam_strategy.cpp, the meal:
// the bot module's own eating is switched off for buddies, being its food
// cheat, "they need real food"), so the same rule picks what to buy: a
// consumable of the food-and-drink kind whose spell restores health (food)
// or mana (drink), that the buddy can use at its level; the starting kit
// gives the same (buddies_kit.cpp, GiveMeals). Drink only for mana users.
// Bought with gold only (never a token or badge price), up to MEAL_STOCK
// servings, spending at most MEAL_SPEND_SHARE of its money per stop. Potions
// wait for the vendor lists the owner will fill in later ("Don't worry about
// that now").
struct MealKind { AuraType regen; bool manaOnly; };
static MealKind const MEAL_KINDS[] = {
    { SPELL_AURA_MOD_REGEN,       false },   // food: health
    { SPELL_AURA_MOD_POWER_REGEN, true  },   // drink: mana, for those who use it
};

static bool WantsMeal(Player* bot, MealKind const& k) { return !k.manaOnly || bot->getPowerType() == POWER_MANA; }

// {{{ IsMealFor
static bool IsMealFor(Player* bot, ItemTemplate const* p, AuraType regen)
{
    if (p->Class != ITEM_CLASS_CONSUMABLE || p->SubClass != ITEM_SUBCLASS_FOOD)
        return false;
    SpellInfo const* spell = sSpellMgr->GetSpellInfo(uint32(p->Spells[0].SpellId));
    return spell && spell->HasAura(regen) && bot->CanUseItem(p) == EQUIP_ERR_OK;
}
// }}}

// {{{ MealsCarried
static uint32 MealsCarried(Player* bot, AuraType regen)
{
    uint32 n = 0;
    for (Item* item : BagItems(bot))
        if (IsMealFor(bot, item->GetTemplate(), regen))
            n += item->GetCount();
    return n;
}
// }}}

// {{{ MealOnSale
// The best meal of this kind the vendor sells for gold (highest item level,
// as the meal eats the best first), and its place in the vendor's list;
// false when it sells none the buddy can use.
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
            continue;                                  // a token or badge price: not for meals
        ItemTemplate const* p = sObjectMgr->GetItemTemplate(v->item);
        if (!p || !IsMealFor(bot, p, regen))
            continue;
        if (!best || p->ItemLevel > best->ItemLevel)
            best = p, slot = i;
    }
    return best != nullptr;
}
// }}}

// {{{ HungryFor
// Whether some meal it wants is below `below` servings and this vendor sells
// one (BuildTodo's choice of shop when a buddy is running short).
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
// }}}

// {{{ BuyMeals
// One purchase at a time, through the server's own vendor purchase (its
// checks: in reach, money, room, a limited stock), so a refusal stops that
// kind there and leaves what was bought.
static void BuyMeals(Player* bot, Creature* npc)
{
    if (!npc->IsVendor())
        return;                                        // a repairer that sells nothing
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
            continue;                                  // this vendor sells none of this kind
        uint32 have  = MealsCarried(bot, k.regen);
        uint32 price = uint32(std::floor(float(p->BuyPrice) * discount));
        uint32 per   = std::max<uint32>(1, p->BuyCount);
        while (have < MEAL_STOCK && spent + price <= budget)
        {
            if (!bot->BuyItemFromVendorSlot(npc->GetGUID(), slot, p->ItemId, 1, NULL_BAG, NULL_SLOT))
                break;                                 // refused (no room, sold out): what it has will do
            spent += price;
            have  += per;
        }
    }
}
// }}}
// }}}

// {{{ full bags without an auction house (617h)
// The owner's rule (2026-09-25), for a town with no auction house: "sell the
// lowest-value half of the bag space (keeping hearthstone, consumables,
// profession trade goods); still 90% full: sell trade goods; still 90%
// full: sell consumables; past that, an error." Done at the vendor stop,
// after the junk, when the bags are FULL_BAGS_SHARE full or more:
//   1 the lowest-value half - the cheapest items (vendor price times count),
//                             up to half the bag slots' worth of them, held
//                             back: the hearthstone, consumables, trade
//                             goods, and what the buddy can't spare (below)
//   2 trade goods           - cheapest first, until under the line
//   3 consumables           - cheapest first, until under the line (never
//                             the hearthstone)
//   still full              - an error, with what each round did
// Never sold in any round (assumed 2026-10-02, open question in 617h): a
// bind-on-equip epic for its owner ("They should never vendor a BoE epic
// item"), a profession tool or fishing pole (selling one ends that
// profession), and anything the bot module judges in use (gear it would
// wear, ammo, quest items). "Lowest value" is the vendor's price for the
// slot's whole stack.
static constexpr uint32 HEARTHSTONE = 6948;

// {{{ SellItem
// The client's sell request at `npc`; whether the item left the bags.
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
// }}}

// {{{ CantSpare
// What no round sells (see above).
static bool CantSpare(PlayerbotAI* ai, Item* item)
{
    ItemTemplate const* p = item->GetTemplate();
    if (p->ItemId == HEARTHSTONE || p->TotemCategory)
        return true;                                   // the hearthstone; a tool (pick, knife, rod, hammer)
    if (p->Class == ITEM_CLASS_WEAPON && p->SubClass == ITEM_SUBCLASS_WEAPON_FISHING_POLE)
        return true;
    if (BuddyIsKeptWeapon(ai->GetBot(), item))
        return true;                                   // its best weapons and runners-up (617e4b)
    if (FateOf(ai, item) == Fate::MailOwner)
        return true;                                   // the owner's epic, waiting for a mailbox
    switch (ai->GetAiObjectContext()->GetValue<ItemUsage>("item usage", item->GetEntry())->Get())
    {
        case ITEM_USAGE_EQUIP: case ITEM_USAGE_REPLACE: case ITEM_USAGE_BROKEN_EQUIP:
        case ITEM_USAGE_QUEST: case ITEM_USAGE_AMMO:
            return true;                               // in use, or about to be
        default:
            return false;
    }
}
// }}}

// {{{ the rounds
// Each round: which items it may sell, and whether it stops at half the bag
// slots sold (round 1) or as soon as the bags are under the line (2 and 3).
struct ClearRound { char const* name; bool (*maySell)(PlayerbotAI*, Item*); bool halfTheSpace; };
static bool RoundLowestHalf(PlayerbotAI*, Item* i) { uint32 c = i->GetTemplate()->Class; return c != ITEM_CLASS_CONSUMABLE && c != ITEM_CLASS_TRADE_GOODS; }
static bool RoundTradeGoods(PlayerbotAI*, Item* i) { return i->GetTemplate()->Class == ITEM_CLASS_TRADE_GOODS; }
static bool RoundConsumable(PlayerbotAI*, Item* i) { return i->GetTemplate()->Class == ITEM_CLASS_CONSUMABLE; }
static ClearRound const CLEAR_ROUNDS[] = {
    { "the lowest-value half", RoundLowestHalf, true  },
    { "trade goods",           RoundTradeGoods, false },
    { "consumables",           RoundConsumable, false },
};
// }}}

// {{{ TownHasAuctioneer
static bool TownHasAuctioneer(Player* bot, uint32 town)
{
    for (Unit* u : UnitsNear(bot, TOWN_SCAN_YARDS))
        if (Creature* c = u->ToCreature())
            if (c->IsAuctioner() && !c->IsHostileTo(bot) && InTown(c, town))
                return true;
    return false;
}
// }}}

// {{{ ClearFullBags
static void ClearFullBags(PlayerbotAI* ai, Player* bot, Creature* npc, uint32 town)
{
    uint32 slots  = BagSlots(bot);
    float  before = BagFullness(bot);
    std::string done;                                  // each round's outcome, for the error
    for (ClearRound const& round : CLEAR_ROUNDS)
    {
        if (BagFullness(bot) < FULL_BAGS_SHARE)
            break;                                     // under the line: the rest of the rounds aren't needed
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

    // still full: what is left, counted when the message is made
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
// }}}
// }}}

// {{{ BuildTodo
// The town's errands for this buddy, from what the town offers ("some
// towns don't even have repair stations"; a missing service is skipped),
// the nearest of each, in the owner's order (617h, 2026-09-24):
//   1 repair       something worn is broken (the client shows it red)
//   2 trainer      it has something to learn
//   3 repair       something is badly worn (yellow), nothing broken
//   4 mailbox      mail to collect (a reward that didn't fit its bags,
//                  617d; auction money and returned items), or a
//                  bind-on-equip epic to send its owner
//   5 auction      something to auction
//   6 repair       anything worn at all
//   7 vendor       junk (odds equal to how full its bags are), and
//                  whatever the auction rules send to a vendor; always
//                  when its bags are FULL_BAGS_SHARE full in a town with no
//                  auction house (the clearance, above); always when its
//                  food or drink is under MEAL_LOW and a vendor here sells
//                  it (that vendor is the stop, the meals are bought there)
static constexpr float YELLOW_SHARE = 0.2f;   // "badly worn": a fifth of its durability or less (assumed from the client's warning)

// Whether some worn item is at or below `share` of its durability.
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
    Creature* grocer     = nullptr;                    // a vendor selling the meal it is short of
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
        todo.push_back({ Errand::Repair, repairer->GetGUID() }), repairing = true;          // 1 broken
    if (trainer)
        todo.push_back({ Errand::Train, trainer->GetGUID() });                                // 2
    if (repairer && !repairing && WornAtMost(bot, YELLOW_SHARE))
        todo.push_back({ Errand::Repair, repairer->GetGUID() }), repairing = true;          // 3 badly worn
    if (MailWaiting(bot) || !ItemsForOwner(ai, bot).empty())                                  // 4
        if (GameObject* box = NearestMailbox(bot))
            todo.push_back({ Errand::Mail, box->GetGUID() });
    // a death knight's runeforge, every visit where the town has one (633)
    if (bot->getClass() == CLASS_DEATH_KNIGHT)
        if (GameObject* forge = NearestRuneforge(bot))
            todo.push_back({ Errand::Runeforge, forge->GetGUID() });
    bool auctioning = auctioneer && AnythingToAuction(ai, bot);
    if (auctioning)
        todo.push_back({ Errand::Auction, auctioneer->GetGUID() });                           // 5
    if (repairer && !repairing && AnythingWorn(bot))
        todo.push_back({ Errand::Repair, repairer->GetGUID() });                              // 6 anything worn
    bool vendorWork = false;
    {
        std::lock_guard<std::mutex> lock(sAuctionLock);
        auto it = sToVendor.find(bot->GetGUID().GetCounter());
        vendorWork = it != sToVendor.end() && !it->second.empty();
    }
    // 7: the shop is the grocer when it is short of a meal (selling works at
    // any vendor), else the nearest vendor
    //   hungry     - the grocer, whatever else there is to do
    //   full bags  - no auction house here and bags past the line: cleared
    //   otherwise  - junk by the bag-fullness odds, or the auction's leftovers
    Creature* shop = grocer ? grocer : vendor;
    bool clearing  = !auctioneer && BagFullness(bot) >= FULL_BAGS_SHARE;
    if (shop && (grocer || clearing || (!Junk(ai, bot).empty() && rand_norm() < BagFullness(bot)) || auctioning || vendorWork))
        todo.push_back({ Errand::Sell, shop->GetGUID() });                                    // 7
    return todo;
}
// }}}

// {{{ the errands themselves
// Each done at the NPC, silently (see the file's header), with the same
// server calls the bot module's own actions make.
//   Train  - every spell the trainer can teach it now, paid as a player
//            pays (the server's Trainer::TeachSpell: checks and money)
//   Sell   - everything Junk() lists, as the client's sell request; then,
//            in a town with no auction house and bags past the line, the
//            clearance; then its meals bought (617h)
//   Repair - everything worn, paid, with the NPC's reputation discount;
//            then its meals, if the repairer sells them (617h)
static void DoTrain(PlayerbotAI* /*ai*/, Player* bot, Creature* npc)
{
    BuddyTrainAtTrainer(bot, npc);                     // cheapest first, until the purse runs short; then quest spells (617n)
}
static void DoSell(PlayerbotAI* ai, Player* bot, Creature* npc)
{
    // junk, and what the auction rules sent to a vendor (617h)
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

    // full bags where no auctioneer takes the surplus (the town is read the
    // way the visit reads it: a building inside the town is the town)
    uint32 town = BuddyTownArea(bot) ? BuddyTownArea(bot) : bot->GetAreaId();
    if (BagFullness(bot) >= FULL_BAGS_SHARE && !TownHasAuctioneer(bot, town))
        ClearFullBags(ai, bot, npc, town);
    BuyMeals(bot, npc);                               // after selling: room in the bags, coin in the purse
}
static void DoRepair(PlayerbotAI* /*ai*/, Player* bot, Creature* npc)
{
    bot->DurabilityRepairAll(true, bot->GetReputationPriceDiscount(npc), false);
    BuyMeals(bot, npc);                               // after repairing, so the repair is paid first
}
// the selling trip's way in (617h1, buddies_town.h)
float BuddyBagFullness(Player* bot) { return BagFullness(bot); }
float BuddyFullBagsShare() { return FULL_BAGS_SHARE; }
void  BuddySellAtVendor(PlayerbotAI* ai, Player* bot, Creature* npc) { DoSell(ai, bot, npc); }
std::vector<Item*> BuddyDisposableItems(PlayerbotAI* ai, Player* bot) { return Disposable(ai, bot); }

using ErrandFn = void (*)(PlayerbotAI*, Player*, Creature*);
static std::unordered_map<uint8, ErrandFn> const sErrands = {
    { uint8(Errand::Train),  DoTrain  },
    { uint8(Errand::Sell),   DoSell   },
    { uint8(Errand::Repair), DoRepair },
    { uint8(Errand::Auction), DoAuction },
};
// }}}

// {{{ BuddyTravelStepAction
// Walks the buddy toward its owner until it stands in the owner's named
// area. The destination is the owner's own position (always inside the
// area, and on walkable ground); arriving anywhere in the area ends the
// trip. Runs, not walks: it is a journey, not a stroll.
//
// Stuck: reported, never moved. The bot module's long walk (MoveFarTo) has
// its own recovery: after 90 seconds without real progress it puts the bot
// at the destination. That is switched off here by resetting its stuck
// clock before every step (the clock lives in the bot's public "rpg"
// state), and this action keeps its own measure: no 10-yard gain toward the
// owner in 90 seconds (the owner, 2026-09-27: "let's make it 10"; it was
// 5), or three long walks in a row that found no way. Either is logged as
// an error naming where the buddy stands, where it was going and why
// (ReportStuck), and the buddy stays and keeps trying. Until 2026-10-30 it
// was then hopped to a random walkable spot within 30 yards (the owner,
// 2026-09-27: "like the unstuck command"); removed as a fallback that hid
// the fault (the owner, 2026-10-30, asked whether a stuck buddy should
// stay stuck and be reported loudly: "yeah. we'll sweep it up in the logs
// and work on it when we can."; 617e4).
class BuddyTravelStepAction : public NewRpgBaseAction
{
public:
    BuddyTravelStepAction(PlayerbotAI* botAI) : NewRpgBaseAction(botAI, "buddy travel step") { }

    bool isUseful() override
    {
        Player* owner = botAI->GetMaster();
        if (!owner || !owner->IsInWorld() || !bot->IsAlive() || bot->IsInCombat())
            return false;
        // Aboard a boat, stepping off one, or the owner on another
        // continent: the crossing (buddies_crossing.cpp, 617e8) says where
        // to walk, and this action walks it.
        if (BuddyCrossingWanted(bot, owner))
            return true;
        if (owner->GetMapId() != bot->GetMapId())
        {
            // an instance, or a crossing paused after a failure: stays (logged once)
            std::lock_guard<std::mutex> lock(sOtherMapLock);
            if (sOtherMapLogged.insert(bot->GetGUID().GetCounter()).second)
                LOG_INFO("module", "mod-buddies: buddy {} is on map {} and its owner {} on map {}, an instance or a crossing "
                    "paused after a failure (logged as an error then), so it stays for now",
                    bot->GetName(), bot->GetMapId(), owner->GetName(), owner->GetMapId());
            return false;
        }
        if (bot->GetMap()->Instanceable())
            return false;
        // in the same town (a building inside it included) is not "elsewhere":
        // the town visit has it, wherever in the town it is (the owner,
        // 2026-10-27, of travelling to the owner inside one town circle:
        // "that's not intended behavior")
        if (uint32 town = BuddyTownArea(owner))
            if (BuddyTownArea(bot) == town)
                return false;
        return bot->GetAreaId() != owner->GetAreaId();
    }

    bool Execute(Event /*event*/) override
    {
        Player* owner = botAI->GetMaster();
        if (!owner)
            return false;
        if (bot->IsWalking())
            bot->SetWalk(false);
        {
            std::lock_guard<std::mutex> lock(sOtherMapLock);
            sOtherMapLogged.erase(bot->GetGUID().GetCounter()); // moving again: report anew next time
        }

        // the crossing's step: walk where it says (straight on and off a
        // deck, the long walk otherwise), or nothing when it handled the step
        if (BuddyCrossingWanted(bot, owner))
        {
            BuddyCrossingMove move;
            if (!BuddyCrossingStep(bot, owner, move))
                return true;
            botAI->rpgInfo.stuckTs = getMSTime();     // the bot module's own teleport-to-destination stays off
            botAI->rpgInfo.stuckAttempts = 0;
            if (move.straight)
            {
                bot->GetMotionMaster()->MovePoint(0, move.x, move.y, move.z, FORCED_MOVEMENT_NONE, 0.0f, 0.0f,
                    /*generatePath*/ false, /*forceDestination*/ false);
                return true;
            }
            // the long walk to the crossing: no 10-yard gain toward its
            // place in 90 seconds is reported stuck, as the walk to the
            // owner is (the owner, 2026-10-30, on a stuck rule toward the
            // dock: "this is a fallback, if buddies are getting stuck, we
            // should find out why, and fix that error instead"; so it is
            // reported, never moved, 617e8). Each path:
            //   a new leg (the place moved more than LEG_YARDS): measured afresh
            //   a 10-yard gain: the clock starts again
            //   90 seconds without one: reported, and it keeps walking
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
        BuddyCrossingForget(bot);                      // on the owner's map again: any crossing is over
        {
            std::lock_guard<std::mutex> lock(sTownLock);
            sCrossTravel.erase(bot->GetGUID().GetCounter());
        }

        // the stuck rule (see above): progress is the distance to the owner
        uint32 guid = bot->GetGUID().GetCounter();
        uint64 now  = Now();
        float  dist = bot->GetExactDist(owner);
        bool   stuck = false;
        {
            std::lock_guard<std::mutex> lock(sTownLock);
            TravelProgress& p = sTravel[guid];
            if (p.toArea != owner->GetAreaId() || p.since == 0)
                p = { owner->GetAreaId(), dist, now };        // a new trip
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

        // keep the bot module's own teleport-to-destination from firing
        botAI->rpgInfo.stuckTs = getMSTime();
        botAI->rpgInfo.stuckAttempts = 0;
        float ax, ay, az;
        ArrivalPlace(owner, ax, ay, az);
        bool walking = MoveFarTo(WorldPosition(owner->GetMapId(), ax, ay, az));
        // No way found to the arc: along the owner's own track instead (the
        // owner, 2026-10-27, idea 3: "the owner's feet already proved the
        // way", through gates, lifts and cave mouths the mesh may not join).
        // Each path:
        //   a track, and a way to its point a few steps on - walk that
        //   no track (just arrived, teleported) or no way to it either -
        //                                                  the failure counts
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
        // A long walk that found no way (2026-10-27: Matis's, every step,
        // from one spot): FAILS_BEFORE_REPORT of them in a row and it is
        // reported stuck now, not after STUCK_MS of standing.
        //   found a way: the counts start again
        //   none, the third in a row: reported (the count of reports in a
        //     row named), and it tries again next step
        //   none, fewer: tried again next step
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

    // {{{ ArrivalPlace
    // The place this buddy walks to on its owner's arrival arc. Every
    // traveller of the owner seen lately is given a place afresh, each time
    // any of them steps: the pairs of (buddy, place) taken shortest first,
    // so the nearest buddy gets the nearest place and one already on its
    // way gives up its place to a nearer one and is handed the next free
    // place instead (its waypoint moves on its next step). The arc is
    // centred on the way the owner faces, a place ARRIVE_SPACING along it
    // from the next, at ARRIVE_RADIUS (wider when the places would wrap
    // round); the height the ground there, or the owner's when none is found.
    void ArrivalPlace(Player* owner, float& x, float& y, float& z)
    {
        uint32 me = bot->GetGUID().GetCounter(), boss = owner->GetGUID().GetCounter();
        uint64 now = Now();
        float ox = owner->GetPositionX(), oy = owner->GetPositionY(), oz = owner->GetPositionZ(), oo = owner->GetOrientation();
        std::lock_guard<std::mutex> lock(sTownLock);
        auto& claims = sArrive[boss];
        // travellers not seen stepping for ARRIVE_CLAIM_MS have arrived or stopped
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
        // every (buddy, place) pair by distance, shortest first; each buddy
        // and each place used once
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
            z = oz;                                    // no ground found there: the owner's height
    }
    // }}}

private:
    // {{{ ReportStuck
    // A stuck buddy, said loudly where it can be swept up from the log
    // (one line, "mod-buddies: STUCK", greppable): who, where it stands
    // (map, zone, area, x y z), where it was going (its owner's area and
    // place, and the distance left), why it counts as stuck, and how many
    // reports in a row. Nothing moves it: the fault is the pathfinding's,
    // mended from these lines (617o). The owner's hearthstone still
    // rescues it by hand. Two forms: going to the owner, and going to any
    // named place (the crossing's dock, portal or tower, 617e8).
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
    // }}}
};
// }}}

// {{{ BuddyTownStepAction
// One step of the town visit: the next errand, or the current pastime, or
// choosing the next pastime.
class BuddyTownStepAction : public MovementAction
{
public:
    BuddyTownStepAction(PlayerbotAI* botAI) : MovementAction(botAI, "buddy town step") { }

    // Only in a town, in the owner's own area (travel brings it there
    // first), alive, out of combat, owner online on the same map.
    bool isUseful() override
    {
        Player* owner = botAI->GetMaster();
        if (!owner || !owner->IsInWorld() || !bot->IsAlive() || bot->IsInCombat())
            return false;
        if (owner->GetMapId() != bot->GetMapId() || bot->GetMap()->Instanceable())
            return false;
        if (bot->GetTransport())                       // aboard at a port town's dock: travel steps it off first (617e8)
            return false;
        uint32 town = BuddyTownArea(owner);            // a building inside a town counts as the town
        return town && BuddyTownArea(bot) == town;
    }

    // {{{ WalkTo (617o3)
    // A walk across town to a person or object: by the town's distance map
    // to it (baked once per spot, over the town's exploring grid, whose
    // steps the navigation mesh allows) a stretch at a time, then the last
    // yards by the bot module's own approach. The town's grid is measured
    // the first time one is asked for; until it is ready (the first
    // minute or so of the first visit) the walk is the bot module's alone,
    // as before, and the trace says so.
    bool WalkTo(WorldObject* to, float nearYards)
    {
        // the turn rule (buddies_steer.h): setting off from standing, face
        // the way first; once walking, the town's stretches follow on
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
    // }}}

    bool Execute(Event /*event*/) override
    {
        uint32 guid   = bot->GetGUID().GetCounter();
        // the town's own area number, also inside its buildings, so stepping
        // into an inn with its own number is not a new town (errands afresh)
        uint32 areaId = BuddyTownArea(bot) ? BuddyTownArea(bot) : bot->GetAreaId();
        uint64 now    = Now();
        TownState s   = LoadTown(guid);

        // "Walk, not run" in towns.
        if (!bot->IsWalking())
            bot->SetWalk(true);

        // A new town (or the first step in one): its errands, afresh.
        if (s.areaId != areaId || s.mapId != bot->GetMapId())
        {
            StandUp();
            s = TownState();
            s.areaId = areaId;
            s.mapId  = bot->GetMapId();
            s.todo   = BuildTodo(botAI, bot, areaId);
        }

        // The guards' fight comes first, within patience (617e12).
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
                return false;                              // a pause between pastimes: stand about
            }
            if (!s.todo.empty())
            {
                NextErrandFirst(s);
                Begin(s, Doing::Errand, s.todo.front().npc, now);
            }
            else
                ChoosePastime(s, areaId, now);
        }

        // Dispatch on what it is doing: each returns whether it acted.
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
    // {{{ HelpTheGuards (617e12)
    // A monster fighting the town's people, near and inside the town: the
    // buddy joins in, as roaming opens a fight (the bot module's combat
    // takes over from there, and this step waits, being out of use while
    // the buddy is in combat). The owner, 2026-10-30: "if the guards are
    // fighting something then the buddy-bots should help out until there's
    // no monsters around, then they can converse... in some cases the
    // monsters continuously spawn, so we should make sure that they do
    // eventually prioritize their errands over fighting, to get them done."
    // Each path:
    //   no such monster          - nothing to do; the patience clock is reset
    //   errands waiting, helping longer than ERRAND_PATIENCE_MS
    //                            - the errands first (the fight is left to the
    //                              guards) until the to-do list is empty
    //   otherwise                - the nearest such monster is attacked; a
    //                              pastime under way is ended (stood up, its
    //                              bed let go), an errand kept and its walk's
    //                              give-up clock restarted
    // A monster counts when it is alive, hostile to the buddy, in combat
    // with someone the buddy is not hostile to (a guard, a townsperson, a
    // player of its side), and inside the town (its own area or a building
    // of it), so a fight at the gate's far side draws no one out.
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
            return false;                                  // patience spent: errands first
        if (errandsWaiting && !s.helpingSince)
            s.helpingSince = now;

        if (s.doing == Doing::Errand)
            s.began = now;                                 // the walk's give-up clock starts again after the fight
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
    // }}}

    // {{{ bookkeeping
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
    // Walking there, or given up after WALK_GIVE_UP_MS (a path the mesh
    // can't find, an NPC upstairs out of reach).
    bool TooLong(TownState const& s, uint64 now) { return !s.there && now - s.began > WALK_GIVE_UP_MS; }
    void Emote(TownState& s, uint64 now, uint32 emote)
    {
        if (now < s.nextEmote)
            return;
        bot->HandleEmoteCommand(emote);
        s.nextEmote = now + urand(EMOTE_MIN_MS, EMOTE_MAX_MS);
    }
    // }}}

    // {{{ NextErrandFirst
    // Which errand next: the list is built in priority order (BuildTodo),
    // but it is run ping-pong, not in that order (the owner, 2026-10-30:
    // "the errands are chosen semi-randomly. so it won't be a circle,
    // otherwise the buddy-bots will always choose the same tasks each time
    // ... ping-pong between them", and "50% chance to pick the nearest on
    // their todo list, 50% chance to pick the farthest. unless the farthest
    // is more than 4x the distance to the nearest, then they do the
    // nearest."). The chosen one is moved to the front, the rest kept in
    // their order. Each path:
    //   one errand or none: nothing to choose
    //   the farthest more than 4 times as far as the nearest: the nearest
    //   otherwise: a coin toss, the nearest or the farthest
    // An errand whose NPC or mailbox can't be found counts as at 0 yards,
    // so it comes first and RunErrand drops it at once.
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
    // yards from the buddy to an errand's NPC or mailbox; 0 when not found
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
    // }}}

    // {{{ RunErrand
    // Walk to the errand's NPC, face it, a talking animation, the errand.
    bool RunErrand(TownState& s, uint64 now)
    {
        ErrandStop stop = s.todo.front();
        if (stop.kind == Errand::Mail || stop.kind == Errand::Runeforge)
        {
            // a mailbox or a runeforge is an object, not a person: walk to it, use it
            GameObject* box = ObjectAccessor::GetGameObject(*bot, stop.npc);
            if (!box || TooLong(s, now))
            {
                s.todo.erase(s.todo.begin());          // gone or out of reach: the next visit tries again
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
            s.todo.erase(s.todo.begin());              // gone, dead, or out of reach: skipped
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
    // }}}

    // {{{ ChoosePastime
    // Leisure, by the odds above: a townsperson (the wander, below), a chair
    // (sociable ones preferred), a sleep on one of the town's beds, or
    // fishing. A pastime with nothing to use (no chair near, no free bed, no
    // water, no pole) falls to a townsperson; with no townsperson either, it
    // stands about for a pause.
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
            s.idleUntil = now + urand(GAP_MIN_MS, GAP_MAX_MS);   // nobody about but whom it just left: a pause
            return;
        }
        Begin(s, Doing::Visit, next->GetGUID(), now);
        s.lastVisit = next->GetGUID();
    }

    // {{{ the wander (617h)
    // Which townsperson next, one of the owner's three ways (2026-09-24),
    // picked at random:
    //   toward the farthest - the next closest townsperson in the general
    //                         direction of the town's most distant one
    //   toward a trainer    - the next closest in the general direction of
    //                         one of its class trainers in the town
    //   anyone              - a random townsperson
    // "General direction" is within WANDER_CONE either side of the bearing;
    // the townsperson aimed at is itself in it, so a way finds someone unless
    // the buddy already stands beside them. A way with nothing to go on (a
    // town without its class trainer; the buddy beside the one aimed at)
    // gives way to the next in a fresh random order, as a town lacking a
    // service skips it; "anyone" always finds someone while anyone is about.
    // The one it just visited is left out, so it moves on. The walk is the
    // visit's own (MoveNear: the navigation mesh, at a walk in towns).
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

    // The nearest of `people` within WANDER_CONE of the bearing to `aim`,
    // not one it already stands beside; null when there is none.
    Creature* NextToward(std::vector<Creature*> const& people, Creature* aim)
    {
        float bearing = bot->GetAngle(aim);
        Creature* best = nullptr;
        for (Creature* c : people)
        {
            if (bot->GetDistance(c) <= ARRIVED_YARDS)
                continue;                              // already there
            float off = std::fabs(std::remainder(bot->GetAngle(c) - bearing, 2.0f * float(M_PI)));
            if (off > WANDER_CONE)
                continue;                              // not the general direction
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
                trainers.push_back(c);                 // its class's trainer, lessons or not
        }
        if (trainers.empty())
            return nullptr;                            // none in this town (or none within reach)
        return NextToward(people, trainers[urand(0, uint32(trainers.size()) - 1)]);
    }

    Creature* AnyTownsperson(std::vector<Creature*> const& people)
    {
        return people[urand(0, uint32(people.size()) - 1)];
    }
    // }}}

    // A chair near the buddy: type "chair" game objects in the area. The
    // sociable ones (townspeople and buddies seated or standing within
    // CROWD_YARDS) are preferred: one is picked at random among the chairs
    // with the most company.
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

    // "Sometimes they'll sleep on beds": only on beds placed by hand for this
    // town (buddies_beds.cpp), one buddy to a spot. A town with none has no
    // sleeping (owner, 2026-09-27: "proper beds"; the floor by the
    // innkeeper, tried first, was dropped). The best free spot is taken: a
    // bed before a cot before the floor ("I'd prefer the cot over the rug.
    // But if 3 people wanna sleep, then one's going on the ground"), at
    // random among spots of the same comfort; a spot of a double bed
    // another clan is using is passed over (BuddyClaimBed refuses it).
    // Within a comfort tier, a spot of a wholly empty double bed comes
    // before a single spot (the owner, 2026-09-27: "maybe one of their
    // clanmates will join them"); comfort still comes first.
    bool ChooseSleep(TownState& s, uint32 areaId, uint64 now)
    {
        std::vector<BuddyBed> beds = BuddyBedsInArea(bot->GetMapId(), areaId);
        if (beds.empty())
            return false;
        Acore::Containers::RandomShuffle(beds);
        std::unordered_map<uint32, bool> emptyDouble;  // judged once per spot, before sorting
        for (BuddyBed const& bed : beds)
            emptyDouble[bed.id] = BuddyBedIsEmptyDouble(bed);
        std::stable_sort(beds.begin(), beds.end(), [&emptyDouble](BuddyBed const& a, BuddyBed const& b)
        {
            if (a.tier != b.tier)
                return a.tier > b.tier;                // comfort first
            return emptyDouble[a.id] && !emptyDouble[b.id];   // then an empty double bed before a single spot
        });
        Player* owner = botAI->GetMaster();
        uint32 clan = owner ? owner->GetGUID().GetCounter() : 0;
        uint32 hold = WALK_GIVE_UP_MS + SLEEP_MAX_MS + 60000;
        for (BuddyBed const& bed : beds)
        {
            if (!BuddyClaimBed(bed.id, bot->GetGUID().GetCounter(), clan, hold))
                continue;                              // another buddy's, or another clan's double bed
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

    // Fishing, where the town has water: the nearest water from here within
    // the leisure reach that lies inside the town's own borders (same named
    // area), a shore spot from which it is in casting reach, a pole to cast
    // with and the fishing skill. The bot module's own fishing helpers find
    // the water and the shore (FishingAction.cpp).
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
            return false;                              // water, but outside the town's borders
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
    // }}}

    // {{{ RunVisit
    // Stand before the townsperson, facing it, playing talking animations
    // (never a line of chat), for VISIT_MIN..MAX.
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
    // }}}

    // {{{ RunSit
    // Walk to the chair, sit (the server seats a player on the chair's
    // nearest free place), and stay: eating, laughing and talking animations.
    // The shared timer: sitting down sets the end for every buddy seated
    // within SEAT_GROUP_YARDS to the newcomer's ("they'll both leave when the
    // latest-to-join's timer expires [...] a third might join, and it resets
    // the timer for all of them").
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
                Finish(s, now);                        // every seat taken: another pastime
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
            Finish(s, now);                            // stood up by something else (the bot module, a spell)
            return false;
        }
        static uint32 const seated[] = { EMOTE_ONESHOT_TALK, EMOTE_ONESHOT_EAT, EMOTE_ONESHOT_EAT_NO_SHEATHE,
                                         EMOTE_ONESHOT_LAUGH, EMOTE_ONESHOT_TALK_NO_SHEATHE };
        Emote(s, now, seated[urand(0, 4)]);
        return true;
    }

    // Every buddy seated (a chair, there) on this map within SEAT_GROUP_YARDS
    // of the newcomer ends when the newcomer does. The table is read and
    // written under its lock; the newcomer's own entry is written by its
    // caller.
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
    // }}}

    // {{{ RunSleep
    // Walk to the claimed bed's recorded spot, face the recorded way, lie
    // down, for SLEEP_MIN..MAX.
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
            Finish(s, now);                            // woken by something else
            return false;
        }
        return true;
    }
    // }}}

    // {{{ RunFish
    // Walk to the shore spot; take the pole in hand (what it held is kept to
    // be put back); then cast, wait for a bite and pull in, castsLeft times.
    // A bite is the bobber turning ready (the bot module's own sign); using
    // it loots the catch, which the bot module stores in the bags. A cast
    // that ends without a bite counts too. Ends when the casts are done, or
    // after FISH_GIVE_UP_MS whatever the count.
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
                Finish(s, now);                        // the pole is gone
                return false;
            }
            s.there = true;
        }

        // a bite: pull it in
        if (GameObject* bobber = OwnBobber())
        {
            if (bobber->getLootState() == GO_READY)
                bobber->Use(bot);
            return true;
        }

        bool channelling = bot->GetCurrentSpell(CURRENT_CHANNELED_SPELL) != nullptr;
        if (s.casting && !channelling)
        {
            s.casting = false;                         // that cast is over, caught or not
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

        // face the water, then cast
        WorldPosition water = FindWaterRadial(bot, bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ(),
            bot->GetMap(), bot->GetPhaseMask(), FISH_WATER_MIN, FISH_WATER_MAX, 2.5f, true, 32);
        if (!water.IsValid())
        {
            Finish(s, now);                            // the shore spot doesn't reach water after all
            return false;
        }
        bot->SetFacingTo(bot->GetAngle(water.GetPositionX(), water.GetPositionY()));
        if (botAI->CastSpell(FISHING_SPELL, bot))
            s.casting = true;
        else if (s.castsLeft)
            --s.castsLeft;                             // refused (a moment's cooldown, a busy hand): counts, so it can't loop
        return true;
    }

    // The buddy's fishing pole, in its bags or already in hand; null without.
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

    // Pole into the main hand (a two-hander, so the off hand empties too),
    // remembering what was held.
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

    // What was held before the pole goes back, if it is still in the
    // backpack or a bag. Not "IsInBag": the server means a bag only, not
    // the backpack, so until 2026-10-15 a weapon that landed in the
    // backpack was never put back (Mozonn's hammer, its pole in hand).
    // Nothing remembered (its hands were empty in town, 617e4b): the pole
    // stays until the weapons pass puts it in the bags.
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

    // Equip as the client asks to (the same request the bot module's own
    // pole-equipping sends), so every rule the server has for it applies.
    void EquipInSlot(Item* item, uint8 slot)
    {
        WorldPacket packet(CMSG_AUTOEQUIP_ITEM_SLOT, 9);
        packet << item->GetGUID() << slot;
        WorldPackets::Item::AutoEquipItemSlot request(std::move(packet));
        request.Read();
        bot->GetSession()->HandleAutoEquipItemSlotOpcode(request);
    }

    // The buddy's own bobber, if one is out.
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
    // }}}
};
// }}}

// {{{ the triggers and strategies
// Always due: whether a step is worth taking now is each action's own
// judgement (isUseful), which the bot module asks before running it.
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
// }}}

// {{{ the makers
Strategy* NewBuddyTravelStrategy(PlayerbotAI* ai)   { return new BuddyTravelStrategy(ai); }
Trigger*  NewBuddyTravelDueTrigger(PlayerbotAI* ai) { return new BuddyTravelDueTrigger(ai); }
Action*   NewBuddyTravelStepAction(PlayerbotAI* ai) { return new BuddyTravelStepAction(ai); }
Strategy* NewBuddyTownStrategy(PlayerbotAI* ai)     { return new BuddyTownStrategy(ai); }
Trigger*  NewBuddyTownDueTrigger(PlayerbotAI* ai)   { return new BuddyTownDueTrigger(ai); }
Action*   NewBuddyTownStepAction(PlayerbotAI* ai)   { return new BuddyTownStepAction(ai); }
// }}}
