/*
 * buddies_party.cpp - buddies group by distance from their owner (issue
 * 617c2).
 *
 * For a general audience: buddies don't stay near their player; they roam
 * the area (617e). Kill experience is shared only inside a group, and only
 * with members within 74 yards of the kill. So groups follow distance
 * (the owner, 2026-09-27):
 *   - a buddy in the owner's group that wanders past 75 yards leaves it
 *     (only one this pass seated: one the owner invited by hand stays,
 *     here and in towns; owner, 2026-09-29);
 *   - a buddy nearer than 60 yards joins the owner's group if it has room
 *     ("I think 60 yards is the farthest a buff spell can go");
 *   - buddies farther than 74 yards group with each other ("if some buddy
 *     bots are far from the player but in the same area, they should join a
 *     group with each other so they share exp"), and leave that group once
 *     within 74 yards of the owner.
 * Between 60 and 74 yards (or nearer with the owner's group full) a buddy
 * is in no group; the gaps stop a buddy on a boundary from flickering in
 * and out. Far parties are made of buddies near each other (the owner,
 * 2026-09-27: "within 70 yards, leaving at 74. It's okay if they flicker a
 * bit more"): a far buddy joins a far party one of whose members is within
 * 70 yards of it, or pairs up with another loose far buddy within 70; two
 * far parties merge when a member of one is within 70 yards of a member of
 * the other and together they fit in five; a far-party buddy more than 74
 * yards from every other member leaves it.
 *
 * Nothing is done in a dungeon, raid or battleground: the dungeon draw
 * (617c3) will decide those. In a town every buddy is ungrouped (617c,
 * 617e4: "When you're in a town or a city, you should be un-grouped with
 * them too"); grouping by distance resumes when the owner leaves.
 *
 * At login the bot module used to add every buddy to its owner's group,
 * turning it into a raid past five; on basic that invite is switched off
 * (source patch B037, config C030, 2026-09-27: "we can probably remove the
 * playerbots buddy-group-up-at-login functions"). A raid made only of the
 * owner and their own buddies is still broken up here if one appears (an
 * install without C030, or an owner who invited them all by hand), and the
 * pass then groups them by distance. A raid with anyone else in it is the
 * owner's own and is left alone.
 */

#include "buddies.h"
#include "buddies_roam.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Group.h"
#include "GroupMgr.h"
#include "Log.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include <algorithm>
#include <map>
#include <mutex>
#include <set>
#include <string>
#include <vector>

// {{{ tuning (the owner's numbers, docs/balance-updates.md)
static constexpr float  JOIN_OWNER_YARDS  = 60.0f;  // an ungrouped buddy this near joins the owner's group
static constexpr float  LEAVE_OWNER_YARDS = 75.0f;  // a buddy in the owner's group this far leaves it
static constexpr float  FAR_YARDS         = 74.0f;  // beyond this a buddy belongs in a far party; within, it leaves one
static constexpr float  FAR_JOIN_YARDS    = 70.0f;  // far buddies / far parties this near each other join or merge
static constexpr float  FAR_LEAVE_YARDS   = 74.0f;  // a far-party buddy this far from every other member leaves
static constexpr uint32 PARTY_SIZE        = 5;
static constexpr uint32 PASS_EVERY_MS     = 5000;
// }}}

// Buddies this pass seated in their owner's party. Only these are ever
// taken out of it again (past 75 yards, or in a town): a buddy the owner
// invited by hand stays until the owner removes it (owner, 2026-09-29:
// "buddies shouldn't leave manually-invited groups"). Kept in memory, so
// after a server restart a buddy still in its owner's party counts as
// invited by hand and stays; the owner can remove it.
static std::set<uint32> sSeatedByPass;

// {{{ IsFarParty
// A group whose every member is one of this owner's buddies. Any other
// group a buddy is in (the owner's, or someone else's) is not ours to
// reshape here.
static bool IsFarParty(Group* group, std::set<uint32> const& buddies)
{
    for (auto const& slot : group->GetMemberSlots())
        if (!buddies.count(slot.guid.GetCounter()))
            return false;
    return true;
}
// }}}

