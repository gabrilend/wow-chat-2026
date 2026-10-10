#!/usr/bin/env bash
# patches.sh - Load all patch files and provide apply/unapply functions
# Sourced by scripts/azerothcore
#
# Each patch file defines:
#   patch_B00X_name()   - Apply the patch
#   unpatch_B00X_name() - Reverse the patch
#
# Both functions must be idempotent (safe to run multiple times)

# Get directory containing this script
PATCHES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all B### patch files (PHASE_BEGIN - source code modifications)
for patch_file in "${PATCHES_DIR}"/B[0-9][0-9][0-9]-*.sh; do
    [[ -f "${patch_file}" ]] && source "${patch_file}"
done

# Source E patches (PHASE_END - config files, symlinks, database)
if [[ -f "${PATCHES_DIR}/E-patches.sh" ]]; then
    source "${PATCHES_DIR}/E-patches.sh"
fi

# {{{ Profile-specific patch lists
# PHASE_BEGIN patches (pre-compile source modifications)
# vanilla applies only compile-fix patches — no ALE engine patches
# (vanilla has no ALE), no wow-chat feature patches (no accuracy cap,
# no talent-bonus, no symmetric aggro). The 13 patches listed are the
# subset of release's patches that fix compilation against the current
# toolchain WITHOUT changing gameplay behaviour. See issue 148 for the
# full walk and the rationale per skipped patch.
declare -A PHASE_BEGIN_PATCHES=(
    ["release"]="B004 B020 B022 B024 B026 B027"  # 2026-10-09 (pin move to core 2a2211cd8f3d): -B009 -B012 -B013 -B014 -B015 -B017 -B018 -B021 -B023 retired (warning fixes the build's compiler no longer warns about, even unpatched, at the old pin and the new; B015 and B023 also already done upstream; B021 broke upstream's not-found checks). 2026-10-03: -B016 -B019 retired (upstream has all of B016; B019 had only harmful or empty edits left; scripts/verify-patches). +B027 (2026-07-21, issue 308: Engine::Init stale-facade guard, companion to B026); +B026 (2026-07-16, bot-login Engine::Init crash guard+diagnostic); warning fixes + mod-playerbots + mod-ale compat + ALE registry lock fix + runtime conf-dir override + ALE FormatQuery lifetime fix + symmetric aggro radius (B011 removed — upstream mod-ale now matches core, patch became harmful; B010 removed 2026-07-16 — upstream now ships ARENA_TYPE_NONE)
    ["beta"]="B002 B003 B004 B005 B006 B007 B020 B022 B024 B026 B027"  # -B008 (2026-10-09: the talent-bonus module it linked in was set aside in 405 and is no longer in the project; beta stopped before compiling, "module folder missing"). -B001 (2026-10-09: the loot module is now AzerothCore's own, which needs neither fix). 2026-10-09 (pin move to core 2a2211cd8f3d): -B009 -B012 -B013 -B014 -B015 -B017 -B018 -B021 -B023 retired (warning fixes the build's compiler no longer warns about, even unpatched, at the old pin and the new; B015 and B023 also already done upstream; B021 broke upstream's not-found checks). 2026-10-03: -B016 -B019 retired (upstream has all of B016; B019 had only harmful or empty edits left; scripts/verify-patches). +B027 (2026-07-21, issue 308: Engine::Init stale-facade guard, companion to B026); +B026 (2026-07-16, bot-login crash guard+diagnostic); All patches (B011 removed — see release-line note; B010 removed 2026-07-16 — upstream now ships ARENA_TYPE_NONE)
    ["alpha"]=""  # -B001 (2026-10-09: alpha has no loot module). 2026-10-09: -B004 (its edits are to files the alpha tree does not have: mod-ale, and a formation file of a newer core; it had failed as stale since 2026-10-03). Minimal compatibility patches
    ["vanilla"]="B002 B004 B020 B022 B025 B026 B027"  # -B001 (2026-10-09: the loot module is now AzerothCore's own, which needs neither fix). 2026-10-09 (pin move to core 2a2211cd8f3d): -B009 -B012 -B013 -B014 -B015 -B017 -B018 -B021 -B023 retired (warning fixes the build's compiler no longer warns about, even unpatched, at the old pin and the new; B015 and B023 also already done upstream; B021 broke upstream's not-found checks). 2026-10-03: -B016 -B019 retired (upstream has all of B016; B019 had only harmful or empty edits left; scripts/verify-patches). +B027 (2026-07-21, issue 308: Engine::Init stale-facade guard, companion to B026). +B026 (2026-07-16, bot-login crash guard+diagnostic). 2026-06-02: ALE added per 148k. Compile fixes + B001 (aoe-loot/ALE compat, conditional) + B002 (playerbots×ALE login hook) + B020 + B023 (ALE thread-safety + dangling-pointer fixes — non-negotiable for ALE stability). Skipped per user OK: B003 B006 B007 (ALE feature patches not yet needed), B005 B008 B024 (wow-chat gameplay), B011 (removed everywhere). 2026-07-15: +B025 (148s — vanilla bots start in the 148h starter kit; self-scoping on the kit data, so it only takes effect on vanilla).
    ["basic"]="B002 B004 B005 B020 B022 B026 B027 B028 B029 B030 B031 B032 B033 B035 B036 B037 B038 B039 B040 B041 B042 B043 B044 B045 B046 B047 B048 B049 B050"  # -B001 (2026-10-09: the loot module is now AzerothCore's own, which needs neither fix). 2026-10-09 (pin move to core 2a2211cd8f3d): -B009 -B012 -B013 -B014 -B015 -B017 -B018 -B021 -B023 retired (warning fixes the build's compiler no longer warns about, even unpatched, at the old pin and the new; B015 and B023 also already done upstream; B021 broke upstream's not-found checks). 617j3: +B050 (2026-10-04, a buddy weighs spirit by what it heals against stamina, by its stats as they stand; needs B036, after B046). issue 167: +B049 (2026-10-04, spirit heals spirit x stamina / 100 per 5 s, every class, in combat too, half for 5 s after damage). 2026-10-03: -B016 -B019 retired (upstream has all of B016; B019 had only harmful or empty edits left; scripts/verify-patches). 617h1: +B048 (2026-10-03, buddies don't whisper "My bags are full" and the other failed-item lines; a full buddy goes to a vendor instead; needs B044's companion-account list). 617f: +B047 (2026-10-03, creature outfits: a listed creature answers the client's mirror-image question with its own look, so Sargobras is drawn as the owner dressed him without a client patch; the buddy module lists him). 617j: +B046 (2026-10-02, buddies roll need/greed by their own judgement and score items by their talent plan's blend of trees; needs B036's module in the tree to link). 617a5: +B044 +B045 (2026-10-02, buddies hidden and locked: the core keeps a list of companion accounts that /who and add-friend skip, then the bot module drops chat commands to them; B045 includes B044's header, so the order matters). issue 163: +B043 (2026-09-29, "Halting process..." says who asked for the stop: file, line, exit code; stop signals by name). 617c2: +B042 (2026-09-29, a bot's automatic AI reset on a group change no longer whispers "AI was reset to defaults"; buddies change groups by distance all the time). issue 164: +B040 +B041 (2026-09-29, creatures one player cannot select: the core rule, then its Lua calls; first use, an owing death knight selects no one in Acherus but Sargobras, 718). issue 163: +B039 (2026-09-29, a silent worldserver shutdown had no log line explaining why; logs before both of CliRunnable.cpp's World::StopNow() calls instead). issue 155: +B038 (2026-09-27, 155x: nobody joins General, Trade, LocalDefense, WorldDefense, GuildRecruitment or LookingForGroup; the channel list is Basic.RefusedChannels, set by C031). +B037 (2026-09-27, 617c2: a playerbots switch for the group invite at an alt's login; basic turns it off with C030, buddies being grouped by distance). +B036 (2026-09-26, 617a1: the project's buddy module, modules/mod-buddies, copied into the build). +B035 (2026-09-25, 155r: respec cost 1, 5, 10 then +10 gold uncapped, one step off per weekly reset, floor 10). (B034, cutting a gem through the trade window, was built 2026-09-25 and dropped the same day: "too obfuscated"). +B033 (2026-09-25, 155p: white gear is never repaired; its doubled durability is E036). +B032 (2026-09-24, 155o: a buff is never refused for the target being too low level, so level-60 players can give each other the scaled high-rank scrolls). +B031 (2026-09-24, issue 803 extension, kept apart from B005 so other profiles can take either; retargeted 2026-09-27: crushing blows start at 8 levels above the target and ramp to the stock chance at 12, replacing "none from level 64+"). (2026-09-23): +B030 (155g: basic's compiled rules, first the vanilla-style talent cap). +B029 (155e: a trainer gossip option can name its trainer list, for the per-class Visiting Mentors). +B028 (155d: new characters start in their faction's rotating starting valley). vanilla's list minus B025 (bots in the vanilla starter kit — basic has no kit) plus B005 (accuracy level cap, issue 803, user directive: level gaps stop worsening hit/miss past ±3, which also makes 155f's level-64 heroics fightable at 60).
    ["cc-test"]="B002 B004 B020 B022 B026 B027 B036 B037 B042 B044 B045 B046 B047 B048 B050"  # 2026-10-09 (pin move to core 2a2211cd8f3d): -B009 -B012 -B013 -B014 -B015 -B017 -B018 -B021 -B023 retired (warning fixes the build's compiler no longer warns about, even unpatched, at the old pin and the new; B015 and B023 also already done upstream; B021 broke upstream's not-found checks). 2026-10-08, later: +the buddy module (owner: "cc-test should include it"; the Alterac Valley stand-ins are made by it, 176a1): B036 copies it in; B044 (companion-account list) and B047 (creature outfits) are core pieces it can't compile without; B037, B042, B045, B046, B048, B050 act only on buddies (or, B042, only silence a whisper) and are the behaviour basic's buddies have. issue 176 (2026-10-08): the custom client's test server, as close to stock as the build allows. Compile and warning fixes (B004 B009 B012-B015 B017 B018 B021), the runtime config-folder option (B022), ALE stability (B020 registry lock, B023 query lifetime), the bot-login crash guards (B026 B027), and bots firing ALE's login event (B002, so a scene's Lua sees its bots arrive). Left out: B001 (mod-aoe-loot is not loaded) and every gameplay patch.
)

