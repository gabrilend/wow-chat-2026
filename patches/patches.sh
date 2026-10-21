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
# (and the bash file of a patch that is a directory, issue 189e)
for patch_file in "${PATCHES_DIR}"/B[0-9][0-9][0-9]-*.sh "${PATCHES_DIR}"/B[0-9][0-9][0-9]-*/B[0-9][0-9][0-9]-*.sh; do
    [[ -f "${patch_file}" ]] && source "${patch_file}"
done

# Source E patches (PHASE_END - config files, symlinks, database)
if [[ -f "${PATCHES_DIR}/E-patches.sh" ]]; then
    source "${PATCHES_DIR}/E-patches.sh"
fi

# {{{ Each profile's patches, from their headers (issue 189c)
# Which patches a profile takes, and in what order, is in each patch's own
# header (its profiles and priority); scripts/plan-patches reads them all and
# says, for each profile, the source patches (below the first gate in
# patches/gates) and the install-stage patches (settings and install steps,
# between the first and second gates), lowest priority first. The two lists
# below are built from that every time this file is loaded, under the names
# everything already reads them by; they are never written by hand any more.
# (Until 2026-10-20 they were, here; their notes, the record of why each
# patch joined or left a profile, are in docs/patches/profile-patch-history.md.)
#
# PHASE_END_PATCHES holds settings patches (C...) beside the install steps
# (E...): since 189c the settings run at their own priorities in the install
# stage, after E006 has made the config files, no longer inside E006.
#
# A broken header, or a profile name in one that is no profile, stops the
# load with every fault named: the build would otherwise run the wrong set.
PROJECT_DIR_OF_PATCHES="${PATCHES_DIR%/patches}"

# the settings patches' functions (they used to be loaded by
# apply_config_values, inside E006)
declare -gA CONFIG_DESCRIPTIONS=()                  # each settings patch's line about itself, by function name
for patch_file in "${PROJECT_DIR_OF_PATCHES}/config/patches"/C[0-9]*.sh; do
    [[ -f "${patch_file}" ]] && source "${patch_file}"
done

declare -gA PHASE_BEGIN_PATCHES=() PHASE_END_PATCHES=() PHASE_SQL_PATCHES=()
_patch_plan="$("${PROJECT_DIR_OF_PATCHES}/scripts/plan-patches" "${PROJECT_DIR_OF_PATCHES}" --every-profile 2>&1)" || {
    echo "ERROR: the patches' headers could not be read, so no profile's patches are known:"
    echo "${_patch_plan}" | sed 's/^/  /'
    echo "  to debug: ${PROJECT_DIR_OF_PATCHES}/scripts/check-patch-headers ${PROJECT_DIR_OF_PATCHES}"
    return 1 2>/dev/null || exit 1
}
while IFS='|' read -r _stage _profile _ids; do
    case "${_stage}" in
        source)  PHASE_BEGIN_PATCHES["${_profile}"]="${_ids}" ;;
        install) PHASE_END_PATCHES["${_profile}"]="${_ids}" ;;
        sql)     PHASE_SQL_PATCHES["${_profile}"]="${_ids}" ;;
    esac
done <<< "${_patch_plan}"
unset _patch_plan _stage _profile _ids
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
        # "|| true": grep -c prints 0 for no match but also exits 1, and
        # under the callers' set -e that ended the build in silence during
        # the revert (2026-10-12 23:22 and 2026-10-13: patches.sh:134, once
        # a revert had turned every tagged line back and the old form was
        # counted again). A count of 0 is an answer, not a failure.
        tagged="$(grep -cxF -- "${new}${tag}" "${file}" || true)"
        have="$(grep -cxF -- "${old}" "${file}" || true)"
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

