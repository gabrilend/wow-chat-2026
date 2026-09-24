# 705 - Custom Class Selection NPC

## Status
- Created: 2026-04-04
- Phase: 2
- Priority: High
- **Implemented:** src/lua-beta/custom-classes.lua.disabled (moved from src/lua/ in the 2026-06-02 per-profile rename; currently disabled, so not loaded on any profile), plus src/lua-beta/custom-classes/knight.lua and SQL for race-specific NPCs

### Implementation Notes (2026-04-05)

**Race-Specific Selector NPCs:**
- Each race has its own selector NPC with race-appropriate model and thematic name
- SQL: `source-beta/data/sql/custom/db_world/custom-class-selector-npcs.sql`
- NPC entries 900001-900011 (skipping 900009 for Goblin which isn't in WotLK):
  - Human (900001): Mysterious Guide - model 4217
  - Orc (900002): Spirit Walker - model 3581
  - Dwarf (900003): Stone Seer - model 2715
  - Night Elf (900004): Moonshadow Oracle - model 5708
  - Undead (900005): Deathwhisper Sage - model 10698
  - Tauren (900006): Earthmother's Voice - model 18807 (Gossip NPC Tauren Male)
  - Gnome (900007): Probability Engine - model 18799 (Gossip NPC Gnome Male)
  - Troll (900008): Loa Speaker - model 18809 (Gossip NPC Troll Male)
  - Blood Elf (900010): Sunwell Seer - model 18097
  - Draenei (900011): Light of the Naaru - model 17083
- Gossip events registered for all race-specific entries

**Lua Infrastructure:**
- Core Lua infrastructure complete (class definitions, player storage)
- Example classes: Spellblade, Shadow Apostle, Beast Shaman, Knight
- Test commands: #customclass, #customset, #customclear, #customlist, #customspawn
- Trainer level scaling formula implemented
- Spell format: `{ id, level, sourceClass }` for dynamic trainer weighting (issue 157)
- Trainer NPC entries shifted to 900021-900031 to avoid collision with selector NPCs

**NOT implemented:**
- File loading from src/custom-class-json/
- Trainer SQL (entries 900021-900031)
- AIO talent addon

**Extended by:** Issue 503 (Dynamic Trainer Spawning; legacy number 157)

## The Owner's Description (verbatim, 2026-09-23)

Given while scheduling the basic profile (155), from memory:

> the custom class architecture if I remember correctly was just assigning
> certain class's abilities to a middle-ground class. They'd visit the other
> trainers, and they could be a warrior mage. Or a necromancer druid. Whatever
> they'd like. Some affordances are made, like converting resource cost (like
> rage and energy) to mana or vice-versa, but they are meant to be normalized.
> Rage and energy characters have more staying power over mana characters, who
> either have to invest in regeneration or accept that they are sprinters who
> run out of mana. But we can normalize their ability costs by thinking about
> how that class would use that type of ability, and match it to other
> similars in player cast tempo cadence.

### Settled 2026-09-23 (verbatim answers, then what they decide)

> yes they are curated.

> both designs are true. Selector NPC picks the class, and the abilities are
> learned from the respective class trainers. We don't have custom abilities,
> but we might have for example a character with Rejuvenation and Heroic
> Strike. They'd train Heroic Strike at the warrior trainer, and Rejuvenation
> at the druid trainer. We'll also need the custom class trainer for each city
> that trains each class that isn't present at that city / starter zone /
> wherever class trainers are known.

> yes it's a fixed list, and we choose which abilities they learn. I think
> their required level has to be fixed at the same place it is normally, so we
> just describe the abilities they want and which ranks we want them to be
> able to train, and they'll learn them at the required levels.

> Ah... Yes... We should instead update this to have 3 talent trees, one for
> each class, same as any other class. But those three talent trees might be
> different. For example Rejuvenation means resto druid's talents, and Heroic
> Strike might mean warrior's arms spec talent tree, and maybe there's another
> like survival hunter or something. They should generally reflect the class
> shape that the class turned out to be.

So:

- **Curated classes**, chosen at the selector NPC (this issue).
- **No new abilities.** A custom class is a fixed list of *existing* spells
  and the ranks it may train. Each is learned from the **source class's own
  trainer** at its **stock required level**. A Heroic-Strike-and-Rejuvenation
  class trains Heroic Strike at a warrior trainer and Rejuvenation at a druid
  trainer.
