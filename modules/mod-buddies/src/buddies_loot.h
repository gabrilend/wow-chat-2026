/*
 * buddies_loot.h - how buddies judge gear and roll on group loot (issue
 * 617j), as the bot module asks it.
 *
 * For a general audience: the bot module (mod-playerbots) scores items by
 * stat weights for a bot's main talent tree and rolls need or greed from
 * that. Source patch B046 has it ask this module two questions first, for
 * buddies only: "what is this buddy's talent plan?" (so an item is scored
 * by every tree the buddy spends in, weighted by its share), and "what
 * does this buddy roll?" (the clan's rules). The two answers are declared
 * here exactly as B046 declares them in the bot module's files; the
 * definitions are in buddies_loot.cpp. A mismatch between the two
 * declarations is a link error, not a silent difference.
 */

#ifndef MOD_BUDDIES_LOOT_H
#define MOD_BUDDIES_LOOT_H

#include "Define.h"
#include "StatsCollector.h"                            // CollectorType

class Player;
struct ItemTemplate;
enum RollVote : uint8;

// {{{ BuddyTalentPlan
// True when `player` is a buddy whose talent plan has been chosen (617g):
// `thirds` its points per tree in thirds, trees left to right as the
// talent window shows them (2,1,0 = two thirds in the first, a third in
// the second; 1,1,1 = a third in each; 3,0,0 = all in the first), and
// `types` the kind of stats each tree values (heal, spell damage, tank,
// melee or ranged damage), by the bot module's own rules per class and
// tree. False for anyone else: the bot module scores them as stock.
// Called from the map threads (bot updates).
bool BuddyTalentPlan(Player* player, uint8 (&thirds)[3], CollectorType (&types)[3]);
// }}}

// {{{ BuddyPlanShape
// Talent plan 1-10's shape for a class: `thirds` per tree and each tree's
// kind of stats, as BuddyTalentPlan gives them for a buddy in the roster;
// for callers that know the plan before the roster does (a buddy being
// made, 617j2's kit gems). False for plan 0 (none) or out of range.
bool BuddyPlanShape(uint8 cls, uint8 profile, uint8 role, uint8 (&thirds)[3], CollectorType (&types)[3]);
// }}}

// {{{ BuddyPlanMainTree
// The main tree (0-2, the talent window's order) of talent plan 1-10, as
// buddy_roster.profile holds it; -1 for no plan.
int8 BuddyPlanMainTree(uint8 profile);
// }}}

// {{{ BuddyLootRollVote
// The vote `bot` casts on a group-loot roll for `proto`. `judged` is the
// bot module's judgement (need for an upgrade it would wear, greed for
// what it could sell or use, pass otherwise), `configured` the same after
// the module's config switches (on basic: need becomes greed, greed
// becomes pass). Anyone not a buddy gets `configured` back. A buddy:
//   - class book (155q): pass when its owner needs it and is there to roll,
//     need when it needs it itself, otherwise greed;
//   - an upgrade (judged need): a buddy on the "a third in each tree" plan
//     needs it only while its own average item level is below its clan's
//     (owner and all the owner's buddies), and greeds it otherwise; every
//     other buddy needs it; a unique item it already holds is passed;
//   - judged greed or disenchant: kept as judged;
//   - judged pass: pass.
RollVote BuddyLootRollVote(Player* bot, ItemTemplate const* proto, int32 randomProperty, RollVote judged, RollVote configured);
// }}}

#endif
