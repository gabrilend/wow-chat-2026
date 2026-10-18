# druid-moonglade.lua

A druid's hearthstone is Teleport: Moonglade (spell 18960), on beta (issue
211a). Every druid knows it from level 1. Cast out in the world, it goes to
the glade, to a random spot on its open ground, and remembers where the
druid stood; cast in the glade, it sends them back there. Kept in the
characters database (`beta_211a_moonglade_return`, installed by E060), so
logouts and restarts keep the spot. Checked offline by
`scripts/test-druid-moonglade`.

## Functions

### `Moonglade.onLogin(event, player)`
Login handler: a druid without the spell learns it; their remembered spot
is read once into `Moonglade.spots`. Other classes: nothing.

### `Moonglade.onCast(event, player, spell)`
The spell-cast handler (fires as a cast completes, before its effect).
For Teleport: Moonglade only:
- in Moonglade (zone 493) with a spot: books the return 1.5 seconds later;
  without one: a message, and the spell's own Nighthaven;
- in an instance, battleground or arena: forgets any spot;
- in the open world: remembers the spot, and books the arrival.

### `Moonglade.arrive(eventId, delay, repeats, player, tries)`
The booked arrival: once the druid is in Moonglade, moves them to a spot
from `Moonglade.drawArrival`; not there yet, looks again (3 tries); no spot
drawn, leaves them in Nighthaven and logs it.

### `Moonglade.drawArrival(map) -> x, y, z, o, or nil`
A random spot on the glade's open ground, by the rules in
`Moonglade.GLADE` (up to 40 draws).

### `Moonglade.goBack(player, spot)`
Sends the druid to `spot` and forgets it.

### `Moonglade.remember(guidLow, spot)`
Keeps a spot, `{ map, x, y, z, o }`, or forgets it (`nil`), in memory and
in the database.

## Data

- `Moonglade.GLADE`: the arrival rules. `x_min, x_max, y_min, y_max`
  (numbers, the valley floor's box, yards), `land_z` (Nighthaven's ground,
  512.1), `HEIGHT_BAND` (40: how far a spot's ground may be from it),
  `STEEP` (3: the most the ground may rise over 3 yards), `DRAWS` (40),
  `AREAS` (set of area numbers: 493 Moonglade, 2361 Nighthaven, 2362 the
  Shrine of Remulos).
- `Moonglade.spots`: by character guid low part, `{ map = number, x, y,
  z, o = numbers }`, or `false` for none.
