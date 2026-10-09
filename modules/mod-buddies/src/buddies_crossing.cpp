/*
 * buddies_crossing.cpp - buddies follow their owner off the edge of a map:
 * over the sea by boat or zeppelin, through the Dark Portal (issue 617e8).
 *
 * For a general audience: the server's world is a handful of maps, one per
 * continent (Lordaeron and Azeroth are one, so the Thandol Span is just a
 * road) plus one per instance. A buddy already walks anywhere on its own
 * map (617e4). The owner's design for the rest (617e, 2026-09-25): "The
 * buddy-bot should move toward the mechanism that allowed the distance at
 * their earliest convenience and attempt to rejoin the player."
 *
 * Two halves:
 *   watching owners - every real player's footing is noted twice a second:
 *                     the last ground it stood on, and the boat or zeppelin
 *                     it boarded from there (with where on the deck it
 *                     stood). When it changes map, the means is recorded: the
 *                     transport it was riding, or the portal (an area
 *                     trigger) it stepped through; anything else (a summon,
 *                     a teleport spell, a hearthstone) leaves no record.
 *                     Stepping off on the far side records the landing.
 *   the buddy's trip - asked by "buddy travel" (buddies_town.cpp) whenever
 *                     its owner is on another map, it picks a way:
 *                       1. a mage buddy's own Teleport spell landing on the
 *                          owner's map (Ritz, 2026-10-02: "they can only
 *                          teleport, not create portals" - never a Portal);
 *                       2. the owner's own recorded means, when it left from
 *                          the buddy's map;
 *                       3. the nearest portal on its map leading there;
 *                       4. the nearest boat or zeppelin stop on its map whose
 *                          route reaches the owner's map;
 *                     then walks to it, waits on the dock, steps aboard when
 *                     the transport is in, rides, and steps off at the far
 *                     dock, after which "buddy travel" walks on as usual.
 *
 * The same ship, when possible (Ritz, 2026-10-02: "detect when you are
 * standing at a dock / on a ship / waiting for a zeppelin and move the
 * buddy bot to the same dock? The goal is to get them to take the same ship
 * as you if possible."): an owner near a ship's stop, or aboard a docked
 * ship, is waiting to sail. Its buddies on that map (once any town errand
 * is done, and each after its own 1-3 s beat) go straight to a recording's
 * start at that dock and wait on it; when the owner is aboard, they board
 * that same ship. Walking away from the dock releases them. A ship that
 * sails without them is followed as above; a buddy aboard without its
 * owner rides on to the stop nearest the owner, usually round the route
 * and back. An owner who jumps off a moving ship is jumped after.
 *
 * Boarding walks a recording of the owner's own boarding when that dock has
 * one (buddies_recorder.cpp, 617e9): the buddy stands on a recording's start
 * spot no other buddy holds, waits for the ship, and walks it step by step;
 * stepping off at the far dock walks a disembark recording the same way.
 * Only a stop with no recording falls back to the straight walk below, and
 * says so in the log.
 *
 * Boarding is what a player does - walking onto the deck while the
 * transport is docked, then being carried - not a teleport onto it. The
 * server's transports carry whoever is on their passenger list; a client
 * puts its player there by reporting it stands on the deck, and a bot has
 * no client, so the buddy is put on the list once it has walked onto the
 * deck (the same server call a client's report ends in).
 *
 * Failures are loud: each logs what was done, what wasn't, where the buddy
 * stood, and what to check, then pauses the buddy a minute before it tries
 * again from the start.
 */

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

// {{{ tuning
// First guesses; tuned values are logged in docs/balance-updates.md.
static constexpr uint32 OWNER_LOOK_MS        = 500;     // how often an owner's footing is noted
static constexpr float  DOCK_REACH_YARDS     = 60.0f;   // a transport this near the departure spot is the one it waits for
static constexpr float  DOCKED_YARDS         = 8.0f;    // a transport this near one of its stops is in (see Docked)
static constexpr float  AT_SPOT_YARDS        = 4.0f;    // near enough the departure spot to stand and wait
static constexpr float  DECK_WALK_YARDS      = 40.0f;   // from this near the deck spot it walks straight on (no mesh on a deck)
static constexpr float  DECK_YARDS           = 2.0f;    // near enough the deck spot to be aboard
static constexpr float  LANDED_YARDS         = 2.0f;    // near enough the landing spot to be ashore
static constexpr float  PIER_NODE_YARDS      = 80.0f;   // a walking travel node this near a transport's stop is its pier
static constexpr uint32 MISSED_SAILINGS      = 3;       // transports seen leaving without it before it gives up
static constexpr uint32 FAIL_PAUSE_MS        = 60000;   // a failed crossing waits this long before starting over
static constexpr uint32 STEP_OFF_MS          = 20000;   // stepping off ends by then, ashore or not
static constexpr uint32 RUNE_OF_TELEPORTATION = 17031;  // the reagent of every mage Teleport spell
static constexpr float  STOP_NEAR_YARDS      = 80.0f;   // a dock spot this near a ship's stop belongs to that stop (recordings)
static constexpr float  DOCK_NEAR_YARDS      = 60.0f;   // an owner this near a ship's stop is at its dock (at once: no dwell)
static constexpr float  DOCK_LEAVE_YARDS     = 90.0f;   // an owner this far from every stop has walked away
static constexpr float  WAIT_NEAR_OWNER_YARDS = 6.0f;   // buddies wait this near an owner on a dock with no recording
static constexpr uint32 BEAT_MIN_MS          = 1000;    // each buddy's own pause before it answers the owner's move
static constexpr uint32 BEAT_MAX_MS          = 3000;    // ... (owner: "+/- 1-3 seconds ... seem a bit more natural")
static constexpr float  JUMP_NEAR_YARDS      = 40.0f;   // an owner this near the ship it just left, at sea, jumped off it
static constexpr uint32 JUMP_FOLLOW_MS       = 30000;   // a jump this old is no longer followed
static constexpr float  JUMP_OUT_YARDS       = 8.0f;    // how far out from the rail a buddy jumps, standing
static constexpr float  JUMP_HOP_SPEED       = 4.0f;    // the jump's upward speed (yards/s): a hop over the rail
static constexpr float  FALL_GRAVITY         = 19.2911f; // the client's gravity (yards/s^2), for how long a drop takes
static constexpr float  JUMP_MIN_SECONDS     = 0.6f;    // the shortest jump, even onto a deck-high landing
static constexpr float  FALL_SEARCH_YARDS    = 1000.0f; // how far down the ground is looked for (a zeppelin flies high)

