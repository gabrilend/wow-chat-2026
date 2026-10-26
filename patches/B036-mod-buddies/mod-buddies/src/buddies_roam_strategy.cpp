
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

static constexpr float  ROAM_RELEVANCE    = 3.0f;
static constexpr float  LEG_YARDS         = 8.0f;
static constexpr float  REACHED_YARDS     = 2.0f;
static constexpr float  SNAP_WAYPOINT_YARDS = 6.0f;
static constexpr float  SNAP_POINT_YARDS  = 3.0f;
static constexpr float  SNAP_RISE_YARDS   = 6.0f;
static constexpr uint32 MESH_RETRY_MS     = 2000;
static constexpr uint32 STUCK_MS          = 3000;
static constexpr float  PROGRESS_YARDS    = 0.5f;
static constexpr uint32 PREY_LOOK_MS      = 1000;
static constexpr float  EDGE_SLACK_YARDS  = 1.5f;
static constexpr float  EDGE_SNAP_YARDS   = 4.0f;
static constexpr uint32 PREY_SHUN_MS      = 60000;
static constexpr uint32 PREY_GIVE_UP_MS   = 20000;
static constexpr uint32 OPEN_GRACE_MS     = 5000;
static constexpr uint32 NPC_LOOK_MS       = 5000;
static constexpr uint32 NPC_GIVE_UP_MS    = 60000;
static constexpr uint32 NPC_TALK_MIN_MS   = 4000;
static constexpr uint32 NPC_TALK_MAX_MS   = 9000;
static constexpr uint32 NPC_TALK_EVERY_MS = 2000;
static constexpr float  NPC_ARRIVED_YARDS = 1.5f;

static constexpr float  SELL_NEAR_YARDS   = 40.0f;
static constexpr float  SELL_TALK_YARDS   = 4.0f;
static constexpr float  SELL_STRETCH_YARDS = 80.0f;
static constexpr float  SELL_SHORT_YARDS  = 30.0f;
static constexpr uint32 SELL_GIVE_UP_MS   = 180000;
static constexpr uint32 SELL_SHUN_MS      = 600000;
enum : uint8 { VIEW_NONE = 0, VIEW_CLIMB = 1, VIEW_ORBIT = 2 };
static constexpr float  VANTAGE_SHARE     = 0.85f;
static constexpr float  CLIMB_STEP_YARDS  = 6.0f;
static constexpr float  CLIMB_TOP_YARDS   = 3.0f;
static constexpr float  ORBIT_MARGIN_MIN  = 1.15f;
static constexpr float  ORBIT_MARGIN_MAX  = 1.30f;
static constexpr float  ORBIT_STEP_YARDS  = 4.0f;
static constexpr float  ORBIT_OUT_YARDS   = 3.0f;
static constexpr uint32 VIEW_GIVE_UP_MS   = 60000;
static constexpr uint32 RETRY_MS          = 10000;
static constexpr float  OTHERS_YARDS      = 100.0f;
static constexpr float  MIN_BODY_YARDS    = 0.5f;
static constexpr uint32 PASS_EVERY_MS     = 3000;
static constexpr uint32 AGGRO_LOOK_MS     = 500;
static constexpr float  AGGRO_REACH       = 1.1f;
static constexpr float  AGGRO_SEARCH_YARDS = 50.0f;
static constexpr float  MOBS_YARDS        = 60.0f;
static constexpr float  HELP_YARDS        = MOBS_YARDS * 1.3f;
static constexpr uint32 MEAL_MAX_MS       = 120000;
static constexpr uint32 CAMPFIRE_SPELL    = 818;

static constexpr float  DETOUR_YARDS      = 45.0f;
static constexpr uint32 DETOUR_LOOK_MS    = 2000;
static constexpr uint32 DETOUR_GIVE_UP_MS = 30000;
static constexpr uint32 DETOUR_TRIED_MS   = 600000;
static constexpr uint32 MINING_PICK_TOOL  = 165;
static constexpr float  NODE_REACH_YARDS  = 3.0f;

