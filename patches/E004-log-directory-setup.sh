#!/usr/bin/env bash

patch_E004_log_directory_setup() {
    local TMP_BASE="/tmp/wow-chat-2"
    local TMP_LOGS="${TMP_BASE}/logs-${PROFILE}"
    mkdir -p "${TMP_BASE}"
    mkdir -p "${TMP_LOGS}"
    [[ -L "${DIR}/tmp" ]] || ln -s "${TMP_BASE}" "${DIR}/tmp"
    [[ -L "${DIR}/logs-${PROFILE}" ]] || ln -s "${TMP_LOGS}" "${DIR}/logs-${PROFILE}"
    echo "  [E004] Log directory setup"
}

unpatch_E004_log_directory_setup() {
    [[ -L "${DIR}/tmp" ]] && rm "${DIR}/tmp"
    [[ -L "${DIR}/logs-${PROFILE}" ]] && rm "${DIR}/logs-${PROFILE}"
    echo "  [E004] Removed log directory symlinks"
}
