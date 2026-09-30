/*
 * buddies_town.cpp - buddies go where their owner goes, and in a town they
 * run their errands and then take their ease (issue 617e4).
 *
 * For a general audience: the owner's words (617e, 2026-09-23 to -27): the
 * buddies "will move to whatever area you're in and explore there. So if you
 * move to town, then they move there as well." In a town they are
 * ungrouped, walk rather than run, first do what the town lets them do
 * (learn at their class trainer, sell junk to a vendor, repair), and then
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
 *                  roaming outside towns, the town visit inside.
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
 */

#include "buddies.h"
#include "buddies_roam.h"
#include "buddies_town.h"
#include "buddies_beds.h"
#include "Bag.h"
#include "Containers.h"
#include "FishingAction.h"
#include "Spell.h"
#include "Timer.h"
#include "CellImpl.h"
#include "Creature.h"
#include "GameObject.h"
#include "GameTime.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Item.h"
#include "ItemPackets.h"
#include "ItemUsageValue.h"
#include "Log.h"
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
// }}}

// {{{ each buddy's town state
// Kept per buddy (character guid, low part), locked because bots run on
// their map's update thread and maps update in parallel. A buddy's entry is
// copied out, worked on and written back; the seat-timer sharing (below)
// reads the others' entries under the same lock.
enum class Errand : uint8 { Train, Sell, Repair };
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

// Buddies on another map than their owner, reported once each: walking
// between continents or into an instance is not this issue's (a later one
// decides boats, zeppelins and the dungeon draw, 617c3).
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

