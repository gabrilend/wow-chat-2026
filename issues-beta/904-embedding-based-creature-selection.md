# 904 - Embedding-Based Creature Selection

**Migrated from:** issues/128-embedding-based-creature-selection.md

## Status: Open

## Phase: 9 - Storytelling & World Structure

## Dependencies
- Issue 903: contextual-creature-spawns (type filtering)

## Current Behavior
- Creatures selected randomly from type-filtered pool
- No semantic awareness of creature names
- May spawn similar creatures repeatedly

## Intended Behavior
- Generate embeddings for all creature names
- Compare creature name embeddings to spawn context
- Select creature MOST DIFFERENT from recent/nearby spawns
- Creates variety within type constraints

## Why Embeddings?

### Semantic Diversity
Traditional random selection might spawn:
- Skeleton Warrior, Skeleton Mage, Skeleton Archer (similar)

Embedding-based selection ensures variety:
- Skeleton Warrior, Banshee, Ghoul, Wraith (diverse within undead)

### Name Clustering
Creatures with similar names are semantically similar:
```
"Skeletal Warrior"  <->  "Skeleton Mage"     (close)
"Skeletal Warrior"  <->  "Restless Banshee"  (far)
"Defias Thug"       <->  "Defias Pillager"   (close)
"Defias Thug"       <->  "Riverpaw Gnoll"    (far)
```

### Selection Algorithm
1. Get all creatures of matching type and level
2. Get embeddings for their names
3. Compare to recently spawned creatures' embeddings
4. Select the one with maximum distance from recent spawns
5. This prevents "Skeleton, Skeleton, Skeleton..." patterns

## Embedding Generation

### Offline Precomputation
```bash
# Generate embeddings for all creature names at build time
# Store in SQLite or binary file for fast lookup

python scripts/generate-creature-embeddings.py \
    --input creature_template.sql \
    --output assets/creature-embeddings.bin \
    --model all-MiniLM-L6-v2
```

### Data Structure
```lua
-- Preloaded at server start
CreatureEmbeddings = {
    [634] = { 0.12, -0.45, 0.78, ... },  -- "Defias Thug"
    [636] = { 0.15, -0.42, 0.80, ... },  -- "Defias Pillager"
    [639] = { 0.89, 0.23, -0.15, ... },  -- "Edwin VanCleef"
}
```

### Dimensionality
- Full embeddings: 384 dimensions (MiniLM)
- Can reduce via PCA to 32-64 for memory
- Trade-off: less precision, faster comparison

## Scalable Distance Selection

### The Problem with Binary Selection
The original algorithm picks the MOST different creature from recent spawns.
But sometimes you want a middle ground - not most similar, not most different,
but somewhere in between.

### Equidistant Selection Parameter
Add a configurable `diversity_factor` between 0.0 and 1.0:
- `0.0` = Select MOST SIMILAR to recent spawns (cohesive groups)
- `0.5` = Select EQUIDISTANT (balanced variety)
- `1.0` = Select MOST DIFFERENT from recent spawns (maximum diversity)

```lua
-- {{{ Configuration
-- diversity_factor controls how different spawned creatures should be:
--   0.0 = most similar (cohesive enemy groups, all skeletons)
--   0.5 = equidistant (balanced, some variety)
--   1.0 = most different (maximum diversity, no repeats)
--
-- This allows tuning spawn behavior for different gameplay feels:
-- - Dungeon rooms might use 0.3 (thematic cohesion)
-- - Open world might use 0.8 (exploration variety)
-- - Boss fights might use 0.0 (all adds of same type)
--
DIVERSITY_FACTOR = 0.7  -- default: lean toward variety
-- }}}
```

### Algorithm: Percentile-Based Selection

```lua
-- {{{ Ambush.selectCreatureByDiversity
-- Instead of picking max/min, pick the creature at the desired percentile
-- of the dissimilarity distribution.
--
function Ambush.selectCreatureByDiversity(candidates, recentSpawns, diversityFactor)
    diversityFactor = diversityFactor or DIVERSITY_FACTOR

    -- Calculate dissimilarity score for each candidate
    local scored = {}
    for _, candidate in ipairs(candidates) do
        local candidateEmb = CreatureEmbeddings[candidate.id]
        if candidateEmb then
            local minDistToRecent = math.huge

            -- Find minimum distance to any recent spawn
            for _, recent in ipairs(recentSpawns) do
                local recentEmb = CreatureEmbeddings[recent]
                if recentEmb then
                    local similarity = cosineSimilarity(candidateEmb, recentEmb)
                    local dissim = 1 - similarity  -- convert to dissimilarity
                    if dissim < minDistToRecent then
                        minDistToRecent = dissim
                    end
                end
            end

            -- If no recent spawns, use neutral score
            if minDistToRecent == math.huge then
                minDistToRecent = 0.5
            end

            table.insert(scored, {
                creature  = candidate,
                dissim    = minDistToRecent,
            })
        end
    end

    if #scored == 0 then return nil end

    -- Sort by dissimilarity (lowest to highest)
    table.sort(scored, function(a, b) return a.dissim < b.dissim end)

    -- Select creature at the percentile specified by diversityFactor
    -- diversityFactor=0.0 -> index 1 (most similar)
    -- diversityFactor=0.5 -> middle index (equidistant)
    -- diversityFactor=1.0 -> last index (most different)
    local targetIndex = math.floor(diversityFactor * (#scored - 1)) + 1
    targetIndex = math.max(1, math.min(#scored, targetIndex))

    return scored[targetIndex].creature
end
-- }}}
```

