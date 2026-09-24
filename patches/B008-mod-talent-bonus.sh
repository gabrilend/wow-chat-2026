#!/usr/bin/env bash
# B008 - Link mod-talent-bonus module to source for compilation
# Issue 120: Talent points system (bonus talent validation)
# Parallelizable: Yes (unique operation)

# {{{ patch_B008_mod_talent_bonus
patch_B008_mod_talent_bonus() {
    local MODULE_SRC="${DIR}/modules/mod-talent-bonus"
    local MODULE_DST="${AC_CODE_DIR}/modules/mod-talent-bonus"

    # The module must exist. This used to "return 0  # Module not available
    # locally", so every beta build silently compiled without the talent
    # bonus (issue 120) while the patch list said B008 was applied. Owner's
    # rule: fail loudly instead (2026-09-23).
    if [[ ! -d "${MODULE_SRC}" ]]; then
        echo "  [B008] ERROR: module folder missing: ${MODULE_SRC}"
        echo "         the talent-bonus module (issue 120) is not in the project, so it"
        echo "         cannot be linked into ${AC_CODE_DIR}/modules/."
        echo "         to debug: was modules/mod-talent-bonus ever committed (git log --all -- modules/)?"
        echo "         or take B008 out of beta's list in patches/patches.sh if the module is retired."
        return 1
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
