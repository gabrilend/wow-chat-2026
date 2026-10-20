
#include "buddies.h"
#include "buddies_crossing.h"
#include "buddies_recorder.h"
#include "buddies_town.h"
#include "DBCStores.h"
#include "GameObject.h"
#include "GameTime.h"
#include "Log.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Opcodes.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "SpellMgr.h"
#include "Transport.h"
#include "TravelNode.h"
#include "World.h"
#include "WorldConfig.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <cmath>
#include <mutex>
#include <set>
#include <string>
#include <unordered_map>
#include <vector>

static constexpr uint32 OWNER_LOOK_MS        = 500;
static constexpr float  DOCK_REACH_YARDS     = 60.0f;
static constexpr float  DOCKED_YARDS         = 8.0f;
static constexpr float  AT_SPOT_YARDS        = 4.0f;
static constexpr float  DECK_WALK_YARDS      = 40.0f;
static constexpr float  DECK_YARDS           = 2.0f;
static constexpr float  LANDED_YARDS         = 2.0f;
static constexpr float  PIER_NODE_YARDS      = 80.0f;
static constexpr uint32 MISSED_SAILINGS      = 3;
static constexpr uint32 FAIL_PAUSE_MS        = 60000;
static constexpr uint32 STEP_OFF_MS          = 20000;
static constexpr uint32 RUNE_OF_TELEPORTATION = 17031;
static constexpr float  STOP_NEAR_YARDS      = 80.0f;
static constexpr float  DOCK_NEAR_YARDS      = 60.0f;
static constexpr float  DOCK_LEAVE_YARDS     = 90.0f;
static constexpr float  WAIT_NEAR_OWNER_YARDS = 6.0f;
static constexpr uint32 BEAT_MIN_MS          = 1000;
static constexpr uint32 BEAT_MAX_MS          = 3000;
static constexpr float  JUMP_NEAR_YARDS      = 40.0f;
static constexpr uint32 JUMP_FOLLOW_MS       = 30000;
static constexpr float  JUMP_OUT_YARDS       = 8.0f;
static constexpr float  JUMP_HOP_SPEED       = 4.0f;
static constexpr float  FALL_GRAVITY         = 19.2911f;
static constexpr float  JUMP_MIN_SECONDS     = 0.6f;
static constexpr float  FALL_SEARCH_YARDS    = 1000.0f;
static constexpr uint32 MAP_SCARLET_ENCLAVE  = 609;
static constexpr uint32 AREA_EBON_HOLD_MAP0  = 4281;
static constexpr float  ENCLAVE_EXIT_X       = 2340.8f;
static constexpr float  ENCLAVE_EXIT_Y       = -5678.0f;
static constexpr float  ENCLAVE_EXIT_Z       = 154.1f;
static constexpr float  ENCLAVE_BESIDE_YARDS = 4.0f;

static constexpr float  LANDING_BEARINGS[]   = { 0.0f, 0.5236f, -0.5236f, 1.0472f, -1.0472f };
static constexpr float  LANDING_YARDS[]      = { 8.0f, 14.0f, 20.0f, 26.0f, 32.0f };

static constexpr float  FALL_DMG_SLOPE       = 0.018f;
static constexpr float  FALL_DMG_INTERCEPT   = -0.2426f;
static constexpr float  MIN_FALL_DMG_DIST    = 13.48f;
static constexpr uint32 SPELL_GUST_OF_WIND   = 43621;
static constexpr uint32 SPELL_DIVINE_PROTECTION = 498;

static constexpr uint32 MAGE_TELEPORTS[] = {
    3561,
    3562,
    3565,
    32271,
    49359,
    33690,
    3567,
    3563,
    3566,
    32272,
    49358,
    35715,
};

static std::mutex sCrossLock;
static uint64 Now() { return uint64(GameTime::GetGameTimeMS().count()); }

struct Spot
{
    uint32 mapId = 0;
    float  x = 0.0f, y = 0.0f, z = 0.0f;
};

struct DeckSpot
{
    float x = 0.0f, y = 0.0f, z = 0.0f, o = 0.0f;
};

struct OwnerTrack
{
    uint32   sinceLook = 0;
    bool     haveGround = false;
    Spot     ground;
    bool     aboard = false;
    uint32   entry = 0;
    ObjectGuid ship;
    Spot     boardedFrom;
    DeckSpot deck;
};

struct OwnerWaiting
{
    uint32   stamp = 0;
    uint32   mapId = 0;
    Spot     spot;
    uint32   entry = 0;
    Spot     departure;
    DeckSpot deck;
};

enum class Means : uint8 { Transport, Portal };

struct OwnerCrossing
{
    Means    means = Means::Transport;
    uint32   fromMap = 0;
    uint32   toMap = 0;
    uint32   stamp = 0;
    uint32   entry = 0;
    Spot     departure;
    DeckSpot deck;
    uint32   triggerId = 0;
    bool     landed = false;
    Spot     landing;
};

static std::unordered_map<uint32, OwnerTrack>    sTrack;
static std::unordered_map<uint32, OwnerCrossing> sCrossing;
static std::unordered_map<uint32, DeckSpot>      sDeckSeen;
static std::unordered_map<uint32, OwnerWaiting>  sWaiting;

struct OwnerJump
{
    ObjectGuid ship;
    uint32     stamp = 0;
    uint64     at = 0;
};
static std::unordered_map<uint32, OwnerJump>     sJumped;
static uint32 sStamp = 0;

enum class Way : uint8 { None, Teleport, Portal, Transport, SameShip, EnclaveExit };

struct BuddyTrip
{
    Way         way = Way::None;
    uint32      ownerStamp = 0;
    uint32      toMap = 0;
    uint32      spell = 0;
    bool        cast = false;
    uint32      triggerId = 0;
    uint32      entry = 0;
    Spot        departure;
    DeckSpot    deck;
    bool        sawDocked = false;
    uint32      missed = 0;
    bool        steppingOff = false;
    Spot        ashore;
    uint64      steppedOffAt = 0;
    uint64      pausedUntil = 0;
    std::set<uint32> spellsFailed;
    bool        embarkPicked = false;
    bool        recorded = false;
    BuddyBoardingStart waitAt;
    bool        replaying = false;
    bool        disembarking = false;
    ObjectGuid  replayShip;
    BuddyReplay replay;
    uint32      beatFor = 0;
    uint64      beatUntil = 0;
    bool        dockPicked = false;
    uint32      dockEntry = 0;
    uint8       dockStop = 0;
    bool        dockRecorded = false;
    uint32      jumpStamp = 0;
    uint64      jumpAt = 0;
    uint64      jumpingUntil = 0;
    float       jumpFromZ = 0.0f;
    bool        jumpIntoWater = false;
    bool        rideOnLogged = false;
};

static std::unordered_map<uint32, BuddyTrip> sTrip;

static float Dist(Player* p, float x, float y, float z)
{
    return p->GetExactDist(x, y, z);
}

static std::string Where(Player* p)
{
    char buf[96];
    std::snprintf(buf, sizeof(buf), "map %u (%.0f, %.0f, %.0f), area %u",
        p->GetMapId(), p->GetPositionX(), p->GetPositionY(), p->GetPositionZ(), p->GetAreaId());
    return buf;
}

static bool IsInstanceMap(uint32 mapId)
{
    MapEntry const* entry = sMapStore.LookupEntry(mapId);
    return !entry || entry->Instanceable();
}

static MotionTransport* TransportNear(Player* bot, uint32 entry, Spot const& near)
{
    MotionTransport* best = nullptr;
    float bestDist = DOCK_REACH_YARDS;
    for (Transport* t : bot->GetMap()->GetAllTransports())
    {
        MotionTransport* mt = t->ToMotionTransport();
        if (!mt || mt->GetEntry() != entry)
            continue;
        float d = mt->GetExactDist(near.x, near.y, near.z);
        if (d <= bestDist)
        {
            best = mt;
            bestDist = d;
        }
    }
    return best;
}

static bool PierOf(Spot const& stop, Spot& pier)
{
    WorldPosition pos(stop.mapId, stop.x, stop.y, stop.z);
    for (TravelNode* node : TravelNodeMap::instance().getNodes(pos, PIER_NODE_YARDS))
    {
        if (node->isTransport() || !node->isWalking())
            continue;
        pier = { node->getMapId(), node->getX(), node->getY(), node->getZ() };
        return true;
    }
    return false;
}

struct TransportRoute
{
    uint32            entry = 0;
    std::vector<Spot> stops;
};

static std::vector<TransportRoute> const& Routes()
{
    static std::vector<TransportRoute> routes;
    static std::once_flag built;
    std::call_once(built, []
    {
        for (auto const& [entry, tmpl] : *sObjectMgr->GetGameObjectTemplates())
        {
            if (tmpl.type != GAMEOBJECT_TYPE_MO_TRANSPORT)
                continue;
            uint32 pathId = tmpl.moTransport.taxiPathId;
            if (pathId >= sTaxiPathNodesByPath.size())
                continue;
            TransportRoute route;
            route.entry = entry;
            for (TaxiPathNodeEntry const* node : sTaxiPathNodesByPath[pathId])
                if (node->delay > 0)
                    route.stops.push_back({ node->mapid, node->x, node->y, node->z });
            if (!route.stops.empty())
                routes.push_back(route);
        }
        LOG_INFO("module", "mod-buddies: {} boat and zeppelin routes read for crossings (617e8)", routes.size());
    });
    return routes;
}

static bool Docked(MotionTransport* mt)
{
    for (TransportRoute const& route : Routes())
    {
        if (route.entry != mt->GetEntry())
            continue;
        for (Spot const& stop : route.stops)
            if (stop.mapId == mt->GetMapId() && mt->GetExactDist2d(stop.x, stop.y) <= DOCKED_YARDS)
                return true;
        return false;
    }
    return false;
}

static float NearestStopDist(uint32 mapId, float x, float y)
{
    float best = 1.0e9f;
    for (TransportRoute const& route : Routes())
        for (Spot const& s : route.stops)
            if (s.mapId == mapId)
                best = std::min(best, std::hypot(s.x - x, s.y - y));
    return best;
}

static TransportRoute const* RouteOf(uint32 entry)
{
    for (TransportRoute const& route : Routes())
        if (route.entry == entry)
            return &route;
    return nullptr;
}

static bool NearestStop(uint32 mapId, float x, float y, float reach, uint32& entry, uint8& stop)
{
    float best  = reach;
    bool  found = false;
    for (TransportRoute const& route : Routes())
        for (uint32 i = 0; i < route.stops.size(); ++i)
        {
            Spot const& s = route.stops[i];
            float d = std::hypot(s.x - x, s.y - y);
            if (s.mapId == mapId && d <= best)
            {
                best  = d;
                entry = route.entry;
                stop  = uint8(i);
                found = true;
            }
        }
    return found;
}

static float StopSeparation(uint32 entry, uint8 stop)
{
    Spot const& at   = RouteOf(entry)->stops[stop];
    float       best = 0.0f;
    for (TransportRoute const& route : Routes())
    {
        if (route.entry == entry)
            continue;
        for (Spot const& s : route.stops)
        {
            float d = std::hypot(s.x - at.x, s.y - at.y);
            if (s.mapId == at.mapId && d <= DOCK_NEAR_YARDS && (best == 0.0f || d < best))
                best = d;
        }
    }
    return best;
}

static bool InBeat(BuddyTrip& trip, uint32 key)
{
    if (trip.beatFor != key)
    {
        trip.beatFor   = key;
        trip.beatUntil = Now() + urand(BEAT_MIN_MS, BEAT_MAX_MS);
    }
    return Now() < trip.beatUntil;
}

bool BuddyTransportStop(uint32 entry, uint32 mapId, float x, float y, float reach, uint8& stop)
{
    for (TransportRoute const& route : Routes())
    {
        if (route.entry != entry)
            continue;
        float best = reach;
        bool  found = false;
        for (uint32 i = 0; i < route.stops.size(); ++i)
        {
            Spot const& s = route.stops[i];
            float d = std::hypot(s.x - x, s.y - y);
            if (s.mapId == mapId && d <= best)
            {
                best  = d;
                stop  = uint8(i);
                found = true;
            }
        }
        return found;
    }
    return false;
}

bool BuddyTransportStopSpot(uint32 entry, uint8 stop, uint32& mapId, float& x, float& y, float& z)
{
    for (TransportRoute const& route : Routes())
    {
        if (route.entry != entry)
            continue;
        if (stop >= route.stops.size())
            return false;
        Spot const& s = route.stops[stop];
        mapId = s.mapId; x = s.x; y = s.y; z = s.z;
        return true;
    }
    return false;
}

static void Fail(Player* bot, Player* owner, BuddyTrip& trip, std::string const& what, std::string const& done,
                 std::string const& toDebug)
{
    LOG_ERROR("module",
        "mod-buddies: buddy {} could not follow its owner {} to map {}: {}\n"
        "  done so far: {}\n"
        "  buddy at: {}; owner at: {}\n"
        "  to debug: {}\n"
        "  it waits {} s, then plans the crossing again from the start",
        bot->GetName(), owner->GetName(), owner->GetMapId(), what, done, Where(bot), Where(owner), toDebug,
        FAIL_PAUSE_MS / 1000);
    BuddyBoardingRelease(bot->GetGUID().GetCounter());
    BuddyTrip fresh;
    fresh.pausedUntil = Now() + FAIL_PAUSE_MS;
    trip = fresh;
}

static bool Plan(Player* bot, Player* owner, BuddyTrip& trip)
{
    uint32 toMap  = owner->GetMapId();
    uint32 myMap  = bot->GetMapId();
    uint32 ownerGuid = owner->GetGUID().GetCounter();
    BuddyTrip plan;
    plan.toMap = toMap;
    plan.spellsFailed = trip.spellsFailed;

    if (bot->getClass() == CLASS_MAGE && bot->HasItemCount(RUNE_OF_TELEPORTATION, 1))
    {
        float bestDist = -1.0f;
        for (uint32 spell : MAGE_TELEPORTS)
        {
            if (!bot->HasSpell(spell) || bot->HasSpellCooldown(spell) || plan.spellsFailed.count(spell))
                continue;
            SpellTargetPosition const* dest = sSpellMgr->GetSpellTargetPosition(spell, EFFECT_0);
            if (!dest || dest->target_mapId != toMap)
                continue;
            float d = owner->GetExactDist(dest->target_X, dest->target_Y, dest->target_Z);
            if (bestDist < 0.0f || d < bestDist)
            {
                bestDist = d;
                plan.spell = spell;
            }
        }
        if (plan.spell)
        {
            plan.way = Way::Teleport;
            trip = plan;
            return true;
        }
    }

    auto rec = sCrossing.find(ownerGuid);
    if (rec != sCrossing.end() && rec->second.fromMap == myMap && rec->second.toMap == toMap)
    {
        OwnerCrossing const& c = rec->second;
        plan.ownerStamp = c.stamp;
        if (c.means == Means::Portal)
        {
            plan.way       = Way::Portal;
            plan.triggerId = c.triggerId;
        }
        else
        {
            plan.way       = Way::Transport;
            plan.entry     = c.entry;
            plan.departure = c.departure;
            plan.deck      = c.deck;
        }
        trip = plan;
        return true;
    }

    float bestDist = -1.0f;
    for (auto const& [id, tele] : sObjectMgr->GetAllAreaTriggerTeleports())
    {
        if (tele.target_mapId != toMap)
            continue;
        AreaTrigger const* at = sObjectMgr->GetAreaTrigger(id);
        if (!at || at->map != myMap)
            continue;
        float d = Dist(bot, at->x, at->y, at->z);
        if (bestDist < 0.0f || d < bestDist)
        {
            bestDist = d;
            plan.triggerId = id;
        }
    }
    if (plan.triggerId)
    {
        plan.way = Way::Portal;
        trip = plan;
        return true;
    }

    Spot bestStop;
    for (TransportRoute const& route : Routes())
    {
        bool reaches = false;
        for (Spot const& s : route.stops)
            reaches |= s.mapId == toMap;
        if (!reaches)
            continue;
        for (Spot const& s : route.stops)
        {
            if (s.mapId != myMap)
                continue;
            float d = Dist(bot, s.x, s.y, s.z);
            if (bestDist < 0.0f || d < bestDist)
            {
                bestDist   = d;
                bestStop   = s;
                plan.entry = route.entry;
            }
        }
    }
    if (plan.entry)
    {
        auto deck = sDeckSeen.find(plan.entry);
        if (deck == sDeckSeen.end())
        {
            Fail(bot, owner, trip, "the nearest boat or zeppelin (transport entry " + std::to_string(plan.entry) +
                 ") has never had a player seen aboard it since the server started, so where to stand on its deck is unknown",
                 "no mage teleport, owner record or portal fitted; the transport route was found",
                 "ride that transport once with any character (its deck spot is learned then); or record deck spots at startup");
            return false;
        }
        if (!PierOf(bestStop, plan.departure))
        {
            Fail(bot, owner, trip, "no walking node of the bot module's travel graph lies within " +
                 std::to_string(int(PIER_NODE_YARDS)) + " yards of the transport's stop, so its pier is unknown",
                 "transport entry " + std::to_string(plan.entry) + " chosen as the nearest route to the owner's map",
                 "is the bot module's travel graph loaded (its travel-node tables in the playerbots database)?");
            return false;
        }
        plan.way  = Way::Transport;
        plan.deck = deck->second;
        trip = plan;
        return true;
    }

    if (myMap == MAP_SCARLET_ENCLAVE)
    {
        plan.way = Way::EnclaveExit;
        trip = plan;
        return true;
    }

    Fail(bot, owner, trip, "no way to the owner's map was found",
         "checked: mage teleports (class " + std::to_string(bot->getClass()) + "), the owner's own crossing (none from this map), "
         "portals on this map, boat and zeppelin routes",
         "is the owner's map one no boat, zeppelin or portal reaches from here (Northrend is closed on basic)?");
    return false;
}


static bool StepTeleport(Player* bot, Player* owner, BuddyTrip& trip, BuddyCrossingMove& )
{
    if (bot->IsNonMeleeSpellCast(false))
        return false;
    if (trip.cast)
    {
        LOG_WARN("module", "mod-buddies: buddy {}'s teleport (spell {}) ended without leaving map {}; trying another way",
            bot->GetName(), trip.spell, bot->GetMapId());
        trip.spellsFailed.insert(trip.spell);
        trip.way = Way::None;
        return false;
    }
    if (bot->isMoving())
        bot->StopMoving();
    SpellCastResult result = bot->CastSpell(bot, trip.spell, false);
    if (result != SPELL_CAST_OK)
    {
        LOG_WARN("module", "mod-buddies: buddy {} could not cast teleport spell {} (result {}); trying another way",
            bot->GetName(), trip.spell, uint32(result));
        trip.spellsFailed.insert(trip.spell);
        trip.way = Way::None;
        return false;
    }
    trip.cast = true;
    LOG_INFO("module", "mod-buddies: buddy {} casts teleport spell {} to follow {} to map {}",
        bot->GetName(), trip.spell, owner->GetName(), trip.toMap);
    return false;
}

static bool StepPortal(Player* bot, Player* owner, BuddyTrip& trip, BuddyCrossingMove& move)
{
    AreaTrigger const* at = sObjectMgr->GetAreaTrigger(trip.triggerId);
    if (!at)
    {
        Fail(bot, owner, trip, "area trigger " + std::to_string(trip.triggerId) + " is not in the server's area trigger table",
             "the portal was chosen", "was the area trigger removed (155l removes portals; check its saved table)?");
        return false;
    }
    if (bot->IsInAreaTriggerRadius(at))
    {
        WorldPacket packet(CMSG_AREATRIGGER);
        packet << trip.triggerId;
        packet.rpos(0);
        bot->GetSession()->HandleAreaTriggerOpcode(packet);
        LOG_INFO("module", "mod-buddies: buddy {} steps through area trigger {} after its owner {}",
            bot->GetName(), trip.triggerId, owner->GetName());
        return false;
    }
    move = { at->map, at->x, at->y, at->z, false };
    return true;
}

