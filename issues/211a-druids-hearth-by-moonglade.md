# 211a - Druids Hearth by Moonglade

## Status
- Created: 2026-10-18
- Phase: 2 (The Empty World: getting around it together)
- Parent: 211 (group hearthstone): the druid's own way home, beside it;
  its invitation is 211's
- First profile: beta (`src/lua-beta/druid-moonglade.lua`)
- Related: 207/503 (travellers: druids meet no innkeepers, the reason
  this exists), 704 (low-level class identity)
- Priority: Medium
- State: in progress (built offline; not yet seen in game; open questions
  below)

## Origin

Writing out which travellers each class meets (`src/lua-beta/travel.info.md`,
2026-10-18) showed druids are the one class that never meets an
innkeeper, with no reason in the source. Asked whether that was meant, the
owner, verbatim:

> yess they're supposed to start with teleport moonglade, and that's their
> hearthstone. But casting it while in Moonglade will teleport them back to
> where they were before they teleported to moonglade.

And, the same day:

> also can we create more than one spawn position for the druid in
> moonglade? It should be essentially random.

Asked whether the group comes along, what a cast from an instance should
remember, and whether it needs a cooldown:

> yes. they can be visitors. but if the druid is no longer in moonglade,
> then they are teleported out as well, to the place they teleported in
> from.

> yes, the spot where they entered the dungeon or battleground or arena.

> I don't think a cooldown is necessary.

## Current Behavior

**Built on branch beta-homework (2026-10-18)** as described in Intended
Behavior. Checked offline by `scripts/test-druid-moonglade` (each guard
undone in a copy of the script makes it fail), which runs before every
build. Not yet seen in game, and the table's SQL (E060) has not yet run
against a database: `scripts/test-beta-sql-in-ram` covers beta's world
database only.

Before it: a druid learns Teleport: Moonglade (spell 18960) from a
trainer at level 10, and it always takes them to Nighthaven, wherever they
cast it, Moonglade included. Druids never meet innkeepers among the
travellers (`Travel.getTravelerTypeMask`), so on beta they could not move
their hearthstone's bind point from where they started.

## Intended Behavior

1. **Druids start with it.** Every druid on beta knows Teleport: Moonglade
   from level 1: it is taught at login to any druid who lacks it, so
   characters made before this change get it too. Their Hearthstone item
   is untouched. No cooldown is added (the stock spell has none: read from
   `Spell.dbc`; the owner: not necessary).
2. **Going: the spot is remembered.** Cast anywhere outside Moonglade, the
   spell goes to Nighthaven as always, and the druid's way back is
   remembered (map, position, facing), kept in the characters database so
   it survives logouts and server restarts:
   - from the open world: where they stood when the cast completed;
   - from a dungeon or raid: its entrance, looked up at the cast in
     `src/lua-beta/data/instance-entrances.lua`, which is generated from the
     game's own triggers (`scripts/generate-beta-instance-entrances`: each
     dungeon's way-out trigger, as `ObjectMgr::GetGoBackTrigger` uses it;
     with two, the one nearest the entrance portal; a way out into another
     dungeon followed to the open world). 67 dungeons and raids have one;
     the ones without are all above beta's level cap;
   - from a battleground or arena: where they joined it. The game keeps
     that spot for each player (`Player::SetEntryPoint`) and saves it with
     the character (`character_entry_point`, written by
     `Player::_SaveEntryPoint` at every save: logout and every
     `PlayerSaveInterval`, 15 minutes by default), which is how it sends
     back someone who logged out during a match. Right after joining, the
     row can still be a previous match's, so at the cast the script asks
     for a save (`player:SaveToDB()`) and reads the row once the spell has
     landed, 1.5 seconds later. No saved join spot: nothing is remembered,
     and the druid is told so. (First built as a source patch, B055,
     reading the game's in-memory copy; the owner asked why the saved one
     would not do, and it does: retired 2026-10-19 before any build,
     `patches/B055-ale-player-entry-point.retired.sh-retired`.)
   (A first version noted every player's position every 5 seconds to know
   where they entered; the owner: "every 5 seconds is an absurd amount of
   time. We need to hook it to the spellcast". It was replaced the same day
   by the table above, read only at the cast.)
