#!/usr/bin/env bash

config_missing_server_config_keys() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"

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
            sed -i "s|^${key}[[:space:]]*=.*|${key} = ${val}|" "${conf}"
        else
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
CONFIG_DESCRIPTIONS[config_missing_server_config_keys]="Backfill 5 server-config keys missing from stale .dist"
