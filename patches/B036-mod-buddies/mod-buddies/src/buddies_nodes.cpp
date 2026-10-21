/*
 * buddies_nodes.cpp - herb and ore nodes no one can walk to (issue 617e3).
 *
 * For a general audience: the owner, 2026-10-02: "if it's path can't find
 * a route to a location that is within 3 yards, then we should despawn the
 * ore node and create a new ore node at the nearest spawn spot, and remove
 * the impossible node from the list of nodes that can spawn." The roaming
 * code (buddies_roam_strategy.cpp, the detour) asks the walking map for a
 * path before it walks to a herb or ore node; when there is none, it hands
 * the node's spawn here. This file moves the node and retires its spot.
 *
 * How the server spawns gathering nodes (the pool manager, PoolMgr):
 *   - a herb or ore spawn is a row of the game-object table (its "spawn
 *     id"), a member of a pool (pool_gameobject);
 *   - usually each spot is its own small pool holding the spot's variants
 *     (copper or tin at one place), and those spot pools are members of a
 *     zone's mother pool (pool_pool) that keeps so many spots alive at once;
 *   - sometimes the spawns sit directly in one pool, with no mother.
 * "Its spawn group" is therefore the mother pool when there is one (move to
 * another spot pool), else the spawn's own pool (move to another member).
 *
 * Moving: the pool manager has no public "spawn this member" call; its own
 * respawn path picks a member at random. To pick the nearest free one, this
 * file reads the group's members through the manager's read-only accessors
 * (meant for debug commands) and drives the group's own despawn-one and
 * spawn-one steps on that group, with the manager's active-object record
 * kept in step exactly as the group's own SpawnObject does. Those steps are
 * full specializations in PoolMgr.cpp (strong symbols), so they link from
 * the module. The objects are owned non-const by the manager, so the
 * const_casts are sound; they run on the world's thread after the map
 * updates, so no map thread is reading the pools meanwhile.
 *
 * Retiring: every spawn id at the spot (all its variants) is written to
 * buddy_retired_node (characters database, 04-buddy-roster.sql, E042) and
 * kept in memory. A retired spot never shows again:
 *   startup    any retired spot the pools activated at startup is moved
 *   add world  a node entering a map whose spawn is retired (a later
 *              respawn roll picked it) is queued and moved
 * Chests are never handed here (the roaming code sends herb and ore only).
 */

#include "buddies.h"
#include "buddies_nodes.h"
#include "DatabaseEnv.h"
#include "GameObject.h"
#include "GameTime.h"
#include "Log.h"
#include "Map.h"
#include "MapMgr.h"
#include "ObjectMgr.h"
#include "PoolMgr.h"
#include "ScriptMgr.h"

#include <cmath>
#include <deque>
#include <mutex>
#include <type_traits>
#include <unordered_set>

// {{{ shared state
// retired    every retired spawn id; read on map threads (the detour skips
//            retired spots, the add-world hook watches for them), written
//            on the world's thread
// queue      retire and move requests, drained on the world's thread
// leftNoted  spots already logged as "no free spot, left in place" this
//            run, so a spot the pool keeps rolling logs once, not per roll
struct NodeRequest
{
    uint32      spawnId;
    uint32      buddyGuid;                // 0: a move only (already retired)
    std::string why;
};

static std::mutex                 sNodesLock;
static std::unordered_set<uint32> sRetired;
static std::deque<NodeRequest>    sQueue;
static std::unordered_set<uint32> sLeftNoted;
// }}}

// {{{ BuddyNodeRetired
bool BuddyNodeRetired(uint32 spawnId)
{
    std::lock_guard<std::mutex> guard(sNodesLock);
    return sRetired.count(spawnId) > 0;
}
// }}}

// {{{ BuddyRetireNode
void BuddyRetireNode(uint32 spawnId, uint32 buddyGuid, std::string const& why)
{
    std::lock_guard<std::mutex> guard(sNodesLock);
    sQueue.push_back({ spawnId, buddyGuid, why });
}
// }}}

// {{{ SpotOf
// Where a pool member stands. A game-object member is its own spawn row; a
// spot pool stands where its first game-object member does (all a spot's
// variants share one place). Returns false for a member with no spawn row
// or a spot pool with no game-object members (a deeper pool of pools, which
// gathering nodes don't use): such a member is never a candidate.
static bool SpotOfSpawn(uint32 spawnId, GameObjectData const*& data)
{
    data = sObjectMgr->GetGameObjectData(spawnId);
    return data != nullptr;
}

