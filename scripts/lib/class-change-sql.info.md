# class-change-sql.lua

Works out what turning one character into another class means for the
database, and writes it as SQL. The thinking half of
`scripts/change-character-class`, which gathers the character's state,
backs it up and applies the SQL. Tested offline by
`scripts/test-change-character-class`.

Run as a program, not loaded as a library:

| Argument | What |
|---|---|
| 1 `PROJECT_DIR` | the project folder (string); the client tables are read from `data-files/dbc/` |
| 2 `STATE_FILE` | the character now (path): tab-separated lines `char guid race class level`, `skill id value max`, `spell id` (all integers) |
| 3 `NEW_CLASS` | the target class number (integer, ChrClasses: 1 warrior … 11 druid) |
| 4 `SQL_OUT` | where the SQL goes (path): one transaction |

Prints a short plain-English report (classes, skills removed and added,
spells removed, whether talents are reset).

## What it decides, and from which client tables

- **Category of a skill** (`SkillLine.dbc`, field 1): 6 weapon, 7 class,
  8 armor. Only these three are ever touched; languages, racials,
  professions, riding are never removed.
- **A class's own lines** (`SkillRaceClassInfo.dbc`): a class-category
  skill with a row naming exactly one class (priest's Holy: class mask 16).
  Class-category skills with only "every class" rows (Mounts, Companion
  Pets, a hidden line 769) are nobody's class line. Weapon skills and
  riding also have single-class rows but are not class lines.
- **Skills removed:** held, touchable, listed, and not for the new class.
- **Spells removed** (`SkillLineAbility.dbc`): any spell under another
  class's line (even if also under a generic line: the warlock's
  Felsteed), or whose every line is being removed. Their cooldowns and
  action-bar buttons go with them.
- **Skills added:** the new class's own lines, full (level × 5 of level ×
  5). The server teaches their automatic first spells at the next login.
- **Only on a real change** (old class ≠ new): talents, glyphs, auras and
  pets are cleared, the class is set, and talents are reset at next login.
  So a second run on the same character writes an empty transaction.

Lessons from the first runs (2026-10-14) are comments in the source at the
rule each one fixed.
