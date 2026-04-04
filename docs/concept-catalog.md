# Everland Ghostsong: Concept Catalog
## Eight Hundred Concepts Wide

Generated: 2026-04-03
Project: WoW Chat 2 (Everland Ghostsong)
Consolidated from 1000-concept original (see git history)

---

# PART I: FOUNDATION LAYER
## Concepts 001-100

---

### 001 - Core Vision: Play With Friends While Talking
The game exists for socializing. Combat, exploration, and progression are the
backdrop for conversation. The "chat" in wow-chat is human connection.

### 002 - Roguelike Layer on WoW
Built on top of World of Warcraft 3.3.5a, a survival-style game loop with
timed events, scaling difficulty, and permanent consequences.

### 003 - Ambush Timer (40s)
Every 40 seconds, level-appropriate monsters spawn and chase the player.
The world is never safe. Movement is survival.

### 004 - Traveller Timer (130s)
Every 130 seconds, friendly NPCs wander into the world. Potential allies,
merchants, or quest givers. The world feels populated.

### 005 - Treasure Timer (100s)
Every 100 seconds, treasure chests spawn nearby. Scaled loot from dungeons
and raids. The carrot to the ambush stick.

### 006 - Rest Mechanic: Sit to Pause Combat
When a player sits, enemies orbit instead of attacking. A moment to breathe,
strategize, or chat. The game respects your conversation.

### 007 - Group Scaling
Solo play spawns regular mobs. Group up and face rare elites. The challenge
grows with your party. Two players = harder monsters, better loot.

### 008 - Playerbots as Core Feature
AI companions are central, not optional. They fill parties, follow commands,
and have scriptable behavior. You're never truly alone.

### 009 - Scriptable Everything
Custom behavior lives in Lua, not C++. The game is soft-coded for rapid
iteration and experimentation.

### 010 - Track the World
Database changes are version controlled. History preserved. Every change
to the world can be traced back to its origin.

### 011 - Isolation Principle
Self-contained project. Doesn't pollute the system. All paths local.
MySQL on port 3307. Data files copied, not symlinked.

### 012 - Data Separation
Generation separate from viewing. Logic separate from presentation.
Errors encapsulated in smaller and smaller areas.

### 013 - AzerothCore Foundation
WotLK (3.3.5a) emulator, Playerbot-enabled fork. The stable base upon
which all custom logic is built.

### 014 - ALE Scripting Engine
AzerothCore Lua Engine. LuaJIT scripting for game logic. Hooks into
server events. The bridge between C++ core and Lua customization.

### 015 - Local MySQL Installation
Database on port 3307. Not system MySQL. Tracked schema changes.
Reproducible world state.

### 016 - mod-playerbots Module
AI companions. Scriptable behavior. Group formation. The heart of
the solo-friendly experience.

### 017 - mod-aoe-loot Module
Quality-of-life looting. One click, all corpses. Respect for player time.

### 018 - mod-grownup Module
Level scaling. High-level players can play with low-level friends.
The world stays challenging.

### 019 - The Soul: src/lua/
The Lua scripts ARE the game. Everything custom lives here. This is
where the magic happens.

### 020 - periodic_events.lua
Main loop. Ties everything together. Registers timers for ambush,
traveller, and treasure spawns.

### 021 - ambush.lua
Enemy spawning and combat. Queue system for monsters. Banned creature
list. Chase behavior. Orbit-on-sit mechanic.

### 022 - treasure.lua
Chest spawning. Dungeon and raid loot. Dinosaur bones. The reward
system that keeps players moving.

### 023 - travel.lua
NPC traveller system. Friendly wanderers. Merchant spawns. The world
feeling alive with non-hostile movement.

### 024 - movement.lua
Position calculations. Distance checks. Arc spawning. Orbit mechanics.
The math of motion.

### 025 - tempo.lua
Game pacing. Timing utilities. The rhythm of the experience.
Fast when needed, slow when appropriate.

### 026 - Directory: installed-files/
Server binaries. Compiled from source. Gitignored (too large).
The executable layer.

### 027 - Directory: data-files/
Client extracts. DBC, maps, vmaps, mmaps. 3.1GB of game data.
Gitignored. The world geometry.

### 028 - Directory: mysql/databases/
Tracked database files. World state. Character data. The persistent
layer of the game.

### 029 - Directory: issues/
Issue tracking. Markdown files. Immutable once created. The history
of development decisions.

### 030 - Directory: scripts/
Build and maintenance. azerothcore, mysql-start, client launchers.
The tooling layer.

### 031 - Directory: docs/
Documentation. Installation, configuration, scripting guides.
The knowledge layer.

### 032 - libs/wow-chat-1/
Reference implementation. The original. 17KB ambush.lua, 34KB travel.lua.
The ancestor scripts.

### 033 - Phase 1: Foundation
Goal: Establish stable server environment. Playable server is the
completion criterion.

### 034 - Phase 2: Scripting Infrastructure
Goal: Create Lua scripting framework. Utility library, event handlers,
chat commands, hot-reload.

### 035 - Phase 3: Chat System
Goal: Custom chat-based interaction. Message parsing, command routing,
response formatting.

### 036 - Phase 4: Bot Integration
Goal: Script playerbot behavior. Command interface, group management,
quest automation, combat customization.

### 037 - Phase 5: Data and Analytics
Goal: Export game data. Event logging, export formats, statistics,
visualization tools.

### 038 - Issue 101: Verify Server Startup
Auth and world server start without errors. Modules load. Lua scripts
execute. Client connects.

### 039 - Issue 102: Test Playerbots Spawn
Bots spawn correctly. Join party. Follow commands. Combat behavior
functional.

### 040 - Issue 103: Document Configuration Options
What's configurable. Hot-reloadable settings. Restart-required settings.
The knobs and levers.

### 041 - Issue 104: Migrate Lua Scripts from wow-chat-1
Port the original scripts. Adapt to new structure. Preserve functionality.
The great migration.

### 042 - Issue 105: Setup Local MySQL Installation
Port 3307. Local instance. Tracked schema. Reproducible database.

### 043 - Issue 106: In-Game Config Control Board
View and modify settings from in-game. Chat commands. NPC gossip menu.
Runtime adjustments.

### 044 - Issue 200: Incremental Feature Restore
Restore stashed features one-by-one. Test before proceeding.
The careful approach.

### 045 - Databases: acore_world
World definitions. Creature templates, items, spells, quests.
The game rules.

### 046 - Databases: acore_characters
Character data. Player progress, inventory, position.
The save game.

### 047 - Databases: acore_auth
Account data. Authentication, access control.
Login system.

### 048 - Databases: acore_playerbots
Bot data. AI state, configurations.
Companion tracking.

### 049 - Symlink: lua_scripts
installed-files/bin/lua_scripts/ symlinked to src/lua/.
Hot-reload path.

### 050 - Build Script: azerothcore
install, update, run commands. Server compilation and management.
The build system.

### 051 - Build Script: mysql-start
Database startup script. Dependency prerequisite.
Required before worldserver.

### 052 - Build Script: client
Game client launcher. Testing entry point.
Player interface.

### 053 - Server Startup Sequence
MySQL first, then authserver, then worldserver. Order matters.
Dependency chain.

### 054 - Thread Count Detection
Auto-detect via nproc. Optimal -jN for compilation.
Build parallelism.

### 055 - Build Mode: RelWithDebInfo
Optimization with debug symbols. Best of both worlds.
Default build mode.

### 056 - worldserver.conf
Main server configuration. Hundreds of options.
The big config file.

### 057 - mod_playerbots.conf
Bot behavior configuration. AI settings, spawn rules.
Companion customization.

### 058 - Script Load Order
require() dependencies. movement.lua before ambush.lua.
Initialization order matters.

### 059 - VimFold Conventions
-- {{{ function_name on opening line. -- }}} on closing.
Collapsible code blocks.

### 060 - Error Message Preference
Prefer errors over fallbacks. Notify user when fallback used.
Create issue for resolution.

### 061 - Comment Requirements
Explain why changes were made. Consider when moving to change.
History in code.

### 062 - Issue File Before Implementation
Always create issue file first. Read and understand before
implementing. Never after.

### 063 - Issue Immutability
Issues may be added to but never deleted. Move to completed
section. Preserve consent.

### 064 - Phase Demo Requirements
Each phase completion = demo script. Show progress.
Combine tools in new ways.

### 065 - Demo Visual Focus
Demonstrate outputs over descriptions. HTML in Firefox.
Graphical windows. Real results.

### 066 - Git Commit Protocol
Only commit after completing issue. Explain extra changes.
Stage only relevant files.

### 067 - Phase Progress File
issues/phase-X-progress.md. Updated after each issue.
Track phase completion.

### 068 - Balance Updates File
docs/balance-updates.md. Append-only. Small tweaks.
Number changes over time.

### 069 - Deprecated File Protocol
Mark with -done suffix. Keep for one commit. Then remove.
Leave a trace.

### 070 - Test Script for Bug Fixes
Every bug fix = validation test. Ensure functionality.
Prevent regression.

### 071 - Input/Output Directory Pattern
input/ for program inputs. output/ for results.
Clean data flow.

### 072 - OnBeforeConfigLoad Hook
Early initialization point. Fires before config parsing.
ALE entry point.

### 073 - OnBeforeWorldInitialized Hook
Late initialization point. More services available.
Alternative entry point.

### 074 - PlayerScript Registration
RegisterPlayerEvent(). Player hooks for login, logout,
kill creature, death, emote.

### 075 - CreatureScript Registration
RegisterCreatureEvent(). Creature hooks for spawn, death,
combat, movement.

### 076 - OnLogin Event
Player enters world. Session start. Initialize player data,
register periodic events.

