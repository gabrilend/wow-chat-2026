/*
 * buddies_roam_strategy.cpp - buddies roam their owner's area instead of
 * following (issue 617e1).
 *
 * For a general audience: a buddy is a bot the bot module ("playerbots")
 * drives. Out of the box such a bot follows its player a yard and a half
 * behind. The owner wants buddies to roam the named area the player is in
 * on their own, fighting what they meet, looting and gathering on the way
 * (617e). The bot module picks, many times a second, the most pressing of
 * the behaviours ("strategies") it has been given; this file adds one of
 * our own, "buddy roam", whose single action walks the buddy along the
 * waypoints the roaming core (roam/buddy_roam_core.h) picks. It is ranked
 * below fighting and looting, so a fight or a corpse always comes first
 * and the roaming picks up where it left off.
 *
 * The owner's rules of 2026-09-27 for buddies (617e1):
 *   no grind       - "100 yards is a long ways": the bot module's grind
 *                    charges anything worth experience within its whole
 *                    sight (100 yards); buddies go without it, and fight
 *                    what the monster nudge brings them near, what attacks
 *                    them, and (617e5) what their clanmates fight;
 *   real food      - "they need real food": the bot module's own eating
 *                    (the "food" behaviour, which uses a cheat: regeneration
 *                    from nothing) is off for buddies; they eat only in the
 *                    meal below, from what they carry;
 *   walking        - run in the open, walk indoors (2026-09-29, replacing
 *                    "If they can't mount, then they shouldn't be running"):
 *                    a roaming buddy runs outdoors and walks where the
 *                    map marks it indoors (a cave, a building); a mounted
 *                    one always runs; a fight puts it back to running at
 *                    once. Not in dungeons,
 *                    raids or battlegrounds, where roaming doesn't run.
 *
 * Three parts:
 *   the behaviour  - the strategy, its trigger and its action, taught to
 *                    the bot module at the server's start (below: why then);
 *   the action     - keeps each buddy's roaming state, starts it on the
 *                    owner's area, asks the core for the next waypoint when
 *                    the last is reached, and walks the planned path in
 *                    short legs with the bot module's own walking (which
 *                    finds its way on the server's navigation mesh);
 *   the pass       - every few seconds, puts each online buddy's peace-time
 *                    behaviours right: the bot module resets them at login,
 *                    on joining a group, on coming back to life and on a few
 *                    other events, so a set made once does not last.
 *
 * Two things the action hands the core or does itself (2026-09-27):
 *   the monsters   - the ones near the buddy that would attack it on sight,
 *                    with their aggro radius against it, so the core can
 *                    bend a trip through a radius and be noticed (617e3);
 *   the meal       - on the rest roll at a waypoint the buddy eats (and
 *                    drinks, if it uses mana): with food that gives Well Fed
 *                    it waits for the buff, otherwise until health (and
 *                    mana) are full; a fight ends the meal. Only what it
 *                    carries: with nothing to eat it lights a campfire
 *                    (if it can), sits, and waits for health (and mana)
 *                    to come back by ordinary regeneration (logged once
 *                    per buddy); the starting kit and cooking (617a4,
 *                    617k) are where food comes from.
 */

#include "buddies.h"
#include "buddies_roam.h"
#include "buddies_town.h"
#include "buddies_explore.h"
#include "Bag.h"
#include "CellImpl.h"
#include "Creature.h"
#include "GameTime.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Item.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "Log.h"
#include "Map.h"
#include "MovementActions.h"
#include "NonCombatStrategy.h"
#include "Player.h"
#include "Playerbots.h"
#include "PlayerbotAI.h"
#include "PlayerbotMgr.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Trigger.h"
#include "WorldSession.h"
#include "DKAiObjectContext.h"
#include "DruidAiObjectContext.h"
#include "HunterAiObjectContext.h"
#include "MageAiObjectContext.h"
#include "PaladinAiObjectContext.h"
#include "PriestAiObjectContext.h"
#include "RogueAiObjectContext.h"
#include "ShamanAiObjectContext.h"
#include "WarlockAiObjectContext.h"
#include "WarriorAiObjectContext.h"
#include <cmath>
#include <cstring>
#include <list>
#include <mutex>
#include <set>
#include <unordered_map>

