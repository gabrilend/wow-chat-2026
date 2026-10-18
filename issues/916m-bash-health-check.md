# 916m - Bash Health Check in scripts/worldserver

## Status
- Created: 2026-06-03
- Parent: Issue 916 (mod-soren-chat)
- Phase: 3
- Priority: Low (purely operational nicety)
- Depends on: nothing — can land any time

## Overview

Pre-flight check in `scripts/worldserver` that verifies the model's
places (916d) are ready before launching the worldserver binary: each
"beside" place's `llama-server` answers, and the in-server library and
model file exist. Warns about places that are not ready but doesn't
block startup — the in-process health system (916f) handles per-request
degradation, so this is just an operator-visible signal at startup.
in-client places cannot be checked here: no player is connected yet.

## Current Behavior

`scripts/worldserver` starts the worldserver binary with no awareness
of mod-soren-chat or where its model runs. Operator has to look at
in-process logs after startup to know if the places are healthy.

## Intended Behavior

After this sub-issue lands, `./scripts/worldserver` produces output
like:

```
Checking Soren model places...
  ✓ llama-server ready at box1 (192.168.1.11:10101)
  ✓ llama-server ready at box2 (192.168.1.12:20202)
  … llama-server still loading its model at box3 (192.168.1.13:30303)
  ✓ in-server: libllama.so and models/<file>.gguf present

WARNING: 1 of 3 beside places not ready.
Soren chat will start with the others; 916f re-probes box3 every 60s.

Starting worldserver (profile: vanilla)
[...]
```

`llama-server`'s `/health` answers 200 when its model is loaded, 503
while it is still loading, and nothing at all when the program is not
running; the three are printed differently (✓, …, ✗). When every place
is ready, just checkmarks and no warning. When none is, a louder warning
but still proceeds.

## Configuration

Places defined in the script (must match `model_places` in
mod-soren-chat's `01-config.lua`):

```bash
declare -A LLAMA_SERVER_PLACES=(
    ["box1"]="192.168.1.11:10101"
    ["box2"]="192.168.1.12:20202"
    ["box3"]="192.168.1.13:30303"
)
IN_SERVER_MODEL="${DIR}/assets/models/<file>.gguf"   # empty when no in-server place
IN_SERVER_LIBRARY="${DIR}/libs/llama.cpp/lib/libllama.so"
```

Future improvement: source places from a shared config file that both
this script and the Lua config read, so they can't drift.

## Implementation Steps

1. Edit `scripts/worldserver`:
   - Add the `LLAMA_SERVER_PLACES` array and the two in-server paths
   - Add a check that curls each place's `/health` with a 2-second
     timeout and tests the in-server files exist
   - Call it after `parse_args`/`get_profile_paths` but before the
     actual exec of the worldserver binary
   - Gate on profile: only run the check where mod-soren-chat is enabled
     (for v0 just vanilla)
2. Use `curl -s --max-time 2 -o /dev/null -w "%{http_code}"`: 200 is
   ready, 503 is loading, 000 is not running or not reachable.
3. Print colorized output (green ✓, yellow … and ✗ in the warning case)
   for operator readability
4. Smoke test:
   - All three up → three checkmarks, no warning
   - Restart `llama-server` on one box and check while it loads → one …
   - Stop it on one box → one ✗, warning text, still starts
   - Stop all three → three ✗, louder warning, still starts
   - Rename the in-server model file → ✗ on the in-server line

## Behaviour Contract

- The check NEVER blocks startup. Worldserver always runs.
- The check NEVER tries to start `llama-server` itself — those machines
  are independent infrastructure.
- The check only runs on profiles that include mod-soren-chat.
- The check completes in ≤6 seconds total (2s timeout × 3 places; or
  parallelize for ≤2s).

## Files to Update

- `scripts/worldserver` — add the health check block

## Open Questions

- Should the check be in `scripts/worldserver` directly or in a
  separate `scripts/check-model-places` that worldserver calls? Direct
  is fine; the check is small.
- Should the check also confirm *which* model each `llama-server` loaded
  (`GET /props` reports its model path), not just that it is ready?
  Catches a box serving a different model than the config expects.
- Should we parallelise the checks? Saves a few seconds when multiple
  places are down. Easy with `&` and `wait`.

## Related

- Parent: [916 - mod-soren-chat](916-mod-soren-chat.md)
- [916d - The model runner](916d-llama-cpp-model-runner.md) — the three
  placements this checks two of
- [916f - Cluster health rotation](916f-cluster-health-rotation.md) —
  in-process equivalent that handles ongoing health
- [916n - Debug commands](916n-debug-commands-observability.md) —
  `.soren status` shows the live version of this same data
