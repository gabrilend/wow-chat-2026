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
   - from a dungeon, raid, battleground or arena: where they entered it,
     the last open-world spot noted before they changed to that map
     (every player's open-world position is noted every 5 seconds; the
     game keeps an entry point only for battlegrounds and the dungeon
     finder, and the Lua engine cannot read it). With no note (they logged
     in inside it after a restart), nothing is remembered and they are
     told so.
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
   cancelled; bots always come). When the druid arrives, everyone who said
   yes is moved round the druid's spot, on 211's circle by group number.
   Each visitor's way back is remembered, by the same rule as the druid's
   (where they stood, or where they entered their instance).
6. **Visitors leave with the druid.** As soon as the druid is no longer in
   Moonglade (they cast their way back, take another way out, change map,
   or log out), every visitor still in Moonglade is sent back to their own
   way back. A visitor who leaves on their own stops being a visitor. A
   visitor who was offline when the druid left is sent back when they log
   in. Casting the way back from the glade invites no one: the visitors
   follow by this rule instead.

## Suggested Implementation Steps

1. The table: `beta_211a_moonglade_return` in beta's characters database
   (character guid, map, x, y, z, facing), created by install step E060
   (`sql/beta/db_characters.src/01-moonglade-return.apply.sql`, with its
   revert), in the shape and naming of basic's death-knight-souls table
   (`basic_718_souls`, E041). Druids' spots only; visitors' are kept in
   memory (open question 1).
2. 211's invitation, opened by another script: `GroupHearth.open(player,
   kind)` when the cast begins (`RegisterSpellEvent(18960, 1, ...)`),
   withdrawn on cancel (`RegisterSpellEvent(18960, 3, ...)`), and
   `GroupHearth.take(guid)` at completion for the members who said yes.
   `GroupHearth` is made by whichever of the two files loads first
   (`GroupHearth = GroupHearth or {}`) and used only when a spell is cast.
3. The script `src/lua-beta/druid-moonglade.lua`:
   - at login: a druid without spell 18960 learns it; the druid's
     remembered spot is read once into a table by guid; every player's
     open-world note starts (rebooked every 5 seconds; while on another
     map it is left as it was);
   - on the spell-cast event (fires as the cast completes, before the
     teleport is carried out: `Spell::_cast`, `OnPlayerSpellCast`): for
     18960 outside zone 493, remember the way back, take the visitors with
     their ways back, and book the move to a random spot in the glade
     1.5 seconds later, after the spell's own move; inside zone 493 with a
     spot, book the return the same way, and forget the spot;
   - the arrival moves the druid, then the visitors round them;
   - the zone-change event (`PLAYER_EVENT_ON_UPDATE_ZONE`) and logout:
     a druid leaving zone 493 sends their visitors back; a visitor leaving
     it stops being one; login: a visitor whose druid is not in Moonglade
     is sent back;
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
4. Tests, offline in the toy world (`scripts/lib/toy-world.lua`, with the
   characters-database calls, the per-spell events and the few player
   methods this needs): a new druid learns it, a druid who has it is not
   taught again, other classes are not; out and back; back with nothing
   remembered; a cast from a dungeon remembers its entrance; no note
   after a restart; the spot survives a logout and a restart; the arrivals
   spread over the glade and never in the lake, on a mountain or a cliff;
   visitors invited, placed round the druid, sent back when the druid
   leaves, when the druid logs out, and at their own login; a visitor
   leaving on their own; a cancelled cast moves no visitor; another spell
   does nothing.
5. In game: a level-1 druid on beta casts it in a starting zone, then in
   Moonglade, and lands where they cast it; then with a second player in
   the group.

## Open Questions

1. **Visitors and a server restart.** Visitors' ways back are kept in
   memory only: a restart while they are in Moonglade leaves them there
   (they can still use their own Hearthstone). Keep them in the database
   too?
2. **A dead visitor.** A visitor who is dead when the druid leaves is sent
   back like the others (as a ghost, at their way back). Or should they be
   left to release and run as usual?