// {{{ tuning
static constexpr float  ROAM_RELEVANCE    = 3.0f;    // below attacking (4.0) and loot's actions (5 to 8)
static constexpr float  LEG_YARDS         = 8.0f;    // how far along the planned path each walking order reaches
static constexpr float  REACHED_YARDS     = 2.0f;    // a path point this near counts as reached
static constexpr uint32 RETRY_MS          = 10000;   // after a failed pick or centre lookup, wait this long
static constexpr float  OTHERS_YARDS      = 100.0f;  // players this near a buddy count for the crowding rule
static constexpr float  MIN_BODY_YARDS    = 0.5f;    // no body is tested more finely than this
static constexpr uint32 PASS_EVERY_MS     = 3000;    // the strategy pass
static constexpr float  MOBS_YARDS        = 60.0f;   // monsters this near a buddy are offered to the nudge
static constexpr uint32 MEAL_MAX_MS       = 120000;  // a meal that hasn't finished by now is ended (and logged)
static constexpr uint32 CAMPFIRE_SPELL    = 818;     // Basic Campfire: taught with Cooking (every buddy has it,
                                                     // 617k); in this version it needs no wood, flint or tinder
                                                     // (no reagents or tools in the spell data), and places a
                                                     // campfire object for a few minutes
// }}}

// {{{ each buddy's roaming state
// Kept per buddy (character guid, low part). The bot module runs each bot
// from its map's update thread and maps may update in parallel, so the
// table is locked; a buddy's own entry is copied out, worked on and written
// back, so the slow part (planning a path, which probes the ground a few
// hundred times) runs outside the lock.
struct RoamState
{
    BuddyRoam::Buddy buddy;
    BuddyRoam::Area  area;
    uint32           mapId      = 0;
    bool             begun      = false;
    bool             noCentre   = false;    // the area has no centre (indoors only): explored by rooms, never the pinwheel
    bool             justArrived = false;   // the last path point was reached; roll for a rest
    uint64           retryAt    = 0;        // game-time ms; after a failure, no roaming before this
    bool             meal       = false;    // eating (and drinking) at a waypoint
    bool             sitRest    = false;    // this rest has no food: sitting it out by a campfire
    uint64           mealStarted = 0;       // game-time ms
    uint32           wellFed    = 0;        // the Well Fed spell the food it ate gives, 0 when none
};
static std::mutex sRoamLock;
static std::unordered_map<uint32, RoamState> sRoam;

static RoamState LoadState(uint32 guid)
{
    std::lock_guard<std::mutex> lock(sRoamLock);
    return sRoam[guid];
}
static void StoreState(uint32 guid, RoamState const& state)
{
    std::lock_guard<std::mutex> lock(sRoamLock);
    sRoam[guid] = state;
}

// Buddies already reported as having nothing to eat, so the log line comes
// once per buddy per server run, not at every waypoint.
static std::mutex sNoFoodLock;
static std::set<uint32> sNoFoodLogged;
// }}}

// {{{ the meal's helpers
// Food and drink are consumables of the "food" kind whose use spell puts a
// regeneration aura on the eater: health regeneration (aura type
// SPELL_AURA_MOD_REGEN) for food, mana (SPELL_AURA_MOD_POWER_REGEN) for
// drink. The best usable one the buddy carries (highest item level) is
// eaten. Returns null when it carries none.
static Item* BestMealItem(Player* bot, AuraType regen)
{
    Item* best = nullptr;
    auto consider = [&](Item* item)
    {
        if (!item)
            return;
        ItemTemplate const* proto = item->GetTemplate();
        if (proto->Class != ITEM_CLASS_CONSUMABLE || proto->SubClass != ITEM_SUBCLASS_FOOD)
            return;
        SpellInfo const* spell = sSpellMgr->GetSpellInfo(uint32(proto->Spells[0].SpellId));
        if (!spell || !spell->HasAura(regen))
            return;
        if (bot->CanUseItem(item) != EQUIP_ERR_OK)
            return;                                    // too high a level, or a skill the buddy lacks
        if (!best || proto->ItemLevel > best->GetTemplate()->ItemLevel)
            best = item;
    };
    for (uint8 slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
        consider(bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot));
    for (uint8 bagSlot = INVENTORY_SLOT_BAG_START; bagSlot < INVENTORY_SLOT_BAG_END; ++bagSlot)
        if (Bag* bag = bot->GetBagByPos(bagSlot))
            for (uint32 j = 0; j < bag->GetBagSize(); ++j)
                consider(bag->GetItemByPos(uint8(j)));
    return best;
}