// {{{ IsOwnersBuddyRaid
// The raid the bot module makes at login: the owner and only the owner's
// buddies.
static bool IsOwnersBuddyRaid(Group* group, Player* owner, std::set<uint32> const& buddies)
{
    if (!group->isRaidGroup())
        return false;
    for (auto const& slot : group->GetMemberSlots())
        if (slot.guid != owner->GetGUID() && !buddies.count(slot.guid.GetCounter()))
            return false;
    return true;
}
// }}}

// {{{ NearAnyMember
// Whether `bot` is within `yards` of some other online member of `group` on
// its map (the far parties' "near each other" rule).
static bool NearAnyMember(Player* bot, Group* group, float yards)
{
    for (auto const& slot : group->GetMemberSlots())
    {
        if (slot.guid == bot->GetGUID())
            continue;
        Player* other = ObjectAccessor::FindConnectedPlayer(slot.guid);
        if (other && other->IsInWorld() && other->GetMapId() == bot->GetMapId() && bot->GetExactDist(other) <= yards)
            return true;
    }
    return false;
}
// }}}

// {{{ PartiesNear
// Whether some member of `a` is within `yards` of some member of `b`.
static bool PartiesNear(Group* a, Group* b, float yards)
{
    for (auto const& slot : a->GetMemberSlots())
    {
        Player* p = ObjectAccessor::FindConnectedPlayer(slot.guid);
        if (p && p->IsInWorld() && NearAnyMember(p, b, yards))
            return true;
    }
    return false;
}
// }}}

// {{{ NewParty
// A new party led by `leader`, the way the bot module's own group
// operation makes one (Group::Create, then the group manager). Null (and
// logged) when the server refuses.
static Group* NewParty(Player* leader)
{
    Group* group = new Group;
    if (!group->Create(leader))
    {
        delete group;
        LOG_ERROR("module", "mod-buddies: could not create a party led by {}; no party made this pass", leader->GetName());
        return nullptr;
    }
    sGroupMgr->AddGroup(group);
    return group;
}
// }}}

// {{{ ArrangeOwner
// One owner's buddies put in the right groups by distance.
struct Near { Player* bot; float yards; };

