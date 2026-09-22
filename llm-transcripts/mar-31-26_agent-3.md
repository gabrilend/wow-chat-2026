# Conversation Summary: agent-a5f2cbf

Generated on: 2026-04-05 18:43:45

--------------------------------------------------------------------------------

### User Request 1

Warmup


--------------------------------------------------------------------------------

### Assistant Response 1

I'll explore the codebase to understand what this warmup request might entail.
Let me start by examining the project structure and recent activity.


<function_calls>

<invoke name="Read">

<parameter
name="file_path">/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/notes/vision</parameter>

</invoke>

</function_calls>

<result>

# Everland Ghostsong - Vision Document


*Technical name: wow-chat-2 (epitome-graph)*


## Core Concept


A WoW 3.3.5a private server reimagined as a **roguelike survival experience**.
The world is empty by default - no static spawns. Everything emerges from player
presence:


- **Ambush System**: Monsters spawn around players at calculated intervals

- **Treasure System**: Chests and loot spawn based on exploration

- **Traveler NPCs**: Wandering characters that create emergent stories

- **Playerbot Companions**: AI party members with customizable behavior


## Design Philosophy


## Emptiness as Canvas

The world starts silent. Players bring life through presence. This creates:

- Meaningful encounters (every monster matters)

- Exploration tension (what's around the corner?)

- Resource scarcity (no farming static spawns)


## Roguelike Pacing

- **Max Level 20**: Tight progression curve

- **Talent Points Every 1/3 Level**: Frequent meaningful choices

- **Abilities Through Quests**: Earning skills, not just leveling

- **Death Has Weight**: Consider permadeath or harsh penalties


## Companion Focus

Playerbots aren't just helpers - they're the party system:

- Named personalities with behavioral quirks

- Relationships that develop over time

- Strategic coordination in combat

- Emotional investment through loss


## Technical Foundation


## AzerothCore 3.3.5a

Stable, well-documented, moddable base.


## Modules

- **mod-ale**: Lua scripting engine (hot-reload for rapid iteration)

- **mod-playerbots**: AI companion framework

- **mod-aoe-loot**: Quality of life

- **mod-grownup**: Skip tutorial content


## Custom Systems (Lua)

All custom behavior implemented in Lua for:

- Hot-reload development

- Clear separation from core

- Easy debugging and iteration


## Spawn Philosophy


## Distance Rings

Spawns occur in calculated rings around players:

- **Close (30-60y)**: Treasure, resources

- **Medium (50-100y)**: Travelers, friendly NPCs

- **Far (120-160y)**: Ambush monsters


## Timing

Random walk algorithms create unpredictable but bounded timing:

- Prevents pattern recognition

- Maintains tension without frustration

- Allows natural play rhythm


## Narrative Layer


## No Quest Log Grind

Traditional quests replaced with:

- Traveler stories (emergent NPC encounters)

- Bounty board (dynamic objectives)

- Exploration rewards (finding hidden places)


## World as Character

The emptiness itself tells a story. Why is the world abandoned? What happened
here? Players piece together through:

- Environmental storytelling

- Traveler dialogue

- Found documents and items


## Phase Goals


## Phase 1: Foundation (Complete)

- Server running with all modules

- Basic ambush spawn system

- Configuration management

- Documentation structure


## Phase 2: Behaviors

- Playerbot command extensions

- Monster behavior patterns (orbit, flee, stalk)

- Traveler conversation system

- Find/avoid mechanics


## Phase 3: Progression

- Talent point system (every 1/3 level)

- Ability quest chains

- Bounty board currency

- Death penalty system


## Phase 4: Polish

- Visual powerline mapping tool

- Balance iteration

- Performance optimization

- Player testing feedback


## Success Metrics


The server succeeds when:

1. Every encounter feels meaningful

2. Bots feel like companions, not tools

3. Exploration creates genuine tension

4. Players tell stories about their experiences

5. The empty world feels full of possibility

</result>


<function_calls>

<invoke name="Glob">

<parameter
name="pattern">/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/*.md</parameter>

</invoke>

</function_calls>

<result>

[

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/102-test-playerbots-spawn",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/113-investigate-ambush-monsters-not-spawning.md",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/114-behavior-find-monsters.md",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/115-behavior-discuss-with-npc.md",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/116-behavior-avoid-monsters.md",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/117-behavior-sit-and-rest.md",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/118-behavior-travel-to-unique-lands.md",

"/mnt:mtwo/programming/ai-stuff/games/wow-chat-2/issues/119-behavior-orbit-player.md",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/120-talent-points-level-20-cap",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/121-bounty-board-currency-system",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/122-rebellious-attitudes-freedom-of-affairs",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/123-visual-powerline-mapping-tool.md",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/124-randomize-ambush-spawn-interval.md",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/125-player-bot-behavior-commands.md",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/126-dungeon-room-spawn-zones.md",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/127-contextual-creature-spawns.md",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/128-embedding-based-creature-selection.md",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/129-portal-dimension-system.md",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/130-ale-initialization-hook-fix.md",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/131-randomized-login-screen-freddi-fish.md",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/132-healer-bot-ping-pong-behavior.md",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/133-gesture-command-system-kneel-convoy.md",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/phase-1-progress.md",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/phase-2-progress.md"

]

</result>


<function_calls>

<invoke name="Read">

<parameter
name="file_path">/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/phase-2-progress.md</parameter>

</invoke>

</function_calls>

<result>

# Phase 2 Progress: Behaviors


## Overview

Phase 2 focuses on behavior systems for playerbots and monsters, creating the
emergent gameplay that makes Everland Ghostsong unique.


## Core Issues


## Playerbot Behaviors

- [ ] 114 - Find Monsters: Bots actively seek out ambush spawns

- [ ] 115 - Discuss with NPC: Conversation system with travelers

- [ ] 116 - Avoid Monsters: Flee behavior for low-health situations

- [ ] 117 - Sit and Rest: Natural resting behavior

- [ ] 118 - Travel to Unique Lands: Exploration-driven movement

- [ ] 119 - Orbit Player: Formation behavior around player


## Monster Behaviors

- [ ] 113 - Investigate ambush monsters not spawning


## System Infrastructure

- [ ] 124 - Randomize ambush spawn interval (random walk algorithm)

- [ ] 125 - Player bot behavior commands

- [ ] 130 - ALE initialization hook fix


## Progress Notes


*Phase 2 has begun. Issue files created for core behavior systems.*


---


## Completed Issues


(none yet)

</result>


<function_calls>

<invoke name="Read">

<parameter
name="file_path">/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/src/lua/ambush.lua</parameter>

</invoke>

</function_calls>

<result>

-- ambush.lua

-- Spawns monsters around players at random intervals using a random walk algorithm.

-- Monsters spawn 120-160 yards away, creating tension through unpredictable encounters.


-- {{{ Configuration

-- Random walk interval configuration (all values in milliseconds)

local AMBUSH_BASE_INTERVAL = 40000 -- starting interval for new players

local AMBUSH_INTERVAL_MIN = 10000 -- floor - interval won't go below this

local AMBUSH_INTERVAL_SOFT = 100000 -- soft cap - 67% chance to decrease

local AMBUSH_INTERVAL_HARD = 200000 -- hard cap - 80% chance to decrease

local AMBUSH_JITTER_MIN = 2000 -- minimum random walk step

local AMBUSH_JITTER_MAX = 4000 -- maximum random walk step

local AMBUSH_GRACE_PERIOD = 30000 -- grace period on login (ms)

local AMBUSH_OFFLINE_RESET = 600 -- seconds offline to trigger grace period


-- Spawn distance configuration

local SPAWN_MIN_DIST = 120 -- minimum spawn distance from player

local SPAWN_MAX_DIST = 160 -- maximum spawn distance from player

local SPAWN_MIN_HEIGHT = -15 -- minimum height difference allowed

local SPAWN_MAX_HEIGHT = 15 -- maximum height difference allowed

-- }}}


-- {{{ Player State Storage

-- Stores per-player timing state for the random walk algorithm

-- Key: player GUID, Value: { interval = ms, lastSpawn = timestamp, graceUntil = timestamp }

local playerState = {}

-- }}}


-- {{{ getJitter

-- Returns a random jitter value between min and max, with random sign

-- Used to create the random walk step for interval changes

local function getJitter()

local magnitude = math.random(AMBUSH_JITTER_MIN, AMBUSH_JITTER_MAX)

return magnitude

end

-- }}}


-- {{{ getDirectionBias

-- Determines whether interval should increase or decrease based on current value

-- Returns: 1 for increase, -1 for decrease

-- At floor: always increase

-- At soft cap: 67% decrease

-- At hard cap: 80% decrease

-- Normal: 50/50

local function getDirectionBias(currentInterval)

if currentInterval <= AMBUSH_INTERVAL_MIN then

return 1 -- at floor, can only go up

elseif currentInterval >= AMBUSH_INTERVAL_HARD then

return math.random() < 0.80 and -1 or 1 -- 80% down at hard cap

elseif currentInterval >= AMBUSH_INTERVAL_SOFT then

return math.random() < 0.67 and -1 or 1 -- 67% down at soft cap

else

return math.random() < 0.50 and -1 or 1 -- 50/50 in normal range

end

end

-- }}}


-- {{{ calculateNextInterval

-- Applies random walk to current interval

-- Returns new interval clamped to valid range

local function calculateNextInterval(currentInterval)

local jitter = getJitter()

local direction = getDirectionBias(currentInterval)

local newInterval = currentInterval + (jitter * direction)



-- clamp to valid range

if newInterval < AMBUSH_INTERVAL_MIN then

newInterval = AMBUSH_INTERVAL_MIN

elseif newInterval > AMBUSH_INTERVAL_HARD then

newInterval = AMBUSH_INTERVAL_HARD

end



return newInterval

end

-- }}}


-- {{{ initPlayerState

-- Initializes or retrieves player state

-- Handles grace period logic for returning players

local function initPlayerState(player, currentTime)

local guid = player:GetGUIDLow()

local state = playerState[guid]



if not state then

-- new player, start with base interval and grace period

state = {

interval = AMBUSH_BASE_INTERVAL,

lastSpawn = currentTime,

graceUntil = currentTime + AMBUSH_GRACE_PERIOD,

lastSeen = currentTime

}

playerState[guid] = state

else

-- returning player, check if grace period needed

local offlineSeconds = currentTime - state.lastSeen

if offlineSeconds >= AMBUSH_OFFLINE_RESET then

state.graceUntil = currentTime + AMBUSH_GRACE_PERIOD

end

state.lastSeen = currentTime

end



return state

end

-- }}}


-- {{{ selectCreatureForLevel

-- Selects an appropriate creature entry for the player's level

-- TODO: implement proper creature selection based on level and zone

local function selectCreatureForLevel(level, mapId)

-- placeholder: return a basic wolf

-- real implementation should query creature tables

return 69

end

-- }}}


-- {{{ calculateSpawnPosition

-- Calculates a spawn position at random angle and distance from player

-- Returns x, y or nil if no valid position found

local function calculateSpawnPosition(player)

local px, py, pz = player:GetPosition()

local mapId = player:GetMapId()



-- random angle and distance

local theta = math.random() * 6.28318 -- 2*pi

local radius = math.random(SPAWN_MIN_DIST, SPAWN_MAX_DIST)



-- calculate position

local x = px + math.cos(theta) * radius

local y = py + math.sin(theta) * radius



-- get terrain height at spawn position

local map = player:GetMap()

local z = map:GetHeight(x, y)



-- validate height difference

local heightDiff = z - pz

if heightDiff < SPAWN_MIN_HEIGHT or heightDiff > SPAWN_MAX_HEIGHT then

return nil, nil, nil -- invalid position

end



return x, y, z

end

-- }}}


-- {{{ trySpawnAmbush

-- Attempts to spawn an ambush creature near the player

-- Returns true if spawn successful, false otherwise

local function trySpawnAmbush(player)

local x, y, z = calculateSpawnPosition(player)



if not x then

return false -- no valid position found

end



local level = player:GetLevel()

local mapId = player:GetMapId()

local entry = selectCreatureForLevel(level, mapId)



-- spawn the creature

-- PerformIngameSpawn(spawnType, entry, mapId, instanceId, x, y, z, o)

-- spawnType 1 = creature

local creature = player:SpawnCreature(entry, x, y, z, 0, 1, 0)



if creature then

-- creature spawned successfully

-- TODO: set creature behavior (aggro toward player, etc)

return true

end



return false

end

-- }}}


-- {{{ onPlayerUpdate

-- Called periodically for each player to check if ambush should spawn

-- Implements the random walk timing system

local function onPlayerUpdate(event, player, diff)

-- skip bots

if player:IsBot and player:IsBot() then

return

end



local currentTime = os.time() * 1000 -- convert to milliseconds

local state = initPlayerState(player, currentTime)



-- check grace period

if currentTime < state.graceUntil then

return -- still in grace period

end



-- check if enough time has passed

local elapsed = currentTime - state.lastSpawn

if elapsed < state.interval then

return -- not time yet

end



-- time for ambush attempt

if trySpawnAmbush(player) then

-- successful spawn, update state with random walk

state.lastSpawn = currentTime

state.interval = calculateNextInterval(state.interval)



-- debug output

print(string.format("[Ambush] Spawned for %s, next interval: %.1fs",

player:GetName(), state.interval / 1000))

else

-- failed to spawn, try again soon

state.lastSpawn = currentTime - (state.interval * 0.9) -- retry in 10% of
interval

end

end

-- }}}


-- {{{ onPlayerLogout

-- Updates last seen time when player logs out

local function onPlayerLogout(event, player)

local guid = player:GetGUIDLow()

local state = playerState[guid]



if state then

state.lastSeen = os.time() * 1000

end

end

-- }}}


-- {{{ Event Registration

-- Register hooks with ALE

-- PLAYER_EVENT_ON_UPDATE_ZONE fires periodically, good for our timer checks

-- Note: may need different event depending on ALE version

RegisterPlayerEvent(27, onPlayerUpdate) -- PLAYER_EVENT_ON_UPDATE_ZONE

RegisterPlayerEvent(4, onPlayerLogout) -- PLAYER_EVENT_ON_LOGOUT

-- }}}


print("[Ambush] System loaded - random walk intervals enabled")

</result>


<function_calls>

<invoke name="Glob">

<parameter
name="pattern">/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/src/lua/**/*.lua</parameter>

</invoke>

</function_calls>

<result>

[

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/src/lua/ambush.lua",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/src/lua/behaviors/find-monsters.lua",

"/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/src/lua/levelling.lua"

]

</result>


<function_calls>

<invoke name="Read">

<parameter
name="file_path">/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/src/lua/behaviors/find-monsters.lua</parameter>

</invoke>

</function_calls>

<result>

-- find-monsters.lua

-- Behavior that makes playerbots actively seek out and engage ambush spawns.

-- Part of the behavior system for creating emergent companion AI.


-- {{{ Configuration

local SEARCH_RADIUS = 80 -- yards to search for monsters

local SEARCH_INTERVAL = 3000 -- ms between searches

local ENGAGE_DISTANCE = 30 -- yards to start engaging

local ANNOUNCE_COOLDOWN = 10 -- seconds between announcements

-- }}}


-- {{{ State Storage

-- Tracks per-bot state for monster searching

-- Key: bot GUID, Value: { lastSearch, lastAnnounce, targetGuid }

local botState = {}

-- }}}


-- {{{ initBotState

-- Initializes or retrieves bot state

local function initBotState(bot, currentTime)

local guid = bot:GetGUIDLow()

local state = botState[guid]



if not state then

state = {

lastSearch = 0,

lastAnnounce = 0,

targetGuid = nil

}

botState[guid] = state

end



return state

end

-- }}}


-- {{{ findNearestHostile

-- Searches for hostile creatures within radius

-- Returns creature or nil

local function findNearestHostile(bot, radius)

local creatures = bot:GetCreaturesInRange(radius)

local nearest = nil

local nearestDist = radius + 1



for _, creature in ipairs(creatures) do

-- check if hostile to bot

if creature:IsHostileTo(bot) and creature:IsAlive() then

local dist = bot:GetDistance(creature)

if dist < nearestDist then

nearest = creature

nearestDist = dist

end

end

end



return nearest, nearestDist

end

-- }}}


-- {{{ announceTarget

-- Bot announces finding a target to the party

local function announceTarget(bot, creature, state, currentTime)

-- check cooldown

if currentTime - state.lastAnnounce < ANNOUNCE_COOLDOWN then

return

end



local creatureName = creature:GetName()

local distance = math.floor(bot:GetDistance(creature))



-- send party message

bot:SendUnitSay(string.format("I see a %s, %d yards away!", creatureName,
distance), 0)



state.lastAnnounce = currentTime

end

-- }}}


-- {{{ engageTarget

-- Commands bot to engage the target creature

local function engageTarget(bot, creature)

-- use playerbot attack command

-- bot:SetTarget(creature)

-- bot:Attack(creature)



-- TODO: implement proper engagement through playerbot API

-- For now, just move toward the creature

local cx, cy, cz = creature:GetPosition()

bot:MoveTo(0, cx, cy, cz)

end

-- }}}


-- {{{ onBotUpdate

-- Called periodically to check if bot should search for monsters

local function onBotUpdate(event, bot, diff)

-- only process playerbots

if not bot:IsBot or not bot:IsBot() then

return

end



local currentTime = os.time()

local state = initBotState(bot, currentTime)



-- check search interval

local elapsed = (currentTime * 1000) - state.lastSearch

if elapsed < SEARCH_INTERVAL then

return

end

state.lastSearch = currentTime * 1000



-- search for hostiles

local creature, distance = findNearestHostile(bot, SEARCH_RADIUS)



if not creature then

state.targetGuid = nil

return

end



-- found a hostile

local creatureGuid = creature:GetGUIDLow()



-- announce if new target

if state.targetGuid ~= creatureGuid then

announceTarget(bot, creature, state, currentTime)

state.targetGuid = creatureGuid

end



-- engage if close enough

if distance <= ENGAGE_DISTANCE then

engageTarget(bot, creature)

end

end

-- }}}


-- {{{ Event Registration

-- Register with player update event

-- Bots are players, so this should fire for them

RegisterPlayerEvent(27, onBotUpdate) -- PLAYER_EVENT_ON_UPDATE_ZONE

-- }}}


print("[Behavior:FindMonsters] Loaded")

</result>


<function_calls>

<invoke name="Read">

<parameter
name="file_path">/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/docs/architecture.md</parameter>

</invoke>

</function_calls>

<result>

# Everland Ghostsong - System Architecture


## Overview


```

┌─────────────────────────────────────────────────────────────────┐

│ World of Warcraft Client │

│ (3.3.5a 12340) │

└─────────────────────────────────────────────────────────────────┘

│

▼

┌─────────────────────────────────────────────────────────────────┐

│ AzerothCore Server │

│ ┌─────────────┐
┌─────────────┐
┌─────────────────────────┐
│

│ │ AuthServer │ │ WorldServer │ │ MySQL (3307) │ │

│ │ (3724) │ │ (8085) │ │ acore_auth/world/char │ │

│ └─────────────┘
└─────────────┘
└─────────────────────────┘
│

└─────────────────────────────────────────────────────────────────┘

│

▼

┌─────────────────────────────────────────────────────────────────┐

│ Module Layer │

│ ┌───────────┐
┌─────────────┐
┌──────────┐ ┌────────────┐
│

│ │ mod-ale │ │mod-playerbots│ │mod-aoe- │ │mod-grownup │ │

│ │(Lua Engine)│ │(AI Companions)│ │ loot │ │(Skip Intro)│ │

│ └───────────┘
└─────────────┘
└──────────┘ └────────────┘
│

└─────────────────────────────────────────────────────────────────┘

│

▼

┌─────────────────────────────────────────────────────────────────┐

│ Lua Scripts (src/lua/) │

│ ┌────────────┐
┌────────────┐
┌────────────┐
┌───────────┐ │

│ │ ambush.lua │ │ travel.lua │ │movement.lua│ │behaviors/ │
│

│ │ (Spawning) │ │(NPC Wander)│ │ (Utilities)│ │(Bot AI) │ │

│ └────────────┘
└────────────┘
└────────────┘
└───────────┘ │

└─────────────────────────────────────────────────────────────────┘

```


## Data Flow


## Ambush Spawn Flow


```

Player Login

│

▼

┌─────────────────┐

│ initPlayerState │ ─── Check offline duration

│ (ambush.lua) │ Set grace period if needed

└─────────────────┘

│

▼

┌─────────────────┐

│ onPlayerUpdate │ ◄── Fires periodically (EVENT 27)

│ Timer Check │

└─────────────────┘

│

▼ (if interval elapsed)

┌─────────────────┐

│ trySpawnAmbush │

└─────────────────┘

│

├─► calculateSpawnPosition() ─► Random angle/distance

│ Validate terrain height

│

├─► selectCreatureForLevel() ─► Query creature tables

│ Return appropriate entry

│

└─► SpawnCreature() ──────────► World gets creature

│

▼

┌─────────────────┐

│calculateNextInt │ ─── Random walk algorithm

│ Update State │ Jitter + direction bias

└─────────────────┘

```


## Playerbot Behavior Flow


```

Bot Update Event

│

▼

┌─────────────────────┐

│ Behavior: Find │ ◄── Check search interval

│ findNearestHostile│ Query creatures in range

└─────────────────────┘

│

▼ (if hostile found)

┌─────────────────────┐

│ announceTarget │ ─── Party chat message

│ engageTarget │ Move toward creature

└─────────────────────┘

│

▼

┌─────────────────────┐

│ Behavior: Orbit │ ◄── Formation around player

│ Behavior: Rest │ Sit when appropriate

│ Behavior: Avoid │ Flee when health low

└─────────────────────┘

```


## Key Interfaces


## ALE (Lua Engine) API


```lua

-- Player methods (docs/ale/docs/Player/)

player:GetPosition() -- returns x, y, z

player:GetLevel() -- returns level 1-20

player:GetMapId() -- returns map ID

player:GetGUIDLow() -- returns unique identifier

player:SpawnCreature() -- spawn creature at position

player:IsBot() -- true if playerbot


-- Creature methods (docs/ale/docs/Creature/)

creature:GetPosition()

creature:IsHostileTo(unit)

creature:IsAlive()

creature:GetName()


-- Map methods (docs/ale/docs/Map/)

map:GetHeight(x, y) -- terrain height at position


-- Events

RegisterPlayerEvent(eventId, callback)

-- 4  = PLAYER_EVENT_ON_LOGOUT

-- 27 = PLAYER_EVENT_ON_UPDATE_ZONE

```


## Playerbot Commands


```

.bot add <name> -- Add bot to party

.bot remove <name> -- Remove bot from party

.bot attack -- Attack current target

.bot follow -- Follow player

.bot stay -- Stay in place

```


## File Locations


## Source Code

```

src/lua/

├── ambush.lua # Monster spawn system

├── travel.lua # Traveler NPC wandering

├── movement.lua # Movement utilities

├── levelling.lua # Level 20 cap, talent points

└── behaviors/

├── find-monsters.lua # Seek hostiles

├── avoid-monsters.lua # Flee behavior

├── discuss-npc.lua # NPC conversation

├── sit-rest.lua # Resting behavior

├── travel-lands.lua # Exploration

└── orbit-player.lua # Formation movement

```


## Configuration

```

installed-files/etc/

├── worldserver.conf.dist

├── authserver.conf.dist

└── modules/

├── playerbots.conf.dist

├── mod_ale.conf.dist

└── mod_aoe_loot.conf.dist

```


## Documentation

```

docs/

├── architecture.md # This file

├── configuration.md # Config options

├── scripting.md # Lua quick reference

├── playerbots/ # Playerbot wiki

├── ale/ # ALE API docs

└── wiki/ # AzerothCore wiki

```


## State Management


## Per-Player State (ambush.lua)

```lua

playerState[guid] = {

interval = number, -- current spawn interval (ms)

lastSpawn = number, -- timestamp of last spawn

graceUntil = number, -- grace period end timestamp

lastSeen = number -- last activity timestamp

}

```


## Per-Bot State (behaviors/)

```lua

botState[guid] = {

lastSearch = number, -- last search timestamp

lastAnnounce = number, -- last announcement timestamp

targetGuid = number -- current target GUID

}

```


## Design Patterns


## Random Walk Timing

Used for unpredictable but bounded intervals:

1. Start with base interval

2. Each cycle, add jitter (+/- random amount)

3. Apply direction bias based on current value

4. Clamp to min/max bounds


## Distance Rings

Spawns occur in concentric rings:

- Close (30-60y): Treasure, resources

- Medium (50-100y): Travelers, friendly NPCs  

- Far (120-160y): Ambush monsters


## Event-Driven Updates

All systems hook into ALE events:

- `PLAYER_EVENT_ON_UPDATE_ZONE` (27) for periodic updates

- `PLAYER_EVENT_ON_LOGOUT` (4) for cleanup

- Systems manage their own timing internally

</result>


I've explored the Everland Ghostsong codebase. This is a WoW 3.3.5a private
server project with roguelike survival mechanics. Here's what I found:


## Project Status


**Phase 1**: Complete (foundation, server setup, basic ambush system)

**Phase 2**: In Progress (behavior systems for playerbots and monsters)


## Current Codebase


## Lua Scripts Implemented

- `ambush.lua` - Monster spawn system with random walk interval algorithm

- `behaviors/find-monsters.lua` - Bot behavior to seek hostiles (skeleton)

- `levelling.lua` - Level 20 cap system


## Phase 2 Open Issues

Key behavior issues waiting for implementation:

- 113 - Investigate ambush monsters not spawning

- 114 - Find monsters behavior

- 115 - Discuss with NPC

- 116 - Avoid monsters

- 117 - Sit and rest

- 118 - Travel to unique lands

- 119 - Orbit player

- 124 - Randomize ambush spawn interval (random walk - appears implemented in ambush.lua)

- 125 - Player bot behavior commands

- 130 - ALE initialization hook fix


## Architecture Summary


The system uses:

- AzerothCore 3.3.5a with mod-ale (Lua scripting)

- mod-playerbots for AI companions

- Event-driven Lua scripts that hook into player update events

- Per-player/per-bot state tables for timing and behavior tracking


## Critical Files for Implementation

- `/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/src/lua/ambush.lua` - Core spawn system, random walk implemented

- `/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/src/lua/behaviors/find-monsters.lua` - Skeleton behavior, needs completion

- `/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/docs/architecture.md` - System design reference

- `/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/issues/phase-2-progress.md` - Current phase tracking

- `/mnt/mtwo/programming/ai-stuff/games/wow-chat-2/docs/ale/` - ALE API documentation for Lua scripting


What would you like to work on?


--------------------------------------------------------------------------------
