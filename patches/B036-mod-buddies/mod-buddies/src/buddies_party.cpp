
#include "buddies.h"
#include "buddies_loot.h"
#include "buddies_roam.h"
#include "buddies_roles.h"
#include "BattlegroundMgr.h"
#include "BattlegroundQueue.h"
#include "DatabaseEnv.h"
#include "SpellAuras.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include "GameTime.h"
#include "Group.h"
#include "GroupMgr.h"
#include "Log.h"
#include "Map.h"
#include "MotionMaster.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include <algorithm>
#include <atomic>
#include <map>
#include <mutex>
#include <set>
#include <string>
#include <vector>

static constexpr float  JOIN_OWNER_YARDS  = 60.0f;
static constexpr float  LEAVE_OWNER_YARDS = 75.0f;
static constexpr float  FAR_YARDS         = 74.0f;
static constexpr float  FAR_JOIN_YARDS    = 70.0f;
static constexpr float  FAR_LEAVE_YARDS   = 74.0f;
static constexpr uint32 PARTY_SIZE        = 5;
static constexpr uint32 PASS_EVERY_MS     = 5000;

static std::set<uint32> sSeatedByPass;

static std::set<uint32> sHandInvited;

static std::atomic<bool> sFillSoon { false };

enum class AskState : uint8 { Seating, Asking, Declined };
struct OwnerAsk
{
    AskState state = AskState::Seating;
    std::set<uint32> lastNear;
    uint32 invitedBy = 0;
    uint64 invitedAt = 0;
    uint32 declinedZone = 0;
    bool   leftZone = false, emptied = false;
};
static std::mutex sAskLock;
static std::map<uint32, OwnerAsk> sAsk;
static constexpr uint64 INVITE_SETTLE_MS = 3000;

static bool Seating(uint32 owner)
{
    std::lock_guard<std::mutex> lock(sAskLock);
    auto it = sAsk.find(owner);
    return it == sAsk.end() || it->second.state == AskState::Seating;
}

static void StartAsking(uint32 owner, char const* why)
{
    std::lock_guard<std::mutex> lock(sAskLock);
    OwnerAsk& a = sAsk[owner];
    if (a.state != AskState::Seating)
        return;
    a = OwnerAsk{};
    a.state = AskState::Asking;
    LOG_INFO("module", "mod-buddies: owner {} {}: buddies now ask before joining instead of being seated", owner, why);
}

static bool IsFarParty(Group* group, std::set<uint32> const& buddies)
{
    for (auto const& slot : group->GetMemberSlots())
        if (!buddies.count(slot.guid.GetCounter()))
            return false;
    return true;
}

static bool IsOwnersBuddyRaid(Group* group, Player* owner, std::set<uint32> const& buddies)
{
    if (!group->isRaidGroup())
        return false;
    for (auto const& slot : group->GetMemberSlots())
        if (slot.guid != owner->GetGUID() && !buddies.count(slot.guid.GetCounter()))
            return false;
    return true;
}

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

struct Near { Player* bot; float yards; };

static std::vector<Near> BuddiesNear(Player* owner, std::vector<uint32> const& buddyGuids)
{
    std::vector<Near> buddies;
    for (uint32 guid : buddyGuids)
    {
        Player* bot = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid));
        if (!bot || !bot->IsInWorld() || bot->GetMapId() != owner->GetMapId())
            continue;
        buddies.push_back({ bot, bot->GetExactDist(owner) });
    }
    return buddies;
}

static void ArrangeOwner(Player* owner, std::vector<uint32> const& buddyGuids)
{
    std::set<uint32> buddySet(buddyGuids.begin(), buddyGuids.end());

    Group* ownerGroup = owner->GetGroup();
    if (ownerGroup && (ownerGroup->isLFGGroup() || ownerGroup->isBGGroup() || ownerGroup->isBFGroup()))
        return;
    if (ownerGroup && IsOwnersBuddyRaid(ownerGroup, owner, buddySet))
    {
        LOG_INFO("module", "mod-buddies: {}'s buddies were gathered into a raid at login; broken up to group by distance",
            owner->GetName());
        ownerGroup->Disband();
        return;
    }

    std::vector<Near> buddies = BuddiesNear(owner, buddyGuids);

    for (Near const& b : buddies)
        if (b.bot->GetGroup() && b.bot->GetGroup() == owner->GetGroup() && !sHandInvited.count(b.bot->GetGUID().GetCounter()))
            sSeatedByPass.insert(b.bot->GetGUID().GetCounter());

    for (Near const& b : buddies)
    {
        Group* g = b.bot->GetGroup();
        if (!g)
            continue;
        if (g == owner->GetGroup())
        {
            uint32 guid = b.bot->GetGUID().GetCounter();
            if (b.yards > LEAVE_OWNER_YARDS && sSeatedByPass.erase(guid))
                g->RemoveMember(b.bot->GetGUID());
        }
        else if (IsFarParty(g, buddySet) && (b.yards <= FAR_YARDS || !NearAnyMember(b.bot, g, FAR_LEAVE_YARDS)))
            g->RemoveMember(b.bot->GetGUID());
    }

}

