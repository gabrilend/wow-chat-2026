# 210 - Ambush Queue: Per-Player Instead of Broadcast

## Status
- Created: 2026-05-20
- Phase: 2 (Behaviors and Systems)
- Priority: Medium (unblocks per-player customisation features)

## Current Behavior

`Ambush.setupAmbushQueue(playerLevel, rank)` and its async callback
`Ambush.pushToAmbushQueue(query)` do not carry the originating player
through the callback. When the async SQL query returns, the callback
has no way to know which player triggered it, so it does this
(`src/lua/ambush.lua:267-298`):

```lua
all_players = { alliance = GetPlayersInWorld(0, false),
                horde    = GetPlayersInWorld(1, false),
                neutral  = GetPlayersInWorld(2, false) }

for _, faction in pairs(all_players) do
    for _, player in pairs(faction) do
        -- if this creature is level-appropriate for this player, add to queue
```

It iterates **every player in the world** and fills their queues with
the query results. This was an async-callback workaround: the function
signature takes `playerLevel` not `player` precisely because the
callback can't associate results with a single caller.

## Why This Is a Problem

- **No per-player customisation.** The user's stated goal is to push
  ambush spawns into a specific player's queue in response to events
  (quest accepted → spawn quest creatures in that player's queue,
  etc.). The broadcast design makes this impossible — anything you
  push for one player either ends up in everyone's queue or in no
  one's.
- **Wrong-player creature mixing.** Player A at level 20 triggers a
  query. Async returns 1+ seconds later. By then Player B at level 21
  has logged in. The callback fills Player B's queue with creatures
  Player B never asked for, drawn from a query specific to Player A's
  level range. Symptomless when level ranges overlap; weird when they
  don't.
- **Wasted work.** A query triggered for one player fills queues for
  every level-compatible player. The triggering player gets their
  queue filled (good), but N-1 other players get unnecessary fills.

## The Sync Predecessor Did It Right

`src/lua/ambush.lua.disabled` took the player object directly:
`Ambush.setupAmbushQueue(player, 4)`. Because the predecessor was
synchronous, the query returned to the same call frame that initiated
it, and only the originating player's queue was filled. Async broke
the caller association → broadcast workaround appeared.

## Intended Behavior

`Ambush.setupAmbushQueue(player, rank)` takes the player object.
The callback receives the player via Lua closure capture, so
`Ambush.pushToAmbushQueue(player, query)` knows exactly whose queue
to fill. The all-faction loop is deleted.

```lua
function Ambush.setupAmbushQueue(player, rank)
    local playerLevel = player:GetLevel()
    WorldDBQueryAsync(
        "SELECT entry, minlevel, maxlevel, `rank` FROM creature_template "
        .. "WHERE minlevel <= " .. playerLevel
        .. " AND maxlevel >= " .. playerLevel
        .. " AND `rank` = " .. rank
        .. " AND npcflag = 0 AND lootid != 0 AND type IN (2, 3, 4, 5, 6, 9, 10);",
        function(query) Ambush.pushToAmbushQueue(player, query) end)
end

function Ambush.pushToAmbushQueue(player, query)
    -- ... build creatures table from query ...
    -- ... write directly to player:SetData(queueType, ...) ...
    -- (no all_players loop)
end
```

The closure `function(query) ... end` captures `player` from the
enclosing scope, so when the async callback fires (potentially much
later, on a different thread), `player` is still the right player.

## Implementation Steps

1. Change `Ambush.setupAmbushQueue` signature: `(playerLevel, rank)` → `(player, rank)`.
2. Compute `playerLevel` inside the function from `player:GetLevel()`.
3. Wrap the callback in a closure that captures `player` and forwards
   to `Ambush.pushToAmbushQueue(player, query)`.
4. Change `Ambush.pushToAmbushQueue` signature: `(query)` → `(player, query)`.
5. Delete `all_players = { ... }` (line 267-270) and the surrounding
   nested for-loop (line 272-298). Replace with a single direct
   manipulation of `player:GetData(queueType)`.
6. Update the three call sites at lines 182, 185, 189 to pass `player`
   instead of `playerLevel` (they already have `player` in scope).
7. Hot-reload the script (ALE supports this) and verify in-game that
   a quest-accepted hook can push a quest creature into the player's
   queue and only that queue.

## Verification

In-game test:
- Two players online, different levels.
- Player A triggers an empty-queue refill. Player B's queue does NOT
  change.
- Player A's queue gets exactly the expected creatures.

