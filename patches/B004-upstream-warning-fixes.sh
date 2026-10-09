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
# was left, and on 2026-10-09 it went too: the build's compiler (clang) gives
# no warning there unpatched, at the old pin or the new one (checked file by
# file with the build's own flags while moving the pins). The run-time fix
# below is now the patch's only edit.
#
# Added 2026-10-09, a warning at run time rather than compile time: the
# worldserver log filled with "MoveSplineInitArgs::Validate: expression
# 'velocity > 0.01f' failed" for Mulgore's Kodo Matriarchs (entry 2974),
# each walking 32 yards behind a Kodo Bull on its path. A creature in a
# formation is sent toward where its place will be in 1.65 seconds, at the
# leader's speed scaled by how far it has to go; one already standing on
# that place gets a speed near zero. Stock code swaps in the leader's walk
# speed only when the speed is exactly zero, so a near-zero one went on to
# the spline check, which refused the move and logged it, every second or
# so per follower. The edit swaps in the walk speed at the check's own limit
# (0.01 yards a second and below), so the follower takes a step of almost
# nothing at walking pace instead of a refused step at no pace: the same
# standing still, without the warning.

# path (from the source root) <TAB> old line <TAB> new line
B004_EDITS=$(cat <<'EDITS'
src/server/game/Movement/MovementGenerators/FormationMovementGenerator.cpp	    if (velocity == 0.0f)	    if (velocity <= 0.01f)
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
