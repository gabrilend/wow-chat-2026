#!/usr/bin/env bash

B044_BEGIN='// >>> B044-companion-accounts-unseen BEGIN'
B044_END='// <<< B044-companion-accounts-unseen END'
B044_WHO_INCLUDE='#include "WhoListCacheMgr.h"'
B044_WHO_LOADING='        if (!player->FindMap() || player->GetSession()->PlayerLoading())'
B044_SOCIAL_INCLUDE='#include "SocialMgr.h"'
B044_SOCIAL_ACCOUNT='    uint32 friendAccountId = playerData->AccountId;'

patch_B044_companion_accounts_unseen() {
    local CACHE="${AC_CODE_DIR}/src/server/game/Cache"
    local HEADER="${CACHE}/CompanionAccounts.h"
    local WHO="${CACHE}/WhoListCacheMgr.cpp"
    local SOCIAL="${AC_CODE_DIR}/src/server/game/Handlers/Socialhandler.cpp"
    [[ -f "${WHO}" && -f "${SOCIAL}" ]] || { echo "  [B044] ERROR: WhoListCacheMgr.cpp or Socialhandler.cpp missing under ${AC_CODE_DIR}"; return 1; }
    grep -qF "B044-companion-accounts-unseen" "${WHO}" && return 0     # witness guard

    local a b c d
    a=$(grep -cxF -- "${B044_WHO_INCLUDE}" "${WHO}")
    b=$(grep -cxF -- "${B044_WHO_LOADING}" "${WHO}")
    c=$(grep -cxF -- "${B044_SOCIAL_INCLUDE}" "${SOCIAL}")
    d=$(grep -cxF -- "${B044_SOCIAL_ACCOUNT}" "${SOCIAL}")
    if [[ "${a}${b}${c}${d}" != "1111" ]]; then
        echo "  [B044] ERROR: anchors found (want 1 each): WhoListCacheMgr.h include ${a}, who loading test ${b}," \
             "SocialMgr.h include ${c}, friend account line ${d}"
        return 1
    fi

    cat > "${HEADER}" <<'EOF'
// B044-companion-accounts-unseen (issue 617a5): created by
// patches/B044-companion-accounts-unseen.sh, removed by its revert.
//
// Companion accounts: accounts whose characters are bot companions (on
// basic, the buddies). Their characters are left out of /who and can't be
// added as friends; the bot module ignores chat commands sent to them
// (B045). Filled by whoever owns the accounts (mod-buddies); in memory only,
// so the owner refills it at every startup.
#ifndef COMPANION_ACCOUNTS_H
#define COMPANION_ACCOUNTS_H

#include "Define.h"

namespace CompanionAccounts
{
    void Mark(uint32 accountId);                                // add to the list
    void Unmark(uint32 accountId);                              // the account is gone
    bool Is(uint32 accountId);                                  // listed?
}

#endif
EOF

    INC="${B044_WHO_INCLUDE}" LOADING="${B044_WHO_LOADING}" BEGIN_M="${B044_BEGIN}" END_M="${B044_END}" awk '
        { print }
        $0 == ENVIRON["INC"] && !inc {
            print ENVIRON["BEGIN_M"]
            print "#include \"CompanionAccounts.h\""
            print "#include <shared_mutex>"
            print "#include <unordered_set>"
            print ENVIRON["END_M"]
            inc = 1
        }
        $0 == ENVIRON["LOADING"] { sawtest = 1; next }
        sawtest && $0 == "            continue;" {
            print "        " ENVIRON["BEGIN_M"]
            print "        // Everland Ghostsong (issue 617a5): a companion account'"'"'s character (a"
            print "        // buddy) is never in /who; everyone else is listed as stock."
            print "        if (CompanionAccounts::Is(player->GetSession()->GetAccountId()))"
            print "            continue;"
            print "        " ENVIRON["END_M"]
        }
        { sawtest = 0 }
    ' "${WHO}" > "${WHO}.b044" && mv "${WHO}.b044" "${WHO}"

    cat >> "${WHO}" <<EOF
${B044_BEGIN}

// Everland Ghostsong (issue 617a5): the companion-account list. Read by the
// who cache (world thread) and friend requests (session threads), written
// by the buddy module, so a reader-writer lock guards it.
namespace CompanionAccounts
{
    static std::shared_mutex          sLock;
    static std::unordered_set<uint32> sAccounts;                // account ids

    void Mark(uint32 accountId)
    {
        std::unique_lock<std::shared_mutex> lock(sLock);
        sAccounts.insert(accountId);
    }

    void Unmark(uint32 accountId)
    {
        std::unique_lock<std::shared_mutex> lock(sLock);
        sAccounts.erase(accountId);
    }

    bool Is(uint32 accountId)
    {
        std::shared_lock<std::shared_mutex> lock(sLock);
        return sAccounts.count(accountId) != 0;
    }
}
${B044_END}
EOF

    INC="${B044_SOCIAL_INCLUDE}" ACCOUNT="${B044_SOCIAL_ACCOUNT}" BEGIN_M="${B044_BEGIN}" END_M="${B044_END}" awk '
        { print }
        $0 == ENVIRON["INC"] && !inc {
            print ENVIRON["BEGIN_M"]
            print "#include \"CompanionAccounts.h\""
            print ENVIRON["END_M"]
            inc = 1
        }
        $0 == ENVIRON["ACCOUNT"] {
            print "    " ENVIRON["BEGIN_M"]
            print "    // Everland Ghostsong (issue 617a5): a buddy can'"'"'t be anyone'"'"'s friend; the"
            print "    // asker hears what an unknown name gets, so a buddy reads as nobody."
            print "    if (CompanionAccounts::Is(friendAccountId))"
            print "    {"
            print "        sSocialMgr->SendFriendStatus(GetPlayer(), FRIEND_NOT_FOUND, ObjectGuid::Empty, false);"
            print "        return;"
            print "    }"
            print "    " ENVIRON["END_M"]
        }
    ' "${SOCIAL}" > "${SOCIAL}.b044" && mv "${SOCIAL}.b044" "${SOCIAL}"

    echo "  [B044] Companion accounts: their characters are left out of /who and can't be friended (CompanionAccounts)"
}

unpatch_B044_companion_accounts_unseen() {
    local CACHE="${AC_CODE_DIR}/src/server/game/Cache"
    local f
    rm -f "${CACHE}/CompanionAccounts.h"
    for f in "${CACHE}/WhoListCacheMgr.cpp" "${AC_CODE_DIR}/src/server/game/Handlers/Socialhandler.cpp"; do
        [[ -f "${f}" ]] || continue
        grep -qF "B044-companion-accounts-unseen" "${f}" || continue    # nothing of ours
        awk '
            /\/\/ >>> B044-companion-accounts-unseen BEGIN/ { inblock = 1; next }
            inblock && /\/\/ <<< B044-companion-accounts-unseen END/ { inblock = 0; next }
            inblock { next }
            { print }' "${f}" > "${f}.b044" && mv "${f}.b044" "${f}"
    done
    return 0
}
