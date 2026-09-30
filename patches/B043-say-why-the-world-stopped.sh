#!/usr/bin/env bash
# B043 - The world says who stopped it
# Issue 163 (2026-09-29).
#
# For a general audience: the server stops its world from about twenty-five
# places in its code (a failed start-up step, an ID running past its limit,
# a stop command, a stop signal, ...). All of them ended in the same line,
# "Halting process...", which says nothing about which one it was. This
# morning's halt took a debugger to trace: an ID limit had been hit, logged
# sixty lines above the halt among start-up noise. Now the halt says where
# the stop was asked for and what kind it was:
#   Halting process... (asked for at ObjectMgr.cpp:7783; exit code 1: an error)
# and a stop signal names itself first:
#   Stop signal 15 (SIGTERM: a kill, or a service manager) received
# The owner, 2026-09-29: "I'm wondering how far upstream we could trace that
# particular problem, and then if we could add output for each similar type
# of problem" / "definitely this one".
#
# Mechanics, three files, every edit inside ">>> B043 ... BEGIN" / "<<< B043
# ... END" marker comments (a replaced line kept as "//B043-ORIG:<line>" for
# the revert):
#   World.h   the stop call becomes StopNowAt(code, file, line), which keeps
#             the first requester's file and line; a macro after the class
#             turns every existing "StopNow(code)" into a call carrying its
#             own file and line, so none of the callers change.
#   World.cpp the two places that set the stop flag directly (a timed
#             ".server shutdown" running out, and ".server shutdown 0") go
#             through the stop call too.
#   Main.cpp  "Halting process..." prints the requester and the exit code's
#             meaning; the signal handler names its signal.
# Anchors must occur exactly once or the patch stops with an error.
# Parallelizable: No (World.h is included nearly everywhere; one patch at a time)

B043_BEGIN='// >>> B043-say-why-the-world-stopped BEGIN'
B043_END='// <<< B043-say-why-the-world-stopped END'
B043_H_STOP='    static void StopNow(uint8 exitcode) { _stopEvent = true; _exitCode = exitcode; }'
B043_H_DEFINE='#define sWorld getWorldInstance()'
B043_CPP_TIMER='                _stopEvent = true;                         // exist code already set'
B043_CPP_NOW='            _stopEvent = true;                             // exist code already set'
B043_MAIN_HALT='    LOG_INFO("server.worldserver", "Halting process...");'
B043_MAIN_SIG='void SignalHandler(boost::system::error_code const& error, int /*signalNumber*/)'

# {{{ _b043_files
_b043_files() {
    B043_H="${AC_CODE_DIR}/src/server/game/World/World.h"
    B043_CPP="${AC_CODE_DIR}/src/server/game/World/World.cpp"
    B043_MAIN="${AC_CODE_DIR}/src/server/apps/worldserver/Main.cpp"
}
# }}}

