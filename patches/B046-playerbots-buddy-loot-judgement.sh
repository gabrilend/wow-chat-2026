#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         B046
# profiles:   buddy-set
# priority:   560
# kind:       source
# about:      Playerbots: buddies judge gear by their own talent plan and roll
# ==== end of header ====
# B046 - Playerbots: buddies judge gear by their own talent plan and roll
# by their clan's rules
# Issue 617j (basic, 2026-10-02).
#
# For a general audience: the bot module decides whether an item is better
# than what a bot wears by scoring both with stat weights for the bot's
# main talent tree, and it rolls need or greed on group loot from that
# judgement. Buddies follow talent plans that split their points across
# trees (two thirds in one, a third in another; or a third in each), so
# scoring by one tree misjudges them; and the owner wants buddies to roll
# by rules of their own (a "thirds" buddy greeds upgrades unless its gear
# is below its clan's average, then needs them; class books go to the
# owner first). The module stays the owner of every decision about bots
# in general; this patch only gives the buddy module (modules/mod-buddies,
# buddies_loot.cpp) two chances to answer for buddies:
#
#   1. The stat-weight scorer asks the buddy module first whether the
#      player is a buddy and, if so, its plan's share of points per tree.
#      A buddy's score is then each such tree's score weighted by its
#      share; anyone else gets the stock score. Every place the bot
#      module scores an item -- equipping upgrades from loot, trades and
#      mail, quest reward choices, need-or-greed -- goes through this one
#      scorer, so they all agree. The scorer also gains a way to be told
#      "score as this talent tree", which the blend uses for each tree.
#   2. The loot roll asks the buddy module for the final vote, given the
#      bot module's own judgement before and after its config switches
#      (basic's config turns need into greed and greed into pass for bots
#      in general). Anyone not a buddy keeps the stock vote.
#
# Both questions are declared here and answered in the buddy module, so
# this patch needs B036 (the module copied into the build): without it the
# server fails to link, which says loudly what is missing.
#
# Mechanics: pure insertions between ">>> B046-buddy-loot-judgement BEGIN"
# / "<<< ... END" marker comments, beside anchors that must each occur
# exactly once (else the patch stops); the revert deletes the blocks.
# Parallelizable: Yes (StatsWeightCalculator.h/.cpp and LootRollAction.cpp
# are touched by no other basic B-patch)

B046_TAG='B046-buddy-loot-judgement'
B046_H_PUBLIC='    void SetExcludeResilience(bool exclude) { exclude_resilience_ = exclude; }'
B046_H_PRIVATE='    bool exclude_resilience_ = false;'
B046_CPP_INCLUDE='#include "Unit.h"'
B046_CPP_SCORE='    ItemTemplate const* proto = &sObjectMgr->GetItemTemplateStore()->at(itemId);'
B046_CPP_RESET='void StatsWeightCalculator::Reset()'
B046_ROLL_INCLUDE='#include "Playerbots.h"'
B046_ROLL_BEFORE='        if (vote == NEED)'
B046_ROLL_AFTER='        switch (group->GetLootMethod())'

# {{{ b046_insert
# Insert the lines of $3 after (where=after) or before (where=before) the
# one line equal to $2 in file $1. Stops if the anchor is not there exactly
# once.
b046_insert() {
    local file="$1" anchor="$2" block="$3" where="$4"
    local count
    count=$(grep -cxF -- "${anchor}" "${file}")
    if [[ "${count}" -ne 1 ]]; then
        echo "  [B046] ERROR: expected exactly one '${anchor}' in ${file}, found ${count}"
        return 1
    fi
    ANCHOR="${anchor}" BLOCK="${block}" WHERE="${where}" awk '
        $0 == ENVIRON["ANCHOR"] && ENVIRON["WHERE"] == "before" { print ENVIRON["BLOCK"] }
        { print }
        $0 == ENVIRON["ANCHOR"] && ENVIRON["WHERE"] == "after" { print ENVIRON["BLOCK"] }' \
        "${file}" > "${file}.b046" && mv "${file}.b046" "${file}"
}
# }}}

