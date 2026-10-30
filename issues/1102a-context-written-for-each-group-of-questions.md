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

And, asked whether to write them all at once or a page at a time:

> just do all of them, you can take your time. Remember we're grouping
> them up together with shared contexts, and the idea is that if we had
> ALL the open questions from the entire project even those that have been
> answered, if we had those, then a user could walk through them
> one-by-one and fully customize the software. And, if a user read through
> every single properly sorted context with the properly sorted open
> questions underneath them, then they'd be able to understand completely
> and answer each and every question in the open questions document. So,
> it'd be like a single documentation page that listed in a couple short
> paragraphs, enough to understand a few simple questions. Then, it'd give
> more context, and a couple more questions. Then more context, then more
> questions, etc etc, and by the end, if we had all the open questions
> which we don't, then we'd be able to fully describe the project
> completely. Does that make sense?

## Current Behavior

**The machinery is built (2026-10-29); no context is written yet.**
- `scripts/generate-answer-pages --questions PATH` exports every question
  of every open issue, answered ones included, in walkthrough order.
- `scripts/write-question-contexts` groups them (452 groups of at most
  five, one family of issues to a group), and for each group asks a
  writer session (`claude -p`, allowed only to read, its answer held to a
  fixed JSON shape) for the components and a context, checks that every
  component's quoted sentence is really in the context, asks once more
  with what is missing, and keeps the result in
  `docs/answer-pages/contexts/<group>.json` with a fingerprint. Several
  writers run at once (`--jobs`, 4 by default).
- The open-questions page has a walkthrough order (the rings, then phase,
  then issue), showing answered questions too, and places each written
  context above the first question of its group.
- **One writer at a time, in order** (the owner, 2026-10-30: "I'm
  concerned that if we don't do it with a single thread, then we'll find
  ourselves re-explaining things from the context. That's not ideal!"):
  writers run in walkthrough order, each told the components the contexts
  before it explained (the last 300), and asked not to explain them again.
- **Key terms marked** (the owner, 2026-10-30: "can we make it so that
  words in the question that are important will stand out in the context
  with a color appropriate and bolded highlight?"): each context names its
  key terms, copied exactly from it, each of a kind (mechanism, number,
  choice, place, decision); the page shows them bold, coloured by kind.
- **Run by the owner**: starting writer sessions from the agent's own
  session is refused by Claude Code's permission system (2026-10-29 and
  30). The owner ran three groups on 2026-10-30 (all components
  explained); the full run is `scripts/write-question-contexts`, then
  `scripts/generate-answer-pages`. The writer's version is in each
  fingerprint, so the three are written again in order with key terms.

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
- **Every question, answered ones too.** An answered question is listed
  with its answer, so the walkthrough covers every decision the project
  has made, not only the ones still open. A reader who customizes their
  own copy walks through all of them and may answer differently.
- **One walkthrough, in order.** The groups are sorted so each context
  builds on the ones before it: the foundations first (the ground, the
  rules, the profiles), the things built on them after, in the order of
  the capability architecture's rings. Read top to bottom, a short
  context, a few questions, the next context, the next questions, it
  explains the whole project to someone who has read nothing else.
- **More questions over time.** The walkthrough is as complete as the
  questions are. Decisions the code made without asking (a number chosen,
  a rule picked) are written into their issues as answered questions
  when found, so the walkthrough grows toward describing the project
  completely.

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
   **Answered 2026-10-29:** all of them, answered ones included, taking
   the time it takes (above).