static void ArrangeFar(Player* owner, std::vector<uint32> const& buddyGuids)
{
    std::set<uint32> buddySet(buddyGuids.begin(), buddyGuids.end());
    Group* ownerGroup = owner->GetGroup();
    if (ownerGroup && (ownerGroup->isLFGGroup() || ownerGroup->isBGGroup() || ownerGroup->isBFGroup()))
        return;
    std::vector<Near> buddies = BuddiesNear(owner, buddyGuids);

    std::vector<Player*> farLoose;
    for (Near const& b : buddies)
        if (b.yards > FAR_YARDS && !b.bot->GetGroup())
            farLoose.push_back(b.bot);
    std::sort(farLoose.begin(), farLoose.end(), [](Player* a, Player* b) { return a->GetGUID() < b->GetGUID(); });
    for (Player* bot : farLoose)
    {
        if (bot->GetGroup())
            continue;
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
            break;
        std::vector<Player*> moving;
        for (auto const& slot : small->GetMemberSlots())
            if (Player* p = ObjectAccessor::FindConnectedPlayer(slot.guid))
                moving.push_back(p);
        for (Player* p : moving)
            if (Group* g = p->GetGroup(); g && g == small)
                small->RemoveMember(p->GetGUID());
        bool moved = false;
        for (Player* p : moving)
        {
            if (p->GetGroup())
                continue;
            if (large->AddMember(p))
                moved = true;
            else
                LOG_ERROR("module", "mod-buddies: {} could not move into the merged far party of {}'s buddies "
                    "(server refused); left ungrouped this pass", p->GetName(), owner->GetName());
        }
        if (!moved)
            break;
    }
}

static void AskOrWait(Player* owner, std::vector<uint32> const& buddyGuids)
{
    uint32 ownerGuid = owner->GetGUID().GetCounter();
    std::set<uint32> nearNow;
    for (Near const& b : BuddiesNear(owner, buddyGuids))
        if (b.bot->IsAlive() && b.yards <= JOIN_OWNER_YARDS)
            nearNow.insert(b.bot->GetGUID().GetCounter());

    std::lock_guard<std::mutex> lock(sAskLock);
    auto it = sAsk.find(ownerGuid);
    if (it == sAsk.end() || it->second.state == AskState::Seating)
        return;
    OwnerAsk& a = it->second;
    uint64 now = uint64(GameTime::GetGameTimeMS().count());

    if (a.state == AskState::Declined)
    {
        a.leftZone |= owner->GetZoneId() != a.declinedZone;
        a.emptied  |= nearNow.empty();
        if (a.leftZone && a.emptied)
        {
            a.state = AskState::Asking;
            a.lastNear = nearNow;
            LOG_INFO("module", "mod-buddies: {} has left the zone they declined in and had no buddy near; buddies ask again",
                owner->GetName());
        }
        return;
    }

    if (a.invitedBy)
    {
        Group* g = owner->GetGroup();
        if (g && g->IsMember(ObjectGuid::Create<HighGuid::Player>(a.invitedBy)))
        {
            if (g->GetLeaderGUID() != owner->GetGUID())
                g->ChangeLeader(owner->GetGUID());
            sSeatedByPass.insert(a.invitedBy);
            LOG_INFO("module", "mod-buddies: {} accepted buddy {}'s invite; buddies are seated by distance again",
                owner->GetName(), a.invitedBy);
            sAsk.erase(it);
            return;
        }
        if (!owner->GetGroupInvite() && now - a.invitedAt >= INVITE_SETTLE_MS)
        {
            LOG_INFO("module", "mod-buddies: {} declined buddy {}'s invite in zone {}; no more until they change zone with "
                "no buddy near", owner->GetName(), a.invitedBy, owner->GetZoneId());
            a.state = AskState::Declined;
            a.declinedZone = owner->GetZoneId();
            a.invitedBy = 0;
            a.leftZone = a.emptied = false;
        }
        return;
    }

    uint32 comer = 0;
    for (uint32 b : nearNow)
        if (!a.lastNear.count(b))
        {
            Player* bot = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(b));
            if (bot && !bot->GetGroup())
            {
                comer = b;
                break;
            }
        }
    a.lastNear = nearNow;
    if (!comer)
        return;
    Player* bot = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(comer));
    if (!owner->GetGroup() && !owner->GetGroupInvite())
    {
        WorldPacket invite(CMSG_GROUP_INVITE);
        invite << owner->GetName();
        invite << uint32(0);
        bot->GetSession()->HandleGroupInviteOpcode(invite);
        a.invitedBy = comer;
        a.invitedAt = now;
        LOG_INFO("module", "mod-buddies: buddy {} came near {} and invited them", bot->GetName(), owner->GetName());
    }
    else if (owner->GetGroup())
        bot->Whisper("I'm close by, if you want me along.", LANG_UNIVERSAL, owner);
}

