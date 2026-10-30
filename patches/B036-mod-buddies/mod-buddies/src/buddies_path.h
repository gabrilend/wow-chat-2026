/*
 * buddies_path.h - the switch between five ways for buddies to find their
 * way (issue 617o7), in game.
 *
 * For a general audience: the owner wanted to try, herself, several very
 * different ways a buddy finds its way to where it is going ("make sure
 * that all of them are viewable in-game. I want to test them myself"), by
 * one switch after one compile. ".buddy path <way>" picks the way for the
 * speaker's buddies: orbit, flow, astar, potential, learn, paint (the
 * painted map, 617o8: one map a region of the world, shared by every buddy
 * there, learned from their steps and the mesh's refusals), or mesh (the
 * server's own walking, as before; the default). With a way picked, a
 * roaming buddy no longer hands its waypoint to the server's path search:
 * a grid of the walkable ground round it and the waypoint is filled from
 * the navigation mesh, the chosen way (roam/buddy_path_ways.h, the same
 * arithmetic the offline test checks) gives the next point a few yards
 * on, and the buddy is sent there in a straight line. A step the mesh
 * says would cross a wall, a cliff or a gap is refused, not walked
 * (without that the server would walk it straight through), and the way
 * is told, as the offline test's world tells it. ".buddy path" alone says
 * which way is picked and how each way has done so far.
 */

#ifndef MOD_BUDDIES_PATH_H
#define MOD_BUDDIES_PATH_H

#include "Define.h"
#include "roam/buddy_path_ways.h"
#include "roam/buddy_roam_core.h"

class Player;

// {{{ BuddyPathWayFor
// The way picked for this owner's buddies; false when none is (mesh: the
// server's own walking, as before the switch).
bool BuddyPathWayFor(uint32 ownerGuid, BuddyPath::Way& way);
// }}}

// {{{ BuddyPathWalk
// One step of walking `bot` to `goal` by `way`, called on each of the
// roam action's ticks while the waypoint holds. Walking: under way (an
// order given, a refused step taken note of, or waiting for the last
// order); Arrived: within BUDDY_PATH_ARRIVED yards of the goal; GaveUp:
// not there in BUDDY_PATH_GIVE_UP_MS, or no walkable ground under the
// buddy to fill a grid from (the caller drops the waypoint, as it does a
// mesh route that isn't complete). A new goal or way starts afresh.
enum class BuddyPathStep : uint8 { Walking, Arrived, GaveUp };
static constexpr float  BUDDY_PATH_ARRIVED    = 3.0f;
static constexpr uint32 BUDDY_PATH_GIVE_UP_MS = 90000;
BuddyPathStep BuddyPathWalk(Player* bot, BuddyPath::Way way, BuddyRoam::Point const& goal);
// }}}

// {{{ BuddyPathForget
// A buddy's walk is over (its waypoint reached, dropped, or roaming
// stopped): its grid and walker are let go.
void BuddyPathForget(uint32 buddyGuid);
// }}}

void AddSC_buddies_path();

#endif
