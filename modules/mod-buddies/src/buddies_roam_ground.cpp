
#include "buddies.h"
#include "buddies_roam.h"
#include "roam/buddy_town_rules.h"
#include "DBCEnums.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Log.h"
#include "GridTerrainData.h"
#include "Map.h"
#include "Player.h"
#include "QueryResult.h"
#include <algorithm>
#include <cmath>
#include <mutex>
#include <set>
#include <unordered_map>

static constexpr uint64 ROSTER_REFRESH_MS = 10000;
static constexpr float  PROBE_ABOVE       = 2.0f;
static constexpr float  PROBE_DEPTH       = 50.0f;
static constexpr float  EDGE_CAP          = 300.0f;
static constexpr int    CLEAR_RING_POINTS = 8;
static constexpr float  CENTRE_ABOVE      = 10.0f;

std::vector<std::pair<uint32, uint32>> const& BuddyRosterPairs()
{
    static std::vector<std::pair<uint32, uint32>> pairs;
    static uint64 readAt = 0;
    uint64 now = uint64(GameTime::GetGameTimeMS().count());
    if (readAt != 0 && now - readAt < ROSTER_REFRESH_MS)
        return pairs;
    readAt = now;
    pairs.clear();
    if (QueryResult rows = CharacterDatabase.Query("SELECT buddy, owner FROM buddy_roster WHERE buddy <> 0"))
        do
            pairs.emplace_back((*rows)[0].Get<uint32>(), (*rows)[1].Get<uint32>());
        while (rows->NextRow());
    return pairs;
}

bool BuddyAreaIsTown(uint32 areaId)
{
    AreaTableEntry const* area = sAreaTableStore.LookupEntry(areaId);
    if (!area)
        return false;
    return BuddyTownRules::IsTown(areaId, area->flags);
}

uint32 BuddyTownArea(Player* who)
{
    if (uint32 circle = BuddyTownCircleArea(who))
        return circle;
    uint32 here = who->GetAreaId();
    if (BuddyAreaIsTown(here))
        return here;
    if (who->IsOutdoors())
        return 0;
    float x = who->GetPositionX(), y = who->GetPositionY();
    if (GridTerrainData* ground = who->GetMap()->GetGridTerrainData(x, y))
    {
        uint32 outside = ground->getArea(x, y);
        if (BuddyAreaIsTown(outside))
            return outside;
    }
    return 0;
}

static bool ProbeHeight(Map const* map, uint32 phaseMask, float x, float y, float zHint, float& z)
{
    z = map->GetHeight(phaseMask, x, y, zHint + PROBE_ABOVE, true, PROBE_DEPTH);
    return z > INVALID_HEIGHT;
}

static bool IsSharpStep(float change, float prevChange, float stepRise)
{
    return std::fabs(change) - std::fabs(prevChange) > stepRise;
}

static float WalkLine(Map const* map, uint32 phaseMask, uint32 areaId, float stepRise,
                      float ax, float ay, float az, float bearing, float maxYards)
{
    float dx = std::cos(bearing), dy = std::sin(bearing);
    float lastZ = az, prevChange = 0.0f;
    int steps = int(std::floor(maxYards));
    for (int i = 1; i <= steps; ++i)
    {
        float x = ax + dx * float(i), y = ay + dy * float(i), z;
        if (!ProbeHeight(map, phaseMask, x, y, lastZ, z))
            return float(i - 1);
        if (map->GetAreaId(phaseMask, x, y, z) != areaId)
            return float(i - 1);
        float change = z - lastZ;
        if (IsSharpStep(change, prevChange, stepRise))
            return float(i - 1);
        prevChange = change;
        lastZ = z;
    }
    return maxYards;
}

BuddyRoam::Ground BuddyRoamGround(Map const* map, uint32 phaseMask, uint32 areaId, BuddyRoam::Settings const& settings)
{
    float stepRise = settings.stepRise;
    BuddyRoam::Ground g;

    g.height = [map, phaseMask](float x, float y, float zHint) -> float
    {
        return map->GetHeight(phaseMask, x, y, zHint + PROBE_ABOVE, true, PROBE_DEPTH);
    };

    g.clear = [map, phaseMask, areaId, stepRise](float x, float y, float z, float clearance) -> bool
    {
        float hc;
        if (!ProbeHeight(map, phaseMask, x, y, z, hc) || map->GetAreaId(phaseMask, x, y, hc) != areaId)
            return false;
        float h[CLEAR_RING_POINTS];
        for (int i = 0; i < CLEAR_RING_POINTS; ++i)
        {
            float a = 2.0f * float(M_PI) * float(i) / float(CLEAR_RING_POINTS);
            float px = x + std::cos(a) * clearance, py = y + std::sin(a) * clearance;
            if (!ProbeHeight(map, phaseMask, px, py, hc, h[i]) || map->GetAreaId(phaseMask, px, py, h[i]) != areaId)
                return false;
            if (std::fabs(h[i] - hc) > clearance)
                return false;
        }
        for (int i = 0; i < CLEAR_RING_POINTS / 2; ++i)
            if (std::fabs(h[i] + h[i + CLEAR_RING_POINTS / 2] - 2.0f * hc) > stepRise)
                return false;
        return true;
    };

    g.edgeAlong = [map, phaseMask, areaId, stepRise](float cx, float cy, float cz, float bearing) -> float
    {
        return WalkLine(map, phaseMask, areaId, stepRise, cx, cy, cz, bearing, EDGE_CAP);
    };

    g.seenThrough = [map, phaseMask, areaId, stepRise](BuddyRoam::Point const& a, BuddyRoam::Point const& b) -> bool
    {
        float dx = b.x - a.x, dy = b.y - a.y;
        float len = std::sqrt(dx * dx + dy * dy);
        if (len < 1.0f)
            return true;
        return WalkLine(map, phaseMask, areaId, stepRise, a.x, a.y, a.z, std::atan2(dy, dx), std::floor(len)) >= std::floor(len);
    };
    return g;
}

