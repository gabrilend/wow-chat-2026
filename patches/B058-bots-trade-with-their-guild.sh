#!/usr/bin/env bash

B058_EDITS=$(printf '%s\t%s\t%s\n' \
    'modules/mod-playerbots/src/Ai/Base/Actions/TradeStatusAction.cpp' \
    '    if (trader != master && traderIsGameClientPlayer &&' \
    '    if (trader != master && traderIsGameClientPlayer && !(bot->GetGuildId() && bot->GetGuildId() == trader->GetGuildId()) &&' \
    'modules/mod-playerbots/src/Ai/Base/Actions/TradeStatusAction.cpp' \
    '    if ((!bot->GetGroup() || !bot->GetGroup()->IsMember(trader->GetGUID())) &&' \
    '    if ((!bot->GetGroup() || !bot->GetGroup()->IsMember(trader->GetGUID())) && !(bot->GetGuildId() && bot->GetGuildId() == trader->GetGuildId()) &&')

patch_B058_bots_trade_with_their_guild() {
    line_edits_apply B058 <<< "${B058_EDITS}"
}

unpatch_B058_bots_trade_with_their_guild() {
    line_edits_revert B058 <<< "${B058_EDITS}"
}
