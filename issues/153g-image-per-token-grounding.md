# 153g - Image-Per-Token Grounding

## Status
- Created: 2026-09-03
- Phase: 1
- Parent: 153
- Depends: 153f (a voice to ground), 916d (Ollama HTTP client), 916e (effil
  worker pool)
- Priority: Low in build order, high in interest — this is the research the
  profile exists to host.

## Origin

> it should be imagining stable-diffusion generated images of the plant or
> mineral and used as input so that it knew what it was looking at. Just, one
> after another, a new one for each token of output. Yes this means slowing
> down the output phase, but it means more accurate results throughput.

## The Direction, Corrected

Recorded because the first draft of this file had it backwards, and the
direction is the whole design. Corrected 2026-09-04:

> it is supposed to take the image and plant name together and generate text
> descriptions of it. So, we need to supply the image, which we can get from
> looking at screenshots on wowhead.

**Image and name go in together; text comes out.** The image is not an
enhancement bolted onto a text pipeline, and there is no version of this
without it — describing the plant *is* describing the picture. And the picture
is **supplied**, not invented: real screenshots of the actual node as it appears
in the actual game.

That correction quietly answers the largest doubt the first draft raised. It had
asked what a diffusion model could possibly know about Peacebloom, a fantasy
object with no real referent, and worried that asking for one would produce a
generic white flower or something from a different game. With supplied
screenshots the question does not arise. The plant in the picture is the plant
the player is standing in front of.

## The Idea, Stated Plainly

A language model asked to describe Peacebloom is working from the word
"Peacebloom" and whatever it absorbed about plants. It has no picture. So it
produces something plausible — broad leaves, stores energy, grows in
meadows — and plausible is the failure mode 153f identifies.

This proposal gives it a picture. Before it writes, a diffusion model renders
what Peacebloom looks like, and that image goes in as visual input, so the
description is of *something* rather than of a word.

Then it goes further, and the further part is the actual idea: **a new image
for every single token.** Token one is written while looking at one imagined
Peacebloom. Token two is written while looking at a different one. Token forty
sees a fortieth.

## Where The Pictures Come From

Two sources, and the project already has working extraction for one of them.

**Wowhead screenshots**, as the brief says: the node photographed in the world,
at the scale and lighting a player meets it, which is exactly the thing being
described. Community-contributed, several per node for the common ones, fewer
or none for the obscure.

**The client, which is already on this machine.** `client/client-files/Data/`
holds the full archive set, and pulling art out of it is solved — the
death-knight spec icons for issue 502 were extracted from `locale-enUS.MPQ`
with `mpyq` and decoded with Pillow's BLP support, and `src/tools/spell-icon-spec-match.py`
does it. Node *icons* are trivially available that way. Node *models* are M2
files and need a renderer, which is real work, but the payoff is arbitrarily
many angles of the exact asset rather than however many screenshots exist.

Start with Wowhead because it is immediate and the images are of the thing in
situ. The client route is the fallback for anything Wowhead is thin on, and the
better answer if the resampling loop turns out to need more images than exist.

**This changes what the resampling is sampling.** The original design drew
fresh images from a generative model, so the variation was the model's
uncertainty and the marginalisation averaged out its hallucinations. Supplied
screenshots vary for a different reason — angle, time of day, terrain, what
else is in frame — and averaging over *that* is arguably better: it isolates
what is true of the plant from what is true of where somebody happened to be
standing. But there are finitely many, and how the loop behaves when it runs
out is an open question below.

## Why That Would Work

Not obvious at first, and worth writing down properly, because the expense only
makes sense if the mechanism is real.

A single generated image is one sample from a distribution. Everything in it is
a mix of two kinds of feature: things that are true of Peacebloom, which appear
because the diffusion model learned them; and things that are true of *this
render*, which appear because a particular noise seed put them there. A
description written from one image cannot tell those apart, and will confidently
report the accident — the way this one leans, the particular five petals this
sample happens to have.

Resample the image at every token and the accidents stop being able to
accumulate. A feature that survives from token to token is one that keeps
appearing across independent draws — which is to say, one the diffusion model
actually believes about Peacebloom. A feature that was a one-render accident is
gone by the next token and never gets written down, because writing it down
takes more than one token.

So the loop is a **marginalisation over the visual prior**: it integrates out
the seed. What comes through is what is stable across samples. That is a real
statistical mechanism, not a vibe, and it is the reason the brief's claim —
slower output, more accurate throughput — is coherent rather than a trade of
speed for nothing.

