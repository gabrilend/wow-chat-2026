
#include "buddies.h"
#include "buddies_roam.h"
#include "buddies_town.h"
#include "buddies_follow.h"
#include "roam/buddy_follow_core.h"
#include "roam/buddy_sell_core.h"
#include "Guild.h"
#include "World.h"
#include "Chat.h"
#include "CompanionAccounts.h"
#include "GameTime.h"
#include "Group.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Playerbots.h"
#include "PlayerbotAI.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include <algorithm>
#include <cctype>
#include <mutex>
#include <set>
#include <string>
#include <vector>

static constexpr uint32 BAGS_LOOK_EVERY_MS = 5000;
static char const* const BAGS_FULL_LINE    = "My bags are full.";
static char const* const GOING_LINE        = "Off to sell. Come with me if you can.";

enum class OrderKind : uint8 { Sell, Attack, Follow, GoAway };
enum class Heard : uint8 { Say, Yell, Group, Whisper, Guild };
struct HeardOrder
{
    ObjectGuid               speaker;
    ObjectGuid               whisperedBuddy;
    OrderKind                kind  = OrderKind::Sell;
    std::vector<std::string> names;
    Heard                    where = Heard::Say;
    bool                     hard  = false;
    bool                     circle = false;
    bool                     everyone = false;
};
static std::mutex              sOrdersLock;
static std::vector<HeardOrder> sHeard;
static std::set<uint32>        sToldToSell;
static std::set<uint32>        sSaidFull;

bool BuddyTakeSellOrder(uint32 buddy)
{
    std::lock_guard<std::mutex> lock(sOrdersLock);
    return sToldToSell.erase(buddy) > 0;
}

static int IsGoSell(std::string msg)
{
    std::transform(msg.begin(), msg.end(), msg.begin(), [](unsigned char c) { return std::tolower(c); });
    while (!msg.empty() && (std::ispunct(static_cast<unsigned char>(msg.back())) || std::isspace(static_cast<unsigned char>(msg.back()))))
        msg.pop_back();
    while (!msg.empty() && std::isspace(static_cast<unsigned char>(msg.front())))
        msg.erase(msg.begin());
    if (msg == "everyone go sell" || msg == "everybody go sell" || msg == "all of you go sell" || msg == "everyone go sell please")
        return 2;
    return (msg == "go sell" || msg == "go sell please" || msg == "please go sell") ? 1 : 0;
}

static bool IsAttack(std::string msg, std::vector<std::string>& names)
{
    std::transform(msg.begin(), msg.end(), msg.begin(), [](unsigned char c) { return std::isalpha(c) ? char(std::tolower(c)) : ' '; });
    std::vector<std::string> words;
    std::string w;
    for (char c : msg + " ")
        if (c == ' ') { if (!w.empty()) words.push_back(w); w.clear(); }
        else w += c;
    words.erase(std::remove(words.begin(), words.end(), "please"), words.end());
    if (words.empty() || (words[0] != "attack" && words[0] != "engage"))
        return false;
    names.assign(words.begin() + 1, words.end());
    return true;
}

static bool IsFollowOrder(std::string const& raw, OrderKind& kind, std::string& name, bool& hard, bool& circle)
{
    BuddyFollow::Order o = BuddyFollow::ReadOrder(raw, name, hard);
    if (o == BuddyFollow::Order::None)
        return false;
    circle = o == BuddyFollow::Order::Circle;
    kind = (o == BuddyFollow::Order::Follow || circle) ? OrderKind::Follow : OrderKind::GoAway;
    return true;
}

