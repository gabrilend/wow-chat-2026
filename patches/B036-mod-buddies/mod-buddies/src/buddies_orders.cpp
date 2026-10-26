
#include "buddies.h"
#include "buddies_roam.h"
#include "buddies_town.h"
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

enum class OrderKind : uint8 { Sell, Attack };
struct HeardOrder { ObjectGuid speaker; ObjectGuid whisperedBuddy; OrderKind kind = OrderKind::Sell; std::vector<std::string> names; };
static std::mutex              sOrdersLock;
static std::vector<HeardOrder> sHeard;
static std::set<uint32>        sToldToSell;
static std::set<uint32>        sSaidFull;

bool BuddyTakeSellOrder(uint32 buddy)
{
    std::lock_guard<std::mutex> lock(sOrdersLock);
    return sToldToSell.erase(buddy) > 0;
}

static bool IsGoSell(std::string msg)
{
    std::transform(msg.begin(), msg.end(), msg.begin(), [](unsigned char c) { return std::tolower(c); });
    while (!msg.empty() && (std::ispunct(static_cast<unsigned char>(msg.back())) || std::isspace(static_cast<unsigned char>(msg.back()))))
        msg.pop_back();
    while (!msg.empty() && std::isspace(static_cast<unsigned char>(msg.front())))
        msg.erase(msg.begin());
    return msg == "go sell" || msg == "go sell please" || msg == "please go sell";
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
        if (!b || !b->IsInWorld() || !b->IsAlive() || BuddyBagFullness(b) < BuddyFullBagsShare())
            continue;
        {
            std::lock_guard<std::mutex> lock(sOrdersLock);
            sToldToSell.insert(buddyGuid);
        }
        if (Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(ownerGuid)))
            SayToOwner(b, owner, GOING_LINE);
        ++going;
    }
    LOG_INFO("module", "mod-buddies: {} said \"go sell\"; {} buddies with full bags set off", speaker->GetName(), going);
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
        { PLAYERHOOK_CAN_PLAYER_USE_CHAT, PLAYERHOOK_CAN_PLAYER_USE_GROUP_CHAT, PLAYERHOOK_CAN_PLAYER_USE_PRIVATE_CHAT }) { }

    bool OnPlayerCanUseChat(Player* player, uint32 type, uint32 , std::string& msg) override
    {
        if (type == CHAT_MSG_SAY || type == CHAT_MSG_YELL)
            Hear(player, msg, ObjectGuid::Empty);
        return true;
    }

    bool OnPlayerCanUseChat(Player* player, uint32 , uint32 , std::string& msg, Group* ) override
    {
        Hear(player, msg, ObjectGuid::Empty);
        return true;
    }

    bool OnPlayerCanUseChat(Player* player, uint32 type, uint32 , std::string& msg, Player* receiver) override
    {
        if (type != CHAT_MSG_WHISPER || !receiver || !CompanionAccounts::Is(receiver->GetSession()->GetAccountId()))
            return true;
        Hear(player, msg, receiver->GetGUID());
        return true;
    }

private:
    static void Hear(Player* player, std::string const& msg, ObjectGuid buddy)
    {
        if (!BuddiesEnabled() || CompanionAccounts::Is(player->GetSession()->GetAccountId()))
            return;
        HeardOrder h { player->GetGUID(), buddy };
        if (IsAttack(msg, h.names))
            h.kind = OrderKind::Attack;
        else if (!IsGoSell(msg))
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
