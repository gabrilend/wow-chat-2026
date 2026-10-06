# 171 - The Everland Wiki

## Status
- Created: 2026-10-04
- Phase: 1
- Priority: Medium
- Related: the documentation pages (`docs/HTML/`), the transcripts
  (`llm-transcripts/`, and their HTML copies), every generator that writes
  world-database changes (`sql/basic/`, the install steps)

## Origin

Verbatim, 2026-10-04:

> can we add an issue file to add a wikipedia style page generated from
> the issue files and such? It should also contain a full database, with
> all the times the item is affected listed as a link to the transcript
> where the edit took place. So you can see why and how something changed.
> We should have two different types of sections for the default things,
> and the changed things.

## Current Behavior

Not built. What the project changes is spread over issue files, install
steps (SQL that edits the world database), source patches and Lua scripts;
why each change was made is in the issues and, in full, in the saved
conversations (`llm-transcripts/`). Nothing gathers, for one item,
creature, quest or spell, what the game had and everything the project
did to it.

## Intended Behavior

A generated wiki, in the style of an encyclopedia: one page per thing
(item, creature, quest, spell, zone, dungeon), pages linked to each other
and to the issues, built from the project's own files and the world
database.

- **Two kinds of section on every page**:
  - *Stock*: the thing as the game ships it (from a stock copy of the world
    database): its stats, where it drops or stands, what gives or uses it.
  - *Changed on Everland*: each change the project makes to it, newest
    first: what changed (before and after), the install step, patch or
    script that makes it, the issue that asked for it, and a link into
    the conversation where it was decided (the transcript, at the line).
- **A full database**: every item, creature, quest and spell has a page,
  changed or not, so the wiki is also the reference for the stock game;
  changed pages are marked and listable.
- **Issue pages**: each issue rendered, its links live (issues, files,
  things it changes).
- **Generated only**: rebuilt by one command from the issue files, the
  install steps' saved originals and new values, and the transcripts;
  never edited by hand.

### Answers, 2026-10-04 (Ritz)

- "maybe we can have the patch file update the wiki page? No need to
  dismantle the wiki page after undoing the source-patch." Each source
  patch, install step and config patch writes its own entry into the
  wiki's change record when it applies (what, where, which issue); undoing
  the patch leaves the entry (the record is history, not state).
- "full database, extracted from mysql during compilation ... this
  includes things like... altered placements for NPCs, or changes to item
  drop rates or whatever": every thing gets a page, extracted from the
  world database as part of the build; changes include moved creature
  spawns and changed loot chances, not only stats.
- Rule changes made in C++ ("spirit heals by stamina"): "for that one, on
  the stats page. Also in a 'changes' page sorted by generally how major
  the feature is." So: on the page of the stat or thing the rule is about,
  and on one Changes page listing every change, the larger features
  first.

## Suggested Implementation Steps

1. The change ledger: for each install step and patch, which things it
   touches and how (the steps already save originals before they change
   anything: those tables are the ledger's source).
2. Link each change to its issue (the step's header names it) and to the
   transcript line where the issue's decision was made (the
   transcript-care skill's issue-to-transcript linking).
3. The page generator: stock section from a stock database copy, changed
   section from the ledger; issue pages; an index and search.
4. Published under `docs/HTML/wiki/`, reachable from the table of contents.

## Open Questions

1. (Answered 2026-10-04) Every thing, extracted from the database during
   the build.
2. (Answered 2026-10-04) On the stat's (or thing's) page, and on the
   Changes page sorted by how major.
3. "How major": who ranks a change: a field in each patch's header (major,
   minor, tuning), or the size of what it touches?
