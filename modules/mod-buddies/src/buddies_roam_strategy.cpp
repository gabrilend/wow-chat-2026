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
 *
 * And one thing it does between waypoints (2026-10-02, 617e3):
 *   the detour     - the bot module's loot and gather behaviours only walk
 *                    15 yards to a chest or a herb or ore node, though it
 *                    sees 100. Every couple of seconds the roam action looks
 *                    for one farther than that and within DETOUR_YARDS
 *                    which the buddy could open (skill, skill level, tool,
 *                    key), claims it for its clan so a clanmate doesn't go
 *                    for the same one, and walks to it as a one-off
 *                    waypoint. Once it is within 15 yards the bot module's
 *                    own looting takes over (it outranks roaming); when the
 *                    object is opened or gone the claim is let go and the
 *                    lap carries on from where the buddy stands, its
 *                    pinwheel bearing and Y untouched.
 */

#include "buddies.h"
#include "buddies_roam.h"
#include "buddies_navmesh.h"
#include "buddies_steer.h"
#include "buddies_npcs.h"
#include "MoveSpline.h"
#include "buddies_town.h"
#include "buddies_explore.h"
#include "buddies_nodes.h"
#include "Bag.h"
#include "CellImpl.h"
#include "Creature.h"
#include "GameObject.h"
#include "GameTime.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Item.h"
#include "LootObjectStack.h"
#include "ObjectAccessor.h"
#include "PlayerbotAIConfig.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "Log.h"
#include "Map.h"
#include "PathGenerator.h"
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
#include <algorithm>
#include <cmath>
#include <cstring>
#include <list>
#include <map>
#include <mutex>
#include <set>
#include <unordered_map>

// {{{ tuning
static constexpr float  ROAM_RELEVANCE    = 3.0f;    // below attacking (4.0) and loot's actions (5 to 8)
static constexpr float  LEG_YARDS         = 8.0f;    // how far along the planned path each walking order reaches
static constexpr float  REACHED_YARDS     = 2.0f;    // a path point this near counts as reached
// The mesh's word on every spot (617o1, 2026-10-03: a point on a rock held
// Mozonn still for good; a point the mesh can't route to is walked to in a
// straight line, through walls, by the server's own fallback)
static constexpr float  SNAP_WAYPOINT_YARDS = 6.0f;  // a picked waypoint is moved onto the mesh from at most this far ...
static constexpr float  SNAP_POINT_YARDS  = 3.0f;    // ... and a path point before its leg, from at most this far
static constexpr float  SNAP_RISE_YARDS   = 6.0f;    // up or down, for both
static constexpr uint32 MESH_RETRY_MS     = 2000;    // a waypoint the mesh refused: a new pick after this
static constexpr uint32 STUCK_MS          = 3000;    // a path point with no progress toward it for this long is skipped
static constexpr float  PROGRESS_YARDS    = 0.5f;    // getting this much nearer counts as progress
// The monster approach (617o4, 617e3; the owner, 2026-10-03: "steer the
// buddy-bot to the edge of that circle [...] Then they should start
// casting spells or charging in to fight or stealthing up or whatever the
// class the buddy-bot is does. Once the monster is slain, they continue on
// their circuit.")
static constexpr uint32 PREY_LOOK_MS      = 1000;    // a roaming buddy looks for a monster to approach this often
static constexpr float  EDGE_SLACK_YARDS  = 1.5f;    // within this of the circle's edge counts as arrived
static constexpr float  EDGE_SNAP_YARDS   = 4.0f;    // the edge spot is moved onto the mesh from at most this far
static constexpr uint32 PREY_SHUN_MS      = 60000;   // a monster given up on (no route, out of reach) is skipped this long
static constexpr uint32 PREY_GIVE_UP_MS   = 20000;   // an approach not at the edge by now is given up
static constexpr uint32 OPEN_GRACE_MS     = 5000;    // an opened fight not begun by now failed (Carago, 2026-10-03)
// People nearby (617p)
static constexpr uint32 NPC_LOOK_MS       = 5000;    // a roaming buddy looks round for people this often
static constexpr uint32 NPC_GIVE_UP_MS    = 60000;   // not at the person by now: given up
static constexpr uint32 NPC_TALK_MIN_MS   = 4000;    // a chat lasts 4 ...
static constexpr uint32 NPC_TALK_MAX_MS   = 9000;    // ... to 9 seconds
static constexpr uint32 NPC_TALK_EVERY_MS = 2000;    // a talking gesture this often during it
static constexpr float  NPC_ARRIVED_YARDS = 1.5f;

// The selling trip (617h1; the owner, 2026-10-03: "they should move to the
// nearest town / vendor and sell what they need to")
static constexpr float  SELL_NEAR_YARDS   = 40.0f;   // this near the vendor's spot, the vendor itself is looked for
static constexpr float  SELL_TALK_YARDS   = 4.0f;    // this near the vendor, the sale
static constexpr float  SELL_STRETCH_YARDS = 80.0f;  // each walking order reaches at most this far toward the vendor ...
static constexpr float  SELL_SHORT_YARDS  = 30.0f;   // ... or this far, when the longer stretch has no route
static constexpr uint32 SELL_GIVE_UP_MS   = 180000;  // a trip not done by now is given up
static constexpr uint32 SELL_SHUN_MS      = 600000;  // a vendor given up on is skipped this long
// A view of the middle (617o5; the owner, 2026-10-03): "walk to the top of
// the hill that is nearest to the middle [...] We only have to walk to the
// top ~85% of the hill though. If the line-of-sight check still doesn't
// work, then we walk upward until it does." And: "if there's a doodad in
// the way, then we should orbit that doodad until we get a good
// line-of-sight. If we do a complete circle, then we should prune the
// waypoint paths until they reach out of the circle we made, and then
// route to that spot instead." Which hill: "one of these three randomly";
// the circle: "From it's center to it's most distant component, add
// 15-30%"; "She should orbit in a random direction each time".
enum : uint8 { VIEW_NONE = 0, VIEW_CLIMB = 1, VIEW_ORBIT = 2 };
static constexpr float  VANTAGE_SHARE     = 0.85f;   // the share of the hill's rise climbed before the first look
static constexpr float  CLIMB_STEP_YARDS  = 6.0f;    // each order up the hill reaches about this far
static constexpr float  CLIMB_TOP_YARDS   = 3.0f;    // this near the top is the top
static constexpr float  ORBIT_MARGIN_MIN  = 1.15f;   // the circle's radius: the object's reach times 1.15 ...
static constexpr float  ORBIT_MARGIN_MAX  = 1.30f;   // ... to 1.30, picked each time
static constexpr float  ORBIT_STEP_YARDS  = 4.0f;    // each order round the circle reaches about this far
static constexpr float  ORBIT_OUT_YARDS   = 3.0f;    // after a whole circle, the spot this far outside it toward the middle
static constexpr uint32 VIEW_GIVE_UP_MS   = 60000;   // a climb or circle not done by now is given up
static constexpr uint32 RETRY_MS          = 10000;   // after a failed pick or centre lookup, wait this long
static constexpr float  OTHERS_YARDS      = 100.0f;  // players this near a buddy count for the crowding rule
static constexpr float  MIN_BODY_YARDS    = 0.5f;    // no body is tested more finely than this
static constexpr uint32 PASS_EVERY_MS     = 3000;    // the strategy pass
// inside a dungeon or raid (617c3, owner 2026-10-04: "They should attack
// when they are ~10% farther than the monster's aggro radius. Otherwise,
// they follow the player.")
static constexpr uint32 AGGRO_LOOK_MS     = 500;     // a buddy inside looks round for monsters this often
static constexpr float  AGGRO_REACH       = 1.1f;    // the owner within this times a monster's aggro radius for them: the buddies go
static constexpr float  AGGRO_SEARCH_YARDS = 50.0f;  // the farthest that can be: the largest radius (45) x 1.1
static constexpr float  MOBS_YARDS        = 60.0f;   // monsters this near a buddy are offered to the nudge
static constexpr uint32 MEAL_MAX_MS       = 120000;  // a meal that hasn't finished by now is ended (and logged)
static constexpr uint32 CAMPFIRE_SPELL    = 818;     // Basic Campfire: taught with Cooking (every buddy has it,
                                                     // 617k); in this version it needs no wood, flint or tinder
                                                     // (no reagents or tools in the spell data), and places a
                                                     // campfire object for a few minutes

static constexpr float  DETOUR_YARDS      = 45.0f;   // a chest or node this near (and past loot's own 15) pulls the buddy off its lap
static constexpr uint32 DETOUR_LOOK_MS    = 2000;    // how often a roaming buddy looks around for one
static constexpr uint32 DETOUR_GIVE_UP_MS = 30000;   // a detour not finished by now is dropped (no way there, a
                                                     // loot that keeps failing); also how long a claim lasts
