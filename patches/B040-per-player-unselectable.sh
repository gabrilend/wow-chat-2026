#!/usr/bin/env bash
# B040 - Creatures one player cannot select
# Issue 164 (2026-09-29).
#
# For a general audience: whether a creature can be clicked and targeted
# is one bit in its flags, the same for everyone. The server already sends
# each player their own copy of those flags (it clears the bit for game
# masters, so they can select anything); this patch lets a script add the
# bit for one player: "these creatures are not selectable to you", or "no
# creature is, except these". Everyone else sees the creature as it is.
# The owner, 2026-09-29: "Do we have tech to make a creature untargetable
# to a specific other player? If not, then we should build it, because
# that's useful." First use: a death knight owing a soul can select no one
# in Acherus but Sargobras (issue 718).
#
# Why a source patch: the per-viewer copy is made inside
# Unit::PatchValuesUpdate, which no script hook reaches.
#
# Mechanics, three files, each insertion inside ">>> B040 ... BEGIN" /
# "<<< B040 ... END" marker comments:
#   PerPlayerCreatures.h  created (a new header, removed on revert): the
#                          rule's four calls. Kept out of Player.h on
#                          purpose: nearly every file includes Player.h,
#                          so touching it would rebuild almost everything.
#   Unit.cpp               the rules (a map from player to rule, behind a
#                          reader-writer lock: maps update on several
#                          threads), appended at the end; and in the
#                          unit-flags step of PatchValuesUpdate, the bit
#                          added for a covered creature, before the game
#                          master line (GM mode still wins). A player's own
#                          pets and guardians are never covered.
#   Player.cpp             GetNPCIfCanInteractWith refuses a covered
#                          creature (a client that asks anyway gets
#                          nothing); ~Player forgets the player's rule.
# Setting or clearing a rule re-sends the flags of every creature within
# the player's sight, so the change shows at once.
# The Lua calls are B041 (mod-ale). Anchors must occur exactly once or the
# patch stops with an error.
# Parallelizable: No (B041 includes the header this creates)

B040_BEGIN='// >>> B040-per-player-unselectable BEGIN'
B040_END='// <<< B040-per-player-unselectable END'
B040_UNIT_INCLUDE='#include "Unit.h"'
B040_UNIT_FLAGS='        uint32 appendValue = m_uint32Values[UNIT_FIELD_FLAGS];'
B040_PLAYER_INCLUDE='#include "Player.h"'
B040_PLAYER_FN='Creature* Player::GetNPCIfCanInteractWith(ObjectGuid const& guid, uint32 npcflagmask)'
B040_PLAYER_DTOR='    sScriptMgr->OnDestructPlayer(this);'

