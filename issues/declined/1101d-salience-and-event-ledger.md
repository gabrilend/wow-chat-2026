# 1101d - Salience and the Event Ledger

## Status
- Created: 2026-08-01
- Parent: Issue 1101 (Bellwether — attended play)
- Phase: 11
- Priority: High
- Depends on: 1101c (consumes facts)

## Overview

A family of five wards generates facts continuously. A person driving to
work can absorb roughly one thing every thirty seconds, and only if it
matters. Something has to choose, and choosing badly is the difference
between a companion and a nuisance.

This issue is the choosing. It is also where the feature most obviously
fails if it's built carelessly, because the failure mode isn't an error —
it's a listener who stops listening.

## Current Behavior

Nothing filters. 1101c emits every fact it finds.

## Intended Behavior

### The ledger

An append-only record of facts that have been extracted but not yet
said. Each entry carries the fact plus:

| Field | Type | Meaning |
|-------|------|---------|
| `score` | float | current salience |
| `first_seen` | int | when the fact entered the ledger |
| `spoken` | bool | whether it made it into an utterance |
| `superseded_by` | fact id or nil | a later fact that made this one moot |

A fact leaves the ledger three ways: it gets spoken, it gets superseded,
or it ages out unspoken. All three are recorded. The count of facts that
aged out unspoken is a health metric — if it's large, either the budget
is too small or the extractor is too chatty, and the ledger says which.

### Scoring

Salience is not a single number pulled from the fact's `urgency`. It's
that, moved by context:

- **Base** — the fact kind's inherent weight. A death outranks a loot.
- **Novelty** — the fifth `hurt` in a minute is worth less than the
  first. Repetition decays.
- **Trend** — a `hurt` that follows a `hurt` that follows a `hurt` is
  worth *more* than any of them alone, because the shape is the news.
  This is the one place where the score goes up with repetition, and it
  is the difference between "she's taking damage" and "she's losing."
- **Boundary** — a fact that lands at a task boundary is worth more than
  the same fact mid-task. The ward has just finished a fight, reached a
  place, run out of something, or otherwise arrived at a moment where a
  decision is due. That is when an explanation is actionable and when
  guidance can actually change what happens next. Between boundaries the
  bot AI is executing and there is nothing to ask about.

- **Ward attention** — a ward the player has recently guided is more
  interesting than one they haven't. They asked about her; tell them
  about her.
- **Age** — most facts decay. A few don't: `stuck`, `poor`, `broke`, and
  `idle` describe conditions rather than events, and a condition that is
  *still true* and *still unaddressed* gets more urgent with time, not
  less. A ward stuck on a rock for ten minutes is a bigger problem than
  one stuck for ten seconds.

The decay-versus-accrual split is the substance of this issue. Getting
it wrong in the decay direction means alarming about ancient news;
wrong in the accrual direction means a ward quietly stuck for an hour.

### The budget

A listener has a rate. The budget is expressed as utterances per minute,
per session, and it is a session setting because it depends on what the
player is doing — driving wants one every couple of minutes; a
half-attentive player at a second screen might want six.

Within the budget, the ledger emits the highest-scoring facts, grouped:
facts about the same ward in the same moment go out together, so the
voice can compose one sentence rather than three.

Above a hard urgency floor, the budget is ignored — that's 1101f's
interrupt path, and this issue's only job there is to mark the fact and
get out of the way.

### Supersession

A `hurt` followed by a `recovered` for the same ward, before either was
spoken, is one fact: she was in trouble and isn't now — and if the
player is busy, possibly zero facts. A `died` supersedes everything
pending about that ward. Supersession rules are per-kind-pair and belong
in a table, not in a chain of conditionals.

## Implementation Steps

1. Ledger structure with insert, score, mark-spoken, mark-superseded,
   and age-out. In memory; the ledger does not need to survive a
   restart, because a stale unspoken fact has no value.
2. A static base-weight table per fact kind — the crude first version,
   which should be shippable on its own.
3. The supersession table, keyed by kind pair.
4. Novelty decay and the condition-accrual exception.
5. Trend detection across same-kind facts for one ward.
6. Ward-attention weighting, fed by 1101l's guidance history.
7. The budget: utterances per minute, grouped emission, and the hard
   urgency floor that bypasses it.
8. Instrumentation: spoken, superseded, and aged-out counts per session,
   surfaced in 1101n. These numbers are how the weights get tuned, and
   the tuning belongs in `docs/balance-updates.md` because it is
   knob-turning, not design.

## Files to Create

- Ledger module (Lua, or a C box if the scoring loop turns out to cost)
- The base-weight and supersession tables — as code structure, not
  runtime data, so a git grep finds them

## Open Questions

- What's the right default budget? This depends on the parent's open
  question about how many wards a person can actually attend, and the
  two numbers should be decided together.
- Does the player set the budget explicitly, or does the system infer it
  from how they respond? An adaptive budget is nicer and much harder to
  reason about when it misbehaves — and per house rules, a system that
  quietly adjusts itself is a system that needs to say so.
- Should the ledger be per-family or per-ward? Per-family lets one
  ward's crisis crowd out another's chatter, which is correct. It also
  means a quiet ward can go unmentioned for a very long time, which may
  read as the system having forgotten her.
- Trend detection needs history. Does that come from the ledger itself,
  or from a snapshot ring in 1101b? The ledger only holds *unspoken*
  facts, so a trend whose early members were already spoken is invisible
  to it — which is probably wrong.
- Is "nothing is happening" itself worth saying? A listener with silence
  in their ear cannot tell the difference between peace and a crashed
  pipeline. A periodic all-quiet may be the most important utterance
  the system makes.

## Related

- Parent: [1101 - Bellwether](1101-bellwether-attended-play.md)
- [1101c - Fact extraction](1101c-fact-extraction-aided-by-data.md) —
  supplies the facts and their base urgency
- [1101f - Urgency branch](1101f-urgency-branch-and-interrupt-path.md) —
  owns everything above the hard floor
- [1101h - The explaining voice](1101h-explaining-voice-prompt-and-persona.md)
  — receives the grouped facts
- [1101n - Session lifecycle](1101n-session-lifecycle-and-observability.md)
  — surfaces the ledger metrics, and owns the catch-up digest, which is
  the ledger read with a completely different budget
- [614 - Activity selection and boredom](614-activity-selection-boredom.md)
  — the existing precedent for weighted selection among competing
  candidate behaviors; worth reading before inventing a second scheme
</content>
