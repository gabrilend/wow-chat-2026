/*
 * buddies_steer.h - steering toward a moving target (issue 617o4).
 *
 * For a general audience: chasing something that moves (a wandering
 * monster) doesn't need a full route search every step. Twice a second the
 * buddy looks again where the target is: if the navigation mesh says the
 * straight line there is clear, it goes straight; if not, it takes the
 * mesh's route (617o1). When it stops to face something, it turns over
 * 0.4 seconds in small steps rather than snapping round (the owner,
 * 2026-10-03: "lerping the orientation to the intended direction over
 * 2/5ths of a second").
 */

#ifndef MOD_BUDDIES_STEER_H
#define MOD_BUDDIES_STEER_H

#include "Define.h"
#include "roam/buddy_roam_core.h"

class Creature;
class Map;
class Player;

static constexpr uint32 BUDDY_STEER_MS = 500;   // a moving target is aimed at again this often
static constexpr uint32 BUDDY_TURN_MS  = 400;   // a turn to face something takes this long

// {{{ BuddySteerFacing
// The facing `elapsedMs` into a turn from `from` to `to` (radians), along
// the shorter way round, reaching `to` at BUDDY_TURN_MS and staying there.
float BuddySteerFacing(float from, float to, uint32 elapsedMs);
// }}}

// {{{ BuddySteerEdge
// The spot at the edge of the circle of `radius` yards round `centre`, on
// the side facing `from`: where a buddy stands to be just outside a
// monster's notice. Its height is `centre`'s; the caller puts it on the mesh.
BuddyRoam::Point BuddySteerEdge(BuddyRoam::Point const& centre, BuddyRoam::Point const& from, float radius);
// }}}

// {{{ BuddyNoticeRadius
// How near the buddy can come before this monster would notice it: the
// server's own aggro radius for the pair (Creature::GetAggroRange: the
// monster's detection range, a yard less per level the buddy is above it
// and more per level below, the detection auras of both, 5 to 45 yards).
// The server never applies it to a neutral monster, but the number is the
// same kind of thing for one (617e3). 0 when the server has aggro off.
float BuddyNoticeRadius(Creature const* monster, Player const* bot);
// }}}

// {{{ the turn rule (the owner, 2026-10-03)
// "anytime we turn toward a new point or waypoint, we should always have
// lerping orientation smoothing. If we are stopped while turning, we
// shouldn't start until we're facing the right direction. If we're moving
// while turning, we can keep moving until we're pointed the right way."
//
// BuddyTurnToward: before a buddy sets off toward a new point. Facing
// within BUDDY_TURN_MIN of `want` already: nothing to do, false. Standing:
// it turns in place over BUDDY_TURN_MS (a small facing step at every
// player update, about every 50 ms) and the caller waits. Moving: it is sent along a
// short curve whose heading swings from its own to `want` over
// BUDDY_TURN_MS of travel, each bend on the navigation mesh; a curve the
// mesh refuses (a wall beside it) stops it and turns it in place instead.
// True while a turn is under way: the caller gives no new order until
// BuddyTurnBusy says it is done.
static constexpr float BUDDY_TURN_MIN = 0.17f;   // radians (about 10 degrees): less is not a turn
bool BuddyTurnToward(Player* bot, float want);
bool BuddyTurnBusy(Player const* bot);
void AddSC_buddies_steer();
// }}}

#endif
