# sargobras-whisper.lua

Reads a whisper sent to Sargobras and says which of his menu's choices it
asks for (issue 617b2). Pure: no server calls; `sargobras.lua` does what it
returns. Tested by `scripts/test-sargobras-whisper`.

`local Whisper = dofile(".../helpers/lib/sargobras-whisper.lua")`

| Function | Takes | Gives |
|---|---|---|
| `Whisper.parse(RC, text)` | RC: the race and class table (`helpers/data/sargobras-race-class-data.lua`: `RC.classes[id].name`, `RC.races[id].name`); text: the whisper (string) | a table: `kind` (string: `"class"`, `"race"`, `"flexible"`, `"help"`, `"owed"`, `"unknown"`), and for class and race also `id` (number: the class or people number) |
| `Whisper.help_line()` | nothing | the one-sentence list of commands he whispers back (string) |

How a whisper is read:
- lower case, punctuation turned to spaces ("Night-Elf!" is "night elf");
- class and people names are matched as whole words, longest first ("blood
  elf" before any shorter name; "priest" not inside "priestess");
- both a class and a people named: the class is taken (his menus offer one
  or the other; the class decides more);
- spec words are read past ("shadow priest" is a priest: the spec is drawn
  as at his menus);
- the death knight is never matched (no owner picks one from him);
- otherwise the keywords: help, commands, owed, flexible, any, anyone;
- nothing matched: `"unknown"` (he tells a joke and the help line).