struct RoamState
{
    BuddyRoam::Buddy buddy;
    BuddyRoam::Area  area;
    uint32           mapId      = 0;
    bool             begun      = false;
    bool             noCentre   = false;
    bool             justArrived = false;
    uint64           retryAt    = 0;
    bool             meal       = false;
    bool             sitRest    = false;
    uint64           mealStarted = 0;
    uint32           wellFed    = 0;
    ObjectGuid       detour;
    uint64           detourStarted = 0;
    uint64           nextLook   = 0;
    std::vector<std::pair<ObjectGuid, uint64>> tried;
    size_t           checkedLeg = SIZE_MAX;
    size_t           orderedLeg = SIZE_MAX;
    size_t           watched    = SIZE_MAX;
    float            nearest    = 0.0f;
    uint64           progressAt = 0;
    ObjectGuid       prey;
    uint64           nextPreyLook = 0;
    uint64           nextAim    = 0;
    uint64           preyStarted = 0;
    ObjectGuid       npc;
    uint8            npcUse     = 0;
    BuddyRoam::Point npcSpot;
    uint64           npcStarted = 0, nextNpcLook = 0, talkUntil = 0, nextGesture = 0;
    bool             selling    = false;
    uint32           sellSpawn  = 0;
    uint32           sellEntry  = 0;
    BuddyRoam::Point sellAt;
    uint64           sellStarted = 0;
    std::vector<std::pair<uint32, uint64>> vendorShun;
    ObjectGuid       opened;
    uint64           openedAt   = 0;
    bool             turning    = false;
    bool             aimed      = false;
    std::vector<std::pair<ObjectGuid, uint64>> shunned;
    uint8            view       = VIEW_NONE;
    uint64           viewStarted = 0;
    BuddyRoam::Point viewGoal;
    float            viewBaseZ  = 0.0f;
    BuddyRoam::Point viewNext;
    bool             viewHasNext = false;
    float            orbitRadius = 0.0f;
    float            orbitAngle = 0.0f;
    float            orbitTurned = 0.0f;
    int8             orbitDir   = 1;
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

static std::mutex sNoFoodLock;
static std::set<uint32> sNoFoodLogged;

struct DetourClaim
{
    uint32 buddy = 0;
    uint64 until = 0;
};
static std::mutex sClaimLock;
static std::unordered_map<uint32, std::map<ObjectGuid, DetourClaim>> sClaims;

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
            return;
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

static float BodyWidth(Player* bot)
{
    float width = 2.0f * bot->GetFloatValue(UNIT_FIELD_BOUNDINGRADIUS);
    return width < MIN_BODY_YARDS ? MIN_BODY_YARDS : width;
}

class BuddyRoamStepAction : public MovementAction
{
public:
    BuddyRoamStepAction(PlayerbotAI* botAI) : MovementAction(botAI, "buddy roam step") { }

    bool isUseful() override
    {
        Player* owner = botAI->GetMaster();
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
        if (bot->GetTransport())
            return false;
        if (BuddyTownArea(owner))
            return false;
        if (bot->GetAreaId() != owner->GetAreaId())
            return false;
        uint64 now = uint64(GameTime::GetGameTimeMS().count());
        RoamState s = LoadState(bot->GetGUID().GetCounter());
        return now >= s.retryAt;
    }

    bool Execute(Event ) override
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

        if (!s.begun || s.area.id != areaId || s.mapId != map->GetId())
        {
            BuddyRoam::Area area;
            bool noCentre = !BuddyAreaCentre(map, owner->GetPhaseMask(), areaId,
                                             owner->GetPositionX(), owner->GetPositionY(), owner->GetPositionZ(), area);
            if (noCentre)
            {
                area.id     = areaId;
                area.centre = { owner->GetPositionX(), owner->GetPositionY(), owner->GetPositionZ() };
            }
            if (s.detour)
                ReleaseDetour(owner->GetGUID().GetCounter(), s.detour, guid);
            s = RoamState();
            s.area     = area;
            s.mapId    = map->GetId();
            s.begun    = true;
            s.noCentre = noCentre;
            BuddyRoam::Begin(s.buddy, area, at, rng);
            s.buddy.body = BodyWidth(bot);
        }

        if (s.meal)
        {
            TendMeal(s, now);
            StoreState(guid, s);
            return true;
        }

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

