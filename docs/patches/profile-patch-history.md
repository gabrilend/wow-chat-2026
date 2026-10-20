# Each Profile's Patch History, Until the Headers (issue 189c)

*Copied word for word on 2026-10-20 from the per-profile lists in
`patches/patches.sh` (`PHASE_BEGIN_PATCHES`, `PHASE_END_PATCHES`), when issue 189c
replaced them with each patch's own header. The notes after each list were
the record of why each patch joined or left a profile, and are kept here as
that record. Which profiles take a patch, and in what order, is now in its
header: `scripts/plan-patches <project> <profile>` lists it.*

```bash
# {{{ Profile-specific patch lists
# PHASE_BEGIN patches (pre-compile source modifications)
# vanilla applies only compile-fix patches — no ALE engine patches
# (vanilla has no ALE), no wow-chat feature patches (no accuracy cap,
# no talent-bonus, no symmetric aggro). The 13 patches listed are the
# subset of release's patches that fix compilation against the current
# toolchain WITHOUT changing gameplay behaviour. See issue 148 for the
# full walk and the rationale per skipped patch.
declare -A PHASE_BEGIN_PATCHES=(
    ["release"]="B004 B020 B022 B024 B026 B027 B056 B057"  # 2026-10-20: +B057 (195: the most a view distance may be, and whether instances keep their forced distances, as worldserver.conf settings, stock values by default). 2026-10-20: +B056 (194: a bot sees no farther than the bot module ever looks or acts, every map; with C039's 250 in instances and battlegrounds). 2026-10-09 (pin move to core 2a2211cd8f3d): -B009 -B012 -B013 -B014 -B015 -B017 -B018 -B021 -B023 retired (warning fixes the build's compiler no longer warns about, even unpatched, at the old pin and the new; B015 and B023 also already done upstream; B021 broke upstream's not-found checks). 2026-10-03: -B016 -B019 retired (upstream has all of B016; B019 had only harmful or empty edits left; scripts/verify-patches). +B027 (2026-07-21, issue 308: Engine::Init stale-facade guard, companion to B026); +B026 (2026-07-16, bot-login Engine::Init crash guard+diagnostic); warning fixes + mod-playerbots + mod-ale compat + ALE registry lock fix + runtime conf-dir override + ALE FormatQuery lifetime fix + symmetric aggro radius (B011 removed — upstream mod-ale now matches core, patch became harmful; B010 removed 2026-07-16 — upstream now ships ARENA_TYPE_NONE)
    ["beta"]="B002 B003 B004 B005 B006 B007 B020 B022 B024 B026 B027 B056 B057"  # 2026-10-20: +B057 (195: the most a view distance may be, and whether instances keep their forced distances, as worldserver.conf settings, stock values by default). 2026-10-20: +B056 (194: a bot sees only as far as the bot module ever looks or acts, so beta's players can see wow-chat-1's 333 yards, C037). 2026-10-19: -B055 retired before any build (211a: the game already saves the battleground join spot to character_entry_point; the script asks for a save and reads it). -B008 (2026-10-09: the talent-bonus module it linked in was set aside in 405 and is no longer in the project; beta stopped before compiling, "module folder missing"). -B001 (2026-10-09: the loot module is now AzerothCore's own, which needs neither fix). 2026-10-09 (pin move to core 2a2211cd8f3d): -B009 -B012 -B013 -B014 -B015 -B017 -B018 -B021 -B023 retired (warning fixes the build's compiler no longer warns about, even unpatched, at the old pin and the new; B015 and B023 also already done upstream; B021 broke upstream's not-found checks). 2026-10-03: -B016 -B019 retired (upstream has all of B016; B019 had only harmful or empty edits left; scripts/verify-patches). +B027 (2026-07-21, issue 308: Engine::Init stale-facade guard, companion to B026); +B026 (2026-07-16, bot-login crash guard+diagnostic); All patches (B011 removed — see release-line note; B010 removed 2026-07-16 — upstream now ships ARENA_TYPE_NONE)
    ["alpha"]=""  # -B001 (2026-10-09: alpha has no loot module). 2026-10-09: -B004 (its edits are to files the alpha tree does not have: mod-ale, and a formation file of a newer core; it had failed as stale since 2026-10-03). Minimal compatibility patches
    ["vanilla"]="B002 B004 B020 B022 B025 B026 B027 B056 B057"  # 2026-10-20: +B057 (195: the most a view distance may be, and whether instances keep their forced distances, as worldserver.conf settings, stock values by default). 2026-10-20: +B056 (194: a bot sees no farther than the bot module ever looks or acts, every map; with C039's 250 in instances and battlegrounds). -B001 (2026-10-09: the loot module is now AzerothCore's own, which needs neither fix). 2026-10-09 (pin move to core 2a2211cd8f3d): -B009 -B012 -B013 -B014 -B015 -B017 -B018 -B021 -B023 retired (warning fixes the build's compiler no longer warns about, even unpatched, at the old pin and the new; B015 and B023 also already done upstream; B021 broke upstream's not-found checks). 2026-10-03: -B016 -B019 retired (upstream has all of B016; B019 had only harmful or empty edits left; scripts/verify-patches). +B027 (2026-07-21, issue 308: Engine::Init stale-facade guard, companion to B026). +B026 (2026-07-16, bot-login crash guard+diagnostic). 2026-06-02: ALE added per 148k. Compile fixes + B001 (aoe-loot/ALE compat, conditional) + B002 (playerbots×ALE login hook) + B020 + B023 (ALE thread-safety + dangling-pointer fixes — non-negotiable for ALE stability). Skipped per user OK: B003 B006 B007 (ALE feature patches not yet needed), B005 B008 B024 (wow-chat gameplay), B011 (removed everywhere). 2026-07-15: +B025 (148s — vanilla bots start in the 148h starter kit; self-scoping on the kit data, so it only takes effect on vanilla).
    ["basic"]="B002 B004 B005 B020 B022 B026 B027 B028 B029 B030 B031 B032 B033 B035 B036 B037 B038 B039 B040 B041 B042 B043 B044 B045 B046 B047 B048 B049 B050 B051 B052 B053 B054 B056 B057"  # 2026-10-20: +B057 (195: the most a view distance may be, and whether instances keep their forced distances, as worldserver.conf settings, stock values by default). 2026-10-20: +B056 (194: a bot sees no farther than the bot module ever looks or acts, every map; with C039's 250 in instances and battlegrounds). +B054 (2026-10-15, the server accepts the project's version-19 navigation tiles as well as version 20: upstream's July bump to 20 left every tile refused since the 08-22 merge, so nothing walked on a mesh; drop it once scripts/extract-maps --mmaps rebuilds them). 166: +B053 (2026-10-12, walking keeps the stock speed; only running and the rest take C003's 0.85). 617e4: +B052 (2026-10-12, a buddy's long walk never ends in the bot module's teleport onto its owner; needs B044). 617b: +B051 (2026-10-12, a Lua call asking the navigation mesh how long the walk to a point is, nil when it can't be walked; the wandering Sargobras picks a standing spot the owner can walk straight to). -B001 (2026-10-09: the loot module is now AzerothCore's own, which needs neither fix). 2026-10-09 (pin move to core 2a2211cd8f3d): -B009 -B012 -B013 -B014 -B015 -B017 -B018 -B021 -B023 retired (warning fixes the build's compiler no longer warns about, even unpatched, at the old pin and the new; B015 and B023 also already done upstream; B021 broke upstream's not-found checks). 617j3: +B050 (2026-10-04, a buddy weighs spirit by what it heals against stamina, by its stats as they stand; needs B036, after B046). issue 167: +B049 (2026-10-04, spirit heals spirit x stamina / 100 per 5 s, every class, in combat too, half for 5 s after damage). 2026-10-03: -B016 -B019 retired (upstream has all of B016; B019 had only harmful or empty edits left; scripts/verify-patches). 617h1: +B048 (2026-10-03, buddies don't whisper "My bags are full" and the other failed-item lines; a full buddy goes to a vendor instead; needs B044's companion-account list). 617f: +B047 (2026-10-03, creature outfits: a listed creature answers the client's mirror-image question with its own look, so Sargobras is drawn as the owner dressed him without a client patch; the buddy module lists him). 617j: +B046 (2026-10-02, buddies roll need/greed by their own judgement and score items by their talent plan's blend of trees; needs B036's module in the tree to link). 617a5: +B044 +B045 (2026-10-02, buddies hidden and locked: the core keeps a list of companion accounts that /who and add-friend skip, then the bot module drops chat commands to them; B045 includes B044's header, so the order matters). issue 163: +B043 (2026-09-29, "Halting process..." says who asked for the stop: file, line, exit code; stop signals by name). 617c2: +B042 (2026-09-29, a bot's automatic AI reset on a group change no longer whispers "AI was reset to defaults"; buddies change groups by distance all the time). issue 164: +B040 +B041 (2026-09-29, creatures one player cannot select: the core rule, then its Lua calls; first use, an owing death knight selects no one in Acherus but Sargobras, 718). issue 163: +B039 (2026-09-29, a silent worldserver shutdown had no log line explaining why; logs before both of CliRunnable.cpp's World::StopNow() calls instead). issue 155: +B038 (2026-09-27, 155x: nobody joins General, Trade, LocalDefense, WorldDefense, GuildRecruitment or LookingForGroup; the channel list is Basic.RefusedChannels, set by C031). +B037 (2026-09-27, 617c2: a playerbots switch for the group invite at an alt's login; basic turns it off with C030, buddies being grouped by distance). +B036 (2026-09-26, 617a1: the project's buddy module, modules/mod-buddies, copied into the build). +B035 (2026-09-25, 155r: respec cost 1, 5, 10 then +10 gold uncapped, one step off per weekly reset, floor 10). (B034, cutting a gem through the trade window, was built 2026-09-25 and dropped the same day: "too obfuscated"). +B033 (2026-09-25, 155p: white gear is never repaired; its doubled durability is E036). +B032 (2026-09-24, 155o: a buff is never refused for the target being too low level, so level-60 players can give each other the scaled high-rank scrolls). +B031 (2026-09-24, issue 803 extension, kept apart from B005 so other profiles can take either; retargeted 2026-09-27: crushing blows start at 8 levels above the target and ramp to the stock chance at 12, replacing "none from level 64+"). (2026-09-23): +B030 (155g: basic's compiled rules, first the vanilla-style talent cap). +B029 (155e: a trainer gossip option can name its trainer list, for the per-class Visiting Mentors). +B028 (155d: new characters start in their faction's rotating starting valley). vanilla's list minus B025 (bots in the vanilla starter kit — basic has no kit) plus B005 (accuracy level cap, issue 803, user directive: level gaps stop worsening hit/miss past ±3, which also makes 155f's level-64 heroics fightable at 60).
    ["cc-test"]="B002 B004 B020 B022 B026 B027 B036 B037 B042 B044 B045 B046 B047 B048 B050 B052 B054 B056 B057"  # 2026-10-20: +B057 (195: the most a view distance may be, and whether instances keep their forced distances, as worldserver.conf settings, stock values by default). 2026-10-20: +B056 (194: a bot sees no farther than the bot module ever looks or acts, every map; with C039's 250 in instances and battlegrounds). +B054 (2026-10-15, as basic: the shared version-19 navigation tiles load). 617e4: +B052 (2026-10-12, as basic: buddies never teleported onto their owner). 2026-10-09 (pin move to core 2a2211cd8f3d): -B009 -B012 -B013 -B014 -B015 -B017 -B018 -B021 -B023 retired (warning fixes the build's compiler no longer warns about, even unpatched, at the old pin and the new; B015 and B023 also already done upstream; B021 broke upstream's not-found checks). 2026-10-08, later: +the buddy module (owner: "cc-test should include it"; the Alterac Valley stand-ins are made by it, 176a1): B036 copies it in; B044 (companion-account list) and B047 (creature outfits) are core pieces it can't compile without; B037, B042, B045, B046, B048, B050 act only on buddies (or, B042, only silence a whisper) and are the behaviour basic's buddies have. issue 176 (2026-10-08): the custom client's test server, as close to stock as the build allows. Compile and warning fixes (B004 B009 B012-B015 B017 B018 B021), the runtime config-folder option (B022), ALE stability (B020 registry lock, B023 query lifetime), the bot-login crash guards (B026 B027), and bots firing ALE's login event (B002, so a scene's Lua sees its bots arrive). Left out: B001 (mod-aoe-loot is not loaded) and every gameplay patch.
)

# PHASE_END patches (post-compile setup: configs, symlinks, database)
declare -A PHASE_END_PATCHES=(
    ["release"]="E004 E006"              # Logs + configs (minimal)
    ["beta"]="E001 E004 E006 E011 E012 E013 E014 E015 E016 E017 E058 E059 E060 E061 E062 E063 E064 E065"  # 2026-10-20: +E062-E065 (193: trade, mail, /who and friends across the factions, every account on beta's realm, accounts DB). 2026-10-18: +E061 (910a: where each narrator is in its book, characters DB). 2026-10-18: +E060 (211a: where each druid returns to from Moonglade, in the characters database). 2026-10-18: +E059 (909: the narrators' books, cut from Project Gutenberg at install time; needs luajit and the network). 2026-10-17: +E058 (death knights start without the level-55 outfit they cannot use at level 1). 2026-10-17: -E005 (it wrote death knight stats into player_levelstats, a table the server no longer reads; the server reads player_class_stats, which E011 fills). Lua symlinks + logs + configs + DK class system (E011) + drop-creatures (E012, destructive) + quest-spells-to-trainers (E013) + trainer-spell-level-cap (E014, destructive) + class-selector-npcs (E015) + empty-loot-chests (E016) + playerbots logout-texts migration fix (E017)
    ["alpha"]="E004 E006"                # Logs + configs (same as release)
    ["vanilla"]="E001 E004 E006 E007 E008 E009 E010 E019 E020 E021"  # 2026-06-02: E001 added for ALE (per 148k). E001 now profile-aware — symlinks src/lua-vanilla/ into installed-files-vanilla/bin/lua_scripts/custom/. Plus: configs + starting-zones SQL (148h, E007) + flight-path removal SQL (148i, E008) + starting-equipment SQL (148h, E009) + pretrain-abilities SQL (148j, E010) + kit RequiredLevel cap (148h, E018, lets level-20 chars equip the kit) + no-intro-cinematic trigger (E019, skips race intro on first login) + mount level requirements (148l, E020, Classic 40/60 riding gates) + starting professions (148q, E021, gathering+production at skill 125 with recipes & tools). No DK stats (DK disabled per 148a/CP8).
    ["basic"]="E001 E004 E006 E008 E019 E020 E022 E023 E024 E025 E026 E027 E028 E029 E030 E031 E032 E033 E036 E037 E038 E039 E040 E042 E043 E044 E045 E046 E049 E050 E052 E053 E054 E055 E056 E057"  # 2026-10-15: +E057 (624: the Eternal Belt Buckle usable from level 60; its source is still to be chosen). 2026-10-09: +E056 (617t1: the kept stand-ins, characters DB). 2026-10-08: +E055 (617e12: the smaller places buddies roam, named areas cut by monster kinds and steep ground; scripts/generate-buddy-subareas). +E054 (issue 182: the game's legendaries as level-60 raid drops; scripts/generate-basic-legendaries-sql). +E053 (the `command` rows for the project's compiled GM commands: .help text, and the GM level that may run them, which also makes .basic reload multipliers and .basic worldboss usable in game; scripts/generate-custom-command-help-sql). 617r2: +E052 (2026-10-05, every gearset profile as rows of gearset_item, for the buddy module to dress new buddies from). 718: +E051 (2026-10-05, Acherus sells the story's reward choices: Lady Alistra the cloaks, Razuvious the two-handers, 1 gold, worthless to other vendors). 617e4a: +E050 (2026-10-03, the world's little towns as circles found from the helpful people in them, plus circles placed by hand; buddies do town things inside one). 617o3: +E049 (2026-10-03, every town's exploring grid baked ahead of time by scripts/bake-buddy-towns into DataDir/buddy-towns/, so buddies cross a town by its distance maps from their first visit; skipped, and says so, until E044's table is loaded). issue 155: +E048 (2026-09-28, 617a4: the buddies' level-20 kit items wearable at 20, originals saved). +E046, E047 (2026-09-27, 155j: the world bosses respawned by hand, a countdown slowed by players nearby; the list and year-long stock delay, world DB; the countdowns, characters DB). +E045 (2026-09-27, 617e4: the beds buddies sleep on, placed by hand). +E044 (2026-09-27, 617e2: every named area's borders and middle, for buddy roaming, generated from the map files). +E043 (2026-09-26, 617b: Sargobras the buddy selector, a valley one per starting valley). +E042 (2026-09-26, 617a1: the buddy clan and roster tables, characters DB). +E040, E041 (2026-09-25, 718: Sargobras at the gate of Acherus, and the soul ledger for the death knight sacrifice). +E039 (2026-09-25, 617l: no guild banks; every Guild Vault removed). +E038 (2026-09-25, 155l: the Dark Portal as the only door into Outland; the other portals removed). +E037 (2026-09-25, 155q: class books for the level 61-80 abilities, dropping in Ahn'Qiraj, from the Emerald Dragons and in Naxxramas). +E036 (2026-09-25, 155p: white gear durability doubled; B033 makes it never repaired). +E035 (2026-09-25, 155p stage 3: sockets on capital whites and vanilla dungeon blues). +E034 (2026-09-25, 155p stage 2: titan-site crystal traders and masterwork jewelcrafters; after E027, E033). +E033 (2026-09-25, 155p: gem supply: prospecting, Wrath and epic gems, cutting recipes at 300, Onyxia's hoard; after E024, E027, E032). +E032 (2026-09-24, 155k: Outland world monsters +4, the Isle +6). +E031 (2026-09-24, 155k/155f: Outland gear rescaled onto the level-60 ladder; after E024, whose template list it reads). +E030 (2026-09-24, 155o: Darkmoon items never bind; Burning Crusade cards from Tempest Keep and Magisters' Terrace bosses). +E029 (2026-09-24, 155o: Inscription without glyphs; after E027). +E028 (2026-09-24, 155l: Outland without quests, no Shattrath portal to the Isle). +E027 (2026-09-24, 155n: Outland without tradeskills). +E026 (2026-09-24, 155i: the per-creature damage/healing/health multiplier table read by basic_rules.cpp). (2026-09-23): +E025 (155e: a Visiting Mentor per valley for the classes it lacks). +E024 (155f: Outland dungeons a level 60 can enter at level 64; open world stock). +E023 (155d rotation-state table, characters DB). Lua link (src/lua-basic/) + logs + configs + flight-path removal (E008) + no intro cinematic (E019) + Classic riding gates 40/60 (E020) + quests open to the whole faction (E022, 155e). Left out on purpose: E007 level-20 spawn towns (basic spawns in the level-1 valleys), E009/E018 starter kit, E010 pretrained abilities, E021 starting professions — all head-start.
    ["cc-test"]="E001 E004 E006 E042 E044 E045 E050 E052 E053 E056"  # 2026-10-09: +E056 (617t1: the kept stand-ins; the scenes ask for theirs). issue 176 (2026-10-08): the Lua link (src/lua-cc-test/), the log folder, the config files; then the buddy module's own data, read from basic's sources (_buddy_sql_src): its roster and clan tables (E042), area centres (E044), beds and boardings (E045), town circles (E050), gearsets (E052). Left out: the buddy selector NPCs (E043, placed in basic's starting valleys), the baked town grids (E049, towns are measured live without them), the level-20 kit change to items (E048), and every change to the stock world.
)
# }}}
```