static bool StepTransport(Player* bot, Player* owner, BuddyTrip& trip, BuddyCrossingMove& move)
{
    MotionTransport* mt = TransportNear(bot, trip.entry, trip.departure);
    bool docked = mt && Docked(mt);

    if (trip.sawDocked && !docked)
    {
        trip.sawDocked = false;
        ++trip.missed;
        LOG_INFO("module", "mod-buddies: buddy {} missed a sailing of transport {} ({} of {})",
            bot->GetName(), trip.entry, trip.missed, MISSED_SAILINGS);
        if (trip.missed >= MISSED_SAILINGS)
        {
            Fail(bot, owner, trip, "transport " + std::to_string(trip.entry) + " left " + std::to_string(MISSED_SAILINGS) +
                 " times without it", "walked to the departure spot and waited",
                 "is the deck spot reachable in a straight walk from the pier (a gangway in the way, the deck too high)?");
            return false;
        }
    }

    if (!trip.embarkPicked)
    {
        trip.embarkPicked = true;
        uint8 stop = 0;
        trip.recorded = BuddyTransportStop(trip.entry, trip.departure.mapId, trip.departure.x, trip.departure.y,
                            STOP_NEAR_YARDS, stop)
                     && BuddyBoardingPick(BUDDY_BOARD_EMBARK, trip.entry, stop, bot, trip.replay, trip.waitAt);
        if (!trip.recorded)
            LOG_WARN("module", "mod-buddies: FALLBACK: no embark recording for transport {} at the dock near ({:.0f}, {:.0f}) "
                "on map {}; buddy {} boards by the straight walk to the deck instead (to fix: record some with "
                ".buddy record start / stop there, 617e9)",
                trip.entry, trip.departure.x, trip.departure.y, trip.departure.mapId, bot->GetName());
    }

    if (trip.recorded)
    {
        float toStart = Dist(bot, trip.waitAt.x, trip.waitAt.y, trip.waitAt.z);
        if (toStart > AT_SPOT_YARDS)
        {
            move = { trip.waitAt.mapId, trip.waitAt.x, trip.waitAt.y, trip.waitAt.z, false };
            return true;
        }
        if (!docked)
        {
            if (bot->isMoving())
                bot->StopMoving();
            bot->SetFacingTo(trip.waitAt.o);
            return false;
        }
        trip.sawDocked    = true;
        trip.replaying    = true;
        trip.disembarking = false;
        trip.replayShip   = mt->GetGUID();
        trip.replay.next  = 0;
        trip.replay.legStarted = 0;
        LOG_INFO("module", "mod-buddies: buddy {} boards transport {} by recording {}", bot->GetName(), trip.entry, trip.replay.id);
        return false;
    }

    float toDepart = Dist(bot, trip.departure.x, trip.departure.y, trip.departure.z);
    if (!docked)
    {
        if (toDepart > AT_SPOT_YARDS)
        {
            move = { trip.departure.mapId, trip.departure.x, trip.departure.y, trip.departure.z, false };
            return true;
        }
        if (bot->isMoving())
            bot->StopMoving();
        return false;
    }

    trip.sawDocked = true;
    float x = trip.deck.x, y = trip.deck.y, z = trip.deck.z, o = trip.deck.o;
    mt->CalculatePassengerPosition(x, y, z, &o);
    float toDeck = Dist(bot, x, y, z);
    if (toDeck <= DECK_YARDS)
    {
        bot->StopMoving();
        mt->AddPassenger(bot, true);
        LOG_INFO("module", "mod-buddies: buddy {} boarded transport {} to follow {} to map {}",
            bot->GetName(), trip.entry, owner->GetName(), trip.toMap);
        return false;
    }
    if (toDeck <= DECK_WALK_YARDS)
    {
        move = { bot->GetMapId(), x, y, z, true };
        return true;
    }
    move = { trip.departure.mapId, trip.departure.x, trip.departure.y, trip.departure.z, false };
    return true;
}

static bool StepSameShip(Player* bot, Player* owner, BuddyTrip& trip, BuddyCrossingMove& move)
{
    auto w = sWaiting.find(owner->GetGUID().GetCounter());
    if (w == sWaiting.end())
    {
        trip.way = Way::None;
        return false;
    }
    OwnerWaiting const& wait = w->second;
    if (InBeat(trip, wait.stamp))
        return false;

    if (!wait.entry)
    {
        if (trip.dockPicked && trip.dockEntry)
        {
            Spot const& picked = RouteOf(trip.dockEntry)->stops[trip.dockStop];
            float       radius = StopSeparation(trip.dockEntry, trip.dockStop);
            uint32 nearEntry = 0;
            uint8  nearStop  = 0;
            if (radius > 0.0f
                && std::hypot(owner->GetPositionX() - picked.x, owner->GetPositionY() - picked.y) > radius
                && NearestStop(owner->GetMapId(), owner->GetPositionX(), owner->GetPositionY(), DOCK_NEAR_YARDS,
                               nearEntry, nearStop)
                && (nearEntry != trip.dockEntry || nearStop != trip.dockStop))
            {
                LOG_INFO("module", "mod-buddies: buddy {} switches from transport {} to transport {}: its owner {} "
                    "moved to that ship's stop", bot->GetName(), trip.dockEntry, nearEntry, owner->GetName());
                trip.dockPicked = false;
            }
        }

        if (!trip.dockPicked)
        {
            trip.dockPicked = true;
            trip.dockEntry  = 0;
            BuddyBoardingRelease(bot->GetGUID().GetCounter());
            if (!NearestStop(owner->GetMapId(), owner->GetPositionX(), owner->GetPositionY(), DOCK_NEAR_YARDS,
                             trip.dockEntry, trip.dockStop))
                trip.dockEntry = 0;

            uint8 myStop = 0;
            if (trip.dockEntry
                && BuddyTransportStop(trip.dockEntry, bot->GetMapId(), bot->GetPositionX(), bot->GetPositionY(),
                                      DOCK_NEAR_YARDS, myStop)
                && myStop != trip.dockStop)
            {
                BuddyTrip plan;
                plan.way       = Way::Transport;
                plan.toMap     = owner->GetMapId();
                plan.entry     = trip.dockEntry;
                plan.departure = { bot->GetMapId(), bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ() };
                auto seen = sDeckSeen.find(trip.dockEntry);
                if (seen != sDeckSeen.end())
                    plan.deck = seen->second;
                plan.beatFor   = trip.beatFor;
                plan.beatUntil = trip.beatUntil;
                LOG_INFO("module", "mod-buddies: buddy {} is at another dock of transport {} than its owner {}; it sails "
                    "to the owner from here", bot->GetName(), trip.dockEntry, owner->GetName());
                trip = plan;
                return StepTransport(bot, owner, trip, move);
            }

            trip.dockRecorded = trip.dockEntry
                && BuddyBoardingPick(BUDDY_BOARD_EMBARK, trip.dockEntry, trip.dockStop, bot, trip.replay, trip.waitAt);
            if (!trip.dockRecorded)
                LOG_WARN("module", "mod-buddies: FALLBACK: no embark recording for {} at the dock {} is waiting at (map {}, "
                    "{:.0f}, {:.0f}); buddy {} waits near its owner instead of on a recording's start (to fix: record some "
                    "with .buddy record start / stop there, 617e9)",
                    trip.dockEntry ? "transport " + std::to_string(trip.dockEntry) : std::string("any ship"),
                    owner->GetName(), wait.mapId, wait.spot.x, wait.spot.y, bot->GetName());
        }

        if (trip.dockRecorded)
        {
            if (Dist(bot, trip.waitAt.x, trip.waitAt.y, trip.waitAt.z) > AT_SPOT_YARDS)
            {
                move = { trip.waitAt.mapId, trip.waitAt.x, trip.waitAt.y, trip.waitAt.z, false };
                return true;
            }
            if (bot->isMoving())
                bot->StopMoving();
            bot->SetFacingTo(trip.waitAt.o);
            return false;
        }
        if (bot->GetExactDist(owner) > WAIT_NEAR_OWNER_YARDS)
        {
            move = { owner->GetMapId(), owner->GetPositionX(), owner->GetPositionY(), owner->GetPositionZ(), false };
            return true;
        }
        if (bot->isMoving())
            bot->StopMoving();
        return false;
    }

    if (trip.entry != wait.entry)
    {
        bool keep = trip.dockRecorded && trip.dockEntry == wait.entry;
        if (!keep)
            BuddyBoardingRelease(bot->GetGUID().GetCounter());
        trip.entry        = wait.entry;
        trip.departure    = wait.departure;
        trip.deck         = wait.deck;
        trip.embarkPicked = keep;
        trip.recorded     = keep;
        trip.sawDocked    = false;
        trip.missed       = 0;
    }
    return StepTransport(bot, owner, trip, move);
}

