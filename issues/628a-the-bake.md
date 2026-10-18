# 628a - The Bake: a Buddy's Creature From the Characters Database

## Status
- Created: 2026-10-17
- Phase: 6
- Parent: 628 (buddies wander as baked NPCs)
- Blocked by: 617r4 (gearsets on creatures), 617f (B047's creature
  outfits)
- Related: 160 (the client caches creature names and must be told when
  they change), 617t1 (stand-ins: the same bake would serve them)
- Priority: Medium

## Origin

See 628 (the owner's words, 2026-10-17, quoted in full there).

## Current Behavior

**The reading half, 2026-10-17** (homework branch):
`scripts/generate-buddy-bake-sql` reads every buddy (the roster joined
to its character row: name, level, race, sex, skin, face, hair, hair
colour, beard, and the 19 slots of its equipment cache), each worn
item's picture, each race's body and faction (ChrRaces.dbc), and writes
an apply and a revert SQL file to `tmp/shared-memory/buddy-bake/`,
changing no database. Each buddy gets: a creature record copied from the
wandering Sargobras (6170002) as the buddy-selector step does, at entry
6280000 + its guid (the range stops below 7180001); its race and sex's
body; its weapons as the creature's equipment row; and an outfit row (11
places in the client's order, plus the line it was baked from) in a new
`creature_outfit` table the file creates. Run 2026-10-17 on the basic
databases: 27 buddies read, 27 baked, none left out.

Not yet:
- **Nothing reads `creature_outfit`.** B047's list is still filled in
  code (`buddies_outfits.cpp`); step 1 below.
- **Health and mana are the creature's normal for its class and level**,
  not the buddy's: the character row saves health as it was at logout
  (1 for buddies that logged out dead), and the saved maximums
  (`character_stats`) are empty while `PlayerSave.Stats.MinLevel` is 0.
  The tool says so on every run (question 2).
- **The apply file has not been tried on a database.**
- The change watcher and the skip-when-unchanged check (the line it was
  baked from is written, not yet compared).

Before this, B047's outfit list held three hand-written entries (the
Sargobras); nothing derived an entry from a character.

## Intended Behavior

A tool, not a hand-written row: given a buddy (or all of them), it reads
the buddy from the characters database and writes everything its
creature needs.

**Read, per buddy** (the characters database, `acore_characters`):
- from the character's own row: name, race, class, sex, level, skin,
  face, hair style, hair colour, facial hair;
- what it wears: the 19 equipment slots (the character row's equipment
  cache, or its inventory's bag-0 slots 0-18 joined to the item
  instances), each slot's item turned into its picture (the item
  template's display id, world database);
- its health and mana at its level (the character's saved stats), so the
  creature isn't visibly weaker than the buddy.

**Written, per buddy:**
- a creature record in a range kept for buddies (one entry each, so its
  name is its own): name, level, faction of the buddy's side, health,
  mana, the gossip flag (628c), not attackable by its own side;
- its outfit entry (race, sex, skin, face, hair, beard, the item
  pictures), in the list B047 answers the mirror-image question from;
- a stamp of what it was baked from (the buddy's look and gear as a
  short fingerprint), so a rebake is skipped when nothing changed.

**When it runs:** on demand (`scripts/` tool, all buddies or one), and
whenever a buddy's look or worn gear changes (the module notices the
change, marks the buddy for rebaking, and the rebakes are written
together in one batch rather than one database trip each).

**Errors, not fallbacks:** a buddy whose race has no body, or an item
with no picture, stops that buddy's bake with a message naming the
buddy, the slot and the item; the others are still baked and the report
says which were.

## Suggested Implementation Steps

1. Read 617r4's record shape and B047's outfit list; make the outfit list
   load from a table rather than code, so baked entries need no rebuild.
2. The tool: read, fingerprint, write (creature record, outfit row),
   report baked, skipped (unchanged) and failed.
3. The change watcher in the buddy module: gear equipped or removed,
   look changed (barber), level gained → mark, batch, rebake.
4. Test: bake one buddy, spawn its creature beside it in game, compare
   the two side by side (a screenshot through the custom client's test
   runs).

## Open Questions

1. When a buddy's name or look changes, the client keeps the old
   creature name in its cache until told (160). Rebake to a fresh entry
   each time, or send the name again?
2. **The buddy's own health.** The server doesn't save a character's
   maximum health and mana unless stat saving is on
   (`PlayerSave.Stats.MinLevel`, 0 today on basic). Turn it on (a config
   patch; it writes one row per character at logout), so the baked
   creature has the buddy's own health, or is a creature's normal health
   for its class and level good enough for a body that only wanders?
