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
    ["release"]="B004 B009 B012 B013 B014 B015 B016 B017 B018 B019 B020 B021 B022 B023 B024 B026 B027"  # +B027 (2026-07-21, issue 308: Engine::Init stale-facade guard, companion to B026); +B026 (2026-07-16, bot-login Engine::Init crash guard+diagnostic); warning fixes + mod-playerbots + mod-ale compat + ALE registry lock fix + runtime conf-dir override + ALE FormatQuery lifetime fix + symmetric aggro radius (B011 removed — upstream mod-ale now matches core, patch became harmful; B010 removed 2026-07-16 — upstream now ships ARENA_TYPE_NONE)
    ["beta"]="B001 B002 B003 B004 B005 B006 B007 B008 B009 B012 B013 B014 B015 B016 B017 B018 B019 B020 B021 B022 B023 B024 B026 B027"  # +B027 (2026-07-21, issue 308: Engine::Init stale-facade guard, companion to B026); +B026 (2026-07-16, bot-login crash guard+diagnostic); All patches (B011 removed — see release-line note; B010 removed 2026-07-16 — upstream now ships ARENA_TYPE_NONE)
    ["alpha"]="B001 B004"                                         # Minimal compatibility patches
    ["vanilla"]="B001 B002 B004 B009 B012 B013 B014 B015 B016 B017 B018 B019 B020 B021 B022 B023 B025 B026 B027"  # +B027 (2026-07-21, issue 308: Engine::Init stale-facade guard, companion to B026). +B026 (2026-07-16, bot-login crash guard+diagnostic). 2026-06-02: ALE added per 148k. Compile fixes + B001 (aoe-loot/ALE compat, conditional) + B002 (playerbots×ALE login hook) + B020 + B023 (ALE thread-safety + dangling-pointer fixes — non-negotiable for ALE stability). Skipped per user OK: B003 B006 B007 (ALE feature patches not yet needed), B005 B008 B024 (wow-chat gameplay), B011 (removed everywhere). 2026-07-15: +B025 (148s — vanilla bots start in the 148h starter kit; self-scoping on the kit data, so it only takes effect on vanilla).
    ["basic"]="B001 B002 B004 B005 B009 B012 B013 B014 B015 B016 B017 B018 B019 B020 B021 B022 B023 B026 B027 B028 B029"  # issue 155 (2026-09-23): +B029 (155e: a trainer gossip option can name its trainer list, for the per-class Visiting Mentors). +B028 (155d: new characters start in their faction's rotating starting valley). vanilla's list minus B025 (bots in the vanilla starter kit — basic has no kit) plus B005 (accuracy level cap, issue 803, user directive: level gaps stop worsening hit/miss past ±3, which also makes 155f's level-64 heroics fightable at 60).
)

# PHASE_END patches (post-compile setup: configs, symlinks, database)
declare -A PHASE_END_PATCHES=(
    ["release"]="E004 E006"              # Logs + configs (minimal)
    ["beta"]="E001 E004 E005 E006 E011 E012 E013 E014 E015 E016 E017"  # Lua symlinks + logs + configs + DK levelstats (E005) + DK class system (E011) + drop-creatures (E012, destructive) + quest-spells-to-trainers (E013) + trainer-spell-level-cap (E014, destructive) + class-selector-npcs (E015) + empty-loot-chests (E016) + playerbots logout-texts migration fix (E017)
    ["alpha"]="E004 E006"                # Logs + configs (same as release)
    ["vanilla"]="E001 E004 E006 E007 E008 E009 E010 E018 E019 E020 E021"  # 2026-06-02: E001 added for ALE (per 148k). E001 now profile-aware — symlinks src/lua-vanilla/ into installed-files-vanilla/bin/lua_scripts/custom/. Plus: configs + starting-zones SQL (148h, E007) + flight-path removal SQL (148i, E008) + starting-equipment SQL (148h, E009) + pretrain-abilities SQL (148j, E010) + kit RequiredLevel cap (148h, E018, lets level-20 chars equip the kit) + no-intro-cinematic trigger (E019, skips race intro on first login) + mount level requirements (148l, E020, Classic 40/60 riding gates) + starting professions (148q, E021, gathering+production at skill 125 with recipes & tools). No DK stats (DK disabled per 148a/CP8).
    ["basic"]="E001 E004 E006 E008 E019 E020 E022 E023 E024 E025"  # issue 155 (2026-09-23): +E025 (155e: a Visiting Mentor per valley for the classes it lacks). +E024 (155f: Outland dungeons a level 60 can enter at level 64; open world stock). +E023 (155d rotation-state table, characters DB). Lua link (src/lua-basic/) + logs + configs + flight-path removal (E008) + no intro cinematic (E019) + Classic riding gates 40/60 (E020) + quests open to the whole faction (E022, 155e). Left out on purpose: E007 level-20 spawn towns (basic spawns in the level-1 valleys), E009/E018 starter kit, E010 pretrained abilities, E021 starting professions — all head-start.
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
patch_needs_applying_B001() {
    local FILE="${AC_CODE_DIR}/modules/mod-aoe-loot/src/aoe_loot.cpp"
    [[ -f "${FILE}" ]] && grep -q "^[[:space:]]*Item\* pItem = player->GetItemByGuid" "${FILE}"
}

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

patch_needs_applying_B008() {
    [[ -d "${DIR}/modules/mod-talent-bonus" ]] && [[ ! -d "${AC_CODE_DIR}/modules/mod-talent-bonus" ]]
}

patch_needs_applying_B009() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.h"
    [[ -f "${FILE}" ]] && ! grep -q "enum EquipmentSlots : uint32" "${FILE}"
}

