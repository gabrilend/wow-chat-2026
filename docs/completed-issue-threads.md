# Completed Issue Threads

How a finished issue stays true to a project that kept moving, and how to
tell when it hasn't.

## Why this exists

A completed issue is the blueprint of a piece of the project as it was
built, and it is never rewritten. The project around it does not stand
still: folders are split by profile (`src/lua/` became `src/lua-beta/` on
2026-06-02), scripts are broken up (the one `scripts/azerothcore` became a
script per command), patches are retired, and later issues rework what an
earlier one made. A reader who opens an old issue sees the design as it
was, with nothing to say what became of it.

## The convention: "What Came After"

Completed issues may be added to, never cut. When a completed issue has
fallen behind, it gains a section at its end:

```
## What Came After

Added <date> (the text above is left as it was written).

- what moved or was renamed, and where it is now
- which later issues built on it, by number and name
- what was tried later instead, and why
- anything still teaching the old way
```

The text above the section stays as history. The section is where a
reader learns what happened next, and it names the later issues by
number, so the thread is tied at both ends: the later issue names this
one, and this one names it back. First written into
`completed/142-split-azerothcore-script.md` and
`completed/307-ale-gameobject-wildcard.md`.

## The trap: reused numbers

An issue number alone does not always say which issue it means:

- **The April renumbering** (`issues/MIGRATION_MAP.md`) moved many
  issues to new numbers, and the old numbers were later given to
  other issues. "Issue 307" in a narrator issue meant narrator
  audience-facing (now 908); today 307 is the gameobject wildcard.
- **Numbers handed out twice:** 141 and 142 each name one completed and
  one open issue, because the next free number was once chosen without
  looking in `completed/`. `validate-issues --next` now counts completed
  files.

So write a reference as number and name ("issue 405, the ability tome
system", or the file name `405-ability-tome-system`), which survives a
reused number. And do not mass-rewrite a number across the project
(`scripts/update-issue-refs` does exactly that): with reused numbers it
breaks the references that were right. Change each by hand, reading the
words around it.

## The tool

`scripts/trace-completed-issues [PROJECT_DIR] [--file ISSUE_PATH]` reads
every completed issue and reports, without changing anything:

- **paths** it names that are no longer in the project, with a likely new
  home when a file of the same name exists elsewhere; paths that its
  "What Came After" section explains are listed as explained, not stale
- **patch steps** (B, C, E) that are gone or retired
- **issues** it names that have no file, with the new number when the
  April map moved it
- **later issues that name it**, told apart from mentions of another
  issue with the same number by the words around the mention (a word of
  its name nearby confirms it; another issue's name marks a reused
  number; neither leaves it unconfirmed), and which of those it does not
  name back
- **issues marked completed but still filed as open**

It prints one line per issue and writes the full report to
`tmp/shared-memory/trace-completed-issues.md`. Run it for current
numbers; any figure copied into a document goes stale.

## Working through the report

1. Pick an issue with stale paths or unanswered later issues.
2. Check each finding by hand (the tool reads text, and text can fool it).
3. Find out why it changed: `git log --follow` on the moved file, the
   later issue's own text, `issues/MIGRATION_MAP.md`.
4. Add the "What Came After" section; fix stale numbers in *open* issues
   in place, by hand.
5. Run the tool again on that issue (`--file`): it should show no dead
   paths and no unanswered later issues.
