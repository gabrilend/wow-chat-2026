# 617e9 - Boarding Recordings

## Status
- Created: 2026-10-02
- Phase: 6
- Parent: 617e
- Blocked by: 617e8 (the crossing that uses the recordings)
- Priority: High

## Origin

Verbatim, 2026-10-02, on learning that a buddy can only ride a ship whose
deck spot some player has shown it since the server started:

> can we build a tool or utility that is startable from in-game that'll
> record my character's starting position and coordinates, then replay
> through my motions? If I stop and stand still halfway through, it doesn't
> have to stop, it can just keep track of the waypoints. I'm thinking I'll
> just, go to each boat and record myself embarking and disembarking like
> 10 times per stop, approaching from slightly different angles or
> whatever. Then, when we need a bot to board, it'll pick one of those
> starting points (ideally an un-occupied one), go stand there, and wait
> until the boat comes. Then it'll replay the exact movements I take
> (including jumping and camera movements and turning and such) to
> properly embark. I can do it with a tauren model if you think that'll
> matter.

## Current Behavior

**Built 2026-10-02, syntax-checked with the build's flags, not yet
compiled or tried in game** (`modules/mod-buddies/src/buddies_recorder.cpp`
and `.h`; used by `buddies_crossing.cpp`; tables in
`sql/basic/db_world.src/28-buddy-beds.apply.sql`, installed by E045;
`scripts/export-buddy-boardings`).

**Recording, in game** (game masters; stand on the dock, or on the deck
for a disembark, before starting):

| Type | What it does |
|---|---|
| `.buddy record start` | begins at the spot you stand on (ashore: an embark; on a ship's deck: a disembark) |
| `.buddy record stop [note]` | checks it and keeps it, telling you its number and how many that stop now has |
| `.buddy record discard` | throws away the one under way |
| `.buddy record list` | every recording of every ship stop within 150 yards: number, kind, ship, stop, steps, seconds, who, note |
| `.buddy record delete <number>` | removes one |

Then, outside the game, `scripts/export-buddy-boardings` copies the live
recordings into the install file, so they are kept in git and come back
with any fresh install (as `scripts/export-buddy-beds` does for beds).

- **Capture**: the server's own "a player moved" hook (every movement
  report the client sends: steps, jumps, landings, stops, turns), chosen
  over sampling the position on a timer, which would miss the instant a
  jump leaves. A report is kept as a step when it is a jump, a landing,
  the moment of stepping onto or off the deck, a stop, a turn of 0.3
  radians or more, or a yard from the last kept step. On the deck the
  client's own offset from the ship is kept. Each step: milliseconds
  from the start, flags (on deck, jump, landing, walking), position and
  facing, and a jump's sideways and upward speeds.
- **What is refused at stop** (each says why and what was recorded):
  anything but exactly one step onto the deck (an embark) or off it (a
  disembark); two different ships; an elevator; a change of map during
  the recording (the ship sailed); more than 1,500 steps; a ship not
  within 60 yards of a stop on its route when you were aboard (not
  docked).
- **Which stop**: the ship's route stops, read by the crossing from the
  client's flight-path data in their own order; the recording is filed
  under the ship and that stop's number (`BuddyTransportStop`).
- **Storage**: `buddy_boarding` (one row per recording) and
  `buddy_boarding_step` (one per step) in the world database, beside the
  beds; read once at first use; written at once by the commands.
- **Choosing**: a buddy boarding a ship at a stop takes a recording of
  that ship, stop and direction whose start no other buddy holds, nearest
  first (else the nearest held one), and holds it until its boarding ends.
