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

// Gives the kit to a buddy just made (before its first save). `mainTree` is
// its talent plan's main tree (0-2, in the talent window's order; -1 with
// no plan), which picks its weapons. Returns what could not be given, empty
// when all is well, for the caller to log.
std::string BuddyGiveStartingKit(Player* buddy, uint32 ownerGuid, int8 mainTree);

// Gives an existing buddy, in the world, the kit's gear for its level now
// (".buddy kit <name>"): the same choosing, replacing what it wears.
// Returns what could not be given.
std::string BuddyRegear(Player* buddy, int8 mainTree);

#endif
