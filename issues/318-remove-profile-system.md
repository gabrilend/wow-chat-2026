# 318 - Remove Profile System, Switch to Git Branches

## Status
- Created: 2026-04-07
- Phase: 2
- Priority: Medium

## Current Behavior

The project uses a "profile system" with three profiles: alpha, beta, release.

Each profile has its own:
- `source-{profile}/` - Cloned AzerothCore source
- `build-{profile}/` - CMake build directory
- `installed-files-{profile}/` - Compiled binaries
- `config/{profile}/` - Config symlinks
- `logs-{profile}` - Runtime logs

The `./scripts/azerothcore` script manages this via:
- `PROFILE_REPO`, `PROFILE_BRANCH`, `PROFILE_COMMIT` arrays
- `PROFILE_MODULES` for per-profile module selection
- `.current-profile` file tracking active profile
- `switch` command to change profiles

### Problems with Current System

1. **Complexity without benefit** - In practice, only beta is used
2. **Disk space waste** - Multiple source clones (~2GB each)
3. **Confusion** - Profile vs git branch semantics overlap
4. **Script complexity** - Many profile-aware code paths
5. **Alpha unused** - All alpha directories are empty

## Intended Behavior

Replace profile system with git branches:
- **beta branch** - Current development work
- **release branch** - Stable snapshot (June 2023 compatible)

### Directory Structure (After)

```
wow-chat-2026/
├── source/              # Single AzerothCore clone (currently on beta branch)
├── build/               # Single build directory
├── installed-files/     # Single install directory
├── config/              # Config files (no subdirs)
└── logs -> /tmp/...     # Single logs symlink
```

### Switching Versions

```bash
# To switch to release:
cd source/
git checkout release
cd ..
./scripts/azerothcore update --force

# To switch to beta:
cd source/
git checkout beta
cd ..
./scripts/azerothcore update --force
```

### Branch Definitions

**beta branch:**
- Tracks: `liyunfan1223/azerothcore-wotlk` Playerbot branch
- Modules: mod-ale, mod-aoe-loot, mod-grownup, mod-playerbots

**release branch:**
- Tracks: `azerothcore/azerothcore-wotlk` master @ a779cca9e3a3d673
- Modules: mod-eluna (commit 1abf244)
- Purpose: wow-chat-1 compatibility, known good state

## Suggested Implementation Steps

### Step 1: Verify Alpha is Empty (Done)
- [x] Check source-alpha/ - empty
- [x] Check build-alpha/ - empty
- [x] Check installed-files-alpha/ - empty
- [x] Check config/alpha/ - doesn't exist

### Step 2: Remove Alpha Directories
```bash
rmdir source-alpha build-alpha installed-files-alpha
```

### Step 3: Rename Beta to Standard Names
```bash
# After current compile completes!
mv source-beta source
mv build-beta build
mv installed-files-beta installed-files
mv logs-beta logs
mv config/beta/* config/
rmdir config/beta
```

### Step 4: Update Symlinks
Update `/home/ritz/programming/lua/azerothcore/` symlinks to new paths.

### Step 5: Simplify azerothcore Script

Remove from `scripts/azerothcore`:
- `PROFILE_*` associative arrays
- `PROFILE` variable and `.current-profile` file
- `get_profile_paths()` function
- `cmd_profiles()` and `cmd_switch()` commands
- Profile suffixes throughout

Replace with:
- Static paths: `AC_CODE_DIR="${DIR}/source"`, etc.
- Document branch switching in help text

### Step 6: Handle Release Profile

Options:
1. **Delete source-release/** - If not needed, just remove it
2. **Keep as archive** - Rename to `source-release-archive/` and ignore
3. **Create release branch** - In main source/, create a local branch tracking the pinned commit

Recommendation: Option 1 (delete). The commit hash is documented in this issue if ever needed again.

### Step 7: Update Documentation

Files to update:
- `docs/table-of-contents.md` - Remove profile references
- `docs/roadmap.md` - Remove profile mentions
- `README.md` - Update build instructions
- `CLAUDE.md` - Update directory references

### Step 8: Clean Up Config Directory

```bash
# Flatten config/beta/ to config/
# Config files are already symlinks to installed-files-beta/etc/
# After renaming, update symlinks to point to installed-files/etc/
```

## Files to Modify

- `scripts/azerothcore` - Major simplification
- `docs/table-of-contents.md` - Remove profile section
- `docs/roadmap.md` - Update directory references
- `README.md` - Simplify build instructions
- `CLAUDE.md` - Update Session Initialization section

## Files to Delete

- `source-alpha/` (empty)
- `build-alpha/` (empty)
- `installed-files-alpha/` (empty)
- `source-release/` (after documenting commit hash)
- `build-release/`
- `installed-files-release/`
- `config/release/`
- `.current-profile`

## Preserved Information

For future reference, the release profile was:
- Repository: `https://github.com/azerothcore/azerothcore-wotlk.git`
- Branch: `master`
- Commit: `a779cca9e3a3d673761d6bbe6d1c5d1f51c2f6f3` (June 27, 2023)
- Module: mod-eluna @ commit `1abf244`

## Testing

1. Build completes with simplified script
2. Server starts correctly
3. Lua scripts load
4. Playerbots spawn
5. All symlinks resolve correctly

## Notes

- Do NOT start until current beta compile finishes
- The release profile hasn't been used in months
- Alpha was never implemented (all directories empty)
- This simplification reduces cognitive overhead significantly
