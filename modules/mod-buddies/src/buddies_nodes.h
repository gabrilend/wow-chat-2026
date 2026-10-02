/*
 * buddies_nodes.h - herb and ore nodes no one can walk to (issue 617e3).
 *
 * For a general audience: a buddy that sees a vein it can't reach (the
 * ground's walking map has no path ending within arm's reach of it) does
 * not stand under it; the vein is moved to the nearest free spawn spot of
 * its own group, and its old spot is retired for good, for everyone. This
 * header is what the roaming code asks and tells.
 */

#ifndef MOD_BUDDIES_NODES_H
#define MOD_BUDDIES_NODES_H

#include "Define.h"
#include <string>

// Whether this game-object spawn (its database id) is a retired spot. Safe
// from any thread (the bot's AI runs on map threads).
bool BuddyNodeRetired(uint32 spawnId);

// Retire this herb or ore spawn: recorded, moved to the nearest free spot
// of its spawn group, never spawned again. Queued and carried out on the
// world's thread, outside map updates, because it changes the pool
// manager's state. `why` is the buddy's account of the failed path, for
// the log. Safe from any thread.
void BuddyRetireNode(uint32 spawnId, uint32 buddyGuid, std::string const& why);

#endif
