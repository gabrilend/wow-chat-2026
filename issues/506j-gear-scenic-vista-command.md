# 506j - Gear Scenic Vista Command

## Status
- Created: 2026-10-01
- Phase: 5
- Parent: 506
- Blocked by: None
- Blocks: world-edit-to-execute W05a's startup photoshoot (it reads the
  saved vistas)
- Priority: Medium

## Origin

The owner, 2026-10-01: "we should teleport the models to a couple scenic
vistas and photograph them there. In-engine image capture and rendering.
We should go through a list of all the models who need a photoshoot when
the server starts up, before players are allowed in." Then: "As we're
playing I'll find cool vistas and save them somehow. Ideally with a chat
command or something, that we haven't built yet." And: "the server will
spin up a client and pose them appropriately."

## Current Behavior

Not built. Nothing records a place in the world as a vista; the startup
photoshoot (W05a) has no list of places to pose models in.

## Intended Behavior

While playing, the owner stands somewhere beautiful and types a chat
command; the server remembers that spot as a **vista**. At startup, the
photoshoot (W05a) poses each model that needs pictures at every saved
vista, photographs it from the scoring camera ring (26 or 42 views)
centred on that spot, and only then lets players log in.

The commands (game masters only, like `.arena start`):

| Command | What it does |
|---------|--------------|
| `.vista save <name>` | saves where the character stands, which way it faces, and the game's time of day, under that name |
| `.vista list` | lists every vista: number, name, zone, who saved it |
| `.vista go <number>` | teleports to a vista, to look at it again |
| `.vista drop <number>` | marks a vista retired; the photoshoot skips it, the row is kept |

A vista record (one row of a world-database table, `gear_vista`):

| Field | Data type | Meaning |
|-------|-----------|---------|
| id | unsigned 32-bit integer, auto-increment | the vista's number |
| name | string, up to 64 characters | what the owner called it |
| map | unsigned 16-bit integer | map id (0 Eastern Kingdoms, 1 Kalimdor, 530 Outland, ...) |
| x, y, z | 32-bit floats | position in yards, the game's own axes |
| facing | 32-bit float | radians, 0 = east, counter-clockwise |
| time_of_day | unsigned 16-bit integer | minutes after midnight, game time, when saved |
| saved_by | unsigned 32-bit integer | the character's low GUID |
| saved_at | unsigned 32-bit integer | Unix time |
| retired | unsigned 8-bit integer | 0 = in use, 1 = dropped |

**What a vista can't hold.** The server knows where the character stands
and faces, but not where the player's camera is (zoom, pitch): the client
never tells it. So a vista is a *place*, not a *shot*: the model stands
on the spot, faces the saved direction, and the photoshoot's own camera
ring supplies the angles. The saved facing decides which camera of the
ring looks the way the owner was looking.

## Suggested Implementation Steps

1. Create `gear_vista` in the world database, from a project SQL file
   applied at install (the E-patches route), so a fresh install has it.
2. A new Lua script in the basic profile's folder: the chat command
   handler (player event 42, the same hook as the arena trial's), with
   save, list, go and drop, each answering in chat. `save` refuses an
   empty name, and refuses a spot inside an instance (map types other
   than the open world), since the photoshoot's client poses models on
   open-world maps.
3. A small export the photoshoot reads: the in-use rows as a list, so the
   custom client's photoshoot (W05a) doesn't need database access of its
   own. Format decided with W05a.
4. Tests: save then list shows the row; go teleports to its coordinates;
   drop hides it from the export but keeps it in the table; a refused save
   (no name, inside an instance) writes nothing and says why.

## Related Issues

- **506** parent; **506e** (the camera plan whose rings are posed here)
- world-edit-to-execute **W05a** (the similarity score: its startup
  photoshoot, region overlays, and the scoring camera ring)
- `src/lua-basic/arena-trial.lua` (the chat command pattern followed)