static std::vector<Player*> Hearers(HeardOrder const& h, Player* speaker)
{
    std::vector<Player*> out;
    float range = h.where == Heard::Yell ? sWorld->getFloatConfig(CONFIG_LISTEN_RANGE_YELL)
                                         : sWorld->getFloatConfig(CONFIG_LISTEN_RANGE_SAY);
    Group* group = speaker->GetGroup();
    for (auto const& [buddyGuid, ownerGuid] : BuddyRosterPairs())
    {
        Player* b = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(buddyGuid));
        if (!b || !b->IsInWorld() || !b->IsAlive())
            continue;
        bool hears = false;
        switch (h.where)
        {
            case Heard::Whisper: hears = h.whisperedBuddy.GetCounter() == buddyGuid; break;
            case Heard::Group:   hears = group && b->GetGroup() == group; break;
            case Heard::Guild:   hears = speaker->GetGuildId() != 0 && b->GetGuildId() == speaker->GetGuildId(); break;
            case Heard::Say:
            case Heard::Yell:    hears = ownerGuid == speaker->GetGUID().GetCounter() && b->GetMapId() == speaker->GetMapId()
                                         && b->GetExactDist(speaker) <= range; break;
        }
        if (hears)
            out.push_back(b);
    }
    return out;
}

static void ObeyFollow(HeardOrder const& h, Player* speaker)
{
    ChatHandler tell(speaker->GetSession());
    std::vector<Player*> hearers = Hearers(h, speaker);
    if (h.kind == OrderKind::Follow)
    {
        Player* leader = speaker;
        if (!h.names.empty())
        {
            std::string wanted = h.names[0];
            leader = nullptr;
            for (Player* p : hearers)
                if (p->GetName().size() == wanted.size() &&
                    std::equal(wanted.begin(), wanted.end(), p->GetName().begin(), [](char a, char b) { return a == std::tolower(static_cast<unsigned char>(b)); }))
                    leader = p;
            if (!leader)
            {
                std::string proper = wanted;
                proper[0] = char(std::toupper(static_cast<unsigned char>(proper[0])));
                leader = ObjectAccessor::FindPlayerByName(proper, true);
            }
            if (!leader || !leader->IsInWorld())
            {
                tell.PSendSysMessage("There is no one called {} here to follow.", wanted);
                return;
            }
        }
        uint32 following = 0, refusing = 0;
        for (Player* b : hearers)
        {
            if (b == leader)
                continue;
            if (BuddyFollowRefused(b->GetGUID().GetCounter(), leader->GetGUID().GetCounter()))
            {
                ++refusing;
                continue;
            }
            BuddyFollowSet(b->GetGUID().GetCounter(), leader->GetGUID().GetCounter());
            BuddyFollowSetRing(b->GetGUID().GetCounter(), h.circle);
            ++following;
        }
        tell.PSendSysMessage("{} {} following {}{}.", following, following == 1 ? "buddy is" : "buddies are", leader->GetName(),
                             refusing ? " (" + std::to_string(refusing) + " were sent away and won't until " + leader->GetName() + " logs out)" : "");
        LOG_INFO("module", "mod-buddies: {} said follow {}; {} buddies follow, {} refused", speaker->GetName(), leader->GetName(), following, refusing);
        return;
    }
    uint32 gone = 0;
    uint32 me = speaker->GetGUID().GetCounter();
    for (Player* b : hearers)
    {
        uint32 guid   = b->GetGUID().GetCounter();
        uint32 leader = BuddyFollowLeader(guid);
        bool   mine   = false;
        for (auto const& [buddyGuid, ownerGuid] : BuddyRosterPairs())
            if (buddyGuid == guid && ownerGuid == me)
                mine = true;
        if (!leader || (leader != me && !mine))
            continue;
        BuddyFollowStop(guid);
        if (h.hard)
            BuddyFollowRefuse(guid, me);
        ++gone;
    }
    tell.PSendSysMessage("{} {} back to {} own business{}.", gone, gone == 1 ? "buddy goes" : "buddies go", gone == 1 ? "its" : "their",
                         h.hard ? ", and won't follow you again until you log out" : "");
}

static void SayToOwner(Player* buddy, Player* owner, char const* text)
{
    Group* g = owner->GetGroup();
    if (g && !g->isBGGroup() && !g->isBFGroup())
    {
        WorldPacket data;
        ChatHandler::BuildChatPacket(data, g->isRaidGroup() ? CHAT_MSG_RAID : CHAT_MSG_PARTY, LANG_UNIVERSAL, buddy, nullptr, text);
        g->BroadcastPacket(&data, false);
        return;
    }
    buddy->Whisper(text, LANG_UNIVERSAL, owner);
}

