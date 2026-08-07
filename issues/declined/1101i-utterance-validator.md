# 1101i - Utterance Validator

## Status
- Created: 2026-08-01
- Parent: Issue 1101 (Bellwether — attended play)
- Phase: 11
- Priority: High (this is the safety property, not a nicety)
- Depends on: 1101c (the fact set defines what's licensed), 1101h

## Overview

Enforces the contract the whole feature rests on: **the narrator may
only speak facts it was handed.**

The listener cannot see the screen. They have no way to catch the model
being wrong. A model that invents a creature, a number, or a death is
not adding colour — it is lying to someone about characters they care
about, in a situation engineered so they can't check.

Prompt instructions are not enforcement. This box is enforcement.

## Current Behavior

Nothing checks generated text. 1101h asks the model to behave; small
models frequently don't.

## Intended Behavior

### The check

Every utterance arrives paired with the fact group that produced it
(the wire value is a pair, per 1101g's open question). The validator
extracts every proper noun and every number from the utterance and
requires each to appear in the union of that group's `text_fragments`
and `numbers`.

| Utterance contains | Licensed by | Verdict |
|---|---|---|
| "Tessa" | a fact's `ward` | pass |
| "Defias Pillager" | a fact's `text_fragments` | pass |
| "a third" | a band phrase from a licensed ratio | pass |
| "Westfall" | an `arrived` fact's fragments | pass |
| "Hogger" | nothing | **reject** |
| "four of them" | no fact licensed the count four | **reject** |
| "she'll be fine" | prediction, no fact | **reject** |

Numbers need care: the fact set licenses `health_pct = 38`, and the
utterance says "a third." Band phrases are licensed by the band the
number falls in, so the mapping from number to permitted phrase lives
alongside 1101c's band definitions — the same knowledge again, and it
should not be written twice.

### On rejection

1. **Retry once**, with the failure named: which token was unlicensed.
   Small models often fix a specific complaint they wouldn't have
   avoided in general.
2. **On second failure, fall back to the composer** from 1101e. The
   listener gets a plain templated sentence built from facts alone.
   Correct, dull, true.
3. **Log the fallback as a warning.** House rules: prefer error messages
   and breaking functionality over fallbacks, notify every time a
   fallback is used. A silent fallback here would hide exactly the
   signal that says the model or the prompt is wrong.

The fallback rate is a first-class metric, surfaced in 1101n. If it
climbs, either the model is too small or the prompt has drifted, and
nobody would notice from the output alone — a templated line and a
generated line sound similar enough to a listener that only the counter
tells the difference.

### What the validator does not do

It does not check that the utterance is *good*, *relevant*, or *well
phrased*. It checks that every specific claim traces to a fact. A dull
but licensed sentence passes. That division keeps this box cheap and
deterministic, which is what lets it sit in the hot path.

## Implementation Steps

1. Tokenizer: extract capitalized tokens and numeric expressions,
   including written numbers ("three," "a third," "half").
2. The licensing check against a fact group's fragments and numbers.
3. The band-phrase mapping, shared with 1101c rather than duplicated.
4. A stop-list of always-permitted tokens — sentence-initial capitals,
   the listener's own name, the family name, common words that happen to
   be capitalized. Keep it short and explicit; every entry is a hole.
5. Retry-once with the specific complaint.
6. Fallback to the composer, plus the warning log and the counter.
7. Tests: a corpus of generated utterances, hand-labelled, asserting the
   verdict. Include the nasty cases — a real creature name that is not
   in *this* fact group, a correct number the facts didn't license, a
   plausible prediction.
8. Adversarial pass: prompt a small model with a fact group designed to
   invite invention (one enemy, vague) and count how often it invents.
   That number is the argument for this box existing.

## Files to Create

- The validator box and its source
- The labelled utterance corpus for tests

## Open Questions

- Proper-noun detection by capitalization is crude and breaks on
  sentence-initial words and on lowercase creature names. Is there a
  better signal — checking every token against the world-name caches
  from 1101c, and rejecting any known game name not in this group?
  That's stricter and catches "Hogger" precisely because Hogger is real.
- How strict on numbers? Rejecting "a couple" for a licensed count of
  two would make the voice stilted. Rejecting "four" for a licensed
  three is essential. Where's the line, and is it a table of permitted
  vaguenesses per number range?
- Should a rejected utterance be shown to the operator? Silently
  discarded text is how prompt problems stay invisible. The JSONL
  transcript is the obvious home.
- Does the validator run in the map or before the interface? In the map,
  so every interface inherits it — but that means the retry costs
  another cluster round trip inside the lap.
- What happens if the *composer* can't produce a line either, because
  the fact group has no template? That's a gap in 1101c's kind coverage
  and should be loud.

## Related

- Parent: [1101 - Bellwether](1101-bellwether-attended-play.md)
- [1101c - Fact extraction](1101c-fact-extraction-aided-by-data.md) —
  defines what is licensed, and owns the band definitions
- [1101e - Map skeleton](1101e-bellwether-map-skeleton-and-fanout.md) —
  the composer that is fallen back to
- [1101h - The explaining voice](1101h-explaining-voice-prompt-and-persona.md)
  — asks for what this enforces
- [916i - Response validator and directive apply](916i-response-validator-and-directive-apply.md)
  — the sibling validator; it validates *structure* against a registry,
  this one validates *content* against a fact set. Different jobs, and
  the retry-once-then-fall-back shape should match
</content>
