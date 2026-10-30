# Answer Pages (dormant)

Issues 1102 and 1102a, built 2026-10-29 and 30, parked 2026-10-30.

## What it is

- **Five pages** (`HTML/`), each one part of the project told as a story
  with five gifs, then every open question its issues ask, with a box to
  answer each: every open question ranked by what it unblocks;
  pathfinding; talents guiding abilities; stand-ins and the army of 64;
  Alterac Valley's weather.
- **The answer server** (`scripts/answer-server`): served the pages on this
  computer and appended each answer, word for word, to
  `notes/answers/<page>.md` (those answers stay in `notes/answers/`, they
  are the owner's words).
- **The page generator** (`scripts/generate-answer-pages`): wrote the
  pages from the stories (`stories/`) and the issue files' Open Questions.
- **The context writer** (`scripts/write-question-contexts`): grouped all
  of the project's questions (452 groups) in walkthrough order and had a
  writer session explain each group, one at a time, each knowing what the
  ones before it explained, key terms marked by kind. Three trial contexts
  are in `stories/contexts/`.
- **The answer filer** (`scripts/file-answers`): copied each answer into
  its issue under its question, word for word (`notes/answers/filed.txt`
  lists those copied).

## Why it sleeps

The owner, 2026-10-30: "there is a zero percent chance I'm going to
remember to use these tools. Let's mark them as "dormant" and archive them
for now. I think it'll just be easier if we go through the issue file open
questions in groups of 10, with sufficient context to read them."

So open questions are now gone through in conversation, ten at a time,
each group with enough context to read it, and the answers written
straight into the issues by the agent.

## Where each file lived

| Now | Before |
|-----|--------|
| `scripts/*` | `scripts/` (the project's own) |
| `stories/` | `docs/answer-pages/` |
| `HTML/` | `docs/HTML/answer-pages/` |

## Waking it

Move the files back to where they lived (`git mv`), then run
`scripts/generate-answer-pages` and `scripts/answer-server` as the issues
describe. The scripts name their old paths, so they only work from there.

The pages' gifs are not kept here (2026-10-30, issue 1103: the inputs
and the pinned generator version are kept, not the pictures). Draw them
full size, byte for byte as they first were, with
`scripts/redraw-gifs assets/gifs/architecture-ideas/attempt-1`, and copy
the gifs it makes into `HTML/gifs/` (the page generator also copies them
from the RAM drive when it runs).
