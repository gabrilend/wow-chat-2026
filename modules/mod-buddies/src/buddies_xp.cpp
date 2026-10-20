
#include "buddies.h"
#include "buddies_roam.h"
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

    void OnPlayerRewardKillRewarder(Player* , KillRewarder* rewarder, bool , float& rate) override
    {
        if (!BuddiesEnabled())
            return;
        Player* killer = rewarder->GetKiller();
        Unit* victim = rewarder->GetVictim();
        if (!killer || !victim || victim->IsPlayer())
            return;
        Group* group = killer->GetGroup();
        if (!group)
            return;
        Map* map = killer->GetMap();
        if (!map || map->IsBattlegroundOrArena())
            return;
        MapEntry const* entry = sMapStore.LookupEntry(killer->GetMapId());
        bool raidRate = entry && entry->IsRaid() && group->isRaidGroup();
        if (raidRate)
            return;

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
            return;

        float bonusAll    = Acore::XP::xp_in_group_rate(all, false);
        float bonusHumans = Acore::XP::xp_in_group_rate(humans, false);
        rate *= bonusHumans / bonusAll;
    }
};


static uint32 ChooseQuestReward(Player* buddy, Quest const* quest)
{
    uint32 n = quest->GetRewChoiceItemsCount();
    if (n <= 1)
        return 0;
    PlayerbotAI* ai = GET_PLAYERBOT_AI(buddy);
    if (!ai)
        return 0;
    AiObjectContext* context = ai->GetAiObjectContext();
    ItemUsage bestUsage = ITEM_USAGE_NONE;
    for (uint32 i = 0; i < n; ++i)
    {
        ItemUsage usage = context->GetValue<ItemUsage>("item usage", quest->RewardChoiceItemId[i])->Get();
        if (usage == ITEM_USAGE_EQUIP || usage == ITEM_USAGE_REPLACE)
            bestUsage = ITEM_USAGE_EQUIP;
        else if (usage == ITEM_USAGE_BAD_EQUIP && bestUsage != ITEM_USAGE_EQUIP)
            bestUsage = usage;
        else if (usage != ITEM_USAGE_NONE && bestUsage == ITEM_USAGE_NONE)
            bestUsage = usage;
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

static void GiveCompletedQuest(Player* buddy, Player* owner, Quest const* quest)
{
    uint32 id = quest->GetQuestId();
    if (buddy->GetQuestRewardStatus(id) && !quest->IsRepeatable())
        return;
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
    buddy->RewardQuest(quest, ChooseQuestReward(buddy, quest), nullptr, false);
}

class buddies_quests_player : public PlayerScript
{
public:
    buddies_quests_player() : PlayerScript("buddies_quests_player", { PLAYERHOOK_ON_PLAYER_COMPLETE_QUEST }) { }

    void OnPlayerCompleteQuest(Player* owner, Quest const* quest) override
    {
        if (!BuddiesEnabled() || !quest)
            return;
        if (BuddyIsNotAPlayer(owner->GetSession()->GetAccountId()))
            return;
        uint32 ownerGuid = owner->GetGUID().GetCounter();
        for (auto const& pair : BuddyRosterPairs())
        {
            if (pair.second != ownerGuid)
                continue;
            Player* buddy = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(pair.first));
            if (!buddy || !buddy->IsInWorld())
                continue;
            GiveCompletedQuest(buddy, owner, quest);
        }
    }
};

void AddSC_buddies_xp()
{
    new buddies_xp_player();
    new buddies_quests_player();
}
