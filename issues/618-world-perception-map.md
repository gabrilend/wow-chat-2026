# 618 - The World Perception Map

## Status
- Created: 2026-10-07
- Phase: 6
- Blocked by: 173v (the custom client in its own project, the W client),
  and through it the client's headless scene pictures (176, 173v)
- Related: 617e (buddy area adventuring: the path planner's road
  preference waits on this), 617 (buddy bots), 176 (cc-test: test scenes)
- Priority: Medium (large; nothing can start until the client is merged)

## Origin

The owner, 2026-10-07, asked whether buddies could find roads from the
ground textures' names in the client's terrain files:

> the problem is that sometimes those textures are used elsewhere.
> Sometimes they're used in large squares, and not as roads. Sometimes a
> different texture is used. It's not a sustainable solution. I think
> instead we'll need to create an "exploring" system that uses image
> recognition to build up a database of perceptions of what's in the
> world, using screen-space-to-worldspace coordinate conversions to build
> out a semantic structure representing the world as the players (and
> ideally, bots) should see it. That's a massive issue though that
> requires the custom client, so... block it on that? And maybe write an
> issue file for it?

## Current Behavior

Nothing exists. What the server knows of the world is geometry: heights,
areas, water, holes, collision shapes. It does not know what a place
*looks like* (a road, a field, a shoreline, a camp). The buddies' path
planner (617e) prefers road, but it has no road data. The road in its
animations is drawn by hand. Classifying the client's ground textures by
name was rejected: the same texture paints roads in one place and whole
squares of plain ground in another, and roads are painted with many
different textures.

## Intended Behavior

A database of what the world looks like, built by looking at it the way a
player does:

- **An explorer** walks or flies the custom client's camera through the
  world with no window open (the headless pictures, 173v and 176), taking
  pictures from many spots and directions.
- **Image recognition** labels each picture's pixels or regions: road,
  grass, water's edge, cliff, building, camp, bridge, and so on.
- **Screen space to world space.** The client knows the camera and the
  depth of every pixel it drew. So each labelled pixel maps back to the
  point in the world it shows: x, y, z, and the map it is on.
- **The perception map** collects these labels per world point, many
  views agreeing or disagreeing. It forms a structure of what is where
  ("this strip is road, this edge is shore, this ring of tents is a
  camp"), stored per map in a form the server can read.
- **Read by bots**, and ideally offered to players: the buddies' planner
  prefers road from it (617e). Later the same map can name places, find
  landmarks, or describe what a buddy sees.

## Suggested Implementation Steps

1. After 173v: the merged client draws a scene from a given camera to a
   picture and a depth picture, with no window.
2. The coordinate step: given a camera and a pixel's depth, the world
   point it shows. Test it against known points (a doodad's position, a
   creature's spawn).
3. Choose the recognition method: a model that labels pixels, trained or
   borrowed. A first labeller could start from the ground's textures and
   models, used as hints rather than as the answer.
4. The explorer's route: which spots and directions cover a map well.
   Playerbots' travel network (617e) gives paths through the whole world.
5. The perception map's format: grid cells or labelled shapes, per map,
   with each label's confidence and how many views saw it.
6. The road grid for 617e's planner, read from the perception map.
7. A phase demo picture: a zone with its perceived roads drawn over the
   map.

## Open Questions

1. (Answered 2026-10-07) **Recognition:** a trained model of our own.
   The custom client produces rough labels automatically (it knows which
   model or texture drew each pixel), and a person corrects them. The
   owner adds: "we might need to provide additional labels, for example
   'this is what a road looks like' - also keep in mind we need to have
   many many different camera angles." So the training set also holds
   hand-given examples of each label ("this is a road"), and every scene
   is photographed from many heights, distances and directions, so the
   model learns a road seen from above, from a horse, and from a
   kneeling gnome alike.
2. (Answered 2026-10-07) **Where it runs:** once per map, on the
   developer's machine. The result is a fixed database shipped with the
   server, the same for everyone.
3. **"As the players (and ideally, bots) should see it":** do players see
   the perception map themselves (a map overlay, named places), or is it
   only for bots?
