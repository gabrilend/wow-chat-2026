
#include "buddies.h"
#include "buddies_crossing.h"
#include "buddies_recorder.h"
#include "Chat.h"
#include "CommandScript.h"
#include "DatabaseEnv.h"
#include "GameObject.h"
#include "GameTime.h"
#include "Log.h"
#include "Map.h"
#include "MotionMaster.h"
#include "MoveSpline.h"
#include "ObjectMgr.h"
#include "Opcodes.h"
#include "Player.h"
#include "QueryResult.h"
#include "ScriptMgr.h"
#include "Transport.h"
#include "WorldSession.h"
#include <algorithm>
#include <atomic>
#include <cmath>
#include <map>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

using namespace Acore::ChatCommands;

static constexpr float  KEEP_YARDS        = 1.0f;
static constexpr float  KEEP_TURN_RAD     = 0.3f;
static constexpr uint32 MAX_STEPS         = 1500;
static constexpr float  STOP_REACH_YARDS  = 60.0f;
static constexpr float  LIST_YARDS        = 150.0f;
static constexpr uint32 LEG_MIN_MS        = 250;
static constexpr float  LEG_SLACK         = 1.5f;
static constexpr uint32 LEG_EXTRA_MS      = 2000;
static constexpr float  ARRIVED_YARDS     = 1.5f;
static constexpr uint8  LEG_RETRIES       = 2;

struct Step
{
    uint32 ms     = 0;
    uint8  flags  = 0;
    float  x = 0.0f, y = 0.0f, z = 0.0f, o = 0.0f;
    float  jumpXY = 0.0f, jumpZ = 0.0f;
};

struct Boarding
{
    uint32            id     = 0;
    uint8             kind   = 0;
    uint32            entry  = 0;
    uint8             stop   = 0;
    uint32            mapId  = 0;
    std::string       author;
    std::string       note;
    std::vector<Step> steps;
};

static std::mutex                         sRecLock;
static std::map<uint32, Boarding>         sBoardings;
static bool                               sLoaded = false;
static std::unordered_map<uint32, uint32> sHeldBy;
static std::unordered_map<uint32, uint32> sHolds;

static uint64 NowMs() { return uint64(GameTime::GetGameTimeMS().count()); }

static void LoadLocked()
{
    sBoardings.clear();
    if (QueryResult rows = WorldDatabase.Query("SELECT id, kind, transport, stop, map, author, note FROM buddy_boarding"))
        do
        {
            Field* f = rows->Fetch();
            Boarding b;
            b.id     = f[0].Get<uint32>();
            b.kind   = f[1].Get<uint8>();
            b.entry  = f[2].Get<uint32>();
            b.stop   = f[3].Get<uint8>();
            b.mapId  = f[4].Get<uint32>();
            b.author = f[5].Get<std::string>();
            b.note   = f[6].Get<std::string>();
            sBoardings[b.id] = b;
        } while (rows->NextRow());
    if (QueryResult rows = WorldDatabase.Query(
            "SELECT boarding, ms, flags, x, y, z, o, jump_xy, jump_z FROM buddy_boarding_step ORDER BY boarding, seq"))
        do
        {
            Field* f = rows->Fetch();
            auto it = sBoardings.find(f[0].Get<uint32>());
            if (it == sBoardings.end())
                continue;
            Step s;
            s.ms     = f[1].Get<uint32>();
            s.flags  = f[2].Get<uint8>();
            s.x      = f[3].Get<float>();
            s.y      = f[4].Get<float>();
            s.z      = f[5].Get<float>();
            s.o      = f[6].Get<float>();
            s.jumpXY = f[7].Get<float>();
            s.jumpZ  = f[8].Get<float>();
            it->second.steps.push_back(s);
        } while (rows->NextRow());
    for (auto it = sBoardings.begin(); it != sBoardings.end();)
    {
        if (it->second.steps.size() < 2)
        {
            LOG_ERROR("module", "mod-buddies: boarding recording {} has {} step(s) in buddy_boarding_step and is not used "
                "(to debug: was the table edited by hand? delete it with .buddy record delete {})",
                it->first, it->second.steps.size(), it->first);
            it = sBoardings.erase(it);
        }
        else
            ++it;
    }
    sLoaded = true;
    LOG_INFO("module", "mod-buddies: {} boarding recording(s) loaded (617e9)", sBoardings.size());
}

