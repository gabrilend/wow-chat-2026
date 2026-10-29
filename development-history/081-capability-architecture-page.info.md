# 081-capability-architecture-page

## What made it
- scripts/generate-capability-architecture-page, then the page photographed headless (photographed: headless Firefox, 1400x1000, file:///mnt/kaun/wow-chat-2026/docs/HTML/capability-architecture.html)
- Commit: c63ad4f (with uncommitted changes to its sources)
- Filed: 2026-10-29 16:31 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `docs/capability-architecture.md` | 7c50203e406b34f9 |
| `scripts/generate-capability-architecture-page` | 6056df4d1f348fd7 |

## What changed since the previous picture
- `docs/capability-architecture.md`: first picture that names it
- `scripts/generate-capability-architecture-page`: first picture that names it

## What it shows
he first page of the architecture of capabilities
(docs/HTML/capability-architecture.html, 1400 by 1000, light theme), before
the patterns and guidance were added: a contents rail on the left (the core
rule, the shape, the contracts, the method, the capabilities ring by ring
with the seven rings listed under it, where the rings are thinnest, keeping
the document true); the title "The Architecture of Capabilities: Concerns
That Cooperate, Ambitions to Be Wrong" in a condensed display face; the
owner's question quoted, and "][tests]["; then the drawing: seven
concentric rings in soft tints, labelled from GROUND at the centre to
OPERATIONS at the edge, each separated by a dashed gold circle (the tests),
"][tests][" in gold at the centre, and a key: "the tests, in every seam;
each ring uses the one inside it, and never overrides it".

## The story so far
n 2026-10-29, after the design target (the next compile builds every
described issue) and the board, the owner asked for an architecture that
organizes every capability "into a structure that cooperates on concerns
and ambitions to be wrong", then sent "][tests][". The document was written
(seven rings, tests at the seams, nine contracts, the method), then this
page made from it by a generator and published as an artifact; the patterns
and the guidance for each section were added next.
