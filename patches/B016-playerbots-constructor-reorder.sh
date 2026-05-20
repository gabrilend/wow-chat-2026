#!/usr/bin/env bash
# B016-playerbots-constructor-reorder.sh
# Fixes constructor initializer list order warnings
#
# Warning: field 'X' will be initialized after field 'Y' [-Wreorder-ctor]
#
# C++ initializes members in declaration order, not initializer list order.
# Fix: Reorder initializer lists to match class declaration order.
#
# Affected files:
#   - GenericSpellActions.cpp:27,239
#   - Arrow.h:106
#   - LastMovementValue.cpp:20
#   - PartyMemberToDispel.cpp:13
#   - PartyMemberWithoutAuraValue.cpp:16
#   - PartyMemberWithoutItemValue.cpp:14

# {{{ patch_B016_playerbots_constructor_reorder
patch_B016_playerbots_constructor_reorder() {
    local PLAYERBOTS_DIR="${AC_CODE_DIR}/modules/mod-playerbots/src"

    [[ -d "${PLAYERBOTS_DIR}" ]] || return 0

    # GenericSpellActions.cpp:27 - range, spell -> spell, range
    local FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/GenericSpellActions.cpp"
    if [[ -f "${FILE}" ]] && grep -q 'range(botAI->GetRange("spell")), spell(spell)' "${FILE}" 2>/dev/null; then
        sed -i 's/range(botAI->GetRange("spell")), spell(spell)/spell(spell), range(botAI->GetRange("spell"))/' "${FILE}"
    fi

    # GenericSpellActions.cpp:239 - estAmount, manaEfficiency -> manaEfficiency, estAmount
    # Check the actual line pattern first
    if [[ -f "${FILE}" ]] && grep -q "estAmount.*manaEfficiency" "${FILE}" 2>/dev/null; then
        sed -i 's/estAmount(estAmount), manaEfficiency(manaEfficiency)/manaEfficiency(manaEfficiency), estAmount(estAmount)/' "${FILE}" 2>/dev/null || true
    fi

    # Arrow.h:106 - masterUnit, built, botUnit -> masterUnit, botUnit, built (match declaration order)
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/Arrow.h"
    if [[ -f "${FILE}" ]] && grep -q "masterUnit(nullptr), built(false), botUnit(nullptr)" "${FILE}" 2>/dev/null; then
        sed -i 's/masterUnit(nullptr), built(false), botUnit(nullptr)/masterUnit(nullptr), botUnit(nullptr), built(false)/' "${FILE}"
    fi

    # LastMovementValue.cpp:20 - lastMoveToOri, lastFlee -> lastFlee, lastMoveToOri
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/LastMovementValue.cpp"
    if [[ -f "${FILE}" ]] && grep -q "lastMoveToOri(0), lastFlee" "${FILE}" 2>/dev/null; then
        sed -i 's/lastMoveToOri(0), lastFlee(0)/lastFlee(0), lastMoveToOri(0)/' "${FILE}" 2>/dev/null || true
    fi

    # PartyMember*.cpp - base class order: FindPlayerPredicate, PlayerbotAIAware
    # These inherit from both and list them in wrong order in initializer.
    #
    # FIXED 2026-05-19: The sed pattern previously omitted the trailing "()"
    # of FindPlayerPredicate() so the substitution left those parens dangling
    # after PlayerbotAIAware(botAI), producing "PlayerbotAIAware(botAI)()"
    # which is a syntax error ("expected '{' or ','"). The corrected pattern
    # anchors on the trailing comma so the parens are captured and replaced
    # cleanly. Same change applied to the unpatch direction below.
    for f in PartyMemberToDispel PartyMemberWithoutAuraValue PartyMemberWithoutItemValue; do
        FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/${f}.cpp"
        if [[ -f "${FILE}" ]] && grep -q "PlayerbotAIAware(botAI), FindPlayerPredicate()," "${FILE}" 2>/dev/null; then
            sed -i 's/PlayerbotAIAware(botAI), FindPlayerPredicate(),/FindPlayerPredicate(), PlayerbotAIAware(botAI),/' "${FILE}" 2>/dev/null || true
        fi
    done
}
# }}}

# {{{ unpatch_B016_playerbots_constructor_reorder
unpatch_B016_playerbots_constructor_reorder() {
    local PLAYERBOTS_DIR="${AC_CODE_DIR}/modules/mod-playerbots/src"

    [[ -d "${PLAYERBOTS_DIR}" ]] || return 0

    # Reverse GenericSpellActions.cpp:27
    local FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/GenericSpellActions.cpp"
    [[ -f "${FILE}" ]] && sed -i 's/spell(spell), range(botAI->GetRange("spell"))/range(botAI->GetRange("spell")), spell(spell)/' "${FILE}"

    # Reverse GenericSpellActions.cpp:239
    [[ -f "${FILE}" ]] && sed -i 's/manaEfficiency(manaEfficiency), estAmount(estAmount)/estAmount(estAmount), manaEfficiency(manaEfficiency)/' "${FILE}" 2>/dev/null || true

    # Reverse Arrow.h:106
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/Arrow.h"
    [[ -f "${FILE}" ]] && sed -i 's/masterUnit(nullptr), botUnit(nullptr), built(false)/masterUnit(nullptr), built(false), botUnit(nullptr)/' "${FILE}" 2>/dev/null || true

    # Reverse LastMovementValue.cpp:20
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/LastMovementValue.cpp"
    [[ -f "${FILE}" ]] && sed -i 's/lastFlee(0), lastMoveToOri(0)/lastMoveToOri(0), lastFlee(0)/' "${FILE}" 2>/dev/null || true

    # Reverse PartyMember*.cpp — comma-anchored to capture the trailing parens
    # cleanly (see apply-direction comment for the bug this avoids).
    for f in PartyMemberToDispel PartyMemberWithoutAuraValue PartyMemberWithoutItemValue; do
        FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/${f}.cpp"
        if [[ -f "${FILE}" ]] && grep -q "FindPlayerPredicate(), PlayerbotAIAware(botAI)," "${FILE}" 2>/dev/null; then
            sed -i 's/FindPlayerPredicate(), PlayerbotAIAware(botAI),/PlayerbotAIAware(botAI), FindPlayerPredicate(),/' "${FILE}" 2>/dev/null || true
        fi
    done
}
# }}}