# PHASE_END patches (post-compile setup: configs, symlinks, database)
declare -A PHASE_END_PATCHES=(
    ["release"]="E004 E006"              # Logs + configs (minimal)
    ["beta"]="E001 E004 E005 E006 E011 E012 E013 E014 E015 E016 E017"  # Lua symlinks + logs + configs + DK levelstats (E005) + DK class system (E011) + drop-creatures (E012, destructive) + quest-spells-to-trainers (E013) + trainer-spell-level-cap (E014, destructive) + class-selector-npcs (E015) + empty-loot-chests (E016) + playerbots logout-texts migration fix (E017)
    ["alpha"]="E004 E006"                # Logs + configs (same as release)
    ["vanilla"]="E001 E004 E006 E007 E008 E009 E010 E018 E019 E020 E021"  # 2026-06-02: E001 added for ALE (per 148k). E001 now profile-aware — symlinks src/lua-vanilla/ into installed-files-vanilla/bin/lua_scripts/custom/. Plus: configs + starting-zones SQL (148h, E007) + flight-path removal SQL (148i, E008) + starting-equipment SQL (148h, E009) + pretrain-abilities SQL (148j, E010) + kit RequiredLevel cap (148h, E018, lets level-20 chars equip the kit) + no-intro-cinematic trigger (E019, skips race intro on first login) + mount level requirements (148l, E020, Classic 40/60 riding gates) + starting professions (148q, E021, gathering+production at skill 125 with recipes & tools). No DK stats (DK disabled per 148a/CP8).
    ["basic"]="E001 E004 E006 E008 E019 E020 E022 E023 E024 E025 E026 E027 E028 E029 E030 E031 E032 E033 E034 E035 E036 E037 E038 E039 E040 E041 E042 E043 E044 E045 E046 E047 E048 E049 E050 E051 E052 E053 E054 E055 E056"  # 2026-10-09: +E056 (617t1: the kept stand-ins, characters DB). 2026-10-08: +E055 (617e12: the smaller places buddies roam, named areas cut by monster kinds and steep ground; scripts/generate-buddy-subareas). +E054 (issue 182: the game's legendaries as level-60 raid drops; scripts/generate-basic-legendaries-sql). +E053 (the `command` rows for the project's compiled GM commands: .help text, and the GM level that may run them, which also makes .basic reload multipliers and .basic worldboss usable in game; scripts/generate-custom-command-help-sql). 617r2: +E052 (2026-10-05, every gearset profile as rows of gearset_item, for the buddy module to dress new buddies from). 718: +E051 (2026-10-05, Acherus sells the story's reward choices: Lady Alistra the cloaks, Razuvious the two-handers, 1 gold, worthless to other vendors). 617e4a: +E050 (2026-10-03, the world's little towns as circles found from the helpful people in them, plus circles placed by hand; buddies do town things inside one). 617o3: +E049 (2026-10-03, every town's exploring grid baked ahead of time by scripts/bake-buddy-towns into DataDir/buddy-towns/, so buddies cross a town by its distance maps from their first visit; skipped, and says so, until E044's table is loaded). issue 155: +E048 (2026-09-28, 617a4: the buddies' level-20 kit items wearable at 20, originals saved). +E046, E047 (2026-09-27, 155j: the world bosses respawned by hand, a countdown slowed by players nearby; the list and year-long stock delay, world DB; the countdowns, characters DB). +E045 (2026-09-27, 617e4: the beds buddies sleep on, placed by hand). +E044 (2026-09-27, 617e2: every named area's borders and middle, for buddy roaming, generated from the map files). +E043 (2026-09-26, 617b: Sargobras the buddy selector, a valley one per starting valley). +E042 (2026-09-26, 617a1: the buddy clan and roster tables, characters DB). +E040, E041 (2026-09-25, 718: Sargobras at the gate of Acherus, and the soul ledger for the death knight sacrifice). +E039 (2026-09-25, 617l: no guild banks; every Guild Vault removed). +E038 (2026-09-25, 155l: the Dark Portal as the only door into Outland; the other portals removed). +E037 (2026-09-25, 155q: class books for the level 61-80 abilities, dropping in Ahn'Qiraj, from the Emerald Dragons and in Naxxramas). +E036 (2026-09-25, 155p: white gear durability doubled; B033 makes it never repaired). +E035 (2026-09-25, 155p stage 3: sockets on capital whites and vanilla dungeon blues). +E034 (2026-09-25, 155p stage 2: titan-site crystal traders and masterwork jewelcrafters; after E027, E033). +E033 (2026-09-25, 155p: gem supply: prospecting, Wrath and epic gems, cutting recipes at 300, Onyxia's hoard; after E024, E027, E032). +E032 (2026-09-24, 155k: Outland world monsters +4, the Isle +6). +E031 (2026-09-24, 155k/155f: Outland gear rescaled onto the level-60 ladder; after E024, whose template list it reads). +E030 (2026-09-24, 155o: Darkmoon items never bind; Burning Crusade cards from Tempest Keep and Magisters' Terrace bosses). +E029 (2026-09-24, 155o: Inscription without glyphs; after E027). +E028 (2026-09-24, 155l: Outland without quests, no Shattrath portal to the Isle). +E027 (2026-09-24, 155n: Outland without tradeskills). +E026 (2026-09-24, 155i: the per-creature damage/healing/health multiplier table read by basic_rules.cpp). (2026-09-23): +E025 (155e: a Visiting Mentor per valley for the classes it lacks). +E024 (155f: Outland dungeons a level 60 can enter at level 64; open world stock). +E023 (155d rotation-state table, characters DB). Lua link (src/lua-basic/) + logs + configs + flight-path removal (E008) + no intro cinematic (E019) + Classic riding gates 40/60 (E020) + quests open to the whole faction (E022, 155e). Left out on purpose: E007 level-20 spawn towns (basic spawns in the level-1 valleys), E009/E018 starter kit, E010 pretrained abilities, E021 starting professions — all head-start.
    ["cc-test"]="E001 E004 E006 E042 E044 E045 E050 E052 E053 E056"  # 2026-10-09: +E056 (617t1: the kept stand-ins; the scenes ask for theirs). issue 176 (2026-10-08): the Lua link (src/lua-cc-test/), the log folder, the config files; then the buddy module's own data, read from basic's sources (_buddy_sql_src): its roster and clan tables (E042), area centres (E044), beds and boardings (E045), town circles (E050), gearsets (E052). Left out: the buddy selector NPCs (E043, placed in basic's starting valleys), the baked town grids (E049, towns are measured live without them), the level-20 kit change to items (E048), and every change to the stock world.
)
# }}}

