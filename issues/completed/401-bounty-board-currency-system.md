# 401 - Bounty Board Currency System

**Phase:** 4 (Economy - Currency & Rewards)
**Effect:** Trophy-based bounty rewards with dynamic world state pricing
**Status:** Will Not Implement (out of scope - may revisit later)

---

## The Effect

Players earn rewards by bringing proof of deeds - no quest pickup required. A wolf pelt is worth 10 copper. An elemental core is worth 50 copper. Trophy value is **known, predictable, and fair**.

Bounty boards display current rates. World events (invasions, scarcity) adjust prices dynamically. Players become "champions" by contributing to faction needs.

---

## What This Solves

### Before (Standard WoW Quests)

**Quest workflow:**
1. Talk to NPC → Accept quest
2. Kill creatures → Loot quest items
3. Return to NPC → Turn in quest
4. Receive random copper/silver reward

**Problems:**
- Must accept before proof matters
- Random reward amounts (7 copper, 13 silver, etc.)
- Static - no response to world state
- No progression tracking beyond quest completion

**Example:**
- Quest: "Kill 10 wolves, bring pelts"
- Reward: 47 copper (arbitrary number)
- If wolves are rare: still 47 copper
- If wolves invade: still 47 copper
- No recognition of cumulative contributions

### After (Bounty Board System)

**Bounty workflow:**
1. Loot wolf pelt
2. Automatically receive 10 copper
3. Broadcast: "Bounty collected: 10 copper"
4. Track contribution for championing

**Improvements:**
- No quest acceptance needed - proof IS the quest
- Clean increments (10c, 50c, 10s, 50s, 1g)
- Dynamic pricing based on world events
- Championing system tracks long-term contributions
- Trust-based rewards for no-drop creatures

**Example:**
- Wolf pelt drops → 10 copper (base rate)
- Wolf invasion event → 20 copper (2x multiplier)
- After 100 pelts contributed → "Grunt" title, bronze spear
- System knows you're helping, responds accordingly

---

## Why This Matters

**Bounty Board Aesthetic**

The name "bounty board" implies:
- Clear posted rates (10c per pelt, not "maybe 7c maybe 13c")
- Bring proof, get paid (no bureaucracy)
- Dynamic response to world needs (invasion → higher bounties)

Standard WoW quests feel like paperwork. Bounty boards feel like a living economy.

**Trust and Recognition**

For creatures that don't drop items:
- System trusts you killed it (witnessed deed)
- Immediate reward, no return trip
- "We saw you fight that dragon - here's 1 gold"

For long-term players:
- Championing tracks cumulative value
- Titles reflect contributions ("Champion of the Horde")
- Unlock rewards (better equipment, time off, faction perks)

**Supply and Demand**

If players farm all wolves → pelts become rare → price increases
If elementals invade → cores flood market → price decreases

This creates emergent gameplay:
- Players notice bounty changes
- Adjust hunting patterns
- Economy feels responsive, not scripted

---

## Design

### Currency Increments

All values in increments of 10:
```
Common trophy:     10 copper
Uncommon trophy:   50 copper
Rare trophy:       10 silver
Uncommon trophy:   50 silver
Epic trophy:       1 gold
Legendary deed:    5 gold+
```

No random amounts. Bounty boards post clean numbers.

### Proof Types by Category

| Category | Proof Type | Example |
|----------|------------|---------|
| Animals | Trophy/Pelt | Wolf pelt, bear claw |
| Elementals | Materials | Elemental core, essence shard |
| Humanoids | Token/Badge | Faction insignia, command scroll |
| No-drop | Trust-based | System witnesses deed, rewards directly |

### Auto-Reward on Loot

```lua
RegisterPlayerEvent(PLAYER_EVENT_ON_LOOT_ITEM, function(event, player, item)
    local itemId = item:GetEntry()
    local bounty = BountyRegistry[itemId]

    if bounty then
        local reward = calculateReward(bounty, player)
        player:ModifyMoney(reward)
        player:SendBroadcastMessage("Bounty collected: " .. formatMoney(reward))

        trackContribution(player, bounty.category, reward)
    end
end)
```

Player loots pelt → money added → message displayed → contribution tracked.

No quest pickup. No turn-in. Proof IS payment trigger.

### Dynamic World Events

```lua
function triggerInvasionEvent(zoneId, creatureType)
    BountyModifiers[creatureType] = 2.0  -- double rewards

    announceToZone(zoneId, "Alert: " .. creatureType .. " invasion! Bounties doubled!")

    -- End event after 30 minutes
    CreateLuaEvent(function()
        BountyModifiers[creatureType] = 1.0
    end, 30 * 60 * 1000, 1)
end
```

Event starts → bounties increase → players respond → event ends → rates normalize.

### Championing System