3. **Coming back.** Cast inside Moonglade (zone 493) with a remembered
   spot, the druid is sent back to it once the spell's own move to
   Nighthaven is done, and the spot is forgotten. With nothing remembered
   (they walked in, or already went back), the spell behaves as stock, and
   the druid is told there is nowhere to return to.
4. **Arriving anywhere in the glade.** The spell itself always lands at
   one spot in Nighthaven (`spell_target_position`, 7991.9, -2679.8).
   Going out, the druid is then moved to a random spot on open ground in
   Moonglade: kept only if there is ground there, it lies in Moonglade's
   open land, Nighthaven or the Shrine of Remulos (areas 493, 2361, 2362
   of `AreaTable.dbc`; not Lake Elune'ara, 656, nor the Stormrage Barrow
   Dens, 2363, which are underground), its ground is within 40 yards of
   Nighthaven's height (the valley floor, not the mountains round it), and
   it is no steeper than 45 degrees. Up to 40 draws: with 1 in 5 kept, 40
   misses in a row is about 1 in 7000, before the lake's area is taken
   out. If no draw is kept, the druid stays where the spell put them, and
   the server log says so.
5. **Visitors.** Going out, the druid's group is invited as for a
   Hearthstone (211's window, as the cast begins; withdrawn if the cast is
   cancelled; bots always come); the dead are asked too. When the druid
   arrives, everyone who said yes is moved round the druid's spot, on
   211's circle by group number, and the dead among them are raised
   ("Nature's magic and all that"). The window says where: "<druid> is
   going to Moonglade. Visit with them?". Each visitor's way back is worked out
   at the cast by the same rule as the druid's; one whose way back is not
   known stays, and is told why.
6. **Visitors leave with the druid.** As soon as the druid is no longer in
   Moonglade (they cast their way back, take another way out, change map,
   or log out), every visitor still in Moonglade is sent back to their own
   way back. A visitor who leaves on their own stops being a visitor. A
   visitor who was offline when the druid left is sent back when they log
   in. A visitor who is dead when sent back is raised first, unless they
   came dead (raised on arrival, then died again in the glade): they go
   back as a ghost. Casting the way back from the glade invites no one: the visitors
   follow by this rule instead. Visitors are kept in the characters
   database, so a restart while they are in the glade still sends them
   back: a visitor logging in whose druid is not hosting them in the glade
   goes back, and a druid logging in outside the glade has left it.

## Suggested Implementation Steps

1. The table: `beta_211a_moonglade_return` in beta's characters database
   (character guid, map, x, y, z, facing), created by install step E060
   (`sql/beta/db_characters.src/01-moonglade-return.apply.sql`, with its
   revert), in the shape and naming of basic's death-knight-souls table
   (`basic_718_souls`, E041). Beside it, `beta_211a_moonglade_visitors`
   (visitor guid, druid guid, way back, and `left_glade`, set when the
   druid left while the visitor was offline). Checked in a throwaway
   database: applies twice, takes rows, reverts to nothing.
2. The entrances: `scripts/generate-beta-instance-entrances` writes
   `src/lua-beta/data/instance-entrances.lua` (dungeons and raids only, by
   `Map.dbc`'s map kind; battlegrounds have exit triggers too, one per
   faction in Alterac Valley, which is why they are left out).
