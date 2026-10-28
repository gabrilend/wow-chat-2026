# 636 - Earthliving Jumps to the Uncovered

## Status
- Created: 2026-10-27
- Phase: 6 (the bots' behaviour; the spell change itself is a server patch)
- Related: 635 (the Botanica party), 637 (totem places)
- Priority: Medium
- State: plan; open questions below

## Origin

The owner, 2026-10-27:

> resto shaman dual wield earthliving? if applied to a target that already
> has it, it jumps to a different nearby target who doesn't? double
> chance, double impact, scaling with coverage or durability indusage.
> (earth shield)

## Current Behavior

Earthliving Weapon is a weapon imbue: each heal the shaman casts has a
chance to put Earthliving, a heal over time, on the target. Only the
main-hand weapon's imbue counts for spells. A second Earthliving on a
target that has one refreshes it.

## Intended Behavior

- **Dual-wielded Earthliving**: a restoration shaman with both weapons
  imbued has two chances per heal ("double chance").
- **A jump instead of a refresh**: an Earthliving landing on a target that
  already carries the shaman's own goes instead to the nearest ally within
  range who doesn't. With no such ally, it refreshes as now.
- **"Scaling with coverage"**: the more allies covered, the more the
  shaman's heals spread, so a well-spread shaman feels the difference.
- **Earth Shield** (open question 2).

## Suggested Implementation Steps

1. Read the server's Earthliving handling (the imbue's proc and its aura)
   and write the jump as a server patch (a B patch), gated on basic.
2. Dual wield for restoration: whether the off-hand imbue procs from
   spells, and the patch that lets it.
3. Tests on scratch copies; then in game with the Botanica party.

## Open Questions

1. "Double impact": two chances to proc, or also a stronger heal when both
   weapons carry it?
2. **Earth Shield**: does the same jump apply (a second Earth Shield cast
   on someone who has one goes to someone who doesn't), or was it named as
   the model to follow?
3. "Durability indusage": the weapon's durability wearing faster with each
   proc, so the strength has a cost? Or something else?