// The Well Fed spell a food gives, 0 when none. In the game's data a food
// that feeds you up has a second effect, a periodic trigger that fires the
// "Well Fed" spell after some seconds of eating (e.g. Spiced Wolf Meat's
// food spell 5004 triggers 19705 "Well Fed"; plain Tough Jerky, 433, has
// only the regeneration). Recognised by the triggered spell's name.
static uint32 WellFedOf(Item* food)
{
    SpellInfo const* spell = sSpellMgr->GetSpellInfo(uint32(food->GetTemplate()->Spells[0].SpellId));
    if (!spell)
        return 0;
    for (SpellEffectInfo const& effect : spell->GetEffects())
        if (effect.TriggerSpell)
            if (SpellInfo const* triggered = sSpellMgr->GetSpellInfo(effect.TriggerSpell))
                if (triggered->SpellName[0] && std::strstr(triggered->SpellName[0], "Well Fed"))
                    return effect.TriggerSpell;
    return 0;
}
// }}}

// {{{ BodyWidth
// Twice the character's bounding radius: a tauren tests the ground about
// three times as coarsely as a human ("Tauren have larger hitboxes, gnomes
// have smaller, so they'll pathfind around obstacles in differing
// increments", the owner, 2026-09-27). The radius field already follows the
// character's scale (basic scales models by level).
static float BodyWidth(Player* bot)
{
    float width = 2.0f * bot->GetFloatValue(UNIT_FIELD_BOUNDINGRADIUS);
    return width < MIN_BODY_YARDS ? MIN_BODY_YARDS : width;
}
// }}}

// {{{ BuddyRoamStepAction
// Walks the buddy one leg along its roaming path, picking the next waypoint
// when the last is reached.
class BuddyRoamStepAction : public MovementAction
{
public:
    BuddyRoamStepAction(PlayerbotAI* botAI) : MovementAction(botAI, "buddy roam step") { }

    // Roaming makes sense only for a living buddy out of combat, whose owner
    // is online on the same map, outside dungeons and battlegrounds, and not
    // in a town (the town visit takes over there, buddies_town.cpp), in
    // the owner's own area, and not while waiting after a failure (a meal
    // under way is tended by Execute itself).
    bool isUseful() override
    {
        Player* owner = botAI->GetMaster();
        // A fight ends a meal ("wait until they get it or are interrupted"):
        // being hit breaks the eating aura anyway; roaming picks up after.
        if (bot->IsInCombat())
        {
            RoamState s = LoadState(bot->GetGUID().GetCounter());
            if (s.meal)
            {
                s.meal = false;
                s.sitRest = false;
                StoreState(bot->GetGUID().GetCounter(), s);
            }
            return false;
        }
        if (!bot->IsAlive() || !owner || !owner->IsInWorld())
            return false;
        if (owner->GetMapId() != bot->GetMapId() || bot->GetMap()->Instanceable())
            return false;
        if (BuddyTownArea(owner))                      // in a town, a building in one included
            return false;
        // In another named area than the owner's: "buddy travel" walks it
        // there first (buddies_town.cpp, 617e4); roaming the owner's area
        // from outside it would aim at a centre it may not even see.
        if (bot->GetAreaId() != owner->GetAreaId())
            return false;
        uint64 now = uint64(GameTime::GetGameTimeMS().count());
        RoamState s = LoadState(bot->GetGUID().GetCounter());
        return now >= s.retryAt;
    }

