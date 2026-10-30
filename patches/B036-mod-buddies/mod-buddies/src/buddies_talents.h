/*
 * buddies_talents.h - buddies lean on the abilities their talents improve
 * (issue 625): the "buddy talents" combat strategy, whose multiplier nudges
 * each answer to a concern by a weighted random draw (buddies_talent_draw.h)
 * built from the talents the buddy has (buddies_talent_touches_data.h).
 * Off unless Buddies.TalentWeights is 1 or 2.
 */

#ifndef MOD_BUDDIES_TALENTS_H
#define MOD_BUDDIES_TALENTS_H

class PlayerbotAI;
class Strategy;

// The strategy's maker, for the buddy strategy context (buddies_roam_strategy.cpp).
Strategy* NewBuddyTalentsStrategy(PlayerbotAI* ai);

#endif