// Where a jump may land (owner, 2026-10-02: "only jump if the fall is
// survivable or they could aim to land in water of a sufficient depth").
// Candidates are tried toward the owner first, then 30 and 60 degrees
// either side, each from near to far. A point is within reach when a
// running jump could carry there: JUMP_OUT_YARDS plus the buddy's run speed
// for as long as that drop takes (a long fall carries a jumper far out).
static constexpr float  LANDING_BEARINGS[]   = { 0.0f, 0.5236f, -0.5236f, 1.0472f, -1.0472f };
static constexpr float  LANDING_YARDS[]      = { 8.0f, 14.0f, 20.0f, 26.0f, 32.0f };

// The server's own fall-damage rule, copied from Player::HandleFall
// (Player.cpp), where these are file-local: damage, as a share of maximum
// health, is SLOPE x (drop - safe fall) + INTERCEPT, nothing under
// MIN_FALL_DMG_DIST, times the world's fall rate (basic: 10x, C004), capped
// at maximum health; Gust of Wind sets it to half, Divine Protection halves
// it. Keep in step with HandleFall if upstream changes it.
static constexpr float  FALL_DMG_SLOPE       = 0.018f;
static constexpr float  FALL_DMG_INTERCEPT   = -0.2426f;
static constexpr float  MIN_FALL_DMG_DIST    = 13.48f;
static constexpr uint32 SPELL_GUST_OF_WIND   = 43621;
static constexpr uint32 SPELL_DIVINE_PROTECTION = 498;

// The mage's Teleport spells (never the Portals: "they can only teleport,
// not create portals"). Where each lands is read from the server's own
// spell-destination table, so only the ids live here. Teleport: Dalaran is
// left out: Northrend is closed on basic (155q).
static constexpr uint32 MAGE_TELEPORTS[] = {
    3561,   // Stormwind
    3562,   // Ironforge
    3565,   // Darnassus
    32271,  // Exodar
    49359,  // Theramore
    33690,  // Shattrath (Alliance)
    3567,   // Orgrimmar
    3563,   // Undercity
    3566,   // Thunder Bluff
    32272,  // Silvermoon
    49358,  // Stonard
    35715,  // Shattrath (Horde)
};
// }}}

// {{{ what is remembered
// Kept under one lock: owners are noted from their own map's thread, buddies
// read from theirs, and maps update in parallel.
static std::mutex sCrossLock;
static uint64 Now() { return uint64(GameTime::GetGameTimeMS().count()); }

struct Spot
{
    uint32 mapId = 0;
    float  x = 0.0f, y = 0.0f, z = 0.0f;
};

// Where on a transport's deck someone stood (offsets from the transport).
struct DeckSpot
{
    float x = 0.0f, y = 0.0f, z = 0.0f, o = 0.0f;
};

// An owner's footing, noted every OWNER_LOOK_MS.
struct OwnerTrack
{
    uint32   sinceLook = 0;
    bool     haveGround = false;
    Spot     ground;                     // the last ground it stood on
    bool     aboard = false;             // on a boat or zeppelin at the last look
    uint32   entry = 0;                  // which one
    ObjectGuid ship;                     // which one, exactly (to tell a jump off it from a step off at a dock)
    Spot     boardedFrom;                // the ground it last stood on before boarding
    DeckSpot deck;                       // where on the deck it stood
};

// An owner waiting to sail from a dock on its map (the same ship, 617e8).
// The ship isn't known until the owner steps aboard one. Every change (on
// the dock, aboard, stepped back off) gets a new stamp: each buddy takes its
// own 1-3 s beat once per stamp before it answers.
struct OwnerWaiting
{
    uint32   stamp = 0;
    uint32   mapId = 0;
    Spot     spot;                       // where the owner stood waiting on the dock
    uint32   entry = 0;                  // the ship it is aboard, once aboard (0: still on the dock)
    Spot     departure;                  // ... the ground it boarded from
    DeckSpot deck;                       // ... where on the deck it stands
};

// How an owner last left a map. Only boats, zeppelins and portals are
// recorded; any other map change (summon, teleport, hearthstone) erases it.
enum class Means : uint8 { Transport, Portal };

struct OwnerCrossing
{
    Means    means = Means::Transport;
    uint32   fromMap = 0;
    uint32   toMap = 0;
    uint32   stamp = 0;                  // a new crossing has a new stamp: buddies plan afresh
    uint32   entry = 0;                  // Transport: which boat or zeppelin
    Spot     departure;                  // Transport: the ground it boarded from
    DeckSpot deck;                       // Transport: where on the deck it stood
    uint32   triggerId = 0;              // Portal: the area trigger it stepped through
    bool     landed = false;             // Transport: stepped off on the far side
    Spot     landing;                    // ... there
};

static std::unordered_map<uint32, OwnerTrack>    sTrack;      // by owner guid (low part)
static std::unordered_map<uint32, OwnerCrossing> sCrossing;   // by owner guid
static std::unordered_map<uint32, DeckSpot>      sDeckSeen;   // by transport entry: a deck spot any player stood on
static std::unordered_map<uint32, OwnerWaiting>  sWaiting;    // by owner guid: waiting to sail from a dock

// An owner who jumped off a moving ship (a zeppelin in the air, a boat at
// sea): its buddies aboard that same ship jump after it (Ritz, 2026-10-02:
// "If you jump off the zeppelin while it's in mid-air or off of the ship into
// the water, they jump with you.").
struct OwnerJump
{
    ObjectGuid ship;                     // the ship jumped from
    uint32     stamp = 0;                // each jump its own: a buddy jumps once per stamp
    uint64     at = 0;                   // game-time ms of the jump
};
static std::unordered_map<uint32, OwnerJump>     sJumped;     // by owner guid
static uint32 sStamp = 0;

// A buddy's own trip. SameShip: the owner waits at a dock on the buddy's
// own map (or is aboard a docked ship there); the buddy goes to it.
enum class Way : uint8 { None, Teleport, Portal, Transport, SameShip };

