/*
 * buddies_orders.cpp - spoken orders to buddies, and the word that their
 * bags are full (issue 617y).
 *
 * For a general audience: a buddy whose bags fill up says so once, "My
 * bags are full.", where its owner will see it; and a player may answer
 * "go sell", which sends every buddy with full bags to the nearest vendor
 * (the selling trip, 617h1, which no longer sets off by itself). The
 * owner, 2026-10-12: "we need the whisper to know when we should send
 * them"; "if any of them have full inventories they'll join the journey,
 * and if all of them do, the player might be forced to, especially if
 * they're somewhere dangerous like Outland."
 *
 * Who hears an order (owner, same day: "only people in the player's
 * party... or raid, maybe. >:)"): said in party or raid chat, or /say, it
 * reaches the buddies of every player in the speaker's party or raid (the
 * speaker's own when alone); whispered to a buddy, that buddy, when the
 * speaker is its owner or in its owner's group. "If one player in a raid
 * says "go sell" then any buddy-bots with full inventories will do so."
 *
 * Where a buddy speaks (owner: "the messages should go to the largest
 * groupsize log that a player is a part of - raid if in a raid, party if
 * in just a group with one or more player, and as a whisper if alone"):
 * its owner's raid chat, else its owner's party chat, else a whisper to
 * its owner. The message is sent to the group's members directly, so a
 * buddy roaming in a far party of its own still reaches its owner's.
 *
 * Flow: the chat hooks (inside the speaker's own chat, maybe off the
 * world's thread) only note what was heard; the world's update hook acts
 * on it, and every 5 seconds looks at each buddy's bags.
 *
 * "attack" (or "engage"), 2026-10-15 (owner: "There should be a macro
 * based command that tells my buddy-bots to 'attack my target' as in,
 * engage / and I should be able to name them by name..."): said in party,
 * raid or /say, every buddy of the speaker goes at the speaker's target;
 * "attack Zugsqonuw Usanda" sends only those named; whispered "attack" to
 * a buddy, that buddy. Only the speaker's own buddies obey (the target is
 * the speaker's). A macro line "/p attack" or "/w Zugsqonuw attack" is
 * the keybind. The bot module's own chat commands stay closed to buddies
 * (B045); this order reaches its attack action directly.
 *
 * "follow me", "follow <name>", "go away", "go away!", "shoo" (617y, the
 * owner 2026-10-23; 617e13, 2026-10-26/27): the buddies that hear it
 * follow the speaker (or the named player) in the following formation
 * (buddies_follow.cpp), until that player says "go away" or "shoo" (they
 * go back to their usual behaviour); "go away!" also keeps them from
 * following that player again until that player logs out. A bare "follow"
 * means nothing. Who hears, by where it is said (the owner, 2026-10-26:
 * "should apply to whatever context they hear it ... A DM is for just
 * them, and in guild chat it's all of them even if they aren't in a
 * party"; 2026-10-27, of /say: "Only to your buddy-bot clan"):
 *   party or raid chat - the buddies in that party or raid
 *   a whisper          - only the buddy whispered
 *   guild chat         - every buddy of the speaker's guild in the world
 *   /say, /yell        - the speaker's own buddies within hearing (the
 *                        server's own say and yell ranges)
 * "go away" and "shoo" reach the hearers following the speaker, and the
 * speaker's own buddies following anyone.
 *
 * The bot module's per-failure "My bags are full" whisper stays silenced
 * (B048), this one line said once replacing it.
 */

#include "buddies.h"
#include "buddies_roam.h"
#include "buddies_town.h"
#include "buddies_follow.h"
#include "roam/buddy_follow_core.h"
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

// {{{ tuning
static constexpr uint32 BAGS_LOOK_EVERY_MS = 5000;
static char const* const BAGS_FULL_LINE    = "My bags are full.";
static char const* const GOING_LINE        = "Off to sell. Come with me if you can.";
// }}}

// {{{ what is remembered
// Heard orders, waiting for the world's thread; buddies told to sell (taken
// by the selling trip as it sets off, BuddyTakeSellOrder); buddies that
// have said their bags are full, until the bags empty again.
enum class OrderKind : uint8 { Sell, Attack, Follow, GoAway };
// where an order was said, which decides who hears it (the follow orders)
enum class Heard : uint8 { Say, Yell, Group, Whisper, Guild };
struct HeardOrder
{
    ObjectGuid               speaker;
    ObjectGuid               whisperedBuddy;
    OrderKind                kind  = OrderKind::Sell;
    std::vector<std::string> names;                    // attack: the buddies named; follow: the player named (empty: "me")
    Heard                    where = Heard::Say;
    bool                     hard  = false;            // "go away!": not again until the speaker logs out
    bool                     circle = false;           // "circle me", "close follow": follow in the ring (617s2)
};
static std::mutex              sOrdersLock;
static std::vector<HeardOrder> sHeard;
static std::set<uint32>        sToldToSell;
static std::set<uint32>        sSaidFull;            // world thread only
// }}}

