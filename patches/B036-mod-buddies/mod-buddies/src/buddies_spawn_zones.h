
#ifndef MOD_BUDDIES_SPAWN_ZONES_H
#define MOD_BUDDIES_SPAWN_ZONES_H

#include "Define.h"
#include <vector>

bool BuddyInSpawnZone(uint32 mapId, uint32 entry, float x, float y);

void BuddySpawnZonesAt(uint32 mapId, float x, float y, std::vector<uint32>& kinds);

bool BuddySharesSpawnZone(uint32 mapId, std::vector<uint32> const& kinds, float x, float y);

#endif