static bool StepReplay(Player* bot, Player* owner, BuddyTrip& trip)
{
    Transport*       t  = bot->GetMap()->GetTransport(trip.replayShip);
    MotionTransport* mt = t ? t->ToMotionTransport() : nullptr;
    if (!mt)
    {
        Fail(bot, owner, trip, "the ship of the boarding recording it was walking is no longer on this map",
             std::string(trip.disembarking ? "disembark" : "embark") + " recording " + std::to_string(trip.replay.id) +
             " walked to step " + std::to_string(trip.replay.next),
             "did the ship sail or despawn mid-replay? was the buddy teleported?");
        return false;
    }
    if (!trip.disembarking && bot->GetTransport() != mt && !Docked(mt))
    {
        ++trip.missed;
        trip.replaying         = false;
        trip.sawDocked         = false;
        trip.replay.next       = 0;
        trip.replay.legStarted = 0;
        LOG_INFO("module", "mod-buddies: buddy {} missed a sailing of transport {} partway through recording {} ({} of {})",
            bot->GetName(), mt->GetEntry(), trip.replay.id, trip.missed, MISSED_SAILINGS);
        if (trip.missed >= MISSED_SAILINGS)
            Fail(bot, owner, trip, "transport " + std::to_string(mt->GetEntry()) + " left " + std::to_string(MISSED_SAILINGS) +
                 " times before its recording was walked", "waited on the recording's start and began walking it",
                 "is the recording slow (a long approach)? record one that starts nearer the deck");
        return false;
    }

    std::string why;
    switch (BuddyReplayStep(bot, mt, trip.replay, why))
    {
        case BuddyReplayResult::Running:
            return false;
        case BuddyReplayResult::Done:
            trip.replaying = false;
            BuddyBoardingRelease(bot->GetGUID().GetCounter());
            if (trip.disembarking)
            {
                LOG_INFO("module", "mod-buddies: buddy {} stepped off transport {} by recording {} at {}",
                    bot->GetName(), mt->GetEntry(), trip.replay.id, Where(bot));
                trip = BuddyTrip();
                return false;
            }
            if (bot->GetTransport() != mt)
            {
                Fail(bot, owner, trip, "embark recording " + std::to_string(trip.replay.id) + " ended with the buddy not aboard",
                     "walked every step of the recording", "does the recording end on the deck? .buddy record list shows it");
                return false;
            }
            LOG_INFO("module", "mod-buddies: buddy {} boarded transport {} by recording {} to follow {}",
                bot->GetName(), mt->GetEntry(), trip.replay.id, owner->GetName());
            return false;
        case BuddyReplayResult::Failed:
            Fail(bot, owner, trip, "walking boarding recording " + std::to_string(trip.replay.id) + " went wrong: " + why,
                 std::string(trip.disembarking ? "disembark" : "embark") + " walked to step " + std::to_string(trip.replay.next),
                 "is something in the way that wasn't when it was recorded (another ship, a crowd)? does the recording "
                 "look right (.buddy record list)? delete a bad one with .buddy record delete <id>");
            return false;
    }
    return false;
}

static bool StepEnclaveExit(Player* bot, Player* owner, BuddyTrip& trip, BuddyCrossingMove& )
{
    float x = ENCLAVE_EXIT_X, y = ENCLAVE_EXIT_Y, z = ENCLAVE_EXIT_Z;
    uint32 mapId = 0;
    bool beside = owner->GetMapId() == 0 && owner->GetAreaId() == AREA_EBON_HOLD_MAP0;
    if (beside)
    {
        float a = frand(0.0f, 2.0f * float(M_PI));
        x = owner->GetPositionX() + std::cos(a) * ENCLAVE_BESIDE_YARDS;
        y = owner->GetPositionY() + std::sin(a) * ENCLAVE_BESIDE_YARDS;
        z = owner->GetPositionZ() + 0.5f;
    }
    if (bot->isMoving())
        bot->StopMoving();
    if (!bot->TeleportTo(mapId, x, y, z, bot->GetOrientation()))
    {
        Fail(bot, owner, trip, "the teleport out of the Scarlet Enclave was refused",
             std::string("planned the way out to ") + (beside ? "beside the owner in the Ebon Hold" : "the ground under the Ebon Hold"),
             "is the buddy dead, in combat, or mid-teleport already?");
        return false;
    }
    LOG_INFO("module", "mod-buddies: buddy {} left the Scarlet Enclave after its owner {}, to {}",
        bot->GetName(), owner->GetName(), beside ? "beside them in the Ebon Hold" : "the ground under the Ebon Hold");
    trip.way = Way::None;
    return false;
}

typedef bool (*WayStep)(Player*, Player*, BuddyTrip&, BuddyCrossingMove&);
static WayStep const WAY_STEPS[] = {
    nullptr,
    StepTeleport,
    StepPortal,
    StepTransport,
    StepSameShip,
    StepEnclaveExit,
};

static uint32 FallDamage(Player* bot, float drop)
{
    if (drop < MIN_FALL_DMG_DIST || bot->isDead() || bot->IsGameMaster() || bot->GetCommandStatus(CHEAT_GOD)
        || bot->HasHoverAura() || bot->HasFeatherFallAura() || bot->HasFlyAura())
        return 0;
    int32 safeFall = bot->GetTotalAuraModifier(SPELL_AURA_SAFE_FALL);
    float share    = FALL_DMG_SLOPE * (drop - safeFall) + FALL_DMG_INTERCEPT;
    if (share <= 0.0f || bot->IsImmunedToDamageOrSchool(SPELL_SCHOOL_MASK_NORMAL))
        return 0;
    uint32 damage = uint32(share * bot->GetMaxHealth() * sWorld->getRate(RATE_DAMAGE_FALL));
    damage = std::min(damage, bot->GetMaxHealth());
    if (bot->HasAura(SPELL_GUST_OF_WIND))
        damage = bot->GetMaxHealth() / 2;
    if (bot->HasAura(SPELL_DIVINE_PROTECTION))
        damage /= 2;
    return damage;
}

