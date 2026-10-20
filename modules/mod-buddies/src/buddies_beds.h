
#ifndef MOD_BUDDIES_BEDS_H
#define MOD_BUDDIES_BEDS_H

#include "Define.h"
#include <vector>

struct BuddyBed
{
    uint32 id     = 0;
    uint32 map    = 0;
    float  x      = 0.0f;
    float  y      = 0.0f;
    float  z      = 0.0f;
    float  facing = 0.0f;
    uint32 area   = 0;
    uint8  tier   = 1;
    uint32 link   = 0;
};

enum BuddyBedTier : uint8
{
    BUDDY_BED_FLOOR = 1,
    BUDDY_BED_COT   = 2,
    BUDDY_BED_BED   = 3,
};

std::vector<BuddyBed> BuddyBedsInArea(uint32 map, uint32 area);

bool BuddyClaimBed(uint32 bedId, uint32 buddyGuid, uint32 clanGuid, uint32 holdMs);
void BuddyReleaseBed(uint32 bedId, uint32 buddyGuid);

bool BuddyBedIsEmptyDouble(BuddyBed const& bed);

void AddSC_buddies_beds();

#endif
