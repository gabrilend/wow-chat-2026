#!/usr/bin/env bash

PATCHES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for patch_file in "${PATCHES_DIR}"/B[0-9][0-9][0-9]-*.sh "${PATCHES_DIR}"/B[0-9][0-9][0-9]-*/B[0-9][0-9][0-9]-*.sh; do
    [[ -f "${patch_file}" ]] && source "${patch_file}"
done

if [[ -f "${PATCHES_DIR}/E-patches.sh" ]]; then
    source "${PATCHES_DIR}/E-patches.sh"
fi

PROJECT_DIR_OF_PATCHES="${PATCHES_DIR%/patches}"

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

reset_source_trees() {
    if [[ -d "${AC_CODE_DIR}/.git" ]]; then
        git -C "${AC_CODE_DIR}" reset --hard HEAD --quiet 2>/dev/null
    fi

    if [[ -d "${AC_CODE_DIR}/modules" ]]; then
        for mod_dir in "${AC_CODE_DIR}"/modules/*/; do
            if [[ -d "${mod_dir}/.git" ]]; then
                git -C "${mod_dir}" reset --hard HEAD --quiet 2>/dev/null
            fi
        done
    fi
}

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

apply_patches_begin() {
    local patches="${PHASE_BEGIN_PATCHES[$PROFILE]:-}"

    if [[ -z "${patches}" ]]; then
        echo ""
        echo "PHASE_BEGIN: No patches for profile '${PROFILE}'"
        return 0
    fi

    echo ""
    echo "Applying PHASE_BEGIN patches for profile '${PROFILE}'..."
    local done_ids=""
    for patch_id in ${patches}; do
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

_reversed_list() {
    local i out=""
    for (( i = $#; i >= 1; i-- )); do out+="${!i} "; done
    printf '%s' "${out% }"
}

unapply_patches_begin() {
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

patch_needs_applying_B002() {
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
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/Factory/PlayerbotFactory.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B025-vanilla-starter-kit" "${FILE}"
}

patch_needs_applying_B026() {
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
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/Engine/Engine.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B027 stale-facade guard" "${FILE}"
}

patch_needs_applying_B003() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/LuaEngine.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "entry != 0 && !eObjectMgr->GetGameObjectTemplate" "${FILE}"
}

patch_needs_applying_B004() {
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
    ! awk '/^void ALEEventProcessor::RemoveEvent/,/^}/' "${FILE}" | grep -q "LOCK_ALE"
}

patch_needs_applying_B022() {
    local FILE="${AC_CODE_DIR}/src/common/Configuration/Config.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "_configPathOverride" "${FILE}"
}

patch_needs_applying_B036() {
    local SRC="${DIR}/modules/mod-buddies" DST="${AC_CODE_DIR}/modules/mod-buddies"
    [[ -d "${SRC}" ]] || return 0          # "needs applying", so B036 runs and reports the missing folder loudly
    [[ -d "${DST}" ]] || return 0          # not copied yet
    ! diff -rq --exclude=.installed-by-B036 "${SRC}" "${DST}" > /dev/null
}

patch_needs_applying_B037() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/PlayerbotMgr.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B037-invite-alts-on-login" "${FILE}"
}

patch_needs_applying_B038() {
    local FILE="${AC_CODE_DIR}/src/server/game/Chat/Channels/Channel.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B038-refused-channels" "${FILE}"
}

patch_needs_applying_B039() {
    local FILE="${AC_CODE_DIR}/src/server/apps/worldserver/CommandLine/CliRunnable.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "console input ended unexpectedly" "${FILE}"
}

patch_needs_applying_B043() {
    local FILE="${AC_CODE_DIR}/src/server/game/World/World.h"
    [[ -f "${FILE}" ]] && ! grep -q "B043-say-why-the-world-stopped" "${FILE}"
}

patch_needs_applying_B044() {
    local FILE="${AC_CODE_DIR}/src/server/game/Cache/WhoListCacheMgr.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B044-companion-accounts-unseen" "${FILE}"
}

patch_needs_applying_B045() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Bot/PlayerbotAI.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B045-companions-take-no-commands" "${FILE}"
}

patch_needs_applying_B050() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Mgr/Item/StatsWeightCalculator.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B050-buddy-spirit-worth" "${FILE}"
}

patch_needs_applying_B049() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B049-spirit-heals-by-stamina" "${FILE}"
}

patch_needs_applying_B048() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/InventoryChangeFailureAction.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B048-buddies-quiet-inventory" "${FILE}"
}

patch_needs_applying_B047() {
    local FILE="${AC_CODE_DIR}/src/server/game/Handlers/SpellHandler.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B047-creature-outfits" "${FILE}"
}

patch_needs_applying_B046() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/LootRollAction.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B046-buddy-loot-judgement" "${FILE}"
}

patch_needs_applying_B042() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/ResetAiAction.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B042-quiet-automatic-ai-reset" "${FILE}"
}

patch_needs_applying_B040() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B040-per-player-unselectable" "${FILE}"
}

patch_needs_applying_B054() {
    local FILE="${AC_CODE_DIR}/src/common/Collision/Management/MMapMgr.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "// B054" "${FILE}"
}

patch_needs_applying_B053() {
    local FILE="${AC_CODE_DIR}/src/server/game/World/World.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "// B053" "${FILE}"
}

patch_needs_applying_B052() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/World/Rpg/Action/NewRpgBaseAction.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B052-buddies-never-teleport" "${FILE}"
}

patch_needs_applying_B051() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/methods/UnitMethods.h"
    [[ -f "${FILE}" ]] && ! grep -q "B051-ale-walkable-path-length" "${FILE}"
}

patch_needs_applying_B041() {
    local FILE="${AC_CODE_DIR}/modules/mod-ale/src/LuaEngine/methods/PlayerMethods.h"
    [[ -f "${FILE}" ]] && ! grep -q "B041-ale-per-player-unselectable" "${FILE}"
}

patch_needs_applying_B035() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B035-respec-cost" "${FILE}"
}

patch_needs_applying_B033() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B033-white-no-repair" "${FILE}"
}

patch_needs_applying_B032() {
    local FILE="${AC_CODE_DIR}/src/server/game/Spells/Spell.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B032-no-buff-level-restriction" "${FILE}"
}

patch_needs_applying_B031() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B031-crush-late" "${FILE}"
}

patch_needs_applying_B024() {
    local FILE="${AC_CODE_DIR}/src/server/game/Entities/Creature/Creature.cpp"
    [[ -f "${FILE}" ]] && ! grep -q "B024-symmetric-aggro" "${FILE}"
}

patches_need_applying() {
    local patches="${PHASE_BEGIN_PATCHES[$PROFILE]:-}"

    if [[ -z "${patches}" ]]; then
        return 1
    fi

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
        if [[ "${patch_id}" == C* ]]; then
            if apply_settings_patch "${patch_id}"; then
                done_ids+="${patch_id} "
                continue
            fi
            _report_stage_stop "${stage}" "${patch_id}" "${done_ids}" "${patches}"
            return 1
        fi
        local patch_func=$(declare -F | grep "^declare -f patch_${patch_id}_" | sed 's/declare -f //')
        if [[ -z "${patch_func}" ]]; then
            echo "  [${patch_id}] ERROR: no function patch_${patch_id}_* is defined"
            _report_stage_stop "${stage}" "${patch_id}" "${done_ids}" "${patches}"
            return 1
        fi
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

apply_patches_end() {
    _apply_stage PHASE_END "${PHASE_END_PATCHES[$PROFILE]:-}"
}

apply_patches_sql() {
    _apply_stage SQL "${PHASE_SQL_PATCHES[$PROFILE]:-}" || return 1
    _mirror_staged_sql || { echo "  ERROR: mirroring the staged SQL for the updater failed (issue 183)"; return 1; }
}

unapply_patches_sql() {
    _unapply_stage SQL "${PHASE_SQL_PATCHES[$PROFILE]:-}"
    _mirror_staged_sql                          # the reverts' SQL, into the updater's folders (issue 183)
}

unapply_patches_end() {
    _unapply_stage PHASE_END "${PHASE_END_PATCHES[$PROFILE]:-}"
}
