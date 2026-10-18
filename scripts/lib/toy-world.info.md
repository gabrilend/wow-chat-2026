# scripts/lib/toy-world.lua

A pretend game world for testing beta's Lua scripts without a server, used
by `scripts/test-ambush` and `scripts/test-travel`. Load it with
`dofile(<scripts folder> .. "lib/toy-world.lua")`; it installs the game
functions the scripts call as globals (`RegisterPlayerEvent`,
`GetPlayerByGUID`, `GetPlayerByName`, `WorldDBQueryAsync`, `GetMapById`,
`bit_and`) and returns:

- `World`: `{ now = ms, events = pending calls, players = by guid low,
  nextGuid, answer = by rank, a list of { entry, minLevel, maxLevel } for
  the ambush's database question }`
- `schedule(owner, fn, delay)`, `advance(ms)` (runs due calls in time
  order, skipping despawned or logged-out owners), `pending(owner, fn) ->
  count`
- `new_map(id, height(x, y) -> number or nil, water(x, y) -> boolean)`,
  `FLAT` (ground 0 everywhere), `maps` (by map number, for `GetMapById`)
- `new_creature(entry, map, x, y, z)`, `new_player(name, guidLow)`: plain
  tables with the methods the scripts call; fields a test sets directly
  include `x, y, z, standing, dead, wet, level, class, horde, bot`, and
  `spawned` (creatures a player summoned)
- `login(p)`, `logout(p)` (logout wipes the player's data, as the
  object-variables extension does), `handlers` (event number -> functions)

It checks a script's own decisions, not how the game would carry them out.
