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

## 2026-10-02 — Basic: how far a chest or node pulls a roaming buddy (617e3)

- **Pull distance**: a chest, or a herb or ore node the buddy can open,
  farther than the bot module's own loot reach (15 yards) and **within 45
  yards** becomes its next waypoint. The issue's test is a copper vein
  passed 40 yards off in Fargodeep Mine; 45 covers it with a little to
  spare, while keeping the detour well short of the 100 yards the bot
  module sees (the owner on grind: "100 yards is a long ways").
- **Look interval** 2 s, **give up** after 30 s (also how long a clan claim
  lasts), **not the same object again** for 10 minutes.
- Values: `modules/mod-buddies/src/buddies_roam_strategy.cpp` (`DETOUR_*`).
  First guesses, to judge in game.

## 2026-10-02 — Basic: buddies wandering towns, clearing full bags, buying meals (617h)

- **Wandering reach**: the next townsperson is looked for within 100
  yards, about a 40-second walk, so it fits inside the existing 60-second
  give-up on a town walk; 150 would use the whole timer.
- **"General direction"**: within 45° either side of the bearing toward the
  town's most distant person or a class trainer.
- **Full bags**: the clearance in a town without an auction house starts at
  90% full, the owner's own "still 90% full" line.
- **Meals**: buy up to 20 servings (one stack, under the bot module's
  two-stack surplus line, so a buddy never sells what it just bought);
  under 10 servings sends it to a vendor that sells its meal; at most a
  quarter of its money per stop, leaving the rest for repairs and training.
- Values: `modules/mod-buddies/src/buddies_town.cpp`. First guesses, to
  judge in game.

## 2026-10-02 — Basic: buddies crossing by boat, zeppelin and portal (617e8)

- **Missed sailings**: a buddy waiting on the dock gives up, loudly, after
  its boat or zeppelin has left **3** times without it. A first guess, so
  one bad boarding or a late arrival doesn't strand it, while a deck spot
  it can never walk onto is reported within a few sailings rather than
  waited on forever; the owner confirmed it, 2026-10-02: "um yeah sure 3
  missed boats is fine."
- **Docked**: a transport counts as in when within **8 yards** of one of
  its route's stops (the transport's own moving flag is private to it).
- **Dock reach** 60 yards (a transport this near the departure spot is
  the one waited for), **deck walk** from 40 yards in a straight line, a
  **failed crossing pauses** the buddy 60 s, **stepping off** gives up
  after 20 s.
- Values: `modules/mod-buddies/src/buddies_crossing.cpp` (tuning block).
  First guesses, to judge in game.

## 2026-10-02 — Basic: how close a path must reach a herb or ore node (617e3)

- **Node reach**: a buddy's best walking path to a herb or ore node must end
  within **3 yards** of it, or the node is moved and its spot retired for
  good. Three yards is the owner's number ("a location that is within 3
  yards") and matches the bot module's own height test for opening an
  object (about 3 yards).
- Value: `NODE_REACH_YARDS` in `modules/mod-buddies/src/buddies_roam_strategy.cpp`;
  the retired spots: `buddy_retired_node`, characters database.

## 2026-10-02 — Basic: buddies gathering at the owner's dock, and boarding by recording (617e8, 617e9)

- **At a dock**: the owner within 60 yards (flat) of a ship's stop, the
  stop being the ship's docked spot out on the water, piers lying within
  about 60 of it; **8 s** there before buddies come, so a stroll along the
  pier summons nobody; let go past **90 yards** from every stop, a gap
  above 60 so standing at the edge doesn't flicker; buddies wait within
  **6 yards** of the owner, close enough to board in time without crowding.
- **A dock spot belongs to a stop** within 80 yards, the pier search
  distance already in use.
- **Recording**: a step kept every 1 yard or turn of 0.3 rad (about 17°),
  fine enough for gangways and small to store; at most 1,500 steps, to
  catch a forgotten stop; a ship counts as docked for a recording within
  60 yards of a route stop, rejecting recordings made at sea.
- **Replay**: a leg may take 1.5 × its walking time + 2 s (start-up and
  small slowdowns); arrived within 1.5 yards (enough to be on the deck);
  a short leg re-sent twice before a loud failure (the bot module may
  nudge a buddy once or twice).
