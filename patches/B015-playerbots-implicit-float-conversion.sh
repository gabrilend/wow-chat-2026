#!/usr/bin/env bash
# B015-playerbots-implicit-float-conversion.sh
# Fixes implicit int-to-float conversion warnings
#
# Warning: implicit conversion from 'int' to 'float' changes value from 2147483647 to 2147483648
#
# RAND_MAX (INT_MAX = 2147483647) loses precision when implicitly converted to float.
# Fix: Cast RAND_MAX to float explicitly.
#
# Affected: RaidMagtheridonActions.cpp:436,469,470,578

# {{{ patch_B015_playerbots_implicit_float_conversion
patch_B015_playerbots_implicit_float_conversion() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Raid/Magtheridon/Action/RaidMagtheridonActions.cpp"

    [[ -f "${FILE}" ]] || return 0

    # Check if already patched
    if grep -q "static_cast<float>(RAND_MAX)" "${FILE}" 2>/dev/null; then
        return 0
    fi

    # Replace / RAND_MAX with / static_cast<float>(RAND_MAX)
    sed -i 's|/ RAND_MAX|/ static_cast<float>(RAND_MAX)|g' "${FILE}"
}
# }}}

# {{{ unpatch_B015_playerbots_implicit_float_conversion
unpatch_B015_playerbots_implicit_float_conversion() {
    local FILE="${AC_CODE_DIR}/modules/mod-playerbots/src/Ai/Raid/Magtheridon/Action/RaidMagtheridonActions.cpp"

    [[ -f "${FILE}" ]] || return 0

    # Reverse: remove the static_cast
    sed -i 's|/ static_cast<float>(RAND_MAX)|/ RAND_MAX|g' "${FILE}"
}
# }}}