    bool Execute(Event /*event*/) override
    {
        Player* owner = botAI->GetMaster();
        if (!owner)
            return false;
        uint32 guid   = bot->GetGUID().GetCounter();
        uint32 areaId = owner->GetAreaId();
        Map*   map    = bot->GetMap();
        uint64 now    = uint64(GameTime::GetGameTimeMS().count());
        RoamState s   = LoadState(guid);
        BuddyRoam::Rng rng = [] { return rand_norm(); };
        BuddyRoam::Point at { bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ() };

        // A new area (or the first step): find its centre and start the
        // pinwheel from where the buddy stands. The centre is looked up in
        // the install-time table of area middles (buddy_area_centre, E044),
        // the piece of the area the owner stands in.
        if (!s.begun || s.area.id != areaId || s.mapId != map->GetId())
        {
            // An area with no centre in the table exists only inside a
            // building or cave (the table is read from the outdoor terrain):
            // the pinwheel can't circle it, so it is explored by rooms
            // (owner, 2026-09-29: "let's say the rooms mode").
            BuddyRoam::Area area;
            bool noCentre = !BuddyAreaCentre(map, owner->GetPhaseMask(), areaId,
                                             owner->GetPositionX(), owner->GetPositionY(), owner->GetPositionZ(), area);
            if (noCentre)
            {
                area.id     = areaId;
                area.centre = { owner->GetPositionX(), owner->GetPositionY(), owner->GetPositionZ() };   // not circled
            }
            s = RoamState();
            s.area     = area;
            s.mapId    = map->GetId();
            s.begun    = true;
            s.noCentre = noCentre;
            BuddyRoam::Begin(s.buddy, area, at, rng);
            s.buddy.body = BodyWidth(bot);
        }

        // A meal under way: keep at it until it is done (TendMeal decides).
        if (s.meal)
        {
            TendMeal(s, now);
            StoreState(guid, s);
            return true;
        }

        // At the end of a path: first the rest roll (the owner: "a chance to
        // sit down and eat food or regenerate health every time they reach a
        // waypoint", half the share of health missing). A rest is a meal
        // (StartMeal); the next walking order stands the buddy up again (the
        // bot module's walking does that).
        if (!s.buddy.hasWaypoint || s.buddy.pathIndex >= s.buddy.path.size())
        {
            if (s.justArrived)
            {
                s.justArrived = false;
                if (rand_norm() < BuddyRoam::RestChance(float(bot->GetHealth()), float(bot->GetMaxHealth())))
                {
                    StartMeal(s, now);
                    StoreState(guid, s);
                    return true;
                }
            }
            // The owner's chosen way of exploring (617e6, ".buddy explore"):
            // least paint, the room orbit or the squished circle choose over
            // the area's measured grid (buddies_explore.cpp); the pinwheel
            // (and those three while the grid is still being measured,
            // logged once) is the roaming core below.
            //
            // Indoors (a building or cave, as the map marks it), and in an
            // area with no centre, the pinwheel can't work: it circles the
            // area's middle and needs a clear line to it, which walls
            // break. There the rooms mode is used whatever the owner chose
            // (it measures the floor cell by cell, rooms and tunnels
            // included). Outdoors, when the pinwheel finds no waypoint
            // (standing against a building, on a ledge), rooms is tried
            // before giving up.
            std::vector<BuddyRoam::Point> explored;
            bool indoors = s.noCentre || !bot->IsOutdoors();
            bool found   = BuddyExploreNext(bot, owner, areaId, explored,
                                            indoors ? BUDDY_EXPLORE_ROOMS : BUDDY_EXPLORE_PINWHEEL);
            if (!found && indoors)
            {
                // the rooms grid is still being measured (logged once by
                // the explorer): wait for it rather than circle a middle
                // that can't be reached
                s.retryAt = now + RETRY_MS;
                StoreState(guid, s);
                return false;
            }
            if (!found)
            {
                BuddyRoam::Settings settings;
                BuddyRoam::Ground ground = BuddyRoamGround(map, owner->GetPhaseMask(), areaId, settings);
                std::vector<BuddyRoam::Point> others = OthersNear(map);
                std::vector<BuddyRoam::Mob> mobs = MobsNear();
                if (!BuddyRoam::NextWaypoint(s.buddy, s.area, at, others, mobs, ground, settings, rng))
                {
                    // the pinwheel found nothing from here: rooms, once
                    found = BuddyExploreNext(bot, owner, areaId, explored, BUDDY_EXPLORE_ROOMS);
                    if (!found)
                    {
                        LOG_ERROR("module", "mod-buddies: buddy {} found no waypoint in area {} on map {} from ({:.1f}, {:.1f}, {:.1f}) "
                            "(the pinwheel: no clear spot in a full circle of bearings, no sight of the centre, or no path; "
                            "rooms: grid not measured yet, or no way over it); roaming paused {} s",
                            bot->GetName(), areaId, map->GetId(), at.x, at.y, at.z, RETRY_MS / 1000);
                        s.retryAt = now + RETRY_MS;
                        StoreState(guid, s);
                        return false;
                    }
                }
            }
            if (found)
            {
                s.buddy.path        = explored;
                s.buddy.pathIndex   = 0;
                s.buddy.waypoint    = explored.back();
                s.buddy.hasWaypoint = true;
            }
        }

        // Walk: points already within reach are passed; the order goes to
        // the farthest point within a leg's length along the path, so the
        // bot module's walking plans each leg on the navigation mesh while
        // the core's plan decides the line (round steps, onto gentle
        // ground). The last point is the waypoint.
        auto& path = s.buddy.path;
        while (s.buddy.pathIndex < path.size() &&
               bot->GetExactDist2d(path[s.buddy.pathIndex].x, path[s.buddy.pathIndex].y) <= REACHED_YARDS)
            ++s.buddy.pathIndex;
        if (s.buddy.pathIndex >= path.size())
        {
            s.buddy.hasWaypoint = false;
            s.justArrived = true;
            StoreState(guid, s);
            return true;
        }
        size_t target = s.buddy.pathIndex;
        float  along  = bot->GetExactDist2d(path[target].x, path[target].y);
        while (target + 1 < path.size())
        {
            float step = std::hypot(path[target + 1].x - path[target].x, path[target + 1].y - path[target].y);
            if (along + step > LEG_YARDS)
                break;
            along += step;
            ++target;
        }
        StoreState(guid, s);
        BuddyRoam::Point const& p = path[target];
        // Run in the open, walk indoors (the owner, 2026-09-29: "When we're
        // in a questing area we don't have to rp walk, that's only for
        // inside towns and dungeons and interior areas"; this replaces
        // 2026-09-27's "If they can't mount, then they shouldn't be
        // running"). Towns walk in the town visit (buddies_town.cpp) and
        // roaming doesn't run in dungeons, so here only "indoors" is left:
        // a cave or a building out in the country, as the server's map
        // data marks it. A mounted buddy never walks. The walk flag stays
        // on the buddy, so the moment a fight begins it is set back to
        // running (OnPlayerEnterCombat below).
        bool walk = !bot->IsMounted() && !bot->IsOutdoors();
        if (bot->IsWalking() != walk)
            bot->SetWalk(walk);
        // The wander priority: any other walking the bot module wants (to a
        // fight, a corpse) is not held up waiting for this one.
        bool ordered = MoveTo(map->GetId(), p.x, p.y, p.z, false, false, false, false, MovementPriority::MOVEMENT_WANDER);
        return ordered || bot->isMoving();
    }

private:
    // {{{ MobsNear
    // The monsters near the buddy that would notice and attack it, for the
    // core's nudge (a trip bent through an aggro radius, 617e3). Each filter
    // and what passing it means:
    //   a creature, not a player    - other buddies and players aren't prey
    //   nobody's pet or guardian    - a player's pet never attacks on sight
    //   not a critter, not civilian,
    //   not immune to players       - these never start a fight
    //   not already fighting        - it is busy and won't turn to the buddy
    //   not someone else's kill     - tapped by another player: no loot, no
    //                                 experience for the buddy
    //   hostile to the buddy and
    //   aggressive                  - only such a creature attacks on sight;
    //                                 a neutral or passive one would need the
    //                                 buddy to strike first (buddies have no
    //                                 grind since 2026-09-27; 617e5 may add
    //                                 picking such fights)
    //   worth experience            - not grey to the buddy
    // The radius is the server's own for this pair (Creature::GetAggroRange:
    // 20 yards, less a yard for each level the buddy is above it, 5 to 45).
    std::vector<BuddyRoam::Mob> MobsNear()
    {
        std::list<Unit*> units;
        Acore::AnyUnitInObjectRangeCheck check(bot, MOBS_YARDS);
        Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> searcher(bot, units, check);
        Cell::VisitObjects(bot, searcher, MOBS_YARDS);
        std::vector<BuddyRoam::Mob> mobs;
        for (Unit* u : units)
        {
            Creature* c = u->ToCreature();
            if (!c || !c->GetCharmerOrOwnerGUID().IsEmpty())
                continue;
            if (c->IsCritter() || c->IsCivilian() || c->IsImmuneToPC() || c->IsInCombat())
                continue;
            if (c->hasLootRecipient() && !c->isTappedBy(bot))
                continue;
            if (!c->IsHostileTo(bot) || !c->HasReactState(REACT_AGGRESSIVE) || !bot->isHonorOrXPTarget(c))
                continue;
            float aggro = c->GetAggroRange(bot);
            if (aggro <= 0.0f)
                continue;                              // the server has aggro switched off (rate 0)
            mobs.push_back({ { c->GetPositionX(), c->GetPositionY(), c->GetPositionZ() }, aggro });
        }
        return mobs;
    }
    // }}}

