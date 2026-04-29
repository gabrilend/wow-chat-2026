# 609 - Gesture Command System: Kneel, Beckon, and Convoy Formation

## Status: Open

## Vision

Players command NPCs through body language, not menus. Kneeling, sitting, and
beckoning become a silent language of leadership. NPCs form convoys that snake
across the world like an ouroboros - when one falls, the chain reforms, the
tail becomes a new head, infinite recursion of the traveling salesman.

## The Gesture Language

```
┌─────────────────────────────────────────────────────────────────┐
│  PLAYER ACTION          NPC RESPONSE                           │
├─────────────────────────────────────────────────────────────────┤
│  Standing + Near    →   NPCs kneel in reverence                │
│  Beckoning          →   NPCs rise, follow, assist              │
│  Sitting            →   NPCs wait beside you                   │
│  Kneeling + Facing  →   NPCs move toward your facing direction │
│                         (mobile waypoint - Warcraft Rumble)     │
└─────────────────────────────────────────────────────────────────┘
```

## Current Behavior

- NPCs stand idle or patrol
- No response to player emotes/poses
- No convoy or follow mechanics
- Kneeling is just an emote, no gameplay effect

## Intended Behavior

### Kneeling = Sitting (Resource Recovery)
```lua
-- Kneeling grants same benefits as sitting:
-- - Increased health/mana regen
-- - "Resting" state for food/drink bonus
-- - But looks more dramatic/submissive

ON_PLAYER_EMOTE(EMOTE_KNEEL):
    player:SetStandState(UNIT_STAND_STATE_KNEEL)
    player:SetRestBonus(true)  -- Same as sitting
```

### NPCs Kneel When Players Approach
```lua
-- {{{ on_player_approach
local function on_player_approach(npc, player)
    local distance = npc:GetDistance(player)

    if distance < KNEEL_RADIUS then
        if not npc:IsInCombat() and not npc:IsKneeling() then
            npc:SetFacing(player)
            npc:Kneel()
            npc.reverence_target = player
        end
    end
end
-- }}}
```

### Beckoning Recruits Followers
```lua
-- {{{ on_player_beckon
local function on_player_beckon(player)
    local nearby_npcs = player:GetNearbyNPCs(BECKON_RADIUS)

    for _, npc in ipairs(nearby_npcs) do
        if npc:IsKneeling() and npc.reverence_target == player then
            npc:Rise()
            npc:Follow(player)
            npc:SetAssistMode(true)
            add_to_convoy(player, npc)
        end
    end
end
-- }}}
```

### Sitting = Wait Command
```lua
-- {{{ on_player_sit
local function on_player_sit(player)
    local convoy = get_player_convoy(player)

    for _, npc in ipairs(convoy) do
        npc:StopFollowing()
        npc:MoveTo(player:GetPosition())
        npc:SetState("waiting")
        npc:Kneel()  -- They kneel while waiting
    end
end
-- }}}
```

### Kneeling = Directional Waypoint
```
Player kneels facing NORTH:

     N
     ↑
     │
  ┌──┴──┐
  │PLAYER│  (kneeling, facing north)
  │  ⬆   │
  └──────┘

NPCs in convoy move NORTH until:
  - They reach an obstacle
  - They reach an enemy
  - Player stands up
  - Player changes facing

Like pointing at allies in Warcraft Rumble!
```

```lua
-- {{{ on_player_kneel_facing
local function on_player_kneel_facing(player)
    local convoy = get_player_convoy(player)
    local facing = player:GetFacing()
    local direction = facing_to_vector(facing)

    for _, npc in ipairs(convoy) do
        -- Create waypoint in facing direction
        local target_pos = project_position(player:GetPosition(), direction, 100)
        npc:MoveTo(target_pos)
        npc:SetState("directed")
    end

    -- Update direction if player rotates while kneeling
    player:RegisterFacingCallback(function(new_facing)
        redirect_convoy(player, new_facing)
    end)
end
-- }}}
```

## The Convoy System

