
#ifndef MOD_BUDDIES_FOLLOW_H
#define MOD_BUDDIES_FOLLOW_H

#include <cstdint>

class Action;
class PlayerbotAI;
class Strategy;
class Trigger;

Strategy* NewBuddyFollowStrategy(PlayerbotAI* ai);
Trigger*  NewBuddyFollowDueTrigger(PlayerbotAI* ai);
Action*   NewBuddyFollowStepAction(PlayerbotAI* ai);

bool BuddyFollowTrackAhead(uint32_t player, float x, float y, float& outX, float& outY, float& outZ);

void     BuddyFollowSet(uint32_t buddy, uint32_t leader);
void     BuddyFollowStop(uint32_t buddy);
void     BuddyFollowRefuse(uint32_t buddy, uint32_t leader);
bool     BuddyFollowRefused(uint32_t buddy, uint32_t leader);
uint32_t BuddyFollowLeader(uint32_t buddy);
void     BuddyFollowSetRing(uint32_t buddy, bool ring);
bool     BuddyFollowRing(uint32_t buddy);
float    BuddyFollowRingYards(uint32_t leader);

#endif
