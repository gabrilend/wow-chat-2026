#!/usr/bin/env bash

B038_BEGIN='// >>> B038-refused-channels BEGIN'
B038_END='// <<< B038-refused-channels END'
B038_INCLUDE_ANCHOR='#include "AccountMgr.h"'
B038_FN_ANCHOR='void Channel::JoinChannel(Player* player, std::string const& pass)'

patch_B038_refused_channels() {
    local FILE="${AC_CODE_DIR}/src/server/game/Chat/Channels/Channel.cpp"
    [[ -f "${FILE}" ]] || { echo "  [B038] ERROR: ${FILE} missing"; return 1; }
    grep -qF "B038-refused-channels" "${FILE}" && return 0      # witness guard
    local a b
    a=$(grep -cxF -- "${B038_INCLUDE_ANCHOR}" "${FILE}" || true)
    b=$(grep -cxF -- "${B038_FN_ANCHOR}" "${FILE}" || true)
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
