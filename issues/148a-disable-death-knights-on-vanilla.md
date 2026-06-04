# 148a - Disable Death Knights on Vanilla

## Status
- Created: 2026-06-01
- Updated: 2026-06-02 — implementation simplified from SQL approach
  to single config-knob (`CharacterCreating.Disabled.ClassMask = 32`).
  Detail below.
- Phase: 1 (Foundation — profile model)
- Parent: 148 (vanilla profile)
- Priority: Medium (blocks shipping vanilla cleanly)

## Problem

The vanilla profile caps player level at 40 and targets Uldaman as the
endgame dungeon. The Death Knight class is in conflict with this on two
counts:

1. **Starting level mismatch.** A new DK spawns at level 55 in the
   Acherus scripted starting zone. On a level-40-cap server the
   character is already 15 levels over the cap before the player
   takes a single step. Capping a DK to 40 at creation means starting
   them at level 40 in Acherus, which the scripted zone wasn't built
   for.

2. **Acherus is its own content arc.** The DK starting experience is a
   self-contained ~1-hour scripted questline that delivers the
   character into Eastern Plaguelands. Skipping it leaves the
   character with no quest progression, missing key spells from the
   intro sequence, and standing in a zone where the world expects them
   to have arrived as a freshly-broken Knight of the Ebon Blade.
   Forcing the player through it on a 40-cap server delivers an
   experience tonally and mechanically disjointed from the rest of
   the ruleset.

Properly handling the DK class on vanilla means **skipping the Acherus
intro** and dropping the character into the world at level 1 (or
whatever the chosen start level is) with class abilities appropriate
to the level. **That requires modifying the WoW client** to bypass
the scripted intro zone, or at minimum to allow the character creation
flow to skip past the Acherus phasing. AzerothCore alone cannot make
the client willing to start a DK outside Acherus — the client hard-codes
that path.

The project does not yet have a client-patching pipeline. Until it
does, the only correct option is to **disable the DK class entirely
on vanilla** and revisit when the client patcher exists.

## Current Behavior

- Vanilla profile does not exist yet (this sub-issue presumes its
  arrival per parent 148).
- On a default AzerothCore install, DK is creatable provided the
  realm-level requirement is met (in 3.3.5a, having any character
  level 55+ on the same realm unlocks DK creation; the realmlist flag
  can also force-allow it).

## Intended Behavior

On the vanilla profile, the Death Knight class is unselectable at the
character creation screen. The class appears greyed out or hidden
depending on what the client respects; the intent is that no player
can create a DK character on a vanilla realm regardless of what other
characters they have.

On release, beta, and alpha the DK class remains available (those
profiles either don't have a level cap conflict or don't care).

## Disablement Mechanism — Config Knob (Plan A)

**AzerothCore ships with a built-in config knob that exactly solves
this case.** `CharacterCreating.Disabled.ClassMask` in
`worldserver.conf` is a bitmask where each bit disables one class:

| Class | Bit | Value |
|-------|-----|-------|
| Warrior | 0 | 1 |
| Paladin | 1 | 2 |
| Hunter | 2 | 4 |
| Rogue | 3 | 8 |
| Priest | 4 | 16 |
| **Death Knight** | **5** | **32** |
| Shaman | 6 | 64 |
| Mage | 7 | 128 |
| Warlock | 8 | 256 |
| Druid | 10 | 1024 |

Setting `CharacterCreating.Disabled.ClassMask = 32` for the vanilla
profile blocks Death Knight character creation at the server. The
client may still display the class as an option, but the create
packet will be rejected.

This documented config knob lives at
`source-beta/src/server/apps/worldserver/worldserver.conf.dist:1950-1965`
and confirmed working in 3.3.5a AzerothCore.

### Implementation: a single C-patch
Mirrors the existing C006c/C007c pattern. New file:
`config/patches/C015-vanilla-disable-deathknight.sh`. The patch
function `config_vanilla_disable_deathknight()` runs `sed` on
`worldserver.conf` to set `CharacterCreating.Disabled.ClassMask = 32`.
`CONFIG_PROFILES[config_vanilla_disable_deathknight]="vanilla"`.

