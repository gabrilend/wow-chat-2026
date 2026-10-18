# 629 - Battleground Fronts: Bots Hold a Line and Fight for Ground

## Status
- Created: 2026-10-17
- Phase: 6
- Parent of: 629a, 629b, 629c, 629d
- Blocked by: 617i (buddies in battlegrounds), 617t (stand-ins)
- Related: 176a1 (Alterac Valley, always running, fought by stand-ins),
  176a2 and 176a2c (Arathi Basin: squads, and roads taken in turn at
  each crossing), 155z2 (front lanes at the Dark Portal), 619 (combat
  footwork: the pack retreat), 617s5 (sidesteps in a fight), 617o (the
  navigation mesh)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-17:

> also can you make buddy-bot behavior that's for bots in battlegrounds?
> They should try and spread out, and always fight for territory to the
> north. Or rather, on the (right angle to equator) axis displaced by
> orientation. So for example in Alterac Valley, the Alliance would push
> south, while the Horde pushes north. And the buddy-bots create a line
> shaped like a "bar chart" type thing, where when an NPC was spawned it
> took a skeleton path system road toward the front and when it was
> within a certain distance (maybe 3-6 steps until facing the foe) they'd
> pick the one with the fewest allies in it. When ranged units were
> struck, they'd put a melee character between themselves and their foe,
> close enough that they can still use ranged attacks on them... but
> ideally with enough distance to defeat their foe. anyway if there's a
> differential of like, 3 in one bar-chart section to another, then 2
> allies will come to assist with greater need having lesser priority.
> This will create moments where units are encircled, and they will
> fight to the last. Melee units don't run, they back up and recede when
> need is [great/grand]. but only backsteps, meaning they go slow.
>
> some places aren't north/south like Arathi Basin isn't I think for
> example so for that one we should make a determinant axis for each
> "border" between one or more objective. This can provide a more
> granular battlefield terrain, for example in Alterac Valley the various
> towers and graveyards are objectives to fight over. So combat tends to
> prioritize that. But the stand-ins have to fight for every inch of
> ground, so we don't get surround. Sometimes some break through, but
> they need to heal and recover so they are often contested. But they
> won't be chased too far, the frontline is more important.
>
> at each road Y intersection, the NPC takes a direction. They choose
> through a shuffled random pick, meaning, deck of cards shuffled without
> replacement. In this way, we don't have to do random number
> calculations, we can just flip a switch back and forth everytime they
> use it for each NPC. And we can save them up and batch them for calls
> to the database if we want, if we think that'll make it easier to send
> them along.

## Current Behavior

Not built. In a battleground, buddies (617i) and stand-ins (planned,
617t) are played by the bot module's battleground tactics: each bot picks
its own objective by the module's priorities and walks the module's road
paths to it, alone. Nothing keeps a line; bots bunch on whatever the
module chose. Arathi Basin's planned squads (176a2b) take roads in turn
at each crossing (176a2c, built on paper: one pointer per side, per
crossing, per road arrived by), and walk in formation (176a2d), but hold
no front.

## Intended Behavior

**The front.** Each side pushes along an axis: on a battleground laid
out north and south, that axis is north-south turned by the
battleground's own heading. In Alterac Valley the Alliance pushes south
and the Horde north. Where the ground isn't one line (Arathi Basin, and
the towers and graveyards inside Alterac Valley), each border between
neighbouring objectives has its own axis, so the battlefield is many
small fronts, and the fighting gathers at objectives (629a).

**Getting there.** A bot that appears takes the roads toward the front.
At each fork it takes the branch its own deck deals: the branches
shuffled once and dealt without replacement, reshuffled when used up;
with two branches, a switch flipped each time it passes (629b).

**The line, as a bar chart.** Each front is cut into sections side by
side along it, and each section holds a count of allies, like the bars
of a chart. A bot a few steps from facing the foe (3 to 6) picks the
section with the fewest allies. Where one section holds 3 more than
another, 2 allies move over to help. The line spreads itself out; a
thin section can still be encircled, and those in it fight to the last
(629c).

**Every inch of ground.** No section is left open, so the line isn't
walked round. Some break through; they must stop to heal and recover,
so the ground behind the line is contested too. They are not chased far:
holding the line matters more than finishing a runner (629c).

**How each one stands** (629d):
- A ranged bot that is struck puts a melee ally between itself and its
  foe, close enough to keep casting, far enough to win.
- Melee bots don't run. When the need is great they give ground only by
  stepping backwards, slowly, still facing the foe.

### Sub-issues

| ID | Name | Dependencies | Description |
|---|---|---|---|
| 629a | front-axes-and-borders | None | Each battleground's push axis, and an axis for each border between neighbouring objectives |
| 629b | road-forks-by-deck | None | Roads toward the front; at each fork, the bot's own shuffled deck (or switch) picks the branch; deals saved in batches |
| 629c | the-bar-chart-line | 629a, 629b | Sections along each front, the fewest-allies pick, the help-when-uneven rule, breakthroughs, no long chases |
| 629d | ranged-shelter-and-melee-backsteps | 629c | A struck ranged bot stands behind a melee ally; melee give ground only by slow backsteps |

Order: 629a and 629b (parallel foundations) → 629c (needs both) → 629d
(needs 629c's line).

## Suggested Implementation Steps

1. Answer the open questions.
2. Lay it out on paper first, as Arathi Basin's rules were: a Lua
   simulation of one front (two sides, sections, arrivals, the help
   rule) drawn to an animated image, played the same way twice from the
   same seed, before any server code (the project's pattern:
   `scripts/test-arathi-basin-rules`, `scripts/compare-arathi-basin-variants`).
3. 629a and 629b in the simulation, then in the buddy module.
4. 629c, then 629d.
5. In game: a running Alterac Valley (176a1) with stand-ins on both
   sides, the sections' counts logged each second, a screenshot series
   from above (617e7's zone view).

## Related Issues

- **617i**, **617t** (blocked by); **176a1**, **176a2**, **176a2c**,
  **155z2**, **619**, **617s5**, **617o**, **617e7**

## Open Questions

1. **Who follows the front?** "Buddy-bot behavior", then "the stand-ins
   have to fight for every inch": buddies and stand-ins both? What about
   real players' own random bots, if any are ever on?
2. **"Greater need having lesser priority."** When two sections are
   short of help, does the more desperate one get help *last*? Read
   literally that's what it says, and it would make the encirclements
   the owner describes (the worst-off section is left to fight to the
   last while the nearly-even ones are evened). Or did you mean the
   greater need goes first?
3. **"A skeleton path system road".** The bot module's hand-placed road
   paths (as in Arathi Basin, 176a2c), or a skeleton drawn from the
   walkable ground (the middle line of the navigation mesh's corridors),
   or roads a game master records (617e9's recorder)?
4. **Steps.** "3-6 steps until facing the foe": a step is about how many
   yards (a running stride is about 2)?
5. **How far is "too far" to chase** a breakthrough?
6. **Arathi Basin.** It already has its own planned rules (squads,
   formations, roads in turn per side). Does the front replace them, or
   do the squads walk to a border and then join its line?
