#!/bin/bash
# scripts/debug-run.sh - Crash-backtrace harness for the server binaries
#
# What it is, in one breath: a sourced helper that launches a server binary
# in a way that captures a stack trace to disk if it crashes, so a segfault
# stops being an opaque "Segmentation fault" and becomes a list of
# file:line frames you can read.
#
# How it does it (two mechanisms, best available wins):
#   1. gdb  - if installed, run the binary under gdb in batch mode. On the
#             crash gdb dumps the crashing thread's backtrace plus every
#             thread. Richest output; needs the gdb package.
#   2. shim - if gdb is absent, compile a tiny LD_PRELOAD shared object that
#             installs a SIGSEGV/SIGABRT/... handler. On the crash it walks
#             the stack and writes, per frame, the module and the frame's
#             offset from that module's load base (via dladdr). Because the
#             server binary is position-independent (PIE), the raw runtime
#             address is ASLR-shifted and useless on its own; the base-
#             relative offset is exactly what addr2line resolves against the
#             not-stripped binary. No extra packages — just the C compiler
#             and addr2line, both already present for building the server.
#
# Everything lands in the RAM-backed tmp/ tree (tmp/ -> /tmp/wow-chat-2), so
# traces never touch disk and clear on reboot.
#
# This file is SOURCED by scripts/worldserver and scripts/authserver; it
# relies on ${DIR} and ${PROFILE} already being set by the caller (the same
# way patches/patches.sh consumes the caller's environment).

# {{{ debug_outdir
# Resolve (and create) the per-profile debug output directory under tmp/.
# Echoes the path so callers can capture it.
debug_outdir() {
    local dir="${DIR}/tmp/debug-${PROFILE}"
    mkdir -p "${dir}"
    echo "${dir}"
}
# }}}