### Formation: Ouroboros Chain
```
Normal convoy (following player):

    [NPC1] → [NPC2] → [NPC3] → [PLAYER]
       ↑                          │
       └──────────────────────────┘
              (circular awareness)

When NPC2 dies:

    [NPC1] → [NPC3] → [PLAYER]
       ↑                  │
       └──────────────────┘
         (chain reforms)

When PLAYER leaves:

    [NPC1] → [NPC3] → [NPC1] ...
         (ouroboros - tail becomes head)
```

### Traveling Salesman Recursion
```lua
-- {{{ convoy_reform
local function convoy_reform(convoy)
    if #convoy == 0 then return end

    -- When leader is lost, find new optimal path
    local remaining = convoy.members
    local new_path = {}
    local current = remaining[1]

    while #remaining > 0 do
        -- Nearest neighbor heuristic
        local nearest = find_nearest(current, remaining)
        table.insert(new_path, nearest)
        remove_from_list(remaining, nearest)
        current = nearest
    end

    -- Connect tail to head (ouroboros)
    new_path[#new_path].next_target = new_path[1]

    -- Each NPC follows the one ahead
    for i = 1, #new_path - 1 do
        new_path[i]:Follow(new_path[i + 1])
    end

    return new_path
end
-- }}}
```

### Dynamic Reassembly on Death
```lua
-- {{{ on_convoy_member_death
local function on_convoy_member_death(dead_npc, convoy)
    -- Remove from chain
    local prev = dead_npc.follower
    local next = dead_npc.following

    if prev and next then
        -- Reconnect the chain
        prev:Follow(next)
    end

    -- If head died, promote next
    if dead_npc == convoy.head then
        convoy.head = next
    end

    -- Recalculate optimal path (traveling salesman)
    convoy_reform(convoy)

    -- The ouroboros continues
    LOG_INFO("Convoy reformed: {} members remain", #convoy.members)
end
-- }}}
```

## Visual Representation

### The Kneel-Beckon-Direct Flow
```
Step 1: Player approaches NPCs
┌─────────────────────────────┐
│    NPC   NPC   NPC          │
│     ↓     ↓     ↓           │
│   (kneel before player)     │
│         PLAYER              │
└─────────────────────────────┘

Step 2: Player beckons
┌─────────────────────────────┐
│         PLAYER 👋           │
│     ↗     ↑     ↖           │
│    NPC   NPC   NPC          │
│   (rise and follow)         │
└─────────────────────────────┘

Step 3: Player kneels facing east
┌─────────────────────────────┐
│    NPC → NPC → NPC →→→ EAST │
│         PLAYER              │
│         (kneeling, facing →)│
└─────────────────────────────┘

Step 4: Player sits (convoy waits)
┌─────────────────────────────┐
│   NPC  NPC  NPC             │
│    ↓    ↓    ↓   (kneeling) │
│       PLAYER                │
│       (sitting)             │
└─────────────────────────────┘
```

### The Ouroboros Reformation
```
Before death:          After death:           Ouroboros complete:

A → B → C → D          A → C → D              A → C → D
        ↓                      ↓                      ↓
      PLAYER               PLAYER              ┌─────┘
                                               ↓
                                               A (tail → head)
```

## Configuration

```lua
-- worldserver.conf
WowChat2.Gesture.KneelRadius = 10          -- yards to trigger kneel
WowChat2.Gesture.BeckonRadius = 15         -- yards for beckon to work
WowChat2.Gesture.ConvoySpacing = 3         -- yards between convoy members
WowChat2.Gesture.DirectionUpdateRate = 0.5 -- seconds between facing checks
WowChat2.Gesture.OuroborosEnabled = true   -- tail becomes head on leader loss
```

## Emote Mappings

```lua
local GESTURE_EMOTES = {
    [EMOTE_ONESHOT_KNEEL]     = "kneel_start",
    [EMOTE_STATE_KNEEL]       = "kneel_hold",
    [EMOTE_ONESHOT_WAVE]      = "beckon",
    [EMOTE_ONESHOT_POINT]     = "direct",
    [EMOTE_STATE_SIT]         = "wait_command",
    [EMOTE_ONESHOT_SALUTE]    = "dismiss_convoy",
}
```

