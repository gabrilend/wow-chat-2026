# 617r5 - The Gearset Gallery

## Status
- Created: 2026-10-05
- Phase: 6
- Parent: 617r (gearset profiles)
- Blocked by: 617r1, 173k (the client in C), item drawing on characters (part of 173d)
- Priority: Medium

## Origin

Verbatim, 2026-10-05:

> Then, we can use the custom client's model rendering capabilities to
> create a small gallery of each of the profiles, rendered on the correct
> race model with a random gender. The goal is to be able to rapidly
> create and update gearsets that look good, so buddy-bots spawn with the
> most fashionable sets they can.

Then, 2026-10-15 (verbatim):

> Can you create an HTML gallery document page that shows with rotatable
> 3d models drawn from the game files and equipped with the necessary
> item models, each of the buddy-bot classes equipment sets (with
> paper-doll item slots to the left and right of each rotatable gallery
> portrait image model renderer viewer rotatable) should have tooltips
> that show what they are. It should have one entry for each class at
> each tier, for a total of... 60, I think. Make sure it's dynamically
> updated whenever we compile, if needed. So, just call the generator in
> the compilation script, and write some output about it's location in
> the logs.

## Current Behavior

**The page without the figure, built 2026-10-15**
(`scripts/generate-buddy-gear-gallery`, the data, and
`scripts/templates/buddy-gear-gallery.html`, the view; writes
`docs/HTML/buddy-gear-gallery.html`). Sixty cards, ten classes at levels
10, 20, 30, 40, 50 and 60 (each the gear list's record at exactly that
level), each with a picker for the class's ten talent shapes, the gear
laid out like the game's character pane (left column, right column,
weapons below), and on every item a tooltip from the world database
(quality, slot and kind, armour, damage and speed, stats, sockets,
required level, item level). The middle of each card sums the outfit
(armour, weapon damage per second, stats, gray pieces). Filters by class
and level. `scripts/compile` runs the gear translator, the gear SQL and
this generator before every build and prints where they wrote.
Necklace, rings and trinkets show "chosen at making": the PvP jewellery
is picked when a buddy is made, not listed.

**Not built: the turning 3D figure.** The custom client draws a naked
night elf; it can't yet draw items on a character, which the figure
needs (the steps below).

## Intended Behavior

**The figure, by a renderer of our own in the page** (owner, 2026-10-15,
correcting a note that it waits on the custom client: "We can render the
models using a simple javascript renderer built specifically to task. We
can even do animations if we want." And: "we need to render the models
using whatever models we have available. In this case, the blizzard
models. But once we have others, we will automatically be updating this
page dynamically according to whatever model preference choice we
make."). The generator, at every compile, takes from the game's own
files the character model of a race and sex (M2 and its skin), the body
texture (CharSections.dbc), and for each worn item its display
(ItemDisplayInfo.dbc: the texture pieces painted onto the body's regions,
the geosets it switches, and the models of helms, shoulders, weapons and
shields hung on the model's attachment points), converts textures to
PNG, and writes them beside the page; a small WebGL renderer in the page
draws the dressed figure, turns it with the mouse or a finger, and plays
its stand animation. Which model set is drawn is one setting (the game's
models now; others when we have them), and the page follows it.

A gallery program (the custom client's renderer, run as a picture
maker): for a profile, one picture per record, the record's items worn
by a model of the right race (for a profile with no race key, a race the
class can be) and a random sex, front and back, on a plain background,
gathered into one page with each picture's keys and item names. Re-run
after editing the profile, it redraws only changed records, so a
gearset can be tried, looked at and changed in a minute.

**Beside each picture** (owner, 2026-10-05: "taste is impossible to
describe, sorry. All I need is the item names and IDs. Ideally, with a link
to the wowhead.com/wotlk/ page, so I can use their gear profile dressing
room builder to assemble an outfit."): every item's slot, name and number,
each linked to `https://www.wowhead.com/wotlk/item=<number>`.

## Suggested Implementation Steps

(For the in-page figure, 2026-10-15; the custom-client steps below stay
for the picture mode.)
A1. Read the game's archives: the client data's MPQ files, through the
    custom client's reader (C, already reading BLP and DBC) or StormLib
    (the map extractor's), as a small extraction tool.
A2. One race and sex first: M2 vertices, skin, bones, the stand animation;
    the body texture; drawn and turned in WebGL with no items.
A3. Armour on the body: ItemDisplayInfo's texture pieces composited onto
    the body texture's regions; geosets for sleeves, robes, boots, gloves.
A4. Attached models: helm, shoulders, weapons, shield on attachment points.
A5. The model set as a setting; the generator regenerates the figures it
    finds changed.

1. Items on characters in the client: ItemDisplayInfo (the item's model
   and textures), armour pieces painted onto the skin sheet's regions and
   switching geosets (sleeves, robes, boots, gloves), and attached models
   (helm, shoulders, weapons, shields) on the model's attachment points.
2. A picture mode: one character, given race, sex and items, rendered to
   a file.
3. The gallery: every record of a profile, a page linking them.

## Open Questions

1. Which race and sex per card: one fixed per class, random (the first
   plan's "a random gender"), or a picker?
2. Where the extracted model files live (they are the game's, large):
   beside the page in docs/HTML (not committed), or made on demand?
