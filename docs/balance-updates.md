# Balance Updates

Append-only log of knob/lever tweaks — small numerical adjustments to
gameplay constants that change the feel of the world without warranting a
full issue file. Each entry says **what** changed, **why**, and points at
the patch or file that holds the actual value.

New entries go at the bottom. Don't edit or remove prior entries; the
chronology is the point.

---

## 2026 — Initial backfill of C-patch tuning values

The following C-patches encode the current set of "what makes this server
feel different from vanilla" knobs. They are listed here for visibility
even though the patches themselves predate this log.

### `C003-run-speed-80-percent`
Player and NPC run speed reduced to 80% of vanilla.
**Why:** Slower movement makes the world feel larger and gives ambush
spawns time to matter. Encounters become deliberate rather than ridden-past.

### `C004-fall-damage-10x`
Fall damage multiplied by 10×.
**Why:** Falling should be a real hazard, not a shortcut. Encourages
careful pathing and gives terrain meaningful danger.

### `C005-exp-rate-2x`
Experience rate doubled.
**Why:** With max level 20 (per `C006b`), the leveling curve is short by
design. 2× keeps testing/iteration cycles tight and matches the "every
level matters" pacing.

### `C006a` / `C006b` — Max level (per profile)
- `release` / `alpha`: 80 (vanilla baseline)
- `beta`: 20 (the wow-chat-1 design)

**Why:** The release profile keeps a familiar baseline so playerbots and
content behave normally. Beta is the experimental profile where the
roguelike-survival shape lives — short levels, dense talent gain, every
level a real decision.

### `C007a` / `C007b` — Starting level (per profile)
- `release` / `alpha`: 40 (testing baseline — skip the empty-zones grind)
- `beta`: 1 (default; made explicit so it can't drift)

### `C008-gm-login-state`
Sets GM level on login per profile.
**Why:** Beta needs admin tools on by default; release ships players in
as players.

### `C009-instant-teleport-beta` (beta only)
Teleport cooldowns reduced to zero.
**Why:** Iteration speed during beta testing. Not a player-facing tweak.

### `C010-network-ports`
Custom non-default auth/world ports.
**Why:** Avoid local conflicts with any default-port AzerothCore install
on the same dev machine.

---

## 2026-07-13 — Vanilla playerbot progression (level 20→40)

Vanilla random bots now enter at level 20 and level up organically toward
the level-40 cap at player-parity XP, gear persisting and upgrading as they
climb — replacing the prior lock that pinned the whole fleet at level 20.
The knobs live in `config/patches/C014-vanilla-playerbot-level-cap.sh`
(RandomBotMinLevel/MaxLevel, DisableRandomLevels, RandomBotXPRate,
EquipmentPersistence, RandomBotMaps). **Why:** a fleet frozen at the floor
of the progression band made the world feel static; a climbing fleet
mirrors the players moving through the same 20-40 Eastern Kingdoms content.
The specific "148h white kit at spawn" intent is not config-expressible
(rndbots self-gear on level-up) and remains an open decision.

---

## 2026-07-16 — Vanilla playerbot population band (128–256 active)

The ambient random-bot fleet is now bounded to a floor of 128 and a ceiling
of 256 simultaneously-online bots, down from the upstream 500/500 default.
The knobs live in `config/patches/C020-vanilla-playerbot-population.sh`
(MinRandomBots / MaxRandomBots). **Why:** a full 500-bot fleet was more
ambient traffic than the 20-40 Eastern Kingdoms band needs, and paid the
whole cost as a cold-boot login stampede every startup; a 128–256 band keeps
the world visibly populated without it. Account provisioning (`C018`, 110
accounts × 10 chars) still covers the ceiling with headroom, so no change
there.

---

## How to add an entry

```markdown
### YYYY-MM-DD — short description

(One-paragraph why. Reference the patch ID or source file that holds the
new value. Do not paste the value here — link to the source of truth so
this log doesn't go stale.)
```

If the change is structural enough to need a rollback path, design notes,
or before/after testing — it's an issue file, not a balance entry.