It also has a natural failure mode that is worth predicting: features which are
stable across samples because they are *stereotypes* rather than facts survive
just as well as true ones. The loop makes the description faithful to the
diffusion model's beliefs. Whether those beliefs are faithful to a real plant is
a separate question this design does not answer, and the WoW plant is a fantasy
object with no real referent anyway.

## What It Costs

The honest accounting, because it is severe.

**Per token: one diffusion render plus one vision-language forward pass.** A
forty-token line is forty renders. On consumer hardware a small SD render is
somewhere between a fraction of a second and several seconds, so a single
sentence is tens of seconds of GPU work.

**The cache costs nothing, once the image is placed correctly.** A transformer
reuses its key-value cache for the prefix of the context; everything from an
edit onward must be recomputed. An image sitting at the *front* and changing
every step therefore invalidates everything, every step, and generation becomes
quadratic in tokens on top of the render cost.

That is an artefact of the placement, not of the idea. Decided 2026-09-03:

> it should go at the point in context when it's referenced. It may be
> referenced more than once, but that's when it should be provided. This should
> apply everywhere we can.

Placed at the point of reference — which, during generation, is the frontier —
the invalidated span is the tail that was about to be computed anyway. The
quadratic disappears and the only remaining cost is the renders. The general
principle and its other applications are written up in
`docs/context-placement.md`; what follows is what it means here.

**But almost all of it hides behind a pipeline.** Image N+1 can render while
token N is being produced. If render time and step time are within an order of
magnitude of each other, the wall-clock cost collapses to roughly the larger of
the two per token rather than their sum. The project already has the machinery
for this: three Ollama machines on the LAN, an effil worker pool, and a design
principle that the worldserver tick never blocks on inference.

**And this is the one profile where the latency does not matter.** Nothing in
explore is on a global cooldown. There is no combat, no rotation, nothing timed.
A bot that takes forty seconds to compose a sentence about a plant is not late
for anything. That is not a rationalisation — it is why this belongs in this
profile and nowhere else.

## Where The Image Goes

Not at the front, and not on a fixed per-token schedule. **At each point in the
text where the plant is being referred to**, and again at the next one.

This changes what the loop is. The brief's original shape was one image per
output token; the placement rule makes it one image per *mention*. A line that
points at the plant four times gets four fresh looks. A line that points once
gets one. The resampling rate becomes a property of the sentence rather than a
constant, which is both cheaper and better aimed — each sample lands exactly
where it is used rather than being averaged across text that is not about
looking at anything.

It costs nothing in cache terms, for the reason above: a reference during
generation is at the frontier, so splicing an image there invalidates only what
was about to be computed.

### The chicken-and-egg, and the way out

You cannot place content at the references until the text exists, and the text
is what you are generating. Three ways out, worst to best:

1. **Two passes** — draft, find the references, regenerate with images at them.
   Doubles the cost, and the second pass may not put its references where the
   first one did.
2. **Detect during streaming** — watch the output and insert when a reference
   seems to be starting. Needs a detector that is right often enough, and it
   inserts a beat late by construction.
3. **Let the model ask.** Give it a marker it can emit meaning *show me that
   again*. The runtime intercepts the marker, renders, splices the image in at
   exactly that position, and continues generating. The reference is what
   emitted it, so it is reference-driven by construction; it lands at the
   frontier, so invalidation is free; and no detector has to guess.

**Three is the design.** It also makes the whole thing legible when it goes
wrong: the markers are visible in the raw output, so a line that came out bad
can be read back to see how many times the model actually looked.

The marker is stripped before the line reaches the validator in 153f, and it
must be — a marker that survives into chat is the single most obvious way this
feature can embarrass itself.

## Intended Behavior

```
bot stands near a node
      │
      ▼
node name from gameobject_template        the only ground truth in the chain
      │
      ▼
render queue starts producing images of that subject, continuously
      │
      │
      ▼
generation runs; model emits a look-again marker when it refers to the plant
      │
      ▼
runtime intercepts the marker, takes the next ready image, splices it in
AT THAT POSITION, and continues
      │
      ▼
context = [prompt, tokens 0..k, image, tokens k+1..]   <- image at the reference
      │                                                   not at the front
      ▼
(loop until the line ends or the player walks away)
      │
      ▼
validator (153f's prohibition) → emit or discard
```

Two properties of that diagram are load-bearing. The render queue runs *ahead*
of generation, so a token never waits on a render that has not started. And the
loop is abandonable — if the player walks away mid-sentence, the whole thing is
dropped, no partial line is emitted, and the render queue is cancelled. A
system this expensive must be cheap to give up on.

## Suggested Implementation Steps

