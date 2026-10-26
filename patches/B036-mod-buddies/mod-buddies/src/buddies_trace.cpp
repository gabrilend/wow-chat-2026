
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

static constexpr uint32 SAMPLE_MS       = 500;
static constexpr float  NEW_DEST_YARDS  = 1.0f;

struct TraceState
{
    uint32 sinceSample = 0;
    bool   hadDest     = false;
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

class buddies_trace_player : public PlayerScript
{
public:
    buddies_trace_player() : PlayerScript("buddies_trace_player", { PLAYERHOOK_ON_UPDATE }) { }

    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        if (!BuddiesEnabled() || !player->GetSession()->IsHeadless())
            return;
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
                return;
            TraceState& t = it->second;

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
        if (!change.empty())
            BuddyTraceLine(player, change);
        if (!sample.empty())
            BuddyTraceLine(player, sample);
    }
};

class buddies_trace_command : public CommandScript
{
public:
    buddies_trace_command() : CommandScript("buddies_trace_command") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "buddy trace", HandleTrace, SEC_GAMEMASTER, Console::Yes },
        };
        return commandTable;
    }

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

void AddSC_buddies_trace()
{
    new buddies_trace_player();
    new buddies_trace_command();
}
