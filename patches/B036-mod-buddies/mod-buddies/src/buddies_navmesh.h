
#ifndef MOD_BUDDIES_NAVMESH_H
#define MOD_BUDDIES_NAVMESH_H

#include "Define.h"
#include "roam/buddy_roam_core.h"
#include <vector>

class Map;
class Player;

bool BuddyMeshSnap(Map const* map, BuddyRoam::Point const& at, float reach, float rise, BuddyRoam::Point& out);

bool BuddyMeshLineClear(Map const* map, BuddyRoam::Point const& from, BuddyRoam::Point const& to);

enum class BuddyRouteKind : uint8 { Complete, Partial, None, Shortcut, OffMesh };
BuddyRouteKind BuddyMeshRoute(Player* bot, BuddyRoam::Point const& to, std::vector<BuddyRoam::Point>& points);
char const* BuddyRouteKindName(BuddyRouteKind kind);

static constexpr float BUDDY_EYE_YARDS = 1.8f;
enum class BuddySight : uint8 { Clear, Object, Ground };
BuddySight BuddySightBlocker(Map const* map, uint32 phaseMask, BuddyRoam::Point const& from, BuddyRoam::Point const& to,
                             BuddyRoam::Point& hit);

#endif