patch_needs_applying_B010() {
    local FILE="${AC_CODE_DIR}/src/server/game/Battlegrounds/Battleground.h"
    [[ -f "${FILE}" ]] && ! grep -q "ARENA_TYPE_NONE" "${FILE}"
}

patch_needs_applying_B011() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/ALE_SC.cpp"
    [[ -f "${FILE}" ]] && grep -q "OnPlayerResurrect.*bool&" "${FILE}"
}

patch_needs_applying_B012() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp"
    [[ -f "${FILE}" ]] && grep -q "for (int slot = EQUIPMENT_SLOT_START\|for (int i = EQUIPMENT_SLOT_START" "${FILE}"
}

patch_needs_applying_B013() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/ChooseRpgTargetAction.cpp"
    [[ -f "${FILE}" ]] && grep -q "groupLeader && !groupLeader->isMoving() ||" "${FILE}"
}

patch_needs_applying_B014() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/BattleGroundTactics.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "default:" "${FILE}"
}

patch_needs_applying_B015() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Raid/Magtheridon/Action/RaidMagtheridonActions.cpp"
    [[ -f "${FILE}" ]] && grep -q "/ RAND_MAX" "${FILE}" && ! grep -q "static_cast<float>(RAND_MAX)" "${FILE}"
}

patch_needs_applying_B016() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/GenericSpellActions.cpp"
    [[ -f "${FILE}" ]] && grep -q 'range(botAI->GetRange("spell")), spell(spell)' "${FILE}"
}

patch_needs_applying_B017() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/ChooseRpgTargetAction.cpp"
    [[ -f "${FILE}" ]] && grep -q "Player\* player = botAI->GetBot();" "${FILE}" && ! grep -q "(void)player;" "${FILE}"
}

patch_needs_applying_B018() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/PlayerbotAIConfig.cpp"
    [[ -f "${FILE}" ]] && grep -q "for (int tab = 0; tab < 3; tab++)" "${FILE}"
}

patch_needs_applying_B019() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Strategy/NonCombatStrategy.cpp"
    [[ -f "${FILE}" ]] && grep -q "std::vector<TriggerNode\*>& triggers)" "${FILE}"
}

patch_needs_applying_B020() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/ALEEventMgr.cpp"
    if [[ ! -f "${FILE}" ]]; then
        return 1
    fi
    # Patch needed if RemoveEvent body does NOT already contain LOCK_ALE
    ! awk '/^void ALEEventProcessor::RemoveEvent/,/^}/' "${FILE}" | grep -q "LOCK_ALE"
}

patch_needs_applying_B021() {
    # Probe the OculusMultipliers fix as the witness: when applied, the
    # `&&` lives outside HasAura's parens; when unapplied, it's inside.
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Dungeon/Oculus/Multiplier/OculusMultipliers.cpp"
    [[ -f "${FILE}" ]] && grep -q "boss->HasAura(SPELL_PLANAR_SHIFT && dynamic_cast" "${FILE}"
}

patch_needs_applying_B022() {
    # Witness: Config.cpp gains the `_configPathOverride` identifier on apply.
    # If it's already present, the patch is in; if not, it needs applying.
    local FILE="${AC_CODE_DIR}/src/common/Configuration/Config.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "_configPathOverride" "${FILE}"
}

patch_needs_applying_B023() {
    # Witness: GlobalMethods.h gains the `B023-formatquery-lifetime` marker
    # on apply. If the marker is present, the patch is in; if not (and the
    # buggy `.c_str()` line is still there), the patch needs applying.
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/methods/GlobalMethods.h"
    [[ -f "${FILE}" ]] && ! grep -q "B023-formatquery-lifetime" "${FILE}"
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
