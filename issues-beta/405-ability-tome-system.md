# 405 - Ability Tome System

**Phase:** 4 (Economy - Currency & Rewards)
**Effect:** Players create ability tomes via Inscription, tomes appear in chests
**Status:** Partial (Lua infrastructure complete, SQL/recipes needed)

---

## The Effect

Inscription profession creates **Ability Tomes** - summoned items that teach spells. Tomes are rank-agnostic: a "Tome of Rejuvenation" teaches whichever rank of Rejuvenation you're eligible to learn next. Tomes cannot be traded between players, but can be sold to vendors - entering a class-specific tome pool. Chests randomly contain tomes drawn from the pool based on the holder's class.

```
Inscriptionist knows Rejuvenation
        ↓
Creates "Tome of Rejuvenation" (any rank)
        ↓
Sells to vendor → enters Druid tome pool
        ↓
Druid player opens chest
        ↓
Tome appears in chest (drawn from pool)
        ↓
Player uses tome → learns NEXT rank they're eligible for
```

---

## What This Solved

### Before (Fixed Rank Tomes)

**Standard WoW tome behavior:**
- Tome of Rejuvenation Rank 1 (specific rank)
- Tome of Rejuvenation Rank 2 (different item)
- Tome of Rejuvenation Rank 3 (yet another item)

**Problems:**
- Inscriptionist must track which rank they're creating
- Tome must specify exact rank
- Player might already know that rank (wasted tome)
- Different players need different ranks
- Pool fragmentation (R1 pool, R2 pool, R3 pool all separate)

**Example:**
- Inscriptionist creates "Tome of Rejuvenation Rank 2"
- Sells to vendor → enters "Rejuvenation R2" pool
- Level 6 Druid opens chest → gets R2 tome
- Too high level required! Can't use it
- OR: Already knows R2! Wasted

Rank-specific tomes create friction: wrong rank, wrong level, already known.

### After (Spell-Family Agnostic Tomes)

**NEXT rank system:**
- "Tome of Rejuvenation" (no rank specified)
- When used, system finds NEXT learnable rank
- Checks custom class definition for level requirements
- Teaches rank if eligible, rejects if not

**Result:**
- One tome per spell family (not one per rank)
- Tome always useful (teaches next rank you need)
- Pool consolidation (one "Rejuvenation" pool, not R1/R2/R3)
- Level validation from custom class table

**Example:**
- Inscriptionist creates "Tome of Rejuvenation" (rank-agnostic)
- Sells to vendor → enters "Rejuvenation" pool (family-based)
- Level 6 Druid opens chest → gets tome
- Uses tome → system checks: knows R1? Yes. Eligible for R2? Level 6 < level 8 required
- Message: "You must be level 8 to learn this spell"
- Saves tome for later!

Same tome works for any rank. No waste, no fragmentation.

---

## Why This Matters

**Decoupling from Blizzard's Ranks**

WoW's rank system (R1, R2, R3...) was designed for level 1-80 progression. We're compressing to level 1-20. Blizzard's rank requirements don't match our level curve.

By making tomes rank-agnostic and validating against custom class definitions:
- We control when each rank unlocks (not Blizzard)
- Same tome works across all ranks (simplicity)
- Future linear scaling (Issue 347) seamless

**Pool Consolidation**

Rank-specific pools fragment:
- Rejuvenation R1 pool: 5 tomes
- Rejuvenation R2 pool: 2 tomes
- Rejuvenation R3 pool: 1 tome
- Total: 8 tomes across 3 pools

Spell-family pools consolidate:
- Rejuvenation pool: 8 tomes (all ranks)
- Any rank-eligible player can use any tome

More efficient distribution, less waste.

**Forward Compatibility with Linear Scaling**

Issue 347 (linear-ability-scaling) creates ~80 versions of each spell (one per level). Example:
- Rejuvenation level 1
- Rejuvenation level 2
- ...
- Rejuvenation level 80

With rank-specific tomes, this would require 80 different tome items. Unmaintainable.