static uint32 FirstSpawnOfPool(uint32 poolId)
{
    PoolGroup<GameObject> const* group = sPoolMgr->GetPoolGameObjectGroup(poolId);
    if (!group)
        return 0;                                           // a pool without game objects
    if (!group->GetExplicitlyChanced().empty())
        return group->GetExplicitlyChanced().front().guid;
    if (!group->GetEqualChanced().empty())
        return group->GetEqualChanced().front().guid;
    return 0;
}
// }}}

// {{{ SpawnsOfSpot
// Every spawn id that stands at the spot of `spawnId`: the whole spot pool
// when its pool sits in a mother pool (every variant is as unreachable as
// the one the buddy saw), else just the spawn itself.
static std::vector<uint32> SpawnsOfSpot(uint32 spawnId, uint32 pool, uint32 mother)
{
    std::vector<uint32> spawns;
    PoolGroup<GameObject> const* group = mother ? sPoolMgr->GetPoolGameObjectGroup(pool) : nullptr;
    if (!group)
        return { spawnId };                                 // no mother, or no group: the spawn alone
    for (PoolObject const& o : group->GetExplicitlyChanced())
        spawns.push_back(o.guid);
    for (PoolObject const& o : group->GetEqualChanced())
        spawns.push_back(o.guid);
    return spawns;
}
// }}}

// {{{ SpotRetiredLocked
// Whether a candidate spot is retired: a game-object member by its own id,
// a spot pool when any of its spawns is (they share the place). Called with
// sNodesLock held.
static bool SpotRetiredLocked(uint32 poolMemberSpawnOrPool, bool isPool)
{
    if (!isPool)
        return sRetired.count(poolMemberSpawnOrPool) > 0;
    for (uint32 s : SpawnsOfSpot(0, poolMemberSpawnOrPool, 1))
        if (sRetired.count(s))
            return true;
    return false;
}
// }}}

// {{{ MoveOff
// Move whatever is active at the retired spot of `spawnId` to the nearest
// free, unretired spot of its group. Each path and what it brings:
//   not pooled        - nothing to move to: left in place, logged once (it
//                       is still retired, so buddies never detour to it)
//   not active        - the pool has a different spot up right now: nothing
//                       to do (a later roll that picks it is caught on its
//                       way into the world)
//   no free spot      - every other spot is up or retired: left in place,
//                       logged once (the open question's default)
//   moved             - the old spot despawned, the nearest free one spawned
//                       through the group's own steps; logged with both
// The outcome text says which path was taken, for the log. World thread only.
template <class T>
static void MoveInGroup(uint32 groupPool, uint32 fromMember, float fx, float fy, uint16 map,
                        std::string& outcome)
{
    PoolGroup<T> const* group = nullptr;
    if constexpr (std::is_same_v<T, Pool>)
        group = sPoolMgr->GetPoolPoolGroup(groupPool);
    else
        group = sPoolMgr->GetPoolGameObjectGroup(groupPool);
    if (!group)
    {
        outcome = "its pool " + std::to_string(groupPool) + " is not loaded (pool manager has no such group)";
        return;
    }
    // which members are up is kept per map since the core's 2026-08 pool
    // change (df93fae2e, "store pool spawn state per map"); before it, one
    // record for the whole world (the pool manager's spawned data). Nodes
    // are on the continents, so the map is the continent's one copy
    Map* onMap = sMapMgr->FindBaseNonInstanceMap(map);
    if (!onMap)
    {
        outcome = "map " + std::to_string(map) + " is not loaded: nothing to move";
        return;
    }
    SpawnedPoolData& spawns = onMap->GetPoolData();
    if (!spawns.IsSpawnedObject<T>(fromMember))
    {
        outcome = "not up right now (another spot of pool " + std::to_string(groupPool) + " is): nothing to move";
        return;
    }

    // the nearest free, unretired member, on the same map
    PoolObject const* best     = nullptr;
    float             bestDist = 0.0f;
    GameObjectData const* bestData = nullptr;
    auto consider = [&](PoolObject const& o)
    {
        if (o.guid == fromMember || spawns.IsSpawnedObject<T>(o.guid))
            return;                                         // the retired spot itself, or already up
        uint32 spawnHere = std::is_same_v<T, Pool> ? FirstSpawnOfPool(o.guid) : o.guid;
        GameObjectData const* d = nullptr;
        if (!spawnHere || !SpotOfSpawn(spawnHere, d) || d->mapid != map)
            return;                                         // nowhere to stand, or another map
        {
            std::lock_guard<std::mutex> guard(sNodesLock);
            if (SpotRetiredLocked(o.guid, std::is_same_v<T, Pool>))
                return;                                     // retired too
        }
        float dist = std::hypot(d->posX - fx, d->posY - fy);
        if (!best || dist < bestDist)
        {
            best     = &o;
            bestDist = dist;
            bestData = d;
        }
    };
    for (PoolObject const& o : group->GetExplicitlyChanced())
        consider(o);
    for (PoolObject const& o : group->GetEqualChanced())
        consider(o);
    if (!best)
    {
        outcome = "no free spot left in pool " + std::to_string(groupPool) + ": left in place";
        return;
    }

    // the group's own two steps, with the map's record kept as SpawnObject
    // keeps it: despawn and forget the old member, remember and spawn the new
    PoolGroup<T>& writable = const_cast<PoolGroup<T>&>(*group);
    writable.Despawn1Object(spawns, fromMember);
    spawns.RemoveSpawn<T>(fromMember, groupPool);
    PoolObject chosen = *best;
    spawns.AddSpawn<T>(chosen.guid, groupPool);
    writable.Spawn1Object(spawns, &chosen);
    outcome = "moved " + std::to_string(uint32(bestDist)) + " yards to (" +
              std::to_string(int(bestData->posX)) + ", " + std::to_string(int(bestData->posY)) + ", " +
              std::to_string(int(bestData->posZ)) + "), pool " + std::to_string(groupPool) + " member " +
              std::to_string(chosen.guid);
}

