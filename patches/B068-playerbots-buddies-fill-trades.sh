#!/usr/bin/env bash

B068_BEGIN='// >>> B068-buddies-fill-trades BEGIN'
B068_END='// <<< B068-buddies-fill-trades END'
B068_SIGNATURE='void TradeStatusAction::BeginTrade()'
B068_CHECK='    if (!trader || (GET_PLAYERBOT_AI(trader) && !IsSelfBot(trader)))'

patch_B068_playerbots_buddies_fill_trades() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/TradeStatusAction.cpp"
    [[ -f "${FILE}" ]] || { echo "  [B068] ERROR: TradeStatusAction.cpp missing under ${AC_CODE_DIR}"; return 1; }
    grep -qF "B068-buddies-fill-trades" "${FILE}" && return 0       # witness guard

    local a b
    a=$(grep -cxF -- "${B068_SIGNATURE}" "${FILE}")
    b=$(grep -cxF -- "${B068_CHECK}" "${FILE}")
    if [[ "${a}${b}" != "11" ]]; then
        echo "  [B068] ERROR: anchors found in TradeStatusAction.cpp (want 1 each): BeginTrade ${a}, its trader check ${b}"
        return 1
    fi

    SIG="${B068_SIGNATURE}" CHECK="${B068_CHECK}" BEGIN_M="${B068_BEGIN}" END_M="${B068_END}" awk '
        $0 == ENVIRON["SIG"] {
            print ENVIRON["BEGIN_M"]
            print "// Everland Ghostsong (issue 623): the buddy module opens a buddy'"'"'s side of a"
            print "// trade itself (defined in mod-buddies, buddies_trade.cpp)."
            print "bool BuddyBeginTrade(Player* bot, Player* trader);"
            print ENVIRON["END_M"]
            print
            next
        }
        $0 == ENVIRON["CHECK"] { print; afterCheck = 1; next }
        afterCheck {
            print
            print "    " ENVIRON["BEGIN_M"]
            print "    // a buddy: the window opened, its owner'"'"'s earmarked items put in, no"
            print "    // inventory whisper; anyone else: the stock steps below"
            print "    if (BuddyBeginTrade(bot, trader))"
            print "        return;"
            print "    " ENVIRON["END_M"]
            afterCheck = 0
            next
        }
        { print }
    ' "${FILE}" > "${FILE}.b068" && mv "${FILE}.b068" "${FILE}"

    if [[ "$(grep -c "B068-buddies-fill-trades" "${FILE}")" != "4" ]]; then
        echo "  [B068] ERROR: the patch did not land in both places in TradeStatusAction.cpp"
        return 1
    fi
    echo "  [B068] A buddy opening a trade puts in what is earmarked for its owner (TradeStatusAction)"
}

unpatch_B068_playerbots_buddies_fill_trades() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/TradeStatusAction.cpp"
    [[ -f "${FILE}" ]] || return 0
    grep -qF "B068-buddies-fill-trades" "${FILE}" || return 0      # nothing of ours
    awk '
        /\/\/ >>> B068-buddies-fill-trades BEGIN/ { inblock = 1; next }
        inblock && /\/\/ <<< B068-buddies-fill-trades END/ { inblock = 0; next }
        inblock { next }
        { print }' "${FILE}" > "${FILE}.b068" && mv "${FILE}.b068" "${FILE}"
    return 0
}
