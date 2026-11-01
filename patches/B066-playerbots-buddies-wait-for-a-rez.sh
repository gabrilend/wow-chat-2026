#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         B066
# profiles:   buddy-set
# priority:   760
# kind:       source
# about:      Playerbots: a dead buddy releases by the buddy module's rule (wait for a nearby rez, ask for one) (issue 632)
# ==== end of header ====
# B066 - Playerbots: a dead buddy releases by the buddy module's rule
# Issue 632 (2026-10-31).
#
# For a general audience: when a bot dies, the bot module decides when it
# releases its spirit (at once, unless its human leader is near in a
# dungeon). The owner, 2026-10-22: "after 1-10 seconds after they die they
# click "release spirit" unless there's a person nearby who maybe can rez
# them alive and on their side. If so, then they wait." And 2026-10-30:
# "anyone on their side who knows one. Within 70 yards probably", "it waits
# until they are out of range. After 10-20 seconds it whispers them asking
# them for a rez." The rule lives in the buddy module
# (buddies_release.cpp, BuddyReleaseRule); this patch has the bot module
# ask it first, for every bot: a buddy gets the buddy module's answer,
# anyone else the stock rules.
#
# Mechanics, one file, each insertion inside ">>> B066 ... BEGIN" /
# "<<< B066 ... END" marker comments:
#   ReleaseSpiritAction.cpp   the buddy module's rule declared above the
#                             auto-release check (a function defined in
#                             mod-buddies, linked into the same modules
#                             library, as B046 does), and asked at the
#                             check's start: 0 hold, 1 release, -1 not a
#                             buddy (the stock rules follow).
# Needs B036 (mod-buddies, which defines the rule); both are on the buddy
# set only. Anchors must occur exactly once or the patch stops with an
# error.
# Needs: B036
# Parallelizable: Yes

B066_BEGIN='// >>> B066-buddies-wait-for-a-rez BEGIN'
B066_END='// <<< B066-buddies-wait-for-a-rez END'
B066_SIGNATURE='bool AutoReleaseSpiritAction::ShouldAutoRelease() const'

# {{{ patch_B066_playerbots_buddies_wait_for_a_rez
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

    # Before the signature: the declaration. After the signature's opening
    # brace (the next line): the question.
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
# }}}

# {{{ unpatch_B066_playerbots_buddies_wait_for_a_rez
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
# }}}
# ==== footer of B066 ====
# lines:      104
# ==== end of footer ====
