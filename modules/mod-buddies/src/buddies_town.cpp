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
 * buddy stuck on a long walk moved to a random spot within 30 yards, "like
 * the unstuck command", instead of to its destination; training paid from
 * the buddy's own money ("make them earn it": no gold cheat is given).
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
#include "buddies_explore.h"
#include "buddies_spells.h"
#include "buddies_steer.h"
#include "MoveSpline.h"
#include "buddies_roam.h"
#include "buddies_gems.h"
#include "buddies_town.h"
#include "buddies_beds.h"
#include "buddies_crossing.h"
#include "Bag.h"
#include "Containers.h"
#include "FishingAction.h"
#include "Spell.h"
#include "SpellMgr.h"
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
static constexpr uint32 STUCK_MS            = 90000;   // no progress on a long walk for this long: unstuck
static constexpr float  PROGRESS_YARDS      = 10.0f;   // what counts as progress toward the owner
static constexpr float  UNSTUCK_YARDS       = 30.0f;   // "a random spot within 30 yards"
static constexpr uint32 UNSTUCK_TRIES       = 12;      // random spots tried for walkable ground
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
enum class Errand : uint8 { Train, Sell, Repair, Mail, Auction };   // Mail: at a mailbox, not an NPC
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
    std::vector<ErrandStop> todo;                // the errands still to run, in order
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
};

// Each buddy's long walk toward its owner's area: the nearest it has come
// and when, for the stuck rule.
struct TravelProgress
{
    uint32 toArea  = 0;
    float  nearest = 0.0f;
    uint64 since   = 0;
};
static std::unordered_map<uint32, TravelProgress> sTravel;   // under sTownLock
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
        if (CantSpare(ai, item) || proto->Class == ITEM_CLASS_CONSUMABLE)
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

// {{{ MailToOwner
// Bind-on-equip epics it has no use for go to its owner (never sold).
static void MailToOwner(PlayerbotAI* ai, Player* bot)
{
    std::vector<Item*> items = ItemsForOwner(ai, bot);
    if (items.empty())
        return;
    QueryResult row = CharacterDatabase.Query("SELECT owner FROM buddy_roster WHERE buddy = {}", bot->GetGUID().GetCounter());
    if (!row)
        return;
    ObjectGuid owner = ObjectGuid::Create<HighGuid::Player>((*row)[0].Get<uint32>());
    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    MailDraft draft("For the clan", "Found this and thought of you.");
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
// Getting unstuck (owner, 2026-09-27): "should teleport them to a random
// spot within 30 yards, like the unstuck command." The bot module's long
// walk (MoveFarTo) has its own recovery: after 90 seconds without real
// progress it puts the bot at the destination. That is switched off here
// by resetting its stuck clock before every step (the clock lives in the
// bot's public "rpg" state), and this action keeps its own: no 10-yard gain
// toward the owner in 90 seconds (the owner, 2026-09-27: "let's make it
// 10"; it was 5), and the buddy is moved to a random
// walkable spot within 30 yards of where it stands, then walks on.
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
        // in the same town (a building inside it included) is not "elsewhere"
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
            return MoveFarTo(WorldPosition(move.mapId, move.x, move.y, move.z));
        }
        BuddyCrossingForget(bot);                      // on the owner's map again: any crossing is over

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
        if (stuck && Unstick())
            return true;

        // keep the bot module's own teleport-to-destination from firing
        botAI->rpgInfo.stuckTs = getMSTime();
        botAI->rpgInfo.stuckAttempts = 0;
        return MoveFarTo(WorldPosition(owner->GetMapId(), owner->GetPositionX(), owner->GetPositionY(), owner->GetPositionZ()));
    }

private:
    // A random walkable spot within UNSTUCK_YARDS: ground found near the
    // buddy's height, not under water, within sight of where it stands (so
    // it isn't put through a wall into a closed room). Returns false, logged,
    // when none of the tries fits; the walk then simply goes on.
    bool Unstick()
    {
        Map* map = bot->GetMap();
        float bx = bot->GetPositionX(), by = bot->GetPositionY(), bz = bot->GetPositionZ();
        for (uint32 attempt = 0; attempt < UNSTUCK_TRIES; ++attempt)
        {
            float angle = frand(0.0f, 2.0f * float(M_PI));
            float d     = frand(5.0f, UNSTUCK_YARDS);
            float x = bx + std::cos(angle) * d;
            float y = by + std::sin(angle) * d;
            float z = map->GetHeight(bot->GetPhaseMask(), x, y, bz + 10.0f, true, 30.0f);
            if (z <= INVALID_HEIGHT || std::fabs(z - bz) > 15.0f)
                continue;                              // no ground there, or another floor
            if (map->IsInWater(bot->GetPhaseMask(), x, y, z, bot->GetCollisionHeight()))
                continue;                              // not into a lake
            if (!bot->IsWithinLOS(x, y, z + 1.0f))
                continue;                              // not through a wall
            LOG_INFO("module", "mod-buddies: buddy {} made no progress toward its owner for {} s; moved {:.0f} yards to walk on",
                bot->GetName(), STUCK_MS / 1000, d);
            bot->NearTeleportTo(x, y, z + 0.5f, angle);
            return true;
        }
        LOG_WARN("module", "mod-buddies: buddy {} is stuck but none of {} spots within {:.0f} yards was walkable; it keeps trying",
            bot->GetName(), UNSTUCK_TRIES, UNSTUCK_YARDS);
        return false;
    }
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

        if (s.doing == Doing::Nothing)
        {
            if (now < s.idleUntil)
            {
                StoreTown(guid, s);
                return false;                              // a pause between pastimes: stand about
            }
            if (!s.todo.empty())
                Begin(s, Doing::Errand, s.todo.front().npc, now);
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

    // {{{ RunErrand
    // Walk to the errand's NPC, face it, a talking animation, the errand.
    bool RunErrand(TownState& s, uint64 now)
    {
        ErrandStop stop = s.todo.front();
        if (stop.kind == Errand::Mail)
        {
            // a mailbox is an object, not a person: walk to it, open it
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

    // What was held before the pole goes back, if it is still in the bags.
    void PutPoleAway(TownState& s)
    {
        if (!s.mainHand.IsEmpty())
            if (Item* item = bot->GetItemByGuid(s.mainHand); item && item->IsInBag())
                EquipInSlot(item, EQUIPMENT_SLOT_MAINHAND);
        if (!s.offHand.IsEmpty())
            if (Item* item = bot->GetItemByGuid(s.offHand); item && item->IsInBag())
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
