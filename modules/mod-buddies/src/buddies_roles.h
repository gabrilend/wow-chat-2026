
#ifndef MOD_BUDDIES_ROLES_H
#define MOD_BUDDIES_ROLES_H

#include "Define.h"

class Player;

enum class BuddyRole : uint8 { Damage = 0, Tank = 1, Healer = 2 };

using BuddyRoles = uint8;
inline constexpr BuddyRoles BuddyRoleBit(BuddyRole r) { return BuddyRoles(1u << uint8(r)); }

uint8 BuddySpecTrees(Player* player);

int8 BuddySpecTree(Player* player);

BuddyRoles BuddyTreeRoles(uint8 cls, uint8 tree);

BuddyRoles BuddyPlayerRoles(Player* player);

#endif
