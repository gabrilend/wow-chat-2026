# Conversation Summary: agent-a73a9a55b4f619e27

Generated on: 2026-09-26 12:46:05
Models: claude-haiku-4-5-20251001

--------------------------------------------------------------------------------

### User Request 1

I need a complete inventory of "vanilla profile" issue files in this repo,
focused on what work is still open/incomplete vs. done.

The project root is /mnt/mtwo/games/azeroth-core/wow-chat-2026

Issue files live in `issues/` (open/in-progress) and `issues/completed/` (done).
The vanilla profile issues seem to be in the "148" cluster (e.g. 148h, 148o,
148p, 148q, 148s) and possibly others tagged "Vanilla". There are also
"E-patches" and "C0xx" patch configs referenced.

Please do the following:
1. List every issue file under `issues/` (NOT in completed/) whose subject
   matter relates to the "vanilla" profile — search filenames and file
   contents for "vanilla", "Vanilla", "148". Report the full filename of each.
2. For each such open issue, read it and give me: (a) a one-to-two sentence
   plain-English summary of what it wants, (b) its current status per the file
   (look for status markers, "current behavior" vs "intended behavior" sections,
   checkboxes, "in progress", "complete", deferred work notes), and (c) whether
   it looks fully done, partially done, or not started.
3. Also list which vanilla-related "148" issues are already in
   `issues/completed/` (just filenames), so I know what's finished.
4. Note any issue that explicitly mentions being a candidate for "will not
   implement", "won't fix", "deferred", "optional", or similar.

Return a structured report grouped by: OPEN issues (with summaries + status),
and COMPLETED issues (filenames only). Be thorough — check both the issues/
dir and issues/completed/ dir. Do not modify any files.

--------------------------------------------------------------------------------

### Assistant Response 1

> I'll conduct a thorough inventory of vanilla profile issues. Let me start by
> exploring the directory structure and finding all relevant files.

> Now let me check for vanilla-related issues in the completed directory and
> search for any other issues with "vanilla" or "Vanilla" tags:

> Let me check the completed directory for any vanilla-related issues more
> broadly:

> Let me search for vanilla-related files in the completed directory:

> Let me also search the open issues directory for any vanilla-related files
> outside the 148 cluster:

> Now let me read all the 148-cluster vanilla profile issues to get their status
> and summaries:

> Let me continue reading the remaining open 148 issues:

> Let me continue reading the remaining vanilla issues:

> Let me continue reading the remaining vanilla issues:

> Now let me search for completed vanilla-related issues in the completed
> directory:

Perfect. Now I have all the information needed. Let me compile the comprehensive
report:

---

## VANILLA PROFILE ISSUES INVENTORY

## OPEN ISSUES (in `issues/` directory)

### **Core Parent Issue**

**148 - Vanilla Profile: Default WotLK + Playerbots**
- **Summary:** Defines and implements the vanilla profile baseline — a WotLK
  3.3.5a server with playerbots and minimal customization (no custom Lua layer
  like release/beta), starting at level 20 with a 40-cap. Serves as the floor
  upon which all other profiles build.
- **Status:** **PARTIALLY COMPLETE (Phase 1 Foundation)** — The design is
  thoroughly documented and in-progress. The install infrastructure and basic
  profile registration exist, but many sub-issues are still pending
  implementation. See sub-issues below for specific blockers.
- **Completion estimate:** ~40-50% done; multiple sub-issues unstarted.

---

### **BLOCKING DEPENDENCIES (must finish before vanilla ships)**

**148a - Disable Death Knights on Vanilla**
- **Summary:** Disable DK class creation on vanilla via config knob
  (`CharacterCreating.Disabled.ClassMask = 32`). The DK starting experience
  (Acherus) is incompatible with vanilla's level-40 cap and level-20 start.
- **Status:** **IN PROGRESS** — Issue redesigned (2026-06-02) to use a config
  knob instead of SQL deletion. Mechanism defined; implementation pending.
- **Completion estimate:** ~10-20% done; patch-system wiring not yet complete.

**148h - Class-Specific Starting Equipment for Level-20 Start**
- **Summary:** Generate and apply full level-20 white-quality starter kits
  (armor + weapons) for all 52 valid (race, class) combos. Cloned items to avoid
  polluting canonical vanilla item data, with normalized DPS and per-race
  curation. Includes armor, weapons, bags, hearthstone, and ammo.
- **Status:** **REDESIGNED & SUBSTANTIALLY COMPLETE (2026-06-12)** — The
  thematic curation, item cloning procedure, damage normalization, and
  loot-table updates are fully specified. SQL generation and apply/revert-form
  design complete. **READY TO IMPLEMENT** but implementation pending.
