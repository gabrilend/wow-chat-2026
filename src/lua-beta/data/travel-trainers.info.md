# data/travel-trainers.lua

The class trainers who may travel by on beta, and the slice of levels
1-20 each covers. Returns a list of rows `{ trainerID = creature entry,
minLevel, maxLevel, rel = 1 horde | 2 alliance | 3 either, id = minus the
class number (-1..-9, -11) }` (the file's header explains each field).

Read by `travel.lua` (which trainer a player meets) and by
`scripts/generate-beta-trainer-tiers-sql`, which writes install step E014:
each trainer's own copy of its class's lessons, cut at its `maxLevel`.
Edit this file, then run the generator. `scripts/test-travel` checks that
every class at every level for both factions meets exactly one trainer.
