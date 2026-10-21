/*
 * buddies_gems.h - buddies gem their gear by their talent plan (issue
 * 617j2).
 *
 * For a general audience: basic's gear has gem sockets (issue 155p). A
 * buddy is made with every socket of its starting gear filled, free, with
 * gems of the tier for each item's level, chosen by what its talent plan
 * values most. Afterwards, whenever a gem enters a buddy's bags, it is
 * placed by the clan as a whole: it goes, once, to the buddy it improves
 * most (over what that buddy has socketed now), who sockets it at once;
 * a socketed gem never moves again, so gems can't be passed back and
 * forth. Gear with sockets arriving offers the clan's loose gems again.
 * At the auction house a buddy buys gems for its empty sockets (the
 * owner, 2026-10-03: "from the auction house"); they come by mail.
 *
 * "What its plan values" is the bot module's own stat weights for each
 * talent tree the plan spends in, blended by the plan's share of points,
 * as items are scored (617j, source patch B046).
 */

#ifndef MOD_BUDDIES_GEMS_H
#define MOD_BUDDIES_GEMS_H

#include "Define.h"
#include "ObjectGuid.h"
#include <string>

class Creature;
class Player;

// {{{ BuddyGemKit
// Every socket of every item the buddy wears filled with gems of the
// item's tier (I below item level 30, II below 45, III from 45), by its
// plan (`profile` 1-10 and `role`, as buddy_roster holds them; 0 = no plan:
// scored as the bot module scores the buddy itself). Free: no gem items
// are used. Works before the buddy is in the world (its making) and in it
// (a buddy made again at a lower level, 617a6). Returns what could not be done, empty when
// all is well, for the caller to log.
std::string BuddyGemKit(Player* buddy, uint8 profile, uint8 role);
// }}}

// {{{ BuddyBuyGemsAtAuction
// At an auctioneer, on the town visit's auction errand: for each empty
// socket it wears, the best gem listed (alone, for a buyout it can afford)
// that fits it, bought, while it has spare bag slots and within a quarter
// of its money. The gems come by mail. Returns how many were bought.
uint32 BuddyBuyGemsAtAuction(Player* bot, Creature* auctioneer);
// }}}

// {{{ BuddyItemArrived
// An item entered a buddy's bags by a route the server's "new item
// stored" moment doesn't see (taken from the mail): queued and handled as
// any arrival is (a gem placed, socketed gear offering the clan's gems).
// Safe from any thread.
void BuddyItemArrived(uint32 buddyGuid, ObjectGuid item);
// }}}

void AddSC_buddies_gems();

#endif
