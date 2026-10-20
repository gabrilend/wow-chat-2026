
#ifndef BUDDY_TOWN_RULES_H
#define BUDDY_TOWN_RULES_H

#include <cstdint>

namespace BuddyTownRules
{
static constexpr uint32_t STARTING_VALLEY_AREAS[] = { 9, 132, 154, 188, 220, 363, 3431, 3526 };

static constexpr uint32_t AREA_FLAG_SLAVE_CAPITAL = 0x00000008;
static constexpr uint32_t AREA_FLAG_CAPITAL       = 0x00000100;
static constexpr uint32_t AREA_FLAG_TOWN          = 0x00200000;

inline bool IsTown(uint32_t areaId, uint32_t areaFlags)
{
    for (uint32_t valley : STARTING_VALLEY_AREAS)
        if (areaId == valley)
            return false;
    return (areaFlags & (AREA_FLAG_TOWN | AREA_FLAG_CAPITAL | AREA_FLAG_SLAVE_CAPITAL)) != 0;
}
}

#endif