- **Completion estimate:** ~70% designed, 0% implemented.
- **Notes:** Explicitly blocks 148k (auto-equip hook) and 148j (weapon
  proficiencies).

**148i - Remove All Flight Paths from Vanilla**
- **Summary:** Disable flight-master taxi UI network-wide; preserve
  boats/zeppelins for cross-continent travel. Replaces flight-master
  interactions with thematic per-NPC flavor gossip so the world remains
  populated and legible.
- **Status:** **DESIGNED, NOT STARTED** — Mechanism (Path B3 + B1) is fully
  specified with implementation sketches.
- **Completion estimate:** ~60% designed, 0% implemented.

**148j - Pre-Train All Level-≤20 Class Abilities at Character Creation**
- **Summary:** Grant every spell + weapon skill a class would learn from
  trainers at levels 1-20, so a level-20 starting character has their full spell
  roster. Generator-driven SQL to keep migration synchronized with trainer data.
- **Status:** **DESIGNED, NOT STARTED** — Data source (npc_trainer join), SQL
  generation approach, and idempotence strategy all defined. Generator script
  stub needed.
- **Completion estimate:** ~60% designed, 0% implemented.

**148k - ALE Auto-Equip Starter Kit on Character Creation**
- **Summary:** Lua hook on PLAYER_EVENT_ON_FIRST_LOGIN that strips all equipped
  items and bags, then fetches the 148h kit from the DB and re-equips it
  categorically (bags → quiver → equipment → ammo → hearthstone),
  binding hearthstone to per-faction spawn towns.
- **Status:** **DESIGNED, NOT STARTED** — Algorithm, trigger event, slot
  resolution table, and async query strategy all specified. Mechanism shape
  clear but Lua code not written.
- **Completion estimate:** ~70% designed, 0% implemented.
- **Notes:** Explicitly depends on 148j (weapon proficiencies) and 148h (kit
  data).

---

### **GAMEPLAY TUNING (high-priority, not blocking)**

