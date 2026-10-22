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
static void GiveCompletedQuest(Player* buddy, std::string const& ownerName, Quest const* quest)
{
    uint32 id = quest->GetQuestId();
    if (buddy->GetQuestRewardStatus(id) && !quest->IsRepeatable())
        return;                                        // done before (not a repeatable one): nothing to give
    // No quest log: a buddy never holds a quest (the owner, 2026-10-22:
    // "buddies should never have quests. They should have perfectly synced
    // quest progress with the player"). The reward step works from the
    // quest alone: it clears a log slot only if the quest has one, and
    // drops the quest from the active ones only if it is there
    // (Player::RewardQuest, Player::RemoveActiveQuest). Until 2026-10-22
    // the quest was taken into the log and completed first, and a buddy
    // with a full log got nothing.
    // No bag check first: the server's reward step mails whatever doesn't
    // fit (its own "items that couldn't be added" mail), and the buddy
    // collects it at a mailbox on its next town visit (buddies_town.cpp,
    // the mail errand; owner, 2026-09-29: "for full bags, can you mail
    // them the item instead? make sure they actually check their mail").
    //
    // The quest giver passed is the buddy itself, never nothing: the
    // server's reward step reads the quest giver without checking it when
    // the quest's reward includes a spell (PlayerQuest.cpp, the reward-spell
    // step, "questGiver->IsUnit()"). Until 2026-10-22 this passed nothing,
    // and the worldserver crashed the moment an owner turned in such a quest
    // with a buddy beside it (Glowsticks, "A Fistful of Slivers", reward
    // spell 24829: "I was just completing a quest on Glowsticks and the
    // server crashed").
    // The reward step uses the giver in three places (checked 2026-10-22,
    // PlayerQuest.cpp): a quest's follow-up letter names it as the sender
    // (Mail.cpp builds a sender from a player too, as from a creature: the
    // letter reads as from the buddy; with nothing passed, that crashed as
    // well), and the two reward-spell paths. The Lua engine's own "reward
    // quest" passes the player itself the same way (PlayerMethods.h), and the
    // death knight skip rewarded 46 quests on Gabrubre through it.
    // With the buddy as giver, the step's two spell paths go:
    //   - a spell that teaches or makes something, or is cast on oneself:
    //     the buddy casts it on itself, as for a player;
    //   - any other (a quest giver's blessing on the hero): the step looks
    //     for a creature with the buddy's id, finds none, and casts nothing,
    //     so the buddy casts it on itself just below.
    buddy->RewardQuest(quest, ChooseQuestReward(buddy, quest), buddy, false);

    uint32 spellId = quest->GetRewSpellCast() > 0 ? uint32(quest->GetRewSpellCast()) : quest->GetRewSpell();
    if (!spellId)
        return;                                        // no reward spell
    SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
    if (!spellInfo)
    {
        LOG_ERROR("module", "mod-buddies: quest {} ({}) rewards spell {}, which the server doesn't know; buddy {} of {} got the rest of the reward",
            quest->GetQuestId(), quest->GetTitle(), spellId, buddy->GetName(), ownerName);
        return;
    }
    if (spellInfo->HasEffect(SPELL_EFFECT_LEARN_SPELL) || spellInfo->HasEffect(SPELL_EFFECT_CREATE_ITEM) || spellInfo->IsSelfCast())
        return;                                        // the reward step cast it already (the first path above)
    buddy->CastSpell(buddy, spellId, true);            // the giver's blessing, from itself
}
// }}}

// {{{ CatchUpQuests
// At a buddy's login: its finished quests made its owner's (617d; the
// owner, 2026-10-22: "buddies should never have quests. They should have
// perfectly synced quest progress with the player"). A buddy offline when
// its owner turned a quest in (set aside, logged out, still arriving) has
// it marked finished now: progress only, no reward (no items, money,
// experience or blessing). Why not the rewards: a buddy made today, at its
// owner's level, logs in lacking every quest its owner ever did, and paying
// them all would flood it with mail and gold, and experience past its
// owner (a buddy's level is the buddy module's own matter, 617a6). A
// buddy in the world at the turn-in still gets the reward (above). Open in
// 617d: whether a buddy that was only briefly away should be paid. A quest
// the buddy has finished and the owner hasn't (from before this rule)
// stays: a reward can't be taken back cleanly. And any quest in the
// buddy's log is dropped: a buddy never holds one.
static void CatchUpQuests(Player* buddy, uint32 ownerGuid)
{
    // the owner's finished quests: from the owner itself when it is online
    // (the database only has them as of its last save), else the database
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

    // a buddy never holds a quest: anything in its log goes (no reward)
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

    // the owner's quests it lacks, marked finished (saved with the buddy's
    // next save, as any finished quest)
    uint32 given = 0, unknown = 0;
    for (uint32 id : ownerQuests)
    {
        if (buddy->GetQuestRewardStatus(id))
            continue;                                  // finished already
        if (!sObjectMgr->GetQuestTemplate(id))
        {
            ++unknown;                                 // a quest the server no longer has (a removed custom one)
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
// }}}

class buddies_quests_player : public PlayerScript
{
public:
    buddies_quests_player() : PlayerScript("buddies_quests_player", { PLAYERHOOK_ON_PLAYER_COMPLETE_QUEST, PLAYERHOOK_ON_LOGIN }) { }

    // A buddy logging in catches up with its owner's quests (617d).
    void OnPlayerLogin(Player* player) override
    {
        if (!BuddiesEnabled())
            return;
        if (!BuddyIsNotAPlayer(player->GetSession()->GetAccountId()))
            return;                                    // a player, not a buddy
        uint32 guid = player->GetGUID().GetCounter();
        for (auto const& pair : BuddyRosterPairs())
            if (pair.first == guid)
            {
                CatchUpQuests(player, pair.second);
                return;
            }
        // a buddy account's character with no roster row (a stand-in, or a
        // bot of another kind): nothing to catch up with
    }

    // Called at the end of the server's quest reward step, for anyone.
    void OnPlayerCompleteQuest(Player* owner, Quest const* quest) override
    {
        if (!BuddiesEnabled() || !quest)
            return;
        if (BuddyIsNotAPlayer(owner->GetSession()->GetAccountId()))
            return;                                    // a buddy's own reward (from here): not passed on again
        uint32 ownerGuid = owner->GetGUID().GetCounter();
        for (auto const& pair : BuddyRosterPairs())
        {
            if (pair.second != ownerGuid)
                continue;
            Player* buddy = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(pair.first));
            if (!buddy || !buddy->IsInWorld())
                continue;                              // not in the world: it catches up at its login (CatchUpQuests)
            GiveCompletedQuest(buddy, owner->GetName(), quest);
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