static void ArrangeOwner(Player* owner, std::vector<uint32> const& buddyGuids)
{
    std::set<uint32> buddySet(buddyGuids.begin(), buddyGuids.end());

    Group* ownerGroup = owner->GetGroup();
    if (ownerGroup && (ownerGroup->isLFGGroup() || ownerGroup->isBGGroup() || ownerGroup->isBFGroup()))
        return;                                        // a dungeon-finder or battleground group: not ours
    if (ownerGroup && IsOwnersBuddyRaid(ownerGroup, owner, buddySet))
    {
        LOG_INFO("module", "mod-buddies: {}'s buddies were gathered into a raid at login; broken up to group by distance",
            owner->GetName());
        ownerGroup->Disband();                         // deletes the group; next pass regroups
        return;
    }

    // The online buddies on the owner's map, with their distances.
    std::vector<Near> buddies;
    for (uint32 guid : buddyGuids)
    {
        Player* bot = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid));
        if (!bot || !bot->IsInWorld() || bot->GetMapId() != owner->GetMapId())
            continue;
        buddies.push_back({ bot, bot->GetExactDist(owner) });
    }

    // 1. Leaving: out of the owner's group past 75; out of a far party
    //    within 74 of the owner, or more than 74 from every other member of
    //    it. RemoveMember disbands a group left with one member. The owner
    //    (2026-09-27) also has a far-party buddy leave "when it could join
    //    the player's party": within the 60-yard join distance it is within
    //    74 too, so it leaves here, and step 2 below adds it to the owner's
    //    party in this same pass when there is room (with no room it stays
    //    ungrouped until a seat frees).
    for (Near const& b : buddies)
    {
        Group* g = b.bot->GetGroup();
        if (!g)
            continue;
        if (g == owner->GetGroup())
        {
            uint32 guid = b.bot->GetGUID().GetCounter();
            if (b.yards > LEAVE_OWNER_YARDS && sSeatedByPass.erase(guid))
                g->RemoveMember(b.bot->GetGUID());     // seated by this pass: it may unseat; invited by hand: stays
        }
        else if (IsFarParty(g, buddySet) && (b.yards <= FAR_YARDS || !NearAnyMember(b.bot, g, FAR_LEAVE_YARDS)))
            g->RemoveMember(b.bot->GetGUID());
    }

    // 2. Joining the owner: ungrouped buddies within 60, nearest first,
    //    while the party has room. With no group yet, the owner leads a new
    //    one. A raid the owner made with other players is never joined (the
    //    owner's rule is a party of five, no conversion).
    std::sort(buddies.begin(), buddies.end(), [](Near const& a, Near const& b) { return a.yards < b.yards; });
    for (Near const& b : buddies)
    {
        if (b.bot->GetGroup() || b.yards > JOIN_OWNER_YARDS)
            continue;
        Group* g = owner->GetGroup();
        if (!g)
            g = NewParty(owner);
        if (!g || g->isRaidGroup() || g->GetMembersCount() >= PARTY_SIZE)
            break;
        if (g->AddMember(b.bot))
            sSeatedByPass.insert(b.bot->GetGUID().GetCounter());
        else
            LOG_ERROR("module", "mod-buddies: {} could not join {}'s party (server refused); left ungrouped this pass",
                b.bot->GetName(), owner->GetName());
    }

    // 3. Far parties: each ungrouped buddy past 74 (lowest guid first, so
    //    the order is stable) joins a far party with room one of
    //    whose members is within 70 yards of it; failing that, it pairs up
    //    with the next loose far buddy within 70 in a new party it leads (the
    //    lower guid leads). A lone far buddy with nobody near waits.
    std::vector<Player*> farLoose;
    for (Near const& b : buddies)
        if (b.yards > FAR_YARDS && !b.bot->GetGroup())
            farLoose.push_back(b.bot);
    std::sort(farLoose.begin(), farLoose.end(), [](Player* a, Player* b) { return a->GetGUID() < b->GetGUID(); });
    for (Player* bot : farLoose)
    {
        if (bot->GetGroup())
            continue;                                  // joined as someone's partner earlier in this loop
        Group* joined = nullptr;
        for (Near const& other : buddies)
        {
            Group* g = other.bot->GetGroup();
            if (!g || other.bot == bot || !IsFarParty(g, buddySet) || g->isRaidGroup() || g->GetMembersCount() >= PARTY_SIZE)
                continue;
            if (!NearAnyMember(bot, g, FAR_JOIN_YARDS))
                continue;
            if (g->AddMember(bot))
                joined = g;
            else
                LOG_ERROR("module", "mod-buddies: {} could not join a far party of {}'s buddies (server refused)",
                    bot->GetName(), owner->GetName());
            break;
        }
        if (joined)
            continue;
        for (Player* partner : farLoose)
        {
            if (partner == bot || partner->GetGroup() || bot->GetExactDist(partner) > FAR_JOIN_YARDS)
                continue;
            Group* g = NewParty(bot);
            if (!g)
                break;
            if (!g->AddMember(partner))
                LOG_ERROR("module", "mod-buddies: {} could not join the far party led by {} (server refused)",
                    partner->GetName(), bot->GetName());
            break;
        }
    }

    // 4. Merging far parties: two far parties merge when a member of one is
    //    within 70 yards of a member of the other and together they fit in
    //    five; the smaller one's members move into the larger. Removing a
    //    member from a party of two disbands (and deletes) that party, so
    //    after the members are taken out the emptied party is never touched
    //    again: each member is checked by asking it for its group, not by
    //    the old group pointer.
    for (;;)
    {
        std::vector<Group*> farParties;
        std::set<Group*> seen;
        for (Near const& b : buddies)
            if (Group* g = b.bot->GetGroup())
                if (!seen.count(g) && IsFarParty(g, buddySet) && !g->isRaidGroup())
                {
                    seen.insert(g);
                    farParties.push_back(g);
                }
        Group* large = nullptr;
        Group* small = nullptr;
        for (size_t i = 0; i < farParties.size() && !large; ++i)
            for (size_t j = i + 1; j < farParties.size(); ++j)
            {
                Group* x = farParties[i];
                Group* y = farParties[j];
                if (x->GetMembersCount() + y->GetMembersCount() > PARTY_SIZE || !PartiesNear(x, y, FAR_JOIN_YARDS))
                    continue;
                large = x->GetMembersCount() >= y->GetMembersCount() ? x : y;
                small = large == x ? y : x;
                break;
            }
        if (!large)
            break;                                     // no two far parties are near and fit together
        std::vector<Player*> moving;
        for (auto const& slot : small->GetMemberSlots())
            if (Player* p = ObjectAccessor::FindConnectedPlayer(slot.guid))
                moving.push_back(p);
        for (Player* p : moving)
            if (Group* g = p->GetGroup(); g && g == small)
                small->RemoveMember(p->GetGUID());     // the last removal disbands and deletes it
        bool moved = false;
        for (Player* p : moving)
        {
            if (p->GetGroup())
                continue;                              // still in a group (should not happen): left alone
            if (large->AddMember(p))
                moved = true;
            else
                LOG_ERROR("module", "mod-buddies: {} could not move into the merged far party of {}'s buddies "
                    "(server refused); left ungrouped this pass", p->GetName(), owner->GetName());
        }
        if (!moved)
            break;                                     // nothing moved: stop rather than loop
    }
}
// }}}