static void EnsureLoadedLocked()
{
    if (!sLoaded)
        LoadLocked();
}

struct Capture
{
    uint64            began     = 0;
    uint32            mapId     = 0;
    std::vector<Step> steps;
    bool              lastDeck  = false;
    ObjectGuid        ship;
    uint32            entry     = 0;
    float             shipX = 0.0f, shipY = 0.0f;
    uint32            crossings = 0;
    std::string       bad;
};
static std::unordered_map<uint32, Capture> sCaptures;
static std::atomic<uint32> sRecordingCount{0};

static float AngleGap(float a, float b)
{
    float d = std::fabs(a - b);
    return d > float(M_PI) ? float(2.0 * M_PI) - d : d;
}

class buddies_recorder_movement : public MovementHandlerScript
{
public:
    buddies_recorder_movement() : MovementHandlerScript("buddies_recorder_movement", { MOVEMENTHOOK_ON_PLAYER_MOVE }) { }

    void OnPlayerMove(Player* player, MovementInfo info, uint32 opcode) override
    {
        if (sRecordingCount == 0)
            return;
        std::lock_guard<std::mutex> lock(sRecLock);
        auto it = sCaptures.find(player->GetGUID().GetCounter());
        if (it == sCaptures.end())
            return;
        Capture& c = it->second;
        if (!c.bad.empty())
            return;

        if (player->GetMapId() != c.mapId)
        {
            c.bad = "the map changed during the recording (the ship sailed, or a teleport): stop before it leaves";
            return;
        }

        bool deck = info.HasMovementFlag(MOVEMENTFLAG_ONTRANSPORT) && !info.transport.guid.IsEmpty();
        if (deck)
        {
            if (c.ship.IsEmpty())
            {
                Transport* t = player->GetMap()->GetTransport(info.transport.guid);
                MotionTransport* mt = t ? t->ToMotionTransport() : nullptr;
                if (!mt)
                {
                    c.bad = "stood on something that is not a boat or zeppelin (an elevator?)";
                    return;
                }
                c.ship  = info.transport.guid;
                c.entry = mt->GetEntry();
                c.shipX = mt->GetPositionX();
                c.shipY = mt->GetPositionY();
            }
            else if (c.ship != info.transport.guid)
            {
                c.bad = "stood on two different ships";
                return;
            }
        }

        Step s;
        s.ms    = uint32(NowMs() - c.began);
        s.flags = (deck ? BUDDY_STEP_DECK : 0)
                | (opcode == MSG_MOVE_JUMP ? BUDDY_STEP_JUMP : 0)
                | (opcode == MSG_MOVE_FALL_LAND ? BUDDY_STEP_LAND : 0)
                | (info.HasMovementFlag(MOVEMENTFLAG_WALKING) ? BUDDY_STEP_WALK : 0);
        Position const& p = deck ? info.transport.pos : info.pos;
        p.GetPosition(s.x, s.y, s.z, s.o);
        if (s.flags & BUDDY_STEP_JUMP)
        {
            s.jumpXY = info.jump.xyspeed;
            s.jumpZ  = info.jump.zspeed;
        }

        bool keep = c.steps.empty() || (s.flags & (BUDDY_STEP_JUMP | BUDDY_STEP_LAND)) || deck != c.lastDeck
                 || opcode == MSG_MOVE_STOP;
        if (!keep)
        {
            Step const& last = c.steps.back();
            float dx = s.x - last.x, dy = s.y - last.y, dz = s.z - last.z;
            keep = std::sqrt(dx * dx + dy * dy + dz * dz) >= KEEP_YARDS || AngleGap(s.o, last.o) >= KEEP_TURN_RAD;
        }
        if (!keep)
            return;
        if (!c.steps.empty() && deck != c.lastDeck)
            ++c.crossings;
        c.lastDeck = deck;
        c.steps.push_back(s);
        if (c.steps.size() > MAX_STEPS)
            c.bad = "longer than " + std::to_string(MAX_STEPS) + " steps (was \".buddy record stop\" forgotten?)";
    }
};

