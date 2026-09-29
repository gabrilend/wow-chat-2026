/*
 * buddies_xp.cpp - buddies don't make a group's experience bonus bigger
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
#include "DBCStores.h"
#include "Formulas.h"
#include "Group.h"
#include "KillRewarder.h"
#include "Map.h"
#include "Player.h"
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

// {{{ AddSC_buddies_xp
void AddSC_buddies_xp()
{
    new buddies_xp_player();
}
// }}}
