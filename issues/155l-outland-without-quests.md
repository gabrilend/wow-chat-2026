# 155l - Outland Without Quests

## Status
- Created: 2026-09-24
- Phase: 1
- Parent: 155
- Blocked by: 155a, 155c
- Related: 155k (Outland gear), 155f (attunement quests), E008 (flight
  paths removed)
- Priority: Medium

## Origin

Verbatim, 2026-09-24:

> Quest rewards, well, we should remove all quests in Outland. Not
> questgivers, but quests. Players make their own missions and rewards,
> they've graduated from quests. But, let's make sure that the players can
> have the first flight path to Thrallmar and Honor Hold, otherwise they'll
> be stuck by the dark portal since right by the dark portal it's mostly
> elites. Otherwise, all flight paths in the game should be disabled unless
> they're required for accessing a place - are there any places like that?
> Moonglade maybe?

Later the same day, verbatim:

> I think MGT is the only one that will give us problems. [...] How about
> we identify the closest Alliance flight-path to the Isle of Quel Danas,
> and force them to fly to it with that flight path. Then, we pick a Horde
> flight path with a similar duration and make them fly too so that
> Silvermoon City doesn't have a quick flight.

> The Dark Portal flights also go back. We don't need to remove the quest
> items, because they are unobtainable if the quests cannot be claimed.

Later still, verbatim: "I still want to force players to fly there because
I'm evil >:)" / "excellent. That is the only flight path to them then. I
love how it's in the highest level zone on Azeroth, too." Shattrath
portal: "remove". The Isle's dailies: "removed. They all require level 70
anyway."

## Current Behavior

- **Quests**: stock. About 1,200 quests are filed under Outland's zones
  (by the quest's zone field: Hellfire Peninsula 243, Shadowmoon Valley
  199, Netherstorm 163, Blade's Edge 158, Terokkar Forest 139, Nagrand 138,
  Zangarmarsh 97, Shattrath 63), plus quests filed under the dungeons.
- **Flight paths**: basic already runs E008, vanilla's flight-path removal:
  every flight master in the game loses its flight-master flag and gets a
  flavor line instead, Outland's included. So on basic today nobody can
  fly by taxi anywhere, including from the Dark Portal.
- The Dark Portal's flight masters stand on the Stair of Destiny: Amish
  Wildhammer (Alliance) and Vlagga Freyfeather (Horde). Honor Hold's is
  Flightmaster Krill Bitterhue, Thrallmar's is Barley.
- **Flying mounts**: Expert Riding (flying) is trainable at 60 on this
  client (stock, 250 gold), and basic's riding patch leaves it alone.

## Intended Behavior

- **No quests in Outland.** Every quest filed under an Outland zone,
  Shattrath, or an Outland dungeon is removed from its givers (the givers
  stay, as characters in the world). The blood-elf and draenei starting
  zones share Outland's map but are not Outland; their quests stay.
- **One flight out of the Dark Portal**: the Stair of Destiny flight master
  of each faction offers one flight, to Honor Hold (Alliance) or Thrallmar
  (Horde), without the player having to discover the destination first.
  No other taxi route is opened.
- The Dark Portal flights **also run back** (Honor Hold / Thrallmar →
  Dark Portal).
- **Isle of Quel'Danas by air, same length for both factions**: the
  closest Alliance flight master to the Isle is at Light's Hope Chapel
  (13,772 yards, a direct route). The Horde flight master at the same
  chapel is 14,007 yards away along the network, nearly the same, so both
  factions fly from Light's Hope Chapel and back. Silvermoon, Zul'Aman and
  Tranquillien get no flight to the Isle. **This is the only way to the
  Isle**: the Shattrath portal (gameobject 187056) is removed.
- **The Isle's quests are removed too**, with Outland's (all level 70).
- **Every other flight path stays disabled** (E008), unless a place can't
  be reached any other way.
- Quest items stay (unobtainable without their quests).

**Places that might need a flight**, checked from what is known so far:

- **Moonglade**: reachable on foot through the Timbermaw Hold tunnel from
  Felwood or Winterspring. It still has to be checked whether the furbolgs
  let a new character pass.
- **Tempest Keep's three dungeons, Skettis, Ogri'la, Netherwing Ledge**:
  floating or cliff-top, reachable only by air. On basic that means a
  flying mount at 60.
- **Isle of Quel'Danas (Magisters' Terrace)**: the Shattrath portal
  (gameobject 187056) has no condition rows, no script and no level fields
  on its spell in this database, so it looks open to a level 60 (not yet
  tried in game). The flight network (read from the client's
  TaxiNodes/TaxiPath/TaxiPathNode files, lengths summed along the
  waypoints) links the Isle's Shattered Sun Staging Area to: Silvermoon
  City 5,523 yards, Zul'Aman 7,526, Tranquillien (via Silvermoon) 7,726,
  **Light's Hope Chapel, Alliance side 13,772** (direct), **Light's Hope
  Chapel, Horde side 14,007**, Ironforge 20,222.

## Suggested Implementation Steps

1. A generator lists the quests to remove (Outland zone and dungeon sort
   ids) and writes an apply/revert SQL that saves and deletes their
   quest-giver and quest-ender links.
2. A gossip option on the two Stair of Destiny flight masters starts the
   fixed flight path to Honor Hold or Thrallmar directly (server-side
   taxi start from a script), leaving E008 in place for everyone else.
3. Check the Moonglade and Isle of Quel'Danas routes in game with a fresh
   level-60 character; open a flight or portal only where one is missing.
4. Test: no Outland quest giver offers a quest; the two flights work.

## Related Issues

- **155** parent; **155k** Outland gear (quest rewards no longer a source)
- **155f** the Old Hillsbrad and Black Morass attunement quests are removed
  here too
- **148i** / E008 flight-path removal (vanilla, shared with basic)

## Open Questions

- Other ways onto the Isle to close (Ritz: "Um. Not sure."): to be found
  when building by listing every teleport whose destination is on the
  Isle (spell target positions, area triggers, gameobject portals) and
  closing each one except the Light's Hope flights.
- (Answered 2026-09-24) Shattrath portal removed; the Light's Hope flight
  is the only way. The Isle's quests removed.
- (Answered 2026-09-24) Dark Portal flights run back. Quest items stay.
