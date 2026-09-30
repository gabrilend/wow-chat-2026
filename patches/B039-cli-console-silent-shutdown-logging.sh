#!/usr/bin/env bash
# B039 - Log why the console thread shuts the world down (issue 163)
#
# CliRunnable.cpp calls World::StopNow() from two places when it decides
# stdin is done -- a failed std::getline in the non-interactive/piped
# branch, and feof(stdin) in the interactive/readline branch -- and halts
# the whole worldserver without a single log line explaining why. This
# patch adds one LOG_ERROR call immediately before each, so the next
# unexpected shutdown says which branch fired (and, for the getline one,
# std::cin's actual eof/fail state) instead of leaving nothing in
# Server.log to go on.
# Parallelizable: Yes (unique file)

# {{{ patch_B039_cli_console_silent_shutdown_logging
patch_B039_cli_console_silent_shutdown_logging() {
    local FILE="${AC_CODE_DIR}/src/server/apps/worldserver/CommandLine/CliRunnable.cpp"
    [[ ! -f "${FILE}" ]] && return 0

    if grep -q "console input ended unexpectedly" "${FILE}"; then
        echo "  [B039] CliRunnable.cpp: shutdown logging already present"
        return 0
    fi

    echo "  [B039] CliRunnable.cpp: logging both silent-shutdown paths"

    # Site 1: the non-interactive/piped branch's failed getline.
    sed -i '/if (!std::getline(std::cin, command))/,/World::StopNow(SHUTDOWN_EXIT_CODE);/{
        /World::StopNow(SHUTDOWN_EXIT_CODE);/i\
                LOG_ERROR("server.worldserver", "console input ended unexpectedly (getline failed, eof={}, fail={}) -- shutting down", std::cin.eof(), std::cin.fail());
    }' "${FILE}"

    # Site 2: the interactive/readline branch's feof(stdin) check.
    sed -i '/else if (feof(stdin))/,/World::StopNow(SHUTDOWN_EXIT_CODE);/{
        /World::StopNow(SHUTDOWN_EXIT_CODE);/i\
            LOG_ERROR("server.worldserver", "console input closed (stdin at EOF) -- shutting down");
    }' "${FILE}"
}
# }}}

# {{{ unpatch_B039_cli_console_silent_shutdown_logging
unpatch_B039_cli_console_silent_shutdown_logging() {
    local FILE="${AC_CODE_DIR}/src/server/apps/worldserver/CommandLine/CliRunnable.cpp"
    [[ ! -f "${FILE}" ]] && return 0

    sed -i '/console input ended unexpectedly/d' "${FILE}"
    sed -i '/console input closed (stdin at EOF)/d' "${FILE}"
}
# }}}
