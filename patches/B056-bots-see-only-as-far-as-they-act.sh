#!/usr/bin/env bash
# B056 - Bots see only as far as they act
# Issue 194 (beta, 2026-10-20).
#
# For a general audience: the server decides, for every player, how far
# away it tells that player about creatures and other players (the map's
# visibility distance; a client draws only what it is told). To the server
# a bot is a player, so a long distance costs for every one of beta's 200
# bots too. wow-chat-1 let players see 333 yards on the continents; the
# owner, 2026-10-20: "Bots should only be able to see as far as the
# largest range they can see." So a bot's reach is capped at the largest
# distance the bot module ever looks or acts at, read from its own
# settings so the two never drift apart (the owner: "bot module's
# settings"), and real players keep the map's full distance. A real player
# still sees a bot out to the player's own distance: the viewer's reach
# decides.
#
# Which distances count: the ones that say how far a bot looks or acts
# (AiPlayerbot.SightDistance, ReactDistance, GrindDistance, RpgDistance,
# SpellDistance, HealDistance, FishingDistance, LootDistance,
# AggroDistance, FarDistance; with stock settings the largest is
# RpgDistance, 200 yards). Left out: WhisperDistance (a chat range),
# RandomBotTeleportDistance, GuildTaskKillTaskDistance and the small
# movement ones, which are not sight. Each is read with the bot module's
# own default, so a setting missing from playerbots.conf counts as the bot
# module would count it. Read once, the first time a bot's reach is asked
# (a config reload does not change it; a restart does).
#
# Where: Player::GetSightRange (src/server/game/Entities/Player/Player.cpp),
# which the server's visibility updates ask for each player. A bot is a
# player whose session is headless (WorldSession::IsHeadless, the core's
# own test, which the Lua engine's IsBot also uses). Only on the
# continents: on any instanced map (dungeons, raids, battlegrounds, arenas:
# Map::Instanceable) bots keep the stock distance too (the owner: "BGs and
# instances should have their stock distances"). That matters: a
# battleground's stock distance, 250 yards, is above the bots' 200, so a
# cap there would have shortened them. FindMap, not GetMap: a player
# between maps has none, and then nothing is capped.
#
# Mechanics: one exact whole-line edit (patches.sh, line_edits_apply /
# line_edits_revert), tagged "  // B056"; the revert turns back only the
# tagged line; an old line not found exactly once stops the patch as stale.
# Parallelizable: Yes

# path (from the source root) <TAB> old line <TAB> new line
B056_EDITS=$(printf '%s\t%s\t%s\n' \
    'src/server/game/Entities/Player/Player.cpp' \
    '    return sightRange;' \
    '    if (GetSession() && GetSession()->IsHeadless() && FindMap() && !FindMap()->Instanceable()) { static float const botReach = [] { float m = 0.0f; for (auto const& d : std::initializer_list<std::pair<char const*, float>>{ { "AiPlayerbot.SightDistance", 100.0f }, { "AiPlayerbot.ReactDistance", 150.0f }, { "AiPlayerbot.GrindDistance", 75.0f }, { "AiPlayerbot.RpgDistance", 200.0f }, { "AiPlayerbot.SpellDistance", 28.5f }, { "AiPlayerbot.HealDistance", 38.5f }, { "AiPlayerbot.FishingDistance", 40.0f }, { "AiPlayerbot.LootDistance", 15.0f }, { "AiPlayerbot.AggroDistance", 22.0f }, { "AiPlayerbot.FarDistance", 20.0f } }) m = std::max(m, sConfigMgr->GetOption<float>(d.first, d.second, false)); return m; }(); if (sightRange > botReach) sightRange = botReach; } return sightRange;')

# {{{ patch_B056_bots_see_only_as_far_as_they_act
patch_B056_bots_see_only_as_far_as_they_act() {
    line_edits_apply B056 <<< "${B056_EDITS}"
}
# }}}

# {{{ unpatch_B056_bots_see_only_as_far_as_they_act
unpatch_B056_bots_see_only_as_far_as_they_act() {
    line_edits_revert B056 <<< "${B056_EDITS}"
}
# }}}
