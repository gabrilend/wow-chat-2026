# 172 - Enchanting Makes Staves and Off-hand Items

## Status
- Created: 2026-10-04
- Phase: 1
- Profile: basic
- Priority: Low
- Related: 155o (Inscription without glyphs: today the only profession
  with off-hand recipes), 155n (Outland without tradeskills), 812
  (enchanting scrolls from dungeon bosses)

## Origin

Verbatim, 2026-10-04: "Also... I don't think there's any profession that
can create staffs and off-hand items. Is that true? If so, can we make
Enchanting do that too?"

## Current Behavior

Not built. Checked 2026-10-04 against the client's spell and skill tables
(every recipe whose spell creates an item, matched to the skill that
teaches it): no profession makes a staff; Inscription alone makes
off-hand items (14 recipes, the expansion's tomes). On basic Inscription
has been reshaped into a buff-scroll profession (155o); whether those 14
recipes are still taught there is to be checked.

## Intended Behavior

Enchanting also makes staves and off-hand items (held in the off hand,
not shields): recipes across its skill range, each making an item of
about the level a character with that skill has, from enchanting
materials (dusts, essences, shards) and a base (a wooden stave, a rod, a
plain tome or orb).

### Answers, 2026-10-04 (Ritz)

- "how about inscription makes the precursor ingredient (runed staff) and
  Enchanting makes the equipment": Inscription makes the blanks (a runed
  staff; for off-hands, a runed tome or orb), Enchanting turns a blank
  into the finished staff or off-hand item.
- "ideally, real recipes. fallback implementation would be the crafting
  menu, if it'd work. And we'd have to craft them at a place of deep
  spiritual value, like the altar of storms or a grand cathedral." Real
  recipes in the profession window first; the Lua crafting menu only if
  that can't be done. Enchanting's finishing step works only at such a
  place (the Altar of Storms, a capital's cathedral: a short list of
  spots, open question 3).
- Item levels: "ya up to level 60".

## Suggested Implementation Steps

1. Choose the items: existing staves and off-hands from the world database
   that drop nowhere (or new items reusing existing looks), one or two per
   step of skill.
2. The recipes as spells: existing crafting spells cannot be added without
   a client patch, so either reuse unused crafting spell ids the client
   already knows, or teach them from a trainer menu in Lua that makes the
   item directly (a scripted craft).
3. Trainers: the enchanting trainers teach them.

## Open Questions

1. (Answered 2026-10-04) Real recipes; the Lua menu as the fallback.
2. (Answered 2026-10-04) Up to level 60.
3. (Answered 2026-10-22) Which places: "it's different per recipe, it
   says per recipe, and it's at a location that a typical player
   levelling through their professions and character level could
   theoretically visit and not be too bothered by the monsters. The
   highest level ones require high level areas, essentially, but the low
   level ones might just be... like, a moonwell in Darnassus or whatever.
   Also we should have multiple copies of the recipe with multiple
   locations, and those recipes should drop from creatures in the area to
   people with the profession, and not to those who don't have it." So:
   - each recipe names its place in its text, and its finishing step
     works only there;
   - the place suits the recipe's level: a low recipe at a safe spot (a
     moonwell in Darnassus), a high one in a high-level area, always one a
     player of that level can reach without much trouble;
   - each item has several copies of its recipe, each with its own place;
   - a copy drops from creatures around its place, and only to characters
     who have Enchanting (loot only those characters can see).
   Open: are these drops in place of the trainers (answer 1 said real
   recipes; trainers were step 3), or beside them? And the server needs a
   way to tell "at the place" (a spell focus object there, as cooking
   fires and forges are, or an area check).