struct BuddyTrip
{
    Way         way = Way::None;
    uint32      ownerStamp = 0;          // the owner's crossing this plan followed (0: a way of its own)
    uint32      toMap = 0;
    uint32      spell = 0;               // Teleport: the spell
    bool        cast = false;            // Teleport: cast begun
    uint32      triggerId = 0;           // Portal
    uint32      entry = 0;               // Transport
    Spot        departure;               // Transport: where to wait
    DeckSpot    deck;                    // Transport: where to stand aboard
    bool        sawDocked = false;       // Transport: it was in at the last look
    uint32      missed = 0;              // Transport: sailings left without it
    bool        steppingOff = false;     // walking ashore from the deck
    Spot        ashore;                  // ... to here
    uint64      steppedOffAt = 0;
    uint64      pausedUntil = 0;         // after a failure
    std::set<uint32> spellsFailed;       // teleports that failed this trip: not tried again
    // boarding recordings (617e9)
    bool        embarkPicked = false;    // a recording was looked for at this dock (found or not)
    bool        recorded = false;        // ... and one is held: wait at its start, walk it when the ship is in
    BuddyBoardingStart waitAt;           // ... its start spot
    bool        replaying = false;       // walking a recording now
    bool        disembarking = false;    // ... and it is a disembark
    ObjectGuid  replayShip;              // ... the ship it is walked against
    BuddyReplay replay;                  // ... and where in it the buddy is
    // answering the owner (617e8, 2026-10-02)
    uint32      beatFor = 0;             // the owner-waiting stamp the current beat answers
    uint64      beatUntil = 0;           // ... game-time ms the buddy moves once it is over
    bool        dockPicked = false;      // SameShip on the dock: the owner's dock's ship and stop looked up
    uint32      dockEntry = 0;           // ... the ship of the stop nearest the owner (0: none found)
    uint8       dockStop = 0;            // ... which stop of its route
    bool        dockRecorded = false;    // ... and an embark recording there is held (waitAt, replay)
    uint32      jumpStamp = 0;           // the owner's last jump this buddy has answered
    uint64      jumpAt = 0;              // game-time ms it jumps after the owner (0: no jump due)
    uint64      jumpingUntil = 0;        // mid-jump until then: nothing else may move it
    float       jumpFromZ = 0.0f;        // ... the height it jumped from (its fall starts there)
    bool        jumpIntoWater = false;   // ... aimed at water deep enough to break the fall: no damage
    bool        rideOnLogged = false;    // "rides on past this stop" logged for this docking
};

static std::unordered_map<uint32, BuddyTrip> sTrip;           // by buddy guid
// }}}

// {{{ small helpers
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

// Whether a map is an instance (a dungeon, raid or battleground). Instances
// are the dungeon draw's (617c3); crossings are between continents only.
static bool IsInstanceMap(uint32 mapId)
{
    MapEntry const* entry = sMapStore.LookupEntry(mapId);
    return !entry || entry->Instanceable();          // an unknown map is treated as not walkable to
}

// The motion transport with this entry on the buddy's map nearest `near`,
// within DOCK_REACH_YARDS; none when it is out at sea or on another map.
static MotionTransport* TransportNear(Player* bot, uint32 entry, Spot const& near)
{
    MotionTransport* best = nullptr;
    float bestDist = DOCK_REACH_YARDS;
    for (Transport* t : bot->GetMap()->GetAllTransports())
    {
        MotionTransport* mt = t->ToMotionTransport();
        if (!mt || mt->GetEntry() != entry)
            continue;                                // an elevator, or another route's boat
        float d = mt->GetExactDist(near.x, near.y, near.z);
        if (d <= bestDist)
        {
            best = mt;
            bestDist = d;
        }
    }
    return best;
}

// The pier of a transport stop: the nearest walking node of the bot
// module's travel graph within PIER_NODE_YARDS of where the transport
// stands when docked (the stop itself is out on the water).
static bool PierOf(Spot const& stop, Spot& pier)
{
    WorldPosition pos(stop.mapId, stop.x, stop.y, stop.z);
    for (TravelNode* node : TravelNodeMap::instance().getNodes(pos, PIER_NODE_YARDS))
    {
        if (node->isTransport() || !node->isWalking())
            continue;                                // a node on the boat's own route, or one not walked to
        pier = { node->getMapId(), node->getX(), node->getY(), node->getZ() };
        return true;
    }
    return false;
}
// }}}

// {{{ the transport routes
// Every boat and zeppelin, with the spots where it stops (its route's
// points with a wait), read once from the server's transport templates and
// their flight paths - the same reading the bot module's travel graph
// makes of them.
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
                continue;                            // elevators and the rest: not between maps
            uint32 pathId = tmpl.moTransport.taxiPathId;
            if (pathId >= sTaxiPathNodesByPath.size())
                continue;                            // no route in the flight-path data
            TransportRoute route;
            route.entry = entry;
            for (TaxiPathNodeEntry const* node : sTaxiPathNodesByPath[pathId])
                if (node->delay > 0)                 // a wait on the route is a stop
                    route.stops.push_back({ node->mapid, node->x, node->y, node->z });
            if (!route.stops.empty())
                routes.push_back(route);
        }
        LOG_INFO("module", "mod-buddies: {} boat and zeppelin routes read for crossings (617e8)", routes.size());
    });
    return routes;
}

// Whether a transport is in at a stop. The transport's own "moving" flag is
// private to it, so this asks where it is instead: within DOCKED_YARDS of
// one of its route's stops (where its route has it wait) counts as in.
static bool Docked(MotionTransport* mt)
{
    for (TransportRoute const& route : Routes())
    {
        if (route.entry != mt->GetEntry())
            continue;
        for (Spot const& stop : route.stops)
            if (stop.mapId == mt->GetMapId() && mt->GetExactDist2d(stop.x, stop.y) <= DOCKED_YARDS)
                return true;
        return false;                                // its route, and no stop under it: at sea
    }
    return false;                                    // no route read for it: never counted as in
}

