/*
 * buddies_roam_ground.cpp - the real map, as the roaming core sees it
 * (issue 617e2).
 *
 * For a general audience: the roaming core decides where a buddy goes by
 * asking the ground four questions: how high is it here, may a waypoint
 * stand here, how far is the first wall along this line, and can this
 * line be walked without leaving the area. On the drawn map of the
 * animations those have exact answers; here they are answered by probing
 * the server's own map, the way a blind walker taps a cane:
 *   - the height at a point comes from the map's height lookup, which
 *     already counts rocks, crates and other solid objects standing on the
 *     ground (checked in the source, Map::GetHeight), searched from just
 *     above the point being asked about, so a bridge overhead is not taken
 *     for the ground;
 *   - "the named area" is its area id (the name the player sees on
 *     screen), so the area's edge is where the id changes;
 *   - an obstacle is a sharp step in the height: a change a good deal
 *     larger than the slope around it (a hill rises steadily; a crate's
 *     edge jumps).
 * It also gives an area's centre, from a table made when the server is
 * installed (buddy_area_centre, scripts/generate-buddy-area-centres: every
 * area's borders and middle read from the server's map files), and keeps
 * the list of buddies and owners the passes work through.
 */

#include "buddies.h"
#include "buddies_roam.h"
#include "DBCEnums.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Log.h"
#include "Map.h"
#include "QueryResult.h"
#include <algorithm>
#include <cmath>
#include <mutex>
#include <set>
#include <unordered_map>

// {{{ tuning
static constexpr uint64 ROSTER_REFRESH_MS = 10000;  // how stale the buddy list may get
static constexpr float  PROBE_ABOVE       = 2.0f;   // yards above the hint a height search starts
static constexpr float  PROBE_DEPTH       = 50.0f;  // yards below it a height search looks
static constexpr float  EDGE_CAP          = 300.0f; // yards: no area edge is looked for beyond this
static constexpr int    CLEAR_RING_POINTS = 8;      // points round a waypoint tested for steps
static constexpr float  CENTRE_ABOVE      = 10.0f;  // yards above the owner a centre's height search starts (then PROBE_DEPTH down)
// }}}

// {{{ BuddyRosterPairs
// Read at most every ROSTER_REFRESH_MS: the roster changes only when a
// buddy is made or deleted, and the passes run every few seconds.
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
// }}}

// {{{ BuddyAreaIsTown
// The starting valleys are countryside to a buddy, whatever the client's
// area table says. Seven of the eight carry its "town" flag (AreaTable.dbc,
// read 2026-09-29: Northshire, Deathknell, Shadowglen, Red Cloud Mesa,
// Valley of Trials, Sunstrider Isle, Ammen Vale; Coldridge Valley alone
// does not), so a buddy in one ran the town visit -- errands and fishing
// -- instead of roaming beside a new character (owner, 2026-09-29: "she's
// trying to fish...? But, we're not in a town! We're in Ammen Vale!").
static constexpr uint32 STARTING_VALLEY_AREAS[] = { 9, 132, 154, 188, 220, 363, 3431, 3526 };

bool BuddyAreaIsTown(uint32 areaId)
{
    for (uint32 valley : STARTING_VALLEY_AREAS)
        if (areaId == valley)
            return false;                              // a starting valley: open country
    AreaTableEntry const* area = sAreaTableStore.LookupEntry(areaId);
    if (!area)
        return false;                                  // unknown id: treated as open country
    return (area->flags & (AREA_FLAG_TOWN | AREA_FLAG_CAPITAL | AREA_FLAG_SLAVE_CAPITAL)) != 0;
}
// }}}

// {{{ ground probes
// The height under (x, y) near zHint, or false when there is none (a hole,
// water with no floor, off the map).
static bool ProbeHeight(Map const* map, uint32 phaseMask, float x, float y, float zHint, float& z)
{
    z = map->GetHeight(phaseMask, x, y, zHint + PROBE_ABOVE, true, PROBE_DEPTH);
    return z > INVALID_HEIGHT;
}

