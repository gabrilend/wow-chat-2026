# Topology-Based Behavior System

*A vision for game world architecture where behavior IS topology*

## Origin Conversation - April 20, 2026

### The Initial Insight (User)

> what if we made a tree-shaped structure for all the datastructures and connected each tree to each other tree in one leaf node. So, an object would have 1 reference to each of the other trees.
>
> think about it like this. the character walks through azeroth. They exist within a zone. That zone has behavior that runs whenever the player wants to do anything related to a zone - usually things like chat and /who and such. The player is also within an area in that zone, like a cave or a town. That zone has behavior, like merchant and summon_gemstone() for caves so players can find rubies and jade and emerald and other cool things like that. Valuables to sell to vendors. Like treasure, except in caves underground. There is also sometimes treasure. But the gemstones down appear aboveground.
>
> the player also has LoS on certain objects, which also might have behavior like "attack-move" or "merchant" or "reinforce" (where they orbit-follow the next unit that comes nearby that's friendly. When the friendly unit stops moving, they do as well. They don't get new nav-points along the circle until the unit starts moving again. And even then, they only get a new one when they reach the previous one. At each one, they stand still and listen for a half-second (but hearing for a randomized amount of time) Sometimes they sit and look outward, but only along the line between them and the player when the player is facing the opposite direction of them. of being able to see them. 180* degrees behind.
>
> when they do that, they stay there until the player gets up again. But they only have a chance to do it each time they pass that one particular nav-point. The one directly behind, point 0 through 180 or whatever increment. 2piR or whatever.
>
> also creatures can exist within zones. They should have LoS abilities like attack-move or prowl or help-a-friend. They should also have merchant where they pass the loot they stole from players or other creatures to an ally and the ally returns to a den (cave or centralized point of conduct) and perhaps others. They're kept secret from the players and only deployed right after a nearby player levels up. the new monsters who spawn in that area will start with that pattern, but it won't propagate unless it's successful. If they are still alive, the knowledge will live on in new creature spawns - but only for those who knew what went on. Don't lose your veterans, don't displace your data-trees, (copy is more expensive than reference move), and now let's see what you've been talking about and on:

### The Critique of Traditional Architecture (User)

> I don't see how either of those could have caused a specific problem. First of all, Follow and ChaseTo should only be loaded in when we have something to apply them to. If there's no unit, then there's nowhere to place the behaviortree. instead, we store follow and chaseto and other behaviors in datatrees, and reference them in the behaviortree. This part is pulled from interpreted, not compiled, code, so it can have it's values, built into it, updated as the program is running. When it fully interprets the entirety of the datatree, it starts over at the beginning and interprets as it goes. The instructions don't even have to be in order, if it finds something it doesn't know how to do it'll just hold onto it until it does. When it loops, it only keeps half of the ones it has. It picks every other one. meaning is lost as expression is abstracted, until there's no more bits of information to display. It's been entirely covered and processed and understood. Then, it starts at the beginning, and operations on it's slightly different fundamentals. Self modifying code, expressing object behavior as object data storage locations. A physical structural genome.

---

## Conceptual Framework

### Core Principle: One Leaf Connects Trees

Each entity type has its own tree structure. Trees connect to each other through exactly ONE shared leaf node. An object doesn't "contain" references to other objects - it shares a leaf with them.

```
        Zone-Tree
            |
            +-- Area-Tree <------+
            |       |            |
            |       +-- Cave     | (one leaf connects trees)
            |            +-- gemstone_spawn()
            |
    Player-Tree -----------------+
        |
        +-- LoS-Tree
                |
                +-- Creature (reinforce, prowl)
                +-- Creature (merchant -> den)
```

The player doesn't "have" a zone. The player-tree and zone-tree share a leaf. Walking through the world is not "moving through zones" - it's rearranging which leaf connects which trees.

### Behavior as Topology

Behaviors are not functions. They are patterns in tree structure. The orbit IS the data. The listening duration IS where the leaf connects.

```
reinforce-behavior:
    +-- orbit-leaf -> friendly-unit-tree
            |
            +-- nav-point[0] (behind, sit-chance=0.3)
            +-- nav-point[1] (listen-duration=rand(400,600)ms)
            +-- nav-point[n] (only-advance-when-reached)
```

### Evolutionary Knowledge Propagation

Tactics propagate through survival. Knowledge dies with the creature.

```
veteran-creature-tree:
    +-- tactic-leaf -> learned-pattern-tree
            |
            +-- "deployed after level-up"
            +-- "propagates only if alive"
            +-- (dies -> leaf detaches -> knowledge lost)
```

New monsters spawning in an area inherit patterns only from living veterans. The knowledge is kept secret from players - deployed only after a nearby player levels up. If the tactic succeeds (creature survives), it propagates. If not, the pattern dies.

### Self-Modifying Interpreted Loop

The behavior system is interpreted, not compiled:

1. Values can be updated while the program runs
2. Instructions don't have to be in order
3. Unknown instructions are held until understood
4. On each loop, keep every other instruction
5. Meaning compresses as expression abstracts
6. When fully processed, restart with modified fundamentals

This is not optimization - this is **forgetting**. Creatures that survive long enough have their tactics compressed to essence. Death mid-compression loses nuance.

---

## Context: Why AzerothCore Can't Do This

### The Current Architecture

AzerothCore stores:
- Behavior as **functions** (C++ compiled code)
- Data as **tables** (MySQL rows)
- The two are fundamentally separate

A compile error like "undeclared identifier 'angle'" happens because:
- `angle` is a function parameter
- If commented out, the function body can't reference it
- The function exists whether or not any unit uses it

### The Topology Architecture

In the topology model:
- Behavior IS **topology** (tree structure)
- Data IS **connection** (which leaves link)
- There is no separation

The "unused parameter" problem dissolves:
- `angle` is a leaf position in a movement-tree
- If nothing references that leaf, it's not there
- No parameter, no warning, self-pruning trees

---

## Earlier Context: Code vs Data

### The Homoiconicity Discussion

User:
> code is data and data is code, can't we just edit the behavior into the world? a database is just bits, with patterns described with mathematical functions so we don't have to remember exactly where they probably go.

Claude:
> The separation is arbitrary. A spell in WoW is already "behavior as data" - INSERT INTO spell_dbc with cast_time, effect, damage_base. That's not "code" but it describes behavior. The C++ just interprets it.
>
> mod-ale takes it further - Lua scripts attached to creatures. The creature entry could just contain that script. Behavior IN the world, not ABOUT the world.
>
> A sufficiently smart data format is just a programming language with weird syntax.

### Why Millions of Lines

User:
> can you tell me why Azerothcore is millions of lines of code? I get billions, but only millions? It's such a huge world!

Claude:
> The trick is: the world isn't in the code.
>
> What's in AzerothCore: network protocol, combat formulas, spell system, AI state machines, pathfinding, state synchronization. Generic rules.
>
> Where the world lives: Client-side (3D terrain, textures, models), DBC files (spell definitions, items), Database (creature templates, quest chains).
>
> The server doesn't describe Teldrassil. It knows "tree at (X,Y,Z), creature entry 1234, 500 HP." The client paints the purple leaves.

---

## Feasibility Analysis

### What AzerothCore Actually Provides (Requirements List)

Since it's open source, we can treat it as a specification:

1. **Network Protocol** - Speak WoW 3.3.5a packet format
2. **World State** - Track positions, health, mana, buffs for all entities
3. **Combat System** - Damage formulas, armor, resistances, procs
4. **Spell System** - Cast times, cooldowns, auras, dispels, channels
5. **Movement** - Pathfinding, collision, swimming, flying, mounts
6. **AI** - Threat tables, aggro, leashing, scripted encounters
7. **Persistence** - Save/load characters, inventories, quest progress
8. **Instance Management** - Dungeons, raids, battlegrounds, phasing

### Mapping to Topology Architecture

| AzerothCore Concept | Topology Equivalent |
|---------------------|---------------------|
| Player object | Player-tree |
| Zone/Area | Zone-tree, Area-tree (shared leaves) |
| Creature AI | Behavior patterns as tree topology |
| Spell effects | Effect-trees linked to caster/target leaves |
| Line of sight | LoS-tree with visible entity leaves |
| Inventory | Item-trees with ownership leaves |
| Quest state | Quest-tree with progress leaves |

### Difficulty Estimate

**What's Actually Hard:**

1. **Network Protocol** - Must be byte-perfect compatible with WoW client
   - This is fixed, documented, doable
   - ~10,000 lines of packet handlers

2. **Data Import** - Reading DBC files, database structure
   - Already solved, can reuse parsers
   - ~5,000 lines

3. **Pathfinding** - Navmesh generation/queries
   - Can use existing mmaps data
   - Recast/Detour library exists
   - ~3,000 lines of integration

4. **The Topology Engine** - THIS IS NEW
   - Tree structure with shared leaves
   - Interpreted behavior loop
   - Evolutionary propagation
   - Compression/forgetting
   - ~15,000-30,000 lines (estimate)

5. **Combat/Spells** - Formulas and effects
   - Can be data-driven in topology model
   - ~50,000 spell definitions become tree patterns
   - Engine: ~5,000 lines, data: massive

**Total Estimate:**

| Component | Lines | Difficulty |
|-----------|-------|------------|
| Protocol | 10,000 | Known |
| Data Import | 5,000 | Known |
| Pathfinding | 3,000 | Known |
| Topology Engine | 25,000 | Novel |
| Combat/Spell Engine | 5,000 | Medium |
| Behavior Patterns | 20,000 | Creative |
| Glue/Integration | 10,000 | Medium |
| **Total** | ~80,000 | |

AzerothCore is ~500,000 lines. We'd be building ~80,000 lines of NEW architecture plus reusing their data structures.

### The Integration Path

1. **Phase 1**: Build topology engine standalone
   - Tree structures, leaf connections
   - Interpreted behavior loop
   - Test with simple entities

2. **Phase 2**: Network protocol layer
   - Packet parsing/sending
   - Session management
   - Can borrow from AzerothCore

3. **Phase 3**: World state as topology
   - Import map data
   - Zones/areas as trees
   - Creature spawns as tree instantiation

4. **Phase 4**: Behavior migration
   - Express AzerothCore AI as topology patterns
   - Evolutionary propagation
   - Compression loop

5. **Phase 5**: Integration
   - Run alongside AzerothCore initially
   - Gradually move systems to topology
   - Or: full replacement for custom server

### Key Insight

> They are, fundamentally due to their open source nature, a list of requirements, to achieve the goals they set out to successfully do.

Yes. AzerothCore is a 500,000 line specification document written in C++. Every function is a requirement. Every database table is a data structure requirement. We can read it as documentation for what a WoW server must do - then implement those requirements in topology.

---

## Architecture Clarification (User, continued)

> keep in mind the interpreter is built into the compiled system, the rest uses shared memory arrays in C. As in... arrays that are sequential and contain all the shared memory stored in three dimensional positions (with minute adjustments to align with terrain and organize in a square and such) which is also where the datastructures live. Meaning... somewhere, there is a point of interest, like a tree or a character or a rock or a pebble or a stone. Or other things like that. Suddenly, if we deform the terrain and supply dynamically generated mmaps and such, then we can change the terrain on the fly while the server is still running.
>
> "surprise, there's a new tunnel that opened, the monsters are attacking from over there instead" dens, from gauntlet

### The Memory Model

```
+------------------------------------------+
|  COMPILED C (fast, fixed)                |
|  - Interpreter loop                      |
|  - Memory management                     |
|  - Network I/O                           |
+------------------------------------------+
           |
           v (operates on)
+------------------------------------------+
|  SHARED MEMORY ARRAYS (mutable)          |
|  - Sequential, 3D-indexed                |
|  - Terrain-aligned with adjustments      |
|  - Points of interest at spatial coords  |
|  - Datastructures LIVE HERE              |
+------------------------------------------+
           |
           v (can be modified to)
+------------------------------------------+
|  DYNAMIC TERRAIN                         |
|  - Regenerate mmaps on the fly           |
|  - New tunnels open                      |
|  - Dens spawn/despawn                    |
|  - Server keeps running                  |
+------------------------------------------+
```

The interpreter is compiled. The DATA is shared memory at 3D positions. A tree, a rock, a character - they exist at coordinates. The datastructure IS the position.

This enables: "surprise, there's a new tunnel" - deform terrain, regenerate navmesh, monsters attack from new vector. Like Gauntlet dens but dynamic.

---

## Reference: w7 Worldbuilding

> READ LATER: /home/ritz/documents/w7/chapters/part-1/

User description of w7:

> in w7, monsters appear from below. The farther down you go, the stronger they get. But they approach at a certain rate, roughly the rate that the humans can maintain against it. A particularly valiant warrior might clear and defend significant chunks of it, but they will never reach the planets center. However... The monsters do not destroy them all, though sometimes they might wave an unholy crusade on a specific point, like the focusing of water jets at las vegas hotels and children's museums onto on central point - it creates a focused effect, a deluge of water at that spot. So too do the monsters sometimes sack an entire city, valley, minor mountain... then they dissipate and return to normal.

### w7 Design Principles (for topology system)

1. **Vertical threat gradient** - Strength increases with depth
2. **Equilibrium rate** - Monsters approach at sustainable defense rate
3. **Asymptotic progress** - Warriors can push but never reach core
4. **Focused assault** - Sometimes coordinate on single point (sacking)
5. **Dissipation** - After focus, return to baseline pressure

This maps to topology:

```
depth-tree:
    +-- strength-leaf (linear or exponential with Z)
    +-- approach-rate-leaf (balanced against human-defense-tree)

focus-assault-tree:
    +-- target-leaf -> city-tree | valley-tree | mountain-tree
    +-- intensity-leaf (water-jet focusing)
    +-- duration-leaf
    +-- dissipation-pattern-leaf
```

The "focusing of water jets" metaphor - multiple streams converging on one point - is the topology model of coordinated assault. Many creature-trees share a leaf with one target-tree.

---

## Next Steps

1. [ ] Design the tree/leaf primitive in detail
2. [ ] Prototype the interpreted behavior loop
3. [ ] Define the compression/forgetting algorithm
4. [ ] Map one AzerothCore system (e.g., creature AI) to topology
5. [ ] Build minimal network protocol handler
6. [ ] Test with WoW client connection
7. [ ] **Read /home/ritz/documents/w7/chapters/part-1/**
8. [ ] Discuss w7 before moving to part-2

---

## Document History

- 2026-04-20: Initial creation from conversation