## Zone Consensus Direction (The Collective Will)

When bots don't know what to do, they look to the players for guidance.
The average facing direction of all players in a zone becomes the "drift" -
the natural flow that lost or idle bots follow.

### The Math
```lua
-- {{{ calculate_zone_consensus_direction
local function calculate_zone_consensus_direction(zone_id)
    local players = get_players_in_zone(zone_id)
    if #players == 0 then return nil end

    -- Average the unit vectors of all player facings
    local sum_x, sum_y = 0, 0

    for _, player in ipairs(players) do
        local facing = player:GetFacing()  -- radians
        sum_x = sum_x + math.cos(facing)
        sum_y = sum_y + math.sin(facing)
    end

    -- Normalize to get consensus direction
    local avg_x = sum_x / #players
    local avg_y = sum_y / #players
    local magnitude = math.sqrt(avg_x^2 + avg_y^2)

    -- Magnitude indicates consensus strength (0 = chaos, 1 = unity)
    local consensus_strength = magnitude

    -- Convert back to facing angle
    local consensus_facing = math.atan2(avg_y, avg_x)

    return consensus_facing, consensus_strength
end
-- }}}
```

### Visual: The Collective Drift
```
Players facing various directions:

    P1→  P2↗  P3→  P4↘  P5→

Average vector: →→ (mostly east, some spread)
Consensus strength: 0.7 (fairly unified)

Lost bots drift: →→→ EAST

---

Players facing randomly:

    P1↑  P2←  P3↓  P4→  P5↖

Average vector: ~0 (cancels out)
Consensus strength: 0.1 (chaos)

Lost bots: wander randomly (no clear guidance)
```

### Bot Idle Behavior
```lua
-- {{{ on_bot_idle
local function on_bot_idle(bot)
    -- Check if bot has any commands or purpose
    if bot:HasConvoy() then return end
    if bot:HasTarget() then return end
    if bot:IsKneeling() then return end

    -- No purpose - follow the collective will
    local zone = bot:GetZoneId()
    local direction, strength = calculate_zone_consensus_direction(zone)

    if direction and strength > CONSENSUS_THRESHOLD then
        -- Strong consensus - drift that way
        local drift_distance = IDLE_DRIFT_DISTANCE * strength
        local target = project_position(bot:GetPosition(), direction, drift_distance)
        bot:WanderToward(target)
    else
        -- Weak consensus - wander randomly
        bot:WanderRandom()
    end
end
-- }}}
```

### The Emergent Behavior

When players explore a zone together, naturally facing forward as they move,
all the idle bots in that zone slowly drift in the same direction. It creates
a feeling of *momentum* - the world itself seems to flow where players go.

```
Zone with 5 players all heading NORTH to a dungeon:

    ════════════════════════════
         DUNGEON ENTRANCE
    ════════════════════════════
              ↑ ↑ ↑
           ↑ ↑ ↑ ↑ ↑
        ↑ ↑ ↑ ↑ ↑ ↑ ↑    ← idle bots drifting north
           ↑ ↑ ↑ ↑ ↑
              ↑ ↑ ↑

         P1↑ P2↑ P3↑ P4↑ P5↑   ← players heading north

    The whole zone feels like it's flowing toward the goal.
```

### Individual Bot Facing: The Traveling Salesman Gaze

When bots have their own targets (not idle), they face their next destination.
But which destination? The nearest neighbor, averaged with momentum from where
they just came. The measurement of distance becomes a field - the bot's gaze
is a vector sum expressing both proximity and history.

```lua
-- {{{ calculate_bot_facing
local function calculate_bot_facing(bot)
    -- Where did we come from?
    local origin = bot.last_position or bot:GetPosition()
    local current = bot:GetPosition()
    local momentum = normalize(current - origin)  -- direction of travel

    -- Where is the nearest unvisited target?
    local targets = bot:GetPotentialTargets()
    local nearest = find_nearest_unvisited(bot, targets)

    if not nearest then
        -- No targets - fall back to zone consensus
        return calculate_zone_consensus_direction(bot:GetZoneId())
    end

    local to_target = normalize(nearest:GetPosition() - current)

    -- Average momentum with target direction
    -- This creates smooth, natural-looking movement
    local facing_x = (momentum.x + to_target.x) / 2
    local facing_y = (momentum.y + to_target.y) / 2

    return math.atan2(facing_y, facing_x)
end
-- }}}
```

