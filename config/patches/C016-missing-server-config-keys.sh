#!/usr/bin/env bash
# C016 - Missing server config keys
# The installed worldserver.conf.dist snapshot is older than the binary
# expects: five keys the binary reads at boot are absent from .dist, so
# the worldserver prints "Missing property X" warnings on every start.
# Source-beta carries those keys at its current HEAD; this patch is a
# compatibility shim until the install pipeline refreshes the installed
# .dist from current source-beta.
#
# Strategy: if a key already exists (refreshed .dist case), sed-replace
# its value to the documented default. If it's missing (stale .dist
# case), append it under a clearly marked "C016 compatibility shim"
# block at the end of the file so a later audit can find and remove
# the block once the .dist is current.
#
# Values come from the missing-property warning itself, which prints
# the upstream-default-for-each-key the binary expects when the
# property is absent. They match the source-beta upstream defaults.
#
# Profiles: release beta vanilla
# Alpha is excluded: its older AzerothCore binary doesn't read these
# keys, so adding them would surface "unknown property" noise.

# -- {{{ config_missing_server_config_keys
config_missing_server_config_keys() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"

    # Ordered list so the append order is deterministic across runs.
    # Each entry is "Key=Default" with the default matching upstream.
    local entries=(
        "DurabilityLoss.OnSpiritResurrect=25"
        "LFG.MailItemOnFullInventory=0"
        "Respawn.DynamicEscortNPC=0"
        "Respawn.ForceCompatibilityMode=0"
        "ChatLog.Enable=0"
    )

    local appended_header=false
    local entry key val
    for entry in "${entries[@]}"; do
        key="${entry%%=*}"
        val="${entry#*=}"

        if grep -qE "^${key}[[:space:]]*=" "${conf}"; then
            # Key already present (refreshed .dist) — replace with the
            # documented default so other patches' assumptions hold.
            sed -i "s|^${key}[[:space:]]*=.*|${key} = ${val}|" "${conf}"
        else
            # Key missing (stale .dist) — append once under a marker
            # header so the additions are easy to spot and remove.
            if [[ "${appended_header}" == false ]]; then
                cat >> "${conf}" <<'EOF'

# === C016: compatibility shim — keys missing from this .dist ===
# The installed worldserver.conf.dist is older than the binary; the
# keys below are appended by config/patches/C016-missing-server-config-keys.sh
# so the worldserver finds them at boot. Once the .dist is refreshed
# from current source-beta this block stops growing and can be removed.
EOF
                appended_header=true
            fi
            echo "${key} = ${val}" >> "${conf}"
        fi
    done
}
CONFIG_PROFILES[config_missing_server_config_keys]="release beta vanilla"
CONFIG_DESCRIPTIONS[config_missing_server_config_keys]="Backfill 5 server-config keys missing from stale .dist"
# -- }}}
