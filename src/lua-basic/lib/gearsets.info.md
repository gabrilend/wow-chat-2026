# lib/gearsets.lua

Finds a character's record in a gearset profile (issues 617r, 617r1).
Pure Lua; the talent check is passed in. Tested by `scripts/test-gearsets`.

| Function | Takes | Gives |
|---|---|---|
| `Gearsets.load(dir, name)` | dir: text, the profiles folder ending in `/`; name: text, letters, digits and dashes | the profile table; errors naming the file when missing or misshapen |
| `Gearsets.points_of(class_trees, knows)` | class_trees: the class's three trees from `data/buddy-talent-data.lua`; knows: function(spell id integer) -> boolean | points spent per tree, a list of three integers |
| `Gearsets.nearest_shape(shapes, per)` | shapes: the class's ten shapes; per: three integers | the shape id (1-10) whose thirds lie nearest; `EVEN_SHAPE` (7) with no points |
| `Gearsets.record(profile, who)` | who: `{ class, shape, race, level }` integers | the record, or nil and the reason (text); never a near match |

## A profile (`data/gearsets/<name>.lua`)

| Field | Type | Meaning |
|---|---|---|
| `name` | text | the file's own name |
| `keys` | list of text | the order records are filed in, from `shape` (class x 100 + shape id), `class`, `race`, `level` (the highest key at or below the character's level) |
| `records` | nested tables | one level per key, the record at the bottom |

A record:

| Field | Type | Meaning |
|---|---|---|
| `items` | table | equipment slot (integer, 0 head ... 17 ranged; 3 shirt and 18 tabard never listed) -> item id (integer) |
| `bags` | list of integers, optional | bag item ids, into empty bag slots in order (a quiver is a bag) |
| `ammo` | table, optional | `item` (integer), `count` (integer) |

The same item in slots 15 and 16 is a dual-wield pair.