```
Visual: The Distance Field

    Bot's history: came from SOUTH
    Bot's target: nearest is EAST

         N
         │
    W ───┼─── E  ← nearest target
         │
         S  ← came from here

    Momentum vector:     ↑ (north, away from origin)
    Target vector:       → (east, toward nearest)
    Average:            ↗ (northeast)

    Bot faces NORTHEAST, splitting the difference between
    where it's been and where it's going.
```

This creates natural "leading" behavior - bots don't snap instantly to
face their targets, they curve into them like rivers finding the sea.

### Level Affinity: The Traveling Salesman's True Cost

The traveling salesman doesn't measure distance in yards - he measures it
in *levels*. Bots seek players of similar level, clustering around their
peers like schools of fish finding their own kind.

```lua
-- {{{ calculate_level_affinity_cost
local function calculate_level_affinity_cost(bot, player)
    local bot_level = bot:GetLevel()
    local player_level = player:GetLevel()
    local max_level = MAX_PLAYER_LEVEL  -- 80 for WotLK

    local level_diff = math.abs(bot_level - player_level)
    local physical_distance = bot:GetDistance(player)

    -- The 50% threshold: proximity vs level preference
    -- If you're beyond halfway to being "close in level", level takes over
    local level_range = LEVEL_AFFINITY_RANGE  -- e.g., 5 levels
    local proximity_threshold = level_range / 2

    if level_diff <= proximity_threshold then
        -- Close enough in level - prefer proximity
        return physical_distance
    else
        -- Beyond halfway - level becomes primary
        return level_diff * 100 + physical_distance
    end
end
-- }}}

-- {{{ find_affinity_target
local function find_affinity_target(bot)
    local players = get_players_in_zone(bot:GetZoneId())
    local bot_level = bot:GetLevel()
    local max_level = MAX_PLAYER_LEVEL

    -- Max level bots only hang with max level players
    if bot_level == max_level then
        local max_players = filter(players, function(p)
            return p:GetLevel() == max_level
        end)
        if #max_players > 0 then
            return find_nearest(bot, max_players)
        end
        -- No max level peers - go help noobs or fighters
        return find_noob_or_fighter(bot, players)
    end

    -- Find level-appropriate peers first
    local peers = filter(players, function(p)
        return math.abs(p:GetLevel() - bot_level) <= LEVEL_AFFINITY_RANGE
    end)

    if #peers > 0 then
        -- Found peers - use standard cost function
        local best_player = nil
        local best_cost = math.huge
        for _, player in ipairs(peers) do
            local cost = calculate_level_affinity_cost(bot, player)
            if cost < best_cost then
                best_cost = cost
                best_player = player
            end
        end
        return best_player
    end

    -- No peers! Go to 75% point on level spectrum
    -- If you're level 20, 75% away is level 65 (toward max)
    -- If you're level 60, 75% away is level 15 (toward min)
    local target_level = calculate_75_percent_opposite(bot_level, max_level)
    return find_closest_to_level(players, target_level)
end
-- }}}

-- {{{ find_noob_or_fighter
local function find_noob_or_fighter(bot, players)
    -- High level bots help: very new players OR those in combat
    local candidates = {}

    for _, player in ipairs(players) do
        if player:GetLevel() <= 5 then
            -- Very noob
            table.insert(candidates, {player = player, priority = 1})
        elseif player:IsInCombat() and player:GetHealthPct() < 50 then
            -- Difficult battle
            table.insert(candidates, {player = player, priority = 2})
        end
    end

    table.sort(candidates, function(a, b) return a.priority < b.priority end)
    return candidates[1] and candidates[1].player or nil
end
-- }}}

-- {{{ calculate_75_percent_opposite
local function calculate_75_percent_opposite(current_level, max_level)
    -- 75% of the way to the opposite end of the spectrum
    local midpoint = max_level / 2

    if current_level < midpoint then
        -- Low level bot goes toward high end
        return current_level + (max_level - current_level) * 0.75
    else
        -- High level bot goes toward low end
        return current_level - (current_level - 1) * 0.75
    end
end
-- }}}
```

