/*
 * buddies_kit.h - a new buddy's starting kit (issue 617a4): white gear,
 * food (and drink for mana users), level x 1 silver, and bags matching its
 * owner's bag slots. See buddies_kit.cpp.
 */

#ifndef MOD_BUDDIES_KIT_H
#define MOD_BUDDIES_KIT_H

#include "Define.h"
#include <string>

class Player;

// Gives the kit to a buddy just made (before its first save). `shape` is
// its talent shape (1-10, buddy_roster.profile), which with its class and
// level finds its gear in the "buddy-white" gearset (617r2). Returns what
// could not be given, empty when all is well, for the caller to log.
std::string BuddyGiveStartingKit(Player* buddy, uint32 ownerGuid, uint8 shape);

// Gives an existing buddy, in the world, the kit's gear for its level now
// (".buddy kit <name>"): the same choosing, replacing what it wears.
// Returns what could not be given.
std::string BuddyRegear(Player* buddy, uint8 shape);

#endif
