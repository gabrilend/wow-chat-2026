
#ifndef MOD_BUDDIES_ROAM_H
#define MOD_BUDDIES_ROAM_H

#include "Define.h"
#include "roam/buddy_roam_core.h"
#include <utility>
#include <vector>

class Map;
class Player;

std::vector<std::pair<uint32, uint32>> const& BuddyRosterPairs();

bool BuddyAreaIsTown(uint32 areaId);

uint32 BuddyTownCircleArea(Player* who);

uint32 BuddyTownArea(Player* who);

BuddyRoam::Ground BuddyRoamGround(Map const* map, uint32 phaseMask, uint32 areaId, BuddyRoam::Settings const& settings);

bool BuddyAreaCentre(Map const* map, uint32 phaseMask, uint32 areaId, float fromX, float fromY, float fromZ,
                     BuddyRoam::Area& out);

struct BuddyAreaPieceInfo
{
    uint32 piece = 0;
    float  minX = 0.0f, maxX = 0.0f, minY = 0.0f, maxY = 0.0f;
};
bool BuddyAreaPieceAt(uint32 mapId, uint32 areaId, float fromX, float fromY, BuddyAreaPieceInfo& out);

#endif
