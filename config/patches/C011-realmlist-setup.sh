#!/usr/bin/env bash

config_realmlist_setup() {
    local MYSQL_DIR="${DIR}/mysql/installed-files"
    local MYSQL_SOCKET="${DIR}/mysql/databases/mysql.sock"

    local USER="ritz"
    local PASS="menardi"

    _mysql_alive() {
        "${MYSQL_DIR}/bin/mysqladmin" --no-defaults \
            --socket="${MYSQL_SOCKET}" --connect-timeout=2 \
            -u "${USER}" -p"${PASS}" ping >/dev/null 2>&1
    }

    if ! _mysql_alive; then
        echo "      (MySQL not responding — attempting start-mysql)"
        if [[ -x "${DIR}/scripts/start-mysql" ]]; then
            "${DIR}/scripts/start-mysql" "${DIR}" >/dev/null 2>&1 || true
        else
            echo "      (start-mysql not found at ${DIR}/scripts/start-mysql — skipping)"
            return 0
        fi

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

    local REALM_ADDRESS="wow.ritzmenardi.com"
    local REALM_LOCAL="127.0.0.1"
    local REALM_PORT=4462

    local MYSQL_ERR
    MYSQL_ERR=$("${MYSQL_DIR}/bin/mysql" --no-defaults \
        --socket="${MYSQL_SOCKET}" -u "${USER}" -p"${PASS}" acore_auth 2>&1 <<EOF
-- Every profile's realm lives on this one host, so all rows advertise the
-- same public address; localAddress stays loopback for same-machine clients.
-- The old 'WHERE id = 1' left the beta/vanilla/alpha rows on 127.0.0.1, so a
-- remote player could reach auth but was handed 127.0.0.1 for the world server
-- and could not enter. Names and the online flag are managed elsewhere (the
-- set-active-realm seed + flip). Every realm is named after its profile
-- there; this patch used to rename id=1 "Everland Ghostsong" each install.
UPDATE realmlist SET
    address = '${REALM_ADDRESS}',
    localAddress = '${REALM_LOCAL}',
    port = ${REALM_PORT};
EOF
)
    local MYSQL_RC=$?

    MYSQL_ERR=$(echo "${MYSQL_ERR}" | grep -v "Using a password on the command line" || true)

    if [[ ${MYSQL_RC} -ne 0 ]]; then
        echo "      (realmlist UPDATE failed: ${MYSQL_ERR:-unknown error})"
        return 1
    fi

    if [[ -n "${MYSQL_ERR}" ]]; then
        echo "      (realmlist UPDATE warning: ${MYSQL_ERR})"
    fi
}
CONFIG_DESCRIPTIONS[config_realmlist_setup]="Realmlist (name, address, port)"
