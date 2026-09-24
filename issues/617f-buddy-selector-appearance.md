# 617f - The Buddy Selector's Appearance

## Status
- Created: 2026-09-23
- Phase: 6
- Parent: 617
- Blocked by: 617b
- Priority: Low (the selector works with any look; this is his look)

## Origin

Verbatim, 2026-09-23:

> I'm thinking it should be a suave human male with pale, almost ashen skin,
> black hair parted down the middle and chin length, with a black and white
> shirt on (not tuxedo, more like inverted, white shirt with black accents)
> and pale green pants. No cloak, helmet, weapon, or shoulderpads, but we can
> pick belts and boots. No gloves probably either. Though maybe he levels up
> with you idk not sure yet. We'll pick the exact outfit later.

## Current Behavior

No such NPC (617b).

## Intended Behavior

- Human male, pale ashen skin, black chin-length hair parted in the middle.
- Shirt: white with black accents. Pants: pale green. Belt and boots to be
  chosen. No cloak, helmet, shoulders, weapon, or (probably) gloves.
- Possibly an outfit that changes with the owner's level.

In 3.3.5 an NPC can wear player-style equipment only if it uses a
*player-like* display (`CreatureDisplayInfoExtra`: skin, face, hair and
the worn items baked into the display). Skin and hair shade are limited to
the client's stock options for a human male, so "almost ashen" means the
palest stock skin. Choosing the outfit is a job for the equipment portrait
tool (159).

## Suggested Implementation Steps

1. Find stock displays of human males with the palest skin and the right
   hair among existing NPCs (the client's display-extra records), or build
   one from the options if a data patch is acceptable.
2. Shortlist shirts, pants, belts and boots; render candidates with 159.
3. Owner picks; set the NPC's display.
4. If he levels with the owner: one display per level band.

## Related Issues

- **617b** the selector; **159** equipment portraits

## Open Questions

- (Answered 2026-09-23) "no client patches allowed until the custom client
  is in." So Sargobras reuses an existing human-male player-like display
  (skin, hair and worn items already baked into a stock display record),
  chosen with the portrait tool (159). The exact look waits for the custom
  client.
- **Levels with you?** Owner is undecided.