With NEXT rank system, still ONE tome per spell family. System finds next level-appropriate version. Scales seamlessly.

**Profession Integration**

Inscription replaces glyphs (removed from game) with tomes. Class-specific implements theme professions:
- Paladin uses Tomes
- Mage uses Scrolls
- Shaman uses Runestones
- Druid uses Bark Tablets

Flavor matters. Each class has aesthetic implement.

---

## Design

### Core Mechanic

**Creation:**
- Inscription profession creates tomes
- Requires: class-specific implement + magic dusts + gems
- Can only create tomes for spells player knows
- 24-48 hour cooldown per tome

**Properties:**
- Summoned item (temporary, expires if not used)
- Duration: 24 or 48 hours
- Cannot be traded between players
- Can be sold to vendors (enters pool)
- Class-restricted to crafter's class

**Distribution:**
- Sold tomes enter class-specific tome pool
- Chests randomly contain tomes drawn from holder's class pool
- Tome selected when chest OPENED, not spawned
- Searchers find tomes for holder, not themselves

### Class-Specific Implements

| Class | Implement |
|-------|-----------|
| Paladin | Tome |
| Mage | Scroll |
| Shaman | Runestone |
| Priest | Prayer Book |
| Warlock | Grimoire |
| Druid | Bark Tablet |
| Hunter | Beast Manual |
| Rogue | Shadow Note |
| Warrior | Battle Scroll |
| Death Knight | Runic Slab |

Materials needed:
- Class implement (crafted or purchased)
- Magic dusts (from Enchanting disenchants)
- Gems (from Mining/JC)

### NEXT Rank Selection Logic

```lua
function useAbilityTome(player, spellFamily)
    local classDef = CustomClasses.getPlayerClass(player)
    local playerLevel = player:GetLevel()

    -- Find all ranks of this spell in class definition
    local ranks = {}
    for spellId, data in pairs(classDef.abilities) do
        if SpellFamilies[spellId] == spellFamily then
            table.insert(ranks, { id = spellId, level = data.level })
        end
    end

    -- Sort by level requirement
    table.sort(ranks, function(a, b) return a.level < b.level end)

    -- Find NEXT rank player doesn't know AND can learn
    for _, rank in ipairs(ranks) do
        if not player:HasSpell(rank.id) then
            if playerLevel >= rank.level then
                player:LearnSpell(rank.id)
                return true
            else
                player:SendBroadcastMessage(
                    "You must be level " .. rank.level .. " to learn this spell.")
                return false
            end
        end
    end

    player:SendBroadcastMessage("You already know all ranks of this spell.")
    return false
end
```

**Key points:**
- Checks custom class definition (not spell database)
- Finds NEXT unlearned rank
- Validates level requirement from class table
- Teaches if eligible, rejects if not

### Spell Family Mapping

Pools keyed by spell family, not individual spell IDs:

```lua
SpellFamilies = {
    [139]  = "renew",         -- Renew R1
    [6074] = "renew",         -- Renew R2
    [6075] = "renew",         -- Renew R3
    [774]  = "rejuvenation",  -- Rejuvenation R1
    [1058] = "rejuvenation",  -- Rejuvenation R2
    -- etc
}

TomePools = {
    [1] = { ["heroic_strike"] = 2, ["rend"] = 1, ... },  -- Warrior
    [2] = { ["holy_light"] = 3, ["blessing_of_might"] = 1, ... },  -- Paladin
    [5] = { ["renew"] = 2, ["power_word_shield"] = 1, ... },  -- Priest
    -- etc (10 classes, 11 with DK)
}
```

Function to add/draw:
```lua
function addToPool(classId, spellId)
    local family = SpellFamilies[spellId] or tostring(spellId)
    TomePools[classId][family] = (TomePools[classId][family] or 0) + 1
end

function drawFromPool(classId, playerClassDef)
    -- Only draw spells that exist in player's class definition
    local available = {}
    for family, count in pairs(TomePools[classId]) do
        if count > 0 and playerHasSpellFamily(playerClassDef, family) then
            table.insert(available, family)
        end
    end
    if #available == 0 then return nil end

    local family = available[math.random(#available)]
    TomePools[classId][family] = TomePools[classId][family] - 1
    return family
end
```

