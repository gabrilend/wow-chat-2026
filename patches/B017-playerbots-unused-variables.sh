#!/usr/bin/env bash
# B017-playerbots-unused-variables.sh
# Fixes unused variable warnings
#
# Warning: unused variable 'X' [-Wunused-variable]
# Warning: variable 'X' set but not used [-Wunused-but-set-variable]
#
# Fix: Add (void)variable; to suppress warning while preserving the code
# (in case the variable is intended for future use or debugging)
#
# Affected files (12 instances):
#   - ChooseRpgTargetAction.cpp:119
#   - DropQuestAction.cpp:82
#   - LfgActions.cpp:177
#   - Arrow.cpp:22
#   - ItemCountValue.cpp:14
#   - ItemUsageValue.cpp:867
#   - RaidSSCActions.cpp:2291
#   - RaidSSCMultipliers.cpp:693
#   - RaidUlduarActions.cpp:2335
#   - PlayerbotMgr.cpp:356
#   - PlayerbotFactory.cpp:1973,2136

# {{{ patch_B017_playerbots_unused_variables
patch_B017_playerbots_unused_variables() {
    local PLAYERBOTS_DIR="${AC_CODE_DIR}/modules/mod-playerbots/src"

    [[ -d "${PLAYERBOTS_DIR}" ]] || return 0

    # For each unused variable, add (void)varname; after its declaration/assignment
    # This is safer than removing the variable in case it's for debugging

    # ChooseRpgTargetAction.cpp:119 - Player* player (assigned from GetMaster, not GetBot)
    local FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/ChooseRpgTargetAction.cpp"
    if [[ -f "${FILE}" ]] && ! grep -q "(void)player;" "${FILE}" 2>/dev/null; then
        sed -i '/Player\* player = botAI->GetMaster();/a\        (void)player;  // Suppress unused warning' "${FILE}" 2>/dev/null || true
    fi

    # DropQuestAction.cpp:82 - numQuest (uint8, not uint16)
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/DropQuestAction.cpp"
    if [[ -f "${FILE}" ]] && ! grep -q "(void)numQuest;" "${FILE}" 2>/dev/null; then
        sed -i '/uint8 numQuest = 0;/a\    (void)numQuest;  // Suppress unused warning' "${FILE}" 2>/dev/null || true
    fi

    # LfgActions.cpp:177 - currentRoles
    # Upstream widened the type from uint8 to uint32 between releases; the
    # earlier `uint8 currentRoles = ` anchor no longer matched, so the
    # warning slipped through. Match on the bare assignment so future
    # type bumps don't break this again.
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Actions/LfgActions.cpp"
    if [[ -f "${FILE}" ]] && ! grep -q "(void)currentRoles;" "${FILE}" 2>/dev/null; then
        sed -i '/currentRoles = sLFGMgr->GetRoles/a\        (void)currentRoles;  // Suppress unused warning' "${FILE}" 2>/dev/null || true
    fi

    # Arrow.cpp:22 - healerLines
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/Arrow.cpp"
    if [[ -f "${FILE}" ]] && ! grep -q "(void)healerLines;" "${FILE}" 2>/dev/null; then
        sed -i '/bool healerLines = /a\    (void)healerLines;  // Suppress unused warning' "${FILE}" 2>/dev/null || true
    fi

    # ItemCountValue.cpp:14 - bot
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/ItemCountValue.cpp"
    if [[ -f "${FILE}" ]] && ! grep -q "(void)bot;" "${FILE}" 2>/dev/null; then
        sed -i '/Player\* bot = botAI->GetBot();/a\    (void)bot;  // Suppress unused warning' "${FILE}" 2>/dev/null || true
    fi

    # ItemUsageValue.cpp:867 - craft_skill_gain
    FILE="${PLAYERBOTS_DIR}/Ai/Base/Value/ItemUsageValue.cpp"
    if [[ -f "${FILE}" ]] && ! grep -q "(void)craft_skill_gain;" "${FILE}" 2>/dev/null; then
        sed -i '/uint32 craft_skill_gain = /a\                    (void)craft_skill_gain;  // Suppress unused warning' "${FILE}" 2>/dev/null || true
    fi

    # RaidSSCActions.cpp:2291 - firstLineup
    FILE="${PLAYERBOTS_DIR}/Ai/Raid/SerpentshrineCavern/Action/RaidSSCActions.cpp"
    if [[ -f "${FILE}" ]] && ! grep -q "(void)firstLineup;" "${FILE}" 2>/dev/null; then
        sed -i '/bool firstLineup = /a\                (void)firstLineup;  // Suppress unused warning' "${FILE}" 2>/dev/null || true
    fi

    # RaidSSCMultipliers.cpp:693 - myIndex
    FILE="${PLAYERBOTS_DIR}/Ai/Raid/SerpentshrineCavern/Multiplier/RaidSSCMultipliers.cpp"
    if [[ -f "${FILE}" ]] && ! grep -q "(void)myIndex;" "${FILE}" 2>/dev/null; then
        sed -i '/int myIndex = /a\        (void)myIndex;  // Suppress unused warning' "${FILE}" 2>/dev/null || true
    fi

    # RaidUlduarActions.cpp:2335 - leviathanMkII
    FILE="${PLAYERBOTS_DIR}/Ai/Raid/Ulduar/Action/RaidUlduarActions.cpp"
    if [[ -f "${FILE}" ]] && ! grep -q "(void)leviathanMkII;" "${FILE}" 2>/dev/null; then
        sed -i '/Unit\* leviathanMkII = /a\        (void)leviathanMkII;  // Suppress unused warning' "${FILE}" 2>/dev/null || true
    fi

    # PlayerbotMgr.cpp:356 - masterWorldSessionPtr
    FILE="${PLAYERBOTS_DIR}/Bot/PlayerbotMgr.cpp"
    if [[ -f "${FILE}" ]] && ! grep -q "(void)masterWorldSessionPtr;" "${FILE}" 2>/dev/null; then
        sed -i '/WorldSession\* masterWorldSessionPtr = /a\            (void)masterWorldSessionPtr;  // Suppress unused warning' "${FILE}" 2>/dev/null || true
    fi

    # PlayerbotFactory.cpp:1973,2136 - newItem (two instances)
    #
    # REMOVED 2026-05-19: Upstream commented out both `Item* newItem = ...`
    # declarations (lines 1983 and 2012 are now inside `//` blocks). The
    # remaining live occurrence at line 2415 is `if (Item* newItem = ...)`
    # — scoped to the if-body, where newItem IS used, so no warning. The
    # sed pattern matched the FIRST occurrence regardless of comment
    # state, inserting raw `(void)newItem;` between `//` lines, which the
    # compiler parsed at file scope: "expected unqualified-id".
    #
    # Block left in place as a tombstone in case upstream re-enables the
    # commented-out branches and the warning returns; restoring would
    # need an anchor that skips `//`-prefixed lines.
}
# }}}

# {{{ unpatch_B017_playerbots_unused_variables
unpatch_B017_playerbots_unused_variables() {
    local PLAYERBOTS_DIR="${AC_CODE_DIR}/modules/mod-playerbots/src"

    [[ -d "${PLAYERBOTS_DIR}" ]] || return 0

    # Remove all (void)...; // Suppress unused warning lines
    find "${PLAYERBOTS_DIR}" -name "*.cpp" -exec sed -i '/Suppress unused warning/d' {} \; 2>/dev/null || true
}
# }}}
