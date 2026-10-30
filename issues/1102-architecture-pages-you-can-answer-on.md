# 1102 - Architecture Pages You Can Answer On

## Status
- Created: 2026-10-29
- Phase: 1 (tooling; numbered 1102 because phase 1's hundreds are full)
- Related: the capability architecture (`docs/capability-architecture.md`),
  625 (talents), 617o8 (the painted map), 617t and 617e17 (stand-ins and
  the army), 921 (Alterac Valley's weather), 1005 (the players' feedback
  mailbox, a different thing: players to the operator by rmail)
- Priority: Medium
- State: in progress

## Origin

The owner, 2026-10-29, asking for proposals: "give me proposals for 5
more HTML artifacts that properly display one portion of the built or
planned subject artitechture? If it is planned but not built, I want to
see the document, then build it after I approve. It should list all open
questions, and it should give a response form where I can respond by
writing to a .md file, stored locally and displayed here for whenever I
come back, or for future LLM guided developments."

On the first page: "for page 1. we should have a message box next to each
of them where we can send data to our locally hosted HTML page launched
web server."

Then, once 25 gifs were drawn for them: "let's think about those 5 HTML
documents we were going to make, and then let's create them, and utilize
the gifs that we created in them. We should have 5 gifs per HTML page,
yes? Let's try and work them into the story. We can use any gif if they
make sense, but we must use the 5 that are assigned to our HTML page
section."

## Current Behavior

**Built 2026-10-29** (pictures 083-087): the five pages and their index,
`docs/HTML/answer-pages/`, written by `scripts/generate-answer-pages` from
the stories in `docs/answer-pages/` and the issue files; the answer
server, `scripts/answer-server`, whose `--check` (post an answer, read it
back word for word, refuse a bad page name) passes. The generator's
`--check` says whether the pages are up to date. Neither check is yet
one of the compile's quick tests.

- Page 1 holds every open issue's questions: 1,573 in 525 issues, 1,004
  still open when written. An item counts as answered when the last mark
  in its text is an answer ("Answered", "decided", "settled by later
  work"), not something open ("stays open", "to be talked through"). The
  states use the status board's own rule, copied. The architecture places
  few issues by number, so most (255 of 450 with questions) are "not yet
  placed".
- The 25 gifs are copied from the first drawing and shrunk by a third
  (15 MB in all).
- Pages 3 and 5 are the plans only; their simulators wait for the
  owner's approval.
- Not done: the new documents are not yet in `docs/table-of-contents.md`
  (a shared file another session holds).

## Intended Behavior

**Five pages, each one part of the architecture, told as a story with
its five gifs:**

| Page | Part | Built? | Its issues |
|------|------|--------|------------|
| 1 | Every open question, ranked by what it unblocks | the data is | every open issue |
| 2 | Pathfinding, end to end | built | 617o and 617o1 to 617o8 |
| 3 | Talents guiding abilities | planned: the plan only, built after approval | 625, 625a, 625b |
| 4 | Stand-ins and the army of 64 | built, waiting for the compile | 617t, 617t1, 617t2, 617t3, 617e17, 617c3 |
| 5 | Alterac Valley's weather | planned: the plan only, built after approval | 921, 921a, 921b |

- **The questions come from the issues themselves**, read when the page is
  written, so a page never holds a stale copy: each issue's Open Questions
  section, item by item, an answered one marked answered.
- **Page 1 ranks every open question** by how many open issues wait on its
  issue (the "Blocked by", "Depends on", "Dependencies" and "Blocks" lines,
  and an issue's own sub-issues), and groups them by the architecture's
  seven rings (read from the architecture document's tables; an issue
  without a place there is listed as not yet placed), by state, and by
  phase.
- **A message box beside every question.** It sends to the answer server
  on this computer, which writes the answer into
  `notes/answers/<page>.md`: the date, the issue, the question quoted, the
  answer word for word. Every page shows the answers already written
  under their questions, so they are there whenever the owner comes back,
  and for any later agent: the files are plain Markdown, committed, and
  copied into the issues by the agent that next works there.
- **Opened without the server** (as a plain file), a page still reads,
  and its boxes say plainly that the answer server is not running and how
  to start it; nothing is pretended to be sent.

**The answer server** (`scripts/answer-server`): LuaJIT with luasocket,
listening only on this computer (127.0.0.1). It serves `docs/HTML/` and
two more things: posting an answer (written to that page's answers file,
nothing else; the page's name may only be letters, digits and dashes), and
reading a page's answers back.

## Suggested Implementation Steps

1. The answer server, with `--help`, a log in the RAM drive, and a test
   that starts it, posts an answer and reads it back.
2. The page generator (`scripts/generate-answer-pages`): each page's story
   from `docs/answer-pages/<page>.md` (gifs placed by a `gif: 2a` line), its
   questions from its issues, the gifs copied into `docs/HTML/answer-pages/`
   from the latest drawing, the shared style and the answer boxes.
3. The five stories.
4. Pages 3 and 5 stay plan pages until the owner approves; then their
   simulators are built (each in its own issue's steps).
5. Each page photographed into the development history.

## Open Questions

1. Should answers also be sent from the pages published on claude.ai (they
   cannot reach this computer; they would keep answers in the page's own
   database for an agent to copy down), or are the local pages enough?