    // {{{ the meal
    // Eat or drink one serving: the best item the buddy carries, used as a
    // player would (so food that gives Well Fed does). Never the bot
    // module's food cheat (the owner: "they need real food"). Returns
    // whether a serving began.
    bool Serve(RoamState& s, AuraType regen)
    {
        Item* item = BestMealItem(bot, regen);
        if (!item)
            return false;
        if (regen == SPELL_AURA_MOD_REGEN)
            s.wellFed = WellFedOf(item);
        SpellCastTargets targets;
        targets.SetUnitTarget(bot);
        bot->CastItemUseSpell(item, targets, 1, 0);
        return true;
    }

    bool UsesMana() { return bot->getPowerType() == POWER_MANA; }
    bool HealthFull() { return bot->GetHealth() >= bot->GetMaxHealth(); }
    bool ManaFull() { return !UsesMana() || bot->GetPower(POWER_MANA) >= bot->GetMaxPower(POWER_MANA); }
    bool Eating() { return bot->HasAuraType(SPELL_AURA_MOD_REGEN); }
    bool Drinking() { return bot->HasAuraType(SPELL_AURA_MOD_POWER_REGEN); }

    // Begin a meal: eat if health is short, drink if mana is short. With
    // nothing to eat or drink the buddy still rests (the owner, 2026-09-27:
    // "they should still sit, ideally starting a fire, and wait until their
    // health regenerates naturally"): it lights a campfire if it can, sits,
    // and waits for health (and mana) to come back by ordinary
    // regeneration. Having no food is logged once per buddy per server run,
    // since food comes from the starting kit and cooking (617a4, 617k).
    void StartMeal(RoamState& s, uint64 now)
    {
        s.wellFed = 0;
        s.sitRest = false;
        bool began = false;
        if (!HealthFull())
            began = Serve(s, SPELL_AURA_MOD_REGEN) || began;
        if (!ManaFull())
            began = Serve(s, SPELL_AURA_MOD_POWER_REGEN) || began;
        if (began)
        {
            s.meal = true;
            s.mealStarted = now;
            return;
        }
        {
            std::lock_guard<std::mutex> lock(sNoFoodLock);
            if (sNoFoodLogged.insert(bot->GetGUID().GetCounter()).second)
                LOG_WARN("module", "mod-buddies: buddy {} rolled a rest (health {}/{}) but carries no food or drink it can use, "
                    "so it sits it out by a campfire instead; buddies get food from the starting kit and cooking (617a4, 617k)",
                    bot->GetName(), bot->GetHealth(), bot->GetMaxHealth());
        }
        // The fire: only if the buddy knows it and the cast is allowed here
        // (the server refuses it indoors, on cooldown, or where objects
        // can't be placed); refused, the buddy just sits.
        if (bot->HasSpell(CAMPFIRE_SPELL))
            bot->CastSpell(bot, CAMPFIRE_SPELL, false);
        bot->SetStandState(UNIT_STAND_STATE_SIT);
        s.meal = true;
        s.sitRest = true;
        s.mealStarted = now;
    }