**No SQL is needed. No database migration. No realm flag adjustment.
No new `sql/vanilla/` directory required for this sub-issue.** The
patch system already does profile-scoped config edits, and this is
exactly the use case it exists for.

## Disablement Mechanism — SQL Approach (Plan B, kept as fallback)

The original design considered an SQL approach: delete DK rows from
`playercreateinfo` and clear the DK bit on the realm flag. That
approach remains documented here as a fallback in case the config
knob ever proves insufficient (e.g. a server fork that ignores the
knob, or a client behavior we haven't anticipated). The SQL approach
is heavier but more thorough — it removes DK at the data layer
rather than the validation layer.

If Plan A ever stops working, the SQL Plan B is:

- `DELETE FROM playercreateinfo WHERE class = 6;` plus the same on
  `playercreateinfo_action`, `playercreateinfo_spell_custom`,
  `playercreateinfo_item` for class 6.
- Clear the realm-flag bit on `acore_auth_vanilla.realmlist.flag`
  for the vanilla realm.

Both layers vanilla-scoped via the C-patch system.

## Files To Update

### `sql/vanilla/` (new directory)
A vanilla-profile-only SQL load path, applied by `scripts/install`
when `PROFILE=vanilla`.

- `01-remove-dk-from-playercreateinfo.sql` — `DELETE FROM
  playercreateinfo WHERE class = 6;` (class 6 is Death Knight in
  3.3.5a). Also remove from `playercreateinfo_action`,
  `playercreateinfo_spell_custom`, and `playercreateinfo_item` for
  the same class for completeness.

### `scripts/install`
- Add a step in the vanilla branch of `get_profile_paths` (or its
  caller) that loads `sql/vanilla/*.sql` after the standard schema
  load, before bringing up the worldserver.

### `scripts/start-mysql` or a new `scripts/setup-realm`
- For the vanilla realm row, clear the DK availability bit on
  `realmlist.flag`. The exact bit value is documented in the
  AzerothCore wiki on `realmlist` columns; record the value here once
  confirmed so future readers don't have to look it up.

## Future Work — Re-Enabling DK on Vanilla

The class becomes eligible to return to vanilla once the project has:

1. **A client-patching pipeline.** Likely tracked under a separate
   top-level issue (the "big issue we're working on" referenced in
   the parent ticket discussion). The pipeline must be able to
   produce a custom client MPQ patch that skips the Acherus phasing
   for DK characters or rewrites the DK starting location.

2. **A redesigned DK starting experience compatible with a level-1
   start at the chosen world location** (Northshire? Coldridge?
   Goldshire? — decision deferred until the client pipeline is real).

3. **DK class spells re-tuned for low-level acquisition.** The DK
   spellbook is designed assuming a level-55 starting set. Bringing
   the class down to level 1 means most spells need to be either
   re-leveled (e.g. Death Strike unlocks at 10 instead of 55) or
   removed from the class kit entirely.

When all three are in place, this sub-issue gets re-opened to remove
the disablement.

## Implementation Steps

1. Confirm the DK class ID in `playercreateinfo` for AzerothCore 3.3.5a
   (expected: 6).
2. Write `sql/vanilla/01-remove-dk-from-playercreateinfo.sql`.
3. Hook the vanilla SQL load path into `scripts/install`.
4. Identify the DK flag bit on `realmlist.flag` and write the
   clear-the-bit step into the realm-setup flow.
5. Boot a vanilla worldserver, attempt to create a DK character,
   verify rejection both visually (greyed out class) and at the
   server (rejection packet on attempted create).
6. Document the disablement in `docs/profiles/vanilla.md` (or the
   equivalent profile documentation page if one exists).

## Open Questions

- Is there a single AzerothCore config option (worldserver.conf knob)
  that disables a class outright, without touching SQL? If so, prefer
  it; the SQL-level deletion is fine but a config knob would be cleaner.
- Does removing rows from `playercreateinfo` cause any startup
  warnings or break unrelated bot-creation paths (e.g. does
  mod-playerbots try to create DK bots and crash when it can't)?
  Verify during step 5.
- What level should a re-enabled DK start at when the client patcher
  arrives — 1 (full leveling experience), 10 (skip the slowest early
  game), or the chosen world's natural starting level for that race?
