/*
 * buddies_arms.h - how a buddy carries its weapons, by where it is (issue
 * 617e4b): bare-handed in town, sheathed in the wilds, drawn in danger.
 * See buddies_arms.cpp.
 */

#ifndef MOD_BUDDIES_ARMS_H
#define MOD_BUDDIES_ARMS_H

class Item;
class Player;

// Whether `item` is one of the weapons this buddy put in its bags for a
// town stay, to be worn again on leaving: the town's selling keeps it.
bool BuddyIsStowedWeapon(Player* bot, Item* item);

#endif
