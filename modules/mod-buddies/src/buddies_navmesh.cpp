
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

static constexpr int   QUERY_NODES  = 2048;

struct QueryDeleter { void operator()(dtNavMeshQuery* q) const { dtFreeNavMeshQuery(q); } };
using OwnedQuery = std::unique_ptr<dtNavMeshQuery, QueryDeleter>;

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

static dtQueryFilter const& Filter()
{
    thread_local dtQueryFilter f = BuddyMeshCore::BuddyFilter();
    return f;
}

bool BuddyMeshSnap(Map const* map, BuddyRoam::Point const& at, float reach, float rise, BuddyRoam::Point& out)
{
    dtNavMeshQuery const* q = Query(map);
    return q && BuddyMeshCore::Snap(q, Filter(), at, reach, rise, out);
}

bool BuddyMeshLineClear(Map const* map, BuddyRoam::Point const& from, BuddyRoam::Point const& to)
{
    dtNavMeshQuery const* q = Query(map);
    return q && BuddyMeshCore::LineClear(q, Filter(), from, to, BuddyMeshCore::LINE_ON_MESH, BuddyMeshCore::LINE_RISE);
}

struct KindRow { uint32 mask; BuddyRouteKind kind; };
static KindRow const sKinds[] = {
    { PATHFIND_NOT_USING_PATH, BuddyRouteKind::Shortcut },
    { PATHFIND_FARFROMPOLY,    BuddyRouteKind::OffMesh  },
    { PATHFIND_NOPATH,         BuddyRouteKind::None     },
    { PATHFIND_SHORTCUT,       BuddyRouteKind::Shortcut },
    { PATHFIND_INCOMPLETE,     BuddyRouteKind::Partial  },
    { PATHFIND_SHORT,          BuddyRouteKind::Partial  },
    { PATHFIND_NORMAL,         BuddyRouteKind::Complete },
};

BuddyRouteKind BuddyMeshRoute(Player* bot, BuddyRoam::Point const& to, std::vector<BuddyRoam::Point>& points)
{
    PathGenerator path(bot);
    if (!path.CalculatePath(to.x, to.y, to.z))
        return BuddyRouteKind::None;
    uint32 type = uint32(path.GetPathType());
    BuddyRouteKind kind = BuddyRouteKind::None;
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

static constexpr float SIGHT_STEP = 2.0f;
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
