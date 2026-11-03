#!/usr/bin/env bash

B065_TAG='B065-buddies-leave-quest-loot'
B065_INCLUDE='#include "LootAction.h"'
B065_ITEM_ANCHOR='    if (proto->StartQuest)'
B065_OBJECT_ANCHOR='    if (go && go->HasFlag(GAMEOBJECT_FLAGS, GO_FLAG_INTERACT_COND) && !go->ActivateToQuest(bot))'

b065_insert() {
    local file="$1" anchor="$2" block="$3" where="$4"
    local count
    count=$(grep -cxF -- "${anchor}" "${file}" || true)
    if [[ "${count}" -ne 1 ]]; then
        echo "  [B065] ERROR: expected exactly one '${anchor}' in ${file}, found ${count} (stale patch)"
        echo "         to debug: has upstream changed StoreLootAction::IsLootAllowed or the loot-object checks?"
        return 1
    fi
    ANCHOR="${anchor}" BLOCK="${block}" WHERE="${where}" awk '
        $0 == ENVIRON["ANCHOR"] && ENVIRON["WHERE"] == "before" { print ENVIRON["BLOCK"] }
        { print }
        $0 == ENVIRON["ANCHOR"] && ENVIRON["WHERE"] == "after" { print ENVIRON["BLOCK"] }' \
        "${file}" > "${file}.b065" && mv "${file}.b065" "${file}"
}

patch_B065_playerbots_buddies_leave_quest_loot() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/LootAction.cpp"
    [[ -f "${FILE}" ]] || { echo "  [B065] ERROR: ${FILE} missing"; return 1; }
    grep -qF "${B065_TAG}" "${FILE}" && return 0                 # witness guard

    b065_insert "${FILE}" "${B065_INCLUDE}" \
"// >>> ${B065_TAG} BEGIN
// The buddy module's answer: whether an account is a companion's (a buddy's).
bool BuddyIsCompanionAccount(uint32 accountId);
// <<< ${B065_TAG} END" after || return 1

    b065_insert "${FILE}" "${B065_ITEM_ANCHOR}" \
"    // >>> ${B065_TAG} BEGIN
    // A buddy leaves a quest's item in the corpse for its owner (617j)
    if (BuddyIsCompanionAccount(botAI->GetBot()->GetSession()->GetAccountId())
        && (proto->Class == ITEM_CLASS_QUEST || proto->Bonding == BIND_QUEST_ITEM || proto->StartQuest))
        return false;
    // <<< ${B065_TAG} END" before || return 1

    b065_insert "${FILE}" "${B065_OBJECT_ANCHOR}" \
"    // >>> ${B065_TAG} BEGIN
    // A buddy never opens an object a quest gates; the owner's to use (617j)
    if (go && go->HasFlag(GAMEOBJECT_FLAGS, GO_FLAG_INTERACT_COND)
        && BuddyIsCompanionAccount(bot->GetSession()->GetAccountId()))
        return false;
    // <<< ${B065_TAG} END" before || return 1
    echo "  [B065] Applied: buddies leave quest loot for their owner"
}

unpatch_B065_playerbots_buddies_leave_quest_loot() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/LootAction.cpp"
    [[ -f "${FILE}" ]] || return 0
    grep -qF "${B065_TAG}" "${FILE}" || return 0                  # nothing of ours
    awk '
        /\/\/ >>> B065-buddies-leave-quest-loot BEGIN/ { inblock = 1; next }
        inblock && /\/\/ <<< B065-buddies-leave-quest-loot END/ { inblock = 0; next }
        inblock { next }
        { print }' "${FILE}" > "${FILE}.b065" && mv "${FILE}.b065" "${FILE}"
    echo "  [B065] Reverted"
}
