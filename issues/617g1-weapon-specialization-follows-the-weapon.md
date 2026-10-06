# 617g1 - Weapon Specialization Follows the Weapon

## Status
- Created: 2026-10-04
- Phase: 6
- Parent: 617g (buddy talent plans; `src/lua-basic/buddy-talents.lua`)
- Priority: Medium
- Related: 617r (outfits that put a weapon kind in a buddy's hands)

## Origin

Verbatim, 2026-10-04:

> arms warriors and combat rogues should automatically switch to the
> correct talent when equipping a certain type of weapon.

## Current Behavior

Not built. A warrior's Arms tree and a rogue's Combat tree each hold
talents that only help one kind of weapon, side by side in a tier:

- warrior, Arms: Poleaxe Specialization (axes and polearms), Mace
  Specialization, Sword Specialization;
- rogue, Combat: Hack and Slash (swords and axes), Mace Specialization,
  Close Quarters Combat (fist weapons and daggers).

Points put into one stay there when the character changes weapons. Buddy
plans (617g) spend into these by the plan's tree shares, not by what the
buddy wields; e.g. Pozeta (Arms) now wields a two-handed sword (617r).

## Intended Behavior

When a warrior or rogue equips a main-hand weapon, the points in its
weapon-kind talents move to the one matching the new weapon: the same
number of points, the same tree, the same tier, so nothing else in the
tree is unlocked or locked by the move. A weapon kind with no matching
talent (a staff on a rogue) moves nothing. The move happens on equipping,
and is said in one line to the character ("Your training turns to
maces.").

Data: per class, the tier's weapon talents as (talent id: integer, ranks:
integer, weapon subclasses: list of integers), read from the client's
talent data (the same source as `scripts/generate-basic-talent-data`),
not typed by hand.

## Suggested Implementation Steps

1. Generator: the weapon-kind talents per class from Talent.dbc and the
   spells' weapon masks.
2. A Lua handler on equip (the Lua engine's equip event): read the main
   hand's weapon subclass; if points sit in a non-matching weapon talent
   of the same tier, unlearn those ranks and learn the matching talent's
   ranks.
3. Test offline in a stand-in world (as `scripts/test-buddy-gm`): equip a
   mace on a sword-specialised warrior and see the points move; equip a
   staff on a rogue and see nothing move.

## Open Questions

1. Buddies only, or players too?
2. In combat as well, or only out of combat (a mid-fight weapon swap
   rewriting talents)?
3. Off-hand weapons: does a dual-wielding rogue follow the main hand only?
