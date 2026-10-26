
#include "buddies.h"
#include "buddies_roam.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"
#include "Formulas.h"
#include "Group.h"
#include "KillRewarder.h"
#include "ItemUsageValue.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "QuestDef.h"
#include "StatsWeightCalculator.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "WorldSession.h"
#include <string>
#include <vector>

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

static void GiveCompletedQuest(Player* buddy, std::string const& ownerName, Quest const* quest)
{
    uint32 id = quest->GetQuestId();
    if (buddy->GetQuestRewardStatus(id) && !quest->IsRepeatable())
        return;
    buddy->RewardQuest(quest, ChooseQuestReward(buddy, quest), buddy, false);

    uint32 spellId = quest->GetRewSpellCast() > 0 ? uint32(quest->GetRewSpellCast()) : quest->GetRewSpell();
    if (!spellId)
        return;
    SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
    if (!spellInfo)
    {
        LOG_ERROR("module", "mod-buddies: quest {} ({}) rewards spell {}, which the server doesn't know; buddy {} of {} got the rest of the reward",
            quest->GetQuestId(), quest->GetTitle(), spellId, buddy->GetName(), ownerName);
        return;
    }
    if (spellInfo->HasEffect(SPELL_EFFECT_LEARN_SPELL) || spellInfo->HasEffect(SPELL_EFFECT_CREATE_ITEM) || spellInfo->IsSelfCast())
        return;
    buddy->CastSpell(buddy, spellId, true);
}

static void CatchUpQuests(Player* buddy, uint32 ownerGuid)
{
    std::vector<uint32> ownerQuests;
    std::string ownerName = "owner " + std::to_string(ownerGuid);
    if (Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(ownerGuid)))
    {
        ownerName = owner->GetName();
        ownerQuests.assign(owner->getRewardedQuests().begin(), owner->getRewardedQuests().end());
    }
    else if (QueryResult rows = CharacterDatabase.Query("SELECT quest FROM character_queststatus_rewarded WHERE guid = {} AND active = 1", ownerGuid))
    {
        do
            ownerQuests.push_back(rows->Fetch()[0].Get<uint32>());
        while (rows->NextRow());
    }

    uint32 dropped = 0;
    for (uint16 slot = 0; slot < MAX_QUEST_LOG_SIZE; ++slot)
    {
        uint32 id = buddy->GetQuestSlotQuestId(slot);
        if (!id)
            continue;
        buddy->SetQuestSlot(slot, 0);
        buddy->RemoveActiveQuest(id, false);
        ++dropped;
    }

    uint32 given = 0, unknown = 0;
    for (uint32 id : ownerQuests)
    {
        if (buddy->GetQuestRewardStatus(id))
            continue;
        if (!sObjectMgr->GetQuestTemplate(id))
        {
            ++unknown;
            continue;
        }
        buddy->SetRewardedQuest(id);
        ++given;
    }

    if (given || dropped)
        LOG_INFO("module", "mod-buddies: {} caught up with {}'s quests at login: {} marked finished (progress only, no reward), {} dropped from its log",
            buddy->GetName(), ownerName, given, dropped);
    if (unknown)
        LOG_ERROR("module", "mod-buddies: {} catching up with {}: {} of the owner's finished quests are not in the world database's "
            "quest list (removed custom quests?); passed over", buddy->GetName(), ownerName, unknown);
}

class buddies_quests_player : public PlayerScript
{
public:
    buddies_quests_player() : PlayerScript("buddies_quests_player", { PLAYERHOOK_ON_PLAYER_COMPLETE_QUEST, PLAYERHOOK_ON_LOGIN }) { }

    void OnPlayerLogin(Player* player) override
    {
        if (!BuddiesEnabled())
            return;
        if (!BuddyIsNotAPlayer(player->GetSession()->GetAccountId()))
            return;
        uint32 guid = player->GetGUID().GetCounter();
        for (auto const& pair : BuddyRosterPairs())
            if (pair.first == guid)
            {
                CatchUpQuests(player, pair.second);
                return;
            }
    }

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
            GiveCompletedQuest(buddy, owner->GetName(), quest);
        }
    }
};

void AddSC_buddies_xp()
{
    new buddies_xp_player();
    new buddies_quests_player();
}
