# 190 - A Comment-Free Copy of the Project, for the Machine's Intuition

## Status
- Created: 2026-10-19
- Phase: 1 (Foundation & Tooling)
- Related: `strategems/intuition-copy.md` (the pattern this builds, for any
  project), 104 (the migration that kept wow-chat-1's code by copying it)
- Priority: Medium
- State: in progress; built, tested and live on GitHub; open questions 3
  and 4 remain

## Origin

Verbatim, the owner, 2026-10-19:

> we should also build a parallel copy of the project, updated whenever we
> git push, that stores all of the source-code without comments. Also,
> none of the explanation documents or claude.md directions. Instead, we
> will have a blank claude.md file that is default and applied anytime we
> apply this pattern (which we should be documenting as a new design
> pattern), which should say some helpful hints on how to proceed like
> "try checking the scripts directory for common actions" and "try
> following the compilation pipeline, looking at a list of src it pulls in
> what order and build your understanding of the project based on the
> order that things go in. Also we should remove the .info.md files for
> this parallel copy. It is expected that we have two agents running
> autonomously working on the problems in the project. One of them uses
> the parallel copy, the other uses the one with comments. The parallel
> copy is meant to be the "machine's intuition", and it is used in tandem
> with ours to achieve the desired goal or outcome.

## Current Behavior

`scripts/make-intuition-copy` builds the copy (default
`/mnt/kaun/wow-chat-2026-intuition`) from the files git tracks in this
project, as committed at HEAD: the explanation folders and files are left
out, comments are removed from the source by kind of file, and the default
`CLAUDE.md` from `strategems/intuition-copy-CLAUDE.md` is put at its root.
It writes a receipt (`.intuition-copy`) naming the source commit and the
counts. When the copy was made from an earlier commit of the same history
it is updated, not remade: only the paths changed since are rewritten
(added and changed ones stripped again, deleted ones removed); `--full`
remakes it all and keeps the copy's own history. With `--commit` the copy
commits itself (a repository of its own), each commit named after its
source commit; `--push` pushes it to `gabrilend/wow-chat-2026-intuition`
(public, like the original; made 2026-10-20 with the owner's "sure we can
do a github repository"). `scripts/install-intuition-push-hook` writes the
pre-push hook that does this for every push of main to origin, from the
commit being pushed; it keeps a hook already there and runs it first.
`scripts/test-make-intuition-copy` checks the tricky cases, an update
against a full remake, the hook in a throwaway repository, and a full copy
of this project (39 checks). `scripts/report-intuition-copy` writes
`docs/intuition-copy-report.md`: what the two share and how they differ.

Before this, there was one copy of the project, its comments and documents
read by every agent.

## Intended Behavior

1. **What the copy holds.** Every file git tracks, at the committed state
   (never half-written work), except the explanations: `docs/`, `issues/`,
   `notes/`, `tissues/`, `strategems/`, `llm-transcripts/`, `art-prompts/`,
   every `*.md` (README, CLAUDE.md, `*.info.md` included) and every `*.info`.
2. **Comments removed, the code unchanged.** Each kind of file by its own
   rules, so what is left still runs and still parses:
   - Lua (`*.lua`, `*.ext`, `*.lua.*`, and scripts whose first line names
     luajit or lua): every `--` comment and `--[[ ]]` block, found by
     reading the file as Lua reads it, so a `--` inside a string stays.
   - Shell (`*.sh`, scripts whose first line names bash or sh): whole lines
     that are a comment. The first line (`#!`) stays, and so does every
     line inside a here-document (patches carry C++ in them, whose
     `#include` lines are code). Comments after code on the same line stay:
     telling them apart from `#` in strings and `${#var}` needs a full shell
     reader (open question 3).
   - SQL: whole `--` comment lines, except the install steps' marker lines
     (`-- MARKER_E0NN_APPLY`), which `patches/E-patches.sh` looks for to tell
     an applied file from a reverted one. `/*! ... */` stays (MySQL runs it).
   - C and C++ (`*.cpp`, `*.h`, `*.c`, `*.js`): `//` and `/* */`, found by
     reading the file as the compiler does, strings and characters skipped.
   - Settings files (`*.conf`, `*.dist`), Python, TOML-like files: whole
     `#` comment lines.
   - Anything else (data, pictures, JSON): copied as it is.
   - Blank lines left where a comment block was are folded to one.
3. **Its own CLAUDE.md.** A fixed default for any project the pattern is
   applied to, with hints on how to find one's way without explanations:
   the scripts folder for common actions, and the build pipeline's order of
   sources as the order to learn the project in.
4. **A receipt.** `.intuition-copy` at its root: the source project, the
   source commit, when, and how many files were copied, stripped and left
   out, so a reader knows which state of the project it is.
5. **Kept up to date on every push** (open question 1).
6. **Two agents** work the same problems, one in each copy, and their
   results are used together (open question 2).

## Suggested Implementation Steps

1. `strategems/intuition-copy.md`: the pattern, for any project.
2. `strategems/intuition-copy-CLAUDE.md`: the default instructions.
3. `scripts/make-intuition-copy [PROJECT_DIR] [OUT_DIR]`: list the files with
   `git ls-files`, read each at HEAD with `git show`, strip by kind, write
   into a fresh folder beside the old copy, then swap it in. It removes an
   old copy only when that folder holds its own receipt, so a wrong path
   never deletes anything else.
4. `scripts/test-make-intuition-copy`: on this project, every Lua file of
   the copy still compiles (`luajit -bl`), every shell script still parses
   (`bash -n`), no comment is left in a sample of each kind, the SQL
   markers are all still there, nothing explanatory got in, and the receipt
   is written. Small hand-made cases for the tricky spots: `--` in a Lua
   string, a long-bracket comment, `#include` in a here-document, `//` in a
   C++ string.
5. The push hook (after open question 1): `.git/hooks/pre-push` runs the
   maker; like the transcripts hook, it is not in git, so CLAUDE.md says how
   to make it again after a fresh clone.

## Open Questions

1. **Where does the copy live, and how is it "updated whenever we git
   push"?** A folder on this computer, remade by a pre-push hook? Its own
   git repository, committed on each push? A GitHub repository of its own
   (making one publishes the code without comments; it is the owner's to
   create)? **Answered** 2026-10-20: "sure we can do a github repository.
   Also it should only remake what has changed, of course." Built as above.
2. **Two agents at once.** Earlier the same day the owner said: "I am never
   ever using more than one LLM agent at a time." This design has two
   running together. Is the second agent for later, or do the two take
   turns (one problem, worked in one copy and then the other)? **Partly
   answered** 2026-10-20: "I regret the experiment, I learned that my
   parallelization scheme was short sighted. I think from now on we should
   have a rule that if multiple agents are working on the same tasks, they
   must claim files for themselves and only complete the parts of issue
   files that don't require touching shared files." The rule is in
   CLAUDE.md ("When more than one agent works here"). Still open: how do
   changes made in the comment-free copy come back to this one (copied by
   hand, as patches, or does that copy's agent only read and suggest)? The
   copy is remade from this one on every push, so anything committed only
   there is overwritten.
3. **Inline shell comments.** `do_thing # because` keeps its comment for
   now. Worth a full shell reader to remove those too?
4. **This project only, or every project?** The pattern is written for any
   project; the maker lives in this project's scripts for now. Should it
   move to the shared scripts (`/home/ritz/programming/ai-stuff/scripts/`)
   with the default CLAUDE.md beside it?
