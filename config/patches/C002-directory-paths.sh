#!/usr/bin/env bash
# C002 - Directory Paths
# Set project directory paths (DataDir, LogsDir, SourceDirectory, etc.)
# Profiles: all

# -- {{{ config_directory_paths
config_directory_paths() {
    local conf_auth="${INSTALL_DIR}/etc/authserver.conf"
    local conf_world="${INSTALL_DIR}/etc/worldserver.conf"

    # DIR must be set - fail early if not
    # Fallback to hardcoded path if not set (shouldn't happen)
    local PROJECT_DIR="${DIR:-/home/ritz/games/azeroth-core/wow-chat-2026}"

    # Define paths locally to avoid dependency on caller context
    local LOGS_DIR="${PROJECT_DIR}/logs-${PROFILE}"
    local BUILD_DIR="${PROJECT_DIR}/build-${PROFILE}"
    local MYSQL_DIR="${PROJECT_DIR}/mysql/installed-files"

    # AC_CODE_DIR: profile to source directory mapping
    # vanilla shares source-beta with release/beta — see issue 148.
    local AC_CODE_DIR
    case "${PROFILE}" in
        release) AC_CODE_DIR="${PROJECT_DIR}/source-beta"  ;;
        beta)    AC_CODE_DIR="${PROJECT_DIR}/source-beta"  ;;
        vanilla) AC_CODE_DIR="${PROJECT_DIR}/source-beta"  ;;
        alpha)   AC_CODE_DIR="${PROJECT_DIR}/source-alpha" ;;
        *)       echo "ERROR: Unknown profile '${PROFILE}' in config_directory_paths"; return 1 ;;
    esac

    # Data and logs
    sed -i 's|^DataDir.*=.*|DataDir = "'"${PROJECT_DIR}"'/data-files"|' "${conf_world}"
    sed -i 's|^LogsDir.*=.*|LogsDir = "'"${LOGS_DIR}"'"|' "${conf_world}"
    sed -i 's|^LogsDir.*=.*|LogsDir = "'"${LOGS_DIR}"'"|' "${conf_auth}"

    # Source and build paths
    sed -i 's|^SourceDirectory.*=.*|SourceDirectory = "'"${AC_CODE_DIR}"'"|' "${conf_auth}"
    sed -i 's|^SourceDirectory.*=.*|SourceDirectory = "'"${AC_CODE_DIR}"'"|' "${conf_world}"
    sed -i 's|^BuildDirectory.*=.*|BuildDirectory = "'"${BUILD_DIR}"'"|' "${conf_world}"

    # MySQL executable
    sed -i 's|^MySQLExecutable.*=.*|MySQLExecutable = "'"${MYSQL_DIR}"'/bin/mysql"|' "${conf_auth}"
    sed -i 's|^MySQLExecutable.*=.*|MySQLExecutable = "'"${MYSQL_DIR}"'/bin/mysql"|' "${conf_world}"
}
CONFIG_PROFILES[config_directory_paths]="all"
CONFIG_DESCRIPTIONS[config_directory_paths]="Directory paths (DataDir, LogsDir, Source)"
# -- }}}
