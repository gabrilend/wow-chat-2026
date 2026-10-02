#!/usr/bin/env bash
# B044 - Companion accounts: their characters are not in /who and can't be friended
# Issue 617a5 (basic, 2026-10-02).
#
# For a general audience: on basic every player's buddies live on a hidden
# "companion account" of their own. The owner's decisions of 2026-09-25
# (617a): buddies never appear in the /who list, and nobody can add one as a
# friend. The server builds /who from every player in the world, and refuses
# a friend only when the target is on a staff account; neither has a script
# hook. Making the companion accounts staff would hide buddies from both with
# no code, but staff characters can carry game-master states (invisible, no
# aggro), which a bot must never have. So this patch gives the server a
# plain list, "these accounts are companion accounts", that the buddy module
# fills (modules/mod-buddies/src/buddies_hidden.cpp), and two checks of it:
#   /who        a character on a listed account is left out of the list
#   add friend  a character on a listed account answers "player not found"
# The bot module asks the same list whether a bot is a buddy, to drop chat
# commands sent to it (B045).
#
# Mechanics, three files, each insertion inside ">>> B044 ... BEGIN" /
# "<<< B044 ... END" marker comments:
#   CompanionAccounts.h    created in Cache/ (removed on revert): the list's
#                          three calls. A header of its own so the module and
#                          the bot module can include it without touching a
#                          header the whole server includes.
#   WhoListCacheMgr.cpp    the list itself appended at the end (a set behind a
#                          reader-writer lock: the who cache updates on the
#                          world thread, friend requests arrive on session
#                          threads, the module writes at startup and logins);
#                          and in Update, a listed account's characters skipped.
#   Socialhandler.cpp      in the add-friend handler, a listed account's
#                          character is refused as not found.
# Anchors must occur exactly once or the patch stops with an error.
# Parallelizable: No (B045 includes the header this creates)

B044_BEGIN='// >>> B044-companion-accounts-unseen BEGIN'
B044_END='// <<< B044-companion-accounts-unseen END'
B044_WHO_INCLUDE='#include "WhoListCacheMgr.h"'
B044_WHO_LOADING='        if (!player->FindMap() || player->GetSession()->PlayerLoading())'
B044_SOCIAL_INCLUDE='#include "SocialMgr.h"'
B044_SOCIAL_ACCOUNT='    uint32 friendAccountId = playerData->AccountId;'

# {{{ patch_B044_companion_accounts_unseen
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
# }}}

# {{{ unpatch_B044_companion_accounts_unseen
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
# }}}
