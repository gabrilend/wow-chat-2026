/*
 * buddies_trace.cpp - a movement trace for watching one buddy in game
 * (issue 617e2).
 *
 * For a general audience: roaming only writes to the log when something
 * fails, so a buddy that walks oddly (Mozonn, 2026-10-03, stepping between
 * two fixed spots 5 yards apart in Ammen Vale) leaves nothing to read. A
 * game master types ".buddy trace <buddy name>" and from then on that
 * buddy's movement is written down: twice a second where it stands and
 * where it is headed, a line each time its destination changes, and a line
 * from roaming itself at each decision (a waypoint picked, a leg ordered,
 * a detour, a meal). ".buddy trace off" stops every trace.
 *
 * The lines go to the bot module's own log channel ("playerbots", so
 * Playerbots.log), where the bot's engine already writes which action it
 * ran on every tick ("Mozonn A:buddy roam step - OK"). Its record of the
 * last action is private to it, so instead of asking it, the trace sits in
 * the same file: each movement line lands among the action lines that
 * caused it, in order.
 *
 * Nothing is kept across a restart: a trace is a question asked while
 * watching, not a setting.
 */

#include "buddies.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "Log.h"
#include "MotionMaster.h"
#include "MoveSpline.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldSession.h"
#include <cmath>
#include <mutex>
#include <unordered_map>

using namespace Acore::ChatCommands;

// {{{ tuning
static constexpr uint32 SAMPLE_MS       = 500;   // a "where is it" line this often
static constexpr float  NEW_DEST_YARDS  = 1.0f;  // a destination moved by more than this is a new destination
// }}}

// {{{ the traced buddies
// Kept per buddy (character guid, low part): the last destination seen,
// so a change can be told apart from the same order repeated. The bot
// module runs each bot's update on its own thread, so everything here is
// read and written under one lock.
struct TraceState
{
    uint32 sinceSample = 0;
    bool   hadDest     = false;     // whether a destination was seen before
    float  destX = 0.0f, destY = 0.0f, destZ = 0.0f;
};
static std::mutex                               sTraceLock;
static std::unordered_map<uint32, TraceState>   sTraced;

bool BuddyTraced(Player const* bot)
{
    std::lock_guard<std::mutex> lock(sTraceLock);
    return sTraced.count(bot->GetGUID().GetCounter()) != 0;
}

void BuddyTraceLine(Player const* bot, std::string const& text)
{
    LOG_INFO("playerbots", "{} TRACE {}", bot->GetName(), text);
}
// }}}

// {{{ MotionName
// The server's movement kinds by number (MotionMaster.h), for the line;
// a number with no name here is printed as the number.
static std::string MotionName(MovementGeneratorType type)
{
    static std::unordered_map<uint8, char const*> const names = {
        { IDLE_MOTION_TYPE,   "idle"   }, { RANDOM_MOTION_TYPE, "random" },
        { WAYPOINT_MOTION_TYPE, "path" }, { CONFUSED_MOTION_TYPE, "confused" },
        { CHASE_MOTION_TYPE,  "chase"  }, { HOME_MOTION_TYPE,   "home"   },
        { FLIGHT_MOTION_TYPE, "flight" }, { POINT_MOTION_TYPE,  "point"  },
        { FLEEING_MOTION_TYPE, "flee"  }, { FOLLOW_MOTION_TYPE, "follow" },
        { ROTATE_MOTION_TYPE, "rotate" }, { EFFECT_MOTION_TYPE, "effect (a jump or knockback)" },
    };
    auto it = names.find(uint8(type));
    return it != names.end() ? it->second : ("kind " + std::to_string(uint32(type)));
}
// }}}

// {{{ the sampler
class buddies_trace_player : public PlayerScript
{
public:
    buddies_trace_player() : PlayerScript("buddies_trace_player", { PLAYERHOOK_ON_UPDATE }) { }

    // Twice a second for a traced buddy: where it stands, and where its
    // current movement ends (the server's spline: the path the client is
    // shown). A destination more than a yard from the last one seen gets
    // its own line with the distance between them, so two destinations
    // taking turns show as alternating lines of about the same distance.
    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        if (!BuddiesEnabled() || !player->GetSession()->IsHeadless())
            return;                                     // only bots are traced; players never pay for the lookup below
        uint32 guid = player->GetGUID().GetCounter();