struct Landing
{
    float  x = 0.0f, y = 0.0f, z = 0.0f;
    float  drop = 0.0f;
    bool   water = false;
    uint32 damage = 0;
};

static bool PickLanding(Player* bot, Player* owner, Landing& out, uint32& unknown, uint32& gentlestDeadly)
{
    Map*  map    = bot->GetMap();
    float fromX  = bot->GetPositionX(), fromY = bot->GetPositionY(), fromZ = bot->GetPositionZ();
    float toward = bot->GetAngle(owner);
    float run    = bot->GetSpeed(MOVE_RUN);
    bool  found  = false;
    unknown = gentlestDeadly = 0;

    for (float turn : LANDING_BEARINGS)
        for (float yards : LANDING_YARDS)
        {
            Landing c;
            c.x = fromX + std::cos(toward + turn) * yards;
            c.y = fromY + std::sin(toward + turn) * yards;
            float ground = map->GetHeight(bot->GetPhaseMask(), c.x, c.y, fromZ, true, FALL_SEARCH_YARDS);
            if (ground <= INVALID_HEIGHT || ground >= fromZ)
            {
                ++unknown;
                continue;
            }
            LiquidData const liquid = map->GetLiquidData(bot->GetPhaseMask(), c.x, c.y, ground, bot->GetCollisionHeight(),
                                                         MAP_LIQUID_TYPE_WATER | MAP_LIQUID_TYPE_OCEAN);
            c.water  = liquid.Level > ground && liquid.Level < fromZ && map->HasEnoughWater(bot, c.x, c.y, ground);
            c.z      = c.water ? liquid.Level : ground;
            c.drop   = fromZ - c.z;
            float secs = std::max(JUMP_MIN_SECONDS, std::sqrt(2.0f * c.drop / FALL_GRAVITY));
            if (yards > JUMP_OUT_YARDS + run * secs)
                continue;
            if (c.water)
            {
                out = c;
                return true;
            }
            c.damage = FallDamage(bot, fromZ - ground);
            if (c.damage >= bot->GetHealth())
            {
                if (!gentlestDeadly || c.damage < gentlestDeadly)
                    gentlestDeadly = c.damage;
                continue;
            }
            if (!found || c.damage < out.damage)
            {
                out   = c;
                found = true;
            }
        }
    return found;
}

static void JumpOff(Player* bot, Player* owner, BuddyTrip& trip, MotionTransport* mt, Landing const& land)
{
    float out  = bot->GetExactDist2d(land.x, land.y);
    float secs = std::max(JUMP_MIN_SECONDS, std::sqrt(2.0f * land.drop / FALL_GRAVITY));
    float path = std::hypot(out, land.drop);
    trip.jumpFromZ     = bot->GetPositionZ();
    trip.jumpIntoWater = land.water;
    mt->RemovePassenger(bot, true);
    bot->GetMotionMaster()->MoveJump(land.x, land.y, land.z, path / secs, JUMP_HOP_SPEED);
    trip.jumpAt       = 0;
    trip.jumpingUntil = Now() + uint64(secs * 1000.0f) + 500;
    LOG_INFO("module", "mod-buddies: buddy {} jumps off transport {} after its owner {}: {:.0f} yards out, {:.0f} down, "
        "into {} ({} damage of {} health, {:.1f} s)", bot->GetName(), mt->GetEntry(), owner->GetName(), out, land.drop,
        land.water ? "deep water" : "ground", land.damage, bot->GetHealth(), secs);
}

static bool StepAboard(Player* bot, Player* owner, BuddyTrip& trip, MotionTransport* mt, BuddyCrossingMove& move)
{
    auto jump = sJumped.find(owner->GetGUID().GetCounter());
    if (jump != sJumped.end() && jump->second.ship == mt->GetGUID() && jump->second.stamp != trip.jumpStamp
        && owner->GetTransport() != mt && Now() - jump->second.at <= JUMP_FOLLOW_MS)
    {
        if (!trip.jumpAt)
            trip.jumpAt = Now() + urand(BEAT_MIN_MS, BEAT_MAX_MS);
        if (Now() < trip.jumpAt)
            return false;
        trip.jumpStamp = jump->second.stamp;
        trip.jumpAt    = 0;
        Landing land;
        uint32  unknown = 0, gentlestDeadly = 0;
        if (PickLanding(bot, owner, land, unknown, gentlestDeadly))
            JumpOff(bot, owner, trip, mt, land);
        else if (unknown == std::size(LANDING_BEARINGS) * std::size(LANDING_YARDS))
            LOG_ERROR("module", "mod-buddies: buddy {} did not jump after its owner {} off transport {}: no ground was "
                "found below any of the {} landing points within {:.0f} yards of {} (search {:.0f} yards down). Stays "
                "aboard and rides round. To debug: are the map and vmap files present for this map (DataDir)? Is the "
                "transport over the map's edge?", bot->GetName(), owner->GetName(), mt->GetEntry(), unknown,
                LANDING_YARDS[std::size(LANDING_YARDS) - 1], Where(bot), FALL_SEARCH_YARDS);
        else
            LOG_INFO("module", "mod-buddies: buddy {} stays aboard transport {} rather than jump after its owner {}: no "
                "deep water within reach, and the gentlest landing would deal {} damage against its {} health ({} of the "
                "landing points had no ground below); it rides round", bot->GetName(), mt->GetEntry(), owner->GetName(),
                gentlestDeadly, bot->GetHealth(), unknown);
        return false;
    }

    if (owner->GetTransport() == mt || !Docked(mt))
    {
        trip.rideOnLogged = false;
        if (bot->isMoving())
            bot->StopMoving();
        return false;
    }

    TransportRoute const* route = RouteOf(mt->GetEntry());
    bool rideOn = false;
    if (route && bot->GetMapId() == owner->GetMapId())
    {
        float here = owner->GetExactDist2d(mt->GetPositionX(), mt->GetPositionY());
        for (Spot const& s : route->stops)
            rideOn |= s.mapId == owner->GetMapId() && owner->GetExactDist2d(s.x, s.y) + DOCKED_YARDS < here;
    }
    else if (route)
        for (Spot const& s : route->stops)
            rideOn |= s.mapId == owner->GetMapId();
    if (rideOn)
    {
        if (!trip.rideOnLogged)
            LOG_INFO("module", "mod-buddies: buddy {} rides transport {} on past this stop ({}): it goes nearer its owner {}",
                bot->GetName(), mt->GetEntry(), Where(bot), owner->GetName());
        trip.rideOnLogged = true;
        if (bot->isMoving())
            bot->StopMoving();
        return false;
    }

    uint8 stop = 0;
    BuddyBoardingStart start;
    bool  atStop = BuddyTransportStop(mt->GetEntry(), mt->GetMapId(), mt->GetPositionX(), mt->GetPositionY(), DOCKED_YARDS, stop);
    if (atStop && BuddyBoardingPick(BUDDY_BOARD_DISEMBARK, mt->GetEntry(), stop, bot, trip.replay, start))
    {
        trip.replaying    = true;
        trip.disembarking = true;
        trip.replayShip   = mt->GetGUID();
        LOG_INFO("module", "mod-buddies: buddy {} steps off transport {} by recording {}", bot->GetName(), mt->GetEntry(),
            trip.replay.id);
        return false;
    }
    LOG_WARN("module", "mod-buddies: FALLBACK: no disembark recording for transport {} at {} on map {}; buddy {} "
        "steps off by the straight walk ashore instead (to fix: record some with .buddy record start / stop aboard, 617e9)",
        mt->GetEntry(), atStop ? "stop " + std::to_string(stop) : std::string("this dock (no route stop found under the ship)"),
        mt->GetMapId(), bot->GetName());

    Spot ashore;
    bool found = false;
    auto rec = sCrossing.find(owner->GetGUID().GetCounter());
    if (rec != sCrossing.end() && rec->second.landed && rec->second.landing.mapId == bot->GetMapId()
        && mt->GetExactDist(rec->second.landing.x, rec->second.landing.y, rec->second.landing.z) <= DOCK_REACH_YARDS)
    {
        ashore = rec->second.landing;
        found = true;
    }
    else if (trip.departure.mapId == bot->GetMapId()
        && mt->GetExactDist(trip.departure.x, trip.departure.y, trip.departure.z) <= DOCK_REACH_YARDS)
    {
        ashore = trip.departure;
        found = true;
    }
    else
    {
        Spot stop = { bot->GetMapId(), mt->GetPositionX(), mt->GetPositionY(), mt->GetPositionZ() };
        found = PierOf(stop, ashore);
    }
    if (!found)
    {
        Fail(bot, owner, trip, "the transport is in, but no spot ashore is known (no owner landing, no departure spot, no "
             "travel-graph pier within " + std::to_string(int(PIER_NODE_YARDS)) + " yards); it stays aboard",
             "boarded and rode to the owner's map",
             "did the owner step off here (a landing is noted then)? is the bot module's travel graph loaded?");
        return false;
    }

    mt->RemovePassenger(bot, true);
    trip.steppingOff  = true;
    trip.ashore       = ashore;
    trip.steppedOffAt = Now();
    LOG_INFO("module", "mod-buddies: buddy {} steps off transport {} at {}", bot->GetName(), mt->GetEntry(), Where(bot));
    move = { ashore.mapId, ashore.x, ashore.y, ashore.z, true };
    return true;
}

