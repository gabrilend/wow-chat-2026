/*
 * buddies_town_circles.cpp - towns found from the people in them, and
 * placed by hand (issue 617e4a).
 *
 * For a general audience: a starting valley is one area in the game's
 * tables, though it has a camp of trainers and shops and wild country
 * round it, and many camps and quest hubs aren't marked as towns at all.
 * scripts/generate-buddy-town-circles finds every cluster of helpful
 * people and draws a circle round it (the world table buddy_town_circle,
 * install step E050). This file reads the circles at startup and answers
 * "is this player in a town circle?" for BuddyTownArea: inside a circle is
 * town, and a player stays in town until 10 yards past its edge, so
 * standing on the edge doesn't flicker between town and country.
 *
 * Game masters place circles by hand (the owner, 2026-10-03: "spawn a
 * whisp NPC that stands at the radius chosen, at every point of the
 * circle, and disappears after 15 seconds [...] however many wisps it'd
 * take to fully define the circle"):
 *   .buddy town here <radius>   a circle where the game master stands
 *   .buddy town show            draw the nearest circle in wisps
 *   .buddy town remove          remove the nearest hand-placed circle
 * Hand-placed circles are written to the world table at once; running
 * scripts/generate-buddy-town-circles carries them into the project's SQL.
 */

#include "buddies.h"
#include "buddies_roam.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"
#include "Log.h"
#include "Map.h"
#include "Player.h"
#include "QueryResult.h"
#include "ScriptMgr.h"
#include "TemporarySummon.h"
#include <cmath>
#include <mutex>
#include <shared_mutex>
#include <string>
#include <unordered_map>
#include <vector>

using namespace Acore::ChatCommands;

// {{{ tuning
static constexpr float  HOLD_YARDS      = 10.0f;    // in town until this far past a circle's edge
static constexpr uint32 WISP            = 3681;     // "Wisp", the night elves' little light
static constexpr uint32 WISP_MS         = 15000;    // the drawn circle stands this long
static constexpr float  WISP_SPACING    = 3.0f;     // one wisp every this many yards round the edge ...
static constexpr uint32 WISP_MAX        = 240;      // ... at most this many (a bigger circle spaces them wider)
static constexpr float  SHOW_YARDS      = 300.0f;   // ".buddy town show" draws the nearest circle within this
static constexpr float  REMOVE_YARDS    = 50.0f;    // ".buddy town remove": the game master inside it or this near its edge
static constexpr uint32 WISP_FACTION = 35;      // friendly to everyone
// }}}

// {{{ the circles
struct TownCircle
{
    uint32      id = 0, map = 0, area = 0;
    float       x = 0.0f, y = 0.0f, z = 0.0f, r = 0.0f;
    uint8       source = 0;                     // 0 found by the generator, 1 placed by hand
    std::string name;
};
static std::shared_mutex                  sCircleLock;
static std::vector<TownCircle>            sCircles;
static std::mutex                         sHoldLock;
static std::unordered_map<uint32, uint32> sHold;   // player guid (low) -> the circle id it is in

static void LoadCircles()
{
    std::vector<TownCircle> found;
    QueryResult rows = WorldDatabase.Query("SELECT id, map, x, y, z, radius, area, source, name FROM buddy_town_circle");
    if (rows)
        do
        {
            Field* f = rows->Fetch();
            TownCircle c;
            c.id = f[0].Get<uint32>(), c.map = f[1].Get<uint32>();
            c.x = f[2].Get<float>(), c.y = f[3].Get<float>(), c.z = f[4].Get<float>(), c.r = f[5].Get<float>();
            c.area = f[6].Get<uint32>(), c.source = f[7].Get<uint8>(), c.name = f[8].Get<std::string>();
            found.push_back(c);
        } while (rows->NextRow());
    else
        LOG_ERROR("module", "mod-buddies: no town circles read (buddy_town_circle missing or empty: install step E050); "
            "only the area table's towns are towns (617e4a)");
    std::unique_lock<std::shared_mutex> lock(sCircleLock);
    sCircles.swap(found);
    LOG_INFO("module", ">> mod-buddies: {} town circles read (617e4a)", sCircles.size());
}

static float Dist2d(TownCircle const& c, float x, float y) { return std::hypot(x - c.x, y - c.y); }

uint32 BuddyTownCircleArea(Player* who)
{
    float  x = who->GetPositionX(), y = who->GetPositionY();
    uint32 map = who->GetMapId(), guid = who->GetGUID().GetCounter();
    std::shared_lock<std::shared_mutex> circles(sCircleLock);
    std::lock_guard<std::mutex> hold(sHoldLock);
    // held: still in its circle while within HOLD_YARDS of the edge
    auto h = sHold.find(guid);
    if (h != sHold.end())
    {
        for (TownCircle const& c : sCircles)
            if (c.id == h->second && c.map == map && Dist2d(c, x, y) <= c.r + HOLD_YARDS)
                return c.area;
        sHold.erase(h);
    }
    for (TownCircle const& c : sCircles)
        if (c.map == map && Dist2d(c, x, y) <= c.r)
        {
            sHold[guid] = c.id;
            return c.area;
        }
    return 0;
}
// }}}

