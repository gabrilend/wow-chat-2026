# druid-moonglade.lua

A druid's hearthstone is Teleport: Moonglade (spell 18960), on beta (issue
211a). Every druid knows it from level 1. Cast out in the world, it goes to
the glade, to a random spot on its open ground, and remembers the druid's
way back, worked out at the cast: where they stood, or the entrance of the
dungeon or raid they were in (`data/instance-entrances.lua`). Cast in the
glade, it sends them back there. The group is invited along as visitors
(issue 211's window, the dead too); visitors are placed round the druid,
raised if dead, and sent back to their own ways back as soon as the druid
leaves the glade. The druid's way back and the visitors are kept in the
characters database (`beta_211a_moonglade_return`,
`beta_211a_moonglade_visitors`, installed by E060), so logouts and
restarts keep them. Checked offline by `scripts/test-druid-moonglade`.

## Functions

### `Moonglade.onLogin(event, player)`
A visitor whose druid has left, is offline or is out of the glade goes
back. A druid learns the spell if they lack it, has their way back read
into `Moonglade.spots`, and, if they have visitors but are not in the
glade (a restart in between), has left it.

### `Moonglade.onLogout(event, player)`, `Moonglade.onZone(event, player, newZone, newArea)`
A druid logging out or leaving zone 493 sends their visitors back
(`Moonglade.druidLeft`); a visitor leaving zone 493 stops being one.

### `Moonglade.onPrepare(event, caster, spell)`
The cast begins (the engine's per-spell event): outside the glade, opens
211's invitation with the glade's own words; in it, invites nobody.

### `Moonglade.onCast(event, player, spell)`
The spell-cast handler (fires as a cast completes, before its effect).
For Teleport: Moonglade only:
- in Moonglade (zone 493) with a way back: books the return 1.5 seconds
  later; without one: a message, and the spell's own Nighthaven;
- outside it: remembers the way back (none known: forgets, with a
  message), takes the visitors who said yes with their own ways back (one
  whose way back is not known stays, with a message), and books the
  arrival.

### `Moonglade.arrive(eventId, delay, repeats, player, tries)`
The booked arrival: once the druid is in Moonglade, moves them to a spot
from `Moonglade.drawArrival` and the visitors round it, on 211's circle
by group number, raising the dead; not there yet, looks again (3 tries);
no spot drawn, leaves the druid in Nighthaven, logs it, and brings the
visitors round them there.

### `Moonglade.drawArrival(map) -> x, y, z, o, or nil`
A random spot on the glade's open ground, by the rules in
`Moonglade.GLADE` (up to 40 draws).

### `Moonglade.goBack(player, spot)`
Sends the druid to `spot` and forgets it; the visitors follow by the zone
change.

### `Moonglade.druidLeft(druidLow)`
Every visitor of that druid in the database: online, sent back now;
offline, marked to be sent back at login.

### `Moonglade.wayBack(player) -> { map, x, y, z, o } or nil`
Where a player returns to: where they stand in the open world; the
entrance of the dungeon or raid they are in; nil in a battleground, an
arena, or a dungeon with no entrance in the table.

### `Moonglade.remember(guidLow, spot)`
Keeps a druid's way back, `{ map, x, y, z, o }`, or forgets it (`nil`), in
memory and in the database.

## Data

- `Moonglade.GLADE`: the arrival rules. `x_min, x_max, y_min, y_max`
  (numbers, the valley floor's box, yards), `land_z` (Nighthaven's ground,
  512.1), `HEIGHT_BAND` (40: how far a spot's ground may be from it),
  `STEEP` (3: the most the ground may rise over 3 yards), `DRAWS` (40),
  `AREAS` (set of area numbers: 493 Moonglade, 2361 Nighthaven, 2362 the
  Shrine of Remulos).
- `Moonglade.ENTRANCES`: `data/instance-entrances.lua`, by dungeon map
  number, `{ map, x, y, z, o }`.
- `Moonglade.spots`: by character guid low part, `{ map = number, x, y,
  z, o = numbers }`, or `false` for none.
- `Moonglade.visiting`: by visitor guid low part, `{ druid = guid low
  part, back = spot }` (the database holds the same).
- `Moonglade.hosting`: by druid guid low part, `true` while they have
  visitors.
- `Moonglade.trips`: by druid guid low part, between the cast and the
  arrival: `{ list = list of { low, place = number, back = spot },
  size = number }`.
