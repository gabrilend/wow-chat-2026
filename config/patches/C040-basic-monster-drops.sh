#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         C040
# profiles:   basic
# priority:   1315
# kind:       settings
# about:      Basic: richer monster drops (greens and blues x2, epics x5, rares' loot rolled twice)
# ==== end of header ====
# C040 - Basic: richer monster drops (greens and blues x2, epics x5, rares' loot rolled twice)
# On basic, ordinary monsters and elites that are not bosses drop greens and
# blues twice as often and epics five times as often, and rares' loot is
# rolled twice, while bosses keep their stock chances (issue 181: with
# quests gone from players, quest gear is gone too, and the monsters they
# fight make up for it). The rule is in basic's rules code
# (src/cpp-basic/basic_rules.cpp, copied in by B030), which reads these
# three settings at start; with none set it logs an error and drops stay
# stock, so every other profile is stock.
#
# Knobs written into worldserver.conf (keys of the project's own, not in
# the stock .conf.dist, so each is set or appended):
#   Basic.Drops.GreenBlueRate = 2   greens and blues from ordinary monsters
#   Basic.Drops.EpicRate      = 5   epics from ordinary monsters
#   Basic.Drops.RareRolls     = 2   times a rare's loot is rolled
# Tuned here, without a rebuild; each change goes into docs/balance-updates.md.
# The key names are kept in variables, as C031 does, which also keeps them
# out of test-profile-config-gates' "key exists in the stock .conf.dist" scan.
# Profiles: basic

# -- {{{ config_basic_monster_drops
config_basic_monster_drops() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    local pair key val
    for pair in "Basic.Drops.GreenBlueRate=2" "Basic.Drops.EpicRate=5" "Basic.Drops.RareRolls=2"; do
        key="${pair%%=*}" val="${pair#*=}"
        if grep -qE "^${key//./\\.}[[:space:]]*=" "${conf}"; then
            sed -i "s|^${key//./\\.}[[:space:]]*=.*|${key} = ${val}|" "${conf}"
        else
            printf '\n# C040 (basic, 181): richer monster drops (read by basic_rules.cpp)\n%s = %s\n' "${key}" "${val}" >> "${conf}"
        fi
    done
}
CONFIG_DESCRIPTIONS[config_basic_monster_drops]="Richer monster drops: greens and blues x2, epics x5, rares' loot rolled twice (read by basic_rules.cpp)"
# -- }}}
# ==== footer of C040 ====
# lines:      46
# ==== end of footer ====
