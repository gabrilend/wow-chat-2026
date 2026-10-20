
#include "buddies.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "DatabaseEnv.h"
#include "Map.h"
#include "Player.h"
#include "ScriptMgr.h"
#include <cmath>
#include <set>
#include <utility>

using namespace Acore::ChatCommands;

static constexpr float  GRID_YARDS    = 533.3333f;
static constexpr float  SQUARE        = GRID_YARDS / 16.0f;
static constexpr float  SHOW_YARDS    = 250.0f;
static constexpr float  SPAWN_YARDS   = 300.0f;
static constexpr uint32 SHOW_MS       = 30000;
static constexpr uint32 WISPS_MAX     = 400;
static constexpr uint32 EDGE_WISPS    = 3;

static int SquareOf(float v) { return int(std::floor(16.0f * (32.0f - v / GRID_YARDS))); }
static float EdgeOf(int s) { return (32.0f - float(s) / 16.0f) * GRID_YARDS; }

class buddies_show_command : public CommandScript
{
public:
    buddies_show_command() : CommandScript("buddies_show_command") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "buddy area show",   HandleShow,   SEC_GAMEMASTER, Console::No },
            { "buddy area spawns", HandleSpawns, SEC_GAMEMASTER, Console::No },
        };
        return commandTable;
    }

    static bool HandleShow(ChatHandler* handler)
    {
        Player* gm = handler->GetSession()->GetPlayer();
        uint32 map = gm->GetMapId();
        int sx = SquareOf(gm->GetPositionX()), sy = SquareOf(gm->GetPositionY());

        QueryResult here = WorldDatabase.Query("SELECT subarea FROM buddy_subarea_square WHERE map = {} AND sx = {} AND sy = {}", map, sx, sy);
        if (!here)
        {
            if (!WorldDatabase.Query("SHOW TABLES LIKE 'buddy_subarea'"))
                handler->PSendSysMessage("No roaming parts in the world database (install step E055, 617e12, not run).");
            else
                handler->PSendSysMessage("Square ({}, {}) of map {} lies in a named area the cut left whole: buddies roam all of it.", sx, sy, map);
            return true;
        }
        uint32 part = (*here)[0].Get<uint32>();
        if (QueryResult info = WorldDatabase.Query(
                "SELECT s.area_name, s.squares, s.min_level, s.max_level, s.monsters, "
                "(SELECT COUNT(*) FROM buddy_subarea o WHERE o.map = s.map AND o.area = s.area) FROM buddy_subarea s WHERE s.id = {}", part))
            handler->PSendSysMessage("Roaming part {} of {} ({} parts there): {} squares, levels {}-{}, mostly {}.", part,
                (*info)[0].Get<std::string>(), (*info)[5].Get<uint64>(), (*info)[1].Get<uint32>(), (*info)[2].Get<uint8>(),
                (*info)[3].Get<uint8>(), (*info)[4].Get<std::string>().empty() ? "no monsters" : (*info)[4].Get<std::string>());

        int reach = int(std::ceil(SHOW_YARDS / SQUARE));
        std::set<std::pair<int, int>> mine;
        if (QueryResult sq = WorldDatabase.Query("SELECT sx, sy FROM buddy_subarea_square WHERE subarea = {} AND sx BETWEEN {} AND {} AND sy BETWEEN {} AND {}",
                part, sx - reach, sx + reach, sy - reach, sy + reach))
            do mine.emplace((*sq)[0].Get<int32>(), (*sq)[1].Get<int32>()); while (sq->NextRow());
        struct Edge { float x1, y1, x2, y2; };
        std::vector<Edge> edges;
        for (auto const& [x, y] : mine)
        {
            float hiX = EdgeOf(x), loX = EdgeOf(x + 1), hiY = EdgeOf(y), loY = EdgeOf(y + 1);
            if (!mine.count({ x - 1, y })) edges.push_back({ hiX, loY, hiX, hiY });
            if (!mine.count({ x + 1, y })) edges.push_back({ loX, loY, loX, hiY });
            if (!mine.count({ x, y - 1 })) edges.push_back({ loX, hiY, hiX, hiY });
            if (!mine.count({ x, y + 1 })) edges.push_back({ loX, loY, hiX, loY });
        }
        uint32 perEdge = EDGE_WISPS;
        while (perEdge > 1 && edges.size() * perEdge > WISPS_MAX)
            --perEdge;
        uint32 placed = 0, skipped = 0;
        for (Edge const& e : edges)
        {
            if (placed >= WISPS_MAX)
            {
                ++skipped;
                continue;
            }
            for (uint32 k = 0; k < perEdge; ++k)
            {
                float t = (float(k) + 0.5f) / float(perEdge);
                placed += BuddyPlaceWisp(gm, e.x1 + (e.x2 - e.x1) * t, e.y1 + (e.y2 - e.y1) * t, gm->GetPositionZ(), 0.0f, SHOW_MS);
            }
        }
        handler->PSendSysMessage("Its border within {:.0f} yards: {} square edges, drawn by {} wisps for {} seconds{}.", SHOW_YARDS,
            edges.size(), placed, SHOW_MS / 1000, skipped ? " (" + std::to_string(skipped) + " edges left undrawn: too many)" : "");
        return true;
    }

    static bool HandleSpawns(ChatHandler* handler, Tail what)
    {
        Player* gm = handler->GetSession()->GetPlayer();
        std::string kind(what);
        if (kind.empty())
        {
            handler->PSendSysMessage("Usage: .buddy area spawns <creature id or name>");
            return false;
        }
        std::string entries;
        if (kind.find_first_not_of("0123456789") == std::string::npos)
            entries = kind;
        else
        {
            std::string name = kind;
            WorldDatabase.EscapeString(name);
            if (QueryResult rows = WorldDatabase.Query("SELECT entry FROM creature_template WHERE name = '{}'", name))
                do entries += (entries.empty() ? "" : ",") + std::to_string((*rows)[0].Get<uint32>()); while (rows->NextRow());
            if (entries.empty())
            {
                handler->PSendSysMessage("No creature is called '{}'.", kind);
                return false;
            }
        }
        float x = gm->GetPositionX(), y = gm->GetPositionY();
        QueryResult rows = WorldDatabase.Query(
            "SELECT position_x, position_y, position_z FROM creature WHERE id IN ({}) AND map = {} "
            "AND position_x BETWEEN {} AND {} AND position_y BETWEEN {} AND {}",
            entries, gm->GetMapId(), x - SPAWN_YARDS, x + SPAWN_YARDS, y - SPAWN_YARDS, y + SPAWN_YARDS);
        uint32 found = 0, placed = 0;
        if (rows)
            do
            {
                float sx = (*rows)[0].Get<float>(), sy = (*rows)[1].Get<float>(), sz = (*rows)[2].Get<float>();
                if (std::hypot(sx - x, sy - y) > SPAWN_YARDS)
                    continue;
                ++found;
                if (placed < WISPS_MAX)
                    placed += BuddyPlaceWisp(gm, sx, sy, sz, 0.0f, SHOW_MS);
            } while (rows->NextRow());
        handler->PSendSysMessage("{} spawn points of {} within {:.0f} yards; {} wisps for {} seconds.", found, kind, SPAWN_YARDS,
            placed, SHOW_MS / 1000);
        return true;
    }
};

void AddSC_buddies_show()
{
    new buddies_show_command();
}