static void MoveOff(uint32 spawnId, std::string& outcome)
{
    GameObjectData const* data = nullptr;
    if (!SpotOfSpawn(spawnId, data))
    {
        outcome = "no such spawn row (deleted from the world database?)";
        return;
    }
    uint32 pool   = sPoolMgr->IsPartOfAPool<GameObject>(spawnId);
    uint32 mother = pool ? sPoolMgr->IsPartOfAPool<Pool>(pool) : 0;
    if (!pool)
        outcome = "not in any pool, so it has no other spot: left in place (buddies skip it)";
    else if (mother)
        MoveInGroup<Pool>(mother, pool, data->posX, data->posY, data->mapid, outcome);   // spot pool to spot pool
    else
        MoveInGroup<GameObject>(pool, spawnId, data->posX, data->posY, data->mapid, outcome);  // member to member
}
// }}}

// {{{ Retire
// Record every spawn at the spot as retired, in memory and in the table.
// Returns the spot's spawn ids. World thread; takes the lock itself.
static std::vector<uint32> Retire(uint32 spawnId, uint32 buddyGuid)
{
    uint32 pool   = sPoolMgr->IsPartOfAPool<GameObject>(spawnId);
    uint32 mother = pool ? sPoolMgr->IsPartOfAPool<Pool>(pool) : 0;
    std::vector<uint32> spawns = SpawnsOfSpot(spawnId, pool, mother);
    uint32 now = uint32(GameTime::GetGameTime().count());
    {
        std::lock_guard<std::mutex> guard(sNodesLock);
        for (uint32 s : spawns)
            sRetired.insert(s);
    }
    for (uint32 s : spawns)
    {
        GameObjectData const* d = sObjectMgr->GetGameObjectData(s);
        if (!d)
            continue;                                       // a spot member without a row: nothing to record
        CharacterDatabase.Execute(
            "INSERT IGNORE INTO buddy_retired_node (spawn, entry, map, x, y, z, retired, buddy) "
            "VALUES ({}, {}, {}, {}, {}, {}, {}, {})",
            s, d->id, d->mapid, d->posX, d->posY, d->posZ, now, buddyGuid);
    }
    return spawns;
}
// }}}

