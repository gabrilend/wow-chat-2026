# 148 - modules-release vs modules-beta Redundancy

## Status
- Created: 2026-05-19
- Phase: 1 (Foundation — build infrastructure cleanup)
- Priority: Low (current state works; cleanup is hygiene)

## Problem

`scripts/install`'s `update_modules_symlink` retargets `source-beta/modules`
to either `${DIR}/modules-release/` or `${DIR}/modules-beta/` depending on
which profile is active. The original rationale was that each profile
could have its own module versions.

That rationale is no longer accurate. Per the canonical profile model in
issue 136, **release and beta share the same source tree (`source-beta`)
and the same compile**. They differ only in:

- Which **B-patches** are applied at build time (release uses a subset;
  beta uses all)
- Which **C-patches** tune the runtime configs (max level, exp rate, etc.)

The **modules themselves are identical** between release and beta. They
have to be — the modules are linked into the same binary built from the
same source. Maintaining two separate `modules-*/` directories that
should contain identical content is a recipe for drift.

(Alpha is genuinely different — it uses `source-alpha` with mod-eluna
instead of mod-ale. Alpha modules legitimately diverge.)

## Current Behavior

- `modules-release/` exists at project root (currently contains
  `mod-playerbots/`)
- `modules-beta/` exists at project root (contains `mod-ale`,
  `mod-aoe-loot`, `mod-grownup`, `mod-playerbots`)
- `scripts/install:update_modules_symlink` retargets the source symlink
  based on profile, so building release sees the
  `modules-release/`-tree's modules and building beta sees the
  `modules-beta/`-tree's modules
- The two trees can silently drift apart since nothing enforces them
  being identical

## Intended Behavior

Release and beta share one modules tree. Three options:

### Option A — Symlink modules-release to modules-beta

```bash
ln -sfn modules-beta modules-release
```

Simplest. Both directories effectively become the same thing. The
existing `update_modules_symlink` logic continues to work unchanged.

### Option B — Rename modules-beta to modules-shared

```bash
git mv modules-beta modules-shared
```

Then update `update_modules_symlink` to point both release and beta
arms at `../modules-shared`. Clearer naming; no more "is the beta
directory really the one I want for release?"

### Option C — Drop the symlink mechanism entirely

If release and beta share modules, `source-beta/modules` could just be
a regular directory or a single symlink to the shared modules dir, with
no per-profile retargeting at all. Alpha's separate
`source-alpha/modules` handles its own.

**Recommendation: Option B**. The rename clarifies intent and the
mechanism stays explicit. Option A is the smallest diff but leaves a
misleading directory name in the tree.

## Suggested Implementation Steps

1. Audit `modules-release/` vs `modules-beta/` contents. If they differ,
   determine whether the difference is intentional (it shouldn't be) or
   drift (it probably is) and reconcile.
2. Rename `modules-beta/` to `modules-shared/`.
3. Update `scripts/install:update_modules_symlink` so both `release` and
   `beta` arms point at `../modules-shared`.
4. Remove `modules-release/` (or leave as a symlink to `modules-shared/`
   for one release-cycle for backward compatibility).
5. Update `issues/136-canonical-profile-definitions.md` to note that
   release and beta share `modules-shared/`.
6. Confirm a fresh `compile --force` for both profiles produces
   equivalent binaries (modulo the patch-set differences).

## Affected Files

- `modules-beta/` → `modules-shared/` (rename)
- `modules-release/` (delete or symlink)
- `scripts/install` (case-switch retarget)
- `issues/136-canonical-profile-definitions.md` (documentation update)

## Related Issues

- **136** canonical-profile-definitions — established that release and
  beta share `source-beta`; this issue follows the implication through
  to the modules tree.

## Notes

This is a vestige of an earlier design where release was wow-chat-1
(mod-eluna, no playerbots) and beta was the modern fork. Under that
model, modules genuinely differed. The model in 136 collapsed release
and beta onto the same source; the modules infrastructure has been
slow to catch up.
