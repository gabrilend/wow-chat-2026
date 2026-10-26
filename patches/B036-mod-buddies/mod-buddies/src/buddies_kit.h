
#ifndef MOD_BUDDIES_KIT_H
#define MOD_BUDDIES_KIT_H

#include "Define.h"
#include <string>

class Player;

std::string BuddyGiveStartingKit(Player* buddy, uint32 ownerGuid, uint8 shape);

std::string BuddyRegear(Player* buddy, uint8 shape);

std::string BuddyGivePvpJewellery(Player* who, uint8 shape, uint8 role);
static constexpr uint8 BUDDY_PVP_JEWELLERY_FROM = 18;

#endif
