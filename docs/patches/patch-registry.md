# Patch Registry

Patches applied during the build process, organized by phase.
Each patch is idempotent (safe to run multiple times) and atomic (self-contained).

## Meta-List Structure

```
BUILD_PATCHES
├── PHASE_BEGIN    (pre-compile source fixes)
├── PHASE_MIDDLE   (compile-time adjustments)
└── PHASE_END      (post-compile config/setup)
```

---

## PHASE_BEGIN: Pre-Compile Source Fixes

Applied after source/modules are cloned, before cmake/make.
These fix compatibility issues in upstream code.

| ID | Name | Target | Parallelizable | Description |
|----|------|--------|----------------|-------------|
| B001 | aoe-loot-item-namespace | mod-aoe-loot/src/aoe_loot.cpp | Yes | Fix `Item` vs `WorldPackets::Item` ambiguity |
| B002 | playerbots-ale-login-hook | mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp | Yes | Trigger PLAYER_EVENT_ON_LOGIN for bots |
| B003 | ale-gameobject-wildcard | mod-ale/src/LuaEngine/LuaEngine.cpp | Yes | Enable entry 0 as wildcard for gameobject events |
| B004 | upstream-warning-fixes | mod-playerbots/*, mod-ale/* | Yes | Fix 695+ compiler warnings |

### B001: aoe-loot-item-namespace

**File:** `modules/mod-aoe-loot/src/aoe_loot.cpp`
**Line:** 458
**Pattern:** `Item* pItem = player->GetItemByGuid`
**Fix:** `::Item* pItem = player->GetItemByGuid`
**Reason:** AzerothCore has both `class Item` and `namespace WorldPackets::Item`. The global scope operator `::` disambiguates.

```bash
# Idempotent check: only patch if unfixed pattern exists
grep -q "^[[:space:]]*Item\* pItem = player->GetItemByGuid" "$FILE" && \
sed -i 's/^\([[:space:]]*\)Item\* pItem = player->GetItemByGuid/\1::Item* pItem = player->GetItemByGuid/' "$FILE"
```

### B002: playerbots-ale-login-hook

**File:** `modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp`
**Issue:** 324 - playerbots don't trigger PLAYER_EVENT_ON_LOGIN
**Reason:** Playerbots log bots in through their own C++ path, bypassing ALE Lua hooks. This prevents Lua scripts from initializing bot behaviors.

**Changes:**
1. Add `#include "LuaEngine.h"` after existing includes
2. Add `sALE->OnLogin(bot);` at end of `OnBotLoginInternal` function

```bash
# Idempotent check: only patch if hook not present
grep -q "sALE->OnLogin(bot)" "$FILE" || {
    # Add include
    sed -i '/#include "RandomPlayerbotMgr.h"/a #include "LuaEngine.h"'
    # Add hook call via awk (brace-depth tracking)
    awk '...' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
}
```

**See:** `docs/patches/playerbots-ale-login-hook.md` for full implementation details.

### B003: ale-gameobject-wildcard

**File:** `modules/mod-ale/src/LuaEngine/LuaEngine.cpp`
**Issue:** 325 - ALE doesn't support entry 0 wildcard for gameobject events
**Reason:** ALE validates gameobject templates before registration. Entry 0 fails validation since no template exists with that ID.

**Changes:**
1. Add `entry != 0 &&` check before `GetGameObjectTemplate` validation (2 locations)

```bash
# Idempotent check: only patch if wildcard not present
grep -q "entry != 0 && !eObjectMgr->GetGameObjectTemplate" "$FILE" || {
    sed -i 's/if (!eObjectMgr->GetGameObjectTemplate(entry))/\/\/ entry 0 = wildcard (Issue 325)\n                if (entry != 0 \&\& !eObjectMgr->GetGameObjectTemplate(entry))/g' "$FILE"
}
```

**See:** `docs/patches/ale-gameobject-wildcard.md` for full implementation details.

### B004: upstream-warning-fixes

**Files:** Multiple files in `mod-playerbots/` and `mod-ale/`
**Issue:** 333 - Upstream code produces ~1137 compiler warnings
**Reason:** Clean build improves code quality and makes real issues easier to spot.

**Warning Categories Fixed (~650):**
- 500: NextAction deprecated copy assignment (`Action.h`)
- 119: MovementActions.h signed/unsigned loop
- 13: ItemCountValue.h unused parameter
- 12: PositionInfo deprecated copy assignment
- 3: CraftData deprecated copy assignment
- 3: UnitPosition deprecated copy assignment
- 2: PlayerMethods.h signed/unsigned comparison

**Not Fixed (~490):**
- 442: boost unary_function deprecated (boost 1.74 → needs 1.81+)
- 40: HunterActions.h unused params (4 locations, low priority)
- 3: Arrow.h initializer order (requires verifying member declaration order)
- ~5: Scattered individual warnings

**Boost Note:**
Current boost version: **1.74** (2020)
The `unary_function` deprecation was fixed in boost **1.81** (2022).
Upgrading boost would eliminate 442 warnings.

**See:** `docs/patches/upstream-warning-fixes.md` for detailed implementation.

---

## PHASE_MIDDLE: Compile-Time Adjustments

Applied during compilation. Currently empty - reserved for future use.

| ID | Name | Target | Parallelizable | Description |
|----|------|--------|----------------|-------------|
| (none) | | | | |

Examples of future use:
- Parallel make job tuning based on available RAM
- Incremental build detection
- Build artifact caching

---

## PHASE_END: Post-Compile Setup

Applied after successful compilation, before server start.
These configure the installed files.

| ID | Name | Target | Parallelizable | Description |
|----|------|--------|----------------|-------------|
| E001 | lua-script-symlinks | installed-files/bin/lua_scripts/ | Yes | Symlink custom Lua to install dir |
| E002 | config-database-paths | installed-files/etc/*.conf | No | Set database connection strings |
| E003 | config-directory-paths | installed-files/etc/*.conf | No | Set log/data/source paths |
| E004 | log-directory-setup | logs-{profile}/ | Yes | Create log dir symlink to /tmp |
| E005 | dk-levelstats | acore_world_{profile} | No | Apply DK level 1-20 stats (issue 138) |

### E001: lua-script-symlinks

**Target:** `installed-files-{profile}/bin/lua_scripts/`
**Action:** Create symlinks to project Lua sources

```bash
mkdir -p "${INSTALL_DIR}/bin/lua_scripts"
ln -sfn "${DIR}/src/lua" "${INSTALL_DIR}/bin/lua_scripts/custom"
```

### E002: config-database-paths

**Target:** `installed-files-{profile}/etc/authserver.conf`, `worldserver.conf`
**Action:** Set MySQL connection strings
**Parallelizable:** No (both modify worldserver.conf)

```bash
sed -i 's|^LoginDatabaseInfo.*=.*|LoginDatabaseInfo = "127.0.0.1;3307;ritz;menardi;acore_auth"|' authserver.conf
sed -i 's|^LoginDatabaseInfo.*=.*|LoginDatabaseInfo     = "127.0.0.1;3307;ritz;menardi;acore_auth"|' worldserver.conf
sed -i 's|^WorldDatabaseInfo.*=.*|WorldDatabaseInfo     = "127.0.0.1;3307;ritz;menardi;acore_world_beta"|' worldserver.conf
sed -i 's|^CharacterDatabaseInfo.*=.*|CharacterDatabaseInfo = "127.0.0.1;3307;ritz;menardi;acore_characters_beta"|' worldserver.conf
```

### E003: config-directory-paths

**Target:** `installed-files-{profile}/etc/authserver.conf`, `worldserver.conf`
**Action:** Set filesystem paths
**Parallelizable:** No (modifies same files as E002)

```bash
sed -i 's|^SourceDirectory.*=.*|SourceDirectory = "'"${AC_CODE_DIR}"'"|' authserver.conf
sed -i 's|^LogsDir.*=.*|LogsDir = "'"${LOGS_DIR}"'"|' authserver.conf
# ... etc
```

### E004: log-directory-setup

**Target:** Project root
**Action:** Create RAM-backed log directory

```bash
mkdir -p "/tmp/wow-chat-2/logs-${PROFILE}"
ln -sfn "/tmp/wow-chat-2/logs-${PROFILE}" "${DIR}/logs-${PROFILE}"
```

---

## Parallelization Groups

Patches that can run concurrently (no file conflicts):

**Group 1 (BEGIN phase):**
- B001 (aoe_loot.cpp)
- B002 (RandomPlayerbotMgr.cpp)
- B003 (LuaEngine.cpp)
- B004 (multiple files - no conflicts with B001-B003)

**Group 2 (END phase):**
- E001 (lua_scripts/)
- E004 (logs/)

**Sequential (END phase):**
- E002 → E003 (both modify .conf files)

---

## Adding New Patches

1. Assign ID: `B###` (begin), `M###` (middle), `E###` (end)
2. Document in appropriate section above
3. Add to `apply_patches_begin/middle/end()` in `scripts/azerothcore`
4. Mark parallelizable if it doesn't share files with other patches
5. Include idempotent check (grep before sed, check before create)

---

## Implementation in scripts/azerothcore

```bash
# Meta-list structure (conceptual)
declare -A BUILD_PATCHES=(
    ["begin"]="B001"
    ["middle"]=""
    ["end"]="E001 E002 E003 E004"
)

apply_patches_begin() {
    # Parallelizable patches can use & and wait
    patch_B001 &
    wait
}

apply_patches_middle() {
    # Currently empty
    :
}

apply_patches_end() {
    # Parallel group
    patch_E001 &
    patch_E004 &
    wait
    # Sequential group
    patch_E002
    patch_E003
}
```
