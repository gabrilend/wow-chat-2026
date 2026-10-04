#!/usr/bin/env bash
# B013-playerbots-logical-op-parentheses.sh
# Fixes '&&' within '||' warnings by adding explicit parentheses
#
# Warning: '&&' within '||' [-Wlogical-op-parentheses]
# The && operator has higher precedence than ||, but explicit parens improve clarity.
#
# Affected files (12 instances):
#   - ChooseRpgTargetAction.cpp:338
#   - LfgActions.cpp:118
#   - RpgTriggers.cpp:34
#   - PvpValues.cpp:27,31
#   - PitOfSaronActions.cpp:27
#   - RaidIccTriggers.cpp:1148
#   - RaidTempestKeepActions.cpp:1443,1444,1445,1611
#   - RandomItemMgr.cpp:1785

# {{{ patch_B013_playerbots_logical_op_parentheses
#
# Rewritten 2026-10-03 as exact whole-line edits (patches.sh,
# line_edits_apply / line_edits_revert): each edited line carries the tag
# "  // B013", the revert turns back only tagged lines, and an old line not
# found the expected number of times stops the patch as stale. The old sed
# revert also changed lines upstream had since written the fixed way
# (scripts/verify-patches). Kept: the extra parentheses in LfgActions.cpp. Dropped: its edits to
# PvpValues.cpp, which on today's upstream changed the meaning ("!sameTeam &&
# X" became "!(sameTeam && X)", so bots judged flag carriers by the wrong
# team); upstream's lines there are already parenthesised and don't warn.

# path (from the source root) <TAB> old line <TAB> new line
B013_EDITS=$(cat <<'EDITS'
modules/mod-playerbots/src/Ai/Base/Actions/LfgActions.cpp	            (botLevel > dungeon->MinLevel + 10 && dungeon->TypeID == LFG_TYPE_DUNGEON))	            ((botLevel > dungeon->MinLevel + 10 && dungeon->TypeID == LFG_TYPE_DUNGEON)))
EDITS
)

# {{{ patch_B013_playerbots_logical_op_parentheses
patch_B013_playerbots_logical_op_parentheses() {
    line_edits_apply B013 <<< "${B013_EDITS}"
}
# }}}

# {{{ unpatch_B013_playerbots_logical_op_parentheses
unpatch_B013_playerbots_logical_op_parentheses() {
    line_edits_revert B013 <<< "${B013_EDITS}"
}
# }}}