# {{{ _reversed_list
# Its arguments, last first, one line: "B002 B004 B020" -> "B020 B004 B002".
_reversed_list() {
    local i out=""
    for (( i = $#; i >= 1; i-- )); do out+="${!i} "; done
    printf '%s' "${out% }"
}
# }}}

# {{{ unapply_patches_begin
# Reverse all PHASE_BEGIN patches for the current profile, last first.
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
    # Back to front: a patch laid over another's output comes off before the
    # one beneath it, or the lower one's revert looks for a shape that is no
    # longer there. Until 2026-10-20 this walked the list front to back
    # (found by wow-chat-2026-ae for issue 192's econ profile, which layers
    # its patches on basic's; the owner: "We definitely need to undo them
    # the same order we applied them, but reversed.").
    local patches
    patches="$(_reversed_list ${PHASE_BEGIN_PATCHES[$PROFILE]:-})"

    if [[ -z "${patches}" ]]; then
        return 0
    fi

    echo ""
    echo "Reverting PHASE_BEGIN patches for profile '${PROFILE}'..."

    local failed_reverts=""
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
        # Called as a condition, as apply_patches_begin calls the patches:
        # a bare call let any failing command inside a revert (a count of
        # zero from grep -c, 2026-10-13) end the whole build in silence,
        # after it had compiled and installed. A failed revert is a bug in
        # that patch's code and fails the run (owner, 2026-10-13: "a failed
        # revert is an error in the patch code and should be treated as an
        # error"): it is named here, the other reverts still run so the
        # report lists every failure at once, and the function returns
        # failure at the end. The caller then resets every tree to its
        # commit (leave_source_trees_clean) and reports the run failed.
        if ! ${unpatch_func}; then
            echo "  [${patch_id}] ERROR: ${unpatch_func} returned failure"
            failed_reverts+="${patch_id} "
        fi
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
    if [[ -n "${failed_reverts}" ]]; then
        echo "  REVERT FAILED for: ${failed_reverts}(each a bug in that patch's revert; the trees are reset to their commits next)"
        FAILURE_ALREADY_EXPLAINED=true                # compile's verdict: this message is the explanation
        return 1
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

patch_needs_applying_B054() {
    # Witness: MMapMgr.cpp's tile version check carries B054's tag.
    local FILE="${AC_CODE_DIR}/src/common/Collision/Management/MMapMgr.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "// B054" "${FILE}"
}

patch_needs_applying_B053() {
    # Witness: World.cpp's walking speed line carries B053's tag (166).
    local FILE="${AC_CODE_DIR}/src/server/game/World/World.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "// B053" "${FILE}"
}

patch_needs_applying_B052() {
    # Witness: NewRpgBaseAction.cpp gains B052's stuck-clock reset for buddies (617e4).
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/World/Rpg/Action/NewRpgBaseAction.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B052-buddies-never-teleport" "${FILE}"
}

patch_needs_applying_B051() {
    # Witness: mod-ale's UnitMethods.h gains B051's walkable-path call (617b).
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/methods/UnitMethods.h"
    [[ -f "${FILE}" ]] && ! grep -q "B051-ale-walkable-path-length" "${FILE}"
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

# {{{ _apply_stage
# Run one stage's patches for the current profile, in the plan's order
# (lowest priority first). Shared by the install stage (between gates 1000
# and 2000: install steps and settings) and the SQL stage (between gates
# 2000 and 9000: the steps that hand our SQL to the server's updater).
#
# Stop at the first step that is missing or fails, and say which steps
# ran. Earlier this printed a WARNING for a missing function, ignored a
# step's failing return code, and always ended with "PHASE_END complete",
# so a half-installed profile (say, a world SQL source file missing)
# looked finished. Later steps can depend on earlier ones (E001's Lua
# link, E006's configs), so continuing past a failure is not safe.
#   $1 = the stage's name in the report (PHASE_END, SQL)
#   $2 = its ids, in order
_apply_stage() {
    local stage="$1" patches="$2"

    if [[ -z "${patches}" ]]; then
        echo ""
        echo "${stage}: No patches for profile '${PROFILE}'"
        return 0
    fi

    echo ""
    echo "Applying ${stage} patches for profile '${PROFILE}'..."
    local done_ids=""
    for patch_id in ${patches}; do
        # A settings patch (C...) is run by its own runner (E-helpers.sh),
        # which finds its function from its file's name; an install or SQL
        # step (E...) by its patch_<id>_ function, below.
        if [[ "${patch_id}" == C* ]]; then
            if apply_settings_patch "${patch_id}"; then
                done_ids+="${patch_id} "
                continue
            fi
            _report_stage_stop "${stage}" "${patch_id}" "${done_ids}" "${patches}"
            return 1
        fi
        # Find the patch function (e.g., patch_E001_lua_script_symlinks)
        local patch_func=$(declare -F | grep "^declare -f patch_${patch_id}_" | sed 's/declare -f //')
        if [[ -z "${patch_func}" ]]; then
            # No function: the profile's plan names a step that does not exist.
            echo "  [${patch_id}] ERROR: no function patch_${patch_id}_* is defined"
            _report_stage_stop "${stage}" "${patch_id}" "${done_ids}" "${patches}"
            return 1
        fi
        # Run inside `if` so a failing step is caught here (and reported)
        # instead of killing the caller outright under `set -e`.
        if ${patch_func}; then
            done_ids+="${patch_id} "
        else
            echo "  [${patch_id}] ERROR: ${patch_func} returned failure"
            _report_stage_stop "${stage}" "${patch_id}" "${done_ids}" "${patches}"
            return 1
        fi
    done
    echo "  ${stage} complete (${done_ids% })"
}

# Print where a stage stopped: what completed, what failed, what never ran.
# Args: stage name, failed id, completed ids, full list.
_report_stage_stop() {
    local stage="$1" failed="$2" done_ids="$3" all_ids="$4" skipped="" seen=0
    for id in ${all_ids}; do
        [[ "${seen}" -eq 1 ]] && skipped+="${id} "
        [[ "${id}" == "${failed}" ]] && seen=1
    done
    echo "  ${stage} STOPPED for profile '${PROFILE}'"
    echo "    completed: ${done_ids:-none}"
    echo "    failed:    ${failed}"
    echo "    not run:   ${skipped:-none}"
}
# }}}

# {{{ _unapply_stage
# Reverse one stage's patches for the current profile, last first (a step
# laid over another's output comes off before the one beneath it).
# A settings patch has no undo of its own: it edits the config files, and
# E006's undo, later in the install stage's walk, removes those files whole.
#   $1 = the stage's name in the report, $2 = its ids, in apply order
_unapply_stage() {
    local stage="$1" patches
    patches="$(_reversed_list $2)"

    if [[ -z "${patches}" ]]; then
        echo ""
        echo "${stage}: No patches to revert for profile '${PROFILE}'"
        return 0
    fi

    echo ""
    echo "Reverting ${stage} patches for profile '${PROFILE}'..."
    for patch_id in ${patches}; do
        [[ "${patch_id}" == C* ]] && continue
        local unpatch_func=$(declare -F | grep "^declare -f unpatch_${patch_id}_" | sed 's/declare -f //')
        if [[ -n "${unpatch_func}" ]]; then
            ${unpatch_func}
        else
            echo "  [${patch_id}] No unpatch function (skipping)"
        fi
    done
    echo "  ${stage} revert complete"
}
# }}}

# {{{ apply_patches_end
# The install stage (between gates 1000 and 2000): config files, symlinks,
# settings, after the compile's install into the shadow folder. Our SQL is
# not here since issue 189d: it is the SQL stage's, after gate 2000.
apply_patches_end() {
    _apply_stage PHASE_END "${PHASE_END_PATCHES[$PROFILE]:-}"
}
# }}}

# {{{ apply_patches_sql
# The SQL stage (between gates 2000 and 9000, issue 189d): the steps that
# hand our SQL to the server's own updater (the owner, 2026-10-20: "we
# should use their updater since I think they're quite proud of it"), then
# the mirror into the folders the updater scans. Run after gate 2000, where
# the compile starts the server once so the updater has brought every
# database to upstream's state (scripts/compile, the gate's step); the
# server's next start, the build's validation, applies ours after them. So
# upstream's updates come first by time, which the z_ names of issue 183
# used to do by sorting.
apply_patches_sql() {
    _apply_stage SQL "${PHASE_SQL_PATCHES[$PROFILE]:-}" || return 1
    # what the steps staged, into the folders the updater scans (issue 183)
    _mirror_staged_sql || { echo "  ERROR: mirroring the staged SQL for the updater failed (issue 183)"; return 1; }
}
# }}}

# {{{ unapply_patches_sql
# Reverse the SQL stage: each step writes its revert form, and the mirror
# hands those to the updater, which runs them at the server's next start.
# Undone before the install stage, the reverse of the order applied.
unapply_patches_sql() {
    _unapply_stage SQL "${PHASE_SQL_PATCHES[$PROFILE]:-}"
    _mirror_staged_sql                          # the reverts' SQL, into the updater's folders (issue 183)
}
# }}}

# {{{ unapply_patches_end
# Reverse the install stage (remove configs, symlinks), last first.
# Used by apply-patches --revert, after unapply_patches_sql.
unapply_patches_end() {
    _unapply_stage PHASE_END "${PHASE_END_PATCHES[$PROFILE]:-}"
}
# }}}
