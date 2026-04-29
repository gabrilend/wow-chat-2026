# Phase 4 Progress: Treasure & Economy

## Effect

Chests spawn. Loot circulates between players.

## Status: Mostly Implemented

## Goal

Create the treasure system where items flow through a shared pool. Players
can't see items in their own chests - cooperation is required. Sold items
re-enter circulation, creating an economy of found goods.

---

## Issues

Ordered by narrative arc: chest substrate → economy hooks → loot
pipeline → multiplayer access → death stakes → exploit hardening.

### Currency substrate
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 401 | bounty-board-currency-system | Completed | Alternative currency. Foundation for non-gold rewards. |

### Chest substrate (the container)
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 409 | custom-empty-loot-chest-templates | Implemented | 37 custom templates. Blocks 402. |
| 402 | treasure-chest-shared-loot | Implemented | Per-player queues. Depends on 409. Core loop. |

### Economy hooks (sold items re-enter pool)
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 403 | ale-sell-item-hook | Completed | C++ patch applied. Blocks 404. |
| 404 | sold-items-to-treasure-pool | In Progress | Needs 403 rebuild. Closes the loop: sells become spawns. |

### Multiplayer access (cooperation required)
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 408 | multiplayer-chest-access | Implemented | Holder can't see own loot — searcher must loot for them. |
| 407 | chest-vulnerability-mechanic | Implemented | Daze/taunt on open. Creates tension during loot. |

### Death stakes
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 406 | death-durability-system | Implemented | Gear damage on death. Blocks Phase 8 permadeath logic. |
| 410 | chest-bound-hearthstones | Open | Teleport items rotate through pool. |

### Exploit hardening
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 411 | zero-value-treasure-duplicates | Open | Prevent gold exploit on re-pooled items. |

### Ability rewards (ties to Phase 7)
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 405 | ability-tome-system | In Progress | Lua done, needs SQL. Crosses into Phase 7 ability system. |

## Completed: 2/11 (5 Implemented, need testing)

---

## Completion Criteria

- [x] Chests spawn near players on timer (~100 seconds)
- [x] Holder can't see items in their own chest
- [x] Second player (searcher) can loot for holder
- [ ] Sold items enter shared pool (blocked by C++ rebuild)
- [ ] Items appear in other players' chests
- [x] Death costs durability on equipment
- [x] Opening chest causes brief vulnerability (daze)
- [ ] Chest-bound hearthstones circulate
- [ ] Pool items have 0 sell value (prevent exploit)

---

## Key Files

- `src/lua/treasure.lua` - Chest spawn and loot system
- `src/lua/chest-vulnerability.lua` - Holder/searcher mechanics
- `sql/custom/db_world/custom-empty-loot-chests.sql` - Empty templates
- `docs/patches/ale-sell-item-hook.md` - C++ patch documentation

---

## Dependencies

- Phase 1 (foundation) - ALE must work
- Phase 3 (ambush) - Chests spawn alongside danger

---

## Holder/Searcher Mechanic

### Roles

- **Holder**: First player to interact with chest
- **Searcher**: Any subsequent player who interacts

### Key Rules

1. Holder sees EMPTY chest (custom template with data1=0)
2. Searcher triggers loot injection
3. Searcher can take items for holder
4. Holder logout = chest snaps shut (no searcher promotion)

### Why This Design

- Forces cooperation between players
- Creates social moments around treasure
- Prevents solo hoarding
- Rewards grouping up

---

## Per-Player Loot Queues (148)

### Distribution Algorithm

Items entering pool assigned to players via mancala-style distribution:
1. Get list of online players
2. Sort by level (ascending)
3. Distribute items round-robin
4. Level-appropriate items only

### Queue Structure

```lua
Treasure.playerQueues = {
  [playerGuid] = {
    { itemId = 1234, itemLevel = 15, count = 1 },
    { itemId = 5678, itemLevel = 18, count = 2 },
  }
}
```

### Injection

When searcher opens holder's chest:
1. Check holder's queue
2. Inject pending items into chest loot
3. Clear injected items from queue

---

## Custom Chest Templates (160)

### The Problem

Retail chest templates have loot tables.
Holder would see retail loot, breaking the mechanic.

### The Solution

37 custom chest templates (entries 900001-900037):
- Copy of retail chest appearance
- `data1 = 0` (no loot table)
- Holder sees truly empty chest

### Template Mapping

```lua
-- Map retail chest entry to custom empty version
EMPTY_CHEST_MAP = {
  [2843] = 900001,  -- Battered Chest
  [2844] = 900002,  -- Tattered Chest
  -- ... etc
}
```

---

## Sold Items to Pool (149, 150)

### Blocked By: C++ Rebuild

ALE needs `PLAYER_EVENT_ON_SELL_ITEM` hook to capture vendor sales.

### Flow

1. Player sells item to vendor
2. ALE hook fires BEFORE buyback slot
3. Lua captures item data (entry, count, enchants)
4. Item added to treasure pool
5. Distributed to player queues
6. Eventually appears in someone's chest

### Patch Status

- Hook implemented in C++ (see docs/patches/ale-sell-item-hook.md)
- Needs server rebuild to activate
- Once rebuilt, issue 404 unblocks

---

## Death Durability (152)

### On Player Death

- All equipped items lose 10% max durability
- Creates gold sink (repair costs)
- Makes death meaningful beyond respawn time
- Gear eventually breaks if dying too much

### Implementation

