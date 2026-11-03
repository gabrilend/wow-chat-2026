/*
 * buddies_board.h - a buddy's bulletin board (issue 165): everything within
 * 70 yards of it, pinned as it comes near and unpinned as it goes, fed by
 * the server's own "what this player sees" pass (source patch B067) through
 * the radius triggers of roam/buddy_radius_core.h. Off unless
 * Buddies.Board = 1 in worldserver.conf.
 */

#ifndef MOD_BUDDIES_BOARD_H
#define MOD_BUDDIES_BOARD_H

#include "Define.h"
#include "ObjectGuid.h"

class Player;

// {{{ BuddyBoardHas
// Whether `thing` is on `buddy`'s board now. False with the board off.
bool BuddyBoardHas(Player* buddy, ObjectGuid thing);
// }}}

// {{{ BuddyBoardCount
// How many things are on `buddy`'s board now: players, buddies (a part of
// the players), creatures. All 0 with the board off.
void BuddyBoardCount(Player* buddy, uint32& players, uint32& buddies, uint32& creatures);
// }}}

#endif
