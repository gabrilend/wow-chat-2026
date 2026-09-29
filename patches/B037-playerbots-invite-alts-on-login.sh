#!/usr/bin/env bash
# B037 - Playerbots: a switch for the group invite at a bot's login
# Issue 617c2 (basic, 2026-09-27).
#
# For a general audience: when a player's own bot (an "alt", here a buddy)
# logs in, the bot module always puts it into its player's group, making a
# raid once the party holds five. On basic, buddies are grouped by distance
# from their owner instead (modules/mod-buddies/src/buddies_party.cpp), so
# that login invite only makes a raid for the distance pass to break up
# again. The owner (2026-09-27): "we can probably remove the playerbots
# buddy-group-up-at-login functions. We're using a different system for
# grouping up." The module has no setting for it; this patch adds one,
# AiPlayerbot.InviteAltsOnLogin, 1 by default (the stock behaviour), and
# basic's config (C030) turns it off. Random bots are never affected.
#
# Where: the only login invite is in PlayerbotMgr::OnBotLogin, two branches
# ("the master has a group" / "the master has none") that both test the
# local `master`. The patch clears `master` just before them when the
# switch is off (and the bot is not a random bot), and puts it back right
# after, since the rest of the function uses it.
#
# Mechanics: pure insertions between ">>> B037-invite-alts-on-login BEGIN"
# / "<<< ... END" marker comments (// in code, # in the config template),
# after anchors that must each occur
# exactly once (else the patch stops); the revert deletes the blocks.
# Parallelizable: Yes (files not touched by other basic B-patches in the
# same regions: PlayerbotAIConfig.h/.cpp, conf/playerbots.conf.dist;
# PlayerbotMgr.cpp is also patched by
# B026 and B002 but in other functions)

B037_TAG='B037-invite-alts-on-login'
B037_H_ANCHOR='    bool KeepAltsInGroup() const { return keepAltsInGroup; }'
B037_CPP_ANCHOR='    keepAltsInGroup = sConfigMgr->GetOption<bool>("AiPlayerbot.KeepAltsInGroup", false);'
B037_MGR_BEFORE='    // Queue group operations for world thread'
B037_MGR_AFTER='    // if (master)'
B037_CONF_ANCHOR='AiPlayerbot.KeepAltsInGroup = 0'

# {{{ b037_insert
# Insert the lines of $3 after (where=after) or before (where=before) the
# one line equal to $2 in file $1. Stops if the anchor is not there exactly
# once.
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
# }}}

# {{{ patch_B037_playerbots_invite_alts_on_login
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

    # the setting documented in the module's config template, so installs
    # carry it like any stock key (and config patches can set it by name)
    b037_insert "${CONF}" "${B037_CONF_ANCHOR}" \
"# >>> ${B037_TAG} BEGIN

# Put a player's own (non-random) bot into its player's group at login
# 0 = no (the player's own system groups them), 1 = yes (default)
AiPlayerbot.InviteAltsOnLogin = 1
# <<< ${B037_TAG} END" after || return 1

    echo "  [B037] Playerbots: AiPlayerbot.InviteAltsOnLogin switch for the login group invite"
}
# }}}

# {{{ unpatch_B037_playerbots_invite_alts_on_login
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
# }}}
