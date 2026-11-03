#!/usr/bin/env bash

B062_BEGIN='// >>> B062-coins-alone-are-the-groups BEGIN'
B062_END='// <<< B062-coins-alone-are-the-groups END'
B062_STORAGE_ANCHOR='    switch (thisGroup->GetLootMethod())'
B062_SEND_ANCHOR='    // LOOT_INSIGNIA and LOOT_FISHINGHOLE unsupported by client'

b062_insert() {
    local file="$1" anchor="$2" where="$3"; shift 3
    local found
    found="$(grep -cxF "${anchor}" "${file}")"
    if [[ "${found}" != "1" ]]; then
        echo "  [B062] ERROR: expected the line '${anchor}' once in ${file}, found it ${found} times"
        echo "         to debug: has upstream changed the loot permission code there?"
        return 1
    fi
    local body
    body="$(printf '%s\n' "$@")"
    ANCHOR="${anchor}" WHERE="${where}" BODY="${body}" BEGIN_M="${B062_BEGIN}" END_M="${B062_END}" awk '
        function block() { print "    " ENVIRON["BEGIN_M"]; print ENVIRON["BODY"]; print "    " ENVIRON["END_M"] }
        $0 == ENVIRON["ANCHOR"] && ENVIRON["WHERE"] == "before" { block() }
        { print }
        $0 == ENVIRON["ANCHOR"] && ENVIRON["WHERE"] == "after" { block() }' "${file}" > "${file}.b062" && mv "${file}.b062" "${file}"
}

patch_B062_coins_alone_are_the_groups() {
    local STORAGE="${AC_CODE_DIR}/src/server/game/Entities/Player/PlayerStorage.cpp"
    local SEND="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp"
    [[ -f "${STORAGE}" && -f "${SEND}" ]] || { echo "  [B062] ERROR: ${STORAGE} or ${SEND} is missing"; return 1; }
    if grep -qF "${B062_BEGIN}" "${STORAGE}" && grep -qF "${B062_BEGIN}" "${SEND}"; then
        return 0                                       # already patched
    fi
    grep -qF "${B062_BEGIN}" "${STORAGE}" || b062_insert "${STORAGE}" "${B062_STORAGE_ANCHOR}" before \
        "    // basic: coins alone on a body (no item left for anyone) are any member's" \
        "    // of the group it fell to (issue 155z17), whatever the loot rule" \
        "    if (loot->gold && loot->unlootedCount == 0)" \
        "        return true;" || return 1
    grep -qF "${B062_BEGIN}" "${SEND}" || b062_insert "${SEND}" "${B062_SEND_ANCHOR}" before \
        "    // basic: coins alone on a body are any member's of the group it fell to" \
        "    // (issue 155z17): full rights to them, whatever the loot rule" \
        "    if (permission != ALL_PERMISSION && permission != OWNER_PERMISSION && loot && guid.IsCreatureOrVehicle()" \
        "        && loot->loot_type == LOOT_CORPSE && loot->gold && loot->unlootedCount == 0 && GetGroup())" \
        "        if (Creature* body = GetMap()->GetCreature(guid); body && body->GetLootRecipientGroup() == GetGroup())" \
        "            permission = ALL_PERMISSION;" || return 1
    echo "  [B062] Applied: coins alone on a body are any group member's"
}

unpatch_B062_coins_alone_are_the_groups() {
    local f
    for f in "${AC_CODE_DIR}/src/server/game/Entities/Player/PlayerStorage.cpp" "${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp"; do
        [[ -f "${f}" ]] || continue
        sed -i "\|${B062_BEGIN}|,\|${B062_END}|d" "${f}"
    done
    echo "  [B062] Reverted"
}