# {{{ debug_build_shim
# Compile the LD_PRELOAD backtrace shim on demand, caching the .so under the
# debug dir. Rebuilds only if the .so is missing (the embedded source never
# changes at runtime, so a present .so is always current). Echoes the .so
# path on success; returns non-zero (and explains why) if no C compiler is
# available, so the caller can fall back or error rather than run blind.
debug_build_shim() {
    local outdir; outdir="$(debug_outdir)"
    local so="${outdir}/bt-shim.so"
    local src="${outdir}/bt-shim.c"

    if [[ -f "${so}" ]]; then
        echo "${so}"
        return 0
    fi

    # Pick a compiler. cc is the conventional alias; fall back to gcc/clang.
    local CC=""
    for candidate in cc gcc clang; do
        if command -v "${candidate}" >/dev/null 2>&1; then
            CC="${candidate}"
            break
        fi
    done
    if [[ -z "${CC}" ]]; then
        echo "  [debug] No C compiler (cc/gcc/clang) found — cannot build the" >&2
        echo "          backtrace shim. Install gdb instead: sudo xbps-install -S gdb" >&2
        return 1
    fi

    # The handler is written to be as signal-safe as a crash handler can be:
    # it only uses write()/open()/backtrace()/dladdr(), pre-warms libgcc's
    # unwinder in the constructor, and re-raises the original signal with the
    # default disposition so the process still dies (and any core policy still
    # applies). DEBUG_BT_FILE names the output file; absent, it writes stderr.
    cat > "${src}" << 'CSHIM'
#define _GNU_SOURCE
#include <execinfo.h>
#include <dlfcn.h>
#include <signal.h>
#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>

/* -- {{{ open_out() : where the trace is written */
static int open_out(void) {
    const char *p = getenv("DEBUG_BT_FILE");
    if (!p) return 2;                       /* stderr */
    int f = open(p, O_WRONLY | O_CREAT | O_APPEND, 0644);
    return (f < 0) ? 2 : f;
}
/* -- }}} */

/* -- {{{ tiny async-safe writers (no stdio in a signal handler) */
static void wstr(int fd, const char *s) { write(fd, s, strlen(s)); }
static void wint(int fd, long v) {
    char t[24]; int j = 0;
    if (v == 0) { t[j++] = '0'; }
    if (v < 0) { write(fd, "-", 1); v = -v; }
    while (v) { t[j++] = '0' + (v % 10); v /= 10; }
    while (j) { char c = t[--j]; write(fd, &c, 1); }
}
static void whex(int fd, unsigned long v) {
    char t[16]; int j = 0;
    write(fd, "0x", 2);
    if (v == 0) { t[j++] = '0'; }
    while (v) { int d = v & 0xf; t[j++] = d < 10 ? '0' + d : 'a' + d - 10; v >>= 4; }
    while (j) { char c = t[--j]; write(fd, &c, 1); }
}
/* -- }}} */

/* -- {{{ handler() : dump base-relative frames, then re-raise */
static void handler(int sig) {
    int fd = open_out();
    wstr(fd, "\n=== CRASH signal "); wint(fd, sig); wstr(fd, " ===\n");

    void *frames[80];
    int n = backtrace(frames, 80);
    /* Machine-readable frames: "FRAME <i> <module-path> <base-offset>".
       base-offset = runtime addr - module load base, i.e. the ELF virtual
       address addr2line wants for a PIE. The bash side resolves each one. */
    for (int i = 0; i < n; i++) {
        Dl_info info;
        wstr(fd, "FRAME "); wint(fd, i); wstr(fd, " ");
        if (dladdr(frames[i], &info) && info.dli_fname && info.dli_fbase) {
            wstr(fd, info.dli_fname); wstr(fd, " ");
            whex(fd, (unsigned long)frames[i] - (unsigned long)info.dli_fbase);
        } else {
            wstr(fd, "? "); whex(fd, (unsigned long)frames[i]);
        }
        wstr(fd, "\n");
    }
    /* Human-readable fallback in case addr2line resolution comes up empty. */
    wstr(fd, "--- raw symbols ---\n");
    backtrace_symbols_fd(frames, n, fd);

    if (fd != 2) close(fd);
    signal(sig, SIG_DFL);
    raise(sig);
}
/* -- }}} */

/* -- {{{ init() : install handlers at load, warm the unwinder */
__attribute__((constructor))
static void init(void) {
    void *warm[1];
    backtrace(warm, 1);                     /* force libgcc unwinder dlopen now */
    struct sigaction sa;
    memset(&sa, 0, sizeof sa);
    sa.sa_handler = handler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_RESTART;
    sigaction(SIGSEGV, &sa, 0);
    sigaction(SIGABRT, &sa, 0);
    sigaction(SIGBUS,  &sa, 0);
    sigaction(SIGFPE,  &sa, 0);
    sigaction(SIGILL,  &sa, 0);
}
/* -- }}} */
CSHIM

    if ! "${CC}" -shared -fPIC -O0 -g -o "${so}" "${src}" -ldl 2>"${outdir}/bt-shim-build.log"; then
        echo "  [debug] Backtrace shim failed to compile — see ${outdir}/bt-shim-build.log" >&2
        return 1
    fi
    echo "${so}"
}
# }}}

# {{{ debug_symbolize
# Turn a raw FRAME dump ($1) into a readable file:line backtrace ($2) using
# addr2line against each frame's own module. Best-effort: unresolved frames
# still appear with their offset so nothing is silently dropped.
debug_symbolize() {
    local raw="${1}"
    local out="${2}"
    : > "${out}"
    local _tag idx fname off
    while read -r _tag idx fname off; do
        [[ "${_tag}" == "FRAME" ]] || continue
        local resolved fn fl
        if [[ -f "${fname}" ]] && command -v addr2line >/dev/null 2>&1; then
            resolved="$(addr2line -f -C -e "${fname}" "${off}" 2>/dev/null)"
            fn="${resolved%%$'\n'*}"
            fl="${resolved#*$'\n'}"
        else
            fn="??"; fl="??"
        fi
        printf '#%-3s %s\n        at %s   [%s +%s]\n' \
            "${idx}" "${fn:-??}" "${fl:-??}" "$(basename "${fname}")" "${off}" >> "${out}"
    done < "${raw}"
}
# }}}

