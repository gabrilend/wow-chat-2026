# Migration Guide: Release to Beta

This document describes the process to migrate from the stable `release` branch
to the fully-featured `beta` branch, integrating all custom systems.

## Prerequisites

- Working release branch build
- MySQL running (`./scripts/start-mysql`)
- All source cloned (`./scripts/azerothcore clone`)

## Baseline State

The `release` branch provides:
- AzerothCore source with modules (mod-ale, mod-playerbots, mod-aoe-loot)
- Local MySQL installation
- Basic Lua scripts from wow-chat-1
- Build and configuration scripts

## Migration Steps

### Step 1: Create Shadow Worktree

```bash
# Create shadow build directory
git worktree add ../wow-chat-2026-shadow release

# Enter shadow directory
cd ../wow-chat-2026-shadow
```

### Step 2: Apply Core Patches (C++)

Apply patches in dependency order. After each patch, rebuild and test.

#### 2.1 B001 - AOE Loot Item Namespace
```bash
# Apply
source patches/patches.sh
patch_B001_aoe_loot_item_namespace

# Verify
grep -q "::Item\*" source-*/modules/mod-aoe-loot/src/aoe_loot.cpp && echo "OK"
```

#### 2.2 B002 - Playerbots ALE Login Hook
```bash
patch_B002_playerbots_ale_login_hook

# Verify - check for cmake file and source changes
ls source-*/modules/mod-playerbots/mod-playerbots.cmake
grep -q "sALE->OnLogin" source-*/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp && echo "OK"
```

#### 2.3 B003 - ALE Gameobject Wildcard
```bash
patch_B003_ale_gameobject_wildcard

# Verify
grep -q "entry != 0" source-*/modules/mod-ale/src/LuaEngine/LuaEngine.cpp && echo "OK"
```

#### 2.4 B004 - Upstream Warning Fixes
```bash
patch_B004_upstream_warning_fixes

# Verify - check for operator= default
grep -q "operator=" source-*/modules/mod-playerbots/src/Bot/Engine/Action/Action.h && echo "OK"
```

#### 2.5 B005 - Accuracy Level Cap
```bash
patch_B005_accuracy_level_cap

# Verify
grep -q "ACCURACY_LEVEL_CAP" source-*/src/server/game/Entities/Unit/Unit.h && echo "OK"
```

#### 2.6 B006 - ALE Sell Item Hook
```bash
patch_B006_ale_sell_item_hook

# Verify
grep -q "PLAYER_EVENT_ON_SELL_ITEM" source-*/modules/mod-ale/src/LuaEngine/Hooks.h && echo "OK"
```

#### 2.7 B007 - ALE Unit Methods
```bash
patch_B007_ale_unit_methods

# Verify
grep -q "int SetWalk" source-*/modules/mod-ale/src/LuaEngine/methods/UnitMethods.h && echo "OK"
```

#### 2.8 B008 - Mod Talent Bonus
```bash
patch_B008_mod_talent_bonus

# Verify
ls -la source-*/modules/mod-talent-bonus && echo "OK"
```

### Step 3: Rebuild

```bash
# Full rebuild with cmake reconfiguration
rm build-*/CMakeCache.txt
./scripts/azerothcore compile
```

### Step 4: Apply Database Changes

```bash
# Death Knight level stats
mysql -u ritz -pmenardi -S mysql/databases/mysql.sock acore_world < sql/custom/db_world/death-knights.sql

# Custom class NPCs
mysql -u ritz -pmenardi -S mysql/databases/mysql.sock acore_world < sql/custom/db_world/custom-class-selector-npcs.sql
```

### Step 5: Copy Lua Scripts

```bash
# Lua scripts are symlinked during build
# Verify symlinks exist
ls -la installed-files-*/bin/lua_scripts/custom/
```

### Step 6: Start and Test

```bash
# Start servers
./scripts/azerothcore authserver &
./scripts/azerothcore worldserver

# In-game tests:
# 1. Login and verify no errors in worldserver console
# 2. Check playerbots spawn: .bot add
# 3. Wait for ambush monsters
# 4. Verify traveler NPCs wandering
```

## Verification Checklist

- [ ] Server starts without fatal errors
- [ ] Can login with WoW client
- [ ] Playerbots can be added
- [ ] Playerbots follow commands
- [ ] Ambush monsters spawn around player
- [ ] Traveler NPCs visible in world
- [ ] Treasure chests spawn
- [ ] Talent points awarded at 33%/66% XP
- [ ] Death Knight can be created at level 1

## Rollback

If issues occur:
```bash
# Revert all patches
unapply_patches_begin

# Or reset source completely
cd source-*
git checkout -- .
```

## Creating Migration Script

Once migration is validated, create `scripts/migrate-release-to-beta`:

```bash
#!/usr/bin/env bash
# Automated migration from release to beta
# Run from project root

set -e

echo "Migrating release to beta..."

# Apply all patches
source patches/patches.sh
apply_patches_begin

# Rebuild
./scripts/azerothcore compile

# Apply database changes
# ... (add database commands)

echo "Migration complete. Start servers to verify."
```

## Related Documents

- `issues/129-release-to-beta-transition.md` - Master tracking issue (was 400; superseded by 136-canonical-profile-definitions)
- `docs/patches/patch-registry.md` - Patch documentation
- `issues-beta/phase-structure.md` - Beta phase planning
