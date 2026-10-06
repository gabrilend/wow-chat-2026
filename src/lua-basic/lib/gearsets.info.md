# lib/gearsets.lua

Finds a character's record in a gearset profile (issue 617r). Pure Lua;
the talent check is passed in. Tested by `scripts/test-gearsets`.

| Function | Takes | Gives |
|---|---|---|
| `Gearsets.load(dir, name)` | dir: text, the profiles folder ending in `/`; name: text, letters, digits and dashes | the profile table; errors naming the file when missing or misshapen |
| `Gearsets.spec_of(class_trees, knows)` | class_trees: the class's three trees from `data/buddy-talent-data.lua`; knows: function(spell id integer) -> boolean | the talent tree id (integer) with most points and the count, or nil, 0 with none spent; ties go to the leftmost tree |
| `Gearsets.record(profile, class, spec, race)` | profile: from `load`; class, race: integers; spec: integer or nil | the record, or nil and the reason (text); never a near match |

## A profile (`data/gearsets/<name>.lua`)

| Field | Type | Meaning |
|---|---|---|
| `name` | text | the file's own name |
| `keyed_by` | text | `"spec"` (talent tree id, TalentTab) or `"class"` (class id), the first level of `records` |
| `records` | table | spec or class (integer) -> race id (integer) -> record |

A record:

| Field | Type | Meaning |
|---|---|---|
| `items` | table | equipment slot (integer, 0 head ... 17 ranged; 3 shirt and 18 tabard never listed) -> item id (integer) |
| `bags` | list of integers, optional | bag item ids, into empty bag slots in order (a quiver is a bag) |
| `ammo` | table, optional | `item` (integer), `count` (integer) |

The same item in slots 15 and 16 is a dual-wield pair.