// {{{ UngroupInTown
// The owner is in a town: each online buddy leaves the owner's group or its
// far party. A group left with one member is disbanded by the server (the
// owner, alone, is then simply ungrouped). The owner's group with other
// players in it stays theirs; only the buddies leave it.
static void UngroupInTown(Player* owner, std::vector<uint32> const& buddyGuids)
{
    std::set<uint32> buddySet(buddyGuids.begin(), buddyGuids.end());
    for (uint32 guid : buddyGuids)
    {
        Player* bot = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid));
        if (!bot || !bot->IsInWorld())
            continue;
        Group* g = bot->GetGroup();
        if (!g || g->isLFGGroup() || g->isBGGroup() || g->isBFGroup())
            continue;                                  // ungrouped already, or a dungeon-finder / battleground group
        // the owner's party: only a buddy this pass seated (one invited by
        // hand stays, in town too); a far party is always this pass's own
        if ((g == owner->GetGroup() && sSeatedByPass.erase(guid)) || IsFarParty(g, buddySet))
            g->RemoveMember(bot->GetGUID());
    }
}
// }}}

// {{{ the dungeon draw (617c3)
// The owner, 2026-09-23: "If you enter a dungeon, then enough join to make
// a dungeon party. We can choose them randomly, without replacement,
// cycling through to make sure everyone gets a chance to go." On entering
// a five-player dungeon, the owner's party's empty seats (up to five) are
// filled with buddies drawn from a bag (buddy_draw: a row per buddy, had_turn
// 1 once drawn; when too few are left, the bag is refilled and the draw
// goes on from the full bag, skipping those already drawn this time). The
// drawn are brought in beside the owner; the rest wait outside. Buddies the
// distance rule had seated make way for the draw; one invited by hand keeps
// its seat. A group with two or more players is left alone (Ritz,
// 2026-09-24: no auto-fill when more than one player is grouped). Raids,
// battlegrounds and the dungeon finder's groups are not ours. When the owner
// comes back out, the buddies inside come out with them.
//
// The owner's map change is seen on the owner's map thread; the draw
// (groups and teleports of other players) waits for the world pass, which
// runs after every map has finished its update.
static constexpr uint32 DRAW_AFTER_MS = 1500;      // after the owner's arrival, before the drawn are brought
struct DrawDue { uint32 owner; bool entering; uint64 dueMs; };
static std::mutex sDrawLock;
static std::vector<DrawDue> sDrawDue;

static bool IsFiveManDungeon(Map* map) { return map->IsDungeon() && !map->IsRaid(); }

// {{{ PlayersIn
// The players (not buddies) of a group who are online.
static uint32 PlayersIn(Group* g)
{
    uint32 n = 0;
    for (GroupReference* r = g->GetFirstMember(); r; r = r->next())
        if (Player* m = r->GetSource())
            if (!BuddyIsCompanionAccount(m->GetSession()->GetAccountId()))
                ++n;
    return n;
}
// }}}

