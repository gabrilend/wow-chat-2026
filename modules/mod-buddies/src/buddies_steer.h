
#ifndef MOD_BUDDIES_STEER_H
#define MOD_BUDDIES_STEER_H

#include "Define.h"
#include "roam/buddy_roam_core.h"

class Creature;
class Map;
class Player;

static constexpr uint32 BUDDY_STEER_MS = 500;
static constexpr uint32 BUDDY_TURN_MS  = 400;

float BuddySteerFacing(float from, float to, uint32 elapsedMs);

BuddyRoam::Point BuddySteerEdge(BuddyRoam::Point const& centre, BuddyRoam::Point const& from, float radius);

float BuddyNoticeRadius(Creature const* monster, Player const* bot);

static constexpr float BUDDY_TURN_MIN = 0.17f;
bool BuddyTurnToward(Player* bot, float want);
bool BuddyTurnBusy(Player const* bot);
void AddSC_buddies_steer();

#endif
