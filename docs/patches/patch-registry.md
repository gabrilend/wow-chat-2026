# Patch Registry

Patches applied during the build-and-deploy process, organized by phase.
Each patch is idempotent (safe to run multiple times) and atomic (self-contained).

## Meta-List Structure

There are **three application times** a patch can fire, each with a distinct
purpose and target:

```
BUILD_PATCHES
├── PHASE_BEGIN    (B-patches — pre-compile source fixes)
├── PHASE_END      (E-patches — post-install setup of shadow tree)
└── PHASE_CONFIG   (C-patches — post-promote tuning of runtime configs)
```

| Phase         | Tier        | When                                            | Target                                              | Purpose |
|---------------|-------------|-------------------------------------------------|-----------------------------------------------------|---------|
| PHASE_BEGIN   | B-patches   | Before cmake/make, on source tree               | `source-{profile}/src/...` and `source-{profile}/modules/...` | Make upstream code compile cleanly against our profile (fix bugs, add hooks, silence warnings). Reverted after build to keep source tree clean. |
| PHASE_END     | E-patches   | After cmake install to shadow, before validate  | `installed-files-shadow/{etc,bin,...}`              | Set up the just-installed shadow tree: write `.conf` files from `.dist`, create log/symlink dirs, link Lua scripts, apply per-profile SQL. |
| PHASE_CONFIG  | C-patches   | After promote, before server start              | `installed-files-{profile}/etc/*.conf`              | Apply gameplay-tuning opinions (max level, exp rate, run speed, fall damage, port numbers, realmlist setup) on the live profile config tree. |

**The separation matters.** B-patches edit upstream code we don't own; they
must be reverted. E-patches set up infrastructure that the server *needs* to
start; they're load-bearing for validation. C-patches encode the *opinions*
that make this server *this server* rather than vanilla AzerothCore — they
live downstream of validation so the validation pass tests the baseline
binary, not the opinionated one.

## Reading the pipeline

