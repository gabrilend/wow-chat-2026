
#ifndef MOD_BUDDIES_CROSSING_H
#define MOD_BUDDIES_CROSSING_H

#include "Define.h"

class Player;

struct BuddyCrossingMove
{
    uint32 mapId    = 0;
    float  x        = 0.0f;
    float  y        = 0.0f;
    float  z        = 0.0f;
    bool   straight = false;
};

bool BuddyCrossingWanted(Player* bot, Player* owner);

bool BuddyTransportStop(uint32 entry, uint32 mapId, float x, float y, float reach, uint8& stop);

bool BuddyTransportStopSpot(uint32 entry, uint8 stop, uint32& mapId, float& x, float& y, float& z);

bool BuddyCrossingStep(Player* bot, Player* owner, BuddyCrossingMove& move);

void BuddyCrossingForget(Player* bot);

#endif
