# Context Placement

*Put a thing where it is referred to. If it is referred to twice, put it there
twice.*

Directive, 2026-09-03:

> it should go at the point in context when it's referenced. It may be
> referenced more than once, but that's when it should be provided. This should
> apply everywhere we can.

## The Rule Already Exists Here, For Source Code

This is not a new idea in this project. The coding standard already says it,
about comments:

> if information about data formatting or other relevant considerations about
> data are found, they should be added as comments to the locations in the
> source-code where they feel most valuable. If it is anticipated that a piece
> of information may be required to be known more than once, for example when
> updating or refactoring a section of code, the considerations must be written
> in as comments

That is the same rule: the fact lives next to its use, and it is repeated
wherever it is used again rather than being stated once at the top and
referred back to. What follows extends it from source files, where the reader
is a person, to model contexts, where the reader is a transformer. The reason
it works turns out to be nearly the same in both cases.

## Why It Works For A Person

A reader who meets a fact where they need it does not have to remember it. A
reader who meets it eight hundred lines earlier has to have kept it, and mostly
has not. A header block full of everything you might later need is a header
block nobody reads twice.

Repetition is the point rather than a cost. The same fact at three call sites
is three readers served. It is only redundancy if you assume everyone reads
from the top.

## Why It Works For A Model

Two separate mechanisms, and they pay off differently.

### Attention has a distance cost

A model attending to a fact adjacent to the token it is writing is doing
something easy. A model reaching back across a thousand tokens of preamble to
recover one number is doing something it can get wrong, and gets wrong more
often the further back the number is and the more things sit between. Placing
the fact at the point of use removes the reach.

### The cache is a prefix, so position decides what survives

This is the mechanical one and it is worth stating precisely, because it is
what makes the rule cheap instead of merely tidy.

A transformer's key-value cache stores computed state for a prefix of the
context. Everything before an edit stays valid; everything from the edit
onward must be recomputed. So the position at which content changes decides
how much work a change costs:

| Where the changing content sits | What must be recomputed |
| ------------------------------- | ----------------------- |
| At the front | everything |
| In the middle | everything from there on |
| At the generation frontier | the tokens you were about to compute anyway |

Content that changes every step and sits at the front makes generation
quadratic in length. The same content at the frontier costs nothing beyond the
step itself. Reference locality and cache economy are the same instruction
here: put the volatile thing where it is used, and where it is used is
generally near where you are.

### The corollary: stable first, volatile at the point of use

The rule has a second edge for prompts that are sent repeatedly. If the
unchanging parts — instructions, vocabulary, persona, schema — sit at the
front, that entire prefix is cacheable across every request that shares it. If
volatile state is front-loaded instead, the shared prefix ends at the first
volatile byte and nothing is reused.

So the practical form is: **stable content first, volatile content at the
point of reference.** Where a volatile fact genuinely is referenced early, that
is a real tension, and the usual fix is to restructure the instruction so the
reference comes later rather than to move the fact forward.

## Applying It

### To generated text with re-supplied context (issue 153g)

The strongest case. A description of a plant is being generated, and the image
of the plant should appear at each point in the text where the plant is being
looked at, not once at the top.

The difficulty is that you do not know where the references are until the text
exists. Three ways out, worst to best:

1. **Two passes.** Generate a draft, find the references, regenerate with
   content placed at them. Doubles the cost and the second pass may not put its
   references where the first did.
2. **Detect during streaming.** Watch the output and insert when the model
   appears to be starting a reference. Requires a reference detector that is
   right often enough, and it is inserting a beat late by construction.
3. **Let the model ask.** Give it a marker it can emit meaning *show me that
   again*. The runtime intercepts the marker, produces the content, splices it
   in at exactly that position, and continues. Reference-driven because the
   reference is what emitted it; frontier-placed because the frontier is where
   the model is; and the invalidated span is the tail that was about to be
   computed regardless.

The third is the recommendation. It also makes the resampling rate a property
of the text rather than a fixed per-token constant — a sentence that mentions
the plant four times gets four fresh looks, one that mentions it once gets one.

### To prompts assembled from game state (issues 916h, 917a, 1101c)

Both existing prompt builders assemble every fact into a block at the front
and then ask the question. Under this rule they should interleave: the party's
health next to the sentence that asks about survivability, the enemy summary
next to the sentence that asks about targeting, the zone next to whatever cares
where you are. A fact used in two places appears in both.

The prefix-caching corollary applies here with force, because these prompts are
sent constantly and share most of their text. The directive vocabulary and the
output schema never change and belong at the front where they can be cached
across every request; the party state changes every time and belongs beside the
questions that use it.

### To documentation

The same rule that produced this file. A concept explained once in an overview
and referenced by name thereafter is a concept most readers will not have. If a
term matters at three points in a document, define it at the first and restate
it in a clause at the other two. The table of contents is for navigation, not
for carrying meaning forward.

## When Not To Apply It

- **When the thing is genuinely stated once and used once.** The rule is about
  repeated reference; a single use has only one place to be.
- **When repetition would contradict itself.** Two copies of a fact are two
  things to keep in step. For anything that changes, either generate both
  copies from one source or accept that they will drift and say so.
- **When the content is enormous relative to its references.** A hundred lines
  of table repeated at four call sites is worse than one table and four
  pointers. The threshold is roughly whether a reader would rather scroll than
  re-read.

## Related

- `CLAUDE.md` — the source-code comment rule this generalises
- `issues/153g-image-per-token-grounding.md` — the case that prompted it
- `issues/916h-guidance-prompt-builder.md`, `issues/917a-what-it-can-see.md` —
  prompt builders that currently front-load and should not
