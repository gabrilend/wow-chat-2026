# 1101c - Fact Extraction, Aided by Data

## Status
- Created: 2026-08-01
- Parent: Issue 1101 (Bellwether — attended play)
- Phase: 11
- Priority: Highest of the sub-issues (this file decides whether the
  whole feature tells the truth)
- Depends on: 1101b (consumes snapshots)

## Overview

This is the "aided by data" half of the request, and the reason the
feature can be trusted.

A snapshot says `target_entry = 1234, health = 412, health_max = 980`.
That is meaningless to someone driving to work. Joined against the
world database it becomes *"a Defias Pillager, two levels above her, and
she's at two fifths."* No model was involved in that transformation, and
that is the point: the interpretation happens in a join, not in an
inference.

The model that comes later chooses which facts to say and how to phrase
them. It does not get to know anything the join didn't hand it.

## Current Behavior

Nothing turns game IDs into words for external consumption. Every system
in the project that needs a creature name today looks it up ad hoc at
the call site.

## Intended Behavior

### A fact

The output unit is a **fact**: a small typed record that is true at a
moment, already carrying its own words.

| Field | Type | Meaning |
|-------|------|---------|
| `kind` | string | which fact this is — a bounded enum, see below |
| `ward` | string | ward's name, already resolved |
| `at` | int | server ms |
| `text_fragments` | list of string | the resolved words — names, places, adjectives |
| `numbers` | table of name → number | every number this fact licenses |
| `urgency` | int 0–100 | how loudly this wants to be said, before salience decides |

Two properties matter:

- **A fact is already in words.** No downstream stage performs a lookup.
  If a name isn't in `text_fragments`, nothing downstream may say it.
- **A fact licenses its numbers.** The validator in 1101i checks
  utterances against the union of `text_fragments` and `numbers` across
  the facts that produced them. A number nobody licensed is a
  hallucination, regardless of how plausible it sounds.

### The fact kinds

A bounded vocabulary, extended deliberately rather than accidentally.
The first pass:

| Kind | Fires when | Joins against |
|------|-----------|---------------|
| `engaged` | ward entered combat | `creature_template` for name, rank, level |
| `hurt` | health crossed downward past a band | — |
| `recovered` | health crossed upward past a band | — |
| `killed` | ward killed something | `creature_template` |
| `died` | ward died | `creature_template` for what killed them |
| `levelled` | level increased | — |
| `looted` | items acquired | `item_template` for name, quality |
| `arrived` | zone or subzone changed | `areatable` / zone names |
| `idle` | no state change for N minutes | — |
| `stuck` | position unchanged while trying to move | — |
| `broke` | durability crossed a floor | `item_template` |
| `poor` | bags full, or out of money for repair | — |
| `alone` | separated from the rest of the family | — |

Every kind is a join or a threshold — nothing requires judgement. The
judgement is 1101d's job.

### Relative, not absolute

Facts should be phrased relative to the ward wherever a listener would
think relatively. "Two levels above her" is actionable; "level 22" is
only actionable if you remember she's 20. So the extractor resolves:

- Enemy level → relative to ward level, plus the rank word (normal,
  elite, rare)
- Health → bands (full, most, half, a third, a sliver), plus the ratio
  in `numbers` for anything that wants precision
- Distance → in words a listener can use (right there, across the
  clearing, a zone away)
- Time → since, not at ("she's been fighting for a minute and a half")

The absolute values stay in `numbers` so nothing is lost.

### The joins

Reads against the active profile's world database:

| ID | Table | Wanted |
|----|-------|--------|
| creature entry | `creature_template` | name, subname, rank, min/max level |
| item entry | `item_template` | name, quality, item level, class |
| zone / area | `areatable` (DBC-derived) | zone name, subzone name |
| spell id | `spell_template` or DBC | name, if spells become facts |

These are static per world build. Cache them at load, in a table keyed
by ID, rather than querying per fact — the extractor runs on every lap
forever, and the world database does not change under it.

## Implementation Steps

1. Build the lookup caches at ALE load: creature names, item names, zone
   and area names. Report the count of each at startup so a missing or
   empty table is loud rather than silent.
2. Implement the fact struct and the kind enum.
3. Implement the diff: two snapshots in, a list of facts out. Start with
   `engaged`, `hurt`, `killed`, `died`, `arrived` — the five that carry
   most of the value.
4. Add the relative-phrasing resolvers (level, health band, distance,
   elapsed) as small pure functions with their own tests. These are the
   pieces most likely to be reused and most likely to be subtly wrong.
5. Add the remaining kinds.
6. Serialize facts to the format 1101e's ingest box reads.
7. Tests: a fixture pair of snapshots per fact kind, asserting the exact
   facts produced. These are cheap and there should be many — one per
   kind, plus the boundary cases on every threshold.
8. A test that asserts no fact carries a name that isn't in its own
   `text_fragments` — the contract 1101i depends on, checked at the
   source.

## Files to Create

- ALE Lua fact extractor module
- ALE Lua lookup-cache module
- Test fixtures: snapshot pairs per fact kind

## Open Questions

- Where do zone and subzone names come from on this server? `areatable`
  is DBC-derived and the wiki docs describe it, but confirm the project
  has it loaded and queryable rather than assuming.
- Health bands: how many, and where are the edges? Bands are what makes
  `hurt` fire at all, so the edges are a balance knob and probably
  belong in `docs/balance-updates.md` once they start moving.
- Should a fact carry *why* as well as what? "She's hurt" versus "she's
  hurt because three of them came at once." The why is often a second
  fact rather than a field — but a listener wants the causal pair, and
  pairing them is either the extractor's job or the voice's (1101h).
- Do facts about the *family as a whole* exist — "they've drifted
  apart," "everyone's out of mana" — or is a family-level fact just a
  ward-level fact for each ward, deduplicated later? Family-level facts
  are more useful to a listener and more work to extract.
- How does this interact with issue 907's language barriers? If a ward
  cannot understand something in-world, should the listener?

## Related

- Parent: [1101 - Bellwether](1101-bellwether-attended-play.md)
- [1101b - Ward state reader](1101b-ward-state-reader.md) — the input
- [1101d - Salience and the event ledger](1101d-salience-and-event-ledger.md)
  — the consumer, which decides which of these facts get said
- [1101i - Utterance validator](1101i-utterance-validator.md) — enforces
  the contract this file establishes
- [904 - Embedding-based creature selection](904-embedding-based-creature-selection.md)
  — the other system that cares about what a creature *is* rather than
  what its entry number is; may share the creature-name cache
- `docs/wiki/docs/creature_template.md`, `docs/wiki/docs/areatable.md` —
  the schemas being joined against
</content>