static void FillSeats(std::map<uint32, std::vector<uint32>> const& byOwner)
{
    std::map<Group*, std::vector<Player*>> forGroup;
    std::map<Player*, std::vector<Player*>> forAlone;
    for (auto const& [ownerGuid, buddyGuids] : byOwner)
    {
        Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(ownerGuid));
        if (!owner || !owner->IsInWorld() || owner->GetMap()->Instanceable() || BuddyTownArea(owner))
            continue;
        if (!Seating(ownerGuid))
            continue;
        Group* g = owner->GetGroup();
        if (g && (g->isRaidGroup() || g->isLFGGroup() || g->isBGGroup() || g->isBFGroup()))
            continue;
        for (Near const& b : BuddiesNear(owner, buddyGuids))
            if (!b.bot->GetGroup() && b.bot->IsAlive() && b.yards <= JOIN_OWNER_YARDS)
                (g ? forGroup[g] : forAlone[owner]).push_back(b.bot);
    }
    auto seat = [](Group* g, std::vector<Player*>& candidates) {
        while (!candidates.empty() && g->GetMembersCount() < PARTY_SIZE)
        {
            size_t i = urand(0, uint32(candidates.size() - 1));
            Player* b = candidates[i];
            candidates.erase(candidates.begin() + i);
            if (g->AddMember(b))
                sSeatedByPass.insert(b->GetGUID().GetCounter());
            else
                LOG_ERROR("module", "mod-buddies: {} could not join its owner's party (server refused); left ungrouped this pass",
                    b->GetName());
        }
    };
    for (auto& [g, candidates] : forGroup)
        seat(g, candidates);
    for (auto& [owner, candidates] : forAlone)
    {
        if (candidates.empty() || owner->GetGroup())
            continue;
        if (Group* g = NewParty(owner))
            seat(g, candidates);
    }
}

static bool MakeRoom(Group* g, ObjectGuid keep)
{
    std::vector<ObjectGuid> seated;
    for (auto const& slot : g->GetMemberSlots())
        if (slot.guid != keep && sSeatedByPass.count(slot.guid.GetCounter()))
            seated.push_back(slot.guid);
    if (seated.empty())
        return false;
    ObjectGuid out = seated[urand(0, uint32(seated.size() - 1))];
    sSeatedByPass.erase(out.GetCounter());
    g->RemoveMember(out);
    LOG_INFO("module", "mod-buddies: a full party made room for an invite: buddy {} stepped out", out.GetCounter());
    return true;
}

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
            continue;
        if ((g == owner->GetGroup() && sSeatedByPass.erase(guid)) || IsFarParty(g, buddySet))
            g->RemoveMember(bot->GetGUID());
    }
}

static constexpr uint32 DRAW_AFTER_MS = 1500;
struct DrawDue { uint32 owner; bool entering; uint64 dueMs; };
static std::mutex sDrawLock;
static std::vector<DrawDue> sDrawDue;

static bool IsFiveManDungeon(Map* map) { return map->IsDungeon() && !map->IsRaid(); }