// {{{ the wisps
// A circle drawn in wisps round its edge, one every WISP_SPACING yards (or
// wider, past WISP_MAX), each on the ground, friendly, untouchable, gone
// after WISP_MS.
static uint32 DrawCircle(Player* gm, float cx, float cy, float cz, float r)
{
    uint32 count = std::min<uint32>(WISP_MAX, std::max<uint32>(8, uint32(std::ceil(2.0f * float(M_PI) * r / WISP_SPACING))));
    uint32 placed = 0;
    for (uint32 k = 0; k < count; ++k)
    {
        float a = 2.0f * float(M_PI) * float(k) / float(count);
        float x = cx + std::cos(a) * r, y = cy + std::sin(a) * r;
        float z = gm->GetMap()->GetHeight(gm->GetPhaseMask(), x, y, cz + 20.0f, true, 60.0f);
        if (z <= INVALID_HEIGHT)
            z = cz;                                    // no ground found: at the circle's own height, floating
        if (TempSummon* w = gm->SummonCreature(WISP, x, y, z, a + float(M_PI), TEMPSUMMON_TIMED_DESPAWN, WISP_MS))
        {
            w->SetFaction(WISP_FACTION);
            w->SetReactState(REACT_PASSIVE);
            w->SetUnitFlag(UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_NOT_SELECTABLE);
            ++placed;
        }
    }
    return placed;
}
// }}}

// {{{ the commands
class buddies_town_circles_command : public CommandScript
{
public:
    buddies_town_circles_command() : CommandScript("buddies_town_circles_command") { }

    ChatCommandTable GetCommands() const override
    {
        // multi-word names join the ".buddy" table the beds file starts
        static ChatCommandTable commandTable =
        {
            { "buddy town here",   HandleHere,   SEC_GAMEMASTER, Console::No },
            { "buddy town show",   HandleShow,   SEC_GAMEMASTER, Console::No },
            { "buddy town remove", HandleRemove, SEC_GAMEMASTER, Console::No },
        };
        return commandTable;
    }

    static bool HandleHere(ChatHandler* handler, float radius)
    {
        Player* gm = handler->GetPlayer();
        if (radius < 5.0f || radius > 500.0f)
        {
            handler->PSendSysMessage("Usage: .buddy town here <radius in yards, 5 to 500>");
            return false;
        }
        AreaTableEntry const* area = sAreaTableStore.LookupEntry(gm->GetAreaId());
        std::string name = area ? area->area_name[0] : "?";
        WorldDatabase.DirectExecute(Acore::StringFormat(
            "INSERT INTO buddy_town_circle (map, x, y, z, radius, area, people, source, name) VALUES ({}, {}, {}, {}, {}, {}, 0, 1, '{}')",
            gm->GetMapId(), gm->GetPositionX(), gm->GetPositionY(), gm->GetPositionZ(), radius, gm->GetAreaId(),
            [&] { std::string n = name; WorldDatabase.EscapeString(n); return n; }()));
        LoadCircles();
        uint32 wisps = DrawCircle(gm, gm->GetPositionX(), gm->GetPositionY(), gm->GetPositionZ(), radius);
        handler->PSendSysMessage("Town circle placed here in {}: {:.0f} yards round, drawn by {} wisps for {} seconds. "
            "Run scripts/generate-buddy-town-circles to keep it in the project.", name, radius, wisps, WISP_MS / 1000);
        return true;
    }

    static bool HandleShow(ChatHandler* handler)
    {
        Player* gm = handler->GetPlayer();
        TownCircle best;
        float bestD = SHOW_YARDS;
        {
            std::shared_lock<std::shared_mutex> lock(sCircleLock);
            for (TownCircle const& c : sCircles)
            {
                float d = std::max(0.0f, Dist2d(c, gm->GetPositionX(), gm->GetPositionY()) - c.r);
                if (c.map == gm->GetMapId() && d < bestD)
                    best = c, bestD = d;
            }
        }
        if (!best.id)
        {
            handler->PSendSysMessage("No town circle within {:.0f} yards.", SHOW_YARDS);
            return false;
        }
        uint32 wisps = DrawCircle(gm, best.x, best.y, best.z, best.r);
        handler->PSendSysMessage("Town circle {} ({}, {}): {:.0f} yards round, its edge {:.0f} yards from you; {} wisps for {} seconds.",
            best.id, best.name, best.source ? "placed by hand" : "found from its people", best.r, bestD, wisps, WISP_MS / 1000);
        return true;
    }

    static bool HandleRemove(ChatHandler* handler)
    {
        Player* gm = handler->GetPlayer();
        TownCircle best;
        float bestD = REMOVE_YARDS;
        {
            std::shared_lock<std::shared_mutex> lock(sCircleLock);
            for (TownCircle const& c : sCircles)
            {
                float d = std::max(0.0f, Dist2d(c, gm->GetPositionX(), gm->GetPositionY()) - c.r);
                if (c.source == 1 && c.map == gm->GetMapId() && d <= bestD)
                    best = c, bestD = d;
            }
        }
        if (!best.id)
        {
            handler->PSendSysMessage("No hand-placed town circle here (within {:.0f} yards of its edge). Found circles are "
                "remade by scripts/generate-buddy-town-circles, not removed by hand.", REMOVE_YARDS);
            return false;
        }
        WorldDatabase.DirectExecute(Acore::StringFormat("DELETE FROM buddy_town_circle WHERE id = {} AND source = 1", best.id));
        LoadCircles();
        handler->PSendSysMessage("Hand-placed town circle {} ({}, {:.0f} yards round) removed. Run "
            "scripts/generate-buddy-town-circles to drop it from the project too.", best.id, best.name, best.r);
        return true;
    }
};

class buddies_town_circles_world : public WorldScript
{
public:
    buddies_town_circles_world() : WorldScript("buddies_town_circles_world", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        if (BuddiesEnabled())
            LoadCircles();
    }
};
// }}}

void AddSC_buddies_town_circles()
{
    new buddies_town_circles_command();
    new buddies_town_circles_world();
}
