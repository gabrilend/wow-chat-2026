
#ifndef MOD_BUDDIES_LOOT_H
#define MOD_BUDDIES_LOOT_H

#include "Define.h"
#include "StatsCollector.h"

class Player;
struct ItemTemplate;
enum RollVote : uint8;

bool BuddyTalentPlan(Player* player, uint8 (&thirds)[3], CollectorType (&types)[3]);

bool BuddyPlanShape(uint8 cls, uint8 profile, uint8 role, uint8 (&thirds)[3], CollectorType (&types)[3]);

float BuddySpiritWorth(Player* player);

int8 BuddyPlanMainTree(uint8 profile);

RollVote BuddyLootRollVote(Player* bot, ItemTemplate const* proto, int32 randomProperty, RollVote judged, RollVote configured);

#endif
