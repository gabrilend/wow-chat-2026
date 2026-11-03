
#ifndef MOD_BUDDIES_SOLO_H
#define MOD_BUDDIES_SOLO_H

#include "Define.h"

class Creature;
class Player;

bool BuddySoloCanTake(Player* bot, Creature* foe, uint32 allies);

void BuddySoloForget(uint32 buddyGuid);

#endif