static std::vector<uint32> DrawFromBag(uint32 owner, std::vector<uint32> const& eligible, uint32 count)
{
    for (uint32 b : eligible)
        CharacterDatabase.DirectExecute("INSERT IGNORE INTO buddy_draw (owner, buddy, had_turn) VALUES ({}, {}, 0)", owner, b);
    std::set<uint32> waiting;
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

static constexpr uint32 WALK_TICK_MS    = 1000;
static constexpr float  WALK_ARRIVED    = 4.0f;
static constexpr uint32 WALK_STUCK_MS   = 60000;
struct Spot { uint32 map; float x, y, z, o; };
struct WalkIn { uint32 buddy; uint32 owner; Spot entrance; Spot inside; float best; uint64 progressMs; };
static std::map<uint32, Spot> sLastOutside;
static std::vector<WalkIn> sWalkIns;

static void StartWalkIn(Player* b, Player* owner)
{
    auto it = sLastOutside.find(owner->GetGUID().GetCounter());
    Spot inside { owner->GetMapId(), owner->GetPositionX(), owner->GetPositionY(), owner->GetPositionZ(), owner->GetOrientation() };
    if (it == sLastOutside.end())
    {
        LOG_ERROR("module", "mod-buddies: no entrance known for {}'s dungeon (they were never seen outside since the server "
            "started); drawn buddy {} is brought in beside them", owner->GetName(), b->GetName());
        b->TeleportTo(inside.map, inside.x, inside.y, inside.z, inside.o);
        return;
    }
    if (b->GetMapId() != it->second.map)
    {
        LOG_ERROR("module", "mod-buddies: drawn buddy {} is on map {}, the entrance to {}'s dungeon on map {}; it can't walk "
            "there (walking between maps is not built) and stays out", b->GetName(), b->GetMapId(), owner->GetName(), it->second.map);
        return;
    }
    sWalkIns.push_back({ b->GetGUID().GetCounter(), owner->GetGUID().GetCounter(), it->second, inside,
        b->GetExactDist(it->second.x, it->second.y, it->second.z), uint64(GameTime::GetGameTimeMS().count()) });
}

static void RunWalkIns()
{
    uint64 now = uint64(GameTime::GetGameTimeMS().count());
    for (auto it = sWalkIns.begin(); it != sWalkIns.end(); )
    {
        WalkIn& w = *it;
        Player* b = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(w.buddy));
        Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(w.owner));
        if (!b || !owner || !b->IsInWorld() || !b->IsAlive() || !IsFiveManDungeon(owner->GetMap())
            || b->GetMapId() != w.entrance.map)
        {
            it = sWalkIns.erase(it);
            continue;
        }
        float d = b->GetExactDist(w.entrance.x, w.entrance.y, w.entrance.z);
        bool stuck = false;
        if (d + 1.0f < w.best)
            w.best = d, w.progressMs = now;
        else if (now - w.progressMs > WALK_STUCK_MS)
            stuck = true;
        if (d <= WALK_ARRIVED || stuck)
        {
            if (stuck)
                LOG_WARN("module", "mod-buddies: drawn buddy {} made no progress toward {}'s dungeon entrance for {} s "
                    "({:.0f} yards off); FALLBACK: brought in without walking the rest", b->GetName(), owner->GetName(),
                    WALK_STUCK_MS / 1000, d);
            b->TeleportTo(w.inside.map, w.inside.x, w.inside.y, w.inside.z, w.inside.o);
            it = sWalkIns.erase(it);
            continue;
        }
        if (PlayerbotAI* ai = GET_PLAYERBOT_AI(b))
            ai->SetNextCheckDelay(WALK_TICK_MS * 3);
        if (b->IsWalking())
            b->SetWalk(false);
        if (!b->isMoving())
            b->GetMotionMaster()->MovePoint(0, w.entrance.x, w.entrance.y, w.entrance.z);
        ++it;
    }
}

static std::set<uint32> sDrawnIn;

static BuddyRole RosterRole(uint32 buddy)
{
    QueryResult r = CharacterDatabase.Query("SELECT role FROM buddy_roster WHERE buddy = {}", buddy);
    return r ? BuddyRole((*r)[0].Get<uint8>()) : BuddyRole::Damage;
}

static constexpr uint32 ROLE_FULL    = 10;
static constexpr uint32 ROLE_PARTIAL = 4;
static uint32 RoleTenths(uint32 buddy, BuddyRole need)
{
    QueryResult r = CharacterDatabase.Query("SELECT role, profile, class FROM buddy_roster WHERE buddy = {}", buddy);
    if (!r)
        return 0;
    uint8 role = (*r)[0].Get<uint8>(), profile = (*r)[1].Get<uint8>(), cls = (*r)[2].Get<uint8>();
    if (BuddyRole(role) == need)
        return ROLE_FULL;
    uint8 thirds[3];
    CollectorType types[3];
    if (!BuddyPlanShape(cls, profile, role, thirds, types))
        return 0;
    CollectorType want = need == BuddyRole::Tank ? CollectorType::MELEE_TANK : CollectorType::SPELL_HEAL;
    for (int t = 0; t < 3; ++t)
        if (types[t] == want && thirds[t] > 0)
            return ROLE_PARTIAL;
    return 0;
}

