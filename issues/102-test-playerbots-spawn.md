# 102 - Test Playerbots Spawn

**Phase:** 1 (Foundation)
**Effect:** Verify AI companions work and respond to commands
**Status:** Open

---

## The Effect

When complete, playerbots will:
- Load on server startup
- Spawn in the world when enabled
- Respond to player commands (.bot add, .bot remove)
- Follow and assist players
- Perform basic AI tasks

This validates the companion system that makes solo play viable.

---

## What This Solves

### Current State (Unverified)

Playerbots module is compiled into worldserver (mod-playerbots cloned during install), but:
- Functionality not tested
- Configuration may need adjustment
- Don't know if bots spawn correctly
- Don't know if commands work
- Don't know if AI behaviors function

### Intended State (Verified Working)

After completion:
1. Playerbots module loads on server startup
2. Random bots spawn in world when enabled
3. Bots respond to player commands
4. Bots can be added to groups
5. Bots perform basic AI tasks (follow, assist, quest)

---

## Implementation Steps

### 1. Verify Module Compiled

Check that mod-playerbots was built into worldserver:
```bash
# Check for playerbots config
ls -la installed-files/etc/*playerbot* 2>/dev/null || echo "No playerbot config found"

# Search for playerbots references in worldserver.conf
grep -i playerbot installed-files/etc/worldserver.conf
```

### 2. Enable Playerbots

Configuration options to check/set:
```
PlayerbotAI.Enabled = 1
PlayerbotAI.RandomBotAutologin = 1
PlayerbotAI.RandomBotCount = 100
```

Location: `installed-files/etc/modules/playerbots.conf` (or similar)

### 3. Start Server and Observe

Start worldserver and watch for playerbots initialization:
```bash
./scripts/azerothcore worldserver
```

Look for log messages indicating:
- Playerbots module loaded
- Random bots logging in
- Bot spawn messages

### 4. Test In-Game Commands

Connect with client and test:
```
.bot add <name>        -- Add a bot to your group
.bot remove <name>     -- Remove a bot
.bot                   -- List available bot commands
```

### 5. Verify Bot Behavior

Observe that bots:
- Follow the player when moving
- Assist in combat
- Respond to group commands
- Can be dismissed and re-summoned

---

## Dependencies

**Blocker:**
- 101-verify-server-startup (server must be running before testing bots)

This issue can't proceed until server startup verification completes.

---

## Related Documents

- docs/architecture.md (Module Integration Points section)
- docs/playerbots/ (playerbot module documentation)
- https://github.com/liyunfan1223/mod-playerbots

---

## Why This Matters

**Solo Play Requires Companions**

Everland Ghostsong is designed for solo/small-group play. The world is empty except for:
- Ambush monsters (hostile)
- Traveler NPCs (friendly but don't fight)
- Treasure chests (loot)

Without playerbots, players are alone against ambush spawns. With playerbots:
- Group compositions possible (tank + healer + DPS)
- Tactical gameplay (CC, focus fire)
- Survivability in dangerous areas
- Social element (even though bots are AI)

**Foundation for Bot Behaviors**

Later phases add custom bot behaviors:
- 119 - orbit-player (defensive positioning)
- 132 - healer-ping-pong (support AI)
- 133 - gesture-commands (kneel, convoy)
- 161 - wandering-traveler-style (exploration mode)

These all depend on playerbots module working. Testing now prevents discovering broken bots when implementing behaviors later.

**Quality Gate**

This issue is a checkpoint:
> "Does the companion system work at all?"

If playerbots don't load, we need to fix that before adding features. If they do load, we can proceed with confidence.

---

## Phase 1 Contribution

This issue validates **Phase 1: Foundation** by ensuring:
> "The companion system is operational"

A single-player roguelike needs AI companions. Verifying playerbots work means the foundation includes not just "server runs" but "server runs with working bots."

This unlocks Phase 2 (Empty World) and Phase 3 (Living Systems) bot behaviors.
