#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         B065
# profiles:   buddy-set
# priority:   750
# kind:       source
# about:      Playerbots: buddies leave quest items on corpses and quest objects untouched, for their owner (issue 617j)
# ==== end of header ====
# B065 - Playerbots: buddies leave quest loot for their owner
# Issue 617j (2026-10-30).
#
# For a general audience: a buddy's quests are done when its owner's are,
# so it has no use for what quests ask for, and taking it leaves the owner
# short. The owner, 2026-10-30: "buddy-bots should not take quest items.
# Their quests are completed when the player completes them, so there's no
# reason for the buddy-bots to take them. They should leave them on corpses
# and leave the nodes behind." The bot module's looting stays the owner of
# every decision about bots in general; this only adds, for buddies (a
# companion account, asked of the buddy module), two refusals:
#
#   1. an item that is a quest's: of the quest item class, bound as a quest
#      item, or one that starts a quest. Left in the corpse (the bot module
#      otherwise takes one its own quest log needs, and any quest starter);
#   2. an object a quest gates (the "interact only on condition" flag the
#      game puts on quest objects: crates to search, plants to pick for a
#      quest): never opened.
#
# Needs B036 (the buddy module, which answers whether an account is a
# companion's): without it the server fails to link, which says loudly
# what is missing, as B046 does.
#
# Mechanics: pure insertions between ">>> B065-buddies-leave-quest-loot
# BEGIN" / "<<< ... END" marker comments, beside anchors that must each
# occur exactly once in LootAction.cpp (else the patch stops); the revert
# deletes the blocks. No other patch touches LootAction.cpp.

B065_TAG='B065-buddies-leave-quest-loot'
B065_INCLUDE='#include "LootAction.h"'
B065_ITEM_ANCHOR='    if (proto->StartQuest)'
B065_OBJECT_ANCHOR='    if (go && go->HasFlag(GAMEOBJECT_FLAGS, GO_FLAG_INTERACT_COND) && !go->ActivateToQuest(bot))'

# {{{ b065_insert
# Insert the lines of $3 after (where=after) or before (where=before) the
# one line equal to $2 in file $1. Stops if the anchor is not there exactly
# once.
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
# }}}

# {{{ patch_B065_playerbots_buddies_leave_quest_loot
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
# }}}

# {{{ unpatch_B065_playerbots_buddies_leave_quest_loot
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
# }}}
# ==== footer of B065 ====
# lines:      109
# ==== end of footer ====
