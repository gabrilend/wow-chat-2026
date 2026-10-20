#!/usr/bin/env bash

B053_EDITS=$(printf '%s\t%s\t%s\n' \
    'src/server/game/World/World.cpp' \
    '        playerBaseMoveSpeed[i] = baseMoveSpeed[i] * getRate(RATE_MOVESPEED_PLAYER);' \
    '        playerBaseMoveSpeed[i] = baseMoveSpeed[i] * (i == MOVE_WALK ? 1.0f : getRate(RATE_MOVESPEED_PLAYER));')

patch_B053_walking_at_full_speed() {
    line_edits_apply B053 <<< "${B053_EDITS}"
}

unpatch_B053_walking_at_full_speed() {
    line_edits_revert B053 <<< "${B053_EDITS}"
}
