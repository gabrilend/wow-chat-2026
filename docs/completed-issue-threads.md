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

## The convention: "Since then"

Completed issues may be added to, never cut. When a completed issue has
fallen behind, it gains a section at its end:

```
## Since then (checked <date>)

- what moved or was renamed, and where it is now
- which later issues built on it, by number and name
- what was tried later instead, and why
- anything still teaching the old way
```

The text above the section stays as history. The section is where a
reader learns what happened next, and it names the later issues by
number, so the thread is tied at both ends: the later issue names this
one, and this one names it back. Old issue numbers in the text above are
annotated in place rather than rewritten: "Issue 334 (now 127)".

Two sessions wrote these notes in parallel on 2026-10-17, one under the
heading "What Came After", one under "Since then"; the second was kept
for every issue, and the checker still reads both.

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

## The tools

`scripts/check-issue-references [PROJECT_DIR] [--summary] [--threads] [--all] [ISSUE_FILE ...]`
reads the completed issues (or all, or the files named) and reports,
without changing anything:

- **paths** it names: there, moved (and where: a known rename such as the
  per-profile Lua folders, a file switched off or on, the same name
  elsewhere, or a project it moved out to), or missing; a gone path that
  the issue's own "Since then" section names is counted as explained
- **patch steps** (B, C, E) that are gone or retired
- **issues** it names that have no file, with the new number from the
  April map; one annotated "(now N)" is explained
- with `--threads`, **later issues that name it**, told apart from
  mentions of another issue with the same number by the words around the
  mention (a word of its name nearby confirms it; another issue's name
  marks a reused number; neither leaves it unconfirmed), and which of
  those it does not name back
- **issues marked completed but still filed as open** (when no files are
  named)

`scripts/test-check-issue-references` checks every verdict against a
made-up issue and a pretend project. `scripts/issue-lineage ISSUE`
gathers, for one issue, the later issues and commits that name it and the
history of each file it names: the raw material for a "Since then" note.
Run the tools for current numbers; any figure copied into a document goes
stale.

The fronts-homework branch first built this audit as a separate script,
`scripts/trace-completed-issues`; its checks were folded into
`check-issue-references` the same day so there is one tool, and it was
retired (kept once as `scripts/trace-completed-issues-done`).

## Working through the report

1. Pick an issue with unexplained paths or unanswered later issues.
2. Check each finding by hand (the tool reads text, and text can fool it).
3. Find out why it changed: `git log --follow` on the moved file, the
   later issue's own text, `issues/MIGRATION_MAP.md`.
4. Add the "Since then" section; fix stale numbers in *open* issues in
   place, by hand, reading the words around each.
5. Run the checker again on that issue (`check-issue-references --threads
   ISSUE_FILE`): it should show no moved or missing paths that the note
   doesn't explain, and no later issues left unnamed.
