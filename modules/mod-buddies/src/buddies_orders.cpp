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
 * Not built yet: "follow me" and "follow <name>" (617y's open question on
 * how a follow ends); the bot module's per-failure "My bags are full"
 * whisper stays silenced (B048), this one line said once replacing it.
 */

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

// {{{ tuning
static constexpr uint32 BAGS_LOOK_EVERY_MS = 5000;
static char const* const BAGS_FULL_LINE    = "My bags are full.";
static char const* const GOING_LINE        = "Off to sell. Come with me if you can.";
// }}}

// {{{ what is remembered
// Heard orders, waiting for the world's thread; buddies told to sell (taken
// by the selling trip as it sets off, BuddyTakeSellOrder); buddies that
// have said their bags are full, until the bags empty again.
enum class OrderKind : uint8 { Sell, Attack };
struct HeardOrder { ObjectGuid speaker; ObjectGuid whisperedBuddy; OrderKind kind = OrderKind::Sell; std::vector<std::string> names; };
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
        { PLAYERHOOK_CAN_PLAYER_USE_CHAT, PLAYERHOOK_CAN_PLAYER_USE_GROUP_CHAT, PLAYERHOOK_CAN_PLAYER_USE_PRIVATE_CHAT }) { }

    // /say (and yell): heard by the speaker's group's buddies
    bool OnPlayerCanUseChat(Player* player, uint32 type, uint32 /*lang*/, std::string& msg) override
    {
        if (type == CHAT_MSG_SAY || type == CHAT_MSG_YELL)
            Hear(player, msg, ObjectGuid::Empty);
        return true;
    }

    // party and raid chat
    bool OnPlayerCanUseChat(Player* player, uint32 /*type*/, uint32 /*lang*/, std::string& msg, Group* /*group*/) override
    {
        Hear(player, msg, ObjectGuid::Empty);
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
        Hear(player, msg, receiver->GetGUID());
        return true;
    }

private:
    // a player (not a buddy) saying "go sell" or "attack": noted for the
    // world's thread
    static void Hear(Player* player, std::string const& msg, ObjectGuid buddy)
    {
        if (!BuddiesEnabled() || CompanionAccounts::Is(player->GetSession()->GetAccountId()))
            return;
        HeardOrder h { player->GetGUID(), buddy };
        if (IsAttack(msg, h.names))
            h.kind = OrderKind::Attack;
        else if (!IsGoSell(msg))
            return;                                    // neither order: ordinary chat
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
