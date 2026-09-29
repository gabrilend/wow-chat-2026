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

## 2026-09-23 — Basic profile starting values (issue 155)

The new basic profile (levels 1–60) takes its first knob settings.
**Bot band:** bots enter at the player start level and may climb to the
cap by XP, across Eastern Kingdoms, Kalimdor and Outland
(`config/patches/C023-basic-playerbot-progression.sh`). **Why:** basic is
the whole 1–60 ladder, so the ambient population walks the whole ladder
too. **Bot population and accounts:** basic reuses vanilla's band and
account count (C020, C018 now gated `vanilla basic`) as a starting point,
not a tuned value. **Outland dungeons:** the creature level inside every Outland
dungeon a level 60 can enter (the open world stays stock) is set in
`sql/basic/db_world.src/09-outland-dungeons-64.apply.sql`. **Why:** the
owner wants these dungeons "as hard as raids" for level-60 characters, with
their loot unchanged so dungeon blues are not an early shortcut; with the ±3
accuracy cap (B005) a four-level gap plays like three.

---

## 2026-09-23 — Run speed now actually 80% on every profile

`config/patches/C003-run-speed-80-percent.sh` has always meant players move
at 80%, but it edited a key the server config does not have, so everyone
ran at 100%. It now edits the real key. **Why this entry:** nothing about the
intended value changed, but every profile's felt movement speed changes on
its next install, and this is where someone would look for why. Beta's
instant flights (`C009`) had the same defect and now take effect too.

---

## 2026-09-24 — Basic: no random bots

Basic's random-bot fleet is switched off: they never log in and their
population is zero (`config/patches/C023-basic-no-random-bots.sh`, renamed
from `C023-basic-playerbot-progression.sh`; the 2026-09-23 entry's bot band
no longer applies). C020 and C018 are gated to `vanilla` only again.
**Why:** Ritz, 2026-09-24: "no random bots in basic. Just playerbot
buddies." Each player's own buddies (issue 617) are the only bots; until
they are built, a basic world has none.

---

## 2026-09-25 — Basic: first gem-supply rates (defaults)

Basic's gem supply (`sql/basic/db_world.src/18-gem-supply.apply.sql`, E033,
issue 155p) needed rates Ritz hadn't set, so it starts from defaults, to be
tuned after play: a cut +4 gem per copper or tin prospect, an Outland
uncommon raw gem per mithril prospect, an Outland rare raw gem per thorium
prospect, and uncut Wrath uncommon and rare gems per Outland kill (the
numbers are in the file's header and its prospecting and loot sections).
**Why:** the tiers need a source at all before their rates can be judged;
the defaults aim at a +4 gem every few prospects, Outland gems a little
rarer, and Wrath gems as a rare Outland find. The rates Ritz did set
(recipe drops near 0.3% of kills, epic-cut recipes 1.5% per boss, the epic
gem drops, Onyxia's hoard) are recorded in the issue.

---

## 2026-09-25 — Basic: gold price of Outland gem cuts at trainers (defaults)

The Jewelcrafting trainers who now teach Outland's gem cuts on basic (same
file, section 7) charge a flat default price per cut, one for uncommon and
one for rare cuts (the values are in that section). **Why:** stock prices
for these cuts were set for level-70 characters with Outland income; a
flat, small price fits characters learning them from skill 150, and can be
tuned once real players' gold is known.

---

## 2026-09-25 — Basic: crystal trade's rare-gem chance (default)

The Earthen Crystal-Keeper (`src/lua-basic/titan-jewelers.lua`, issue 155p)
gives an uncommon uncut Wrath gem for a Nexus Crystal, and a rare one at a
default chance (`RARE_CHANCE` in that file). **Why:** Ritz asked for "a
small chance to be a rare" without a number; this starts it small and
leaves it for tuning.

---

## 2026-09-26 — Basic: how smoothly Sargobras turns (defaults)

The wandering Sargobras (`src/lua-basic/sargobras.lua`, issue 617b) turns
toward his owner in small steps, because the server can only set a facing,
not animate one: a step every `TURN_STEP_MS`, at `TURN_SPEED`. **Why:** Ritz
asked for a slow, lerp-style turn, stepped "once every N frames, where N is
the number we pick that 'feels fine' that's as high as possible so there's
less performance demands on the server". These are first guesses; raise
the step time until the turn starts to look jerky in game, then back off.

---

## 2026-09-27 — Basic: when a travelling buddy counts as stuck

A buddy walking to its owner's area (`modules/mod-buddies/src/buddies_town.cpp`,
issue 617e4) is moved to a random spot within 30 yards when it hasn't
gained `PROGRESS_YARDS` toward its owner in `STUCK_MS`. The progress needed
went from 5 yards to 10 (90 seconds unchanged). **Why:** Ritz: "let's make
it 10" — a buddy shuffling back and forth against an obstacle can gain a
few yards by accident and never count as stuck; 10 asks for real headway.
A buddy stuck again after the move is left for the owner's hearthstone to
rescue ("the player can always rescue them with a hearthstone cast").

