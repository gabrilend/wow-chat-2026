# 1101l - Guidance Capture, Vocabulary, and Standing Orders

## Status
- Created: 2026-08-01
- Parent: Issue 1101 (Bellwether — attended play)
- Phase: 11
- Priority: High (without this the feature is a broadcast, not a game)
- Depends on: 1101j (the `guidance` port)

## Overview

The return path. *"They can guide it any of many which ways."*

That phrase is a specification, not a flourish. Guidance is not one
channel with one grammar. A player who is driving says something vague;
a player at their desk edits a policy; a player who has thought about it
for a week rewires the pipeline. All three are guidance, and each lands
in a different place in the system.

This issue defines the altitudes, the vocabulary, and the mechanism that
makes a player's silence mean the last thing they decided.

## Current Behavior

Nothing accepts input. Issue 916 sends LLM-derived directives to bots;
no path exists for a *player's* directives, and the guidance layer there
is aimed at bots near a player, not at a family being attended.

## Intended Behavior

### Five altitudes

| Altitude | Example | Lands in | Lifetime |
|----------|---------|----------|----------|
| **Mood** | "be careful" | multipliers across the family | until changed |
| **Target** | "help Tessa" | one ward's focus | the current fight |
| **Task** | "go sell, then regroup" | a queued objective per ward | until done |
| **Standing order** | "never fight anything above your level" | the roster's `standing_order` | until changed, across sessions |
| **Rewire** | "stop telling me about loot" | the map itself | permanent, needs a restart |

**Task is the load-bearing one.** Per the parent's cadence note, the
natural moment for guidance is a task boundary — a fight ends, a place
is reached, a ward runs out of something and stops. Between boundaries
the bot AI is executing and has nothing to ask about. Mood and standing
order are the settings that shape how boundaries get resolved when the
player says nothing; target is the exception that interrupts mid-task;
rewire is a considered act done at a keyboard. Everything is timed
around task, and a guidance system that ignores boundaries will feel
like it is interrupting, because it will be.

The bottom four go through the vocabulary parser below. The top one —
rewire — is the player editing the pipeline: changing salience weights,
detaching an interface, adding a box. SoraMech has no runtime graph
mutation (its issue 419, rolled back), so a rewire means editing the map
and restarting the run. That's acceptable for a rewire, which is a
considered act, and unacceptable for the other four, which is why the
mechanism below matters.

### Parsing freeform into directives

Guidance arrives as words — typed, clicked, or spoken. It becomes a
bounded directive, and the bound is the same one issue 916h defines:
strategy names from mod-playerbots' registry, multiplier names from the
action registry, plus this feature's own focus and stance vocabulary.

Two-stage, because the failure modes differ:

1. **Exact match first.** The fast buttons and a small phrase table
   ("regroup," "back off," "rest") resolve with no model at all. Most
   guidance in practice is one of a dozen things.
2. **Model fallback for the rest.** An inference call that maps freeform
   words onto the bounded vocabulary, validated against the registries
   exactly as 916i validates, and *read back to the player* when it
   isn't confident: "I'm taking that as: everyone stays within earshot
   of Bram. Yes?"

The read-back is not politeness. A misparsed instruction to a family
you can't see is worse than no instruction, and the listener has no
other way to catch it.

### Standing orders and the meaning of silence

The mechanism, from SoraMech's port semantics: a port may have both
call-box producers and read-box predecessors; the consumer takes a
queued value if one is waiting and falls back to the read box when the
slot is empty. A read box is inexhaustible — it can be pulled every lap
forever and never runs dry.

So:

- The **read box holds the standing order**. It is pulled on every lap
  where the player has said nothing.
- A **queued value is the player speaking**. It wins for that fire only.
- **Silence is not absence.** It means the standing order still holds.

That's the whole design, and it comes from the runtime rather than from
code we write. Persisting it is the part that's ours: the standing order
lives in the roster's `standing_order` column (1101a), is written into
the map's read box at session start, and survives logout.

### Ambiguity and refusal

Guidance that doesn't parse is refused out loud, with what was heard.
It is never silently dropped and never guessed at. Per house rules a
fallback is a warning; here the fallback is *acting on a guess about
what someone said*, and the cost lands on characters they care about.

## Implementation Steps

1. The directive vocabulary: focus, stance, mood, task — as a table,
   aligned with 916h's so the two systems speak one language.
2. The exact-match phrase table and the fast-button mapping.
3. The `guidance` port wired from the interface sub-map into the map.
4. Standing-order read box, populated from the roster at session start.
5. Queued-override path, and a test that proves the read box resumes
   after the override is consumed — one lap of override, then back.
6. The model fallback parser, with registry validation and read-back.
7. Refusal path with the heard-text echoed.
8. Guidance history per ward, feeding 1101d's ward-attention weighting.
9. Persist standing orders on change; restore on next session.

## Files to Create

- The vocabulary table and phrase table
- The guidance parser box and source
- The standing-order read box, and the tool that writes it at session
  start

## Open Questions

- Is "mood" real, or is it just a preset bundle of multiplier changes
  wearing a friendly name? A preset is honest and inspectable. A mood
  the model interprets freshly each time is more expressive and less
  predictable — and unpredictable is bad when you can't see the result.
- How does a task get marked done? "Go sell, then regroup" needs a
  completion condition, and completion conditions are how simple task
  systems turn into schedulers. Is there a small closed set of tasks
  with known completion tests?
- Can guidance address the family as a whole, or only wards
  individually? "Everyone back off" is the most natural thing a listener
  will say, and it is either a broadcast or a compound directive.
- What happens when guidance contradicts a standing order? Override for
  this fire and keep the order, or treat the contradiction as an implied
  edit to the order? The first is safer; the second is what people
  actually mean when they say "no, stop doing that."
- Should the player be able to guide the *voice* as well as the wards —
  "less detail," "only tell me about Tessa"? That's the rewire altitude,
  but it's the one players will reach for constantly, and requiring a
  map edit and a restart for it is going to feel wrong.
- Speech input: does an ASR pass happen before this parser, producing
  text, or does the guidance port carry audio? Text, almost certainly,
  but it means transcription errors arrive as ordinary parse failures
  and the refusal message has to make that legible.

## Related

- Parent: [1101 - Bellwether](1101-bellwether-attended-play.md)
- [1101a - Family enrollment](1101a-family-enrollment-and-persistence.md)
  — owns the `standing_order` column
- [1101m - Applying guidance](1101m-applying-guidance-to-wards.md) —
  what happens to a parsed directive
- [916h - Guidance prompt builder](916h-guidance-prompt-builder.md) —
  the directive vocabulary to align with
- [916i - Response validator](916i-response-validator-and-directive-apply.md)
  — the registry validation to reuse
- [609 - Gesture command system](609-gesture-command-system-kneel-convoy.md)
  and [607 - Player bot behavior commands](607-player-bot-behavior-commands.md)
  — existing in-game command vocabularies; guidance should not become a
  third unrelated way to tell a bot what to do
- `notes/wow-chat-secretary-2` — *"An LLM should have levers to pull,
  not timestamps to clobber and crush."*
</content>
