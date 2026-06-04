# 916i - Response Validator and Directive Application

## Status
- Created: 2026-06-03
- Parent: Issue 916 (mod-soren-chat)
- Phase: 3
- Priority: High
- Depends on: 916b (ChangeStrategy binding), 916e (consumes responses), 916h (schema definition)

## Overview

Two adjacent responsibilities bundled into one sub-issue because they
share the same per-response code path:

1. **Response validator** — parses the LLM's JSON output, checks it
   against the schema from 916h, rejects unknown strategy/action names,
   bounds-checks multipliers, retries once on failure
2. **Directive application** — translates validated directives into
   actual `SorenBindings.change_strategy()` calls and policy state
   updates per bot

Together they're the "consume side" of the worker pool — they're what
the response draining loop does with each LLM result.

## Current Behavior

No response handler exists. Guidance requests submitted in 916g would
return responses to the outbox channel but nothing would consume them.

## Intended Behavior

After this sub-issue lands, the main worldserver tick (or a small
periodic timer) drains responses from the worker pool and routes each
to the appropriate handler:

```lua
local responses = workers.drain()
for _, response in ipairs(responses) do
    if response.type == "guidance" then
        handle_guidance_response(response)
    elseif response.type == "chat" then
        handle_chat_response(response)
    end
end
```

`handle_guidance_response` does:

1. Attempt to parse `.text` as JSON
2. Validate against the schema from 916h:
   - Top level has `party_intent` (string) and `directives` (array)
   - Each directive has `bot` (string, must be a known bot in this party)
   - `strategies_add` / `strategies_remove` are arrays of strings;
     each name must pass `SorenBindings.is_strategy_known(name)`
   - `multiplier_overrides` values are numbers in [0.0, 2.0]
   - `stance` is one of the allowed enum values
3. On validation failure, log and retry once with a follow-up prompt:
   "Your previous output was malformed: {error}. Please return strict
   JSON matching the schema."
4. On second validation failure, fall back to no-op (bots keep prior
   policy or default playerbots)
5. On success, apply each directive:
   - Look up bot guid by name
   - Compose strategy edit string: `+s1,+s2,-s3,-s4`
   - Call `SorenBindings.change_strategy(guid, edits, "combat")`
   - Store per-bot policy state (stance, focus, multiplier_overrides)
     in a Lua table the SorenDirected strategy (916j) will read

## Validation Schema Reference

Re-stated from 916h for convenience:

```json
{
  "party_intent": "string",
  "directives": [
    {
      "bot": "string (known bot name in party)",
      "strategies_add":    ["known strategy name", ...],
      "strategies_remove": ["known strategy name", ...],
      "multiplier_overrides": { "known action name": 0.0_to_2.0 },
      "focus":  "string or null",
      "stance": "front_line|back_line|flanking|follow_tank"
    }
  ]
}
```

## Implementation Steps

1. Write `lua/06-response-parse.lua`:
   - `parse_and_validate(response_text, expected_party)` returning
     `(directives, error)` tuple
   - Schema enforcement function for each field, with clear error
     messages
2. Write `lua/08-directive-apply.lua`:
   - `apply_directives(party_id, directives)` function
   - Per-bot policy state table keyed by guid
   - Translation from directive struct → `change_strategy` string +
     state-table update
3. Wire response draining into the main update loop — extend the
   tick handler from 916g (or use a separate periodic timer)
4. Implement the retry path: on first validation failure, the response
   draining loop re-submits the request with a "your previous output
   was malformed" suffix to the prompt. Track retry count per
   request_id; cap at 1 retry.
5. Smoke test:
   - Feed a known-good JSON through the validator → confirm directives
     extracted
   - Feed malformed JSON → confirm rejection with clear error
   - Feed JSON with unknown strategy name → confirm rejection
   - Feed JSON with out-of-bounds multiplier → confirm rejection
   - Send a real LLM request, watch the apply path light up

## Notes on Retry Strategy

One retry is the right number. Zero means small-model JSON glitches
cost real guidance opportunities. More than one risks burning inference
budget on a request the LLM clearly can't satisfy.

The retry prompt should be terse and include the error message. Don't
re-send the full party state — the worker still has it in flight.
(May require small change to 916e to retain request context across
retry.)

## Failure Modes

| Failure | Behavior |
|---|---|
| JSON parse error | Retry once, then fall back silently |
| Schema violation | Retry once with error in prompt, then fall back |
| Unknown strategy name | Log, drop that directive only, apply the rest |
| Unknown bot name | Log, drop that directive only |
| Out-of-bounds multiplier | Clamp to [0.0, 2.0], apply |
| Empty directives array | No-op, but not an error |
| LLM returns explanation prose instead of JSON | Same as JSON parse error |

## Files to Create

- `source-beta/modules/mod-soren-chat/lua/06-response-parse.lua`
- `source-beta/modules/mod-soren-chat/lua/08-directive-apply.lua`

## Files to Update

- `source-beta/modules/mod-soren-chat/lua/07-proximity-hook.lua` —
  consume the per-bot policy state (set here) when computing whether
  to re-plan
- `source-beta/modules/mod-soren-chat/lua/03-effil-workers.lua` —
  expose a "retry with modified prompt" path (may not require change
  if retry submits as new request)

## Open Questions

- Per-bot policy state lifetime: how long does a stance/focus stick
  before it's considered stale? Lean toward "until next plan or until
  party leaves LLM zone." Simpler than expiration timers.
- Should focus support multiple targets (focus list)? v0: single target,
  matches the schema. Extend later if needed.
- Multiplier_overrides interact with SorenDirected (916j); make sure
  the binding semantics are crystal clear in that ticket.

## Related

- Parent: [916 - mod-soren-chat](916-mod-soren-chat.md)
- [916b - ALE bindings](916b-ale-bindings-playerbots.md) — provides
  ChangeStrategy and is_strategy_known
- [916e - Worker pool](916e-effil-worker-pool.md) — produces responses
  this consumes
- [916g - Proximity hook](916g-proximity-detection-hook.md) — drains
  responses on each tick
- [916h - Guidance prompt builder](916h-guidance-prompt-builder.md) —
  defines the schema this validates against
- [916j - SorenDirected strategy](916j-sorendirected-strategy-class.md)
  — reads the per-bot policy state set here