---

## 2026-09-27 — Crushing blows: later start, ramped (basic, B031)

- **Crushing blows** start at a level gap of **8** (was: stock 4 below
  level-64 creatures, none from 64 up), at the stock chance × (gap − 7) / 5,
  full stock chance from a gap of 12. At 8 levels up: 13% instead of 65%.
- Why: Ritz, "can we re-enable the crushing blow penalty at +4 the level it
  normally is? And have it scale up to it's nominal percentage with another
  4 levels." Crushing returns as a real threat from much stronger foes, for
  every creature level, without the stock cliff from none to every hit over
  four levels. Table: `docs/patches/crushing-blows-late.md`.

## 2026-09-27 — World bosses: the respawn countdown and the battle bonus (basic, 155j)

- **Respawn**: a dead world boss is due back after **2.5 hours plus its
  moment tokens' worth**: every 5-second pass, each player (not bot) in the
  boss's area deposits a token worth **1% of the pass**. Nobody there: 2.5
  hours; 50 players: 5 hours; 100 or more: never. No random share. Values:
  `src/lua-basic/lib/world-boss-countdown.lua` (`BASE_SECONDS`,
  `PASS_SECONDS`, `TOKEN_PERCENT`). Was: the stock timers (Kazzak about 2
  hours, Doomwalker a day, Azuregos and the dragons about 10 days).
- **Battle bonus**: while any world boss lives, every monster hostile to
  both factions deals **+1% damage** and has **+1% health**, server-wide.
  Values: `src/cpp-basic/basic_rules.cpp` (`BATTLE_BONUS_DAMAGE`,
  `BATTLE_BONUS_HEALTH_DIV`).
- **Kazzak's swarm**: **one elite demon pack per player** in his zone when
  he comes back, **3 demons a pack** (an Overseer and two Peons), at most
  packs **60 yards** apart and from him; **no cap** on packs (owner,
  2026-09-27: "no cap. demons will be long slain by the time he's done").
- **Kazzak's size**: model scale **x4**; walk **5 -> 10**, run **10 -> 20**
  yards a second (square-root-of-size gait); reach and radius kept stock
  (15.75, 9). Values: `sql/basic/db_world.src/29-world-boss-respawn.apply.sql`.
  Owner: "scale up his model 4x [...] Large enough to be 6 people tall, at
  least." Steps to judge in game. Values:
  `basic_rules.cpp` (`SWARM_*`). First guesses, to tune after a fight.
- Why: the owner, 2026-09-27: world bosses are for "vast swarms of
  parties" fought in the open, so they come back often ("Can we change
  their respawn time to 2.5 hours?"), wait while a crowd holds the ground
  ("if 100 players are there, then it'll never happen"), lift every
  monster while alive ("all monsters get a 1% battle bonus"), and Kazzak
  brings "wayyyy too many demons [...] about one elite pack per person".

## How to add an entry

```markdown
### YYYY-MM-DD — short description

(One-paragraph why. Reference the patch ID or source file that holds the
new value. Do not paste the value here — link to the source of truth so
this log doesn't go stale.)
```

If the change is structural enough to need a rollback path, design notes,
or before/after testing — it's an issue file, not a balance entry.

