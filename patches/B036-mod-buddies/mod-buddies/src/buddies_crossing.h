/*
 * buddies_crossing.h - what the crossing file offers "buddy travel" (issue
 * 617e8).
 *
 * For a general audience: a buddy walks to its owner anywhere on one map
 * (617e4). This file is what it does when the owner is on another map
 * altogether - across the sea, or through the Dark Portal: it works out
 * how to get there (the boat its owner took, the portal its owner stepped
 * through, a mage's own teleport, or the nearest boat or portal that goes
 * there), and handles waiting on the dock, boarding, riding and stepping
 * off. The walking itself stays with "buddy travel", which owns the bot
 * module's long walk; this file only says where to walk.
 */

#ifndef MOD_BUDDIES_CROSSING_H
#define MOD_BUDDIES_CROSSING_H

#include "Define.h"

class Player;

// {{{ BuddyCrossingMove
// Where "buddy travel" should walk this step.
//   mapId, x, y, z - the spot (always on the buddy's own map)
//   straight       - true: a straight line, ignoring the navigation mesh
//                    (onto a deck or off it, where the mesh has no ground);
//                    false: the bot module's long walk on the mesh
struct BuddyCrossingMove
{
    uint32 mapId    = 0;
    float  x        = 0.0f;
    float  y        = 0.0f;
    float  z        = 0.0f;
    bool   straight = false;
};
// }}}

// Whether the crossing has something for this buddy now: it is aboard a
// boat or zeppelin, or its owner is on another map that is not an instance
// (dungeons are the dungeon draw's, 617c3), or its owner is waiting to sail
// from a dock on the buddy's own map (the same ship, 617e8) and the buddy
// isn't partway through a town errand; and it isn't paused after a failure.
bool BuddyCrossingWanted(Player* bot, Player* owner);

// Which stop of a boat's or zeppelin's route lies within `reach` yards
// (flat distance) of x, y on mapId: its index in the route's stops, which is
// how boarding recordings name their stop (617e9). False when none does.
bool BuddyTransportStop(uint32 entry, uint32 mapId, float x, float y, float reach, uint8& stop);

// Where that stop is (the ship's own position when docked there). False
// when the ship or the stop is unknown.
bool BuddyTransportStopSpot(uint32 entry, uint8 stop, uint32& mapId, float& x, float& y, float& z);

// One step of the crossing. True, with `move` filled: walk there. False:
// the step was handled here (holding still aboard or on the dock, boarding,
// stepping off, casting a teleport, stepping into a portal, or a failure
// that pauses the buddy, logged).
bool BuddyCrossingStep(Player* bot, Player* owner, BuddyCrossingMove& move);

// The buddy is on its owner's map again: its crossing is over.
void BuddyCrossingForget(Player* bot);

#endif
