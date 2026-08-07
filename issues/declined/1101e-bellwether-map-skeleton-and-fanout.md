# 1101e - The Bellwether Map Skeleton and Family Fanout

## Status
- Created: 2026-08-01
- Parent: Issue 1101 (Bellwether — attended play)
- Phase: 11
- Priority: High (first end-to-end run)
- Depends on: 1101d (facts arrive already chosen), SoraMech available

## Overview

Builds the SoraMech map that is the pipeline. After this issue, facts go
in one end and come out the other, once per ward, forever, with no model
anywhere in it. That is a real deliverable — attended play with a
robotic voice — and everything after this replaces boxes inside a graph
that already turns.

## Current Behavior

No map exists. Facts sit in the worldserver's memory with nothing
reading them.

## Intended Behavior

### The map directory

```
maps/bellwether/
  meta.json          name, description, entry box, src dirs
  boxes/
    ingest.json      call box — pulls fresh facts (see below)
    fanout.json      iterator routing — one output port per ward
    compose.json     call box — facts to a plain sentence, no model
    emit.json        the interface sub-map's entry box (1101j)
    heartbeat.json   re-arms the lap
  src/
    ingest.lua       reads the fact feed
    compose.lua      templated sentences from facts
  drivers.json       lua and bash drivers
```

Per SoraMech's own house rules the map directory *is* the program.
Reading `boxes/` in order should tell the story of a lap.

### The lap must not be a raw back-edge

SoraMech's loader rejects a raw back-edge as a deadlock risk. A
long-running map is built from its cycle-safe constructs — an
iterator-routing box, or a re-arming heartbeat. The lap here re-arms
through the heartbeat box, which is also the natural place to hold the
lap interval.

This is the single most likely thing to get wrong on the first attempt.
Read `docs/004-runtime.md` in the SoraMech tree, the "Termination:
circular vs. quiescent" section, before wiring anything.

### The fact feed cannot be a read box

A path-backed `read` box reads its file once at graph load and caches it
for the life of the run. The map runs for hours. A read box pointed at
the fact feed would narrate the first lap's facts forever — and it would
do it silently and plausibly, which is the worst kind of bug.

The ingest box is therefore a `call` box that does its own fresh I/O
every fire. What it reads is the open question below.

### Fanout across the family

`iterator` routing, one output port per ward. Consecutive fires take
ports in round-robin via a per-port atomic counter, so parallel laps get
distinct wards without the map having to coordinate anything.

The family size is not fixed, and the port count in a map file is. Three
options, decided in this issue:

1. **Fixed maximum ports** — wire N ports for the ceiling family size;
   unused ports carry a no-op ward id. Simple, wasteful, works today.
2. **Regenerate the map on roster change** — a small tool writes the box
   JSON from the roster, and the run restarts. Honest, and restarts are
   cheap; costs a gap in coverage at exactly the moment the player is
   fiddling with their family.
3. **One ward per fire through a single port**, with the ward id
   travelling as a value rather than as a port choice. Loses the
   parallelism the iterator was providing, gains a family size the map
   never has to know.

Option 3 is probably right and option 1 is probably what gets built
first. Runtime graph mutation, which would make this a non-question, is
not available upstream (SoraMech issue 419, rolled back).

### The composer

`compose.lua` turns a group of facts into a plain sentence using
templates only — one template per fact kind, filled from
`text_fragments` and `numbers`. No cleverness. This box exists for two
reasons: it makes the map deliverable before any model exists, and it is
the fallback 1101i falls back *to* when a generated utterance fails
validation. It is not scaffolding to be deleted later; it is the floor.

## Implementation Steps

1. Create the map directory, `meta.json`, and `drivers.json`. Confirm
   `soramech-pool maps/bellwether` loads and reports the box count.
2. The heartbeat lap: a two-box map that re-arms itself and logs a tick.
   Run it for ten minutes and confirm it neither quiesces nor deadlocks.
3. The ingest box, reading a fixed fixture file of facts. Confirm fresh
   reads on every lap by editing the fixture mid-run — this is the
   read-box trap, verified rather than assumed.
4. The composer, with templates for the five core fact kinds.
5. A `write` box to a text file as the world's simplest interface, so
   the lap is observable before 1101j exists.
6. The iterator fanout, with whichever family-size option is chosen.
   Test at family sizes of 1, 3, and 5.
7. Connect the real fact feed from 1101d.
8. A run script in `scripts/` that starts the pool runner against this
   map, per house rules: hard-coded `${DIR}` at the top, overridable by
   argument, all paths relative to it.

## Files to Create

- `maps/bellwether/` — the map directory
- `scripts/bellwether` — start, stop, status for the runner process
- Fact fixture files for testing the map without a running worldserver

## Open Questions

- **How do facts cross from the worldserver into the map?** The
  candidates: a file the ingest box re-reads each lap (simplest, and the
  fact feed is small); a Unix socket; a database queue table; or an HTTP
  endpoint the ingest box polls. A file in the RAM tier under
  `tmp/shared-memory/` is the house-style answer and probably right —
  but it needs a write discipline so the map never reads a half-written
  feed.
- **Where does `soramech-pool` run, and who starts it?** Alongside the
  worldserver under `scripts/`, or as its own service? What happens to a
  running map when the worldserver restarts under it?
- Should the whole pipeline be one map or several? One map per family is
  the obvious cut and gives per-player isolation; one map with the
  family as an iterator is fewer processes. SoraMech runs multiple maps
  as separate runner processes, so both are supported.
- Does the composer's template set live in the map's `src/`, or beside
  the fact extractor in ALE Lua? The templates are the *same knowledge*
  as the fact kinds, and splitting them across two languages in two
  repositories is how they drift apart.

## Related

- Parent: [1101 - Bellwether](1101-bellwether-attended-play.md)
- [1101d - Salience and the event ledger](1101d-salience-and-event-ledger.md)
  — produces the fact groups this ingests
- [1101f - Urgency branch](1101f-urgency-branch-and-interrupt-path.md) —
  the first box added inside this skeleton
- [1101j - Interfaces as sub-maps](1101j-interfaces-as-submaps.md) —
  replaces the temporary text-file write box
- SoraMech `docs/002-map-model.md` (box kinds, routing kinds, read-box
  semantics, encapsulation) and `docs/004-runtime.md` (the lap, the
  JSONL transcript, termination) — required reading before step 1
- SoraMech issue 419 (runtime graph mutation) — why the family-size
  question has no clean answer yet
</content>
