
#ifndef MOD_BUDDIES_GEMS_H
#define MOD_BUDDIES_GEMS_H

#include "Define.h"
#include "ObjectGuid.h"
#include <string>

class Creature;
class Player;

std::string BuddyGemKit(Player* buddy, uint8 profile, uint8 role);

uint32 BuddyBuyGemsAtAuction(Player* bot, Creature* auctioneer);

void BuddyItemArrived(uint32 buddyGuid, ObjectGuid item);

void AddSC_buddies_gems();

#endif