        bool  moving  = !player->movespline->Finalized();
        float x = 0.0f, y = 0.0f, z = 0.0f;
        if (moving)
        {
            G3D::Vector3 d = player->movespline->FinalDestination();
            x = d.x; y = d.y; z = d.z;
        }

        std::string sample, change;
        {
            std::lock_guard<std::mutex> lock(sTraceLock);
            auto it = sTraced.find(guid);
            if (it == sTraced.end())
                return;                                 // not traced: the common case
            TraceState& t = it->second;

            // a new destination: report at once, not at the next sample
            if (moving)
            {
                float jump = t.hadDest ? std::hypot(x - t.destX, y - t.destY) : -1.0f;
                if (jump < 0.0f || jump > NEW_DEST_YARDS)
                    change = jump < 0.0f
                        ? Acore::StringFormat("new destination ({:.1f}, {:.1f}, {:.1f}), the first seen", x, y, z)
                        : Acore::StringFormat("new destination ({:.1f}, {:.1f}, {:.1f}), {:.1f} yards from the previous", x, y, z, jump);
                t.hadDest = true;
                t.destX = x; t.destY = y; t.destZ = z;
            }

            t.sinceSample += diff;
            if (t.sinceSample >= SAMPLE_MS)
            {
                t.sinceSample = 0;
                sample = Acore::StringFormat("at ({:.1f}, {:.1f}, {:.1f}) {} by \"{}\"{}",
                    player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(),
                    moving ? "moving" : "standing",
                    MotionName(player->GetMotionMaster()->GetCurrentMovementGeneratorType()),
                    moving ? Acore::StringFormat(", headed for ({:.1f}, {:.1f}, {:.1f}), {:.1f} yards on",
                                 x, y, z, player->GetExactDist(x, y, z)) : std::string());
            }
        }
        // written outside the lock: logging may wait on its file
        if (!change.empty())
            BuddyTraceLine(player, change);
        if (!sample.empty())
            BuddyTraceLine(player, sample);
    }
};
// }}}

// {{{ the command
class buddies_trace_command : public CommandScript
{
public:
    buddies_trace_command() : CommandScript("buddies_trace_command") { }

    ChatCommandTable GetCommands() const override
    {
        // multi-word names join the ".buddy" table the beds file starts
        static ChatCommandTable commandTable =
        {
            { "buddy trace", HandleTrace, SEC_GAMEMASTER, Console::Yes },
        };
        return commandTable;
    }

    // ".buddy trace <buddy name>" starts tracing that buddy (it must be
    // online, and a buddy: a companion account's character); ".buddy
    // trace off" stops every trace. Each reply says what happened and
    // where the lines go.
    static bool HandleTrace(ChatHandler* handler, std::string name)
    {
        if (name == "off")
        {
            size_t n;
            {
                std::lock_guard<std::mutex> lock(sTraceLock);
                n = sTraced.size();
                sTraced.clear();
            }
            handler->PSendSysMessage("Buddy trace: stopped ({} buddy/buddies were traced).", n);
            return true;
        }
        if (!normalizePlayerName(name))
        {
            handler->PSendSysMessage("Buddy trace: \"{}\" is not a character name. Usage: .buddy trace <buddy name> | off", name);
            return false;
        }
        Player* bot = ObjectAccessor::FindPlayerByName(name, true);
        if (!bot)
        {
            handler->PSendSysMessage("Buddy trace: {} is not in the world. A buddy is in the world while its owner is online and near; log the owner in and try again.", name);
            return false;
        }
        if (!BuddyIsCompanionAccount(bot->GetSession()->GetAccountId()))
        {
            handler->PSendSysMessage("Buddy trace: {} is not a buddy (its account holds no owner's buddies); only buddies are traced.", name);
            return false;
        }
        {
            std::lock_guard<std::mutex> lock(sTraceLock);
            sTraced[bot->GetGUID().GetCounter()] = TraceState();
        }
        LOG_INFO("module", "mod-buddies: tracing {}'s movement into Playerbots.log (lines \"{} TRACE ...\")", name, name);
        handler->PSendSysMessage("Buddy trace: tracing {}. Lines \"{} TRACE ...\" go to Playerbots.log among its action lines; \".buddy trace off\" stops.", name, name);
        return true;
    }
};
// }}}

void AddSC_buddies_trace()
{
    new buddies_trace_player();
    new buddies_trace_command();
}
