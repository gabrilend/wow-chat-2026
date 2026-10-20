#!/usr/bin/env bash

patch_B039_cli_console_silent_shutdown_logging() {
    local FILE="${AC_CODE_DIR}/src/server/apps/worldserver/CommandLine/CliRunnable.cpp"
    [[ ! -f "${FILE}" ]] && return 0

    if grep -q "console input ended unexpectedly" "${FILE}"; then
        echo "  [B039] CliRunnable.cpp: shutdown logging already present"
        return 0
    fi

    echo "  [B039] CliRunnable.cpp: logging both silent-shutdown paths"

    sed -i '/if (!std::getline(std::cin, command))/,/World::StopNow(SHUTDOWN_EXIT_CODE);/{
        /World::StopNow(SHUTDOWN_EXIT_CODE);/i\
                LOG_ERROR("server.worldserver", "console input ended unexpectedly (getline failed, eof={}, fail={}) -- shutting down", std::cin.eof(), std::cin.fail());
    }' "${FILE}"

    sed -i '/else if (feof(stdin))/,/World::StopNow(SHUTDOWN_EXIT_CODE);/{
        /World::StopNow(SHUTDOWN_EXIT_CODE);/i\
            LOG_ERROR("server.worldserver", "console input closed (stdin at EOF) -- shutting down");
    }' "${FILE}"
}

unpatch_B039_cli_console_silent_shutdown_logging() {
    local FILE="${AC_CODE_DIR}/src/server/apps/worldserver/CommandLine/CliRunnable.cpp"
    [[ ! -f "${FILE}" ]] && return 0

    sed -i '/console input ended unexpectedly/d' "${FILE}"
    sed -i '/console input closed (stdin at EOF)/d' "${FILE}"
}
