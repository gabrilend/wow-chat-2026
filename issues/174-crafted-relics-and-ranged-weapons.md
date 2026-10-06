# 174 - Crafted Relics and Ranged Weapons

## Status
- Created: 2026-10-04
- Phase: 1
- Profile: basic
- Priority: Low
- Related: 172 (Inscription and Enchanting making staves and off-hands)

## Origin

Verbatim, 2026-10-04, on custom relics: of the three ways (stats only; an
existing relic's effect with new numbers; a new effect the client can't
describe), the second "let's consider this option impossible, because it
modifies something the player can't see", and the third "as well,
because it hides information". Then:

> we should consider making idols be part inscription, part leatherworking
> or herbalism (spec), and totems be mining and librams be enchanting and
> ranged weapons do blacksmithing thrown gets 2x as many recipes than bows
> and crossbows and such - any others?

## Current Behavior

Not built. Relics (idols, totems, librams, sigils) only drop; no
profession makes them. Bows and crossbows are mostly drops; guns are
Engineering's; thrown weapons drop.

## Intended Behavior

- **Relics are stats only**: new relic items carry plain stats and reuse
  an icon the client already has; no relic effect the player can't read.
- **Who makes what**:
  - idols (druids): part Inscription, part Leatherworking or Herbalism
    (by the crafter's specialisation);
  - totems (shamans): Mining;
  - librams (paladins): Enchanting;
  - ranged weapons (bows, crossbows, thrown): Blacksmithing, with twice as
    many thrown recipes as bow or crossbow ones.
- Item levels up to 60 (as 172).

## Suggested Implementation Steps

1. Item rows: relics and ranged weapons by level step, stats by the item
   budget, icons reused.
2. Recipes (as 172: real recipes, else a crafting menu).
3. Trainers or recipe drops (open question 2).

## Open Questions

1. "any others?": sigils (death knights' relics) unassigned: Inscription
   (runes) or Blacksmithing (the runeforge)? Wands are already Enchanting's;
   guns stay Engineering's?
2. Recipes from trainers, or as drops (812's scrolls' kind)?
