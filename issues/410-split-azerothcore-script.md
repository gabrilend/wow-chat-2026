# 410 - Split azerothcore Script Into Separate Commands

## Status
- Created: 2026-04-14
- Phase: 3
- Priority: Low

## Problem

The `scripts/azerothcore` script is a 2093-line monolith with a dispatcher pattern:
```bash
./scripts/azerothcore compile
./scripts/azerothcore update
./scripts/azerothcore apply-patches
```

The dispatcher adds unnecessary indirection. Each command should be its own script.

## Intended Behavior

Each command becomes a standalone script:

```
scripts/
├── azerothcore.conf.sh            # Shared config (profile defs, paths, arg parsing)
├── compile                        # Build to shadow
├── update                         # Pull + compile
├── install                        # First-time setup
├── apply-patches                  # Manual patch application
├── validate                       # Test shadow build
├── promote                        # Shadow → main
├── worldserver                    # Start worldserver
├── authserver                     # Start authserver
├── profiles                       # List profiles
├── switch                         # Switch profile
├── boost                          # Install boost
├── keira                          # Launch Keira3
└── extract-maps                   # (already separate)
```

Usage becomes:
```bash
./scripts/compile
./scripts/update
./scripts/apply-patches --begin --revert
./scripts/validate
./scripts/promote
./scripts/worldserver
```

### Shared Config

`scripts/azerothcore.conf.sh` contains:
- Profile definitions (PROFILE_REPO, PROFILE_BRANCH, etc.)
- Path functions (get_profile_paths)
- Common argument parsing (--profile, --threads)
- Shared helpers (check_git_status, parallel checks, spinners)

Each script starts with:
```bash
#!/bin/bash
DIR="/home/ritz/games/azeroth-core/wow-chat-2026"
source "${DIR}/scripts/azerothcore.conf.sh"
parse_args "$@"

# Command-specific code here
```

## Benefits

1. **Unix philosophy** - Each tool does one thing
2. **Simpler scripts** - No routing, no case statement
3. **Direct execution** - Run the script you want
4. **Easier to read** - Open one file, see one command
5. **Independent help** - Each script has its own --help

## Implementation Steps

### Phase 1: Create Shared Config
1. Create `scripts/azerothcore.conf.sh`
2. Move: profile definitions, get_profile_paths, parse_args, helpers
3. Test: `source azerothcore.conf.sh && echo $PROFILE`

### Phase 2: Extract Commands (simplest first)
For each command:
1. Create `scripts/{command}`
2. Add shebang, source config, move function body
3. Make executable: `chmod +x scripts/{command}`
4. Test the command
5. Remove from monolith

Order:
1. keira (no dependencies)
2. boost (standalone)
3. profiles, switch
4. authserver, worldserver
5. validate, promote
6. apply-patches
7. compile
8. update
9. install

### Phase 3: Delete Dispatcher
1. Remove `scripts/azerothcore` entirely
2. Or: keep as symlink farm / wrapper for backwards compatibility

## Example: scripts/validate

```bash
#!/bin/bash
# Validate shadow worldserver build before promotion
# Tests that worldserver starts and initializes successfully

DIR="/home/ritz/games/azeroth-core/wow-chat-2026"
source "${DIR}/scripts/azerothcore.conf.sh"
parse_args "$@"
get_profile_paths

echo "Validating shadow worldserver..."
echo "  Shadow: ${INSTALL_DIR_SHADOW}/bin/worldserver"

# Check binary exists
if [[ ! -f "${INSTALL_DIR_SHADOW}/bin/worldserver" ]]; then
    echo "  ERROR: worldserver not found in shadow"
    exit 1
fi

# Check config exists
if [[ ! -f "${INSTALL_DIR_SHADOW}/etc/worldserver.conf" ]]; then
    echo "  ERROR: worldserver.conf not found in shadow/etc/"
    exit 1
fi

# Start and validate
# ... rest of validation logic ...
```

## Common Issues

### Issue: "source: not found"
**Cause:** Running with sh instead of bash
**Fix:** Use `#!/bin/bash` shebang, run with `./scripts/command`

### Issue: "Variable not set"
**Cause:** Forgot to source config or call get_profile_paths
**Fix:** Every script needs: source config → parse_args → get_profile_paths

### Issue: "Command not found after split"
**Cause:** Old muscle memory typing `./scripts/azerothcore compile`
**Fix:** Update habits, or keep azerothcore as backwards-compat wrapper

## Backwards Compatibility (Optional)

If desired, keep `scripts/azerothcore` as a thin wrapper:
```bash
#!/bin/bash
DIR="/home/ritz/games/azeroth-core/wow-chat-2026"
CMD="$1"; shift
exec "${DIR}/scripts/${CMD}" "$@"
```

This lets old commands still work while transitioning.

## Related Files

- `scripts/azerothcore` - Current monolithic script (to be split)
- `scripts/extract-maps` - Already a separate script (good example)
- `patches/patches.sh` - Separate patch orchestration (stays as-is)