# {{{ patch_B046_playerbots_buddy_loot_judgement
patch_B046_playerbots_buddy_loot_judgement() {
    local SRC="${AC_CODE_DIR}/modules/mod-playerbots/src"
    local H="${SRC}/Mgr/Item/StatsWeightCalculator.h"
    local CPP="${SRC}/Mgr/Item/StatsWeightCalculator.cpp"
    local ROLL="${SRC}/Ai/Base/Actions/LootRollAction.cpp"
    local f
    for f in "${H}" "${CPP}" "${ROLL}"; do
        [[ -f "${f}" ]] || { echo "  [B046] ERROR: ${f} missing"; return 1; }
    done
    grep -qF "${B046_TAG}" "${ROLL}" && return 0                 # witness guard

    # -- the scorer: "score as this tree" ------------------------------------
    b046_insert "${H}" "${B046_H_PUBLIC}" \
"    // >>> ${B046_TAG} BEGIN
    // Score as if the player's main talent tree were \`specTab\` (0-2, left to
    // right) with stats collected as \`collectorType\`; also stops this
    // scorer asking the buddy module (mod-buddies, buddies_loot.cpp), which
    // uses it to score each tree of a buddy's plan.
    void SetSpecTab(int specTab, CollectorType collectorType);
    // <<< ${B046_TAG} END" after || return 1

    b046_insert "${H}" "${B046_H_PRIVATE}" \
"    // >>> ${B046_TAG} BEGIN
    bool specOverridden_ = false;
    // <<< ${B046_TAG} END" after || return 1

    b046_insert "${CPP}" "${B046_CPP_INCLUDE}" \
"// >>> ${B046_TAG} BEGIN
// Answered by the buddy module (mod-buddies, buddies_loot.cpp): true when
// \`player\` is a buddy with a chosen talent plan, with \`thirds\` its
// points per tree in thirds (left to right, summing to 3) and \`types\`
// how each tree collects stats; false for anyone else (scored as stock).
bool BuddyTalentPlan(Player* player, uint8 (&thirds)[3], CollectorType (&types)[3]);
// <<< ${B046_TAG} END" after || return 1

    b046_insert "${CPP}" "${B046_CPP_SCORE}" \
"    // >>> ${B046_TAG} BEGIN
    // A buddy is scored by its talent plan (617j): each tree it spends in
    // scores the item as that tree would, weighted by its share of the
    // points (2/3 + 1/3, or a third each). The parts keep this scorer's
    // switches. A scorer told its tree (SetSpecTab) is such a part, and
    // scores as stock.
    if (!specOverridden_)
    {
        uint8         thirds[3] = { 0, 0, 0 };
        CollectorType types[3]  = { CollectorType::MELEE_DMG, CollectorType::MELEE_DMG, CollectorType::MELEE_DMG };
        if (BuddyTalentPlan(player_, thirds, types))
        {
            float blended = 0.0f;
            for (int t = 0; t < 3; ++t)
            {
                if (thirds[t] == 0)
                    continue;                          // no points in this tree: no say
                StatsWeightCalculator part(player_);
                part.SetSpecTab(t, types[t]);
                part.enable_overflow_penalty_ = enable_overflow_penalty_;
                part.enable_item_set_bonus_   = enable_item_set_bonus_;
                // (quality blend: gone upstream since playerbots 05473d62, 2026-09-18,
                // "score item by stats only"; nothing to copy)
                part.pvpSpec_                 = pvpSpec_;
                part.exclude_resilience_      = exclude_resilience_;
                blended += float(thirds[t]) / 3.0f * part.CalculateItem(itemId, randomPropertyIds, slot);
            }
            return blended;
        }
    }
    // <<< ${B046_TAG} END" before || return 1

    b046_insert "${CPP}" "${B046_CPP_RESET}" \
"// >>> ${B046_TAG} BEGIN
// The constructor's choices, made for a named tree instead of the main one.
void StatsWeightCalculator::SetSpecTab(int specTab, CollectorType collectorType)
{
    specOverridden_ = true;
    tab             = specTab;
    type_           = collectorType;
    collector_      = std::make_unique<StatsCollector>(type_, cls);

    if (cls == CLASS_DEATH_KNIGHT && tab == DEATH_KNIGHT_TAB_UNHOLY)
        hitOverflowType_ = CollectorType::SPELL;
    else if (cls == CLASS_SHAMAN && tab == SHAMAN_TAB_ENHANCEMENT)
        hitOverflowType_ = CollectorType::SPELL;
    else if (cls == CLASS_ROGUE)
        hitOverflowType_ = CollectorType::SPELL;
    else
        hitOverflowType_ = type_;
}
// <<< ${B046_TAG} END" before || return 1

    # -- the roll: the buddy module has the last word for buddies ------------
    b046_insert "${ROLL}" "${B046_ROLL_INCLUDE}" \
"// >>> ${B046_TAG} BEGIN
// Answered by the buddy module (mod-buddies, buddies_loot.cpp): the vote a
// bot casts. \`judged\` is this action's own judgement before the config's
// need/greed switches, \`configured\` after them; anyone not a buddy gets
// \`configured\` back unchanged.
RollVote BuddyLootRollVote(Player* bot, ItemTemplate const* proto, int32 randomProperty, RollVote judged, RollVote configured);
// <<< ${B046_TAG} END" after || return 1

    b046_insert "${ROLL}" "${B046_ROLL_BEFORE}" \
"        // >>> ${B046_TAG} BEGIN
        RollVote const b046Judged = vote;
        // <<< ${B046_TAG} END" before || return 1

    b046_insert "${ROLL}" "${B046_ROLL_AFTER}" \
"        // >>> ${B046_TAG} BEGIN
        vote = BuddyLootRollVote(bot, proto, randomProperty, b046Judged, vote);
        // <<< ${B046_TAG} END" before || return 1

    echo "  [B046] Playerbots: buddies score gear by their talent plan and roll by their clan's rules"
}
# }}}

# {{{ unpatch_B046_playerbots_buddy_loot_judgement
unpatch_B046_playerbots_buddy_loot_judgement() {
    local SRC="${AC_CODE_DIR}/modules/mod-playerbots/src"
    local f
    for f in "${SRC}/Mgr/Item/StatsWeightCalculator.h" "${SRC}/Mgr/Item/StatsWeightCalculator.cpp" \
             "${SRC}/Ai/Base/Actions/LootRollAction.cpp"; do
        [[ -f "${f}" ]] || continue
        grep -qF "B046-buddy-loot-judgement" "${f}" || continue     # nothing of ours
        awk '
            /\/\/ >>> B046-buddy-loot-judgement BEGIN/ { inblock = 1; next }
            inblock && /\/\/ <<< B046-buddy-loot-judgement END/ { inblock = 0; next }
            inblock { next }
            { print }' "${f}" > "${f}.b046" && mv "${f}.b046" "${f}"
    done
    return 0
}
# }}}
# ==== footer of B046 ====
# lines:      211
# ==== end of footer ====
