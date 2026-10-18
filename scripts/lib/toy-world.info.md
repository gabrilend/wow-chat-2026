# scripts/lib/toy-world.lua

A pretend game world for testing beta's Lua scripts without a server (the
guide is `docs/toy-world.md`). Used by `scripts/test-ambush`,
`scripts/test-travel`, `scripts/test-treasure`, `scripts/test-hearthstone`
and `scripts/demo-beta-toy-session`. Load it with
`dofile(<scripts folder> .. "lib/toy-world.lua")`; it installs, as
globals, the game functions the scripts call, and returns the table
`Toy` described below.

It checks a script's own decisions, not how the game would carry them out.

## The game's functions, as globals

- `RegisterPlayerEvent(event, fn)`: keeps `fn` in `Toy.handlers[event]`.
- `GetPlayerByGUID(guid)`, `GetPlayerByName(name)`: a logged-in player, or nil.
- `GetPlayersInWorld()`: the logged-in players in login order.
- `WorldDBQueryAsync(sql, callback)`: answers the ambush's creature
  question from `World.answer`, filtered by rank and level as the real
  query is.
- `GetMapById(id)`: the map made with that number, or the flat one.
- `bit_and(a, b)`: as the engine's.
- `RegisterGameObjectEvent(entry, event, fn)`: a chest's events; event 13
  (removed from the world) is the one the toy fires.
- `RegisterItemEvent(entry, event, fn)`: kept in `Toy.itemHandlers[entry][event]`.
- `RegisterPlayerGossipEvent(menu, event, fn)`: kept in
  `Toy.gossipHandlers[menu][event]`.
- `CharDBExecute(sql)`, `CharDBQuery(sql)`: the characters database, for
  the one table the druids' Moonglade return keeps (`Toy.chardb.moonglade`,
  rows by guid). Any other statement is an error: teach the stand-in first.

## The table it returns (`Toy`)

- `World`: `{ now = ms, events = pending calls, players = by guid low,
  order = players in login order, nextGuid = number, answer = by rank, a
  list of { entry, minLevel, maxLevel } }`
- `schedule(owner, fn, delay)`, `advance(ms)` (runs due calls in time
  order, skipping despawned or logged-out owners), `pending(owner, fn) ->
  count`
- `new_map(id, height(x, y) -> number or nil, water(x, y) -> boolean,
  area(x, y, z) -> area number)`, `FLAT` (ground 0 everywhere, area 0),
  `maps` (by map number)
- `new_creature(entry, map, x, y, z)`, `new_player(name, guidLow)`: plain
  tables with the methods the scripts call. Fields a test sets or reads
  directly: `x, y, z, standing, dead, wet, moving, level, class, horde,
  bot`; `spawned` (creatures a player summoned), `objects` (chests),
  `bags`, `buyback` (12 slots), `home` (bind point `{ mapId, x, y, z }`),
  `teleports` (list of `{ map, x, y, z, o }`), `window` (the open gossip
  window: `{ menu, items = list of { text, sender, intid, popup } }`),
  `spells` (set of known spell numbers), `zone` (number), `messages`
  (what they were sent, a list of strings).
- `login(p)`, `logout(p)`: run the registered handlers. Logout wipes the
  player's data (as the object-variables extension does), removes their
  chests and empties the buyback tab (as the game does).
- `handlers`: event number -> list of functions.
- `new_gameobject(entry, map, x, y, z)`, `new_item(entry, fields)`: a
  chest, and an item with the fields the sale rules read (quality 2,
  required level 0, item level 10, stack 1, class 2, count 1 unless given).
- `give(p, item)`, `sell(p, item)`, `buy_back(p, item)`: an item into the
  bags; out of them through the sell event into the buyback tab (the
  oldest pushed out past 12); and back again.
- `group(players)`: puts the players in one group, and returns it.
- `answer(p, intid)`: picks the option with that number in the player's
  open window, as a click would; false when there is none.
- `spell(entry)`: a spell object as the spell-cast event passes it.
