/*
 * buddies_explore.h - the four ways a buddy explores, in game (issue 617e6).
 *
 * For a general audience: the owner asked for every exploring system from
 * the gallery in game at once, "to see what kind of mechanics they create".
 * A buddy explores its owner's area by one of four: the pinwheel (the
 * roaming core, as before), least paint, the room orbit, or the squished
 * circle (roam/buddy_explore_core.h). The owner chooses with a chat
 * command, ".buddy explore <pinwheel|paint|rooms|disc|mixed>" (mixed: the
 * buddies take the four in turn, so they can be watched side by side),
 * remembered for the session. This header is what the roam action and the
 * command need from buddies_explore.cpp.
 */

#ifndef MOD_BUDDIES_EXPLORE_H
#define MOD_BUDDIES_EXPLORE_H

#include "Define.h"
#include "roam/buddy_roam_core.h"
#include <string>
#include <vector>

class ChatHandler;
class Player;

// {{{ the modes
enum BuddyExploreMode : uint8
{
    BUDDY_EXPLORE_PINWHEEL = 0,   // the roaming core's pinwheel (617e2)
    BUDDY_EXPLORE_LEAST    = 1,   // least paint, walls painting a fringe
    BUDDY_EXPLORE_ROOMS    = 2,   // the pinwheel round the room it is in
    BUDDY_EXPLORE_DISC     = 3,   // the pinwheel on the squished circle
    BUDDY_EXPLORE_MIXED    = 4,   // the owner's setting only: the buddies take the four in turn
};
// }}}

// The mode this buddy explores by: the owner's setting, with "mixed" given
// out in turn over the owner's buddies (by character number). Pinwheel
// until the owner chooses.
BuddyExploreMode BuddyExploreModeFor(uint32 ownerGuid, uint32 buddyGuid);

// The next waypoint and path for a buddy exploring by paint, least paint,
// rooms or disc, in its owner's area: true with `path` filled (the last
// point the waypoint), false when the area's grid is not ready yet (being
// built: the caller walks the pinwheel meanwhile, logged once per area) or
// nothing can be chosen. Called from the roam action (a map thread).
// `forced`: a mode the roam action needs whatever the owner chose (rooms,
// indoors and where the pinwheel finds nothing); PINWHEEL means none.
bool BuddyExploreNext(Player* bot, Player* owner, uint32 areaId, std::vector<BuddyRoam::Point>& path,
                      BuddyExploreMode forced = BUDDY_EXPLORE_PINWHEEL);

// ".buddy explore <mode>", registered in buddies_beds.cpp's "buddy" table.
bool BuddyExploreHandleCommand(ChatHandler* handler, std::string const& word);

// {{{ BuddyExploreStepToward (617o3)
// A spot about `lookahead` yards along the shortest walk from the buddy to
// `goal` over the area's exploring grid (whose steps the navigation mesh
// allows), from a distance map baked for that goal on first use and kept.
// False while the area's grid is still being measured (asking starts the
// measuring), or when the goal or the buddy is off its floor, or no joined
// way links them; the caller then walks its own way.
bool BuddyExploreStepToward(Player* bot, Player* owner, uint32 areaId, BuddyRoam::Point const& goal, float lookahead,
                            BuddyRoam::Point& next);
// }}}

// {{{ the view (617o5)
// Which hill a buddy with no sight of the area's middle climbs; the owner,
// 2026-10-03, of the three: "one of these three randomly".
enum class BuddyHillChoice : uint8 { NearestMiddle, InTheWay, NearestBuddy };
// The top of that hill on the area's grid (at least a few yards above the
// buddy, reachable from it over the grid's joins); false when there is
// none, or the grid isn't ready.
bool BuddyExploreHilltop(Player* bot, Player* owner, uint32 areaId, BuddyHillChoice choice, BuddyRoam::Point const& middle,
                         BuddyRoam::Point& top);
// The object a look struck at `hit`, as the grid sees it: the patch of
// non-floor cells round it. `centre` is that patch's middle, `reach` the
// distance from there to its farthest part (the owner: "From it's center
// to it's most distant component"). False when the grid isn't ready, or
// the patch is too big to walk round (a cliff, a wall) or runs off the grid.
bool BuddyExploreObstacle(Player* owner, uint32 areaId, BuddyRoam::Point const& hit, BuddyRoam::Point& centre, float& reach);
// }}}

#endif
