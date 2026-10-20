
#ifndef BUDDY_MESH_CORE_H
#define BUDDY_MESH_CORE_H

#include "buddy_roam_core.h"
#include "DetourNavMesh.h"
#include "DetourNavMeshQuery.h"

namespace BuddyMeshCore
{
enum : unsigned short { NAV_GROUND = 0x01, NAV_MAGMA = 0x02, NAV_SLIME = 0x04, NAV_WATER = 0x08 };

static constexpr float LINE_ON_MESH = 2.0f;
static constexpr float LINE_RISE    = 4.0f;

inline dtQueryFilter BuddyFilter()
{
    dtQueryFilter f;
    f.setIncludeFlags(NAV_GROUND | NAV_WATER);
    f.setExcludeFlags(NAV_MAGMA | NAV_SLIME);
    return f;
}

inline bool Snap(dtNavMeshQuery const* q, dtQueryFilter const& f, BuddyRoam::Point const& at, float reach, float rise,
                 BuddyRoam::Point& out)
{
    float const centre[3] = { at.y, at.z, at.x };
    float const extent[3] = { reach, rise, reach };
    float near[3];
    dtPolyRef ref = 0;
    if (dtStatusFailed(q->findNearestPoly(centre, extent, &f, &ref, near)) || !ref)
        return false;
    out = { near[2], near[0], near[1] };
    return true;
}

inline bool LineClear(dtNavMeshQuery const* q, dtQueryFilter const& f, BuddyRoam::Point const& from,
                      BuddyRoam::Point const& to, float onMesh, float rise)
{
    float const ext[3] = { onMesh, rise, onMesh };
    float const a[3]   = { from.y, from.z, from.x };
    float const b[3]   = { to.y, to.z, to.x };
    float onA[3], onB[3];
    dtPolyRef refA = 0, refB = 0;
    if (dtStatusFailed(q->findNearestPoly(a, ext, &f, &refA, onA)) || !refA)
        return false;
    if (dtStatusFailed(q->findNearestPoly(b, ext, &f, &refB, onB)) || !refB)
        return false;
    float t = 0.0f, normal[3];
    dtPolyRef visited[64];
    int count = 0;
    if (dtStatusFailed(q->raycast(refA, onA, onB, &f, &t, normal, visited, &count, 64)))
        return false;
    return t > 1.0f;
}
}

#endif
