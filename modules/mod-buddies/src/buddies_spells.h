/*
 * buddies_spells.h - what buddies learn, and when (issue 617n).
 *
 * For a general audience: a buddy learns as its owner does, in towns with
 * a class trainer, paying from its own purse (the owner, 2026-10-03: "Just
 * on town visits, and only if there's a trainer in that town"; "It's own
 * money. If it gets to the trainer and realizes it doesn't have enough
 * money, it should mark the task as complete. It should learn the lowest
 * cost spells first."). A buddy made above level 1 starts knowing
 * everything up to its level, free ("Everything up to it's level"). The
 * class spells only quests teach come from a generated list
 * (buddies_quest_spells.h) and are taught free at the trainer. A hunter
 * buddy is given a random pet, and a new one whenever its talents are
 * reset ("It should start with one randomly. Everytime the player respecs,
 * they should pick a new pet and get it instantly.").
 */

#ifndef MOD_BUDDIES_SPELLS_H
#define MOD_BUDDIES_SPELLS_H

#include "Define.h"

class Creature;
class Player;

// {{{ BuddyTrainAtTrainer
// At a class trainer in a town: the lessons it can teach the buddy now,
// cheapest first, each paid; the first one it can't afford ends the visit
// (a debug log line only: running short is ordinary). Then the quest
// spells its level allows that it lacks, free. Returns lessons learned.
uint32 BuddyTrainAtTrainer(Player* bot, Creature* trainer);
// }}}

// {{{ BuddyLearnEverything
// When a buddy is made: every lesson any class trainer valid for its race
// teaches up to its level (ranks in order), and every quest spell its
// level allows, free. Safe before the buddy is in the world: spells are
// added, not cast. Returns how many were learned.
uint32 BuddyLearnEverything(Player* bot);
// }}}

// {{{ BuddyForgetLessons
// The reverse of BuddyLearnEverything, for a stored buddy brought back
// (617a6): every lesson any class trainer valid for it teaches, and every
// quest spell of its class, is taken out of its spell book, whatever the
// level, so BuddyLearnEverything can then teach it afresh for its level.
// Talents are not touched (a talent reset does those). Returns how many
// spells were removed.
uint32 BuddyForgetLessons(Player* bot);
// }}}

void AddSC_buddies_spells();

#endif
