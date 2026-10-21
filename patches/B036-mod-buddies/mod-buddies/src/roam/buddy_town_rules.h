/*
 * buddy_town_rules.h - which areas are towns to a buddy, shared by the
 * server (BuddyAreaIsTown, buddies_roam_ground.cpp) and the town baker
 * (issues 617e, 617o3), with no server code, so both pick the same towns.
 *
 * For a general audience: a town is an area the client's area table flags
 * as a town, a capital, or part of a capital (the owner's rule,
 * 2026-09-25, 617e), except the starting valleys, which are countryside
 * to a buddy whatever the table says. Seven of the eight carry the table's
 * "town" flag (AreaTable.dbc, read 2026-09-29: Northshire, Deathknell,
 * Shadowglen, Red Cloud Mesa, Valley of Trials, Sunstrider Isle, Ammen
 * Vale; Coldridge Valley alone does not), so a buddy in one ran the town
 * visit -- errands and fishing -- instead of roaming beside a new
 * character (owner, 2026-09-29: "she's trying to fish...? But, we're not
 * in a town! We're in Ammen Vale!").
 */

#ifndef BUDDY_TOWN_RULES_H
#define BUDDY_TOWN_RULES_H

#include <cstdint>

namespace BuddyTownRules
{
static constexpr uint32_t STARTING_VALLEY_AREAS[] = { 9, 132, 154, 188, 220, 363, 3431, 3526 };

// the client's area flags (the server's DBCEnums.h)
static constexpr uint32_t AREA_FLAG_SLAVE_CAPITAL = 0x00000008;   // a capital's subzone
static constexpr uint32_t AREA_FLAG_CAPITAL       = 0x00000100;
static constexpr uint32_t AREA_FLAG_TOWN          = 0x00200000;   // small towns with an inn

inline bool IsTown(uint32_t areaId, uint32_t areaFlags)
{
    for (uint32_t valley : STARTING_VALLEY_AREAS)
        if (areaId == valley)
            return false;                              // a starting valley: open country
    return (areaFlags & (AREA_FLAG_TOWN | AREA_FLAG_CAPITAL | AREA_FLAG_SLAVE_CAPITAL)) != 0;
}
}

#endif
