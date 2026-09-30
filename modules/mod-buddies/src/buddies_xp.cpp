/*
 * buddies_xp.cpp - how buddies level: they don't make a group's experience
 * bonus bigger, and they complete each quest their owner turns in (617d,
 * at the end of this file)
 * (issue 617c2).
 *
 * For a general audience: when a group kills something, the server shares
 * the kill's experience among the members standing near it, and adds a
 * bonus for grouping: the pool grows to x1.166 with three members near,
 * x1.3 with four, x1.4 with five or more. The owner (2026-09-27): "oh,
 * that's for getting human players to group up. We shouldn't apply it to
 * buddy-bots." So the bonus is worked out from the human players near the
 * kill only: buddies still take their share of the pool, but add nothing
 * to its size. A player alone with four buddies gets the pool of one
 * player (no bonus); two players with three buddies get the bonus for two
 * (x1.0 again: the stock bonus starts at three); a far party of buddies
 * alone gets none.
 *
 * How: the server calls a hook as it pays each member, with that member's
 * rate (the group bonus times the member's share by level). This file
 * scales the rate by (bonus for the humans near) / (bonus for everyone
 * near), counting "near" exactly as the server does (KillRewarder: alive,
 * and the killer or within the group reward distance of the victim).
 *
 * Left as stock:
 *   - battlegrounds: the server gives no group bonus there;
 *   - raid dungeons with a raid group: the server's bonus there is a flat
 *     x1.0 whatever the count, so there is nothing to take away;
 *   - kills of players: no experience either way;
 *   - a killer with no group: no bonus to begin with.
 */

#include "buddies.h"
#include "buddies_roam.h"          // BuddyRosterPairs
#include "DBCStores.h"
#include "Formulas.h"
#include "Group.h"
#include "KillRewarder.h"
#include "ItemUsageValue.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "QuestDef.h"
#include "StatsWeightCalculator.h"
#include "ScriptMgr.h"
#include "WorldSession.h"

class buddies_xp_player : public PlayerScript
{
public:
    buddies_xp_player() : PlayerScript("buddies_xp_player", { PLAYERHOOK_ON_REWARD_KILL_REWARDER }) { }

    // `rate` is this member's rate for this kill; changed in place.
    void OnPlayerRewardKillRewarder(Player* /*player*/, KillRewarder* rewarder, bool /*isDungeon*/, float& rate) override
    {
        if (!BuddiesEnabled())
            return;
        Player* killer = rewarder->GetKiller();
        Unit* victim = rewarder->GetVictim();
        if (!killer || !victim || victim->IsPlayer())
            return;                                    // a player killed: no experience to scale
        Group* group = killer->GetGroup();
        if (!group)
            return;                                    // no group, no bonus
        Map* map = killer->GetMap();
        if (!map || map->IsBattlegroundOrArena())
            return;                                    // battleground: the server adds no bonus there
        MapEntry const* entry = sMapStore.LookupEntry(killer->GetMapId());
        bool raidRate = entry && entry->IsRaid() && group->isRaidGroup();
        if (raidRate)
            return;                                    // raid dungeon: the server's bonus is a flat x1.0

        // Count who the server counted: alive, and the killer or within the
        // group reward distance of the victim.
        uint32 all = 0, humans = 0;
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        {
            Player* member = ref->GetSource();
            if (!member || !member->IsAlive())
                continue;
            if (member != killer && !member->IsAtGroupRewardDistance(victim))
                continue;
            ++all;
            if (!BuddyIsCompanionAccount(member->GetSession()->GetAccountId()))
                ++humans;
        }
        if (all == 0 || humans == all)
            return;                                    // nobody counted, or no buddies near: stock bonus stands

        float bonusAll    = Acore::XP::xp_in_group_rate(all, false);
        float bonusHumans = Acore::XP::xp_in_group_rate(humans, false);   // 0 or 1 human: x1.0
        rate *= bonusHumans / bonusAll;
    }
};

// {{{ quests: a buddy completes each quest its owner turns in (617d)
// The owner, 2026-09-23: "They instantly receive every quest that you do
// and complete it automatically whenever you do"; 2026-09-27: "we also
// don't need to track quest progress for bots - it is irrelevant. They get
// a completed quest when you turn yours in"; 2026-09-29: "we're going to
// auto-complete buddy quests to ensure they level up alongside you". So a
// buddy never carries its owner's quests: when the owner turns one in,
// each of the owner's buddies in the world is given the quest, has it
// completed and is rewarded, all at once, through the server's own quest
// steps (so experience, money, reputation and follow-up quests work as for
// anyone). Rules and requirements (level, class, race, earlier quests) are
// not checked: the owner earned it for the clan.
//
// A choice of reward is made the way every bot of the bot module makes it
// (TalkToQuestGiverAction's BestRewards, written out here since it is
// private there): the choices ranked by use, an upgrade it can equip over
// gear it could wear over anything merely usable; among the best-ranked,
// the highest score by the bot's stat weights.