### Chest Integration

Tome selected when chest opened (holder determines class):

```lua
RegisterGameObjectEvent(0, GAMEOBJECT_EVENT_ON_USE, function(event, go, player)
    -- player is the HOLDER (keeping chest open)
    local classId = player:GetClass()
    local classDef = CustomClasses.getPlayerClass(player)

    -- Random chance to contain tome
    if math.random() < 0.3 then  -- 30% chance
        local family = drawFromPool(classId, classDef)
        if family then
            local tomeItemId = getTomeItemForSpellFamily(family)
            go:AddLoot(tomeItemId, 1)
        end
    end
end)
```

Requires Issue 307 (ale-gameobject-wildcard) for entry 0 registration.

---

## Implementation

### Current Status (2026-04-04)

**Implemented:**
- Core Lua infrastructure (`src/lua/ability-tomes.lua`)
- Spell family mapping
- Pool management (add/draw)
- NEXT rank selection logic
- Test commands: `#tomeadd`, `#tomepool`, `#tomereg`

**Not Implemented:**
- SQL: Tome item templates (one per spell family)
- SQL: Inscription recipes with class implements
- SQL: Remove glyphs from game
- DB: Pool persistence (currently in-memory only)
- C++: Requires Issue 403 (ale-sell-item-hook) for vendor sales
- C++: Requires Issue 307 (ale-gameobject-wildcard) for chest events

### SQL Requirements

**1. Remove Glyphs**
```sql
-- Drop all glyph items from game
DELETE FROM item_template WHERE class = 16;  -- Glyph item class

-- Remove glyph-related inscription recipes
DELETE FROM npc_trainer WHERE SpellID IN (SELECT id FROM spell_template WHERE ...);

-- Clear glyph slots from characters
UPDATE characters SET glyph1 = 0, glyph2 = 0, ...;
```

**2. Create Tome Item Templates**
One template per spell family (not per rank):
```sql
INSERT INTO item_template (entry, name, class, subclass, quality, duration, ...)
VALUES
    (900001, 'Tome of Rejuvenation', 0, 0, 2, 86400, ...),  -- 24hr duration
    (900002, 'Tome of Renew', 0, 0, 2, 86400, ...),
    (900003, 'Tome of Holy Light', 0, 0, 2, 86400, ...),
    -- etc for each spell family
```

Properties:
- Summoned item (disappears on expiry)
- Cannot trade (bind on pickup)
- Class restriction
- Duration 24/48 hours

**3. Create Inscription Recipes**
Per-class recipe lists:
```sql
-- Paladin inscription recipes
INSERT INTO npc_trainer (ID, SpellID, MoneyCost, ReqSkillLine, ReqSkillRank, ReqLevel)
VALUES
    (200101, 920001, 100, 773, 1, 1),  -- Inscription: Tome of Holy Light
    (200101, 920002, 150, 773, 50, 10),  -- Inscription: Tome of Blessing of Might
    -- etc
```

Requirements:
- Class-specific implement in inventory
- Magic dusts (from enchanting)
- Gems
- Player knows the spell

### Lua Implementation

**File:** `src/lua/ability-tomes.lua`

**Functions:**
```lua
AbilityTomes = {
    pools = {},      -- [classId][spellFamily] = count
    families = {},   -- [spellId] = spellFamily

    addToPool = function(classId, spellId),
    drawFromPool = function(classId, classDef),
    onChestOpen = function(event, go, player),
    onTomeUse = function(event, player, item),
    onVendorSell = function(event, player, item, vendor, count)
}
```

**Test Commands:**
```lua
-- #tomeadd <classId> <spellId> - Add tome to class pool
-- #tomepool <classId> - Show pool contents for class
-- #tomereg - Show registered spell families
```