// {{{ Drain
// The world thread's turn: each queued request retired (if it came from a
// buddy) and moved, and logged. A request for a spot already retired from a
// buddy (two buddies saw it) only moves. "Left in place" outcomes log once
// per spot per run; moves and first retirements always log.
static void Drain()
{
    std::deque<NodeRequest> work;
    {
        std::lock_guard<std::mutex> guard(sNodesLock);
        work.swap(sQueue);
    }
    for (NodeRequest const& r : work)
    {
        bool fresh = false;
        if (r.buddyGuid)
        {
            std::lock_guard<std::mutex> guard(sNodesLock);
            fresh = sRetired.count(r.spawnId) == 0;
        }
        std::vector<uint32> spot;
        if (fresh)
            spot = Retire(r.spawnId, r.buddyGuid);
        std::string outcome;
        MoveOff(r.spawnId, outcome);
        GameObjectData const* d = sObjectMgr->GetGameObjectData(r.spawnId);
        std::string where = d ? "map " + std::to_string(d->mapid) + " (" + std::to_string(int(d->posX)) + ", " +
                                std::to_string(int(d->posY)) + ", " + std::to_string(int(d->posZ)) + "), entry " +
                                std::to_string(d->id)
                              : "unknown spot";
        // Each outcome and its log:
        //   retired just now        - a warning: a buddy found a spot no path
        //                             reaches, with what became of the node
        //   not up (startup sweep)  - silent: nothing was shown, nothing moved
        //   left in place, unpooled - once per run, as information: such a
        //                             node has no other spot by design
        //   left in place, pooled   - once per run, as an error: the pool has
        //                             run out of reachable spots
        //   moved                   - information, every time
        bool notUp       = outcome.rfind("not up", 0) == 0;
        bool unpooled    = outcome.rfind("not in any pool", 0) == 0;
        bool leftInPlace = outcome.find("left in place") != std::string::npos;
        if (!fresh && notUp)
            continue;
        if (leftInPlace)
        {
            std::lock_guard<std::mutex> guard(sNodesLock);
            if (!sLeftNoted.insert(r.spawnId).second && !fresh)
                continue;                                   // logged already this run
        }
        if (fresh)
            LOG_WARN("module", "mod-buddies: retired gathering spot {} at {} ({} spawn(s) at the spot): {}. Node: {}",
                r.spawnId, where, spot.size(), r.why, outcome);
        else if (unpooled)
            LOG_INFO("module", "mod-buddies: retired gathering spot {} at {} is up again and {}", r.spawnId, where, outcome);
        else if (leftInPlace)
            LOG_ERROR("module", "mod-buddies: retired gathering spot {} at {} came up again and {}. "
                "to debug: is every spot of its pool retired (SELECT COUNT(*) FROM buddy_retired_node)? "
                "If so, the zone has run out of spots buddies can reach",
                r.spawnId, where, outcome);
        else
            LOG_INFO("module", "mod-buddies: retired gathering spot {} at {}: {}", r.spawnId, where, outcome);
    }
}
// }}}

class buddies_nodes_world : public WorldScript
{
public:
    buddies_nodes_world() : WorldScript("buddies_nodes_world", { WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_UPDATE }) { }

    // {{{ OnStartup
    // The record read back and every retired spot the pools put up at
    // startup moved off before anyone can log in. Pools are spawned during
    // the world's initialisation, which finishes before this hook.
    void OnStartup() override
    {
        if (!BuddiesEnabled())
            return;                                         // roster tables missing: the roster check said so
        QueryResult result = CharacterDatabase.Query("SELECT spawn FROM buddy_retired_node");
        uint32 count = 0;
        if (result)
        {
            std::lock_guard<std::mutex> guard(sNodesLock);
            do
            {
                sRetired.insert((*result)[0].Get<uint32>());
                ++count;
            } while (result->NextRow());
        }
        {
            std::lock_guard<std::mutex> guard(sNodesLock);
            for (uint32 s : sRetired)
                sQueue.push_back({ s, 0, "" });
        }
        Drain();
        LOG_INFO("module", "mod-buddies: {} retired gathering spawn(s) kept out of their pools", count);
    }
    // }}}

    // {{{ OnUpdate
    void OnUpdate(uint32 /*diff*/) override
    {
        if (!BuddiesEnabled())
            return;
        Drain();
    }
    // }}}
};

class buddies_nodes_gameobject : public AllGameObjectScript
{
public:
    buddies_nodes_gameobject() : AllGameObjectScript("buddies_nodes_gameobject") { }

    // {{{ OnGameObjectAddWorld
    // A node entering a map at a retired spot: a respawn roll picked it, or
    // its grid loaded with it up. Queued for the world thread (this runs on
    // a map thread, mid-update, where the pools must not be changed).
    void OnGameObjectAddWorld(GameObject* go) override
    {
        if (!BuddiesEnabled() || !go->GetSpawnId())
            return;                                         // buddies off, or a summoned object with no spawn row
        std::lock_guard<std::mutex> guard(sNodesLock);
        if (sRetired.count(go->GetSpawnId()))
            sQueue.push_back({ uint32(go->GetSpawnId()), 0, "" });
    }
    // }}}
};

// {{{ AddSC_buddies_nodes
void AddSC_buddies_nodes()
{
    new buddies_nodes_world();
    new buddies_nodes_gameobject();
}
// }}}
