/*
 * buddies_navmesh.cpp - questions a buddy asks the navigation mesh (issue
 * 617o; what each question means is in buddies_navmesh.h).
 *
 * For a general audience: the mesh's own library (Detour) stores points
 * with the axes in a different order from the game's: (y, z, x), height in
 * the middle. Every point going in or out is turned around here and
 * nowhere else.
 *
 * A mesh query object keeps scratch memory while it searches, so two
 * threads must never share one (the server's note in MapCollisionData.h:
 * "navMeshQuery is not thread safe and needs its own instance per map").
 * The bot module runs bots on more than one thread, so each thread keeps
 * its own query object per mesh, made on first use and kept for the
 * thread's life. Route questions go to the server's own path search
 * (PathGenerator), which the walking itself uses, so a route judged
 * complete here is the route the walking will take.
 */

#include "buddies_navmesh.h"
#include "roam/buddy_mesh_core.h"
#include "DetourNavMesh.h"
#include "DetourNavMeshQuery.h"
#include "Map.h"
#include "PathGenerator.h"
#include "Player.h"
#include <cmath>
#include <memory>
#include <unordered_map>

// {{{ tuning
static constexpr int   QUERY_NODES  = 2048;   // search scratch per query object (the server's own uses 1024 to 65535)
// }}}

// {{{ the per-thread query objects
struct QueryDeleter { void operator()(dtNavMeshQuery* q) const { dtFreeNavMeshQuery(q); } };
using OwnedQuery = std::unique_ptr<dtNavMeshQuery, QueryDeleter>;

// The query object for this map's mesh on this thread; null when the map
// has no mesh (pathfinding off for it, or no mesh files).
static dtNavMeshQuery const* Query(Map const* map)
{
    dtNavMesh const* mesh = map->GetMapCollisionData().GetMMapData().GetNavMesh();
    if (!mesh)
        return nullptr;
    thread_local std::unordered_map<dtNavMesh const*, OwnedQuery> mine;
    auto it = mine.find(mesh);
    if (it != mine.end())
        return it->second.get();
    OwnedQuery q(dtAllocNavMeshQuery());
    if (!q || dtStatusFailed(q->init(mesh, QUERY_NODES)))
        return nullptr;
    return mine.emplace(mesh, std::move(q)).first->second.get();
}

// What a buddy may stand on: the shared rule (roam/buddy_mesh_core.h).
static dtQueryFilter const& Filter()
{
    thread_local dtQueryFilter f = BuddyMeshCore::BuddyFilter();
    return f;
}
// }}}

// {{{ BuddyMeshSnap
bool BuddyMeshSnap(Map const* map, BuddyRoam::Point const& at, float reach, float rise, BuddyRoam::Point& out)
{
    dtNavMeshQuery const* q = Query(map);
    return q && BuddyMeshCore::Snap(q, Filter(), at, reach, rise, out);
}
// }}}

// {{{ BuddyMeshLineClear
// The shared walkability ray (roam/buddy_mesh_core.h), ends found within
// LINE_ON_MESH sideways and LINE_RISE up or down.
bool BuddyMeshLineClear(Map const* map, BuddyRoam::Point const& from, BuddyRoam::Point const& to)
{
    dtNavMeshQuery const* q = Query(map);
    return q && BuddyMeshCore::LineClear(q, Filter(), from, to, BuddyMeshCore::LINE_ON_MESH, BuddyMeshCore::LINE_RISE);
}
// }}}

// {{{ BuddyMeshRoute
// The server's path answer is a set of flags; which kind it is goes by
// the first matching row, in this order (a "no path" that also says "far
// from the mesh" is reported as off the mesh, the more useful reason).
struct KindRow { uint32 mask; BuddyRouteKind kind; };
static KindRow const sKinds[] = {
    { PATHFIND_NOT_USING_PATH, BuddyRouteKind::Shortcut },  // swimming, flying, or a map without a mesh
    { PATHFIND_FARFROMPOLY,    BuddyRouteKind::OffMesh  },
    { PATHFIND_NOPATH,         BuddyRouteKind::None     },
    { PATHFIND_SHORTCUT,       BuddyRouteKind::Shortcut },
    { PATHFIND_INCOMPLETE,     BuddyRouteKind::Partial  },
    { PATHFIND_SHORT,          BuddyRouteKind::Partial  },  // cut at the search's length limit
    { PATHFIND_NORMAL,         BuddyRouteKind::Complete },
};

BuddyRouteKind BuddyMeshRoute(Player* bot, BuddyRoam::Point const& to, std::vector<BuddyRoam::Point>& points)
{
    PathGenerator path(bot);
    if (!path.CalculatePath(to.x, to.y, to.z))
        return BuddyRouteKind::None;
    uint32 type = uint32(path.GetPathType());
    BuddyRouteKind kind = BuddyRouteKind::None;          // no flag matched: treated as no route
    for (KindRow const& row : sKinds)
        if (type & row.mask)
        {
            kind = row.kind;
            break;
        }
    if (kind == BuddyRouteKind::Complete)
    {
        points.clear();
        for (G3D::Vector3 const& p : path.GetPath())
            points.push_back({ p.x, p.y, p.z });
    }
    return kind;
}

char const* BuddyRouteKindName(BuddyRouteKind kind)
{
    static char const* const names[] = { "complete", "partial", "none (would walk straight)", "shortcut (straight line)", "off the mesh" };
    return names[uint8(kind)];
}
// }}}

// {{{ BuddySightBlocker
static constexpr float SIGHT_STEP = 2.0f;   // yards between the terrain samples along the look
BuddySight BuddySightBlocker(Map const* map, uint32 phaseMask, BuddyRoam::Point const& from, BuddyRoam::Point const& to,
                             BuddyRoam::Point& hit)
{
    float ax = from.x, ay = from.y, az = from.z + BUDDY_EYE_YARDS;
    float bx = to.x,   by = to.y,   bz = to.z + BUDDY_EYE_YARDS;
    float rx, ry, rz;
    if (map->GetMapCollisionData().GetStaticTree().GetObjectHitPos(ax, ay, az, bx, by, bz, rx, ry, rz, 0.0f))
    {
        hit = { rx, ry, rz };
        return BuddySight::Object;
    }
    // the ground: the terrain alone (no buildings, they were asked above),
    // sampled along the look; the sample farthest above the line is the
    // crest that hides the far end
    float len = std::hypot(bx - ax, by - ay);
    float worst = 0.0f;
    bool  hidden = false;
    for (float s = SIGHT_STEP; s < len; s += SIGHT_STEP)
    {
        float k = s / len;
        float x = ax + (bx - ax) * k, y = ay + (by - ay) * k, lineZ = az + (bz - az) * k;
        float g = map->GetHeight(phaseMask, x, y, lineZ + 200.0f, false, 400.0f);
        if (g > INVALID_HEIGHT && g - lineZ > worst)
        {
            worst  = g - lineZ;
            hidden = true;
            hit    = { x, y, g };
        }
    }
    return hidden ? BuddySight::Ground : BuddySight::Clear;
}
// }}}
