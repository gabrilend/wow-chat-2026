# 617e5a - The Kraken in Game

## Status
- Created: 2026-09-29
- Phase: 6
- Parent: 617e5 (fighting together)
- Related: 617c3 (the dungeon draw: who is in the party), the arena test
  ring (`src/lua-basic/arena-trial.lua`)

## Origin

The owner, 2026-09-29: "the gallery is supposed to have generated it's gifs
using the correct data model, so we should be able to just copy/paste it in
and adjust accordingly" / the kraken "should be the default combat style
when following a tank."

## Current Behavior

The kraken runs only in the roaming gallery: `docs/HTML/buddy-roaming/
dungeon-kraken.js` (a playable scene; "a drawn simulation of the intended
behaviour, not the game's combat": round numbers for health, damage, speed
and cooldowns) and the language-free rules in `docs/roaming-pattern.md`
("The kraken"). In game, buddies fight by the bot module's own rules:
tanks hold and taunt, damage dealers attack the tank's target, healers
heal, everyone steps out of area spells on the ground.

## Intended Behavior

When the party has a tank (the owner by spec, or a buddy whose role is
tank), the buddies fight as the kraken; with no tank, the bot module's own
way stays. The scene's turn rules carry over; the game supplies the
numbers and the spells:

| Scene part (dungeon-kraken.js) | In game |
|---|---|
| `mawSpot`: where the damage dealers' ranges overlap best | a point beside the tank when it first holds monsters; moved only by the tank's steps |
| `tankTurn`: within 6 yards of the maw; taunt what is on someone else; take idle monsters near the maw while the hold is light (six or fewer, an elite counting three) and health above half; step to the maw's far side from a newly taken one | a buddy tank: its movement kept within 6 yards of the maw; the bot module's own "taunt"; its "pull" on an idle monster within reach under the same limits. An owner tank does this themselves; the buddies read the maw from where the owner holds |
| `pullerTurn` (ranged damage dealers): reach an idle monster near the maw, hit it once, slow it, lead it to the far side of a neighbouring quadrant (never the opposite), blink or disengage when it closes, kite round the maw until the tank takes it; only while the total threat stays under what the tank has shown it can take | the bot module's "pull" (one hit) and its class "snare" (Frostbolt, Concussive Shot, Frost Shock, ...), then walking orders round the maw's neighbouring quadrant until the monster is on the tank; the class's blink or disengage where it has one |
| `dpsTurn`: area spells on the maw when two or more stand in it; against a boss area and single-target about equally | the bot module's area-damage behaviour allowed from two monsters in the maw (its own threshold is higher), else the tank's target |
| `healTurn` | the bot module's healing, unchanged |
| moving on: all held monsters dead, the whole party moves on | the kraken ends; roaming (or following the owner in a dungeon) resumes |

## Suggested Implementation Steps

1. **The strategy frame** (mod-buddies, next to "buddy roam"): a "buddy
   kraken" combat strategy, switched on in the roam pass's want-lists when
   the party has a tank; its state (the maw, the hold's weight, each
   puller's charge) kept per party.
2. **The maw and the tank's leash**: set when the tank first holds; a buddy
   tank's movement kept within 6 yards of it.
3. **Pullers**: choose (idle monster nearest the maw within reach, not
   linked to the held pack), pull, snare, lead round the neighbouring
   quadrant, release when the tank has it. The threat budget: the tank's
   hold plus the pull's weight at most six (elites three), the tank's
   health above half.
4. **Area damage on the maw**: the damage dealers' area threshold lowered
   to two while the kraken runs.
5. **Test** in the arena ring (`.arena start`): a buddy tank and a
   warrior owner in turn; count pulls, slows and deaths like the scene's
   HUD does, to the log.

## Open Questions

- **Who is "a tank"?** The bot module decides by spec (`IsTank`) and by a
  main-tank mark. Is an owner a tank only by spec, or also when they mark
  themselves (or say so to Sargobras)?
- **The maw with an owner tank**: the owner stands wherever they like.
  Should the maw follow the owner continuously, or be set when they first
  hold and moved only when they walk more than 6 yards from it?
- (Answered 2026-09-29: "just damage.") **Casters without a slow**
  (priests, warlocks without Curse of Exhaustion): do they pull at all, or
  only damage the maw? They only damage the maw.
- **Deferred, 2026-09-29** (owner: "for the kraken let's just use
  playerbots for now"): buddies fight by the bot module's own rules, in
  dungeons too, until this is taken up again.