```
Visual: Level Clustering (with 75% rule)

Zone with mixed level players:

    [Lv80 Player]     [Lv15 Player]     [Lv35 Player]
         │                  │                  │
         ▼                  ▼                  ▼
    ┌─────────┐        ┌─────────┐        ┌─────────┐
    │ Lv80 Bot│        │ Lv12 Bot│        │ Lv33 Bot│
    │ Lv78 Bot│        │ Lv17 Bot│        │ Lv36 Bot│
    └─────────┘        └─────────┘        └─────────┘
         │
         │ (no max peers? help noobs!)
         ▼
    [Lv3 Noob struggling in combat]

    When a Lv45 bot has NO peers:
    - 75% toward opposite = Lv45 + (80-45)*0.75 = Lv71
    - Bot seeks out ~Lv71 player
```

### The Special Cases

```lua
-- {{{ handle_special_level_cases
local function handle_special_level_cases(bot, player)
    local bot_level = bot:GetLevel()
    local player_level = player:GetLevel()
    local max_level = MAX_PLAYER_LEVEL

    -- Level 1 bots: same behavior as toward fresh/idle/max players
    if bot_level == 1 then
        return is_fresh_login(player) or
               player_level == 1 or
               player_level == max_level
    end

    -- Max level bots: exclusive club
    if bot_level == max_level then
        return player_level == max_level
    end

    return false  -- no special case applies
end
-- }}}

-- {{{ is_fresh_login
local function is_fresh_login(player)
    -- Players who haven't moved since logging in
    local login_pos = player:GetLoginPosition()
    local current_pos = player:GetPosition()

    return positions_equal(login_pos, current_pos)
end
-- }}}
```

### Max Level Dungeon Scaling

When max level players are alone in open world dungeons, the world
responds to their presence:

```lua
-- {{{ scale_dungeon_to_visitors
local function scale_dungeon_to_visitors(dungeon)
    local visitors = dungeon:GetPlayers()
    local max_level_only = all(visitors, function(p)
        return p:GetLevel() == MAX_PLAYER_LEVEL
    end)

    if max_level_only and #visitors > 0 then
        -- Spawn max level monsters, scale rewards
        dungeon:SetMonsterLevel(MAX_PLAYER_LEVEL)
        dungeon:SetTreasureScale(#visitors)  -- more visitors = more treasure
    else
        -- Mixed levels: scale to highest non-max player
        local scale_target = find_highest_non_max(visitors)
        dungeon:SetMonsterLevel(scale_target:GetLevel())
    end
end
-- }}}
```

```
Dungeon Scaling Visual:

    SOLO MAX LEVEL PLAYER:
    ┌────────────────────────────────┐
    │  [Lv80 Player]                 │
    │       vs                       │
    │  [Lv80 Elite] [Lv80 Elite]     │
    │       💰 TREASURE 💰           │
    └────────────────────────────────┘

    MIXED PARTY:
    ┌────────────────────────────────┐
    │  [Lv80] [Lv45] [Lv30]          │
    │       vs                       │
    │  [Lv45 Mob] [Lv45 Mob]         │
    │  (scaled to highest non-max)   │
    │  Lv30 player watches, learns   │
    └────────────────────────────────┘
```

### Mid-Level Boredom: Visiting the Noobs

```lua
-- {{{ mid_level_boredom_check
local function mid_level_boredom_check(bot)
    -- Mid-level bots with nothing to do go help newbies
    local bot_level = bot:GetLevel()
    local is_mid_level = bot_level > 20 and bot_level < MAX_PLAYER_LEVEL - 10

    if is_mid_level and bot:IsIdle() then
        local noobs = find_players_below_level(bot:GetZoneId(), 10)
        if #noobs > 0 then
            return find_nearest(bot, noobs)
        end
    end

    return nil
end
-- }}}
```

