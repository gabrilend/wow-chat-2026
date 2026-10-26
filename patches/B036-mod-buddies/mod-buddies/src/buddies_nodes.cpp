
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

struct NodeRequest
{
    uint32      spawnId;
    uint32      buddyGuid;
    std::string why;
};

static std::mutex                 sNodesLock;
static std::unordered_set<uint32> sRetired;
static std::deque<NodeRequest>    sQueue;
static std::unordered_set<uint32> sLeftNoted;

bool BuddyNodeRetired(uint32 spawnId)
{
    std::lock_guard<std::mutex> guard(sNodesLock);
    return sRetired.count(spawnId) > 0;
}

void BuddyRetireNode(uint32 spawnId, uint32 buddyGuid, std::string const& why)
{
    std::lock_guard<std::mutex> guard(sNodesLock);
    sQueue.push_back({ spawnId, buddyGuid, why });
}

static bool SpotOfSpawn(uint32 spawnId, GameObjectData const*& data)
{
    data = sObjectMgr->GetGameObjectData(spawnId);
    return data != nullptr;
}

static uint32 FirstSpawnOfPool(uint32 poolId)
{
    PoolGroup<GameObject> const* group = sPoolMgr->GetPoolGameObjectGroup(poolId);
    if (!group)
        return 0;
    if (!group->GetExplicitlyChanced().empty())
        return group->GetExplicitlyChanced().front().guid;
    if (!group->GetEqualChanced().empty())
        return group->GetEqualChanced().front().guid;
    return 0;
}

static std::vector<uint32> SpawnsOfSpot(uint32 spawnId, uint32 pool, uint32 mother)
{
    std::vector<uint32> spawns;
    PoolGroup<GameObject> const* group = mother ? sPoolMgr->GetPoolGameObjectGroup(pool) : nullptr;
    if (!group)
        return { spawnId };
    for (PoolObject const& o : group->GetExplicitlyChanced())
        spawns.push_back(o.guid);
    for (PoolObject const& o : group->GetEqualChanced())
        spawns.push_back(o.guid);
    return spawns;
}

static bool SpotRetiredLocked(uint32 poolMemberSpawnOrPool, bool isPool)
{
    if (!isPool)
        return sRetired.count(poolMemberSpawnOrPool) > 0;
    for (uint32 s : SpawnsOfSpot(0, poolMemberSpawnOrPool, 1))
        if (sRetired.count(s))
            return true;
    return false;
}

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

    PoolObject const* best     = nullptr;
    float             bestDist = 0.0f;
    GameObjectData const* bestData = nullptr;
    auto consider = [&](PoolObject const& o)
    {
        if (o.guid == fromMember || spawns.IsSpawnedObject<T>(o.guid))
            return;
        uint32 spawnHere = std::is_same_v<T, Pool> ? FirstSpawnOfPool(o.guid) : o.guid;
        GameObjectData const* d = nullptr;
        if (!spawnHere || !SpotOfSpawn(spawnHere, d) || d->mapid != map)
            return;
        {
            std::lock_guard<std::mutex> guard(sNodesLock);
            if (SpotRetiredLocked(o.guid, std::is_same_v<T, Pool>))
                return;
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
        MoveInGroup<Pool>(mother, pool, data->posX, data->posY, data->mapid, outcome);
    else
        MoveInGroup<GameObject>(pool, spawnId, data->posX, data->posY, data->mapid, outcome);
}

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
            continue;
        CharacterDatabase.Execute(
            "INSERT IGNORE INTO buddy_retired_node (spawn, entry, map, x, y, z, retired, buddy) "
            "VALUES ({}, {}, {}, {}, {}, {}, {}, {})",
            s, d->id, d->mapid, d->posX, d->posY, d->posZ, now, buddyGuid);
    }
    return spawns;
}

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
        bool notUp       = outcome.rfind("not up", 0) == 0;
        bool unpooled    = outcome.rfind("not in any pool", 0) == 0;
        bool leftInPlace = outcome.find("left in place") != std::string::npos;
        if (!fresh && notUp)
            continue;
        if (leftInPlace)
        {
            std::lock_guard<std::mutex> guard(sNodesLock);
            if (!sLeftNoted.insert(r.spawnId).second && !fresh)
                continue;
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

class buddies_nodes_world : public WorldScript
{
public:
    buddies_nodes_world() : WorldScript("buddies_nodes_world", { WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_UPDATE }) { }

    void OnStartup() override
    {
        if (!BuddiesEnabled())
            return;
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

    void OnUpdate(uint32 ) override
    {
        if (!BuddiesEnabled())
            return;
        Drain();
    }
};

class buddies_nodes_gameobject : public AllGameObjectScript
{
public:
    buddies_nodes_gameobject() : AllGameObjectScript("buddies_nodes_gameobject") { }

    void OnGameObjectAddWorld(GameObject* go) override
    {
        if (!BuddiesEnabled() || !go->GetSpawnId())
            return;
        std::lock_guard<std::mutex> guard(sNodesLock);
        if (sRetired.count(go->GetSpawnId()))
            sQueue.push_back({ uint32(go->GetSpawnId()), 0, "" });
    }
};

void AddSC_buddies_nodes()
{
    new buddies_nodes_world();
    new buddies_nodes_gameobject();
}
