#!/usr/bin/env bash
# B004 - Fix ~695 compiler warnings in upstream modules
# Issue 333: Clean build improves code quality
# Parallelizable: Yes (no conflicts with B001-B003)

# {{{ patch_B004_upstream_warning_fixes
#
# Rewritten 2026-10-03 as exact whole-line edits (patches.sh,
# line_edits_apply / line_edits_revert): each edited line carries the tag
# "  // B004", the revert turns back only tagged lines, and an old line not
# found the expected number of times stops the patch as stale. The old sed
# revert also changed lines upstream had since written the fixed way
# (scripts/verify-patches). Of its original warning fixes, upstream now has all but one (the
# equipment-slot comparison in mod-ale's PlayerMethods.h); only that edit
# is left.

# path (from the source root) <TAB> old line <TAB> new line
B004_EDITS=$(cat <<'EDITS'
modules/mod-ale/src/LuaEngine/methods/PlayerMethods.h	        if (slot >= EQUIPMENT_SLOT_START && slot < EQUIPMENT_SLOT_END)	        if (slot >= static_cast<int32>(EQUIPMENT_SLOT_START) && slot < static_cast<int32>(EQUIPMENT_SLOT_END))
EDITS
)

# {{{ patch_B004_upstream_warning_fixes
patch_B004_upstream_warning_fixes() {
    line_edits_apply B004 <<< "${B004_EDITS}"
}
# }}}

# {{{ unpatch_B004_upstream_warning_fixes
unpatch_B004_upstream_warning_fixes() {
    line_edits_revert B004 <<< "${B004_EDITS}"
}
# }}}