// {{{ DrawFromBag
// `count` buddies of `eligible`, at random, without replacement across
// runs. Written straight to the table (a few rows, world thread).
static std::vector<uint32> DrawFromBag(uint32 owner, std::vector<uint32> const& eligible, uint32 count)
{
    for (uint32 b : eligible)
        CharacterDatabase.DirectExecute("INSERT IGNORE INTO buddy_draw (owner, buddy, had_turn) VALUES ({}, {}, 0)", owner, b);
    std::set<uint32> waiting;                          // eligible and not yet had a turn
    if (QueryResult rows = CharacterDatabase.Query("SELECT buddy FROM buddy_draw WHERE owner = {} AND had_turn = 0", owner))
        do
            waiting.insert((*rows)[0].Get<uint32>());
        while (rows->NextRow());
    std::vector<uint32> bag;
    for (uint32 b : eligible)
        if (waiting.count(b))
            bag.push_back(b);
    std::vector<uint32> drawn;
    for (int round = 0; round < 2 && drawn.size() < count; ++round)
    {
        if (round == 1)
        {
            // everyone has had a turn: the bag refills (those drawn just now excepted)
            CharacterDatabase.DirectExecute("UPDATE buddy_draw SET had_turn = 0 WHERE owner = {}", owner);
            bag.clear();
            for (uint32 b : eligible)
                if (std::find(drawn.begin(), drawn.end(), b) == drawn.end())
                    bag.push_back(b);
        }
        while (!bag.empty() && drawn.size() < count)
        {
            size_t i = urand(0, uint32(bag.size() - 1));
            drawn.push_back(bag[i]);
            bag.erase(bag.begin() + i);
        }
    }
    for (uint32 b : drawn)
        CharacterDatabase.DirectExecute("UPDATE buddy_draw SET had_turn = 1 WHERE owner = {} AND buddy = {}", owner, b);
    return drawn;
}
// }}}

// {{{ BringDrawn
static void BringDrawn(Player* owner, std::vector<uint32> const& buddyGuids)
{
    if (!IsFiveManDungeon(owner->GetMap()))
        return;                                        // left again already, or not a five-player dungeon
    Group* g = owner->GetGroup();
    if (g && (g->isRaidGroup() || g->isLFGGroup() || g->isBGGroup() || g->isBFGroup()))
        return;                                        // a raid, or the dungeon finder's: not ours
    if (g && PlayersIn(g) >= 2)
        return;                                        // two or more players: no auto-fill

    // the distance rule's seats make way for the draw
    if (g)
        for (uint32 guid : buddyGuids)
            if (g->IsMember(ObjectGuid::Create<HighGuid::Player>(guid)) && sSeatedByPass.erase(guid))
                g->RemoveMember(ObjectGuid::Create<HighGuid::Player>(guid));
    g = owner->GetGroup();                             // a party left with one member was disbanded
    uint32 have = g ? g->GetMembersCount() : 1;
    if (have >= PARTY_SIZE)
        return;

    std::vector<uint32> eligible;                      // online, alive buddies not in the party already
    for (uint32 guid : buddyGuids)
    {
        Player* b = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid));
        if (b && b->IsInWorld() && b->IsAlive() && !b->InBattleground() && (!g || !g->IsMember(b->GetGUID())))
            eligible.push_back(guid);
    }
    std::vector<uint32> drawn = DrawFromBag(owner->GetGUID().GetCounter(), eligible, PARTY_SIZE - have);
    if (drawn.empty())
        return;
    if (!g)
        g = NewParty(owner);
    if (!g)
    {
        LOG_ERROR("module", "mod-buddies: {} entered a dungeon but no party could be made; no buddies drawn in", owner->GetName());
        return;
    }
    std::string names;
    for (uint32 guid : drawn)
    {
        Player* b = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid));
        if (!b)
            continue;
        if (Group* old = b->GetGroup())
            old->RemoveMember(b->GetGUID());           // a far party, most likely
        if (!g->AddMember(b))
        {
            LOG_ERROR("module", "mod-buddies: drawn buddy {} could not join {}'s party (server refused); left outside",
                b->GetName(), owner->GetName());
            continue;
        }
        sSeatedByPass.insert(guid);                    // outside again, the distance rule may unseat it
        b->TeleportTo(owner->GetMapId(), owner->GetPositionX(), owner->GetPositionY(), owner->GetPositionZ(), owner->GetOrientation());
        names += (names.empty() ? "" : ", ") + b->GetName();
    }
    LOG_INFO("module", "mod-buddies: {} entered {}; drawn in: {}", owner->GetName(), owner->GetMap()->GetMapName(), names);
}
// }}}

