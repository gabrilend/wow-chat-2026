# 919c - Things Made Where Nobody Looks

## Status
- Created: 2026-10-20
- Phase: 9
- Parent: 919 (three worlds: Earth, Mars and the Sun)
- Blocked by: 919b (the planets exist)
- Related: the ambush spawner (`src/lua-beta/ambush.lua`; issues 303-305
  in `issues/completed/`), travellers (`src/lua-beta/travel.lua`; 504, 505)
- Priority: Low

## Current Behavior

The ambush system places monsters 120-160 yards from a player at a random
angle, whether or not the player is facing that way. Travellers walk from
place to place on the stock continents. Neither knows where any player is
looking, and nothing appears on the planets (they don't exist yet).

## Intended Behavior

The owner, 2026-10-20: "Maybe, with time, we could auto-generate plausible
looking things that nobody is looking at so when they turn around the
corner, there it'll be. Characters, endlessly wandering, nobody knowing how
to find each other or ever ever get back."

- **Out of sight.** A spot is out of sight when, for every player near
  enough to see it, it is behind them (outside a cone around the direction
  they face, about 120° wide, the client's default field of view plus a
  margin) or hidden behind ground (a line-of-sight test against the
  height field), or past the fog. Things (ruins, camps, standing stones,
  creatures resting) are placed only in such spots, so they are never seen
  appearing. When a player turns, it is already there.
- **Kept, or let go.** A thing placed this way stays while anyone is near
  it, and is removed once no player has been within range for a while,
  again only while out of sight. The world feels full without being stored.
- **Wanderers who never arrive.** On the planets, travellers walk without
  a destination: each picks its next step by the ground (downhill, along
  valleys, away from where it has been) and never stops. They do not know
  where other wanderers are. A player can meet one, but cannot summon one
  back.

## Suggested Implementation Steps

1. A view test: given a position, every player within range, each player's
   facing and the ground heights between, say whether it is out of sight.
   Used by the placer and the remover.
2. The ambush spawner's angle choice tries out-of-sight angles first (its
   distances stay its own). Test on 919a's map: count how often a spawn
   lands in view before and after.
3. A placer for things: a table of thing kinds per biome (from W09e's
   biome grid), each with its spacing and how long it lingers.
4. Wanderer travellers: travel.lua's movement without destinations, on the
   planets only.
5. A test that drives a character with scripted turns and checks no spawn
   or placement ever happens inside its view.

## Open Questions

1. Is a thing placed out of sight kept forever once seen (it becomes part
   of the world), or always let go when nobody is near?