bool BuddyBoardingPick(uint8 kind, uint32 entry, uint8 stop, Player* bot, BuddyReplay& replay, BuddyBoardingStart& start)
{
    std::lock_guard<std::mutex> lock(sRecLock);
    EnsureLoadedLocked();
    uint32 guid = bot->GetGUID().GetCounter();

    auto held = sHolds.find(guid);
    if (held != sHolds.end())
    {
        sHeldBy.erase(held->second);
        sHolds.erase(held);
    }

    Boarding const* best     = nullptr;
    bool            bestFree = false;
    float           bestDist = 0.0f;
    for (auto const& [id, b] : sBoardings)
    {
        if (b.kind != kind || b.entry != entry || b.stop != stop)
            continue;
        Step const& s0 = b.steps.front();
        bool  free = sHeldBy.find(id) == sHeldBy.end();
        float d    = kind == BUDDY_BOARD_EMBARK ? bot->GetExactDist(s0.x, s0.y, s0.z)
                                                : std::sqrt(s0.x * s0.x + s0.y * s0.y);
        if (!best || (free && !bestFree) || (free == bestFree && d < bestDist))
        {
            best     = &b;
            bestFree = free;
            bestDist = d;
        }
    }
    if (!best)
        return false;

    sHeldBy[best->id] = guid;
    sHolds[guid]      = best->id;
    replay            = BuddyReplay();
    replay.id         = best->id;
    Step const& s0    = best->steps.front();
    start             = { best->mapId, s0.x, s0.y, s0.z, s0.o };
    return true;
}

void BuddyBoardingRelease(uint32 buddyGuid)
{
    std::lock_guard<std::mutex> lock(sRecLock);
    auto held = sHolds.find(buddyGuid);
    if (held == sHolds.end())
        return;
    sHeldBy.erase(held->second);
    sHolds.erase(held);
}

