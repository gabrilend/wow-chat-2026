# 635a - A Party Checkpoint: Save and Restore

## Status
- Created: 2026-10-27
- Phase: 6
- Parent: 635
- Blocked by: none
- Related: 197 (`scripts/change-character-class` and its backups)
- Priority: High
- State: in progress (the tool and its test built 2026-10-27; the
  Botanica party not yet made, so not yet saved; the place and the
  grouping not yet part of a restore)

## Current Behavior

**Built 2026-10-27**: `scripts/party-checkpoint` (`save NAME
CHARACTER...`, `restore [--dry-run] NAME`, `list`, `show NAME`,
`tables`).
- A checkpoint is a folder, `backups/checkpoints/NAME/`: a `party` list
  (name, character number, level, class) and one SQL file per character,
  which deletes what the character holds and loads what it held, in one
  transaction.
- What a character's picture holds is a table list in the tool: kept
  (saved and restored: the character, its items through its inventory,
  spells, talents, glyphs, bars, skills, quests, reputation, pets and
  their spells, its bot settings), cleared (deleted on restore, not
  saved: cooldowns, auras, dungeon locks, a corpse), and left alone with
  a reason (shared things: guilds, groups, mail, teams, the auction
  house; logs; the buddy module's own records).
- Rows are written by the tool, not by `mysqldump`: the dump tool prints a
  FLOAT (a position, a facing) in a short form that loads back as a
  different number, which the test caught; the tool reads floats as
  doubles and text as hexadecimal, so a restore is bit for bit.
- Both commands refuse while a character is online (the server holds it
  in memory and would write over a restore), naming who.
- `scripts/test-party-checkpoint` (a quick test on basic) checks that
  every table of the characters database naming a character is kept,
  cleared or explained, and round-trips one offline character through
  scratch databases: saved, changed, a dry run (no change), a refusal
  while online, a restore equal to the save by MySQL's table checksums,
  cooldowns cleared, a second restore the same as the first.

Not yet: the party itself (635's questions on who the five are), and a
restore that also forms the group and stands it at the Botanica's door
with the dungeon reset (today the place is whatever the characters had
when saved, which is the door if they are saved there).

## Intended Behavior

- **`scripts/party-checkpoint save NAME CHARACTER...`** keeps everything
  the party is: each character's rows (level, talents and both talent
  pages, spells, action bars, skills, gear and bags, money, reputation,
  auras removed), its bot settings (strategies, skipped spells, role),
  the group itself and the place (the Botanica's entrance).
- **`scripts/party-checkpoint restore NAME`** puts it all back as saved:
  the same characters, healthy, cooldowns cleared, grouped, at the place,
  with the dungeon reset for them. "Easily and quickly": one command, the
  server stopped or running (a running server is told through its
  console, as the GM tools are).
- **`list`** and **`show NAME`**: what checkpoints exist, and what is in
  one.
- **Saved as files** in `backups/checkpoints/NAME/`, one per character, so
  a checkpoint can be read, compared with another and kept in git.
- Idempotent: restoring twice is the same as once.

## Suggested Implementation Steps

1. The list of character tables a checkpoint holds, read from the
   character database's own schema, so a new table is not missed (a quick
   test: every table with a character column is listed or named as
   skipped, with a reason).
2. Save and restore, with a dry run.
3. A test on a scratch character: save, change it, restore, compare.

## Open Questions

- Follows 635's second and third questions.
