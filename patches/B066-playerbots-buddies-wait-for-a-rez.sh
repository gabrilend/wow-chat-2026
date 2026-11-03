#!/usr/bin/env bash

B066_BEGIN='// >>> B066-buddies-wait-for-a-rez BEGIN'
B066_END='// <<< B066-buddies-wait-for-a-rez END'
B066_SIGNATURE='bool AutoReleaseSpiritAction::ShouldAutoRelease() const'

patch_B066_playerbots_buddies_wait_for_a_rez() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/ReleaseSpiritAction.cpp"
    [[ -f "${FILE}" ]] || { echo "  [B066] ERROR: ReleaseSpiritAction.cpp missing under ${AC_CODE_DIR}"; return 1; }
    grep -qF "B066-buddies-wait-for-a-rez" "${FILE}" && return 0       # witness guard

    local a
    a=$(grep -cxF -- "${B066_SIGNATURE}" "${FILE}")
    if [[ "${a}" != "1" ]]; then
        echo "  [B066] ERROR: anchor found in ReleaseSpiritAction.cpp ${a} times (want 1): ${B066_SIGNATURE}"
        return 1
    fi

    SIG="${B066_SIGNATURE}" BEGIN_M="${B066_BEGIN}" END_M="${B066_END}" awk '
        $0 == ENVIRON["SIG"] {
            print ENVIRON["BEGIN_M"]
            print "// Everland Ghostsong (issue 632): the buddy module says when a dead buddy"
            print "// releases (defined in mod-buddies, buddies_release.cpp)."
            print "int BuddyReleaseRule(Player* bot);"
            print ENVIRON["END_M"]
            print
            sig = 1
            next
        }
        sig && $0 == "{" {
            print
            print "    " ENVIRON["BEGIN_M"]
            print "    // a buddy: 1 release now, 0 wait; anyone else (-1): the stock rules below"
            print "    if (int rule = BuddyReleaseRule(bot); rule >= 0)"
            print "        return rule == 1;"
            print "    " ENVIRON["END_M"]
            sig = 0
            next
        }
        { print }
    ' "${FILE}" > "${FILE}.b066" && mv "${FILE}.b066" "${FILE}"

    if ! grep -qF "BuddyReleaseRule(bot); rule >= 0" "${FILE}"; then
        echo "  [B066] ERROR: the opening brace after the anchor was not found; the patch is incomplete"
        return 1
    fi
    echo "  [B066] A dead buddy releases by the buddy module's rule (ReleaseSpiritAction)"
}

unpatch_B066_playerbots_buddies_wait_for_a_rez() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/ReleaseSpiritAction.cpp"
    [[ -f "${FILE}" ]] || return 0
    grep -qF "B066-buddies-wait-for-a-rez" "${FILE}" || return 0      # nothing of ours
    awk '
        /\/\/ >>> B066-buddies-wait-for-a-rez BEGIN/ { inblock = 1; next }
        inblock && /\/\/ <<< B066-buddies-wait-for-a-rez END/ { inblock = 0; next }
        inblock { next }
        { print }' "${FILE}" > "${FILE}.b066" && mv "${FILE}.b066" "${FILE}"
    return 0
}