1. **Prove the mechanism offline before building any of it in-game.** Collect
   several Wowhead screenshots of one node — Peacebloom is the obvious
   candidate, common enough to be well photographed. Then generate a
   description two ways: **one image plus the name**, and **a different image
   at each reference plus the name**. Read both. There is no third arm without
   an image, because that is not the design.

   If the multi-image version is not visibly better than the single-image one,
   the resampling loop is answered and nothing downstream of it needs
   building — the profile still gets grounded descriptions from one picture,
   which is most of the value for almost none of the cost. This is the
   cheapest possible test of the only claim the expensive machinery rests on,
   and it should happen before anything else in this issue.

2. **Measure the two clocks.** Render time per image and forward-pass time per
   token, on the actual cluster. Their ratio determines whether the pipeline
   hides the cost or merely reorders it, and it is the number every later
   decision depends on.

3. **Assemble the image library.** One directory per node type, several images
   each, sourced from Wowhead and filled in from the client where Wowhead is
   thin. There are only a few dozen node types in the world, so this is a
   bounded, finite, one-time collection rather than a service — which is a
   large simplification over the original design and removes the need for a
   diffusion endpoint on the cluster entirely. Record where each image came
   from alongside it.

4. **Build the image-ahead queue** in the effil pool (916e), handing out the
   next image for a subject each time the generation loop asks. With a fixed
   library this is a cursor over a list rather than a render farm, and the
   whole GPU-side cost of the original design disappears — what remains is the
   vision-language forward passes.

5. **Build the marker-driven splice loop.** Teach the model the look-again
   marker in its prompt, watch the output stream for it, and on each one splice
   the next ready image into the context at that exact position before
   continuing. This is the part no off-the-shelf serving stack offers, because
   they are all built to keep the context immutable. Expect to drive the model
   below the chat-endpoint level. Strip the markers before the text goes to
   153f's validator.

6. **Cache aggressively at the species level.** There are on the order of a
   few dozen herb and ore node types in the world, not thousands. Once a good
   line exists for Peacebloom, the expensive path never needs to run for
   Peacebloom again. This turns a per-encounter cost into a one-off, and it is
   probably what makes the whole thing shippable — see Open Questions, because
   it also removes most of the reason to run the loop live.

## Affected Files (anticipated)

- a diffusion client alongside `916d`'s Ollama HTTP client
- the render-ahead queue in the effil worker pool
- a low-level generation driver, since the per-token image swap is below what
  a chat endpoint exposes
- `916f`'s cluster health rotation, extended to render hosts
- a species-level line cache

## Related Documents

- `docs/context-placement.md` — the general principle this issue's placement
  decision comes from, and its other applications

## Related Issues

- **916d** Ollama HTTP client — the existing pattern for talking to the cluster
- **916e** effil worker pool — where this runs so the tick does not block
- **916f** cluster health rotation — must learn about render hosts
- **153f** the voice being grounded
- **904** embedding-based creature selection — the project's other piece of
  learned-representation machinery, worth comparing approaches with

## Open Questions

- **Does step 1 actually show a difference?** Everything here is downstream of
  a claim that has not been tested. Test it before building any of it.
- **If species-level caching works, does the live loop still have a purpose?**
  A few dozen node types, each described once, cached forever — that is a batch
  job run overnight, not a live system. The live loop only earns its keep if
  descriptions should vary per encounter, per season, per player, or per
  individual plant. Decide what the variation is *for* before building the
  machinery that provides it.
- **Which vision-language model, and does the cluster have the VRAM?** The
  three LAN machines were sized for text inference. A VLM is a different
  budget, though a smaller one now that no diffusion model needs to be resident
  beside it.

- **What happens when the images run out?** A node with three screenshots and
  a line that refers to the plant six times either cycles back to the first
  image or stops resampling. Cycling reuses a sample, which weakens the
  averaging argument — the accidents in that image get a second vote. Stopping
  means later references are ungrounded. A third option is to generate
  variations from the real screenshots with img2img, which brings the
  diffusion model back but anchored to truth rather than inventing from a
  word — the best of both, and the most work.

- **How many screenshots exist for the obscure nodes?** Peacebloom is
  photographed constantly. Something like Ghost Mushroom or a Rich Thorium
  Vein may have one image or none. The design has to degrade to the
  single-image path for those without anybody noticing a difference in
  quality, or the profile is inconsistent in a way players will spot.
- **How many looks before the marginalisation actually averages anything?**
  The argument needs enough independent samples for a one-render accident to
  fail to recur. Under reference placement the sample count is the number of
  times the line refers to the plant, not the token count — so a one-sentence
  line in 153f's voice might get two looks, which averages almost nothing. This
  is a real tension between 153f wanting short lines and this issue wanting
  many references, and it should be settled by writing a line in the target
  voice and counting its references before either is built.
