# 1201 - Robot Search Party: a Left 4 Dead 2 Mod on Our Roaming Pattern

## Status
- Created: 2026-10-17
- Phase: 12 (Example products: the framework outside World of Warcraft)
- Parent of: 1201a, 1201b, 1201c, 1201d, 1201e
- Blocked by: nothing in this project; needs Left 4 Dead 2 and its
  Authoring Tools on the machine (open question 1)
- Related: `docs/roaming-pattern.md` (the pattern this carries), 617e
  (buddy area adventuring, where the pattern came from), 617o (the
  navigation mesh), 612b (routes precomputed on the mesh), 1202 (the
  other phase-12 example)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-17:

> hi can you make issue files to create a sample demo product that uses
> our pathfinding mechanics in a Left 4 Dead mod that replaces the
> zombies with humanoid robots?

## Why This Exists

The project is a framework with examples, adapted to what its users
need (owner, 2026-10-17). Every example so far lives inside World of
Warcraft. This one shows that the parts that are design rather than
game data travel: the Roaming Pattern (`docs/roaming-pattern.md`) is
written in no programming language on purpose ("Build the pattern,
build it twice", owner, 2026-09-28), already has a Lua and a
JavaScript implementation held to one check (`scripts/test-roam-pattern`),
and can take a third in another engine's language.

Left 4 Dead 2 is a good host because its pieces line up with ours:

| Ours | Left 4 Dead 2's |
|---|---|
| an area as a union of axis-aligned rectangles (the roaming pattern's data model) | the navigation mesh: rectangular areas, each with its corner heights |
| scripts that decide, an engine that walks (buddies) | VScript (Squirrel) decides; `CommandABot` sends any bot, common infected included, to a position, and its own AI is paused while commanded (Valve's script reference) |
| the toy world, where scripts are checked offline | the same scripts can run in a plain Squirrel interpreter, outside the game (1201a) |
| buddies' mesh pathfinding (617o): a flood of walking distance from a goal over joined cells (617o3), and steering that aims straight at a moving target when the line is clear and follows the route when not (617o4) | the navigation mesh's areas and their connections, which a script can walk; and robots that must close on survivors who move |

So the robots use two of our pieces: the **roaming pattern to search**
(cover ground, sector by sector, until someone is seen) and **617o's
distance maps and steering to close in** (from the last place a survivor
was seen, toward where they are now).

## Current Behavior

Nothing exists. The roaming pattern runs only in Lua (the server-side
buddy scripts and the GIF generator) and in JavaScript (the gallery's
playable scenes).

## Intended Behavior

A mod (an add-on packed as a `.vpk`, installed into Left 4 Dead 2's
add-ons folder or from the Workshop) in which the horde is replaced:

- **Humanoid robots instead of zombies.** Common infected look like
  robots, with models made by the project, not taken from anyone (1201c).
  The special infected are left as the game has them in the first
  version (open question 3).
- **A search party instead of a stampede.** Zombies rush. Robots
  search: the Director script divides the map's navigation mesh into the
  roaming pattern's areas (1201b) and sends robots to sweep them the way
  buddies explore a cave, painting ground as covered, taking sectors in
  turn, closing on the survivors once one of them is seen (1201d). The
  tension changes from "run" to "they are checking every room".
- **The same pattern, a third time.** The decisions are made by a
  Squirrel implementation of `docs/roaming-pattern.md`, checked against
  the Lua and JavaScript ones on the same seeded situations (1201a).

### Sub-issues

| ID | Name | Dependencies | Description |
|----|------|--------------|-------------|
| 1201a | roam-pattern-in-squirrel | None | The roaming pattern's third implementation, in Squirrel, held to `scripts/test-roam-pattern` |
| 1201b | nav-mesh-to-roam-areas | None | Read a map's navigation mesh into the pattern's area model; the same areas exported to a file for offline checks |
| 1201c | robot-common-infected | None | Humanoid robot models for the common infected, made by the project's own asset pipeline |
| 1201d | the-search-party-director | 1201a, 1201b, 1201c, 1201e | The Director script that commands robots by the pattern; the playable demo |
| 1201e | closing-in-by-distance-map | 1201b | 617o3's distance maps and 617o4's steering over the game's navigation areas, for robots that have seen a survivor |

Execution order: `1201a ‖ 1201b ‖ 1201c`, then `1201b → 1201e`, then
`1201d`. The first four can be built and checked apart; 1201d puts them
in a map.

## Suggested Implementation Steps

1. Answer the open questions (below).
2. 1201a, 1201b and 1201c in any order; each is checkable on its own.
3. 1201d on one official campaign map first, then a second map to show
   nothing is tuned to one layout.
4. A demo receipt: a scripted run (bots only, no player) writes the
   house goodbye receipt (`output/goodbye`: seed, robots commanded,
   areas swept, minutes run) and a screenshot per minute into
   `tmp/shared-memory/`, filed in `development-history/`.

## Related Issues

- `docs/roaming-pattern.md` and `scripts/test-roam-pattern`: the pattern
  and its check
- 617e and its sub-issues: buddy area adventuring, where the pattern was
  designed
- 617o: the navigation mesh in this project
- 1202: the other example product of phase 12

## Open Questions

1. **Which game, and is it on this machine?** Left 4 Dead 2 (the first
   game has no scripting at all). Is it installed, with its Authoring
   Tools (Hammer, the model compiler), on Linux or through Proton?
2. **Which of our pathfinding pieces should the robots show?** This plan
   uses the roaming pattern to search and 617o's distance maps and
   steering to close in. The others are the routes precomputed on the
   mesh (612b) and the exploring rules raced in
   `docs/HTML/exploration-compare.html`. Add one of those, or swap one in?
3. **Special infected.** Robots for the common infected only in the
   first version, or robot versions of the special infected too (they
   have their own abilities, which the pattern does not decide)?
4. **Survivors.** Keep the four stock survivors, or replace them too?
5. **Release.** A Workshop item others can install, or a demo kept to
   this project? A Workshop item carries Valve's subscriber agreement
   and needs every asset in it to be the project's own (1201c).
