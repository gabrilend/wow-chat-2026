# 919d - The Architect

## Status
- Created: 2026-10-20; rewritten 2026-10-21 (the player tells him, not he
  the player)
- Phase: 9
- Parent: 919 (three worlds: Earth, Mars and the Sun)
- Blocked by: 919a (a real-scale map to remember), 916 (the chat layer and
  its model runner), world-edit-to-execute W09 (the recipes) and W05 (the
  asset forge: find or generate a model)
- Blocks: custom-client 909 (the Architect's assets in the client: how
  each player's own versions, and a square's chosen versions, are drawn)
- Related: 506c and 506f (gear from images to 3D: the same image-to-model
  steps, for items), 920 (parked: the hidden-character way and the whisper
  handling designed there are reused here; the Architect is the project's
  own character, not Blizzard's, so he is not parked)
- Priority: Low

## Origin

The owner, 2026-10-20, verbatim:

> then can we make an architect character who players can whisper to
> inform about the veracity status of their particular section of the map?
> He should be a local LLM that generates shapes, models, textures,
> whatever you need, either locally or shelling out to some network command
> that outputs the file type requested. He'll try and accomadate their
> concerns, taking as input the various local nearby perspectives. In this
> way, we might be able to recreate our childhood homes and etceteras. I
> bet it'd make a lot of old people cry.
>
> my question is, how do we go from flat terrain to 3d model? I think we'd
> need some sort of...
>
> custom trained model...
>
> jeez my budget can't afford that!
>
> I'll see what I can do.

And 2026-10-21, correcting the first draft (which had him telling players
how accurate the map was):

> no you tell him how accurate it is. Your memory is what matters. And it's
> part of the custom client, the architect, so make sure he goes over
> there. Though, he's sort of a wow-chat-2026 specific feature, so maybe he
> goes here? The point is that you should use him as a way to say "no, for
> me, I want my asset generation to look like this" and as long as it's
> functionally the same, then it's fine I think.

On two players who remember the same place differently:

> stays local. Whichever player entered that square first is the one who
> decides, until they leave.

## Current Behavior

Not started. Generated maps (919a, 919b) are built from recipes; every
player sees the same ground, the same buildings and the same textures, and
nobody can say "that is not how I remember it".

## Intended Behavior

**The Architect** is a character players whisper (in the way 920b designs
for the legends: a hidden character, always online). The player is the
authority, not the data: **the player's memory is what matters.** A player
standing somewhere tells him what this place was like for them ("the house
on the corner had a porch and was painted green", "the hill behind the
school was steeper", "the light came through the cottonwoods here"), and
sends photographs if they have them. He makes **their version**:
the models, textures and shapes that look the way they remember, and
gives them to that player's client.

### Functionally the same

A player's version may change how anything *looks*, never how the world
*works*. The rule, checked by a tool on every generated asset before it is
handed over:

- **Ground**: no change to heights or holes. Ground heights are the server's
  (it computes walking, falling and line of sight from them), so a
  remembered "steeper hill" is drawn as a steeper-looking surface (texture,
  shading, small rocks) over the same heights, or not at all.
- **Models**: the same collision shape within a tolerance (the outline
  walkers bump into, which the server and the client share), the same
  doorways and walkable floors, the same attachment points; any shape,
  colour and detail inside that.
- **Textures and light**: free.

An asset that fails is not handed over; the Architect says what part
failed ("a porch there would block the path the server walks people
along") and offers what would pass.

### Who sees which version

- **Each player sees their own**: their versions are their own asset pack,
  which the custom client already ranks first ("priority is: player chosen,
  server supplied, blizzard original", custom-client
  `docs/012-asset-replacement-and-provenance.md`).
- **The square's shared look, for everyone else in it**, follows the owner's
  rule: "Whichever player entered that square first is the one who decides,
  until they leave." While the first player to have entered a map square
  (one terrain tile, 533 yards on a side) is in it, the others there who
  have no version of their own see that player's. When that player leaves,
  the next earliest arrival decides. When nobody with a version is there,
  the recipe's own build shows. The server keeps, per square, the order in
  which players entered, and tells each client whose versions to draw.

### Where he lives

He is split along the line between server and client:

- **Here (wow-chat-2026)**: the character, the conversations, each
  player's memories of each place (a store: player, square, what they said,
  photographs, the versions made from them), the per-square arrival order,
  the generation queue and the "functionally the same" check.
- **The custom client** (custom-client 909): receiving a player's versions
  and a square's chosen versions, keeping them as packs, and drawing the
  right one. The stock client cannot draw different versions for different
  players, so only the custom client shows them.
- **Generation runs** on the project's model runner, wherever it is: in the
  server, beside it, or in the player's own client (custom-client 907, the
  model in the client), so a player's version can be made on their own
  graphics card. What he can do is a fixed list of tools (generate a
  texture, a model, a building from an outline; check an asset; hand it
  over), each local or a named network command from a list the owner keeps;
  he cannot run anything not on it.

### From flat terrain to 3D (the owner's question)

No custom-trained model is needed, because most of the 3D is already in
the data or can be built by rules:

1. **The ground is already 3D.** Elevation data is a height for every
   point; the map writer turns it into the client's terrain mesh (W02a).
2. **Buildings from footprints, by rules.** OpenStreetMap stores each
   building's outline, and often its height or number of floors and its
   roof shape. Raising the outline to its height and putting the named roof
   on top makes a plain, correctly sized building; this is how existing 3D
   map viewers draw cities. These are the recipe's buildings, the ones
   everyone sees until someone remembers otherwise.
3. **Trees, fields, rock** from the satellite land cover, placed by rules.
4. **A remembered building, from photographs or words**, all with free,
   already-trained tools on one's own graphics card:
   - **photogrammetry** (COLMAP, Meshroom: programs that find the same
     points in many overlapping photographs, work out where each point is
     in space, and lay a surface through them), from a few dozen photos;
   - **single-image to 3D** (TripoSR, Hunyuan3D-2, TRELLIS: open models
     that guess a mesh and its texture from one picture), through ComfyUI,
     which world-edit-to-execute's asset forge (W05) already uses; one old
     photograph is enough to start;
   - **words to texture** (image generation in the same ComfyUI) for what
     the player only describes ("painted green, peeling").
   Each result is reduced to the client's budget and run through the
   "functionally the same" check against the recipe's building it replaces.

So the cost is graphics-card time, not training.

## Suggested Implementation Steps

1. The memory store and the per-square arrival order (server side, a
   characters-database table each, made by an install step).
2. The "functionally the same" checker as a tool of its own (collision
   outline, doorways, floors, attachment points compared within
   tolerances), with tests: a recoloured house passes, a house with a wall
   across its door fails.
3. Footprint buildings as a stage in `build-world` (W09), so every
   real-scale map has the recipe's buildings to remember against.
4. The Architect's character and whisper handling (920b and 920c's
   designs, reused), with his fixed tool list.
5. Generation routes (photogrammetry, single-image, words-to-texture)
   through W05's forge.
6. Handing over: a version goes to its player's client as a pack
   (custom-client 909), and to the server's per-square record.
7. A test: a planted memory ("the corner house is green") makes a version
   that passes the check, reaches that player's client, and is shown to a
   second player in the square only while the first is there.

## Open Questions

1. **Does the first arrival also outrank another player's own version?**
   As written, a player always sees their own; the first arrival decides
   only for those with none. Or should the first arrival's memory be what
   everyone in the square sees, own versions included, until they leave?
2. **Whose house is it?** A version made from photographs of a real home,
   shown to others in that square, puts a real place's look into a shared
   world. Should a player be able to keep their versions to themselves
   (never shown to others, even when they arrived first)?
