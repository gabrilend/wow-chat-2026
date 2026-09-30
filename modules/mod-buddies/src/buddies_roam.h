/*
 * buddies_roam.h - what the roaming and grouping files share (issues
 * 617e1, 617e2, 617c2).
 *
 * For a general audience: roaming is split in three. The roaming core
 * (roam/buddy_roam_core.h) decides where a buddy goes and knows nothing of
 * the server; the ground (buddies_roam_ground.cpp) answers its questions
 * about the real map; the strategy (buddies_roam_strategy.cpp) makes the
 * bot walk it; the party pass (buddies_party.cpp) groups buddies by
 * distance. This header is what they need of each other: which online
 * characters are buddies and whose, whether an area is a town, the ground
 * over a map, and a named area's centre.
 */

#ifndef MOD_BUDDIES_ROAM_H
#define MOD_BUDDIES_ROAM_H

#include "Define.h"
#include "roam/buddy_roam_core.h"
#include <utility>
#include <vector>

class Map;
class Player;

// {{{ the roster, as the passes see it
// Every made buddy and its owner (character guids, low part), read from
// buddy_roster at most every 10 seconds and kept in memory between reads
// (buddies_roam_ground.cpp). Called only from the world thread (the
// passes run in world-update hooks).
std::vector<std::pair<uint32, uint32>> const& BuddyRosterPairs();
// }}}

// {{{ BuddyAreaIsTown
// Whether a named area is a town or city by the client's area flags: town
// (0x00200000, "small towns with Inn"), capital (0x00000100) or a capital's
// subzone (0x00000008) (the owner's rule, 2026-09-25, 617e). An unknown
// area id is not a town.
bool BuddyAreaIsTown(uint32 areaId);
// }}}

// {{{ BuddyTownArea
// The town a player is in, or 0. A building inside a town often has its
// own area number without the town flag (an inn, a crypt, a guild hall);
// indoors, the ground outside at that spot says whose building it is.
// So a player indoors counts as in the town their building stands in, and
// buddies keep their town manners there instead of taking the building
// for a separate place to roam (owner, 2026-09-29: "make sure we account
// for indoors areas inside of towns"). Returns the town's own area number,
// the same for everyone anywhere inside it.
uint32 BuddyTownArea(Player* who);
// }}}

// {{{ BuddyRoamGround
// The core's four questions answered over a map, for one named area and
// phase (see roam/buddy_roam_core.h, Ground). Heights are searched from
// just above the hint, not from the sky.
BuddyRoam::Ground BuddyRoamGround(Map const* map, uint32 phaseMask, uint32 areaId, BuddyRoam::Settings const& settings);
// }}}

// {{{ BuddyAreaCentre
// The centre of the named area `areaId` on `map`, for an owner standing at
// `from`: the middle of the area's piece the owner is in, from the table
// buddy_area_centre (made at install time from the map files, install step
// E044; loaded once, on the first call), its height the ground under it
// searched down from just above the owner (a mine's middle lies under a
// hill). False (logged) when the area has no row (reported once per area)
// or there is no ground under the middle; true with `out` filled
// otherwise. Safe to call from the map threads.
bool BuddyAreaCentre(Map const* map, uint32 phaseMask, uint32 areaId, float fromX, float fromY, float fromZ,
                     BuddyRoam::Area& out);
// }}}

// {{{ BuddyAreaPieceAt
// The piece of a named area an owner at (fromX, fromY) is in (the same
// choice BuddyAreaCentre makes), with its borders from buddy_area_centre:
// what the exploring grid is laid over (617e6). `piece` is its place in the
// area's list (0 the largest), to tell pieces apart. False when the area
// has no row (reported once, as for the centre).
struct BuddyAreaPieceInfo
{
    uint32 piece = 0;
    float  minX = 0.0f, maxX = 0.0f, minY = 0.0f, maxY = 0.0f;
};
bool BuddyAreaPieceAt(uint32 mapId, uint32 areaId, float fromX, float fromY, BuddyAreaPieceInfo& out);
// }}}

#endif