### Cosine Similarity
```lua
function cosineSimilarity(a, b)
    local dot = 0
    local normA = 0
    local normB = 0

    for i = 1, #a do
        dot = dot + a[i] * b[i]
        normA = normA + a[i] * a[i]
        normB = normB + b[i] * b[i]
    end

    return dot / (math.sqrt(normA) * math.sqrt(normB))
end
```

### Visual Representation

```
Dissimilarity scores sorted (low to high):

   0.0       0.25      0.5       0.75      1.0
    |---------|---------|---------|---------|
    ^                   ^                   ^
  factor=0.0         factor=0.5         factor=1.0
  (most similar)    (equidistant)    (most different)

With 10 candidates:
  factor=0.0 -> index 1  (Skeleton Warrior)
  factor=0.3 -> index 4  (Skeleton Mage)
  factor=0.5 -> index 5  (Risen Ghoul)
  factor=0.7 -> index 8  (Restless Banshee)
  factor=1.0 -> index 10 (Plague Eruptor)
```

### Use Cases

| Scenario | Diversity Factor | Effect |
|----------|-----------------|--------|
| Dungeon boss room | 0.0-0.2 | All adds are thematically similar |
| Dungeon trash | 0.4-0.6 | Some variety, still cohesive |
| Open world | 0.7-0.9 | High variety, exploration feel |
| Testing/debug | 1.0 | Maximum diversity |
| Horde mode | 0.0 | Waves of identical enemies |

### Configuration per Zone Type

```lua
-- Different zones can have different diversity settings
ZoneDiversityConfig = {
    ["dungeon_boss"]   = 0.1,  -- cohesive add packs
    ["dungeon_trash"]  = 0.5,  -- balanced
    ["open_world"]     = 0.8,  -- varied exploration
    ["graveyard"]      = 0.3,  -- themed undead
    ["forest"]         = 0.6,  -- some variety in beasts
}

function Ambush.getDiversityForZone(zoneType)
    return ZoneDiversityConfig[zoneType] or DIVERSITY_FACTOR
end
```

## Recent Spawn Tracking

```lua
-- Track last N spawned creatures per player
-- Ring buffer, configurable size

RECENT_SPAWN_MEMORY = 5  -- remember last 5 spawns

function Ambush.recordSpawn(player, creatureId)
    local recent = player:GetData("recent-spawns") or {}

    table.insert(recent, creatureId)

    -- Trim to max size
    while #recent > RECENT_SPAWN_MEMORY do
        table.remove(recent, 1)
    end

    player:SetData("recent-spawns", recent)
end
```

## Implementation Steps

### Phase 1: Embedding Generation
1. Create scripts/generate-creature-embeddings.py
2. Extract creature names from creature_template
3. Generate embeddings using sentence-transformers
4. Save to assets/creature-embeddings.bin
5. Create Lua loader for binary format

### Phase 2: Runtime Integration
1. Load embeddings at server start
2. Implement cosine similarity in Lua
3. Track recent spawns per player
4. Modify creature selection to use embeddings
5. Fallback to random if embeddings unavailable

### Phase 3: Optimization
1. Reduce dimensionality if memory constrained
2. Precompute distance matrix for small pools
3. Cache similarity computations
4. Profile performance impact

## Performance Considerations

### Memory
- 10,000 creatures x 384 floats x 4 bytes = 15 MB
- Reduced to 64 dims: 2.5 MB
- Acceptable for server memory

### CPU
- Cosine similarity: O(embedding_dim) per comparison
- 100 candidates x 5 recent x 64 dims = 32,000 operations
- Trivial for modern CPU

### Startup
- Load embeddings from binary file
- 15 MB binary loads in <100ms
- One-time cost at server start

## File Formats

### Binary Embedding File
```
Header:
  4 bytes: magic number (0x454D4244 = "EMBD")
  4 bytes: version (1)
  4 bytes: embedding dimension
  4 bytes: creature count

Per creature:
  4 bytes: creature entry ID
  N floats: embedding values
```

### Lua Loader
```lua
function loadEmbeddings(filepath)
    local file = io.open(filepath, "rb")
    local magic = file:read(4)
    -- ... parse binary format
    return embeddings
end
```

## Related Issues
- 902-dungeon-room-spawn-zones (zone definitions)
- 903-contextual-creature-spawns (type filtering)

## Related Files
- scripts/generate-creature-embeddings.py (new)
- assets/creature-embeddings.bin (generated)
- src/lua/embeddings.lua (loader + similarity)
- src/lua/ambush.lua (integration)