static void BringDrawn(Player* player, std::vector<uint32> const& )
{
    if (!IsFiveManDungeon(player->GetMap()))
        return;
    Group* g = player->GetGroup();
    if (g && (g->isRaidGroup() || g->isLFGGroup() || g->isBGGroup() || g->isBFGroup()))
        return;

    std::vector<Player*> players;
    if (g)
    {
        for (GroupReference* r = g->GetFirstMember(); r; r = r->next())
            if (Player* m = r->GetSource())
                if (!BuddyIsCompanionAccount(m->GetSession()->GetAccountId()))
                    players.push_back(m);
    }
    else
        players.push_back(player);
    std::set<uint32> playerGuids;
    for (Player* p : players)
        playerGuids.insert(p->GetGUID().GetCounter());

    if (g)
    {
        std::vector<ObjectGuid> out;
        for (auto const& slot : g->GetMemberSlots())
            if (sSeatedByPass.count(slot.guid.GetCounter()) && !sDrawnIn.count(slot.guid.GetCounter()))
                out.push_back(slot.guid);
        for (ObjectGuid guid : out)
        {
            sSeatedByPass.erase(guid.GetCounter());
            if (Group* now = player->GetGroup())
                now->RemoveMember(guid);
        }
    }
    g = player->GetGroup();
    uint32 have = g ? g->GetMembersCount() : 1;
    if (have >= PARTY_SIZE)
        return;

    uint32 tankSum = 0, healSum = 0;
    auto count = [&](Player* m) {
        if (BuddyIsCompanionAccount(m->GetSession()->GetAccountId()))
        {
            uint32 low = m->GetGUID().GetCounter();
            tankSum += RoleTenths(low, BuddyRole::Tank);
            healSum += RoleTenths(low, BuddyRole::Healer);
            return;
        }
        BuddyRoles roles = BuddyPlayerRoles(m);
        if (roles & BuddyRoleBit(BuddyRole::Tank))   tankSum += ROLE_FULL;
        if (roles & BuddyRoleBit(BuddyRole::Healer)) healSum += ROLE_FULL;
    };
    if (g)
    {
        for (GroupReference* r = g->GetFirstMember(); r; r = r->next())
            if (Player* m = r->GetSource())
                count(m);
    }
    else
        count(player);

    std::map<uint32, std::vector<uint32>> eligible;
    std::map<uint32, BuddyRole> roleOf;
    std::map<uint32, uint32> ownerOf;
    for (auto const& [buddy, owner] : BuddyRosterPairs())
    {
        if (!playerGuids.count(owner))
            continue;
        Player* b = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(buddy));
        if (b && b->IsInWorld() && b->IsAlive() && !b->InBattleground() && (!g || !g->IsMember(b->GetGUID())))
        {
            eligible[owner].push_back(buddy);
            roleOf[buddy]  = RosterRole(buddy);
            ownerOf[buddy] = owner;
        }
    }
    std::vector<uint32> drawn;
    auto take = [&](uint32 buddy) {
        drawn.push_back(buddy);
        std::vector<uint32>& mine = eligible[ownerOf[buddy]];
        mine.erase(std::remove(mine.begin(), mine.end(), buddy), mine.end());
        CharacterDatabase.DirectExecute("INSERT INTO buddy_draw (owner, buddy, had_turn) VALUES ({}, {}, 1) "
            "ON DUPLICATE KEY UPDATE had_turn = 1", ownerOf[buddy], buddy);
    };
    for (BuddyRole need : { BuddyRole::Tank, BuddyRole::Healer })
    {
        uint32& sum = need == BuddyRole::Tank ? tankSum : healSum;
        char const* what = need == BuddyRole::Tank ? "tank" : "healer";
        while (sum < ROLE_FULL && have + drawn.size() < PARTY_SIZE)
        {
            uint32 best = 0;
            std::vector<uint32> top;
            for (auto const& [owner, list] : eligible)
                for (uint32 b : list)
                {
                    uint32 w = RoleTenths(b, need);
                    if (w == 0 || w < best)
                        continue;
                    if (w > best)
                    {
                        best = w;
                        top.clear();
                    }
                    top.push_back(b);
                }
            if (top.empty())
            {
                LOG_INFO("module", "mod-buddies: {}'s group entered {} with a {} sum of {}.{} and no buddy left to add to it",
                    player->GetName(), player->GetMap()->GetMapName(), what, sum / 10, sum % 10);
                break;
            }
            uint32 pick = top[urand(0, uint32(top.size() - 1))];
            take(pick);
            tankSum += RoleTenths(pick, BuddyRole::Tank);
            healSum += RoleTenths(pick, BuddyRole::Healer);
        }
    }
    std::vector<uint32> order(playerGuids.begin(), playerGuids.end());
    for (size_t i = order.size(); i > 1; --i)
        std::swap(order[i - 1], order[urand(0, uint32(i - 1))]);
    for (bool damageOnly : { true, false })
        for (bool any = true; any && have + drawn.size() < PARTY_SIZE; )
        {
            any = false;
            for (uint32 owner : order)
            {
                if (have + drawn.size() >= PARTY_SIZE)
                    break;
                std::vector<uint32> pool;
                for (uint32 b : eligible[owner])
                    if (!damageOnly || roleOf[b] == BuddyRole::Damage)
                        pool.push_back(b);
                std::vector<uint32> one = DrawFromBag(owner, pool, 1);
                if (one.empty())
                    continue;
                take(one.front());
                any = true;
            }
        }
    if (drawn.empty())
        return;
    if (!g)
        g = NewParty(player);
    if (!g)
    {
        LOG_ERROR("module", "mod-buddies: {} entered a dungeon but no party could be made; no buddies drawn in", player->GetName());
        return;
    }
    std::string names;
    for (uint32 guid : drawn)
    {
        Player* b = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid));
        if (!b)
            continue;
        if (Group* old = b->GetGroup())
            old->RemoveMember(b->GetGUID());
        if (!g->AddMember(b))
        {
            LOG_ERROR("module", "mod-buddies: drawn buddy {} could not join {}'s party (server refused); left outside",
                b->GetName(), player->GetName());
            continue;
        }
        sSeatedByPass.insert(guid);
        sDrawnIn.insert(guid);
        StartWalkIn(b, player);
        names += (names.empty() ? "" : ", ") + b->GetName() + " (" + (roleOf[guid] == BuddyRole::Tank ? "tank" :
            roleOf[guid] == BuddyRole::Healer ? "healer" : "damage") + ")";
    }
    LOG_INFO("module", "mod-buddies: {} entered {}; drawn in: {}", player->GetName(), player->GetMap()->GetMapName(), names);
}