### 077 - OnLogout Event
Player leaves world. Session end. Cleanup player data,
deregister events.

### 078 - OnKillCreature Event
Player defeats monster. Combat resolution. Deregister
ambusher, award loot.

### 079 - OnEmote Event
Player performs emote. Gesture input. Trigger convoy
commands.

### 080 - Database Query Execution
WorldDBQuery() synchronous, WorldDBQueryAsync() non-blocking.
Data access patterns.

### 081 - Query Result Handling
GetUInt32(), GetString(), NextRow(). Field access and
row iteration.

### 082 - creature_template Table
Creature definitions. entry, minlevel, maxlevel, rank,
npcflag, lootid, type. Spawn source.

### 083 - RegisterEvent for Timed Callbacks
creature:RegisterEvent(func, delay, repeats). The heartbeat
of all AI behavior.

### 084 - CreateLuaEvent for Global Timers
Server-wide timers. Periodic spawn events.
Global scheduling.

### 085 - Data Storage on Units
unit:SetData("key", value) and unit:GetData("key").
Instance metadata attachment.

### 086 - SendBroadcastMessage
player:SendBroadcastMessage(text). Player notification.
Chat system integration.

### 087 - GetMap and Height Queries
creature:GetMap():GetHeight(x, y). Terrain following.
Proper Z coordinates.

### 088 - NearTeleport for Position Correction
creature:NearTeleport(x, y, z, o). Instant repositioning
after spawn validation.

### 089 - SpawnCreature
player:SpawnCreature(id, x, y, z, o, despawnType, despawnTimer).
Create creature instance.

### 090 - DespawnOrUnsummon
creature:DespawnOrUnsummon(0). Immediate removal from world.
Clean up failed spawns.

### 091 - MoveTo with Random ID
creature:MoveTo(0, x, y, z, true, random_id). Movement with
32-bit tracking ID.

### 092 - MoveRandom for Idle Wander
creature:MoveRandom(30). 30-yard wander radius when idle.
Keep creature moving.

### 093 - MoveHome on Combat End
Return to home position. Reset state. Prepare for next chase.

### 094 - MoveClear to Stop Movement
Clear movement queue. Used when transitioning to orbit.
Stop all movement.

### 095 - AttackStart and AttackStop
Begin or end melee attack. Combat state management.
AI engagement control.

### 096 - SetAggroEnabled
Enable/disable creature aggro. Peaceful mode while player
sits. Orbit behavior.

### 097 - ClearInCombat
Remove combat state. Used with AttackStop for full reset.
Clean state transition.

### 098 - SetHomePosition
Update creature's "home" location. Affects MoveHome.
Dynamic positioning.

### 099 - GetAITarget
creature:GetAITarget(SELECT_TARGET_NEAREST, true, 0, 30, 0).
Find nearby hostile player.

### 100 - Faction-Based Player Lists
Alliance (0), Horde (1), Neutral (2). GetPlayersInWorld for
each faction. Handle all factions.

---

# PART II: AMBUSH SYSTEM
## Concepts 101-175

---

### 101 - Ambush Queue System
Database query for level-appropriate monsters. Queue per player.
Random selection from queue.

### 102 - Banned Creature IDs
~200 creatures that should never spawn. Bosses, event NPCs,
glitchy mobs. The blacklist.

### 103 - Rare vs Regular Spawning
Solo = rare (rank 4). Group 3+ = rare elite (rank 2). Different
corpse despawn timers.

### 104 - Arc Spawn Position
When player is moving, spawn in an arc ahead of them. Intercept
course. Feel like an ambush.

### 105 - Plus Spawn Position
When player is stationary, spawn in cardinal directions. Surround
the target. Tactical spawning.

### 106 - Spawn Z-Height Validation
Check height after spawn. If too high/low, retry up to 5 times.
Reduce spawn distance on each retry.

### 107 - Spawn Water Check
Check if spawned in water. Retry up to 3 times. Despawn if no
valid land position found.

### 108 - Chase Player Behavior
Creatures move toward player until within attack range. Recalculate
position every 1 second.

### 109 - Orbit-on-Sit Behavior
When player sits, creature stops chasing. Orbits at wander radius.
Peaceful coexistence until standing.

### 110 - In-Combat Check Loop
Every 500ms, verify creature is still in combat. If player sits,
return home. If combat ends, deregister.

### 111 - Ambush Deregistration
On creature death or despawn, decrement num-ambushers counter.
Clean up player data.

### 112 - Max Ambushers Per Player
Currently 3. Can't spawn more until existing ambushers die.
Prevents overwhelming spawns.

### 113 - Is-In-Boss-Fight Flag
Set when rare spawns. Prevents regular ambushes. One boss at
a time. Focus mechanic.

### 114 - Map Boundary Respawn
If creature and player on different maps, despawn creature and
re-queue for respawn. Handle zone transitions.

### 115 - Spirit World Handling
Players logging in while dead skip periodic events. Spirit
heartbeat checks for resurrection. Re-register on revive.

### 116 - Corpse Despawn Types
Type 6 = timed (6 minutes). Type 8 = loot-based. Rare elites
persist longer for looting.

### 117 - Broadcast Messages
"Ambush! Watch out!" for regular mobs. "A dark rustling..." for
rares. Player awareness through chat.

### 118 - Creature Data Storage
ambush-chase-target, wander-radius, ambush-max-distance, is-rare.
Metadata on the creature instance.

### 119 - Player Data Storage
queue, rare-queue, num-ambushers, is-in-boss-fight. Metadata on
the player instance.

### 120 - Creature Template Query
SELECT entry, minlevel, maxlevel, rank WHERE level matches player,
npcflag = 0, has loot, is beast/demon/etc.

### 121 - Queue Size Limit
Max 8 creatures per queue. Random selection if query returns more.
Prevent memory bloat.

### 122 - All-Player Queue Update
When query returns, update queues for ALL logged-in players.
Shared query, distributed results.

### 123 - Level Differential Constants
LEVEL_MIN and LEVEL_MAX. How far above/below player level can
creatures spawn. Tunable difficulty.

### 124 - Movement Speed Calculations
creature:GetSpeed(1) for walking speed. Used in orbit position
calculations. Time-based waypoints.

### 125 - Lazy Distance Check
Manhattan distance: |x1-x2| + |y1-y2|. Fast but inaccurate.
Good enough for despawn checks.

### 126 - Close Enough Check
Euclidean distance: sqrt(dx² + dy²). Precise measurement.
Used for combat initiation.

### 127 - Midpoint Calculation
(x1+x2)/2, (y1+y2)/2. Used for chase waypoints. Move toward
player but not directly on top.

### 128 - Initial Angle Calculation
atan2(dy, dx). Starting angle for orbit. Creature's current
position relative to player.

### 129 - Orbit Direction
+1 or -1. Clockwise or counter-clockwise. Flips when terrain
blocks path.

### 130 - Orbit Position Calculation
Advance angle by speed * time / radius. Move along circle
around player.

### 131 - AMBUSH_MIN_DISTANCE (120 yards)
Minimum spawn distance from player. Gives time to react.
Far enough to see coming.

### 132 - AMBUSH_MAX_DISTANCE (160 yards)
Maximum spawn distance. Not too far to miss.
Close enough to engage.

### 133 - WANDER_RADIUS (30 yards)
Orbit distance when player sits. Circle size for peaceful
coexistence.

### 134 - WANDER_ROTATION_DELAY (2000 ms)
Time between orbit waypoints. Controls orbit speed.
Pacing of circular motion.

### 135 - ATTACK_DISTANCE (30 yards)
Distance to initiate attack. Engagement range for combat
start.

### 136 - CREATURE_MAX_DISTANCE (60 yards)
Despawn if creature too far. Tether range to prevent
runaway creatures.

### 137 - MAX_QUEUE_SIZE (8)
Creatures per player ambush queue. Memory limit.
Queue capacity.

### 138 - LEVEL_MIN / LEVEL_MAX (0)
Creature level range relative to player. 0 means exact
level match only.

### 139 - MAX_AMBUSHERS (3)
Maximum simultaneous ambushers per player. Overwhelm
prevention.

### 140 - CORPSE_DESPAWN_REGULAR (6 min)
Regular mob corpse duration. Standard loot window.
Type 6 despawn.

### 141 - CORPSE_DESPAWN_RARE (loot-based)
Rare corpse until looted. Extended loot window.
Type 8 despawn.

### 142 - SPIRIT_HEARTBEAT_DELAY (1000 ms)
Check interval for dead player revival. Spirit world
polling rate.

### 143 - DELAY_PERIODIC_SPAWN_CREATURE (40s)
Main ambush timer in milliseconds. 40 * 1000.
Heart of the danger.

### 144 - DELAY_PERIODIC_SPAWN_TRAVELLER (130s)
Traveller spawn timer. 130 * 1000.
Peaceful rhythm.

### 145 - DELAY_PERIODIC_SPAWN_TREASURE (100s)
Treasure spawn timer. 100 * 1000.
Reward cadence.

### 146 - Random Walk Spawn Interval
Base 40s, changes +/- 2-4s each spawn. Floor 10s.
Soft cap 100s. Hard cap 200s.

### 147 - Grace Period on Login
30 second fixed grace period. Only if offline 10+ minutes.
Quick relogs resume random walk.

### 148 - Position Projection
pos + direction * distance. Move along vector.
Waypoint calculation for spawning.

### 149 - Circle Point Calculation
center + {cos(angle) * radius, sin(angle) * radius}.
Point on circle for orbit.

### 150 - Angle from Vector
atan2(v.y, v.x). Convert direction to facing angle.
Orientation math.

