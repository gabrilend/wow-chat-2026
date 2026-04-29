# 144 - Automatic Validate-Promote Pipeline

## Status: Completed (2026-04-18)

## Current Behavior

The build pipeline requires three manual commands:
```bash
./scripts/compile     # Build to shadow
./scripts/validate    # Test shadow build
./scripts/promote     # Copy shadow to main
```

Each step must be run manually. If the user forgets to run validate or promote,
the shadow build sits unused and the main installation remains stale.

The validate script uses a naive 30-second timeout with a single success string
("World initialized in"). This doesn't account for:
- Servers that initialize faster (wasted time)
- Servers that initialize slower (false failure)
- Module loading that happens after core init

## Intended Behavior

### Automatic Chaining

1. `compile` automatically calls `validate` on successful build
2. `validate` automatically calls `promote` on successful validation
3. Single command (`./scripts/update` or `./scripts/compile`) does everything

### Smart Validation Detection

Instead of fixed timeout, detect stability via output analysis:

1. **No new output** - If no new lines for N seconds, server is stable
2. **Repeating output** - If same line repeats (heartbeat), server is stable
3. **Unique line tracking** - Count unique lines; when count stops growing, done

Suggested algorithm:
```
Start worldserver
Track last_line_time and unique_lines set
Every 0.5 seconds:
  Read new output
  If new output:
    last_line_time = now
    Add to unique_lines
  If (now - last_line_time) > 5 seconds:
    Server is stable, validation passed
  If same line seen 3+ times consecutively:
    Server is in heartbeat mode, validation passed
  If timeout (60s max):
    Fail with warning
```

### Failure Modes

- Crash during startup: immediate failure
- ERROR/FATAL in log: immediate failure
- Timeout without stability: fail but suggest increasing timeout
- Stability achieved: pass and auto-promote

## Suggested Implementation Steps

### Step 1: Update validate script

Add smart output detection:
- Track unique lines via associative array
- Detect repeated consecutive lines (heartbeat)
- Detect output silence (stability)
- Remove hardcoded 30s timeout, use 60s max with early exit

### Step 2: Add auto-promote to validate

After successful validation:
- Call `./scripts/promote --profile ${PROFILE}`
- Print combined success message

### Step 3: Add auto-validate to compile

After successful build:
- Call `./scripts/validate --profile ${PROFILE}`
- validate will then auto-call promote

### Step 4: Add --no-validate flag to compile

For cases where user wants manual control:
- `./scripts/compile --no-validate` - build only, don't validate/promote

## Related Files

- scripts/compile - Needs to call validate on success
- scripts/validate - Needs smart detection and auto-promote
- scripts/promote - No changes needed
- scripts/update - Calls compile, so will inherit the chain

## Notes

The validate script must be careful to:
- Kill the worldserver cleanly after validation
- Not leave zombie processes
- Handle the case where worldserver won't stop (SIGKILL fallback)

The 5-second silence threshold works because:
- Worldserver outputs heartbeat every 10 seconds
- If we see 5 seconds of silence, we're between heartbeats = stable
- Alternatively, seeing 3 heartbeats means server is running stably

## Implementation Summary

**Date:** 2026-04-18

### Changes Made

**scripts/compile:**
- Added `AUTO_VALIDATE=true` configuration variable
- Added `--no-validate` flag to skip auto-validation
- Updated help text to reflect automatic pipeline
- After successful build, auto-calls `scripts/validate` via exec
- Pipeline: compile -> validate -> promote (all automatic)

**scripts/validate:**
- Rewrote `validate_shadow_worldserver()` with smart detection:
  - `SILENCE_THRESHOLD=5` - stable if no output for 5 seconds
  - `REPEAT_THRESHOLD=3` - stable if same line repeats 3 times (heartbeat)
  - `MAX_TIMEOUT=300` - hard timeout increased from 30s to 5 minutes
- Tracks line count and unique lines for output analysis
- Fast-path detection via "World initialized in" message
- Graceful shutdown with SIGKILL fallback for stuck processes
- Auto-calls `scripts/promote` on successful validation

### New Workflow

**Single command (recommended):**
```bash
./scripts/update        # Pulls, compiles, validates, promotes
# or
./scripts/compile       # Compiles, validates, promotes
```

**Manual control (if needed):**
```bash
./scripts/compile --no-validate   # Build only
./scripts/validate                # Test and promote
```

### Detection Algorithm

```
Start worldserver, track output
Every second:
  If crash -> FAIL
  If FATAL error -> FAIL
  If no new lines for 5s -> STABLE
  If same line 3x in row -> STABLE (heartbeat)
  If "World initialized in" -> wait 2s, STABLE
  If 5min elapsed -> TIMEOUT
On STABLE: kill server, call promote
```

### Benefits

1. **Single command** - No manual steps to forget
2. **Smart detection** - Exits early when stable, not fixed timeout
3. **Heartbeat detection** - Recognizes periodic server output
4. **Clean shutdown** - Graceful kill with SIGKILL fallback
5. **Manual override** - `--no-validate` for debugging
