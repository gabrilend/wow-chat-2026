# 148l - Vanilla Mount Level Requirements

## Status
- Created: 2026-06-04
- Phase: 1 (Foundation — profile model; see 148 parent)
- Parent: 148 (vanilla profile)
- Priority: Low (vanilla-flavor; doesn't block launch)

## Problem

The vanilla profile aims for the WoW Classic feel where ground travel
is slow and mounts are an earned milestone. AzerothCore ships with the
WotLK-adjusted riding levels (Apprentice 20 / Journeyman 40 / Expert 60),
which make mounts trivially accessible long before a Classic-era player
would have seen one. The vanilla profile already restricts the world
elsewhere (no flight paths per 148i, no class-trainer hand-holding per
148j, custom starting equipment per 148h); mount accessibility should
match the same era to keep the feel consistent.

For Classic / vanilla the canonical thresholds were:

| Skill | Speed bonus | Required level | Cost (Classic) |
|---|---|---|---|
| Apprentice Riding | +60% mount speed | 40 | ~35g for the skill |
| Journeyman Riding | +100% mount speed | 60 | ~900g for the skill |

The vanilla profile caps the player at level 40 (per 148 / C006c), which
means under these thresholds **only the +60% mount is reachable, and
only at max level**. That's an intended consequence: the slow mount
becomes the level-cap reward, and the +100% epic mount is left as a
glimpsed-but-unreachable target — same vibe as Classic before someone
had grinded to 60.

## Current Behavior

Vanilla profile inherits AzerothCore's WotLK riding levels:

| Skill | Spell ID | AC default reqlevel |
|---|---|---|
| Apprentice Riding | 33388 | 20 |
| Journeyman Riding | 33391 | 40 |
| Expert Riding | 34090 | 60 (flying — vanilla irrelevant) |
| Artisan Riding | 34091 | 70 (flying — vanilla irrelevant) |

A vanilla character can train Apprentice Riding the moment they hit
level 20 — half the vanilla cap — and Journeyman at level 40, exactly
at the cap. The 100%-speed mount sitting at the level cap collapses the
"epic mount as long-term goal" feel; the 60%-speed mount at level 20 is
too early to be a milestone.

## Intended Behavior

On the vanilla profile, the trainer's `reqlevel` for the two ground
riding skills is reset to Classic values:

| Skill | Spell ID | Vanilla reqlevel |
|---|---|---|
| Apprentice Riding | 33388 | 40 |
| Journeyman Riding | 33391 | 60 |

Effects under vanilla's MaxPlayerLevel = 40 cap:

- The +60% mount becomes the level-cap reward (reachable only at 40).
- The +100% mount is permanently unreachable on a vanilla character
  (would need level 60). Trainers will display it but reject the train
  request. This is intentional — it's the unreached horizon.

Release, beta, and alpha profiles retain AzerothCore's WotLK defaults
(those profiles either cap above 40 or don't care).

## Disablement Mechanism — Trainer reqlevel (Plan A)

`npc_trainer.reqlevel` is the per-(trainer, spell) gate that AC's
trainer-handler checks before offering or accepting a train request.
Two `UPDATE` rows on this table push the two riding skills to their
Classic levels:

```sql
UPDATE `npc_trainer` SET `reqlevel` = 40 WHERE `SpellID` = 33388;
UPDATE `npc_trainer` SET `reqlevel` = 60 WHERE `SpellID` = 33391;
```

Lives at the data layer; AC's worldserver picks it up on next boot
without code changes. Mirrors the pattern E007/E008/E009/E010 use for
other vanilla-profile data tweaks.

## Disablement Mechanism — DBC patching (Plan B, fallback)

If the trainer-reqlevel approach proves insufficient (e.g. a future AC
release reads the spell's intrinsic level from `Spell.dbc` and ignores
the trainer's gate), the fallback is to patch the DBC entries for the
two spells:

- `Spell.dbc` row for SpellID 33388: `SpellLevel = 40`, `BaseLevel = 40`
- `Spell.dbc` row for SpellID 33391: `SpellLevel = 60`, `BaseLevel = 60`

DBC patching is heavier (requires a client-side .mpq distribution and
matching server-side override), so reserve for the case where Plan A
doesn't hold.

## Files To Add

### `sql/vanilla/db_world.src/05-mount-level-requirements.apply.sql`
The vanilla-scoped UPDATE statements wrapped in the project's apply-
form template (MARKER_E018_APPLY header so the unpatch idiom holds).
The revert form restores AC defaults (20 / 40).

### `patches/E-patches.sh`
A new `patch_E018_vanilla_mount_level_requirements` function following
the post-refactor profile-anonymous shape: paths use `${PROFILE}` and
the DB name comes from `_profile_db_name acore_world`. The dispatcher
entry in `patches.sh:PHASE_END_PATCHES["vanilla"]` gets `E018` appended.

## Files To Update

### `patches/patches.sh`
Add `E018` to `PHASE_END_PATCHES["vanilla"]` so the dispatcher fires
the patch on vanilla compile/install runs only.

## Implementation Steps

1. Confirm the riding-skill spell IDs on this AC build (33388, 33391
   are the WotLK 3.3.5a canonical IDs; spot-check against
   `acore_world_vanilla.npc_trainer` to confirm trainer rows reference
   them).
2. Verify a baseline vanilla trainer offers Apprentice Riding at
   level 20 today (smoke test before the patch).
3. Write `sql/vanilla/db_world.src/05-mount-level-requirements.apply.sql`
   with the apply-form INSERT (or UPDATE in this case) plus the marker
   header. The revert section restores 20 / 40.
4. Add the E018 handler to `patches/E-patches.sh` mirroring E007's
   shape post-refactor.
5. Append `E018` to `PHASE_END_PATCHES["vanilla"]` in `patches/patches.sh`.
6. Trigger an install/compile to apply, then boot the worldserver and
   verify:
   - Apprentice Riding offered at level 40 (rejected at 39).
   - Journeyman Riding visible in trainer list but rejected (under cap).
7. Document the design choice in `docs/profiles/vanilla.md` next to
   the level-cap section so a future reader understands why epic mount
   is permanently unreachable on vanilla.

## Future Work

- If the vanilla cap is ever raised above 40, the Journeyman threshold
  needs to be revisited — at cap 60 it becomes reachable again, and at
  cap 70 the flying riding skills would also need review.
- The 35g / 900g classic gold costs are a separate dimension. AC's
  trainer cost lives in `npc_trainer.MoneyCost`. If we want the full
  Classic mount economy (where mount cost is a major progression
  milestone), update `MoneyCost` to 350000 / 9000000 (copper) for
  33388 / 33391. Out of scope for this sub-issue; track separately.

## Open Questions

- Are there race-specific mount training spells (e.g. tauren plainsrunning
  vs. mount training) that also need level adjustment? Spot-check the
  trainer list for spells in the 33388/33391 family.
- Does the playerbots module respect `npc_trainer.reqlevel` when
  auto-training mounts on bots? Verify that bots above level 40 don't
  end up with Journeyman Riding from some other code path (e.g. AI
  direct spell-learn that bypasses trainers).
- Does the level-50 horse breeder questline (if it still exists in
  3.3.5a content) collide with these thresholds? Vanilla profile may
  already disable that quest via the empty-world treatment, but worth
  confirming.
