# 1101n - Session Lifecycle, Catch-Up Digest, and Observability

## Status
- Created: 2026-08-01
- Parent: Issue 1101 (Bellwether — attended play)
- Phase: 11
- Priority: Medium (the last thing built, the first thing used)
- Depends on: most of the rest existing to be operated

## Overview

A session is the unit of attendance: it starts, it has an interface and
a budget and a family, it goes quiet, it resumes, it ends. This issue
owns that lifecycle, the digest a player gets when they come back, and
the operator's view of whether any of it is working.

## Current Behavior

There is no session object. The map either runs or doesn't.

## Intended Behavior

### The session record

| Field | Meaning |
|-------|---------|
| `family` | which roster (1101a) |
| `interfaces` | which sub-maps are attached (1101j) |
| `budget` | utterances per minute (1101d) |
| `attention` | driving / second screen / at the desk |
| `started_at`, `last_heard_from` | for detecting a listener who has drifted off |
| `state` | starting / attending / away / ending |

### Starting

1. Resolve the family, confirm the wards are enrollable
2. Run the cluster pre-flight — the same check 916m specifies, curling
   each host — and report the result rather than discovering it on the
   first utterance
3. Enroll the family (1101a)
4. Load standing orders into the map's read boxes (1101l)
5. Attach the interfaces
6. Start or adopt the runner
7. Say one line confirming all of the above in a sentence: who's out,
   under what orders, how you'll be told.

That last step is the whole start sequence from the player's side, and
it should be a sentence, not a status dump.

### Going away and coming back

**Away** is the listener not responding and not receiving — the car
stopped, the interface detached, the person asleep. The family keeps
playing. Facts keep entering the ledger. Nothing is spoken.

**Coming back** produces a digest, and the digest is not the ledger
replayed. It's the ledger read with a completely different budget and a
different question: not "what is happening" but "what happened." The
shapes are different — a digest wants outcomes and trends, not moments.

> You were out about an hour. Everyone's alive. Tessa hit 24 and she's
> in Duskwood now, which is further than you left her. Bram died once to
> something big near the bridge and has been resting since. Nobody's
> broke.

Deaths, level-ups, zone changes, anything unresolved, and the state
right now. Everything else is dropped, and the count of what was dropped
is available if they want it.

### Ending

Unenroll or leave enrolled — the player's choice, because an unattended
family that keeps playing is a legitimate thing to want. Persist
standing orders. Detach interfaces. Say goodbye, which per house rules
is the last thing a program does.

### Observability

Console commands for the operator, following the `.soren` precedent from
916n:

| Command | Shows |
|---------|-------|
| `.bell status` | active sessions, families, interfaces, runner state |
| `.bell family <name>` | roster, enrollment, standing orders |
| `.bell ledger` | pending facts, scores, what aged out unspoken |
| `.bell cluster` | host health, latency, which host served what |
| `.bell reload` | re-read the map and restart the runner |

And the numbers that say whether this is working, logged periodically:

- Utterances per minute, versus budget
- **Fallback rate** — templated lines standing in for generated ones
  (1101i). The single most diagnostic number in the system, because a
  listener cannot hear the difference.
- Facts aged out unspoken, by kind — if `hurt` never gets said, the
  weights are wrong
- Alarm latency, p50 and worst case — 1101f's guarantee, measured
- Guidance: accepted, refused, read-back-corrected
- Inference latency and error rate per host

SoraMech writes a JSONL transcript per run, one event per line. Most of
the above is a query over that file rather than new instrumentation, and
the queries should ship as small scripts rather than as remembered
incantations.

## Implementation Steps

1. The session record and its state machine.
2. Start sequence, including the pre-flight and the one-sentence
   confirmation.
3. Away detection: an interface reporting unattached, or no response for
   a threshold.
4. The digest: a separate read over the ledger with its own budget and
   its own prompt, since it answers a different question than 1101h's.
5. End sequence, including the choice to leave the family enrolled.
6. The `.bell` command set.
7. Metric extraction scripts over the JSONL transcript, in `scripts/`,
   per house rules on `${DIR}` and paths.
8. Periodic metric logging to the RAM-tier log directory.

## Files to Create

- Session module
- Digest prompt and builder
- `.bell` command registration
- `scripts/bellwether-metrics` — transcript queries
- `docs/bellwether-operations.md`, added to the table of contents

## Open Questions

- How long away before a digest is worth generating rather than just
  resuming? Five minutes of silence isn't a story.
- Is the digest generated when the player leaves, when they return, or
  continuously? Continuously means it's always ready and always costing;
  on return means the first thing a returning player gets is a wait.
- Can one player attend two families at once, and if so does that need
  two sessions or one session with two rosters?
- Should sessions be resumable across a worldserver restart? A player
  attending from a car does not know the server bounced, and "the
  session ended because a machine restarted" is not a fact about their
  family.
- What does the system do when the player never comes back — a session
  left attending for three days? There is presumably a timeout, and
  presumably the family keeps playing, and those are two different
  decisions.
- Do the metrics belong in the in-client panel (1101k) as well as the
  console? The fallback rate matters to the player, not just the
  operator, because it tells them how much of what they heard was
  written by a template.

## Related

- Parent: [1101 - Bellwether](1101-bellwether-attended-play.md)
- [1101d - Salience and the event ledger](1101d-salience-and-event-ledger.md)
  — the digest is the ledger under a different budget
- [1101j - Interfaces as sub-maps](1101j-interfaces-as-submaps.md) —
  attachment and the `attached` port drive away-detection
- [916n - Debug commands and observability](916n-debug-commands-observability.md)
  — the `.soren` command set this mirrors; consider whether one command
  set should cover both systems
- [916m - Bash health check](916m-bash-health-check.md) — the pre-flight
  reused at session start
- [128 - Script command history](128-script-command-history.md) — the
  house pattern for operator-facing script ergonomics
</content>