static void BringOut(Player* owner, std::vector<uint32> const& buddyGuids)
{
    if (owner->GetMap()->Instanceable())
        return;
    for (uint32 guid : buddyGuids)
    {
        Player* b = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid));
        if (b && b->IsInWorld() && b->GetMap()->Instanceable() && !b->InBattleground())
            b->TeleportTo(owner->GetMapId(), owner->GetPositionX(), owner->GetPositionY(), owner->GetPositionZ(), owner->GetOrientation());
        sDrawnIn.erase(guid);
    }
}

class buddies_draw_player : public PlayerScript
{
public:
    buddies_draw_player() : PlayerScript("buddies_draw_player", { PLAYERHOOK_ON_MAP_CHANGED }) { }

    void OnPlayerMapChanged(Player* player) override
    {
        if (!BuddiesEnabled() || BuddyIsNotAPlayer(player->GetSession()->GetAccountId()))
            return;
        Map* map = player->GetMap();
        bool entering = IsFiveManDungeon(map);
        if (!entering && map->Instanceable())
            return;
        std::lock_guard<std::mutex> lock(sDrawLock);
        sDrawDue.push_back({ player->GetGUID().GetCounter(), entering,
            uint64(GameTime::GetGameTimeMS().count()) + DRAW_AFTER_MS });
    }
};

static constexpr uint32 QUEUE_EVERY_MS    = 2000;
static constexpr uint32 SPELL_DESERTER    = 26013;
static constexpr int32  DESERTER_STOCK_MS = 15 * MINUTE * IN_MILLISECONDS;
static std::map<uint32, std::set<BattlegroundQueueTypeId>> sQueuedByPass;

static void MirrorQueues(Player* owner, std::vector<uint32> const& buddyGuids)
{
    std::set<BattlegroundQueueTypeId> ownerQueues;
    for (uint32 i = 0; i < PLAYER_MAX_BATTLEGROUND_QUEUES; ++i)
    {
        BattlegroundQueueTypeId q = owner->GetBattlegroundQueueTypeId(i);
        if (q != BATTLEGROUND_QUEUE_NONE && !BattlegroundMgr::BGArenaType(q))
            ownerQueues.insert(q);
    }
    for (uint32 guid : buddyGuids)
    {
        Player* b = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid));
        if (!b || !b->IsInWorld())
            continue;
        if (Aura* deserter = b->GetAura(SPELL_DESERTER))
            if (deserter->GetMaxDuration() >= DESERTER_STOCK_MS)
            {
                deserter->SetMaxDuration(deserter->GetMaxDuration() / 3);
                deserter->SetDuration(std::min(deserter->GetDuration(), deserter->GetMaxDuration()));
            }
        if (b->InBattleground())
            continue;
        std::set<BattlegroundQueueTypeId>& mine = sQueuedByPass[guid];
        for (BattlegroundQueueTypeId q : ownerQueues)
        {
            if (mine.count(q) || b->InBattlegroundQueueForBattlegroundQueueType(q))
                continue;
            mine.insert(q);
            if (!b->HasFreeBattlegroundQueueId())
                continue;
            WorldPacket* p = new WorldPacket(CMSG_BATTLEMASTER_JOIN, 20);
            *p << b->GetGUID() << uint32(BattlegroundMgr::BGTemplateId(q)) << uint32(0) << uint8(0);
            b->GetSession()->QueuePacket(p);
        }
        for (auto it = mine.begin(); it != mine.end(); )
        {
            if (ownerQueues.count(*it))
            {
                ++it;
                continue;
            }
            if (b->InBattlegroundQueueForBattlegroundQueueType(*it))
            {
                sBattlegroundMgr->GetBattlegroundQueue(*it).RemovePlayer(b->GetGUID(), true);
                b->RemoveBattlegroundQueueId(*it);
            }
            it = mine.erase(it);
        }
    }
}

