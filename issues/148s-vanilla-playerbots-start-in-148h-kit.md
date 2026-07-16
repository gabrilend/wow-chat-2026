# 148s - Vanilla Playerbots Start in the 148h Starter Kit

## Status
- Created: 2026-07-13
- Phase: 1 (Foundation — vanilla profile)
- Parent: 148 (vanilla profile)
- Related: 148h (the starter kit itself), C014 / balance-updates
  (bot progression 20→40 — this is the "start with the starting gear"
  half of that decision), the patch system (`patches/patches.sh`,
  `docs/patches/`)

## Problem

Vanilla random bots do not wear the 148h starter kit. mod-playerbots'
`PlayerbotFactory` self-gears every bot with randomized,
level-appropriate items on init and on level-up
(`InitEquipment` / `IncrementalGearInit`), so a fresh level-20 bot
comes up in generated greens, not the class's white 148h kit.

The user's directive (2026-07-13): **bots should start in the 148h
starting gear** and upgrade as they climb (the "upgrade as they go"
half is already handled by C014's `IncrementalGearInit=1` /
`AutoUpgradeEquip=1`). So only the *starting* gear needs changing: a
newly-initialized level-20 bot should be equipped from the 148h kit
instead of random gear.

There is no config knob for this — `PlayerbotFactory` always self-gears
— so it requires a **source patch** to the module. Per project policy
that patch goes through the **patch system** (a B-patch that edits the
module source at build time + a `docs/patches/` patch doc), never a raw
in-place edit, so it survives the upstream update we still owe.

## Intended Behavior

- A random bot initialized at level 20 on the **vanilla** profile is
  equipped from the 148h kit for its (race, class) — the same
  `playercreateinfo_item` rows (`Note LIKE 'vanilla-148h-%'`) players
  get — instead of `PlayerbotFactory`'s randomized starting gear.
- As the bot levels past 20 it upgrades normally (drops / AH / the
  existing gear knobs) — the kit is a *starting* state, not a pin.
- **Vanilla only.** Release/beta bots keep stock factory gearing; those
  profiles have no 148h kit.
- Bots already above level 20 are not reset back into the kit — only
  the initial level-20 gearing is affected.

## Mechanism — where and how

- **Entry point:** `PlayerbotFactory`'s equipment init
  (`source-beta/modules/mod-playerbots/src/Bot/Factory/PlayerbotFactory.cpp`
  — the gear path around `InitEquipment` / `InitSkills` /
  `InitAvailableSpells`, ~line 610-640, called from `Randomize`).
- **Change:** when the bot's target level is the vanilla start level
  (20) and the profile is vanilla, load the 148h kit rows for
  `(race, class)` and equip those, in place of the random-gear pass.
  Reuse the same equip ordering the ALE hook proved out (containers,
  then equipment, then the starter-weapon proficiency/skill — see 148h;
  note the proficiency-pretrain dependency, since off-default kit
  weapons need the proficiency grant to equip).
- **Vanilla scoping:** the module binary is shared (all profiles build
  from `source-beta`), so the kit-gearing must be gated at runtime, not
  compile-time. Options to weigh: gate on the world DB name ending in
  `_vanilla`, or on a new `AiPlayerbot.*` config flag written only into
  vanilla's `playerbots.conf` by a C-patch. The config-flag route is
  cleaner and matches the C-patch pattern (see C014).

## Patch-system packaging

- **B-patch** (`patches/patches.sh` `PHASE_BEGIN_PATCHES["vanilla"]`
  + a new `patches/B0##-*.sh`) that seds the change into
  `PlayerbotFactory.cpp` at build time, idempotently, matched by
  context not line number.
- **Patch doc** in `docs/patches/` describing the change exactly (file,
  context, before/after) so it can be re-applied after an upstream
  mod-playerbots update — per the "Documentation as Code" policy in
  CLAUDE.md.
- If a config flag is chosen for vanilla scoping, add the C-patch that
  writes it.

## Current Behavior

The source change is written, packaged, and dry-run-verified — pending
only a vanilla rebuild + in-world check:

- `patches/B025-playerbots-vanilla-starter-kit.sh` injects a branch at
  the top of `PlayerbotFactory::InitEquipment` that, on the initial
  (non-incremental) level-20 gearing, equips the 148h kit for the bot's
  (race, class) via `StoreNewItemInBestSlots` and returns before the
  random-gear pass. Reuses the same equip helper the `level < 5`
  starter-outfit path already uses.
- Registered in `PHASE_BEGIN_PATCHES["vanilla"]` (`patches/patches.sh`)
  with a `patch_needs_applying_B025` witness.
- Spec: `docs/patches/playerbot-vanilla-starter-kit.md`.
- Verified without a build: the block lands in the right place, is
  idempotent (re-apply leaves one copy), and its unpatch round-trips
  `PlayerbotFactory.cpp` byte-for-byte back to upstream HEAD.

Until the vanilla worldserver is rebuilt through the patch pipeline, the
running bots still wear the factory's randomized gear.

## Implementation Steps

- [x] Vanilla-scoping mechanism decided: **self-scope on the kit data**,
      not a config flag. The branch queries the 148h kit rows, which exist
      only on vanilla, so release/beta fall through untouched — no config
      flag, no C-patch, no DB-name string check needed.
- [x] Insertion point identified: top of `PlayerbotFactory::InitEquipment`,
      after the incremental guard, before the `level < 5` outfit path.
- [x] Source change written: query the 148h kit for (race, class) and
      equip via `StoreNewItemInBestSlots` when `!incremental && level == 20`,
      returning to skip the random pass.
- [x] Packaged: `patches/B025-playerbots-vanilla-starter-kit.sh` +
      `PHASE_BEGIN_PATCHES["vanilla"]` registration + witness +
      `docs/patches/playerbot-vanilla-starter-kit.md`; verified idempotent
      and round-trip-clean in a source dry-run.
- [ ] Rebuild the vanilla worldserver via the patch pipeline; confirm the
      B-patch applies and the module compiles. *(owner: build machine)*
- [ ] Validate in-world: reset the bot fleet, inspect a fresh level-20 bot
      per a few race/class pairs — confirm it wears the 148h kit, that an
      off-default kit weapon (e.g. a Tauren Warrior polearm) equips, and
      that it upgrades as it levels. Confirm release/beta bots are
      unaffected.

## Open Questions

- ~~Config flag vs DB-name check for vanilla scoping.~~ **Resolved:**
  neither — the branch self-scopes on the presence of the 148h kit rows,
  which exist only on vanilla. No config plumbing, no DB-name string.
- Should party-added alt-bots (a player's own alts) also be forced into
  the kit, or only random bots? (Alts already went through player
  creation, so they may already have the kit — verify before forcing.)