// Whether a height change between two neighbouring probes stands out from
// the change just before it: the step test. A hill changes by about the
// same each yard, so it never stands out; a crate's or a ledge's edge
// does. `prevChange` is the change over the previous yard (0 at the
// start).
static bool IsSharpStep(float change, float prevChange, float stepRise)
{
    return std::fabs(change) - std::fabs(prevChange) > stepRise;
}

// Walk the straight line from (ax, ay, az) toward `bearing` for up to
// `maxYards`, a yard at a time, while the area id stays, the ground is
// there and no sharp step is met. Returns the yards walked before the
// first failure (maxYards when none).
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
            return float(i - 1);                       // no ground: the edge of the walkable
        if (map->GetAreaId(phaseMask, x, y, z) != areaId)
            return float(i - 1);                       // the named area ends here
        float change = z - lastZ;
        if (IsSharpStep(change, prevChange, stepRise))
            return float(i - 1);                       // a wall, rock or ledge
        prevChange = change;
        lastZ = z;
    }
    return maxYards;
}
// }}}

// {{{ BuddyRoamGround
BuddyRoam::Ground BuddyRoamGround(Map const* map, uint32 phaseMask, uint32 areaId, BuddyRoam::Settings const& settings)
{
    float stepRise = settings.stepRise;
    BuddyRoam::Ground g;

    g.height = [map, phaseMask](float x, float y, float zHint) -> float
    {
        return map->GetHeight(phaseMask, x, y, zHint + PROBE_ABOVE, true, PROBE_DEPTH);
    };

    // A waypoint may stand where the point is in the area with ground under
    // it, and a ring of points at the clearance radius is in the area, has
    // ground, and is not stepped: for each opposite pair on the ring, the
    // two heights either side should average to the middle's (a plane,
    // however tilted, does); a crate or a rock on one side breaks that by
    // more than the step rise. A slope steeper than 45 degrees (more rise
    // than the clearance over the radius) is also refused: no waypoint on a
    // cliff face.
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

    // "The first wall along the line" (the owner, 2026-09-27): from the
    // centre, a yard at a time, until the area ends, the ground ends or a
    // sharp step.
    g.edgeAlong = [map, phaseMask, areaId, stepRise](float cx, float cy, float cz, float bearing) -> float
    {
        return WalkLine(map, phaseMask, areaId, stepRise, cx, cy, cz, bearing, EDGE_CAP);
    };

    // The same walk from a to b, required to reach b.
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
// }}}

// {{{ BuddyAreaCentre
// The table buddy_area_centre (world database, install step E044): one row
// per separate piece of a named area on a map, with its borders and middle,
// generated from the map files. Loaded once, the first time a centre is
// asked for (from whichever map thread asks first; std::call_once makes the
// others wait), and kept for the server's run: it changes only when the
// maps are re-extracted and the table regenerated.
struct AreaPiece
{
    float minX, maxX, minY, maxY;
    float centreX, centreY;
    uint32 cells;
};
static std::once_flag sPiecesLoaded;
static std::unordered_map<uint64, std::vector<AreaPiece>> sPieces;   // (map id << 32 | area id) -> its pieces, largest first
static std::mutex sReportLock;
static std::set<uint64> sReported;                                   // areas already reported missing (each once)

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

// The centre of the area piece the owner stands in. Which piece: one whose
// borders hold the owner (several may, when one piece's borders surround
// another's; then the one whose middle is nearest), else the piece whose
// borders are nearest (the owner stands on a square labelled with a
// neighbour's id at a border). The height: the ground under the middle,
// searched from CENTRE_ABOVE yards above the owner downward, not from the
// sky: an area can be a mine under a hill (Fargodeep Mine), and a search
// from the sky would find the hilltop above its middle; the owner stands on
// the area's own floor, so its height is the right place to start. No
// ground there is an error for this call (tried again at the next step).
// The piece the owner stands in (see above); null (reported once per area)
// when the area has no row. `index` is the piece's place in the list.
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
        // inside: rank by the middle's distance (negative, so any inside
        // beats any outside); outside: by the distance to the borders
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
    // ProbeHeight starts PROBE_ABOVE over its hint, so the hint is set to
    // start the search CENTRE_ABOVE over the owner
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
// }}}
