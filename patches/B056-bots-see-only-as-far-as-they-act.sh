#!/usr/bin/env bash

B056_EDITS=$(printf '%s\t%s\t%s\n' \
    'src/server/game/Entities/Player/Player.cpp' \
    '    return sightRange;' \
    '    if (GetSession() && GetSession()->IsHeadless()) { static float const botReach = [] { float m = 0.0f; for (auto const& d : std::initializer_list<std::pair<char const*, float>>{ { "AiPlayerbot.SightDistance", 100.0f }, { "AiPlayerbot.ReactDistance", 150.0f }, { "AiPlayerbot.GrindDistance", 75.0f }, { "AiPlayerbot.RpgDistance", 200.0f }, { "AiPlayerbot.SpellDistance", 28.5f }, { "AiPlayerbot.HealDistance", 38.5f }, { "AiPlayerbot.FishingDistance", 40.0f }, { "AiPlayerbot.LootDistance", 15.0f }, { "AiPlayerbot.AggroDistance", 22.0f }, { "AiPlayerbot.FarDistance", 20.0f } }) m = std::max(m, sConfigMgr->GetOption<float>(d.first, d.second, false)); return m; }(); if (sightRange > botReach) sightRange = botReach; } return sightRange;')

patch_B056_bots_see_only_as_far_as_they_act() {
    line_edits_apply B056 <<< "${B056_EDITS}"
}

unpatch_B056_bots_see_only_as_far_as_they_act() {
    line_edits_revert B056 <<< "${B056_EDITS}"
}
