# 196 - Issue Numbers Out of Order (Tech Debt)

## Status
- Created: 2026-10-23
- Phase: 1
- Related: 155 (the basic profile: 48 sub-issues, 155a to 155z13)
- Priority: Low (tech debt: "save it for tech debt resolution tasks later")
- State: noted; to be worked when tech debt is taken up

## Origin

Verbatim, 2026-10-23:

> okay why the heck does 155 go all the way to Z that seems a little odd,
> our phase numbers are wayyyyyy out of order.
>
> But, let's not worry about it now, and save it for tech debt resolution
> tasks later.

## Current Behavior

- **155 runs past z.** Every change to the basic profile has been filed as
  a sub-issue of 155, the profile's own issue: 155a to 155z, then 155z1 to
  155z13 once the alphabet ran out. It holds things of every kind:
  plumbing, the world database, sockets and gems, professions, talents,
  deaths, monster stat pages.
- **Phases don't follow the house rule.** The rule (CLAUDE.md): an issue's
  phase is the section of the software it belongs to, and lower numbers
  are the foundations later ones build on. Here 155's sub-issues are all
  "phase 1" whatever they are about; the buddy issues are 617 (phase 6)
  with sub-issues to 617z; death knight work is 718 (phase 7); and many
  numbers record when an idea arrived rather than what it builds on.
- `validate-issues` (the house tool) gives the next free number per phase
  and checks links; it doesn't judge whether a number fits.

## Intended Behavior

Issues numbered by what they are: each part of basic (gems and sockets,
professions, death knights, deaths and travel, monsters) in the phase that
holds its kind of system, foundations low and capstones high, with no
sub-issue chain running past z. History kept: files moved with `git mv`,
every reference updated.

## Suggested Implementation Steps

1. Draw up the phases as sections of the software (from
   `docs/table-of-contents.md` and the roadmap), and map each open and
   completed issue to one.
2. A renumbering table (old number, new number, reason), reviewed by the
   owner before anything moves.
3. A script that moves the files with `git mv` and rewrites every reference
   in issues, docs, code comments, patch headers and commit-message-free
   places (grep the whole project for each old number).
4. `validate-issues` clean afterwards; the phase progress files rebuilt.

## Open Questions

1. When to take it up, and whether other tech debt joins this list (this
   issue could become the tech-debt list itself).

## Answers, 2026-10-23

1. **Issue renumbering only** ("just issue renumbering."): this issue
   doesn't become a general tech-debt list.