bool BuddyCrossingWanted(Player* bot, Player* owner)
{
    if (Transport* t = bot->GetTransport())
        if (t->ToMotionTransport())
            return true;
    bool errand = BuddyTownErrandUnderway(bot->GetGUID().GetCounter());
    std::lock_guard<std::mutex> lock(sCrossLock);
    BuddyTrip& trip = sTrip[bot->GetGUID().GetCounter()];
    if (Now() < trip.jumpingUntil)
        return true;
    if (trip.steppingOff && bot->GetMapId() == trip.ashore.mapId)
        return true;
    if (trip.replaying)
        return true;
    if (owner->GetMapId() == bot->GetMapId())
    {
        bool waiting = sWaiting.count(owner->GetGUID().GetCounter()) && !IsInstanceMap(bot->GetMapId());
        if (!waiting && trip.way == Way::SameShip)
        {
            BuddyBoardingRelease(bot->GetGUID().GetCounter());
            uint64 paused = trip.pausedUntil;
            trip = BuddyTrip();
            trip.pausedUntil = paused;
        }
        return waiting && !errand && Now() >= trip.pausedUntil;
    }
    if (IsInstanceMap(bot->GetMapId()) || IsInstanceMap(owner->GetMapId()))
        return false;
    return Now() >= trip.pausedUntil;
}

bool BuddyCrossingStep(Player* bot, Player* owner, BuddyCrossingMove& move)
{
    std::unique_lock<std::mutex> lock(sCrossLock);
    BuddyTrip& trip = sTrip[bot->GetGUID().GetCounter()];

    if (trip.jumpingUntil)
    {
        if (Now() < trip.jumpingUntil)
            return false;
        uint32 answered  = trip.jumpStamp;
        float  fromZ     = trip.jumpFromZ;
        bool   intoWater = trip.jumpIntoWater;
        trip = BuddyTrip();
        trip.jumpStamp = answered;
        lock.unlock();
        if (!intoWater)
        {
            MovementInfo landed = bot->m_movementInfo;
            landed.pos.Relocate(bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ());
            bot->SetFallInformation(0, fromZ);
            bot->HandleFall(landed);
            bot->RemoveUnitMovementFlag(MOVEMENTFLAG_FALLING | MOVEMENTFLAG_FALLING_FAR);
        }
        return false;
    }

    if (trip.replaying)
        return StepReplay(bot, owner, trip);

    if (Transport* t = bot->GetTransport())
        if (MotionTransport* mt = t->ToMotionTransport())
            return StepAboard(bot, owner, trip, mt, move);

    if (trip.steppingOff)
    {
        float left = Dist(bot, trip.ashore.x, trip.ashore.y, trip.ashore.z);
        if (left <= LANDED_YARDS || Now() - trip.steppedOffAt >= STEP_OFF_MS)
        {
            if (left > LANDED_YARDS)
                LOG_WARN("module", "mod-buddies: buddy {} stepped off its transport but stopped {:.0f} yards short of the "
                    "shore spot after {} s, at {}; the long walk takes over from here",
                    bot->GetName(), left, STEP_OFF_MS / 1000, Where(bot));
            BuddyTrip fresh;
            trip = fresh;
            return false;
        }
        move = { trip.ashore.mapId, trip.ashore.x, trip.ashore.y, trip.ashore.z, true };
        return true;
    }

    auto rec = sCrossing.find(owner->GetGUID().GetCounter());
    bool stale = (trip.way != Way::None && trip.ownerStamp
                  && (rec == sCrossing.end() || rec->second.stamp != trip.ownerStamp))
              || (trip.way != Way::None && trip.toMap != owner->GetMapId());
    if (stale)
    {
        BuddyBoardingRelease(bot->GetGUID().GetCounter());
        trip.way = Way::None;
    }

    if (trip.way == Way::None)
    {
        if (owner->GetMapId() == bot->GetMapId())
        {
            BuddyTrip plan;
            plan.way         = Way::SameShip;
            plan.toMap       = owner->GetMapId();
            plan.pausedUntil = trip.pausedUntil;
            trip = plan;
        }
        else if (!Plan(bot, owner, trip))
            return false;
    }
    return WAY_STEPS[uint8(trip.way)](bot, owner, trip, move);
}

