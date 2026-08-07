# 1101h - The Explaining Voice: Prompt and Persona

## Status
- Created: 2026-08-01
- Parent: Issue 1101 (Bellwether — attended play)
- Phase: 11
- Priority: Medium-High (this is where the feature becomes pleasant)
- Depends on: 1101c (facts), 1101g (somewhere to send the prompt)

## Overview

Turns a group of facts into a sentence a person can act on without
looking at anything.

The request says the system "explains and guides." Those are two
different verbs and this issue owns the first. Explaining means saying
*why*, not just *what* — "she's losing because two more came in from the
ridge" rather than "health 22%." A listener who is driving cannot infer
the why from the what; if the sentence doesn't carry it, it isn't there.

## Current Behavior

1101e's composer produces templated sentences: correct, complete,
toneless, and identical every time. Fine as a floor. Not something a
person wants in their ear for an hour.

## Intended Behavior

### What the prompt contains

- **The fact group** — words and numbers, already resolved by 1101c.
- **The standing order** — what the player last told this ward to do.
  The explanation should be framed against their intent: if they said
  "stay together," then a ward drifting apart is *news*; if they didn't,
  it's a detail.
- **What was said recently** — so the voice doesn't repeat itself, and
  so it can say "still" and "again," which are among the most
  information-dense words available to it.
- **The ward's persona** — see below.
- **The listener's situation** — the session declares how much attention
  the listener has (driving, second screen, at the desk). The same facts
  want different sentence lengths at different attention levels.

### What the prompt forbids

Stated in the system prompt, and enforced structurally by 1101i:

- No name that isn't in the fact set
- No number that isn't in the fact set
- No speculation about what will happen
- No advice unless a fact supports it
- No filling silence — if there is nothing worth saying, say nothing

The last one is genuinely hard for small models and is the most
important. A model asked to narrate will always narrate.

### Persona

Each ward has a voice that stays the same across sessions, so a listener
can tell who is being talked about before the name arrives. Persona
here is *how this ward is described*, not how the ward talks — the
listener is hearing an account of her, not her.

Issue 916k already specifies a persona table for bot chat, keyed by
character guid, holding a short archetype seed and an origin story.
Reuse it rather than building a second one; a ward that speaks in-world
through mod-soren-chat and is described here should be the same person
in both.

### Register

Worth deciding explicitly because it colours everything: the voice is
someone in the room with you telling you what your family is up to. Not
a sports announcer, not a dungeon master, not a status readout. Short
sentences. Names first. Ordinary words.

## Implementation Steps

1. Write the system prompt with the constraint list and the fact-set
   framing. Keep it short — the constraints matter more than the flavour
   for a small model.
2. The prompt builder box: fact group, standing order, recent
   utterances, persona, attention level → prompt string.
3. Recent-utterance memory, per ward, bounded — a handful, not a
   transcript.
4. Hook the persona table from 916k; generate lazily on first use with a
   neutral placeholder in the meantime.
5. Attention levels as a session setting, with a sentence-length target
   per level.
6. Iterate against real fact groups. This is prompt work: dump twenty
   real groups, generate, read them out loud, adjust. Out loud matters —
   a sentence that reads well and hears badly is the failure mode.
7. Test the hardest case deliberately: a group of low-salience facts
   where the correct output is nothing at all. Measure how often the
   model says nothing when nothing is the answer.

## Files to Create

- The prompt builder box and its source
- The system prompt, in its own file so it can be diffed and reverted

## Open Questions

- Does the voice speak about the wards, or as them? "Tessa's in trouble"
  versus "I'm in trouble." The parent's framing is *watching after* a
  family, which implies about. But a family of five all speaking for
  themselves is a livelier thing to listen to, and issue 916k already
  gives them voices. This may be a per-session interface choice rather
  than a fixed answer.
- How does the voice handle a ward it has said nothing about for twenty
  minutes? Silence about her is information, but only if the listener
  can distinguish it from the system having lost her.
- Do standing orders belong in the prompt at all, or does mentioning
  them bias the model toward reporting compliance rather than reality?
- Second-person or third? "She's" versus "Tessa's" — a listener with one
  ward wants pronouns; with five, they need names every time.
- Should the explanation ever ask a question back? "She's about to pull
  a second group — want her to back off?" That is the seam between
  explaining and guiding, and it may be where the feature actually
  lives.

## Related

- Parent: [1101 - Bellwether](1101-bellwether-attended-play.md)
- [916k - Chat prompt and persona](916k-chat-prompt-and-persona.md) —
  the persona table to reuse, and the prompt-design precedent
- [916h - Guidance prompt builder](916h-guidance-prompt-builder.md) —
  the sibling prompt builder; its notes on small-model behaviour apply
  here unchanged
- [1101i - Utterance validator](1101i-utterance-validator.md) — enforces
  what this prompt asks for
- [1101l - Guidance capture](1101l-guidance-capture-and-standing-orders.md)
  — supplies the standing order this frames against
- [910 - Wandering narrator system](910-wandering-narrator-system) — the
  in-world narrator; different audience, same craft problem
</content>