// {{{ BuddyTakeSellOrder
bool BuddyTakeSellOrder(uint32 buddy)
{
    std::lock_guard<std::mutex> lock(sOrdersLock);
    return sToldToSell.erase(buddy) > 0;
}
// }}}

// {{{ IsGoSell
// "go sell", any case, with or without trailing punctuation or a "please".
static bool IsGoSell(std::string msg)
{
    std::transform(msg.begin(), msg.end(), msg.begin(), [](unsigned char c) { return std::tolower(c); });
    while (!msg.empty() && (std::ispunct(static_cast<unsigned char>(msg.back())) || std::isspace(static_cast<unsigned char>(msg.back()))))
        msg.pop_back();
    while (!msg.empty() && std::isspace(static_cast<unsigned char>(msg.front())))
        msg.erase(msg.begin());
    return msg == "go sell" || msg == "go sell please" || msg == "please go sell";
}
// }}}

// {{{ IsAttack
// "attack" or "engage", any case, then any buddy names (lower-cased into
// `names`); punctuation and a "please" are dropped.
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
// }}}

// {{{ IsFollowOrder
// The words of a follow order, read by the following core
// (BuddyFollow::ReadOrder, roam/buddy_follow_core.h, where the test checks
// them).
static bool IsFollowOrder(std::string const& raw, OrderKind& kind, std::string& name, bool& hard, bool& circle)
{
    BuddyFollow::Order o = BuddyFollow::ReadOrder(raw, name, hard);
    if (o == BuddyFollow::Order::None)
        return false;
    // "circle me" is a follow of the speaker, in the ring
    circle = o == BuddyFollow::Order::Circle;
    kind = (o == BuddyFollow::Order::Follow || circle) ? OrderKind::Follow : OrderKind::GoAway;
    return true;
}
// }}}

// {{{ Hearers
// The buddies a follow order reaches, by where it was said (see the top).
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
// }}}

// {{{ ObeyFollow
// One heard follow order, carried out by each buddy that hears it.
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
            for (Player* p : hearers)                  // a buddy of the hearers, by name
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
                continue;                              // a buddy told to follow itself stays as it is
            if (BuddyFollowRefused(b->GetGUID().GetCounter(), leader->GetGUID().GetCounter()))
            {
                ++refusing;
                continue;
            }
            BuddyFollowSet(b->GetGUID().GetCounter(), leader->GetGUID().GetCounter());
            BuddyFollowSetRing(b->GetGUID().GetCounter(), h.circle);   // "follow me" ends a ring, "circle me" starts one
            ++following;
        }
        tell.PSendSysMessage("{} {} following {}{}.", following, following == 1 ? "buddy is" : "buddies are", leader->GetName(),
                             refusing ? " (" + std::to_string(refusing) + " were sent away and won't until " + leader->GetName() + " logs out)" : "");
        LOG_INFO("module", "mod-buddies: {} said follow {}; {} buddies follow, {} refused", speaker->GetName(), leader->GetName(), following, refusing);
        return;
    }
    // go away / shoo: the hearers following the speaker, and the speaker's
    // own buddies following anyone
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
// }}}

// {{{ SayToOwner
// The buddy's line where its owner will see it: the owner's raid, else
// party, else a whisper.
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
// }}}

// {{{ ObeyAttack
// One heard "attack": the speaker's buddies (those named, or the one
// whispered) go at the speaker's target, through the bot module's own
// "attack my target" action (their master is the speaker).
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
            continue;                                  // only the speaker's own buddies
        if (!h.whisperedBuddy.IsEmpty() && h.whisperedBuddy.GetCounter() != buddyGuid)
            continue;                                  // whispered to one buddy: only that one
        Player* b = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(buddyGuid));
        if (!b || !b->IsInWorld() || !b->IsAlive())
            continue;
        std::string name = b->GetName();
        std::transform(name.begin(), name.end(), name.begin(), [](unsigned char c) { return char(std::tolower(c)); });
        if (!wanted.empty() && !wanted.erase(name))
            continue;                                  // names given, and not this one
        if (PlayerbotAI* ai = GET_PLAYERBOT_AI(b))
            if (ai->DoSpecificAction("attack my target", Event(), true))
                ++sent;
    }
    for (std::string const& missing : wanted)
        tell.PSendSysMessage("No buddy of yours named {} is here to attack.", missing);
    LOG_INFO("module", "mod-buddies: {} ordered an attack on {}; {} buddies went", speaker->GetName(), target->GetName(), sent);
}
// }}}

