title: Every Open Question
subtitle: Ranked by what it unblocks
part: Operations
state: the questions are read from the issue files each time this page is written
issues: all
gifs: 1a 1b 1c 1d 1e

The owner, 2026-10-29: "give me proposals for 5 more HTML artifacts that
properly display one portion of the built or planned subject artitechture
... It should list all open questions, and it should give a response form
where I can respond". This page is the first of the five, and the hub of
the other four: every question every open issue is still asking, in one
place, with a box beside each to answer it.

## Where the questions settle

gif: 1a

Every capability the project has sits in one of seven rings, from the
ground the game's files describe out to the operations that build and run
it (the capability architecture). A question settles into the ring of the
issue that asks it. An issue the architecture has not placed yet is listed
as "not yet placed", and placing it is part of answering.

## One answer unlocks many

gif: 1b

Issues wait on each other: an issue's "Blocked by", "Depends on" and
"Dependencies" lines name what it waits for, a "Blocks" line names what
waits on it, and a sub-issue waits on its parent's design. Following
those lines all the way down gives each issue a count: how many open
issues are held up, directly or through others, until it moves. The
questions below are sorted by that count, so the first ones you answer
are the ones that free the most work.

## How an answer travels

gif: 1d

1. You type into the box beside a question and press send.
2. The answer server on this computer (`scripts/answer-server`) appends
   it to this page's answers file, `notes/answers/open-questions.md`:
   the date, the issue, the question quoted, and your words as typed.
3. This page reads that file back and shows your answer under its
   question, whenever you come back.
4. The next agent that works on the issue copies your answer into it,
   word for word, and the question is marked answered there.

The box works only when the page is opened through the answer server
(start it with `scripts/answer-server`, then open
`http://127.0.0.1:8642/answer-pages/open-questions.html`). Opened as a
plain file, the page still reads, and the boxes say so.

## Answered, a ripple at a time

gif: 1c

Answered questions stay listed, marked and folded, so a question that
looks open is open. The count at the top of the list says how many are
left.

## The questions

gif: 1e

Sorted by what each issue unblocks, the most first. Narrow them by ring,
state or phase, or search; tick "show answered" to see the answered ones
too.

questions:
