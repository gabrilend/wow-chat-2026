#!/usr/bin/env bash
# E004-log-directory-setup.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E004_log_directory_setup
# Create RAM-backed log directory symlink
# Parallelizable: Yes (unique target)
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
# -- }}}
