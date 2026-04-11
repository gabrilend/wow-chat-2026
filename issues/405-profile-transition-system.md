# 405 - Profile Transition System

## Status
- Created: 2026-04-10
- Priority: Critical
- Phase: Foundation

## Problem

Current system uses separate source directories per profile:
```
source-release/
source-alpha/
source-beta/
```

This causes:
- Wasted disk space (3x source trees)
- Slow switching (re-clone required)
- Bugfixes don't propagate between profiles
- Hard to track what changed between profiles

## Solution

Use git branches to track profile states:

```
source/   ← Single directory
  release branch = vanilla
  alpha branch = vanilla + playerbots
  beta branch = alpha + custom features
```

## Implementation Steps

### 1. Unify Source Directory

**Current state:**
```bash
source-release/   # AzerothCore vanilla
source-alpha/     # (doesn't exist yet)
source-beta/      # liyunfan1223 fork
```

**Target state:**
```bash
source/           # Single directory, branch = profile
```

**Migration:**
```bash
# Rename source-beta to source
mv source-beta source

# Remove source-release (will use git checkout instead)
rm -rf source-release

# Update .gitignore
echo "build-*/" >> .gitignore
echo "installed-files-*/" >> .gitignore
```

### 2. Create Git Branches

**release branch:**
```bash
cd source
git checkout -b release origin/master
git tag release-2026-04-10-baseline
```

**alpha branch:**
```bash
git checkout -b alpha release
# Add minimal patches (B001, B004)
# Commit
git tag alpha-2026-04-10-baseline
```

**beta branch:**
```bash
git checkout -b beta alpha
# Add all custom features
# Commit current state
git tag beta-2026-04-10-baseline
```

### 3. Update Patch System

Patches need profile awareness:

```bash
# patches/patches.sh

apply_patches_for_profile() {
    local profile="$1"

    case "$profile" in
        release)
            # No patches
            ;;
        alpha)
            patch_B001_aoe_loot_item_namespace
            patch_B004_upstream_warning_fixes
            ;;
        beta)
            # All patches
            patch_B001_aoe_loot_item_namespace
            patch_B002_playerbots_ale_login_hook
            patch_B003_ale_gameobject_wildcard
            patch_B004_upstream_warning_fixes
            patch_B005_accuracy_level_cap
            patch_B006_ale_sell_item_hook
            patch_B007_ale_unit_methods
            patch_B008_mod_talent_bonus
            ;;
    esac
}
```

### 4. Create Profile Switch Script

**scripts/profile-switch**

```bash
#!/usr/bin/env bash
# profile-switch - Switch between release/alpha/beta profiles

set -euo pipefail

TARGET_PROFILE="$1"
CURRENT_PROFILE="$(cat .current-profile)"
SOURCE_DIR="source"

echo "Switching: $CURRENT_PROFILE → $TARGET_PROFILE"

# Git checkout target branch
cd "$SOURCE_DIR"
git checkout "$TARGET_PROFILE"
cd ..

# Update profile marker
echo "$TARGET_PROFILE" > .current-profile

# Trigger rebuild
echo "Rebuilding for $TARGET_PROFILE profile..."
./scripts/azerothcore update

echo "✓ Switched to $TARGET_PROFILE"
```

### 5. Update Build Script

**scripts/azerothcore** changes:

```bash
# Old:
AC_CODE_DIR="${DIR}/source-${PROFILE}"

# New:
AC_CODE_DIR="${DIR}/source"

# Git checkout happens in profile-switch
# Build script just compiles what's checked out
```

### 6. Lua Script Management

Lua scripts track profile in filename:

```bash
src/lua/
  movement.lua                # All profiles
  death-knights.lua           # All profiles

  ambush.beta.lua             # Beta only
  travel.beta.lua             # Beta only
  levelling.beta.lua          # Beta only
  behaviors.beta/             # Beta only
```

ALE loads scripts matching current profile:
```lua
-- In ALE config
LoadScriptPattern("src/lua/*.lua")              -- Always
LoadScriptPattern("src/lua/*.${PROFILE}.lua")   -- Profile-specific
```

### 7. Module Management

Modules track profile via git:

```bash
# release branch
modules/
  mod-ale/
  mod-aoe-loot/
  mod-grownup/

# alpha branch (adds playerbots)
modules/
  mod-ale/
  mod-aoe-loot/
  mod-grownup/
  mod-playerbots/

# beta branch (adds custom modules)
modules/
  mod-ale/
  mod-aoe-loot/
  mod-grownup/
  mod-playerbots/
  mod-talent-bonus/
```

Each profile's git branch has correct modules checked in.

## Benefits

1. **Instant switching**: `git checkout` takes seconds
2. **Automatic propagation**: `git merge alpha` brings fixes to beta
3. **Clear history**: `git log --graph --all` shows evolution
4. **Disk efficient**: One source tree instead of three
5. **Rollback friendly**: `git checkout <commit>` to any state

## Testing Plan

### Test 1: Switch beta → alpha
```bash
./scripts/profile-switch alpha
# Verify:
# - .current-profile = "alpha"
# - source/ on alpha branch
# - mod-playerbots present
# - mod-talent-bonus absent
# - Custom Lua disabled
# - Server compiles
```

### Test 2: Switch alpha → release
```bash
./scripts/profile-switch release
# Verify:
# - .current-profile = "release"
# - source/ on release branch
# - mod-playerbots absent
# - All custom features absent
# - Vanilla server compiles
```

### Test 3: Switch release → beta
```bash
./scripts/profile-switch beta
# Verify:
# - .current-profile = "beta"
# - source/ on beta branch
# - All modules present
# - All Lua enabled
# - Full feature set compiles
```

### Test 4: Bugfix propagation
```bash
# Fix bug on alpha
./scripts/profile-switch alpha
git commit -m "Fix: Bot crash on login"

# Merge to beta
./scripts/profile-switch beta
git merge alpha
# Bugfix now in beta automatically
```

## Migration Checklist

- [ ] Commit current beta state
- [ ] Rename source-beta → source
- [ ] Remove source-release
- [ ] Create release branch from upstream
- [ ] Create alpha branch from release
- [ ] Verify beta branch has all features
- [ ] Update patches.sh with profile awareness
- [ ] Create profile-switch script
- [ ] Update .gitignore
- [ ] Test all transitions
- [ ] Document final workflow

## Success Criteria

1. Single source directory
2. Three git branches (release, alpha, beta)
3. `./scripts/profile-switch <profile>` works
4. Patches apply based on profile
5. Bugfixes merge from alpha → beta
6. All profiles compile and run

## Related Files

- `docs/profile-transition-flow.md` - Design document
- `scripts/profile-switch` - Switching script
- `patches/patches.sh` - Profile-aware patches
- `.current-profile` - Active profile marker

## Notes

Git is the version control system. Let it do version control.
We don't need three copies of the same source tree.
Branches are cheap. Disk space is not.
