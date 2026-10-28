/*
 * buddies_follow.h - what the following file offers the strategy file
 * (issue 617e13).
 *
 * For a general audience: "buddy follow" is a behaviour for the bot module,
 * made in buddies_follow.cpp and taught to it by buddies_roam_strategy.cpp
 * beside "buddy roam": a buddy walks beside its owner's own track, on a
 * half circle behind, and rests until the owner walks off. The strategy
 * file only needs to make it by name; these are the makers.
 */

#ifndef MOD_BUDDIES_FOLLOW_H
#define MOD_BUDDIES_FOLLOW_H

#include <cstdint>

class Action;
class PlayerbotAI;
class Strategy;
class Trigger;

// {{{ the makers
// Each returns a new object the bot module owns (it deletes them).
Strategy* NewBuddyFollowStrategy(PlayerbotAI* ai);
Trigger*  NewBuddyFollowDueTrigger(PlayerbotAI* ai);
Action*   NewBuddyFollowStepAction(PlayerbotAI* ai);
// }}}

// {{{ BuddyFollowTrackAhead
// A point of the player's own track (noted for every owner and every
// player followed) a few points on from the point nearest (x, y): where a
// buddy that found no way to that player walks next, along the way the
// player came (the owner, 2026-10-27, idea 3 of the pathfinding report).
// False when there is no track yet (the player just arrived or teleported).
bool BuddyFollowTrackAhead(uint32_t player, float x, float y, float& outX, float& outY, float& outZ);
// }}}

// {{{ the follow orders (617y, 617e13; heard in buddies_orders.cpp)
// "follow me" / "follow <name>": the buddy follows that player (its
// leader) instead of its usual behaviour; "go away" or "shoo" from that
// player ends it; "go away!" ends it and the buddy won't follow that player
// again until that player logs out (the owner, 2026-10-23). A leader who
// logs out ends every follow of them and every refusal.
// Player numbers are the characters' guid counters.
void     BuddyFollowSet(uint32_t buddy, uint32_t leader);
void     BuddyFollowStop(uint32_t buddy);
void     BuddyFollowRefuse(uint32_t buddy, uint32_t leader);
bool     BuddyFollowRefused(uint32_t buddy, uint32_t leader);
uint32_t BuddyFollowLeader(uint32_t buddy);           // 0: no follow order
// }}}

#endif