# {{{ reset_source_trees
# Unconditional pre-flight cleanup called at the top of high-level
# workflow scripts (update, install, compile). Hard-resets the main
# source tree and every module beneath it to their respective HEADs.
#
# Why unconditional rather than only-if-dirty?
#   Source trees are build artifacts per issue 136's fourth-path design
#   — regenerable from upstream + the patch system, and any working-tree
#   change is by definition discardable since real customizations live
#   in patches/B###*.sh. Hard-reset on a clean tree is a no-op, so a
#   dirty-check adds complexity without value. Doing it always means the
#   precondition "source matches HEAD" is guaranteed at every call site,
#   no matter what dirt the previous session left behind.
#
# Why hard-reset and not unapply_patches_begin?
#   Unapply was the original approach but it has a fundamental bug: each
#   unpatch sed pattern reverts "the post-patch shape" regardless of
#   whether the patch was actually applied by us. When upstream converges
#   on the shape we patched to (e.g. upstream HEAD adopts our
#   `enum EquipmentSlots : uint32` form), unpatch silently over-reverts
#   clean code into false dirt. Calling unapply on a clean tree is NOT
#   safe — the "idempotent" promise at patches.sh:9 doesn't hold for the
#   upstream-converged case. See unapply_patches_begin's note below.
#
# What this discards:
#   - Patch residue from a previous compile that was killed in a way
#     that bypassed the EXIT trap (SIGKILL, OOM, system crash).
#   - Stale patch output from before a recent B-patch re-target.
#   - Genuine in-progress edits in source-beta or any module. Per the
#     fourth-path design these shouldn't exist; if you're prototyping a
#     patch by editing source directly, stash it before running the
#     workflow scripts or it will be discarded.
#
# Requires: ${AC_CODE_DIR} set.
reset_source_trees() {
    # Main source tree
    if [[ -d "${AC_CODE_DIR}/.git" ]]; then
        git -C "${AC_CODE_DIR}" reset --hard HEAD --quiet 2>/dev/null
    fi

    # Each module is its own git repo cloned into modules/ per the
    # fourth-path design (issue 136). Each can drift independently of
    # the main source tree and needs its own reset.
    if [[ -d "${AC_CODE_DIR}/modules" ]]; then
        for mod_dir in "${AC_CODE_DIR}"/modules/*/; do
            if [[ -d "${mod_dir}/.git" ]]; then
                git -C "${mod_dir}" reset --hard HEAD --quiet 2>/dev/null
            fi
        done
    fi
}
# }}}

# {{{ line_edits_apply / line_edits_revert
# Exact whole-line edits, for the small source fixes (a cast, a type) that
# used to be sed patterns. Rewritten 2026-10-03: a pattern turned back on
# revert also matched lines upstream had since written the "fixed" way,
# and the revert changed them (scripts/verify-patches found eight patches
# doing it; one, B013, even changed a condition's meaning on apply).
#
# A patch hands its edits as a table on standard input, one per line,
# fields separated by a tab:
#     path (from the source root)  <TAB>  old line  <TAB>  new line
# a line repeated as many times as the old line occurs in the file.
# Apply: every line exactly equal to `old` becomes `new` followed by the
# tag "  // <ID>"; the old line must occur exactly as many times as the
# table names it, or nothing is changed and the patch is reported stale
# (upstream moved). Already tagged: nothing to do (repeatable). Revert:
# only lines exactly equal to `new` + tag become `old` again, so upstream's
# own lines can never be touched.
_line_edits() {
    local mode="$1" id="$2" tag="  // $2" table rel old new file want have tagged
    table="$(cat)"
    while IFS=$'\t' read -r rel old new; do
        [[ -n "${rel}" ]] || continue
        file="${AC_CODE_DIR}/${rel}"
        if [[ ! -f "${file}" ]]; then
            echo "  [${id}] ERROR: ${rel} is missing (stale patch)"
            return 1
        fi
        want="$(printf '%s\n' "${table}" | awk -F'\t' -v r="${rel}" -v o="${old}" '$1 == r && $2 == o' | wc -l)"
        tagged="$(grep -cxF -- "${new}${tag}" "${file}")"
        have="$(grep -cxF -- "${old}" "${file}")"
        if [[ "${mode}" == "apply" ]]; then
            [[ "${tagged}" -eq "${want}" ]] && continue                 # applied already
            if [[ "${have}" -ne "${want}" ]]; then
                echo "  [${id}] ERROR: ${rel}: wanted ${want} line(s) reading \"${old}\", found ${have} (stale patch)"
                return 1
            fi
            OLD="${old}" NEW="${new}${tag}" awk '$0 == ENVIRON["OLD"] { print ENVIRON["NEW"]; next } { print }' \
                "${file}" > "${file}.lineedit" && mv "${file}.lineedit" "${file}"
        else
            [[ "${tagged}" -gt 0 ]] || continue                         # nothing of ours here
            OLD="${old}" NEW="${new}${tag}" awk '$0 == ENVIRON["NEW"] { print ENVIRON["OLD"]; next } { print }' \
                "${file}" > "${file}.lineedit" && mv "${file}.lineedit" "${file}"
        fi
    done <<< "${table}"
    return 0
}
line_edits_apply()  { _line_edits apply  "$1"; }
line_edits_revert() { _line_edits revert "$1"; }
# }}}

# {{{ leave_source_trees_clean
# After the build's revert: whatever the patches' own reverts left behind is
# named (the file and the repository), then every tree is reset to its
# commit, so a build always ends on clean upstream source. Found
# 2026-10-03: some reverts match by content (a sed back from the fixed
# form), and where upstream has since adopted the same fix they un-fix
# upstream's own lines (B012 turned every "uint8 i = EQUIPMENT_SLOT_START"
# in Player.cpp into "int i"; B019 and B004 likewise in 23 bot-module
# files). The reset is the guarantee; the report says which revert needs
# rewriting. Untracked files are left alone (B036's module copy lives there).
leave_source_trees_clean() {
    local repo dirty=0
    for repo in "${AC_CODE_DIR}" "${AC_CODE_DIR}"/modules/*/; do
        [[ -d "${repo}/.git" ]] || continue
        local changed
        changed="$(git -C "${repo}" diff --name-only)"
        if [[ -n "${changed}" ]]; then
            dirty=1
            echo "  WARNING: after the patches' reverts, $(basename "${repo}") still differs from its commit in:"
            echo "${changed}" | sed 's/^/      /'
        fi
    done
    if [[ ${dirty} -eq 1 ]]; then
        echo "  (a patch's revert left those; reset to the commit now. scripts/verify-patches names the patch.)"
    fi
    reset_source_trees
}
# }}}

