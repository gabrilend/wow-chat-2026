#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         C038
# profiles:   basic beta release vanilla
# priority:   1305
# kind:       settings
# about:      No Quest Sparkles, Object Quest Marks or Map Points
# ==== end of header ====
# C038 - No Quest Sparkles, Object Quest Marks or Map Points
# Stock AzerothCore makes objects a player's quests need sparkle, puts the
# quest-giver's "!" and "?" over objects too, and marks quest places on the
# map and minimap. wow-chat-1 turned all three off: you find things by
# looking. The owner, 2026-10-20: "we should remove the sparkles from items
# and quest points from the map", and, asked whether the servers with
# quests should lose them too, "yes". Beta has no quests (E012), but it had
# them off already with the rest of wow-chat-1's settings, so it stays in.
# (Until 2026-10-20 the three were in C037, beta only.)
#
# Knobs written into worldserver.conf:
#   Visibility.ObjectSparkles     = 0
#   Visibility.ObjectQuestMarkers = 0
#   QuestPOI.Enabled              = 0
# A config without one of the keys stops the step with an error naming it.
# Profiles: basic vanilla release beta (not cc-test, kept stock for the
# client's tests; not alpha, whose older server is left as it was)

# -- {{{ config_no_quest_sparkles_or_map_points
config_no_quest_sparkles_or_map_points() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    local key pattern missing=0
    for key in Visibility.ObjectSparkles Visibility.ObjectQuestMarkers QuestPOI.Enabled; do
        pattern="${key//./\\.}"
        if ! grep -qE "^${pattern}[[:space:]]*=" "${conf}"; then
            echo "    ERROR: C038 found no '${key}' line in ${conf}; it stays on"
            missing=$((missing + 1))
            continue
        fi
        sed -i "s|^${pattern}[[:space:]]*=.*|${key} = 0|" "${conf}"
    done
    if [[ ${missing} -gt 0 ]]; then
        echo "           to debug: grep -n 'Sparkles\\|QuestMarkers\\|QuestPOI' ${conf} - did upstream rename them?"
        return 1
    fi
}
CONFIG_PROFILES[config_no_quest_sparkles_or_map_points]="basic vanilla release beta"
CONFIG_DESCRIPTIONS[config_no_quest_sparkles_or_map_points]="No quest sparkles, object quest marks or map points"
# -- }}}
# ==== footer of C038 ====
# lines:      50
# ==== end of footer ====
