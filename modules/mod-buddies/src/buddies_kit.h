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

// Gives the kit to a buddy just made (before its first save). Returns what
// could not be given, empty when all is well, for the caller to log.
std::string BuddyGiveStartingKit(Player* buddy, uint32 ownerGuid);

#endif
