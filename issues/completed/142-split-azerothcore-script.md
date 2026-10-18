# 142 - Split azerothcore Script Into Separate Commands

## Status
- Created: 2026-04-14
- Completed: 2026-04-14
- Phase: 3

## Problem

The `scripts/azerothcore` script was a 2093-line monolith with a dispatcher pattern:
```bash
./scripts/azerothcore compile
./scripts/azerothcore update
./scripts/azerothcore apply-patches
```

The dispatcher added unnecessary indirection. Each command should be its own script.

## Solution Implemented

Each command became a standalone script with:
- Hard-coded `DIR` path at top
- Profile definitions duplicated in each script (no shared dependency)
- Independent argument parsing per script
- Scripts call each other where appropriate (update→compile, install→compile)

### Scripts Created

```
scripts/
├── compile            # Build to shadow (sources patches/patches.sh)
├── update             # Pull + calls compile
├── install            # First-time setup + calls compile
├── apply-patches      # Manual patch application
├── redownload-source  # Remove source for fresh re-clone
├── validate           # Test shadow build
├── promote            # Shadow → main
├── worldserver        # Start worldserver
├── authserver         # Start authserver
├── profiles           # List profiles
├── switch             # Switch profile
├── boost              # Install Boost 1.74.0
├── keira              # Launch Keira3
└── extract-maps       # (already existed)
```

### Profile System

Profile stored in `.profile` file (simple text file containing just the profile name):
```bash
$ cat .profile
release
```

Each script loads the profile:
```bash
if [[ -f "${DIR}/.profile" ]]; then
    PROFILE="$(cat "${DIR}/.profile")"
else
    PROFILE="release"
fi
```

### Script Interactions

- `update` checks git status, pulls updates, then exec's `compile`
- `install` clones repos, calls `compile`, then does MySQL setup
- `compile` sources `patches/patches.sh` for patch functions

### Deprecated Files

Renamed to `-deprecated` (will be removed after one commit):
- `scripts/azerothcore-deprecated` - old monolithic dispatcher
- `scripts/profile-switch-deprecated` - old profile switcher using `.current-profile`

Removed:
- `.current-profile` - replaced by `.profile`

## Usage

```bash
./scripts/profiles                    # List profiles
./scripts/switch beta                 # Switch profile
./scripts/compile                     # Build to shadow
./scripts/validate                    # Test shadow build
./scripts/promote                     # Shadow → main
./scripts/worldserver                 # Start worldserver
./scripts/authserver                  # Start authserver
./scripts/update                      # Pull and rebuild
./scripts/install                     # First-time setup
./scripts/redownload-source           # Remove source for re-clone
./scripts/apply-patches --dry-run     # Preview patches
./scripts/boost                       # Install Boost
./scripts/keira                       # Launch database editor
```

### Fresh Install Workflow

Instead of `--force` flags, use explicit preparation scripts:
```bash
./scripts/redownload-source           # Remove source directory
./scripts/install                     # Detects missing source, re-clones
```

This way `install` checks if source exists - if not, it clones. The `redownload-source`
script explicitly handles the "remove for re-clone" action, making the workflow visible.

## Design Decisions

1. **No shared config file** - Profile definitions duplicated in each script
   - Simpler to understand each script in isolation
   - No hidden dependencies
   - Each script has specific I/O requirements

2. **Scripts call scripts** - Rather than duplicating build logic
   - `update` calls `compile` after git operations
   - `install` calls `compile` then continues with MySQL setup
   - Follows Unix philosophy of composable tools

3. **Profile as simple text file** - Just contains "release", "beta", or "alpha"
   - Easy to read programmatically
   - Easy to manually edit
   - No complex parsing needed

4. **Decompose --force into explicit actions** - Instead of `--force` flags
   - `redownload-source` removes source so `install` will re-clone
   - `compile --force` only forces cmake reconfig (minimal scope)
   - Each action is its own script, visible in the workflow
   - Scripts detect missing state and act accordingly

## Related Files

- `patches/patches.sh` - Patch orchestration (sourced by compile)
- `.profile` - Current profile name
- `scripts/start-mysql` - MySQL management (unchanged)
- `scripts/stop-mysql` - MySQL management (unchanged)

## Since then (checked 2026-10-17)

- **The split stands**: one script per command in `scripts/`, the old
  monolith kept as `scripts/azerothcore-deprecated`. The `scripts/azerothcore`
  name itself stayed a while longer and was deleted on 2026-06-04 (6ee263b,
  with the vanilla rule set); the project's CLAUDE.md "Build and Run" still
  shows `./scripts/azerothcore update`, `authserver`, `worldserver`, which
  are now `scripts/update`, `scripts/authserver`, `scripts/worldserver`
  (left for the owner, who keeps that file). Commands have been
  added since (`switch`, `promote`, `teach-character-lessons`, the
  generators and tests).
- **The cost of "profile definitions duplicated in each script"** showed
  up: by October the copies disagreed. The alpha profile pointed at the
  playerbots fork in `install` and `switch` (since this split), while the
  real alpha tree is upstream AzerothCore (issue 134); `scripts/profiles`
  listed release with modules it does not build. Corrected 2026-10-17, and
  `scripts/test-profile-tables-agree` now compares every copy of every
  profile table key by key, before every build. The duplication itself is
  kept, as this issue chose (no script depends on another's file).
- **Number clash**: 142 is also held by an open issue
  (`issues/142-symmetric-aggro-radius.md`), made on 2026-05-21, after this
  one (2026-04-14) had kept 142 through the April renumbering (the legacy
  142, custom-spell-system, became 702). The number looked free because
  finished issues live in `completed/`; `validate-issues --next` now looks
  there too. Name them with their slugs: "142" in issues 126 and 801
  means the aggro radius, and 710's old "142 - Custom spell system" meant
  the legacy 142, now 702. (Corrected 2026-10-17 by the fronts-homework
  session: this note first said the renumbering gave 142 to the other.)