### Proportional EXP Sharing

```lua
-- {{{ calculate_shared_exp
local function calculate_shared_exp(killer_level, helper_level, base_exp)
    -- A level 2 with a level 72 still learns proportionally
    -- But the level 72 barely gains anything (already knows it)

    local level_ratio = helper_level / killer_level
    local shared_exp = base_exp / level_ratio

    -- Cap: can't gain more than solo would give
    return math.min(shared_exp, base_exp)
end
-- }}}

-- Example:
-- Lv72 kills monster worth 1000 EXP
-- Lv2 helper gets: 1000 / (72/2) = 1000 / 36 = ~28 EXP
-- Still meaningful for a level 2!
--
-- But monsters are Lv72, so Lv2 just watches.
-- Learning by observation.
```

### Gesture Response by Level Peers

When a player gestures, only level-appropriate bots respond.
**Tiebreaker rules differ by gesture:**

```lua
-- {{{ on_player_gesture_with_affinity
local function on_player_gesture_with_affinity(player, gesture)
    local player_level = player:GetLevel()
    local nearby_bots = get_bots_in_zone(player:GetZoneId())

    -- Filter to level-appropriate bots
    local responding_bots = filter(nearby_bots, function(bot)
        return math.abs(bot:GetLevel() - player_level) <= LEVEL_AFFINITY_RANGE
    end)

    if gesture == "sit" then
        -- SITTING: tiebreaker is pure proximity
        -- Bots approach the player, closest first
        table.sort(responding_bots, function(a, b)
            return a:GetDistance(player) < b:GetDistance(player)
        end)

        for _, bot in ipairs(responding_bots) do
            bot:MoveTo(player:GetPosition())
            bot:SetState("gathering")
        end

    elseif gesture == "kneel" then
        -- KNEELING: tiebreaker is AXIS first, then proximity
        -- Bots on the facing axis get priority
        local facing = player:GetFacing()

        table.sort(responding_bots, function(a, b)
            local a_axis = calculate_axis_alignment(player, a, facing)
            local b_axis = calculate_axis_alignment(player, b, facing)

            if math.abs(a_axis - b_axis) > 0.1 then
                -- Different axis alignment - prefer better aligned
                return a_axis > b_axis
            else
                -- Same axis - use proximity
                return a:GetDistance(player) < b:GetDistance(player)
            end
        end)

        local target_pos = project_position(
            player:GetPosition(),
            facing,
            KNEEL_DIRECTION_DISTANCE
        )

        for _, bot in ipairs(responding_bots) do
            bot:MoveTo(target_pos)
            bot:SetState("directed")
        end
    end
end
-- }}}

-- {{{ calculate_axis_alignment
local function calculate_axis_alignment(player, bot, facing)
    -- How aligned is the bot with the player's facing axis?
    -- Returns 0-1, where 1 = perfectly on the axis

    local player_pos = player:GetPosition()
    local bot_pos = bot:GetPosition()

    local to_bot = normalize(bot_pos - player_pos)
    local facing_vec = facing_to_vector(facing)

    -- Dot product gives alignment (-1 to 1)
    local dot = to_bot.x * facing_vec.x + to_bot.y * facing_vec.y

    -- Convert to 0-1 range (we care about absolute alignment)
    return math.abs(dot)
end
-- }}}
```

```
Tiebreaker Visual:

SITTING - Pure Proximity:
┌─────────────────────────────────┐
│     B3(far)                     │
│           B2(mid)               │
│  PLAYER ← B1(close)             │
│  (sitting)                      │
│                                 │
│  Order: B1, B2, B3 (by distance)│
└─────────────────────────────────┘

KNEELING - Axis First, Then Proximity:
┌─────────────────────────────────┐
│  B2(off-axis, close)            │
│                                 │
│  PLAYER →→→ B1(on-axis, far)    │
│  (kneeling, facing east)        │
│                                 │
│  B3(off-axis, far)              │
│                                 │
│  Order: B1, B2, B3              │
│  (B1 wins despite being far -   │
│   it's ON the facing axis!)     │
└─────────────────────────────────┘
```

