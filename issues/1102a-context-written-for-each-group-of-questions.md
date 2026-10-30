# 1102a - Context Written for Each Group of Questions

## Status
- Created: 2026-10-29
- Phase: 1
- Parent: 1102 (architecture pages you can answer on)
- Priority: High
- State: planned

## Origin

The owner, 2026-10-29, on the open questions page:

> okay now for the open questions listed in the open questions system, we
> should build a system that dynamically builds the context that a reader
> who is reasonably familiar with the project needs to know in order to
> answer the question. Essentially, explaining each of the specifics. This
> context should be placed above a series of questions that are directly
> related to it - each of them will have components that must be included
> in the context description we generate. Then, below it, is another
> context for the next few series of questions. Right now... Right now
> it's hard.

## Current Behavior

The page lists each issue's questions as the issue wrote them, under the
issue's title: issue numbers, code names and shorthand from the day they
were asked, with nothing explaining them.

## Intended Behavior

- **Questions in groups.** The open questions are gathered into groups of
  a few that are directly related (the same mechanism, the same decision,
  the same feature), across issues where they belong together.
- **Each question's components.** For each question, the things a reader
  must know to answer it are listed: the terms it uses, the mechanism it
  is about, the numbers it names, what was already decided around it, the
  choices it offers and what each would bring.
- **A context above each group**, written for a reader who knows the
  project reasonably well but not this corner of it: plain English, no
  issue numbers or code names, every component of every question in the
  group explained. A check refuses a context that leaves a component out,
  and the context is written again.
- **Dynamic.** Contexts are made again when the issues they draw on
  change (each group's context is kept with a fingerprint of the issue
  text it was written from), so a page never explains a stale question.
- **Then the questions**, reworded only where the original is unreadable
  out of its issue, the original kept beside it, each with its answer box.

## Suggested Implementation Steps

1. Grouping: questions clustered by the issues they come from and the
   words they share, a group at most five questions; checked by eye on
   the page.
2. Components: for each question, its components found (by a writer
   session reading the issue around it, the concept catalog and the
   architecture document) and kept as a list.
3. Contexts: a writer session (Claude Code, run without a window) given a
   group's questions, their components and the source text, asked for a
   context covering every component; the check reads the context for each
   component and sends back what is missing.
4. Kept per group in `docs/answer-pages/contexts/`, with the fingerprint;
   the page generator places each above its group.

## Open Questions

1. Should the contexts be written for every open question at once (about
   a thousand, a long run), or a page at a time as it is opened, starting
   with those that unblock the most?