// The flat distance from x, y to the nearest stop of any ship on mapId
// (a very large number when none stops on that map).
static float NearestStopDist(uint32 mapId, float x, float y)
{
    float best = 1.0e9f;
    for (TransportRoute const& route : Routes())
        for (Spot const& s : route.stops)
            if (s.mapId == mapId)
                best = std::min(best, std::hypot(s.x - x, s.y - y));
    return best;
}

// A ship's route, by its entry; none when no route was read for it.
static TransportRoute const* RouteOf(uint32 entry)
{
    for (TransportRoute const& route : Routes())
        if (route.entry == entry)
            return &route;
    return nullptr;
}

// The ship and stop nearest x, y on mapId within `reach` (flat), any ship:
// the dock an owner is standing at. False when no stop is that near.
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

// How far this ship's stop lies from the nearest stop of any other ship
// on the same map, within DOCK_NEAR_YARDS (flat): the size of "its own
// patch" of a dock that serves two ships. 0 when no other ship stops that
// near (a dock with one ship: nothing to re-pick between). Measured from
// the route data itself, so each dock gets its own spacing rather than
// one number for every dock (Ritz, 2026-10-02: "the docks are smaller than
// 30 yards. We need to calculate the distance between each dock").
static float StopSeparation(uint32 entry, uint8 stop)
{
    // entry/stop come from NearestStop's reading of Routes(): the route exists
    Spot const& at   = RouteOf(entry)->stops[stop];
    float       best = 0.0f;
    for (TransportRoute const& route : Routes())
    {
        if (route.entry == entry)
            continue;                                // its own other stops are other docks, not this one's neighbour
        for (Spot const& s : route.stops)
        {
            float d = std::hypot(s.x - at.x, s.y - at.y);
            if (s.mapId == at.mapId && d <= DOCK_NEAR_YARDS && (best == 0.0f || d < best))
                best = d;                            // a nearer neighbouring ship's stop at this dock
        }
    }
    return best;
}
// }}}

// {{{ the beat
// Each buddy answers its owner's move after its own 1-3 s, once per move
// (Ritz, 2026-10-02: "No need to wait, although +/- 1-3 seconds could be a
// good way to get them to seem a bit more natural."). True while the beat
// for this move is still running; a new `key` draws a new beat.
static bool InBeat(BuddyTrip& trip, uint32 key)
{
    if (trip.beatFor != key)
    {
        trip.beatFor   = key;
        trip.beatUntil = Now() + urand(BEAT_MIN_MS, BEAT_MAX_MS);
    }
    return Now() < trip.beatUntil;
}
// }}}

// {{{ BuddyTransportStop
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
        return found;                                // its route: a stop within reach, or none
    }
    return false;                                    // no route read for this ship
}
// }}}

// {{{ BuddyTransportStopSpot
bool BuddyTransportStopSpot(uint32 entry, uint8 stop, uint32& mapId, float& x, float& y, float& z)
{
    for (TransportRoute const& route : Routes())
    {
        if (route.entry != entry)
            continue;
        if (stop >= route.stops.size())
            return false;                            // a stop number this route doesn't have (the route data changed?)
        Spot const& s = route.stops[stop];
        mapId = s.mapId; x = s.x; y = s.y; z = s.z;
        return true;
    }
    return false;
}
// }}}

// {{{ failing
// The house error shape: what failed, what had been done, where it stood,
// what to check. The trip is dropped and the buddy paused; it plans afresh
// after the pause.
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
    BuddyBoardingRelease(bot->GetGUID().GetCounter());   // a held boarding recording goes back for others
    BuddyTrip fresh;
    fresh.pausedUntil = Now() + FAIL_PAUSE_MS;
    trip = fresh;
}
// }}}

