/*
 * buddies_board.cpp - a buddy's bulletin board (issue 165).
 *
 * For a general audience: the owner, 2026-10-30: "buddies should be aware
 * of everything within 70 yards of them. They should all be on the concern
 * list. So, radius triggers only to put things up on the mental bulletin
 * board, or remove them if they're far enough away." Each buddy carries
 * one radius trigger, 70 yards with 5 of slack, whose only actions are
 * "pin" and "unpin" (roam/buddy_radius_core.h). What it does about what is
 * pinned is decided elsewhere, from the board; nothing reads it yet but
 * ".buddy board".
 *
 * Where the stream comes from: whenever something moves far enough, the
 * server updates what each nearby player sees of it, and source patch B067
 * calls RadiusSeenHook there with the player and the thing. This file sets
 * that pointer at start-up when Buddies.Board is 1, and listens only when
 * the player is a buddy (its account on the companion list, a fast set).
 * Nothing polls for arrivals.
 *
 * One look on a timer remains, every PRUNE_MS: a thing that leaves the
 * world (despawned, logged out, teleported away) is never seen moving off,
 * so the world pass takes down pins whose thing is gone, on another map, or
 * beyond the radius and its slack (a boss in its fight and a flag carrier
 * stay, as the core says). It only looks at pins already up.
 */

#include "buddies.h"
#include "buddies_board.h"
#include "roam/buddy_radius_core.h"
#include "Chat.h"
#include "CommandScript.h"
#include "CompanionAccounts.h"
#include "Config.h"
#include "GameTime.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include <mutex>
#include <unordered_map>

using namespace Acore::ChatCommands;

// defined by source patch B067 (PlayerUpdates.cpp)
extern void (*RadiusSeenHook)(Player* seer, WorldObject* target);

static constexpr float  BOARD_YARDS = 70.0f;           // "everything within 70 yards"
static constexpr float  BOARD_SLACK = 5.0f;            // past 75 yards it comes down (the 60/75 grouping's kind of slack)
static constexpr uint32 PRUNE_MS    = 10000;

static std::mutex sBoardLock;
static BuddyRadius::Registry sRegistry;                // under sBoardLock
static std::unordered_map<uint64, BuddyRadius::Board> sBoards;   // buddy (raw guid) -> its board; under sBoardLock
static bool sBoardOn = false;

// {{{ AsUnit
// The core's view of a unit: its id, kinds and place.
static BuddyRadius::Unit AsUnit(Unit const* u)
{
    BuddyRadius::Unit b;
    b.id = u->GetGUID().GetRawValue();
    if (Player const* p = u->ToPlayer())
    {
        b.kinds = BuddyRadius::UNIT_PLAYER;
        if (p->GetSession() && CompanionAccounts::Is(p->GetSession()->GetAccountId()))
            b.kinds |= BuddyRadius::UNIT_BUDDY;
    }
    else
    {
        b.kinds = BuddyRadius::UNIT_CREATURE;
        b.entry = u->GetEntry();
    }
    b.x = u->GetPositionX();
    b.y = u->GetPositionY();
    b.z = u->GetPositionZ();
    return b;
}
// }}}

// {{{ OnSeen
// The server's pass: `seer` now sees `target` where it stands. A buddy's
// board trigger is made the first time it is needed. Each path:
//   the seer not a buddy, or the target not a living unit  - nothing
//   the trigger's answer                                    - pin / unpin
static void OnSeen(Player* seer, WorldObject* target)
{
    if (!seer->GetSession() || !CompanionAccounts::Is(seer->GetSession()->GetAccountId()))
        return;
    Unit* u = target->ToUnit();
    if (!u || !u->IsAlive())
        return;
    BuddyRadius::Unit b = AsUnit(u);
    uint64 me = seer->GetGUID().GetRawValue();
    uint64 now = GameTime::GetGameTimeMS().count();
    std::lock_guard<std::mutex> lock(sBoardLock);
    if (!sRegistry.Has(me))
        sRegistry.Add(me, BuddyRadius::BoardTrigger(BOARD_YARDS, BOARD_SLACK));
    for (BuddyRadius::Call const& call : sRegistry.Moved(me, seer->GetPositionX(), seer->GetPositionY(), seer->GetPositionZ(), b))
    {
        if (call.action.name == "pin")
            sBoards[me].PinUnit(b, now);
        else if (call.action.name == "unpin")
            sBoards[me].Unpin(b.id);
    }
}
// }}}

