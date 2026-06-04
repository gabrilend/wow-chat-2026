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

**The source tree is a build artifact.** `source-{profile}/` is cloned
from upstream by `scripts/redownload-source` and gitignored (line 17 of
the project `.gitignore`, pattern `source*/`). It is never tracked, never
committed. The B-patches in PHASE_BEGIN are the *only* mechanism by
which the source acquires our customizations, and they revert after
every build to keep the tree pristine. Any modification to source code
that survives across builds is a bug — either an unapply that failed,
or a manual edit that should have been a patch. See issue 136's
"Source Tree Is A Build Artifact" section for the canonical
description of this design.

| Phase         | Tier        | When                                            | Target                                              | Purpose |
|---------------|-------------|-------------------------------------------------|-----------------------------------------------------|---------|
| PHASE_BEGIN   | B-patches   | Before cmake/make, on source tree               | `source-{profile}/src/...` and `source-{profile}/modules/...` | Make upstream code compile cleanly against our profile (fix bugs, add hooks, silence warnings). Reverted after build to keep source tree clean. |
| PHASE_END     | E-patches   | After cmake install to shadow, before validate  | `installed-files-shadow/{etc,bin,...}`              | Set up the just-installed shadow tree: write `.conf` files from `.dist`, create log/symlink dirs, link Lua scripts, apply per-profile SQL. |
| PHASE_CONFIG  | C-patches   | After promote, before server start              | `installed-files-{profile}/etc/*.conf`              | Apply gameplay-tuning opinions (max level, exp rate, run speed, fall damage, port numbers, realmlist setup) on the live profile config tree. |

**The separation matters.** Each tier targets a **different state of the
build tree at a different chronological moment**:

- B-patches edit upstream code we don't own; the source tree exists, the
  binary doesn't yet. Must revert so the source stays clean.
- E-patches set up the shadow install tree; binaries exist in shadow, the
  profile dir may not. Validation depends on E-patches having run.
- C-patches modify the live profile config tree; the profile dir exists
  with live deployment paths and database names. Some C-patches encode
  gameplay opinions (max level, exp rate); **others are strictly required**
  — they rewrite paths and credentials in the profile configs that
  couldn't be known until promote placed the files in the profile dir.

The chronological split is the primary reason for three tiers, not two. A
secondary benefit: putting C-patches after validate means a botched gameplay
opinion can't break the validate gate.

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

| ID   | Name                                    | Target                                                  | Description |
|------|-----------------------------------------|---------------------------------------------------------|-------------|
| B001 | aoe-loot-item-namespace                 | mod-aoe-loot/src/aoe_loot.cpp                           | Fix `Item` vs `WorldPackets::Item` ambiguity |
| B002 | playerbots-ale-login-hook               | mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp           | Trigger PLAYER_EVENT_ON_LOGIN for bots |
| B003 | ale-gameobject-wildcard                 | mod-ale/src/LuaEngine/LuaEngine.cpp                     | Enable entry 0 as wildcard for gameobject events |
| B004 | upstream-warning-fixes                  | mod-playerbots/*, mod-ale/*                             | Fix ~695 compiler warnings in upstream modules |
| B005 | accuracy-level-cap                      | src/server/game/Entities/Unit/*                         | Cap level diff for hit/miss at ±3 |
| B006 | ale-sell-item-hook                      | mod-ale/*, Handlers/ItemHandler.cpp                     | Add PLAYER_EVENT_ON_SELL_ITEM = 74 |
| B007 | ale-unit-methods                        | mod-ale/*/UnitMethods.h, LuaFunctions.cpp               | Add SetWalk, IsWalking, IsHostileTo, IsFriendlyTo |
| B008 | mod-talent-bonus                        | modules/mod-talent-bonus                                | Link local module for compilation |
| B009 | playerbots-equipment-slots-enum         | mod-playerbots                                          | Forward-declare `enum EquipmentSlots : uint32;` |
| B010 | playerbots-arena-type-none              | mod-playerbots                                          | `if (type != ARENA_TYPE_NONE)` enum comparison fix |
| B011 | ale-resurrect-signature                 | mod-ale                                                 | Reconcile `bool&` vs `bool` mismatch with current core |
| B012 | player-equipment-slot-sign              | core                                                    | Fix int vs `EquipmentSlots` sign-compare warning |
| B013 | playerbots-logical-op-parentheses       | mod-playerbots                                          | `&&` within `||` parens (-Wlogical-op-parentheses) |
| B014 | playerbots-switch-enum-default          | mod-playerbots                                          | Missing case values for `WSBotStrategy` (-Wswitch) |
| B015 | playerbots-implicit-float-conversion    | mod-playerbots                                          | int→float value-change warning |
| B016 | playerbots-constructor-reorder          | mod-playerbots                                          | Field-init order (-Wreorder-ctor) |
| B017 | playerbots-unused-variables             | mod-playerbots                                          | -Wunused-variable cleanup |
| B018 | playerbots-sign-compare                 | mod-playerbots                                          | Signed/unsigned compare warnings |
| B019 | playerbots-unused-parameter             | mod-playerbots                                          | -Wunused-parameter cleanup |
| B020 | ale-event-removeevent-lock              | mod-ale                                                 | Add LOCK_ALE around `ALEEventProcessor::RemoveEvent` |
| B021 | playerbots-misc-warnings                | mod-playerbots                                          | Catch-all bundle for residual one-off warnings |
| B022 | runtime-conf-dir-override               | core                                                    | Runtime `--conf-dir` override (avoids cmake-baked path) |
| B023 | ale-formatquery-lifetime                | mod-ale                                                 | Fix variadic format-arg lifetime in FormatQuery |
| B024 | symmetric-aggro-radius                  | core                                                    | Make `Creature::GetAttackDistance` symmetric |