# {{{ patch_B043_say_why_the_world_stopped
patch_B043_say_why_the_world_stopped() {
    _b043_files
    local f
    for f in "${B043_H}" "${B043_CPP}" "${B043_MAIN}"; do
        [[ -f "${f}" ]] || { echo "  [B043] ERROR: ${f} missing"; return 1; }
    done
    grep -qF "B043-say-why-the-world-stopped" "${B043_H}" && return 0     # witness guard

    local a b c d e g
    a=$(grep -cxF -- "${B043_H_STOP}"   "${B043_H}")
    b=$(grep -cxF -- "${B043_H_DEFINE}" "${B043_H}")
    c=$(grep -cxF -- "${B043_CPP_TIMER}" "${B043_CPP}")
    d=$(grep -cxF -- "${B043_CPP_NOW}"   "${B043_CPP}")
    e=$(grep -cxF -- "${B043_MAIN_HALT}" "${B043_MAIN}")
    g=$(grep -cxF -- "${B043_MAIN_SIG}"  "${B043_MAIN}")
    if [[ "${a}${b}${c}${d}${e}${g}" != "111111" ]]; then
        echo "  [B043] ERROR: anchors found (want 1 each): World.h stop ${a}, sWorld define ${b}," \
             "World.cpp timer ${c}, immediate ${d}, Main.cpp halt ${e}, signal handler ${g}"
        return 1
    fi

    STOP="${B043_H_STOP}" DEFINE="${B043_H_DEFINE}" BEGIN_M="${B043_BEGIN}" END_M="${B043_END}" awk '
        $0 == ENVIRON["STOP"] {
            print "    " ENVIRON["BEGIN_M"]
            print "//B043-ORIG:" $0
            print "    // Everland Ghostsong (issue 163): the first stop request keeps its file"
            print "    // and line, so the halt can say who asked. Callers write StopNow(code);"
            print "    // the macro after this class adds their location."
            print "    static void StopNowAt(uint8 exitcode, char const* file, int line)"
            print "    {"
            print "        if (!_stopEvent)"
            print "        {"
            print "            _stopFile = file;"
            print "            _stopLine = line;"
            print "        }"
            print "        _stopEvent = true;"
            print "        _exitCode = exitcode;"
            print "    }"
            print "    static char const* GetStopFile() { return _stopFile; }   // null: nothing asked yet"
            print "    static int GetStopLine() { return _stopLine; }"
            print "    static inline char const* _stopFile = nullptr;"
            print "    static inline int _stopLine = 0;"
            print "    " ENVIRON["END_M"]
            next
        }
        { print }
        $0 == ENVIRON["DEFINE"] {
            print ENVIRON["BEGIN_M"]
            print "// every World::StopNow(code) / sWorld->StopNow(code) carries its own"
            print "// file and line (issue 163)"
            print "#define StopNow(code) StopNowAt((code), __FILE__, __LINE__)"
            print ENVIRON["END_M"]
        }
    ' "${B043_H}" > "${B043_H}.b043" && mv "${B043_H}.b043" "${B043_H}"

    TIMER="${B043_CPP_TIMER}" NOW="${B043_CPP_NOW}" BEGIN_M="${B043_BEGIN}" END_M="${B043_END}" awk '
        $0 == ENVIRON["TIMER"] || $0 == ENVIRON["NOW"] {
            ind = ($0 == ENVIRON["TIMER"]) ? "                " : "            "
            print ind ENVIRON["BEGIN_M"]
            print "//B043-ORIG:" $0
            print ind "StopNow(_exitCode);                        // the shutdown command'"'"'s stop, located (issue 163)"
            print ind ENVIRON["END_M"]
            next
        }
        { print }
    ' "${B043_CPP}" > "${B043_CPP}.b043" && mv "${B043_CPP}.b043" "${B043_CPP}"

    HALT="${B043_MAIN_HALT}" SIG="${B043_MAIN_SIG}" BEGIN_M="${B043_BEGIN}" END_M="${B043_END}" awk '
        $0 == ENVIRON["HALT"] {
            print "    " ENVIRON["BEGIN_M"]
            print "//B043-ORIG:" $0
            print "    // Everland Ghostsong (issue 163): who asked for the stop, and what kind"
            print "    {"
            print "        uint8 code = World::GetExitCode();"
            print "        char const* meaning = code == SHUTDOWN_EXIT_CODE ? \"a shutdown\""
            print "                            : code == ERROR_EXIT_CODE    ? \"an error; its ERROR line is above\""
            print "                            : code == RESTART_EXIT_CODE  ? \"a restart\" : \"unknown\";"
            print "        if (char const* file = World::GetStopFile())"
            print "        {"
            print "            std::string where = file;"
            print "            where = where.substr(where.find_last_of(\"/\\\\\") + 1);"
            print "            LOG_INFO(\"server.worldserver\", \"Halting process... (asked for at {}:{}; exit code {}: {})\","
            print "                where, World::GetStopLine(), code, meaning);"
            print "        }"
            print "        else"
            print "            LOG_INFO(\"server.worldserver\", \"Halting process... (no stop request was recorded; exit code {}: {})\","
            print "                code, meaning);"
            print "    }"
            print "    " ENVIRON["END_M"]
            next
        }
        $0 == ENVIRON["SIG"] {
            print ENVIRON["BEGIN_M"]
            print "//B043-ORIG:" $0
            print "void SignalHandler(boost::system::error_code const& error, int signalNumber)"
            print ENVIRON["END_M"]
            getline; print                              # the opening brace
            print "    " ENVIRON["BEGIN_M"]
            print "    // Everland Ghostsong (issue 163): name the signal before stopping"
            print "    if (!error)"
            print "        LOG_INFO(\"server.worldserver\", \"Stop signal {} ({}) received\", signalNumber,"
            print "            signalNumber == SIGINT  ? \"SIGINT: Ctrl+C in the server'"'"'s terminal\""
            print "          : signalNumber == SIGTERM ? \"SIGTERM: a kill, or a service manager\" : \"another signal\");"
            print "    " ENVIRON["END_M"]
            next
        }
        { print }
    ' "${B043_MAIN}" > "${B043_MAIN}.b043" && mv "${B043_MAIN}.b043" "${B043_MAIN}"

    echo "  [B043] The world says who stopped it (file, line, exit code; signals by name)"
}
# }}}

# {{{ unpatch_B043_say_why_the_world_stopped
unpatch_B043_say_why_the_world_stopped() {
    _b043_files
    local f
    for f in "${B043_H}" "${B043_CPP}" "${B043_MAIN}"; do
        [[ -f "${f}" ]] || continue
        grep -qF "B043-say-why-the-world-stopped" "${f}" || continue    # nothing of ours
        awk '
            /\/\/ >>> B043-say-why-the-world-stopped BEGIN/ { inblock = 1; next }
            inblock && /^\/\/B043-ORIG:/ { sub(/^\/\/B043-ORIG:/, ""); print; next }
            inblock && /\/\/ <<< B043-say-why-the-world-stopped END/ { inblock = 0; next }
            inblock { next }
            { print }' "${f}" > "${f}.b043" && mv "${f}.b043" "${f}"
    done
    return 0
}
# }}}