```lua
local ChampionTiers = {
    {contributions = 100,  reward = "bronze_spear",  title = "Grunt"},
    {contributions = 500,  reward = "iron_spear",    title = "Soldier"},
    {contributions = 1000, reward = "steel_spear",   title = "Champion"},
    {contributions = 5000, reward = "day_off",       title = "Hero"},
}

function checkChampionProgress(player)
    local total = player:GetData("total_contributions") or 0

    for _, tier in ipairs(ChampionTiers) do
        if total >= tier.contributions then
            local key = "champion_" .. tier.title
            if not player:GetData(key) then
                player:SetData(key, true)
                grantChampionReward(player, tier)
            end
        end
    end
end
```

After 100 contributions → "Grunt" + bronze spear
After 500 contributions → "Soldier" + iron spear
After 5000 contributions → "Hero" + day off (rest bonus, XP multiplier, etc.)

### Trust-Based Rewards

For creatures that don't drop trophies:

```lua
RegisterCreatureEvent(CREATURE_EVENT_ON_DIED, function(event, creature, killer)
    if not hasTrophy(creature:GetEntry()) then
        local bounty = getTrustBounty(creature:GetEntry())
        if bounty and killer:IsPlayer() then
            killer:ModifyMoney(bounty)
            killer:SendBroadcastMessage("Deed witnessed. Bounty: " .. formatMoney(bounty))
        end
    end
end)
```

Player kills boss (no-drop) → system witnesses → reward granted.

"We saw you slay the dragon. Here's 5 gold."

---

## Implementation

### 1. Bounty Registry (Lua)

```lua
local BountyRegistry = {
    -- [itemID] = {copper, rarity, category}
    [12345] = {copper = 10, rarity = "common", category = "animal"},
    [12346] = {copper = 50, rarity = "uncommon", category = "animal"},
    [12347] = {silver = 10, rarity = "rare", category = "elemental"},
}

local BountyModifiers = {
    -- [creatureEntry] = multiplier (updated by world events)
}

function calculateReward(bounty, player)
    local base = bounty.copper or (bounty.silver * 100) or 0
    local modifier = BountyModifiers[bounty.category] or 1.0
    return math.floor(base * modifier)
end
```

### 2. Database Schema

```sql
-- Bounty item registry
CREATE TABLE IF NOT EXISTS wowchat_bounties (
    item_entry INT PRIMARY KEY,
    base_copper INT DEFAULT 10,
    rarity ENUM('common', 'uncommon', 'rare', 'epic') DEFAULT 'common',
    category VARCHAR(32) DEFAULT 'animal'
);

-- Player contribution tracking
CREATE TABLE IF NOT EXISTS wowchat_contributions (
    player_guid INT,
    category VARCHAR(32),
    total_value INT DEFAULT 0,
    PRIMARY KEY (player_guid, category)
);

-- Normalize existing money rewards to increments of 10
UPDATE creature_loot_template SET mincountOrRef = ROUND(mincountOrRef / 10) * 10;
UPDATE quest_template SET RewardMoney = ROUND(RewardMoney / 10) * 10;
```

### 3. Configuration

```conf
WowChat2.Bounty.Enabled = 1
WowChat2.Bounty.TrustEnabled = 1
WowChat2.Bounty.DynamicEventsEnabled = 1
WowChat2.Bounty.ChampioningEnabled = 1
WowChat2.Bounty.BaseMultiplier = 1.0
```

### 4. Files to Create

- `src/lua/bounty.lua` - Core bounty system
- `src/lua/championing.lua` - Contribution tracking and rewards
- `sql/custom/db_world/bounty-registry.sql` - Initial bounty items
- `sql/custom/db_characters/contributions.sql` - Tracking table

---

## Design Philosophy

### "Suddenly no pelts. Not very strategic."

If players farm all wolves → pelts become rare → value increases.
If elementals invade → cores flood → value decreases.

The rarity system should reflect **actual game state**, not static configuration.

### Clean Numbers

No random amounts. Bounty boards post rates like:
```
Wolf Pelt:        10 copper
Elemental Core:   50 copper (INVASION: x2)
Dragon Scale:     1 gold
```

Players know value before hunting. Like real bounty boards.

### Trust Over Bureaucracy

System trusts witnessed deeds. No quest pickup paperwork.

Bring pelt → get paid.
Kill dragon (no-drop) → system sees, pays anyway.

Recognition without friction.

---

## Phase 4 Contribution

This issue defines **Phase 4: Economy - Currency & Rewards** by establishing:

> **Predictable currency increments** (10c, 50c, 10s, 50s, 1g)
> **Auto-reward system** (proof-based, no quest pickup)
> **Dynamic world economy** (supply/demand, event modifiers)
> **Championing progression** (titles, rewards, recognition)

The bounty board aesthetic transforms WoW's quest grind into a living economy that responds to player actions and world events. Players become champions through contributions, not just quest completions.