**148m - Vanilla XP and Talent Tuning**
- **Summary:** Slow XP progression to 0.8× (net 1.6× after C005's 2x doubling)
  so 20→40 leveling takes longer. Boost talent grants to 3 points per level
  (instead of 1) from 21-40 so characters reach level cap fully specced.
- **Status:** **DESIGNED, NOT STARTED** — C-patch for XP rate defined; Lua
  hook for talent bonus event specified. Exact values confirmed by user (0.8, 3
  points).
- **Completion estimate:** ~60% designed, 0% implemented.

**148n - Vanilla Racial Starting Zones (per-race refinement)**
- **Summary:** Replace the coarse two-faction zone split (Darkshire / Tarren
  Mill) with a six-town per-race spread (Menethil, Darkshire, Astranaar,
  Ratchet, Tarren Mill, Stonetalon) to distribute the player population and
  match race lore.
- **Status:** **DESIGNED + LIVE ANCHOR FIX PARTIAL (2026-07-13)** — Per-race
  coordinates specified. The Sun Rock Retreat anchor (race 6+10) was fixed
  2026-07-13 after proving broken in testing. The change was **generalized to
  all six anchors** as innkeeper coordinates to guarantee walkable ground. ALE
  hearth-bind table updated. Remaining: full test-dev matrix validation.
- **Completion estimate:** ~75% done; five anchors unvalidated in-client (one
  test pass pending).

**148o - Vanilla Spawn & Kit Validation Pass (per race × class)**
- **Summary:** Structured reroll matrix across all 52 valid (race, class) pairs
  to validate spawn anchors are walkable (non-void-death), starter kit applied,
  hearthstone bind correct, and level-20 state correct. Includes test-dev
  account setup (TESTDEV/menardi) and per-character spot-check checklist.
- **Status:** **IN PROGRESS (2026-07-13)** — Sun Rock anchor fixed and
  generalized; test-dev account recommended; matrix structure designed. The
  actual 52-character reroll validation **not yet executed**.
- **Completion estimate:** ~50% designed, 0% validated; blockers fixed but test
  matrix pending.

---

### **OPTIONAL / DEFERRED**

**148l - Vanilla Mount Level Requirements**
- **Summary:** Raise mount-skill level requirements from WotLK defaults
  (Apprentice 20 / Journeyman 40) to Classic values (Apprentice 40 / Journeyman
  60) so only the 60%-speed mount is reachable at level 40, and the epic mount
  is an unreached horizon.
- **Status:** **DESIGNED, NOT STARTED** — Mechanism (trainer reqlevel UPDATE)
  and fallback (DBC patching) both specified.
- **Completion estimate:** ~50% designed, 0% implemented.
- **Priority:** Low (flavor, not blocking vanilla ship).

**148p - Wand DPS at ~100% of Spell DPS**
- **Summary:** Rebalance all wands in the item DB so auto-attacking with a wand
  deals roughly equivalent DPS to casting spells, enabling auto-attack-only
  caster builds at mechanical parity. Deferred from 148h because it's a
  cross-cutting item rebalance, not a starter-kit tweak.
- **Status:** **SPECIFIED, NOT STARTED** — Reference spell-DPS table, proposed
  wand-DPS targets per level band, rescaling formula, and open questions (talent
  scaling, PvP balance, coefficient interaction) all documented. No
  implementation started.
- **Completion estimate:** ~40% designed, 0% implemented.
- **Priority:** Low (deferred out of 148h scope; ship at 20 DPS placeholder).
- **Notes:** 148h's wands currently set to 20 DPS as a placeholder; this ticket
  finishes the proper rebalance.

**148q - Vanilla Starting Professions (gathering by race, production by class)**
- **Summary:** Grant every level-20 vanilla character two professions: one
  gathering (by race with per-faction class overrides) and one production (by
  class), both at skill 125, with every learnable recipe and the profession's
  tool. Seven gatherings + seven productions split evenly between the axes.
- **Status:** **FULLY SPECIFIED (2026-07-13), NOT BUILT** — Mappings confirmed
  by user (race defaults, class overrides, skill value 125). Generator strategy,
  SQL shape, bitmask-keying lesson (learned from 148j bug), and data-coherence
  validator all designed. Zero implementation code written yet.
- **Completion estimate:** ~80% specified, 0% implemented.
- **Priority:** Medium (QoL; not blocking vanilla ship).

**148s - Vanilla Playerbots Start in the 148h Starter Kit**
- **Summary:** Patch mod-playerbots `PlayerbotFactory` so level-20 bots spawn in
  the 148h kit instead of randomized gear. Vanilla-only; remains config-gated or
  DB-name-gated; bots upgrade normally as they level.
- **Status:** **SPECIFIED, NOT BUILT** — Mechanism (B-patch to module source +
  C-patch for vanilla scoping), entry point, and vanilla-gating strategy all
  designed. Patch-system packaging clear. No source patch written.
- **Completion estimate:** ~60% specified, 0% implemented.
- **Priority:** Medium (consistency with player kit; not critical).
- **Notes:** Depends on 148h (kit definitions) and 148j (weapon proficiency
  pre-training).

---

### **DECLINED SUB-ISSUES (kept as record for future decisions)**

**148b - Add mod-instance-reset to Vanilla — DECLINED**
- **Summary:** Would raise the per-hour dungeon-entry cap (default 5→30) so
  Uldaman can be farmed without hourly lockout. Decided vanilla's default 5/hour
  is acceptable; revisit if play-testing shows it actually blocks the loop in
  practice.
- **Status:** DECLINED (2026-06-02); kept on disk as reference.

**148c - Add mod-quest-status to Vanilla — DECLINED**
- **Summary:** Would add objective markers over quest NPCs/objects. Decided
  vanilla players should read quest text and use the in-game map; slower
  exploration matches the ruleset's intent.
- **Status:** DECLINED (2026-06-02); kept on disk as reference.

**148d - Add mod-zone-difficulty to Vanilla — DECLINED**
- **Summary:** Would scale Uldaman HP/damage multipliers. Decided vanilla's
  default tuning stands for v1; revisit if play-testing shows Uldaman feels
  trivial.
- **Status:** DECLINED (2026-06-02); kept on disk as reference.

**148e - Add mod-account-achievements to Vanilla — DECLINED**
- **Summary:** Would move achievements to account-level instead of
  per-character. Decided achievements are not a focus of vanilla; default
  per-character behavior stands.
- **Status:** DECLINED (2026-06-02); kept on disk as reference.

**148f - Add mod-server-auto-shutdown to Vanilla — DECLINED**
- **Summary:** Would schedule periodic server restarts with countdown
  announcements. Decided manual restarts are fine for the current hosting
  context; revisit if vanilla goes public.
- **Status:** DECLINED (2026-06-02); kept on disk as reference.

**148g - Class Combination Modifier System — PROMOTED**
- **Summary:** Was a 148 sub-issue (cross-profile race/class availability
  system) but promoted to **issue 716** in the phase-7 custom-class cluster
  because it's cross-profile, not vanilla-specific.
- **Status:** PROMOTED to 716 (2026-06-01); this file is a redirect.

---

## COMPLETED ISSUES (in `issues/completed/` directory)

**None of the vanilla profile (148-cluster) issues are in the completed
directory.** The profile is still in Phase 1 (Foundation).

However, several unrelated completed issues reference vanilla:
- **119-config-value-orchestrator.md** — completed; discusses vanilla as a
  profile option
- **133-profile-transition-system.md** — completed; mentions vanilla profile
  transitions
- **129-release-to-beta-transition.md** — completed; references vanilla in
  passing
- **202-lua-engine-initialization** — completed; mentions vanilla Lua path
  setup

These are not vanilla-profile implementation tickets; they're infrastructure
that vanilla depends on.

---

## SUMMARY TABLE: Vanilla Profile Work Status

| Issue | Title | Status | % Done | Blocker? | Notes |
|-------|-------|--------|--------|----------|-------|
| **148** | Vanilla Profile: Default WotLK + Playerbots | Partially Complete | 40-50 | NO | Parent issue; design complete, infrastructure partial, most sub-issues pending |
| **148a** | Disable Death Knights | In Progress | 10-20 | YES | Config-knob mechanism redesigned; patch wiring pending |
| **148h** | Class-Specific Starting Equipment | Designed | 70 | YES | Thematic curation, cloning, loot-table sweep all specified; SQL generation ready but not executed |
| **148i** | Remove All Flight Paths | Designed | 60 | YES | Path B (flavor gossip) fully specified; migration not written |
| **148j** | Pre-Train Level-≤20 Abilities | Designed | 60 | YES | Data source + SQL shape + generator strategy clear; script not written |
| **148k** | ALE Auto-Equip Starter Kit | Designed | 70 | YES | Algorithm + events + slot resolution all specified; Lua code not written |
| **148l** | Mount Level Requirements | Designed | 50 | NO | Mechanism + fallback specified; low priority (flavor) |
| **148m** | XP and Talent Tuning | Designed | 60 | NO | C-patch + Lua hook both specified; code not written |
| **148n** | Racial Starting Zones | Live (Partial) | 75 | NO | All six anchors moved to innkeeper coords (2026-07-13); test matrix pending |
| **148o** | Spawn & Kit Validation Pass | In Progress | 50 | YES | Test structure designed; 52-character matrix not executed; blockers fixed |
| **148p** | Wand DPS Parity | Specified | 40 | NO | Reference spell table + targets + formula all designed; implementation deferred (low priority) |
| **148q** | Starting Professions | Fully Specified | 80 | NO | Mappings + generator strategy + bitmask lesson all defined; no code written (medium priority) |
| **148s** | Playerbots Start in 148h Kit | Specified | 60 | NO | B-patch + C-patch design clear; patch not written (medium priority) |
| **148b** | mod-instance-reset | Declined | — | — | 5/hour cap acceptable; revisit if blocking in practice |
| **148c** | mod-quest-status | Declined | — | — | Players read quest text; slower pace is intentional |
| **148d** | mod-zone-difficulty | Declined | — | — | Uldaman default tuning stands for v1 |
| **148e** | mod-account-achievements | Declined | — | — | Achievements not a focus; per-character is default |
| **148f** | mod-server-auto-shutdown | Declined | — | — | Manual restarts OK; revisit if vanilla goes public |
| **148g** | Class Combination Modifier | Promoted to 716 | — | — | Cross-profile system; now in phase-7 cluster |

---

## CRITICAL BLOCKERS TO VANILLA SHIP

The following **must be completed** before vanilla can launch:

1. **148h** (Starting Equipment) — without this, level-20 characters are naked
   and unplayable
2. **148i** (Flight Paths) — core to the "small, deliberate world" design
3. **148j** (Level-20 Ability Pretrain) — without this, level-20 characters
   don't have their spell roster
4. **148k** (Auto-Equip Kit) — requires 148h and 148j; makes kit visible on
   character-select
5. **148a** (DK Disablement) — prevents broken DK creation experience
6. **148o** (Validation Matrix) — currently pending; one blocker (Sun Rock
   anchor) was fixed 2026-07-13 but the full 52-character reroll matrix has not
   been executed

---

## NEXT STEPS FOR COMPLETION

**Immediate (Week 1):**
- Execute 148o's 52-character reroll matrix against the test-dev account to
  validate all anchors and kits
- Implement 148h's SQL generation and apply-form patches
- Implement 148j's SQL generation and pretrain migration
- Implement 148k's Lua auto-equip hook (depends on 148h + 148j)

**Short-term (Week 2-3):**
- Implement 148i's flight-path removal with flavor gossip
- Implement 148a's DK disablement config patch
- Implement 148m's XP rate + talent bonus (C-patch + Lua)
- Implement 148n's finalized per-race zone coordinate updates in live DB

**Medium-term (Week 3-4, non-blocking):**
- Implement 148l's mount level requirements (optional, low-priority flavor)
- Build 148q's profession generator + SQL migrations
- Build 148s's playerbots kit-gearing B-patch
- Start 148p's wand rebalance work (lowest priority, can ship as placeholder)

--------------------------------------------------------------------------------