Programmatic test (a later issue could automate this):
- Spawn a fake creature in Player A's queue via
  `Ambush.addCreatureToQueue(playerA, fakeId, ...)`.
- Verify `playerA:GetData("queue")` contains the fake.
- Verify `playerB:GetData("queue")` does NOT contain the fake.

## Risks and Things to Verify

- **Player disconnect between query and callback.** The async query
  might return after the player has logged out. The closure still
  holds a reference to the (now-invalid) player object. Need to
  null-check or wrap in `pcall`. Suggested guard at the top of
  `pushToAmbushQueue`:
  ```lua
  if not player or not player:IsInWorld() then return end
  ```
- **Closure capture semantics.** Lua closures capture upvalues by
  reference, but `player` here is a function parameter (a local), and
  the userdata it points to is the live player. Capture works as
  expected — confirmed in Lua 5.1 / LuaJIT semantics.
- **The `all_players` removal also removes a fallback path.** The
  current code, when `#creatures == 0`, sets `{0}` in everyone's
  rare-queue and re-registers `spawnAndAttackPlayer` to fire in 1s.
  After the refactor, this fallback applies only to the originating
  player — which is the correct behavior, but it's a change worth
  noting in the implementation comment.

## Related

- `issues/141-ale-formatquery-dangling-pointer.md` — the FormatQuery
  bug that prompted the original async switch (which created this
  broadcast workaround as a side effect)
- `src/lua/ambush.lua` — the file being refactored
- `src/lua/ambush.lua.disabled` — the sync predecessor with the
  correct per-player design
- `issues/completed/305-ambush-aggro-and-corpse-movement.md` —
  earlier ambush work for context

## Follow-up

Once this lands and is verified in-game:
- Future feature: hook `PLAYER_EVENT_ON_QUEST_ACCEPT` (or whatever
  ALE exposes) to push quest creatures into the accepting player's
  ambush queue. This was the user's motivating example for the
  refactor and should get its own issue.

---

## Post-deployment Crash and Real Fix 2026-05-21

The first implementation captured the `player` userdata directly in
the closure. In-game testing produced a consistent crash:

```
lua_scripts/custom/ambush.lua:241: calling 'GetName' on bad self
  (Player expected, got pointer to nonexisting (invalidated) object
   (userdata). Check your code.)
```

### Why the IsInWorld guard was insufficient

The "Risks" section above flagged this exact scenario:

> Player disconnect between query and callback. The async query
> might return after the player has logged out. The closure still
> holds a reference to the (now-invalid) player object. Need to
> null-check or wrap in `pcall`.

The first attempt added a guard:

```lua
function Ambush.pushToAmbushQueue(player, query)
    print("[Ambush] callback fired for " .. (player and player:GetName() or "<gone>"))  -- crash
    if not player or not player:IsInWorld() then return end
    ...
```

Both lines crash. The lesson: in ALE, an invalidated player userdata
is **still truthy** in Lua's `and` short-circuit. The boolean check
`player and player:GetName()` evaluates `player` first (it's
non-nil — userdata is truthy) and then calls `:GetName()` on the
invalid object, which throws. The guard *was inside the call* that
needed guarding. Order didn't help — `:IsInWorld()` would have thrown
the same way if reached.

There is no safe way to check whether a userdata wraps a valid
object from Lua. The userdata layer doesn't expose that state.

### The fix: re-resolve by name at callback time

Capture only **plain Lua values** in the closure — the player's
name (a string) and level (a number). At callback time, re-look-up
the player by name via `GetPlayerByName(name)`. If the lookup
returns nil, the player has logged out and we drop the query
silently. The re-resolved `player` userdata is guaranteed valid
because we just got it from the live player accessor.

```lua
function Ambush.setupAmbushQueue(player, rank)
    local playerLevel = player:GetLevel()
    local playerName  = player:GetName()  -- plain string, safe to capture
    WorldDBQueryAsync(sql,
        function(query)
            local p = GetPlayerByName(playerName)
            if p then Ambush.pushToAmbushQueue(p, query) end
        end)
end
```

This pattern is the right one for **any** ALE async callback that
needs a player reference. The general rule:

> Capture only values, not userdata, across async boundaries.
> Re-resolve to userdata at the moment of use.

Worth adding to the project's Lua coding-style notes.

### Removed prints

The crash-prone `print("[Ambush] callback fired for ...")` was
removed along with its companion `"originating player gone, dropping
query result"`. The new code doesn't need them — the lookup pattern
silently handles the disconnect race, and the function name in any
future error trace is sufficient to locate the call.
