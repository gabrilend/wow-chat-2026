#!/usr/bin/env bash
# C011 - Realmlist Setup
# Configure realm entry in database (address, port, flags)
# Profiles: all

# -- {{{ config_realmlist_setup
config_realmlist_setup() {
    local MYSQL_DIR="${DIR}/mysql/installed-files"
    local MYSQL_SOCKET="${DIR}/mysql/databases/mysql.sock"

    # The socket file alone is not a sufficient liveness check — a stale
    # socket from a previous shutdown will still pass `-S`. Probe with a
    # real connection (ping with a short timeout). Three distinct outcomes:
    #   - no socket at all: MySQL never started; skip with note
    #   - socket present but ping fails: stale socket; skip with note
    #   - ping succeeds: proceed
    if [[ ! -S "${MYSQL_SOCKET}" ]]; then
        echo "      (MySQL socket missing, skipping)"
        return 0
    fi

    if ! "${MYSQL_DIR}/bin/mysqladmin" --no-defaults \
            --socket="${MYSQL_SOCKET}" --connect-timeout=2 \
            -u ritz -pmenardi ping >/dev/null 2>&1; then
        echo "      (MySQL not actually running — stale socket — skipping)"
        return 0
    fi

    # Realm configuration
    local REALM_NAME="Everland Ghostsong"
    local REALM_ADDRESS="wow.ritzmenardi.com"
    local REALM_LOCAL="127.0.0.1"
    local REALM_PORT=4462
    local REALM_FLAG=0  # 0=normal, 1=invalid, 2=offline

    # Capture mysql errors so a real SQL failure (missing table, bad
    # credentials, etc.) surfaces to the operator instead of a bare
    # exit code. Empty stderr on success.
    local MYSQL_ERR
    MYSQL_ERR=$("${MYSQL_DIR}/bin/mysql" --no-defaults \
        --socket="${MYSQL_SOCKET}" -u ritz -pmenardi acore_auth 2>&1 <<EOF
UPDATE realmlist SET
    name = '${REALM_NAME}',
    address = '${REALM_ADDRESS}',
    localAddress = '${REALM_LOCAL}',
    port = ${REALM_PORT},
    flag = ${REALM_FLAG}
WHERE id = 1;
EOF
)
    local MYSQL_RC=$?

    # Drop the routine "password on command line" notice from output.
    MYSQL_ERR=$(echo "${MYSQL_ERR}" | grep -v "Using a password on the command line" || true)

    if [[ ${MYSQL_RC} -ne 0 ]]; then
        echo "      (realmlist UPDATE failed: ${MYSQL_ERR:-unknown error})"
        return 1
    fi

    if [[ -n "${MYSQL_ERR}" ]]; then
        echo "      (realmlist UPDATE warning: ${MYSQL_ERR})"
    fi
}
CONFIG_PROFILES[config_realmlist_setup]="all"
CONFIG_DESCRIPTIONS[config_realmlist_setup]="Realmlist (name, address, port)"
# -- }}}