        if (!s.detour && NpcErrand(s, now))
        {
            StoreState(guid, s);
            return true;
        }

        if (!s.detour && SellingTrip(s, now))
        {
            StoreState(guid, s);
            return true;
        }

        if (!s.detour && Approach(s, now))
        {
            StoreState(guid, s);
            return true;
        }

        if (s.view != VIEW_NONE && View(s, owner, areaId, now))
        {
            StoreState(guid, s);
            return true;
        }

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
            std::vector<BuddyRoam::Point> explored;
            bool indoors = s.noCentre || !bot->IsOutdoors();
            bool found   = BuddyExploreNext(bot, owner, areaId, explored,
                                            indoors ? BUDDY_EXPLORE_ROOMS : BUDDY_EXPLORE_PINWHEEL);
            if (!found && indoors)
            {
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
                    found = BuddyExploreNext(bot, owner, areaId, explored, BUDDY_EXPLORE_ROOMS);
                    if (!found && StartView(s, owner, areaId, at, now))
                    {
                        StoreState(guid, s);
                        return true;
                    }
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
            BuddyTrace(bot, "roam: waypoint ({:.1f}, {:.1f}, {:.1f}), {:.1f} yards off, {} path points, chosen by {}",
                s.buddy.waypoint.x, s.buddy.waypoint.y, s.buddy.waypoint.z,
                bot->GetExactDist2d(s.buddy.waypoint.x, s.buddy.waypoint.y), s.buddy.path.size(),
                found ? "the explorer's grid" : "the pinwheel");

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

        auto& path = s.buddy.path;
        for (size_t i = path.size(); i > s.buddy.pathIndex; --i)
            if (bot->GetExactDist2d(path[i - 1].x, path[i - 1].y) <= REACHED_YARDS)
            {
                s.buddy.pathIndex = i;
                break;
            }

        if (s.buddy.pathIndex < path.size())
        {
            float d = bot->GetExactDist2d(path[s.buddy.pathIndex].x, path[s.buddy.pathIndex].y);
            if (s.watched != s.buddy.pathIndex)
            {
                s.watched    = s.buddy.pathIndex;
                s.nearest    = d;
                s.progressAt = now;
            }
            else if (d < s.nearest - PROGRESS_YARDS)
            {
                s.nearest    = d;
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
                    return true;
                }
                s.buddy.hasWaypoint = false;
                s.retryAt = now + MESH_RETRY_MS;
                StoreState(guid, s);
                return false;
            }
        }
        StoreState(guid, s);
        BuddyRoam::Point const& p = path[target];
        bool walk = !bot->IsMounted() && !bot->IsOutdoors();
        if (bot->IsWalking() != walk)
            bot->SetWalk(walk);
        if (target != s.orderedLeg)
        {
            float want = std::atan2(p.y - bot->GetPositionY(), p.x - bot->GetPositionX());
            if (BuddyTurnToward(bot, want))
                return true;
            s.orderedLeg = target;
            StoreState(guid, s);
        }
        bool ordered = MoveTo(map->GetId(), p.x, p.y, p.z, false, false, false, false, MovementPriority::MOVEMENT_WANDER);
        BuddyTrace(bot, "roam: leg to path point {} of {} ({:.1f}, {:.1f}, {:.1f}), {:.1f} yards, {}{}",
            target + 1, path.size(), p.x, p.y, p.z, bot->GetExactDist2d(p.x, p.y),
            ordered ? "ordered" : "not re-ordered", walk ? ", walking" : ", running");
        return ordered || bot->isMoving();
    }

private:
    void EndNpcErrand(RoamState& s)
    {
        BuddyNpcRelease(bot, s.npc);
        s.npc.Clear();
        s.npcUse = 0;
    }

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
        if (bot->GetExactDist2d(s.npcSpot.x, s.npcSpot.y) > NPC_ARRIVED_YARDS)
        {
            if (!bot->movespline->Finalized())
                return true;
            if (BuddyTurnToward(bot, std::atan2(s.npcSpot.y - bot->GetPositionY(), s.npcSpot.x - bot->GetPositionX())))
                return true;
            MoveTo(bot->GetMapId(), s.npcSpot.x, s.npcSpot.y, s.npcSpot.z, false, false, false, false, MovementPriority::MOVEMENT_WANDER);
            return true;
        }
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

