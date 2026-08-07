# 918 - fg-sora-cluster: Three Mirror Companions, One Per Box

## Status
- Created: 2026-08-07
- Phase: 9 (Storytelling & Immersion — sibling of 916 and 917, shares
  their cluster and bindings)
- Depends on: 916 family (Ollama client, effil worker pool, ALE
  bindings for playerbots)
- Priority: Low — this is a want, not a gap. Nothing waits on it.

## Source Report (verbatim, 2026-04-07)

> fg-sora-cluster each one runs a bot that's constantly ollama generating
> thoughts. I only have computers for three, but they'd follow beside me. Each
> one would be configured to look like me, talk like me, but be beside me.
>
> some of them you could tell "two truths and a lie" and they'd coordinate with
> one another. supplying each of their thoughts to each of their contexts, with
> slightly different motions to next be applied upon next.

And, from the continuation of the same note:

> feldowinn, chorus of angels

## What It Is

Three playerbots, one bound to each machine in the Ollama cluster.
Each is built to look like the player's own character and speak in
the player's own voice. They walk beside her. Not behind, not as
pets — beside.

Each bot generates thoughts **continuously** rather than in response
to events. There is no trigger. The bot is always thinking, and the
box it owns is always working on the next thought.

The three are not independent. Each one's generated thought is fed
into the other two's contexts, and each applies a slightly different
transformation before its next generation step. They share what they
think and diverge in how they carry it forward. The result should be
three voices that clearly come from the same person and clearly are
not the same voice.

"Chorus of angels" is the image. Not a party of adventurers, not a
crowd of NPCs — a small number of near-identical presences that are
recognizably you, walking alongside, thinking out loud in parallel.

## How It Differs From 916

916 also uses the three-box cluster, and the overlap is real enough
that it is worth being precise about what is different, because two
of the differences are load-bearing.

| | 916 (mod-soren-chat) | 918 (fg-sora-cluster) |
|---|---|---|
| Persona | One distinct persona per bot, seeded by race/class/spec, stored in `soren_chat_persona` | One persona — the player's — instantiated three times |
| Trigger | Event-driven: proximity hook, player spoke, zone entry, periodic ambient | Continuous. Always generating |
| Box assignment | Round-robin across boxes; any request can go anywhere | One bot pinned to one box, permanently |
| Context | Per-request, built from party state | Shared and cross-fed — each thought enters the others' contexts |
| Purpose | Make companions interesting and their tactics smart | Be beside the player |

The persona inversion matters for the schema: 916k's
`soren_chat_persona` table is keyed one persona per bot GUID, which
this design uses backwards — one persona spanning three GUIDs, plus
per-bot divergence state that 916's schema has no column for.

The continuous-generation difference matters more, and it is the
thing most likely to force a decision. 916's model is that the boxes
sit mostly idle and burst when something happens. This model is that
all three boxes are saturated forever by three bots that never stop
thinking. Those two cannot both be true at once on three machines.
Either 918 runs instead of 916's traffic, or continuous generation
gets a duty cycle, or the cluster grows.

## The Coordination Test

"Two truths and a lie" is not a feature request — it is the
acceptance test, and it is a good one, because passing it requires
everything underneath to actually work:

- **Shared state.** All three have to hold the same three facts. If
  the thought-exchange is not really landing in each other's
  contexts, they will hold three different sets and the game
  collapses.
- **Agreement.** They have to agree on which one is the lie without
  being told. That agreement can only come through the exchanged
  thoughts, so it directly tests the channel.
- **Divergence.** They have to each present it differently. Three
  identical answers means the per-bot transformation is not doing
  anything and the ensemble is just one model queried three times.
- **Turn-taking.** They have to not all speak at once, which tests
  whatever arbitration exists between them.

A system that can play two truths and a lie correctly has a working
shared context, a working divergence mechanism, and working
arbitration. A system that cannot is missing at least one of the
three, and which answer it gets wrong says which.

## The Divergence Mechanism

The phrase from the report — "with slightly different motions to next
be applied upon next" — is the design's core and its least specified
part. What is clear: each bot receives the same pool of thoughts and
applies its own transformation before generating again. What is not
clear is what the transformation is.

Candidates, cheapest first:

- **Sampling temperature.** Same prompt, same context, three
  different temperatures. Nearly free, and produces genuine variation
  without any per-bot state. Probably too shallow to sustain three
  distinguishable voices over a long session.
- **A per-bot lean in the system prompt.** One is the one who
  doubts, one is the one who commits, one is the one who notices.
  Same person, three postures. Cheap, and the divergence is stable
  rather than random.
- **Different slices of the shared pool.** Each bot sees all three
  thoughts but in a different order, or weighted differently by
  recency. The divergence emerges from context construction rather
  than from prompt text.
- **A carried-forward per-bot state vector** that accumulates across
  generations, so the three drift apart over a session and would
  need to be re-synced. Richest, most expensive, most likely to
  produce three bots who stop sounding like the same person.

The first two are enough to build the thing and run the two-truths
test. The last one is the interesting version.

## Looking Like the Player

The visual half is the cheap half and should not be overlooked,
because it is what makes the feature land before anyone says a word.
A playerbot's appearance comes from its character record — race,
gender, and the face/hair/skin fields. Copying the player's values
onto the three bots at spawn time makes them read as her instantly.
Name and equipment are separate decisions: identical names are not
possible, and identical gear may or may not be wanted.

## Suggested Implementation Steps

1. Land enough of the 916 foundation to have a working Ollama client
   and worker pool (916a–916f). This rides on that infrastructure and
   should not build a second copy of it.
2. Decide the resource question — whether 918 and 916 coexist, and if
   so what the duty cycle is. This gates everything else, because
   continuous generation on all three boxes leaves nothing for
   anything else.
3. Spawn three bots with the player's appearance fields copied from
   her character record. Confirm they look right before any LLM work.
   This alone is worth seeing.
4. Pin one bot per box. Unlike 916's round-robin, the binding is
   permanent — a bot's box is part of its identity here.
5. Build the shared thought pool: each bot's generated thought is
   written somewhere all three read from, with recency bounds so the
   context does not grow without limit.
6. Implement the simplest divergence first (per-bot lean in the
   system prompt) and see whether three voices are distinguishable
   over a twenty-minute session.
7. Run the two-truths-and-a-lie test. Record which of the four
   properties above fails, if any.
8. Only then consider the carried-state version of divergence.

## Cross-References

- `issues/916-mod-soren-chat.md` — the cluster, the worker pool, the
  ALE bindings, and the per-bot persona model this inverts.
- `issues/916e-effil-worker-pool.md` — the worker pool. 918's pinning
  requirement is a constraint on it.
- `issues/916k-chat-prompt-and-persona.md` — the persona table that
  does not currently fit one-persona-across-three-bots.
- `issues/917-ask-the-bots-in-plain-text.md` — the other 916 sibling.
  917 is about the player addressing bots in plain language; 918 is
  about bots that are the player. They will want to be aware of each
  other.
- `issues/913-clustered-worldserver.md` — the other cross-machine
  infrastructure issue.
- `issues/declined/1101-bellwether-attended-play.md` and its family —
  the declined design for LLM companions that explain and guide.
  Worth reading for what was rejected there and why, before building
  something adjacent.

## Open Questions

- **What does "fg" stand for?** The name is taken verbatim from the
  report. Like "soren" in 916, it may be a handle rather than a
  description, in which case nothing needs resolving.
- **Do 916 and 918 run at the same time?** Three boxes, and 918's
  continuous generation wants all of them permanently. This is the
  question that decides whether 918 is a mode you switch into or a
  feature that is always on.
- **What happens with more than one player?** Three boxes is three
  bots is one player's chorus. A second player either shares them,
  gets none, or the cluster grows. The report says "I only have
  computers for three," which reads as a single-player-at-a-time
  design.
- **Do they use the player's name?** Three bots named some variation
  of the player's own name is either the whole point or deeply
  confusing in a party frame. Untested either way.
- **What do they do in combat?** The report describes them as
  thinking and walking beside her. Whether they fight, and whether
  their thoughts have anything to do with fighting, is unspecified —
  and if they do fight, 916's guidance layer is the natural way to
  drive it, which pulls the two systems back together.
- **Is "constantly generating" literal?** A 1B model on a dedicated
  box can produce a thought every few seconds indefinitely. Whether
  the player wants a thought every few seconds from each of three
  companions is a separate question from whether the hardware can do
  it.
