#!/usr/bin/env bash

config_vanilla_custom_spells() {
    local KEY="PlayerStart.CustomSpells"
    local WANT=1
    local conf="${INSTALL_DIR}/etc/worldserver.conf"

    if [[ ! -f "${conf}" ]]; then
        echo "    [C022] ERROR: worldserver.conf not found"
        echo "           Looked for: ${conf}"
        echo "           INSTALL_DIR resolved to: ${INSTALL_DIR:-<unset>}"
        echo "           Did not complete: setting ${KEY} = ${WANT}"
        echo "           Completed before this: nothing — this is the first check"
        echo "           To debug: did init_config() run and copy the .dist"
        echo "           template? If INSTALL_DIR is empty the profile never"
        echo "           resolved, which would break every C-patch, not just"
        echo "           this one — check whether the others also failed."
        return 1
    fi

    local found
    found="$(grep -c "^${KEY}[[:space:]]*=" "${conf}")"
    if [[ "${found}" -eq 0 ]]; then
        echo "    [C022] ERROR: key '${KEY}' not present in worldserver.conf"
        echo "           File: ${conf}"
        echo "           Matching lines found: ${found} (expected 1)"
        echo "           Did not complete: setting ${KEY} = ${WANT}"
        echo "           Completed before this: file-presence check passed"
        echo "           Most likely cause: upstream renamed or removed the"
        echo "           key. Grep WorldConfig.cpp for CONFIG_START_CUSTOM_SPELLS"
        echo "           to see what it binds to now — if the name changed, this"
        echo "           patch needs re-targeting to the new key, and issue 148w"
        echo "           needs updating with it."
        echo "           Rarer cause: the .dist template was replaced by a"
        echo "           hand-trimmed config. If so, does it drop other keys the"
        echo "           C-patches expect, and did those fail quietly?"
        return 1
    fi

    sed -i 's|^'"${KEY}"'[[:space:]]*=.*|'"${KEY}"' = '"${WANT}"'|' "${conf}"

    local now
    now="$(grep -m1 "^${KEY}[[:space:]]*=" "${conf}" | sed 's|.*=[[:space:]]*||' | tr -d '[:space:]')"
    if [[ "${now}" != "${WANT}" ]]; then
        echo "    [C022] ERROR: ${KEY} did not take the intended value"
        echo "           File: ${conf}"
        echo "           Wanted: ${WANT}"
        echo "           Reads back as: '${now}'"
        echo "           Completed before this: file present, key found,"
        echo "           substitution ran"
        echo "           To debug: is there more than one line defining this"
        echo "           key? The substitution rewrites every match, and a"
        echo "           later duplicate would win when the server parses the"
        echo "           file. Run: grep -n '^${KEY}' '${conf}'"
        return 1
    fi

    return 0
}
CONFIG_PROFILES[config_vanilla_custom_spells]="vanilla"
CONFIG_DESCRIPTIONS[config_vanilla_custom_spells]="Enable custom starting spells (reads 148j pretrain table)"
