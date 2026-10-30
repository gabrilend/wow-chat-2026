/*
 * buddies_army.h - an army of stand-ins round a game master, on a test
 * realm (issue 617e17).
 *
 * For a general audience: the owner wanted sixty-four bots round her
 * character to try the ways of finding a path on (617o7): "an army of 64,
 * just for me, and my buddy-bots should displace some of them, so it's
 * always a total of 64 ... they will quest in the area that my character
 * is in". ".buddy army [count]" raises it: the game master's own buddies
 * in the world count first, random stand-ins (buddies_stand_ins.cpp) make
 * up the rest, a few every two seconds. A buddy of theirs coming into the
 * world sends a stand-in out; one leaving brings a stand-in in. Each
 * stand-in, once in the world, takes the game master as its master, so
 * the roaming that drives buddies drives it too, as one of theirs: the
 * same clan, wandering and fighting in the area the game master is in, by
 * whichever way of finding a path ".buddy path" picked. ".buddy army
 * dismiss" sends every stand-in out (kept for the next asker). Only on a
 * test realm (a realm branch, 136d, whose launcher sets the module's
 * setting Buddies.TestRealm).
 */

#ifndef MOD_BUDDIES_ARMY_H
#define MOD_BUDDIES_ARMY_H

#include "Define.h"
#include <utility>
#include <vector>

// {{{ BuddyArmyPairs
// Every army's stand-ins and their game master (character guids, low
// part), as the roster's pairs are. The roster's list (BuddyRosterPairs)
// adds them after its own, so every pass takes them as the game master's
// buddies (the owner, 2026-10-29: "treat them like as if we had 64
// buddy-bots"). World thread only.
std::vector<std::pair<uint32, uint32>> BuddyArmyPairs();
// }}}

void AddSC_buddies_army();

#endif
