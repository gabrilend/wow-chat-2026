# 145 - Playerbots Compile-Fix Patches B009 and B010

## Status
- Created: 2026-05-14
- Phase: 1 (Foundation — patch system)
- Priority: High (blocks release rebuild — mod-playerbots cannot compile without these)

## Problem

mod-playerbots, against modern AzerothCore source, fails to compile due to two
type-related mismatches between the module and the core. The patches that fix
each were written and saved as `patches/B009-playerbots-equipment-slots-enum.sh`
and `patches/B010-playerbots-arena-type-none.sh`, but never registered in
`patches/patches.sh` `PHASE_BEGIN_PATCHES`. Without registration, the patch
system never applies them during `compile`, so the build fails (or — silently
worse — produces a binary missing playerbot functionality).

Sister patches B011 through B019 (also playerbots compatibility fixes) were
registered correctly when they were added. B009 and B010 fell through the gap.

### B009 — Equipment Slots Enum Underlying Type Mismatch

mod-playerbots forward-declares:
```cpp
enum EquipmentSlots : uint32;
```

AzerothCore core defines:
```cpp
enum EquipmentSlots { ... };  // no explicit underlying type
```

C++ requires forward declarations to match the underlying type. The patch adds
`: uint32` to the core enum definition, aligning it with the forward
declaration.

### B010 — Missing ARENA_TYPE_NONE Constant

mod-playerbots references `ARENA_TYPE_NONE`:
```cpp
if (type != ARENA_TYPE_NONE) { ... }
```

But the core `ArenaType` enum only defines `ARENA_TYPE_2v2`, `_3v3`, `_5v5` —
no `NONE` value. The patch adds `ARENA_TYPE_NONE = 0` to the enum, giving
mod-playerbots the sentinel value it expects.

## Current Behavior

- B009 and B010 patch scripts exist on disk in `patches/`
- Both are untracked in the parent git repo
- Neither is listed in `PHASE_BEGIN_PATCHES` for any profile
- A clean rebuild attempting to compile mod-playerbots fails

## Intended Behavior

- Both patch files are tracked in the parent repo
- Both are registered in `PHASE_BEGIN_PATCHES` for `release` and `beta`
- They are *not* registered for `alpha` (alpha uses mod-eluna, no playerbots)
- `compile --force` runs them as part of the standard patch sequence
- After build, `scripts/verify-build` confirms worldserver contains
  playerbot symbols

## Implementation Steps

1. Add `B009 B010` to the release profile patch list in
   `patches/patches.sh:PHASE_BEGIN_PATCHES`.
2. Add `B009 B010` to the beta profile patch list in the same array.
3. Stage the previously-untracked patch files `B009-*.sh` and `B010-*.sh`.
4. Commit the three files together (this issue).
5. Verify by triggering `compile --force` and confirming the patch system
   reports both as applied (look for `[B009] Applied:` and `[B010] Applied:`
   in build log).
6. Run `scripts/verify-build` post-rebuild; the "worldserver references
   playerbots" check should pass.

## Affected Files

- `patches/B009-playerbots-equipment-slots-enum.sh` (newly tracked)
- `patches/B010-playerbots-arena-type-none.sh` (newly tracked)
- `patches/patches.sh` (PHASE_BEGIN_PATCHES array update)

## Related Issues

- **127** patch-system-improvements — established the data-driven
  `PHASE_BEGIN_PATCHES` array that this issue adds entries to.
- **135** release-profile-build-fixes — earlier work that exposed the need for
  release-profile module/patch declarations.
- **137** shadow-conf-path-baked-into-binary — adjacent work in the same
  upcoming rebuild.
- **136** canonical-profile-definitions — the model that says release must
  include mod-playerbots.

## Validation

After applying:
```bash
./scripts/compile --force --profile release
grep "B009\|B010" tmp/build-release.log
# Expected: "[B009] Applied: patch_B009_playerbots_equipment_slots_enum"
#           "[B010] Applied: patch_B010_playerbots_arena_type_none"

./scripts/verify-build
# Expected: "PASS worldserver references playerbots"
```

## Notes

This is a discovered-during-rebuild-prep issue, not a new design idea. It came
out of the systematic patch-registration audit done before triggering a
`compile --force`. The pattern (write a patch, save the file, forget to
register it in the orchestration array) is one to watch for — propose adding
a check in patches.sh that warns about un-registered `patches/B*.sh` files at
build-time, so the gap is loud rather than silent.
