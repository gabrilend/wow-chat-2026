# Profile Transition Flow

## Overview

Three profiles sharing same git branch, differentiated by file naming:

```
alpha   = wow-chat-1 baseline (old Eluna, earliest regression point)
release = Latest AzerothCore + playerbots, rock-solid features only
beta    = Lawless development space, all experimental features
```

**Key insight:** Files are labeled by profile (*.alpha.lua, *.beta.lua), all committed to same git branch.

## Profile States

### alpha
- Base: wow-chat-1 baseline (old Eluna)
- Known-good regression point
- Minimal features, proven stable
- Files: *.alpha.lua, alpha-*.sh patches
- Goal: Always works, earliest safe rollback point

### release
- Base: Latest AzerothCore + playerbots
- Only rock-solid, confirmed-working features
- Currently: Nothing extra beyond playerbots
- Files: *.release.lua (if any), regular patches
- Goal: Stable, deployable state

### beta
- Base: release + experimental features
- Lawless development space
- All in-progress features
- Files: *.beta.lua, regular patches
- Goal: Fast iteration, break things, learn

## Directory Structure

### Two Source Trees

```
source-alpha/              ← wow-chat-1 baseline (old Eluna)
  src/lua/
    *.alpha.lua            ← Alpha-specific scripts

source-beta/               ← Latest AzerothCore (shared by release & beta)
  src/lua/
    movement.lua           ← Shared scripts
    *.release.lua          ← Release-specific (if any)
    *.beta.lua             ← Beta experimental scripts

build-alpha/               ← Alpha build artifacts
build-release/             ← Release build artifacts
build-beta/                ← Beta build artifacts

installed-files-alpha/     ← Alpha binaries
installed-files-release/   ← Release binaries
installed-files-beta/      ← Beta binaries
```

### Profile Mapping

| Profile | Source Directory | Patches | Feature Level |
|---------|-----------------|---------|---------------|
| alpha   | source-alpha/   | alpha-*.sh | Minimal (wow-chat-1) |
| release | source-beta/    | *.sh | Playerbots only |
| beta    | source-beta/    | *.sh | All experimental |

### File Loading by Profile

**alpha:**
- Source: source-alpha/
- Scripts: *.alpha.lua
- Patches: alpha-*.sh
- Goal: Known-good baseline

**release:**
- Source: source-beta/
- Scripts: *.release.lua (if any), no-suffix files
- Patches: stable patches only
- Goal: Rock-solid, deployable

**beta:**
- Source: source-beta/
- Scripts: *.beta.lua, no-suffix files
- Patches: all patches
- Goal: Experimental features

### Transition Mechanics

**Switch to alpha:**
```bash
echo "alpha" > .current-profile
./scripts/azerothcore update
# Uses source-alpha/, builds to build-alpha/
```

**Switch to release:**
```bash
echo "release" > .current-profile
./scripts/azerothcore update
# Uses source-beta/, only stable features
```

**Switch to beta:**
```bash
echo "beta" > .current-profile
./scripts/azerothcore update
# Uses source-beta/, all experimental features
```

## Patch Pinning System

Each patch tracks which commits require it:

```
patches/B001-aoe-loot-item-namespace.sh
  # Required by: alpha@abc1234, beta@def5678
  # Reason: Upstream changed Item namespace

patches/B002-playerbots-ale-login-hook.sh
  # Required by: beta@ghi9012
  # Reason: Bot behaviors need ALE OnLogin
```

When checking out a commit, patches auto-apply if needed.

## Bugfix Commit Linking

Bugfixes are commits on the profile branch:

```
alpha branch:
  abc1234 - Initial alpha setup (playerbots enabled)
  def5678 - Fix: RandomPlayerbotMgr API compatibility
            (Triggered by: abc1234)

beta branch:
  ghi9012 - Add custom Lua behaviors
  jkl3456 - Fix: Lua OnLogin crash in behaviors
            (Triggered by: ghi9012)
```

Format: `Fix: {description} (Triggered by: {commit})`

## Transition Flow Script

```bash
./scripts/profile-switch <target-profile>
```

Actions:
1. Read current profile from `.current-profile`
2. Determine transition path (beta→alpha, alpha→release, etc)
3. Git checkout target branch in source directory
4. Apply/unapply patches based on target profile
5. Trigger rebuild if source changed
6. Update `.current-profile`
7. Report what changed

## Source Directory Unification

Instead of:
```
source-release/
source-alpha/
source-beta/
```

Use:
```
source/   ← Single directory, git tracks state
```

Profile determines git branch to checkout, not directory.

## Migration Plan

### Phase 1: Current State Capture
- Commit current beta state to beta branch
- Tag as `beta-2026-04-10-baseline`

### Phase 2: Alpha Branch Creation
- Create alpha branch from release
- Add minimal playerbots patches
- Commit as `alpha-2026-04-10-baseline`

### Phase 3: Release Verification
- Verify release branch is clean vanilla
- Tag as `release-2026-04-10-baseline`

### Phase 4: Transition Script
- Implement `./scripts/profile-switch`
- Test all transitions
- Document edge cases

### Phase 5: Patch Annotation
- Add "Required by" comments to all patches
- Map bugfixes to triggering commits
- Create patch dependency graph

## Benefits

1. **No duplicate source trees** - git manages state
2. **Instant switching** - `git checkout` instead of re-clone
3. **Automatic bugfix application** - commits follow branches
4. **Clear history** - git log shows evolution
5. **Easy rollback** - `git checkout <commit>`
6. **Shared base** - release changes propagate via merge

## Workflow Examples

### Fixing bug in alpha
```bash
./scripts/profile-switch alpha
# Make fix
git add -A
git commit -m "Fix: Bot spawning crash (Triggered by: abc1234)"
```

### Adding feature to beta
```bash
./scripts/profile-switch beta
# Implement feature
git add -A
git commit -m "feat(Lua): Add treasure spawn system"
```

### Merging alpha fixes to beta
```bash
git checkout beta
git merge alpha
# Alpha fixes automatically in beta
```

### Testing release still works
```bash
./scripts/profile-switch release
./scripts/azerothcore update
# Test vanilla server
```

## Patch State Matrix

| Patch | release | alpha | beta |
|-------|---------|-------|------|
| B001  | No      | Yes   | Yes  |
| B002  | No      | No    | Yes  |
| B003  | No      | No    | Yes  |
| B004  | No      | Yes   | Yes  |
| B005  | No      | No    | Yes  |
| B006  | No      | No    | Yes  |
| B007  | No      | No    | Yes  |
| B008  | No      | No    | Yes  |

Alpha needs: B001 (aoe-loot fix), B004 (warning fixes)
Beta needs: All 8 patches

## Next Steps

1. Commit current work to beta branch
2. Create alpha branch with minimal patches
3. Verify release branch is vanilla
4. Implement profile-switch script
5. Test all transitions
6. Document lessons learned