# {{{ patch_B040_per_player_unselectable
patch_B040_per_player_unselectable() {
    local DIR_UNIT="${AC_CODE_DIR}/src/server/game/Entities/Unit"
    local HEADER="${DIR_UNIT}/PerPlayerCreatures.h"
    local UNIT="${DIR_UNIT}/Unit.cpp"
    local PLAYER="${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp"
    [[ -f "${UNIT}" && -f "${PLAYER}" ]] || { echo "  [B040] ERROR: Unit.cpp or Player.cpp missing under ${AC_CODE_DIR}"; return 1; }
    grep -qF "B040-per-player-unselectable" "${UNIT}" && return 0     # witness guard

    local a b c d e
    a=$(grep -cxF -- "${B040_UNIT_INCLUDE}" "${UNIT}")
    b=$(grep -cxF -- "${B040_UNIT_FLAGS}" "${UNIT}")
    c=$(grep -cxF -- "${B040_PLAYER_INCLUDE}" "${PLAYER}")
    d=$(grep -cxF -- "${B040_PLAYER_FN}" "${PLAYER}")
    e=$(grep -cxF -- "${B040_PLAYER_DTOR}" "${PLAYER}")
    if [[ "${a}${b}${c}${d}${e}" != "11111" ]]; then
        echo "  [B040] ERROR: anchors found (want 1 each): Unit.h include ${a}, unit-flags line ${b}," \
             "Player.h include ${c}, GetNPCIfCanInteractWith ${d}, OnDestructPlayer ${e}"
        return 1
    fi

    cat > "${HEADER}" <<'EOF'
// B040-per-player-unselectable (issue 164): created by
// patches/B040-per-player-unselectable.sh, removed by its revert.
//
// Creatures one player cannot select. A rule per player, in memory:
// allExcept false - the listed creature entries are unselectable to them;
// allExcept true  - every creature but the listed entries is.
// A player's own pets and guardians are never covered. Setting or clearing
// re-sends the flags of the creatures within the player's sight.
#ifndef PER_PLAYER_CREATURES_H
#define PER_PLAYER_CREATURES_H

#include "Define.h"
#include <vector>

class Player;

namespace PerPlayerCreatures
{
    // selecting: which creatures the player can't click or target
    void Set(Player* player, std::vector<uint32> const& entries, bool allExcept);
    void Clear(Player* player);
    bool IsUnselectable(uint32 playerLowGuid, uint32 creatureEntry);

    // seeing: single creature spawns (by spawn number) the player can't see
    void SetHidden(Player* player, uint32 spawnId, bool hidden);
    bool IsHidden(uint32 playerLowGuid, uint32 spawnId);

    void Forget(uint32 playerLowGuid);                          // the player is gone: no re-send
}

#endif
EOF

    INC="${B040_UNIT_INCLUDE}" FLAGS="${B040_UNIT_FLAGS}" BEGIN_M="${B040_BEGIN}" END_M="${B040_END}" awk '
        { print }
        $0 == ENVIRON["INC"] && !inc {
            print ENVIRON["BEGIN_M"]
            print "#include \"PerPlayerCreatures.h\""
            print "#include <shared_mutex>"
            print "#include <unordered_map>"
            print "#include <unordered_set>"
            print ENVIRON["END_M"]
            inc = 1
        }
        $0 == ENVIRON["FLAGS"] {
            print "        " ENVIRON["BEGIN_M"]
            print "        // Everland Ghostsong (issue 164): not selectable to this viewer by its rule;"
            print "        // a player'"'"'s own pets and guardians never are. Before the GM line: GM mode wins."
            print "        if (creature && !creature->GetOwnerGUID().IsPlayer() &&"
            print "            PerPlayerCreatures::IsUnselectable(target->GetGUID().GetCounter(), creature->GetEntry()))"
            print "            appendValue |= UNIT_FLAG_NOT_SELECTABLE;"
            print "        " ENVIRON["END_M"]
        }
    ' "${UNIT}" > "${UNIT}.b040" && mv "${UNIT}.b040" "${UNIT}"

    cat >> "${UNIT}" <<EOF
${B040_BEGIN}

// Everland Ghostsong (issue 164): creatures one player cannot select. The
// rules are read while building updates, on the map threads, and written
// by scripts, so a reader-writer lock guards them.
namespace PerPlayerCreatures
{
    struct Rule
    {
        bool selectRule = false;                            // a selection rule is set
        bool allExcept  = false;                            // true: every creature but \`entries\`
        std::unordered_set<uint32> entries;
        std::unordered_set<uint32> hiddenSpawns;            // spawn numbers this player can't see
    };

    static std::shared_mutex sRulesLock;
    static std::unordered_map<uint32, Rule> sRules;         // player low guid -> rule

    // Marks the unit flags of every creature within the player's sight as
    // changed, so the next update re-sends them (patched per viewer).
    static void Refresh(Player* player)
    {
        if (!player->IsInWorld())
            return;
        std::list<Creature*> near;
        Acore::AllWorldObjectsInRange check(player, player->GetVisibilityRange());
        Acore::CreatureListSearcher<Acore::AllWorldObjectsInRange> searcher(player, near, check);
        Cell::VisitObjects(player, searcher, player->GetVisibilityRange());
        for (Creature* c : near)
            c->ForceValuesUpdateAtIndex(UNIT_FIELD_FLAGS);
    }

    void Set(Player* player, std::vector<uint32> const& entries, bool allExcept)
    {
        {
            std::unique_lock<std::shared_mutex> lock(sRulesLock);
            Rule& rule = sRules[player->GetGUID().GetCounter()];
            rule.selectRule = true;
            rule.allExcept  = allExcept;
            rule.entries    = std::unordered_set<uint32>(entries.begin(), entries.end());
        }
        Refresh(player);
    }

    void Clear(Player* player)
    {
        {
            std::unique_lock<std::shared_mutex> lock(sRulesLock);
            auto it = sRules.find(player->GetGUID().GetCounter());
            if (it != sRules.end())
            {
                it->second.selectRule = false;
                it->second.entries.clear();
                if (it->second.hiddenSpawns.empty())
                    sRules.erase(it);                       // nothing left for this player
            }
        }
        Refresh(player);
    }

    // Hides or shows one creature spawn to this player alone. The server
    // re-decides that creature's visibility for them at once, so it goes
    // (or comes back) without the player moving away.
    void SetHidden(Player* player, uint32 spawnId, bool hidden)
    {
        {
            std::unique_lock<std::shared_mutex> lock(sRulesLock);
            uint32 guid = player->GetGUID().GetCounter();
            if (hidden)
                sRules[guid].hiddenSpawns.insert(spawnId);
            else
            {
                auto it = sRules.find(guid);
                if (it != sRules.end())
                {
                    it->second.hiddenSpawns.erase(spawnId);
                    if (!it->second.selectRule && it->second.hiddenSpawns.empty())
                        sRules.erase(it);
                }
            }
        }
        if (!player->IsInWorld())
            return;
        std::list<Creature*> near;
        Acore::AllWorldObjectsInRange check(player, player->GetVisibilityRange());
        Acore::CreatureListSearcher<Acore::AllWorldObjectsInRange> searcher(player, near, check);
        Cell::VisitObjects(player, searcher, player->GetVisibilityRange());
        for (Creature* c : near)
            if (c->GetSpawnId() == spawnId)
                player->UpdateVisibilityOf(c);
    }

    bool IsHidden(uint32 playerLowGuid, uint32 spawnId)
    {
        std::shared_lock<std::shared_mutex> lock(sRulesLock);
        auto it = sRules.find(playerLowGuid);
        return it != sRules.end() && it->second.hiddenSpawns.count(spawnId) != 0;
    }

    void Forget(uint32 playerLowGuid)
    {
        std::unique_lock<std::shared_mutex> lock(sRulesLock);
        sRules.erase(playerLowGuid);
    }

    bool IsUnselectable(uint32 playerLowGuid, uint32 creatureEntry)
    {
        std::shared_lock<std::shared_mutex> lock(sRulesLock);
        auto it = sRules.find(playerLowGuid);
        if (it == sRules.end())
            return false;                                   // no rule: everything as it is
        if (!it->second.selectRule)
            return false;                                   // only hidden spawns: selecting as it is
        bool listed = it->second.entries.count(creatureEntry) != 0;
        return it->second.allExcept ? !listed : listed;
    }
}
${B040_END}
EOF

    INC="${B040_PLAYER_INCLUDE}" FN="${B040_PLAYER_FN}" DTOR="${B040_PLAYER_DTOR}" BEGIN_M="${B040_BEGIN}" END_M="${B040_END}" awk '
        { print }
        $0 == ENVIRON["INC"] && !inc {
            print ENVIRON["BEGIN_M"]
            print "#include \"PerPlayerCreatures.h\""
            print ENVIRON["END_M"]
            inc = 1
        }
        $0 == ENVIRON["DTOR"] {
            print "    " ENVIRON["BEGIN_M"]
            print "    PerPlayerCreatures::Forget(GetGUID().GetCounter());   // issue 164"
            print "    " ENVIRON["END_M"]
        }
        $0 == ENVIRON["FN"] { infn = 1 }
        infn && $0 == "    if (!creature)" { sawcheck = 1; next }
        sawcheck && $0 == "        return nullptr;" {
            print "    " ENVIRON["BEGIN_M"]
            print "    // Everland Ghostsong (issue 164): a creature this player cannot select is"
            print "    // one they cannot talk to, trade with or take quests from, whatever the"
            print "    // client asks. GM mode wins, as it does for selecting."
            print "    if (!IsGameMaster() && !creature->GetOwnerGUID().IsPlayer() &&"
            print "        PerPlayerCreatures::IsUnselectable(GetGUID().GetCounter(), creature->GetEntry()))"
            print "        return nullptr;"
            print "    " ENVIRON["END_M"]
            sawcheck = 0; infn = 0
        }
        { sawcheck = (sawcheck && $0 == "    if (!creature)") }
    ' "${PLAYER}" > "${PLAYER}.b040" && mv "${PLAYER}.b040" "${PLAYER}"

    # Object.cpp: the seeing half. Every "can this one see that one?" goes
    # through CanSeeOrDetect; right after its "can never see" test, a
    # creature spawn hidden from this player is not seen. GM mode still
    # sees it. Anchors checked here, at the file they belong to.
    local OBJECT="${AC_CODE_DIR}/src/server/game/Entities/Object/Object.cpp"
    local f g
    f=$(grep -cxF -- '#include "Object.h"' "${OBJECT}")
    g=$(grep -cxF -- '    if (CanNeverSee(obj))' "${OBJECT}")
    if [[ "${f}${g}" != "11" ]]; then
        echo "  [B040] ERROR: Object.cpp anchors found (want 1 each): Object.h include ${f}, CanNeverSee test ${g}"
        return 1
    fi
    BEGIN_M="${B040_BEGIN}" END_M="${B040_END}" awk '
        { print }
        $0 == "#include \"Object.h\"" && !inc {
            print ENVIRON["BEGIN_M"]
            print "#include \"PerPlayerCreatures.h\""
            print ENVIRON["END_M"]
            inc = 1
        }
        $0 == "    if (CanNeverSee(obj))" { sawtest = 1; next }
        sawtest && $0 == "        return false;" {
            print "    " ENVIRON["BEGIN_M"]
            print "    // Everland Ghostsong (issue 164): a creature spawn hidden from this player"
            print "    // alone is not seen by them; GM mode still sees it."
            print "    if (Player const* viewer = ToPlayer())"
            print "        if (Creature const* hidden = obj->ToCreature())"
            print "            if (hidden->GetSpawnId() && !viewer->IsGameMaster() &&"
            print "                PerPlayerCreatures::IsHidden(viewer->GetGUID().GetCounter(), hidden->GetSpawnId()))"
            print "                return false;"
            print "    " ENVIRON["END_M"]
        }
        { sawtest = 0 }
    ' "${OBJECT}" > "${OBJECT}.b040" && mv "${OBJECT}.b040" "${OBJECT}"

    echo "  [B040] Creatures one player cannot select or see (PerPlayerCreatures)"
}
# }}}

# {{{ unpatch_B040_per_player_unselectable
unpatch_B040_per_player_unselectable() {
    local DIR_UNIT="${AC_CODE_DIR}/src/server/game/Entities/Unit"
    local f
    rm -f "${DIR_UNIT}/PerPlayerCreatures.h"
    for f in "${DIR_UNIT}/Unit.cpp" "${AC_CODE_DIR}/src/server/game/Entities/Player/Player.cpp" "${AC_CODE_DIR}/src/server/game/Entities/Object/Object.cpp"; do
        [[ -f "${f}" ]] || continue
        grep -qF "B040-per-player-unselectable" "${f}" || continue    # nothing of ours
        awk '
            /\/\/ >>> B040-per-player-unselectable BEGIN/ { inblock = 1; next }
            inblock && /\/\/ <<< B040-per-player-unselectable END/ { inblock = 0; next }
            inblock { next }
            { print }' "${f}" > "${f}.b040" && mv "${f}.b040" "${f}"
    done
    return 0
}
# }}}
