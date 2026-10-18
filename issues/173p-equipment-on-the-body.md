# 173p - Equipment on the Body

*Continues in the W client (`/mnt/kaun/custom-client/`), since the move on 2026-10-07 (173v): issue 404. This issue stays as the record of how the client began; its paths are as they were then.*

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

**Painted items, switched pieces and hung items built (2026-10-06).**
- **The look:** `CharacterLook` carries an item look (ItemDisplayInfo id)
  per slot: shirt, legs, feet, wrists, chest, hands, tabard, waist, head,
  shoulders, back, main hand, off hand. The slots are listed in the order
  they paint, the lower layers first.
- **Painting** (`wear` in `character.c`): each item's region pictures
  (fields 16-23) are painted onto the skin sheet's regions. The full
  table of ten regions is now in `character.c`. The picture is
  Item\TextureComponents\<region folder>\<name>_<F or M>.blp, else _U.
  A picture missing from every archive is named, and its region left
  unpainted.
- **Pieces:** each slot switches the piece groups it governs. These rules
  are this client's reading, to check against the original:
  - shirt or chest: sleeves g8 = 1 + gg0, g10 = 1 + gg1, a robe's skirt
    g13 = 1 + gg2;
  - legs: g9, g11, g13;
  - feet g5, hands g4, waist g18, back g15, tabard g12 = 2.
  Later slots win, so a robe's skirt overrides the legs. A chosen variant
  above 1 that the model lacks is named.
- **Picture option:** `--wear SLOT:LOOK,...` dresses her. The rogue's
  set (chest 41143, hands 41138, legs 41140, waist 41476, feet 41480)
  shows painted dark leather, glove cuffs and tall boots.
- **Test:** dressed in the rogue's set, her upper torso is painted, her
  boots (504) show, and her bare feet (501) don't.
- **The tail (173d)** was fixed separately: the fur picture.
- **Hung items:** `character.c` resolves each hung slot into an item
  model, its picture, and the attachment point it hangs from:
  - head: Item\ObjectComponents\Head\<model>_<race><sex>.m2 (made per
    race and sex, as _NiF), point 11;
  - shoulders: left model at 6, right at 5;
  - main hand: a weapon at 1;
  - off hand: a weapon at 2, or a shield or buckler at 0.
  `figure.c` loads each as its own figure (`figure_from_item`: pictures
  named inside, or the item's own picture for kind 2). Each frame it
  hangs from her bone at the attachment point's place, read from her
  model (header 240), and is drawn with her.
- **The helm's hiding:** the look's HelmetGeosetVisData row (field 14 for
  men, 15 for women: masks of races for hair, three facial-hair groups
  and ears) hides those pieces for her race.
- **Cloaks:** their picture (Item\ObjectComponents\Cape) is model
  texture kind 2.
- **Seen:** in the rogue's full set (plus hood 41139, shoulders 41142,
  sword 40857), the hood hides her hair, the spiked shoulders sit on her
  shoulders, and the sword is in her right hand.
- **Tests:** 2 more checks. The four hung items hang from points 11, 6,
  5 and 1, the hood hides her hair, and the hood's _NiF model is in the
  archives.

**Starting outfits (2026-10-06).** The owner: "can we give each character
some equipment so they aren't naked?" `character_start_outfit` reads the
client's starting-outfit table (CharStartOutfit.dbc: race, class, sex as
bytes in field 2, then 24 items, 24 looks, 24 slot kinds) and fills a
look's slots by kind; bows, guns, thrown weapons, ammunition, bags and
food have no slot and are left out. She wears a fresh hunter's (shirt,
trousers, boots, axe: `HER_CLASS` in `main.c`), the tauren bystander a
fresh warrior's (shirt, trousers, axe). `--wear` now lays single slots
over her outfit. Townsfolk already wear theirs (173t). Tests: the
hunter's four looks, the warrior's three, and a race and class with no
outfit refused.

**Left:**
- Items' own animations and particles (glowing weapons).
- Sheathing (weapons on the back or hip when not fighting).
- Comparing the piece rules with the original on a few sets.
- The server sending each character's looks (with the network).

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
