
#include "buddies_spawn_zones.h"
#include "CreatureData.h"
#include "ObjectMgr.h"
#include <algorithm>
#include <cmath>
#include <mutex>
#include <unordered_map>
#include <unordered_set>
#include <vector>

static constexpr float SPAWN_ZONE_MARGIN    = 20.0f;
static constexpr float SPAWN_ZONE_MIN_YARDS = 30.0f;
static constexpr float CELL_YARDS           = 64.0f;

struct ZonePoint { float x, y, r2; };

struct MapZones
{
    std::unordered_map<uint32, std::vector<ZonePoint>> points;
    std::unordered_map<uint64, std::vector<uint32>>    cells;
};

static std::once_flag sZonesRead;
static std::unordered_map<uint32, MapZones> sZones;

static uint64 CellKey(int32 cx, int32 cy) { return (uint64(uint32(cx)) << 32) | uint32(cy); }

static void ReadZones()
{
    std::unordered_map<uint32, std::unordered_map<uint64, std::unordered_set<uint32>>> cells;
    for (auto const& [spawnId, data] : sObjectMgr->GetAllCreatureData())
    {
        float r = std::max(SPAWN_ZONE_MIN_YARDS, data.wander_distance + SPAWN_ZONE_MARGIN);
        ZonePoint p{ data.posX, data.posY, r * r };
        for (uint32 entry : { data.id, data.id2, data.id3 })
        {
            if (!entry)
                continue;
            CreatureTemplate const* t = sObjectMgr->GetCreatureTemplate(entry);
            if (!t || t->npcflag || t->type == CREATURE_TYPE_CRITTER)
                continue;
            sZones[data.mapid].points[entry].push_back(p);
            for (int32 cx = int32(std::floor((p.x - r) / CELL_YARDS)); cx <= int32(std::floor((p.x + r) / CELL_YARDS)); ++cx)
                for (int32 cy = int32(std::floor((p.y - r) / CELL_YARDS)); cy <= int32(std::floor((p.y + r) / CELL_YARDS)); ++cy)
                    cells[data.mapid][CellKey(cx, cy)].insert(entry);
        }
    }
    for (auto& [map, byCell] : cells)
        for (auto& [key, kinds] : byCell)
            sZones[map].cells[key].assign(kinds.begin(), kinds.end());
}

bool BuddyInSpawnZone(uint32 mapId, uint32 entry, float x, float y)
{
    std::call_once(sZonesRead, ReadZones);
    auto m = sZones.find(mapId);
    if (m == sZones.end())
        return false;
    auto k = m->second.points.find(entry);
    if (k == m->second.points.end())
        return false;
    for (ZonePoint const& p : k->second)
        if ((x - p.x) * (x - p.x) + (y - p.y) * (y - p.y) <= p.r2)
            return true;
    return false;
}

void BuddySpawnZonesAt(uint32 mapId, float x, float y, std::vector<uint32>& kinds)
{
    kinds.clear();
    std::call_once(sZonesRead, ReadZones);
    auto m = sZones.find(mapId);
    if (m == sZones.end())
        return;
    auto c = m->second.cells.find(CellKey(int32(std::floor(x / CELL_YARDS)), int32(std::floor(y / CELL_YARDS))));
    if (c == m->second.cells.end())
        return;
    for (uint32 entry : c->second)
        if (BuddyInSpawnZone(mapId, entry, x, y))
            kinds.push_back(entry);
}

bool BuddySharesSpawnZone(uint32 mapId, std::vector<uint32> const& kinds, float x, float y)
{
    for (uint32 entry : kinds)
        if (BuddyInSpawnZone(mapId, entry, x, y))
            return true;
    return false;
}
