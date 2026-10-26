#!/usr/bin/env bash

config_directory_paths() {
    local conf_auth="${INSTALL_DIR}/etc/authserver.conf"
    local conf_world="${INSTALL_DIR}/etc/worldserver.conf"

    local PROJECT_DIR="${DIR:-/mnt/kaun/wow-chat-2026}"

    local LOGS_DIR="${PROJECT_DIR}/logs-${PROFILE}"
    local BUILD_DIR="${PROJECT_DIR}/build-${PROFILE}"
    local MYSQL_DIR="${PROJECT_DIR}/mysql/installed-files"

    local AC_CODE_DIR
    case "${PROFILE}" in
        release) AC_CODE_DIR="${PROJECT_DIR}/source-beta"  ;;
        beta)    AC_CODE_DIR="${PROJECT_DIR}/source-beta"  ;;
        vanilla) AC_CODE_DIR="${PROJECT_DIR}/source-beta"  ;;
        basic)   AC_CODE_DIR="${PROJECT_DIR}/source-beta"  ;;
        cc-test) AC_CODE_DIR="${PROJECT_DIR}/source-beta"  ;;
        alpha)   AC_CODE_DIR="${PROJECT_DIR}/source-alpha" ;;
        *)       echo "ERROR: Unknown profile '${PROFILE}' in config_directory_paths"; return 1 ;;
    esac

    sed -i 's|^DataDir.*=.*|DataDir = "'"${PROJECT_DIR}"'/data-files"|' "${conf_world}"
    sed -i 's|^LogsDir.*=.*|LogsDir = "'"${LOGS_DIR}"'"|' "${conf_world}"
    sed -i 's|^LogsDir.*=.*|LogsDir = "'"${LOGS_DIR}"'"|' "${conf_auth}"

    sed -i 's|^SourceDirectory.*=.*|SourceDirectory = "'"${AC_CODE_DIR}"'"|' "${conf_auth}"
    sed -i 's|^SourceDirectory.*=.*|SourceDirectory = "'"${AC_CODE_DIR}"'"|' "${conf_world}"
    sed -i 's|^BuildDirectory.*=.*|BuildDirectory = "'"${BUILD_DIR}"'"|' "${conf_world}"

    sed -i 's|^MySQLExecutable.*=.*|MySQLExecutable = "'"${MYSQL_DIR}"'/bin/mysql"|' "${conf_auth}"
    sed -i 's|^MySQLExecutable.*=.*|MySQLExecutable = "'"${MYSQL_DIR}"'/bin/mysql"|' "${conf_world}"
}
CONFIG_DESCRIPTIONS[config_directory_paths]="Directory paths (DataDir, LogsDir, Source)"