Hook `PLAYER_EVENT_ON_KILLED_BY_CREATURE`:
```lua
for slot = 0, 18 do
  local item = player:GetItemByPos(255, slot)
  if item then
    local maxDur = item:GetMaxDurability()
    local newDur = item:GetDurability() - (maxDur * 0.10)
    item:SetDurability(math.max(0, newDur))
  end
end
```

---

## Chest Vulnerability (153)

### On Chest Open

Holder becomes briefly vulnerable:
- **Daze**: 2 second movement slow
- **Mild Taunt**: Nearby monsters prioritize holder

### Purpose

- Opening chest is a risk
- Must clear area or have help
- Creates tension around treasure
- Searcher can defend holder

---

## Zero-Value Duplicates (305)

### The Problem

Items can cycle: chest → player → vendor → pool → chest.
If items retain sell value, infinite gold generation.

### The Solution

When item enters pool:
- Create duplicate with sell value = 0
- Original item data preserved (stats, enchants)
- Gold enters economy once (original sale)
- Item circulates forever after

---

## Chest-Bound Hearthstones (303)

### Concept

Two unique hearthstones (blue/red) in treasure pool:
- When looted, binds to THAT chest's location
- Using stone teleports to discovery spot
- Stone immediately respawns into pool
- Players can have both = two return points

### Why

- No inns in empty world
- Only teleport options are discovered chests
- Creates meaningful exploration reward
- Players share "good spots" socially

---

## Notes

### Test Commands

```
#pooladd <itemId> <itemLevel> [count]  -- Add item to pool
#poolsize                               -- Show pool size
#myqueue                                -- Show your pending items
```

### Bounty Board Currency (121)

Alternative currency for services:
- Earn bounty by killing monsters
- Spend at bounty boards for training, items
- Separate from gold economy
- Future feature, not v1.0

---

## rmail Integration (Reference)

Phase 4 doesn't directly use rmail, but it establishes the **circulation pattern** that
rmail echoes at a different layer. Items flow between players; messages flow between
services. See **Phase 10** for the full rmail treatment with design philosophy.

### Circulation as Pattern

The treasure pool creates a circulation system for physical goods.
rmail creates a circulation system for information.

| System | What Flows | Pool | Distribution |
|--------|------------|------|--------------|
| Treasure | Items | shared loot pool | per-player queues |
| rmail | Messages | service inboxes | address routing |

Both systems remove the "direct grab" pattern. You can't just take what you want.
Someone else mediates. Searcher opens holder's chest. Service processes your mail.

### Value and Stakes

```
THOUGHT: An economy creates stakes. Stakes create meaning.

When items have value, losing them hurts.
When gaining them requires cooperation, relationships form.
When the loop is closed (sold → pool → chest), nothing is permanent.

The treasure system trains players for impermanence.
Items come, items go. What matters is the moment of discovery.

rmail echoes this. Messages arrive, messages expire.
Custom class definitions submitted, validated, maybe rejected.
Feedback given, maybe acted on, maybe not.

Both systems are about flow, not possession.
The game isn't about having. It's about participating.
```

### How They Rhyme

| Treasure | rmail |
|----------|-------|
| Holder can't see own loot | Sender can't guarantee receipt |
| Searcher must help | Service must validate |
| Items enter pool | Messages enter queue |
| Eventually redistributed | Eventually delivered or expired |
| Zero-value prevents exploit | Lifecycle prevents spam |

### Indirect Service Connections

| Service | Port | Relationship to Economy |
|---------|------|------------------------|
| accounts | 4562 | Players need accounts to participate in economy |
| classes | 4662 | Ability tomes link to custom class abilities |
| mail | 4762 | Mail system for trading, gifting (future) |
| narrator | 4862 | Narrators might describe legendary items |
| feedback | 4962 | Balance feedback about loot distribution |

### Ability Tomes (151) and Custom Classes

Ability tomes in the treasure pool teach custom class abilities via the **NEXT rank** system:
- Tome found in chest (e.g., "Tome of Rejuvenation")
- Tome is **spell-family based**, not rank-specific
- When used, system looks up player's custom class definition
- Finds the NEXT rank of that spell the player hasn't learned
- Validates player level against custom class level requirement
- Links Phase 4 (where it spawns) to Phase 7 (what it teaches)
- The class definition was submitted via rmail (4662), discovery via treasure

**Key design change:** Tomes are decoupled from the rank system.
An inscriptionist who knows "Rejuvenation" (any rank) creates "Tome of Rejuvenation".
The recipient learns whichever rank they're eligible for based on their class definition.

**Future (issue 347):** Linear ability scaling creates level-specific spell versions.
All abilities scale 1-80, so a level-12 player learning Rejuvenation gets
"Rejuvenation (Level 12)" - perfectly balanced for their level. No ranks at all.

```
THOUGHT: The tome is where treasure meets identity.

A custom class is an idea, submitted through rmail.
An ability tome is that idea made physical, found in a chest.
The searcher hands you a scroll that teaches YOUR design.

External creation → internal discovery.
rmail carries the definition. Treasure delivers the reward.
The rank doesn't matter - the tome knows what you need next.
```

For the full WHY behind rmail, see Phase 10's "Thoughts" sections.

---

## Related Phases

- **Phase 3** - Chests spawn alongside ambush
- **Phase 5** - Merchants interact with economy
- **Phase 7** - Ability tomes in treasure pool (rmail port 4662)
- **Phase 10** - rmail coordination (circulation pattern echoes)
