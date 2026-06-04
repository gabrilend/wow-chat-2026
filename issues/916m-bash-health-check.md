# 916m - Bash Health Check in scripts/worldserver

## Status
- Created: 2026-06-03
- Parent: Issue 916 (mod-soren-chat)
- Phase: 3
- Priority: Low (purely operational nicety)
- Depends on: nothing — can land any time

## Overview

Pre-flight check in `scripts/worldserver` that verifies the three
Ollama boxes are reachable before launching the worldserver binary.
Warns about unreachable boxes but doesn't block startup — the in-process
health system (916f) handles per-request degradation, so this is just
an operator-visible signal at startup.

## Current Behavior

`scripts/worldserver` starts the worldserver binary with no awareness
of mod-soren-chat or the Ollama cluster. Operator has to look at
in-process logs after startup to know if the cluster is healthy.

## Intended Behavior

After this sub-issue lands, `./scripts/worldserver` produces output
like:

```
Checking Soren Ollama cluster...
  ✓ Ollama reachable at box1 (192.168.1.11:10101)
  ✓ Ollama reachable at box2 (192.168.1.12:20202)
  ✗ Ollama UNREACHABLE at box3 (192.168.1.13:30303)

WARNING: 1 of 3 Ollama hosts unreachable.
Soren chat will operate in degraded mode (default playerbots behavior
on unreachable hosts; round-robin will skip failed boxes).

Starting worldserver (profile: vanilla)
[...]
```

When all three are healthy, just three checkmarks and no warning. When
all three are down, a louder warning but still proceeds (worldserver
runs without LLM features, falls back to default playerbots).

## Configuration

Hosts defined in the script (must match `01-config.lua` in mod-soren-chat):

```bash
declare -A OLLAMA_HOSTS=(
    ["box1"]="192.168.1.11:10101"
    ["box2"]="192.168.1.12:20202"
    ["box3"]="192.168.1.13:30303"
)
```

Future improvement: source hosts from a shared config file that both
this script and the Lua config read, so they can't drift.

## Implementation Steps

1. Edit `scripts/worldserver`:
   - Add the `OLLAMA_HOSTS` associative array
   - Add `check_ollama_hosts()` function that curls each host's
     `/api/tags` endpoint with a 2-second timeout
   - Call `check_ollama_hosts` after `parse_args`/`get_profile_paths`
     but before the actual exec of the worldserver binary
   - Gate on profile: only run the check if `PROFILE=vanilla` (or
     wherever mod-soren-chat is enabled — for v0 just vanilla)
2. Use `curl -s --max-time 2 -o /dev/null -w "%{http_code}"` to get the
   HTTP status without output noise. 200 means healthy.
3. Print colorized output (green ✓, yellow ✗ in the warning case) for
   operator readability
4. Smoke test:
   - Run with all three boxes up → confirm three checkmarks, no warning
   - Stop Ollama on one box → confirm one ✗, warning text, still starts
   - Stop all three → confirm three ✗, louder warning, still starts

## Behaviour Contract

- The check NEVER blocks startup. Worldserver always runs.
- The check NEVER tries to start Ollama itself — those boxes are
  independent infrastructure.
- The check only runs when profile = vanilla (or future profiles that
  include mod-soren-chat).
- The check completes in ≤6 seconds total (2s timeout × 3 hosts; or
  parallelize for ≤2s).

## Files to Update

- `scripts/worldserver` — add the health check block

## Open Questions

- Should the check be in `scripts/worldserver` directly or in a
  separate `scripts/check-ollama` that worldserver calls? Direct is
  fine; the check is small.
- Should the check also probe model availability (`/api/show` for
  `llama3.2:1b`) not just daemon liveness? Lean no — model presence is
  verified by the in-process workers, and we don't want startup to
  drag on a slow model-show call.
- Should we parallelise the three checks? Saves a few seconds when
  multiple hosts are down. Easy with `&` and `wait`.

## Related

- Parent: [916 - mod-soren-chat](916-mod-soren-chat.md)
- [916f - Cluster health rotation](916f-cluster-health-rotation.md) —
  in-process equivalent that handles ongoing health
- [916n - Debug commands](916n-debug-commands-observability.md) —
  `.soren status` shows the live version of this same data
