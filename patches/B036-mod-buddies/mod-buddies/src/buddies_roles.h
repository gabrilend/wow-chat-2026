/*
 * buddies_roles.h - what part a character plays in a group: tank, healer
 * or damage (issue 617c3, shared).
 *
 * For a general audience: a player's role is read from its talents. The
 * points spent in each of its three talent trees are added up, the tree
 * with the most is its spec (the owner, 2026-10-03: "Player talents should
 * be summed per tree, and whichever one has the most points should be
 * counted as their spec [...] we should probably abstract that
 * functionality because we'll probably need it elsewhere"), and each
 * class's trees have roles. A tie is kept as a tie (the owner: "ties
 * should pick one of the potentials randomly. Unless we can return a tuple
 * of the two or something?"): the trees come back as a set, and a caller
 * that needs one tree gets one of them at random. A tree may have two
 * roles (a feral druid tanks or deals damage: "Yeah they can do both").
 * A buddy's role is its talent plan's, kept in the roster.
 */

#ifndef MOD_BUDDIES_ROLES_H
#define MOD_BUDDIES_ROLES_H

#include "Define.h"

class Player;

// The roster's own numbers (buddy_roster.role).
enum class BuddyRole : uint8 { Damage = 0, Tank = 1, Healer = 2 };

// A set of roles, one bit per role (1 << BuddyRole).
using BuddyRoles = uint8;
inline constexpr BuddyRoles BuddyRoleBit(BuddyRole r) { return BuddyRoles(1u << uint8(r)); }

// {{{ BuddySpecTrees
// The talent trees (bit 0, 1, 2: the talent window's order) tied for the
// most points spent in the active spec; 0 with no points spent.
uint8 BuddySpecTrees(Player* player);
// }}}

// {{{ BuddySpecTree
// One spec tree (0-2): the most points, a tie broken at random; -1 with no
// points spent.
int8 BuddySpecTree(Player* player);
// }}}

// {{{ BuddyTreeRoles
// The roles of a class's talent tree (0-2).
BuddyRoles BuddyTreeRoles(uint8 cls, uint8 tree);
// }}}

// {{{ BuddyPlayerRoles
// Every role a character can take by its spec trees (all tied trees);
// damage with no talents spent.
BuddyRoles BuddyPlayerRoles(Player* player);
// }}}

#endif