BuddyReplayResult BuddyReplayStep(Player* bot, MotionTransport* mt, BuddyReplay& replay, std::string& why)
{
    std::lock_guard<std::mutex> lock(sRecLock);
    EnsureLoadedLocked();
    auto it = sBoardings.find(replay.id);
    if (it == sBoardings.end())
    {
        why = "recording " + std::to_string(replay.id) + " is gone (deleted while in use?)";
        return BuddyReplayResult::Failed;
    }
    std::vector<Step> const& steps = it->second.steps;
    uint64 now = NowMs();

    auto worldOf = [mt](Step const& s, float& x, float& y, float& z, float& o)
    {
        x = s.x; y = s.y; z = s.z; o = s.o;
        if (s.flags & BUDDY_STEP_DECK)
            mt->CalculatePassengerPosition(x, y, z, &o);
    };

    if (replay.legStarted)
    {
        bool done = now - replay.legStarted >= LEG_MIN_MS && bot->movespline->Finalized();
        if (!done)
        {
            if (now - replay.legStarted <= replay.legLimitMs)
                return BuddyReplayResult::Running;
            why = "the leg to step " + std::to_string(replay.next) + " of " + std::to_string(steps.size()) +
                  " of recording " + std::to_string(replay.id) + " did not finish in " +
                  std::to_string(replay.legLimitMs / 1000) + " s";
            return BuddyReplayResult::Failed;
        }
        Step const& reached = steps[replay.next];
        float x, y, z, o;
        worldOf(reached, x, y, z, o);
        if (bot->GetExactDist(x, y, z) > ARRIVED_YARDS)
        {
            if (replay.retries >= LEG_RETRIES)
            {
                why = "kept ending short of step " + std::to_string(replay.next) + " of recording " +
                      std::to_string(replay.id) + " (" + std::to_string(int(bot->GetExactDist(x, y, z))) + " yards off)";
                return BuddyReplayResult::Failed;
            }
            ++replay.retries;
            replay.legStarted = 0;
        }
        else
        {
            if ((reached.flags & BUDDY_STEP_DECK) && bot->GetTransport() != mt)
                mt->AddPassenger(bot, true);
            replay.legStarted = 0;
            replay.retries    = 0;
            ++replay.next;
        }
    }

    if (replay.next >= steps.size())
    {
        float x, y, z, o;
        worldOf(steps.back(), x, y, z, o);
        bot->SetFacingTo(o);
        return BuddyReplayResult::Done;
    }

    uint32 target   = replay.next;
    uint32 jumpFrom = target > 0 ? target - 1 : 0;
    bool   jump     = target > 0 && (steps[jumpFrom].flags & BUDDY_STEP_JUMP);
    if (jump)
        while (target + 1 < steps.size() && !(steps[target].flags & BUDDY_STEP_LAND))
            ++target;
    replay.next = target;
    Step const& to = steps[target];

    if (!(to.flags & BUDDY_STEP_DECK) && bot->GetTransport() == mt)
        mt->RemovePassenger(bot, true);

    float x, y, z, o;
    worldOf(to, x, y, z, o);
    bool  walk  = to.flags & BUDDY_STEP_WALK;
    bot->SetWalk(walk);
    float speed = std::max(0.5f, bot->GetSpeed(walk ? MOVE_WALK : MOVE_RUN));
    float dist  = bot->GetExactDist(x, y, z);
    if (jump)
    {
        Step const& from = steps[jumpFrom];
        float xy = from.jumpXY > 0.1f ? from.jumpXY : speed;
        float zs = from.jumpZ  > 0.1f ? from.jumpZ  : 7.96f;
        bot->GetMotionMaster()->MoveJump(x, y, z, xy, zs);
        replay.legLimitMs = uint32(dist / xy * 1000.0f * LEG_SLACK) + LEG_EXTRA_MS;
    }
    else
    {
        bot->GetMotionMaster()->MovePoint(0, x, y, z, FORCED_MOVEMENT_NONE, 0.0f, o,  false,
             true);
        replay.legLimitMs = uint32(dist / speed * 1000.0f * LEG_SLACK) + LEG_EXTRA_MS;
    }
    replay.legStarted = now;
    return BuddyReplayResult::Running;
}

