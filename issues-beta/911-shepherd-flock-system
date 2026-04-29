# 911 - Shepherd and Flock System

Immortal shepherds wander with flocks of critters, explain the immortality lore,
and provide the only source of high-level tradeskill materials. Immortal players
can choose to permanently become critters in the flock.

## Current Behavior

No shepherd NPCs exist. There's no way to obtain tradeskill materials above
level 20. Immortality (issue 309) has no lore explanation or endgame choices.

## Intended Behavior

### Shepherd Identity

Shepherds are immortal NPCs who achieved ascension long ago:
- Wander the world with a flock of critters (lambs, cows, etc.)
- Can't be killed (invulnerable)
- Big tall creatures: giraffes, kodo, scattered everywhere
- Visual indicator of the immortality path

### Flock Behavior

The critters move as a dynamic crowd:
- **Normal movement:** Walking speed, staying near shepherd
- Move **away** from nearby monsters at walking speed
- **Part around** players (flow around, not through)
- **Flee behavior** when player gets too close:
  - Critter bursts to **100% speed** for just a few steps
  - Player only has 80% speed (worldserver config) so can't catch them
  - Then returns to walking speed
  - Creates illusion of skittish, dynamic herd

### True Names

Shepherds have "true names" that change periodically:
- Each shepherd has a current true name (curated by server owners)
- Name changes on a timer (configurable, e.g., daily/weekly)
- Knowing the true name is key to triggering the lore interaction

### Rumor Propagation to Narrators

Shepherds seed rumors through narrator network:
- When shepherd is near a narrator AND no players nearby
- Shepherd whispers their curated story/rumor to narrator
- Narrator can then share it with players (issue 310)
- Creates a discovery chain: narrator → player → shepherd

### Player Interaction

If player says part of the shepherd's curated story in /say:
- Match threshold: ~20% of the story's keywords
- Shepherd responds: "Hey, you. Where did you hear that tale?"
- Shepherd reveals they're the only one who should know it
- "I haven't told it out loud for exactly half-way since the server was founded"

Then:
- Shepherd explains immortality mechanics (issue 309)
- How surviving trials led to becoming "solid sound"
- Shepherd vanishes in a puff of smoke
- Shepherd transforms into tradeskill gathering node
- **Each critter in flock also becomes a node**

### Tradeskill Nodes

This is the **only way** to obtain materials above level 20:
- Nodes that spawn match player's invisible exp level (issue 309)
- Invisible level 5 → level 25 nodes
- Invisible level 40 → level 60 nodes
- Enables crafting progression tied to combat progression

### Ulduar Boss Spawning

World event every 80 immortals:
- Count immortal players/bots server-wide
- Every 80th immortal triggers Ulduar boss spawn
- Boss spawns at **centroid** of all player/bots on that continent
- Exactly equidistant from everyone present
- Boss never despawns until slain
- Damage adjusted (high HP, balanced abilities)

### Critter Transformation (Permanent)

Immortal players can choose to join the flock:
1. Immortal player kneels before shepherd
2. Shepherd asks in /say: "Are you sure?"
3. Player responds - consent matching rules:
   - **Exact match:** Player says "yes" (case insensitive), punctuation stripped → transformation proceeds
     - "yes", "Yes", "YES!", "yes.", "yes?" all count as consent
     - Punctuation preserved as tone context but not part of match
   - **Inverted meaning:** These markers signal irony/sarcasm and do NOT count:
     - `¡yes` - inverted exclamation before
     - `(yes)` - parentheses surrounding (hedging, distancing)
     - These are treated as "needs_clarification"
   - **Guidance brackets:** `[yes]` in square brackets signals guidance/instruction, not consent
     - Shepherd responds: "I knew it." or "I had no clue." (random)
     - Random chance persisted per-player, recomputed each occurrence
     - Bias direction: toward least hope, evaluated from prior response history
     - If history trends toward certainty ("I knew it."), drift toward uncertainty
     - Over time, the shepherd forgets more than remembers
   - **Contains but not only:** Player says something containing "yes" but with other words
     (e.g., "yes please", "oh yes", "I say yes") → shepherd responds "I need to hear you say it."
   - **No match:** Player says anything else → shepherd disregards, waits silently
4. **Player permanently transforms into a critter**