// {{{ Obey
// One heard "go sell": every buddy it reaches with full bags is told to go.
static void Obey(HeardOrder const& h)
{
    Player* speaker = ObjectAccessor::FindConnectedPlayer(h.speaker);
    if (!speaker || !speaker->IsInWorld())
        return;
    if (h.kind == OrderKind::Attack)
        return ObeyAttack(h, speaker);
    if (h.kind == OrderKind::Follow || h.kind == OrderKind::GoAway)
        return ObeyFollow(h, speaker);
    std::set<uint32> owners;                           // whose buddies hear it
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
            continue;                                  // whispered to one buddy: only that one
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
// }}}

// {{{ LookAtBags
// Each online buddy whose bags have just become full says so, once, until
// they are below full again.
static void LookAtBags()
{
    for (auto const& [buddyGuid, ownerGuid] : BuddyRosterPairs())
    {
        Player* b = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(buddyGuid));
        if (!b || !b->IsInWorld())
            continue;
        if (BuddyBagFullness(b) < BuddyFullBagsShare())
        {
            sSaidFull.erase(buddyGuid);                // room again: the next filling is said again
            continue;
        }
        if (!sSaidFull.insert(buddyGuid).second)
            continue;                                  // said already
        if (Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(ownerGuid)))
            if (owner->IsInWorld())
                SayToOwner(b, owner, BAGS_FULL_LINE);
    }
}
// }}}

// {{{ the hearing
class buddies_orders_player : public PlayerScript
{
public:
    buddies_orders_player() : PlayerScript("buddies_orders_player",
        { PLAYERHOOK_CAN_PLAYER_USE_CHAT, PLAYERHOOK_CAN_PLAYER_USE_GROUP_CHAT, PLAYERHOOK_CAN_PLAYER_USE_PRIVATE_CHAT,
          PLAYERHOOK_CAN_PLAYER_USE_GUILD_CHAT }) { }

    // /say (and yell): the sell and attack orders reach the speaker's
    // group's buddies; the follow orders, the speaker's own within hearing
    bool OnPlayerCanUseChat(Player* player, uint32 type, uint32 /*lang*/, std::string& msg) override
    {
        if (type == CHAT_MSG_SAY || type == CHAT_MSG_YELL)
            Hear(player, msg, ObjectGuid::Empty, type == CHAT_MSG_YELL ? Heard::Yell : Heard::Say);
        return true;
    }

    // party and raid chat
    bool OnPlayerCanUseChat(Player* player, uint32 /*type*/, uint32 /*lang*/, std::string& msg, Group* /*group*/) override
    {
        Hear(player, msg, ObjectGuid::Empty, Heard::Group);
        return true;
    }

    // guild chat: the follow orders only, heard by the guild's buddies
    bool OnPlayerCanUseChat(Player* player, uint32 /*type*/, uint32 /*lang*/, std::string& msg, Guild* /*guild*/) override
    {
        Hear(player, msg, ObjectGuid::Empty, Heard::Guild);
        return true;
    }

    // a whisper to one buddy: that buddy, when the speaker is its owner or
    // in its owner's group
    bool OnPlayerCanUseChat(Player* player, uint32 type, uint32 /*lang*/, std::string& msg, Player* receiver) override
    {
        if (type != CHAT_MSG_WHISPER || !receiver || !CompanionAccounts::Is(receiver->GetSession()->GetAccountId()))
            return true;
        // whether the speaker may order it (its owner, or in its owner's
        // group) is settled on the world's thread (Obey), where groups are
        // safe to read
        Hear(player, msg, receiver->GetGUID(), Heard::Whisper);
        return true;
    }

private:
    // a player (not a buddy) saying an order: noted for the world's thread
    // (guild chat carries only the follow orders)
    static void Hear(Player* player, std::string const& msg, ObjectGuid buddy, Heard where)
    {
        if (!BuddiesEnabled() || CompanionAccounts::Is(player->GetSession()->GetAccountId()))
            return;
        // every field named: a sell order until the readers below say
        // otherwise (two given and two left to their defaults made the
        // compiler warn, -Wmissing-field-initializers, 2026-10-26)
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
            return;                                    // guild chat: only the follow orders
        else if (IsAttack(msg, h.names))
            h.kind = OrderKind::Attack;
        else if (!IsGoSell(msg))
            return;                                    // no order: ordinary chat
        std::lock_guard<std::mutex> lock(sOrdersLock);
        sHeard.push_back(h);
    }
};
// }}}

// {{{ the acting
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
// }}}

// {{{ AddSC_buddies_orders
void AddSC_buddies_orders()
{
    new buddies_orders_player();
    new buddies_orders_world();
}
// }}}