```
1. clone/update source
2. PHASE_BEGIN apply         ← B-patches modify source in place
3. cmake configure + make
4. cmake --install (to shadow)
5. PHASE_END apply           ← E-patches set up shadow's etc/, logs/, db
6. PHASE_BEGIN unapply       ← B-patches reverted (trap also handles failure)
7. validate                  ← run shadow worldserver briefly
8. promote                   ← shadow → installed-files-{profile}/
9. PHASE_CONFIG apply        ← C-patches tune profile config files
10. server start
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
| B005 | accuracy-level-cap | src/server/game/Entities/Unit/* | Yes | Cap level diff for hit/miss at ±3 (Issue 803) |
| B006 | ale-sell-item-hook | mod-ale/*, Handlers/ItemHandler.cpp | Yes | Add PLAYER_EVENT_ON_SELL_ITEM = 74 (Issue 403) |
| B007 | ale-unit-methods | mod-ale/*/UnitMethods.h, LuaFunctions.cpp | Yes | Add SetWalk, IsWalking, IsHostileTo, IsFriendlyTo (Issue 209) |
| B008 | mod-talent-bonus | modules/mod-talent-bonus | Yes | Link local module for compilation (Issue 205) |

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
**Issue:** 306 (was 324) - playerbots don't trigger PLAYER_EVENT_ON_LOGIN
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
**Issue:** 307 (was 325) - ALE doesn't support entry 0 wildcard for gameobject events
**Reason:** ALE validates gameobject templates before registration. Entry 0 fails validation since no template exists with that ID.

**Changes:**
1. Add `entry != 0 &&` check before `GetGameObjectTemplate` validation (2 locations)

```bash
# Idempotent check: only patch if wildcard not present
grep -q "entry != 0 && !eObjectMgr->GetGameObjectTemplate" "$FILE" || {
    sed -i 's/if (!eObjectMgr->GetGameObjectTemplate(entry))/\/\/ entry 0 = wildcard (Issue 307)\n                if (entry != 0 \&\& !eObjectMgr->GetGameObjectTemplate(entry))/g' "$FILE"
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

### B005: accuracy-level-cap

**Files:** `src/server/game/Entities/Unit/Unit.h`, `Unit.cpp`
**Issue:** 156 - Monster accuracy level cap
**Reason:** Cap level difference impact on hit/miss at ±3 levels for flatter combat curve.

**Changes:**
1. Add `ACCURACY_LEVEL_CAP` and `ACCURACY_SKILL_CAP` defines to Unit.h
2. Cap `levelDiff` in `MagicSpellHitResult()` at ±3
3. Cap `skillDiff` in `MeleeSpellMissChance()` at ±15 (3 levels × 5 skill/level)
4. Cap `skillBonus` in `RollMeleeOutcomeAgainst()` at ±15

**See:** `docs/patches/accuracy-level-cap.md` for detailed implementation.

### B006: ale-sell-item-hook

**Files:** `mod-ale/*/Hooks.h`, `LuaEngine.h`, `PlayerHooks.cpp`, `Handlers/ItemHandler.cpp`
**Issue:** 403 (was 150) - ALE sell item hook
**Reason:** Allow Lua scripts to react to vendor sales for treasure pool recycling.

**Changes:**
1. Add `PLAYER_EVENT_ON_SELL_ITEM = 74` to Hooks.h
2. Add `OnSellItem()` declaration to LuaEngine.h
3. Add `OnSellItem()` implementation to PlayerHooks.cpp
4. Add `sALE->OnSellItem()` calls to ItemHandler.cpp

**See:** `docs/patches/ale-sell-item-hook.md` for detailed implementation.

### B007: ale-unit-methods

**Files:** `mod-ale/*/UnitMethods.h`, `LuaFunctions.cpp`
**Issue:** 332 - ALE unit methods patch
**Reason:** Bot behaviors need walking animation and faction hostility checks.

**Changes:**
1. Add `SetWalk()`, `IsWalking()`, `IsHostileTo()`, `IsFriendlyTo()` to UnitMethods.h
2. Register methods in LuaFunctions.cpp

**See:** `docs/patches/ale-unit-setwalk.md` for detailed implementation.

### B008: mod-talent-bonus

**Files:** (symlink) `modules/mod-talent-bonus`
**Issue:** 120 - Talent points system
**Reason:** Server validates expected talent points on login; module adjusts count for bonus points.

**Changes:**
1. Create symlink from `modules/mod-talent-bonus/` to `source-beta/modules/mod-talent-bonus/`

**See:** `docs/patches/ale-calculate-talents-hook.md` for module details.

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
| E005 | dk-levelstats | acore_world_{profile} | No | Apply DK level 1-20 stats (issue 206) |

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

## PHASE_CONFIG: Post-Promote Runtime Tuning

Applied after `promote` has moved the validated shadow tree into the active
profile directory, but before the server is started. These patches operate on
`installed-files-{profile}/etc/*.conf` and on profile-scoped database tables
to encode the *opinions* that distinguish this server from a vanilla
AzerothCore install.

Each C-patch declares which profile(s) it applies to via the
`CONFIG_PROFILES` associative array. The orchestrator filters by the active
profile at run time, so the same patch directory serves all three profiles
with different selections.

| ID    | Name                     | Target                                                        | Profiles | Description |
|-------|--------------------------|---------------------------------------------------------------|----------|-------------|
| C001  | database-connections     | `installed-files-{profile}/etc/authserver.conf` + `worldserver.conf` | all      | Set MySQL connection strings (project-specific host/port/credentials/db names). |
| C002  | directory-paths          | `installed-files-{profile}/etc/worldserver.conf`              | all      | Set DataDir, LogsDir, SourceDirectory to project layout. |
| C003  | run-speed-80-percent     | `installed-files-{profile}/etc/worldserver.conf`              | all      | Set player run speed to 80% (slower, more deliberate exploration). |
| C004  | fall-damage-10x          | `installed-files-{profile}/etc/worldserver.conf`              | all      | Increase fall damage to 10x baseline (encourages careful movement). |
| C005  | exp-rate-2x              | `installed-files-{profile}/etc/worldserver.conf`              | all      | Double experience rate (faster testing/iteration cycles). |
| C006a | max-level-80             | `installed-files-{profile}/etc/worldserver.conf`              | alpha, release | Set MaxPlayerLevel = 80 (testing/baseline). |
| C006b | max-level-20             | `installed-files-{profile}/etc/worldserver.conf`              | beta     | Set MaxPlayerLevel = 20 (wow-chat-1 design). |
| C007a | starting-level-40        | `installed-files-{profile}/etc/worldserver.conf`              | alpha, release | Set StartPlayerLevel = 40 (testing/baseline). |
| C007b | starting-level-1         | `installed-files-{profile}/etc/worldserver.conf`              | beta     | Set StartPlayerLevel = 1 (default, made explicit). |
| C008  | gm-login-state           | `installed-files-{profile}/etc/worldserver.conf`              | all      | Set GM level on login (0 = player, 3 = admin). |
| C009  | instant-teleport-beta    | `installed-files-{profile}/etc/worldserver.conf`              | beta     | Reduce teleport cooldowns to zero for beta testing. |
| C010  | network-ports            | `installed-files-{profile}/etc/authserver.conf` + `worldserver.conf` | all      | Set custom non-default server ports (avoids local conflicts). |
| C011  | realmlist-setup          | `acore_auth.realmlist` (database row)                         | all      | Configure realm entry: address, port, flags. |

### Variant pattern (a/b)

`C006a`/`C006b` and `C007a`/`C007b` demonstrate a **per-profile variant**
pattern: same conceptual setting (max level, starting level), different
value for different profiles. Only one variant fires per build because each
declares non-overlapping `CONFIG_PROFILES` entries.

This pattern lets the C-patch tree document *what setting matters* (the
slot) and *what value applies* (the variant). When a new profile is added,
adding a `C006c` variant for it keeps history visible — old values aren't
overwritten, they're recorded as sibling patches.

### C001: database-connections

**Target:** `${INSTALL_DIR}/etc/authserver.conf`, `${INSTALL_DIR}/etc/worldserver.conf`
**Action:** Set MySQL connection strings to project-local credentials and profile-scoped database names

```bash
config_database_connections() {
    local auth="${INSTALL_DIR}/etc/authserver.conf"
    local world="${INSTALL_DIR}/etc/worldserver.conf"
    # Connection format: "host;port;user;pass;database"
    sed -i 's|^LoginDatabaseInfo .*=.*|LoginDatabaseInfo = "127.0.0.1;3307;ritz;menardi;acore_auth"|' "${auth}"
    # ... (worldserver: login/world/character db rows)
}
CONFIG_PROFILES[config_database_connections]="alpha release beta"
```

### C006b: max-level-20 (the variant example)

**Target:** `${INSTALL_DIR}/etc/worldserver.conf`
**Profile:** beta only
**Action:** Override MaxPlayerLevel to 20

```bash
config_max_level_20() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^MaxPlayerLevel.*=.*|MaxPlayerLevel = 20|' "${conf}"
}
CONFIG_PROFILES[config_max_level_20]="beta"
CONFIG_DESCRIPTIONS[config_max_level_20]="Max level 20"
```

The corresponding alpha/release variant (`C006a`) sets the same setting to
80 and declares `CONFIG_PROFILES[config_max_level_80]="alpha release"`. The
orchestrator picks exactly one based on `${PROFILE}` at run time.

### Note on overlap with E-patches

`E002` (config-database-paths) and `E003` (config-directory-paths) in the
PHASE_END registry overlap conceptually with `C001` and `C002` — both
write `.conf` files. The current distinction:

- **E-patches** write configs to the **shadow** tree, as part of setting up
  a buildable / validatable install.
- **C-patches** write configs to the **profile** tree, as part of applying
  this server's gameplay opinions after promote.

If the E-patch versions are sufficient (validation passes with the same
configs production will use), the C-patch versions become redundant. If the
shadow validation should test the *baseline* and production should run the
*tuned* configs, the split is meaningful. This is a design decision still
open — see issue 127 for the broader patch-system context.

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

---

## Unpatch System (Issue 127)

Each PHASE_BEGIN patch has a corresponding unpatch function that reverses its changes.
After build completes (success or failure), all patches are reverted to keep source clean.

### Unpatch Functions

| ID | Patch Function | Unpatch Function |
|----|----------------|------------------|
| B001 | `patch_B001_aoe_loot_item_namespace()` | `unpatch_B001_aoe_loot_item_namespace()` |
| B002 | `patch_B002_playerbots_ale_login_hook()` | `unpatch_B002_playerbots_ale_login_hook()` |
| B003 | `patch_B003_ale_gameobject_wildcard()` | `unpatch_B003_ale_gameobject_wildcard()` |
| B004 | `patch_B004_upstream_warning_fixes()` | `unpatch_B004_upstream_warning_fixes()` |
| B005 | `patch_B005_accuracy_level_cap()` | `unpatch_B005_accuracy_level_cap()` |
| B006 | `patch_B006_ale_sell_item_hook()` | `unpatch_B006_ale_sell_item_hook()` |
| B007 | `patch_B007_ale_unit_methods()` | `unpatch_B007_ale_unit_methods()` |
| B008 | `patch_B008_mod_talent_bonus()` | `unpatch_B008_mod_talent_bonus()` |

### Build Workflow

```bash
apply_patches_begin          # Apply all patches
trap 'unapply_patches_begin' EXIT  # Ensure revert on failure
do_build                     # Compile
trap - EXIT                  # Clear trap
unapply_patches_begin        # Revert all patches
```

### Design Principles

1. **Idempotent** - Both patch and unpatch are safe to run multiple times
2. **Self-contained** - Each patch/unpatch pair is independent
3. **Parallel-safe** - No file conflicts between patches
4. **Failure-safe** - Bash trap ensures cleanup on build failure