static void ObeyAttack(HeardOrder const& h, Player* speaker)
{
    ChatHandler tell(speaker->GetSession());
    Unit* target = ObjectAccessor::GetUnit(*speaker, speaker->GetTarget());
    if (!target || !target->IsAlive() || !speaker->IsValidAttackTarget(target))
    {
        tell.SendSysMessage("Your buddies need a living enemy targeted to attack.");
        return;
    }
    std::set<std::string> wanted(h.names.begin(), h.names.end());
    uint32 sent = 0;
    for (auto const& [buddyGuid, ownerGuid] : BuddyRosterPairs())
    {
        if (ownerGuid != speaker->GetGUID().GetCounter())
            continue;
        if (!h.whisperedBuddy.IsEmpty() && h.whisperedBuddy.GetCounter() != buddyGuid)
            continue;
        Player* b = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(buddyGuid));
        if (!b || !b->IsInWorld() || !b->IsAlive())
            continue;
        std::string name = b->GetName();
        std::transform(name.begin(), name.end(), name.begin(), [](unsigned char c) { return char(std::tolower(c)); });
        if (!wanted.empty() && !wanted.erase(name))
            continue;
        if (PlayerbotAI* ai = GET_PLAYERBOT_AI(b))
            if (ai->DoSpecificAction("attack my target", Event(), true))
                ++sent;
    }
    for (std::string const& missing : wanted)
        tell.PSendSysMessage("No buddy of yours named {} is here to attack.", missing);
    LOG_INFO("module", "mod-buddies: {} ordered an attack on {}; {} buddies went", speaker->GetName(), target->GetName(), sent);
}

static void Obey(HeardOrder const& h)
{
    Player* speaker = ObjectAccessor::FindConnectedPlayer(h.speaker);
    if (!speaker || !speaker->IsInWorld())
        return;
    if (h.kind == OrderKind::Attack)
        return ObeyAttack(h, speaker);
    if (h.kind == OrderKind::Follow || h.kind == OrderKind::GoAway)
        return ObeyFollow(h, speaker);
    std::set<uint32> owners;
    owners.insert(speaker->GetGUID().GetCounter());
    if (Group* g = speaker->GetGroup())
        for (GroupReference* r = g->GetFirstMember(); r; r = r->next())
            if (Player* m = r->GetSource())
                if (!CompanionAccounts::Is(m->GetSession()->GetAccountId()))
                    owners.insert(m->GetGUID().GetCounter());

    uint32 going = 0;
    for (auto const& [buddyGuid, ownerGuid] : BuddyRosterPairs())
    {
        if (!owners.count(ownerGuid))
            continue;
        if (!h.whisperedBuddy.IsEmpty() && h.whisperedBuddy.GetCounter() != buddyGuid)
            continue;
        Player* b = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(buddyGuid));
        if (!b || !b->IsInWorld() || !b->IsAlive())
            continue;
        PlayerbotAI* ai = GET_PLAYERBOT_AI(b);
        uint32 slots = BuddyBagSlots(b);
        float share = (ai && slots) ? float(BuddyDisposableItems(ai, b).size()) / float(slots) : 0.0f;
        float yards = BuddyNearestVendorYards(b);
        bool goes = BuddySell::Goes(share, yards, h.everyone);
        Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(ownerGuid));
        if (owner && !h.everyone)
        {
            uint32 pct = uint32(share * 100.0f + 0.5f);
            std::string line = goes
                ? Acore::StringFormat("My bags are {}% full of things to sell, and the vendor is {}, so I'm just gonna go sell.", pct, BuddySell::HowFar(yards))
                : Acore::StringFormat("My bags are only {}% full of things to sell, and the vendor is {}, so I'll keep going.", pct, BuddySell::HowFar(yards));
            SayToOwner(b, owner, line.c_str());
        }
        if (!goes)
            continue;
        {
            std::lock_guard<std::mutex> lock(sOrdersLock);
            sToldToSell.insert(buddyGuid);
        }
        if (owner && h.everyone)
            SayToOwner(b, owner, GOING_LINE);
        ++going;
    }
    LOG_INFO("module", "mod-buddies: {} said \"{}go sell\"; {} buddies set off", speaker->GetName(), h.everyone ? "everyone " : "", going);
}

