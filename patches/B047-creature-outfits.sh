#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         B047
# profiles:   buddy-set
# priority:   570
# kind:       source
# about:      Creature outfits: a creature can look like a dressed player character
# ==== end of header ====
# B047 - Creature outfits: a creature can look like a dressed player character
# Issue 617f (basic, 2026-10-03).
#
# For a general audience: an NPC's whole look is normally one picture the
# game client already has, chosen by number, and no picture shows
# Sargobras as the owner chose him (a bald, bearded human in the Black
# Baron's cape, a black mageweave vest over an orange shirt, black tuxedo
# pants and dress shoes; owner, 2026-10-03). Adding one means patching the
# client, which waits for the custom client (owner, 2026-09-23). But the
# 3.3.5a client already knows how to draw a creature from parts: for the
# mage's Mirror Image, a creature marked "mirror image" makes the client
# ask the server what it looks like (race, sex, skin, face, hair, hair
# colour, beard, and each worn item's picture), and the client dresses it
# from the answer. The server answers only for a mage's copies, copying the
# caster. This patch gives the server a plain list, "these creatures wear
# these looks", which the buddy module fills
# (modules/mod-buddies/src/buddies_outfits.cpp), and answers from it first.
# The module marks those creatures as mirror images and gives them a
# player body.
#
# Mechanics, two files, each insertion inside ">>> B047 ... BEGIN" /
# "<<< B047 ... END" marker comments:
#   CreatureOutfits.h   created in Entities/Creature/ (removed on revert):
#                       the look's fields and the list (entry -> look).
#                       Header only, so nothing else of the core changes.
#   SpellHandler.cpp    in the mirror-image request, before the "is it a
#                       mage's copy" check: a listed creature is answered
#                       from its listed look.
# Anchors must occur exactly once or the patch stops with an error.
# Parallelizable: Yes

B047_BEGIN='// >>> B047-creature-outfits BEGIN'
B047_END='// <<< B047-creature-outfits END'
B047_INCLUDE='#include "DBCStores.h"'
B047_CLONE_CHECK='    if (!unit->HasCloneCasterAura())'