- Values: `modules/mod-buddies/src/buddies_crossing.cpp` and
  `buddies_recorder.cpp`. First guesses, to judge in game.

## 2026-10-02 — Basic: no dwell at the dock, a 1–3 s beat instead; jumping after the owner (617e8)

- **The 8 s dwell is removed**: an owner within 60 yards of a ship's stop
  is at the dock at once. Owner: "8 seconds might be a little too long. If
  you're on a dock, they should go to the dock too. If you're on a boat,
  they should board too. No need to wait, although +/- 1-3 seconds could be
  a good way to get them to seem a bit more natural."
- **The beat**: each buddy answers each of its owner's moves (arrived on
  the dock, boarded, stepped back off, jumped) after its own random
  **1–3 s**, so a clan doesn't move as one.
- **Jumping**: an owner leaving a ship that isn't at a stop while within
  **40 yards** of it has jumped (farther is a teleport); buddies jump
  **8 yards** out with a **4 yd/s** hop, the drop paced by the client's
  gravity (19.29 yd/s²) with **0.6 s** at least; a jump older than **30 s**
  is not followed (a buddy boarding later doesn't leap off).
- Values: `modules/mod-buddies/src/buddies_crossing.cpp` (tuning block).

## 2026-10-02 — Basic: a buddy jumps only where it would live (617e8)

- **The rule** (owner: "only jump if the fall is survivable or they could
  aim to land in water of a sufficient depth"): survivable is judged by
  the server's own fall-damage rule at basic's 10× rate, against the
  buddy's current health; "sufficient depth" is the server's own swimming
  depth (`Map::HasEnoughWater`), not a number of ours.
- **Where it looks**: 25 points, toward the owner first, then 30° and 60°
  either side, at **8, 14, 20, 26 and 32 yards** out. 32 is about how far a
  running jumper carries over a zeppelin-height fall (run speed × about
  three seconds of falling, plus the 8-yard hop); each point must also be
  within that carry for its own drop, so a short boat-deck drop only
  reaches the near points. Ground is searched up to **1,000 yards** down,
  higher than any zeppelin flies.
- **Choice**: the first deep-water point found wins; else the survivable
  ground landing with the least damage; else it stays aboard and rides
  round.
- Values: `modules/mod-buddies/src/buddies_crossing.cpp` (tuning block:
  `LANDING_*`, `FALL_SEARCH_YARDS`; the copied fall-damage constants).

## 2026-10-02 — Basic: a whispered buddy's scrambled answer (617a5)

- **One answer per whisperer per 10 s**, so a flood of whispers gets a
  single reply rather than an echo of each.
- **1.5 s before answering**, a typing beat so the reply doesn't land the
  instant the whisper is sent.
- Values: `modules/mod-buddies/src/buddies_whisper.cpp`. First guesses.

## 2026-10-02 — Basic: re-picking the ship at a dock that serves two (617e8)

- **30 yards**: an owner this near a different ship's stop than the one
  buddies picked makes them pick again. The owner asked for a re-pick
  "if you move within a certain radius of the other stop"; 30 is half the
  60 yards that counts as being at a dock at all, so the owner has to walk
  clearly over to the other arm, and merely standing between the two
  doesn't flip the pick back and forth.
- Value: `DOCK_REPICK_YARDS`, `modules/mod-buddies/src/buddies_crossing.cpp`.

## 2026-10-02 — Basic: the dock re-pick radius is measured per dock, not fixed (617e8)

- **Replaces the 30 yards above.** The owner: "the docks are smaller than
  30 yards. We need to calculate the distance between each dock, and use
  that number as the radius that a player needs to leave before the
  buddy-bots re-calculate." Each picked stop's radius is now its distance
  to the nearest other ship's stop at the same dock, read from the route
  data; leaving it makes buddies work out the nearest stop again. No fixed
  number remains to tune; `DOCK_REPICK_YARDS` is removed.
- Value: `StopSeparation`, `modules/mod-buddies/src/buddies_crossing.cpp`.

## 2026-10-03 — Basic: buddies buying gems at the auction house (617j2)

| Knob | Value | Where |
|---|---|---|
| Share of its money a buddy spends on gems per visit | 25% | `buddies_gems.cpp`, `GEM_SPEND_SHARE` |
| A buddy's old gear kept in its mail | 900 days (stock mail: 30) | `buddies_stage.cpp`, `KEPT_DAYS` |

Why: the owner asked for gems "from the auction house" and named no
spending limit; the quarter matches what a buddy may spend on meals per
stop (617e4). A first rule of buying only with more than 2 free bag slots
was dropped the same day: bought gems arrive by mail, so bag room matters
at the mailbox, not at the auction house. The 900 days are the owner's
("we should change the duration to be 900 days"), so old gear waits for a
buddy to level back into it.

## 2026-10-03 — Basic: buddies remember the people they visited (617p)

| Knob | Value | Where |
|---|---|---|
| How long a visited person is remembered | 15 to 30 minutes: two buffers, swapped server-wide every 15 minutes | `buddies_npcs.cpp`, `SWAP_MS` |

Why: the owner first said "every 30 minutes or so", then asked for "a
double-buffer system, and a server-wide 15 minute timer". Replaces the 3%
chance per look of going to chat.

## 2026-10-04 — Basic: the wandering Sargobras trails farther back (617b)

| Knob | Value | Where |
|---|---|---|
| How far behind the owner he walks | 10 yards (was 7) | `src/lua-basic/sargobras.lua`, `STOP_AT` |
| How far the owner must walk off before he follows | 25 yards (was 15) | `src/lua-basic/sargobras.lua`, `FOLLOW_AGAIN_AT` |
| Spread between several tiers' Sargobras behind the owner | about 23 degrees | `src/lua-basic/sargobras.lua`, `FAN_STEP` |

Why: the owner said "he follows too closely, you should have to walk a
bit (just back from where you've come)". Changed together with how he
moves (the server's own follow at the owner's pace, instead of sprinting
to a point once a second), which is in the issue, not here.

## 2026-10-04 — Basic: Sargobras's campfire burns, and he leaves with it (617b)

| Knob | Value | Where |
|---|---|---|
| How long the fire burns (he leaves with it) | 120 seconds | `src/lua-basic/sargobras.lua`, `FIRE_SECONDS` |
| How far from its centre the fire burns | 2.5 yards | `FIRE_RADIUS` |
| Burn per second | 2% of max health per tier he serves | `FIRE_PCT_PER_TIER` |
| His seat: distance from the fire, swing off the line back | 3 yards, 1.0 radian | `SIT_RADIUS`, `SIT_SWING` |

Why: the owner asked for the fire under the player, "increase in damage
for each tier", and for him to go "after the fire does". The duration and
the percentage are first guesses; the old rule (leave when no player is
within 100 yards) is gone.

## 2026-10-12 — Basic: the wandering Sargobras keeps to a circle, and his level (617b)

| Knob | Value | Where |
|---|---|---|
| His circle's radius (drawn each time) | 5 to 10 yards | `src/lua-basic/sargobras.lua`, `CIRCLE_MIN`, `CIRCLE_MAX` |
| Owner this far from him: a new circle | 15 yards (was: 25 yards of slack behind the server's follow) | `MOVE_ON_AT` |
| A spot with no direct route: pulled in by / down to | 1.5 yards / 2 yards | `PULL_STEP`, `PULL_FLOOR` |
| "Direct": a walk at most this long | 1.25 x the straight line + 1 yard | `DIRECT_FACTOR`, `DIRECT_SLACK` |
| He turns again when this far off | about 10 degrees | `FACE_SLACK` |
| His level | his tier's level + 1 | `summon_wanderer` |

Why: the owner's numbers ("he should stand 5-10 yards away from you",
"unless you're more than like, 15 yards away", "if you hit level 30 then
he should be level 31"). The pull-in steps and the "direct" margin are
first guesses. The old trailing distance (10) and slack (25) are gone with
the server's follow, which made him walk away from an owner coming to talk.

## 2026-10-12 — Every profile but cc-test: run speed 0.8 → 0.85 (C003)

| Knob | Value | Where |
|---|---|---|
| Player run speed (`Rate.MoveSpeed.Player`) | 0.85 (was 0.8) | `config/patches/C003-run-speed-80-percent.sh`, `RUN_SPEED` |

Why: the owner, "can we increase the movement speed for blood elf females
to 0.85 instead of 0.8?", then "Sure, 0.85 for everyone, let's see how it
feels": per-body speeds (issue 166) aren't built, so the reference body's
pace is everyone's for now. Takes effect at the next install or config
step (C003 rewrites worldserver.conf), then a world-server restart.

## 2026-10-12 — Basic: no faster healing below level 15 (C034); walking at full speed (B053)

| Knob | Value | Where |
|---|---|---|
| Low-level healing boost (`EnableLowLevelRegenBoost`) | 0 (stock 1) | `config/patches/C034-basic-no-low-level-regen-boost.sh` |
| Player walking speed | stock (2.5 yards a second), outside the 0.85 rate | `patches/B053-walking-at-full-speed.sh` |

Why: the owner, playing two new characters, "can we turn off the
mechanic that makes levels 1-5 or 10 I forget heal faster? They should
heal at the normal rate." (stock heals faster under 15) and "can we make
sure that walking speed is at 100% of it's normal speed?". C034 is set in
the installed basic config too (a restart picks it up); B053 needs a
build.

## 2026-10-17 — Beta: 200 random bots (C035)

| Knob | Value | Where |
|---|---|---|
| Random bots in the world (`AiPlayerbot.MinRandomBots`, `MaxRandomBots`) | 200 (stock 500) | `config/patches/C035-beta-playerbot-population.sh` |

Why: beta's ambush sends monsters at every bot as well as every player
(wanted), so each bot is a stream of spawns and chases of its own; at 500
that was about 12 spawns a second across the world. The owner, 2026-10-17:
"We want monsters to spawn for playerbots. We might need to decrease the
number of playerbots." and "if it's 500 bots now, then we should turn it
down to 200." Takes effect at beta's next install, then a restart.

## 2026-10-20 — Beta takes wow-chat-1's survival settings (C037); no low-level healing boost anywhere (C034); beta's kill experience 3× (C037, C005)

| Knob | Value | Where |
|---|---|---|
| wow-chat-1's tuned server settings, on beta | the list in the patch | `config/patches/C037-beta-wow-chat-1-survival-settings.sh` |
| Low-level healing boost (`EnableLowLevelRegenBoost`), every profile | 0 (stock 1) | `config/patches/C034-no-low-level-regen-boost.sh` (was `C034-basic-...`, basic only) |
| Kill experience (`Rate.XP.Kill`) on beta | in C037 | C005 (2×) is release's only now |

Why: the settings wow-chat-1 ran with were found in its old server folder
and laid out in `docs/wow-chat-1-settings.md`. The owner, 2026-10-20: "in
general the wow-chat-1 server settings should be applied to wow-chat style
survival servers, and not to the ones that still have NPCs and such";
"professions we should leave at 2 for now"; on battleground line of sight
through objects, "that seems bad" (kept at stock); "we should remove the
low level regen boost on all servers. It feels cheap!"; "for servers that
don't have any quests (because we removed the quests, or the quest givers)
we should have kill experience set to 3" (beta, whose quest givers E012
removes). The settings held back for a decision are listed in C037's
header and the doc. Takes effect at each profile's next install, then a
restart.

## 2026-10-20 — Corpses lie 10 hours on beta (C037); no quest sparkles or map points on basic, vanilla, release and beta (C038)

| Knob | Value | Where |
|---|---|---|
| `Corpse.Decay.*`, `Rate.Corpse.Decay.Looted` on beta | in C037 | `config/patches/C037-beta-wow-chat-1-survival-settings.sh` |
| `Visibility.ObjectSparkles`, `Visibility.ObjectQuestMarkers`, `QuestPOI.Enabled` | 0 (stock 1) | `config/patches/C038-no-quest-sparkles-or-map-points.sh` (moved out of C037) |

Why: the owner, 2026-10-20, on wow-chat-1's 10-hour corpses, held at
first: "this should be on beta". And asked whether the servers with
quests should lose the sparkles and map points beta already had off:
"yes". Takes effect at each profile's next install, then a restart.

## 2026-10-20 — Beta's players see 333 yards on the continents (C037); bots no farther than they act (B056)

| Knob | Value | Where |
|---|---|---|
| `Visibility.Distance.Continents` on beta | 333 (stock 100) | `config/patches/C037-beta-wow-chat-1-survival-settings.sh` |
| A bot's reach on the continents | the bot module's largest sight-like distance | `patches/B056-bots-see-only-as-far-as-they-act.sh` |

Why: wow-chat-1's sight distance, held because the server tracks it for
every bot too. The owner, 2026-10-20: "Bots should only be able to see as
far as the largest range they can see", read from the bot module's
settings, and "BGs and instances should have their stock distances".
Issue 194. Takes effect at beta's next compile (B056) and install (C037).

## 2026-10-20 — 250 yards everywhere it is raised; instances and battlegrounds at 250 on every profile (C039); bots capped on every map (B056)

| Knob | Value | Where |
|---|---|---|
| `Visibility.Distance.Continents` on beta | 250 (was 333 in the entry above) | `config/patches/C037-beta-wow-chat-1-survival-settings.sh` |
| `Visibility.Distance.Instances`, `.BGArenas`, basic vanilla release beta cc-test | 250 (stock 170, 250) | `config/patches/C039-instances-and-battlegrounds-see-all.sh` |
| A bot's reach, every map, every one of those profiles | the bot module's largest sight-like distance | `patches/B056-bots-see-only-as-far-as-they-act.sh` |

Why: the server clamps every view distance to 250 (`MAX_VISIBILITY_DISTANCE`),
with an error at each start, so 333 was 250 in effect and is written as
250. The owner, 2026-10-20: "how about for battlegrounds and instances we
just have 100% view distance for all players and bots, always? ...
So how about the largest size for them [buddy-bots, stand-ins] in dungeons
and BGs and instances and such?" Takes effect at each profile's next
compile (B056) and install (C037, C039).

## 2026-10-22 — a death knight's talent points: 11 at 55, then 8 a level to 60 (basic)

| Knob | Value | Where |
|---|---|---|
| A death knight's talent points, levels 55-60, basic | the table at the top of the rule (stock: 46 at 55 outside Acherus) | `src/cpp-basic/basic_rules.cpp`, death knight talent points |

Why: the owner, 2026-10-22, wanted a death knight's points spread over its
first levels rather than all at once, ending at the 51 every class has at
60 ("There should be the correct total amount applied"), with "11 talent
points at level 55? So they can have an extra ability to play with", and
"1 per level" after 60. Issue 718d; the pattern is
`strategems/talents-caught-up-over-first-levels.md`. Takes effect at
basic's next compile (B030).

## 2026-10-22 — a skipper's talent points meet the story's at 58 (basic)

| Knob | Value | Where |
|---|---|---|
| A death knight's talent points, levels 55-60, basic | skippers and buddies by the table (was 11 to 51 evenly); story players stock | `src/cpp-basic/basic_rules.cpp`, death knight talent points |

Why: the owner, 2026-10-22, the same day as the entry above: "The DKs
should have the same number of talent points at 58 if they skipped or did
the story, and they should have the same number of talent points as
everyone else at levels 58, 59, and 60", keeping the stock 51 at 60 for
every class. A story player already finishes at 58 with what everyone has
(its quests' 46 plus one a level past 55), so it keeps the stock rule and
the table rises from 11 to meet it there. Issue 718d. Takes effect at
basic's next compile (B030).

## 2026-10-23 — the Dark Portal's wave demons halfway down toward level 60 (basic)

| Knob | Value | Where |
|---|---|---|
| The four Stair of Destiny wave demons' levels, basic | halfway between their saved levels and 60, rounded up | `patches/E069-basic-portal-demons-halfway/40-portal-demons-halfway.apply.sql` |

Why: the owner, 2026-10-23: "Right now it's very difficult to get through
the hordes of demons - we need to fight them back", then, offered bringing
them to the player's level: "let's bring them down halfway." A stopgap
until the front (issue 155z) replaces the stock event. Takes effect at
basic's next install.

## 2026-10-23 — Outland's friendly people +4 levels (+6 on the Isle) (basic)

| Knob | Value | Where |
|---|---|---|
| Outland's friendly creatures' levels, basic | +4, or +6 when they stand only on the Isle (as E032's monsters) | `patches/E070-basic-outland-folk-plus-four/41-outland-folk-plus-four.apply.sql` |

Why: the owner, 2026-10-04: "can you make the guards and townspeople in
Outland be roughly scaled to the threats they are to diminish? It should
be an even fight"; 2026-10-23: "let's scale them all, then" and "just give
it +4 like we do with the other creatures." Issue 155z1. The Dark Portal's
defenders go from 68 to 72, against its demons at 65 to 68 (E069). Takes
effect at basic's next install.

## 2026-10-23 — both Outland level changes above undone before install (basic)

| Knob | Value | Where |
|---|---|---|
| The Dark Portal's wave demons' levels | back to as before: 70 to 76 (E069 removed) | none (stock, with E032's +4) |
| Outland's friendly people's levels | back to stock (E070 removed) | none |

Why: told the portal's defenders would reach 72 against demons at 65 to
68, the owner, the same day: "let's bump the monsters back to their normal
level again, and nix our previous thing. Actually, maybe monsters in
Outland are just... really difficult? Can we remove the NPC level
adjustment? It's okay if they die a lot. Outland is hard!" Neither step
was ever installed, so no database changed. Issues 155z, 155z1.

## 2026-10-23 — spirit's health healing halved (basic)

| Knob | Value | Where |
|---|---|---|
| Health from spirit per 5 seconds | spirit x stamina / 200 (was / 100) | `patches/B049-spirit-heals-by-stamina.sh` |

Why: a worked example (issue 167) showed a level-60 warrior who trades
gear stamina for spirit refilling from empty in about a minute standing
still. The owner: "we should double the divisor so the numbers are
doubled. A full refill should take ~2 minutes I think. That's much longer
than the 30 seconds it takes to eat / drink." Takes effect at basic's next
compile.

## 2026-10-25 — spirit's health healing back to full (basic)

| Knob | Value | Where |
|---|---|---|
| Health from spirit per 5 seconds | spirit x stamina / 100 (was / 200 for two days) | `patches/B049-spirit-heals-by-stamina.sh` |

Why: measured against the level-60 raid bosses and basic's Outland
dungeon bosses (`scripts/tank-damage-taken`, issue 167), at 200 spirit
healed 1 to 8 percent of a boss's melee while being hit, and the best build
for a short fight was all stamina. The owner: "I want spirit to be useful
in combat. I also want it to be useful for people who aren't tanks", and
nothing should be "always right". At 100 the best split moves with the
fight's length and with whether the boss is hitting you. Takes effect at
basic's next compile.

## 2026-10-25 — no crushing blows (basic)

| Knob | Value | Where |
|---|---|---|
| Crushing blows (150% hits from creatures well above their target) | none (was: from 8 levels above, full at 12) | `patches/B031-crushing-blows-late.sh` |

Why: a level-60 tank's defence stops counting against crushing at 300, so
from level 71 every landed swing of Outland's raised bosses crushed, and
no gear could answer it (`scripts/tank-damage-taken`, issue 155f1). The
owner: "let's remove them. There's already crits". Their difficulty goes
into per-creature multipliers (155i). Takes effect at basic's next compile.

## 2026-10-25 — Doom Lord Kazzak tuned for level 60 (basic)

| Knob | Value | Where |
|---|---|---|
| Kazzak's melee and spell damage | x0.40 | `patches/E071-basic-fight-multipliers/fights.lua` |
| His Berserk at 3 minutes | removed (no effects) | the same |
| His Frenzy | no +30% damage; stops swinging and casting for 6 s, a volley a second (about 1,090 each, six about 140% of a raid member's health) | the same |

Why: built for level-70 raids, his swings were twice a level-60 tank's
health. The owner wanted him "nearly impossible to defeat. But, not
impossible", chose 0.40 ("Needs playtesting of course"), asked for the
frenzy to become a channelled volley the raid survives with strong
healing, and removed the Berserk, which comes from the server's script
and not Wowhead's page. Issues 155j, 155f1. Takes effect at basic's next
install and server start.

## How to add an entry

```markdown
### YYYY-MM-DD — short description

(One-paragraph why. Reference the patch ID or source file that holds the
new value. Do not paste the value here — link to the source of truth so
this log doesn't go stale.)
```

If the change is structural enough to need a rollback path, design notes,
or before/after testing — it's an issue file, not a balance entry.