class buddies_recorder_command : public CommandScript
{
public:
    buddies_recorder_command() : CommandScript("buddies_recorder_command") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "buddy record start",   HandleStart,   SEC_GAMEMASTER, Console::No },
            { "buddy record stop",    HandleStop,    SEC_GAMEMASTER, Console::No },
            { "buddy record discard", HandleDiscard, SEC_GAMEMASTER, Console::No },
            { "buddy record list",    HandleList,    SEC_GAMEMASTER, Console::No },
            { "buddy record delete",  HandleDelete,  SEC_GAMEMASTER, Console::No },
        };
        return commandTable;
    }

    static char const* KindName(uint8 kind)
    {
        static char const* const names[] = { "?", "embark", "disembark" };
        return kind <= BUDDY_BOARD_DISEMBARK ? names[kind] : "?";
    }

    static std::string ShipName(uint32 entry)
    {
        GameObjectTemplate const* t = sObjectMgr->GetGameObjectTemplate(entry);
        return t ? t->name : ("ship " + std::to_string(entry));
    }

    static bool HandleStart(ChatHandler* handler)
    {
        Player* gm = handler->GetPlayer();
        std::lock_guard<std::mutex> lock(sRecLock);
        Capture c;
        c.began = NowMs();
        c.mapId = gm->GetMapId();
        Step s;
        Transport* t = gm->GetTransport();
        MotionTransport* mt = t ? t->ToMotionTransport() : nullptr;
        if (t && !mt)
        {
            handler->SendSysMessage("You are standing on an elevator, not a boat or zeppelin. Step off it and start again.");
            return true;
        }
        if (mt)
        {
            c.ship  = mt->GetGUID();
            c.entry = mt->GetEntry();
            c.shipX = mt->GetPositionX();
            c.shipY = mt->GetPositionY();
            gm->m_movementInfo.transport.pos.GetPosition(s.x, s.y, s.z, s.o);
            s.flags = BUDDY_STEP_DECK;
        }
        else
            gm->GetPosition(s.x, s.y, s.z, s.o);
        c.lastDeck = mt != nullptr;
        c.steps.push_back(s);
        sCaptures[gm->GetGUID().GetCounter()] = c;
        sRecordingCount = uint32(sCaptures.size());
        handler->PSendSysMessage("Recording a {} from here. Walk {}, then type .buddy record stop (or .buddy record discard).",
            mt ? "disembark" : "embark", mt ? "off the ship onto the dock" : "onto the ship's deck");
        return true;
    }

    static bool HandleStop(ChatHandler* handler, Optional<Tail> note)
    {
        Player* gm = handler->GetPlayer();
        std::lock_guard<std::mutex> lock(sRecLock);
        auto it = sCaptures.find(gm->GetGUID().GetCounter());
        if (it == sCaptures.end())
        {
            handler->SendSysMessage("No recording under way. Start one with .buddy record start.");
            return true;
        }
        Capture c = it->second;
        sCaptures.erase(it);
        sRecordingCount = uint32(sCaptures.size());

        std::string seen = std::to_string(c.steps.size()) + " steps, started " +
            ((c.steps.front().flags & BUDDY_STEP_DECK) ? "on a deck" : "ashore") + ", went onto or off the deck " +
            std::to_string(c.crossings) + " time(s), ended " + (c.lastDeck ? "on a deck" : "ashore");
        if (!c.bad.empty())
        {
            handler->PSendSysMessage("Not kept: {}. ({}.) Start again with .buddy record start.", c.bad, seen);
            return true;
        }
        if (c.crossings != 1)
        {
            handler->PSendSysMessage("Not kept: a recording must go onto the deck once (embark) or off it once (disembark). "
                "({}.) Start again with .buddy record start.", seen);
            return true;
        }
        uint8 stop = 0;
        if (!BuddyTransportStop(c.entry, c.mapId, c.shipX, c.shipY, STOP_REACH_YARDS, stop))
        {
            handler->PSendSysMessage("Not kept: {} was not within {} yards of a stop on its route when you were on its deck "
                "(was it docked?). ({}.) Start again with .buddy record start.", ShipName(c.entry), int(STOP_REACH_YARDS), seen);
            return true;
        }

        EnsureLoadedLocked();
        Boarding b;
        b.id     = sBoardings.empty() ? 1 : sBoardings.rbegin()->first + 1;
        b.kind   = c.lastDeck ? BUDDY_BOARD_EMBARK : BUDDY_BOARD_DISEMBARK;
        b.entry  = c.entry;
        b.stop   = stop;
        b.mapId  = c.mapId;
        b.author = gm->GetName();
        b.note   = note ? std::string(*note) : std::string();
        b.steps  = c.steps;

        std::string author = b.author, text = b.note;
        WorldDatabase.EscapeString(author);
        WorldDatabase.EscapeString(text);
        WorldDatabase.DirectExecute("INSERT INTO buddy_boarding (id, kind, transport, stop, map, author, note) "
            "VALUES ({}, {}, {}, {}, {}, '{}', '{}')", b.id, b.kind, b.entry, b.stop, b.mapId, author, text);
        std::string values;
        for (uint32 seq = 0; seq < b.steps.size(); ++seq)
        {
            Step const& s = b.steps[seq];
            values += (seq ? "," : "") + Acore::StringFormat("({},{},{},{},{:.4f},{:.4f},{:.4f},{:.4f},{:.3f},{:.3f})",
                b.id, seq, s.ms, s.flags, s.x, s.y, s.z, s.o, s.jumpXY, s.jumpZ);
        }
        WorldDatabase.DirectExecute("INSERT INTO buddy_boarding_step (boarding, seq, ms, flags, x, y, z, o, jump_xy, jump_z) "
            "VALUES " + values);
        sBoardings[b.id] = b;

        uint32 count = 0;
        for (auto const& [id, other] : sBoardings)
            count += other.kind == b.kind && other.entry == b.entry && other.stop == b.stop;
        handler->PSendSysMessage("Kept as recording {}: {} of {} at stop {} of its route, {} steps over {:.1f} s. "
            "This stop now has {} {} recording(s). Run scripts/export-buddy-boardings to keep it in the project.",
            b.id, KindName(b.kind), ShipName(b.entry), uint32(b.stop), b.steps.size(), b.steps.back().ms / 1000.0f,
            count, KindName(b.kind));
        return true;
    }

    static bool HandleDiscard(ChatHandler* handler)
    {
        std::lock_guard<std::mutex> lock(sRecLock);
        bool had = sCaptures.erase(handler->GetPlayer()->GetGUID().GetCounter()) > 0;
        sRecordingCount = uint32(sCaptures.size());
        handler->SendSysMessage(had ? "Recording discarded." : "No recording under way.");
        return true;
    }

    static bool HandleList(ChatHandler* handler)
    {
        Player* gm = handler->GetPlayer();
        std::lock_guard<std::mutex> lock(sRecLock);
        EnsureLoadedLocked();
        uint32 shown = 0;
        for (auto const& [id, b] : sBoardings)
        {
            uint32 mapId = 0;
            float  x = 0.0f, y = 0.0f, z = 0.0f;
            if (!BuddyTransportStopSpot(b.entry, b.stop, mapId, x, y, z) || mapId != gm->GetMapId()
                || gm->GetExactDist2d(x, y) > LIST_YARDS)
                continue;
            auto held = sHeldBy.find(id);
            handler->PSendSysMessage("{}: {} of {} at stop {}, {} steps, {:.1f} s, by {}{}{}{}", id, KindName(b.kind),
                ShipName(b.entry), uint32(b.stop), b.steps.size(), b.steps.back().ms / 1000.0f, b.author,
                b.note.empty() ? "" : " - ", b.note, held != sHeldBy.end() ? " (held by a buddy now)" : "");
            ++shown;
        }
        if (!shown)
            handler->PSendSysMessage("No boarding recordings at any ship stop within {} yards.", int(LIST_YARDS));
        return true;
    }

    static bool HandleDelete(ChatHandler* handler, uint32 id)
    {
        std::lock_guard<std::mutex> lock(sRecLock);
        EnsureLoadedLocked();
        if (!sBoardings.erase(id))
        {
            handler->PSendSysMessage("There is no boarding recording {}. .buddy record list shows the ones nearby.", id);
            return true;
        }
        WorldDatabase.DirectExecute("DELETE FROM buddy_boarding_step WHERE boarding = {}", id);
        WorldDatabase.DirectExecute("DELETE FROM buddy_boarding WHERE id = {}", id);
        auto held = sHeldBy.find(id);
        if (held != sHeldBy.end())
        {
            sHolds.erase(held->second);
            sHeldBy.erase(held);
        }
        handler->PSendSysMessage("Boarding recording {} deleted. Run scripts/export-buddy-boardings to keep the change in the project.", id);
        return true;
    }
};

void AddSC_buddies_recorder()
{
    new buddies_recorder_movement();
    new buddies_recorder_command();
}
