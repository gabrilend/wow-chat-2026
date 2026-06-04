#!/usr/bin/env bash
# C015 - Disable Death Knight (Vanilla)
# Set CharacterCreating.Disabled.ClassMask to 32 (bit 5 = Death Knight) so
# DK characters cannot be created on vanilla. AzerothCore ships with this
# bitmask knob as a built-in feature — no SQL migration needed.
#
# The vanilla profile caps player level at 40, but DK characters start at
# level 55 inside the scripted Acherus zone. Properly skipping that intro
# requires a client patch the project doesn't yet have, so for v1 the
# class is turned off entirely. Re-enabling depends on the client-patching
# pipeline landing (see issue 148a for the full rationale and the
# eventual re-enable plan).
#
# The mask is documented at
# source-beta/src/server/apps/worldserver/worldserver.conf.dist:1950-1965
# with bit values per class (Warrior=1, Paladin=2, Hunter=4, Rogue=8,
# Priest=16, Death Knight=32, Shaman=64, Mage=128, Warlock=256,
# Druid=1024). Combine bits to disable multiple classes.
#
# Profiles: vanilla

# -- {{{ config_vanilla_disable_deathknight
config_vanilla_disable_deathknight() {
    local CLASS_MASK=32
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^CharacterCreating\.Disabled\.ClassMask.*=.*|CharacterCreating.Disabled.ClassMask = '"${CLASS_MASK}"'|' "${conf}"
}
CONFIG_PROFILES[config_vanilla_disable_deathknight]="vanilla"
CONFIG_DESCRIPTIONS[config_vanilla_disable_deathknight]="Disable Death Knight creation (ClassMask 32)"
# -- }}}
