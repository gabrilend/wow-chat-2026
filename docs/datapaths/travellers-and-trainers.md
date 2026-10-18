# Data path: travellers, and the trainers among them

*How a class trainer of the right level walks up to a beta player, and
where its lessons come from. Written 2026-10-17. Code:
`src/lua-beta/travel.lua` and `src/lua-beta/data/travel-trainers.lua`
(summaries beside them); install steps E011, E013, E014; tests
`scripts/test-travel` and `scripts/test-beta-sql-in-ram`.*

## In the game

1. **Login** (`Travel.onLogin`). The player's traveller lists are made
   from the categories in travel.lua (ammo, innkeepers, trainers,
   consumables, poisons, others, melee, ranged, armor, food), filtered by
   class (`Travel.getTravelerTypeMask`: a mage meets no ammunition vendor),
   faction and level. The trainer category adds exactly one trainer: of
   the player's class, whose slice of levels holds the player's level. Real
   players also get the clock; bots get lists only.
2. **The clock** (`Travel.tick`): a minute after login, then every 130
   seconds; booked first, then the holds (`Travel.HOLDS`: dead, swimming,
   sitting).
3. **The traveller** (`Travel.spawnAndTravel`): one entry drawn at random
   from the lists (refilled, at the current level, when empty), placed 30-45
   yards away in a square ring, summoned to leave after 5 minutes or when
   killed, and set walking past the player to the opposite side.
4. **The walk** (`Travel.continueTravelling`, every 2-4 seconds): 10 yards
   at a time along its heading, turning away from steep ground; sits while
   the nearest player sits (issue 504); leaves when no player is within 200
   yards.
5. **Talking to a trainer** is the game's own trainer window, which reads
   the trainer's lesson list from the database (below).

## In the database: where a trainer's lessons come from

The server reads lessons from `trainer_spell` (rows: list number, spell,
price in copper, required level, required spells), finds a creature's list
through `creature_default_trainer` (creature entry -> list number), and
the list's kind and class from `trainer` (kind 0 is a class trainer, its
`Requirement` the class). Every trainer of a class shares one list in the
stock game. Beta's install steps change that, in order:

| Step | What it does | Lists it makes |
|---|---|---|
| E011 | the death knight kit for levels 2-20; the three death knight trainers (29194-29196) point at it | 2060001 |
| E013 | 21 quest-taught lessons (Defensive Stance, Call Pet, the totems...) added to every class list of their class; a record of what it added | none (adds to the game's lists) |
| E014 | each travelling class trainer gets its own copy of its class's list, cut at the top of its slice, and points at it | 5030001 onward, one per trainer (issue 503's block) |

E014's SQL is generated (`scripts/generate-beta-trainer-tiers-sql`) from
`data/travel-trainers.lua`, the same list travel.lua reads, so the slice a
player meets a trainer for and the slice that trainer teaches are one
fact. Nothing of the game's own lists is cut or deleted; each step has an
undo file beside it that returns the tables exactly
(`scripts/test-beta-sql-in-ram` checks this on a stock database).

## How it got here

- **wow-chat-1** sent travellers from its scheduler every 210 seconds;
  the trainer table listed world trainers per class, each for a level band
  of 1-80. The three slips fixed in October are already there: priest
  4906 (no such creature), Ker Ragetotem (3043, a warrior trainer) as the
  first horde druid, and druids numbered -10. So no wow-chat-1 druid met a
  trainer either.
- **2026-04-05, issue 503:** the trainer bands were renormalised to 1-20,
  "20 levels shared among each class's trainers", and an install step was
  written to cut each trainer's lessons to its band. It was written against
  `npc_trainer`, the table older servers used, where a trainer's number was
  its creature entry.
- **2026-04-10:** every custom script switched off for the profile
  baseline; travellers with them.
- **Some time before October:** the server's trainer data moved to
  `trainer`, `trainer_spell` and `creature_default_trainer` (shared lists).
  `npc_trainer` stayed in the database, unread, so beta's E011, E013 and
  E014 kept running without effect, and their undos (written for the old
  table) deleted the game's own rows there.
- **2026-10-17:** travellers back on with a clock of their own (the old
  scheduler's bot half was left mid crash-hunt, so it stays off); the trainer
  table moved to a data file and three slips in it fixed (a priest that did
  not exist, a warrior filed as a druid, druids numbered 10 where the game
  numbers them 11); the install steps rewritten for the current tables, with
  per-trainer copies instead of deletions.

## Related

Issues 503 (dynamic trainer spawning), 504 (sitting with the player), 505
(creature-class travellers), 701 (quest spells to trainers), 206 (death
knights from level 1), 721 (class trainers for custom classes);
`docs/datapaths/ambush.md` (the clock pattern travellers follow).