```
Gesture Flow:

1. Player (Lv30) SITS
   ┌──────────────────────────────────────┐
   │   Lv60 Bot: "Not my peer" (ignores)  │
   │   Lv28 Bot: "My people!" (approaches)│
   │   Lv32 Bot: "My people!" (approaches)│
   │   Lv10 Bot: "Not my peer" (ignores)  │
   └──────────────────────────────────────┘

2. Player (Lv30) KNEELS facing EAST
   ┌──────────────────────────────────────┐
   │   Lv28 Bot ──→ EAST                  │
   │   Lv32 Bot ──→ EAST                  │
   │   (moving where player points)       │
   └──────────────────────────────────────┘
```

Configuration:
```lua
-- worldserver.conf
WowChat2.Gesture.LevelAffinityRange = 5       -- levels +/- to respond
WowChat2.Gesture.LevelCostWeight = 10         -- how much level matters vs distance
WowChat2.Gesture.KneelDirectionDistance = 50  -- yards to project kneeling direction
WowChat2.Gesture.ProximityThreshold = 0.5     -- 50% of level range = switch to proximity
WowChat2.Gesture.NoPeersTargetPercent = 0.75  -- 75% toward opposite end when no peers
WowChat2.Dungeon.MaxLevelScaling = true       -- scale dungeons for solo max level
WowChat2.Dungeon.MixedPartyScaleToNonMax = true  -- use highest non-max for scaling
WowChat2.EXP.ProportionalSharing = true       -- level-proportional EXP sharing
WowChat2.Bot.MidLevelBoredThreshold = 300     -- seconds idle before visiting noobs
```

## Edge Cases

1. **Multiple Players**: NPCs serve the first player they knelt to
2. **Combat**: Kneeling breaks if player enters combat
3. **Distance**: Convoy members too far become "lost" and seek player
4. **Obstacles**: Directed NPCs pathfind around, don't walk into walls
5. **Enemy Contact**: Directed NPCs engage enemies in path
6. **Low Consensus**: If players face randomly, bots wander aimlessly
7. **Empty Zone**: No players = no consensus, bots do their default behavior
8. **No Level Peers**: Bot goes to 75% point on opposite end of level spectrum
9. **Level Ties (Sitting)**: Pure proximity tiebreaker - closest bot responds first
10. **Level Ties (Kneeling)**: Axis alignment first, then proximity
11. **Level 1 Bots**: Follow fresh logins, other level 1s, or max level players
12. **Max Level Bots**: Only hang with other max levels; if none, help noobs or fighters
13. **50% Threshold**: Within half the level range = prefer proximity; beyond = prefer level
14. **Fresh Login Players**: Treated same as level 1 (haven't found their purpose yet)
15. **Max Level Solo Dungeons**: Spawn max level monsters, scale treasure to party size
16. **Mixed Level Parties**: Dungeons scale to highest non-max player; low levels watch and learn
17. **Proportional EXP**: Low level helpers still gain meaningful EXP from high level kills

## The Poetry of It

```
Kneel before the wanderer,
Rise when beckoned near.
Sit and they will wait for you,
Kneel and they will steer.

The ouroboros convoy moves,
A serpent made of souls.
When one link falls another leads,
The traveling salesman's goals.

Infinite recursion, tail to head,
The caravan goes on.
Point them east, point them west,
Until the player's gone.
```

## Related Issues

- **132 - Healer Ping-Pong**: Similar traveling salesman optimization
- **119 - Orbit Player**: Formation positioning concepts
- **114 - Find Monsters**: NPC pathfinding to targets

## Files to Create

- `src/lua/gestures.lua` - Emote detection and response
- `src/lua/convoy.lua` - Convoy formation and reformation
- `src/lua/ouroboros.lua` - Recursive chain management
- `src/lua/behaviors/kneel-reverence.lua` - NPC kneeling behavior

