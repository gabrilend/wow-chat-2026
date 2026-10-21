/*
 * buddies_navmesh.h - questions a buddy asks the navigation mesh (issue
 * 617o).
 *
 * For a general audience: the navigation mesh is the server's map of
 * every spot a character can stand on, as a sheet of joined flat pieces
 * (built offline from the game's terrain, buildings and placed objects:
 * rocks, crystals, wreckage). The server's own walking searches it. The
 * buddy's planners used a different, coarser picture of the ground and
 * picked spots the walking couldn't reach (617o's origin), so every spot
 * and route is now checked here first. Three questions:
 *   the nearest standing spot - where on the mesh is closest to a point;
 *   the straight line         - can one walk straight from here to there
 *                               without leaving the mesh (no wall, cliff
 *                               or gap between);
 *   the route                 - the server's own path search, and whether
 *                               its answer is a complete route or one of
 *                               its fallbacks.
 */

#ifndef MOD_BUDDIES_NAVMESH_H
#define MOD_BUDDIES_NAVMESH_H

#include "Define.h"
#include "roam/buddy_roam_core.h"
#include <vector>

class Map;
class Player;

// {{{ BuddyMeshSnap
// The nearest spot on the mesh to `at`, searched within `reach` yards
// sideways and `rise` yards up or down. False when the map has no mesh,
// its tile isn't loaded, or nothing is that near; `out` is then untouched.
bool BuddyMeshSnap(Map const* map, BuddyRoam::Point const& at, float reach, float rise, BuddyRoam::Point& out);
// }}}

// {{{ BuddyMeshLineClear
// Whether a walker can go in a straight line from `from` to `to` over the
// mesh: both ends on the mesh and nothing (a wall, a cliff edge, a gap)
// between them. Answers along the ground, ignoring slope.
bool BuddyMeshLineClear(Map const* map, BuddyRoam::Point const& from, BuddyRoam::Point const& to);
// }}}

// {{{ BuddyMeshRoute
// The server's own path search from the bot to `to`, the same search its
// walking runs. The kinds, by what the walking would then do:
//   complete - a route over the mesh to the spot: walked along the mesh
//   partial  - the route ends short of the spot: walked part way, stopped
//   none     - no route: the server walks in a straight line, through walls
//   shortcut - the search was skipped or gave a straight line: the same
//   offmesh  - the start or the end is far from the mesh
// `points` gets the route (smoothed, about 4 yards apart) when complete.
enum class BuddyRouteKind : uint8 { Complete, Partial, None, Shortcut, OffMesh };
BuddyRouteKind BuddyMeshRoute(Player* bot, BuddyRoam::Point const& to, std::vector<BuddyRoam::Point>& points);
char const* BuddyRouteKindName(BuddyRouteKind kind);
// }}}

// {{{ BuddySightBlocker (617o5)
// What stops a straight look from `from` to `to`, both at eye height
// (BUDDY_EYE_YARDS above the given points): nothing, a placed object (a
// doodad: a rock, a crystal, wreckage; or a building), or the ground
// itself (a hill). `hit` gets where an object was struck, or the highest
// point of ground above the line. Objects are asked of the map's static
// collision models; ground of the terrain heights every 2 yards.
static constexpr float BUDDY_EYE_YARDS = 1.8f;
enum class BuddySight : uint8 { Clear, Object, Ground };
BuddySight BuddySightBlocker(Map const* map, uint32 phaseMask, BuddyRoam::Point const& from, BuddyRoam::Point const& to,
                             BuddyRoam::Point& hit);
// }}}

#endif
