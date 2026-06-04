# 916b - ALE Bindings for Playerbots API

## Status
- Created: 2026-06-03
- Parent: Issue 916 (mod-soren-chat)
- Phase: 3
- Priority: High (blocks the directive-application and proximity layers)
- Depends on: 916a (skeleton must exist)

## Overview

Expose the two playerbots-internal operations the Lua side needs:
applying strategy changes to a bot, and querying whether a bot is within
N yards of a player. Both currently live behind C++ APIs that ALE has no
direct access to. This sub-issue is the binding layer that makes them
callable from Lua.

## Current Behavior

- mod-ale exposes a Lua API for general AzerothCore objects (Player,
  Creature, Map, etc.) but does not bind any mod-playerbots internals.
- `botAI->ChangeStrategy(string, BotState)` is reachable in C++ but
  invisible from Lua.
- Proximity queries between an arbitrary bot and arbitrary players exist
  in the engine but require iterating maps; no convenient Lua-callable
  form.

## Intended Behavior

After this sub-issue lands, ALE Lua scripts can call:

```lua
-- Toggle strategies on a bot. State is "combat" or "noncombat".
SorenBindings.change_strategy(bot_guid, "+save_mana,-aggressive_heal", "combat")

-- Returns true if the bot is within yards of any player on the same map.
local nearby = SorenBindings.is_bot_within_yards_of_player(bot_guid, 100)

-- Returns a table of {guid, name, class, level, health_pct, mana_pct,
-- map_id, x, y, z} for every bot in the same party as the given bot.
local party = SorenBindings.get_party_state(bot_guid)

-- Returns true if the named strategy exists in mod-playerbots' registry.
-- Used by the response validator to reject hallucinated strategy names.
local valid = SorenBindings.is_strategy_known("save_mana")
```

The bindings live in a new `SorenBindings` table exposed via ALE's C++
extension mechanism. They wrap small, focused C++ helper functions in
SorenALEBindings.cpp.

## Implementation Steps

1. Identify mod-ale's extension point for registering new Lua-callable
   C++ functions (typically a method on the LuaEngine or a registration
   header — needs investigation in source-beta/modules/mod-ale/src/)
2. Write `SorenALEBindings.h` declaring the four C++ functions:
   `BindChangeStrategy`, `BindIsBotWithinYards`, `BindGetPartyState`,
   `BindIsStrategyKnown`
3. Implement each function in `SorenALEBindings.cpp`:
   - `ChangeStrategy`: look up bot by guid, call
     `botAI->ChangeStrategy(opts, botState)`, return success bool
   - `IsBotWithinYards`: look up bot, iterate players on same map, check
     `bot->GetDistance(player) <= yards`
   - `GetPartyState`: look up bot, find its Group, walk members and
     emit a Lua table of state structs
   - `IsStrategyKnown`: query mod-playerbots' strategy context for the
     name
4. Register the functions with ALE via the `SorenALEBindings::Register()`
   call from `SorenChatLoader.cpp`'s `AddSC_mod_soren_chat()`
5. Write a one-file smoke-test Lua script
   (`src/lua-vanilla/test-soren-bindings.lua`) that:
   - Logs in as a GM
   - Picks any nearby bot
   - Calls each binding
   - Prints results to the log
6. Run the smoke test in a live worldserver; confirm strategy toggle is
   visible to the bot's behavior

## Files to Create

- `source-beta/modules/mod-soren-chat/src/SorenALEBindings.h`
- `source-beta/modules/mod-soren-chat/src/SorenALEBindings.cpp`
- `src/lua-vanilla/test-soren-bindings.lua` (smoke test, removable once
  more comprehensive testing is in place)

## Files to Update

- `source-beta/modules/mod-soren-chat/src/SorenChatLoader.cpp` — call
  `SorenALEBindings::Register()`
- `source-beta/modules/mod-soren-chat/CMakeLists.txt` — add new .cpp to
  source list and link against mod-playerbots' library if needed

## Open Questions

- How does ALE register new C++-defined Lua functions? Likely via a
  `LuaEngine::RegisterFunction(name, fn)` style API, but the exact
  shape is in mod-ale's source. Investigate first.
- mod-playerbots' `ChangeStrategy` signature accepts a string of toggles
  (`"+a,-b,~c"`) and a `BotState` enum. The binding takes a string for
  the state and converts internally — saves Lua side from importing
  enums.
- Should the bindings be in their own ALE namespace (`SorenBindings.*`)
  or hung off a global (`change_strategy(...)`)? Lean toward the table
  namespace for collision avoidance.

## Risks

- mod-playerbots changes its public C++ surface across upstream pulls.
  If `ChangeStrategy` signature shifts, the binding breaks at compile
  time, which is loud and fixable. The B-patch system already handles
  shifting upstream signatures (B016/B017/B019 are precedent — see
  issue 126).
- ALE registration mechanics may turn out to be undocumented or
  require a new ALE patch. If so, file a sub-sub-issue and write that
  patch first.

## Related

- Parent: [916 - mod-soren-chat](916-mod-soren-chat.md)
- [916a - Skeleton](916a-mod-soren-chat-skeleton.md) — blocks this
- [916g - Proximity detection hook](916g-proximity-detection-hook.md) —
  consumes `is_bot_within_yards_of_player` and `get_party_state`
- [916i - Response validator and directive application](916i-response-validator-and-directive-apply.md)
  — consumes `change_strategy` and `is_strategy_known`
- B-patch B002 (playerbots × ALE login hook) — established the pattern
  of cross-module integration via B-patches
