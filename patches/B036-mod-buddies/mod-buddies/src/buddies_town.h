/*
 * buddies_town.h - what the town-visit file offers the strategy file (issue
 * 617e4).
 *
 * For a general audience: two more behaviours for the bot module, made in
 * buddies_town.cpp and taught to it by buddies_roam_strategy.cpp alongside
 * "buddy roam": "buddy travel" walks a buddy to whatever named area its
 * owner is in, and "buddy town" is what a buddy does in a town (errands,
 * then leisure). The strategy file only needs to be able to make them by
 * name; these are the makers.
 */

#ifndef MOD_BUDDIES_TOWN_H
#define MOD_BUDDIES_TOWN_H

#include <vector>

class Action;
class Item;
class PlayerbotAI;
class Strategy;
class Trigger;

// {{{ the makers
// Each returns a new object the bot module owns (it deletes them).
Strategy* NewBuddyTravelStrategy(PlayerbotAI* ai);
Trigger*  NewBuddyTravelDueTrigger(PlayerbotAI* ai);
Action*   NewBuddyTravelStepAction(PlayerbotAI* ai);

Strategy* NewBuddyTownStrategy(PlayerbotAI* ai);
Trigger*  NewBuddyTownDueTrigger(PlayerbotAI* ai);
Action*   NewBuddyTownStepAction(PlayerbotAI* ai);
// }}}

// Whether the buddy is partway through a town errand; the crossing waits
// for it before heading for the dock (617e8: "finish the current task").
bool BuddyTownErrandUnderway(unsigned int buddyGuid);

// Whether the buddy's town visit is fishing (walking to the shore
// included): the weapons pass leaves the pole in hand then (617e4b).
bool BuddyTownFishing(unsigned int buddyGuid);

// {{{ the selling trip's use of the town visit's selling (617h1)
// How full the buddy's bags are, 0..1, and the share at which they count
// as full (the town visit clears them past it). And what a vendor stop
// sells, done at `npc`: junk, the auction rules' leftovers, and past the
// full share with no auctioneer in the buddy's area the clearance; then
// its meals. Silent, as the town visit is.
class Creature;
class Player;
float BuddyBagFullness(Player* bot);
float BuddyFullBagsShare();
void  BuddySellAtVendor(PlayerbotAI* ai, Player* bot, Creature* npc);
// The items in its bags the buddy would part with for money: greys, and
// what the bot module would sell to a vendor or auction (617h1's dungeon
// rule, buddies_dungeon_bags.cpp).
std::vector<Item*> BuddyDisposableItems(PlayerbotAI* ai, Player* bot);
// }}}

#endif