// {{{ ChooseQuestReward
static uint32 ChooseQuestReward(Player* buddy, Quest const* quest)
{
    uint32 n = quest->GetRewChoiceItemsCount();
    if (n <= 1)
        return 0;                                      // no choice, or only one
    PlayerbotAI* ai = GET_PLAYERBOT_AI(buddy);
    if (!ai)
        return 0;                                      // not driven by the bot module: the first
    AiObjectContext* context = ai->GetAiObjectContext();
    ItemUsage bestUsage = ITEM_USAGE_NONE;
    for (uint32 i = 0; i < n; ++i)
    {
        ItemUsage usage = context->GetValue<ItemUsage>("item usage", quest->RewardChoiceItemId[i])->Get();
        if (usage == ITEM_USAGE_EQUIP || usage == ITEM_USAGE_REPLACE)
            bestUsage = ITEM_USAGE_EQUIP;              // an upgrade it can wear: best
        else if (usage == ITEM_USAGE_BAD_EQUIP && bestUsage != ITEM_USAGE_EQUIP)
            bestUsage = usage;                         // wearable, not better
        else if (usage != ITEM_USAGE_NONE && bestUsage == ITEM_USAGE_NONE)
            bestUsage = usage;                         // usable some other way
    }
    StatsWeightCalculator calc(buddy);
    uint32 best = 0;
    float bestScore = 0.0f;
    for (uint32 i = 0; i < n; ++i)
    {
        ItemUsage usage = context->GetValue<ItemUsage>("item usage", quest->RewardChoiceItemId[i])->Get();
        if (usage != bestUsage && usage != ITEM_USAGE_REPLACE)
            continue;
        float score = calc.CalculateItem(quest->RewardChoiceItemId[i]);
        if (score > bestScore)
            bestScore = score, best = i;
    }
    return best;
}
// }}}

// {{{ GiveCompletedQuest
static void GiveCompletedQuest(Player* buddy, Player* owner, Quest const* quest)
{
    uint32 id = quest->GetQuestId();
    if (buddy->GetQuestRewardStatus(id) && !quest->IsRepeatable())
        return;                                        // done before (not a repeatable one): nothing to give
    if (buddy->GetQuestStatus(id) == QUEST_STATUS_NONE || buddy->GetQuestStatus(id) == QUEST_STATUS_REWARDED)
    {
        if (buddy->FindQuestSlot(0) >= MAX_QUEST_LOG_SIZE)
        {
            LOG_ERROR("module", "mod-buddies: buddy {} of {} can't take quest {} ({}): its quest log is full; no reward",
                buddy->GetName(), owner->GetName(), id, quest->GetTitle());
            return;
        }
        buddy->AddQuest(quest, nullptr);
    }
    buddy->CompleteQuest(id);
    uint32 reward = ChooseQuestReward(buddy, quest);
    if (!buddy->CanRewardQuest(quest, reward, false))
    {
        // no room in its bags for the reward, most likely: the quest is
        // taken back out of its log rather than left there, never turned in
        LOG_ERROR("module", "mod-buddies: buddy {} of {} can't be rewarded for quest {} ({}) (bags full?); quest removed, no reward",
            buddy->GetName(), owner->GetName(), id, quest->GetTitle());
        buddy->RemoveActiveQuest(id);
        return;
    }
    buddy->RewardQuest(quest, reward, nullptr, false);
}
// }}}

class buddies_quests_player : public PlayerScript
{
public:
    buddies_quests_player() : PlayerScript("buddies_quests_player", { PLAYERHOOK_ON_PLAYER_COMPLETE_QUEST }) { }

    // Called at the end of the server's quest reward step, for anyone.
    void OnPlayerCompleteQuest(Player* owner, Quest const* quest) override
    {
        if (!BuddiesEnabled() || !quest)
            return;
        if (BuddyIsCompanionAccount(owner->GetSession()->GetAccountId()))
            return;                                    // a buddy's own reward (from here): not passed on again
        uint32 ownerGuid = owner->GetGUID().GetCounter();
        for (auto const& pair : BuddyRosterPairs())
        {
            if (pair.second != ownerGuid)
                continue;
            Player* buddy = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(pair.first));
            if (!buddy || !buddy->IsInWorld())
                continue;                              // buddies log in with their owner (617c1); one still arriving misses it
            GiveCompletedQuest(buddy, owner, quest);
        }
    }
};
// }}}

// {{{ AddSC_buddies_xp
void AddSC_buddies_xp()
{
    new buddies_xp_player();
    new buddies_quests_player();                       // 617d, above
}
// }}}
