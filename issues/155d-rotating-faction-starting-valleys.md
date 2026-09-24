# 155d - Rotating Faction Starting Valleys

## Status
- Created: 2026-09-23
- Phase: 1
- Parent: 155
- Blocked by: 155a, 155e
- Priority: Medium

## Origin

Verbatim, 2026-09-23:

> we should have characters spawn at a random starting zone. Fully
> randomized. But, it's syncronized, so like the next 30 alliance characters
> spawn in northshire and the next 30 horde characters spawn in Mulgore, then
> after that the next 30 alliance characters spawn in teldrassil and the next
> 30 horde characters spawn in Eversong Woods, etc. Make sure to ensure that
> quests aren't gated by race anymore, only faction.

## Current Behavior

**Built 2026-09-23 (route 1); patched source type-checks, not yet compiled
or run.** Source patch B028 (`patches/B028-basic-starting-valley-rotation.sh`)
adds the rotation to the character-creation handler. It runs after the
character object is built, inside the same database transaction that first
saves it. Death knights are skipped. The block picks the faction's current
valley, moves the character there (switching its map when the valley is on
another continent), writes the hearthstone home point there, and appends
the rotation's new state to the same transaction. Rotation state lives in
`basic_starting_valley_rotation` in the characters database, created and
seeded by setup step E023. The server caches it after the first read, so
two creations in the same moment cannot read a stale count. A missing
table or row refuses the creation with a logged error naming E023.

Bots never enter the rotation, and no check is needed for that: the bot
module creates characters through its own factory, not through this
handler. That settles the "do bots count?" question in the direction the
issue proposed.

Tested so far: the patch applies and reverts byte-identically
(`scripts/test-source-patches basic`). A full compiler syntax-and-type check
of the patched file passes, using the build's own flags (a planted error
was caught, so the check is real). Untested until the owner's compile and
install: creating 31 characters (step 4 below), and
`scripts/validate-basic-state`'s rotation-table check.

One accepted imprecision: if the database transaction saving a character
fails after the rotation advanced in memory, the in-memory count is one
ahead of the database until the next restart.

Before this issue: where a new character appears is one row per race and class in the world
database's player-creation table. Stock values send each race to its own
level-1 valley. The server reads that table once at startup and keeps it in
memory, so rewriting the rows while the server runs changes nothing until the
next restart. Vanilla's starting-zone step (E007) rewrites those rows once,
to fixed level-20 towns; basic does not run it (155c).

## Intended Behavior

Each faction has four level-1 valleys:

| Alliance | Horde |
|---|---|
| Northshire Valley (Elwynn Forest) | Valley of Trials (Durotar) |
| Coldridge Valley (Dun Morogh) | Deathknell (Tirisfal Glades) |
| Shadowglen (Teldrassil) | Camp Narache (Mulgore) |
| Ammen Vale (Azuremyst Isle) | Sunstrider Isle (Eversong Woods) |

The upstream coordinates for all eight are already written out in the
revert half of vanilla's starting-zone step (`patches/E-patches.sh`, the E007
revert heredoc).

- A new character appears in its faction's **current valley**, whatever its
  race.
- Each faction's current valley changes after **30** new characters of that
  faction.
- The order is shuffled, and fair: a faction's four valleys are drawn from a
  bag without replacement. When the bag is empty it is refilled and
  reshuffled, and a valley cannot come up twice in a row across the
  boundary. Every valley hosts exactly one batch per cycle of four.
- The hearthstone home point is set to the valley the character actually
  arrived in, not to its race's stock valley.
- The rotation state (each faction's current valley, how many characters it
  has taken, the rest of the bag) survives server restarts. It lives in a
  small table in `acore_characters_basic`.
- A creation that cannot resolve a valley is an error with a message that
  says which faction, which bag state and which step failed. It never quietly
  falls back to the stock racial valley.

### Mechanism choice

The player-creation table is cached at startup, so the rotation cannot work
by rewriting that table. There are two workable routes:

1. **A source patch at character creation** (a B-patch), where the server
   chooses the spawn position and home point together. One place, no
   visible teleport, but it is C++.
2. **A Lua hook on first login** that teleports the character and rebinds the
   hearthstone. No C++, but the first login loads the stock valley and then
   teleports.

Route 1 is preferred. Find where the core copies the creation position into
the new character, and confirm that the home point is written from the same
values, before choosing.

## Suggested Implementation Steps

1. Read the core's character-creation path. Note where the spawn position
   and home point come from.
2. Write the rotation table (faction, current valley, count, remaining bag)
   and its SQL under `sql/basic/db_characters.src/`.
3. Implement the draw: count, advance on 30, refill and reshuffle with the
   no-repeat rule.
4. Test by creating 31 characters of one faction on a scratch account.
   Characters 1–30 land in one valley, character 31 in a different one, and
   every home point matches its landing valley.

## Related Issues

- **155** parent; **155e** blocks this (a character must be able to do the
  quests of the valley it lands in)
- **204** random spawn point — beta's fully random world spawn; a different
  mechanism for a different profile
- **148n** vanilla's racial starting zones — the fixed-assignment version
- **502** universal class trainers — see 155e on trainers per valley

## Open Questions

- (Answered 2026-09-23) Separate counters per faction, as built: "Alliance
  and Horde will never spawn in the same valley, so there's no reason to
  share a counter."
- (Settled) Bots do not count: they are created outside the handler B028
  patches. Death knights start in Acherus and are outside the rotation (718).
