
#ifndef MOD_BUDDIES_TOWN_H
#define MOD_BUDDIES_TOWN_H

#include <vector>

class Action;
class Item;
class PlayerbotAI;
class Strategy;
class Trigger;

Strategy* NewBuddyTravelStrategy(PlayerbotAI* ai);
Trigger*  NewBuddyTravelDueTrigger(PlayerbotAI* ai);
Action*   NewBuddyTravelStepAction(PlayerbotAI* ai);

Strategy* NewBuddyTownStrategy(PlayerbotAI* ai);
Trigger*  NewBuddyTownDueTrigger(PlayerbotAI* ai);
Action*   NewBuddyTownStepAction(PlayerbotAI* ai);

bool BuddyTownErrandUnderway(unsigned int buddyGuid);

bool BuddyTownFishing(unsigned int buddyGuid);

class Creature;
class Player;
float BuddyBagFullness(Player* bot);
float BuddyFullBagsShare();
void  BuddySellAtVendor(PlayerbotAI* ai, Player* bot, Creature* npc);
std::vector<Item*> BuddyDisposableItems(PlayerbotAI* ai, Player* bot);

#endif
