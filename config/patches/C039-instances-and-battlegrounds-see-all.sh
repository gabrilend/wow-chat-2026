#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         C039
# profiles:   basic beta cc-test release vanilla
# priority:   1310
# kind:       settings
# about:      Instances and Battlegrounds: See as Far as the Server Allows
# ==== end of header ====
# C039 - Instances and Battlegrounds: See as Far as the Server Allows
# The owner, 2026-10-20: "how about for battlegrounds and instances we just
# have 100% view distance for all players and bots, always? That way we can
# see distant stuff happening. Makes it more immersive I think." The most
# the server allows is 250 yards (MAX_VISIBILITY_DISTANCE in ObjectDefines.h;
# a larger setting is clamped to 250 with an error at every start). Stock is
# 170 in dungeons and raids, already 250 in battlegrounds and arenas (stated
# here anyway, so the decision is written down). Bots see no farther than
# the bot module ever looks or acts (B056, issue 194), which the owner
# asked for alongside: "So how about the largest size for them in dungeons
# and BGs and instances and such?"
#
# Knobs written into worldserver.conf:
#   Visibility.Distance.Instances = 250
#   Visibility.Distance.BGArenas  = 250
# A config without one of the keys stops the step with an error naming it.
# Profiles: basic vanilla release beta cc-test (every profile built from
# source-beta, as B056; not alpha)

# -- {{{ config_instances_and_battlegrounds_see_all
config_instances_and_battlegrounds_see_all() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    local key pattern missing=0
    for key in Visibility.Distance.Instances Visibility.Distance.BGArenas; do
        pattern="${key//./\\.}"
        if ! grep -qE "^${pattern}[[:space:]]*=" "${conf}"; then
            echo "    ERROR: C039 found no '${key}' line in ${conf}; it stays at stock"
            missing=$((missing + 1))
            continue
        fi
        sed -i "s|^${pattern}[[:space:]]*=.*|${key} = 250|" "${conf}"
    done
    if [[ ${missing} -gt 0 ]]; then
        echo "           to debug: grep -n 'Visibility.Distance' ${conf} - did upstream rename them?"
        return 1
    fi
}
CONFIG_DESCRIPTIONS[config_instances_and_battlegrounds_see_all]="Instances and battlegrounds seen to 250 yards, the server's most"
# -- }}}
# ==== footer of C039 ====
# lines:      50
# ==== end of footer ====