## The patch registry's hand-kept tables, until the lists were generated (issue 189f)

*Moved word for word on 2026-10-20 from `patch-registry.md`, when issue 189f
made its list of patches from their headers. They describe the build as it
was first designed (three stages, settings after promote), which had already
changed before 2026-10-20; they are kept as the record they are.*

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
| B001 | aoe-loot-item-namespace                 | mod-aoe-loot/src/aoe_loot.cpp                           | **Retired 2026-10-09**: the loot module is now AzerothCore's own (azerothcore/mod-aoe-loot), which compiles against the core unpatched. Was: Fix `Item` vs `WorldPackets::Item` ambiguity; since 2026-10-09 also the packet hook's read-only signature (the new core dropped the other) |
| B002 | playerbots-ale-login-hook               | mod-playerbots/src/Bot/PlayerbotMgr.cpp, mod-playerbots.cmake | Trigger PLAYER_EVENT_ON_LOGIN for bots |
| B003 | ale-gameobject-wildcard                 | mod-ale/src/LuaEngine/LuaEngine.cpp                     | Enable entry 0 as wildcard for gameobject events |
| B004 | upstream-warning-fixes                  | core: FormationMovementGenerator.cpp                    | Since 2026-10-09 only: formation followers' near-zero speed (a log flood) |
| B005 | accuracy-level-cap                      | src/server/game/Entities/Unit/*                         | Cap level diff for hit/miss at ±3 |
| B006 | ale-sell-item-hook                      | mod-ale/*, Handlers/ItemHandler.cpp                     | Add PLAYER_EVENT_ON_SELL_ITEM = 74 |
| B007 | ale-unit-methods                        | mod-ale/*/UnitMethods.h, LuaFunctions.cpp               | Add SetWalk, IsWalking, IsHostileTo, IsFriendlyTo |
| B008 | mod-talent-bonus                        | modules/mod-talent-bonus                                | **Retired 2026-10-09**: the module was set aside in 405 and is not in the project. Was: Link local module for compilation |
| B009 | playerbots-equipment-slots-enum         | mod-playerbots                                          | **Retired 2026-10-09** (pin move): playerbots no longer forward-declares the enum, at either pin. Was: Forward-declare `enum EquipmentSlots : uint32;` |
| B010 | playerbots-arena-type-none              | mod-playerbots                                          | `if (type != ARENA_TYPE_NONE)` enum comparison fix |
| B011 | ale-resurrect-signature                 | mod-ale                                                 | Reconcile `bool&` vs `bool` mismatch with current core |
| B012 | player-equipment-slot-sign              | core                                                    | **Retired 2026-10-09** (pin move): no warning with the build's compiler, unpatched, at either pin. Was: Fix int vs `EquipmentSlots` sign-compare warning |
| B013 | playerbots-logical-op-parentheses       | mod-playerbots                                          | `&&` within `||` parens (-Wlogical-op-parentheses) |
| B014 | playerbots-switch-enum-default          | mod-playerbots                                          | **Retired 2026-10-09** (pin move): no warning with the build's compiler, unpatched, at either pin. Was: Missing case values for `WSBotStrategy` (-Wswitch) |
| B015 | playerbots-implicit-float-conversion    | mod-playerbots                                          | **Retired 2026-10-09** (pin move): its file and line are gone upstream; it already did nothing at the old pin. Was: int→float value-change warning |
| B016 | playerbots-constructor-reorder          | mod-playerbots                                          | **Retired 2026-10-03**: upstream has the fix. Was: Field-init order (-Wreorder-ctor) |
| B017 | playerbots-unused-variables             | mod-playerbots                                          | **Retired 2026-10-09** (pin move): no warning with the build's compiler, unpatched, at either pin. Was: -Wunused-variable cleanup |
| B018 | playerbots-sign-compare                 | mod-playerbots                                          | **Retired 2026-10-09** (pin move): no warning with the build's compiler, unpatched, at either pin. Was: Signed/unsigned compare warnings |
| B019 | playerbots-unused-parameter             | mod-playerbots                                          | **Retired 2026-10-03**: upstream has the fix. Was: -Wunused-parameter cleanup |
| B020 | ale-event-removeevent-lock              | mod-ale                                                 | Add LOCK_ALE around `ALEEventProcessor::RemoveEvent` |
| B021 | playerbots-misc-warnings                | mod-playerbots                                          | **Retired 2026-10-09** (pin move): no warning unpatched; worse, widening to size_t broke upstream's `== uint32(-1)` not-found checks (an endless loop in bot outfit parsing). Was: Catch-all bundle for residual one-off warnings |
| B022 | runtime-conf-dir-override               | core                                                    | Runtime `--conf-dir` override (avoids cmake-baked path) |
| B023 | ale-formatquery-lifetime                | mod-ale                                                 | **Retired 2026-10-09** (pin move): fixed upstream in mod-ale bd74eae. Was: Fix variadic format-arg lifetime in FormatQuery |
| B024 | symmetric-aggro-radius                  | core                                                    | Make `Creature::GetAttackDistance` symmetric |
| B055 | ale-player-entry-point                  | mod-ale/*/PlayerMethods.h, LuaFunctions.cpp             | **Retired 2026-10-19, before any build**: the game already saves the join spot to `character_entry_point`, which the script reads after asking for a save. Was: add `player:GetEntryPoint()` (issue 211a; `ale-player-entry-point.md`) |

(B025 to B054 are not listed in this table yet: each script's header in
`patches/` describes it, and `patches/patches.sh` says which profiles use
it.)

Per-patch source of truth lives in `patches/B###-*.sh` — each script's
header comments document the upstream symptom, the matched pattern, and
the inverse-unpatch operation. Detailed write-ups for the older B-patches
(B001–B008) follow below; the B009+ family is generally one-warning-at-a-time
and is documented in the scripts themselves rather than duplicated here.

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

