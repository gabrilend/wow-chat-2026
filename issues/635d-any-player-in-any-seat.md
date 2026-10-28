# 635d - Any Player in Any Seat

## Status
- Created: 2026-10-27
- Phase: 6
- Parent: 635
- Blocked by: 635a
- Related: the buddies' hidden companion accounts (`buddies_create.cpp`)
- Priority: Medium
- State: plan

## Current Behavior

A character belongs to one account, and only that account can log it in.
Buddies are on hidden companion accounts no person logs into.

## Intended Behavior

The owner, 2026-10-27: "the player should be able to play as any of them.
a group of players should be able to queue as any of them. they can swap
the roles."

- **One player**: logs in as one seat; the other four come as bots.
- **A group of players**: each takes a seat; the empty seats are bots.
- **Swapping**: a seat changes hands between runs: the checkpoint is put
  back (635a) and each chosen seat goes to the player who chose it.

## Suggested Implementation Steps

1. The way a seat reaches a player (open question 1).
2. A command (in game, or the checkpoint tool's) to choose seats.

## Open Questions

1. **How a player gets a seat.** (a) Each seat's character is copied onto
   the player's own account when they take it, and removed when they give
   it back; (b) the five characters sit on five shared accounts whose
   logins the group shares; (c) a seat chooser in game. (a) keeps each
   player's own login and is my recommendation.
2. "Queue": the game's own dungeon finder, or just choosing seats before
   going in?
