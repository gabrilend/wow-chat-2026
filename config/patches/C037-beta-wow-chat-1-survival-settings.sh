#!/usr/bin/env bash
# C037 - Beta: wow-chat-1's Survival Settings
# wow-chat-1 ran with about a hundred server settings tuned by hand; they
# were found in its old server folder on 2026-10-19 and laid out with the
# reasons in docs/wow-chat-1-settings.md (scripts/compare-wow-chat-1-settings).
# The owner, 2026-10-20: "in general the wow-chat-1 server settings should
# be applied to wow-chat style survival servers, and not to the ones that
# still have NPCs and such." Beta is that server: E012 takes every creature
# but the spirit healers out of its world. So beta takes them, with these
# owner's exceptions and these held for a decision:
#   kept at stock by the owner: MaxPrimaryTradeSkill (2: "professions we
#     should leave at 2 for now"), vmap.BlizzlikePvPLOS (battleground objects
#     still block sight: "that seems bad"), DBC.EnforceItemAttributes (the
#     client's own item data still wins)
#   held, each crossing something the project already does (see the doc):
#     PlayerLimit 100 (beta's 200 bots are players too), Rate.Talent (issue
#     205's Lua gives the points), Rate.MissChanceMultiplier.* (B005 already
#     caps the level gap), Visibility.Distance.Continents 333 (ten times the
#     area to track with 200 bots), Corpse.Decay.* (10-hour corpses beside
#     the ambush's dead), Guild.CharterCost (a "no guilds" switch never
#     decided), Warden.Enabled
#   handled elsewhere: Rate.MoveSpeed (C003), Rate.Damage.Fall (C004),
#     EnableLowLevelRegenBoost (C034)
# Rate.XP.Kill is 3 because beta has no quests (the owner: "for servers that
# don't have any quests ... we should have kill experience set to 3"); C005
# no longer covers beta.
#
# A key missing from the config stops the step with an error naming it,
# rather than leaving that setting at stock unnoticed. Values are written
# as wow-chat-1 had them.
# Profiles: beta

# -- {{{ the settings
# "key|value", in the doc's themes. Changing one: change it here and add a
# line to docs/balance-updates.md saying why.
C037_SETTINGS=(
    # 1. death and wear: dying costs nothing, fighting wears gear, repairs are the expense
    "DurabilityLoss.OnDeath|0"
    "DurabilityLossChance.Damage|3"
    "DurabilityLossChance.Absorb|5"
    "DurabilityLossChance.Parry|0.5"
    "DurabilityLossChance.Block|0.5"
    "Death.SicknessLevel|255"
    "Rate.RepairCost|25"
    # 2. money: loot sells for more, to pay for the repairs
    "Rate.SellValue.Item.Normal|2"
    "Rate.SellValue.Item.Uncommon|3"
    "Rate.SellValue.Item.Rare|4"
    "Rate.SellValue.Item.Epic|5"
    "Rate.SellValue.Item.Legendary|10"
    "Guild.AllowMultipleGuildMaster|1"
    "Guild.BankInitialTabs|1"
    # 3. levelling: kills (no quests on beta), wandering, resting, staying near your group
    "Rate.XP.Kill|3"
    "Rate.XP.Explore|10"
    "Rate.Rest.InGame|10"
    "Rate.Rest.Offline.InTavernOrCity|5"
    "MaxGroupXPDistance|148"
    "HonorPointsAfterDuel|10"
    # 4. professions: the count stays 2; prospecting and milling raise their skill
    "SkillChance.Prospecting|1"
    "SkillChance.Milling|1"
    # 5. creatures and the world's dangers
    "CreatureFamilyAssistanceRadius|30"
    "CreatureFamilyFleeAssistanceRadius|60"
    "WaterBreath.Timer|18000"
    # 6. groups, dungeons and quests: any level, any group size
    "Quests.IgnoreRaid|1"
    "Group.Raid.LevelRestriction|1"
    "Instance.IgnoreLevel|1"
    "Instance.IgnoreRaid|1"
    "DungeonAccessRequirements.PrintMode|2"
    "DungeonFinder.OptionsMask|0"
    "LFG.MaxKickCount|0"
    # 7. battlegrounds
    "Wintergrasp.Enable|2"
    "Battleground.CastDeserter|0"
    "Battleground.QueueAnnouncer.Enable|1"
    "Battleground.QueueAnnouncer.Limit.MinLevel|1"
    "Battleground.QueueAnnouncer.PlayerOnly|1"
    "Battleground.QueueAnnouncer.Timed|1"
    "Battleground.QueueAnnouncer.Timer|15000"
    "Battleground.PrematureFinishTimer|0"
    "Battleground.GiveXPForKills|1"
    "Battleground.InvitationType|2"
    "Battleground.PlayerRespawn|60"
    "Battleground.RestorationBuffRespawn|10"
    "Battleground.BerserkingBuffRespawn|10"
    "Battleground.SpeedBuffRespawn|10"
    # 8. both factions together (trade, mail, /who and friends are
    #    permissions in today's server, not settings: open question in the doc)
    "AllowTwoSide.Interaction.Calendar|1"
    "AllowTwoSide.Interaction.Chat|1"
    "AllowTwoSide.Interaction.Channel|1"
    "AllowTwoSide.Interaction.Group|1"
    "AllowTwoSide.Interaction.Guild|1"
    "AllowTwoSide.Interaction.Arena|1"
    "AllowTwoSide.Interaction.Auction|1"
    # 9. the server, names, and the world's look (no sparkles, marks or map points)
    "PreventAFKLogout|1"
    "GM.AllowInvite|1"
    "GM.AllowFriend|1"
    "GM.TicketSystem.ChanceOfGMSurvey|0"
    "Channel.SilentlyGMJoin|1"
    "StrictNames.Reserved|0"
    "StrictNames.Profanity|0"
    "StrictPlayerNames|1"
    "StrictPetNames|1"
    "StrictChannelNames|1"
    "StrictCharterNames|1"
    "ChatFakeMessagePreventing|0"
    "ChatStrictLinkChecking.Severity|-1"
    "Visibility.GroupMode|0"
    "Visibility.ObjectSparkles|0"
    "Visibility.ObjectQuestMarkers|0"
    "QuestPOI.Enabled|0"
)
# }}}

# -- {{{ config_beta_wow_chat_1_survival_settings
config_beta_wow_chat_1_survival_settings() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    local entry key value pattern missing=0
    for entry in "${C037_SETTINGS[@]}"; do
        key="${entry%%|*}"
        value="${entry#*|}"
        pattern="${key//./\\.}"
        if ! grep -qE "^${pattern}[[:space:]]*=" "${conf}"; then
            echo "    ERROR: C037 found no '${key}' line in ${conf}; it stays at stock"
            missing=$((missing + 1))
            continue
        fi
        sed -i "s|^${pattern}[[:space:]]*=.*|${key} = ${value}|" "${conf}"
    done
    if [[ ${missing} -gt 0 ]]; then
        echo "           to debug: grep -n '<key>' ${conf} - did upstream rename it? (${missing} of ${#C037_SETTINGS[@]} missing)"
        return 1
    fi
}
CONFIG_PROFILES[config_beta_wow_chat_1_survival_settings]="beta"
CONFIG_DESCRIPTIONS[config_beta_wow_chat_1_survival_settings]="wow-chat-1's survival settings (${#C037_SETTINGS[@]} values; docs/wow-chat-1-settings.md)"
# -- }}}
