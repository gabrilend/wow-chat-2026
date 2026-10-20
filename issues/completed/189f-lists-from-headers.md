# 189f - Lists Made From the Headers

## Status
- Created: 2026-10-20
- Phase: 1 (Foundation & Tooling)
- Parent: 189
- Blocked by: 189b
- State: completed 2026-10-20

## Current Behavior

Built 2026-10-20. No list of patches or of quick tests is kept by hand.

- **The quick tests** are gathered from their headers: `scripts/plan-patches
  --quick-tests` names every `scripts/test-*` whose whole header says
  `quick-test: yes` (sorted; a retired `-done` file left out; a broken test
  header is a fault, since that test might be a quick one silently
  skipped). `scripts/compile` runs exactly those, and
  `scripts/check-issue-tests` takes the same set. The compile's comment on
  the tests left out, and why, stays where it was.
- **The written lists**: `scripts/generate-patch-lists` writes, between two
  marker lines (the first says what writes it and not to edit by hand),
  the patch registry's table of every patch and quick test (id, kind,
  priority, profiles, about, file, lowest priority first) and each profile
  page's list of that profile's patches by stage, in the planner's order,
  the build's own. Columns are padded in the raw text, numbers
  right-aligned; widths count letters, not bytes. A page without the
  markers is an error naming it. `--check` writes nothing and says which
  pages are stale; `scripts/test-patch-lists-current`, a quick test, runs
  it, so the compile stops while a header and the pages disagree.
- **The pages**: `docs/patches/patch-registry.md` was rewritten around the
  one priority line and its gates, with the generated table; its older
  per-patch write-ups (B001-B008) are kept; its hand-kept tables and its
  description of the first three-stage design moved word for word to
  `docs/patches/profile-patch-history.md`. Beta's page had its source and
  install lists by hand; they are now the generated list. The other five
  profile pages gained one.
- **Headers mended on the way**: eight headers whose `about` was only their
  id (B010, B011, B022, B024 and four tests) now say what they are, taken
  from each file's own description.
- **Retired and removed**: `scripts/write-patch-headers-done`,
  `scripts/test-patch-headers-match-lists-done` (both from 189c, a commit
  ago) and `scripts/split-install-steps-done` (issue 150).

The settings test's expected-values table is not generated: it is the
independent statement the settings test checks the patches against.

The compile's last hand list (51 tests, the same set the headers now give):
test-acherus-vendors test-ale-method-names test-ambush
test-arathi-basin-rules test-beta-lua-load test-beta-two-side-permissions
test-buddy-arc test-buddy-choice test-buddy-gems test-buddy-gm
test-buddy-hearth test-buddy-kit test-buddy-roam-core test-buddy-stand-ins
test-buddy-talents test-check-issue-references test-compile-module-set
test-dk-buddies-by-level test-dk-buddy-gear test-dk-skip-story
test-dk-soul-trade test-druid-moonglade test-forget-unprefixed-updates
test-gear-designs test-gearsets test-gm-command-reference test-hearthstone
test-info-files-match-source test-line-edits test-lua-globals
test-lua-unique-names test-make-intuition-copy test-movement
test-navmesh-caves test-patch-headers test-patch-plan
test-patch-undo-order test-profile-config-gates test-profile-tables-agree
test-redirect-listener test-roam-pattern test-sargobras-follow
test-sql-mirror test-steady-mtimes test-travel test-treasure
test-valley-deal test-validate-needs-world-up test-watch-compile
test-world-boss-countdown; and, new with this issue,
test-patch-lists-current.

Checked: the gathered set equals the last hand list; all 51 quick tests
pass; `scripts/test-patch-plan` (30 checks) checks the gathering on its
pretend project and against a plain reading of the real headers;
`scripts/check-issue-tests --run` still shows each left-out test's reason.

## Intended Behavior

The compile gathers its quick tests from `scripts/`, every test whose
header says `quick-test: yes`. The patch registry and each profile page's
patch lists are written from the headers by a tool, run with each change,
each written file saying what made it. The settings test's expected-values
table is not one of these: it is the independent statement the settings
test checks the patches against, and stays written by hand.

## Suggested Implementation Steps

1. `scripts/plan-patches --quick-tests`; `scripts/compile` and
   `scripts/check-issue-tests` read the tests from it.
2. `scripts/generate-patch-lists`: the registry and the profile pages'
   patch sections, between markers, with `--check`.
3. `scripts/test-patch-lists-current`, a quick test.
4. Rewrite the registry around the priority line; move its stale hand
   tables to the history page; markers on every profile page.
