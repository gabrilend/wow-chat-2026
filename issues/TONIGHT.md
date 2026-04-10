# TONIGHT - Get Alpha Working

## Three Tiers

```
release = wow-chat-1 (vanilla)
alpha   = wow-chat-1 + playerbots  <-- TONIGHT
beta    = alpha + readme features
```

## Quick Commands

```bash
# Switch to release baseline
git checkout release

# Clean build
./scripts/azerothcore update --force

# Start MySQL
./scripts/start-mysql

# Start servers
./scripts/azerothcore authserver &
./scripts/azerothcore worldserver

# Test bots in-game
.bot add
```

## If Build Fails

1. Check error message
2. Apply minimal patch to fix
3. Rebuild
4. Document what was needed

## Files That Matter

- `scripts/azerothcore` - build script
- `patches/*.sh` - patch files (only use if needed)
- `source-release/` - source code
- `build-release/` - build artifacts
- `installed-files-release/` - binaries

## Current Profile

Check: `cat scripts/azerothcore | grep "^PROFILE="`

Switch if needed: edit line or use `./scripts/azerothcore switch release`

## Success =

1. Server runs
2. Login works
3. `.bot add` works
4. No crashes

That's it. Everything else is beta.
