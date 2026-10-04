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

### The chosen look, 2026-10-03

The owner sent two screenshots of the look ("I took some pictures of what
Sargobras's outfit should look like"), replacing the 2026-09-23 sketch:

| Slot  | Item (world database entry, item display id) |
|-------|----------------------------------------------|
| Back  | Cape of the Black Baron (13340, 24013)       |
| Chest | Black Mageweave Vest (9998, 24352)           |
| Shirt | Orange Mageweave Shirt (10056, 18925)        |
| Legs  | Black Tuxedo Pants (6835, 13117)             |
| Feet  | Dress Shoes (6836, 16368)                    |

Face: skin colour 7, face 8, hair style bald, hair colour 1, facial hair
"Bearded". The screenshot's tool also listed face shape (narrow), eyebrows
(straight) and eye colour (1); the 3.3.5a client has no such options, so
they have no effect here. The race is not shown: human male is assumed
from the original sketch, confirmed by the owner the same day ("yes.
Don't worry about the unknown options.").

## Current Behavior

**Written 2026-10-03 (the owner: "yes please" to the mirror-image route),
syntax-checked with the build's own flags, patch round trip tested on a
copy, not yet built or run.**
- `patches/B047-creature-outfits.sh` (basic): a list of creature looks in
  the core (`CreatureOutfits.h`, created) and, in the client's
  mirror-image question (`SpellHandler.cpp`), a listed creature answered
  from it before the stock "is it a mage's copy" check. Applying twice
  and reverting twice on a copy of the handler left it byte for byte as
  it was.
- `modules/mod-buddies/src/buddies_outfits.cpp`: at startup lists the
  look for the three Sargobras (6170001, 6170002, 7180001): human man
  (body 49), skin 7, face 8, hair colour 1, the five items' pictures read
  from the world database; each Sargobras entering the world gets that
  body and the mirror-image mark, which makes the client ask for it.
  The hair style (11, "Bald") and beard (3, "Bearded") numbers are a
  first guess: `.buddy look <skin|face|hair|haircolor|beard> <n>` changes
  them for the run (walk out of sight and back to see it), and the right
  ones go into the file.

Before this:
No such NPC (617b). One Sargobras exists since 2026-09-25: the static one at the gate of Acherus (718, creature 7180001), wearing a stand-in model (Lord Gregor Lescovar's, a Stormwind noble) until this issue chooses his look.

## Intended Behavior

- The look chosen 2026-10-03 (table above): bald and bearded, the Black
  Baron's cape, a black mageweave vest over an orange shirt, black tuxedo
  pants, dress shoes. (The 2026-09-23 sketch, ashen skin, chin-length
  black hair, white shirt and pale green pants, is superseded.)
- The outfit doesn't change with level (2026-09-25).
- No client patch (2026-09-23). A stock display record with exactly this
  outfit is unlikely to exist, so the likely route is the server's own
  "mirror image" message: the 3.3.5a client asks the server what a
  creature flagged as a mirror image looks like (race, skin, face, hair,
  facial hair, and the display of each worn item), and draws it from the
  answer. The server's handler today answers only for a mage's mirror
  images (copying the caster); a reversible source patch could answer
  with Sargobras's fixed look instead. Needs the owner's approval.

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
- (Answered 2026-09-25) Sargobras's outfit doesn't change: "sargobras's
  outfit doesn't change, let's say."
