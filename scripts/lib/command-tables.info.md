# scripts/lib/command-tables.lua

Reads the game server's C++ command tables out of source files and returns
every whole command as data. Loaded with
`package.path = "<project>/scripts/lib/?.lua;" .. package.path` and
`require("command-tables")`.

## Functions

| Function | Takes | Gives |
|---|---|---|
| `read_file(path, shown_as)` | path: string; shown_as: string or nil, the path to print in results | commands: list; errors: list of strings |
| `read_files(paths, root)` | paths: list of strings; root: string or nil, stripped from the front of each path shown | commands: list; errors: list of strings |
| `files_with_tables(folder)` | folder: string | list of the `.cpp` paths under it that mention `ChatCommandTable`, sorted |

## A command

| Field | Type | Meaning |
|---|---|---|
| `name` | string | the words without the dot, joined by single spaces (`buddy bed add`) |
| `level` | number or nil | 0 player, 1 moderator, 2 game master, 3 administrator, 4 console; nil when the code names an `rbac::` permission, which no account level reaches (the world database's `command` row then decides) |
| `perm` | string | the permission exactly as written in the code (`SEC_GAMEMASTER`, `rbac::RBAC_PERM_COMMAND_RELOAD`) |
| `console` | boolean or nil | true: also runs from the server console (and SOAP); false: in game only; nil: the row did not say |
| `file` | string | where it was declared |

## What it understands

- `static ChatCommandTable name = { rows };` and `static ChatCommandTable name { rows };`
- rows `{ "word", Handler, PERMISSION, Console::Yes|No }` (a command), the
  same with a help string before the permission (five fields, cs_rbac.cpp), and
  `{ "word", otherTable }` (nested words); a word may itself hold spaces
  (`"buddy kit"`), and an empty word makes the table's own name a command
- a `GetCommands` body inside a class or defined outside it; the table it
  `return`s is the root; tables defined elsewhere in the same file are found
- comments are removed first, so a commented-out row is not read

An error is returned (not thrown) for a returned table that can't be read,
a row with no quoted name, a nested table defined nowhere in the file, or
nesting deeper than eight.

Used by `scripts/generate-gm-command-reference` and
`scripts/test-gm-command-reference`.
