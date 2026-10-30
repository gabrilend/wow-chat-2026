#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         C043
# profiles:   none
# priority:   1345
# kind:       settings
# about:      Monsters and objects respawn faster the more players are in their zone (the server's own rule; off until a profile is named)
# ==== end of header ====
# C043 - Respawns by Players in the Zone
# Issue 155z8. The owner, 2026-10-22: "the more players are in the area,
# the faster they respawn. Each player gives a 10% boost to the respawn
# speed". Asked on 2026-10-30 whether to use the server's own rule or new
# code for that 10%: "let's just use their system for now, we can come
# back to ours later."
#
# The server's rule (Map.cpp, the respawn delay's dynamic part): past
# RATE players in a zone, a respawn wait is multiplied by RATE / players,
# never under the minimum; RATE 1 means off (stock). Read in its code on
# 2026-10-30, two things it does that the owner's words don't say:
#   - rares and rare elites are left out (as are quest givers, world
#     bosses and anything in an instance), so it does not speed the rares
#     155z8 is about; their own clock is that issue's other step;
#   - every character in the zone counts, buddies included: one player
#     with a clan of seven is eight. RATE below counts that.
# Built and on are separate decisions: the profiles line says "none" until
# the owner names basic.
#
# Knobs written into worldserver.conf:
#   Respawn.DynamicRateCreature    = 8   (one player and a full clan: unchanged;
#                                         two such: half the wait)
#   Respawn.DynamicMinimumCreature = 10  (seconds; stock)
# A config without either key stops the step with an error naming it.

C043_RATE=8
C043_MINIMUM=10

# -- {{{ config_basic_respawns_by_players_in_the_zone
config_basic_respawns_by_players_in_the_zone() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    local key value pattern missing=0
    for key in Respawn.DynamicRateCreature Respawn.DynamicMinimumCreature; do
        pattern="${key//./\\.}"
        if ! grep -qE "^${pattern}[[:space:]]*=" "${conf}"; then
            echo "    ERROR: C043 found no '${key}' line in ${conf}; respawns stay at stock"
            missing=$((missing + 1))
            continue
        fi
        [[ "${key}" == Respawn.DynamicRateCreature ]] && value="${C043_RATE}" || value="${C043_MINIMUM}"
        sed -i "s|^${pattern}[[:space:]]*=.*|${key} = ${value}|" "${conf}"
    done
    if [[ ${missing} -gt 0 ]]; then
        echo "           to debug: grep -n 'Respawn.Dynamic' ${conf} - did upstream rename them?"
        return 1
    fi
}
CONFIG_DESCRIPTIONS[config_basic_respawns_by_players_in_the_zone]="Respawns quicken past 8 characters in a zone (the server's own rule)"
# -- }}}
# ==== footer of C043 ====
# lines:      60
# ==== end of footer ====
