
#ifndef MOD_BUDDIES_PATH_H
#define MOD_BUDDIES_PATH_H

#include "Define.h"
#include "roam/buddy_path_ways.h"
#include "roam/buddy_roam_core.h"

class Player;

bool BuddyPathWayFor(uint32 ownerGuid, BuddyPath::Way& way);

enum class BuddyPathStep : uint8 { Walking, Arrived, GaveUp };
static constexpr float  BUDDY_PATH_ARRIVED    = 3.0f;
static constexpr uint32 BUDDY_PATH_GIVE_UP_MS = 90000;
BuddyPathStep BuddyPathWalk(Player* bot, BuddyPath::Way way, BuddyRoam::Point const& goal);

void BuddyPathForget(uint32 buddyGuid);

void AddSC_buddies_path();

#endif
