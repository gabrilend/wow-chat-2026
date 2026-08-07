# Phase 11 Progress: Attendance

## Effect

The game is attended from elsewhere. You listen; they fight.

## Status: Not Started

## Goal

Let a player keep a family of their own characters adventuring while
they are doing something else, and understand what is happening to that
family without looking at a screen.

The characters act on playerbot AI. Each is its own connection,
collected into a single view. The language model is **an input method** —
the same class of thing as a keyboard or a gamepad — carrying intent in
and state out of a game that is otherwise unchanged. It guides between
tasks; it never makes a decision the bot AI would have made faster.

The server reads each ward's state and joins it against the game's own
data until it is sentence-ready. The LLM cluster explains it to a
listener. The listener answers however they like, at whatever altitude
suits them, and their answer becomes standing policy until they change
it.

> real life is for living, video games are for fighting.

---

## Issues

| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 1101 | bellwether-attended-play | Open | Parent |
| 1101a | family-enrollment-and-persistence | Open | Blocks everything; owns the anchor question |
| 1101b | ward-state-reader | Open | Raw snapshots, no interpretation |
| 1101c | fact-extraction-aided-by-data | Open | **Correctness-critical**: the join that makes it true |
| 1101d | salience-and-event-ledger | Open | Chooses what is worth saying |
| 1101e | bellwether-map-skeleton-and-fanout | Open | First end-to-end run, no LLM |
| 1101f | urgency-branch-and-interrupt-path | Open | The half that has to be fast |
| 1101g | inference-boxes-and-cluster-routing | Open | Overlaps 916f; decide once |
| 1101h | explaining-voice-prompt-and-persona | Open | Where it becomes pleasant |
| 1101i | utterance-validator | Open | **Safety property**: no unlicensed claims |
| 1101j | interfaces-as-submaps | Open | Per-user, per-session windows |
| 1101k | bellwether-aio-addon | Open | The client half, panel + sensor |
| 1101l | guidance-capture-and-standing-orders | Open | The return path, five altitudes |
| 1101m | applying-guidance-to-wards | Open | Reuses the 916 apply path |
| 1101n | session-lifecycle-and-observability | Open | Sessions, digest, `.bell` |

## Issue Hierarchy

```
1101 (Bellwether — attended play)
│
├── The sensor — no LLM, no map
│   ├── 1101a  family enrollment ──────► gates everything
│   ├── 1101b  ward state reader
│   ├── 1101c  fact extraction ────────► the correctness story
│   └── 1101d  salience ledger
│
├── The map — SoraMech
│   ├── 1101e  skeleton + family fanout
│   ├── 1101f  urgency branch ─────────► never waits on inference
│   └── 1101g  inference + cluster routing
│
├── The voice
│   ├── 1101h  explaining voice
│   └── 1101i  utterance validator ────► the safety property
│
├── The window
│   ├── 1101j  interfaces as sub-maps
│   └── 1101k  the AIO addon
│
└── The return path
    ├── 1101l  guidance + standing orders
    ├── 1101m  applying guidance
    └── 1101n  sessions + observability
```

## The Shippable Floor

Steps 1101a through 1101f produce a working attended mode with **no
language model in it at all** — templated facts, spoken plainly, with
alarms that interrupt. That is the honest floor and it should ship on
its own before any generation exists.

Everything from 1101g onward makes that floor pleasant. If the cluster
is down, the floor is what the listener falls back to, which is why it
is built first and kept rather than discarded as scaffolding.

## Completed: 0/15

---

## Before State

- Altbots exist upstream and can be added by name or by account, and
  selfbot support lets a player hand their own logged-in character to
  bot AI. What's missing is any notion of a persistent *family* — a
  named set that survives logout and carries its own standing orders.
- Issue 916 (mod-soren-chat) specifies the LLM cluster, the worker pool,
  host health rotation, and a directive-apply path into mod-playerbots.
  All of it is aimed at bots near a present player.
- SoraMech exists as an external project with a working box-and-wire
  runtime, a C thread pool, and a JSONL transcript. Nothing in this
  repository uses it yet.
- AIO is installed; issue 616 carries the addon precedent and the
  combat-lockdown research.
- No system in the project addresses a player who is not looking at the
  screen.

## Dependencies On Other Phases

| Phase | What Phase 11 needs from it |
|-------|------------------------------|
| 3 / 9 | Issue 916's cluster, worker pool, and directive-apply path |
| 6 | Bot behaviors — the wards' moment-to-moment competence |
| 8 | Death and progression rules, which decide what a death alarm means |
| 10 | The rmail bridge, as one of the interface sub-maps |

## Open Questions Held At Phase Level

These are gates on the phase, not on any single issue. Each is recorded
in the parent issue with its full framing.

1. What the system should be called — "Bellwether" is a working handle.
2. Whether issue 916's three-box cluster and SoraMech's Alpine cluster
   are the same hardware, and who owns the slot budget if so.
3. ~~Whether an attended session needs the WoW client running at all.~~
   **Answered 2026-08-01:** the player is logged in, playing their own
   characters, which act on playerbot AI. The selfbot permission level
   already in `playerbots.conf.dist` is the whole mechanism — no
   headless session holder, no core patch. Guidance happens between
   tasks rather than on a timer.
4. How the player answers when they're driving; whether speech
   recognition needs an issue of its own.
5. How many wards a person can actually attend, which sets the salience
   budget.
6. What happens when a ward dies while the player is away.
7. Which profile this targets.
</content>
