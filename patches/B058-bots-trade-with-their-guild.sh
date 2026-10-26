#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         B058
# profiles:   basic cc-test
# priority:   680
# kind:       source
# about:      Bots trade with their own guild
# ==== end of header ====
# B058 - Bots trade with their own guild
# Issue 623 (2026-10-26), the buddy profiles (basic, cc-test).
#
# For a general audience: the bot module lets a player trade with a bot
# only when the player is the bot's master or in the bot's group, and with
# the master only when grouped or at the module's top security level.
# Buddies are often ungrouped (in town they leave the party, 617c2), so
# their owner could not hand them an item. The owner, 2026-10-26: "If I
# want to give an item to a buddy-bot, they currently won't accept a trade
# request. Can we make it so they do? But only if they're in my clan." A
# buddy's clan is a guild (617l), so: a player in the bot's own guild may
# trade with it too. Anyone else is refused as before ("I'm kind of busy
# now"). Once past these checks the bot accepts what it is given (a buddy's
# account is not a random bot's, so the module's own fairness rules for
# random bots don't apply).
#
# Where: TradeStatusAction::Execute
# (modules/mod-playerbots/src/Ai/Base/Actions/TradeStatusAction.cpp), its
# two refusals: "neither master nor group member" and "ungrouped without
# full security". Each gains "and not in the bot's guild".
#
# Mechanics: two exact whole-line edits (patches.sh, line_edits_apply /
# line_edits_revert), tagged "  // B058"; the revert turns back only the
# tagged lines; an old line not found exactly once stops the patch as stale.
# Parallelizable: Yes

# path (from the source root) <TAB> old line <TAB> new line
B058_EDITS=$(printf '%s\t%s\t%s\n' \
    'modules/mod-playerbots/src/Ai/Base/Actions/TradeStatusAction.cpp' \
    '    if (trader != master && traderIsGameClientPlayer &&' \
    '    if (trader != master && traderIsGameClientPlayer && !(bot->GetGuildId() && bot->GetGuildId() == trader->GetGuildId()) &&' \
    'modules/mod-playerbots/src/Ai/Base/Actions/TradeStatusAction.cpp' \
    '    if ((!bot->GetGroup() || !bot->GetGroup()->IsMember(trader->GetGUID())) &&' \
    '    if ((!bot->GetGroup() || !bot->GetGroup()->IsMember(trader->GetGUID())) && !(bot->GetGuildId() && bot->GetGuildId() == trader->GetGuildId()) &&')

# {{{ patch_B058_bots_trade_with_their_guild
patch_B058_bots_trade_with_their_guild() {
    line_edits_apply B058 <<< "${B058_EDITS}"
}
# }}}

# {{{ unpatch_B058_bots_trade_with_their_guild
unpatch_B058_bots_trade_with_their_guild() {
    line_edits_revert B058 <<< "${B058_EDITS}"
}
# }}}
# ==== footer of B058 ====
# lines:      57
# ==== end of footer ====
