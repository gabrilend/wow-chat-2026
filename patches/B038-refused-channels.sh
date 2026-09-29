#!/usr/bin/env bash
# B038 - Built-in chat channels a profile refuses
# Issue 155x (basic, 2026-09-27).
#
# For a general audience: on basic, nobody joins the world's shared chat
# channels (General, Trade, LocalDefense, WorldDefense), so news doesn't
# spread across a zone or the world. The owner, 2026-09-27: "to keep news
# from spreading" (via the coordinator): players never join General, Trade,
# LocalDefense, and WorldDefense, which carries the same kind of news. The
# player's own channels ("/join anything") and the others (Looking For
# Group, Guild Recruitment) are unaffected. A refused join is silent: no
# error line in the chat window, the channel simply isn't there.
#
# Why a source patch: no script hook sees every join. A player's client
# asks to join at login (a request a module could drop), but the server
# itself moves players between zone channels on every zone change
# (Player::UpdateLocalChannels), and the bot module joins its bots directly
# (PlayerbotHolder, PlayerbotMgr.cpp); all three end in Channel::JoinChannel,
# so the refusal sits at its top.
#
# Which channels: the worldserver setting Basic.RefusedChannels, a list of
# the client's channel numbers (ChatChannels.dbc: 1 General, 2 Trade,
# 22 LocalDefense, 23 WorldDefense, 25 GuildRecruitment, 26 LookingForGroup),
# set by C031 on basic. With the setting
# absent (every other profile) nothing is refused, so the patch is safe in
# any profile's build. Read once, at the first join after start; changing it
# needs a restart.
#
# Mechanics: two pure insertions inside ">>> B038 ... BEGIN" / "<<< B038 ...
# END" marker comments: the includes after the file's first include, and the
# check as the first lines of Channel::JoinChannel's body (after the opening
# brace that follows its signature). The revert removes both blocks. Anchors
# must occur exactly once or the patch stops with an error.
# Parallelizable: Yes (unique file)

B038_BEGIN='// >>> B038-refused-channels BEGIN'
B038_END='// <<< B038-refused-channels END'
B038_INCLUDE_ANCHOR='#include "AccountMgr.h"'
B038_FN_ANCHOR='void Channel::JoinChannel(Player* player, std::string const& pass)'

# {{{ patch_B038_refused_channels
patch_B038_refused_channels() {
    local FILE="${AC_CODE_DIR}/src/server/game/Chat/Channels/Channel.cpp"
    [[ -f "${FILE}" ]] || { echo "  [B038] ERROR: ${FILE} missing"; return 1; }
    grep -qF "B038-refused-channels" "${FILE}" && return 0      # witness guard
    local a b
    a=$(grep -cxF -- "${B038_INCLUDE_ANCHOR}" "${FILE}")
    b=$(grep -cxF -- "${B038_FN_ANCHOR}" "${FILE}")
    if [[ "${a}" -ne 1 || "${b}" -ne 1 ]]; then
        echo "  [B038] ERROR: expected one '${B038_INCLUDE_ANCHOR}' and one JoinChannel signature in ${FILE}, found ${a} and ${b}"
        return 1
    fi
    INC="${B038_INCLUDE_ANCHOR}" FN="${B038_FN_ANCHOR}" BEGIN_M="${B038_BEGIN}" END_M="${B038_END}" awk '
        { print }
        $0 == ENVIRON["INC"] && !inc {
            print ENVIRON["BEGIN_M"]
            print "#include \"Config.h\""
            print "#include <set>"
            print "#include <sstream>"
            print ENVIRON["END_M"]
            inc = 1
        }
        infn && $0 == "{" {
            print "    " ENVIRON["BEGIN_M"]
            print "    // Everland Ghostsong (issue 155x): built-in channels this profile refuses"
            print "    // (Basic.RefusedChannels: ChatChannels.dbc numbers). No one joins them:"
            print "    // players, bots, or the server'"'"'s own zone moves. Silent. Read once."
            print "    {"
            print "        static std::set<uint32> const refused = []"
            print "        {"
            print "            std::set<uint32> ids;"
            print "            std::istringstream in(sConfigMgr->GetOption<std::string>(\"Basic.RefusedChannels\", \"\", false));"
            print "            for (uint32 id; in >> id; )"
            print "                ids.insert(id);"
            print "            return ids;"
            print "        }();"
            print "        if (IsConstant() && refused.count(GetChannelId()))"
            print "            return;"
            print "    }"
            print "    " ENVIRON["END_M"]
            infn = 0
        }
        $0 == ENVIRON["FN"] { infn = 1 }
    ' "${FILE}" > "${FILE}.b038" && mv "${FILE}.b038" "${FILE}"
    echo "  [B038] Built-in channels a profile refuses (Basic.RefusedChannels)"
}
# }}}

# {{{ unpatch_B038_refused_channels
unpatch_B038_refused_channels() {
    local FILE="${AC_CODE_DIR}/src/server/game/Chat/Channels/Channel.cpp"
    [[ -f "${FILE}" ]] || return 0
    grep -qF "B038-refused-channels" "${FILE}" || return 0         # nothing of ours
    awk '
        /\/\/ >>> B038-refused-channels BEGIN/ { inblock = 1; next }
        inblock && /\/\/ <<< B038-refused-channels END/ { inblock = 0; next }
        inblock { next }
        { print }' "${FILE}" > "${FILE}.b038" && mv "${FILE}.b038" "${FILE}"
    return 0
}
# }}}