static constexpr uint32 DETOUR_TRIED_MS   = 600000;  // an object a buddy detoured to is not its target again
                                                     // for this long ("once"): nodes respawn under the same guid
static constexpr uint32 MINING_PICK_TOOL  = 165;     // the "Mining Pick" tool category (item_template.TotemCategory
                                                     // of item 2901); the core's own test for "carries a pick",
                                                     // which also accepts the army knife and the hammer picks
static constexpr float  NODE_REACH_YARDS  = 3.0f;    // a herb or ore node whose best walking path ends farther
                                                     // than this from it can't be gathered (the bot module's
                                                     // height test allows about 3 yards): the node is moved and
                                                     // its spot retired (owner, 2026-10-02; buddies_nodes.cpp)
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
    ObjectGuid       detour;                // the chest or node it is walking to; empty when on its lap
    uint64           detourStarted = 0;     // game-time ms
    uint64           nextLook   = 0;        // game-time ms; no look for a detour before this
    std::vector<std::pair<ObjectGuid, uint64>> tried;   // objects already detoured to, and until when they are skipped
    // the leg checks and the stuck rule (617o1)
    size_t           checkedLeg = SIZE_MAX; // the path point whose leg the mesh last judged complete (none: SIZE_MAX)
    size_t           orderedLeg = SIZE_MAX; // the path point the last walking order went to (the turn rule turns before a new one)
    size_t           watched    = SIZE_MAX; // the bookmarked point progress is measured toward
    float            nearest    = 0.0f;     // the nearest the buddy has been to it, yards
    uint64           progressAt = 0;        // game-time ms of the last progress toward it
    // the monster approach (617o4)
    ObjectGuid       prey;                  // the monster being approached; empty when none
    uint64           nextPreyLook = 0;      // game-time ms; no new monster chosen before this
    uint64           nextAim    = 0;        // game-time ms; the prey is aimed at again then
    uint64           preyStarted = 0;       // game-time ms the approach began
    // the people nearby (617p)
    ObjectGuid       npc;                   // the person it is going to; empty when none
    uint8            npcUse     = 0;        // BuddyNpcUse
    BuddyRoam::Point npcSpot;               // its claimed standing spot
    uint64           npcStarted = 0, nextNpcLook = 0, talkUntil = 0, nextGesture = 0;
    // the selling trip (617h1)
    bool             selling    = false;
    uint32           sellSpawn  = 0;        // the vendor's spawn (creature table guid)
    uint32           sellEntry  = 0;        // its creature entry
    BuddyRoam::Point sellAt;                // its spawn spot
    uint64           sellStarted = 0;       // game-time ms
    std::vector<std::pair<uint32, uint64>> vendorShun;   // vendor spawns given up on, and until when
    ObjectGuid       opened;                // the monster a fight was last opened on, until it begins or fails
    uint64           openedAt   = 0;        // game-time ms
    bool             turning    = false;    // at the edge, stopped and turning to face the prey
    bool             aimed      = false;    // the first aim's turn is done
    std::vector<std::pair<ObjectGuid, uint64>> shunned;   // monsters given up on, and until when
    // looking for a view of the middle (617o5)
    uint8            view       = VIEW_NONE;
    uint64           viewStarted = 0;       // game-time ms
    BuddyRoam::Point viewGoal;              // the hilltop climbed, or the centre of the object circled
    float            viewBaseZ  = 0.0f;     // climbing: the height it began at
    BuddyRoam::Point viewNext;              // circling: the spot on the circle it is walking to
    bool             viewHasNext = false;
    float            orbitRadius = 0.0f;    // circling: yards from the object's centre
    float            orbitAngle = 0.0f;     // circling: where on the circle, radians
    float            orbitTurned = 0.0f;    // circling: how far round so far, radians
    int8             orbitDir   = 1;        // circling: 1 anticlockwise, -1 clockwise
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

// {{{ the clan's claims
// Which chest or node each clan's buddies are already walking to, so two
// of them don't go for the same one: "the first to claim it keeps it"
// (617e3). Kept per owner (character guid, low part): buddies of other
// owners may race for the same vein, as players do. A claim is let go by
// the buddy that holds it when its detour ends (opened, gone, given up),
// and lapses on its own after DETOUR_GIVE_UP_MS, which covers a buddy that
// logged out or changed area mid-detour. Locked: the clan's buddies may
// stand on maps updating in parallel.
struct DetourClaim
{
    uint32 buddy = 0;
    uint64 until = 0;    // game-time ms
};
static std::mutex sClaimLock;
static std::unordered_map<uint32, std::map<ObjectGuid, DetourClaim>> sClaims;

// Take the claim, or confirm this buddy already holds it. False when a
// clanmate holds a claim that hasn't lapsed.
static bool ClaimDetour(uint32 ownerGuid, ObjectGuid object, uint32 buddyGuid, uint64 now)
{
    std::lock_guard<std::mutex> lock(sClaimLock);
    auto& claims = sClaims[ownerGuid];
    for (auto it = claims.begin(); it != claims.end(); )
        it = it->second.until <= now ? claims.erase(it) : std::next(it);
    auto found = claims.find(object);
    if (found != claims.end() && found->second.buddy != buddyGuid)
        return false;
    claims[object] = { buddyGuid, now + DETOUR_GIVE_UP_MS };
    return true;
}

