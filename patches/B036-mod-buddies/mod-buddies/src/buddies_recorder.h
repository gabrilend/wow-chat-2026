
#ifndef MOD_BUDDIES_RECORDER_H
#define MOD_BUDDIES_RECORDER_H

#include "Define.h"
#include <string>

class MotionTransport;
class Player;

enum BuddyBoardingKind : uint8
{
    BUDDY_BOARD_EMBARK    = 1,
    BUDDY_BOARD_DISEMBARK = 2,
};

enum BuddyBoardingStepFlag : uint8
{
    BUDDY_STEP_DECK = 0x01,
    BUDDY_STEP_JUMP = 0x02,
    BUDDY_STEP_LAND = 0x04,
    BUDDY_STEP_WALK = 0x08,
};

struct BuddyReplay
{
    uint32 id         = 0;
    uint32 next       = 0;
    uint64 legStarted = 0;
    uint32 legLimitMs = 0;
    uint8  retries    = 0;
};

struct BuddyBoardingStart
{
    uint32 mapId = 0;
    float  x = 0.0f, y = 0.0f, z = 0.0f, o = 0.0f;
};

bool BuddyBoardingPick(uint8 kind, uint32 entry, uint8 stop, Player* bot, BuddyReplay& replay, BuddyBoardingStart& start);

void BuddyBoardingRelease(uint32 buddyGuid);

enum class BuddyReplayResult : uint8 { Running, Done, Failed };
BuddyReplayResult BuddyReplayStep(Player* bot, MotionTransport* mt, BuddyReplay& replay, std::string& why);

#endif