// {{{ BuddyBoardHas, BuddyBoardCount
bool BuddyBoardHas(Player* buddy, ObjectGuid thing)
{
    std::lock_guard<std::mutex> lock(sBoardLock);
    auto it = sBoards.find(buddy->GetGUID().GetRawValue());
    return it != sBoards.end() && it->second.Has(thing.GetRawValue());
}

void BuddyBoardCount(Player* buddy, uint32& players, uint32& buddies, uint32& creatures)
{
    players = buddies = creatures = 0;
    std::lock_guard<std::mutex> lock(sBoardLock);
    auto it = sBoards.find(buddy->GetGUID().GetRawValue());
    if (it == sBoards.end())
        return;
    for (uint64 id : it->second.Ids())
    {
        BuddyRadius::Pin const* p = it->second.Get(id);
        if (p->kinds & BuddyRadius::UNIT_PLAYER)   ++players;
        if (p->kinds & BuddyRadius::UNIT_BUDDY)    ++buddies;
        if (p->kinds & BuddyRadius::UNIT_CREATURE) ++creatures;
    }
}
// }}}

// {{{ buddies_board_world
class buddies_board_world : public WorldScript
{
public:
    buddies_board_world() : WorldScript("buddies_board_world", { WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_UPDATE }) { }

    // the switch, read once: on, the server's pass is listened to
    void OnStartup() override
    {
        sBoardOn = sConfigMgr->GetOption<bool>("Buddies.Board", false, false);
        if (sBoardOn)
            RadiusSeenHook = &OnSeen;
        LOG_INFO("module", ">> mod-buddies: the bulletin board (165) is {}", sBoardOn ? "on (Buddies.Board = 1)" : "off (Buddies.Board = 0)");
    }

    // the prune (see the header): pins whose thing is gone, elsewhere, or
    // past the radius and slack come down; a buddy gone takes its board
    void OnUpdate(uint32 diff) override
    {
        if (!sBoardOn)
            return;
        _since += diff;
        if (_since < PRUNE_MS)
            return;
        _since = 0;
        std::lock_guard<std::mutex> lock(sBoardLock);
        for (auto it = sBoards.begin(); it != sBoards.end();)
        {
            Player* buddy = ObjectAccessor::FindConnectedPlayer(ObjectGuid(it->first));
            if (!buddy || !buddy->IsInWorld())
            {
                sRegistry.Remove(it->first);
                it = sBoards.erase(it);
                continue;
            }
            for (uint64 id : it->second.Ids())
            {
                Unit* u = ObjectAccessor::GetUnit(*buddy, ObjectGuid(id));
                if (!u || !u->IsInWorld() || !u->IsAlive() || u->GetMapId() != buddy->GetMapId()
                    || buddy->GetExactDist(u) > BOARD_YARDS + BOARD_SLACK)
                {
                    it->second.Unpin(id);              // a sticky or always-kept pin stays (the core's rule)
                    sRegistry.Forget(id);
                }
            }
            ++it;
        }
    }

private:
    uint32 _since = 0;
};
// }}}

// {{{ .buddy board
class buddies_board_command : public CommandScript
{
public:
    buddies_board_command() : CommandScript("buddies_board_command") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "buddy board", HandleBoard, SEC_GAMEMASTER, Console::Yes },
        };
        return commandTable;
    }

    // ".buddy board <buddy name>": how many players, buddies and creatures
    // are on its board now
    static bool HandleBoard(ChatHandler* handler, std::string name)
    {
        if (!sBoardOn)
        {
            handler->SendSysMessage("The bulletin board is off (Buddies.Board = 0 in worldserver.conf).");
            return false;
        }
        if (!normalizePlayerName(name))
        {
            handler->PSendSysMessage("\"{}\" is not a character name.", name);
            return false;
        }
        Player* buddy = ObjectAccessor::FindPlayerByName(name);
        if (!buddy)
        {
            handler->PSendSysMessage("{} is not in the world.", name);
            return false;
        }
        uint32 players, buddies, creatures;
        BuddyBoardCount(buddy, players, buddies, creatures);
        handler->PSendSysMessage("{}'s board: {} players ({} of them buddies), {} creatures within {:.0f} yards.",
            name, players, buddies, creatures, BOARD_YARDS);
        return true;
    }
};
// }}}

void AddSC_buddies_board()
{
    new buddies_board_world();
    new buddies_board_command();
}