// Let go of a claim this buddy holds (another buddy's is left alone: this
// one's may have lapsed and been taken since).
static void ReleaseDetour(uint32 ownerGuid, ObjectGuid object, uint32 buddyGuid)
{
    std::lock_guard<std::mutex> lock(sClaimLock);
    auto owner = sClaims.find(ownerGuid);
    if (owner == sClaims.end())
        return;
    auto found = owner->second.find(object);
    if (found != owner->second.end() && found->second.buddy == buddyGuid)
        owner->second.erase(found);
}
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
        // Aboard a boat or zeppelin: "buddy travel" holds it still and steps
        // it off at the dock (buddies_crossing.cpp, 617e8); a roaming walk
        // from the deck would steer it off the side into the sea.
        if (bot->GetTransport())
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
            if (s.detour)
                ReleaseDetour(owner->GetGUID().GetCounter(), s.detour, guid);   // a detour in the old area ends with it
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

        // A chest or node off the lap (617e3): end a detour that is over,
        // or look for a new one every DETOUR_LOOK_MS. Either changes only
        // the path being walked; the pinwheel's bearing and Y stay as they
        // were, so the next waypoint pick carries the lap on from here.
        // Within the bot module's loot reach, roaming stands aside: its loot
        // and gather actions (which outrank this one) walk the last yards
        // and open it; this action only keeps the buddy from wandering off
        // meanwhile, until the object is opened, gone, or given up on.
        if (s.detour)
        {
            if (TendDetour(s, owner, now))
            {
                StoreState(guid, s);
                return false;
            }
        }
        else if (now >= s.nextLook)
        {
            s.nextLook = now + DETOUR_LOOK_MS;
            StartDetour(s, owner, areaId, now);
        }

        // People within 100 yards it needs (lessons, selling, repairs), or
        // now and then a chat (617p); before the selling trip, so a vendor
        // close by is used rather than the database's nearest
        if (!s.detour && NpcErrand(s, now))
        {
            StoreState(guid, s);
            return true;
        }

        // Full bags: a trip to the nearest vendor first (617h1)
        if (!s.detour && SellingTrip(s, now))
        {
            StoreState(guid, s);
            return true;
        }

        // A monster worth fighting near: approach it and open the fight
        // (617o4); roaming waits meanwhile and carries on after the kill
        if (!s.detour && Approach(s, now))
        {
            StoreState(guid, s);
            return true;
        }

        // Looking for a view of the middle (617o5): a climb or a circle
        // under way holds roaming until it sees the middle or gives up
        if (s.view != VIEW_NONE && View(s, owner, areaId, now))
        {
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
                    // no sight of the middle: climb for it, or circle what
                    // blocks it (617o5), from the next tick
                    if (!found && StartView(s, owner, areaId, at, now))
                    {
                        StoreState(guid, s);
                        return true;
                    }
                    // then a few steps toward the middle by its distance map
                    // (617o3): the pinwheel needs a straight sight of the
                    // middle, the map walks round whatever blocks it
                    BuddyRoam::Point toward;
                    if (!found && BuddyExploreStepToward(bot, owner, areaId, s.area.centre, LEG_YARDS * 2.0f, toward))
                    {
                        explored = { toward };
                        found    = true;
                        BuddyTrace(bot, "roam: no pinwheel waypoint; {:.1f} yards toward the middle by its distance map",
                            bot->GetExactDist2d(toward.x, toward.y));
                    }
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
            // found: the explorer's grid chose it; not found but here: the
            // pinwheel core did (a failure returned above)
            BuddyTrace(bot, "roam: waypoint ({:.1f}, {:.1f}, {:.1f}), {:.1f} yards off, {} path points, chosen by {}",
                s.buddy.waypoint.x, s.buddy.waypoint.y, s.buddy.waypoint.z,
                bot->GetExactDist2d(s.buddy.waypoint.x, s.buddy.waypoint.y), s.buddy.path.size(),
                found ? "the explorer's grid" : "the pinwheel");

            // The mesh's word on the waypoint (617o1): moved onto the mesh,
            // and a complete route there, or the pick is dropped and another
            // made shortly. Every planner judges ground its own way; only
            // the mesh is what the walking walks on.
            BuddyRoam::Point onMesh;
            std::vector<BuddyRoam::Point> route;
            BuddyRouteKind kind = BuddyRouteKind::None;
            bool snapped = BuddyMeshSnap(map, s.buddy.waypoint, SNAP_WAYPOINT_YARDS, SNAP_RISE_YARDS, onMesh);
            if (snapped)
                kind = BuddyMeshRoute(bot, onMesh, route);
            if (!snapped || kind != BuddyRouteKind::Complete)
            {
                BuddyTrace(bot, "roam: waypoint dropped: {}", snapped
                    ? Acore::StringFormat("the mesh's route there is {}", BuddyRouteKindName(kind))
                    : Acore::StringFormat("no mesh within {:.0f} yards of it", SNAP_WAYPOINT_YARDS));
                s.buddy.hasWaypoint = false;
                s.retryAt = now + MESH_RETRY_MS;
                StoreState(guid, s);
                return false;
            }
            BuddyTrace(bot, "roam: waypoint on the mesh at ({:.1f}, {:.1f}, {:.1f}), {:.1f} yards from the pick; route complete",
                onMesh.x, onMesh.y, onMesh.z,
                std::hypot(onMesh.x - s.buddy.waypoint.x, onMesh.y - s.buddy.waypoint.y));
            s.buddy.waypoint    = onMesh;
            s.buddy.path.back() = onMesh;
            s.checkedLeg        = SIZE_MAX;
            s.watched           = SIZE_MAX;
            s.orderedLeg        = SIZE_MAX;
        }

        // Walk: points already within reach are passed; the order goes to
        // the farthest point within a leg's length along the path, so the
        // bot module's walking plans each leg on the navigation mesh while
        // the core's plan decides the line (round steps, onto gentle
        // ground). The last point is the waypoint.
        //
        // Passed means within reach of that point or of any point further
        // along (617o1): a planned point the walking can't come within 2
        // yards of (on a rock beside the path) no longer holds the
        // bookmark when the buddy stands on a later one.
        auto& path = s.buddy.path;
        for (size_t i = path.size(); i > s.buddy.pathIndex; --i)
            if (bot->GetExactDist2d(path[i - 1].x, path[i - 1].y) <= REACHED_YARDS)
            {
                s.buddy.pathIndex = i;
                break;
            }

        // Stuck: no progress toward the bookmarked point for STUCK_MS (the
        // order refused, the buddy standing) skips it; skipping the last
        // ends the waypoint as reached.
        if (s.buddy.pathIndex < path.size())
        {
            float d = bot->GetExactDist2d(path[s.buddy.pathIndex].x, path[s.buddy.pathIndex].y);
            if (s.watched != s.buddy.pathIndex)
            {
                s.watched    = s.buddy.pathIndex;       // a new point to watch: start its clock
                s.nearest    = d;
                s.progressAt = now;
            }
            else if (d < s.nearest - PROGRESS_YARDS)
            {
                s.nearest    = d;                       // nearer: progress
                s.progressAt = now;
            }
            else if (now - s.progressAt > STUCK_MS)
            {
                BuddyTrace(bot, "roam: path point {} of {} skipped: no progress in {} s, {:.1f} yards off",
                    s.buddy.pathIndex + 1, path.size(), STUCK_MS / 1000, d);
                ++s.buddy.pathIndex;
                s.watched = SIZE_MAX;
            }
        }
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

        // The leg's check (617o1), once per target point: onto the mesh,
        // and a complete route to it. Anything else would end short (the
        // buddy waiting for good) or be walked in a straight line by the
        // server's fallback, so the planned path is given up for the mesh's
        // own route to the waypoint; with no complete route there either,
        // the waypoint is dropped.
        if (s.checkedLeg != target)
        {
            BuddyRoam::Point onMesh;
            std::vector<BuddyRoam::Point> route;
            BuddyRouteKind kind = BuddyRouteKind::None;
            bool snapped = BuddyMeshSnap(map, path[target], SNAP_POINT_YARDS, SNAP_RISE_YARDS, onMesh);
            if (snapped)
                kind = BuddyMeshRoute(bot, onMesh, route);
            if (snapped && kind == BuddyRouteKind::Complete)
            {
                path[target]  = onMesh;
                s.checkedLeg  = target;
            }
            else
            {
                BuddyRouteKind whole = BuddyMeshRoute(bot, s.buddy.waypoint, route);
                BuddyTrace(bot, "roam: leg to path point {} of {} refused by the mesh ({}); {}",
                    target + 1, path.size(), snapped ? BuddyRouteKindName(kind) : "no mesh near it",
                    whole == BuddyRouteKind::Complete ? "following the mesh's own route to the waypoint" : "waypoint dropped");
                if (whole == BuddyRouteKind::Complete)
                {
                    path              = route;
                    s.buddy.pathIndex = 0;
                    s.checkedLeg      = SIZE_MAX;
                    s.watched         = SIZE_MAX;
                    s.orderedLeg      = SIZE_MAX;
                    StoreState(guid, s);
                    return true;                        // walked from the next tick
                }
                s.buddy.hasWaypoint = false;
                s.retryAt = now + MESH_RETRY_MS;
                StoreState(guid, s);
                return false;
            }
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
        // the turn rule (buddies_steer.h): before setting off toward a new
        // point, face it smoothly, standing still or along a short curve;
        // the same point again (most ticks) needs no turn
        if (target != s.orderedLeg)
        {
            float want = std::atan2(p.y - bot->GetPositionY(), p.x - bot->GetPositionX());
            if (BuddyTurnToward(bot, want))
                return true;                            // turning: the order waits for it
            s.orderedLeg = target;
            StoreState(guid, s);
        }
        // The wander priority: any other walking the bot module wants (to a
        // fight, a corpse) is not held up waiting for this one.
        bool ordered = MoveTo(map->GetId(), p.x, p.y, p.z, false, false, false, false, MovementPriority::MOVEMENT_WANDER);
        // "not re-ordered": the bot module ignores an order to where it is
        // already headed or standing, which is most ticks of a leg
        BuddyTrace(bot, "roam: leg to path point {} of {} ({:.1f}, {:.1f}, {:.1f}), {:.1f} yards, {}{}",
            target + 1, path.size(), p.x, p.y, p.z, bot->GetExactDist2d(p.x, p.y),
            ordered ? "ordered" : "not re-ordered", walk ? ", walking" : ", running");
        return ordered || bot->isMoving();
    }

