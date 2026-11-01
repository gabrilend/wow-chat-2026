/*
 * buddies_solo.h - the solo record in the server (issue 623, question 7):
 * which foes a buddy can beat alone, from the hardest fight it has won
 * with no help, one per kind of foe. The arithmetic is roam/buddy_solo_core.h
 * (checked offline by scripts/test-buddy-solo-record); buddies_solo.cpp
 * notes each fight a buddy wins alone, keeps the records in the
 * buddy_solo_record table (install step E076), and answers the two calls
 * below.
 */

#ifndef MOD_BUDDIES_SOLO_H
#define MOD_BUDDIES_SOLO_H

#include "Define.h"

class Creature;
class Player;

// {{{ BuddySoloCanTake
// Whether `bot` judges it can beat `foe` with `allies` allies near (0 or 1:
// alone): the foe's health and damage per second (its weapon damage over
// its attack speed, from the game's data) each within the record of the
// foe's kind times the allies. A stand-in always can; a buddy with no
// record of that kind can't; anyone not a buddy: true (no fear to judge).
// Called from the map threads.
bool BuddySoloCanTake(Player* bot, Creature* foe, uint32 allies);
// }}}

// {{{ BuddySoloForget
// Every record of the buddy `buddyGuid` (low guid) forgotten, in memory and
// in the table: for when Sargobras sets its level or its class changes
// (the owner, 2026-10-30: "only when Sargobras changes your level.
// Levelling up via normal means shouldn't affect it.").
void BuddySoloForget(uint32 buddyGuid);
// }}}

#endif