- **Trainer coverage.** Wherever class trainers stand (cities, starting
  zones, towns), a custom-class trainer covers the classes missing there.
  basic's Visiting Mentors (155e) are the first instance: they already
  cover the missing classes per valley, and a custom-class character uses
  them too. Generalizing them from valleys to every trainer location is
  tracked in 155e.
- **Talents: three trees, like every class**, but chosen per custom class
  from the source classes' specs to match its shape (Rejuvenation → the
  restoration druid tree; Heroic Strike → the arms warrior tree; perhaps a
  third such as survival hunter). This replaces the "curated tree via AIO"
  idea in the Talent Trees section below; see 713.
- **Resources:** the owner's direction is recorded in 710.

**Re-evaluated 2026-09-23 (owner: "that can't be true! It'll harm most of
our plans if true").** The check is real, but it is cheap to get past, and
all of it is on the server:

- **Gate one** (the whole trainer: "class trainers teach only their class")
  is `Trainer::IsTrainerValidForPlayer`. basic's Visiting Mentors already
  show one way around it: a dialogue line that opens a class's list (B029).
  A custom-class character can be offered the lines for its source classes
  the same way, conditioned on its custom class.
- **Gate two** (each spell: "can this class and race learn it") is
  `Player::IsSpellFitByClassAndRace`. It reads the server's copy of the
  client's skill tables (`SkillLineAbility`, `SkillRaceClassInfo`). The
  server merges database override tables over those
  (`skilllineability_dbc`, `skillraceclassinfo_dbc`; `DBCStores.cpp`
  `LOAD_DBC(..., "skilllineability_dbc")`), so allowing a class a spell is a
  data edit. It is per *class*, though: allowing warriors Rejuvenation allows
  every warrior. Per *character* (only the custom class) takes a few lines
  of source patch, or a script hook the patch adds. Either way it is small
  and server-side.
- **Casting** it is the resource question, in 710. Short version: the
  server already keeps rage and energy pools for every class, and has hooks
  for the rest.

**Training design (owner, 2026-09-23, verbatim):**

> why don't we make it so that for example, a spellblade with warrior and mage
> abilities, when talking to a warrior and a mage trainer, opens up not the
> warrior and mage class training lists, but the spellblade training lists,
> with the warrior spellblade spells on the warrior trainer, and the mage
> spellblade spells on the mage's training list? That way, we can make
> duplicates that have a different class requirement, which I think are
> available now without a client edit. Confirm? Alternatively, make it so
> that any class can learn any spell, remove the requirements completely, and
> populate specific class lists for the custom classes (and the classes that
> need trainers in the new zones!) that just have the intended spells.

What is and isn't possible without a client edit:

- **Duplicate trainer lists: yes.** A trainer list is server data only
  (`trainer`, `trainer_spell`). A "spellblade (warrior side)" list on
  warrior trainers and a "spellblade (mage side)" list on mage trainers are
  plain rows. The stock trainer gets one extra dialogue line ("Train me as a
  spellblade") that opens that list, using the same mechanism as basic's
  Visiting Mentors (B029: a trainer line names the list it opens). The line
  is shown only to spellblades through a dialogue condition. A custom class
  has to be something a condition can test; the simplest is a hidden
  quest, marked done when the class is chosen at the selector
  (condition "quest rewarded"). Quests are server data; their text is
  cached, and C025 refreshes that.
- **Duplicate spells: no.** A copy of a spell with its own class
  requirement would be a new spell id, and spells live in the client's own
  data files. Duplicates of the *lists* get the same effect without that.
- **The per-spell class check** (gate two) still stands between a
  warrior-based spellblade and Fireball. Two ways past it, both server-side:
  - **A. Skip it for curated lists** (a few lines of source patch): lists
    with no class requirement (the custom-class lists) skip the class check
    and keep the race check. Stock class lists and the Visiting Mentors'
    lists behave as today. *Recommended*: it touches only the lists we
    write.
  - **B. Remove class restrictions everywhere** (the owner's alternative),
    as data: a generated override table (`skilllineability_dbc`) with every
    spell's class mask cleared and race masks kept. It works too, since
    stock lists only ever hold their own class's spells, but it rewrites a
    world-wide table (thousands of rows) and every future list must be
    curated with care.
  Either way the same curated lists serve custom classes and the new-zone
  trainers.

What is not known yet is only client-side. Does a warrior's spellbook
display Rejuvenation (the client files spells by skill line)? It can be
answered in two minutes with the GM command `.learn 774` on a warrior.

## Overview

Create custom "classes" as curated arrangements of existing spells from multiple base classes. No DBC edits required - we work within the existing spell system but create unique combinations.

A new character meets an NPC who offers them a choice of custom class. This determines which spells they can learn from trainers and find in tomes.

## Current Behavior
- Player creates character with base class (Warrior, Mage, etc.)
- Can only learn spells from that class
- Trainers teach only their class's spells
- Tomes contain only class-specific spells

## Intended Behavior

### Character Creation Flow
1. Player creates new character (any base class for animations/armor)
2. Player spawns at **random NPC spawn point** or pathing waypoint
3. **Custom Class NPC spawns** at nearest pathable location in front of them
4. NPC offers choice of custom classes (no spell lists shown - player must guess)
5. Player selects custom class OR walks away (base class remains default)
6. NPC despawns when no players nearby
7. NPC **only talks to level 1 characters** - others are disregarded

### NPC Behavior
- Spawns at nearest pathable point (NPC spawn point or pathing waypoint)
- Persists until no players are nearby
- Only interacts with level 1 characters
- Higher level characters ignored completely
- Selection is optional - base class is the fallback

### Custom Class Definition
A custom class is:
- A **curated list of spells** drawn from multiple base classes
- A **unique trainer list** - which trainers can teach which spells
- A **tome pool assignment** - which class pool tomes are drawn from
- A **talent tree** (via AIO addon) that targets the curated spells

### Trainer Integration
- If a trainer knows a spell that's on your custom class list, they can teach it
- Doesn't matter if trainer is "Warrior Trainer" or "Mage Trainer"
- What matters: does this trainer know a spell you can learn?
- Trainers effectively become "universal" for custom class spells

### Trainer Level-Based Spell Filtering
Trainers only know spells relevant to their level, scaled to player max level 20:

```
trainerLevel = 60 (example)
maxNpcLevel  = 80 (example)
maxPlayerLvl = 20

ratio = trainerLevel / maxNpcLevel = 0.75
scaledLevel = ratio * maxPlayerLvl = 15

Trainer teaches spells in range: [scaledLevel - 2, scaledLevel + 2]
Example: level 60 trainer teaches spells for levels 13-17
```

This means:
- Low level trainers teach low level spells
- High level trainers teach high level spells
- Players must find appropriate trainers for their level
- No single trainer teaches everything

### Tome Integration
- Tomes are drawn from the **base class pool** of the spell
- If a Fireball tome exists and your custom class includes Fireball, you can find it
- When chest is opened, system checks: does any pool have a spell this player can learn?
- Pulls from relevant pool(s)

### Talent Trees (AIO Addon)
- **ALL talent trees modified** - base classes AND custom classes
- Custom talent trees via AIO client addon
- AIO allows custom UI without modifying game client files
- Player trusts AIO (established addon system) not individual developer

**Base Class Talent Changes:**
- Lower tier talents **disabled** for base classes
- These talents transferred to custom classes instead
- Base classes lose some options but remain viable
- Custom classes open doors AND close doors

**Custom Class Talents:**
- **Same number of talents** as normal classes
- Different selection: includes talents from lower tiers (tier 4+)
- Normal players only access first 3 tiers (level 20 cap)
- Custom classes can access tier 4+ talents instead of tier 1-3
- Relevant to the custom class spell list
- Some talents shared between classes (discouraged but allowed)

## Example Custom Classes

### Spellblade
- Base class: Warrior (for plate armor, weapon skills)
- Spells: Warrior combat abilities + select Mage fire/frost spells
- Trainers: Warrior trainers (combat), Mage trainers (spells)
- Theme: Melee fighter who enhances weapons with magic

### Shadow Priest Variant
- Base class: Priest (for cloth, spirit)
- Spells: Shadow priest abilities + select Warlock curses
- Trainers: Priest trainers (shadow), Warlock trainers (curses)
- Theme: Darker priest with demon-adjacent powers

### Beast Shaman
- Base class: Shaman (for mail, totems)
- Spells: Shaman nature spells + select Hunter pet/beast abilities
- Trainers: Shaman trainers, Hunter trainers (beast-related)
- Theme: Nature-connected hybrid with animal companions

## Implementation Steps

1. Define custom class data structure
   - Class ID (custom, not conflicting with base classes)
   - Display name
   - Base class (for armor/animations)
   - Spell list (spell IDs that can be learned)
   - Trainer mapping (which trainers teach which spells)

2. Create Custom Class NPC
   - Spawns on first login for new characters
   - Gossip menu with class choices
   - Stores selection on character (custom data field)
   - Despawns after selection

3. Modify trainer interaction
   - On gossip with trainer, check custom class spell list
   - Show only spells the custom class can learn
   - That this trainer knows how to teach

4. Modify tome system
   - On chest open, check all base class pools
   - Filter to spells the custom class can learn
   - Draw from filtered set

5. Create AIO addon for talent trees
   - Define custom talent trees per custom class
   - Target spells in the custom class list
   - May include higher-tier talents rearranged

6. Store custom class persistently
   - Character data field for custom class ID
   - Survives logout/login
   - Cannot be changed after selection

## Technical Notes

### Custom Class Data Structure
```lua
CustomClasses = {
    [1001] = {  -- Spellblade
        name = "Spellblade",
        baseClass = 1,  -- Warrior
        spells = {
            -- Warrior spells
            78, 100, 772,    -- Heroic Strike, Charge, Rend
            -- Mage spells
            133, 116, 122,   -- Fireball, Frostbolt, Frost Nova
        },
        trainers = {
            -- Warrior trainers teach these
            [914] = { 78, 100, 772 },
            -- Mage trainers teach these
            [5144] = { 133, 116, 122 },
        },
        tomeClasses = { 1, 8 },  -- Can find Warrior and Mage tomes
    },
    -- More custom classes...
}
```

### Custom Class NPC Spawn
```lua
function onFirstLogin(event, player)
    if player:GetLevel() > 1 then return end  -- only level 1

    -- Find nearest pathable point (NPC spawn or waypoint)
    local px, py, pz = player:GetPosition()
    local spawnPoint = findNearestPathablePoint(px, py, pz)

    local npc = SpawnCreature(CUSTOM_CLASS_NPC_ID, spawnPoint.x, spawnPoint.y, spawnPoint.z, 0)
    npc:SetData("spawn-time", os.time())

    -- NPC checks for nearby players periodically, despawns when alone
    npc:RegisterEvent(checkForNearbyPlayers, 5000, 0)
end

function checkForNearbyPlayers(eventId, delay, repeats, npc)
    local nearbyPlayers = npc:GetPlayersInRange(30)
    if #nearbyPlayers == 0 then
        npc:DespawnOrUnsummon(0)
    end
end

function onNpcGossip(event, player, npc)
    -- Only talk to level 1 characters
    if player:GetLevel() > 1 then
        return false  -- disregard
    end

    -- Show custom class selection menu
    showCustomClassMenu(player, npc)
end
```

### Trainer Gossip Filter
```lua
function onTrainerGossip(event, player, trainer)
    local customClassId = player:GetData("custom-class")
    if not customClassId then return end  -- no custom class, use base

    local customClass = CustomClasses[customClassId]
    local trainerId = trainer:GetEntry()
    local availableSpells = customClass.trainers[trainerId] or {}

    -- Filter gossip to only show available spells
    for _, spellId in ipairs(availableSpells) do
        if not player:HasSpell(spellId) then
            -- Add to gossip menu
            addSpellToGossip(player, trainer, spellId)
        end
    end
end
```

### Tome Pool Filtering
```lua
function drawTomeForPlayer(player)
    local customClassId = player:GetData("custom-class")
    if not customClassId then
        -- No custom class, use base class
        return drawFromPool(player:GetClass())
    end

    local customClass = CustomClasses[customClassId]
    local available = {}

    -- Check all relevant class pools
    for _, classId in ipairs(customClass.tomeClasses) do
        for spellId, count in pairs(TomePools[classId]) do
            if count > 0 and contains(customClass.spells, spellId) then
                table.insert(available, { classId = classId, spellId = spellId })
            end
        end
    end

    if #available == 0 then return nil end

    local selection = available[math.random(#available)]
    TomePools[selection.classId][selection.spellId] =
        TomePools[selection.classId][selection.spellId] - 1
    return selection.spellId
end
```

## Custom Class Definitions

Custom classes defined in: `src/custom-class-json/`

**This directory is an rmail inbox** - people who know the password from the website can upload custom mods. Community-contributed custom classes.

-- if there are more custom classes in the directory than that which fits in a basic WoW characters dialogue, then select from the pool randomly. Also only allow one contribution from each immutable contact password. once you got one, that's always what I'll remember you as. Like a name, introduced at a gathering or meeting. do the sort of random where once picked, you don't show up again until all the options have cycled through.

File format: Custom format (not actually JSON, but "json" is descriptive shorthand for structured data definitions).

Each file defines one custom class:
- Spell list
- Trainer mappings
- Tome pool assignments
- Talent tree modifications

Number of custom classes: As many as are uploaded. No fixed limit.

## Design Principles

- **No spell list preview** - player must guess and discover
- **Same level requirements** - no DBC edits, spells keep original requirements
- **Base class is default** - custom classes are optional
- **Doors open AND close** - choosing custom class gains some options, loses others
- **Base classes also modified** - lower tier talents disabled, transferred to custom

## Error Observations

### 2026-04-08 - SQL schema mismatch (scale column)

**Error:** `ERROR 1054 (42S22) at line 17: Unknown column 'scale' in 'field list'`

**Cause:** The `creature_template` table schema changed in newer AzerothCore. The custom SQL file used the old schema.

**Schema Changes:**
- Removed: `scale` (now in `creature_template_model.DisplayScale`)
- Removed: `trainer_type`, `trainer_spell`, `trainer_class`, `trainer_race`
- Removed: `mechanic_immune_mask`, `spell_school_immune_mask`
- Added: `speed_swim`, `speed_flight`, `detection_range`
- Added: `CreatureImmunitiesId` (replaces immune masks)

**Resolution:** Updated `source-beta/data/sql/custom/db_world/custom-class-selector-npcs.sql` to match current schema.

### 2026-04-07 - Creature templates 900001-900011 not in database

**Error:** `lua_scripts/custom/custom-classes.lua:629: Couldn't find a creature with (ID: 900001)!`

**Cause:** Lines 628-631 register gossip events for creature entries 900001-900011 (race-specific selector NPCs), but these creatures don't exist in the `creature_template` table.

**Impact:** Custom class selection NPCs cannot spawn. The `RegisterCreatureGossipEvent` calls fail silently for all 10 race-specific entries.

**SQL File:** `sql/custom/db_world/custom-class-selector-npcs.sql` exists but hasn't been applied to the database.

**Resolution:** Apply the SQL file:
```bash
mysql -u ritz -pmenardi acore_world_beta < sql/custom/db_world/custom-class-selector-npcs.sql
```

Or add to build patch system like E005 for automatic application.

**Note:** Only entry 900001 is logged because the error occurs on the first iteration of the loop - subsequent entries would fail the same way.

### 2026-04-08 - Invalid CreatureDisplayID for Tauren/Gnome/Troll

**Error:**
```
Creature (Entry: 900006) lists non-existing CreatureDisplayID id (8022), this can crash the client.
Creature (Entry: 900007) lists non-existing CreatureDisplayID id (7574), this can crash the client.
Creature (Entry: 900008) lists non-existing CreatureDisplayID id (8071), this can crash the client.
```

**Cause:** Display IDs 8022, 7574, 8071 exist in `creature_template_model` but NOT in `creature_model_info`. The worldserver validates that all creature display IDs have corresponding entries in `creature_model_info`.

**Resolution:** Updated display IDs to use valid Gossip NPC models:
- Tauren (900006): 8022 → 18807 (Gossip NPC Tauren Male)
- Gnome (900007): 7574 → 18799 (Gossip NPC Gnome Male)
- Troll (900008): 8071 → 18809 (Gossip NPC Troll Male)

**Validation query used:**
```sql
SELECT DisplayID FROM creature_model_info WHERE DisplayID IN (8022, 7574, 8071);
-- Returns empty set (IDs not valid)

SELECT DisplayID FROM creature_model_info WHERE DisplayID IN (18807, 18799, 18809);
-- Returns all three (IDs valid)
```

## Related Issues
- 405 - Ability tome system (tome integration; legacy 151)
- 701 - Quest spells to trainers (trainer system; legacy 140)
- 503 - Dynamic trainer spawning (extends this issue with weighted trainer selection; legacy 157)
- Future: AIO talent addon issue
- 155 - Basic profile: the level 1–60 baseline custom classes are developed
  against first (2026-09-23)
- 718 - Death knight sacrifice and open Acherus: scheduled after this
  infrastructure

## Open Questions

- (Answered 2026-09-23) Curated classes, chosen at the NPC; abilities learned
  at the source classes' trainers. See "Settled 2026-09-23" above.
