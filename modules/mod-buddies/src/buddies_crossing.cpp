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
#include "DBCStores.h"
#include "GameObject.h"
#include "GameTime.h"
#include "Log.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Opcodes.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellMgr.h"
#include "Transport.h"
#include "TravelNode.h"
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
    Spot     boardedFrom;                // the ground it last stood on before boarding
    DeckSpot deck;                       // where on the deck it stood
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
static uint32 sStamp = 0;

// A buddy's own trip.
enum class Way : uint8 { None, Teleport, Portal, Transport };

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
        return false;                                // wait on the dock (sit or roam: open question, 617e8)
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

typedef bool (*WayStep)(Player*, Player*, BuddyTrip&, BuddyCrossingMove&);
static WayStep const WAY_STEPS[] = {
    nullptr,          // Way::None: planned before any step
    StepTeleport,     // Way::Teleport
    StepPortal,       // Way::Portal
    StepTransport,    // Way::Transport
};
// }}}

// {{{ aboard
// Riding: hold still until the transport is in on the owner's map (or back
// on the buddy's own, if the owner came back first), then step off and walk
// straight ashore - to where the owner stepped off, else to the dock it
// boarded from, else the pier the travel graph knows.
static bool StepAboard(Player* bot, Player* owner, BuddyTrip& trip, MotionTransport* mt, BuddyCrossingMove& move)
{
    if (!Docked(mt) || bot->GetMapId() != owner->GetMapId())
    {
        if (bot->isMoving())
            bot->StopMoving();
        return false;                                // at sea, or docked somewhere the owner isn't: stay aboard
    }

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
    std::lock_guard<std::mutex> lock(sCrossLock);
    BuddyTrip& trip = sTrip[bot->GetGUID().GetCounter()];
    if (trip.steppingOff && bot->GetMapId() == trip.ashore.mapId)
        return true;                                 // walking ashore from the deck
    if (owner->GetMapId() == bot->GetMapId())
        return false;                                // same map: "buddy travel"'s own walk
    if (IsInstanceMap(bot->GetMapId()) || IsInstanceMap(owner->GetMapId()))
        return false;                                // instances are the dungeon draw's (617c3)
    return Now() >= trip.pausedUntil;                // paused after a failure: not yet
}
// }}}

// {{{ BuddyCrossingStep
bool BuddyCrossingStep(Player* bot, Player* owner, BuddyCrossingMove& move)
{
    std::lock_guard<std::mutex> lock(sCrossLock);
    BuddyTrip& trip = sTrip[bot->GetGUID().GetCounter()];

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
    if (trip.way != Way::None && trip.ownerStamp && (rec == sCrossing.end() || rec->second.stamp != trip.ownerStamp))
        trip.way = Way::None;
    if (trip.way != Way::None && trip.toMap != owner->GetMapId())
        trip.way = Way::None;                        // the owner has moved on to yet another map

    if (trip.way == Way::None && !Plan(bot, owner, trip))
        return false;
    return WAY_STEPS[uint8(trip.way)](bot, owner, trip, move);
}
// }}}

// {{{ BuddyCrossingForget
void BuddyCrossingForget(Player* bot)
{
    std::lock_guard<std::mutex> lock(sCrossLock);
    sTrip.erase(bot->GetGUID().GetCounter());
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

    // {{{ OnPlayerUpdate
    // Twice a second: on ground, the ground is noted; on first being seen
    // on a boat or zeppelin, the ground before it is where it boarded, and
    // its deck spot is noted (also as this transport's known deck spot, for
    // buddies who take it without the owner); on first being seen ashore
    // again on the map its crossing went to, the landing is noted.
    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        if (!BuddiesEnabled() || player->GetSession()->IsBot())
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

        if (!t)
        {
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
        if (!BuddiesEnabled() || player->GetSession()->IsBot())
            return true;
        uint32 fromMap = player->GetMapId();
        if (mapId == fromMap || IsInstanceMap(mapId) || IsInstanceMap(fromMap))
            return true;                             // within a map, or into or out of an instance: no crossing

        std::lock_guard<std::mutex> lock(sCrossLock);
        uint32 guid = player->GetGUID().GetCounter();
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
