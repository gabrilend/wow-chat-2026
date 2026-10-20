#!/usr/bin/env bash

config_cc_test_warden_kicks() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    local WARDEN_FAIL_ACTION=0   # 0 log only, until the custom client answers Warden; then 1 (kick)

    if ! grep -qE '^Warden\.ClientCheckFailAction[[:space:]]*=' "${conf}"; then
        echo "    ERROR: C033 found no Warden.ClientCheckFailAction line in ${conf}; Warden left at log-only"
        echo "           to debug: grep -n '^Warden' ${conf} — did upstream rename the key,"
        echo "           or was worldserver.conf generated from an old .dist (C016's case)?"
        return 1
    fi
    sed -i 's|^Warden\.ClientCheckFailAction[[:space:]]*=.*|Warden.ClientCheckFailAction = '"${WARDEN_FAIL_ACTION}"'|' "${conf}"
}
CONFIG_PROFILES[config_cc_test_warden_kicks]="cc-test"
CONFIG_DESCRIPTIONS[config_cc_test_warden_kicks]="Warden failures logged (kicks once the custom client answers Warden)"