static void LookAtBags()
{
    for (auto const& [buddyGuid, ownerGuid] : BuddyRosterPairs())
    {
        Player* b = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(buddyGuid));
        if (!b || !b->IsInWorld())
            continue;
        if (BuddyBagFullness(b) < BuddyFullBagsShare())
        {
            sSaidFull.erase(buddyGuid);
            continue;
        }
        if (!sSaidFull.insert(buddyGuid).second)
            continue;
        if (Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(ownerGuid)))
            if (owner->IsInWorld())
                SayToOwner(b, owner, BAGS_FULL_LINE);
    }
}

class buddies_orders_player : public PlayerScript
{
public:
    buddies_orders_player() : PlayerScript("buddies_orders_player",
        { PLAYERHOOK_CAN_PLAYER_USE_CHAT, PLAYERHOOK_CAN_PLAYER_USE_GROUP_CHAT, PLAYERHOOK_CAN_PLAYER_USE_PRIVATE_CHAT,
          PLAYERHOOK_CAN_PLAYER_USE_GUILD_CHAT }) { }

    bool OnPlayerCanUseChat(Player* player, uint32 type, uint32 , std::string& msg) override
    {
        if (type == CHAT_MSG_SAY || type == CHAT_MSG_YELL)
            Hear(player, msg, ObjectGuid::Empty, type == CHAT_MSG_YELL ? Heard::Yell : Heard::Say);
        return true;
    }

    bool OnPlayerCanUseChat(Player* player, uint32 , uint32 , std::string& msg, Group* ) override
    {
        Hear(player, msg, ObjectGuid::Empty, Heard::Group);
        return true;
    }

    bool OnPlayerCanUseChat(Player* player, uint32 , uint32 , std::string& msg, Guild* ) override
    {
        Hear(player, msg, ObjectGuid::Empty, Heard::Guild);
        return true;
    }

    bool OnPlayerCanUseChat(Player* player, uint32 type, uint32 , std::string& msg, Player* receiver) override
    {
        if (type != CHAT_MSG_WHISPER || !receiver || !CompanionAccounts::Is(receiver->GetSession()->GetAccountId()))
            return true;
        Hear(player, msg, receiver->GetGUID(), Heard::Whisper);
        return true;
    }

private:
    static void Hear(Player* player, std::string const& msg, ObjectGuid buddy, Heard where)
    {
        if (!BuddiesEnabled() || CompanionAccounts::Is(player->GetSession()->GetAccountId()))
            return;
        HeardOrder h { player->GetGUID(), buddy, OrderKind::Sell, {}, where, false };
        OrderKind follow = OrderKind::Follow;
        std::string name;
        if (IsFollowOrder(msg, follow, name, h.hard, h.circle))
        {
            h.kind = follow;
            if (!name.empty())
                h.names.push_back(name);
        }
        else if (where == Heard::Guild)
            return;
        else if (IsAttack(msg, h.names))
            h.kind = OrderKind::Attack;
        else if (int sell = IsGoSell(msg))
            h.everyone = sell == 2;
        else
            return;
        std::lock_guard<std::mutex> lock(sOrdersLock);
        sHeard.push_back(h);
    }
};

class buddies_orders_world : public WorldScript
{
public:
    buddies_orders_world() : WorldScript("buddies_orders_world", { WORLDHOOK_ON_UPDATE }) { }

    void OnUpdate(uint32 diff) override
    {
        if (!BuddiesEnabled())
            return;
        std::vector<HeardOrder> heard;
        {
            std::lock_guard<std::mutex> lock(sOrdersLock);
            heard.swap(sHeard);
        }
        for (HeardOrder const& h : heard)
            Obey(h);

        _since += diff;
        if (_since < BAGS_LOOK_EVERY_MS)
            return;
        _since = 0;
        LookAtBags();
    }

private:
    uint32 _since = 0;
};

void AddSC_buddies_orders()
{
    new buddies_orders_player();
    new buddies_orders_world();
}