### 151 - Vector to Position
{cos(facing), sin(facing)}. Convert angle to unit direction.
Movement direction.

### 152 - Retry Logic Pattern
tries < MAX_TRIES: retry with modified parameters.
Bounded attempts for validation.

### 153 - Spawn Distance Reduction
On validation failure, minDist = minDist / 2. Shrinking
search to find valid position.

### 154 - Position Validation Pipeline
height_ok AND not_water AND in_range. Multi-check for
spawn validity.

### 155 - State Transition Pattern
creature behavior states: chasing, orbiting, idle.
State machine for AI.

### 156 - Event Cancellation
Implicit through not re-registering callback. Stop
heartbeat by returning early.

### 157 - Callback Chaining
Callback registers next callback. Event sequence for
complex behaviors.

### 158 - denizens_of_the_spirit_world Table
{[guid] = true}. Dead players awaiting respawn. Spirit
world tracking.

### 159 - GetPlayersInWorld
Fetch all players by faction. World query for ambush
target selection.

### 160 - Queue Distribution
For each player: filter creatures by level, add to their
queue. Per-player customization.

### 161 - Random Selection from Queue
table.remove(list, math.random(#list)). Pick and remove.
Queue consumption.

### 162 - Weighted Random Selection
Select based on probability weights. Biased selection
for priority spawning.

### 163 - Level Matching
Appropriate challenge based on player level. Fair fights.
Scaled engagement.

### 164 - Spawn Function Selection
Moving player = getArcSpawnPosition. Stationary = getPlusSpawnPosition.
Dynamic spawn logic.

### 165 - Height Interpolation
map:GetHeight(x, y). Terrain sampling for Z coordinate.
Ground level calculation.

### 166 - Creature Type Filtering
Only spawn beasts, demons, dragonkin, etc. Filter out
humanoids, critters, mechanical.

### 167 - NPC Flag Check
npcflag = 0 means no special functions. No vendors,
trainers, or quest givers in ambush.

### 168 - Loot Check
Only spawn creatures with lootid. Meaningful kills.
Reward-bearing monsters.

### 169 - Rank-Based Selection
rank 0 = normal, 2 = rare elite, 4 = rare. Filter by
difficulty tier.

### 170 - Async Query Callback
WorldDBQueryAsync with callback function. Non-blocking
database access pattern.

### 171 - Combat State Management
Track when creature is fighting. AttackStart sets,
AttackStop clears.

### 172 - Home Position for Reset
Creatures return to home position when combat ends.
MoveHome behavior.

### 173 - Despawn on Failure
If spawn validation fails after max retries, despawn
immediately. Clean up.

### 174 - Player Movement Detection
Check if player position changed recently. Determine
arc vs plus spawn.

### 175 - Combat Range Calculation
Distance between creature and player. Determines when
to engage in melee.

---

# PART III: BEHAVIOR SYSTEMS
## Concepts 176-275

---

### 176 - Gesture Command System
Players command NPCs through body language. Kneeling, sitting,
beckoning. Silent leadership.

### 177 - Kneeling = Sitting (Resource Recovery)
Kneeling grants same benefits as sitting. Increased health/mana
regen. Resting state.

### 178 - NPCs Kneel When Players Approach
Within KNEEL_RADIUS yards, NPCs not in combat kneel. Face the
player. Show reverence.

### 179 - Beckoning Recruits Followers
Player waves/beckons. NPCs who knelt to this player rise.
Follow and assist. Join the convoy.

### 180 - Sitting = Wait Command
Player sits. Convoy members stop following. Move to player
position. Kneel and wait.

### 181 - Kneeling = Directional Waypoint
Player kneels facing a direction. Convoy moves that direction.
Mobile waypoint. Warcraft Rumble style.

### 182 - Facing Direction Updates
While kneeling, player can rotate. Convoy redirects to new
facing. Real-time steering.

### 183 - Convoy System: Ouroboros Chain
NPCs follow in a chain. Each follows the one ahead. Tail
connects to head conceptually. Infinite loop.

### 184 - Convoy Reformation on Death
When a convoy member dies, chain reconnects. Previous follows
next. No gap in formation.

### 185 - Traveling Salesman Reformation
When leader dies, recalculate optimal path. Nearest neighbor
heuristic. New order emerges.

### 186 - Tail Becomes Head
When player leaves, convoy continues without them. Last member
follows first. Ouroboros.

### 187 - Convoy Spacing (3 yards)
CONVOY_SPACING between members. Prevents bunching and collisions.
Formation density.

### 188 - Reverence Target Tracking
npc.reverence_target = player_guid. Remember who the NPC knelt
to. Only respond to that player.

### 189 - Zone Consensus Direction
Average facing of all players in a zone. Idle bots drift that
direction. Collective will.

### 190 - Consensus Strength
Vector magnitude of averaged facings. 0 = chaos (random).
1 = unity (all same direction).

### 191 - Consensus Threshold
CONSENSUS_THRESHOLD for drift activation. Too weak = wander
randomly. Strong enough = follow the flow.

### 192 - Idle Drift Distance
IDLE_DRIFT_DISTANCE * consensus_strength. Move farther when
consensus is strong.

### 193 - WanderToward vs WanderRandom
With consensus: WanderToward target. Without: WanderRandom.
Two modes of idle behavior.

### 194 - Individual Bot Facing: Traveling Salesman Gaze
Bots face their next target. Nearest unvisited. Averaged with
momentum from origin.

### 195 - Momentum Vector
Direction of travel. Current position - last position. Where
the bot came from.

### 196 - Target Vector
Direction to nearest unvisited target. Where the bot is going.
Pathfinding orientation.

### 197 - Average Facing
(momentum + target) / 2. Smooth transition between origin and
destination. Natural curves.

### 198 - Level Affinity System
Bots cluster around players of similar level. Level difference
is the "cost" in traveling salesman.

### 199 - 50% Threshold Rule
Within half the level range = prefer proximity. Beyond halfway
= level becomes primary cost.

### 200 - 75% Opposite Spectrum Rule
No level-appropriate peers? Go to 75% toward opposite end.
Level 20 with no peers seeks ~Lv65.

### 201 - Max Level Exclusive Club
Max level bots only hang with max level players. Elite circles.
End-game community.

### 202 - Max Level Helping Noobs
When no max level peers, high level bots help noobs (Lv≤5) or
players in difficult combat.

### 203 - Fresh Login Detection
Player hasn't moved since logging in. Treated like level 1.
Haven't found purpose yet.

### 204 - Level 1 Bot Behavior
Follow fresh logins, other level 1s, or max level players.
Three acceptable targets.

### 205 - Max Level Dungeon Scaling
Solo max level in open world dungeon = max level monsters.
Scale rewards to challenge.

### 206 - Mixed Party Dungeon Scaling
Scale to highest non-max player. Low levels watch and learn.
Mentorship mechanic.

### 207 - Proportional EXP Sharing
Level 2 with Level 72 gets: base_exp / (72/2) = ~28 EXP.
Still meaningful at low level.

### 208 - Learning by Observation
Low levels can't fight high-level monsters. But they learn.
Passive experience gain.

### 209 - Gesture Tiebreaker: Sitting
Pure proximity. Closest bot responds first. Distance is the
only factor.

### 210 - Gesture Tiebreaker: Kneeling
Axis alignment first, then proximity. On-axis bot beats closer
off-axis bot.

### 211 - Axis Alignment Calculation
Dot product of (to_bot) and (facing). Absolute value.
0 = perpendicular, 1 = on-axis.

### 212 - Mid-Level Boredom Check
Mid-level bots with nothing to do visit noobs. Idle threshold:
300 seconds.

### 213 - Noob Finder Function
find_players_below_level(zone, 10). Find players level 10 or
below. Help them.

### 214 - Fighter Detection
player:IsInCombat() and player:GetHealthPct() < 50. Someone
struggling. Worth helping.

### 215 - Healer Bot Ping-Pong
Healers spiral through 3D space. Ping-pong between players.
Mobile healing stations.

### 216 - Traveling Salesman Healing Path
Sort targets by combined score. Visit in optimal order.
Minimize travel, maximize healing.

### 217 - Healing Priority Score
(1/distance) * health_deficit * role_weight * time_factor.
Proximity is king.

### 218 - Role Weights
Tank = 2.0, Healer = 1.5, DPS = 1.0. Tanks are most important
to keep alive.

### 219 - Time Since Last Healed
Track last heal timestamp per target. Longer = higher priority.
Don't neglect anyone.

### 220 - 3D Spiral Movement
Not direct path. Spiral around the direct line. Two full
rotations per traversal.

### 221 - Spiral Waypoints
Calculate intermediate points. Add circular offset to direct
path. Create helix.

### 222 - PING_PONG_SPEED (300%)
Percent of normal run speed. "Woooosh" past player. Instant
heal. Move on.

### 223 - HEAL_WINDOW (1.5s)
Time to cast while passing. Proximity trigger. No standing
still.

### 224 - MIN_PROXIMITY (5 yards)
Distance to trigger heal. Close enough to cast instant heal.
Then move on.

### 225 - SPIRAL_RADIUS (3 yards)
Healer spiral offset. The width of the helix. Visual flair.

### 226 - Orbit Tank Fallback
Nobody needs healing? Orbit the tank. Stay close for emergency
response.

### 227 - Heal-While-Moving Loop
Continuous circuit. Heal, move, heal, move. Never stop. Always
spiraling.

### 228 - Multiple Healer Coordination
Multiple healers coordinate paths. Avoid overlap. Each takes
different route.

### 229 - Tight Space Spiral Reduction
Dungeons = reduce spiral radius. Don't get stuck on walls.
Adapt to environment.

### 230 - Moving Target Prediction
Target is moving? Lead the spiral. Predict where they'll be.
Intercept.

### 231 - Portal Dimension System
Players can enter battleground maps as exploration zones.
Retail separates; we unify.

### 232 - Battleground Map Mirroring
6 BG maps. Alternative versions of existing zones. Slightly
different terrain.

### 233 - Warsong Gulch Portal (Instance 489)
Forest strongholds. Flag capture arena becomes exploration zone.

### 234 - Arathi Basin Portal (Instance 529)
Resource nodes. Rolling hills. Strategic points become landmarks.

### 235 - Alterac Valley Portal (Instance 30)
Snowy battleground. Stormpike vs Frostwolf. Largest BG becomes
open world.

### 236 - Eye of the Storm Portal (Instance 566)
Floating platforms. Netherstorm aesthetics. Vertical exploration.

### 237 - Strand of the Ancients Portal (Instance 607)
Beach assault. Titan relics. Vehicle combat zone becomes
archaeology site.

### 238 - Isle of Conquest Portal (Instance 628)
Massive siege. Multiple objectives. War zone becomes adventure
map.

### 239 - BG Dimension as End-Game Content
Max level players explore BG maps. Challenging monsters. Unique
rewards.

### 240 - Dimension Scaling
Scale monsters to visitor level. Everyone can explore. Challenge
appropriate.

### 241 - Treasure in Alternate Dimensions
Unique loot only in BG maps. Reason to visit. Exclusive rewards.

### 242 - Randomized Login Screen
Different cinematic each day. Cycle through all options. Fresh
experience daily.

### 243 - Daily Cinematic Rotation
Day 1: Classic. Day 2: BC. Day 3: WotLK. Day 4: Custom. Back
to Day 1.

### 244 - Freddi Fish Background
Animated underwater scene. Virtualized game footage. Playful
aesthetic.

### 245 - Interactive Login Fish
Click on fish = reactions. Swim away, play sound. Bubbles spawn
on empty clicks.

### 246 - ScummVM Integration
Run Freddi Fish in ScummVM. Capture frames. Display as background
texture.

### 247 - Frame Capture Pipeline
ffmpeg capture. 10 fps. 30 seconds of footage. Convert to BLP
sequence.

### 248 - GIF to BLP Conversion
Animated GIF to WoW texture format. Frame-by-frame extraction
and conversion.

### 249 - Glue Screen Addon Hook
WoW addon hooks login screen. Creates transparent frame. Plays
animated texture.

### 250 - Fish Reaction System
find_nearest_fish(x, y). Play animation. Swim away in random
direction.

### 251 - Bubble Spawning
Click empty water = spawn bubbles. Water splash sound. Visual
feedback.

### 252 - Cinematic Index Tracking
Store last_cinematic_index in client config. Increment on new
calendar day.

### 253 - Calendar Day Detection
tonumber(date("%j")). Day of year. Modulo cinematic count.
Cycle through all.

### 254 - KNEEL_RADIUS (10 yards)
Distance to trigger NPC kneeling. Approach radius.

### 255 - BECKON_RADIUS (15 yards)
Distance for beckoning to work. Recruitment range.

### 256 - DIRECTION_UPDATE_RATE (0.5s)
Facing check interval. Steering responsiveness.

### 257 - OUROBOROS_ENABLED
Toggle: tail becomes head on leader loss. Loop behavior.

### 258 - LEVEL_AFFINITY_RANGE (5)
+/- levels to respond to gestures. Peer definition.

### 259 - LEVEL_COST_WEIGHT (10)
How much level matters vs distance. Clustering strength.

### 260 - KNEEL_DIRECTION_DISTANCE (50 yards)
How far to project kneeling direction. Waypoint distance.

### 261 - PROXIMITY_THRESHOLD (0.5)
50% of level range = switch to proximity cost function.

### 262 - NO_PEERS_TARGET_PERCENT (0.75)
75% toward opposite end when no peers. Fallback seeking.

### 263 - MID_LEVEL_BORED_THRESHOLD (300s)
Idle time before visiting noobs. Boredom timer.

### 264 - PING_PONG_ENABLED
Toggle: enable healer spiral behavior. Movement style.

### 265 - MIN_HEALTH_TO_HEAL (90%)
Health threshold below which healing needed.

### 266 - MAX_LEVEL_SCALING
Toggle: scale dungeons for solo max level. End-game.

### 267 - MIXED_PARTY_SCALE_TO_NON_MAX
Toggle: use highest non-max for scaling. Mentorship.

### 268 - PROPORTIONAL_EXP_SHARING
Toggle: level-proportional EXP sharing. Learning mechanic.

### 269 - Convoy Table Structure
{head, members, target}. Convoy state tracking. Formation data.

### 270 - Convoy Member Links
npc.following, npc.follower. Doubly-linked list. Chain structure.

### 271 - Consensus Result Structure
{direction, strength}. Zone consensus output. Collective will.

### 272 - Bot State Enum
"idle", "following", "directed", "gathering", "waiting".
State machine states.

### 273 - Gesture Enum
"kneel_start", "kneel_hold", "beckon", "direct", "wait_command",
"dismiss_convoy". Action types.

### 274 - Chain Reconnection Algorithm
prev.following = next. Skip dead member. Link repair.

### 275 - Head Promotion Algorithm
convoy.head = next. Dead head replacement. Leadership transfer.

---

# PART IV: DATA STRUCTURES & ALGORITHMS
## Concepts 276-375

---

### 276 - Player Queue Table
player:GetData("queue"). Array of creature IDs. Pending ambushers.

### 277 - Player Rare Queue Table
player:GetData("rare-queue"). Separate queue for rare spawns.
Boss candidates.

### 278 - Creature Table Structure
{id, minLevel, maxLevel}. Creature candidate info. Spawn metadata.

### 279 - All Players Table
{alliance={}, horde={}, neutral={}}. Faction-grouped player lists.
World state.

### 280 - Waypoint Table
{{x, y, z}, ...}. Sequence of positions. Path definition.

### 281 - Position Structure
{x, y, z, o}. 3D position plus orientation. Spatial data.

### 282 - Vector Structure
{x, y}. 2D direction. Movement math.

### 283 - Candidate Table
{{player, priority}, ...}. Sorted candidates for targeting.
Priority queue.

### 284 - Path Table
Ordered array of targets. Traveling salesman result. Route.

### 285 - Heal Timestamps Map
healer.heal_timestamps[target_guid] = time. Last heal time per
target. Priority factor.

### 286 - Zone Players Map
zone_players[zone_id] = {players...}. Players by zone. Geographic
indexing.

### 287 - Login Position
player:GetLoginPosition(). Starting point after login. Fresh
login detection.

### 288 - Dungeon Visitors Table
dungeon.visitors = {players...}. Who's in the dungeon. Scaling
input.

### 289 - Treasure Scale
dungeon.treasure_scale = party_size. Loot multiplier. Reward
scaling.

### 290 - Config Category Table
{"rates", "ambush", "playerbots", "server"}. Available categories.
Navigation.

### 291 - Config Setting Structure
{key, value, type, range, description}. Setting metadata. Schema.

### 292 - Stand State Enum
UNIT_STAND_STATE_STAND, _SIT, _KNEEL. Player posture. State
tracking.

### 293 - Player Event Enum
PLAYER_EVENT_ON_LOGIN = 3, PLAYER_EVENT_ON_KILL_CREATURE = 7.
Hook points.

### 294 - Creature Rank Enum
0 = regular, 2 = rare elite, 4 = rare. Spawn categories.
Difficulty tiers.

### 295 - Despawn Type Enum
6 = timed, 8 = loot-based. Corpse behavior. Persistence rules.

### 296 - Target Select Enum
SELECT_TARGET_NEAREST = 3. AI target selection mode. Targeting
strategy.

### 297 - Traveling Salesman Heuristic
Nearest neighbor algorithm. Visit closest unvisited. O(n²)
approximation. Route optimization.

### 298 - Nearest Neighbor Selection
Compare distances to all remaining. Pick minimum. Greedy choice.

### 299 - Path Optimization
Order targets by combined cost. Minimize total travel. Route
planning.

### 300 - Distance Calculation (Euclidean)
sqrt((x2-x1)² + (y2-y1)²). Precise geometry. Standard distance.

### 301 - Distance Calculation (Manhattan)
|x2-x1| + |y2-y1|. Taxicab distance. Fast approximation.

### 302 - Vector Operations
Normalize, add, scale, dot product. Fundamental direction math.
All vector operations consolidated.

### 303 - Angle Calculations
atan2 for direction, acos for difference, sin/cos for conversion.
Trigonometry consolidated.

### 304 - Linear Interpolation
lerp(a, b, t) = a + (b - a) * t. Blend between points. Smooth
transition.

### 305 - Circle Point
center + {cos(angle) * radius, sin(angle) * radius}. Point on
circle. Orbit math.

### 306 - Orbit Angle Increment
angle + (speed * time) / radius. Next orbit position. Angular
velocity.

### 307 - Spiral Point
direct_point + {cos(t * 4π) * radius, sin(t * 4π) * radius}.
Helical path.

### 308 - Midpoint Calculation
{(a.x + b.x) / 2, (a.y + b.y) / 2}. Center point. Chase target.

### 309 - Priority Score Calculation
proximity * deficit * weight * time. Combined metric. Multi-factor
sorting.

### 310 - Health Deficit
100 - health_percent. How much healing needed. Urgency measure.

### 311 - Time Factor
min(time_since_heal / 10, 2.0). Capped scaling. Neglect penalty.

### 312 - Proximity Score
100 / max(distance, 1). Inverse distance. Closer = higher.

### 313 - Level Difference Cost
|bot_level - player_level|². Squared difference. Exponential
penalty.

### 314 - Level Ratio
helper_level / killer_level. Proportional scaling. EXP calculation.

### 315 - Shared EXP Formula
base_exp / level_ratio. Proportional distribution. Fair sharing.

### 316 - 75% Opposite Calculation
level + (max - level) * 0.75. Seek opposite end when no peers.

### 317 - Consensus Vector Sum
sum(cos(facing), sin(facing)) for all players. Directional
accumulation.

### 318 - Consensus Average
sum / count. Mean direction. Central tendency.

### 319 - Consensus Magnitude
sqrt(avg_x² + avg_y²). Agreement strength. 0 = chaos, 1 = unity.

### 320 - Consensus Direction
atan2(avg_y, avg_x). Average facing angle. Collective will.

### 321 - Axis Alignment
|dot(to_bot, facing)|. How aligned with facing. 0 = perpendicular,
1 = on-axis.

### 322 - Sort by Score
table.sort(items, function(a, b) return a.score > b.score end).
Priority ordering.

### 323 - Sort by Distance
table.sort(items, function(a, b) return dist(a) < dist(b) end).
Proximity ordering.

### 324 - Filter by Predicate
filter(list, function(x) return condition(x) end). Subset
selection.

### 325 - Map Transform
map(list, function(x) return transform(x) end). Element
transformation.

### 326 - Reduce Aggregation
reduce(list, function(acc, x) return acc + x end, 0). Accumulation.

### 327 - Queue Construction
for each row: table.insert(queue, entry). Build from query.

### 328 - Queue Truncation
if #queue > max: random_sample(queue, max). Limit size.

### 329 - Event Scheduling
RegisterEvent(callback, delay, repeats). Timer creation. Async
execution.

### 330 - Exponential Backoff
delay = delay * 2. Increasing wait. Congestion avoidance.

### 331 - State Machine
States and transitions. Behavior modeling. AI structure.

### 332 - Nil Coalescing
value or default. Handle missing data. Defaults.

### 333 - Table Iteration
for k, v in pairs(table). Traverse all entries. for i, v in
ipairs(array) for sequential.

### 334 - Table Operations
insert, remove, length (#). Collection management.

### 335 - Empty Check
next(table) == nil. Is table empty? Presence query.

### 336 - Random Number Generation
math.random(min, max) for integers. math.random() for 0-1 float.

### 337 - Math Functions Consolidated
abs, sqrt, floor, ceil, min, max. Standard math library.

### 338 - Clamp
max(min_val, min(value, max_val)). Bounded value. Range enforcement.

### 339 - Wrap
((value - min) % (max - min)) + min. Circular bounds. Angle wrapping.

### 340 - Sign
x > 0 and 1 or (x < 0 and -1 or 0). Direction indicator.

### 341 - Rotate Vector
{x*cos(θ) - y*sin(θ), x*sin(θ) + y*cos(θ)}. 2D rotation.

### 342 - Perpendicular
{-y, x}. 90° rotation. Normal vector.

### 343 - Priority Queue
Heap structure. Efficient min/max access. Scheduling.

### 344 - Linked List
O(1) insert/delete. Convoy chains. Sequential structure.

### 345 - Circular Buffer
Ring structure. Fixed size. Ouroboros data pattern.

### 346 - Hash Table
O(1) lookup. Key-value storage. Lua tables natively.

### 347 - Module Pattern
return module table. API export. Interface definition.

### 348 - Global Table
_G.Ambush = {}. Shared namespace. Module export.

### 349 - Local Scope
local variable. Encapsulation. File isolation.

### 350 - Metatable Integration
setmetatable(), __index. Object-oriented patterns. Polymorphism.

### 351 - Coroutine Potential
Cooperative multitasking. Async patterns. Future use.

### 352 - String Operations
format, find, match, gsub. Text manipulation.

### 353 - OS Integration
os.date(), os.time(). System time queries.

### 354 - Package Integration
require(), package.path. Module loading.

### 355 - Debug Integration
debug.traceback(). Error diagnosis. Stack traces.

### 356 - Garbage Collection
collectgarbage(). Memory management. Resource cleanup.

### 357 - FFI Potential
LuaJIT FFI for C interop. Performance. Native access.

### 358 - Player Data Queries
GetLevel, GetHealth, GetHealthPct, GetPower. Unit stats.

### 359 - Position Queries
GetX, GetY, GetZ, GetO. Spatial queries. Location.

### 360 - Identity Queries
GetGUID, GetEntry, GetName. Entity identification.

### 361 - Character Queries
GetClass, GetRace, GetGender. Character properties.

### 362 - Creature Queries
GetCreatureType, GetRank, GetNPCFlags. NPC properties.

### 363 - State Queries
IsInCombat, IsDead, IsStandState. Unit state.

### 364 - Group Queries
GetGroup, GetMembersCount. Party information.

### 365 - Map Queries
GetMap, GetZoneId, GetAreaId, GetInstanceId. Location.

### 366 - Facing Integration
GetFacing, SetFacing. Orientation management.

### 367 - Speed Integration
GetSpeed, SetSpeed. Velocity management.

### 368 - Health Integration
GetHealth, GetMaxHealth, SetHealth. Vitality management.

### 369 - Combat Integration
IsInCombat, ClearInCombat. Battle state.

### 370 - Aggro Integration
CanAggro, SetAggroEnabled. Hostility state.

### 371 - Home Position Integration
GetHomePosition, SetHomePosition. Reset point.

### 372 - Follow Integration
Follow(target). Pursuit behavior. AI attachment.

### 373 - Aura Integration
AddAura, RemoveAura. Buff/debuff management.

### 374 - Spell Integration
CastSpell, GetSpellId. Ability usage.

### 375 - Item Integration
AddItem, GetItemCount. Inventory management.

---

# PART V: CONFIGURATION REFERENCE
## Concepts 376-450

---

### 376 - Game Rates: XP
Experience point multiplier. Default 1.0. Hot-reloadable.

### 377 - Game Rates: Loot
Drop rate multiplier. Default 1.0. Hot-reloadable.

### 378 - Game Rates: Reputation
Faction standing multiplier. Default 1.0. Hot-reloadable.

### 379 - Game Rates: Honor
PvP currency multiplier. Default 1.0. Hot-reloadable.

### 380 - Server Settings: Max Players
Concurrent player limit. Requires restart.

### 381 - Server Settings: MOTD
Message of the day. Shown on login. Server news.

### 382 - Server Settings: Realm Name
Display name in realm list. Identity.

### 383 - Playerbots: Bot Spawn Settings
How bots appear. Random login, on-demand.

### 384 - Playerbots: AI Behavior Toggles
Combat style, healing priority, crowd control.

### 385 - Playerbots: Party Formation
Where bots stand. Tank front, healer back.

### 386 - Chat Command: .config
Show help. Entry point to configuration.

### 387 - Chat Command: .config list
List categories. Show available options.

### 388 - Chat Command: .config show
Show settings in category. Current values.

### 389 - Chat Command: .config set
Modify setting. Immediate effect if hot-reloadable.

### 390 - Chat Command: .config reload
Reload from files. Discard runtime changes.

### 391 - Chat Command: .config save
Save current to files. Persist runtime changes.

### 392 - NPC Configuration Terminal
Spawnable NPC. Gossip menu for browsing settings.

### 393 - Configuration Backup
Before modify, backup existing. Rollback capability.

### 394 - Hot-Reload Support
Some settings change immediately. No restart needed.

### 395 - Restart-Required Settings
Some settings need server restart. Flagged in UI.

### 396 - Setting Validation
Check value ranges. Reject invalid input.

### 397 - Default Values
Factory settings. Reset option.

### 398 - Setting Dependencies
Some settings depend on others. Cascading requirements.

### 399 - Category Descriptions
Explain what each category controls. Help text.

### 400 - Setting Descriptions
Explain each setting. Units. Valid range.

### 401 - Units Display
"yards", "seconds", "percent". Show measurement.

### 402 - Range Display
"1-100", "0.0-5.0". Show valid range.

### 403 - Current vs Default
Show both values. Know what changed.

### 404 - Export Configuration
Export to file. Share settings.

### 405 - Import Configuration
Load from file. Restore settings.

### 406 - Configuration Diff
Compare two configs. Show differences.

### 407 - Configuration History
Track changes over time. Audit trail.

### 408 - Per-Player Settings
Some settings per-player. Personal preferences.

### 409 - Per-Zone Settings
Different settings per zone. Difficulty scaling.

### 410 - Runtime Variable Access
Lua can read config. sWorld:GetValue("key").

### 411 - Runtime Variable Modification
Lua can write config. sWorld:SetValue("key", val).

### 412 - Configuration Events
OnConfigChange callback. React to changes.

### 413 - Configuration Presets
"Easy", "Normal", "Hard". Bundle of settings.

### 414 - Data Directory Path
${DIR}/data-files/. Game extracts. Maps, vmaps, mmaps.

### 415 - Logs Directory Path
${DIR}/logs/. Runtime output. Auth, Server, Errors.

### 416 - Source Directory Path
${DIR}/source/. AzerothCore source. C++ code.

### 417 - Build Directory Path
${DIR}/build/. CMake output. Compiled objects.

### 418 - Installed Files Path
${DIR}/installed-files/. Server binaries.

### 419 - MySQL Executable Path
${DIR}/mysql/installed-files/bin/mysql. Local client.

### 420 - Database Port (3307)
Local MySQL instance. Not system port 3306.

### 421 - CMake Configuration
Build system. Compiler options. Platform support.

### 422 - Make Parallel Build
-j flag with nproc. Thread count. Speed.

### 423 - Clang++ Compilation
C++ compiler. Code generation.

### 424 - Build Mode: Debug
Full symbols. No optimization. For debugging.

### 425 - Build Mode: Release
Full optimization. Stripped symbols. For production.

### 426 - Installation Target
make install. Binary deployment.

### 427 - Symlink Setup
Link lua_scripts. Configuration path.

### 428 - Database Schema Update
SQL migrations. Structure evolution.

### 429 - Data File Copying
3.1GB game data. Local isolation.

### 430 - Configuration Migration
Path updates. Environment adaptation.

### 431 - Credential Management
Secrets pattern. Not in git.

### 432 - authserver.conf
Authentication server config. Login handling.

### 433 - mod_ale.conf
Lua engine configuration. Script paths.

### 434 - mod_aoe_loot.conf
AOE loot configuration. Range. Item filters.

### 435 - mod_grownup.conf
Level scaling configuration. Stat adjustments.

### 436 - Character Data Persistence
Player persistent state. Inventory, skills, position.

### 437 - World State Persistence
Server persistent state. NPCs, objects, events.

### 438 - Account Data Persistence
User persistent state. Characters, settings.

### 439 - Realm Data
Server identity. Name, type, population.

### 440 - Module Configuration
Per-module settings. Isolated configuration.

### 441 - Script Registry
Loaded scripts. Initialization order.

### 442 - Hook Registry
Registered callbacks. Event handlers.

### 443 - Command Registry
Chat commands. Handler functions.

### 444 - Timer System
CreateLuaEvent global timers. RegisterEvent per-unit.

### 445 - Log Integration
print(), LOG_INFO(). Debug output.

### 446 - Error Integration
error(), assert(). Exception handling.

### 447 - Config Integration
sWorld:GetValue(). Setting access.

### 448 - Time Integration
GetTime(), date(). Temporal queries.

### 449 - IO Integration
Restricted for security. Sandboxing.

### 450 - Session ID
Unique identifier for server session.

---

# PART VI: DEVELOPMENT WORKFLOW
## Concepts 451-550

---

### 451 - Git Version Control
Track changes. History preservation. Collaboration.

### 452 - Branch Strategy
master for stable, feature branches for development.

### 453 - Commit Message Format
feat(id): description. Semantic. Searchable.

### 454 - Co-Author Attribution
Co-Authored-By: header. Credit. Collaboration tracking.

### 455 - Generated Notice
Claude Code attribution. Provenance.

### 456 - Stash for WIP
git stash. Temporary storage. Context switching.

### 457 - Stash Recovery
git checkout stash@{0} -- file. Selective restoration.

### 458 - Git Status Awareness
Track modified files. Change awareness.

### 459 - Git Log History
Commit messages. Development narrative.

### 460 - Git Diff Inspection
Change review. Code comparison.

### 461 - Git Add Selective
Stage specific files. Change isolation.

### 462 - Git Restore
Revert changes. Mistake recovery.

### 463 - Issue-First Development
Create issue before implementing. Planning.

### 464 - Issue File Structure
Current/Intended/Steps. Standard format.

### 465 - Issue Numbering
Phase + ID. Example: 522 = phase 5, issue 22.

### 466 - Sub-Issue Pattern
a, b, c suffixes. Breakdown. Incremental progress.

### 467 - Phase Progress Tracking
phase-X-progress.md. Overview. Status summary.

### 468 - Issue Completion Workflow
Update issue. Move to completed/. Commit.

### 469 - Demo Creation
Phase completion artifact. Validation. Showcase.

### 470 - Test Before Commit
Verify functionality. Validation. Quality assurance.

### 471 - Documentation Updates
Keep docs current. Maintenance.

### 472 - Deprecated File Handling
-done suffix. One commit. Then remove.

### 473 - Server Shutdown Sequence
Graceful termination. State saving.

### 474 - Log Analysis
Error diagnosis. Problem identification.

### 475 - Error Log Review
Errors.log. Historical problems.

### 476 - Console Output Monitoring
Real-time status. Live debugging.

### 477 - Client Connection Testing
Port verification. Network testing.

### 478 - Module Loading Verification
Console messages. Initialization confirmation.

### 479 - Lua Script Loading Verification
require() success. Error messages.

### 480 - Hot-Reload Testing
.reload config. Live changes.

### 481 - Database Query Testing
SQL console. Query verification.

### 482 - In-Game Testing
Play test. Functional validation.

### 483 - Bot Spawn Testing
Playerbot verification. AI functionality.

### 484 - Ambush System Testing
Monster spawning. Combat. Core feature test.

### 485 - Treasure System Testing
Chest spawning. Loot. Reward feature test.

### 486 - Travel System Testing
NPC wandering. Population. Ambient feature test.

### 487 - Gesture System Testing
Emote response. NPC behavior.

### 488 - Convoy System Testing
Follow chains. Formation.

### 489 - Healer System Testing
Spiral movement. Healing.

### 490 - Level Affinity Testing
Bot clustering. Level matching.

### 491 - Consensus Testing
Zone direction. Bot drift.

### 492 - Portal Testing
BG map access. Dimension exploration.

### 493 - Login Screen Testing
Cinematic rotation. Visuals.

### 494 - Config Dashboard Testing
Chat commands. UI.

### 495 - Phase Demo Creation
Comprehensive test. All features.

### 496 - Regression Testing
Previous features work. Stability.

### 497 - Performance Testing
Resource usage. Speed. Efficiency.

### 498 - Memory Testing
Leak detection. Resource management.

### 499 - Stress Testing
Load testing. Scalability.

### 500 - Error Handling Testing
Failure scenarios. Recovery. Robustness.

### 501 - Edge Case Testing
Boundary conditions. Special cases.

### 502 - Integration Testing
Component interaction. System cohesion.

### 503 - Session Management Testing
Login/Logout cycles. State handling.

### 504 - Event Timing Testing
Delay accuracy. Scheduling precision.

### 505 - Callback Testing
Async completion. Correctness.

### 506 - Error Message Testing
Clarity. Helpfulness.

### 507 - Log Quality Testing
Information density. Usefulness.

### 508 - Configuration Validation Testing
Invalid input handling. Robustness.

### 509 - Default Value Testing
Missing config handling. Sensible defaults.

### 510 - Cleanup Testing
Resource release. Termination.

### 511 - Initialization Testing
Startup sequence. Dependencies.

### 512 - Documentation Review
Accuracy check. Completeness.

### 513 - Code Review
Quality check. Best practices.

### 514 - Security Review
Vulnerability check. Safety.

### 515 - Performance Review
Optimization opportunities.

### 516 - Architecture Review
Design check. Structure.

### 517 - Dependency Review
External requirements. Updates.

### 518 - Backup Verification
Recovery testing. Data safety.

### 519 - Restore Testing
Recovery procedure. Disaster recovery.

### 520 - Rollback Testing
Revert procedure. Safety net.

### 521 - Upgrade Testing
Version migration. Compatibility.

### 522 - Cross-Platform Testing
Different environments. Portability.

### 523 - Multi-User Testing
Concurrent access. Scaling.

### 524 - Network Testing
Connectivity. Latency.

### 525 - Timeout Testing
Long operations. Cancellation.

### 526 - Interruption Testing
Mid-operation stop. State consistency.

### 527 - Resource Exhaustion Testing
Memory limits. Graceful degradation.

### 528 - Concurrent Access Testing
Race conditions. Synchronization.

### 529 - State Persistence Testing
Save/Load cycles. Data integrity.

### 530 - Build Script: install-client-addons
Addon deployment. UI customization.

### 531 - CMake Debug Flags
-DCMAKE_BUILD_TYPE=Debug. Full symbols.

### 532 - CMake Release Flags
-DCMAKE_BUILD_TYPE=Release. Optimized.

### 533 - CMake RelWithDebInfo Flags
-DCMAKE_BUILD_TYPE=RelWithDebInfo. Both.

### 534 - Database Schema Tracking
Version controlled migrations.

### 535 - Feature Branch Workflow
Isolate features. Merge when complete.

### 536 - Pull Request Format
Summary + Test Plan. Clear communication.

### 537 - GitHub Integration
gh CLI tool. Automation.

### 538 - HEREDOC for Commits
Proper multiline formatting.

### 539 - Source References
file_path:line_number. Navigation.

### 540 - Code Without Reading First
Never propose changes to unread code.

### 541 - Avoid Over-Engineering
Solve the problem. No extras.

### 542 - No Unnecessary Comments
Self-evident code. Clean.

### 543 - No Unused Code
Delete dead code. Clean.

### 544 - No Backward Compatibility Hacks
Just change it. Clean.

### 545 - Minimum Complexity
Just enough. No more.

### 546 - Future Readers
Consider maintenance. Clarity.

### 547 - Technical Accuracy
Truth over validation.

### 548 - Professional Objectivity
Facts first. No flattery.

### 549 - Respectful Disagreement
When necessary. Honesty.

### 550 - No Time Estimates
What, not when. Concrete steps.

---

# PART VII: VISUAL AND AESTHETIC
## Concepts 551-650

---

### 551 - Ouroboros Imagery
Serpent eating its tail. Infinite loop. Convoy metaphor.

### 552 - Staircase Descent
Healer spiraling down through party. 3D visual.

### 553 - Bee Pollination
Healer visiting flowers. Quick touch, move on.

### 554 - River Finding Sea
Bots curving toward targets. Natural flow.

### 555 - Schools of Fish
Level-appropriate bots clustering. Flocking.

### 556 - Momentum and Drift
Bots blending origin and destination. Smooth curves.

### 557 - The Collective Will
Zone consensus direction. Emergent behavior.

### 558 - World Flow
All bots drifting toward player goal. Zone energy.

### 559 - Silent Leadership
Gestures command without words. Body language.

### 560 - Reverence and Kneeling
NPCs showing respect. Hierarchical display.

### 561 - Rising and Following
NPCs answering the call. Alliance formation.

### 562 - Waiting and Watching
NPCs kneeling beside sitting player. Loyalty.

### 563 - Directional Steering
Kneeling player points the way. Mobile waypoint.

### 564 - Chain Reformation
Death causes reorganization. Resilience.

### 565 - Spiral Healing Path
Helix through formation. 3D beauty.

### 566 - Figure-8 Pattern
Healer weaving through party. Continuous motion.

### 567 - Warsong Gulch Aesthetic
Forest strongholds. Night elf architecture.

### 568 - Arathi Basin Aesthetic
Rolling hills. Farm structures.

### 569 - Alterac Valley Aesthetic
Snowy mountains. Dwarven and orcish camps.

### 570 - Eye of the Storm Aesthetic
Floating platforms. Netherstorm energy.

### 571 - Strand of the Ancients Aesthetic
Beach and titans. Ancient technology.

### 572 - Isle of Conquest Aesthetic
Massive fortress. Industrial military.

### 573 - Freddi Fish Aesthetic
Underwater cartoon. Playful colors.

### 574 - Fish Reactions
Surprised expression. Swimming away.

### 575 - Bubble Effects
Rising bubbles on click. Water physics.

### 576 - Daily Cinematic Variety
Different intro each day. Fresh experience.

### 577 - Login Screen Interactivity
Click and response. Engagement before game.

### 578 - Formation Diagrams
Tank, healer, DPS positions. Party layout.

### 579 - Spawn Position Diagrams
Arc ahead, plus around. Geometry illustration.

### 580 - Orbit Diagram
Circle around sitting player. Movement path.

### 581 - Chase Diagram
Creature approaching player. Direct pursuit.

### 582 - Zone Consensus Diagram
Player arrows averaging. Direction emergence.

### 583 - Config Menu Mockup
Text-based UI. Command structure.

### 584 - NPC Gossip Menu
Tree structure. Selection flow.

### 585 - Roadmap Table
Phase/Milestone/Status. Progress tracking.

### 586 - Issue Tracking Table
ID/Title/Status. Organized work.

### 587 - Directory Tree
Hierarchical structure. Project organization.

### 588 - Configuration Table
Setting/Old/New. Change tracking.

### 589 - Module List
Name and purpose. Component catalog.

### 590 - Timer Table
Event/Delay/Description. Rhythm documentation.

### 591 - Banned Creatures List
IDs and reasons. Blacklist documentation.

### 592 - Emote Mapping Table
Emote ID to action. Input translation.

### 593 - Edge Case List
Scenario and handling. Exception documentation.

### 594 - Validation Commands
Bash examples. Testing instructions.

### 595 - Stash Commands
Git examples. Recovery instructions.

### 596 - Install Steps
Sequential commands. Setup instructions.

### 597 - Update Steps
Sequential commands. Maintenance instructions.

### 598 - Files to Create
Target paths. Implementation scope.

### 599 - Related Issues
Cross-references. Connection mapping.

### 600 - Related Documents
Documentation links. Reference material.

### 601 - Fun Factor Rating
Subjective assessment. Joy measurement.

### 602 - Vision Statement
Purpose description. Why it exists.

### 603 - Promise Statement
Commitment to quality. Design principle.

### 604 - Non-Goals List
What we won't do. Scope boundaries.

### 605 - Status Indicators
Open/In Progress/Completed. State badges.

### 606 - Checkbox List
- [ ] Incomplete. - [x] Complete. Task tracking.

### 607 - Code Blocks
```lua syntax highlighting. Example code.

### 608 - Inline Code
`backtick` formatting. Function names.

### 609 - Headers
# H1 ## H2 ### H3. Document structure.

### 610 - Horizontal Rules
---. Section separation.

### 611 - Bold Text
**emphasis**. Important terms.

### 612 - Italic Text
*emphasis*. Subtle highlighting.

### 613 - Tables
| Column | alignment |. Data presentation.

### 614 - Lists
- Bullet. 1. Numbered. Item enumeration.

### 615 - VimFold Markers
-- {{{ and -- }}}. Code folding.

### 616 - Comment Documentation
-- Explanation. Code clarity.

### 617 - Function Signatures
local function name(params). Interface.

### 618 - Return Documentation
-- Returns: description. Output specification.

### 619 - Parameter Documentation
-- @param name description. Input specification.

### 620 - Example Usage
-- Example: code. Usage demonstration.

### 621 - Warning Comments
-- WARNING: caution. Hazard notification.

### 622 - TODO Comments
-- TODO: task. Future work.

### 623 - FIXME Comments
-- FIXME: problem. Known issue.

### 624 - NOTE Comments
-- NOTE: information. Context.

### 625 - Version Numbers
0.1.0. Semantic versioning.

### 626 - Dates
2026-03-31. ISO format.

### 627 - Author Attribution
Co-Authored-By: Name. Credit.

### 628 - Generated Notice
Generated with Claude Code.

### 629 - License Reference
Link to license.

### 630 - Repository Link
GitHub URL.

### 631 - Feedback Link
Issue tracker.

### 632 - Help Command
/help. User assistance.

### 633 - Vertical Alignment
Connect things at same X value. Signify meaning.

### 634 - Dense Math, Few Functions
Lots of math, fewer functions. Get it right first.

### 635 - Configuration in Structure
Maintain config in code structure. Git greps cheap.

### 636 - Comments Abound
Self-documentation for humans. Comments for machines.

### 637 - Use Vertical Space
Breathe. Group related operations.

### 638 - Powerline Mapping
Parallel pngs/ directory. Annotated screenshots.

### 639 - Powerline Generation
Tool parses source, indexes identifiers, draws lines.

### 640 - Powerline Principles
Vertical alignment first. Powerlines as stop-gap.

### 641 - Skooch Refactoring
Adjust alignment so elements clear visually.

### 642 - Wave Refactoring
Align config points across files.

### 643 - Directory: pngs/
Parallel to src/. Visual documentation.

### 644 - File-to-PNG Mapping
src/lua/ambush.lua → pngs/lua/ambush.png.

### 645 - Semantic Over Syntactic
Connect by meaning, not proximity.

### 646 - Editor-Rendered Powerlines
Powerlines in viewing layer, not source.

### 647 - ASCII Art Diagrams
Text-based visualization. Documentation art.

### 648 - Box Drawing Characters
┌─┐ └─┘ │. Unicode boxes. Clean diagrams.

### 649 - Arrow Indicators
→ ← ↑ ↓ ↗ ↘. Direction symbols.

### 650 - Poetry in Documentation
Rhythmic descriptions. Emotional resonance.

---

# PART VIII: PHILOSOPHY AND IDENTITY
## Concepts 651-800

---

### 651 - Software Design Over Product
Interest in craft, not commercial. Art over commerce.

### 652 - Play With Friends
Social experience. Connection. Human warmth.

### 653 - The Chat in WoW-Chat
Socializing is the system. Not a feature. Core purpose.

### 654 - Scriptable Everything
Soft-code over hard-code. Flexibility. Iteration.

### 655 - Track the World
History preserved. Changes traced. Accountability.

### 656 - Isolation Principle (Philosophy)
Self-contained. No pollution. Clean boundaries.

### 657 - Data Separation (Philosophy)
Generation vs viewing. Concerns isolated. Modularity.

### 658 - Error Over Fallback
Fail loudly. Know problems. Transparency.

### 659 - Issue Before Implementation
Plan first. Document intent. Intentionality.

### 660 - Immutable Issues (Philosophy)
History preserved. Consent tracked. Accountability.

### 661 - Phase Demos (Philosophy)
Validation artifacts. Progress visible. Milestone markers.

### 662 - Visual Over Description
Show, don't tell. Real output. Concrete.

### 663 - Comment Why Not How
Reasoning preserved. Intent clear. Maintainability.

### 664 - Test Every Fix
Prevent regression. Validate behavior. Quality.

### 665 - Append-Only History
Balance updates file. No deletion. Traceability.

### 666 - One Issue Per Change
Atomic changes. Clear history. Organization.

### 667 - Git as Memory
Commit history. Development narrative. Recall.

### 668 - Poetry in Code
Emotional resonance. Beauty in engineering.

### 669 - The Ouroboros Metaphor
Infinite recursion. Tail to head. Continuity.

### 670 - The Traveling Salesman
Optimization. Efficiency. Elegant solutions.

### 671 - The Collective Will
Emergent behavior. Unspoken coordination.

### 672 - Silent Leadership (Philosophy)
Body language. Gesture command. Drama.

### 673 - Reverence and Service
NPCs respect players. Hierarchy. World-building.

### 674 - Level Affinity (Philosophy)
Like attracts like. Natural clustering.

### 675 - The 75% Rule (Philosophy)
When lost, seek different. Exploration. Growth.

### 676 - Learning by Watching (Philosophy)
Low levels observe. Passive growth. Mentorship.

### 677 - Max Level Exclusivity
End-game community. Earned status.

### 678 - Fresh Login Uncertainty
New players = undefined purpose. Potential.

### 679 - The Spiral Path
Not direct. Beautiful curves. Aesthetic motion.

### 680 - Bee Pollination (Philosophy)
Quick touch. Move on. Natural metaphor.

### 681 - River to Sea (Philosophy)
Natural flow. Inevitable destination.

### 682 - Freddi Fish Playfulness
Childlike wonder. Joy in login.

### 683 - Daily Surprise
Rotating content. Fresh experience.

### 684 - Interactive Entry
Click fish. Engagement before play.

### 685 - Battleground Exploration
Combat zones as adventure. Repurposing.

### 686 - Dimension Portals
Alternative realities. Expanded content.

### 687 - Treasure in Dimensions
Unique rewards. Reason to explore.

### 688 - Solo Max Level Challenge
End-game solo content. Self-reliance.

### 689 - Mixed Party Learning
Mentorship mechanic. Shared experience.

### 690 - Proportional Rewards
Fair distribution. Level-appropriate gains.

### 691 - The Promise
"Raise more than one. Pick the purest."

### 692 - Non-Goal: Public Hosting
Private experience. Personal server.

### 693 - Non-Goal: Client Mods
Server-side only. Clean client.

### 694 - Non-Goal: Retail Replication
Not a copy. Original vision.

### 695 - Lua as Soul
The scripts ARE the game. Identity.

### 696 - wow-chat-1 Ancestry
The original. Reference implementation.

### 697 - Resurrection Project
wow-chat-2 brings back the old.

### 698 - One Year of History
Development archaeology. Heritage.

### 699 - Version Milestones
0.1.0 to 1.0.0. Progress markers.

### 700 - Phase Structure (Philosophy)
Organized development. Clear goals.

### 701 - Issue Numbering System
Phase + ID. Organization. Navigation.

### 702 - VimFold Convention (Philosophy)
Collapsible code. Organization.

### 703 - DIR Variable Pattern
Hard-coded at top. Argument override.

### 704 - Script Documentation Standard
CEO-level description. General purpose.

### 705 - Absolute Paths Preference
No cd commands. Explicit targeting.

### 706 - Complete Tasks Fully
No stopping mid-task. Finish.

### 707 - Ask Questions
When uncertain. Clarification.

### 708 - Security Awareness
No vulnerabilities. Responsibility.

### 709 - No Secrets in Git
Credentials separate. Protection.

### 710 - Everland Ghostsong
Project codename. Identity. Vision.

### 711 - WoW Chat 2
Sequel. Evolution. Continuation.

### 712 - Friends While Talking
Core experience. Social gaming.

### 713 - Fight Monsters
Combat pillar. Challenge.

### 714 - Find Treasure
Reward pillar. Motivation.

### 715 - Explore Forgotten Deserts
Discovery pillar. Wonder.

### 716 - Do Quests
Story pillar. Purpose.

### 717 - Find Equipment
Progression pillar. Growth.

### 718 - Solo with AI
Independence. Availability.

### 719 - Difficulty Scales
Adaptive challenge. Fairness.

### 720 - Team Up
Social scaling. Cooperation.

### 721 - Proportionally Harder
Fair challenge. Balanced scaling.

### 722 - WotLK Base
3.3.5a client. Stable foundation.

### 723 - Playerbot Fork
AI-enabled branch. Core dependency.

### 724 - LuaJIT Engine
Fast scripting. Performance.

### 725 - MySQL Backend
Reliable storage. Persistence.

### 726 - Linux Platform
Development environment.

### 727 - Git Tracking (Philosophy)
Version control. History.

### 728 - Markdown Documentation
Readable format. Portable.

### 729 - Issue-Driven Development (Philosophy)
Planning method. Organization.

### 730 - Phase-Based Progress
Milestone structure. Achievement.

### 731 - Demo Artifacts
Validation proof. Celebration.

### 732 - The Soul Directory
src/lua/. Custom logic home.

### 733 - Reference Implementation
libs/wow-chat-1/. Guidance.

### 734 - Clean Rebuild Branch
Starting fresh. New beginning.

### 735 - Stashed Progress
WIP preserved. Recovery option.

### 736 - Incremental Restore
One feature at a time. Careful.

### 737 - Test After Restore
Verify functionality. Quality.

### 738 - Commit After Test
Only when passing. Discipline.

### 739 - Ambush Core
Danger system. Tension.

### 740 - Treasure Core
Reward system. Motivation.

### 741 - Travel Core
Population system. Life.

### 742 - Periodic Events Core
Timing system. Rhythm.

### 743 - Movement Core
Math system. Navigation.

### 744 - Tempo Core
Pacing system. Feel.

### 745 - Gesture Future
Command system. Expression.

### 746 - Convoy Future
Formation system. Teamwork.

### 747 - Healer Future
AI behavior. Support.

### 748 - Affinity Future
Social physics. Clustering.

### 749 - Consensus Future
Emergent behavior. Coordination.

### 750 - Portal Future
Content expansion. Adventure.

### 751 - Login Future
Visual polish. Welcome.

### 752 - Config Future
Control interface. Customization.

### 753 - Analytics Future
Data export. Insight.

### 754 - Wave Survival Future
Escalating challenge. Climax.

### 755 - Bot Personality Future
Character AI. Depth.

### 756 - Quest Automation Future
Convenience. Respect.

### 757 - Chat Commands Future
Interface expansion. Power.

### 758 - Hot Reload Future
Rapid iteration. Speed.

### 759 - Visual Dashboard Future
In-game UI. Control.

### 760 - The Heartbeat
40s ambush, 100s treasure, 130s travel.

### 761 - Sit to Pause
Rest mechanic. Breathing room.

### 762 - Group Scaling Tables
Solo vs party. Challenge curves.

### 763 - Banned Creature Curation
200+ entries. Quality control.

### 764 - Level Matching (Philosophy)
Appropriate challenge. Fair fights.

### 765 - Spawn Position Variety
Arc and plus patterns. Tactical.

### 766 - Height Validation (Philosophy)
No cliff spawns. Fair placement.

### 767 - Water Check (Philosophy)
No underwater spawns. Playability.

### 768 - Chase Logic (Philosophy)
Persistent pursuit. Engagement.

### 769 - Orbit Logic (Philosophy)
Peaceful coexistence. Rest respect.

### 770 - Combat Registration (Philosophy)
Tracking active threats.

### 771 - Death Handling (Philosophy)
Proper cleanup. Stability.

### 772 - Map Boundary Handling (Philosophy)
Cross-zone spawning. Robustness.

### 773 - Spirit World Queue (Philosophy)
Dead player handling. Continuity.

### 774 - Queue Distribution (Philosophy)
Per-player, per-level. Fair spawning.

### 775 - Async Query Pattern (Philosophy)
Non-blocking database. Performance.

### 776 - Callback Chaining (Philosophy)
Event sequences. AI patterns.

### 777 - Timer-Based AI
RegisterEvent heartbeat. Effective.

### 778 - Data Attachment (Philosophy)
SetData/GetData. Flexibility.

### 779 - Broadcast Messages (Philosophy)
Player notification. Awareness.

### 780 - Movement Commands (Philosophy)
MoveTo, MoveRandom, MoveHome.

### 781 - Combat Commands (Philosophy)
AttackStart, AttackStop.

### 782 - State Commands (Philosophy)
SetAggroEnabled, ClearInCombat.

### 783 - Position Queries (Philosophy)
GetLocation, GetDistance.

### 784 - Map Queries (Philosophy)
GetMap, GetHeight.

### 785 - Target Queries (Philosophy)
GetAITarget. Combat selection.

### 786 - Group Queries (Philosophy)
GetGroup, GetMembersCount.

### 787 - Health Queries
GetHealth, GetHealthPct.

### 788 - Level Queries
GetLevel. Power. Matching.

### 789 - GUID Queries
GetGUID. Identity. Tracking.

### 790 - Random Numbers
math.random. Variety.

### 791 - Trigonometry (Philosophy)
sin, cos, atan2. Geometry.

### 792 - Distance Formulas (Philosophy)
Euclidean, Manhattan.

### 793 - Vector Math (Philosophy)
Normalize, dot, project.

### 794 - Interpolation (Philosophy)
lerp. Smooth transitions.

### 795 - Table Operations (Philosophy)
insert, remove, sort.

### 796 - String Operations (Philosophy)
format, find. Text.

### 797 - Global vs Local (Philosophy)
Scope management. Safety.

### 798 - Module Pattern (Philosophy)
Tables as namespaces.

### 799 - Error Handling (Philosophy)
print, return. Robustness.

### 800 - Eight Hundred Complete
Eight hundred concepts cataloged. Consolidated. Efficient.

---

# APPENDIX: CROSS-REFERENCE INDEX

## By System
- Ambush: 003, 021, 101-175, 739, 760-777
- Travel: 004, 023, 741
- Treasure: 005, 022, 740
- Gesture: 176-188, 209-214, 745
- Convoy: 183-188, 269-275, 746
- Healer: 215-230, 747
- Affinity: 198-208, 748
- Consensus: 189-197, 749
- Portal: 231-241, 750
- Login: 242-253, 751
- Config: 376-450, 752

## By Phase
- Phase 1: 033, 038-044
- Phase 2: 034, 044
- Phase 3: 035
- Phase 4: 036
- Phase 5: 037

## By File
- periodic_events.lua: 020, 143-145
- ambush.lua: 021, 101-175
- movement.lua: 024, 148-175, 300-350
- treasure.lua: 022
- travel.lua: 023
- tempo.lua: 025

## By Issue
- 101-verify-server-startup: 011, 013-015, 026-028, 033, 038, 072-073
- 102-test-playerbots-spawn: 008, 016, 039, 383-385
- 103-document-configuration-options: 040, 376-450
- 104-migrate-lua-scripts-from-wowchat1: 019-025, 032, 041, 058
- 105-setup-local-mysql-installation: 015, 028, 042, 420
- 106-ingame-config-control-board: 043, 386-413
- 200-incremental-feature-restore: 003-007, 019-025, 032, 044, 101-275

---

*End of Catalog*
*Consolidated from 1000-concept original (see git history)*
*Generated by Claude Code for Everland Ghostsong*
*2026-04-03*
