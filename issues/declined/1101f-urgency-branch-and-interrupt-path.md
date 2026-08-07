# 1101f - The Urgency Branch and the Interrupt Path

## Status
- Created: 2026-08-01
- Parent: Issue 1101 (Bellwether — attended play)
- Phase: 11
- Priority: High (this is the half of the feature that has to be fast)
- Depends on: 1101e (the map to put the branch in)

## Overview

Some things cannot wait for a language model. A ward at a sliver of
health, a ward dead, a ward stuck for ten minutes — the listener needs
to hear those now, in a fixed form, with no inference between the fact
and their ear.

This issue adds the `comparator` branch that splits the lap into a fast
path and a slow path, and defines what qualifies for the fast one.

## Current Behavior

Every fact group takes the same path through the map at the same speed.
After 1101e that path has no model in it and is fast by accident. As
soon as 1101g lands, every utterance waits on inference, and the
accident becomes a defect.

## Intended Behavior

### The split

A `comparator` routing box on the fact group's urgency value. Above the
threshold, the group leaves by the alarm port; below, by the narration
port. SoraMech's comparator routing requires the `else` port to be
handled explicitly or the runner refuses to start the map — which is the
correct behaviour and worth not working around.

### What takes the alarm port

Conditions, not scores — the threshold exists so the table below is
expressible, not so a tunable number decides matters of life and death:

| Condition | Why it can't wait |
|-----------|-------------------|
| A ward died | the most important thing that happens to a family |
| A ward below the critical health band, falling | seconds decide it |
| A ward is stuck | every minute unaddressed is a wasted minute |
| A ward has been idle far past the idle threshold | something is wrong that isn't in the fact set |
| The pipeline itself is failing | see below |
| The player asked a direct question | answering slowly is worse than answering plainly |

### The alarm line

Templated, from the fact's own words. Short. Names the ward first,
because a listener with five wards needs the subject before the verb:

> Tessa's down.
> Tessa's at a sliver, and it's still on her.
> Bram hasn't moved in ten minutes.

No model, no cluster round trip, no queue. The alarm path goes straight
from the branch to the interface sub-map.

### The pipeline's own failures are alarms

If the cluster is unreachable, if every host is failing health checks,
if the fact feed has gone stale, if the map has been running with an
empty roster — the listener has to be told, because from where they're
sitting, silence from a broken pipeline is indistinguishable from peace.

This is the house rule about fallbacks applied to a system whose user
cannot see the screen: a fallback is a warning, a warning is an error,
and here an unreported error is a person believing their family is fine.

### Latency budget

State the numbers so they can be tested rather than felt:

| Segment | Budget |
|---------|--------|
| Fact extracted → alarm branch taken | one lap interval |
| Branch → interface sub-map | immediate, same fire |
| Interface → the player's ear | interface-dependent, declared by each in 1101j |

The alarm path shares no box with the inference path, so a saturated
cluster cannot delay it. That is the structural guarantee this issue
exists to make, and the test below is what proves it.

## Implementation Steps

1. Add the `comparator` box to the map, wired from the ingest fanout.
   Handle the `else` port explicitly.
2. Define the alarm conditions as a table in the fact extractor (1101c),
   marking qualifying facts at extraction time rather than
   re-deriving urgency in the map.
3. Alarm-line templates, one per condition. These live wherever 1101e's
   composer templates live — the same knowledge.
4. Wire the alarm port directly to the interface sub-map's entry,
   bypassing everything downstream.
5. Pipeline self-checks as fact kinds: stale feed, empty roster, all
   hosts down. They enter the same ledger and take the same branch.
6. **The test that matters**: saturate the cluster with slow inference
   requests, then kill a ward. Measure the time from death to alarm. It
   must be within one lap interval and must not move when the cluster is
   loaded.

## Files to Create

- Alarm condition table and templates (alongside 1101c and 1101e's
  composer)
- The comparator box JSON
- A load-test script that saturates the cluster, for step 6

## Open Questions

- Should an alarm interrupt an utterance already being spoken? For a
  text interface the question is meaningless; for speech it is the whole
  question. Cutting someone off mid-sentence to say "Tessa's down" is
  correct, and requires the interface sub-maps to support cancellation —
  which means it's a constraint on 1101j, decided here.
- Does an alarm cost budget? If a family is falling apart, every fact is
  an alarm, and the listener gets a stream of them. There is probably a
  rate limit even on alarms, and probably a coalescing rule ("everyone's
  in trouble") — but a rate-limited alarm is a suppressed alarm, and
  suppressing an alarm needs to be visible.
- Is "the player asked a direct question" really an urgency condition,
  or does the return path in 1101l own its own reply route entirely?
- How does the alarm path behave when *no interface is attached* —
  session over, player gone? Queue for the catch-up digest, or drop?
  Ten alarms recited on return is not useful; "she died twice while you
  were out" is.

## Related

- Parent: [1101 - Bellwether](1101-bellwether-attended-play.md)
- [1101d - Salience and the event ledger](1101d-salience-and-event-ledger.md)
  — everything below the hard floor is its business, everything above is
  this issue's
- [1101c - Fact extraction](1101c-fact-extraction-aided-by-data.md) —
  marks facts as alarm-qualifying
- [1101j - Interfaces as sub-maps](1101j-interfaces-as-submaps.md) —
  inherits the cancellation requirement
- [406 - Death durability system](406-death-durability-system) and
  [806 - Proximity raid system](806-proximity-raid-system.md) — what
  death costs, which is what makes a death alarm worth interrupting for
</content>
