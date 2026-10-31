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
#include <string>

class Creature;
class Player;

// {{{ BuddyTrainAtTrainer
// At a class trainer in a town: the lessons it can teach the buddy now,
// cheapest first, each paid; the first one it can't afford ends the visit
// (a debug log line only: running short is ordinary). Then the quest
// spells its level allows that it lacks, free. Returns lessons learned.
uint32 BuddyTrainAtTrainer(Player* bot, Creature* trainer);
// }}}

// {{{ weapon kinds: the one it arrives with, one more per kind its owner trained
// How many extra weapon kinds (Axes, Staves, Guns ...) a new buddy of this
// owner gets: one for each kind the owner learned at a trainer, not those
// its race and class start with; now (online) or as last saved. The
// owner's rule, 2026-10-30 (617n).
uint32 BuddyWeaponAllowance(uint32 ownerGuid);
// Teaches the buddy a weapon kind (a skill line) from a weapon master's
// lessons, free, if it lacks it: a weapon its kit hands it is always
// known (the owner, 2026-10-15: "That one they should know"). True when it
// knows the kind afterwards (or `skill` is not a weapon kind); false with
// `why` filled when no weapon master teaches it to its class and race.
// Safe before the buddy is in the world.
bool BuddyLearnWeaponKind(Player* bot, uint32 skill, std::string& why);
// When a buddy is made: `allowance` (BuddyWeaponAllowance) more kinds, at
// random among those its class and race can still learn (fewer when it
// runs out). Returns how many learned.
uint32 BuddyFillWeaponKinds(Player* bot, uint32 allowance);
// Every weapon kind the buddy knows raised to the most its level allows
// ("maxxed for their level", 2026-10-30). Returns how many were raised.
uint32 BuddyMaxWeaponSkills(Player* bot);
// }}}

// {{{ BuddyLearnEverything
// When a buddy is made: every lesson any class trainer valid for its race
// teaches up to its level (ranks in order), and every quest spell its
// level allows, free. Safe before the buddy is in the world: spells are
// added, not cast. Returns how many were learned.
uint32 BuddyLearnEverything(Player* bot);
// }}}

// {{{ BuddyRaiseProfessions
// Every profession the buddy has (cooking, first aid and fishing too)
// raised to its level's skill (five a level, up to 300), the rank spells
// that skill needs, every recipe its profession trainers teach at or
// below that skill and level, and an enchanter's runed rod of its skill.
// Never lowers a skill. Safe before the buddy is in the world. Returns how
// many skills and recipes changed; `problems` gains what could not be done.
uint32 BuddyRaiseProfessions(Player* bot, std::string& problems);
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