# {{{ apply_patches_begin
# PHASE_BEGIN: Pre-compile source fixes
# Run after clone/update, before cmake
apply_patches_begin() {
    local patches="${PHASE_BEGIN_PATCHES[$PROFILE]:-}"

    if [[ -z "${patches}" ]]; then
        echo ""
        echo "PHASE_BEGIN: No patches for profile '${PROFILE}'"
        return 0
    fi

    echo ""
    echo "Applying PHASE_BEGIN patches for profile '${PROFILE}'..."
    # A source patch that is missing or fails means the build would compile
    # without it, so stop here instead of printing "Applied" regardless (the
    # old behavior) and compiling a binary that silently lacks the change.
    # Every patch in every profile's list was checked to return success on a
    # clean tree before this became strict (scripts/test-source-patches).
    local done_ids=""
    for patch_id in ${patches}; do
        # Find the patch function (e.g., patch_B001_aoe_loot_item_namespace)
        local patch_func=$(declare -F | grep "^declare -f patch_${patch_id}_" | sed 's/declare -f //')
        if [[ -z "${patch_func}" ]]; then
            echo "  [${patch_id}] ERROR: no function patch_${patch_id}_* is defined"
            echo "  PHASE_BEGIN STOPPED — applied: ${done_ids:-none}; failed: ${patch_id}"
            return 1
        fi
        if ${patch_func}; then
            echo "  [${patch_id}] Applied: ${patch_func}"
            done_ids+="${patch_id} "
        else
            echo "  [${patch_id}] ERROR: ${patch_func} returned failure"
            echo "  PHASE_BEGIN STOPPED — applied: ${done_ids:-none}; failed: ${patch_id}"
            echo "  (the compile's exit trap reverts what was applied)"
            return 1
        fi
    done
}
# }}}