// {{{ BringOut
// The owner is back in the open world: buddies still in an instance
// (drawn in earlier) come out beside them.
static void BringOut(Player* owner, std::vector<uint32> const& buddyGuids)
{
    if (owner->GetMap()->Instanceable())
        return;                                        // into another instance: its own draw handles it
    for (uint32 guid : buddyGuids)
    {
        Player* b = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid));
        if (b && b->IsInWorld() && b->GetMap()->Instanceable() && !b->InBattleground())
            b->TeleportTo(owner->GetMapId(), owner->GetPositionX(), owner->GetPositionY(), owner->GetPositionZ(), owner->GetOrientation());
    }
}
// }}}

class buddies_draw_player : public PlayerScript
{
public:
    buddies_draw_player() : PlayerScript("buddies_draw_player", { PLAYERHOOK_ON_MAP_CHANGED }) { }

    void OnPlayerMapChanged(Player* player) override
    {
        if (!BuddiesEnabled() || BuddyIsCompanionAccount(player->GetSession()->GetAccountId()))
            return;                                    // buddies' own moves are not draws
        Map* map = player->GetMap();
        bool entering = IsFiveManDungeon(map);
        if (!entering && map->Instanceable())
            return;                                    // a raid or battleground: not ours
        std::lock_guard<std::mutex> lock(sDrawLock);
        sDrawDue.push_back({ player->GetGUID().GetCounter(), entering,
            uint64(GameTime::GetGameTimeMS().count()) + DRAW_AFTER_MS });
    }
};
// }}}

class buddies_party_world : public WorldScript
{
public:
    buddies_party_world() : WorldScript("buddies_party_world", { WORLDHOOK_ON_UPDATE }) { }

    // Every 5 seconds, each online owner out in the open world. The world
    // runs this hook on its own thread after every map has finished its
    // update (World::Update), so no bot is mid-thought while groups change;
    // the bot module makes its own group changes from the same hook.
    void OnUpdate(uint32 diff) override
    {
        RunDraws();                                    // the dungeon draw's due entries, every tick (617c3)

        _sinceLast += diff;
        if (_sinceLast < PASS_EVERY_MS || !BuddiesEnabled())
            return;
        _sinceLast = 0;

        std::map<uint32, std::vector<uint32>> byOwner;
        for (auto const& [buddy, owner] : BuddyRosterPairs())
            byOwner[owner].push_back(buddy);
        for (auto const& [ownerGuid, buddyGuids] : byOwner)
        {
            Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(ownerGuid));
            if (!owner || !owner->IsInWorld() || owner->GetMap()->Instanceable())
                continue;                              // offline, or in a dungeon or battleground
            if (BuddyTownArea(owner))                  // a building inside a town counts as the town
                UngroupInTown(owner, buddyGuids);      // in town: nobody grouped
            else
                ArrangeOwner(owner, buddyGuids);
        }
    }

private:
    // Owners whose map change is due for its draw (entering) or its bringing
    // out (leaving).
    static void RunDraws()
    {
        std::vector<DrawDue> due;
        {
            std::lock_guard<std::mutex> lock(sDrawLock);
            if (sDrawDue.empty())
                return;
            uint64 now = uint64(GameTime::GetGameTimeMS().count());
            for (auto it = sDrawDue.begin(); it != sDrawDue.end(); )
                if (it->dueMs <= now) { due.push_back(*it); it = sDrawDue.erase(it); }
                else ++it;
        }
        for (DrawDue const& d : due)
        {
            Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(d.owner));
            if (!owner || !owner->IsInWorld())
                continue;
            std::vector<uint32> buddies;
            for (auto const& [buddy, o] : BuddyRosterPairs())
                if (o == d.owner)
                    buddies.push_back(buddy);
            if (d.entering)
                BringDrawn(owner, buddies);
            else
                BringOut(owner, buddies);
        }
    }

    uint32 _sinceLast = 0;
};

// {{{ AddSC_buddies_party
void AddSC_buddies_party()
{
    new buddies_party_world();
    new buddies_draw_player();                         // the dungeon draw (617c3)
}
// }}}
