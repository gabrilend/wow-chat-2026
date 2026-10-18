# travel.lua

Travellers who wander by on beta: vendors, innkeepers and the player's
class trainers, of the player's level (issues 503, 504, 505). Each real
player gets one a minute after login and then every 130 seconds, unless
dead, swimming or sitting. Checked offline by `scripts/test-travel`.

## Functions

### `Travel.onLogin(event, player)`
Login handler: makes the player's traveller lists; real players (not
bots) also get the clock.

### `Travel.tick(eventId, delay, repeats, player)`
One tick: winds the clock, checks `Travel.HOLDS`, sends one traveller.

### `Travel.spawnAndTravel(player)`
Draws a traveller from the player's lists, places it 30-45 yards away,
and sets it walking past the player. No ground there: none this time.

### `Travel.continueTravelling(eventId, delay, repeats, creature)`
The traveller's walk, every 2-4 seconds: sits while the nearest player
sits, leaves when no player is within 200 yards or the ground fails.

### `Travel.setupPlayer(event, player)`, `Travel.updatePlayerTravellers(playerGuid)`
Make (and remake, when the lists run out) the player's lists from the
categories below, by class, faction and current level; trainers: one of
the player's class whose slice holds the level.

### `Travel.getTravelerTypeMask(class) -> number`
Which traveller categories a class meets, as bits that add up: each
category's `typeMask` is one bit (1, 2, 4 … 512), and a category is drawn
from when its bit is in the class's number (Ammo 1, Innkeepers 2,
Trainers 4, Consumables 8, Poisons 16, Others 32, Melee 64, Ranged 128,
Armor 256, Food 512). Every class meets trainers, consumables, others,
melee and armour. Only hunters meet ammunition sellers and only rogues
poison sellers; ranged sellers come to warriors, hunters and rogues;
mages meet no food sellers (they conjure their own), and druids no
innkeepers (their way home is Teleport: Moonglade instead, issue 211a,
`druid-moonglade.lua`).

### `Travel.getRandomTravellerId(playerGuid, count) -> creature entry (number), 0 if none`
### `Travel.isTrainer(entry) -> boolean`, `Travel.getTrainerForClass(class, level, faction) -> entry or nil`
### `Travel.despawn(creature)`, `Travel.isValidFaction(a, b) -> boolean`
### `Travel.handleChat(event, player, message)`
Typing `#travel` sends a traveller at once (a test command; anyone can).

## Data

- `Travel.travellers`: by category name, `{ name, list, typeMask }`; each
  list row `{ id = creature entry, minLevel, maxLevel, rel }` (rel: 1 horde,
  2 alliance, 3 both). Trainers come from `data/travel-trainers.lua`.
- `Travel.HOLDS`: `{ why, holds = function(player) }`: dead, in water,
  sitting.
- Per player (`"travellers"`): `{ travellers = list of entries, typeMask,
  playerFaction (1 or 2), playerLevel, playerClass }`.
- Per traveller: `"theta"` (the heading it keeps to, radians).
- Settings: the `TRAVEL_*` globals at the top of the file.
