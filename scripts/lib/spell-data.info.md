# lib/spell-data.lua

What a spell does, read from the game's own spell file
(`data-files/dbc/Spell.dbc`, the file the server reads), with the world
database's replaced rows (`spell_dbc`, how basic rescales spells) winning
as they do in the server. Returns its table:
`local Spells = dofile(".../spell-data.lua").open(DIR, MYSQL)`.

| Function | Takes | Gives |
|---|---|---|
| `SpellData.open(dir, mysql)` | dir: project folder (text); mysql: a command line running one query with `-N -B` (text), or false for the file alone | a reader (below); stops with an error if the file is missing or `spell_dbc` does not have the file's column count |
| `R.exists(id)` | spell number | true when the file or the database has it |
| `R.name(id)` | spell number | its English name (text), or nil |
| `R.school(id)` | spell number | its school bit mask (number: 1 physical, 2 holy, 4 fire, 8 nature, 16 frost, 32 shadow, 64 arcane), or nil |
| `R.replaced(id)` | spell number | true when `spell_dbc` replaces its row |
| `R.effects(id)` | spell number | list of its effects, or nil; each a table: `effect` (what it does: 2 school damage, 6 apply aura, ...), `aura` (for auras: 3 periodic damage, 30 skill, 189 rating, ...), `base` (smallest amount, as shown), `dice` (at most this much more), `misc` (the aura's which-one: a skill number, a rating mask), `target`, `radius` (radius index, 0 = one target), `period` (ms between ticks); all numbers |

Used by `scripts/tank-damage-taken` (equip effects' defence, dodge and
parry on tank gear; next, bosses' spells for issue 155f1).
