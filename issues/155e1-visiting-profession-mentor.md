# 155e1 - A Visiting Mentor for Professions

## Status
- Created: 2026-10-13
- Phase: 1
- Parent: 155e (quests open to the faction; the Visiting Mentor, a class
  trainer for the classes a site lacks)
- Related: 155p1 (each capital jewelcrafter teaches its own order of
  cuts; the eccentric visitor), 155n (no profession trainers beyond
  Azeroth), B029 (the server honours a trainer list named on a gossip
  line)
- Priority: Medium
- State: built 2026-10-22 (install step E068); waiting for the install and an in-game look

## Origin

Verbatim, 2026-10-13. Asked about jewelcrafting trainers:

> We have a special vendor that teaches all the professions in each
> capital city, right? How does that go?

On hearing it was the Visiting Mentor, who teaches classes, not
professions:

> ah yes we need one of those

## Current Behavior

**Built 2026-10-22, install step E068, waiting for an install.**
`scripts/generate-basic-profession-mentors-sql` writes
`patches/E068-basic-profession-mentors/39-profession-mentors.{apply,revert}.sql`:

- **What each capital lacks:** the stock profession trainers standing
  inside each capital's rectangle (the client's WorldMapArea.dbc, as 155p
  reads it), against fourteen professions (eleven primary, three
  secondary). When built: Stormwind, Ironforge, Orgrimmar and the
  Undercity lacked jewelcrafting; Darnassus blacksmithing, engineering,
  jewelcrafting and mining; Thunder Bluff engineering and jewelcrafting;
  the Exodar and Silvermoon nothing, so they get no mentor. Run the
  generator for the current table.
- **The lists:** one per missing profession (ids 155201-155214), the union
  of that profession's general stock lists (those teaching its recipes
  from skill 0; specialisation lists start at 225 and stay out), stopping
  at 300 as basic's lists do (155n); no required spell, so every player
  sees the line. Jewelcrafting's line opens list 113, the capitals' shared
  list (each capital's own order is 155p1's, not built).
- **Where:** two yards to the right of the city's mining trainer (any
  profession trainer when there is none: Darnassus's fishing trainer),
  where the Visiting Jewelcrafter stood. The six Visiting Jewelcrafter
  spawns are removed and saved; the revert brings them back.
- **The look:** a copy of the highest-level trainer of one of its missing
  professions from another capital of its side (a draenei jewelcrafter in
  Stormwind and Ironforge, a blood elf one in Orgrimmar and the Undercity,
  a dwarf weaponsmith in Darnassus, a goblin engineer in Thunder Bluff),
  named "Visiting Mentor" <Profession Trainer>, gossip and trainer flags.
- **The dialogue:** a greeting, and one "Can you teach me alchemy?" line
  per missing profession opening its list (B029).
- **The dance:** `src/lua-basic/profession-mentors.lua`: only the goblin
  in Thunder Bluff dances (the owner, 2026-10-22: "only the goblin trainer
  dances. And he dances for a set amount of time each time"): he waits 30
  to 90 minutes, dances for exactly a minute, and waits again.
- **Homes of their own:** 155e1a (the goblin's quiet tent in Thunder
  Bluff, robes, wizard decor) and 155e1b (Geraldenge's tower in Darnassus,
  a workshop and sparring youths), planned.
- **Checked:** applied twice and reverted on the real basic world
  database (six mentors, ten lines, the mining list's 17 spells from skill
  0 to 300; the revert leaves it exactly as before); the post-install
  checker's new check passes with it and fails without it, and 155p's
  jewelcrafter check accepts either state. The RAM database test lists the
  step (not run: the RAM disk was too full).

Before: each capital had the stock one-profession trainers, scattered
through the city, and (from 155p) a Visiting Jewelcrafter in the six
capitals that had no jewelcrafting trainer. No trainer taught more than one
profession.

The Visiting Mentor (155e, install step E022): one at each of 23 sites
(every starting valley, first town and capital), teaching the classes
that have no trainer there. It has no list of its own: its dialogue has
one line per missing class ("Can you teach me the ways of the druid?"),
each naming that class's list, which source patch B029 makes the server
open. A player sees only the line for their own class.

## Intended Behavior

A visiting profession mentor in each capital: one creature whose
dialogue has a line per profession ("Can you teach me alchemy?"), each
opening that profession's trainer list, through the same mechanism as
the Visiting Mentor.

## Suggested Implementation Steps

1. Answer the open questions.
2. The profession lists (one per profession, capped at 300 by 155n's
   rules), the gossip menu with a line per profession, and the creature,
   in a basic install step with its revert.
3. Its spawn in each capital, beside the Visiting Mentor or the city's
   crafting quarter (generated, as the mentors' sites are).
4. A check in `scripts/validate-basic-state`: one per capital, every
   profession line opening a list.
5. In game: one capital, each line.
## Answers, 2026-10-22

1. **Only the professions with no trainer in that city** ("Only missing
   ones"), as the class Visiting Mentor does for classes.
2. **Capitals only**, the eight.
3. **Jewelcrafting:** the owner: "idk about this eccentric visiting
   jewelcrafter. Isn't that just, the profession mentor?? Also, if the
   capital has a jewelcrafting trainer already, then the visiting mentor
   wouldn't be able to teach anything, and no action is required. But if
   there's no JC trainer in that capital, then the wandering trainer
   fills that role and uses the capital's set, which... may or may not be
   accounted for currently, so look into that please." Looked into: the
   six Visiting Jewelcrafters (155p) don't wander, each stands in one
   capital; all eight capital jewelcrafters teach one shared list today
   (the per-capital orders are 155p1's, not built). Then, asked whether
   to fold them into this mentor: **merge them**. Each capital has one
   visitor from afar, the Profession Mentor, the eccentric one of 155p1
   (dancing about once an hour); in the six capitals with no jewelcrafter
   it teaches jewelcrafting too, with that capital's own order of cuts
   (155p1). The six Visiting Jewelcrafters are removed. Silvermoon and
   the Exodar keep their stock jewelcrafters (whose orders are 155p1's).
4. **Its look:** "different per city, but should try and match the
   professions that are missing. A tauren in Silvermoon is much easier to
   notice than another blood elf." Each borrows the look of a
   high-level trainer of one of the professions it teaches, preferring
   one of a race other than the city's own (from the same faction), so it
   stands out.

## Intended Behavior (as answered)

One Profession Mentor in each of the eight capitals, a visitor from afar
(155p1's eccentric: about once an hour, every 30 to 90 minutes at random,
it dances for a minute). Its dialogue has a line for each profession with
no trainer in its city ("Can you teach me alchemy?"), each opening that
profession's list (capped at 300, 155n); in a city with no jewelcrafter,
a jewelcrafting line opening the city's own order of cuts. A capital that
has every profession's trainer gets no mentor. It looks like a trainer of
one of its professions, of another race of the faction where one exists.

## Open Questions

None open (answered 2026-10-22, above). 155p1's own questions (the
orders of cuts) still decide the jewelcrafting lists.