```lua
-- Consent validation logic
-- {{{ validateConsentResponse
function validateConsentResponse(message, playerGuid)
    local trimmed   = message:gsub("^%s*(.-)%s*$", "%1")          -- trim whitespace
    local lowercase = trimmed:lower()

    -- check for guidance brackets first: [yes]
    -- signals instruction, not consent - shepherd reflects on knowing
    local guidance  = lowercase:match("^%[yes%]$")

    if guidance then
        return "guidance"
    end

    -- check for inversion markers BEFORE stripping punctuation
    -- ¡yes or (yes) signals ironic/hedged meaning - not true consent
    local inverted  = lowercase:match("^¡yes")                    -- inverted exclamation
                   or lowercase:match("^%(yes%)$")                -- parentheses surrounding

    if inverted then
        return "needs_clarification"
    end

    -- strip punctuation for core word matching
    -- but punctuation preserved in original for tone context
    local stripped  = lowercase:gsub("[%p]", "")                  -- remove all punctuation

    if stripped == "yes" then
        return "accepted"
    elseif lowercase:find("yes") then
        return "needs_clarification"                              -- has "yes" but not only "yes"
    else
        return "ignored"
    end
end -- }}}

-- Guidance response with drifting memory
-- {{{ handleGuidanceResponse
-- Per-player state: tracks ratio of "knew" vs "clueless" responses
-- Bias drifts toward least hope (uncertainty) over time
local guidanceHistory = {}  -- [playerGuid] = { knew = n, clueless = n, lastChance = 0.5 }

function handleGuidanceResponse(playerGuid)
    local history = guidanceHistory[playerGuid] or { knew = 0, clueless = 0, lastChance = 0.5 }

    -- evaluate prior history: if more certainty, drift toward uncertainty
    -- "least hope" = whichever outcome has been less common, biased toward clueless
    local total      = history.knew + history.clueless
    local hopeRatio  = (total > 0) and (history.knew / total) or 0.5
    local driftSpeed = 0.05

    -- drift toward least hope: if knew > clueless, chance of "clueless" increases
    -- over time, shepherd forgets more than remembers
    local newChance  = history.lastChance
    if hopeRatio > 0.5 then
        newChance = newChance - driftSpeed                        -- drift toward clueless
    else
        newChance = newChance - (driftSpeed * 0.5)                -- still drift, but slower
    end
    newChance = math.max(0.1, math.min(0.9, newChance))           -- clamp to [0.1, 0.9]

    -- roll and record
    local roll     = math.random()
    local response = (roll < newChance) and "I knew it." or "I had no clue."

    if response == "I knew it." then
        history.knew = history.knew + 1
    else
        history.clueless = history.clueless + 1
    end
    history.lastChance = newChance

    guidanceHistory[playerGuid] = history
    return response
end -- }}}
```

As a critter:
- No input accepted (can't move, can't cast)
- Only visual feed: watch the world through critter's eyes
- Follows shepherd as it wanders
- **Chat appears as gibberish** (character knows no languages)
  - Still see chat bubbles and messages, just scrambled text
  - Creates eerie disconnect: world talks, you can't understand
- Can't send whispers or any communication
- Unselectable by other players
- Hidden from /who
- On login: **spawn shepherd at player's logout position** if not in world
  - Player-critter always has a shepherd to follow
  - Shepherd spawns where player logged out, then wanders from there
- If shepherd already exists: teleport player to shepherd's location
- Shepherd won't despawn while a player-critter is in flock
- Only despawns when all player-critters log off

**This effect is permanent. The immortal is now a critter forever.**

## Design Considerations

### Shepherd Spawning

Options:
- Static spawns in specific zones
- Rare spawns that wander between zones
- Spawn near tradeskill-relevant areas

Recommendation: Rare wandering spawns, like travelers but rarer.

### Critter Flock Composition

- 5-10 critters per shepherd
- Mix of creature types (lambs, chickens, cats, etc.)
- Some large (kodo), some small (rabbits)
- Variety creates visual interest

### Story/Rumor Curation

**BLOCKED BY: Issue 312 (automated-lore-generation)**

Stories come from the automated generation pipeline:
- See issue 312 for generation system design
- Pipeline produces content without human curation
- Stored in content pool, pulled by shepherds
- Keywords extracted automatically for matching
- Rotated with true name changes

This issue cannot proceed until 312 defines how content is generated.

### Centroid Calculation

