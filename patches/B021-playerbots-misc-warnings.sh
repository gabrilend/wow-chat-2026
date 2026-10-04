#!/usr/bin/env bash
# B021-playerbots-misc-warnings.sh
#
# Catch-all for the small warning categories that don't share a shape
# with the existing B-patches. One patch per category would multiply
# files needlessly; bundling them keeps the registry lean. Each block
# is independent and idempotent — adding or removing one block doesn't
# affect the others.
#
# Covers:
#   -Wmisleading-indentation     — AuchenaiCrypts x2, TravelMgr x1
#   -Wrange-loop-construct       — CustomStrategy
#   -Wunused-lambda-capture      — RandomPlayerbotMgr
#   -Wint-in-bool-context        — OculusMultipliers (also fixes a real bug)
#   -Wtautological-constant-out-of-range-compare — InventoryAction

# {{{ patch_B021_playerbots_misc_warnings
#
# Rewritten 2026-10-03 as exact whole-line edits (patches.sh,
# line_edits_apply / line_edits_revert): each edited line carries the tag
# "  // B021", the revert turns back only tagged lines, and an old line not
# found the expected number of times stops the patch as stale. The old sed
# revert also changed lines upstream had since written the fixed way
# (scripts/verify-patches). All three string positions still need size_t upstream.

# path (from the source root) <TAB> old line <TAB> new line
B021_EDITS=$(cat <<'EDITS'
modules/mod-playerbots/src/Ai/Base/Actions/InventoryAction.cpp	    uint32 pos = outfit.find("=");	    size_t pos = outfit.find("=");
modules/mod-playerbots/src/Ai/Base/Actions/InventoryAction.cpp	    uint8 pos = text.find("=") + 1;	    size_t pos = text.find("=") + 1;
modules/mod-playerbots/src/Ai/Base/Actions/InventoryAction.cpp	        uint32 endPos = text.find(',', pos);	        size_t endPos = text.find(',', pos);
EDITS
)

# {{{ patch_B021_playerbots_misc_warnings
patch_B021_playerbots_misc_warnings() {
    line_edits_apply B021 <<< "${B021_EDITS}"
}
# }}}

# {{{ unpatch_B021_playerbots_misc_warnings
unpatch_B021_playerbots_misc_warnings() {
    line_edits_revert B021 <<< "${B021_EDITS}"
}
# }}}