# {{{ _snapshot_dirty_state
# Internal helper: emit a stable string fingerprint of the working-tree
# dirty state across the main source tree and every module beneath it.
# Used by unapply_patches_begin to detect whether a given unpatch
# function actually changed any file content.
#
# Comparing two snapshots is sufficient because git status --porcelain
# output is line-deterministic for a given working tree, and any change
# to a file's tracked content will alter at least one porcelain line
# (status code, path, or both).
_snapshot_dirty_state() {
    if [[ -d "${AC_CODE_DIR}/.git" ]]; then
        git -C "${AC_CODE_DIR}" status --porcelain 2>/dev/null
    fi
    if [[ -d "${AC_CODE_DIR}/modules" ]]; then
        for mod_dir in "${AC_CODE_DIR}"/modules/*/; do
            if [[ -d "${mod_dir}/.git" ]]; then
                git -C "${mod_dir}" status --porcelain 2>/dev/null
            fi
        done
    fi
}
# }}}

# {{{ unapply_patches_begin
# Reverse all PHASE_BEGIN patches for the current profile.
#
# Canonical use: compile's EXIT trap calls this after build (success or
# failure) to keep source clean for the next session. In that context the
# patches WERE just applied by apply_patches_begin, so the unpatch
# functions revert real changes and the output reflects real work.
#
# Caveats — DO NOT call this defensively as a cleanup tool:
#   - Each unpatch sed pattern targets "the post-patch shape" and has no
#     way to distinguish "we applied this" from "upstream now ships
#     this." When upstream converges on the patched form, the unpatch
#     silently reverts clean code into false dirt. For defensive cleanup,
#     use reset_source_trees() instead, which hard-resets to HEAD and
#     can't introduce false dirt.
#
# Per-patch reporting: snapshots the dirty state before and after each
# unpatch call. Only prints `[BXXX] Reverted` when the call actually
# changed file content. No-ops stay silent. The summary at the end says
# how many were no-ops so the absence-of-output isn't ambiguous.
unapply_patches_begin() {
    local patches="${PHASE_BEGIN_PATCHES[$PROFILE]:-}"

    if [[ -z "${patches}" ]]; then
        return 0
    fi

    echo ""
    echo "Reverting PHASE_BEGIN patches for profile '${PROFILE}'..."

    local reverted=0
    local noop=0
    for patch_id in ${patches}; do
        local unpatch_func
        unpatch_func=$(declare -F | grep "^declare -f unpatch_${patch_id}_" | sed 's/declare -f //')
        if [[ -z "${unpatch_func}" ]]; then
            continue
        fi

        local before
        before=$(_snapshot_dirty_state)
        ${unpatch_func}
        local after
        after=$(_snapshot_dirty_state)

        if [[ "${before}" != "${after}" ]]; then
            echo "  [${patch_id}] Reverted"
            reverted=$((reverted + 1))
        else
            noop=$((noop + 1))
        fi
    done

    if [[ ${reverted} -eq 0 && ${noop} -gt 0 ]]; then
        echo "  (nothing to revert — all ${noop} patches were already absent)"
    elif [[ ${noop} -gt 0 ]]; then
        echo "  (${reverted} reverted, ${noop} no-op)"
    fi
}
# }}}

# {{{ patch_needs_applying_XXXX
# Individual patch condition checks - return 0 if patch needs applying
patch_needs_applying_B002() {
    # Retargeted 2026-08-07 alongside the patch itself. B002 moved from
    # RandomPlayerbotMgr.cpp to PlayerbotMgr.cpp when upstream relocated
    # OnBotLoginInternal; this probe was left pointing at the old file, so it
    # searched somewhere the witness could never appear and reported "needs
    # applying" unconditionally, forever. A probe that can only ever say yes
    # cannot detect the thing it exists to detect — which is exactly the
    # silent-no-op failure that broke B002 in the first place.
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/PlayerbotMgr.cpp"
    local CMAKE_FILE="${AC_CODE_DIR}/modules/mod-playerbots/mod-playerbots.cmake"
    if [[ -f "${FILE}" ]] && ! grep -q "sALE->OnLogin(bot)" "${FILE}"; then
        return 0
    fi
    if [[ -f "${FILE}" ]] && { [[ ! -f "${CMAKE_FILE}" ]] || ! grep -q "MOD_ALE_PATH" "${CMAKE_FILE}"; }; then
        return 0
    fi
    return 1
}

patch_needs_applying_B025() {
    # Grouped with B002 (the other mod-playerbots patch). Witness: the
    # factory gains the B025 marker once the starter-kit block is injected.
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/Factory/PlayerbotFactory.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B025-vanilla-starter-kit" "${FILE}"
}

patch_needs_applying_B026() {
    # B026 edits two files with two independently-guarded halves, so the probe
    # reports "needs applying" if EITHER witness is missing — mirroring the
    # apply function, where each half tests its own marker before editing.
    #
    # Added 2026-08-07. B026 shipped without a probe, and the consumer in
    # patches_need_applying() skips any patch that has none
    # (`declare -F ... || skip`), so B026 silently contributed nothing to the
    # "do patches need applying?" decision for its whole life. Every other
    # B-patch from B001 to B027 has one.
    local ENGINE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/Engine/Engine.cpp"
    local MGR="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/PlayerbotMgr.cpp"
    if [[ -f "${ENGINE}" ]] && ! grep -q "B026 dangling-strategy guard" "${ENGINE}"; then
        return 0
    fi
    if [[ -f "${MGR}" ]] && ! grep -q "B026 duplicate-login fix" "${MGR}"; then
        return 0
    fi
    return 1
}

patch_needs_applying_B027() {
    # Companion to B026 (same Engine::Init crash site). Witness: Engine.cpp
    # gains the B027 guard marker once the stale-facade skip is injected. The
    # paired PlayerbotAIAware.h accessor is applied in the same step.
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/Engine/Engine.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B027 stale-facade guard" "${FILE}"
}

patch_needs_applying_B003() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/LuaEngine.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "entry != 0 && !eObjectMgr->GetGameObjectTemplate" "${FILE}"
}

patch_needs_applying_B004() {
    # Add condition for B004 if it exists
    return 1
}

patch_needs_applying_B005() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.h"
    [[ -f "${FILE}" ]] && ! grep -q "ACCURACY_LEVEL_CAP" "${FILE}"
}

patch_needs_applying_B006() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/Hooks.h"
    [[ -f "${FILE}" ]] && ! grep -q "PLAYER_EVENT_ON_SELL_ITEM" "${FILE}"
}

patch_needs_applying_B007() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/methods/UnitMethods.h"
    [[ -f "${FILE}" ]] && ! grep -q "int SetWalk" "${FILE}"
}

patch_needs_applying_B010() {
    local FILE="${AC_CODE_DIR}/src/server/game/Battlegrounds/Battleground.h"
    [[ -f "${FILE}" ]] && ! grep -q "ARENA_TYPE_NONE" "${FILE}"
}

patch_needs_applying_B011() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/ALE_SC.cpp"
    [[ -f "${FILE}" ]] && grep -q "OnPlayerResurrect.*bool&" "${FILE}"
}

patch_needs_applying_B020() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/ALEEventMgr.cpp"
    if [[ ! -f "${FILE}" ]]; then
        return 1
    fi
    # Patch needed if RemoveEvent body does NOT already contain LOCK_ALE
    ! awk '/^void ALEEventProcessor::RemoveEvent/,/^}/' "${FILE}" | grep -q "LOCK_ALE"
}

patch_needs_applying_B022() {
    # Witness: Config.cpp gains the `_configPathOverride` identifier on apply.
    # If it's already present, the patch is in; if not, it needs applying.
    local FILE="${AC_CODE_DIR}/src/common/Configuration/Config.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "_configPathOverride" "${FILE}"
}

patch_needs_applying_B036() {
    # Witness: the build's copy of the buddy module is missing or differs
    # from the project's (the copy is refreshed so edits reach the build).
    local SRC="${DIR}/modules/mod-buddies" DST="${AC_CODE_DIR}/modules/mod-buddies"
    [[ -d "${SRC}" ]] || return 0          # "needs applying", so B036 runs and reports the missing folder loudly
    [[ -d "${DST}" ]] || return 0          # not copied yet
    ! diff -rq --exclude=.installed-by-B036 "${SRC}" "${DST}" > /dev/null
}

patch_needs_applying_B037() {
    # Witness: PlayerbotMgr.cpp gains the B037 marker in OnBotLogin.
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/PlayerbotMgr.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B037-invite-alts-on-login" "${FILE}"
}

patch_needs_applying_B038() {
    # Witness: Channel.cpp gains the B038 marker in JoinChannel.
    local FILE="${AC_CODE_DIR}/src/server/game/Chat/Channels/Channel.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B038-refused-channels" "${FILE}"
}

patch_needs_applying_B039() {
    # Witness: CliRunnable.cpp gains the logging B039 adds before either of
    # its two silent World::StopNow() calls (issue 163).
    local FILE="${AC_CODE_DIR}/src/server/apps/worldserver/CommandLine/CliRunnable.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "console input ended unexpectedly" "${FILE}"
}

patch_needs_applying_B043() {
    # Witness: World.h gains B043's located stop call (issue 163).
    local FILE="${AC_CODE_DIR}/src/server/game/World/World.h"
    [[ -f "${FILE}" ]] && ! grep -q "B043-say-why-the-world-stopped" "${FILE}"
}

patch_needs_applying_B044() {
    # Witness: WhoListCacheMgr.cpp gains B044's companion-account list (617a5).
    local FILE="${AC_CODE_DIR}/src/server/game/Cache/WhoListCacheMgr.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B044-companion-accounts-unseen" "${FILE}"
}

patch_needs_applying_B045() {
    # Witness: PlayerbotAI.cpp gains B045's command drop for buddies (617a5).
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/PlayerbotAI.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B045-companions-take-no-commands" "${FILE}"
}

patch_needs_applying_B050() {
    # Witness: StatsWeightCalculator.cpp gains B050's spirit worth for buddies (617j3).
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Mgr/Item/StatsWeightCalculator.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B050-buddy-spirit-worth" "${FILE}"
}

patch_needs_applying_B049() {
    # Witness: Player.cpp gains B049's spirit-by-stamina health rate (issue 167).
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B049-spirit-heals-by-stamina" "${FILE}"
}

patch_needs_applying_B048() {
    # Witness: InventoryChangeFailureAction.cpp gains B048's quiet for buddies (617h1).
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/InventoryChangeFailureAction.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B048-buddies-quiet-inventory" "${FILE}"
}

patch_needs_applying_B047() {
    # Witness: SpellHandler.cpp gains B047's outfit answer (617f).
    local FILE="${AC_CODE_DIR}/src/server/game/Handlers/SpellHandler.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B047-creature-outfits" "${FILE}"
}

patch_needs_applying_B046() {
    # Witness: LootRollAction.cpp gains B046's buddy roll judgement (617j).
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/LootRollAction.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B046-buddy-loot-judgement" "${FILE}"
}

patch_needs_applying_B042() {
    # Witness: ResetAiAction.cpp gains B042's quiet automatic reset (617c2).
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/ResetAiAction.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B042-quiet-automatic-ai-reset" "${FILE}"
}

patch_needs_applying_B040() {
    # Witness: Unit.cpp gains B040's per-viewer rule (issue 164).
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B040-per-player-unselectable" "${FILE}"
}

patch_needs_applying_B041() {
    # Witness: mod-ale's PlayerMethods.h gains B041's two Lua calls (issue 164).
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/methods/PlayerMethods.h"
    [[ -f "${FILE}" ]] && ! grep -q "B041-ale-per-player-unselectable" "${FILE}"
}

patch_needs_applying_B035() {
    # Witness: Player.cpp gains the B035 marker in resetTalentsCost.
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B035-respec-cost" "${FILE}"
}

patch_needs_applying_B033() {
    # Witness: Player.cpp gains the B033 marker in the repair function.
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B033-white-no-repair" "${FILE}"
}

patch_needs_applying_B032() {
    # Witness: Spell.cpp gains the B032 marker around the buff target level check.
    local FILE="${AC_CODE_DIR}/src/server/game/Spells/Spell.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B032-no-buff-level-restriction" "${FILE}"
}

patch_needs_applying_B031() {
    # Witness: Unit.cpp gains the B031 markers around the crushing-blow condition and chance.
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B031-crush-late" "${FILE}"
}

patch_needs_applying_B024() {
    # Witness: Creature.cpp gains the `B024-symmetric-aggro` marker
    # on apply. If the marker is present, the patch is in.
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Creature/Creature.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B024-symmetric-aggro" "${FILE}"
}
# }}}

# {{{ patches_need_applying
# Check if any PHASE_BEGIN patches for current profile would modify source
# Returns 0 (true) if patches need applying, 1 (false) if all applied
# Profile-aware: only checks patches in PHASE_BEGIN_PATCHES[$PROFILE]
patches_need_applying() {
    local patches="${PHASE_BEGIN_PATCHES[$PROFILE]:-}"

    # No patches for this profile = nothing to check
    if [[ -z "${patches}" ]]; then
        return 1
    fi

    # Check each patch in the profile's list
    for patch_id in ${patches}; do
        local check_func="patch_needs_applying_${patch_id}"
        if declare -F "${check_func}" > /dev/null 2>&1; then
            if ${check_func}; then
                return 0  # This patch needs applying
            fi
        fi
    done

    return 1  # All patches already applied
}
# }}}

# {{{ apply_patches_end
# PHASE_END: Post-compile setup (config files, symlinks, database)
# Run after successful build and atomic swap
apply_patches_end() {
    local patches="${PHASE_END_PATCHES[$PROFILE]:-}"

    if [[ -z "${patches}" ]]; then
        echo ""
        echo "PHASE_END: No patches for profile '${PROFILE}'"
        return 0
    fi

    echo ""
    echo "Applying PHASE_END patches for profile '${PROFILE}'..."
    # Stop at the first step that is missing or fails, and say which steps
    # ran. Earlier this printed a WARNING for a missing function, ignored a
    # step's failing return code, and always ended with "PHASE_END complete",
    # so a half-installed profile (say, a world SQL source file missing)
    # looked finished. Later steps can depend on earlier ones (E001's Lua
    # link, E006's configs), so continuing past a failure is not safe.
    local done_ids=""
    for patch_id in ${patches}; do
        # Find the patch function (e.g., patch_E001_lua_script_symlinks)
        local patch_func=$(declare -F | grep "^declare -f patch_${patch_id}_" | sed 's/declare -f //')
        if [[ -z "${patch_func}" ]]; then
            # No function: the profile's list names a step that does not exist.
            echo "  [${patch_id}] ERROR: no function patch_${patch_id}_* is defined"
            _report_patches_end_stop "${patch_id}" "${done_ids}" "${patches}"
            return 1
        fi
        # Run inside `if` so a failing step is caught here (and reported)
        # instead of killing the caller outright under `set -e`.
        if ${patch_func}; then
            done_ids+="${patch_id} "
        else
            echo "  [${patch_id}] ERROR: ${patch_func} returned failure"
            _report_patches_end_stop "${patch_id}" "${done_ids}" "${patches}"
            return 1
        fi
    done
    echo "  PHASE_END complete (${done_ids% })"
}

# Print where the PHASE_END pipeline stopped: what completed, what failed,
# what never ran. Args: failed id, completed ids, full list.
_report_patches_end_stop() {
    local failed="$1" done_ids="$2" all_ids="$3" skipped="" seen=0
    for id in ${all_ids}; do
        [[ "${seen}" -eq 1 ]] && skipped+="${id} "
        [[ "${id}" == "${failed}" ]] && seen=1
    done
    echo "  PHASE_END STOPPED for profile '${PROFILE}'"
    echo "    completed: ${done_ids:-none}"
    echo "    failed:    ${failed}"
    echo "    not run:   ${skipped:-none}"
}
# }}}

# {{{ unapply_patches_end
# Reverse all PHASE_END patches (remove configs, symlinks, database entries)
# Used by apply-patches --revert
unapply_patches_end() {
    local patches="${PHASE_END_PATCHES[$PROFILE]:-}"

    if [[ -z "${patches}" ]]; then
        echo ""
        echo "PHASE_END: No patches to revert for profile '${PROFILE}'"
        return 0
    fi

    echo ""
    echo "Reverting PHASE_END patches for profile '${PROFILE}'..."
    for patch_id in ${patches}; do
        local unpatch_func=$(declare -F | grep "^declare -f unpatch_${patch_id}_" | sed 's/declare -f //')
        if [[ -n "${unpatch_func}" ]]; then
            ${unpatch_func}
        else
            echo "  [${patch_id}] No unpatch function (skipping)"
        fi
    done
    echo "  PHASE_END revert complete"
}
# }}}
