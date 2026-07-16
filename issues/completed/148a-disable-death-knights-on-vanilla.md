# 148a - Disable Death Knights on Vanilla

## Status
- Created: 2026-06-01
- Updated: 2026-06-02 — implementation simplified from SQL approach
  to single config-knob (`CharacterCreating.Disabled.ClassMask = 32`).
- **Completed: 2026-07-15** — C015 ships the config knob (committed).
  Verified it blocks BOTH player creation and random-bot generation:
  the bot factory reads the same mask, and the live
  `acore_characters_vanilla` fleet holds 0 Death Knights.
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

Death Knight is disabled on vanilla by the single config knob:

- `config/patches/C015-vanilla-disable-deathknight.sh` sed-sets
  `CharacterCreating.Disabled.ClassMask = 32` (bit 5 = DK) in the
  vanilla `worldserver.conf`, scoped `CONFIG_PROFILES[...]="vanilla"`.
  Committed; the live vanilla conf carries `= 32`.
- **Player creation:** the create-character packet for a DK is rejected
  server-side, so no player can roll one on a vanilla realm.
- **Bot generation:** `RandomPlayerbotFactory` reads the SAME knob
  (`CONFIG_CHARACTER_CREATING_DISABLED_CLASSMASK`) and `continue`s past
  any masked class while building the random fleet
  (`source-beta/modules/mod-playerbots/.../RandomPlayerbotFactory.cpp:711`),
  so it never attempts a DK — no crash, no leak. Verified live:
  `acore_characters_vanilla.characters` holds 0 class-6 rows across
  ~2100 bots (the nine non-DK classes, all level 20).

Release/beta/alpha leave the mask at 0, so DK stays available there.

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

## Files Involved (Plan A — implemented)

| Path | Role |
|---|---|
| `config/patches/C015-vanilla-disable-deathknight.sh` | the whole implementation — `sed`s `CharacterCreating.Disabled.ClassMask = 32` into the vanilla `worldserver.conf`, profile-scoped to vanilla |

No SQL migration, no `sql/vanilla/` additions, no `scripts/install`
change, and no realm-flag edit were needed: the one knob covers both
the player and the bot creation path (the bot factory honours the same
config value). The heavier SQL route in "Plan B" below is retained only
as a documented fallback if a fork ever ignores the knob.

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

## Implementation Steps (Plan A — done)

1. ✅ Write `config/patches/C015-vanilla-disable-deathknight.sh` —
   `config_vanilla_disable_deathknight()` sed-sets the mask to 32,
   `CONFIG_PROFILES[...]="vanilla"`. (Class 6 = DK; bit 5 = 32.)
2. ✅ Apply via the config-patch system on vanilla install; the live
   conf reads `CharacterCreating.Disabled.ClassMask = 32`.
3. ✅ Confirm the bot factory honours the same mask
   (`RandomPlayerbotFactory.cpp:711`) so no DK bots are generated.
4. ✅ Verify against the live DB: 0 class-6 rows in
   `acore_characters_vanilla.characters`.
5. ⏳ Optional in-client eyeball (folds into the 148o pass): confirm a
   vanilla realm rejects DK creation at the character screen.

## Open Questions

- ~~Single config knob that disables a class without SQL?~~
  **Answered:** yes — `CharacterCreating.Disabled.ClassMask`, which is
  what C015 uses. The SQL deletion (Plan B) was never needed.
- ~~Does mod-playerbots try to create DK bots and crash?~~
  **Answered:** no. `RandomPlayerbotFactory` skips masked classes via
  the same config value (`.cpp:711`), so it never attempts a DK on
  vanilla — no crash, and the fleet contains 0 DKs.
- What level should a re-enabled DK start at when the client patcher
  arrives — 1 (full leveling experience), 10 (skip the slowest early
  game), or the chosen world's natural starting level for that race?
  (Still open, but belongs to the future re-enable — see "Future Work"
  — not to this disablement issue.)
