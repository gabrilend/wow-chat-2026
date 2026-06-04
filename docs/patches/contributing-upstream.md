# Contributing Patches Upstream

When one of our B-patches fixes a bug that affects all users of the upstream
project (mod-ale, mod-playerbots, AzerothCore core), the right destination
for the fix is upstream — not as a permanent local workaround. Submitting
upstream benefits everyone, eventually retires our patch, and removes one
source of drift maintenance from our project.

This document explains how to translate a B-patch into a clean upstream
pull request.

---

## Why our patches aren't already PR-shaped

Our B-patches are **sed scripts** designed for a specific lifecycle:
apply at PHASE_BEGIN, compile, revert at PHASE_END so the source tree
stays clean. They're idempotent on apply and unpatch. They use marker
comments for multi-line insertions so the round-trip never drifts.

Upstream wants a **clean git commit on a feature branch**, applied
directly to upstream's tree, with a PR description, and no project-local
marker comments. The fix is the same; the encoding is different.

The translation step is mechanical but easy to get wrong. This doc
codifies it.

---

## Which upstream repository

Each B-patch targets one of three repos. Look at the patch's
`AC_CODE_DIR`-relative paths to determine which:

| Path prefix in patch                                | Upstream repo                                              | Notes                                                                                                              |
|-----------------------------------------------------|-----------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| `src/server/...` or `src/common/...` or `src/tools/...` | `azerothcore/azerothcore-wotlk`                            | The core. Our B022 (conf-dir override) targets this.                                                                |
| `modules/mod-ale/src/...`                           | `azerothcore/mod-eluna`                                    | Our fork renamed Eluna to ALE; upstream still uses "Eluna". Strip the rename when porting. Our B020/B023 target this. |
| `modules/mod-playerbots/src/...`                    | `liyunfan1223/mod-playerbots` (the active fork upstream)   | Most warning-fix B-patches target this. Our B013–B019, B021 target this.                                            |

If a patch touches more than one repo, split it into separate PRs.

---

## Step-by-step

### 1. Clone upstream in a scratch directory

Don't reuse our source-beta tree — its history and any in-flight local
state would contaminate the PR. Use a fresh workspace.

```bash
cd ~/scratch
git clone https://github.com/<org>/<repo>.git upstream-<repo>
cd upstream-<repo>
git checkout -b fix/<short-descriptive-name>
```

For mod-ale upstream: `https://github.com/azerothcore/mod-eluna.git`.

### 2. Read the B-patch to understand the edit

Open `patches/B0XX-*.sh` in our repo. Look at the `patch_B0XX_*`
function. For each `sed` call, work out what the edit *is* — not how
the sed encodes it. The marker comments (`// {{{ B0XX-name ... // }}} B0XX-name`)
are project-local scaffolding; **strip them**. Upstream gets the
substantive code change only.

For substitutions (`sed s|OLD|NEW|`), the edit is "replace OLD with NEW
where NEW excludes any marker comments."

For insertions (`sed /anchor/a\ ...`), the edit is "insert the
marker-bounded block at the anchored position, then delete the marker
lines."

### 3. Make the edit by hand in the upstream tree

Open the target file in your editor. Apply the change exactly as the
B-patch describes — but without the markers. The result should look
like what the file would look like if upstream had written the fix
themselves.

### 4. Verify the build still works upstream

Build upstream against its own setup, **not against our project's
build harness**. The point is to prove the fix compiles cleanly in
upstream's environment, not in ours.

```bash
mkdir build && cd build
cmake .. -DTOOLS_BUILD=all
make -j$(nproc)
```

If upstream has tests, run them. Module repos (mod-eluna, mod-playerbots)
build via the core's harness — clone azerothcore-wotlk, drop the module
in `modules/`, configure with the module enabled.

### 5. Write the commit message

Match the upstream project's style — look at recent merged PRs for
voice and structure. Generally:

- **Title**: short, imperative ("Fix dangling pointer in FormatQuery sync paths")
- **Body**:
  - **What**: a one-paragraph plain-language description of the bug
  - **Why**: how the bug manifests (a symptom, a crash, a wrong result)
  - **How**: what the fix does and why it's correct
  - **Reproduction**: minimal code/SQL/Lua that triggers the bug, if useful
  - **Affected versions**: how far back the bug exists, found via `git log -S`

Do not mention our project, our B-patch system, or our fork's naming.
Upstream readers don't have that context.

### 6. Open the PR

```bash
git push origin fix/<short-descriptive-name>
gh pr create --title "Fix ..." --body "$(cat <<'EOF'
## Summary
<one-sentence>

## What
<paragraph>

## Why
<paragraph>

## How
<paragraph>

## Reproduction
```
<code>
```
EOF
)"
```

### 7. Cross-reference back in our tree

Add a single line to the originating B-patch's issue file (e.g.
`issues/141-...`):

```
- Submitted upstream as <repo>#<PR-number> on YYYY-MM-DD
```

Update the same line when the PR merges or closes.

### 8. After upstream merges

When upstream merges the fix and the next pull brings it into
`source-beta`, the B-patch's `patch_needs_applying_BXXX` witness
returns "already applied" and the patch becomes a no-op. At that
point:

1. Remove the patch ID from `PHASE_BEGIN_PATCHES` in `patches.sh`
   for every profile that listed it.
2. Move `patches/B0XX-*.sh` to `patches/retired/B0XX-*.sh`. **Do not
   delete** — preserve the historical record of what we fixed and why.
3. Update `issues/126-upstream-warning-fixes.md` inventory table:
   change the patch's status to "upstream-adopted in commit `<sha>`".
4. Close the originating issue (`issues/141-...` etc.) with a final
   line: "Resolved upstream in commit `<sha>`; B0XX retired."

This is the lifecycle the `-Werror` goal in issue 126 describes:
patches are *temporary scaffolding*, upstream is the destination, and
retirement is the win.

---

## When NOT to submit upstream

Some B-patches are project-local by nature and should never be
submitted:

- **Configuration patches (`C-patches`)**: these set our specific
  credentials, paths, gameplay knobs. Not upstream-relevant.
- **Feature patches that depend on our architecture**: e.g. B022's
  runtime conf-dir override might be upstream-able (it's a generic
  improvement), but if it depended on our specific shadow/release
  layout, it would not be.
- **Workarounds for behavior we want but upstream doesn't**: e.g. if
  we patched mod-playerbots to disable a feature we don't want, that's
  ours alone. Upstream wouldn't accept it.

The general test: would another AzerothCore server administrator benefit
from this fix without changing their gameplay? If yes, upstream it. If
no, keep it local.

---

## Quick reference: example workflow for B023

Hypothetical timeline for our FormatQuery fix:

1. We discover the dangling pointer bug while diagnosing why the
   `.disabled` ambush.lua existed.
2. Write `patches/B023-ale-formatquery-lifetime.sh` for our local build.
3. Create `issues/141-ale-formatquery-dangling-pointer.md` with the
   bug analysis.
4. Clone `azerothcore/mod-eluna` to a scratch dir.
5. Apply the fix manually to upstream — same code change as our B-patch,
   but without `// {{{ B023-... // }}}` markers.
6. Build upstream, confirm clean.
7. Open PR with title "Fix dangling pointer in WorldDBQuery/CharDBQuery
   sync paths when using parameterized queries".
8. Note the PR number in issue 141 and the patch file's header comment.
9. When merged: retire B023, update inventory, close issue 141.

The fix lives in three places during transition (our B-patch, the PR,
the eventual upstream commit) and in one place after retirement (the
upstream commit). Drift is bounded by retirement.