// How full the buddy's bags are, 0..1 (the backpack's 16 slots and every
// bag's). "merchants, with priority equal to how full the buddy's bags
// are (half-full bags: 50% priority)" (617e, 2026-09-23).
static float BagFullness(Player* bot)
{
    uint32 total = INVENTORY_SLOT_ITEM_END - INVENTORY_SLOT_ITEM_START;
    for (uint8 i = INVENTORY_SLOT_BAG_START; i < INVENTORY_SLOT_BAG_END; ++i)
        if (Bag* bag = bot->GetBagByPos(i))
            total += bag->GetBagSize();
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

// What to sell: what the bot module itself would sell to a vendor (its
// "item usage" judgement says vendor: junk, and gear and goods it has no
// use for), and every grey item. Items it would rather auction are kept for
// the auction-house errand (617h).
static std::vector<ObjectGuid> Junk(PlayerbotAI* ai, Player* bot)
{
    std::vector<ObjectGuid> junk;
    for (Item* item : BagItems(bot))
    {
        ItemTemplate const* proto = item->GetTemplate();
        if (!proto->SellPrice)
            continue;                                  // a vendor pays nothing for it (quest items, and the like)
        bool grey = proto->Quality == ITEM_QUALITY_POOR;
        bool surplus = ai->GetAiObjectContext()->GetValue<ItemUsage>("item usage", item->GetEntry())->Get() == ITEM_USAGE_VENDOR;
        if (grey || surplus)
            junk.push_back(item->GetGUID());
    }
    return junk;
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
// with a service (a vendor gnome counts, a stray cat does not).
static bool Townsperson(Creature* c, Player* bot, uint32 areaId)
{
    if (c->IsInCombat() || c->IsHostileTo(bot) || c->IsCritter() || c->IsTotem() || c->IsPet() || c->IsGuardian())
        return false;
    if (!c->GetCharmerOrOwnerGUID().IsEmpty() || c->GetAreaId() != areaId)
        return false;
    return c->GetCreatureType() == CREATURE_TYPE_HUMANOID || c->GetNpcFlags() != UNIT_NPC_FLAG_NONE;
}
// }}}

// {{{ BuildTodo
// The town's errands for this buddy, from what the town's people offer
// ("some towns don't even have repair stations"): its class trainer when it
// has something to learn; a vendor with odds equal to how full its bags are,
// when it carries anything to sell; a repairer when anything is worn. The
// nearest of each. Order (617e, 617h): trainer, vendor, repair.
static std::vector<ErrandStop> BuildTodo(PlayerbotAI* ai, Player* bot, uint32 areaId)
{
    Creature* trainer = nullptr;
    Creature* vendor  = nullptr;
    Creature* repairer = nullptr;
    auto nearer = [&](Creature* best, Creature* c) { return !best || bot->GetDistance(c) < bot->GetDistance(best); };
    for (Unit* u : UnitsNear(bot, TOWN_SCAN_YARDS))
    {
        Creature* c = u->ToCreature();
        if (!c || c->IsHostileTo(bot) || c->GetAreaId() != areaId)
            continue;
        if (ClassLessons(c, bot) && nearer(trainer, c))
            trainer = c;
        if (c->IsVendor() && nearer(vendor, c))
            vendor = c;
        if (c->IsArmorer() && nearer(repairer, c))
            repairer = c;
    }
    std::vector<ErrandStop> todo;
    if (trainer)
        todo.push_back({ Errand::Train, trainer->GetGUID() });
    if (vendor && !Junk(ai, bot).empty() && rand_norm() < BagFullness(bot))
        todo.push_back({ Errand::Sell, vendor->GetGUID() });
    if (repairer && AnythingWorn(bot))
        todo.push_back({ Errand::Repair, repairer->GetGUID() });
    return todo;
}
// }}}

// {{{ the errands themselves
// Each done at the NPC, silently (see the file's header), with the same
// server calls the bot module's own actions make.
//   Train  - every spell the trainer can teach it now, paid as a player
//            pays (the server's Trainer::TeachSpell: checks and money)
//   Sell   - everything Junk() lists, as the client's sell request
//   Repair - everything worn, paid, with the NPC's reputation discount
static void DoTrain(PlayerbotAI* /*ai*/, Player* bot, Creature* npc)
{
    if (Trainer::Trainer* trainer = ClassLessons(npc, bot))
        for (Trainer::Spell const& spell : trainer->GetSpells())
            if (trainer->CanTeachSpell(bot, &spell))
                trainer->TeachSpell(npc, bot, spell.SpellId);
}
static void DoSell(PlayerbotAI* ai, Player* bot, Creature* npc)
{
    for (ObjectGuid itemGuid : Junk(ai, bot))
    {
        Item* item = bot->GetItemByGuid(itemGuid);
        if (!item)
            continue;
        WorldPacket p(CMSG_SELL_ITEM);
        p << npc->GetGUID() << itemGuid << uint32(item->GetCount());
        WorldPackets::Item::SellItem request(std::move(p));
        request.Read();
        bot->GetSession()->HandleSellItemOpcode(request);
    }
}
static void DoRepair(PlayerbotAI* /*ai*/, Player* bot, Creature* npc)
{
    bot->DurabilityRepairAll(true, bot->GetReputationPriceDiscount(npc), false);
}
using ErrandFn = void (*)(PlayerbotAI*, Player*, Creature*);
static std::unordered_map<uint8, ErrandFn> const sErrands = {
    { uint8(Errand::Train),  DoTrain  },
    { uint8(Errand::Sell),   DoSell   },
    { uint8(Errand::Repair), DoRepair },
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
        if (owner->GetMapId() != bot->GetMapId())
        {
            // another continent or an instance: not walked here (logged once)
            std::lock_guard<std::mutex> lock(sOtherMapLock);
            if (sOtherMapLogged.insert(bot->GetGUID().GetCounter()).second)
                LOG_INFO("module", "mod-buddies: buddy {} is on map {} and its owner {} on map {}; walking between maps is "
                    "not built (617e4), so it stays until the owner returns or the bot module moves it",
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
            sOtherMapLogged.erase(bot->GetGUID().GetCounter()); // on the same map again: report anew next time
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
        uint32 town = BuddyTownArea(owner);            // a building inside a town counts as the town
        return town && BuddyTownArea(bot) == town;
    }

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
        Creature* npc = ObjectAccessor::GetCreature(*bot, stop.npc);
        if (!npc || !npc->IsAlive() || TooLong(s, now))
        {
            s.todo.erase(s.todo.begin());              // gone, dead, or out of reach: skipped
            Finish(s, now);
            return false;
        }
        if (bot->GetDistance(npc) > ARRIVED_YARDS)
            return MoveNear(npc, NPC_YARDS);
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
    // Leisure, by the odds above: a townsperson, a chair (sociable ones
    // preferred), a sleep on one of the town's beds, or fishing. A pastime
    // with nothing to use (no chair near, no free bed, no water, no pole)
    // falls to a townsperson; with no townsperson either, it stands about for
    // a pause.
    void ChoosePastime(TownState& s, uint32 areaId, uint64 now)
    {
        uint32 roll = urand(1, WEIGHT_VISIT + WEIGHT_SIT + WEIGHT_SLEEP + WEIGHT_FISH);
        if (roll > WEIGHT_VISIT + WEIGHT_SIT + WEIGHT_SLEEP && ChooseFishing(s, areaId, now))
            return;
        if (roll > WEIGHT_VISIT + WEIGHT_SIT && roll <= WEIGHT_VISIT + WEIGHT_SIT + WEIGHT_SLEEP && ChooseSleep(s, areaId, now))
            return;
        if (roll > WEIGHT_VISIT && roll <= WEIGHT_VISIT + WEIGHT_SIT && ChooseChair(s, areaId, now))
            return;
        std::vector<Creature*> people;
        for (Unit* u : UnitsNear(bot, LEISURE_SCAN_YARDS))
            if (Creature* c = u->ToCreature())
                if (Townsperson(c, bot, areaId))
                    people.push_back(c);
        if (people.empty())
        {
            s.idleUntil = now + urand(GAP_MIN_MS, GAP_MAX_MS);
            return;
        }
        Begin(s, Doing::Visit, people[urand(0, uint32(people.size()) - 1)]->GetGUID(), now);
    }

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
                return MoveNear(npc, NPC_YARDS);
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
