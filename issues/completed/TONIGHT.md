# TONIGHT - Get Alpha Working

> **Archived 2026-08-07 as a historical artifact.** This was a
> one-evening scratch runbook from the period when the profile model
> was believed to be `release = wow-chat-1 (vanilla)`. That model is
> wrong and has been superseded by
> `issues/136-canonical-profile-definitions.md`, which is the
> canonical source for what each profile is. `source-release/` and
> `build-release/` as described below no longer reflect the tree —
> release and beta share `source-beta/`.
>
> `issues/phase-structure.md` (Loose Files — Disposition) called for
> this move. Kept rather than deleted because the three-tier framing
> here is the origin of the promotion pipeline that 136 formalized.

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
