#!/usr/bin/env bash


B004_EDITS=$(cat <<'EDITS'
src/server/game/Movement/MovementGenerators/FormationMovementGenerator.cpp	    if (velocity == 0.0f)	    if (velocity <= 0.01f)
EDITS
)

patch_B004_upstream_warning_fixes() {
    line_edits_apply B004 <<< "${B004_EDITS}"
}

unpatch_B004_upstream_warning_fixes() {
    line_edits_revert B004 <<< "${B004_EDITS}"
}
