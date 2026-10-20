#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         B053
# profiles:   basic
# priority:   630
# kind:       source
# about:      Players walk at the full stock speed; only running and the rest
# ==== end of header ====
# B053 - Players walk at the full stock speed; only running and the rest
# take the player move-speed rate
# Issue 166 (basic, 2026-10-12).
#
# For a general audience: the server's player move-speed setting
# (Rate.MoveSpeed.Player, 0.85 on basic, config patch C003) multiplies
# every kind of player movement: running, swimming, flying, and walking
# too. The owner, 2026-10-12: "can we make sure that walking speed is at
# 100% of it's normal speed?" So walking keeps the stock speed (2.5 yards
# a second) and only the other kinds are slowed.
#
# Where: World.cpp works out each kind's base speed for players once, at
# startup and on a config reload (playerBaseMoveSpeed, one per movement
# type); the edit leaves the walking one (MOVE_WALK, 0) out of the rate.
#
# Mechanics: one exact whole-line edit (patches.sh, line_edits_apply /
# line_edits_revert), tagged "  // B053"; the revert turns back only the
# tagged line; an old line not found exactly once stops the patch as stale.
# Parallelizable: Yes

# path (from the source root) <TAB> old line <TAB> new line
B053_EDITS=$(printf '%s\t%s\t%s\n' \
    'src/server/game/World/World.cpp' \
    '        playerBaseMoveSpeed[i] = baseMoveSpeed[i] * getRate(RATE_MOVESPEED_PLAYER);' \
    '        playerBaseMoveSpeed[i] = baseMoveSpeed[i] * (i == MOVE_WALK ? 1.0f : getRate(RATE_MOVESPEED_PLAYER));')

# {{{ patch_B053_walking_at_full_speed
patch_B053_walking_at_full_speed() {
    line_edits_apply B053 <<< "${B053_EDITS}"
}
# }}}

# {{{ unpatch_B053_walking_at_full_speed
unpatch_B053_walking_at_full_speed() {
    line_edits_revert B053 <<< "${B053_EDITS}"
}
# }}}
# ==== footer of B053 ====
# lines:      48
# ==== end of footer ====