    // Keep a meal going, or end it. The owner's rule:
    //   food with Well Fed - done when the Well Fed buff is on (and mana is
    //                        full or the buddy isn't drinking); if the eating
    //                        stops first without it, the meal was
    //                        interrupted, and that ends it too
    //   other food         - done when health and (for mana users) mana are
    //                        full; a serving that ran out early is followed by
    //                        another
    // A fight ends a meal in isUseful. A meal with food still going after
    // MEAL_MAX_MS is ended and logged with what was still short (a serving
    // that fails to start, or a pool too big for the food); kept as a guard
    // against a stuck eat, unlike the rest without food, which has no cap.
    // The owner leaving the area ends either (Execute resets the state).
    void TendMeal(RoamState& s, uint64 now)
    {
        // no food: sitting until health and (for mana users) mana are full,
        // with no time cap (the owner, 2026-09-27: "there's no cap on how
        // long to rest. The player moving from the zone is enough to
        // interrupt the rest"). The three ways it ends:
        //   full         - here;
        //   a fight      - isUseful drops the meal;
        //   owner leaves - Execute sees the owner's area differ from the
        //                  roaming state's and starts the state afresh, meal
        //                  and all; the next walking order stands it up.
        if (s.sitRest)
        {
            if (HealthFull() && ManaFull())
                s.meal = s.sitRest = false;
            else if (bot->getStandState() != UNIT_STAND_STATE_SIT)
                bot->SetStandState(UNIT_STAND_STATE_SIT);   // stood by something harmless (a bump): sit again
            return;
        }
        if (s.wellFed)
        {
            if ((bot->HasAura(s.wellFed) && (ManaFull() || !Drinking())) || !Eating())
                s.meal = false;
        }
        else if (HealthFull() && ManaFull())
            s.meal = false;
        else
        {
            bool going = true;
            if (!HealthFull() && !Eating())
                going = Serve(s, SPELL_AURA_MOD_REGEN);
            if (!ManaFull() && !Drinking())
                going = Serve(s, SPELL_AURA_MOD_POWER_REGEN) && going;
            if (!going)
                s.meal = false;                        // ran out of servings: done with what it had
        }
        if (s.meal && now - s.mealStarted > MEAL_MAX_MS)
        {
            LOG_WARN("module", "mod-buddies: buddy {}'s meal ran past {} s and was ended (health {}/{}, mana {}/{}, "
                "waiting for Well Fed spell {}, eating {}, drinking {})", bot->GetName(), MEAL_MAX_MS / 1000,
                bot->GetHealth(), bot->GetMaxHealth(), bot->GetPower(POWER_MANA), bot->GetMaxPower(POWER_MANA),
                s.wellFed, Eating(), Drinking());
            s.meal = false;
        }
    }
    // }}}

