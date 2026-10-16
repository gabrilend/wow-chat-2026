/*
 * buddies_arms.h - how a buddy carries its weapons, by where it is (issue
 * 617e4b): bare-handed in town, sheathed in the wilds, drawn in danger.
 * See buddies_arms.cpp.
 */

#ifndef MOD_BUDDIES_ARMS_H
#define MOD_BUDDIES_ARMS_H

class Item;
class Player;

// Whether `item` is the best or the runner-up for one of this buddy's
// hand slots (main, off, ranged), worked out now from all it carries:
// the town's selling keeps it (owner, 2026-10-15: "they never sell their
// *best* weapon ... If there's two that are good ... they shouldn't be
// sold, either").
bool BuddyIsKeptWeapon(Player* bot, Item* item);

#endif