struct AreaPiece
{
    float minX, maxX, minY, maxY;
    float centreX, centreY;
    uint32 cells;
};
static std::once_flag sPiecesLoaded;
static std::unordered_map<uint64, std::vector<AreaPiece>> sPieces;
static std::mutex sReportLock;
static std::set<uint64> sReported;

static void LoadAreaPieces()
{
    QueryResult rows = WorldDatabase.Query("SELECT map, area, min_x, max_x, min_y, max_y, centre_x, centre_y, cells "
        "FROM buddy_area_centre ORDER BY map, area, piece");
    if (!rows)
    {
        LOG_ERROR("module", "mod-buddies: the table buddy_area_centre is missing or empty in the world database, so no "
            "named area has a centre and buddies will not roam. To fix: install step E044 (sql/basic/db_world.src/"
            "27-buddy-area-centres.apply.sql, made by scripts/generate-buddy-area-centres).");
        return;
    }
    uint32 count = 0;
    do
    {
        Field* f = rows->Fetch();
        uint64 key = (uint64(f[0].Get<uint16>()) << 32) | f[1].Get<uint16>();
        sPieces[key].push_back({ f[2].Get<float>(), f[3].Get<float>(), f[4].Get<float>(), f[5].Get<float>(),
                                 f[6].Get<float>(), f[7].Get<float>(), f[8].Get<uint32>() });
        ++count;
    } while (rows->NextRow());
    LOG_INFO("module", "mod-buddies: loaded {} pieces of {} named areas for buddy roaming", count, uint32(sPieces.size()));
}

static AreaPiece const* PieceAt(uint32 mapId, uint32 areaId, float fromX, float fromY, float fromZ, uint32& index)
{
    std::call_once(sPiecesLoaded, LoadAreaPieces);
    uint64 key = (uint64(mapId) << 32) | areaId;
    auto found = sPieces.find(key);
    if (found == sPieces.end())
    {
        std::lock_guard<std::mutex> lock(sReportLock);
        if (sReported.insert(key).second)
            LOG_ERROR("module", "mod-buddies: area {} on map {} has no row in buddy_area_centre (looked up for a buddy "
                "whose owner stands at {:.1f}, {:.1f}, {:.1f}); buddies explore it by rooms (an indoor-only area has no row). Is the table from the same "
                "map files the server loads? (regenerate: scripts/generate-buddy-area-centres)",
                areaId, mapId, fromX, fromY, fromZ);
        return nullptr;
    }

    AreaPiece const* best = nullptr;
    float bestScore = 0.0f;
    uint32 k = 0;
    for (AreaPiece const& p : found->second)
    {
        bool inside = fromX >= p.minX && fromX <= p.maxX && fromY >= p.minY && fromY <= p.maxY;
        float score;
        if (inside)
            score = -1.0e9f + std::hypot(p.centreX - fromX, p.centreY - fromY);
        else
        {
            float dx = std::max({ p.minX - fromX, 0.0f, fromX - p.maxX });
            float dy = std::max({ p.minY - fromY, 0.0f, fromY - p.maxY });
            score = std::hypot(dx, dy);
        }
        if (!best || score < bestScore)
            best = &p, bestScore = score, index = k;
        ++k;
    }
    return best;
}

bool BuddyAreaPieceAt(uint32 mapId, uint32 areaId, float fromX, float fromY, BuddyAreaPieceInfo& out)
{
    uint32 index = 0;
    AreaPiece const* p = PieceAt(mapId, areaId, fromX, fromY, 0.0f, index);
    if (!p)
        return false;
    out.piece = index;
    out.minX = p->minX, out.maxX = p->maxX, out.minY = p->minY, out.maxY = p->maxY;
    return true;
}

bool BuddyAreaCentre(Map const* map, uint32 phaseMask, uint32 areaId, float fromX, float fromY, float fromZ,
                     BuddyRoam::Area& out)
{
    uint32 index = 0;
    AreaPiece const* best = PieceAt(map->GetId(), areaId, fromX, fromY, fromZ, index);
    if (!best)
        return false;

    float cz;
    if (!ProbeHeight(map, phaseMask, best->centreX, best->centreY, fromZ + CENTRE_ABOVE - PROBE_ABOVE, cz))
    {
        LOG_ERROR("module", "mod-buddies: area {} on map {}: no ground under its middle ({:.1f}, {:.1f}) within {:.0f} yards "
            "below {:.1f} (the owner's height + {:.0f}); no centre this time",
            areaId, map->GetId(), best->centreX, best->centreY, PROBE_DEPTH, fromZ + CENTRE_ABOVE, CENTRE_ABOVE);
        return false;
    }
    out.id = areaId;
    out.centre.x = best->centreX;
    out.centre.y = best->centreY;
    out.centre.z = cz;
    return true;
}