    // Where the players near this buddy stand (other buddies are players
    // too), for the crowding rule: "we shouldn't place a waypoint within 5
    // yards of another player or buddybot".
    std::vector<BuddyRoam::Point> OthersNear(Map* map)
    {
        std::vector<BuddyRoam::Point> others;
        for (auto const& ref : map->GetPlayers())
        {
            Player* p = ref.GetSource();
            if (!p || p == bot || !p->IsInWorld() || p->GetDistance(bot) > OTHERS_YARDS)
                continue;
            others.push_back({ p->GetPositionX(), p->GetPositionY(), p->GetPositionZ() });
        }
        return others;
    }
};
// }}}

// {{{ BuddyRoamDueTrigger
// Always due: whether a step is worth taking now is the action's own
// judgement (isUseful), which the bot module asks before running it.
class BuddyRoamDueTrigger : public Trigger
{
public:
    BuddyRoamDueTrigger(PlayerbotAI* botAI) : Trigger(botAI, "buddy roam due") { }
    bool IsActive() override { return true; }
};
// }}}

// {{{ BuddyRoamStrategy
class BuddyRoamStrategy : public NonCombatStrategy
{
public:
    BuddyRoamStrategy(PlayerbotAI* botAI) : NonCombatStrategy(botAI) { }
    std::string const getName() override { return "buddy roam"; }

    // Only our trigger: the peace-time basics (eating, buffing, mounting)
    // come from the default strategies, which stay on alongside.
    void InitTriggers(std::vector<TriggerNode*>& triggers) override
    {
        triggers.push_back(new TriggerNode("buddy roam due", { NextAction("buddy roam step", ROAM_RELEVANCE) }));
    }
};
// }}}

// {{{ the three lists the bot module reads names from
class BuddyStrategyContext : public NamedObjectContext<Strategy>
{
public:
    BuddyStrategyContext()
    {
        creators["buddy roam"]   = [](PlayerbotAI* ai) -> Strategy* { return new BuddyRoamStrategy(ai); };
        creators["buddy travel"] = NewBuddyTravelStrategy;    // buddies_town.cpp (617e4)
        creators["buddy town"]   = NewBuddyTownStrategy;
    }
};
class BuddyActionContext : public NamedObjectContext<Action>
{
public:
    BuddyActionContext()
    {
        creators["buddy roam step"]   = [](PlayerbotAI* ai) -> Action* { return new BuddyRoamStepAction(ai); };
        creators["buddy travel step"] = NewBuddyTravelStepAction;
        creators["buddy town step"]   = NewBuddyTownStepAction;
    }
};
class BuddyTriggerContext : public NamedObjectContext<Trigger>
{
public:
    BuddyTriggerContext()
    {
        creators["buddy roam due"]   = [](PlayerbotAI* ai) -> Trigger* { return new BuddyRoamDueTrigger(ai); };
        creators["buddy travel due"] = NewBuddyTravelDueTrigger;
        creators["buddy town due"]   = NewBuddyTownDueTrigger;
    }
};
// }}}

// {{{ RegisterWithPlayerbots
// Every bot reads its behaviours by name from its class's three shared
// lists (a table per class; each list keeps what it is given and deletes it
// at shutdown, so each class gets its own copies). The bot module builds
// those lists when it loads its configuration, in its "before the world is
// initialised" hook (PlayerbotAIConfig::Initialize calls
// AiObjectContext::BuildAllSharedContexts). Adding ours in the world's
// start hook comes after that (the world's start runs once the world is
// initialised, apps/worldserver/Main.cpp) and before any bot can log in
// (bots log in during world updates, which begin after the start hook).
// If an administrator reloads the bot module's configuration later, it
// adds its own lists again on top; ours stay in the same name tables.
template <class Ctx>
static void TeachClass()
{
    Ctx::sharedStrategyContexts.Add(new BuddyStrategyContext());
    Ctx::sharedActionContexts.Add(new BuddyActionContext());
    Ctx::sharedTriggerContexts.Add(new BuddyTriggerContext());
}
static void RegisterWithPlayerbots()
{
    TeachClass<WarriorAiObjectContext>();
    TeachClass<PaladinAiObjectContext>();
    TeachClass<HunterAiObjectContext>();
    TeachClass<RogueAiObjectContext>();
    TeachClass<PriestAiObjectContext>();
    TeachClass<DKAiObjectContext>();
    TeachClass<ShamanAiObjectContext>();
    TeachClass<MageAiObjectContext>();
    TeachClass<WarlockAiObjectContext>();
    TeachClass<DruidAiObjectContext>();
}
// }}}

