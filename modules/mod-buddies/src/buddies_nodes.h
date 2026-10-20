
#ifndef MOD_BUDDIES_NODES_H
#define MOD_BUDDIES_NODES_H

#include "Define.h"
#include <string>

bool BuddyNodeRetired(uint32 spawnId);

void BuddyRetireNode(uint32 spawnId, uint32 buddyGuid, std::string const& why);

#endif
