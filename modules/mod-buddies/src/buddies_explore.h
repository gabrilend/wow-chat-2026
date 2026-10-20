
#ifndef MOD_BUDDIES_EXPLORE_H
#define MOD_BUDDIES_EXPLORE_H

#include "Define.h"
#include "roam/buddy_roam_core.h"
#include <string>
#include <vector>

class ChatHandler;
class Player;

enum BuddyExploreMode : uint8
{
    BUDDY_EXPLORE_PINWHEEL = 0,
    BUDDY_EXPLORE_LEAST    = 1,
    BUDDY_EXPLORE_ROOMS    = 2,
    BUDDY_EXPLORE_DISC     = 3,
    BUDDY_EXPLORE_MIXED    = 4,
};

BuddyExploreMode BuddyExploreModeFor(uint32 ownerGuid, uint32 buddyGuid);

bool BuddyExploreNext(Player* bot, Player* owner, uint32 areaId, std::vector<BuddyRoam::Point>& path,
                      BuddyExploreMode forced = BUDDY_EXPLORE_PINWHEEL);

bool BuddyExploreHandleCommand(ChatHandler* handler, std::string const& word);

bool BuddyExploreStepToward(Player* bot, Player* owner, uint32 areaId, BuddyRoam::Point const& goal, float lookahead,
                            BuddyRoam::Point& next);

enum class BuddyHillChoice : uint8 { NearestMiddle, InTheWay, NearestBuddy };
bool BuddyExploreHilltop(Player* bot, Player* owner, uint32 areaId, BuddyHillChoice choice, BuddyRoam::Point const& middle,
                         BuddyRoam::Point& top);
bool BuddyExploreObstacle(Player* owner, uint32 areaId, BuddyRoam::Point const& hit, BuddyRoam::Point& centre, float& reach);

#endif
