#!/usr/bin/env bash
# C011 - Realmlist Setup
# Configure realm entry in database (address, port, flags)
# Profiles: all

# -- {{{ config_realmlist_setup
config_realmlist_setup() {
    local MYSQL_DIR="${DIR}/mysql/installed-files"
    local MYSQL_SOCKET="${DIR}/mysql/databases/mysql.sock"

    # Credentials live in ${DIR}/secrets.conf — same source as
    # scripts/mysql-client. Hard-coding them here means they go stale
    # the moment the operator rotates them; sourcing keeps the single
    # source of truth.
    local SECRETS_FILE="${DIR}/secrets.conf"
    if [[ -f "${SECRETS_FILE}" ]]; then
        # shellcheck disable=SC1090
        source "${SECRETS_FILE}"
    fi
    local USER="${DB_USER:-root}"
    local PASS="${DB_PASS:-}"

    # Helper: does a real ping succeed within 2 seconds?
    _mysql_alive() {
        "${MYSQL_DIR}/bin/mysqladmin" --no-defaults \
            --socket="${MYSQL_SOCKET}" --connect-timeout=2 \
            -u "${USER}" -p"${PASS}" ping >/dev/null 2>&1
    }

    # The socket file alone is not a sufficient liveness check — a stale
    # socket from a previous shutdown still passes `-S`. Ping first; if
    # MySQL isn't up, try to bring it up via scripts/start-mysql so the
    # patch can complete on the same install pass.
    if ! _mysql_alive; then
        echo "      (MySQL not responding — attempting start-mysql)"
        if [[ -x "${DIR}/scripts/start-mysql" ]]; then
            "${DIR}/scripts/start-mysql" "${DIR}" >/dev/null 2>&1 || true
        else
            echo "      (start-mysql not found at ${DIR}/scripts/start-mysql — skipping)"
            return 0
        fi

        # Give the daemon a moment to settle then re-ping. start-mysql
        # already waits up to 10s for the PID file, but the listening
        # socket is created slightly later, so a brief retry is safer.
        local attempt
        for attempt in 1 2 3 4 5; do
            _mysql_alive && break
            sleep 1
        done

        if ! _mysql_alive; then
            echo "      (MySQL still not responding after start-mysql — skipping)"
            return 0
        fi
        echo "      (MySQL started successfully)"
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
        --socket="${MYSQL_SOCKET}" -u "${USER}" -p"${PASS}" acore_auth 2>&1 <<EOF
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
