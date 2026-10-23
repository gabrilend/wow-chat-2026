# 155y - No World Map, No Minimap

## Status
- Created: 2026-10-04
- Phase: 1
- Parent: 155 (basic profile)
- Priority: Medium
- Related: 710 (records the project-wide decision not to use AIO, the
  server-to-client addon framework), 617b (Sargobras; asked about in the
  same breath)

## Origin

Verbatim, 2026-10-04:

> and can we also disable the map and minimap?

Asked addon or client patch file, 2026-10-04:

> an addon and no script that copies it to the client. We will offer it on
> our website and say it's the intended way to play unless you're at a
> planning table or a map, like outside the Dark Portal or in the throne
> rooms.

## Current Behavior

Built 2026-10-04, not yet tried in the client. The addon is
`src/client-addons/EverlandNoMap/` (a table-of-contents file and one Lua
file); nothing installs it: it is offered on the website. Without it,
players have the stock world map (M key, the quest log's map button, the
zone map on shift-M) and the minimap.

## Intended Behavior

On basic, the intended way to play is without a map: the player finds the
way by the land, the sky and what people say. The addon is how; the
website says so. Nothing forces it.

**Why an addon.** Both maps are drawn by the game client from its own
files. The server sends positions of things, not pictures, and there is no
server message that turns a map off. The project has no other
client-side part (710: AIO is not used); this addon is the first, and is
plain (no server-to-client framework).

**What it does:**

- the minimap, and everything clustered round it (zone name, clock, mail
  and tracking buttons), is hidden, always, even where a map is kept
  (owner, 2026-10-04: "nah no minimap ever");
- the world map and the zone map close the moment anything opens them,
  unless the player stands where a map is kept: outside the Dark Portal
  (and its other side), and in each capital's throne room. The first
  refusal in a place says why ("there is no map here. Maps are kept at
  planning tables: ..."); a map open when the player walks out of such a
  place closes;
- `/nomap where` prints the zone and sub-zone the player stands in and
  whether a map is kept there.

**Where a map is kept** is a list in the addon: zone name to sub-zone names
as the client shows them (the text that sat above the minimap). The
client knows zone and sub-zone, not what objects stand nearby, so "a
planning table" is expressed as the sub-zone it stands in.

## Suggested Implementation Steps

1. (Done) The addon: minimap hidden; world map and zone map closed on show
   outside the listed places; closed on leaving; `/nomap where`.
2. In the client: walk to each listed place with `/nomap where`, correct
   the sub-zone names that differ, and check M, shift-M and the quest
   log's map button open nothing elsewhere; the minimap stays hidden after
   `/reload` and after zoning.
3. The website text offering it as the intended way to play.

## Open Questions

1. Several throne-room sub-zone names in the list are unconfirmed (Ironforge
   "The High Seat", Darnassus "The Temple of the Moon", Thunder Bluff "The
   High Rise", Undercity "The Royal Quarter", Silvermoon "Sunfury Spire",
   Exodar "The Vault of Lights"); which are right, and which other planning
   tables or maps should be on it?
2. Does this apply to basic only, or to other profiles too?
3. Dungeons and raids: no map there either?

Answered 2026-10-04 ("nah no minimap ever"): the minimap never comes
back, not at map places either, and nothing clustered round it stays.
- (Answered 2026-10-23) **Dungeons and raids lose their maps too:** asked
  whether dungeons and raids should keep a map ("a dungeon map is the most
  "solved" way to play, and dungeons are where getting lost is part of the
  fun"): "yes".