static constexpr uint32 PULL_GIVE_UP_MS = 30000;
struct PullDue { uint32 buddy; uint32 inviter; uint64 sinceMs; bool left; };
static std::mutex sPullLock;
static std::vector<PullDue> sPulls;

void BuddyPullIntoGroup(uint32 buddyGuid, uint32 inviterGuid)
{
    std::lock_guard<std::mutex> lock(sPullLock);
    sPulls.push_back({ buddyGuid, inviterGuid, uint64(GameTime::GetGameTimeMS().count()), false });
}

static void RunPulls()
{
    std::vector<PullDue> work;
    {
        std::lock_guard<std::mutex> lock(sPullLock);
        if (sPulls.empty())
            return;
        work.swap(sPulls);
    }
    uint64 now = uint64(GameTime::GetGameTimeMS().count());
    std::vector<PullDue> again;
    for (PullDue& p : work)
    {
        Player* b = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(p.buddy));
        Player* inviter = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(p.inviter));
        if (!b || !inviter)
            continue;
        if (now - p.sinceMs > PULL_GIVE_UP_MS)
        {
            LOG_ERROR("module", "mod-buddies: buddy {} was to join {}'s group, but after {} s it was still not back in "
                "the world (leaving a battleground, or teleporting); given up", b->GetName(), inviter->GetName(), PULL_GIVE_UP_MS / 1000);
            continue;
        }
        if (!p.left)
        {
            p.left = true;
            if (b->InBattleground())
            {
                b->LeaveBattleground();
                again.push_back(p);
                continue;
            }
        }
        if (b->InBattleground() || !b->IsInWorld() || b->IsBeingTeleported())
        {
            again.push_back(p);
            continue;
        }
        Group* g = inviter->GetGroup();
        if (!g)
            g = NewParty(inviter);
        if (g && g->IsMember(b->GetGUID()))
        {
            sSeatedByPass.erase(p.buddy);
            sHandInvited.insert(p.buddy);
            continue;
        }
        if (g && !g->isRaidGroup() && g->GetMembersCount() >= PARTY_SIZE)
            MakeRoom(g, b->GetGUID());
        if (!g || g->isRaidGroup() || g->GetMembersCount() >= PARTY_SIZE)
        {
            BuddyTrace(b, "party: {} invited me, but their group has no seat for me", inviter->GetName());
            continue;
        }
        if (Group* old = b->GetGroup())
            old->RemoveMember(b->GetGUID());
        if (!g->AddMember(b))
            LOG_ERROR("module", "mod-buddies: buddy {} could not join {}'s group after leaving its own (server refused); "
                "it is ungrouped", b->GetName(), inviter->GetName());
        sSeatedByPass.erase(p.buddy);
        sHandInvited.insert(p.buddy);
    }
    if (!again.empty())
    {
        std::lock_guard<std::mutex> lock(sPullLock);
        sPulls.insert(sPulls.end(), again.begin(), again.end());
    }
}

struct HeldInvite { uint32 inviter; std::vector<uint8> packet; };
static std::mutex sHeldLock;
static std::vector<HeldInvite> sHeld;

void BuddyHoldInviteForRoom(uint32 inviterGuid, WorldPacket const& packet)
{
    std::lock_guard<std::mutex> lock(sHeldLock);
    sHeld.push_back({ inviterGuid, std::vector<uint8>(packet.contents(), packet.contents() + packet.size()) });
}

