# 211a - Druids Hearth by Moonglade

## Status
- Created: 2026-10-18
- Phase: 2 (The Empty World: getting around it together)
- Parent: 211 (group hearthstone): the druid's own way home, beside it
- First profile: beta (`src/lua-beta/druid-moonglade.lua`)
- Related: 207/503 (travellers: druids meet no innkeepers, the reason
  this exists), 704 (low-level class identity)
- Priority: Medium
- State: in progress (built offline; open questions below)

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

## Current Behavior

**Built on branch beta-homework (2026-10-18)** as described in Intended
Behavior, with the open questions answered by default for now (each
marked in the script's header). Checked offline by
`scripts/test-druid-moonglade` (each guard undone in a copy of the script
makes it fail), which runs before every build. Not yet seen in game, and
the table's SQL (E060) has not yet run against a database:
`scripts/test-beta-sql-in-ram` covers beta's world database only.

Before it: a druid learns Teleport: Moonglade (spell 18960) from a
trainer at level 10, and it always takes them to Nighthaven, wherever they
cast it, Moonglade included. Druids never meet innkeepers among the
travellers (`Travel.getTravelerTypeMask`), so on beta they could not move
their hearthstone's bind point from where they started.

## Intended Behavior

1. **Druids start with it.** Every druid on beta knows Teleport: Moonglade
   from level 1: it is taught at login to any druid who lacks it, so
   characters made before this change get it too. Their Hearthstone item
   is untouched.
2. **Going: the spot is remembered.** Cast anywhere outside Moonglade, the
   spell goes to Nighthaven as always, and the place the druid stood when
   the cast completed (map, position, facing) is remembered, kept in the
   characters database so it survives logouts and server restarts.
3. **Coming back.** Cast inside Moonglade (zone 493) with a remembered
   spot, the druid is sent back to it once the spell's own move to
   Nighthaven is done, and the spot is forgotten. With nothing remembered
   (they walked in, or already went back), the spell behaves as stock, and
   the druid is told there is nowhere to return to.
4. **Arriving anywhere in the glade.** The spell itself always lands at
   one spot in Nighthaven (`spell_target_position`, 7991.9, -2679.8).
   Going out, the druid is then moved to a random spot on open ground in
   Moonglade: drawn anywhere in the valley, kept only if there is ground
   there, it lies in Moonglade's open land, Nighthaven or the Shrine of
   Remulos (areas 493, 2361, 2362 of `AreaTable.dbc`; not Lake Elune'ara,
   656, nor the Stormrage Barrow Dens, 2363, which are underground), and
   its ground is within 40 yards of Nighthaven's height (the valley floor,
   not the mountains round it). If no draw is kept, the
   druid stays where the spell put them, and the server log says so.
   (Up to 40 draws, each also turned away on ground steeper than 45
   degrees: with 1 in 5 kept, 40 misses in a row is about 1 in 7000,
   before the lake's area is taken out; the in-game check says how it
   goes with the areas.)
5. **Only open-world spots.** A cast from an instance, battleground or
   arena is not remembered (a return into one would land outside its
   rules); it forgets any earlier spot, so a later return never goes to a
   place older than the druid's last trip.

## Suggested Implementation Steps

1. The table: `beta_211a_moonglade_return` in beta's characters database
   (character guid, map, x, y, z, facing), created by install step E060
   (`sql/beta/db_characters.src/01-moonglade-return.apply.sql`, with its
   revert), in the shape and naming of basic's death-knight-souls table
   (`basic_718_souls`, E041).
2. The script `src/lua-beta/druid-moonglade.lua`:
   - at login: a druid without spell 18960 learns it; the druid's
     remembered spot is read once into a table by guid;
   - on the spell-cast event (fires as the cast completes, before the
     teleport is carried out: `Spell::_cast`, `OnPlayerSpellCast`): for
     18960 outside zone 493, remember the spot (or forget it, from an
     instance) and book the move to a random spot in the glade a second
     later, after the spell's own move; inside zone 493 with a spot, book
     the return the same way, and forget the spot;
   - the glade's draw box: x 7400 to 8300, y -2950 to -1850, the valley
     floor round Nighthaven and the Shrine, checked with the map's ground
     height and area at each draw, and a steepness rule (the ground 3
     yards away on each side within 3 yards of the spot's). Measured
     offline from the game's map files (`scripts/lib/map-heights.lua`,
     8000 draws, 2026-10-18): 1 draw in 5 passes height and steepness in
     that box; Moonglade's whole recorded bounds (`buddy_area_centres`:
     x 7066.7 to 8633.3, y -3200 to -1600) pass 1 in 10, a quarter of
     them outside the valley, which is why the box is the valley's;
   - keep guids, not player objects, across the delay (issue 210's lesson).
3. Tests, offline in the toy world (`scripts/lib/toy-world.lua`, with the
   characters-database calls and the few player methods this needs): a
   new druid learns it, a druid who has it is not taught again, other
   classes are not; out and back; back with nothing remembered; an
   instance forgets; the spot survives a logout and a "restart" (the
   in-memory table cleared, read back from the stand-in database); another
   spell does nothing.
4. In game: a level-1 druid on beta casts it in a starting zone, then in
   Moonglade, and lands where they cast it.

## Open Questions

1. **Does the group come along?** Teleport: Moonglade is the druid's
   hearthstone; should it send 211's invitation to the group like a
   Hearthstone or Astral Recall (out to Nighthaven, and back round the
   druid's remembered spot)? Built for now as the druid's alone.
2. **From an instance:** built to forget the earlier spot (so a return
   never goes somewhere older than the last trip). Or should an instance
   cast keep the earlier open-world spot?
3. **Its cooldown:** stock Teleport: Moonglade has no cooldown in 3.3.5
   beyond its 10-second cast; a Hearthstone has 30 minutes. Keep it free,
   or give it the hearthstone's?