private:
    // {{{ the people nearby (617p)
    void EndNpcErrand(RoamState& s)
    {
        BuddyNpcRelease(bot, s.npc);
        s.npc.Clear();
        s.npcUse = 0;
    }

    // One step of going to a person and using them; true while it holds
    // the buddy.
    bool NpcErrand(RoamState& s, uint64 now)
    {
        if (!s.npc)
        {
            if (now < s.nextNpcLook)
                return false;
            s.nextNpcLook = now + NPC_LOOK_MS;
            BuddyNpcPick pick;
            if (!BuddyNpcNotice(bot, pick))
                return false;
            s.npc = pick.npc, s.npcUse = uint8(pick.use), s.npcSpot = pick.spot, s.npcStarted = now, s.talkUntil = 0;
            BuddyTrace(bot, "people: going to {} for {}", pick.npc.ToString(), BuddyNpcUseName(pick.use));
        }
        Creature* npc = ObjectAccessor::GetCreature(*bot, s.npc);
        if (!npc || !npc->IsAlive())
        {
            BuddyTrace(bot, "people: the person is gone");
            EndNpcErrand(s);
            return false;
        }
        if (now - s.npcStarted > NPC_GIVE_UP_MS)
        {
            BuddyTrace(bot, "people: not there in {} s; given up", NPC_GIVE_UP_MS / 1000);
            EndNpcErrand(s);
            return false;
        }
        // walk to the claimed spot (turning first, by the turn rule)
        if (bot->GetExactDist2d(s.npcSpot.x, s.npcSpot.y) > NPC_ARRIVED_YARDS)
        {
            if (!bot->movespline->Finalized())
                return true;
            if (BuddyTurnToward(bot, std::atan2(s.npcSpot.y - bot->GetPositionY(), s.npcSpot.x - bot->GetPositionX())))
                return true;
            MoveTo(bot->GetMapId(), s.npcSpot.x, s.npcSpot.y, s.npcSpot.z, false, false, false, false, MovementPriority::MOVEMENT_WANDER);
            return true;
        }
        // there: face them, then whatever they offer that it can use, decided
        // now (617p: "only test to see what they do the first time they
        // arrive"), or, with nothing to use, a chat over a few seconds
        if (BuddyTurnToward(bot, bot->GetAngle(npc)))
            return true;
        if (!s.talkUntil)
        {
            bool talk = false;
            std::string done = BuddyNpcArrive(botAI, bot, npc, talk);
            BuddyTrace(bot, "people: at {} (came for {}): {}", npc->GetName(), BuddyNpcUseName(BuddyNpcUse(s.npcUse)), done);
            if (!talk)
            {
                bot->HandleEmoteCommand(EMOTE_ONESHOT_TALK);
                EndNpcErrand(s);
                return true;
            }
            s.talkUntil   = now + urand(NPC_TALK_MIN_MS, NPC_TALK_MAX_MS);
            s.nextGesture = now;
        }
        if (now >= s.talkUntil)
        {
            EndNpcErrand(s);
            return false;
        }
        if (now >= s.nextGesture)
        {
            bot->HandleEmoteCommand(EMOTE_ONESHOT_TALK);
            s.nextGesture = now + NPC_TALK_EVERY_MS;
        }
        return true;
    }
    // }}}

    // {{{ the selling trip (617h1)
    // Every vendor of the world that sells something (its spawn spot),
    // read once; hidden stand-ins left out as the town circles leave them.
    struct VendorSpawn { uint32 spawn, entry, map; BuddyRoam::Point at; };
    static std::vector<VendorSpawn> const& Vendors()
    {
        static std::once_flag once;
        static std::vector<VendorSpawn> list;
        std::call_once(once, [] {
            QueryResult rows = WorldDatabase.Query(
                "SELECT DISTINCT c.guid, c.id, c.map, c.position_x, c.position_y, c.position_z FROM creature c "
                "JOIN creature_template ct ON ct.entry = c.id JOIN npc_vendor v ON v.entry = c.id "
                "WHERE (ct.npcflag & 128) <> 0 AND ct.name NOT LIKE '%[DND]%' AND (ct.unit_flags & 33554432) = 0 "
                "AND (ct.flags_extra & 128) = 0");
            if (rows)
                do
                {
                    Field* f = rows->Fetch();
                    list.push_back({ f[0].Get<uint32>(), f[1].Get<uint32>(), f[2].Get<uint32>(),
                                     { f[3].Get<float>(), f[4].Get<float>(), f[5].Get<float>() } });
                } while (rows->NextRow());
            LOG_INFO("module", "mod-buddies: {} vendors known for selling trips (617h1)", list.size());
        });
        return list;
    }

    void ShunVendor(RoamState& s, uint64 now, char const* why)
    {
        s.vendorShun.erase(std::remove_if(s.vendorShun.begin(), s.vendorShun.end(),
            [now](auto const& v) { return v.second <= now; }), s.vendorShun.end());
        s.vendorShun.push_back({ s.sellSpawn, now + SELL_SHUN_MS });
        BuddyTrace(bot, "sell: trip given up ({}); that vendor skipped for {} minutes", why, SELL_SHUN_MS / 60000);
        s.selling = false;
    }

    // One step of the trip; true while it holds the buddy.
    bool SellingTrip(RoamState& s, uint64 now)
    {
        if (!s.selling)
        {
            if (BuddyBagFullness(bot) < BuddyFullBagsShare())
                return false;
            // only when told (617y, owner 2026-10-12: the full buddy says so,
            // and "go sell" sends it); until then it keeps roaming, full
            if (!BuddyTakeSellOrder(bot->GetGUID().GetCounter()))
                return false;
            VendorSpawn const* best = nullptr;
            float bestD = 1e30f;
            for (VendorSpawn const& v : Vendors())
            {
                if (v.map != bot->GetMapId())
                    continue;
                bool shunned = false;
                for (auto const& sh : s.vendorShun)
                    if (sh.first == v.spawn && sh.second > now)
                        shunned = true;
                float d = bot->GetExactDist2d(v.at.x, v.at.y);
                if (!shunned && d < bestD)
                    best = &v, bestD = d;
            }
            if (!best)
                return false;                           // no vendor on this map (or all given up on): keep roaming
            s.selling     = true;
            s.sellSpawn   = best->spawn;
            s.sellEntry   = best->entry;
            s.sellAt      = best->at;
            s.sellStarted = now;
            BuddyTrace(bot, "sell: bags {:.0f}% full; off to the vendor {} yards away (creature {}, at ({:.1f}, {:.1f}, {:.1f}))",
                BuddyBagFullness(bot) * 100.0f, uint32(bestD), best->entry, best->at.x, best->at.y, best->at.z);
        }
        if (now - s.sellStarted > SELL_GIVE_UP_MS)
        {
            ShunVendor(s, now, "not there in time");
            return false;
        }

        // near: the vendor itself, then the sale
        if (bot->GetExactDist2d(s.sellAt.x, s.sellAt.y) <= SELL_NEAR_YARDS)
        {
            Creature* npc = bot->FindNearestCreature(s.sellEntry, SELL_NEAR_YARDS * 1.5f);
            if (!npc)
            {
                ShunVendor(s, now, "the vendor isn't there");
                return false;
            }
            if (bot->GetDistance(npc) > SELL_TALK_YARDS)
            {
                MoveNear(npc, SELL_TALK_YARDS - 1.0f);
                return true;
            }
            bot->SetFacingToObject(npc);
            float before = BuddyBagFullness(bot);
            BuddySellAtVendor(botAI, bot, npc);
            BuddyTrace(bot, "sell: sold at {}: bags {:.0f}% full, now {:.0f}%", npc->GetName(), before * 100.0f,
                BuddyBagFullness(bot) * 100.0f);
            s.selling = false;
            s.buddy.hasWaypoint = false;                // roaming picks a fresh waypoint from here
            return true;
        }

        // the walk: a stretch toward the vendor that the mesh has a whole
        // route for (80 yards, or 30 when that has none); ordered when
        // standing or near the end of the last stretch
        if (!bot->movespline->Finalized())
        {
            G3D::Vector3 end = bot->movespline->FinalDestination();
            if (bot->GetExactDist2d(end.x, end.y) > 5.0f)
                return true;
        }
        BuddyRoam::Point here { bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ() };
        float d = bot->GetExactDist2d(s.sellAt.x, s.sellAt.y);
        for (float reach : { SELL_STRETCH_YARDS, SELL_SHORT_YARDS })
        {
            float k = std::min(1.0f, reach / std::max(d, 0.01f));
            BuddyRoam::Point toward { here.x + (s.sellAt.x - here.x) * k, here.y + (s.sellAt.y - here.y) * k,
                                      here.z + (s.sellAt.z - here.z) * k }, onMesh;
            std::vector<BuddyRoam::Point> route;
            if (!BuddyMeshSnap(bot->GetMap(), toward, SNAP_WAYPOINT_YARDS, 40.0f, onMesh) ||
                BuddyMeshRoute(bot, onMesh, route) != BuddyRouteKind::Complete)
                continue;
            if (BuddyTurnToward(bot, std::atan2(onMesh.y - here.y, onMesh.x - here.x)))
                return true;
            MoveTo(bot->GetMapId(), onMesh.x, onMesh.y, onMesh.z, false, false, false, false, MovementPriority::MOVEMENT_WANDER);
            return true;
        }
        ShunVendor(s, now, "no route toward it from here");
        return false;
    }
    // }}}

    // {{{ the monster approach (617o4)
    // The nearest monster a buddy would fight: alive, nobody's pet, not a
    // critter or civilian or immune to players, not already fighting, not
    // someone else's kill, one the buddy may attack, worth experience to
    // it, hostile or neutral (617e3: starting zones are nearly all neutral
    // monsters), not recently given up on.
    Creature* PreyNear(RoamState const& s, uint64 now)
    {
        std::list<Unit*> units;
        Acore::AnyUnitInObjectRangeCheck check(bot, MOBS_YARDS);
        Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> searcher(bot, units, check);
        Cell::VisitObjects(bot, searcher, MOBS_YARDS);
        Creature* best = nullptr;
        float bestDist = MOBS_YARDS + 1.0f;
        for (Unit* u : units)
        {
            Creature* c = u->ToCreature();
            if (!c || !c->IsAlive() || !c->GetCharmerOrOwnerGUID().IsEmpty())
                continue;
            if (c->IsCritter() || c->IsCivilian() || c->IsImmuneToPC() || c->IsInCombat())
                continue;
            if (c->hasLootRecipient() && !c->isTappedBy(bot))
                continue;
            if (!bot->IsValidAttackTarget(c) || !bot->isHonorOrXPTarget(c))
                continue;
            bool shunned = false;
            for (auto const& sh : s.shunned)
                if (sh.first == c->GetGUID() && sh.second > now)
                    shunned = true;
            if (shunned)
                continue;
            float d = bot->GetExactDist(c);
            if (d < bestDist)
            {
                best = c;
                bestDist = d;
            }
        }
        return best;
    }

    void Shun(RoamState& s, ObjectGuid guid, uint64 now, char const* why)
    {
        s.shunned.erase(std::remove_if(s.shunned.begin(), s.shunned.end(),
            [now](auto const& sh) { return sh.second <= now; }), s.shunned.end());
        s.shunned.push_back({ guid, now + PREY_SHUN_MS });
        BuddyTrace(bot, "approach: monster given up on ({}), skipped for {} s", why, PREY_SHUN_MS / 1000);
        s.prey.Clear();
        s.turning = false;
    }

    // Open the fight the bot module's way (as its attack action does): the
    // target selected and remembered, the fighting engine switched on, the
    // first swing begun; from then on the class's own fighting (a pull
    // spell, a charge, stealth) takes over.
    //
    // Seen 2026-10-03 (Carago, a rogue, at a neutral Volatile Mutation 20
    // yards off): the bot module dropped the target at once and the
    // approach chose the same monster again, round and round. A neutral
    // monster not yet struck is no fight to the bot module, so a melee
    // buddy now also runs in after it (the server's chase), which makes
    // the first blow land and the fight real; a ranged one is left to its
    // class's pull from the edge. OPEN_GRACE_MS later, no fight means the
    // opening failed: the monster is skipped for a while (Shun) and the
    // trace says what the bot module would have objected to.
    void OpenFight(Creature* c, RoamState& s, uint64 now)
    {
        bool melee = botAI->IsMelee(bot);
        bot->SetSelection(c->GetGUID());
        context->GetValue<Unit*>("current target")->Set(c);
        botAI->ChangeEngine(BOT_STATE_COMBAT);
        bot->Attack(c, melee);
        if (melee)
            bot->GetMotionMaster()->MoveChase(c);
        s.opened   = c->GetGUID();
        s.openedAt = now;
    }

    // An opened fight that never began: given up on, with the reasons the
    // bot module checks (its "invalid target" rule) written to the trace.
    void CheckOpening(RoamState& s, uint64 now)
    {
        if (!s.opened || now - s.openedAt < OPEN_GRACE_MS)
            return;
        ObjectGuid opened = s.opened;
        s.opened.Clear();
        if (bot->IsInCombat())
            return;                                     // the fight began: nothing to check
        Creature* c = ObjectAccessor::GetCreature(*bot, opened);
        if (c)
            BuddyTrace(bot, "approach: the fight with {} never began in {} s (in sight {}, it sees us {}, friendly {}, alive {})",
                c->GetName(), OPEN_GRACE_MS / 1000, bot->IsWithinLOSInMap(c), bot->CanSeeOrDetect(c), c->IsFriendlyTo(bot), c->IsAlive());
        Shun(s, opened, now, "the fight never began");
    }

    // One step of the approach; true while it holds the buddy (roaming
    // waits), false when there is nothing to approach.
    bool Approach(RoamState& s, uint64 now)
    {
        CheckOpening(s, now);
        if (!s.prey && now >= s.nextPreyLook)
        {
            s.nextPreyLook = now + PREY_LOOK_MS;
            if (Creature* c = PreyNear(s, now))
            {
                s.prey      = c->GetGUID();
                s.nextAim   = 0;
                s.turning   = false;
                s.aimed     = false;
                s.preyStarted = now;
                BuddyTrace(bot, "approach: {} (entry {}, level {}, {}), {:.1f} yards off, notice radius {:.1f}",
                    c->GetName(), c->GetEntry(), c->GetLevel(), c->IsHostileTo(bot) ? "hostile" : "neutral",
                    bot->GetExactDist(c), BuddyNoticeRadius(c, bot));
            }
        }
        if (!s.prey)
            return false;
        Creature* c = ObjectAccessor::GetCreature(*bot, s.prey);
        if (!c || !c->IsAlive() || (c->IsInCombat() && c->GetVictim() != bot) || !bot->IsValidAttackTarget(c))
        {
            BuddyTrace(bot, "approach: ended (the monster is gone, dead, or busy with someone else)");
            s.prey.Clear();
            s.turning = false;
            return false;
        }
        if (now - s.preyStarted > PREY_GIVE_UP_MS)
        {
            Shun(s, c->GetGUID(), now, "not at the edge in time");
            return false;
        }

        // the radius: the server's own; with aggro off (0) the edge is the
        // monster's own reach, so the buddy still stops short of touching it
        float radius = BuddyNoticeRadius(c, bot);
        if (radius <= 0.0f)
            radius = c->GetCombatReach() + bot->GetCombatReach();
        float d = bot->GetExactDist2d(c);

        // at the edge: turn to face it over BUDDY_TURN_MS, then open the fight
        if (d <= radius + EDGE_SLACK_YARDS)
        {
            if (!s.turning)
            {
                bot->StopMoving();                      // arrived: stand, then face it by the turn rule
                s.turning = true;
            }
            if (BuddyTurnToward(bot, bot->GetAngle(c)))
                return true;
            BuddyTrace(bot, "approach: at the edge of {}'s notice ({:.1f} yards), the fight opened", c->GetName(), d);
            OpenFight(c, s, now);
            s.prey.Clear();
            s.turning = false;
            return true;
        }

        // on the way: aim again every BUDDY_STEER_MS at where it stands now
        if (now < s.nextAim)
            return true;
        s.nextAim = now + BUDDY_STEER_MS;
        BuddyRoam::Point here  { bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ() };
        BuddyRoam::Point there { c->GetPositionX(), c->GetPositionY(), c->GetPositionZ() };
        BuddyRoam::Point edge = BuddySteerEdge(there, here, radius);
        BuddyRoam::Point onMesh;
        if (!BuddyMeshSnap(bot->GetMap(), edge, EDGE_SNAP_YARDS, SNAP_RISE_YARDS, onMesh))
        {
            Shun(s, c->GetGUID(), now, "no standing spot at the edge of its notice");
            return false;
        }
        bool straight = BuddyMeshLineClear(bot->GetMap(), here, onMesh);
        if (!straight)
        {
            std::vector<BuddyRoam::Point> route;
            BuddyRouteKind kind = BuddyMeshRoute(bot, onMesh, route);
            if (kind != BuddyRouteKind::Complete)
            {
                Shun(s, c->GetGUID(), now, BuddyRouteKindName(kind));
                return false;
            }
        }
        // the turn rule on the first aim only: later aims follow a target
        // that moves a little, and turning for each would stall the chase
        if (!s.aimed)
        {
            if (BuddyTurnToward(bot, std::atan2(onMesh.y - here.y, onMesh.x - here.x)))
            {
                s.nextAim = 0;                          // aim again as soon as the turn is done
                return true;
            }
            s.aimed = true;
        }
        bool ordered = MoveTo(bot->GetMapId(), onMesh.x, onMesh.y, onMesh.z, false, false, false, false, MovementPriority::MOVEMENT_WANDER);
        BuddyTrace(bot, "approach: aim at ({:.1f}, {:.1f}, {:.1f}), {:.1f} yards, {}, {}", onMesh.x, onMesh.y, onMesh.z,
            bot->GetExactDist2d(onMesh.x, onMesh.y), straight ? "straight (the line is clear)" : "by the mesh's route",
            ordered ? "ordered" : "not re-ordered");
        return true;
    }
    // }}}

    // {{{ the view (617o5)
    // What blocks the look at the middle decides: an object is circled, the
    // ground climbed. False when neither can start (nothing blocks the look,
    // no hill, the object too big, the grid not ready).
    bool StartView(RoamState& s, Player* owner, uint32 areaId, BuddyRoam::Point const& at, uint64 now)
    {
        BuddyRoam::Point hit;
        BuddySight sight = BuddySightBlocker(bot->GetMap(), bot->GetPhaseMask(), at, s.area.centre, hit);
        if (sight == BuddySight::Object)
        {
            BuddyRoam::Point centre;
            float reach = 0.0f;
            if (!BuddyExploreObstacle(owner, areaId, hit, centre, reach))
            {
                BuddyTrace(bot, "view: an object at ({:.1f}, {:.1f}, {:.1f}) blocks the middle, but it can't be circled "
                    "(too big, off the grid, or the grid isn't ready)", hit.x, hit.y, hit.z);
                return false;
            }
            s.view        = VIEW_ORBIT;
            s.viewStarted = now;
            s.viewGoal    = centre;
            s.orbitRadius = reach * frand(ORBIT_MARGIN_MIN, ORBIT_MARGIN_MAX);
            s.orbitAngle  = std::atan2(at.y - centre.y, at.x - centre.x);
            s.orbitTurned = 0.0f;
            s.orbitDir    = urand(0, 1) ? 1 : -1;
            s.viewHasNext = false;
            BuddyTrace(bot, "view: an object blocks the middle; circling it {} at {:.1f} yards (its reach {:.1f}), round "
                "({:.1f}, {:.1f})", s.orbitDir > 0 ? "anticlockwise" : "clockwise", s.orbitRadius, reach, centre.x, centre.y);
            return true;
        }
        if (sight == BuddySight::Ground)
        {
            static BuddyHillChoice const choices[] = { BuddyHillChoice::NearestMiddle, BuddyHillChoice::InTheWay,
                                                       BuddyHillChoice::NearestBuddy };
            static char const* const names[] = { "the hilltop nearest the middle", "the hill in the way",
                                                 "the high ground nearest her" };
            uint32 pick = urand(0, 2);
            BuddyRoam::Point top;
            if (!BuddyExploreHilltop(bot, owner, areaId, choices[pick], s.area.centre, top))
            {
                BuddyTrace(bot, "view: the ground hides the middle, but {} can't be found or reached", names[pick]);
                return false;
            }
            s.view        = VIEW_CLIMB;
            s.viewStarted = now;
            s.viewGoal    = top;
            s.viewBaseZ   = at.z;
            BuddyTrace(bot, "view: the ground hides the middle; climbing {} at ({:.1f}, {:.1f}, {:.1f}), {:.1f} yards up",
                names[pick], top.x, top.y, top.z, top.z - at.z);
            return true;
        }
        return false;                                   // the look is clear: the pinwheel failed for another reason
    }

    // One step of a climb or a circle; true while it holds the buddy.
    bool View(RoamState& s, Player* owner, uint32 areaId, uint64 now)
    {
        if (now - s.viewStarted > VIEW_GIVE_UP_MS)
        {
            BuddyTrace(bot, "view: given up after {} s", VIEW_GIVE_UP_MS / 1000);
            s.view = VIEW_NONE;
            return false;
        }
        BuddyRoam::Point at { bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ() }, hit;
        bool seen = BuddySightBlocker(bot->GetMap(), bot->GetPhaseMask(), at, s.area.centre, hit) == BuddySight::Clear;

        if (s.view == VIEW_CLIMB)
        {
            float rise = s.viewGoal.z - s.viewBaseZ;
            bool  high = at.z >= s.viewBaseZ + VANTAGE_SHARE * rise;
            if (high && seen)
            {
                BuddyTrace(bot, "view: the middle is in sight from ({:.1f}, {:.1f}, {:.1f}); roaming on from here", at.x, at.y, at.z);
                s.view = VIEW_NONE;
                s.buddy.hasWaypoint = false;
                s.retryAt = 0;
                return false;
            }
            if (bot->GetExactDist2d(s.viewGoal.x, s.viewGoal.y) <= CLIMB_TOP_YARDS)
            {
                BuddyTrace(bot, "view: at the top and still no sight of the middle; given up");
                s.view = VIEW_NONE;
                return false;
            }
            BuddyRoam::Point next;
            if (!BuddyExploreStepToward(bot, owner, areaId, s.viewGoal, CLIMB_STEP_YARDS, next))
            {
                BuddyTrace(bot, "view: lost the way up; given up");
                s.view = VIEW_NONE;
                return false;
            }
            if (!bot->movespline->Finalized())
            {
                G3D::Vector3 end = bot->movespline->FinalDestination();
                if (bot->GetExactDist2d(end.x, end.y) > 2.0f)
                    return true;                        // the last stretch still has some way to go: no new order yet
            }
            if (BuddyTurnToward(bot, std::atan2(next.y - at.y, next.x - at.x)))
                return true;
            MoveTo(bot->GetMapId(), next.x, next.y, next.z, false, false, false, false, MovementPriority::MOVEMENT_WANDER);
            return true;
        }

        // circling: the middle in sight from here means the pinwheel's way
        // out crosses the circle here ("We don't even need to make a full
        // circle if the intended path crosses the orbit circle she's
        // making, then great! Just follow the path.")
        if (seen)
        {
            BuddyTrace(bot, "view: the middle came in sight {:.0f} degrees round; roaming on from here",
                s.orbitTurned * 180.0f / float(M_PI));
            s.view = VIEW_NONE;
            s.buddy.hasWaypoint = false;
            s.retryAt = 0;
            return false;
        }
        if (s.orbitTurned >= 2.0f * float(M_PI))
        {
            // a whole circle: the way toward the middle, cut where it leaves
            // the circle, and a route there
            float dx = s.area.centre.x - s.viewGoal.x, dy = s.area.centre.y - s.viewGoal.y;
            float d  = std::max(0.01f, std::hypot(dx, dy));
            float r  = s.orbitRadius + ORBIT_OUT_YARDS;
            BuddyRoam::Point out { s.viewGoal.x + dx / d * r, s.viewGoal.y + dy / d * r, at.z }, onMesh;
            std::vector<BuddyRoam::Point> route;
            s.view = VIEW_NONE;
            if (BuddyMeshSnap(bot->GetMap(), out, SNAP_WAYPOINT_YARDS, SNAP_RISE_YARDS, onMesh) &&
                BuddyMeshRoute(bot, onMesh, route) == BuddyRouteKind::Complete)
            {
                s.buddy.path        = route;
                s.buddy.pathIndex   = 0;
                s.buddy.waypoint    = onMesh;
                s.buddy.hasWaypoint = true;
                s.checkedLeg = s.watched = s.orderedLeg = SIZE_MAX;
                BuddyTrace(bot, "view: a whole circle without sight; routing out past it to ({:.1f}, {:.1f}, {:.1f})",
                    onMesh.x, onMesh.y, onMesh.z);
            }
            else
                BuddyTrace(bot, "view: a whole circle without sight, and no route out past it; given up");
            return false;
        }
        // the next spot round the circle, once the last is reached (or the
        // buddy stands): ORBIT_STEP_YARDS further, in its own direction
        if (s.viewHasNext && !bot->movespline->Finalized() && bot->GetExactDist2d(s.viewNext.x, s.viewNext.y) > 1.5f)
            return true;
        if (!s.viewHasNext || bot->GetExactDist2d(s.viewNext.x, s.viewNext.y) <= 1.5f)
        {
            float step = ORBIT_STEP_YARDS / std::max(1.0f, s.orbitRadius);
            s.orbitAngle  += float(s.orbitDir) * step;
            s.orbitTurned += step;
            BuddyRoam::Point spot { s.viewGoal.x + std::cos(s.orbitAngle) * s.orbitRadius,
                                    s.viewGoal.y + std::sin(s.orbitAngle) * s.orbitRadius, at.z }, onMesh;
            if (!BuddyMeshSnap(bot->GetMap(), spot, SNAP_POINT_YARDS, SNAP_RISE_YARDS, onMesh))
            {
                s.viewHasNext = false;                  // no floor there: on round to the next spot next tick
                return true;
            }
            s.viewNext    = onMesh;
            s.viewHasNext = true;
        }
        if (BuddyTurnToward(bot, std::atan2(s.viewNext.y - at.y, s.viewNext.x - at.x)))
            return true;
        MoveTo(bot->GetMapId(), s.viewNext.x, s.viewNext.y, s.viewNext.z, false, false, false, false, MovementPriority::MOVEMENT_WANDER);
        return true;
    }
    // }}}

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

    // {{{ the detour
    // Whether the buddy could open this object, were it there: the bot
    // module's own reading of the object (LootObject: a chest with only
    // quest items the buddy doesn't need is skipped; the lock says which
    // skill, skill level or key opens it), then the checks its
    // IsLootPossible makes, all but one. Each test and what failing it means:
    //   a chest-type object        - chests, herb and ore nodes are all of
    //                                this kind; anything else (a door, a
    //                                mailbox, a quest object to use) is not
    //                                a detour
    //   spawned, closed, idle      - not on its respawn timer, not already
    //                                opened, not being opened by someone
    //   selectable, no condition   - the bot module's own skip, e.g. the
    //                                Gunship Armory before its event
    //   the bot module would loot  - its reading found something worth it
    //   the key                    - a locked chest needs its key carried
    //   the skill                  - none needed; never fishing (pools are
    //                                not walked to); known and high enough
    //   the pick                   - mining needs a mining pick, by the
    //                                core's tool-category test rather than
    //                                the bot module's list of pick items
    // Left out on purpose: IsLootPossible's height test (within about 3
    // yards of the buddy's height), meant for an object in arm's reach; a
    // node 40 yards off on a slope would fail it. The bot module applies it
    // itself once the buddy arrives; if it still refuses there, the detour
    // gives up after DETOUR_GIVE_UP_MS.
    bool DetourWorthy(GameObject* go)
    {
        if (go->GetGOInfo()->type != GAMEOBJECT_TYPE_CHEST)
            return false;
        if (!go->isSpawned() || go->GetGoState() != GO_STATE_READY || go->getLootState() != GO_READY)
            return false;
        if (go->HasFlag(GAMEOBJECT_FLAGS, GO_FLAG_INTERACT_COND | GO_FLAG_NOT_SELECTABLE))
            return false;
        if (go->GetSpawnId() && BuddyNodeRetired(go->GetSpawnId()))
            return false;                              // a retired spot still up (no free spot to move it to)
        LootObject loot(bot, go->GetGUID());
        if (loot.IsEmpty())
            return false;
        if (loot.reqItem && !bot->HasItemCount(loot.reqItem, 1))
            return false;
        if (loot.skillId == SKILL_NONE)
            return true;
        if (loot.skillId == SKILL_FISHING || !bot->HasSkill(loot.skillId))
            return false;
        if (bot->GetSkillValue(loot.skillId) < loot.reqSkillValue)
            return false;
        if (loot.skillId == SKILL_MINING && !bot->HasItemTotemCategory(MINING_PICK_TOOL))
            return false;
        return true;
    }

    // Whether the buddy could walk to within NODE_REACH_YARDS of this object,
    // asked of the walking map (the same path search the server's own
    // movement uses) before a step is taken. Only herb and ore nodes are
    // judged; a chest is never moved, so it is always "reachable" here and
    // left to the give-up timer.
    //
    // A trap in the path search, read 2026-10-02 (PathGenerator.cpp,
    // BuildPolyPath): when either end lies off the walking map's ground, a
    // path for a player (not a creature) is answered "straight line, not
    // using the map" rather than "no path", the same answer as on a map with
    // no navigation data at all. So the buddy's own spot is asked first, as
    // a path from itself to itself: if even that is a straight line, the
    // search has nothing to say here; if not, a straight-line answer for the
    // node means the node is off the walkable ground.
    //
    // Each answer and what it brings:
    //   buddy off the map         - no navigation data, or the buddy is
    //                               swimming or not on walkable ground: no
    //                               verdict, the detour goes ahead
    //   cut short by length       - the search's point limit stopped it: no
    //                               verdict, the detour goes ahead
    //   node in water             - a swim may reach it: no verdict
    //   node off the ground       - unreachable (straight-line answer, or the
    //                               end far from any walkable polygon)
    //   no path, or ends short    - unreachable
    //   ends within reach         - reachable: the detour goes ahead
    // Unreachable is handed to the node keeper (buddies_nodes.cpp), which
    // retires the spot and moves the node, and logs it.
    bool NodeReachable(GameObject* go)
    {
        LootObject loot(bot, go->GetGUID());
        if (loot.skillId != SKILL_HERBALISM && loot.skillId != SKILL_MINING)
            return true;
        float gx = go->GetPositionX(), gy = go->GetPositionY(), gz = go->GetPositionZ();

        PathGenerator self(bot);
        self.CalculatePath(bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ(), false);
        if (self.GetPathType() & PATHFIND_NOT_USING_PATH)
            return true;                               // buddy off the map

        PathGenerator path(bot);
        path.CalculatePath(gx, gy, gz, false);
        uint32 type = path.GetPathType();
        if (type & PATHFIND_SHORT)
            return true;                               // cut short by length
        bool offGround = (type & (PATHFIND_NOT_USING_PATH | PATHFIND_FARFROMPOLY_END)) != 0;
        if (offGround && bot->GetMap()->IsInWater(bot->GetPhaseMask(), gx, gy, gz, bot->GetCollisionHeight()))
            return true;                               // node in water
        G3D::Vector3 const& end = path.GetActualEndPosition();
        float shortBy = go->GetExactDist(end.x, end.y, end.z);
        if (!offGround && !(type & PATHFIND_NOPATH) && shortBy <= NODE_REACH_YARDS)
            return true;                               // ends within reach

        std::string what = offGround                ? " (it stands off the walkable ground)"
                         : (type & PATHFIND_NOPATH) ? " (no path at all)"
                         : " (the best path ends " + std::to_string(int(shortBy)) + " yards from it)";
        BuddyRetireNode(uint32(go->GetSpawnId()), bot->GetGUID().GetCounter(),
            "buddy " + bot->GetName() + " found no walking path to " + go->GetName() + what);
        return false;
    }

    // Look for the nearest worthy object among those the bot module already
    // sees (its "nearest game objects", 100 yards, refreshed each second; it
    // doesn't test sight, so this does) that lies past its loot reach and
    // within DETOUR_YARDS, in the owner's area (the roaming stays in it),
    // not tried by this buddy lately, and not claimed by a clanmate. Found:
    // claimed, and the buddy's path becomes the one point. Its old waypoint
    // is dropped rather than kept for later: the pinwheel's bearing and Y
    // are what make the lap, and the next pick goes on from them.
    void StartDetour(RoamState& s, Player* owner, uint32 areaId, uint64 now)
    {
        s.tried.erase(std::remove_if(s.tried.begin(), s.tried.end(),
                                     [now](std::pair<ObjectGuid, uint64> const& t) { return t.second <= now; }),
                      s.tried.end());
        float reach = sPlayerbotAIConfig.lootDistance;
        GameObject* best     = nullptr;
        float       bestDist = DETOUR_YARDS;
        for (ObjectGuid const& g : AI_VALUE(GuidVector, "nearest game objects"))
        {
            GameObject* go = ObjectAccessor::GetGameObject(*bot, g);
            if (!go)
                continue;                              // left the map since the bot module's last look
            float dist = bot->GetDistance(go);
            if (dist <= reach || dist > bestDist)
                continue;                              // the bot module's own reach, or no nearer than the best so far
            if (go->GetAreaId() != areaId || !DetourWorthy(go) || !bot->IsWithinLOSInMap(go))
                continue;
            bool tried = std::any_of(s.tried.begin(), s.tried.end(),
                                     [&g](std::pair<ObjectGuid, uint64> const& t) { return t.first == g; });
            if (tried)
                continue;
            best     = go;
            bestDist = dist;
        }
        if (!best || !ClaimDetour(owner->GetGUID().GetCounter(), best->GetGUID(), bot->GetGUID().GetCounter(), now))
            return;                                    // nothing near, or a clanmate got there first (looked at again next time)
        if (!NodeReachable(best))
        {
            ReleaseDetour(owner->GetGUID().GetCounter(), best->GetGUID(), bot->GetGUID().GetCounter());
            s.tried.push_back({ best->GetGUID(), now + DETOUR_TRIED_MS });
            return;                                    // handed to the node keeper, which moves it; the next look picks anew
        }
        BuddyRoam::Point p { best->GetPositionX(), best->GetPositionY(), best->GetPositionZ() };
        s.detour            = best->GetGUID();
        s.detourStarted     = now;
        s.tried.push_back({ best->GetGUID(), now + DETOUR_TRIED_MS });
        s.buddy.path        = { p };
        s.buddy.pathIndex   = 0;
        s.buddy.waypoint    = p;
        s.buddy.hasWaypoint = true;
        s.justArrived       = false;
        LOG_DEBUG("module", "mod-buddies: buddy {} detours {:.0f} yards to {} (entry {}) in area {}",
            bot->GetName(), bestDist, best->GetName(), best->GetEntry(), areaId);
        BuddyTrace(bot, "roam: detour begun, {:.0f} yards to {} (entry {}) at ({:.1f}, {:.1f}, {:.1f})",
            bestDist, best->GetName(), best->GetEntry(), p.x, p.y, p.z);
    }

    // A detour under way. Its three ends, each letting go of the claim and
    // sending the buddy back to its lap (a fresh waypoint pick, no rest
    // roll):
    //   gone or opened  - the object left the map, or isn't worthy any more
    //                     (looted, on its respawn timer, the skill lost)
    //   too long        - DETOUR_GIVE_UP_MS passed: no path there, or the
    //                     bot module refuses to loot it on arrival (the
    //                     height test above); logged, since the next time
    //                     the buddy passes it it will have been skipped
    //   neither         - still going: true when the buddy is within the
    //                     bot module's loot reach (it holds still and the
    //                     loot action does the rest), false while it still
    //                     has to walk there along the path
    bool TendDetour(RoamState& s, Player* owner, uint64 now)
    {
        GameObject* go = ObjectAccessor::GetGameObject(*bot, s.detour);
        bool gone      = !go || !DetourWorthy(go);
        bool tooLong   = !gone && now - s.detourStarted > DETOUR_GIVE_UP_MS;
        if (!gone && !tooLong)
            return bot->GetDistance(go) <= sPlayerbotAIConfig.lootDistance;
        if (tooLong)
            LOG_WARN("module", "mod-buddies: buddy {} gave up its detour to {} (entry {}) after {} s, {:.1f} yards short "
                "(no path there, or the bot module would not open it here: its height test allows about 3 yards)",
                bot->GetName(), go->GetName(), go->GetEntry(), DETOUR_GIVE_UP_MS / 1000, bot->GetDistance(go));
        BuddyTrace(bot, "roam: detour ended ({})", gone ? "the object is gone or no longer worth opening" : "given up: too long");
        ReleaseDetour(owner->GetGUID().GetCounter(), s.detour, bot->GetGUID().GetCounter());
        s.detour.Clear();
        s.buddy.path.clear();
        s.buddy.pathIndex   = 0;
        s.buddy.hasWaypoint = false;
        s.justArrived       = false;
        return false;
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
            BuddyTrace(bot, "roam: meal begun (eating or drinking), health {}/{}", bot->GetHealth(), bot->GetMaxHealth());
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
        BuddyTrace(bot, "roam: meal begun (sitting it out, no food), health {}/{}", bot->GetHealth(), bot->GetMaxHealth());
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
// In a dungeon, raid or battleground: the bot module's own way of running
// one, which is to follow its leader and fight beside it (its bots don't
// clear a dungeon by themselves; the leader leads the pulls). Seen
// 2026-10-03 in Zul'Farrak: buddies stood at the entrance, because the
// open-country set (no "follow") was left as it was when they went in.
static std::vector<Want> const sInstance = {
    { "follow", true }, { "buddy roam", false }, { "grind", false }, { "loot", true },
    { "buddy travel", false }, { "buddy town", false },
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

    // Each online buddy's peace-time set put on when its kind of place
    // changes (open country, town, instance) or it comes online, and not
    // otherwise: what the owner then types (".. nc -follow", "nc +stay")
    // stays until the buddy next changes place. (Until 2026-10-04 the set
    // was put right every pass, every three seconds, undoing any order the
    // owner gave; owner: "whoa 3 seconds? That seems like a bad design.")
    // In a dungeon, raid or battleground the set is the bot module's own
    // following (sInstance; who goes in is the dungeon draw, 617c3); dead
    // buddies are left alone (the bot module's own dead behaviours bring
    // them back, then this pass takes over again).
    void OnUpdate(uint32 diff) override
    {
        _sinceAggro += diff;
        if (_sinceAggro >= AGGRO_LOOK_MS && BuddiesEnabled())
        {
            _sinceAggro = 0;
            AggroPass();
        }
        _sinceLast += diff;
        if (_sinceLast < PASS_EVERY_MS || !BuddiesEnabled())
            return;
        _sinceLast = 0;
        for (auto const& [buddyGuid, ownerGuid] : BuddyRosterPairs())
        {
            Player* bot = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(buddyGuid));
            if (!bot)
                _placeSetFor.erase(buddyGuid);         // offline: its set is put on again when it is back
            if (!bot || !bot->IsInWorld() || !bot->IsAlive())
                continue;
            PlayerbotAI* ai = GET_PLAYERBOT_AI(bot);
            if (!ai)
                continue;                              // not yet under the bot module (still logging in)
            Player* owner = ai->GetMaster();
            if (!owner || owner->GetGUID().GetCounter() != ownerGuid)
                continue;                              // not driven by its owner (no master yet)
            // inside an instance: follow; else town or country by where the
            // owner stands (a building inside a town counts as the town)
            bool inside = bot->GetMap()->Instanceable();
            bool town   = !inside && BuddyTownArea(owner) != 0;
            std::vector<Want> const& wants = inside ? sInstance : (town ? sTown : sOpenCountry);
            uint8 place = inside ? PLACE_INSIDE : (town ? PLACE_TOWN : PLACE_COUNTRY);
            auto set = _placeSetFor.find(buddyGuid);
            if (set != _placeSetFor.end() && set->second == place)
                continue;                              // set already put on for this place: the owner's orders stand
            _placeSetFor[buddyGuid] = place;
            if (inside && bot->IsWalking())
                bot->SetWalk(false);                   // following runs
            for (Want const& w : wants)
                if (ai->HasStrategy(w.name, BOT_STATE_NON_COMBAT) != w.on)
                    ai->ChangeStrategy(std::string(w.on ? "+" : "-") + w.name, BOT_STATE_NON_COMBAT);
            // Walking and running out of town are set where the moving is
            // ordered: the roam action walks an unmounted buddy, travel
            // runs it, a fight runs it (below).
        }
    }

private:
    // {{{ AggroPass
    // Inside a dungeon or raid: when an owner comes within AGGRO_REACH times
    // a monster's aggro radius for the owner (a little before it would
    // notice them), every buddy of that owner inside and not fighting goes
    // at that monster: melee runs in, casters move into range and cast (the
    // bot module's fighting does the moving once the target is set). The
    // owner, 2026-10-04: "walks into range and attacks / spellcasts when
    // the player is at 110% aggro range of the monster." The nearest such
    // monster to the owner is taken. Each filter, and what failing it means:
    //   a creature, nobody's pet     - players, buddies and pets are no prey
    //   alive, not already fighting  - a fight already on is the bot
    //                                  module's (it attacks what attacks the
    //                                  group)
    //   not a critter or civilian,
    //   not immune to players        - these never start a fight
    //   hostile and aggressive       - only these attack on sight; a neutral
    //                                  one is left for the owner to pull
    //   in the owner's line of sight - nothing behind a wall
    // Otherwise nothing is done and the buddies follow (sInstance).
    void AggroPass()
    {
        std::map<uint32, Creature*> targetOf;          // owner -> the monster their buddies go at (nullptr: none)
        for (auto const& [buddyGuid, ownerGuid] : BuddyRosterPairs())
        {
            Player* bot = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(buddyGuid));
            if (!bot || !bot->IsInWorld() || !bot->IsAlive() || bot->IsInCombat() || !bot->GetMap()->IsDungeon())
                continue;                              // outside, dead, or already fighting
            PlayerbotAI* ai = GET_PLAYERBOT_AI(bot);
            Player* owner = ai ? ai->GetMaster() : nullptr;
            if (!owner || owner->GetGUID().GetCounter() != ownerGuid || owner->GetMap() != bot->GetMap())
                continue;                              // still logging in, or the owner is elsewhere
            auto known = targetOf.find(ownerGuid);
            Creature* target = known != targetOf.end() ? known->second : (targetOf[ownerGuid] = ThreatNearOwner(owner));
            if (!target)
                continue;
            bool melee = ai->IsMelee(bot);
            bot->SetSelection(target->GetGUID());
            ai->GetAiObjectContext()->GetValue<Unit*>("current target")->Set(target);
            ai->ChangeEngine(BOT_STATE_COMBAT);
            bot->Attack(target, melee);
            if (melee)
                bot->GetMotionMaster()->MoveChase(target);
            BuddyTrace(bot, "inside: {} came within {:.1f} yards of {} (its aggro radius for them {:.1f}, reach x{:.1f}); going at it",
                owner->GetName(), owner->GetExactDist(target), target->GetName(), target->GetAggroRange(owner), AGGRO_REACH);
        }
    }

    // The nearest monster to `owner` that would attack them on sight and
    // that they are within AGGRO_REACH times its aggro radius of; nullptr
    // when none (the filters are AggroPass's).
    Creature* ThreatNearOwner(Player* owner)
    {
        std::list<Unit*> units;
        Acore::AnyUnitInObjectRangeCheck check(owner, AGGRO_SEARCH_YARDS);
        Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> searcher(owner, units, check);
        Cell::VisitObjects(owner, searcher, AGGRO_SEARCH_YARDS);
        Creature* best = nullptr;
        float bestDist = 0.0f;
        for (Unit* u : units)
        {
            Creature* c = u->ToCreature();
            if (!c || !c->GetCharmerOrOwnerGUID().IsEmpty() || !c->IsAlive() || c->IsInCombat())
                continue;
            if (c->IsCritter() || c->IsCivilian() || c->IsImmuneToPC())
                continue;
            if (!c->IsHostileTo(owner) || !c->HasReactState(REACT_AGGRESSIVE))
                continue;
            float aggro = c->GetAggroRange(owner);
            if (aggro <= 0.0f)
                continue;                              // the server has aggro switched off (rate 0)
            float d = owner->GetExactDist(c);
            if (d > aggro * AGGRO_REACH || (best && d >= bestDist) || !owner->IsWithinLOSInMap(c))
                continue;
            best = c;
            bestDist = d;
        }
        return best;
    }
    // }}}

    uint32 _sinceLast  = 0;
    uint32 _sinceAggro = 0;
    // buddy guid -> the kind of place its set was last put on for
    static constexpr uint8 PLACE_COUNTRY = 0, PLACE_TOWN = 1, PLACE_INSIDE = 2;
    std::map<uint32, uint8> _placeSetFor;
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
        if (BuddyIsNotAPlayer(player->GetSession()->GetAccountId()))
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
