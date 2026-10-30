# 618a - Routes Forward, and How the Ground Feels (rmaps)

## Status
- Created: 2026-10-29
- Phase: 6
- Parent: 618 (the world perception map)
- Blocked by: 618's pictures (the custom client's headless scene
  pictures, 173v and 176)
- Related: 617o8 (the painted map: walls learned by walking), 617e4c
  (questing roads), 629b (road forks), 617o (buddy pathfinding)
- Priority: Medium
- State: planned

## Origin

The owner, 2026-10-29:

> can we make a functionality that walks a bot through the world and then
> asks an image recognition program which routes forward exist? Maybe even
> classifying certain regions in certain terms like "dirty" or "snowy" or
> "solid" or "flat" or similar? Then, we can have different creatures
> walk along different things depending on how they like to feel. Um, okay
> for the pathfinding it'll help us build out a road network and such.

And on how the program is asked (2026-10-29):

> it's not an interactive thing. We'd walk a bot around in the world on
> totally random parts of the map, essentially trying to display a
> character in the world for sizing relationship, then say "which parts
> should I walk on?" and then say "walk on this part because it looks
> flat and solid" (and the "flat" and "solid" and "this part" are all tool
> calls btw) or "don't walk on this part because of the flowers" etc. And
> they store data about that particular pictured piece of the terrain and
> geometry, and then we'd build it into our mmaps. Maybe... rmaps, for
> ritz maps! like mmaps but with priority and labelling and route-finding
> details.
>
> depending on the character, they can move throughout the world
> differently depending on their characteristics and role.

## Current Behavior

Not built. 618 plans an explorer camera and labels (road, grass, shore,
cliff, building) mapped back to world points. Bots learn walls by walking
into them (617o8) but know nothing of what the ground looks or feels like.

## Intended Behavior

- **A walker that looks ahead.** A bot walks a route; every few yards the
  custom client draws what a player standing there would see, facing the
  way the bot walks and to either side. The picture goes to the image
  recognition program with one question: which ways forward are there
  (a road going on, a path bending left, an open slope, a bridge, a gap
  between rocks), and which are blocked. Each way forward it names is
  mapped back to the world (618's screen-to-world step) and becomes a
  candidate route for the painted map to try (617o8): seen first, then
  walked, then kept.
- **How the ground feels.** Regions are labelled in words a creature
  could care about: dirty, muddy, snowy, icy, sandy, grassy, rocky,
  solid, soft, flat, steep, wet, dark, open, cramped. A region can carry
  several. They are kept per cell beside the painted map's kinds.
- **Creatures walk by what they like.** Each kind of creature (and each
  buddy, by race or by temper) has likes and dislikes over those words: a
  wolf keeps to snow and forest, a kodo to flat open ground, a gnome to
  solid paths, an undead to dark places. Its route cost adds its dislikes
  and subtracts its likes, so different creatures take different routes
  through the same valley.
- **A road network.** Where many routes forward agree and the ground is
  "solid, flat, dirty" in a strip, it is a road. Roads are joined into a
  network per map (crossings, forks, ends at towns and flight masters),
  which the planner prefers (617e) and the questing roads use (617e4c).

**How the program is asked** (2026-10-29): not a conversation. The bot
is placed at random spots across a map, with a character standing in the
picture for scale, and the program is asked one thing: "which parts
should I walk on?" It answers only through tool calls: it marks a region
of the picture ("this part"), gives it words ("flat", "solid"), and says
walk on it or don't, with the reason ("because of the flowers"). Each
answer is stored against that piece of terrain and geometry: the region
mapped back to the world, its words, walk or don't, and why.

**rmaps** ("ritz maps", the owner's name): the server's movement maps
(mmaps, the navigation mesh the game's pathfinding uses) are where a
creature can stand. rmaps lay over them what a place is like and how
much to prefer it: the words, walk or don't, priorities and routes. A
character reads them by its own characteristics and role, so a tank, a
healer, a wolf and a gnome cross the same ground differently.

## Suggested Implementation Steps

1. The walker: a route, a camera every few yards, three pictures (ahead,
   left, right), and the question asked of the recognition program;
   answers kept with the camera's place and facing.
2. The words: a fixed list to begin with, one place in the code; the
   recognition program asked to label regions with them.
3. The labels into the perception map's cells (618), and a page that
   draws them over the zone map (617e14c) to be judged by eye.
4. Likes and dislikes per creature kind, as data, and the route cost
   reading them; a test that a wolf and a kodo cross the same valley by
   different ways.
5. Roads from agreeing routes, joined into a network, drawn on the page.

## Open Questions

1. Which image recognition program: one that answers questions about a
   picture (a vision language model, none installed yet), or one that
   paints labels on every pixel (a segmentation model), or both, the first
   for routes forward and the second for the ground's feel?
   **Answered 2026-10-29:** a model that looks at the picture and answers
   only through tool calls (mark this part, these words, walk or don't,
   why), run over random spots without anyone talking to it (above).
2. Should likes and dislikes be per kind of creature only, or should each
   buddy also have its own, so two buddies of one race walk differently?
