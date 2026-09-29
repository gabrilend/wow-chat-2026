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

class Action;
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

#endif
