# 617q - The Word "Owner" Renamed: A Buddy's Player Is Its Partner

## Status
- Created: 2026-10-04
- Phase: 6
- Parent: 617
- Blocked by: None
- Priority: Low

## Origin

The owner of the project, 2026-10-03, while describing party rules: "God,
we gotta think of a different word than 'owner'." She used
"player-partner" herself; asked whether to rename, 2026-10-04: "It's fine
I guess. Make it an open issue that we need to replace the 'owner' name."

The buddies' design (617c4) says why the word is wrong: "they aren't
masters, they're clanmates, and there wouldn't be a hierarchy except only
the player can do certain things".

## Current Behavior

The player a buddy belongs to is called its "owner" everywhere: the
roster's column (`buddy_roster.owner`, `buddy_clan.owner`,
`buddy_draw.owner`), the module's code and comments
(`patches/B036-mod-buddies/mod-buddies/src/`, about 1,400 uses of words starting "owner"
there and in `src/lua-basic/`, counted 2026-10-04 with `grep -rho
"\bowner\w*"`), the log lines, the issue files and the docs. From
2026-10-04 the conversation with the project's owner says "partner"
(the "player-partner"); the files don't yet.

## Intended Behavior

- The player a buddy belongs to is its **partner** in every name a person
  reads: comments, log lines, trace lines, issue files, docs, and the
  names in the code (variables, functions, table columns).
- The project's owner (the person) stays "the owner" where the issues
  quote or credit her, so the two meanings no longer share a word.
- The database columns change through the install step that owns them
  (E042), keeping existing rows: a renamed column, not a dropped one.

## Suggested Implementation Steps

1. A list of every use (code, SQL, Lua, issues, docs), made by a script,
   kept with this issue so the rename can be checked as finished.
2. The columns renamed in `04-buddy-roster.apply.sql` with a guarded
   `ALTER TABLE ... RENAME COLUMN` (as the greeting column was added), and
   every query that names them changed in the same commit.
3. Code names and comments, file by file, each file compiled (syntax
   check) after its change.
4. Issue files and docs: "owner" meaning the buddy's player becomes
   "partner"; quotes of the project's owner left as they are.
5. A test that greps for the old word in code and SQL and fails while any
   use of the buddy meaning is left.

## Open Questions

- (Open) "Partner" or "player-partner" in names? The first is shorter in
  code; the second is what the project's owner said.

## Related Issues

- **617** parent; touches every 617 sub-issue's files