### Dependencies

**Issue 307 - ale-gameobject-wildcard (REQUIRED)**

Enables `RegisterGameObjectEvent(0, ...)` for all chests. Without this, must register each chest entry individually (impractical).

**Status:** Completed (2026-04-08)

**Issue 403 - ale-sell-item-hook (REQUIRED)**

Provides `PLAYER_EVENT_ON_SELL_ITEM` for detecting tome sales to vendors.

**Status:** Completed (2026-04-05)

**Issue 402 - treasure-chest-shared-loot (OPTIONAL)**

Provides treasure pool infrastructure. Tomes use separate pools but similar distribution logic.

**Status:** Partial

---

## Design Philosophy

### Rank-Agnostic Tomes

"A tome teaches the spell, not a specific rank."

This decouples tome creation from rank management. Inscriptionist doesn't think "I'll make R2 tome" - they think "I'll make Rejuvenation tome." System handles rank selection.

### Custom Class Definition Authority

Level requirements come from custom class tables, not spell database:
```lua
knight.abilities[139] = { level = 8, ... }  -- Renew R1 at level 8
```

This gives us control over progression independent of Blizzard's original design.

### Spell Family Abstraction

"Rejuvenation" is a spell family containing R1, R2, R3, etc. Pools store families, not ranks. This:
- Simplifies pool management
- Enables consolidation
- Future-proofs for linear scaling

### Cannot Trade, Can Sell

Tomes cannot be traded between players (bind on pickup), but CAN be sold to vendors. This:
- Prevents tome hoarding/trading economy
- Forces tomes into pool (vendor sales)
- Creates distribution via chests (not player trades)

Tomes flow through NPCs, not players.

---

## Lessons Learned

### Spell Family Mapping is Manual

No automated way to group spell ranks into families. Must manually map:
```lua
SpellFamilies = {
    [139] = "renew",
    [6074] = "renew",
    -- hundreds of entries
}
```

Tedious, but necessary for rank-agnostic system.

### Wildcard Registration Required

Initially tried registering specific chest entries. Problem: hundreds of chest templates exist. Unmaintainable.

Solution: Issue 307 (wildcard registration) enables `entry = 0` for all gameobjects. Much cleaner.

### Glyphs Must Go

Inscription creates glyphs in base WoW. For tomes to work, glyphs must be removed:
- Drop all glyph items
- Remove glyph recipes
- Clear glyph slots

Otherwise inscription has two outputs (glyphs + tomes). Confusing.

### Duration Balances Cooldown

Tome creation cooldown: 24 hours
Tome duration: 24 hours

If you create tome but don't sell immediately, it expires before next tome available. Creates urgency - use it or sell it.

### Class Implements Add Flavor

Generic "Inscription creates tomes" is bland. Class-specific implements add flavor:
- Paladins use Tomes (holy books)
- Mages use Scrolls (arcane)
- Shamans use Runestones (elemental)

Small detail, big aesthetic impact.

---

## Phase 4 Contribution

This issue expands **Phase 4: Economy - Currency & Rewards** by adding profession-based item creation:

> **Inscription profession** - Creates ability tomes
> **Class-specific tome pools** - Fair distribution via chest loot
> **NEXT rank system** - Rank-agnostic tome usage
> **Treasure pool integration** - Vendor sales feed economy

Combined with bounty system (401) and treasure pools (402), creates a multi-layered economy:
- Vendor sales recycle items
- Profession creates new items (tomes)
- Chests distribute both

Players have multiple economy paths: hunting (bounties), crafting (tomes), looting (chests).

---

## Related Issues

- 307 - ale-gameobject-wildcard (required for chest registration)
- 403 - ale-sell-item-hook (required for vendor sale detection)
- 402 - treasure-chest-shared-loot (similar pool distribution logic)
- 347 - linear-ability-scaling (future: ~80 spell versions per family)
- 163 - custom-class-lua-format (defines ability lists and level requirements)
