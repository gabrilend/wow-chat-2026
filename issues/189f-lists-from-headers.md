# 189f - Lists Made From the Headers

## Status
- Created: 2026-10-20
- Phase: 1 (Foundation & Tooling)
- Parent: 189
- Blocked by: 189b
- State: planned

## Current Behavior

The compile's quick tests are a list in `scripts/compile`. The patch
registry (`docs/patches/patch-registry.md`) and the patch lists on the
profile pages (`docs/profiles/*.md`) are written by hand, and nothing
checks them, so they can drift from the patches.

## Intended Behavior

The compile gathers its quick tests from `scripts/`, every test whose
header says `quick-test: yes`. The patch registry and each profile page's
patch lists are written from the headers by a tool, run with each change,
each written file saying what made it. The settings test's expected-values
table is not one of these: it is the independent statement the settings
test checks the patches against, and stays written by hand.

## Suggested Implementation Steps

1. `scripts/compile` reads the headers for its quick tests.
2. `scripts/generate-patch-lists`: the registry and the profile pages'
   patch sections, between markers.
3. A test that the generated lists are current.