void BuddyCrossingForget(Player* bot)
{
    std::lock_guard<std::mutex> lock(sCrossLock);
    sTrip.erase(bot->GetGUID().GetCounter());
    BuddyBoardingRelease(bot->GetGUID().GetCounter());
}

class buddies_crossing_player : public PlayerScript
{
public:
    buddies_crossing_player() : PlayerScript("buddies_crossing_player",
        { PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_BEFORE_TELEPORT }) { }

    static void NoteWaiting(Player* player, uint32 guid, OwnerTrack const& track, Spot const& here, MotionTransport* ship)
    {
        if (IsInstanceMap(here.mapId))
        {
            sWaiting.erase(guid);
            return;
        }
        auto w = sWaiting.find(guid);
        if (ship)
        {
            if (!Docked(ship) || (w != sWaiting.end() && w->second.entry == ship->GetEntry()))
                return;
            OwnerWaiting wait;
            wait.stamp     = ++sStamp;
            wait.mapId     = here.mapId;
            wait.spot      = track.haveGround ? track.ground : here;
            wait.entry     = ship->GetEntry();
            wait.departure = (track.aboard && track.entry == ship->GetEntry()) ? track.boardedFrom : wait.spot;
            player->m_movementInfo.transport.pos.GetPosition(wait.deck.x, wait.deck.y, wait.deck.z, wait.deck.o);
            sWaiting[guid] = wait;
            LOG_INFO("module", "mod-buddies: {} is aboard transport {} at a dock; its buddies come to sail with it",
                player->GetName(), wait.entry);
            return;
        }
        float d = NearestStopDist(here.mapId, here.x, here.y);
        if (d <= DOCK_NEAR_YARDS)
        {
            if (w != sWaiting.end() && w->second.entry)
            {
                w->second.entry = 0;
                w->second.spot  = here;
                w->second.stamp = ++sStamp;
                return;
            }
            if (w == sWaiting.end())
            {
                OwnerWaiting wait;
                wait.stamp = ++sStamp;
                wait.mapId = here.mapId;
                wait.spot  = here;
                sWaiting[guid] = wait;
                LOG_INFO("module", "mod-buddies: {} is at a dock (map {}, {:.0f}, {:.0f}); its buddies come to it",
                    player->GetName(), here.mapId, here.x, here.y);
            }
            return;
        }
        if (d > DOCK_LEAVE_YARDS && w != sWaiting.end())
        {
            sWaiting.erase(w);
            LOG_INFO("module", "mod-buddies: {} walked away from the dock; its buddies are let go", player->GetName());
        }
    }

    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        if (!BuddiesEnabled() || player->GetSession()->IsHeadless())
            return;
        std::lock_guard<std::mutex> lock(sCrossLock);
        uint32 guid = player->GetGUID().GetCounter();
        OwnerTrack& track = sTrack[guid];
        track.sinceLook += diff;
        if (track.sinceLook < OWNER_LOOK_MS)
            return;
        track.sinceLook = 0;

        Spot here = { player->GetMapId(), player->GetPositionX(), player->GetPositionY(), player->GetPositionZ() };
        Transport* t = player->GetTransport();
        if (t && !t->ToMotionTransport())
            return;

        NoteWaiting(player, guid, track, here, t ? t->ToMotionTransport() : nullptr);

        if (!t)
        {
            if (track.aboard)
            {
                Transport*       left = player->GetMap()->GetTransport(track.ship);
                MotionTransport* lmt  = left ? left->ToMotionTransport() : nullptr;
                if (lmt && !Docked(lmt) && player->GetExactDist(lmt) <= JUMP_NEAR_YARDS)
                {
                    OwnerJump j;
                    j.ship  = track.ship;
                    j.stamp = ++sStamp;
                    j.at    = Now();
                    sJumped[guid] = j;
                    LOG_INFO("module", "mod-buddies: {} jumped off transport {} at {}; its buddies aboard jump after it",
                        player->GetName(), lmt->GetEntry(), Where(player));
                }
            }

            auto rec = sCrossing.find(guid);
            if (track.aboard && rec != sCrossing.end() && rec->second.means == Means::Transport
                && rec->second.toMap == here.mapId && !rec->second.landed)
            {
                rec->second.landed  = true;
                rec->second.landing = here;
            }
            track.aboard     = false;
            track.haveGround = true;
            track.ground     = here;
            return;
        }

        if (track.aboard && track.entry == t->GetEntry())
            return;

        track.aboard = true;
        track.entry  = t->GetEntry();
        track.ship   = t->GetGUID();
        track.boardedFrom = track.haveGround ? track.ground : here;
        player->m_movementInfo.transport.pos.GetPosition(track.deck.x, track.deck.y, track.deck.z, track.deck.o);
        sDeckSeen[track.entry] = track.deck;
    }

    bool OnPlayerBeforeTeleport(Player* player, uint32 mapId, float x, float y, float z, float ,
                                uint32 , Unit* ) override
    {
        if (!BuddiesEnabled() || player->GetSession()->IsHeadless())
            return true;
        uint32 fromMap = player->GetMapId();
        if (mapId == fromMap || IsInstanceMap(mapId) || IsInstanceMap(fromMap))
            return true;

        std::lock_guard<std::mutex> lock(sCrossLock);
        uint32 guid = player->GetGUID().GetCounter();
        sWaiting.erase(guid);
        OwnerCrossing c;
        c.fromMap = fromMap;
        c.toMap   = mapId;
        c.stamp   = ++sStamp;

        Transport* t = player->GetTransport();
        if (t && t->ToMotionTransport())
        {
            OwnerTrack const& track = sTrack[guid];
            if (!track.aboard || track.entry != t->GetEntry() || track.boardedFrom.mapId != fromMap)
            {
                LOG_WARN("module", "mod-buddies: {} crossed to map {} on transport {} but was not seen boarding it; "
                    "buddies will find their own way", player->GetName(), mapId, t->GetEntry());
                sCrossing.erase(guid);
                return true;
            }
            c.means     = Means::Transport;
            c.entry     = t->GetEntry();
            c.departure = track.boardedFrom;
            c.deck      = track.deck;
            sCrossing[guid] = c;
            return true;
        }

        for (auto const& [id, tele] : sObjectMgr->GetAllAreaTriggerTeleports())
        {
            if (tele.target_mapId != mapId || std::fabs(tele.target_X - x) > 1.0f || std::fabs(tele.target_Y - y) > 1.0f
                || std::fabs(tele.target_Z - z) > 1.0f)
                continue;
            AreaTrigger const* at = sObjectMgr->GetAreaTrigger(id);
            if (!at || at->map != fromMap)
                continue;
            c.means     = Means::Portal;
            c.triggerId = id;
            sCrossing[guid] = c;
            return true;
        }

        sCrossing.erase(guid);
        return true;
    }
};

void AddSC_buddies_crossing()
{
    new buddies_crossing_player();
}