Per-patch source of truth lives in `patches/B###-*.sh` — each script's
header comments document the upstream symptom, the matched pattern, and
the inverse-unpatch operation. Detailed write-ups for the older B-patches
(B001–B008) follow below; the B009+ family is generally one-warning-at-a-time
and is documented in the scripts themselves rather than duplicated here.

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

## PHASE_END: Post-Compile Setup

Reserved for E-patches that set up the just-installed shadow tree (write
`.conf` files from `.dist`, create log dirs, link Lua scripts, apply
per-profile SQL). **No E-patches are currently active** — the equivalent
work happens inside `scripts/generate-configs`, `scripts/install`, and the
C-patches that run after promote. When the responsibilities split off
into discrete idempotent patches they will be registered here as
`patches/E###-*.sh` and indexed in this table.

---

## PHASE_CONFIG: Post-Promote Runtime Tuning

Applied after `promote` has moved the validated shadow tree into the active
profile directory, but before the server is started. These patches operate on
`installed-files-{profile}/etc/*.conf` and on profile-scoped database tables.

They serve **two purposes** that share a target and a timing:

- **Required path/credential rewriting.** Configs need to know which profile
  is live (which database to talk to, which directory holds logs, where the
  data files are). These values couldn't be written before promote because
  the profile dir didn't exist yet. C001 (database connections) and C002
  (directory paths) are in this category — without them the server can't
  find its world.
- **Gameplay opinions.** Knobs that distinguish this server from a vanilla
  AzerothCore install: max level, exp rate, run speed, fall damage, port
  numbers, realmlist setup. C003 through C011 are tuning, not survival.

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

### Resolved overlap with E-patches

`E002` (config-database-paths) and `E003` (config-directory-paths) in the
PHASE_END registry overlap conceptually with `C001` and `C002` — both
write `.conf` files with paths and credentials.

**The resolution:** keep both tiers, write full and valid configs at every
stage, and let the C-patches update only the values that need to be
profile-aware after promote. No stripped-down validate-only stubs — the
configs in shadow during validation are real, complete configs. The
C-patches' job is narrower than overwriting the whole file: **they
specifically update credentials and file paths** that need to point at
the live profile installation.

What this means concretely:

- **E002 writes valid database connection strings to shadow.** Validation
  can actually connect. These may use the same credentials and DB names
  that production will use (release/beta share infrastructure, so the
  shadow validate uses the same DB host/port/credentials as the eventual
  live release server reads back at startup).
- **C001 updates the database connection strings post-promote** if the
  profile needs different credentials, ports, or DB names than what
  E002 wrote. For release/beta this is often a no-op (values match);
  for alpha the C001 update is load-bearing because alpha runs against
  a separate MySQL on a different port with different DBs.
- **E003 writes valid directory paths to shadow** (pointing at shadow
  dirs for the validate run).
- **C002 updates directory paths post-promote** to point at the
  profile-correct dirs (`installed-files-{profile}/` instead of shadow).

The chronology principle holds: each tier writes the configs that make
sense for the state of the build tree at that moment. C-patches are not
redundant with E-patches — they're the **delta** between "valid for
shadow validation" and "valid for live profile run."

---

## Adding New Patches

1. Assign the next free ID in the appropriate tier (`B###`, `E###`, `C###`).
   `C###` variants for per-profile splits use `Cnnna` / `Cnnnb` (see
   C006a/C006b).
2. Create `patches/<ID>-<name>.sh` (B-patch) or `config/patches/<ID>-<name>.sh`
   (C-patch). The script header is the source of truth: what upstream symptom
   it addresses, the matched pattern, the inverse-unpatch sed.
3. Add a one-line row to the appropriate table in this registry.
4. Include an idempotent guard (grep before sed, check before create) so the
   patch is safe to re-run.
5. B-patches must ship with an exact-inverse unpatch operation so the source
   tree round-trips cleanly. Multi-line insertions should be wrapped in
   `// {{{ B###-name ... // }}} B###-name` marker comments; the unpatch
   then range-deletes by marker.

---

## Patch Orchestration

`scripts/apply-patches` iterates the `patches/` and `config/patches/`
directories in numeric order. Each script self-registers via the
conventions in `patches/patches.sh` (B-patches) and the corresponding
C-patch registry. B-patches apply pre-compile, run their compile, and
unapply via a trap so the source tree stays pristine. C-patches apply
after promote, against the live profile's `installed-files-{profile}/etc/`.

### Design Principles

1. **Idempotent** — apply and unapply are safe to re-run.
2. **Self-contained** — each patch/unpatch pair is independent.
3. **One-to-one targeting** — N upstream errors = N anchored apply seds +
   N anchored inverse seds. Broad seds corrupt clean source.
4. **Failure-safe** — bash traps ensure cleanup on build failure.