- **Replay**: the buddy walks to the start on the navigation mesh, waits
  facing the way the recording began, and once the ship is in walks it
  one leg at a time: a straight move to each kept step (no path search:
  the recording is the path), walking where the recording walked; from a
  jump step, a jump straight to its landing with the recorded speeds;
  deck steps turned into world yards from where the ship lies at that
  moment. Arriving on the first deck step puts the buddy on the ship's
  passenger list; leaving the deck takes it off. Pauses in the recording
  are not waited out. A leg gets 1.5 times its walking time plus 2
  seconds; a leg that ends more than 1.5 yards short is sent again twice,
  then the boarding fails loudly (617e8's failure shape).
- **No recording**: 617e8's straight walk, logged as a "FALLBACK" warning
  naming the ship and dock.

What the server can and can't see, which shapes the recording:
- **It sees** every movement the client reports: position, facing,
  jumps and falls, swimming, and, once aboard, the position *relative to
  the ship* (the client sends the ship's id and an offset on its deck).
- **It never sees the camera.** Only the character's facing reaches the
  server, so turning is recorded and camera swings are not.
- **Model size doesn't matter.** A bot's movement is driven by the server
  along given points, not by the client's collision, so a tauren's path
  replays the same for a gnome. Any race can record.

## Intended Behavior

- **Recording, from in game**: a GM command starts a recording at the
  character's current spot (with the dock or ship it is next to) and stops
  it on command. In between, every reported movement is kept as a timed
  waypoint: where, which way facing, jumping or not, on the ground or on
  the deck (and if on the deck, the offset on it). Standing still
  mid-recording just leaves a gap in time; nothing stops.
- **Kinds**: an embark (dock to deck) and a disembark (deck to dock), each
  tied to the transport and the route stop where it was made. The owner
  plans about ten of each per stop, from different approaches.
- **Stored for good** in a table, so recordings survive restarts and are
  shared by every buddy.
- **Boarding by replay**: a buddy sent to a dock (617e8) picks one of that
  stop's embark recordings whose starting spot no other buddy holds,
  walks there on the navigation mesh, waits until the ship is docked at
  that stop, then replays the movements in time: walking legs, turns,
  jumps, and the deck part in the ship's own frame, so it lands where the
  recording landed even though the ship has moved. Getting off uses a
  disembark recording for the arrival stop the same way.
- **No recording for a stop**: 617e8's own straight-leg boarding is used,
  and the log says no recording existed.
- **Listing and pruning**: commands to list a stop's recordings and delete
  a bad one by number.

## Suggested Implementation Steps

1. The recordings table (characters database, beside the buddy tables):
   one row per recording (kind, transport, route stop, who made it, when),
   one row per waypoint (time offset, position, facing, jump/fall flag,
   on-deck flag and deck offset).
2. The record command: start, stop, discard; capture from the player's
   reported movement (the server's movement handling, or a short periodic
   sample of the player's movement state while recording).
3. The replay: walking legs with the server's point moves, jumps with its
   jump move, deck legs converted from the ship's frame each step;
   boarding attaches the buddy to the ship the way the server attaches a
   player who steps onto it.
4. Choosing a recording: unoccupied start spot first, else the nearest.
5. 617e8's boarding calls this first and falls back only when a stop has
   none (logged).
6. In game: record an embark at Menethil's dock, have a buddy replay it
   onto the Theramore boat; record a disembark at Theramore and watch it
   step off.

## Related Issues

- **617e** parent; **617e8** the crossing that boards with these

## Open Questions

- (2026-10-02) Ten recordings per stop, all kept, or keep only the best few
  (shortest, fewest jumps)?
- (2026-10-02) **Seen by other players**: the server moves a boarding buddy
  along the recorded points and then puts it on the ship's passenger list
  without telling nearby clients the way a real client's own report does.
  617e8's straight boarding does the same. Whether onlookers see the buddy
  carried with the ship, or left standing on the water until it next
  moves, is to be seen in game.
- (2026-10-02) **Timing kept or not**: legs follow one another as fast as
  they finish; a recorded pause (waiting for the gangway to line up) is not
  waited out. If a boarding only works with the pause, should a long
  standstill in a recording be kept as a wait?
