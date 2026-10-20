# 189a - The Header and Its Reader

## Status
- Created: 2026-10-20
- Phase: 1 (Foundation & Tooling)
- Parent: 189
- Blocks: 189b
- State: in progress

## Current Behavior

No patch, setting, install step or test says anything about itself in a
form a program reads; what each is, which profiles take it and in what
order live in lists elsewhere (`patches/patches.sh`, `scripts/compile`).

## Intended Behavior

**The shape** (the owner, 2026-10-20: "Sure."), written in the file's own
comment marker (`#` for shell, `--` for SQL and Lua), right after a `#!`
line if there is one:

```
# ==== header: 7 lines, footer: 3 lines ====
# id:        E062
# profiles:  beta
# priority:  1620
# kind:      install
# about:     trade across the factions, on beta's realm
# ==== end of header ====
  ... the patch ...
# ==== footer of E062 ====
# lines:     148
# ==== end of footer ====
```

- The first line states both lengths. The header has exactly that many
  lines, the last of them `==== end of header ====`; the footer is the
  file's last lines, exactly that many, opening with `==== footer of <id>
  ====` and closing with `==== end of footer ====`.
- Required fields: `id`, `profiles` (profile and group names, spaces
  between), `priority` (an integer), `kind` (`source`, `settings`,
  `install`, `sql`, `test`), `about` (one line). Optional: `carries`
  (189e), `quick-test` (`yes`, for tests, 189f). An unknown field is an
  error, so a typo is not ignored.
- The footer's `lines` is the file's whole line count, so a file cut short,
  or added to without its footer moved, no longer matches.
- **Whole**: everything above holds; the file is a patch. **Broken**: the
  first line is a header line but anything else fails; an error that stops
  a run, naming each fault. **Absent**: no header line at all (a helper, a
  note); listed as skipped, never silently.

**The reader** (`scripts/lib/patch-header.lua`) returns a file's state,
its fields and, when broken, every fault. **The checker**
(`scripts/check-patch-headers`) reads every file where patches and tests
live, prints whole, broken and skipped files, exits with failure on any
broken one, and with `--fix-lines` rewrites each whole file's footer line
count (the one field every edit changes).

## Suggested Implementation Steps

1. `scripts/lib/patch-header.lua` and its `.info.md`.
2. `scripts/check-patch-headers [PROJECT_DIR] [--fix-lines]`.
3. `scripts/test-patch-headers`: small files for each case (whole; whole
   after a `#!` line; an SQL file's `--` header; each kind of break: a
   wrong stated length, a missing closing line, a footer naming another
   id, a wrong line count, a missing field, an unknown field, a priority
   that isn't a number; absent), and `--fix-lines` mending a count and
   nothing else.
