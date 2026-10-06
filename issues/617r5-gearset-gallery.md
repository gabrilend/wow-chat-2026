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

## Current Behavior

Not built. The custom client draws a naked night elf; it can't yet draw
items on a character.

## Intended Behavior

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

1. Items on characters in the client: ItemDisplayInfo (the item's model
   and textures), armour pieces painted onto the skin sheet's regions and
   switching geosets (sleeves, robes, boots, gloves), and attached models
   (helm, shoulders, weapons, shields) on the model's attachment points.
2. A picture mode: one character, given race, sex and items, rendered to
   a file.
3. The gallery: every record of a profile, a page linking them.

## Open Questions

None yet.