3. 211's invitation, opened by another script: `GroupHearth.open(player,
   kind)` when the cast begins (`RegisterSpellEvent(18960, 1, ...)`),
   withdrawn on cancel (`RegisterSpellEvent(18960, 3, ...)`), and
   `GroupHearth.take(guid)` at completion for the members who said yes;
   the kind's `withDead` asks and takes the dead too. `GroupHearth` is made
   by hearthstone.lua only; this script uses it when a spell is cast.
4. The script `src/lua-beta/druid-moonglade.lua`:
   - at login: a druid without spell 18960 learns it; the druid's way back
     is read once; a visitor whose druid is not hosting them goes back; a
     druid with visitors who is not in the glade has left it;
   - on the spell-cast event (fires as the cast completes, before the
     teleport is carried out: `Spell::_cast`, `OnPlayerSpellCast`): for
     18960 outside zone 493, work out every way back, take the visitors,
     and book the move to a random spot in the glade 1.5 seconds later,
     after the spell's own move; inside zone 493 with a way back, book the
     return the same way, and forget it;
   - the arrival moves the druid, then the visitors round them, raising
     the dead (`ResurrectPlayer`), and keeps each visitor in the database;
   - the zone-change event (`PLAYER_EVENT_ON_UPDATE_ZONE`) and logout:
     a druid leaving zone 493 sends their visitors back (read from the
     database); a visitor leaving it stops being one;
   - the glade's draw box: x 7400 to 8300, y -2950 to -1850, the valley
     floor round Nighthaven and the Shrine, checked with the map's ground
     height and area at each draw, and a steepness rule (the ground 3
     yards away on each side within 3 yards of the spot's). Measured
     offline from the game's map files (`scripts/lib/map-heights.lua`,
     8000 draws, 2026-10-18): 1 draw in 5 passes height and steepness in
     that box; Moonglade's whole recorded bounds (`buddy_area_centres`:
     x 7066.7 to 8633.3, y -3200 to -1600) pass 1 in 10, a quarter of
     them outside the valley, which is why the box is the valley's;
   - keep guids, not player objects, across a delay (issue 210's lesson).
5. Tests, offline in the toy world (`scripts/lib/toy-world.lua`, with the
   characters-database calls, the per-spell events and the few player
   methods this needs): a new druid learns it, a druid who has it is not
   taught again, other classes are not; out and back; back with nothing
   remembered; a cast from a dungeon remembers its entrance, one from a
   battleground nothing; the spot survives a logout and a restart; the
   arrivals spread over the glade and never in the lake, on a mountain or
   a cliff; visitors invited, placed round the druid, sent back when the
   druid leaves, when the druid logs out, and at their own login; a
   visitor leaving on their own; a cancelled cast moves no visitor; the
   dead asked, brought and raised; a restart with visitors in the glade,
   in each order of logging in; another spell does nothing.
6. In game: a level-1 druid on beta casts it in a starting zone, then in
   Moonglade, and lands where they cast it; then with a second player in
   the group.

## Open Questions

None open. Answered 2026-10-18:

1. **The invitation: 211's window, during the cast, naming the place.**
   Asked whether it should be the game's summon window instead, the owner
   first said "it should just be like a dungeon or warlock summon", then,
   shown how 211's window works: "oh no I like this idea better - while
   the druid is casting the teleport spell (10 seconds right?) have the
   'come along?' message display, as with the hearthstones. But let's make
   it say where the person is hearthing to, like 'moonglade' or 'eversong
   woods' or similar. For both." So the window stays, shown while the
   10-second cast runs (`SpellCastTimes.dbc` index 7, read 2026-10-18),
   and says where: "Moonglade" for the druid; for a Hearthstone or Astral
   Recall, the zone of the bind point (`character_homebind.zoneId`, which
   the game writes when a player binds, named by `GetAreaName`).
   (Found while looking: the game's summon cannot be accepted by a ghost
   or in combat, `WorldSession::HandleSummonResponseOpcode`, and the bots
   have no code that answers one.)
2. **A way back from a battleground or arena:** "sure. Make it a patch,
   remember!", then, the next day: "I'm curious why we need a
   source-patch for that. How does the game know where to put players
   when they log out during a battleground? ... Why don't we just use that
   location instead?" The saved join spot (`character_entry_point`) serves,
   after a save asked for at the cast; the patch was retired unbuilt.
3. **A visitor who dies in the glade:** "yes we can resurrect them, unless
   they were a ghost when they came, then we leave them as a ghost if they
   died in moonglade." Raised before being sent back, unless they arrived
   dead (and were raised on arrival): then they go back as they are. The
   visitors' table keeps `came_dead` for this.