static void RunHeldInvites()
{
    std::vector<HeldInvite> work;
    {
        std::lock_guard<std::mutex> lock(sHeldLock);
        if (sHeld.empty())
            return;
        work.swap(sHeld);
    }
    for (HeldInvite const& h : work)
    {
        Player* inviter = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(h.inviter));
        if (!inviter || !inviter->GetSession())
            continue;
        if (Group* g = inviter->GetGroup(); g && !g->isRaidGroup() && g->GetMembersCount() >= PARTY_SIZE)
            MakeRoom(g, ObjectGuid::Empty);
        WorldPacket again(CMSG_GROUP_INVITE, h.packet.size());
        if (!h.packet.empty())
            again.append(h.packet.data(), h.packet.size());
        inviter->GetSession()->HandleGroupInviteOpcode(again);
    }
}

class buddies_party_group : public GroupScript
{
public:
    buddies_party_group() : GroupScript("buddies_party_group", { GROUPHOOK_ON_REMOVE_MEMBER }) { }

    void OnRemoveMember(Group* group, ObjectGuid guid, RemoveMethod method, ObjectGuid kicker, char const* ) override
    {
        sFillSoon = true;
        uint32 low = guid.GetCounter();
        sHandInvited.erase(low);
        for (auto const& [buddy, owner] : BuddyRosterPairs())
        {
            if (method == GROUP_REMOVEMETHOD_KICK && buddy == low && kicker.GetCounter() == owner && sSeatedByPass.count(low))
            {
                StartAsking(owner, "removed a buddy the distance rule had seated");
                return;
            }
            if (method == GROUP_REMOVEMETHOD_LEAVE && owner == low && sSeatedByPass.count(buddy) && group->IsMember(ObjectGuid::Create<HighGuid::Player>(buddy)))
            {
                StartAsking(owner, "left a party the distance rule had seated buddies in");
                return;
            }
        }
    }
};

class buddies_party_world : public WorldScript
{
public:
    buddies_party_world() : WorldScript("buddies_party_world", { WORLDHOOK_ON_UPDATE }) { }

    void OnUpdate(uint32 diff) override
    {
        RunDraws();
        RunPulls();
        RunHeldInvites();
        if (sFillSoon && BuddiesEnabled())
        {
            sFillSoon = false;
            std::map<uint32, std::vector<uint32>> byOwner;
            for (auto const& [buddy, owner] : BuddyRosterPairs())
                byOwner[owner].push_back(buddy);
            FillSeats(byOwner);
        }

        _sinceWalk += diff;
        if (_sinceWalk >= WALK_TICK_MS / 2 && BuddiesEnabled())
        {
            _sinceWalk = 0;
            std::set<uint32> owners;
            for (auto const& [buddy, owner] : BuddyRosterPairs())
                owners.insert(owner);
            for (uint32 o : owners)
                if (Player* p = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(o)))
                    if (p->IsInWorld() && !p->GetMap()->Instanceable() && !p->IsBeingTeleported())
                        sLastOutside[o] = { p->GetMapId(), p->GetPositionX(), p->GetPositionY(), p->GetPositionZ(), p->GetOrientation() };
            if (!sWalkIns.empty())
                RunWalkIns();
        }

        _sinceQueues += diff;
        if (_sinceQueues >= QUEUE_EVERY_MS && BuddiesEnabled())
        {
            _sinceQueues = 0;
            std::map<uint32, std::vector<uint32>> byOwner;
            for (auto const& [buddy, owner] : BuddyRosterPairs())
                byOwner[owner].push_back(buddy);
            for (auto const& [ownerGuid, buddyGuids] : byOwner)
                if (Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(ownerGuid)))
                    if (owner->IsInWorld())
                        MirrorQueues(owner, buddyGuids);
        }

        _sinceLast += diff;
        if (_sinceLast < PASS_EVERY_MS || !BuddiesEnabled())
            return;
        _sinceLast = 0;

        std::map<uint32, std::vector<uint32>> byOwner;
        for (auto const& [buddy, owner] : BuddyRosterPairs())
            byOwner[owner].push_back(buddy);
        std::vector<std::pair<Player*, std::vector<uint32> const*>> outside;
        for (auto const& [ownerGuid, buddyGuids] : byOwner)
        {
            Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(ownerGuid));
            if (!owner || !owner->IsInWorld() || owner->GetMap()->Instanceable())
                continue;
            if (BuddyTownArea(owner))
                UngroupInTown(owner, buddyGuids);
            else
            {
                ArrangeOwner(owner, buddyGuids);
                AskOrWait(owner, buddyGuids);
                outside.push_back({ owner, &buddyGuids });
            }
        }
        FillSeats(byOwner);
        sFillSoon = false;
        for (auto const& [owner, buddyGuids] : outside)
            ArrangeFar(owner, *buddyGuids);
    }

private:
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
    uint32 _sinceQueues = 0;
    uint32 _sinceWalk = 0;
};

void AddSC_buddies_party()
{
    new buddies_party_world();
    new buddies_party_group();
    new buddies_draw_player();
}
