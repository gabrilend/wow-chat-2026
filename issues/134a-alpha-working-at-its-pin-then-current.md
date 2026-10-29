# 134a - Alpha Working at Its Pin, Then Brought Current

## Status
- Created: 2026-10-28
- Phase: 1 (Foundation)
- Parent: 134 (the alpha baseline: `source-alpha/`, AzerothCore pinned
  at 5af3d2d6, 2024-09-18, with the original mod-eluna)
- Related: 147 (alpha's MySQL on port 3308, which nothing listens on),
  132 (playerbots on alpha), 136 (the profiles' definitions), 1100c (the
  installed Lua links)
- Priority: High
- State: in progress (planning)

## Origin

Asked 2026-10-28 what release's Lua should be (its links led nowhere),
the owner answered:

> we should ensure that the old pinned azerothcore we have for that
> profile is fully functional, then we should bring it to compatibility
> with the current version.

and, asked which old version she meant (release's May 21 build, the
project's commit 1fc133a, or alpha's fork), chose **alpha's pinned-old
fork**.

## Current Behavior

- `source-alpha/` is an AzerothCore clone at 5af3d2d6 (2024-09-18) on a
  branch of its own, `alpha-baseline` (issue 134), with mod-eluna and
  mod-transmog (`scripts/update`'s module list for alpha); its
  `PROFILE_COMMIT` there is empty ("track HEAD"), so an update could move
  it off its pin.
- Alpha has never been installed here: there is no
  `installed-files-alpha/bin/`.
- Its config patch (C001) puts its MySQL on port 3308; the project's MySQL
  listens only on 3307 (issue 147), so an alpha server could not reach
  its databases.
- Its databases (`acore_*_alpha`) don't exist yet.

## Intended Behavior

1. **Working at its pin.** Alpha builds from `source-alpha` at 5af3d2d6,
   installs into `installed-files-alpha`, reaches its own databases,
   and its world server starts and lets a character into the world, with
   its Lua (`src/lua-alpha`) loaded by mod-eluna. Nothing in the steps
   moves it off its pin.
2. **Then brought to compatibility with the current version**: what the
   current profiles have (their AzerothCore pin, 2a2211cd8f3d, and its
   modules) reached from alpha step by step, each step building and
   starting, so the differences between the old and the new are known
   and written down.

## Suggested Implementation Steps

1. Pin alpha in `scripts/update` (`PROFILE_COMMIT["alpha"]="5af3d2d6"`),
   so an update can't carry it off.
2. Its MySQL (147): choose a path (a second listener on 3308, or its own
   MySQL), make it, create its databases.
3. The owner's build of alpha (`scripts/update`, `scripts/compile`,
   `scripts/install` with alpha active), its log read for what fails;
   each failure fixed as a patch of alpha's own.
4. Start it; log in; a character in the world; its Lua loaded.
5. Then the way up: what changed between 5af3d2d6 and the current pin,
   in steps the owner chooses.

## Open Questions

1. **"compatibility with the current version"**: should alpha end up on
   the current AzerothCore (the same pin as the others, with mod-ale in
   place of mod-eluna), or stay on its own old core with its content made
   to work beside the current one (shared accounts, characters moving
   between them)?
2. **Its MySQL** (147's two paths): a second port on the same MySQL, or
   its own MySQL?
