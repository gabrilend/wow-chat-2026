#!/usr/bin/env bash

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
