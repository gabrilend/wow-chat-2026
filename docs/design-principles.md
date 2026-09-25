# Design Principles

Rules of thumb that shape many features at once. Each one is Ritz's, quoted
where it was first said, and lists where it is applied so a change to the
rule can find everything it touches.

## Sustain, then power, then focus

When a set of stats is spread across a level range (recipes along a
profession's skill range, gems along the level tiers, rewards along a
zone's levels), the order is:

1. **Sustain first** — what keeps a character going: Stamina, Spirit, mana
   every 5 seconds, health regeneration, resilience.
2. **Power next** — what makes everything stronger at once: Strength,
   Agility, Intellect, attack power, spell power.
3. **Focus last** — the specific, specialised stats that the power
   supports: critical strike, hit, haste, expertise, armor and spell
   penetration, and the defensive ratings (defense, dodge, parry, block).

Ritz, 2026-09-25: "Stats like stamina and spirit and mp5 and other such
things are on the low end because they provide sustain - things like
strength and intellect provide power so they are the middle, to better
support the higher end which is specific focused stats like crit rating and
haste. This pattern should be applied to the other gems as well. We might
make a guiding document that mentions this principle as well - when stats
are split across a level range like this, offer sustain first, then power,
then focus."

Defensive stats (Ritz, 2026-09-25): "resilience is sustain. The others are
focus." Resilience is sustain; defense, dodge, parry and block are focus.

Two-stat gems (Ritz, 2026-09-25): "Between the two: e.g. after all the pure
sustain gems and before the pure power gems." The full order is sustain,
sustain+power, power, power+focus, focus (a sustain+focus gem sits with
power).

Applied in:
- issue 155p — Jewelcrafting: the order in which trainers teach gem cuts
  across the skill range, for Outland's cuts and the other gem families.

## Tooltips always tell the truth

Whatever the game shows a player (a tooltip, a price, a recipe's colour)
must match what actually happens, even on legendary items; where the
client's own data can't be changed, the server is made to match it.

Ritz, 2026-09-25: "Let's keep the tooltips and the names in sync." /
"Always honest. Even in legendary items." / on recipe colours: "If it's
fine, then we have to make it true - we should ensure they have the
correct skill-up percentage chance that the player expects."

Known exception, accepted: white gear that can never be repaired still
shows a repair price in the vendor window ("It might be the best that we
can do.").

Applied in: issue 155p (gem names, socket bonuses, recipe colours).

## No required addons

Players may install any addon; no feature may depend on one until the
project ships its own client. See `docs/roadmap.md`, Project-wide
decisions.
