/*
 * buddies_spawn_zones.h - where each kind of creature lives (issue 617e13,
 * question 1): its spawn zone, read from the world's spawn table.
 *
 * For a general audience: the owner, 2026-10-30, on which monsters
 * buddies spread over while questing: "any monsters that are in the same
 * spawn-zone as the player. Remember, there are overlapping spawn-zones."
 * A kind of creature's spawn zone is the ground round its spawn points:
 * a circle round each, as wide as the creature wanders from its point plus
 * SPAWN_ZONE_MARGIN yards (at least SPAWN_ZONE_MIN_YARDS). Where kinds live
 * side by side their zones overlap, and a spot can be in several.
 */

#ifndef MOD_BUDDIES_SPAWN_ZONES_H
#define MOD_BUDDIES_SPAWN_ZONES_H

#include "Define.h"
#include <vector>

// {{{ BuddyInSpawnZone
// Whether (x, y) on map `mapId` lies in the spawn zone of creature kind
// `entry` (creature_template id): within a circle round one of its spawn
// points. The spawn table is read once, the first time anyone asks (a
// pass over every spawn, under a lock); afterwards each answer is a look
// at that kind's own points. Called from the map threads.
bool BuddyInSpawnZone(uint32 mapId, uint32 entry, float x, float y);
// }}}

// {{{ BuddySpawnZonesAt
// Every monster kind whose spawn zone holds (x, y) on map `mapId`, into
// `kinds` (emptied first; empty: no monster lives here, a road or a town).
void BuddySpawnZonesAt(uint32 mapId, float x, float y, std::vector<uint32>& kinds);
// }}}

// {{{ BuddySharesSpawnZone
// Whether (x, y) lies in the spawn zone of any of `kinds` (as
// BuddySpawnZonesAt gives them for another spot): the two spots hold the
// same monster spawns.
bool BuddySharesSpawnZone(uint32 mapId, std::vector<uint32> const& kinds, float x, float y);
// }}}

#endif
