
#ifndef MOD_BUDDIES_SPELLS_H
#define MOD_BUDDIES_SPELLS_H

#include "Define.h"
#include <string>

class Creature;
class Player;

uint32 BuddyTrainAtTrainer(Player* bot, Creature* trainer);

uint32 BuddyWeaponAllowance(uint32 ownerGuid);
bool BuddyLearnWeaponKind(Player* bot, uint32 skill, std::string& why);
uint32 BuddyFillWeaponKinds(Player* bot, uint32 allowance);

uint32 BuddyLearnEverything(Player* bot);

uint32 BuddyRaiseProfessions(Player* bot, std::string& problems);

uint32 BuddyForgetLessons(Player* bot);

void AddSC_buddies_spells();

#endif