// {{{ planning
// Choose the buddy's way to the owner's map, in the order at the top of
// the file. Returns false (after Fail) when there is none.
static bool Plan(Player* bot, Player* owner, BuddyTrip& trip)
{
    uint32 toMap  = owner->GetMapId();
    uint32 myMap  = bot->GetMapId();
    uint32 ownerGuid = owner->GetGUID().GetCounter();
    BuddyTrip plan;
    plan.toMap = toMap;
    plan.spellsFailed = trip.spellsFailed;

    // 1. a mage's own Teleport, landing on the owner's map, nearest the owner
    if (bot->getClass() == CLASS_MAGE && bot->HasItemCount(RUNE_OF_TELEPORTATION, 1))
    {
        float bestDist = -1.0f;
        for (uint32 spell : MAGE_TELEPORTS)
        {
            if (!bot->HasSpell(spell) || bot->HasSpellCooldown(spell) || plan.spellsFailed.count(spell))
                continue;                            // not known, cooling down, or already failed this trip
            SpellTargetPosition const* dest = sSpellMgr->GetSpellTargetPosition(spell, EFFECT_0);
            if (!dest || dest->target_mapId != toMap)
                continue;                            // lands elsewhere
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

    // 2. the owner's own means, when it left from this buddy's map
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

    // 3. the nearest portal on this map leading to the owner's
    float bestDist = -1.0f;
    for (auto const& [id, tele] : sObjectMgr->GetAllAreaTriggerTeleports())
    {
        if (tele.target_mapId != toMap)
            continue;                                // leads elsewhere
        AreaTrigger const* at = sObjectMgr->GetAreaTrigger(id);
        if (!at || at->map != myMap)
            continue;                                // not on this map
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

    // 4. the nearest boat or zeppelin stop on this map whose route reaches the owner's
    Spot bestStop;
    for (TransportRoute const& route : Routes())
    {
        bool reaches = false;
        for (Spot const& s : route.stops)
            reaches |= s.mapId == toMap;
        if (!reaches)
            continue;                                // never goes to the owner's map
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

    Fail(bot, owner, trip, "no way to the owner's map was found",
         "checked: mage teleports (class " + std::to_string(bot->getClass()) + "), the owner's own crossing (none from this map), "
         "portals on this map, boat and zeppelin routes",
         "is the owner's map one no boat, zeppelin or portal reaches from here (Northrend is closed on basic)?");
    return false;
}
// }}}

// {{{ the ways
// Each returns what BuddyCrossingStep returns: true with `move` to walk,
// false when handled here. A dispatch table at the end picks by Way.

// {{{ StepTeleport
static bool StepTeleport(Player* bot, Player* owner, BuddyTrip& trip, BuddyCrossingMove& /*move*/)
{
    if (bot->IsNonMeleeSpellCast(false))
        return false;                                // the cast is under way: stand still
    if (trip.cast)
    {
        // cast begun earlier and over, yet still on the old map: interrupted or refused
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
// }}}

// {{{ StepPortal
// Walk into the portal's area trigger; once inside it, step through the way
// the bot module does for its bots (it hands the server the "entered an area
// trigger" message a client would send).
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
// }}}

// {{{ StepTransport
// To the departure spot; wait; when the transport is in, walk straight onto
// the deck spot and be taken aboard; count the sailings that leave without it.
static bool StepTransport(Player* bot, Player* owner, BuddyTrip& trip, BuddyCrossingMove& move)
{
    MotionTransport* mt = TransportNear(bot, trip.entry, trip.departure);
    bool docked = mt && Docked(mt);

    // a sailing left without it
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

    // a boarding recording of this dock, looked for once per trip (617e9)
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

    // with a recording: wait on its start spot, walk it when the ship is in
    if (trip.recorded)
    {
        float toStart = Dist(bot, trip.waitAt.x, trip.waitAt.y, trip.waitAt.z);
        if (toStart > AT_SPOT_YARDS)
        {
            move = { trip.waitAt.mapId, trip.waitAt.x, trip.waitAt.y, trip.waitAt.z, false };
            return true;                             // walk to the recording's start
        }
        if (!docked)
        {
            if (bot->isMoving())
                bot->StopMoving();
            bot->SetFacingTo(trip.waitAt.o);
            return false;                            // wait on the start spot, facing the way the recording began
        }
        trip.sawDocked    = true;
        trip.replaying    = true;
        trip.disembarking = false;
        trip.replayShip   = mt->GetGUID();
        trip.replay.next  = 0;
        trip.replay.legStarted = 0;
        LOG_INFO("module", "mod-buddies: buddy {} boards transport {} by recording {}", bot->GetName(), trip.entry, trip.replay.id);
        return false;                                // the replay walks it from the next step on
    }

    float toDepart = Dist(bot, trip.departure.x, trip.departure.y, trip.departure.z);
    if (!docked)
    {
        if (toDepart > AT_SPOT_YARDS)
        {
            move = { trip.departure.mapId, trip.departure.x, trip.departure.y, trip.departure.z, false };
            return true;                             // walk to the dock
        }
        if (bot->isMoving())
            bot->StopMoving();
        return false;                                // wait standing on the dock (owner, 2026-10-02: "it can just wait at the dock")
    }

    trip.sawDocked = true;
    float x = trip.deck.x, y = trip.deck.y, z = trip.deck.z, o = trip.deck.o;
    mt->CalculatePassengerPosition(x, y, z, &o);     // the deck spot, where it is now
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
        move = { bot->GetMapId(), x, y, z, true };   // across the gangway: no mesh on a deck
        return true;
    }
    move = { trip.departure.mapId, trip.departure.x, trip.departure.y, trip.departure.z, false };
    return true;                                     // still on the way to the dock
}
// }}}

// {{{ StepSameShip
// The owner is on a dock of this map, or aboard a ship docked here. Every
// change of the owner's (arrived, boarded, stepped back) is answered after
// the buddy's own beat. Then:
//   owner on the dock, buddy at another stop of that dock's ship
//                         - an island dock (Auberdine and Rut'theran): no
//                           walk joins them, so it sails from where it is;
//   owner on the dock, a recording there
//                         - straight to an unheld recording start of the
//                           ship whose stop is nearest the owner, and wait
//                           on it facing the way it began (Ritz, 2026-10-02:
//                           "they should move to a starting point as soon as
//                           you enter the dock");
//   owner on the dock, no recording
//                         - wait near the owner (logged FALLBACK, once);
//   owner aboard          - board that same ship (a transport trip from the
//                           owner's boarding spot); a start already held for
//                           that very ship is kept, so the buddy walks the
//                           recording from where it already stands.
static bool StepSameShip(Player* bot, Player* owner, BuddyTrip& trip, BuddyCrossingMove& move)
{
    auto w = sWaiting.find(owner->GetGUID().GetCounter());
    if (w == sWaiting.end())
    {
        trip.way = Way::None;                        // the owner walked away meanwhile: nothing to do
        return false;
    }
    OwnerWaiting const& wait = w->second;
    if (InBeat(trip, wait.stamp))
        return false;                                // its own beat before answering: stays as it is

    if (!wait.entry)
    {
        // A dock can serve two ships (a zeppelin tower's two arms). The pick
        // follows the owner (Ritz, 2026-10-02: "so long as they dynamically
        // re-calculate if you move within a certain radius of the other
        // stop"; then: "calculate the distance between each dock, and use
        // that number as the radius that a player needs to leave before the
        // buddy-bots re-calculate"). The picked stop's radius is its distance
        // to the neighbouring ship's stop (StopSeparation):
        //   one ship at this dock          - never re-picked here (leaving
        //                                    the dock altogether releases them);
        //   owner within the radius        - the pick stands;
        //   owner outside it, and another
        //   stop is now the nearest        - re-picked from where the owner
        //                                    stands (the block below);
        //   owner outside it, same nearest - the pick stands.
        if (trip.dockPicked && trip.dockEntry)
        {
            // dockEntry/dockStop came out of NearestStop, which reads them
            // from Routes(), built once at first use: the route is there
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
            // from the owner's present spot, not where it began waiting, so a
            // re-pick lands on the stop the owner moved to
            if (!NearestStop(owner->GetMapId(), owner->GetPositionX(), owner->GetPositionY(), DOCK_NEAR_YARDS,
                             trip.dockEntry, trip.dockStop))
                trip.dockEntry = 0;                  // the owner's waiting spot lost its stop (route data changed?): near the owner below

            // the buddy stands at another stop of that same ship: sail from here
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
                    plan.deck = seen->second;        // for the straight walk, if this dock has no recording
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
                return true;                         // to the recording's start
            }
            if (bot->isMoving())
                bot->StopMoving();
            bot->SetFacingTo(trip.waitAt.o);
            return false;                            // on the start, facing the way the recording began, until the owner boards
        }
        if (bot->GetExactDist(owner) > WAIT_NEAR_OWNER_YARDS)
        {
            move = { owner->GetMapId(), owner->GetPositionX(), owner->GetPositionY(), owner->GetPositionZ(), false };
            return true;                             // to the owner on the dock
        }
        if (bot->isMoving())
            bot->StopMoving();
        return false;                                // wait with the owner until it boards
    }

    if (trip.entry != wait.entry)
    {
        // the owner boarded a ship (or another one than before): board that one,
        // keeping a start already held for this very ship
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
// }}}

// {{{ StepReplay
// Walking a boarding recording (617e9), either way; the trip's replay holds
// the place. An embark whose ship sails before the buddy reached the deck
// is a missed sailing: back to the recording's start for the next one.
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
            return false;                            // a leg under way
        case BuddyReplayResult::Done:
            trip.replaying = false;
            BuddyBoardingRelease(bot->GetGUID().GetCounter());
            if (trip.disembarking)
            {
                LOG_INFO("module", "mod-buddies: buddy {} stepped off transport {} by recording {} at {}",
                    bot->GetName(), mt->GetEntry(), trip.replay.id, Where(bot));
                trip = BuddyTrip();                  // the crossing is done: "buddy travel" walks on from here
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
// }}}

typedef bool (*WayStep)(Player*, Player*, BuddyTrip&, BuddyCrossingMove&);
static WayStep const WAY_STEPS[] = {
    nullptr,          // Way::None: planned before any step
    StepTeleport,     // Way::Teleport
    StepPortal,       // Way::Portal
    StepTransport,    // Way::Transport
    StepSameShip,     // Way::SameShip
};
// }}}

// {{{ aboard
// FallDamage: what the server would deal this buddy for a fall of `drop`
// yards onto the ground, by Player::HandleFall's own rule (see the copied
// constants in tuning). Every exemption HandleFall makes is made here too:
// a short drop, Feather Fall, hovering, flying, physical immunity, god mode.
static uint32 FallDamage(Player* bot, float drop)
{
    if (drop < MIN_FALL_DMG_DIST || bot->isDead() || bot->IsGameMaster() || bot->GetCommandStatus(CHEAT_GOD)
        || bot->HasHoverAura() || bot->HasFeatherFallAura() || bot->HasFlyAura())
        return 0;                                    // HandleFall ignores the fall altogether
    int32 safeFall = bot->GetTotalAuraModifier(SPELL_AURA_SAFE_FALL);
    float share    = FALL_DMG_SLOPE * (drop - safeFall) + FALL_DMG_INTERCEPT;
    if (share <= 0.0f || bot->IsImmunedToDamageOrSchool(SPELL_SCHOOL_MASK_NORMAL))
        return 0;                                    // too short after Safe Fall, or immune: unhurt
    uint32 damage = uint32(share * bot->GetMaxHealth() * sWorld->getRate(RATE_DAMAGE_FALL));
    damage = std::min(damage, bot->GetMaxHealth());  // never more than a full health bar
    if (bot->HasAura(SPELL_GUST_OF_WIND))
        damage = bot->GetMaxHealth() / 2;            // Gust of Wind: always half
    if (bot->HasAura(SPELL_DIVINE_PROTECTION))
        damage /= 2;                                 // Divine Protection: halved
    return damage;
}

// One place a jump could land.
struct Landing
{
    float  x = 0.0f, y = 0.0f, z = 0.0f;
    float  drop = 0.0f;                  // from the jump's height to where it lands
    bool   water = false;                // water deep enough to swim in: the fall does no harm
    uint32 damage = 0;                   // onto ground: the fall's damage by the server's rule
};

// PickLanding: where to jump, if anywhere. Each candidate (toward the owner
// first, near to far) is judged by what lies below it:
//   no ground found below          - skipped (counted for the log);
//   water deep enough to swim in   - taken at once: aim for it (the server's
//                                    own depth rule, Map::HasEnoughWater; a
//                                    swimmer's landing ends the fall unhurt);
//   ground the drop wouldn't kill  - kept, the gentlest such fall wins;
//   ground the drop would kill     - refused;
//   out of a running jump's reach  - refused (for that drop's fall time).
// Returns false when nothing is safe: the buddy stays aboard and rides round.
// `gentlestDeadly` is the least damage among the deadly landings (0 when none
// was judged deadly): the log reports it against the buddy's health, which
// says how far from survivable the jump was. A count of deadly landings
// would say little, since every point in reach is usually the same drop.
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
                ++unknown;                           // no ground below (or above the rail): can't judge it
                continue;
            }
            LiquidData const liquid = map->GetLiquidData(bot->GetPhaseMask(), c.x, c.y, ground, bot->GetCollisionHeight(),
                                                         MAP_LIQUID_TYPE_WATER | MAP_LIQUID_TYPE_OCEAN);
            // The depth test is the position form of Map::HasEnoughWater: the
            // form taking ready-made liquid data is declared in Map.h but has
            // no body upstream, so calling it fails at link time ("undefined
            // reference", first build 2026-10-02). The position form looks
            // the liquid up again itself (all liquid kinds) and applies the
            // same swimming-depth rule.
            c.water  = liquid.Level > ground && liquid.Level < fromZ && map->HasEnoughWater(bot, c.x, c.y, ground);
            c.z      = c.water ? liquid.Level : ground;
            c.drop   = fromZ - c.z;
            float secs = std::max(JUMP_MIN_SECONDS, std::sqrt(2.0f * c.drop / FALL_GRAVITY));
            if (yards > JUMP_OUT_YARDS + run * secs)
                continue;                            // a running jump from the rail can't carry this far
            if (c.water)
            {
                out = c;                             // deep water: the safest landing there is
                return true;
            }
            c.damage = FallDamage(bot, fromZ - ground);
            if (c.damage >= bot->GetHealth())
            {
                if (!gentlestDeadly || c.damage < gentlestDeadly)
                    gentlestDeadly = c.damage;       // this fall would kill it; the gentlest such is reported
                continue;
            }
            if (!found || c.damage < out.damage)
            {
                out   = c;                           // the gentlest survivable fall so far
                found = true;
            }
        }
    return found;
}

// JumpOff: the owner jumped off this ship at sea or in the air; the buddy
// jumps too, from where it stands, to `land`. The drop takes as long as a
// real fall would (so a zeppelin's height isn't crossed in an instant);
// nothing else moves the buddy until it has landed, then "buddy travel"
// walks (or swims) on. The fall's damage is dealt on landing (see
// BuddyCrossingStep): a bot sends no landing report, so the server's own
// fall handling would otherwise never run for it.
static void JumpOff(Player* bot, Player* owner, BuddyTrip& trip, MotionTransport* mt, Landing const& land)
{
    float out  = bot->GetExactDist2d(land.x, land.y);
    float secs = std::max(JUMP_MIN_SECONDS, std::sqrt(2.0f * land.drop / FALL_GRAVITY));
    float path = std::hypot(out, land.drop);                     // the spline is paced along its whole length
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

// Riding. In order:
//   the owner jumped off this ship  - jump after it, after its own beat;
//   the owner aboard, or at sea     - stay;
//   docked on the owner's map, but another stop of this route there is
//   nearer the owner                - ride on (an island dock: getting off
//                                     here would leave no way by land);
//   docked off the owner's map, and the route reaches the owner's map
//                                   - ride on: the ship carries it there
//                                     (Ritz, 2026-10-02: "...which almost
//                                     always will mean just... waiting on
//                                     the boat until it loops back around");
//   otherwise                       - step off here and walk straight
//                                     ashore (a recording first), to where
//                                     the owner stepped off, else the dock
//                                     it boarded from, else the travel
//                                     graph's pier; a route that never
//                                     reaches the owner's map is left at
//                                     its next stop and the way planned
//                                     afresh from there.
static bool StepAboard(Player* bot, Player* owner, BuddyTrip& trip, MotionTransport* mt, BuddyCrossingMove& move)
{
    auto jump = sJumped.find(owner->GetGUID().GetCounter());
    if (jump != sJumped.end() && jump->second.ship == mt->GetGUID() && jump->second.stamp != trip.jumpStamp
        && owner->GetTransport() != mt && Now() - jump->second.at <= JUMP_FOLLOW_MS)
    {
        if (!trip.jumpAt)
            trip.jumpAt = Now() + urand(BEAT_MIN_MS, BEAT_MAX_MS);
        if (Now() < trip.jumpAt)
            return false;                            // its own beat at the rail
        trip.jumpStamp = jump->second.stamp;         // judged once per jump, either way
        trip.jumpAt    = 0;
        Landing land;
        uint32  unknown = 0, gentlestDeadly = 0;
        // somewhere safe to land: jump; nowhere: stay aboard and ride round
        // (the riding rules below carry it back to the owner's side)
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
        return false;                                // the owner aboard too, or at sea: stay
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

    // a disembark recording for this stop: walk it (617e9)
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
        return false;                                // the replay walks it from the next step on
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
        ashore = rec->second.landing;                // where the owner stepped off this transport
        found = true;
    }
    else if (trip.departure.mapId == bot->GetMapId()
        && mt->GetExactDist(trip.departure.x, trip.departure.y, trip.departure.z) <= DOCK_REACH_YARDS)
    {
        ashore = trip.departure;                     // back where it boarded: the owner came back first
        found = true;
    }
    else
    {
        Spot stop = { bot->GetMapId(), mt->GetPositionX(), mt->GetPositionY(), mt->GetPositionZ() };
        found = PierOf(stop, ashore);                // the travel graph's pier for this stop
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
// }}}

// {{{ BuddyCrossingWanted
bool BuddyCrossingWanted(Player* bot, Player* owner)
{
    if (Transport* t = bot->GetTransport())
        if (t->ToMotionTransport())
            return true;                             // aboard a boat or zeppelin: only the crossing moves it
    // asked before the crossing's lock, so the two files' locks never nest
    bool errand = BuddyTownErrandUnderway(bot->GetGUID().GetCounter());
    std::lock_guard<std::mutex> lock(sCrossLock);
    BuddyTrip& trip = sTrip[bot->GetGUID().GetCounter()];
    if (Now() < trip.jumpingUntil)
        return true;                                 // in the air after its owner: nothing else may move it
    if (trip.steppingOff && bot->GetMapId() == trip.ashore.mapId)
        return true;                                 // walking ashore from the deck
    if (trip.replaying)
        return true;                                 // partway through a boarding recording: finish it
    if (owner->GetMapId() == bot->GetMapId())
    {
        bool waiting = sWaiting.count(owner->GetGUID().GetCounter()) && !IsInstanceMap(bot->GetMapId());
        if (!waiting && trip.way == Way::SameShip)
        {
            // the owner walked away from the dock: the buddy is let go
            BuddyBoardingRelease(bot->GetGUID().GetCounter());
            uint64 paused = trip.pausedUntil;
            trip = BuddyTrip();
            trip.pausedUntil = paused;
        }
        // waiting at a dock: the same ship, once any errand is done ("finish
        // the current task first", 617h); otherwise "buddy travel"'s own walk
        return waiting && !errand && Now() >= trip.pausedUntil;
    }
    if (IsInstanceMap(bot->GetMapId()) || IsInstanceMap(owner->GetMapId()))
        return false;                                // instances are the dungeon draw's (617c3)
    return Now() >= trip.pausedUntil;                // paused after a failure: not yet
}
// }}}

// {{{ BuddyCrossingStep
bool BuddyCrossingStep(Player* bot, Player* owner, BuddyCrossingMove& move)
{
    std::unique_lock<std::mutex> lock(sCrossLock);
    BuddyTrip& trip = sTrip[bot->GetGUID().GetCounter()];

    // mid-jump after the owner: hold; landed: the crossing is over, and
    // "buddy travel" walks (or swims) to the owner from here
    if (trip.jumpingUntil)
    {
        if (Now() < trip.jumpingUntil)
            return false;
        uint32 answered  = trip.jumpStamp;
        float  fromZ     = trip.jumpFromZ;
        bool   intoWater = trip.jumpIntoWater;
        trip = BuddyTrip();
        trip.jumpStamp = answered;                   // the same jump is never answered twice
        lock.unlock();                               // a deadly fall runs death hooks: never under this lock
        // landed on ground: the server's own fall handling, which a client's
        // landing report would have started (the bot module does the same
        // for a forced dismount); landed in deep water: the fall did no harm
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

    // walking a boarding recording, onto a deck or off one (617e9)
    if (trip.replaying)
        return StepReplay(bot, owner, trip);

    // aboard: riding, then stepping off
    if (Transport* t = bot->GetTransport())
        if (MotionTransport* mt = t->ToMotionTransport())
            return StepAboard(bot, owner, trip, mt, move);

    // walking ashore: a straight line until there, or until STEP_OFF_MS
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
            trip = fresh;                            // the crossing is done
            return false;
        }
        move = { trip.ashore.mapId, trip.ashore.x, trip.ashore.y, trip.ashore.z, true };
        return true;
    }

    // a new owner crossing replaces a plan that followed the old one
    auto rec = sCrossing.find(owner->GetGUID().GetCounter());
    bool stale = (trip.way != Way::None && trip.ownerStamp
                  && (rec == sCrossing.end() || rec->second.stamp != trip.ownerStamp))
              || (trip.way != Way::None && trip.toMap != owner->GetMapId());   // the owner moved on to yet another map
    if (stale)
    {
        BuddyBoardingRelease(bot->GetGUID().GetCounter());
        trip.way = Way::None;
    }

    if (trip.way == Way::None)
    {
        if (owner->GetMapId() == bot->GetMapId())
        {
            // same map: only asked while the owner waits at a dock (see
            // BuddyCrossingWanted), so go to it and sail with it
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
// }}}

// {{{ BuddyCrossingForget
void BuddyCrossingForget(Player* bot)
{
    std::lock_guard<std::mutex> lock(sCrossLock);
    sTrip.erase(bot->GetGUID().GetCounter());
    BuddyBoardingRelease(bot->GetGUID().GetCounter());
}
// }}}

// {{{ buddies_crossing_player
// The owners' half: their footing, and how they leave a map. Bots are
// skipped (a buddy's own crossings are not means for anyone to follow).
class buddies_crossing_player : public PlayerScript
{
public:
    buddies_crossing_player() : PlayerScript("buddies_crossing_player",
        { PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_BEFORE_TELEPORT }) { }

    // {{{ NoteWaiting
    // Whether the owner is waiting to sail (the same ship, 617e8), noted on
    // each look with sCrossLock held:
    //   in an instance            - never waiting
    //   aboard a ship that is in  - waiting, aboard that ship: buddies board it
    //   near a ship's stop        - waiting at once (Ritz, 2026-10-02: "If you're
    //                               on a dock, they should go to the dock too";
    //                               the 8 s dwell is gone, each buddy's own beat
    //                               stands in for it); an owner who stepped back
    //                               off a ship waits on the dock again
    //   far from every stop       - not waiting (walked away: buddies let go)
    // Aboard a ship at sea nothing changes: the owner's map change (or its
    // arrival at another dock of the same map) settles it. Each change takes
    // a new stamp, so every buddy draws a new beat for it.
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
                return;                              // at sea, or already noted aboard this one
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
                w->second.entry = 0;                 // stepped back off before it sailed: waiting on the dock again
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
            return;                                  // already waiting here: nothing new
        }
        if (d > DOCK_LEAVE_YARDS && w != sWaiting.end())
        {
            sWaiting.erase(w);
            LOG_INFO("module", "mod-buddies: {} walked away from the dock; its buddies are let go", player->GetName());
        }
    }
    // }}}

    // {{{ OnPlayerUpdate
    // Twice a second: on ground, the ground is noted; on first being seen
    // on a boat or zeppelin, the ground before it is where it boarded, and
    // its deck spot is noted (also as this transport's known deck spot, for
    // buddies who take it without the owner); on first being seen ashore
    // again on the map its crossing went to, the landing is noted.
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
            return;                                  // an elevator: neither ground nor a crossing

        NoteWaiting(player, guid, track, here, t ? t->ToMotionTransport() : nullptr);

        if (!t)
        {
            // just left a ship that isn't at a stop, still near it: it jumped
            // (or fell) off, in the air or into the sea - its buddies aboard
            // jump after it. A ship at a stop was stepped off of; a ship far
            // away was left by a teleport (a summon, a spell): neither is a jump.
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

            // just stepped off, on the far side of a recorded crossing: the landing
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
            return;                                  // still riding the same one

        // just boarded
        track.aboard = true;
        track.entry  = t->GetEntry();
        track.ship   = t->GetGUID();
        track.boardedFrom = track.haveGround ? track.ground : here;
        player->m_movementInfo.transport.pos.GetPosition(track.deck.x, track.deck.y, track.deck.z, track.deck.o);
        sDeckSeen[track.entry] = track.deck;
    }
    // }}}

    // {{{ OnPlayerBeforeTeleport
    // Fires while the player is still on the old map, still a passenger of
    // the transport that is carrying it across (the transport moves its
    // passengers to the new map with this same teleport). A portal's
    // teleport lands exactly on its trigger's recorded destination, which
    // is how the trigger is found. Never refuses the teleport.
    bool OnPlayerBeforeTeleport(Player* player, uint32 mapId, float x, float y, float z, float /*orientation*/,
                                uint32 /*options*/, Unit* /*target*/) override
    {
        if (!BuddiesEnabled() || player->GetSession()->IsHeadless())
            return true;
        uint32 fromMap = player->GetMapId();
        if (mapId == fromMap || IsInstanceMap(mapId) || IsInstanceMap(fromMap))
            return true;                             // within a map, or into or out of an instance: no crossing

        std::lock_guard<std::mutex> lock(sCrossLock);
        uint32 guid = player->GetGUID().GetCounter();
        sWaiting.erase(guid);                        // left the map: no longer waiting at its dock
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
                // boarded unseen (before login, or between looks): no departure spot to send buddies to
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
                continue;                            // not this teleport's destination
            AreaTrigger const* at = sObjectMgr->GetAreaTrigger(id);
            if (!at || at->map != fromMap)
                continue;                            // a trigger on another map with the same destination
            c.means     = Means::Portal;
            c.triggerId = id;
            sCrossing[guid] = c;
            return true;
        }

        sCrossing.erase(guid);                       // a summon, a teleport spell, a hearthstone: no means to follow
        return true;
    }
    // }}}
};
// }}}

void AddSC_buddies_crossing()
{
    new buddies_crossing_player();
}
