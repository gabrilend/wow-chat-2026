# Everland Ghostsong

A roguelike survival layer on World of Warcraft 3.3.5a. The world is empty
until you arrive.

## Core Philosophy

The game exists for socializing. Combat, exploration, and progression are the
backdrop for conversation.

**The world is empty.** We removed all NPCs, creatures, and vendors from the
game. No quest givers standing around, no monsters wandering paths, no guards
at the gates. The world is a quiet, abandoned place—until you log in.

**You're never alone.** Playerbots are AI companions that join your party,
follow commands, fight alongside you, and have their own behaviors. They
wander the world independently, get bored, explore dungeons, and seek out
other players.

**Everything spawns around you.** Monsters ambush you on a timer. Friendly
travelers wander by periodically. Treasure chests appear nearby. The world
comes alive in your presence and goes quiet when you leave.

**Max Level: 20** | Talent points every 1/3 level | Abilities from training

---

## The Three Timers

Three periodic events create constant tension and reward.

### Ambush (every 40 seconds)

Monsters spawn in the distance and chase you. You're never safe. The timer
drifts randomly—sometimes attacks come fast, sometimes you get a breather.
Grouping up spawns stronger enemies.

### Travelers (every 130 seconds)

Friendly NPCs wander into view. Merchants, trainers, quest givers. Your class
trainer might walk by, letting you learn new abilities without returning to
a city that no longer exists.

### Treasure (every 100 seconds)

Chests appear nearby with dungeon and raid loot scaled to your level.

---

## The Sit Mechanic

When you sit down, enemies stop attacking and orbit around you instead. A
moment to breathe, strategize, or just talk. The game respects your
conversation. Stand up when you're ready to fight again.

---

## Playerbots

AI companions wander the world like you do. They get bored after combat and
decide what to do next—usually more wandering, sometimes exploring a cave.
They seek out other players when lonely. They sit and rest when hurt.

When you invite them to your party, they follow you and fight alongside you.
When you dismiss them, they go back to their own lives.

---

## Treasure Chests

### Sold Items Return to the World

When you sell items to a vendor, they go into a shared loot pool. Those items
appear in treasure chests that spawn near other players. Your trash becomes
someone else's treasure.

### Sharing Chests

You can't loot your own chest. When you open a chest, you can see the items
inside, but you can't take them. A second player has to come by and pull
them out for you. This fosters trust and cooperation—you need each other.

### Death Costs Durability

Equipment takes durability damage when you die. Death has consequences.

---

## Classes

### Level 20 Cap

The game caps at level 20. You get talent points every few levels, six total
by the end. Abilities come from trainers who wander by as travelers.

### Custom Classes

Players can submit their own custom classes. Pick any abilities from the base
game, arrange them in any order, and that becomes a playable class. Want a
healer with stealth? A tank that throws fireballs? Build it.

### Death Knights

Death Knights start at level 1 like everyone else. No special treatment.

---

## Technical Reference

Everything below is for developers.

### File Structure

```
src/lua/
├── periodic_events.lua    -- Main loop, timers, bot orchestrator
├── ambush.lua             -- Monster spawning
├── treasure.lua           -- Chest spawning, loot pools
├── travel.lua             -- Traveler NPCs
├── movement.lua           -- Position math
├── custom-classes.lua     -- Class selection
└── behaviors/
    ├── bot-wander.lua     -- Wandering
    ├── dungeon-rails.lua  -- Cave navigation
    ├── sit-and-rest.lua   -- Resource recovery
    └── ...
```

### Build and Run

```bash
./scripts/azerothcore update    # Build server
./scripts/mysql-start           # Start database (port 3307)
./scripts/azerothcore authserver
./scripts/azerothcore worldserver
```

### Foundation

Built on AzerothCore (WotLK 3.3.5a) with mod-ale for Lua scripting and
mod-playerbots for AI companions.

---

## License

Private project. Not for distribution.
