# 617e16l - Battlegrounds, Two Sides, on the Page

## Status
- Created: 2026-10-29
- Phase: 6
- Parent: 617e16 (the fish-school sandbox)
- Related: 176a2 (the Arathi Basin match) and its parts: 176a2a (the
  match), 176a2b (squads, departures, coming back, guarding), 176a2c (the
  roads taken in turn), 176a2d (formations), 176a2e (base bonuses); 629
  (battleground fronts); 617e16c (the ground: heights, steep ground,
  doodads); 617o7 (the five ways to find a path)
- Priority: High
- State: in progress

## Origin

The owner, 2026-10-29, asked where the battleground scenes stand and what
pathfinding they have (the designs are tested Lua, nothing runs in game,
and squads walk the bot module's roads by the turn rule):

> Okay let's do all of those things. A squad should path find as we
> designed in the PvP settings. Can we get a section to the HTML
> visualizer that shows the BGs with two sides? They should play the same
> way the bots would - running around and circle orbiting their foes at
> their preferred range. Also moving away from groups of enemies and
> toward groups of allies, when presented with the option. And sometimes
> when successful breaking off to do the objective - no enemies to fight
> means you won the battle, so go and claim your prize.

## Current Behavior

**First version built 2026-10-29** (picture 064):
`docs/HTML/battleground-sandbox.html`, made by
`scripts/generate-battleground-sandbox-page` from its template
(`scripts/templates/battleground-sandbox.html`), the shared height decoder
and the roads data; linked from the ground sandbox's panel and back.
Arathi Basin's ground (`docs/HTML/battleground-sandbox/zone-529-3358.js`)
comes from `scripts/generate-zone-maps --map 529` and
`scripts/generate-ground-sandbox-data --zone 529-3358 --out ...` (that
tool's files now name their real folder in their first line).

What the page plays:
- the homes drawn each match;
- squads of the designed shape leaving home every 12 seconds, with a tank
  per base taken;
- the dead back on the 30-second wave, at a held base or home;
- the roads taken in turn at each place;
- an orbit of the foe at the role's range, turning away from bunched foes
  and leaning toward allies;
- healing, and breaking off at the slider's share while two to one up;
- squads moving only while none of them fights;
- the 60-second assault, a guard left behind;
- resources by the stock table, a win at 1,600, the next match a minute
  later.

Moving is refused by the ground: steep ground and doodads, with the
nearest open heading within 90 degrees taken instead.

Not built yet: the squads' shapes beyond a lead and pairs behind it (the
diamond, 176a2d), the base bonuses (176a2e), and fronts (629). The
bots are small at the whole field's zoom.

Before this: the battleground rules existed only as plain Lua with tests
(`src/lua-cc-test/lib/arathi-basin-*.lua`, `src/lua-basic/lib/battleground-front.lua`).

## Intended Behavior

A page beside the ground sandbox, in its style and linked both ways:
**Arathi Basin on its own ground**, two sides playing a match as the bots
would.

- **The ground**: Arathi Basin's heights, steep ground and doodads, from
  the same files and in the same form as the sandbox's zones (617e16c);
  the seven places (two homes, five bases) and the bot module's 15 roads
  between them (`src/lua-cc-test/data/arathi-basin-roads.lua`).
- **Two sides**, each at a home drawn at random (176a2a), squads as
  designed (176a2b): trios of two damage and a healer leaving home every
  12 seconds, a tank waiting at home for each base taken and leaving with
  the next squad; the dead coming back on the next 30-second graveyard
  wave, at a base their side holds or at home.
- **Squads find their path as designed** (the owner: "A squad should
  path find as we designed in the PvP settings"): along the roads; at
  each place, every road but the one the squad came by, taken in turn
  (one pointer per side, per place, per road arrived by, 176a2c), walked
  in formation (176a2d). The five ways (617o7) are not used to choose a
  squad's way.
- **Fighting as the bots would** (the owner's words):
  - "running around and circle orbiting their foes at their preferred
    range": a bot that meets an enemy within notice range orbits its foe
    at its role's range (melee close, ranged and healers far), each bot
    turning its own way round;
  - "moving away from groups of enemies and toward groups of allies,
    when presented with the option": while orbiting, a bot leans away
    from where enemies are bunched and toward where its allies are;
  - "sometimes when successful breaking off to do the objective - no
    enemies to fight means you won the battle, so go and claim your
    prize": with no enemy within notice range the fight is won and the
    squad goes back to its road and the base ahead; while its side
    clearly outnumbers the enemies near, a bot now and then breaks off
    to the objective early.
  - Healers heal the most hurt ally in range; each role's damage and
    health from a small table on the page.
- **The objective**: a bot at a base that isn't its side's, with no enemy
  near the banner, assaults it; 60 seconds uncontested and it is taken.
  One of the squad stays to guard; a bot reaching a base its side holds
  guards too (176a2b). Resources by bases held (`BattlegroundAB`'s table),
  the first side to 1,600 wins, and the next match starts a minute later.
- **Measures** on the panel, as the sandbox's: resources, bases held,
  kills and deaths each side, fights going on, bots orbiting, breaking off,
  guarding; a slider for each number above that is a guess.
- Run with the sandbox's address settings (`sim=` seconds run at once,
  then drawn), so pictures can be filed by the tool.

## Suggested Implementation Steps

1. Arathi Basin's ground for the page: the zone data for map 529
   (`scripts/generate-zone-maps --map 529`), then its heights and doodads
   (`scripts/generate-ground-sandbox-data --zone 529-<zone>`).
2. A generator for the page (`scripts/generate-battleground-sandbox-page`,
   LuaJIT): the places and roads as data, written into the page beside
   its template (`scripts/templates/battleground-sandbox.html`); the
   simulation and drawing kept in the template, the data in the
   generator (the owner's rule: data making apart from data viewing).
3. The match, the squads, the roads in turn, the fighting, the objective.
4. Pictures through `scripts/file-screenshot`, every version committed
   with its picture.

## Open Questions

1. **Numbers that are guesses**: notice range 40 yards; preferred ranges
   melee 3, ranged 25, healer 28; breaking off early at 5% a second per
   bot while its side outnumbers the enemies near two to one; the
   damage, healing and health table. Sliders on the page; which feel right?
2. **Mid-road crossings**: the owner's crossings table (176a2c question 6)
   is not settled, so the page takes the roads as the bot module has
   them (place to place). Settle it, and the page takes the forks too.
