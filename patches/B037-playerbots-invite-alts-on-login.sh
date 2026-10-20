#!/usr/bin/env bash

B037_TAG='B037-invite-alts-on-login'
B037_H_ANCHOR='    bool KeepAltsInGroup() const { return keepAltsInGroup; }'
B037_CPP_ANCHOR='    keepAltsInGroup = sConfigMgr->GetOption<bool>("AiPlayerbot.KeepAltsInGroup", false);'
B037_MGR_BEFORE='    // Queue group operations for world thread'
B037_MGR_AFTER='    // if (master)'
B037_CONF_ANCHOR='AiPlayerbot.KeepAltsInGroup = 0'

b037_insert() {
    local file="$1" anchor="$2" block="$3" where="$4"
    local count
    count=$(grep -cxF -- "${anchor}" "${file}")
    if [[ "${count}" -ne 1 ]]; then
        echo "  [B037] ERROR: expected exactly one '${anchor}' in ${file}, found ${count}"
        return 1
    fi
    ANCHOR="${anchor}" BLOCK="${block}" WHERE="${where}" awk '
        $0 == ENVIRON["ANCHOR"] && ENVIRON["WHERE"] == "before" { print ENVIRON["BLOCK"] }
        { print }
        $0 == ENVIRON["ANCHOR"] && ENVIRON["WHERE"] == "after" { print ENVIRON["BLOCK"] }' \
        "${file}" > "${file}.b037" && mv "${file}.b037" "${file}"
}

patch_B037_playerbots_invite_alts_on_login() {
    local SRC="${AC_CODE_DIR}/modules/mod-playerbots/src"
    local H="${SRC}/PlayerbotAIConfig.h" CPP="${SRC}/PlayerbotAIConfig.cpp" MGR="${SRC}/Bot/PlayerbotMgr.cpp"
    local CONF="${AC_CODE_DIR}/modules/mod-playerbots/conf/playerbots.conf.dist"
    local f
    for f in "${H}" "${CPP}" "${MGR}" "${CONF}"; do
        [[ -f "${f}" ]] || { echo "  [B037] ERROR: ${f} missing"; return 1; }
    done
    grep -qF "${B037_TAG}" "${MGR}" && return 0                  # witness guard

    b037_insert "${H}" "${B037_H_ANCHOR}" \
"    // >>> ${B037_TAG} BEGIN
    // Whether a player's own (non-random) bot is put into its player's group
    // at login. 1 = stock. Off on basic, where buddies are grouped by distance.
    bool inviteAltsOnLogin = true;
    bool InviteAltsOnLogin() const { return inviteAltsOnLogin; }
    // <<< ${B037_TAG} END" after || return 1

    b037_insert "${CPP}" "${B037_CPP_ANCHOR}" \
"    // >>> ${B037_TAG} BEGIN
    inviteAltsOnLogin = sConfigMgr->GetOption<bool>(\"AiPlayerbot.InviteAltsOnLogin\", true);
    // <<< ${B037_TAG} END" after || return 1

    b037_insert "${MGR}" "${B037_MGR_BEFORE}" \
"    // >>> ${B037_TAG} BEGIN
    // AiPlayerbot.InviteAltsOnLogin = 0: no login invite for a player's own
    // bot. Both invite branches below test \`master\`, so it is cleared for
    // them and put back after (the rest of this function uses it).
    Player* const b037Master = master;
    if (!sPlayerbotAIConfig.InviteAltsOnLogin() && !sRandomPlayerbotMgr.IsRandomBot(bot))
        master = nullptr;
    // <<< ${B037_TAG} END" before || return 1

    b037_insert "${MGR}" "${B037_MGR_AFTER}" \
"    // >>> ${B037_TAG} BEGIN
    master = b037Master;
    // <<< ${B037_TAG} END" before || return 1

    b037_insert "${CONF}" "${B037_CONF_ANCHOR}" \
"# >>> ${B037_TAG} BEGIN

# Put a player's own (non-random) bot into its player's group at login
# 0 = no (the player's own system groups them), 1 = yes (default)
AiPlayerbot.InviteAltsOnLogin = 1
# <<< ${B037_TAG} END" after || return 1

    echo "  [B037] Playerbots: AiPlayerbot.InviteAltsOnLogin switch for the login group invite"
}

unpatch_B037_playerbots_invite_alts_on_login() {
    local SRC="${AC_CODE_DIR}/modules/mod-playerbots/src"
    local f
    for f in "${SRC}/PlayerbotAIConfig.h" "${SRC}/PlayerbotAIConfig.cpp" "${SRC}/Bot/PlayerbotMgr.cpp" \
             "${AC_CODE_DIR}/modules/mod-playerbots/conf/playerbots.conf.dist"; do
        [[ -f "${f}" ]] || continue
        grep -qF "B037-invite-alts-on-login" "${f}" || continue    # nothing of ours
        awk '
            /(\/\/|#) >>> B037-invite-alts-on-login BEGIN/ { inblock = 1; next }
            inblock && /(\/\/|#) <<< B037-invite-alts-on-login END/ { inblock = 0; next }
            inblock { next }
            { print }' "${f}" > "${f}.b037" && mv "${f}.b037" "${f}"
    done
    return 0
}