// {{{ the peace-time sets
// What a buddy's peace-time behaviours should include, in the open and in
// a town. A table rather than branches: the pass reads the row for where
// the owner is and puts each name right.
//   open country - roam instead of follow; loot, gather (defaults,
//                  re-asserted here because a reset from the saved set
//                  could drop them); travel to the owner's area when not in
//                  it; no grind ("100 yards is a long ways", 2026-09-27)
//   town         - the town visit (errands, then leisure, 617e4) and
//                  travel; no following, no roaming, no grind
// In both, no "food": the bot module's own eating is its food cheat;
// buddies eat real food in the roam action's meal (2026-09-27).
// "buddy travel" is on in both: it acts only while the buddy stands in
// another named area than its owner.
struct Want { char const* name; bool on; };
static std::vector<Want> const sOpenCountry = {
    { "follow", false }, { "buddy roam", true }, { "grind", false }, { "food", false }, { "loot", true }, { "gather", true },
    { "buddy travel", true }, { "buddy town", false },
};
static std::vector<Want> const sTown = {
    { "follow", false }, { "buddy roam", false }, { "grind", false }, { "food", false },
    { "buddy travel", true }, { "buddy town", true },
};
// }}}

class buddies_roam_world : public WorldScript
{
public:
    buddies_roam_world() : WorldScript("buddies_roam_world", { WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_UPDATE }) { }

    void OnStartup() override
    {
        RegisterWithPlayerbots();
        LOG_INFO("module", ">> mod-buddies: \"buddy roam\" taught to the bot module (ten classes)");
    }

    // Each online buddy's peace-time set put right, only where it differs
    // (so a buddy already right costs a few lookups). Buddies in a dungeon,
    // raid or battleground are left to the bot module (the dungeon draw is
    // 617c3); dead buddies too (the bot module's own dead behaviours bring
    // them back, then this pass takes over again).
    void OnUpdate(uint32 diff) override
    {
        _sinceLast += diff;
        if (_sinceLast < PASS_EVERY_MS || !BuddiesEnabled())
            return;
        _sinceLast = 0;
        for (auto const& [buddyGuid, ownerGuid] : BuddyRosterPairs())
        {
            Player* bot = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(buddyGuid));
            if (!bot || !bot->IsInWorld() || !bot->IsAlive() || bot->GetMap()->Instanceable())
                continue;
            PlayerbotAI* ai = GET_PLAYERBOT_AI(bot);
            if (!ai)
                continue;                              // not yet under the bot module (still logging in)
            Player* owner = ai->GetMaster();
            if (!owner || owner->GetGUID().GetCounter() != ownerGuid)
                continue;                              // not driven by its owner (no master yet)
            bool town = BuddyTownArea(owner) != 0;     // a building inside a town counts as the town
            std::vector<Want> const& wants = town ? sTown : sOpenCountry;
            for (Want const& w : wants)
                if (ai->HasStrategy(w.name, BOT_STATE_NON_COMBAT) != w.on)
                    ai->ChangeStrategy(std::string(w.on ? "+" : "-") + w.name, BOT_STATE_NON_COMBAT);
            // Walking and running out of town are set where the moving is
            // ordered: the roam action walks an unmounted buddy, travel
            // runs it, a fight runs it (below).
        }
    }

private:
    uint32 _sinceLast = 0;
};

// {{{ buddies_roam_player
// A buddy that starts a fight runs: the roam action leaves the walk flag on
// an unmounted buddy, and the bot module's chasing and fleeing move at
// whatever pace the flag says.
class buddies_roam_player : public PlayerScript
{
public:
    buddies_roam_player() : PlayerScript("buddies_roam_player", { PLAYERHOOK_ON_PLAYER_ENTER_COMBAT }) { }

    void OnPlayerEnterCombat(Player* player, Unit* /*enemy*/) override
    {
        if (!BuddiesEnabled() || !player->IsWalking())
            return;
        if (BuddyIsCompanionAccount(player->GetSession()->GetAccountId()))
            player->SetWalk(false);
    }
};
// }}}

// {{{ AddSC_buddies_roam_strategy
void AddSC_buddies_roam_strategy()
{
    new buddies_roam_world();
    new buddies_roam_player();
}
// }}}
