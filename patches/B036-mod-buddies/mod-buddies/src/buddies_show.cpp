/*
 * buddies_show.cpp - game masters see the roaming parts and where creatures
 * spawn, drawn in wisps (issue 617e12).
 *
 * For a general audience: the world's named areas are cut into smaller
 * parts for buddies to roam (scripts/generate-buddy-subareas, install step
 * E055), and the cut is judged by where monsters live. These two commands
 * put that on the ground in game, in the markers the town circles already
 * use (BuddyPlaceWisp, buddies_town_circles.cpp: wisps, friendly and
 * untouchable, gone after a while). The owner, 2026-10-09: "Can we add a GM
 * command that let's us visualize these areas? We'll need another one for
 * letting us visualize the spawn points of a particular type of unit.
 * Usually we can use an un-interactable wisp unit."
 *
 *   .buddy area show
 *       names the part the game master stands in (its named area, its
 *       share of the area, levels, leading monsters, size) and draws its
 *       border in wisps: along every edge of its map squares (about 33
 *       yards across) that faces a square of another part, within
 *       SHOW_YARDS of the game master
 *   .buddy area spawns <creature id or name>
 *       a wisp on every spawn point of that creature (every creature of
 *       that name) on the game master's map within SPAWN_YARDS
 *
 * Both read the world database as it is (buddy_subarea, buddy_subarea_
 * square, creature), so a regenerated cut shows after its install step,
 * without a restart.
 */

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

static constexpr float  GRID_YARDS    = 533.3333f;      // a map grid's side, yards (the core's SIZE_OF_GRIDS, a macro there)
static constexpr float  SQUARE        = GRID_YARDS / 16.0f;   // a roaming square's side (generate-buddy-subareas)
static constexpr float  SHOW_YARDS    = 250.0f;          // border edges drawn within this of the game master
static constexpr float  SPAWN_YARDS   = 300.0f;          // spawn points shown within this
static constexpr uint32 SHOW_MS       = 30000;           // the wisps stand this long
static constexpr uint32 WISPS_MAX     = 400;             // at most this many at once (spaced wider past it)
static constexpr uint32 EDGE_WISPS    = 3;               // wisps along one square edge (about 11 yards apart)

// {{{ squares
// A map position's square, and a square's corner: the generator's own
// arithmetic (square_of, square_middle in scripts/generate-buddy-subareas),
// where square numbers grow as x and y fall.
static int SquareOf(float v) { return int(std::floor(16.0f * (32.0f - v / GRID_YARDS))); }
static float EdgeOf(int s) { return (32.0f - float(s) / 16.0f) * GRID_YARDS; }   // the square's high edge; s + 1's is its low
// }}}

class buddies_show_command : public CommandScript
{
public:
    buddies_show_command() : CommandScript("buddies_show_command") { }

    ChatCommandTable GetCommands() const override
    {
        // multi-word names join the ".buddy" table the beds file starts
        static ChatCommandTable commandTable =
        {
            { "buddy area show",   HandleShow,   SEC_GAMEMASTER, Console::No },
            { "buddy area spawns", HandleSpawns, SEC_GAMEMASTER, Console::No },
        };
        return commandTable;
    }

    // {{{ HandleShow
    static bool HandleShow(ChatHandler* handler)
    {
        Player* gm = handler->GetSession()->GetPlayer();
        uint32 map = gm->GetMapId();
        int sx = SquareOf(gm->GetPositionX()), sy = SquareOf(gm->GetPositionY());

        QueryResult here = WorldDatabase.Query("SELECT subarea FROM buddy_subarea_square WHERE map = {} AND sx = {} AND sy = {}", map, sx, sy);
        if (!here)
        {
            // squares are listed only for areas the cut split: this one is
            // whole (or the install step hasn't run: said by the next check)
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

        // the part's squares near the game master, and the edges they share
        // with squares of other parts (or of nothing)
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
            if (!mine.count({ x - 1, y })) edges.push_back({ hiX, loY, hiX, hiY });   // the side toward greater x
            if (!mine.count({ x + 1, y })) edges.push_back({ loX, loY, loX, hiY });
            if (!mine.count({ x, y - 1 })) edges.push_back({ loX, hiY, hiX, hiY });   // toward greater y
            if (!mine.count({ x, y + 1 })) edges.push_back({ loX, loY, hiX, loY });
        }
        uint32 perEdge = EDGE_WISPS;
        while (perEdge > 1 && edges.size() * perEdge > WISPS_MAX)
            --perEdge;                                     // a long border: fewer wisps an edge
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
    // }}}

    // {{{ HandleSpawns
    static bool HandleSpawns(ChatHandler* handler, Tail what)
    {
        Player* gm = handler->GetSession()->GetPlayer();
        std::string kind(what);
        if (kind.empty())
        {
            handler->PSendSysMessage("Usage: .buddy area spawns <creature id or name>");
            return false;
        }
        // an id, or every creature of that name
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
            "SELECT position_x, position_y, position_z FROM creature WHERE id IN ({}) AND map = {} "   // "id": upstream renamed id1 (2026_06_16_00)
            "AND position_x BETWEEN {} AND {} AND position_y BETWEEN {} AND {}",
            entries, gm->GetMapId(), x - SPAWN_YARDS, x + SPAWN_YARDS, y - SPAWN_YARDS, y + SPAWN_YARDS);
        uint32 found = 0, placed = 0;
        if (rows)
            do
            {
                float sx = (*rows)[0].Get<float>(), sy = (*rows)[1].Get<float>(), sz = (*rows)[2].Get<float>();
                if (std::hypot(sx - x, sy - y) > SPAWN_YARDS)
                    continue;                              // in the box, outside the circle
                ++found;
                if (placed < WISPS_MAX)
                    placed += BuddyPlaceWisp(gm, sx, sy, sz, 0.0f, SHOW_MS);
            } while (rows->NextRow());
        handler->PSendSysMessage("{} spawn points of {} within {:.0f} yards; {} wisps for {} seconds.", found, kind, SPAWN_YARDS,
            placed, SHOW_MS / 1000);
        return true;
    }
    // }}}
};

// {{{ AddSC_buddies_show
void AddSC_buddies_show()
{
    new buddies_show_command();
}
// }}}
