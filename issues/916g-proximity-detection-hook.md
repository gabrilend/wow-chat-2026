# 916g - Proximity Detection Hook

## Status
- Created: 2026-06-03
- Parent: Issue 916 (mod-soren-chat)
- Phase: 3
- Priority: High (gates all guidance requests — wrong gating = wasted inference)
- Depends on: 916b (proximity binding), 916e (worker pool to submit to)

## Overview

The single most important gate in mod-soren-chat. Determines when an
LLM consultation is justified: when at least one party member is within
100 yards of a player. With proximity gating, the LLM load is roughly
proportional to "bots near players," not "bots in the world" — typically
a 10× or larger reduction.

Implements hysteresis (enter at 100yd, exit at 130yd) to prevent
boundary flapping when a player walks back and forth across the
threshold.

## Current Behavior

No proximity hook exists. The guidance layer would consult the LLM at
all times for all parties if naively enabled. That would saturate the
cluster before any meaningful number of bots came online.

## Intended Behavior

After this sub-issue lands:

- An ALE hook fires every 500ms (configurable, not every game tick —
  that's too aggressive for the use case)
- Each hook iteration walks all party-leader bots, calls
  `SorenBindings.get_party_state(leader_guid)` (from 916b)
- For each party, checks if any member has a player within 100yd
  (entry threshold)
- Tracks per-party "in LLM zone" state with hysteresis: parties in the
  zone need to drop below 130yd (exit threshold) to leave
- Newly-entered parties get a guidance request submitted (916h builds
  the prompt, 916e workers handle the call)
- Newly-exited parties have their LLM-set policies cleared, falling
  back to default playerbots behavior
- Parties already in the zone get re-planned at the configured cadence
  (5s in combat, 20s otherwise)

## Implementation Steps

1. Identify the ALE event that fires per-tick on the worldserver. Likely
   `OnWorldUpdate` or similar.
2. Write `lua/07-proximity-hook.lua`:
   ```lua
   local config = require("mod-soren-chat.config")
   local bindings = SorenBindings  -- exposed by 916b
   local workers = require("mod-soren-chat.workers")

   local party_state = {}  -- [leader_guid] = {in_zone, last_plan_time, last_member_count}
   local accumulator_ms = 0

   local function on_world_update(elapsed_ms)
       accumulator_ms = accumulator_ms + elapsed_ms
       if accumulator_ms < 500 then return end
       accumulator_ms = 0

       for leader_guid, _ in pairs(get_active_party_leaders()) do
           process_party(leader_guid)
       end
   end

   local function process_party(leader_guid)
       local state = party_state[leader_guid] or { in_zone = false, last_plan_time = 0 }
       local party = bindings.get_party_state(leader_guid)
       local any_member_near = false

       for _, member in ipairs(party) do
           local threshold = state.in_zone and config.proximity_yards + config.proximity_hysteresis
                                            or config.proximity_yards
           if bindings.is_bot_within_yards_of_player(member.guid, threshold) then
               any_member_near = true
               break
           end
       end

       if any_member_near and not state.in_zone then
           state.in_zone = true
           submit_guidance_request(leader_guid, party)
       elseif not any_member_near and state.in_zone then
           state.in_zone = false
           clear_policies_for_party(leader_guid, party)
       elseif state.in_zone then
           local in_combat = is_party_in_combat(party)
           local cadence = in_combat and config.guidance_cadence_combat
                                      or config.guidance_cadence_noncombat
           if (now() - state.last_plan_time) >= cadence then
               submit_guidance_request(leader_guid, party)
           end
       end
       party_state[leader_guid] = state
   end
   ```
3. Implement `get_active_party_leaders()` — depends on whether
   playerbots exposes this or we need to walk all bots and group by
   their `Group` membership. May need an additional binding in 916b.
4. Implement `submit_guidance_request(leader_guid, party)` — builds the
   request struct, calls `workers.submit()`. The prompt itself is built
   by 916h, this just routes.
5. Implement `clear_policies_for_party(leader_guid, party)` — calls
   `SorenBindings.change_strategy(guid, "...", state)` for each member
   to reset to default. Need to figure out what "default" means per
   class/role.
6. Wire the hook up to ALE's tick event in `SorenChatLoader.cpp` via the
   loader registration.
7. Smoke test: bring up a server, create a party of bots, watch logs as
   you (a player) walk in and out of 100yd.

## Configuration

Already specified in 916's main config block:

```lua
M.proximity_yards            = 100
M.proximity_hysteresis       = 30
M.guidance_cadence_combat    = 5
M.guidance_cadence_noncombat = 20
```

Plus from this sub-issue:

```lua
M.proximity_tick_ms          = 500
```

## Open Questions

- Does playerbots have a way to query "all active party-leader bots"
  efficiently, or do we need to iterate all bots? Walking all bots
  every 500ms might be cheap enough — they're already in worldserver
  memory.
- How do we detect "party in combat"? Some member of the party has
  `bot->IsInCombat()` true. Add to 916b as a binding if not already
  there.
- What about solo bots (not in a party)? Treat them as single-member
  parties for this system. Same logic, simpler prompt.
- The "clear policies" path needs a sensible default-strategy set per
  class. Investigate what mod-playerbots sets by default and replicate
  that as the reset target.

## Related

- Parent: [916 - mod-soren-chat](916-mod-soren-chat.md)
- [916b - ALE bindings](916b-ale-bindings-playerbots.md) — provides
  `is_bot_within_yards_of_player`, `get_party_state`
- [916e - Worker pool](916e-effil-worker-pool.md) — submit destination
- [916h - Guidance prompt builder](916h-guidance-prompt-builder.md) —
  builds the prompt from the party-state struct this hook gathers
