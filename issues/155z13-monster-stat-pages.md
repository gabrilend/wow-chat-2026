# 155z13 - Monsters with Stat Pages of Their Own

## Status
- Created: 2026-10-22
- Phase: 1
- Parent: 155 (basic profile)
- Related: 155p (the +1 glass gems: haste, health every 5 seconds,
  resilience), 155i (creature multipliers: damage, healing, health per
  creature), 628a (the bake: a stand-in buddy's look and gear baked into
  a creature, the rest kept as data), 617t1 (stand-ins)
- Priority: Low
- State: an idea; open questions first

## Origin

Verbatim, 2026-10-22:

> Also can we add +hp5 (only like 1) and +resilience (it reduces damage
> from crits and periodic effects) question do monsters crit at all or do
> only players? If it's only players, can we enable monster crits and give
> them stat pages too, with the "bake an NPC buddy-bot stand-in profile to
> an NPC and render that while the rest is in data" idea perhaps
> considered as inspiration?

## Current Behavior

Monsters already crit (read 2026-10-22, `Unit::GetUnitCriticalChance`):
a creature's melee crit chance is a flat 5%, plus whatever its auras and
spells add; its spells can crit too. Resilience lowers the chance of
being crit by any attacker, monsters included (`Unit::ApplyResilience`),
so resilience gear already matters against them.

What a monster doesn't have is a stat page: no strength, agility,
critical strike or haste rating of its own. Its damage comes from its
level and rank (the creature tables' damage ranges and modifiers); basic
can scale a creature's damage, healing and health (155i's per-creature
multipliers), not its crit chance or speed.

## Intended Behavior

(As read; the open questions decide.) Monsters get stat pages: numbers
like a character's (critical strike chance, haste, maybe resilience and
the primary stats) that change how they fight, per creature or per kind,
kept as data the way 628a keeps a stand-in's profile as data while the
creature shows its baked look. Then the low glass gems (+1 haste, +1
resilience) and players' gear meet monsters on the same terms.

## Suggested Implementation Steps

1. Answer the open questions.
2. A table of monster stat pages (per creature entry, or per family and
   level band), read at start by basic's compiled rules, as 155i's
   multipliers table is.
3. Compiled hooks that apply them: crit chance (the server's crit hooks
   for creatures), attack and cast speed (haste), and whichever others
   the answers keep.
4. A way to see a monster's page (a game master command, and perhaps the
   documentation pages).

## Open Questions

1. **Is this still wanted, now that monsters do crit?** The question
   started from "if it's only players". The flat 5% could become a
   per-monster number; is that the point (bosses and elites crit more,
   critters never), or the whole stat page?
2. **Which stats:** crit and haste only, or a full page (strength,
   agility, stamina, intellect, spirit, ratings, resilience)?
3. **Per creature or per kind:** set by hand for named monsters and by
   family and level for the rest?
