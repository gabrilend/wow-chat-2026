#!/usr/bin/env bash
# C020 - Vanilla Playerbot Population Band (hold 128–256 active bots)
# Bound the ambient random-bot fleet to a floor of 128 and a ceiling of 256
# simultaneously-online bots, replacing the upstream .dist default of
# 500/500. The module keeps the live population inside this band: it logs
# more bots in whenever fewer than MinRandomBots are online and stops adding
# once MaxRandomBots are up, cycling individuals in and out over time.
#
# Knobs written into playerbots.conf:
#   MinRandomBots=128   floor — keep at least this many bots in-world
#   MaxRandomBots=256   ceiling — never more than this online at once
#
# Account headroom: C018 pins RandomBotAccountCount=110, and each account
# hosts up to 10 bot characters, so 110 accounts cover the 256 ceiling with
# room to spare (the module's own formula wants only MaxRandomBots/10 +
# AddClassAccountPoolSize ≈ 76). So lowering the ceiling does not undershoot
# C018 — no change needed there.
#
# Why 128–256: a full 500-bot fleet was more ambient traffic than the 20-40
# Eastern Kingdoms band needs, and it paid for the whole 500 in cold-boot
# login cost every startup. A 128–256 band keeps the world visibly populated
# without the login stampede, and leaves the ceiling free to tune. Adjust in
# docs/balance-updates.md.
#
# Counterpart data point: C014 owns the level band (20→40); this owns how
# many of those bots exist at once.
# Profiles: vanilla (basic dropped 2026-09-24: basic runs no random bots, C023)

# -- {{{ config_vanilla_playerbot_population
config_vanilla_playerbot_population() {
    local BOT_FLOOR=128
    local BOT_CEIL=256
    local conf="${INSTALL_DIR}/etc/modules/playerbots.conf"
    # Anchor with [[:space:]]*= so the sed can't bleed past the key name. The
    # bare `.*=.*` was greedy: it also matched MinRandomBots*PriceChangeInterval*
    # (the `.*` swallowed "PriceChangeInterval"), rewriting that line into a
    # second MinRandomBots entry — duplicating the population key AND deleting
    # MinRandomBotsPriceChangeInterval, which then surfaced as "Missing property"
    # at boot. Same failure shape as the old C012/C014 RandomBotMinLevel bug.
    sed -i 's|^AiPlayerbot\.MinRandomBots[[:space:]]*=.*|AiPlayerbot.MinRandomBots = '"${BOT_FLOOR}"'|' "${conf}"
    sed -i 's|^AiPlayerbot\.MaxRandomBots[[:space:]]*=.*|AiPlayerbot.MaxRandomBots = '"${BOT_CEIL}"'|' "${conf}"
}
CONFIG_PROFILES[config_vanilla_playerbot_population]="vanilla"
CONFIG_DESCRIPTIONS[config_vanilla_playerbot_population]="Playerbot population band 128–256 active"
# -- }}}