```lua
function calculateCentroid(mapId)
    local players = GetPlayersOnMap(mapId)
    local sumX, sumY, count = 0, 0, 0

    for _, player in ipairs(players) do
        local x, y = player:GetPosition()
        sumX = sumX + x
        sumY = sumY + y
        count = count + 1
    end

    if count == 0 then return nil end
    return sumX / count, sumY / count
end
```

### Player-Critter State

Store critter transformation in character data:
```sql
-- character_data table
-- Key: "critter_state"
-- Value: shepherdGUID or 0 if not critter
```

Hook login to check critter state and apply restrictions.

## Suggested Implementation Steps

1. **Create shepherd NPC template**
   - Invulnerable, wandering behavior
   - Large creature models (giraffe, kodo variants)
   - Configure flock size and composition

2. **Implement flock spawning**
   - Spawn critters around shepherd on shepherd spawn
   - Link critters to shepherd for coordinated movement

3. **Implement flock movement behaviors**
   - Stay near shepherd (leash distance)
   - Avoid monsters at walking speed
   - Part around players
   - Run away if player too close (100% speed burst)

4. **Add true name system**
   - Data storage for shepherd true names
   - Rotation timer
   - Curated story/rumor per shepherd

5. **Implement narrator seeding**
   - Detect shepherd near narrator with no players
   - Pass rumor to narrator system (issue 310)

6. **Add player interaction detection**
   - Hook /say chat near shepherds
   - Keyword extraction and matching (20% threshold)
   - Trigger lore dialogue

7. **Implement shepherd-to-node transformation**
   - On lore completion, despawn shepherd
   - Spawn tradeskill nodes at shepherd + critter positions
   - Node level based on player's invisible level

8. **Add Ulduar boss spawning**
   - Track immortal count server-wide
   - Every 80th: calculate centroid, spawn boss
   - Boss configuration (HP, abilities scaled)

9. **Implement critter transformation**
   - Detect kneel emote from immortal player
   - Confirmation dialogue
   - Transform player to critter state
   - Apply all restrictions (no input, hidden, etc.)

10. **Handle player-critter login**
    - Check critter state on login
    - Spawn with shepherd or at logout position
    - Apply visual/control restrictions

11. **Prevent shepherd despawn with player-critters**
    - Track player-critter count per shepherd
    - Block despawn while count > 0

12. **Test scenarios**
    - Shepherd wanders with flock
    - Flock avoids monsters, parts around players
    - Critters run when player gets close
    - Narrator receives shepherd rumor (no players nearby)
    - Player triggers lore with keyword match
    - Shepherd + flock become tradeskill nodes
    - Node level matches invisible level
    - 80th immortal triggers Ulduar boss
    - Immortal kneels → becomes critter permanently
    - Player-critter login behavior

## Configuration

```lua
-- Shepherd behavior
SHEPHERD_FLOCK_SIZE         = 8       -- critters per shepherd
SHEPHERD_FLOCK_LEASH        = 15      -- yards max from shepherd
SHEPHERD_AVOID_MONSTER_DIST = 20      -- yards to detect monsters
SHEPHERD_TRUE_NAME_ROTATION = 604800  -- seconds (1 week)
SHEPHERD_STORY_MATCH_THRESH = 0.2     -- 20% keyword match

-- Flock behavior
FLOCK_PLAYER_PART_DIST      = 5       -- yards to start parting
FLOCK_PLAYER_RUN_DIST       = 3       -- yards to trigger run
FLOCK_RUN_SPEED             = 1.0     -- 100% speed
FLOCK_RUN_DURATION          = 2000    -- ms of running

-- World events
IMMORTAL_BOSS_THRESHOLD     = 80      -- immortals per boss spawn
ULDUAR_BOSS_HP_MULTIPLIER   = 10      -- HP scaling
```

## Related Concepts

- Concept 309: Invisible level progression
- Concept 119: Narrator NPC system
- Concept 267: Tradeskill material sourcing

## Related Files

- src/lua/travel.lua - Wandering NPC patterns
- src/lua/ambush.lua - Spawn patterns

## Related Issues

- Issue 309: invisible-level-progression (immortality mechanics)
- Issue 310: wandering-narrator-system (rumor seeding)

## Stats

- **Phase:** 3
- **Priority:** Medium (endgame content, lore)
- **Complexity:** Very High (multiple systems, permanent transformation)
- **Dependencies:** Issues 309, 310
- **Blocked By:** Issue 312 (automated-lore-generation)

