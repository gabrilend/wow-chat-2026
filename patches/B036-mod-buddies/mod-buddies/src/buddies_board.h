
#ifndef MOD_BUDDIES_BOARD_H
#define MOD_BUDDIES_BOARD_H

#include "Define.h"
#include "ObjectGuid.h"

class Player;

bool BuddyBoardHas(Player* buddy, ObjectGuid thing);

void BuddyBoardCount(Player* buddy, uint32& players, uint32& buddies, uint32& creatures);

#endif
