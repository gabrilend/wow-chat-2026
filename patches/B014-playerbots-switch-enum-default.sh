#!/usr/bin/env bash
# B014-playerbots-switch-enum-default.sh
# Fixes switch enum warnings by adding default case
#
# Warning: case value not in enumerated type 'WSBotStrategy' [-Wswitch]
#
# The WSBotStrategy enum only has values 0-3, but the switch uses cases 0-9.
# This appears to be dead code or enum mismatch. Adding default: silences
# the warning without changing runtime behavior (unreachable cases remain so).
#
# Affected: BattleGroundTactics.cpp:2188-2195

# {{{ patch_B014_playerbots_switch_enum_default
patch_B014_playerbots_switch_enum_default() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/BattleGroundTactics.cpp"

    [[ -f "${FILE}" ]] || return 0

    # Check if already patched (default case exists after case 9)
    if grep -q "case 9:.*default:" "${FILE}" 2>/dev/null; then
        return 0
    fi

    # Add default: after case 9: Heavy Defense block
    # Pattern: "case 9:  // Heavy Defense" ... "break;" -> add "default: break;" after
    sed -i '/case 9:.*Heavy Defense/,/break;/ {
        /break;/ {
            a\                default:
            a\                    break;
        }
    }' "${FILE}"

    # --- 2026-05-19: Upstream introduced many more switches over enum
    # types in this file (Battleground types, motion generator types, AV
    # and EY strategies, and the same WS strategy switch shifted lines).
    # Adding a `default:` to every one of them would require fragile
    # multi-line sed inserts inside nested braces — too many drift
    # surfaces. The lower-cost workaround is to cast the switch
    # discriminant to int. Once the discriminant is no longer the
    # enum's own type, `-Wswitch` stops checking enum-coverage and stops
    # complaining about case values outside the enum. Runtime behavior
    # is unchanged — every case label still compares as an integer
    # against the same integer value.

    # bgType switches (6 instances, all `switch (bgType)`)
    if ! grep -q "switch (static_cast<int>(bgType))" "${FILE}" 2>/dev/null; then
        sed -i 's#switch (bgType)#switch (static_cast<int>(bgType))#g' "${FILE}" 2>/dev/null || true
    fi
    # GetBgTypeID() switch (line 4330)
    if ! grep -q "switch (static_cast<int>(bg->GetBgTypeID()))" "${FILE}" 2>/dev/null; then
        sed -i 's#switch (bg->GetBgTypeID())#switch (static_cast<int>(bg->GetBgTypeID()))#g' "${FILE}" 2>/dev/null || true
    fi
    # MotionGeneratorType switch (line 1661)
    if ! grep -q "switch (static_cast<int>(bot->GetMotionMaster" "${FILE}" 2>/dev/null; then
        sed -i 's#switch (bot->GetMotionMaster()->GetCurrentMovementGeneratorType())#switch (static_cast<int>(bot->GetMotionMaster()->GetCurrentMovementGeneratorType()))#g' "${FILE}" 2>/dev/null || true
    fi
    # Strategy switches (AV/WS/EY all use `switch (strategy)`)
    if ! grep -q "switch (static_cast<int>(strategy))" "${FILE}" 2>/dev/null; then
        sed -i 's#switch (strategy)#switch (static_cast<int>(strategy))#g' "${FILE}" 2>/dev/null || true
    fi
}
# }}}

# {{{ unpatch_B014_playerbots_switch_enum_default
unpatch_B014_playerbots_switch_enum_default() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Base/Actions/BattleGroundTactics.cpp"

    [[ -f "${FILE}" ]] || return 0

    # Remove the added default: case
    sed -i '/^[[:space:]]*default:$/,/^[[:space:]]*break;$/ {
        /default:/d
        /break;/d
    }' "${FILE}"
}
# }}}
