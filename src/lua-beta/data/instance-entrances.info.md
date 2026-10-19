# data/instance-entrances.lua

Generated; don't edit by hand. Made by
`scripts/generate-beta-instance-entrances` from beta's world database
(`instance_template`, `areatrigger_teleport`) and the game's
`AreaTrigger.dbc` and `Map.dbc`. Run it again after the world database's
triggers change.

Returns one table: by the map number of a dungeon or raid, the spot just
outside its entrance, `{ map = number (the open-world map), x, y, z, o =
numbers }`, the place the dungeon's own way-out trigger sends players (as
the core's `ObjectMgr::GetGoBackTrigger`). With two ways out, the one
nearest the entrance portal; a way out into another dungeon is followed
until it reaches the open world. Battlegrounds and arenas have no row.

Read by `druid-moonglade.lua` (`Moonglade.ENTRANCES`), for a druid or
visitor's way back from the glade (issue 211a).
