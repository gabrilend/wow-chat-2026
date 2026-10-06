# 173p - Equipment on the Body

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: 173d (models; first, the tauren's pieces chosen by the
  game's tables)
- Related: 175 (custom items told ahead), 617f (buddy gear), 159
  (equipment portrait grid)
- Priority: Medium

## Origin

Verbatim, 2026-10-06: "yeah we gotta work on that before we consider the
character models to be done. Where are we at with equipment and such?"

## Current Behavior

Not built. Characters are drawn bare: body, hair, face and underwear
only. A tauren man lacks his tail and hooves, because pieces are switched
on by fixed numbers checked only on the night elf (173d).

## Intended Behavior

A character wears what the server says it wears (item display ids per
slot), each turned into looks from the client's own files
(ItemDisplayInfo.dbc):
- **Painted on:** chest, shirt, sleeves, bracers, gloves, belt, legs,
  boots and tabard pictures painted onto the skin sheet's regions
  (arm upper and lower, hand, torso upper and lower, leg upper and
  lower, foot), each picture chosen for the wearer's sex (_M / _F / _U).
- **Shapes:** the item switches body pieces, by its geoset groups: long
  sleeves, gloves, boots, robe skirts, belts, tabard. This uses the
  same piece choice as a bare character's (173d's fix), with items
  overriding.
- **Attached:** helmets (with hair and ears hidden as the helm's table
  says), shoulders, weapons, shields and capes, each a model on its
  bone's attachment point (M2 attachments), with its own picture.
- **Checked against** the original's look for a few full sets.

## Suggested Implementation Steps

1. 173d's fix: each piece group chosen by the game's own tables.
2. Paint one item (a chest) onto the skin sheet.
3. Piece switching by item.
4. Attachments: one helmet, one weapon.

## Open Questions

None yet.
