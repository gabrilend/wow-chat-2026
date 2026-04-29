# 120 - Parallel Update Status Spinners

## Status: COMPLETED

## Current Behavior (After Implementation)

Both `./scripts/azerothcore install` and `update` commands run git status checks in parallel with live spinner feedback:
```
Checking for updates...
  ⠸ Checking Core...
  ⠸ Checking mod-ale...
  ⠸ Checking mod-aoe-loot...
  ⠸ Checking mod-grownup...
  ⠸ Checking mod-playerbots...
```

As each completes, its line updates:
```
  ✓ Core is up-to-date
  ✓ mod-ale is up-to-date
  ✓ mod-aoe-loot is up-to-date
  ✓ mod-grownup is up-to-date
  ✓ mod-playerbots is up-to-date
```

## Previous Behavior

Sequential checks - each git fetch blocked until complete, total time = sum of all check times.

## Implementation

### Functions Added (scripts/azerothcore:659-856)

1. `parallel_check_init` - Initialize arrays and temp directory
2. `parallel_check_add` - Add repo to check (name, dir, commit)
3. `parallel_check_worker` - Background worker, writes status to temp file
4. `parallel_check_display` - Render all lines with appropriate symbols
5. `parallel_check_run` - Start workers, poll, animate, collect results

### Status Values

- `checking` - Initial state, shows spinner
- `up-to-date` - Green ✓
- `needs-update` - Yellow ↓
- `missing` - Red ✗

### IPC Mechanism

- Temp files at `/tmp/wow-chat-2/parallel-checks/{name}.status`
- Workers write status, main thread polls every 100ms
- ANSI `\033[nA` to move cursor up, `\033[K` to clear line

### Commands Using Parallel Checks

- `cmd_install` - Checks existing repos after clone phase
- `cmd_update` - Checks all repos before pull phase

## Notes

- Core is treated the same as modules (first in list)
- Network is the bottleneck - parallel saves ~5x time with 5 repos
- Spinner uses braille dots: ⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏
