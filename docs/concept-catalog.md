# Everland Ghostsong: Concept Catalog
## Ten Hundred Concepts Wide

Generated: 2026-03-31
Project: WoW Chat 2 (Everland Ghostsong)

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

### 014 - Eluna/ALE Scripting Engine
LuaJIT scripting for game logic. Hooks into server events. The bridge
between C++ core and Lua customization.

### 015 - Local MySQL Installation
Database on port 3307. Not system MySQL. Tracked schema changes.
Reproducible world state.

### 016 - mod-playerbots Module
AI companions. Scriptable behavior. Group formation. The heart of
the solo-friendly experience.

### 017 - mod-eluna Module
Original Lua engine. Being replaced by mod-ale for better hooks.
Legacy compatibility layer.

### 018 - mod-aoe-loot Module
Quality-of-life looting. One click, all corpses. Respect for player time.

### 019 - mod-grownup Module
Level scaling. High-level players can play with low-level friends.
The world stays challenging.

### 020 - The Soul: src/lua/
The Lua scripts ARE the game. Everything custom lives here. This is
where the magic happens.

### 021 - periodic_events.lua
Main loop. Ties everything together. Registers timers for ambush,
traveller, and treasure spawns.

### 022 - ambush.lua
Enemy spawning and combat. Queue system for monsters. Banned creature
list. Chase behavior. Orbit-on-sit mechanic.

### 023 - treasure.lua
Chest spawning. Dungeon and raid loot. Dinosaur bones. The reward
system that keeps players moving.

### 024 - travel.lua
NPC traveller system. Friendly wanderers. Merchant spawns. The world
feeling alive with non-hostile movement.

### 025 - movement.lua
Position calculations. Distance checks. Arc spawning. Orbit mechanics.
The math of motion.

### 026 - tempo.lua
Game pacing. Timing utilities. The rhythm of the experience.
Fast when needed, slow when appropriate.

### 027 - wow-chat-survival/waves.lua.vision
Future: Risk of Rain 2 style wave system. Escalating difficulty.
The vision for phase 2+ content.

-- add what it means to be gitignored

### 028 - Directory: installed-files/
Server binaries. Compiled from source. Gitignored (too large).
The executable layer.

### 029 - Directory: data-files/
Client extracts. DBC, maps, vmaps, mmaps. 3.1GB of game data.
Gitignored. The world geometry.

### 030 - Directory: logs/
Runtime logs. Auth.log, Server.log, Errors.log. Gitignored.
Debug output for troubleshooting.

### 031 - Directory: mysql/databases/
Tracked database files. World state. Character data. The persistent
layer of the game.

### 032 - Directory: issues/
Issue tracking. Markdown files. Immutable once created. The history
of development decisions.

### 033 - Directory: scripts/
Build and maintenance. azerothcore, mysql-start, client launchers.
The tooling layer.

### 034 - Directory: docs/
Documentation. Installation, configuration, scripting guides.
The knowledge layer.

### 035 - Directory: notes/
Vision and design notes. The why behind the what. Strategic thinking
preserved for future reference.

### 036 - libs/wow-chat-1/
Reference implementation. The original. 17KB ambush.lua, 34KB travel.lua.
The ancestor scripts.

### 037 - Phase 1: Foundation
Goal: Establish stable server environment. Playable server is the
completion criterion.

### 038 - Phase 2: Scripting Infrastructure
Goal: Create Lua scripting framework. Utility library, event handlers,
chat commands, hot-reload.

### 039 - Phase 3: Chat System
Goal: Custom chat-based interaction. Message parsing, command routing,
response formatting.

### 040 - Phase 4: Bot Integration
Goal: Script playerbot behavior. Command interface, group management,
quest automation, combat customization.

### 041 - Phase 5: Data and Analytics
Goal: Export game data. Event logging, export formats, statistics,
visualization tools.

### 042 - Issue 101: Verify Server Startup
Auth and world server start without errors. Modules load. Lua scripts
execute. Client connects.

### 043 - Issue 102: Test Playerbots Spawn
Bots spawn correctly. Join party. Follow commands. Combat behavior
functional.

### 044 - Issue 103: Document Configuration Options
What's configurable. Hot-reloadable settings. Restart-required settings.
The knobs and levers.

### 045 - Issue 104: Migrate Lua Scripts from wow-chat-1
Port the original scripts. Adapt to new structure. Preserve functionality.
The great migration.

### 046 - Issue 105: Setup Local MySQL Installation
Port 3307. Local instance. Tracked schema. Reproducible database.
Completed.

### 047 - Issue 106: In-Game Config Control Board
View and modify settings from in-game. Chat commands. NPC gossip menu.
Runtime adjustments.

### 048 - Issue 106a: Read-Only Config Dashboard
`.config list` and `.config show`. View without modify. The first step.

### 049 - Issue 106b: Runtime Config Modifications
Hot-reload settings. Immediate effect. Visual feedback on success/failure.

### 050 - Issue 106c: Config Persistence Layer
Write back to files. Backup before modify. Script to regenerate configs.

### 051 - Issue 107: Credential Manager Script
Secure handling of database credentials. Not hardcoded. Not in git.
The secrets pattern.

### 052 - Issue 108: Thread Count Variable
Auto-detect thread count. -jN for make. Optimal compilation.
Completed.

### 053 - Issue 109: Add Build Mode to Azerothcore Script
Debug vs Release. Different flags. Different use cases.
Completed.

### 054 - Issue 200: Incremental Feature Restore
Restore stashed features one-by-one. Test before proceeding.
The careful approach.

### 055 - Ambush Queue System
Database query for level-appropriate monsters. Queue per player.
Random selection from queue.

### 056 - Banned Creature IDs
~200 creatures that should never spawn. Bosses, event NPCs, glitchy
mobs. The blacklist. 7

### 057 - Rare vs Regular Spawning
Solo = rare (rank 4). Group 3+ = rare elite (rank 2). Different
corpse despawn timers.

### 058 - Arc Spawn Position
When player is moving, spawn in an arc ahead of them. Intercept
course. Feel like an ambush.

### 059 - Plus Spawn Position
When player is stationary, spawn in cardinal directions. Surround
the target. Tactical spawning.

### 060 - Spawn Z-Height Validation
Check height after spawn. If too high/low, retry up to 5 times.
Reduce spawn distance on each retry.

### 061 - Spawn Water Check
Check if spawned in water. Retry up to 3 times. Despawn if no
valid land position found.

### 062 - Chase Player Behavior
Creatures move toward player until within attack range. Recalculate
position every 1 second.

### 063 - Orbit-on-Sit Behavior
When player sits, creature stops chasing. Orbits at wander radius.
Peaceful coexistence until standing.

### 064 - In-Combat Check Loop
Every 500ms, verify creature is still in combat. If player sits,
return home. If combat ends, deregister.

### 065 - Ambush Deregistration
On creature death or despawn, decrement num-ambushers counter.
Clean up player data.

### 066 - Max Ambushers Per Player
Currently 3. Can't spawn more until existing ambushers die.
Prevents overwhelming spawns.

### 067 - Is-In-Boss-Fight Flag
Set when rare spawns. Prevents regular ambushes. One boss at a time.
Focus mechanic.

### 068 - Map Boundary Respawn
If creature and player on different maps, despawn creature and
re-queue for respawn. Handle zone transitions.

### 069 - Spirit World Handling
Players logging in while dead skip periodic events. Spirit heartbeat
checks for resurrection. Re-register on revive.

### 070 - Corpse Despawn Types
Type 6 = timed (6 minutes). Type 8 = loot-based. Rare elites persist
longer for looting.

### 071 - Broadcast Messages
"Ambush! Watch out!" for regular mobs. "A dark rustling..." for rares.
Player awareness through chat.

### 072 - Creature Data Storage
ambush-chase-target, wander-radius, ambush-max-distance, is-rare.
Metadata on the creature instance.

### 073 - Player Data Storage
queue, rare-queue, num-ambushers, is-in-boss-fight. Metadata on
the player instance.

### 074 - Async Database Queries
WorldDBQueryAsync for creature template lookup. Non-blocking.
Callback-based result handling.

### 075 - Creature Template Query
SELECT entry, minlevel, maxlevel, rank WHERE level matches player,
npcflag = 0, has loot, is beast/demon/etc.

### 076 - Queue Size Limit
Max 8 creatures per queue. Random selection if query returns more.
Prevent memory bloat.

### 077 - All-Player Queue Update
When query returns, update queues for ALL logged-in players.
Shared query, distributed results.

### 078 - Faction-Based Player Lists
Alliance (0), Horde (1), Neutral (2). GetPlayersInWorld for each.
Handle all factions.

### 079 - Level Differential Constants
LEVEL_MIN and LEVEL_MAX. How far above/below player level can
creatures spawn. Tunable difficulty.

### 080 - Movement Speed Calculations
creature:GetSpeed(1) for walking speed. Used in orbit position
calculations. Time-based waypoints.

### 081 - Lazy Distance Check
Manhattan distance approximation. |x1-x2| + |y1-y2|. Fast but
inaccurate. Good enough for despawn checks.

### 082 - Close Enough Check
Proper distance calculation for attack range. sqrt(dx² + dy²).
Used for combat initiation.

### 083 - Midpoint Calculation
(x1+x2)/2, (y1+y2)/2. Used for chase waypoints. Move toward player
but not directly on top.

### 084 - Initial Angle Calculation
atan2(dy, dx). Starting angle for orbit. Creature's current
position relative to player.

### 085 - Orbit Direction
+1 or -1. Clockwise or counter-clockwise. Flips when terrain
blocks path.

### 086 - Orbit Position Calculation
Advance angle by speed * time / radius. Move along circle
around player.

### 087 - GetMap and Height Queries
creature:GetMap():GetHeight(x, y). Terrain following. Proper Z
coordinates.

### 088 - NearTeleport for Position Correction
creature:NearTeleport(x, y, z, o). Instant repositioning after
spawn validation.

### 089 - MoveTo with Random ID
math.random(0, 4294967295). Movement ID for tracking. 32-bit
unsigned integer.

### 090 - MoveRandom for Idle Wander
creature:MoveRandom(30). 30-yard wander radius when player dead.
Keep creature moving.

### 091 - MoveHome on Combat End
Return to home position. Reset state. Prepare for next chase.

### 092 - MoveClear to Stop Movement
Clear movement queue. Used when transitioning to orbit.
Stop chasing.

### 093 - AttackStart and AttackStop
Begin or end melee attack. Combat state management.

### 094 - SetAggroEnabled
Disable creature aggro during orbit. Peaceful mode while player
sits. Re-enable on stand.

### 095 - ClearInCombat
Remove combat state. Used with AttackStop for full combat reset.

### 096 - SetHomePosition
Update creature's "home" location. Affects MoveHome behavior.
Dynamic positioning.

### 097 - RegisterEvent for Timed Callbacks
creature:RegisterEvent(func, delay, repeats). The heartbeat of
all AI behavior.

### 098 - GetAITarget
creature:GetAITarget(SELECT_TARGET_NEAREST, true, 0, 30, 0).
Find nearby hostile player. 30-yard range.

### 099 - SpawnCreature
player:SpawnCreature(id, x, y, z, o, despawnType, despawnTimer).
Create creature instance.

### 100 - DespawnOrUnsummon
creature:DespawnOrUnsummon(0). Immediate removal from world.
Clean up failed spawns.

---

# PART II: BEHAVIOR SYSTEMS
## Concepts 101-200

---

### 101 - Gesture Command System (Issue 133)
Players command NPCs through body language. Kneeling, sitting,
beckoning. Silent leadership.

### 102 - Kneeling = Sitting (Resource Recovery)
Kneeling grants same benefits as sitting. Increased health/mana
regen. Resting state. But more dramatic.

### 103 - NPCs Kneel When Players Approach
Within KNEEL_RADIUS yards, NPCs not in combat kneel. Face the
player. Show reverence.

### 104 - Beckoning Recruits Followers
Player waves/beckons. NPCs who knelt to this player rise.
Follow and assist. Join the convoy.

### 105 - Sitting = Wait Command
Player sits. Convoy members stop following. Move to player
position. Kneel and wait.

### 106 - Kneeling = Directional Waypoint
Player kneels facing a direction. Convoy moves that direction.
Mobile waypoint. Warcraft Rumble style.

### 107 - Facing Direction Updates
While kneeling, player can rotate. Convoy redirects to new
facing. Real-time steering.

-- beckoning or pointing while kneeling will double the distance or half
   when commanded playerbots reach the end of the line segment forward,
   they start orbiting the player
   max distance is the draw
   min is as close as you want them to be. half a step closer each time.

### 108 - Convoy System: Ouroboros Chain
NPCs follow in a chain. Each follows the one ahead. Tail
connects to head conceptually.

-- as players move around, it changes it's positioning
   recalculates it's curve

### 109 - Convoy Reformation on Death
When a convoy member dies, chain reconnects. Previous follows
next. No gap in formation.

### 110 - Traveling Salesman Reformation
When leader dies, recalculate optimal path. Nearest neighbor
heuristic. New order emerges.

### 111 - Tail Becomes Head
When player leaves, convoy continues without them. Last member
follows first. Infinite loop. Ouroboros.

### 112 - Convoy Spacing
CONVOY_SPACING yards between members. Default 3. Prevents
bunching and collisions.

### 113 - Reverence Target Tracking
npc.reverence_target = player. Remember who the NPC knelt to.
Only respond to that player.

### 114 - Zone Consensus Direction
Average facing of all players in a zone. Idle bots drift
that direction. Collective will.

### 115 - Consensus Strength
Vector magnitude of averaged facings. 0 = chaos (random).
1 = unity (all same direction).

-- 0 is like this old multimedia fusion game I made.
        ask me about it sometime
-- 1 is like 
-- 2 is like the gravity ship in particle fleet emergence
        the one that throws blue particles in a direction
        

### 116 - Consensus Threshold
CONSENSUS_THRESHOLD for drift activation. Too weak = wander
randomly. Strong enough = follow the flow.

### 117 - Idle Drift Distance
IDLE_DRIFT_DISTANCE * consensus_strength. Move farther when
consensus is strong.

### 118 - WanderToward vs WanderRandom
With consensus: WanderToward target. Without: WanderRandom.
Two modes of idle behavior.

### 119 - Individual Bot Facing: Traveling Salesman Gaze
Bots face their next target. Nearest unvisited. Averaged
with momentum from origin.

### 120 - Momentum Vector
Direction of travel. Current position - last position.
Where the bot came from.

### 121 - Target Vector
Direction to nearest unvisited target. Where the bot is
going.

### 122 - Average Facing
(momentum + target) / 2. Smooth transition between origin
and destination. Natural curves.

### 123 - Level Affinity System
Bots cluster around players of similar level. Level difference
is the "cost" in traveling salesman.

### 124 - 50% Threshold Rule
Within half the level range = prefer proximity. Beyond halfway
= level becomes primary cost.

### 125 - 75% Opposite Spectrum Rule
No level-appropriate peers? Go to 75% toward opposite end.
Level 20 with no peers seeks ~Lv65.

### 126 - Max Level Exclusive Club
Max level bots only hang with max level players. Elite
circles. End-game community.

### 127 - Max Level Helping Noobs
When no max level peers, high level bots help noobs (Lv≤5)
or players in difficult combat.

### 128 - Fresh Login Detection
Player hasn't moved since logging in. Same as level 1.
Haven't found their purpose yet.

### 129 - Level 1 Bot Behavior
Follow fresh logins, other level 1s, or max level players.
Three acceptable targets.

### 130 - Max Level Dungeon Scaling
Solo max level in open world dungeon = max level monsters.
Scale rewards to challenge.

### 131 - Mixed Party Dungeon Scaling
Scale to highest non-max player. Low levels watch and learn.
Mentorship mechanic.

### 132 - Proportional EXP Sharing
Level 2 with Level 72 gets: base_exp / (72/2) = ~28 EXP.
Still meaningful at low level.

### 133 - Learning by Observation
Low levels can't fight high-level monsters. But they learn.
Passive experience gain.

### 134 - Gesture Tiebreaker: Sitting
Pure proximity. Closest bot responds first. Distance is
the only factor.

### 135 - Gesture Tiebreaker: Kneeling
Axis alignment first, then proximity. On-axis bot beats
closer off-axis bot.

### 136 - Axis Alignment Calculation
Dot product of (to_bot) and (facing). Absolute value.
0 = perpendicular, 1 = on-axis.

### 137 - Mid-Level Boredom Check
Mid-level bots with nothing to do visit noobs. Idle
threshold: 300 seconds.

### 138 - Noob Finder Function
find_players_below_level(zone, 10). Find players level
10 or below. Help them.

### 139 - Fighter Detection
player:IsInCombat() and player:GetHealthPct() < 50.
Someone struggling. Worth helping.

### 140 - Healer Bot Ping-Pong (Issue 132)
Healers spiral through 3D space. Ping-pong between players.
Mobile healing stations.

### 141 - Traveling Salesman Healing Path
Sort targets by combined score. Visit in optimal order.
Minimize travel, maximize healing.

### 142 - Healing Priority Score
(1/distance) * health_deficit * role_weight * time_factor.
Proximity is king.

### 143 - Role Weights
Tank = 2.0, Healer = 1.5, DPS = 1.0. Tanks are most
important to keep alive.

### 144 - Time Since Last Healed
Track last heal timestamp per target. Longer = higher
priority. Don't neglect anyone.

### 145 - 3D Spiral Movement
Not direct path. Spiral around the direct line. Two full
rotations per traversal.

### 146 - Spiral Waypoints
Calculate intermediate points. Add circular offset to
direct path. Create helix.

### 147 - PING_PONG_SPEED
300% of normal run speed. "Woooosh" past player. Instant
heal. Move on.

### 148 - HEAL_WINDOW
1.5 seconds to cast while passing. Proximity trigger.
No standing still.

### 149 - MIN_PROXIMITY
5 yards to trigger heal. Close enough to cast instant
heal. Then move on.

### 150 - SPIRAL_RADIUS
3 yards offset from direct path. The width of the helix.
Visual flair.

### 151 - Orbit Tank Fallback
Nobody needs healing? Orbit the tank. Stay close for
emergency response.

### 152 - Heal-While-Moving Loop
Continuous circuit. Heal, move, heal, move. Never stop.
Always spiraling.

### 153 - Multiple Healer Coordination
Multiple healers? Coordinate paths. Avoid overlap. Each
takes different route.

### 154 - Tight Space Spiral Reduction
Dungeons = reduce spiral radius. Don't get stuck on walls.
Adapt to environment.

### 155 - Spread Mechanic Handling
Encounter requires spread? Increase speed, reduce spiral.
Fast and direct.

### 156 - Stack Mechanic Handling
Encounter requires stack? Collapse spiral. Stand and heal.
Emergency protocol.

### 157 - Moving Target Prediction
Target is moving? Lead the spiral. Predict where they'll
be. Intercept.

### 158 - Portal Dimension System (Issue 129)
Players can enter battleground maps as exploration zones.
Retail separates; we unify.

### 159 - Battleground Map Mirroring
6 BG maps. Alternative versions of existing zones. Slightly
different terrain.

### 160 - Warsong Gulch Portal
Instance 489. Forest strongholds. Flag capture arena
becomes exploration zone.

### 161 - Arathi Basin Portal
Instance 529. Resource nodes. Rolling hills. Strategic
points become landmarks.

### 162 - Alterac Valley Portal
Instance 30. Snowy battleground. Stormpike vs Frostwolf.
Largest BG becomes open world.

### 163 - Eye of the Storm Portal
Instance 566. Floating platforms. Netherstorm aesthetics.
Vertical exploration.

### 164 - Strand of the Ancients Portal
Instance 607. Beach assault. Titan relics. Vehicle combat
zone becomes archaeology site.

### 165 - Isle of Conquest Portal
Instance 628. Massive siege. Multiple objectives. War zone
becomes adventure map.

### 166 - BG Dimension as End-Game Content
Max level players explore BG maps. Challenging monsters.
Unique rewards.

### 167 - Dimension Scaling
Scale monsters to visitor level. Everyone can explore.
Challenge appropriate.

### 168 - Treasure in Alternate Dimensions
Unique loot only in BG maps. Reason to visit. Exclusive
rewards.

### 169 - Randomized Login Screen (Issue 131)
Different cinematic each day. Cycle through all options.
Fresh experience daily.

### 170 - Daily Cinematic Rotation
Day 1: Classic. Day 2: BC. Day 3: WotLK. Day 4: Custom.
Back to Day 1.

### 171 - Freddi Fish Background
Animated underwater scene. Virtualized game footage.
Playful aesthetic.

### 172 - Interactive Login Fish
Click on fish = reactions. Swim away, play sound. Bubbles
spawn on empty clicks.

### 173 - ScummVM Integration
Run Freddi Fish in ScummVM. Capture frames. Display as
background texture.

### 174 - Frame Capture Pipeline
ffmpeg capture. 10 fps. 30 seconds of footage. Convert
to BLP sequence.

### 175 - GIF to BLP Conversion
Animated GIF to WoW texture format. Frame-by-frame
extraction and conversion.

### 176 - Glue Screen Addon Hook
WoW addon hooks login screen. Creates transparent frame.
Plays animated texture.

### 177 - Fish Reaction System
find_nearest_fish(x, y). Play animation. Swim away in
random direction.

### 178 - Bubble Spawning
Click empty water = spawn bubbles. Water splash sound.
Visual feedback.

### 179 - Cinematic Index Tracking
Store last_cinematic_index in client config. Increment
on new calendar day.

### 180 - Calendar Day Detection
tonumber(date("%j")). Day of year. Modulo cinematic count.
Cycle through all.

### 181 - ALE Initialization (Issue 130)
AzerothCore Lua Engine. Hook registration. Script loading
on server start.

### 182 - OnBeforeConfigLoad Hook
Original initialization point. Fires early. May be too
early for some operations.

### 183 - OnBeforeWorldInitialized Hook
Alternative initialization point. Fires later. More
services available.

### 184 - Lua Script Directory
installed-files/bin/lua_scripts/. Where ALE looks for
Lua files. Symlinked from src/lua/.

### 185 - Script Load Order
require() dependencies. movement.lua before ambush.lua.
Order matters.

### 186 - VimFold Conventions
-- {{{ function_name on opening line. -- }}} on closing.
Collapsible code blocks.

### 187 - Error Message Preference
Prefer errors over fallbacks. Notify user when fallback
used. Create issue for resolution.

### 188 - Comment Requirements
Explain why changes were made. Consider when moving to
change. History in code.

### 189 - Issue File Before Implementation
Always create issue file first. Read and understand
before implementing. Never after.

### 190 - Issue Immutability
Issues may be added to but never deleted. Move to
completed section. Preserve consent.

### 191 - Phase Demo Requirements
Each phase completion = demo script. Show progress.
Combine tools in new ways.

### 192 - Demo Visual Focus
Demonstrate outputs over descriptions. HTML in Firefox.
Graphical windows. Real results.

### 193 - Git Commit Protocol
Only commit after completing issue. Explain extra changes.
Stage only relevant files.

### 194 - Phase Progress File
issues/phase-X-progress.md. Updated after each issue.
Track phase completion.

### 195 - Balance Updates File
docs/balance-updates.md. Append-only. Small tweaks.
Number changes over time.

### 196 - Table of Contents Updates
docs/table-of-contents.md. Add new documents to tree
hierarchy. Keep organized.

### 197 - Deprecated File Protocol
Mark with -done suffix. Keep for one commit. Then remove.
Leave a trace.

### 198 - Test Script for Bug Fixes
Every bug fix = validation test. Ensure functionality.
Prevent regression.

### 199 - Input/Output Directory Pattern
input/ for program inputs. output/ for results. desire/
for wishes. faith/ for blessings.

### 200 - Stratagem Directory
Data flow patterns. Proven useful across areas. Reusable
solutions.

---

# PART III: CONFIGURATION AND TUNING
## Concepts 201-300

---

### 201 - DELAY_PERIODIC_SPAWN_CREATURE
40 * 1000 = 40 seconds. Ambush timer. Heart of the danger.

### 202 - DELAY_PERIODIC_SPAWN_TRAVELLER
130 * 1000 = 130 seconds. Traveller timer. Peaceful rhythm.

### 203 - DELAY_PERIODIC_SPAWN_TREASURE
100 * 1000 = 100 seconds. Treasure timer. Reward cadence.

### 204 - KNEEL_RADIUS
10 yards. Distance to trigger NPC kneeling. Approach
radius.

### 205 - BECKON_RADIUS
15 yards. Distance for beckoning to work. Recruitment
range.

### 206 - CONVOY_SPACING
3 yards. Distance between convoy members. Formation
density.

### 207 - DIRECTION_UPDATE_RATE
0.5 seconds. Facing check interval. Steering responsiveness.

### 208 - OUROBOROS_ENABLED
true/false. Tail becomes head on leader loss. Loop
behavior toggle.

### 209 - LEVEL_AFFINITY_RANGE
5 levels. +/- to respond to gestures. Peer definition.

### 210 - LEVEL_COST_WEIGHT
10. How much level matters vs distance. Clustering
strength.

### 211 - KNEEL_DIRECTION_DISTANCE
50 yards. How far to project kneeling direction.
Waypoint distance.

### 212 - PROXIMITY_THRESHOLD
0.5. 50% of level range = switch to proximity.
Threshold for cost function.

### 213 - NO_PEERS_TARGET_PERCENT
0.75. 75% toward opposite end when no peers. Fallback
seeking distance.

### 214 - MAX_LEVEL_SCALING
true/false. Scale dungeons for solo max level. End-game
toggle.

### 215 - MIXED_PARTY_SCALE_TO_NON_MAX
true/false. Use highest non-max for scaling. Mentorship
toggle.

### 216 - PROPORTIONAL_EXP_SHARING
true/false. Level-proportional EXP sharing. Learning
mechanic toggle.

### 217 - MID_LEVEL_BORED_THRESHOLD
300 seconds. Idle time before visiting noobs. Boredom
timer.

### 218 - PING_PONG_ENABLED
true/false. Enable healer spiral behavior. Movement
style toggle.

### 219 - PING_PONG_SPEED
300. Percent of normal run speed. Healer velocity.

### 220 - SPIRAL_RADIUS
3 yards. Healer spiral offset. Visual width.

### 221 - HEAL_WINDOW
1.5 seconds. Time to cast while passing. Proximity
heal duration.

### 222 - MIN_HEALTH_TO_HEAL
90. Percent health threshold. Below = needs healing.

### 223 - AMBUSH_MIN_DISTANCE
120 yards. Minimum spawn distance from player. Gives
time to react.

### 224 - AMBUSH_MAX_DISTANCE
160 yards. Maximum spawn distance. Not too far to
miss.

### 225 - WANDER_RADIUS
30 yards. Orbit distance when player sits. Circle
size.

### 226 - WANDER_ROTATION_DELAY
2000 ms. Time between orbit waypoints. Orbit speed.

### 227 - ATTACK_DISTANCE
30 yards. Distance to initiate attack. Engagement
range.

### 228 - CREATURE_MAX_DISTANCE
60 yards. Despawn if creature too far. Tether range.

### 229 - MAX_QUEUE_SIZE
8 creatures. Per player ambush queue. Memory limit.

### 230 - LEVEL_MIN
0. Minimum level below player for creatures. Easy
mode.

### 231 - LEVEL_MAX
0. Maximum level above player for creatures. Challenge
limit.

### 232 - MAX_AMBUSHERS
3. Maximum simultaneous ambushers. Overwhelm prevention.

### 233 - CORPSE_DESPAWN_REGULAR
360 * 1000 = 6 minutes. Regular mob corpse duration.
Loot window.

### 234 - CORPSE_DESPAWN_RARE
nil (loot-based). Rare corpse until looted. Extended
loot window.

### 235 - SPIRIT_HEARTBEAT_DELAY
1000 ms. Check if dead player revived. Spirit world
poll rate.

### 236 - Database Port
3307. Local MySQL instance. Not system port 3306.
Isolation.

### 237 - Data Directory
${DIR}/data-files/. Game extracts. Maps, vmaps, mmaps.
Geometry path.

### 238 - Logs Directory
${DIR}/logs/. Runtime output. Auth, Server, Errors.
Debug path.

### 239 - Source Directory
${DIR}/source/. AzerothCore source. C++ code. Build
input.

### 240 - Build Directory
${DIR}/build/. CMake output. Compiled objects. Temporary.

### 241 - Installed Files Directory
${DIR}/installed-files/. Server binaries. Final output.
Runtime path.

### 242 - MySQL Executable Path
${DIR}/mysql/installed-files/bin/mysql. Local MySQL
client. Database tool.

### 243 - Thread Count Detection
Auto-detect available threads. nproc command. Optimal
build parallelism.

### 244 - Build Mode: Debug
Full symbols. No optimization. For debugging. Slower
execution.

### 245 - Build Mode: Release
Full optimization. Stripped symbols. For production.
Faster execution.

### 246 - Build Mode: RelWithDebInfo
Optimization with debug info. Best of both. Default
mode.

### 247 - Game Rates: XP
Experience point multiplier. Default 1.0. Hot-reloadable.

### 248 - Game Rates: Loot
Drop rate multiplier. Default 1.0. Hot-reloadable.

### 249 - Game Rates: Reputation
Faction standing multiplier. Default 1.0. Hot-reloadable.

### 250 - Game Rates: Honor
PvP currency multiplier. Default 1.0. Hot-reloadable.

### 251 - Server Settings: Max Players
Concurrent player limit. Requires restart. Capacity
planning.

### 252 - Server Settings: MOTD
Message of the day. Shown on login. Server news.

### 253 - Server Settings: Realm Name
Display name in realm list. Identity. Branding.

### 254 - Playerbots: Bot Spawn Settings
How bots appear. Random login. On-demand. Spawn
behavior.

### 255 - Playerbots: AI Behavior Toggles
Combat style. Healing priority. Crowd control. Bot
personality.

### 256 - Playerbots: Party Formation
Where bots stand. Tank front. Healer back. Positioning
rules.

### 257 - Config Categories
rates, ambush, playerbots, server. Organizational
structure. Menu hierarchy.

### 258 - Chat Command: .config
Show help. Entry point to configuration. User
interface.

### 259 - Chat Command: .config list
List categories. Show available options. Navigation.

### 260 - Chat Command: .config show
Show settings in category. Current values. Inspection.

### 261 - Chat Command: .config set
Modify setting. Immediate effect if hot-reloadable.
Mutation.

### 262 - Chat Command: .config reload
Reload from files. Discard runtime changes. Reset.

### 263 - Chat Command: .config save
Save current to files. Persist runtime changes.
Commit.

### 264 - NPC Configuration Terminal
Spawnable NPC. Gossip menu for browsing. GUI-like
interface.

### 265 - Configuration Backup
Before modify, backup existing. Rollback capability.
Safety net.

### 266 - Configuration Restore
Restore from backup. Undo changes. Recovery.

### 267 - Hot-Reload Support
Some settings change immediately. No restart needed.
Dynamic configuration.

### 268 - Restart-Required Settings
Some settings need server restart. Flagged in UI.
User expectation.

### 269 - worldserver.conf
Main server configuration. Hundreds of options.
The big file.

### 270 - authserver.conf
Authentication server config. Login handling.
Security settings.

### 271 - mod_ale.conf
Lua engine configuration. Script paths. Debug
options.

### 272 - mod_playerbots.conf
Bot behavior configuration. AI settings. Spawn
rules.

### 273 - mod_aoe_loot.conf
AOE loot configuration. Range. Item filters.
Quality of life.

### 274 - mod_grownup.conf
Level scaling configuration. Stat adjustments.
Difficulty curves.

### 275 - Database-Backed Settings
Store in database instead of files. Easier runtime
modification. Alternative approach.

### 276 - Visual Feedback on Config Change
Show success/failure. Green = worked. Red = failed.
User confirmation.

### 277 - Confirmation Dialogs
Dangerous changes require confirmation. "Are you
sure?" Protection.

### 278 - Setting Validation
Check value ranges. Reject invalid input. Type
checking.

### 279 - Default Values
Factory settings. Reset option. Known-good
configuration.

### 280 - Setting Dependencies
Some settings depend on others. Enable X requires
Y. Cascading requirements.

### 281 - Category Descriptions
Explain what each category controls. Help text.
Documentation in UI.

### 282 - Setting Descriptions
Explain each setting. Units. Valid range. Inline
documentation.

### 283 - Units Display
"yards", "seconds", "percent". Show measurement.
Clarity.

### 284 - Range Display
"1-100", "0.0-5.0". Show valid range. Constraints.

### 285 - Current vs Default
Show both values. Know what changed. Comparison.

### 286 - Export Configuration
Export to file. Share settings. Backup whole
config.

### 287 - Import Configuration
Load from file. Restore settings. Configuration
migration.

### 288 - Configuration Diff
Compare two configs. Show differences. Debug
tool.

### 289 - Configuration History
Track changes over time. Git for configs. Audit
trail.

### 290 - Per-Player Settings
Some settings per-player. Personal preferences.
Individual customization.

### 291 - Per-Zone Settings
Different settings per zone. Difficulty scaling.
Regional configuration.

### 292 - Per-Creature Settings
Override defaults for specific creatures. Tuning.
Fine-grained control.

### 293 - Runtime Variable Access
Lua can read config. sWorld:GetValue("key").
Scripting integration.

### 294 - Runtime Variable Modification
Lua can write config. sWorld:SetValue("key", val).
Dynamic adjustment.

### 295 - Configuration Events
OnConfigChange callback. React to changes. Live
updates.

### 296 - Configuration Presets
"Easy", "Normal", "Hard". Bundle of settings.
Quick setup.

### 297 - Seasonal Configuration
Holiday events. Time-limited settings. Calendar
triggers.

### 298 - A/B Testing Support
Random assignment. Measure outcomes. Data-driven
tuning.

### 299 - Configuration Documentation
Auto-generate docs from config schema. Always
current. Self-documenting.

### 300 - Configuration Migration
Handle version upgrades. Translate old settings.
Compatibility.

---

# PART IV: DATA STRUCTURES
## Concepts 301-400

---

### 301 - Player Queue Table
player:GetData("queue"). Array of creature IDs.
Pending ambushers.

### 302 - Player Rare Queue Table
player:GetData("rare-queue"). Separate queue for
rare spawns. Boss candidates.

### 303 - Creature Table Structure
{id, minLevel, maxLevel}. Creature candidate info.
Spawn metadata.

### 304 - All Players Table
{alliance={}, horde={}, neutral={}}. Faction-grouped
player lists. World state.

### 305 - Convoy Table
{head, members, target}. Convoy state. Formation
tracking.

### 306 - Convoy Member Links
npc.following, npc.follower. Doubly-linked list.
Chain structure.

### 307 - Reverence Target
npc.reverence_target = player_guid. Who the NPC
serves. Loyalty tracking.

### 308 - Spirit World Table
denizens_of_the_spirit_world = {[guid] = true}.
Dead players awaiting respawn.

### 309 - BANNED_CREATURE_IDS Array
~200 entries. Creatures that should never spawn.
Blacklist.

### 310 - BANNED_RARE_IDS Array
Currently empty. Reserved for rare blacklist.
Future use.

### 311 - GESTURE_EMOTES Map
{[EMOTE_ID] = "action_name"}. Map emote IDs to
actions. Input translation.

### 312 - Waypoint Table
{{x, y, z}, ...}. Sequence of positions. Path
definition.

### 313 - Position Structure
{x, y, z, o}. 3D position plus orientation.
Spatial data.

### 314 - Vector Structure
{x, y}. 2D direction. Movement math.

### 315 - Spawn Function Reference
spawnFunction = Movement.getArcSpawnPosition or
Movement.getPlusSpawnPosition. Dynamic selection.

### 316 - Candidate Table
{{player, priority}, ...}. Sorted candidates for
targeting. Priority queue.

### 317 - Path Table
Ordered array of targets. Traveling salesman
result. Route.

### 318 - Heal Timestamps Map
healer.heal_timestamps[target_guid] = time.
Last heal time per target. Priority factor.

### 319 - Zone Players Map
zone_players[zone_id] = {players...}. Players by
zone. Geographic indexing.

### 320 - Login Position
player:GetLoginPosition(). Starting point after
login. Fresh login detection.

### 321 - Dungeon Visitors Table
dungeon.visitors = {players...}. Who's in the
dungeon. Scaling input.

### 322 - Treasure Scale
dungeon.treasure_scale = party_size. Loot
multiplier. Reward scaling.

### 323 - Config Category Table
{"rates", "ambush", "playerbots", "server"}.
Available categories. Navigation.

### 324 - Config Setting Table
{key, value, type, range, description}. Setting
metadata. Schema.

### 325 - Config Change Event
{setting, old_value, new_value, player}. Change
record. Audit.

### 326 - Backup Manifest
{timestamp, settings_count, checksum}. Backup
metadata. Verification.

### 327 - Player Facing
player:GetFacing(). Radians 0-2π. Direction
looking. Orientation.

### 328 - Consensus Result
{direction, strength}. Zone consensus output.
Collective will.

### 329 - Bot State Enum
"idle", "following", "directed", "gathering",
"waiting". State machine states.

### 330 - Gesture Enum
"kneel_start", "kneel_hold", "beckon", "direct",
"wait_command", "dismiss_convoy". Action types.

### 331 - Creature Rank Enum
0 = regular, 2 = rare elite, 4 = rare. Spawn
categories. Difficulty tiers.

### 332 - Despawn Type Enum
6 = timed, 8 = loot-based. Corpse behavior.
Persistence rules.

### 333 - Target Select Enum
SELECT_TARGET_NEAREST = 3. AI target selection
mode. Targeting strategy.

### 334 - Stand State Enum
UNIT_STAND_STATE_STAND, _SIT, _KNEEL. Player
posture. State tracking.

### 335 - Player Event Enum
PLAYER_EVENT_ON_LOGIN = 3, PLAYER_EVENT_ON_KILL_CREATURE = 7.
Hook points.

### 336 - Movement Queue
Internal creature movement queue. MoveTo entries.
Path following.

### 337 - Event Registration
{function, delay, repeats}. Timed callback. The
heartbeat registration.

### 338 - Query Result
{fields...}. Database query output. Row data.

### 339 - Query Callback
function(query). Async result handler. Non-blocking
data access.

### 340 - Creature Template Row
{entry, minlevel, maxlevel, rank, npcflag, lootid,
type}. Database schema. Spawn source.

### 341 - Map Height Query
map:GetHeight(x, y). Terrain Z at position.
Ground level.

### 342 - Distance Result
sqrt(dx² + dy²). Euclidean distance. Precise
measurement.

### 343 - Lazy Distance Result
|dx| + |dy|. Manhattan distance. Fast approximation.

### 344 - Angle Result
atan2(dy, dx). Radians. Direction calculation.

### 345 - Orbit Position Result
{x, y}. Next position on circle. Orbit math
output.

### 346 - Midpoint Result
{x, y}. Point between two positions. Chase
target.

### 347 - Arc Spawn Result
{x, y}. Position in arc ahead of player. Ambush
point.

### 348 - Plus Spawn Result
{x, y}. Cardinal direction from player. Surround
point.

### 349 - Height Validation Result
boolean. Is Z acceptable? Spawn validity check.

### 350 - Water Check Result
boolean. Is position in water? Spawn validity
check.

### 351 - Combat Check Result
boolean. Is creature in combat? State query.

### 352 - Aggro Check Result
boolean. Can creature aggro? Ability query.

### 353 - Stand State Check
boolean. Is player standing? Activity query.

### 354 - Dead Check Result
boolean. Is unit dead? Mortality query.

### 355 - Group Check Result
boolean. Is player in group? Social query.

### 356 - Group Count Result
number. How many in group? Party size.

### 357 - Level Query Result
number. Unit level. Power metric.

### 358 - Health Percent Result
number. Current health / max health * 100.
Damage assessment.

### 359 - Speed Query Result
number. Movement speed. Velocity.

### 360 - Location Query Result
{x, y, z, o}. Current position. Spatial query.

### 361 - Map Query Result
object. Map reference. Geometry access.

### 362 - GUID Query Result
number. Globally unique identifier. Entity ID.

### 363 - Entry Query Result
number. Creature template ID. Type identifier.

### 364 - Zone Query Result
number. Zone ID. Geographic identifier.

### 365 - Instance Query Result
number. Instance ID. Map version.

### 366 - Phase Completion Table
{phase_number, issues_completed, issues_total,
demo_created}. Progress tracking.

### 367 - Issue Structure
{id, title, status, current_behavior, intended_behavior,
implementation_steps}. Issue schema.

### 368 - Commit Structure
{hash, message, files_changed, timestamp}. Git
commit metadata.

### 369 - Stash Structure
{index, description, timestamp}. Git stash
metadata.

### 370 - Feature Restore Checklist
{feature_name, restored, tested, committed}.
Migration tracking.

### 371 - Demo Script
Lua script that demonstrates phase features.
Validation artifact.

### 372 - Test Result
{test_name, passed, error_message}. Test output.
Validation.

### 373 - Log Entry
{timestamp, level, message, source}. Runtime
log record.

### 374 - Error Log
Accumulated errors. Debugging history. Problem
record.

### 375 - Session ID
Unique identifier for server session. Correlation
key.

### 376 - Character Data
Player persistent state. Inventory, skills,
position. Save game.

### 377 - World State
Server persistent state. NPCs, objects, events.
Global data.

### 378 - Account Data
User persistent state. Characters, settings,
access. Authentication.

### 379 - Realm Data
Server identity. Name, type, population. Meta
configuration.

### 380 - Module Configuration
Per-module settings. Isolated configuration.
Encapsulation.

### 381 - Script Registry
Loaded scripts. Initialization order. Module
system.

### 382 - Hook Registry
Registered callbacks. Event handlers. Extension
points.

### 383 - Command Registry
Chat commands. Handler functions. User interface
extension.

### 384 - NPC Registry
Spawned NPCs. Active entities. World population.

### 385 - Creature Registry
Creature templates. Type definitions. Spawn
catalog.

### 386 - Item Registry
Item templates. Type definitions. Loot catalog.

### 387 - Spell Registry
Spell templates. Ability definitions. Combat
catalog.

### 388 - Quest Registry
Quest templates. Story definitions. Content
catalog.

### 389 - Zone Registry
Zone definitions. Geographic data. World map.

### 390 - Map Registry
Map definitions. Geometry data. Terrain.

### 391 - Instance Registry
Instance templates. Dungeon definitions. Instanced
content.

### 392 - Faction Registry
Faction definitions. Reputation systems. Political
structure.

### 393 - Event Registry
Scheduled events. Timer system. Automation.

### 394 - Broadcast Registry
Broadcast messages. Server announcements. Communication.

### 395 - Channel Registry
Chat channels. Communication infrastructure. Social
system.

### 396 - Guild Registry
Guild data. Player organizations. Social groups.

### 397 - Arena Registry
Arena teams. Competitive groups. PvP structure.

### 398 - Battleground Registry
BG instances. PvP content. Combat zones.

### 399 - Achievement Registry
Achievement definitions. Progress tracking.
Accomplishments.

### 400 - Calendar Registry
Calendar events. Scheduled activities. Time
system.

---

# PART V: ALGORITHMS AND MATHEMATICS
## Concepts 401-500

---

### 401 - Traveling Salesman Heuristic
Nearest neighbor algorithm. Visit closest unvisited.
O(n²) approximation.

### 402 - Nearest Neighbor Selection
Compare distances to all remaining. Pick minimum.
Greedy choice.

### 403 - Path Optimization
Order targets by combined cost. Minimize total
travel. Route planning.

### 404 - Distance Calculation
sqrt((x2-x1)² + (y2-y1)²). Euclidean distance.
Precise geometry.

### 405 - Manhattan Distance
|x2-x1| + |y2-y1|. Taxicab distance. Fast
approximation.

### 406 - Vector Normalization
v / |v|. Unit vector. Direction without magnitude.

### 407 - Vector Addition
{a.x + b.x, a.y + b.y}. Combine directions.
Vector math.

### 408 - Vector Averaging
(a + b) / 2. Midpoint direction. Blending.

### 409 - Dot Product
a.x * b.x + a.y * b.y. Alignment measure.
-1 to 1.

### 410 - Angle from Dot Product
acos(dot(a, b)). Radians between vectors.
Angular difference.

### 411 - Facing to Vector
{cos(facing), sin(facing)}. Convert angle to
direction. Orientation math.

### 412 - Vector to Facing
atan2(v.y, v.x). Convert direction to angle.
Inverse orientation.

### 413 - Position Projection
pos + direction * distance. Move along vector.
Waypoint calculation.

### 414 - Linear Interpolation
lerp(a, b, t) = a + (b - a) * t. Blend between
points. Smooth transition.

### 415 - Circle Point
center + {cos(angle) * radius, sin(angle) * radius}.
Point on circle. Orbit math.

### 416 - Orbit Angle Increment
angle + (speed * time) / radius. Next orbit position.
Angular velocity.

### 417 - Spiral Point
direct_point + {cos(t * 4π) * radius, sin(t * 4π) * radius}.
Helical path. Spiral calculation.

### 418 - Midpoint Calculation
{(a.x + b.x) / 2, (a.y + b.y) / 2}. Center point.
Chase target.

### 419 - Height Interpolation
map:GetHeight(x, y). Terrain sampling. Z from
geometry.

### 420 - Random Selection
table.remove(list, math.random(#list)). Pick and
remove. Queue consumption.

### 421 - Weighted Random
Select based on probability weights. Biased
selection. Priority spawning.

### 422 - Priority Score
proximity * deficit * weight * time. Combined
metric. Multi-factor sorting.

### 423 - Health Deficit
100 - health_percent. How much healing needed.
Urgency measure.

### 424 - Time Factor
min(time_since_heal / 10, 2.0). Capped scaling.
Neglect penalty.

### 425 - Proximity Score
100 / max(distance, 1). Inverse distance. Closer
= higher.

### 426 - Level Difference Cost
|bot_level - player_level|². Squared difference.
Exponential penalty.

### 427 - Level Ratio
helper_level / killer_level. Proportional scaling.
EXP calculation.

### 428 - Shared EXP Formula
base_exp / level_ratio. Proportional distribution.
Fair sharing.

### 429 - 75% Opposite Calculation
level + (max - level) * 0.75 or level - (level - 1) * 0.75.
Seek opposite end.

### 430 - Consensus Vector Sum
sum(cos(facing), sin(facing)) for all players.
Directional accumulation.

### 431 - Consensus Average
sum / count. Mean direction. Central tendency.

### 432 - Consensus Magnitude
sqrt(avg_x² + avg_y²). Agreement strength.
0 = chaos, 1 = unity.

### 433 - Consensus Direction
atan2(avg_y, avg_x). Average facing angle.
Collective will.

### 434 - Axis Alignment
|dot(to_bot, facing)|. How aligned with facing.
0 = perpendicular, 1 = on-axis.

### 435 - Sort by Score
table.sort(items, function(a, b) return a.score > b.score end).
Priority ordering. Descending.

### 436 - Sort by Distance
table.sort(items, function(a, b) return dist(a) < dist(b) end).
Proximity ordering. Ascending.

### 437 - Filter by Predicate
filter(list, function(x) return condition(x) end).
Subset selection. Conditional.

### 438 - Map Transform
map(list, function(x) return transform(x) end).
Element transformation. Projection.

### 439 - Reduce Aggregation
reduce(list, function(acc, x) return acc + x end, 0).
Accumulation. Summary.

### 440 - Chain Reconnection
prev.following = next. Skip dead member. Link
repair.

### 441 - Head Promotion
convoy.head = next. Dead head replacement.
Leadership transfer.

### 442 - Queue Construction
for each row: table.insert(queue, entry). Build
from query. Initialization.

### 443 - Queue Truncation
if #queue > max: random_sample(queue, max). Limit
size. Memory management.

### 444 - Queue Distribution
for each player: filter by level, add to player queue.
Spread results. Per-player queues.

### 445 - Event Scheduling
RegisterEvent(callback, delay, repeats). Timer
creation. Async execution.

### 446 - Event Cancellation
implicit through returns. Don't re-register.
Timer termination.

### 447 - Callback Chaining
callback registers next callback. Event sequence.
State machine.

### 448 - Retry Logic
tries < MAX_TRIES: retry. Bounded attempts.
Failure handling.

### 449 - Exponential Backoff
delay = delay * 2. Increasing wait. Congestion
avoidance.

### 450 - Spawn Distance Reduction
minDist = minDist / 2. Shrinking search. Find
valid position.

### 451 - Position Validation
height_ok and not_water and in_range. Multi-check.
Spawn validity.

### 452 - State Transition
creature:SetState("new_state"). State machine
progression. Behavior change.

### 453 - Data Storage
unit:SetData("key", value). Attach metadata.
Instance state.

### 454 - Data Retrieval
unit:GetData("key"). Read metadata. State query.

### 455 - Nil Coalescing
value or default. Handle missing data. Defaults.

### 456 - Table Iteration
for k, v in pairs(table). Traverse all entries.
Enumeration.

### 457 - Array Iteration
for i, v in ipairs(array). Traverse sequential.
Ordered enumeration.

### 458 - Table Removal
table.remove(table, index). Delete and shift.
Queue pop.

### 459 - Table Insert
table.insert(table, value). Append. Queue push.

### 460 - Table Length
#table. Array length. Size query.

### 461 - Empty Check
next(table) == nil. Is table empty? Presence
query.

### 462 - Random Number
math.random(min, max). Integer in range. Chance.

### 463 - Random Float
math.random(). 0 to 1. Probability.

### 464 - Absolute Value
math.abs(x). Remove sign. Magnitude.

### 465 - Square Root
math.sqrt(x). Root extraction. Distance formula.

### 466 - Sine
math.sin(x). Trigonometric function. Circle
math.

### 467 - Cosine
math.cos(x). Trigonometric function. Circle
math.

### 468 - Arc Tangent 2
math.atan2(y, x). Four-quadrant angle. Direction
calculation.

### 469 - Floor
math.floor(x). Round down. Integer conversion.

### 470 - Minimum
math.min(a, b). Lesser value. Clamping.

### 471 - Maximum
math.max(a, b). Greater value. Clamping.

### 472 - Modulo
x % y. Remainder. Cycling.

### 473 - Power
x ^ y. Exponentiation. Scaling.

### 474 - Pi
math.pi = 3.14159... Circle constant. Radian
conversion.

### 475 - Degrees to Radians
degrees * (π / 180). Angle conversion. Unit
change.

### 476 - Radians to Degrees
radians * (180 / π). Angle conversion. Unit
change.

### 477 - Clamp
max(min, min(value, max)). Bounded value. Range
enforcement.

### 478 - Wrap
((value - min) % (max - min)) + min. Circular
bounds. Angle wrapping.

### 479 - Sign
x > 0 and 1 or (x < 0 and -1 or 0). Direction
indicator. Polarity.

### 480 - Normalize
x / |x|. Make unit length. Direction only.

### 481 - Rotate Vector
{x*cos(θ) - y*sin(θ), x*sin(θ) + y*cos(θ)}.
2D rotation. Transform.

### 482 - Scale Vector
{x * s, y * s}. Magnitude change. Stretch.

### 483 - Perpendicular
{-y, x}. 90° rotation. Normal vector.

### 484 - Reflect
v - 2 * dot(v, n) * n. Bounce off surface.
Mirror direction.

### 485 - Project
(dot(a, b) / dot(b, b)) * b. Shadow of a on b.
Component extraction.

### 486 - Reject
a - project(a, b). Perpendicular component.
Remainder.

### 487 - Lerp
a + (b - a) * t. Linear interpolation. Blend.

### 488 - Slerp
Spherical linear interpolation. Angle blending.
Rotation smooth.

### 489 - Bezier Curve
(1-t)²P0 + 2(1-t)tP1 + t²P2. Smooth path.
Curved trajectory.

### 490 - Catmull-Rom Spline
Interpolation through control points. Smooth
path. Continuous curve.

### 491 - A* Pathfinding
Heuristic search. Optimal path. Navigation.

### 492 - Breadth-First Search
Level-by-level exploration. Shortest path in
unweighted graph.

### 493 - Depth-First Search
Recursive exploration. Maze solving. Tree
traversal.

### 494 - Dijkstra's Algorithm
Shortest path with weights. Optimal routing.
Graph algorithm.

### 495 - Greedy Best-First
Heuristic-only search. Fast but suboptimal.
Approximation.

### 496 - Priority Queue
Heap structure. Efficient min/max access.
Scheduling.

### 497 - Hash Table
O(1) lookup. Key-value storage. Fast access.

### 498 - Linked List
O(1) insert/delete. Convoy chains. Sequential
structure.

### 499 - Circular Buffer
Ring structure. Fixed size. Ouroboros data.

### 500 - State Machine
States and transitions. Behavior modeling.
AI structure.

---

# PART VI: VISUAL AND AESTHETIC CONCEPTS
## Concepts 501-600

---

### 501 - Ouroboros Imagery
Serpent eating its tail. Infinite loop. Convoy
metaphor.

### 502 - Staircase Descent
Healer spiraling down through party. 3D visual.
Vertical movement.

### 503 - Bee Pollination
Healer visiting flowers. Quick touch, move on.
Natural metaphor.

### 504 - River Finding Sea
Bots curving toward targets. Natural flow.
Movement poetry.

### 505 - Schools of Fish
Level-appropriate bots clustering. Group behavior.
Flocking.

### 506 - Momentum and Drift
Bots blending origin and destination. Smooth
curves. Natural motion.

### 507 - The Collective Will
Zone consensus direction. Players unknowingly
guide. Emergent behavior.

### 508 - World Flow
All bots drifting toward player goal. Momentum
feeling. Zone energy.

### 509 - Silent Leadership
Gestures command without words. Body language.
Dramatic communication.

### 510 - Reverence and Kneeling
NPCs showing respect. Dramatic submission.
Hierarchical display.

### 511 - Rising and Following
NPCs answering the call. Recruitment moment.
Alliance formation.

### 512 - Waiting and Watching
NPCs kneeling beside sitting player. Patience.
Loyalty display.

### 513 - Directional Steering
Kneeling player points the way. Mobile waypoint.
Tactical direction.

### 514 - Chain Reformation
Death causes reorganization. New leader emerges.
Resilience visual.

### 515 - Traveling Salesman Path
Optimal route visualization. Efficiency. Math
made visible.

### 516 - Spiral Healing Path
Helix through formation. 3D beauty. Movement
art.

### 517 - Figure-8 Pattern
Healer weaving through party. Continuous motion.
Graceful path.

### 518 - Warsong Gulch Aesthetic
Forest strongholds. Night elf architecture.
Faction flavor.

### 519 - Arathi Basin Aesthetic
Rolling hills. Farm structures. Rustic beauty.
Resource nodes.

### 520 - Alterac Valley Aesthetic
Snowy mountains. Dwarven and orcish camps.
Winter war.

### 521 - Eye of the Storm Aesthetic
Floating platforms. Netherstorm energy. Alien
landscape.

### 522 - Strand of the Ancients Aesthetic
Beach and titans. Ancient technology. Archaeological
site.

### 523 - Isle of Conquest Aesthetic
Massive fortress. Siege warfare. Industrial
military.

### 524 - Freddi Fish Aesthetic
Underwater cartoon. Playful colors. Childlike
wonder.

### 525 - Fish Reactions
Surprised expression. Swimming away. Interactive
delight.

### 526 - Bubble Effects
Rising bubbles on click. Water physics. Visual
feedback.

### 527 - Daily Cinematic Variety
Different intro each day. Fresh experience.
Rotation surprise.

### 528 - Login Screen Interactivity
Click and response. Engagement before game.
Playful entry.

### 529 - ASCII Art Diagrams
Text-based visualization. Documentation art.
Concept illustration.

### 530 - Box Drawing Characters
┌─┐ └─┘ │. Unicode boxes. Clean diagrams.

### 531 - Arrow Indicators
→ ← ↑ ↓ ↗ ↘. Direction symbols. Flow
representation.

### 532 - Poetry in Documentation
Rhythmic descriptions. Emotional resonance.
Design philosophy.

### 533 - The Kneel-Beckon-Direct Flow
Visual sequence. Step-by-step. User journey.

### 534 - Level Clustering Visualization
Bots around similar-level players. Group
formation. Affinity visible.

### 535 - 50% Threshold Visualization
Switch point diagram. Decision boundary.
Cost function illustration.

### 536 - 75% Opposite Visualization
Level spectrum. Fallback seeking. Target
calculation.

### 537 - Axis Alignment Visualization
On-axis vs off-axis. Priority illustration.
Geometry explanation.

### 538 - Tiebreaker Comparison
Sitting vs kneeling behavior. Side-by-side.
Rule clarification.

### 539 - Dungeon Scaling Visualization
Solo max vs mixed party. Monster levels.
Scaling illustration.

### 540 - EXP Sharing Calculation
Math example. Level ratio. Proportion
demonstration.

### 541 - Formation Diagrams
Tank, healer, DPS positions. Party layout.
Tactical visualization.

### 542 - Spawn Position Diagrams
Arc ahead, plus around. Spawn patterns.
Geometry illustration.

### 543 - Orbit Diagram
Circle around sitting player. Movement path.
Behavior illustration.

### 544 - Chase Diagram
Creature approaching player. Direct pursuit.
Combat initiation.

### 545 - Zone Consensus Diagram
Player arrows averaging. Direction emergence.
Collective visualization.

### 546 - Config Menu Mockup
Text-based UI. Command structure. Interface
design.

### 547 - NPC Gossip Menu
Tree structure. Selection flow. UI
navigation.

### 548 - Roadmap Table
Phase/Milestone/Status. Progress tracking.
Project overview.

### 549 - Issue Tracking Table
ID/Title/Status. Organized work. Task
management.

### 550 - Directory Tree
Hierarchical structure. Project organization.
File navigation.

### 551 - Configuration Table
Setting/Old/New. Change tracking. Migration
documentation.

### 552 - Module List
Name and purpose. Component catalog.
Architecture overview.

### 553 - Timer Table
Event/Delay/Description. Rhythm documentation.
Pacing overview.

### 554 - Banned Creatures List
IDs and reasons. Blacklist documentation.
Curation record.

### 555 - Emote Mapping Table
Emote ID to action. Input translation.
Interface documentation.

### 556 - Edge Case List
Scenario and handling. Exception documentation.
Completeness.

### 557 - Validation Commands
Bash examples. Testing instructions.
Verification guide.

### 558 - Stash Commands
Git examples. Recovery instructions.
Rescue guide.

### 559 - Install Steps
Sequential commands. Setup instructions.
Deployment guide.

### 560 - Update Steps
Sequential commands. Maintenance instructions.
Upgrade guide.

### 561 - Files to Create
Target paths. Implementation scope.
Deliverables list.

### 562 - Related Issues
Cross-references. Connection mapping.
Context links.

### 563 - Related Documents
Documentation links. Reference material.
Knowledge links.

### 564 - Fun Factor Rating
Subjective assessment. Joy measurement.
Design priority.

### 565 - Vision Statement
Purpose description. Why it exists.
Philosophical foundation.

### 566 - Promise Statement
Commitment to quality. Design principle.
Guiding light.

### 567 - Non-Goals List
What we won't do. Scope boundaries.
Focus maintenance.

### 568 - Status Indicators
Open/In Progress/Completed. State badges.
Progress tracking.

### 569 - Checkbox List
- [ ] Incomplete. - [x] Complete. Task
tracking.

### 570 - Code Blocks
```lua syntax highlighting. Example code.
Implementation reference.

### 571 - Inline Code
`backtick` formatting. Function names.
Technical terms.

### 572 - Blockquotes
> Citation. Design quotes. Emphasis.

### 573 - Headers
# H1 ## H2 ### H3. Document structure.
Navigation.

### 574 - Horizontal Rules
---. Section separation. Visual break.

### 575 - Bold Text
**emphasis**. Important terms. Highlighting.

### 576 - Italic Text
*emphasis*. Subtle highlighting. Nuance.

### 577 - Links
[text](url). References. Navigation.

### 578 - Tables
| Column | alignment |. Data presentation.
Organization.

### 579 - Lists
- Bullet. 1. Numbered. Item enumeration.

### 580 - Nested Lists
  - Indented. Sub-items. Hierarchy.

### 581 - VimFold Markers
-- {{{ and -- }}}. Code folding.
Organization.

### 582 - Comment Documentation
-- Explanation. Code clarity. Maintainability.

### 583 - Function Signatures
local function name(params). Interface.
API definition.

### 584 - Return Documentation
-- Returns: description. Output specification.
Contract.

### 585 - Parameter Documentation
-- @param name description. Input specification.
Contract.

### 586 - Example Usage
-- Example: code. Usage demonstration.
Learning aid.

### 587 - Warning Comments
-- WARNING: caution. Hazard notification.
Safety.

### 588 - TODO Comments
-- TODO: task. Future work. Reminder.

### 589 - FIXME Comments
-- FIXME: problem. Known issue. Debt
tracking.

### 590 - NOTE Comments
-- NOTE: information. Context. Explanation.

### 591 - HACK Comments
-- HACK: workaround. Technical debt.
Temporary solution.

### 592 - Version Numbers
0.1.0. Semantic versioning. Release
tracking.

### 593 - Dates
2026-03-31. ISO format. Timestamps.

### 594 - Author Attribution
Co-Authored-By: Name. Credit. Collaboration.

### 595 - Generated Notice
Generated with Claude Code. Provenance.
Origin.

### 596 - License Reference
Link to license. Legal compliance.
Distribution rights.

### 597 - Repository Link
GitHub URL. Source access. Contribution.

### 598 - Feedback Link
Issue tracker. Bug reports. Communication.

### 599 - Help Command
/help. User assistance. Documentation
access.

### 600 - Emoji Guidelines
Only if requested. Restraint. Professional
tone.

---

# PART VII: SYSTEM INTEGRATION
## Concepts 601-700

---

### 601 - AzerothCore Hook System
WorldScript hooks. Event interception.
Extension mechanism.

### 602 - WorldScript Registration
RegisterWorldScript(). Hook attachment.
Initialization.

### 603 - OnBeforeConfigLoad Hook
Fires before config parsing. Early
initialization.

### 604 - OnBeforeWorldInitialized Hook
Fires before world ready. Late
initialization.

### 605 - PlayerScript Registration
RegisterPlayerEvent(). Player hooks.
Character events.

### 606 - CreatureScript Registration
RegisterCreatureEvent(). Creature hooks.
NPC events.

### 607 - OnLogin Event
Player enters world. Session start.
Initialization trigger.

### 608 - OnLogout Event
Player leaves world. Session end.
Cleanup trigger.

### 609 - OnKillCreature Event
Player defeats monster. Combat resolution.
Reward trigger.

### 610 - OnDeath Event
Unit dies. Combat outcome. State
transition.

### 611 - OnEmote Event
Player performs emote. Gesture input.
Command trigger.

### 612 - OnChat Event
Player sends message. Communication.
Command parsing.

### 613 - OnCommand Event
GM command used. Administrative action.
Control interface.

### 614 - Database Connection
OpenDatabasePool(). Database access.
Persistence layer.

### 615 - Query Execution
WorldDBQuery(). Synchronous query.
Blocking.

### 616 - Async Query
WorldDBQueryAsync(). Non-blocking query.
Callback-based.

### 617 - Query Results
GetUInt32(), GetString(). Field access.
Data extraction.

### 618 - NextRow Iteration
query:NextRow(). Result traversal.
Multi-row handling.

### 619 - MySQL Schema
Database structure. Tables and columns.
Data model.

### 620 - creature_template Table
Creature definitions. Spawn source.
Entity catalog.

### 621 - character Table
Player data. Persistent state. Save
game.

### 622 - acore_world Database
World definitions. Content data.
Game rules.

### 623 - acore_characters Database
Character data. Player state.
Progress tracking.

### 624 - acore_auth Database
Account data. Authentication.
Access control.

### 625 - acore_playerbots Database
Bot data. AI state. Companion
tracking.

### 626 - Symlink Management
ln -s target link. Path redirection.
Configuration.

### 627 - Lua Script Loading
require("module"). Module import.
Code organization.

### 628 - Global Table
_G.Ambush = {}. Shared namespace.
Module export.

### 629 - Local Scope
local variable. Encapsulation.
Isolation.

### 630 - Module Pattern
return module. API export. Interface
definition.

### 631 - Event Loop
RegisterEvent() chain. Continuous
execution. Heartbeat.

### 632 - Timer System
CreateLuaEvent(). Global timers.
Scheduled execution.

### 633 - Player Timer
player:RegisterEvent(). Per-player
timer. Instance-bound.

### 634 - Creature Timer
creature:RegisterEvent(). Per-creature
timer. Instance-bound.

### 635 - Combat System Integration
AttackStart(), AttackStop(). Combat
state management. AI behavior.

### 636 - Movement System Integration
MoveTo(), MoveRandom(), MoveHome().
Navigation. AI movement.

### 637 - Spawning System Integration
SpawnCreature(), DespawnOrUnsummon().
Entity management. World population.

### 638 - Targeting System Integration
GetAITarget(). Combat selection.
Threat management.

### 639 - Group System Integration
GetGroup(), GetMembersCount(). Party
management. Social mechanics.

### 640 - Map System Integration
GetMap(), GetHeight(). Terrain access.
Navigation support.

### 641 - Zone System Integration
GetZoneId(), GetAreaId(). Geographic
queries. Location tracking.

### 642 - Instance System Integration
GetInstanceId(). Instance tracking.
Dungeon management.

### 643 - Faction System Integration
GetFactionId(), GetReaction(). Political
relationships. Hostility.

### 644 - Spell System Integration
CastSpell(), GetSpellId(). Ability
usage. Combat actions.

### 645 - Item System Integration
AddItem(), GetItemCount(). Inventory
management. Loot handling.

### 646 - Quest System Integration
HasQuest(), CompleteQuest(). Story
progression. Content tracking.

### 647 - Achievement System Integration
CompletedAchievement(). Progress
tracking. Milestones.

### 648 - Chat System Integration
SendBroadcastMessage(). Player
communication. Notifications.

### 649 - Unit Frame Integration
Health, mana queries. UI data.
Display support.

### 650 - Aura System Integration
AddAura(), RemoveAura(). Buff/debuff
management. Status effects.

### 651 - Loot System Integration
lootid, loot tables. Reward
distribution. Item drops.

### 652 - Corpse System Integration
Despawn types, timers. Death
handling. Cleanup.

### 653 - Gossip System Integration
NPC menus, selections. UI
interaction. NPC dialogue.

### 654 - Vendor System Integration
npcflag, items. Commerce.
Trading.

### 655 - Flight System Integration
Flight paths, taxi. Transportation.
Travel convenience.

### 656 - Teleport System Integration
NearTeleport(), Teleport(). Instant
movement. Location change.

### 657 - Resurrection System Integration
Resurrect(), IsDead(). Death
recovery. Respawn.

### 658 - Rest System Integration
SetRestBonus(), IsResting(). Recovery
state. Resource regeneration.

### 659 - Stand State Integration
SetStandState(), IsStandState().
Posture management. Gesture input.

### 660 - Facing Integration
GetFacing(), SetFacing(). Orientation
management. Direction.

### 661 - Speed Integration
GetSpeed(), SetSpeed(). Velocity
management. Movement rate.

### 662 - Level Integration
GetLevel(), SetLevel(). Power
tracking. Progression.

### 663 - Health Integration
GetHealth(), GetMaxHealth(). Vitality
tracking. Damage state.

### 664 - Power Integration
GetPower(), GetMaxPower(). Resource
tracking. Ability fuel.

### 665 - Position Integration
GetX(), GetY(), GetZ(), GetO().
Spatial queries. Location.

### 666 - GUID Integration
GetGUID(). Identity queries.
Entity tracking.

### 667 - Entry Integration
GetEntry(). Template ID. Type
identification.

### 668 - Name Integration
GetName(). Display name. Identity.

### 669 - Class Integration
GetClass(). Character class.
Role determination.

### 670 - Race Integration
GetRace(). Character race.
Faction alignment.

### 671 - Gender Integration
GetGender(). Character gender.
Display.

### 672 - Creature Type Integration
GetCreatureType(). NPC category.
Spawn filtering.

### 673 - Rank Integration
GetRank(). Creature difficulty.
Challenge level.

### 674 - NPCFlag Integration
GetNPCFlags(). NPC capabilities.
Interaction types.

### 675 - UnitFlag Integration
GetUnitFlags(). Unit state flags.
Status bits.

### 676 - Combat State Integration
IsInCombat(), ClearInCombat().
Battle state. AI behavior.

### 677 - Aggro Integration
CanAggro(), SetAggroEnabled().
Hostility state. AI behavior.

### 678 - Home Position Integration
GetHomePosition(), SetHomePosition().
Reset point. Return location.

### 679 - Random Movement Integration
MoveRandom(radius). Wander behavior.
Idle movement.

### 680 - Path Movement Integration
MoveAlongPath(waypoints). Scripted
movement. Route following.

### 681 - Follow Integration
Follow(target). Pursuit behavior.
AI attachment.

### 682 - Stop Integration
MoveClear(). Movement cancellation.
State reset.

### 683 - Data Storage Integration
SetData(), GetData(). Instance
metadata. State attachment.

### 684 - Event Registration Integration
RegisterEvent(). Timer creation.
Scheduled callbacks.

### 685 - Event Cancellation Integration
Implicit through non-registration.
Timer removal. Cleanup.

### 686 - Log Integration
print(), LOG_INFO(). Debug output.
Diagnostics.

### 687 - Error Integration
error(), assert(). Exception
handling. Failure notification.

### 688 - Config Integration
sWorld:GetValue(). Setting access.
Configuration queries.

### 689 - Time Integration
GetTime(), date(). Temporal queries.
Scheduling support.

### 690 - Math Integration
math.random(), math.sin(). Numerical
computation. Algorithm support.

### 691 - String Integration
string.format(), string.find().
Text manipulation. Message
construction.

### 692 - Table Integration
table.insert(), table.remove().
Collection management. Data
structures.

### 693 - OS Integration
os.date(), os.time(). System
interaction. Environment.

### 694 - IO Integration
Restricted. Security. Sandboxing.

### 695 - Debug Integration
debug.traceback(). Error diagnosis.
Stack traces.

### 696 - Coroutine Integration
Potential async patterns. Cooperative
multitasking.

### 697 - Package Integration
require(), package.path. Module
loading. Code organization.

### 698 - Metatable Integration
setmetatable(), __index. Object-
oriented patterns. Polymorphism.

### 699 - Garbage Collection Integration
collectgarbage(). Memory management.
Resource cleanup.

### 700 - FFI Integration
LuaJIT FFI for C interop. Performance.
Native code access.

---

# PART VIII: DEVELOPMENT WORKFLOW
## Concepts 701-800

---

### 701 - Git Version Control
Track changes. History preservation.
Collaboration.

### 702 - Branch Strategy
master, feature branches. Isolation.
Parallel development.

### 703 - Commit Message Format
feat(id): description. Semantic.
Searchable.

### 704 - Co-Author Attribution
Co-Authored-By: header. Credit.
Collaboration tracking.

### 705 - Generated Notice
Claude Code attribution. Provenance.
Origin tracking.

### 706 - Stash for WIP
git stash. Temporary storage.
Context switching.

### 707 - Stash Recovery
git checkout stash@{0} -- file.
Selective restoration. Incremental
approach.

### 708 - Git Status Awareness
Track modified files. Change
awareness. State tracking.

### 709 - Git Log History
Commit messages. Development
narrative. Audit trail.

### 710 - Git Diff Inspection
Change review. Code comparison.
Verification.

### 711 - Git Add Selective
Stage specific files. Change
isolation. Clean commits.

### 712 - Git Restore
Revert changes. Mistake recovery.
State reset.

### 713 - Issue-First Development
Create issue before implementing.
Planning. Documentation.

### 714 - Issue File Structure
Current/Intended/Steps. Standard
format. Consistency.

### 715 - Issue Numbering
Phase + ID. Organizational system.
Navigation.

### 716 - Sub-Issue Pattern
a, b, c suffixes. Breakdown.
Incremental progress.

### 717 - Phase Progress Tracking
phase-X-progress.md. Overview.
Status summary.

### 718 - Issue Completion Workflow
Update issue. Move to completed.
Commit. Sequence.

### 719 - Demo Creation
Phase completion artifact. Validation.
Showcase.

### 720 - Test Before Commit
Verify functionality. Validation.
Quality assurance.

### 721 - Documentation Updates
Keep docs current. Maintenance.
Knowledge preservation.

### 722 - Balance Updates File
Append-only changes. Tuning history.
Iteration tracking.

### 723 - Deprecated File Handling
-done suffix. One commit. Then remove.
History preservation.

### 724 - Build Script: azerothcore
install, update, run commands.
Automation. Convenience.

### 725 - Build Script: mysql-start
Database startup. Dependency.
Prerequisite.

### 726 - Build Script: client
Game client launch. Testing.
Playability.

### 727 - Build Script: install-client-addons
Addon deployment. UI customization.
Client setup.

### 728 - CMake Configuration
Build system. Compiler options.
Platform support.

### 729 - Make Parallel Build
-j flag. Thread count. Speed.

### 730 - Clang++ Compilation
C++ compiler. Code generation.
Binary creation.

### 731 - RelWithDebInfo Mode
Optimization with symbols. Best
of both. Default.

### 732 - Installation Target
make install. Binary deployment.
Output generation.

### 733 - Symlink Setup
Link lua_scripts. Configuration.
Path management.

### 734 - Database Schema Update
SQL migrations. Structure evolution.
Version tracking.

### 735 - Data File Copying
3.1GB game data. Local isolation.
Independence.

### 736 - Configuration Migration
Path updates. Environment adaptation.
Setup.

### 737 - Credential Management
Secrets pattern. Not in git.
Security.

### 738 - Thread Count Auto-Detection
nproc command. Optimal parallelism.
Resource utilization.

### 739 - Server Startup Sequence
MySQL, auth, world. Order matters.
Dependency chain.

### 740 - Server Shutdown Sequence
Graceful termination. State saving.
Clean exit.

### 741 - Log Analysis
Error diagnosis. Problem identification.
Debugging.

### 742 - Error Log Review
4.7MB Errors.log. Historical problems.
Context.

### 743 - Console Output Monitoring
Real-time status. Live debugging.
Observation.

### 744 - Client Connection Testing
Port verification. Network testing.
Connectivity.

### 745 - Module Loading Verification
Console messages. Initialization
confirmation. Status.

### 746 - Lua Script Loading Verification
require() success. Error messages.
Script status.

### 747 - Hot-Reload Testing
.reload config. Live changes.
Dynamic modification.

### 748 - Database Query Testing
SQL console. Query verification.
Data validation.

### 749 - In-Game Testing
Play test. Functional validation.
User experience.

### 750 - Bot Spawn Testing
Playerbot verification. AI
functionality. Feature test.

### 751 - Ambush System Testing
Monster spawning. Combat. Core
feature test.

### 752 - Treasure System Testing
Chest spawning. Loot. Reward
feature test.

### 753 - Travel System Testing
NPC wandering. Population.
Ambient feature test.

### 754 - Gesture System Testing
Emote response. NPC behavior.
Command feature test.

### 755 - Convoy System Testing
Follow chains. Formation.
Group feature test.

### 756 - Healer System Testing
Spiral movement. Healing.
Bot behavior test.

### 757 - Level Affinity Testing
Bot clustering. Level matching.
Social feature test.

### 758 - Consensus Testing
Zone direction. Bot drift.
Emergent feature test.

### 759 - Portal Testing
BG map access. Dimension
exploration. Content test.

### 760 - Login Screen Testing
Cinematic rotation. Visuals.
Client feature test.

### 761 - Config Dashboard Testing
Chat commands. UI. Management
feature test.

### 762 - Phase Demo Creation
Comprehensive test. All features.
Validation artifact.

### 763 - Regression Testing
Previous features work. Stability.
Quality maintenance.

### 764 - Performance Testing
Resource usage. Speed. Efficiency
validation.

### 765 - Memory Testing
Leak detection. Resource management.
Stability.

### 766 - Stress Testing
Load testing. Scalability.
Capacity validation.

### 767 - Error Handling Testing
Failure scenarios. Recovery.
Robustness validation.

### 768 - Edge Case Testing
Boundary conditions. Special cases.
Completeness.

### 769 - Integration Testing
Component interaction. System
cohesion. Holistic validation.

### 770 - User Acceptance Testing
Real usage. Feedback. Final
validation.

### 771 - Documentation Review
Accuracy check. Completeness.
Knowledge quality.

### 772 - Code Review
Quality check. Best practices.
Maintainability.

### 773 - Security Review
Vulnerability check. Safety.
Protection.

### 774 - Performance Review
Optimization opportunities.
Efficiency. Improvement.

### 775 - Architecture Review
Design check. Structure.
Maintainability.

### 776 - Dependency Review
External requirements. Updates.
Currency.

### 777 - License Review
Legal compliance. Distribution
rights. Safety.

### 778 - Backup Verification
Recovery testing. Data safety.
Insurance.

### 779 - Restore Testing
Recovery procedure. Disaster
recovery. Resilience.

### 780 - Rollback Testing
Revert procedure. Mistake
recovery. Safety net.

### 781 - Upgrade Testing
Version migration. Compatibility.
Continuity.

### 782 - Downgrade Testing
Version revert. Fallback.
Recovery.

### 783 - Cross-Platform Testing
Different environments. Portability.
Compatibility.

### 784 - Multi-User Testing
Concurrent access. Scaling.
Load handling.

### 785 - Network Testing
Connectivity. Latency. Performance.

### 786 - Timeout Testing
Long operations. Cancellation.
User experience.

### 787 - Interruption Testing
Mid-operation stop. State
consistency. Recovery.

### 788 - Resource Exhaustion Testing
Memory limits. Disk space.
Graceful degradation.

### 789 - Concurrent Access Testing
Race conditions. Synchronization.
Correctness.

### 790 - State Persistence Testing
Save/Load cycles. Data integrity.
Durability.

### 791 - Session Management Testing
Login/Logout cycles. State
handling. Lifecycle.

### 792 - Event Timing Testing
Delay accuracy. Scheduling.
Precision.

### 793 - Callback Testing
Async completion. Correctness.
Reliability.

### 794 - Error Message Testing
Clarity. Helpfulness. User
guidance.

### 795 - Log Quality Testing
Information density. Usefulness.
Debug support.

### 796 - Configuration Validation Testing
Invalid input handling. Robustness.
Safety.

### 797 - Default Value Testing
Missing config handling. Sensible
defaults. Usability.

### 798 - Migration Testing
Data conversion. Compatibility.
Continuity.

### 799 - Cleanup Testing
Resource release. Termination.
Hygiene.

### 800 - Initialization Testing
Startup sequence. Dependencies.
Correctness.

---

# PART IX: PHILOSOPHY AND DESIGN
## Concepts 801-900

---

### 801 - Software Design Over Product
Interest in craft, not commercial.
Art over commerce. Exploration.

### 802 - Play With Friends
Social experience. Connection.
Human warmth.

### 803 - The Chat in WoW-Chat
Socializing is the system. Not
a feature. Core purpose.

### 804 - Scriptable Everything
Soft-code over hard-code. Flexibility.
Iteration.

### 805 - Track the World
History preserved. Changes traced.
Accountability.

### 806 - Isolation Principle
Self-contained. No pollution.
Clean boundaries.

### 807 - Data Separation
Generation vs viewing. Concerns
isolated. Modularity.

### 808 - Error Over Fallback
Fail loudly. Know problems.
Transparency.

### 809 - Issue Before Implementation
Plan first. Document intent.
Intentionality.

### 810 - Immutable Issues
History preserved. Consent tracked.
Accountability.

### 811 - Phase Demos
Validation artifacts. Progress
visible. Milestone markers.

### 812 - Visual Over Description
Show, don't tell. Real output.
Concrete.

### 813 - Comment Why Not How
Reasoning preserved. Intent clear.
Maintainability.

### 814 - Test Every Fix
Prevent regression. Validate
behavior. Quality.

### 815 - Append-Only History
Balance updates file. No deletion.
Traceability.

### 816 - One Issue Per Change
Atomic changes. Clear history.
Organization.

### 817 - Git as Memory
Commit history. Development
narrative. Recall.

### 818 - Poetry in Code
Emotional resonance. Beauty in
engineering. Art.

### 819 - The Ouroboros Metaphor
Infinite recursion. Tail to head.
Continuity.

### 820 - The Traveling Salesman
Optimization. Efficiency. Elegant
solutions.

### 821 - The Collective Will
Emergent behavior. Unspoken
coordination. Magic.

### 822 - Silent Leadership
Body language. Gesture command.
Drama.

### 823 - Reverence and Service
NPCs respect players. Hierarchy.
World-building.

### 824 - Level Affinity
Like attracts like. Natural
clustering. Social physics.

### 825 - The 75% Rule
When lost, seek different.
Exploration. Growth.

### 826 - Learning by Watching
Low levels observe. Passive
growth. Mentorship.

### 827 - Max Level Exclusivity
End-game community. Earned
status. Progression.

### 828 - Fresh Login Uncertainty
New players = undefined purpose.
Potential. Possibility.

### 829 - The Spiral Path
Not direct. Beautiful curves.
Aesthetic motion.

### 830 - Speed of Sound
Fast healing. Efficiency. Time
respect.

### 831 - Bee Pollination
Quick touch. Move on. Natural
metaphor.

### 832 - River to Sea
Natural flow. Inevitable
destination. Graceful path.

### 833 - Freddi Fish Playfulness
Childlike wonder. Joy in
login. Tone setting.

### 834 - Daily Surprise
Rotating content. Fresh
experience. Anticipation.

### 835 - Interactive Entry
Click fish. Engagement before
play. Invitation.

### 836 - Battleground Exploration
Combat zones as adventure.
Repurposing. Value extraction.

### 837 - Dimension Portals
Alternative realities. Expanded
content. Wonder.

### 838 - Treasure in Dimensions
Unique rewards. Reason to
explore. Motivation.

### 839 - Solo Max Level Challenge
End-game solo content. Self-
reliance. Mastery.

### 840 - Mixed Party Learning
Mentorship mechanic. Shared
experience. Community.

### 841 - Proportional Rewards
Fair distribution. Level-
appropriate gains. Balance.

### 842 - The Promise
"Raise more than one. Pick
the purest." Quality over
quantity.

### 843 - Non-Goal: Public Hosting
Private experience. Personal
server. Intimacy.

### 844 - Non-Goal: Client Mods
Server-side only. Clean client.
Simplicity.

### 845 - Non-Goal: Retail Replication
Not a copy. Original vision.
Innovation.

### 846 - Lua as Soul
The scripts ARE the game.
Custom logic. Identity.

### 847 - wow-chat-1 Ancestry
The original. Reference
implementation. History.

### 848 - Resurrection Project
wow-chat-2 brings back the
old. Continuity. Memory.

### 849 - One Year of History
Ancient history. Development
archaeology. Heritage.

### 850 - Version Milestones
0.1.0 to 1.0.0. Progress
markers. Achievement.

### 851 - Phase Structure
Organized development. Clear
goals. Incremental.

### 852 - Issue Numbering System
Phase + ID. Organization.
Navigation.

### 853 - Vimfold Convention
Collapsible code. Organization.
Navigation.

### 854 - DIR Variable Pattern
Hard-coded at top. Argument
override. Portability.

### 855 - Script Documentation
CEO-level description. General
purpose. Accessibility.

### 856 - Absolute Paths
No cd commands. Explicit
targeting. Clarity.

### 857 - Parallel Tool Calls
Efficiency. Speed. Resource
utilization.

### 858 - Sequential Dependencies
When order matters. Correctness.
Safety.

### 859 - Read Before Edit
Understand first. Respect
existing code. Safety.

### 860 - Avoid Over-Engineering
Solve the problem. No extras.
Simplicity.

### 861 - No Unnecessary Comments
Self-evident code. Clean.
Minimal.

### 862 - No Unused Code
Delete dead code. Clean.
Maintenance.

### 863 - No Backward Compatibility Hacks
Just change it. Clean. Direct.

### 864 - Minimum Complexity
Just enough. No more. Elegance.

### 865 - Future Readers
Consider maintenance. Clarity.
Communication.

### 866 - Technical Accuracy
Truth over validation. Honesty.
Integrity.

### 867 - Professional Objectivity
Facts first. No flattery.
Substance.

### 868 - Respectful Disagreement
When necessary. Honesty.
Growth.

### 869 - No Time Estimates
What, not when. Planning
without scheduling. Flexibility.

### 870 - Concrete Steps
Actionable items. Clear
direction. Practicality.

### 871 - Task Management
TodoWrite tool. Progress
tracking. Organization.

### 872 - Mark Completed Immediately
Real-time tracking. Accuracy.
Clarity.

### 873 - One In-Progress
Focus. Single-tasking.
Clarity.

### 874 - Complete Before New
Finish what's started.
Discipline. Quality.

### 875 - Ask Questions
When uncertain. Clarification.
Collaboration.

### 876 - Security Awareness
No vulnerabilities. Safety.
Responsibility.

### 877 - OWASP Top 10
Known risks. Prevention.
Security.

### 878 - No Secrets in Git
Credentials separate. Security.
Protection.

### 879 - Hook Feedback
Treat as user input. Respect.
Integration.

### 880 - Summarization
Unlimited context. Memory.
Continuity.

### 881 - Complete Tasks Fully
No stopping mid-task. Finish.
Reliability.

### 882 - Specialized Agents
Task tool for exploration.
Efficiency. Expertise.

### 883 - Parallel When Possible
Maximize throughput. Speed.
Efficiency.

### 884 - Sequential When Needed
Dependencies respected. Order.
Correctness.

### 885 - Read Tool for Files
Not bash cat. Proper tooling.
Best practice.

### 886 - Edit Tool for Changes
Not bash sed. Proper tooling.
Best practice.

### 887 - Write Tool for Creation
Not bash echo. Proper tooling.
Best practice.

### 888 - Bash for Commands
System operations. Git, npm.
Appropriate use.

### 889 - No Bash Communication
Direct text output. Clear.
Appropriate channels.

### 890 - Explore Agent
Codebase exploration. Thorough.
Discovery.

### 891 - Plan Agent
Architecture design. Strategy.
Planning.

### 892 - Source References
file_path:line_number. Navigation.
Precision.

### 893 - HEREDOC for Commits
Proper formatting. Clean
messages. Readability.

### 894 - PR Format
Summary + Test Plan. Clear
communication. Review support.

### 895 - GitHub Integration
gh CLI tool. Automation.
Workflow.

### 896 - Code Without Files
Trust context. Efficiency.
Focus.

### 897 - Trust Agent Results
Expertise delegation. Efficiency.
Collaboration.

### 898 - Clear Prompts
Detailed instructions. Autonomy.
Effectiveness.

### 899 - Background Tasks
Parallel execution. Efficiency.
Multitasking.

### 900 - Resume Capability
Continue previous work.
Persistence. Continuity.

---

# PART X: THE THOUSAND
## Concepts 901-1000

---

### 901 - Everland Ghostsong
Project codename. Identity.
Vision.

### 902 - WoW Chat 2
Sequel. Evolution. Continuation.

### 903 - Friends While Talking
Core experience. Social gaming.
Connection.

### 904 - Fight Monsters
Combat pillar. Challenge.
Engagement.

### 905 - Find Treasure
Reward pillar. Motivation.
Satisfaction.

### 906 - Explore Forgotten Deserts
Discovery pillar. Wonder.
Adventure.

### 907 - Do Quests
Story pillar. Purpose.
Narrative.

### 908 - Find Equipment
Progression pillar. Growth.
Empowerment.

### 909 - Solo with AI
Independence. Availability.
Flexibility.

### 910 - Difficulty Scales
Adaptive challenge. Fairness.
Balance.

### 911 - Team Up
Social scaling. Cooperation.
Community.

### 912 - Proportionally Harder
Fair challenge. Balanced
scaling. Reward.

### 913 - WotLK Base
3.3.5a client. Stable foundation.
Nostalgia.

### 914 - Playerbot Fork
AI-enabled branch. Core
dependency. Foundation.

### 915 - LuaJIT Engine
Fast scripting. Performance.
Flexibility.

### 916 - MySQL Backend
Reliable storage. Persistence.
Stability.

### 917 - Linux Platform
Development environment. Server
hosting. Reliability.

### 918 - Git Tracking
Version control. History.
Collaboration.

### 919 - Markdown Documentation
Readable format. Portable.
Standard.

### 920 - Issue-Driven Development
Planning method. Organization.
Traceability.

### 921 - Phase-Based Progress
Milestone structure. Achievement.
Motivation.

### 922 - Demo Artifacts
Validation proof. Progress
evidence. Celebration.

### 923 - The Soul Directory
src/lua/. Custom logic home.
Identity.

### 924 - Reference Implementation
libs/wow-chat-1/. Ancestry.
Guidance.

### 925 - Clean Rebuild Branch
Starting fresh. Clean state.
New beginning.

### 926 - Stashed Progress
WIP preserved. Context saved.
Recovery option.

### 927 - Incremental Restore
One feature at a time. Careful.
Validated.

### 928 - Test After Restore
Verify functionality. Quality.
Safety.

### 929 - Commit After Test
Only when passing. Quality
gate. Discipline.

### 930 - Ambush Core
Danger system. Tension.
Excitement.

### 931 - Treasure Core
Reward system. Motivation.
Satisfaction.

### 932 - Travel Core
Population system. Life.
Atmosphere.

### 933 - Periodic Events Core
Timing system. Rhythm.
Pacing.

### 934 - Movement Core
Math system. Navigation.
Position.

### 935 - Tempo Core
Pacing system. Feel.
Experience.

### 936 - Gesture Future
Command system. Control.
Expression.

### 937 - Convoy Future
Formation system. Organization.
Teamwork.

### 938 - Healer Future
AI behavior. Support.
Care.

### 939 - Affinity Future
Social physics. Clustering.
Community.

### 940 - Consensus Future
Emergent behavior. Coordination.
Magic.

### 941 - Portal Future
Content expansion. Exploration.
Adventure.

### 942 - Login Future
Visual polish. Joy.
Welcome.

### 943 - Config Future
Control interface. Tuning.
Customization.

### 944 - Analytics Future
Data export. Insight.
Improvement.

### 945 - Wave Survival Future
Escalating challenge. Intensity.
Climax.

### 946 - Bot Personality Future
Character AI. Depth.
Connection.

### 947 - Quest Automation Future
Convenience. Efficiency.
Respect.

### 948 - Chat Commands Future
Interface expansion. Control.
Power.

### 949 - Hot Reload Future
Rapid iteration. Development.
Speed.

### 950 - Visual Dashboard Future
In-game UI. Control.
Convenience.

### 951 - The Fifty-Second Timer
40s ambush, 100s treasure, 130s
travel. The heartbeat.

### 952 - Sit to Pause
Rest mechanic. Breathing room.
Respect.

### 953 - Group Scaling Tables
Solo vs party. Challenge curves.
Fairness.

### 954 - Banned Creature Curation
200+ entries. Quality control.
Balance.

### 955 - Level Matching
Appropriate challenge. Fair
fights. Engagement.

### 956 - Spawn Position Variety
Arc and plus patterns. Tactical.
Interesting.

### 957 - Height Validation
No cliff spawns. Fair placement.
Playability.

### 958 - Water Check
No underwater spawns. Fair
placement. Playability.

### 959 - Chase Logic
Persistent pursuit. Engagement.
Tension.

### 960 - Orbit Logic
Peaceful coexistence. Rest
respect. Design.

### 961 - Combat Registration
Tracking active threats.
State management. Cleanup.

### 962 - Death Handling
Proper cleanup. Resource
management. Stability.

### 963 - Map Boundary Handling
Cross-zone spawning. Edge
cases. Robustness.

### 964 - Spirit World Queue
Dead player handling. Resume
on revive. Continuity.

### 965 - Queue Distribution
Per-player, per-level. Fair
spawning. Organization.

### 966 - Async Query Pattern
Non-blocking database. Responsive.
Performance.

### 967 - Callback Chaining
Event sequences. State machines.
AI patterns.

### 968 - Timer-Based AI
RegisterEvent heartbeat. Simple.
Effective.

### 969 - Data Attachment
SetData/GetData. Instance state.
Flexibility.

### 970 - Broadcast Messages
Player notification. Awareness.
Communication.

### 971 - Movement Commands
MoveTo, MoveRandom, MoveHome.
Navigation. Control.

### 972 - Combat Commands
AttackStart, AttackStop. Engagement.
Control.

### 973 - State Commands
SetAggroEnabled, ClearInCombat.
Behavior. Control.

### 974 - Position Queries
GetLocation, GetDistance. Spatial.
Calculation.

### 975 - Map Queries
GetMap, GetHeight. Terrain.
Navigation.

### 976 - Target Queries
GetAITarget. Combat selection.
Tactics.

### 977 - Group Queries
GetGroup, GetMembersCount. Social.
Scaling.

### 978 - Health Queries
GetHealth, GetHealthPct. Vitality.
Priority.

### 979 - Level Queries
GetLevel. Power. Matching.

### 980 - GUID Queries
GetGUID. Identity. Tracking.

### 981 - Random Numbers
math.random. Variety. Chance.

### 982 - Trigonometry
sin, cos, atan2. Geometry.
Movement.

### 983 - Distance Formulas
Euclidean, Manhattan. Measurement.
Optimization.

### 984 - Vector Math
Normalize, dot, project. Direction.
Calculation.

### 985 - Interpolation
lerp. Smooth transitions.
Animation.

### 986 - Table Operations
insert, remove, sort. Collections.
Management.

### 987 - String Operations
format, find. Text. Messages.

### 988 - Global vs Local
Scope management. Encapsulation.
Safety.

### 989 - Module Pattern
Tables as namespaces. Organization.
Clarity.

### 990 - Error Handling
print, return. Failure paths.
Robustness.

### 991 - Nil Checking
if not x then. Safety. Defaults.

### 992 - Type Coercion
Lua flexibility. Awareness.
Correctness.

### 993 - Table Iteration
pairs, ipairs. Traversal.
Processing.

### 994 - Function References
Callbacks. First-class functions.
Power.

### 995 - Closure Capture
State in functions. Encapsulation.
Pattern.

### 996 - Coroutine Potential
Async patterns. Future use.
Capability.

### 997 - FFI Potential
C integration. Performance.
Extension.

### 998 - Metatable Potential
OOP patterns. Polymorphism.
Abstraction.

### 999 - The Journey Continues
Phase 1 in progress. Phase 2+
awaiting. Future.

### 1000 - Ten Hundred Complete
One thousand concepts cataloged.
The width achieved. Comprehensive.

---

# APPENDIX: CROSS-REFERENCE INDEX

## By System
- Ambush: 003, 021, 022, 055-100, 930, 951-969
- Travel: 004, 024, 932
- Treasure: 005, 023, 931
- Gesture: 101-112, 134-139, 936
- Convoy: 107-112, 937
- Healer: 140-157, 938
- Affinity: 123-133, 939
- Consensus: 114-118, 940
- Portal: 158-168, 941
- Login: 169-180, 942
- Config: 201-300, 943

## By Phase
- Phase 1: 037, 042-053
- Phase 2: 038, 054
- Phase 3: 039
- Phase 4: 040
- Phase 5: 041

## By File
- periodic_events.lua: 021, 091-114
- ambush.lua: 022, 055-100
- movement.lua: 025, 080-090
- treasure.lua: 023
- travel.lua: 024
- tempo.lua: 026

## By Issue
See **concept-issue-map.md** for detailed issue-to-concept mappings.

Quick reference:
- 101-verify-server-startup: 011, 013-015, 028-030, 033, 037, 042, 181-184, 236-241, 269-270, 601-604, 724-725, 739-746
- 102-test-playerbots-spawn: 008, 016, 043, 254-256, 272, 750
- 103-document-configuration-options: 044, 201-300, 269-274
- 104-migrate-lua-scripts-from-wowchat1: 020-027, 036, 045, 185, 627-630
- 105-setup-local-mysql-installation: 015, 031, 046, 236, 242, 619-625
- 106-ingame-config-control-board: 047-050, 257-268, 293-295
- 107-credential-manager-script: 051, 737, 878
- 108-thread-count-variable: 052, 243, 729
- 109-add-build-mode-to-azerothcore-script: 053, 244-246
- 200-incremental-feature-restore: 003-007, 021-027, 036, 054-157, 370, 706-707

---

*End of Catalog*
*Generated by Claude Code for Everland Ghostsong*
*2026-03-31*
