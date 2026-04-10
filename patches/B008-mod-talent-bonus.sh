#!/usr/bin/env bash
# B008 - Link mod-talent-bonus module to source for compilation
# Issue 120: Talent points system (bonus talent validation)
# Parallelizable: Yes (unique operation)

# {{{ patch_B008_mod_talent_bonus
patch_B008_mod_talent_bonus() {
    local MODULE_SRC="${DIR}/modules/mod-talent-bonus"
    local MODULE_DST="${AC_CODE_DIR}/modules/mod-talent-bonus"

    # Check if local module exists
    if [[ ! -d "${MODULE_SRC}" ]]; then
        return 0  # Module not available locally
    fi

    # Check if already linked/copied
    if [[ -d "${MODULE_DST}" ]]; then
        return 0  # Already present
    fi

    echo "  [B008] mod-talent-bonus: Linking module"

    # Create symlink to local module
    ln -sf "${MODULE_SRC}" "${MODULE_DST}"
}
# }}}

# {{{ unpatch_B008_mod_talent_bonus
unpatch_B008_mod_talent_bonus() {
    local MODULE_DST="${AC_CODE_DIR}/modules/mod-talent-bonus"

    # Remove symlink (but not a real directory)
    if [[ -L "${MODULE_DST}" ]]; then
        rm -f "${MODULE_DST}"
    fi
}
# }}}
