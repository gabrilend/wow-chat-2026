# 917d - What It Keeps Doing

## Status
- Created: 2026-08-01
- Parent: Issue 917 (Ask the bots in plain text)
- Phase: 9
- Priority: Medium
- Depends on: 917c (something to persist)

## Current Behavior

A command is issued and that's the end of it. Nothing remembers why.

## Intended Behavior

A request doesn't end when the sentence does. "Keep everyone repaired"
is not a command, it's a policy, and it should still be true an hour
later without being retyped.

So the layer holds **standing instructions**: requests that persist
until changed, re-checked when the state changes enough to matter.

The set of them is the interesting part. It accumulates. A player and
the layer work out, over weeks, what this particular person wants their
bots to do — and that accumulated set is the system the two of them
built together. It is the thing worth backing up, worth naming, and
worth being able to read as a list.

### Reading and editing them

A player can ask what's standing and get a list in plain language. They
can drop one. They can replace one. Nothing about the set should be
invisible — a standing instruction the player has forgotten giving is a
bot doing something inexplicable.

### When they conflict

Two standing instructions can contradict, and the layer should say so
when the second one is given rather than silently letting the newer win.
The player is building a system; a system that quietly overwrites itself
is not one they can reason about.

## Implementation Steps

1. Persist standing instructions — the original text, when it was given,
   which bots it covers.
2. Re-evaluate on a trigger: a timer at first, state change later.
3. Reading them back as a list, in the player's own words.
4. Dropping and replacing.
5. Conflict detection at the moment of adding, not at the moment of
   firing.
6. Test the accumulation directly: give six over a session, relog, and
   confirm the set is intact and still legible.

## Open Questions

- Where do they live — a table in the characters database, or a file the
  player could edit by hand? A file is inspectable and diffable, which
  suits something meant to be built up over time.
- Per character, per account, or per player? "Keep everyone repaired"
  isn't about one bot.
- What triggers re-evaluation? A timer is easy and wasteful; a state
  change is right and needs to know which changes matter.
- Do standing instructions apply to bots added later? "Everyone" was
  true when it was said.
- Is there an expiry? An instruction given in a dungeon and still
  standing three zones later may be wrong in a way nobody notices.
- Can the player name a set of them and switch between sets — one for
  dungeons, one for wandering? That's the point at which this stops
  being a list and becomes something they've genuinely built.

## Related

- Parent: [917 - Ask the bots in plain text](917-ask-the-bots-in-plain-text.md)
- [917c - Writing the commands](917c-writing-the-commands.md) — supplies
  what gets persisted
- [613 - Behavior orchestrator modes](613-behavior-orchestrator-modes.md)
  — the existing notion of a bot being in a mode; standing instructions
  should not become a second unrelated mode system
</content>
