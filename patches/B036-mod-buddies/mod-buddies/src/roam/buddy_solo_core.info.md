# buddy_solo_core.h

A buddy's sense of which foes it can beat alone: the hardest fight it has
won with no help, one per kind of foe (issue 623, question 7). Plain
arithmetic, no server; checked by `scripts/test-buddy-solo-record`. Not yet
wired into the server: nothing notes a solo kill or keeps the records on a
buddy so far.

## Kinds

| Name | What it is |
|---|---|
| `Kind` (uint8 enum) | `KIND_WARRIOR`, `KIND_PALADIN`, `KIND_ROGUE`, `KIND_MAGE`, and `KIND_COUNT` (4) |
| `KindOf(unitClass, kind)` | takes a creature's `unit_class` (uint32: 1, 2, 4, 8); gives its kind and true, or false for any other value |

## A fight

`Fight`, six floats:

| Field | Meaning |
|---|---|
| `foeHealth` | the foe's health at the start (points) |
| `foeDps` | the damage per second it dealt to the buddy |
| `healthLost` | health the buddy lost (points) |
| `manaSpent` | mana or its resource spent (points) |
| `seconds` | how long the fight took |
| `goldCost` | consumables used, in copper |

`MoreInEvery(a, b)`: true when `a` is at least `b` in all six and more in one.

## A buddy's records

`Records`:

| Member | Type | Meaning |
|---|---|---|
| `has[4]` | bool | whether a record of each kind exists |
| `best[4]` | Fight | each kind's record |
| `standIn` | bool | a stand-in: keeps none, never afraid |
| `Won(kind, fight)` | -> bool | a solo win: becomes the record if there is none, or replaces it if more in every number; true when it changed |
| `Forget()` | | all records gone (Sargobras set the level, or the class changed) |
| `CanTake(kind, foeHealth, foeDps, allies)` | -> bool | whether the foe's health and damage per second are each within the record's, times the allies near (alone: times 1); always true for a stand-in; false with no record of that kind |
