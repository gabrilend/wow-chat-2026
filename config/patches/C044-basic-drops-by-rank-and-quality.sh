#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         C044
# profiles:   basic
# priority:   1316
# kind:       settings
# about:      Basic: the drop table's knobs by monster rank and item quality (issue 155z10; none turned yet)
# ==== end of header ====
# C044 - Basic: drops by monster rank and item quality (issue 155z10)
# The owner, 2026-10-22: "Can we find the tuning knob that calibrates how
# much more each tier of mob will be rewarded with certain quality item
# drops? ... We can store it in the config file." The rule is in basic's
# rules code (src/cpp-basic/basic_rules.cpp, the rank-by-quality table),
# which reads, for each monster rank and item quality, two settings, each 1
# (stock) when unset, on top of C040's rates:
#   Basic.Drop.<Rank>.<Quality>.Rate      the chance each item drops, times this
#   Basic.Drop.<Rank>.<Quality>.Quantity  how many tries each item, or each
#                                         one-quality table, gets
#   <Rank>:    Normal Elite Rare RareElite Boss
#   <Quality>: Poor Common Uncommon Rare Epic Legendary
# The knobs are the lines of C044_CELLS below: add one to turn a knob,
# then install (or edit worldserver.conf and restart, to try a value); each
# change goes into docs/balance-updates.md. None is turned yet, so nothing
# changes. The key names are built in the loop, as C040 keeps its own out of
# test-profile-config-gates' "key exists in the stock .conf.dist" scan.
# Profiles: basic

# Each "Rank Quality Rate Quantity". For example, rares' greens twice as
# likely with three tries: "Rare Uncommon 2 3".
C044_CELLS=(
)

# -- {{{ config_basic_drops_by_rank_and_quality
config_basic_drops_by_rank_and_quality() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    local cell rank quality rate quantity key val part
    for cell in "${C044_CELLS[@]}"; do
        read -r rank quality rate quantity <<< "${cell}"
        if [[ -z "${quantity}" ]]; then
            echo "    ERROR: C044 cell '${cell}' needs four words: Rank Quality Rate Quantity"
            return 1
        fi
        for part in "Rate=${rate}" "Quantity=${quantity}"; do
            key="Basic.Drop.${rank}.${quality}.${part%%=*}" val="${part#*=}"
            if grep -qE "^${key//./\\.}[[:space:]]*=" "${conf}"; then
                sed -i "s|^${key//./\\.}[[:space:]]*=.*|${key} = ${val}|" "${conf}"
            else
                printf '\n# C044 (basic, 155z10): drops by rank and quality (read by basic_rules.cpp)\n%s = %s\n' "${key}" "${val}" >> "${conf}"
            fi
        done
    done
}
CONFIG_DESCRIPTIONS[config_basic_drops_by_rank_and_quality]="Drops by monster rank and item quality: the knobs turned (read by basic_rules.cpp)"
# -- }}}
# ==== footer of C044 ====
# lines:      57
# ==== end of footer ====