    bool SellingTrip(RoamState& s, uint64 now)
    {
        if (!s.selling)
        {
            if (BuddyBagFullness(bot) < BuddyFullBagsShare())
                return false;
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
                return false;
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
            s.buddy.hasWaypoint = false;
            return true;
        }

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

    Creature* HelpNear()
    {
        Player* owner = botAI->GetMaster();
        if (!owner)
            return nullptr;
        uint32 ownerGuid = owner->GetGUID().GetCounter();
        std::vector<Player*> clan;
        clan.push_back(owner);
        for (auto const& [buddy, o] : BuddyRosterPairs())
            if (o == ownerGuid && buddy != bot->GetGUID().GetCounter())
                if (Player* p = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(buddy)))
                    clan.push_back(p);
        Creature* best = nullptr;
        float bestDist = HELP_YARDS + 1.0f;
        for (Player* mate : clan)
        {
            if (!mate->IsInWorld() || mate->GetMapId() != bot->GetMapId() || !mate->IsAlive() || !mate->IsInCombat())
                continue;
            float d = bot->GetExactDist(mate);
            if (d > HELP_YARDS || d >= bestDist)
                continue;
            Unit* foe = mate->GetVictim();
            if (!foe)
                continue;
            Creature* c = foe->ToCreature();
            if (!c || !c->IsAlive() || !bot->IsValidAttackTarget(c))
                continue;
            best = c;
            bestDist = d;
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

    void CheckOpening(RoamState& s, uint64 now)
    {
        if (!s.opened || now - s.openedAt < OPEN_GRACE_MS)
            return;
        ObjectGuid opened = s.opened;
        s.opened.Clear();
        if (bot->IsInCombat())
            return;
        Creature* c = ObjectAccessor::GetCreature(*bot, opened);
        if (c)
            BuddyTrace(bot, "approach: the fight with {} never began in {} s (in sight {}, it sees us {}, friendly {}, alive {})",
                c->GetName(), OPEN_GRACE_MS / 1000, bot->IsWithinLOSInMap(c), bot->CanSeeOrDetect(c), c->IsFriendlyTo(bot), c->IsAlive());
        Shun(s, opened, now, "the fight never began");
    }

    bool Approach(RoamState& s, uint64 now)
    {
        CheckOpening(s, now);
        if (!s.prey && now >= s.nextPreyLook)
        {
            s.nextPreyLook = now + PREY_LOOK_MS;
            if (Creature* foe = HelpNear())
            {
                BuddyTrace(bot, "help: joining a clan-mate's fight with {} ({:.1f} yards off)", foe->GetName(), bot->GetExactDist(foe));
                OpenFight(foe, s, now);
                return true;
            }
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

        float radius = BuddyNoticeRadius(c, bot);
        if (radius <= 0.0f)
            radius = c->GetCombatReach() + bot->GetCombatReach();
        float d = bot->GetExactDist2d(c);

        if (d <= radius + EDGE_SLACK_YARDS)
        {
            if (!s.turning)
            {
                bot->StopMoving();
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
        if (!s.aimed)
        {
            if (BuddyTurnToward(bot, std::atan2(onMesh.y - here.y, onMesh.x - here.x)))
            {
                s.nextAim = 0;
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
        return false;
    }

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
                    return true;
            }
            if (BuddyTurnToward(bot, std::atan2(next.y - at.y, next.x - at.x)))
                return true;
            MoveTo(bot->GetMapId(), next.x, next.y, next.z, false, false, false, false, MovementPriority::MOVEMENT_WANDER);
            return true;
        }

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
                s.viewHasNext = false;
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
                continue;
            mobs.push_back({ { c->GetPositionX(), c->GetPositionY(), c->GetPositionZ() }, aggro });
        }
        return mobs;
    }

    bool DetourWorthy(GameObject* go)
    {
        if (go->GetGOInfo()->type != GAMEOBJECT_TYPE_CHEST)
            return false;
        if (!go->isSpawned() || go->GetGoState() != GO_STATE_READY || go->getLootState() != GO_READY)
            return false;
        if (go->HasFlag(GAMEOBJECT_FLAGS, GO_FLAG_INTERACT_COND | GO_FLAG_NOT_SELECTABLE))
            return false;
        if (go->GetSpawnId() && BuddyNodeRetired(go->GetSpawnId()))
            return false;
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

    bool NodeReachable(GameObject* go)
    {
        LootObject loot(bot, go->GetGUID());
        if (loot.skillId != SKILL_HERBALISM && loot.skillId != SKILL_MINING)
            return true;
        float gx = go->GetPositionX(), gy = go->GetPositionY(), gz = go->GetPositionZ();

        PathGenerator self(bot);
        self.CalculatePath(bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ(), false);
        if (self.GetPathType() & PATHFIND_NOT_USING_PATH)
            return true;

        PathGenerator path(bot);
        path.CalculatePath(gx, gy, gz, false);
        uint32 type = path.GetPathType();
        if (type & PATHFIND_SHORT)
            return true;
        bool offGround = (type & (PATHFIND_NOT_USING_PATH | PATHFIND_FARFROMPOLY_END)) != 0;
        if (offGround && bot->GetMap()->IsInWater(bot->GetPhaseMask(), gx, gy, gz, bot->GetCollisionHeight()))
            return true;
        G3D::Vector3 const& end = path.GetActualEndPosition();
        float shortBy = go->GetExactDist(end.x, end.y, end.z);
        if (!offGround && !(type & PATHFIND_NOPATH) && shortBy <= NODE_REACH_YARDS)
            return true;

        std::string what = offGround                ? " (it stands off the walkable ground)"
                         : (type & PATHFIND_NOPATH) ? " (no path at all)"
                         : " (the best path ends " + std::to_string(int(shortBy)) + " yards from it)";
        BuddyRetireNode(uint32(go->GetSpawnId()), bot->GetGUID().GetCounter(),
            "buddy " + bot->GetName() + " found no walking path to " + go->GetName() + what);
        return false;
    }

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
                continue;
            float dist = bot->GetDistance(go);
            if (dist <= reach || dist > bestDist)
                continue;
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
            return;
        if (!NodeReachable(best))
        {
            ReleaseDetour(owner->GetGUID().GetCounter(), best->GetGUID(), bot->GetGUID().GetCounter());
            s.tried.push_back({ best->GetGUID(), now + DETOUR_TRIED_MS });
            return;
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
        if (bot->HasSpell(CAMPFIRE_SPELL))
            bot->CastSpell(bot, CAMPFIRE_SPELL, false);
        bot->SetStandState(UNIT_STAND_STATE_SIT);
        s.meal = true;
        s.sitRest = true;
        s.mealStarted = now;
        BuddyTrace(bot, "roam: meal begun (sitting it out, no food), health {}/{}", bot->GetHealth(), bot->GetMaxHealth());
    }

    void TendMeal(RoamState& s, uint64 now)
    {
        if (s.sitRest)
        {
            if (HealthFull() && ManaFull())
                s.meal = s.sitRest = false;
            else if (bot->getStandState() != UNIT_STAND_STATE_SIT)
                bot->SetStandState(UNIT_STAND_STATE_SIT);
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
                s.meal = false;
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

class BuddyRoamDueTrigger : public Trigger
{
public:
    BuddyRoamDueTrigger(PlayerbotAI* botAI) : Trigger(botAI, "buddy roam due") { }
    bool IsActive() override { return true; }
};

class BuddyRoamStrategy : public NonCombatStrategy
{
public:
    BuddyRoamStrategy(PlayerbotAI* botAI) : NonCombatStrategy(botAI) { }
    std::string const getName() override { return "buddy roam"; }

    void InitTriggers(std::vector<TriggerNode*>& triggers) override
    {
        triggers.push_back(new TriggerNode("buddy roam due", { NextAction("buddy roam step", ROAM_RELEVANCE) }));
    }
};

class BuddyStrategyContext : public NamedObjectContext<Strategy>
{
public:
    BuddyStrategyContext()
    {
        creators["buddy roam"]   = [](PlayerbotAI* ai) -> Strategy* { return new BuddyRoamStrategy(ai); };
        creators["buddy travel"] = NewBuddyTravelStrategy;
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

struct Want { char const* name; bool on; };
static std::vector<Want> const sOpenCountry = {
    { "follow", false }, { "buddy roam", true }, { "grind", false }, { "food", false }, { "loot", true }, { "gather", true },
    { "buddy travel", true }, { "buddy town", false },
};
static std::vector<Want> const sTown = {
    { "follow", false }, { "buddy roam", false }, { "grind", false }, { "food", false },
    { "buddy travel", true }, { "buddy town", true },
};
static std::vector<Want> const sInstance = {
    { "follow", true }, { "buddy roam", false }, { "grind", false }, { "loot", true },
    { "buddy travel", false }, { "buddy town", false },
};

class buddies_roam_world : public WorldScript
{
public:
    buddies_roam_world() : WorldScript("buddies_roam_world", { WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_UPDATE }) { }

    void OnStartup() override
    {
        RegisterWithPlayerbots();
        LOG_INFO("module", ">> mod-buddies: \"buddy roam\" taught to the bot module (ten classes)");
    }

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
                _placeSetFor.erase(buddyGuid);
            if (!bot || !bot->IsInWorld() || !bot->IsAlive())
                continue;
            PlayerbotAI* ai = GET_PLAYERBOT_AI(bot);
            if (!ai)
                continue;
            Player* owner = ai->GetMaster();
            if (!owner || owner->GetGUID().GetCounter() != ownerGuid)
                continue;
            bool inside = bot->GetMap()->Instanceable();
            bool town   = !inside && BuddyTownArea(owner) != 0;
            std::vector<Want> const& wants = inside ? sInstance : (town ? sTown : sOpenCountry);
            uint8 place = inside ? PLACE_INSIDE : (town ? PLACE_TOWN : PLACE_COUNTRY);
            auto set = _placeSetFor.find(buddyGuid);
            if (set != _placeSetFor.end() && set->second == place)
                continue;
            _placeSetFor[buddyGuid] = place;
            if (inside && bot->IsWalking())
                bot->SetWalk(false);
            for (Want const& w : wants)
                if (ai->HasStrategy(w.name, BOT_STATE_NON_COMBAT) != w.on)
                    ai->ChangeStrategy(std::string(w.on ? "+" : "-") + w.name, BOT_STATE_NON_COMBAT);
        }
    }

private:
    void AggroPass()
    {
        std::map<uint32, Creature*> targetOf;
        for (auto const& [buddyGuid, ownerGuid] : BuddyRosterPairs())
        {
            Player* bot = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(buddyGuid));
            if (!bot || !bot->IsInWorld() || !bot->IsAlive() || bot->IsInCombat() || !bot->GetMap()->IsDungeon())
                continue;
            PlayerbotAI* ai = GET_PLAYERBOT_AI(bot);
            Player* owner = ai ? ai->GetMaster() : nullptr;
            if (!owner || owner->GetGUID().GetCounter() != ownerGuid || owner->GetMap() != bot->GetMap())
                continue;
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
                continue;
            float d = owner->GetExactDist(c);
            if (d > aggro * AGGRO_REACH || (best && d >= bestDist) || !owner->IsWithinLOSInMap(c))
                continue;
            best = c;
            bestDist = d;
        }
        return best;
    }

    uint32 _sinceLast  = 0;
    uint32 _sinceAggro = 0;
    static constexpr uint8 PLACE_COUNTRY = 0, PLACE_TOWN = 1, PLACE_INSIDE = 2;
    std::map<uint32, uint8> _placeSetFor;
};

class buddies_roam_player : public PlayerScript
{
public:
    buddies_roam_player() : PlayerScript("buddies_roam_player", { PLAYERHOOK_ON_PLAYER_ENTER_COMBAT }) { }

    void OnPlayerEnterCombat(Player* player, Unit* ) override
    {
        if (!BuddiesEnabled() || !player->IsWalking())
            return;
        if (BuddyIsNotAPlayer(player->GetSession()->GetAccountId()))
            player->SetWalk(false);
    }
};

void AddSC_buddies_roam_strategy()
{
    new buddies_roam_world();
    new buddies_roam_player();
}