# {{{ patch_B047_creature_outfits
patch_B047_creature_outfits() {
    local HEADER="${AC_CODE_DIR}/src/server/game/Entities/Creature/CreatureOutfits.h"
    local HANDLER="${AC_CODE_DIR}/src/server/game/Handlers/SpellHandler.cpp"
    [[ -f "${HANDLER}" ]] || { echo "  [B047] ERROR: SpellHandler.cpp missing under ${AC_CODE_DIR}"; return 1; }
    grep -qF "B047-creature-outfits" "${HANDLER}" && return 0         # witness guard

    local a b
    a=$(grep -cxF -- "${B047_INCLUDE}" "${HANDLER}")
    b=$(grep -cxF -- "${B047_CLONE_CHECK}" "${HANDLER}")
    if [[ "${a}${b}" != "11" ]]; then
        echo "  [B047] ERROR: anchors found in SpellHandler.cpp (want 1 each): DBCStores.h include ${a}, clone-caster check ${b}"
        return 1
    fi

    cat > "${HEADER}" <<'EOF'
// B047-creature-outfits (issue 617f): created by
// patches/B047-creature-outfits.sh, removed by its revert.
//
// Creature outfits: a creature listed here, and marked as a mirror image
// (UNIT_FLAG2_MIRROR_IMAGE) with a player race's body, is drawn by the
// client as a dressed character of that race: the server answers the
// client's mirror-image question with the listed look instead of a mage's.
// Filled by whoever owns the creatures (mod-buddies); in memory only, so
// the owner refills it at every startup.
#ifndef CREATURE_OUTFITS_H
#define CREATURE_OUTFITS_H

#include "Define.h"
#include <array>
#include <mutex>
#include <unordered_map>

struct CreatureOutfit
{
    uint32 displayId  = 0;        // the race's body (a player model display)
    uint8  race       = 0;
    uint8  gender     = 0;        // 0 male, 1 female
    uint8  cls        = 1;        // class: no visible effect
    uint8  skin       = 0;
    uint8  face       = 0;
    uint8  hair       = 0;        // hair style
    uint8  hairColor  = 0;
    uint8  facialHair = 0;
    // item display ids (0 = nothing worn), in the order the client reads
    // them: head, shoulders, shirt, chest, waist, legs, feet, wrists,
    // hands, back, tabard
    std::array<uint32, 11> items = {};
};

namespace CreatureOutfits
{
    inline std::mutex& Lock() { static std::mutex m; return m; }
    inline std::unordered_map<uint32, CreatureOutfit>& List() { static std::unordered_map<uint32, CreatureOutfit> l; return l; }

    // list (or relist) a creature entry's look
    inline void Set(uint32 entry, CreatureOutfit const& outfit)
    {
        std::lock_guard<std::mutex> lock(Lock());
        List()[entry] = outfit;
    }

    // the listed look of a creature entry, if any
    inline bool Find(uint32 entry, CreatureOutfit& out)
    {
        std::lock_guard<std::mutex> lock(Lock());
        auto it = List().find(entry);
        if (it == List().end())
            return false;
        out = it->second;
        return true;
    }
}

#endif
EOF

    INC="${B047_INCLUDE}" CHECK="${B047_CLONE_CHECK}" BEGIN_M="${B047_BEGIN}" END_M="${B047_END}" awk '
        $0 == ENVIRON["CHECK"] {
            print "    " ENVIRON["BEGIN_M"]
            print "    // Everland Ghostsong (issue 617f): a creature with a listed outfit is"
            print "    // answered with it (a mage'"'"'s copies, never listed, go on as stock)."
            print "    {"
            print "        CreatureOutfit outfit;"
            print "        if (unit->IsCreature() && CreatureOutfits::Find(unit->GetEntry(), outfit))"
            print "        {"
            print "            WorldPacket look(SMSG_MIRRORIMAGE_DATA, 68);"
            print "            look << guid << uint32(outfit.displayId) << uint8(outfit.race) << uint8(outfit.gender) << uint8(outfit.cls);"
            print "            look << uint8(outfit.skin) << uint8(outfit.face) << uint8(outfit.hair) << uint8(outfit.hairColor) << uint8(outfit.facialHair);"
            print "            look << uint32(0);                                   // guild"
            print "            for (uint32 item : outfit.items)"
            print "                look << uint32(item);"
            print "            SendPacket(&look);"
            print "            return;"
            print "        }"
            print "    }"
            print "    " ENVIRON["END_M"]
        }
        { print }
        $0 == ENVIRON["INC"] && !inc {
            print ENVIRON["BEGIN_M"]
            print "#include \"CreatureOutfits.h\""
            print ENVIRON["END_M"]
            inc = 1
        }
    ' "${HANDLER}" > "${HANDLER}.b047" && mv "${HANDLER}.b047" "${HANDLER}"

    echo "  [B047] Creature outfits: listed creatures answer the client's mirror-image question with their own look (CreatureOutfits)"
}
# }}}

# {{{ unpatch_B047_creature_outfits
unpatch_B047_creature_outfits() {
    local HANDLER="${AC_CODE_DIR}/src/server/game/Handlers/SpellHandler.cpp"
    rm -f "${AC_CODE_DIR}/src/server/game/Entities/Creature/CreatureOutfits.h"
    [[ -f "${HANDLER}" ]] || return 0
    grep -qF "B047-creature-outfits" "${HANDLER}" || return 0           # nothing of ours
    awk '
        /\/\/ >>> B047-creature-outfits BEGIN/ { inblock = 1; next }
        inblock && /\/\/ <<< B047-creature-outfits END/ { inblock = 0; next }
        inblock { next }
        { print }' "${HANDLER}" > "${HANDLER}.b047" && mv "${HANDLER}.b047" "${HANDLER}"
    return 0
}
# }}}
# ==== footer of B047 ====
# lines:      172
# ==== end of footer ====