# {{{ debug_run_binary
# Launch ${1} (e.g. ./worldserver, relative to the current bin dir) under the
# best available crash catcher, labelling output files with ${2}. The caller
# has already cd'd into the bin dir and exported LD_LIBRARY_PATH, so the
# binary sees the same environment a normal run would.
debug_run_binary() {
    local binary="${1}"
    local label="${2}"
    local outdir; outdir="$(debug_outdir)"
    local stamp; stamp="$(date +%Y%m%d-%H%M%S)"
    local bt="${outdir}/${label}-${stamp}-backtrace.txt"

    echo "=========================================================="
    echo " DEBUG MODE — crash traces go to:"
    echo "   ${outdir}/"
    echo "=========================================================="

    if command -v gdb >/dev/null 2>&1; then
        # gdb batch: run to completion/crash, then dump backtraces. Console
        # still shows the live server output (tee), and the same stream is
        # saved so the trace survives the terminal scrollback.
        echo " Using gdb. Backtrace on crash -> ${bt}"
        echo ""
        # Dump everything that helps localize a crash, to the console (tee) and
        # the saved file. Note: exact file:line still depends on how the binary
        # was built — a RelWithDebInfo (-O2) build smears inlined frames, so for
        # a precise line, build the target at -O0/-Og (a build-time concern the
        # runtime flag can't change; see the debug-build option in scripts/compile).
        gdb -batch -nx \
            -ex 'set pagination off' \
            -ex 'set confirm off' \
            -ex 'set print pretty on' \
            -ex 'run' \
            -ex 'printf "\n=== CRASHING THREAD (full: frames + locals) ===\n"' \
            -ex 'backtrace full' \
            -ex 'printf "\n=== REGISTERS ===\n"' \
            -ex 'info registers' \
            -ex 'printf "\n=== FAULTING FRAME: args + locals ===\n"' \
            -ex 'info args' \
            -ex 'info locals' \
            -ex 'printf "\n=== DISASSEMBLY AROUND PC ===\n"' \
            -ex 'x/24i $pc-32' \
            -ex 'printf "\n=== ALL THREADS (full) ===\n"' \
            -ex 'thread apply all backtrace full' \
            -ex 'printf "\n=== SHARED LIBRARIES ===\n"' \
            -ex 'info sharedlibrary' \
            -ex 'printf "\n=== MEMORY MAP ===\n"' \
            -ex 'info proc mappings' \
            -ex 'quit' \
            --args "${binary}" 2>&1 | tee "${bt}"
        echo ""
        echo " gdb session ended. Backtrace (if it crashed) saved to:"
        echo "   ${bt}"
        return 0
    fi

    # No gdb — fall back to the LD_PRELOAD shim. Announce the fallback per the
    # "notify on every fallback" rule; the shim is capable but gdb is richer.
    echo " gdb not found — falling back to the LD_PRELOAD backtrace shim."
    echo " (Install gdb for fuller traces: sudo xbps-install -S gdb)"

    local shim
    if ! shim="$(debug_build_shim)"; then
        echo ""
        echo " ERROR: no gdb and no working backtrace shim — running the"
        echo "        binary plainly, so a crash will NOT be traced."
        "${binary}"
        return 1
    fi

    local frames="${outdir}/${label}-${stamp}-frames.txt"
    echo " Using backtrace shim. Raw frames on crash -> ${frames}"
    echo ""

    DEBUG_BT_FILE="${frames}" LD_PRELOAD="${shim}" "${binary}"
    local rc=$?

    echo ""
    if [[ -s "${frames}" ]]; then
        debug_symbolize "${frames}" "${bt}"
        echo " Crash captured. Symbolized backtrace:"
        echo "   ${bt}"
        echo " (raw frames: ${frames})"
    else
        echo " No crash frames were recorded (exit code ${rc})."
        echo " If it crashed without a trace, the shim may have missed the"
        echo " signal — install gdb and re-run with --debug for a full trace."
    fi
    return "${rc}"
}
# }}}
