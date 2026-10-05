# 167 - Spirit Heals as It Refreshes

## Status
- Created: 2026-10-04
- Phase: 1
- Priority: Medium
- Patch: B049 (`patches/B049-spirit-heals-as-it-refreshes.sh`), basic
- Related: 155k1 (stamina scaled to the threat: the other half of
  "players have too little health")

## Origin

Verbatim, 2026-10-04:

> can we add a patch that makes spirit restore hp5 equal to the amount of
> mana it would restore if the character wasn't casting?

## Current Behavior

**Patch written 2026-10-04 (B049), not yet compiled.** Before it, stock:
out of combat, a character's health comes back every 2 seconds by its
spirit through the server's own health-per-spirit tables
(`Player::OCTRegenHPPerSpirit`: the first 50 spirit at one rate, the rest
at another, by class and level). Its mana comes back from spirit and
intellect by a different table: per second, the square root of intellect
times spirit times the class's mana-per-spirit ratio, in full while not
casting (the "five-second rule") and only in part while casting. For a
caster the mana figure is much the larger: a level-60 priest with 300
spirit and 300 intellect regains about 34 mana a second out of casting,
about 69 every 2 seconds, while spirit gives back roughly 25-30 health a
tick.

## Intended Behavior

Spirit restores health, every 2-second tick, equal to the mana it would
restore in those 2 seconds if the character were not casting: the square
root of intellect times spirit times the class's mana-per-spirit ratio
(the client's `gtRegenMPPerSpt` table), times 2. Everything around it is
unchanged: health still regenerates only out of combat (or with the
effects that allow it in combat), sitting still adds a third, and
health-regeneration effects still apply.

Classes whose spirit gives no mana (warrior, rogue, death knight: their
mana-per-spirit ratio is 0 at every level) keep the stock health from
spirit.

## Suggested Implementation Steps

1. (Done) B049: at the top of the health-per-spirit function, a marked
   block returns the mana formula's value times 2 when the class's
   mana-per-spirit ratio is above 0; otherwise the stock formula runs.
2. `scripts/test-source-patches basic`: B049 applies and reverts
   byte-identically.
3. In game after the owner's compile: a caster's health regained per tick
   out of combat, sitting and standing, against its mana regained per tick
   out of casting.

## Open Questions

1. Warriors, rogues and death knights: keep stock health from spirit (as
   built), or give them a spirit health rate of their own?
2. Only out of combat, as stock health regeneration is, or in combat too?
