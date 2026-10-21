/*
 * buddies_explore.cpp - the four ways a buddy explores, in game (issue 617e6).
 *
 * For a general audience: the gallery's exploring systems (least paint,
 * the room orbit, the squished circle; roam/buddy_explore_core.h) need the
 * area as a grid of cells: which cells are floor a buddy can walk to, how
 * high each is, where the walls are. The drawn arenas have exact outlines;
 * the real world doesn't, so this file measures it the way a surveyor
 * pacing out a field would: from where the owner stands, cell by cell,
 * the ground's height and its area's name, stepping on only where the
 * ground rises or falls gently enough to walk (a sharp step is a wall).
 * Then, on a worker thread, the distances to the edge and the walls, the
 * rooms and tunnels, and the squished circle are worked out; from then on
 * the clan's buddies paint what they see onto that grid, and each picks
 * its waypoints by its own system.
 *
 * Parts:
 *   the setting   - ".buddy explore <pinwheel|paint|rooms|disc|mixed>",
 *                   per owner, for the session;
 *   the grids     - one per piece of a named area on a map, built on first
 *                   need and kept for the server's run (the ground doesn't
 *                   change): measured a few hundred cells each world tick
 *                   (the maps are idle then), finished on a worker thread;
 *   the paint     - one per owner per area piece: each buddy in the area
 *                   paints every second (fighting or not: "bots should keep
 *                   painting while fighting"), the walls pulse every 3
 *                   seconds, and 15 seconds after the owner leaves the area
 *                   its paint is dropped ("last until the player leaves the
 *                   area for 15 seconds");
 *   the choosing  - BuddyExploreNext, asked by the roam action.
 */

#include "buddies.h"
#include "buddies_explore.h"
#include "buddies_roam.h"
#include "buddies_navmesh.h"
#include "roam/buddy_explore_core.h"
#include "roam/buddy_grid_rules.h"
#include "roam/buddy_town_file.h"
#include "Config.h"
#include <sys/stat.h>
#include "Chat.h"
#include "GameTime.h"
#include "Log.h"
#include "Map.h"
#include "MapMgr.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include <algorithm>
#include <atomic>
#include <chrono>
#include <cmath>
#include <deque>
#include <map>
#include <memory>
#include <mutex>
#include <set>
#include <thread>
#include <tuple>
#include <unordered_map>

// {{{ tuning
// The cell size, the slope limit and the mesh's reach for a floor cell are
// shared with the town baker (roam/buddy_grid_rules.h), so a baked town
// and a measured one are the same grid.
using BuddyGridRules::CELL_YARDS;
using BuddyGridRules::MAX_CELLS;
using BuddyGridRules::MAX_GRADE;
using BuddyGridRules::MESH_SNAP_YARDS;
using BuddyGridRules::MESH_RISE_YARDS;
static constexpr uint32 PROBES_PER_TICK = 600;     // ground measurements per world tick while a grid is measured
static constexpr float  PROBE_DROP      = 50.0f;   // yards below a cell's neighbour its ground is looked for
static constexpr uint32 PAINT_EVERY_MS  = 1000;    // each buddy paints this often
static constexpr uint32 PULSE_EVERY_MS  = 3000;    // the walls' pulse (the owner: "a pulse every 3 seconds or so")
static constexpr uint32 DROP_AFTER_MS   = 15000;   // paint dropped this long after the owner leaves the area
static constexpr uint32 RETRY_FAILED_MS = 60000;   // a grid whose measuring failed is tried again after this
static constexpr float  INDOOR_BOX_YARDS = 100.0f; // an area with no piece in the table: measured this far around the owner
static constexpr uint32 NO_PIECE        = 0xFFFFFFFFu;   // ... under this piece number
static constexpr uint32 FORCED_KEEP_MS  = 60000;   // an owner whose buddy needed rooms keeps its grid wanted this long
static constexpr int32  DISC_SWEEPS     = 4000;    // the squished circle's passes at most ...
static constexpr double DISC_TOLERANCE  = 1e-6;    // ... or until no cell moves more than this in a pass
// }}}

// {{{ the setting
static std::mutex sSettingLock;
static std::unordered_map<uint32, BuddyExploreMode> sSetting;   // owner guid -> chosen mode (MIXED included)

BuddyExploreMode BuddyExploreModeFor(uint32 ownerGuid, uint32 buddyGuid)
{
    BuddyExploreMode chosen = BUDDY_EXPLORE_PINWHEEL;
    {
        std::lock_guard<std::mutex> lock(sSettingLock);
        auto it = sSetting.find(ownerGuid);
        if (it != sSetting.end())
            chosen = it->second;
    }
    if (chosen != BUDDY_EXPLORE_MIXED)
        return chosen;
    // mixed: the owner's buddies in character-number order take pinwheel,
    // least paint, rooms, disc, pinwheel, ... in turn
    std::vector<uint32> mine;
    for (auto const& pair : BuddyRosterPairs())
        if (pair.second == ownerGuid)
            mine.push_back(pair.first);
    std::sort(mine.begin(), mine.end());
    size_t index = size_t(std::find(mine.begin(), mine.end(), buddyGuid) - mine.begin());
    return BuddyExploreMode(index % 4);
}

bool BuddyExploreHandleCommand(ChatHandler* handler, std::string const& word)
{
    // the words, as a table: a word picks its mode directly
    static std::map<std::string, BuddyExploreMode> const words = {
        { "pinwheel", BUDDY_EXPLORE_PINWHEEL }, { "paint", BUDDY_EXPLORE_LEAST }, { "least", BUDDY_EXPLORE_LEAST },
        { "rooms", BUDDY_EXPLORE_ROOMS }, { "disc", BUDDY_EXPLORE_DISC }, { "mixed", BUDDY_EXPLORE_MIXED },
    };
    static char const* const names[] = { "the pinwheel", "least paint", "the room orbit", "the squished circle", "mixed" };
    Player* owner = handler->GetPlayer();
    auto it = words.find(word);
    if (it == words.end())
    {
        handler->PSendSysMessage("'{}' is not a way of exploring: use pinwheel, paint, rooms, disc or mixed.", word);
        return true;
    }
    {
        std::lock_guard<std::mutex> lock(sSettingLock);
        sSetting[owner->GetGUID().GetCounter()] = it->second;
    }
    handler->PSendSysMessage("Your buddies now explore by {}{}.", names[it->second],
        it->second == BUDDY_EXPLORE_MIXED ? " (each buddy one of the four, in turn)" : "");
    if (it->second == BUDDY_EXPLORE_MIXED)
    {
        std::vector<uint32> mine;
        for (auto const& pair : BuddyRosterPairs())
            if (pair.second == owner->GetGUID().GetCounter())
                mine.push_back(pair.first);
        std::sort(mine.begin(), mine.end());
        for (size_t k = 0; k < mine.size(); ++k)
            if (Player* b = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(mine[k])))
                handler->PSendSysMessage("  {}: {}", b->GetName(), names[k % 4]);
    }
    return true;
}
// }}}

// {{{ the grids
// One per (map, area, piece). Measured on the world thread, finished on a
// worker thread; `state` says which, and only a Ready grid is read by the
// buddies (the worker's writes are complete before it sets Ready).
enum GridState : int32 { GRID_MEASURING, GRID_COMPUTING, GRID_READY, GRID_FAILED };
struct GridEntry
{
    std::atomic<int32> state { GRID_MEASURING };
    BuddyExplore::Grid grid;
    uint32 mapId = 0, areaId = 0, phaseMask = 1, piece = 0;
    // the measuring
    std::deque<int32>    queue;      // walkable cells whose neighbours are still to be measured
    std::vector<uint8_t> probed;     // measured
    uint32  probes = 0, noGround = 0;
    uint32  noMesh = 0, walled = 0;  // cells with ground but no mesh there; joins the mesh's line refused (617o2)
    // which neighbours a buddy can step to from each cell (bits: 1 east,
    // 2 west, 4 north, 8 south), and which pairs were tested; complete when
    // the grid is Ready (617o3's distance maps walk these)
    std::vector<uint8_t> joins, tested;
    uint64  startedMs = 0, failedAt = 0;
    double  computeMs = 0.0;
    int32   sweeps = 0;
};
using GridKey = std::tuple<uint32, uint32, uint32>;   // map, area, piece
static std::mutex sGridLock;
static std::map<GridKey, std::shared_ptr<GridEntry>> sGrids;

// The piece of the area the owner stands in, from the area table. An area
// the table doesn't have (one that exists only inside a building or cave,
// like the Shadow Grave under Deathknell: the table is read from the
// outdoor terrain, which never carries its number) gets a square around
// the owner instead; the measuring reads the area number cell by cell, and
// indoors that number comes from the building itself, so the grid still
// finds the rooms. (2026-09-29, owner: "buddy-bots not knowing how to roam
// in indoor buildings".)
static bool PieceAt(Player* owner, uint32 areaId, BuddyAreaPieceInfo& piece)
{
    if (BuddyAreaPieceAt(owner->GetMapId(), areaId, owner->GetPositionX(), owner->GetPositionY(), piece))
        return true;                                   // the table's piece
    piece.piece = NO_PIECE;                            // no piece: a square around the owner
    piece.minX = owner->GetPositionX() - INDOOR_BOX_YARDS, piece.maxX = owner->GetPositionX() + INDOOR_BOX_YARDS;
    piece.minY = owner->GetPositionY() - INDOOR_BOX_YARDS, piece.maxY = owner->GetPositionY() + INDOOR_BOX_YARDS;
    return true;
}

// Start measuring the grid of the area piece the owner stands in (the
// cell under the owner is the first floor).
// {{{ LoadBaked (617o3)
// A town baked ahead of time (scripts/bake-buddy-towns) is read instead of
// measured: same layout (checked), and only if every mesh file it was
// baked from is still the same size and age on disk; otherwise an error
// says why and the caller measures live. No file is the ordinary case for
// anything but a town, and says nothing.
static void FinishGrid(std::shared_ptr<GridEntry> e);
static bool LoadBaked(std::shared_ptr<GridEntry> const& e)
{
    std::string dataDir = sConfigMgr->GetOption<std::string>("DataDir", ".");
    std::string path = BuddyTownFile::Name(dataDir, e->mapId, e->areaId, e->piece);
    BuddyTownFile::Town t;
    std::string why;
    if (!BuddyTownFile::Read(path, t, why))
    {
        if (why != "no file")
            LOG_ERROR("module", "mod-buddies: baked town {} unreadable ({}); measuring area {} live", path, why, e->areaId);
        return false;
    }
    BuddyExplore::Grid& g = e->grid;
    if (t.nx != g.nx || t.ny != g.ny || t.cell != g.cell || t.x0 != g.x0 || t.y0 != g.y0)
    {
        LOG_ERROR("module", "mod-buddies: baked town {} has another layout ({}x{} cells of {:.1f} at ({:.1f}, {:.1f}); the area table "
            "gives {}x{} of {:.1f} at ({:.1f}, {:.1f})); re-run scripts/bake-buddy-towns. Measuring live.", path, t.nx, t.ny, t.cell,
            t.x0, t.y0, g.nx, g.ny, g.cell, g.x0, g.y0);
        return false;
    }
    for (BuddyTownFile::Tile const& tile : t.tiles)
    {
        char name[64];
        std::snprintf(name, sizeof(name), "/mmaps/%03u%02u%02u.mmtile", e->mapId, tile.x, tile.y);
        struct stat st;
        if (::stat((dataDir + name).c_str(), &st) != 0 || uint64(st.st_size) != tile.size || int64(st.st_mtime) != tile.mtime)
        {
            LOG_ERROR("module", "mod-buddies: baked town {} was baked from a mesh file that has changed or gone ({}); re-run "
                "scripts/bake-buddy-towns. Measuring area {} live.", path, dataDir + name, e->areaId);
            return false;
        }
    }
    size_t n = size_t(g.Count());
    g.inside = t.inside, g.open = t.open, g.height = t.height;
    e->joins = t.joins;
    e->tested.assign(n, 0x0F);
    e->probed.assign(n, 1);
    e->queue.clear();
    e->state = GRID_COMPUTING;
    LOG_INFO("module", "mod-buddies: area {} on map {} (piece {}) read from its bake, {} ({} mesh files checked)",
        e->areaId, e->mapId, e->piece, path, uint32(t.tiles.size()));
    std::thread(FinishGrid, e).detach();
    return true;
}
// }}}

static std::shared_ptr<GridEntry> RequestGrid(Player* owner, uint32 areaId, GridKey& key)
{
    BuddyAreaPieceInfo piece;
    PieceAt(owner, areaId, piece);
    key = GridKey(owner->GetMapId(), areaId, piece.piece);
    uint64 now = uint64(GameTime::GetGameTimeMS().count());
    std::lock_guard<std::mutex> lock(sGridLock);
    auto found = sGrids.find(key);
    if (found != sGrids.end())
    {
        // a failed one is tried again after a while (the owner may now stand
        // where the measuring can start)
        if (found->second->state.load() != GRID_FAILED || now - found->second->failedAt < RETRY_FAILED_MS)
            return found->second;
        sGrids.erase(found);
    }
    auto e = std::make_shared<GridEntry>();
    e->mapId = owner->GetMapId(), e->areaId = areaId, e->phaseMask = owner->GetPhaseMask(), e->piece = piece.piece;
    e->startedMs = now;
    BuddyExplore::Grid& g = e->grid;
    // the piece's borders and one cell more, laid out by the shared rule
    if (!BuddyGridRules::Layout(piece.minX, piece.maxX, piece.minY, piece.maxY, g))
        LOG_INFO("module", "mod-buddies: area {} on map {} is {:.0f} by {:.0f} yards; its exploring grid uses {:.1f}-yard cells "
            "to stay under {} cells", areaId, e->mapId, piece.maxX - piece.minX, piece.maxY - piece.minY, g.cell, MAX_CELLS);
    size_t n = size_t(g.nx) * size_t(g.ny);
    g.inside.assign(n, 0), g.open.assign(n, 0), g.height.assign(n, 0.0f);
    g.edge.assign(n, -1.0), g.wall.assign(n, -1.0);
    e->probed.assign(n, 0);
    e->joins.assign(n, 0), e->tested.assign(n, 0);
    if (piece.piece != NO_PIECE && LoadBaked(e))
    {
        sGrids[key] = e;
        return e;
    }
    int32 start = g.CellOf(owner->GetPositionX(), owner->GetPositionY());
    if (start < 0)
    {
        e->state = GRID_FAILED, e->failedAt = now;
        LOG_ERROR("module", "mod-buddies: {} stands at ({:.1f}, {:.1f}) outside the borders the area table gives area {} on map {} "
            "(piece {}); no exploring grid there, buddies explore by the pinwheel", owner->GetName(), owner->GetPositionX(),
            owner->GetPositionY(), areaId, e->mapId, piece.piece);
    }
    else
    {
        g.inside[start] = 1, g.open[start] = 1, g.height[start] = owner->GetPositionZ();
        e->probed[start] = 1;
        e->queue.push_back(start);
        LOG_INFO("module", "mod-buddies: measuring the exploring grid of area {} on map {} (piece {}): {} by {} cells of {:.1f} yards",
            areaId, e->mapId, piece.piece, g.nx, g.ny, g.cell);
    }
    sGrids[key] = e;
    return e;
}

// The worker thread's part: distances, rooms and tunnels, the traced border
// and the squished circle; then Ready.
static void FinishGrid(std::shared_ptr<GridEntry> e)
{
    auto t0 = std::chrono::steady_clock::now();
    BuddyExplore::Settings s;
    BuddyExplore::Grid& g = e->grid;
    BuddyExplore::ComputeDistances(g);
    BuddyExplore::Prepare(g, s);
    std::vector<std::pair<int32_t, double>> rim = BuddyExplore::RimAngles(g);
    std::unordered_map<int32_t, double> angleOf(rim.begin(), rim.end());
    e->sweeps = BuddyExplore::DiscMap(g, [&angleOf](int32_t i)
    {
        auto it = angleOf.find(i);
        double a = it == angleOf.end() ? 0.0 : it->second;
        return std::make_pair(std::cos(a), std::sin(a));
    }, DISC_SWEEPS, DISC_TOLERANCE);
    e->computeMs = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
    LOG_INFO("module", "mod-buddies: exploring grid of area {} on map {} ready: {} walkable cells of {}, {} rooms, {} tunnels; "
        "measured with {} probes ({} without ground, {} with ground but no mesh, {} steps the mesh walls off) in {:.1f} s, "
        "worked out in {:.0f} ms ({} disc passes)",
        e->areaId, e->mapId, uint32(g.openList.size()), g.Count(), uint32(g.rooms.size()), uint32(g.tunnels.size()),
        e->probes, e->noGround, e->noMesh, e->walled, double(uint64(GameTime::GetGameTimeMS().count()) - e->startedMs) / 1000.0, e->computeMs, e->sweeps);
    e->state = GRID_READY;
}

// Measure some cells of the grids still being measured: a flood from the
// owner's cell over walkable ground. Each walkable cell's four neighbours
// are measured once: the ground under the neighbour's middle, searched from
// a cell's rise above this cell (so a bridge or a roof overhead is not
// read) down to PROBE_DROP below; the neighbour is part of the area when
// the ground there carries the area's id, and walkable from here when it
// rises or falls no more than MAX_GRADE over the cell (a steeper change is a
// wall, a ledge or a rock). A cell first met as too steep from one side may
// still be walked onto from another side. Called from the world update,
// when the maps are idle.
static void MeasureSome()
{
    std::vector<std::shared_ptr<GridEntry>> work;
    {
        std::lock_guard<std::mutex> lock(sGridLock);
        for (auto const& kv : sGrids)
            if (kv.second->state.load() == GRID_MEASURING)
                work.push_back(kv.second);
    }
    uint32 budget = PROBES_PER_TICK;
    for (auto& e : work)
    {
        if (!budget)
            break;
        Map* map = sMapMgr->FindBaseNonInstanceMap(e->mapId);
        if (!map)
            continue;
        BuddyExplore::Grid& g = e->grid;
        while (budget && !e->queue.empty())
        {
            int32 i = e->queue.front();
            e->queue.pop_front();
            int32 ix = i % g.nx, iy = i / g.nx;
            float zi = g.height[i];
            static int32 const NB[4][2] = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } };
            bool all = true;                            // every neighbour seen to (else the cell goes back on the queue)
            for (auto const& nb : NB)
            {
                int32 jx = ix + nb[0], jy = iy + nb[1];
                if (jx < 0 || jy < 0 || jx >= g.nx || jy >= g.ny)
                    continue;
                int32 j = jy * g.nx + jx;
                uint8 dirBit = uint8(1u << (&nb - NB)), backBit = uint8(1u << ((&nb - NB) ^ 1));   // E W N S; ^1 is the opposite
                if (g.open[j])
                {
                    // both floor: whether a buddy can step between them is
                    // recorded once per pair for the distance maps (617o3);
                    // the flood itself needs nothing more from this pair
                    if (e->tested[i] & dirBit)
                        continue;
                    if (!budget)
                    {
                        all = false;
                        break;
                    }
                    --budget;
                    e->tested[i] |= dirBit, e->tested[j] |= backBit;
                    double xi, yi, xj, yj;
                    g.CellXY(i, xi, yi);
                    g.CellXY(j, xj, yj);
                    if (BuddyGridRules::Gentle(zi, g.height[j], g.cell) &&
                        BuddyMeshLineClear(map, { float(xi), float(yi), zi }, { float(xj), float(yj), g.height[j] }))
                        e->joins[i] |= dirBit, e->joins[j] |= backBit;
                    continue;
                }
                if (!e->probed[j])
                {
                    if (!budget)
                    {
                        all = false;                    // out of measurements this tick: finish this cell next tick
                        break;
                    }
                    double x, y;
                    g.CellXY(j, x, y);
                    float rise = float(g.cell) * MAX_GRADE;
                    float z = map->GetHeight(e->phaseMask, float(x), float(y), zi + rise, true, rise + PROBE_DROP);
                    ++e->probes;
                    --budget;
                    e->probed[j] = 1;
                    if (z <= INVALID_HEIGHT)
                    {
                        ++e->noGround;
                        continue;                       // no ground: outside the walkable
                    }
                    // floor only where the navigation mesh is (617o2): the
                    // height lookup above knows terrain and buildings but not
                    // placed rocks, crystals or wreckage, which the mesh (what
                    // the walking walks on) leaves holes for; the cell's
                    // height is the mesh's
                    BuddyRoam::Point onMesh;
                    if (!BuddyMeshSnap(map, { float(x), float(y), z }, MESH_SNAP_YARDS, MESH_RISE_YARDS, onMesh))
                    {
                        ++e->noMesh;
                        continue;                       // ground, but nowhere to stand
                    }
                    z = onMesh.z;
                    g.height[j] = z;
                    g.inside[j] = map->GetAreaId(e->phaseMask, float(x), float(y), z) == e->areaId ? 1 : 0;
                }
                // part of the area and a gentle enough change from here: walkable,
                // and its own neighbours are measured in turn; too steep from here
                // may still be walked onto from another side. The step must also
                // stay on the mesh (617o2): a wall, cliff edge or gap between the
                // two middles refuses it, though either may be reached another way
                bool gentle = g.inside[j] && BuddyGridRules::Gentle(zi, g.height[j], g.cell);
                if (gentle)
                {
                    double xi, yi, xj, yj;
                    g.CellXY(i, xi, yi);
                    g.CellXY(j, xj, yj);
                    if (!BuddyMeshLineClear(map, { float(xi), float(yi), zi }, { float(xj), float(yj), g.height[j] }))
                    {
                        ++e->walled;
                        gentle = false;
                    }
                }
                e->tested[i] |= dirBit, e->tested[j] |= backBit;
                if (gentle)
                {
                    g.open[j] = 1;
                    e->joins[i] |= dirBit, e->joins[j] |= backBit;
                    e->queue.push_back(j);
                }
            }
            if (!all)
            {
                e->queue.push_front(i);
                break;
            }
        }
        if (e->queue.empty() && e->state.load() == GRID_MEASURING)
        {
            e->state = GRID_COMPUTING;
            std::thread(FinishGrid, e).detach();
        }
    }
}

static std::shared_ptr<GridEntry> ReadyGrid(GridKey const& key)
{
    std::lock_guard<std::mutex> lock(sGridLock);
    auto found = sGrids.find(key);
    if (found == sGrids.end() || found->second->state.load() != GRID_READY)
        return nullptr;
    return found->second;
}
// }}}

// {{{ the distance maps (617o3)
// For one goal on one grid: every floor cell's walking distance to the
// goal, in cells, over the joins the measuring recorded (a step between two
// cells counts only where the mesh lets a buddy take it). A flood outward
// from the goal fills it, each cell once (every step costs the same, so a
// plain first-in-first-out flood gives the shortest distances). A buddy
// walks one by stepping to a joined neighbour with a lower number. Built
// the first time a goal is asked for, on the asking thread (an area of
// 30,000 floor cells floods in about a millisecond), and kept for the
// server's run: the ground doesn't change. At most MAPS_KEPT, the least
// recently used dropped first.
static constexpr size_t MAPS_KEPT    = 64;
static constexpr int32  GOAL_SEARCH  = 3;      // cells round a goal's own cell searched for floor when it isn't floor
static constexpr int32  UNREACHED    = -1;
struct DistMap
{
    std::vector<int32_t> dist;     // cells to the goal; UNREACHED where the flood never came
    uint64               usedAt = 0;
};
using DistKey = std::tuple<uint32, uint32, uint32, int32>;   // map, area, piece, goal cell
static std::mutex sDistLock;
static std::map<DistKey, std::shared_ptr<DistMap>> sDist;

// The floor cell nearest (x, y) within GOAL_SEARCH cells, or -1.
static int32 FloorNear(BuddyExplore::Grid const& g, double x, double y)
{
    int32 c = g.CellOf(x, y);
    if (c >= 0 && g.open[c])
        return c;
    int32 best = -1;
    double bestD = 1e30;
    int32 cx = int32((x - g.x0) / g.cell), cy = int32((y - g.y0) / g.cell);
    for (int32 dy = -GOAL_SEARCH; dy <= GOAL_SEARCH; ++dy)
        for (int32 dx = -GOAL_SEARCH; dx <= GOAL_SEARCH; ++dx)
        {
            int32 jx = cx + dx, jy = cy + dy;
            if (jx < 0 || jy < 0 || jx >= g.nx || jy >= g.ny)
                continue;
            int32 j = jy * g.nx + jx;
            if (!g.open[j])
                continue;
            double d = double(dx * dx + dy * dy);
            if (d < bestD)
                best = j, bestD = d;
        }
    return best;
}

static std::shared_ptr<DistMap> DistFor(GridKey const& key, std::shared_ptr<GridEntry> const& e, int32 goal)
{
    DistKey dk(std::get<0>(key), std::get<1>(key), std::get<2>(key), goal);
    uint64 now = uint64(GameTime::GetGameTimeMS().count());
    {
        std::lock_guard<std::mutex> lock(sDistLock);
        auto it = sDist.find(dk);
        if (it != sDist.end())
        {
            it->second->usedAt = now;
            return it->second;
        }
    }
    BuddyExplore::Grid const& g = e->grid;
    auto t0 = std::chrono::steady_clock::now();
    auto m = std::make_shared<DistMap>();
    m->dist.assign(size_t(g.Count()), UNREACHED);
    m->usedAt = now;
    std::deque<int32> flood { goal };
    m->dist[goal] = 0;
    int32 const offset[4] = { 1, -1, g.nx, -g.nx };   // east, west, north, south: the joins' bit order
    uint32 reached = 1;
    while (!flood.empty())
    {
        int32 i = flood.front();
        flood.pop_front();
        for (int32 d = 0; d < 4; ++d)
        {
            if (!(e->joins[i] & (1u << d)))
                continue;
            int32 j = i + offset[d];
            if (m->dist[j] != UNREACHED)
                continue;
            m->dist[j] = m->dist[i] + 1;
            ++reached;
            flood.push_back(j);
        }
    }
    double ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
    double gx, gy;
    g.CellXY(goal, gx, gy);
    LOG_INFO("module", "mod-buddies: distance map for ({:.1f}, {:.1f}) in area {} on map {}: {} of {} floor cells reached, "
        "built in {:.1f} ms", gx, gy, e->areaId, e->mapId, reached, uint32(g.openList.size()), ms);
    std::lock_guard<std::mutex> lock(sDistLock);
    if (sDist.size() >= MAPS_KEPT)
    {
        auto oldest = sDist.begin();
        for (auto it = sDist.begin(); it != sDist.end(); ++it)
            if (it->second->usedAt < oldest->second->usedAt)
                oldest = it;
        sDist.erase(oldest);
    }
    sDist[dk] = m;
    return m;
}

bool BuddyExploreStepToward(Player* bot, Player* owner, uint32 areaId, BuddyRoam::Point const& goal, float lookahead,
                            BuddyRoam::Point& next)
{
    GridKey key;
    RequestGrid(owner, areaId, key);                   // starts the measuring if this area has none yet
    std::shared_ptr<GridEntry> e = ReadyGrid(key);
    if (!e)
        return false;                                  // still being measured (or failed): no map yet
    BuddyExplore::Grid const& g = e->grid;
    int32 goalCell = FloorNear(g, goal.x, goal.y);
    int32 here     = FloorNear(g, bot->GetPositionX(), bot->GetPositionY());
    if (goalCell < 0 || here < 0)
        return false;                                  // the goal or the buddy is off this grid's floor
    std::shared_ptr<DistMap> m = DistFor(key, e, goalCell);
    if (m->dist[here] == UNREACHED)
        return false;                                  // no joined way from here to there on this grid
    int32 const offset[4] = { 1, -1, g.nx, -g.nx };
    int32 steps = std::max(1, int32(lookahead / float(g.cell)));
    int32 at = here;
    while (steps-- > 0 && m->dist[at] > 0)
    {
        int32 bestJ = -1;
        for (int32 d = 0; d < 4; ++d)
            if ((e->joins[at] & (1u << d)) && m->dist[at + offset[d]] == m->dist[at] - 1)
            {
                bestJ = at + offset[d];
                break;
            }
        if (bestJ < 0)
            break;                                     // cannot happen on a finished flood; stop rather than wander
        at = bestJ;
    }
    double x, y;
    g.CellXY(at, x, y);
    next = { float(x), float(y), g.height[at] };
    return true;
}
// }}}

// {{{ the view: hilltops and what stands in the way (617o5)
// Read from a Ready grid only (its floor, heights and joins are final).
static constexpr int32 HILL_RADIUS     = 3;      // cells: a hilltop is the highest floor cell this far round
static constexpr float HILL_MIN_RISE   = 3.0f;   // yards: a "hill" stands at least this far above the buddy
static constexpr int32 BLOB_MAX_CELLS  = 1500;   // an obstacle's outline bigger than this (a whole cliff, a town wall) is not orbited

// Whether floor cell i is a hilltop: no floor cell within HILL_RADIUS is
// higher (an equal one with a lower number wins, so a flat top has one).
static bool IsHilltop(BuddyExplore::Grid const& g, int32 i)
{
    int32 ix = i % g.nx, iy = i / g.nx;
    for (int32 dy = -HILL_RADIUS; dy <= HILL_RADIUS; ++dy)
        for (int32 dx = -HILL_RADIUS; dx <= HILL_RADIUS; ++dx)
        {
            int32 jx = ix + dx, jy = iy + dy;
            if ((!dx && !dy) || jx < 0 || jy < 0 || jx >= g.nx || jy >= g.ny)
                continue;
            int32 j = jy * g.nx + jx;
            if (g.open[j] && (g.height[j] > g.height[i] || (g.height[j] == g.height[i] && j < i)))
                return false;
        }
    return true;
}

bool BuddyExploreHilltop(Player* bot, Player* owner, uint32 areaId, BuddyHillChoice choice, BuddyRoam::Point const& middle,
                         BuddyRoam::Point& top)
{
    GridKey key;
    RequestGrid(owner, areaId, key);
    std::shared_ptr<GridEntry> e = ReadyGrid(key);
    if (!e)
        return false;
    BuddyExplore::Grid const& g = e->grid;
    int32 here = FloorNear(g, bot->GetPositionX(), bot->GetPositionY());
    if (here < 0)
        return false;
    float baseZ = g.height[here];

    // the hill in the way: the highest floor cell under the straight line
    // to the middle, then uphill from it (joined steps only) to its top
    int32 start = -1;
    if (choice == BuddyHillChoice::InTheWay)
    {
        double len = std::hypot(middle.x - bot->GetPositionX(), middle.y - bot->GetPositionY());
        for (double s = 0.0; s < len; s += g.cell)
        {
            double k = s / std::max(len, 1.0);
            int32 c = g.CellOf(bot->GetPositionX() + (middle.x - bot->GetPositionX()) * k,
                               bot->GetPositionY() + (middle.y - bot->GetPositionY()) * k);
            if (c >= 0 && g.open[c] && (start < 0 || g.height[c] > g.height[start]))
                start = c;
        }
        if (start < 0)
            return false;
        int32 const offset[4] = { 1, -1, g.nx, -g.nx };
        for (bool climbed = true; climbed; )
        {
            climbed = false;
            for (int32 d = 0; d < 4; ++d)
                if ((e->joins[start] & (1u << d)) && g.height[start + offset[d]] > g.height[start])
                {
                    start   = start + offset[d];
                    climbed = true;
                    break;
                }
        }
    }
    else
    {
        // a hilltop high enough, nearest the middle or nearest the buddy
        double fromX = choice == BuddyHillChoice::NearestMiddle ? middle.x : bot->GetPositionX();
        double fromY = choice == BuddyHillChoice::NearestMiddle ? middle.y : bot->GetPositionY();
        double best = 1e30;
        for (int32 i : g.openList)
        {
            if (g.height[i] < baseZ + HILL_MIN_RISE || !IsHilltop(g, i))
                continue;
            double x, y;
            g.CellXY(i, x, y);
            double d = (x - fromX) * (x - fromX) + (y - fromY) * (y - fromY);
            if (d < best)
                best = d, start = i;
        }
        if (start < 0)
            return false;
    }
    if (g.height[start] < baseZ + HILL_MIN_RISE)
        return false;                                  // nothing worth calling a hill
    std::shared_ptr<DistMap> m = DistFor(key, e, start);
    if (m->dist[here] == UNREACHED)
        return false;                                  // no joined way up it from here
    double x, y;
    g.CellXY(start, x, y);
    top = { float(x), float(y), g.height[start] };
    return true;
}

bool BuddyExploreObstacle(Player* owner, uint32 areaId, BuddyRoam::Point const& hit, BuddyRoam::Point& centre, float& reach)
{
    GridKey key;
    RequestGrid(owner, areaId, key);
    std::shared_ptr<GridEntry> e = ReadyGrid(key);
    if (!e)
        return false;
    BuddyExplore::Grid const& g = e->grid;
    // the obstacle's footprint: the cells that aren't floor (inside the
    // area's borders, or measured and found without mesh) joined to the
    // cell the look struck, flooded until floor surrounds them
    int32 seed = g.CellOf(hit.x, hit.y);
    if (seed < 0)
        return false;
    if (g.open[seed])
    {
        // struck above open floor (an overhang, a thin trunk): the
        // nearest non-floor cell round it is the footprint's start
        int32 sx = seed % g.nx, sy = seed / g.nx;
        seed = -1;
        for (int32 r = 1; r <= 2 && seed < 0; ++r)
            for (int32 dy = -r; dy <= r && seed < 0; ++dy)
                for (int32 dx = -r; dx <= r && seed < 0; ++dx)
                {
                    int32 jx = sx + dx, jy = sy + dy;
                    if (jx >= 0 && jy >= 0 && jx < g.nx && jy < g.ny && !g.open[jy * g.nx + jx])
                        seed = jy * g.nx + jx;
                }
        if (seed < 0)
            return false;
    }
    std::vector<uint8_t> seen(size_t(g.Count()), 0);
    std::deque<int32> flood { seed };
    std::vector<int32> blob;
    seen[seed] = 1;
    while (!flood.empty())
    {
        int32 i = flood.front();
        flood.pop_front();
        blob.push_back(i);
        if (int32(blob.size()) > BLOB_MAX_CELLS)
            return false;                              // too big to walk round: a cliff or a wall, not a doodad
        int32 ix = i % g.nx, iy = i / g.nx;
        static int32 const NB[4][2] = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } };
        for (auto const& nb : NB)
        {
            int32 jx = ix + nb[0], jy = iy + nb[1];
            if (jx < 0 || jy < 0 || jx >= g.nx || jy >= g.ny)
                return false;                          // runs off the grid: not something to circle
            int32 j = jy * g.nx + jx;
            if (seen[j] || g.open[j])
                continue;
            seen[j] = 1;
            flood.push_back(j);
        }
    }
    double sx = 0.0, sy = 0.0;
    for (int32 i : blob)
    {
        double x, y;
        g.CellXY(i, x, y);
        sx += x, sy += y;
    }
    sx /= double(blob.size()), sy /= double(blob.size());
    double far = 0.0;
    for (int32 i : blob)
    {
        double x, y;
        g.CellXY(i, x, y);
        far = std::max(far, std::hypot(x - sx, y - sy));
    }
    centre = { float(sx), float(sy), hit.z };
    reach  = float(far + g.cell * 0.5);                 // to the far side of its farthest cell
    return true;
}
// }}}

// {{{ the paint
// One per owner per area piece. Its explorers are the buddies' choosing
// state in that area (a new area starts them afresh). Guarded by
// sPaintLock: the buddies choose on their map threads, the world update
// paints and pulses.
struct ClanPaint
{
    std::shared_ptr<GridEntry> grid;
    BuddyExplore::Paint paint;
    double ex = 0.0, ey = 0.0, farRef = 1.0;   // where the owner entered (the far measure's origin)
    uint64 lastPulse = 0, leftAt = 0;
    std::unordered_map<uint32, BuddyExplore::Explorer> explorers;   // buddy guid -> its state
};
using PaintKey = std::tuple<uint32, uint32, uint32, uint32>;   // owner, map, area, piece
static std::mutex sPaintLock;
static std::map<PaintKey, ClanPaint> sPaint;
// where each owner entered its current area (owner guid -> map, area, x, y)
struct Entered { uint32 mapId = 0, areaId = 0; float x = 0.0f, y = 0.0f; };
static std::unordered_map<uint32, Entered> sEntered;          // world thread only
static std::mutex sWarnLock;
static std::set<std::tuple<uint32, uint32, uint32>> sWarned;  // (owner, map, area): "not ready yet" logged once
static std::map<uint32, uint64> sForcedAt;                      // owner -> when a buddy of theirs last needed rooms (sWarnLock)

// The clan's paint for the owner's area, made when first needed (paint
// starts empty, the walls pulse at once). Caller holds sPaintLock.
static ClanPaint* PaintFor(uint32 ownerGuid, GridKey const& key, std::shared_ptr<GridEntry> const& grid, float ex, float ey)
{
    PaintKey pk(ownerGuid, std::get<0>(key), std::get<1>(key), std::get<2>(key));
    auto found = sPaint.find(pk);
    if (found != sPaint.end())
        return &found->second;
    ClanPaint& cp = sPaint[pk];
    cp.grid = grid;
    cp.paint.Reset(grid->grid);
    BuddyExplore::WallPulse(grid->grid, cp.paint);
    cp.lastPulse = uint64(GameTime::GetGameTimeMS().count());
    cp.ex = ex, cp.ey = ey;
    cp.farRef = std::max(1.0, BuddyExplore::FarRef(grid->grid, ex, ey));
    return &cp;
}
// }}}

// {{{ BuddyExploreNext
bool BuddyExploreNext(Player* bot, Player* owner, uint32 areaId, std::vector<BuddyRoam::Point>& path, BuddyExploreMode forced)
{
    uint32 ownerGuid = owner->GetGUID().GetCounter(), guid = bot->GetGUID().GetCounter();
    // a mode forced by the roam action (rooms, indoors) wins over the
    // owner's setting; the owner's grid is then wanted by the world pass
    // for a while, so it gets measured
    BuddyExploreMode mode = forced != BUDDY_EXPLORE_PINWHEEL ? forced : BuddyExploreModeFor(ownerGuid, guid);
    if (mode == BUDDY_EXPLORE_PINWHEEL || mode == BUDDY_EXPLORE_MIXED)
        return false;
    if (forced != BUDDY_EXPLORE_PINWHEEL)
    {
        std::lock_guard<std::mutex> lock(sWarnLock);
        sForcedAt[ownerGuid] = uint64(GameTime::GetGameTimeMS().count());
    }
    GridKey key;
    std::shared_ptr<GridEntry> entry;
    {
        // the grid is requested from here the first time; measuring then
        // goes on in the world update
        BuddyAreaPieceInfo piece;
        PieceAt(owner, areaId, piece);
        key = GridKey(owner->GetMapId(), areaId, piece.piece);
        entry = ReadyGrid(key);
    }
    if (!entry)
    {
        std::lock_guard<std::mutex> lock(sWarnLock);
        if (sWarned.insert(std::make_tuple(ownerGuid, owner->GetMapId(), areaId)).second)
            LOG_WARN("module", "mod-buddies: {}'s buddies explore area {} on map {} by the pinwheel while its exploring grid "
                "is measured (the other systems need it); they switch once it is ready", owner->GetName(), areaId, owner->GetMapId());
        return false;
    }
    BuddyExplore::Settings s;
    BuddyExplore::Grid const& g = entry->grid;
    std::lock_guard<std::mutex> lock(sPaintLock);
    auto enteredAt = std::make_pair(owner->GetPositionX(), owner->GetPositionY());
    ClanPaint* cp = PaintFor(ownerGuid, key, entry, enteredAt.first, enteredAt.second);
    auto found = cp->explorers.find(guid);
    bool fresh = found == cp->explorers.end();
    BuddyExplore::Explorer& e = cp->explorers[guid];
    e.x = bot->GetPositionX(), e.y = bot->GetPositionY();
    if (fresh)
    {
        e.id = int32(cp->explorers.size());
        e.spin = urand(0, 1) ? 1 : -1;
        if (mode == BUDDY_EXPLORE_DISC)
            BuddyExplore::BeginDisc(g, e);
    }
    BuddyExplore::Rng rng = [] { return rand_norm(); };
    bool picked = false;
    switch (mode)
    {
        case BUDDY_EXPLORE_LEAST: picked = BuddyExplore::PickLeast(g, cp->paint, s, e, cp->ex, cp->ey, cp->farRef, rng); break;
        case BUDDY_EXPLORE_ROOMS: picked = BuddyExplore::PickRooms(g, cp->paint, s, e, cp->ex, cp->ey, cp->farRef, rng); break;
        case BUDDY_EXPLORE_DISC:  picked = BuddyExplore::PickDisc(g, cp->paint, s, e, cp->ex, cp->ey, cp->farRef, rng); break;
        default: break;
    }
    if (!picked)
        return false;
    std::vector<BuddyExplore::Point2> pts = BuddyExplore::GridPath(g, cp->paint, s, e.x, e.y, e.gx, e.gy, s.pathWeight);
    if (pts.empty())
    {
        // no way over the grid's walkable cells from where it stands (off
        // the measured floor: another level, beyond a ledge): this pick
        // falls to the pinwheel; said once per buddy and area
        std::lock_guard<std::mutex> warn(sWarnLock);
        if (sWarned.insert(std::make_tuple(guid, owner->GetMapId(), areaId | 0x80000000u)).second)
            LOG_WARN("module", "mod-buddies: buddy {} at ({:.1f}, {:.1f}) has no way over area {}'s measured floor to its "
                "chosen spot ({:.1f}, {:.1f}); that pick goes to the pinwheel", bot->GetName(), e.x, e.y, areaId, e.gx, e.gy);
        return false;
    }
    path.clear();
    path.push_back({ bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ() });
    for (BuddyExplore::Point2 const& p : pts)
    {
        int32 c = g.CellOf(p.x, p.y);
        float z = (c >= 0 && g.open[c]) ? g.height[c] : bot->GetPositionZ();
        path.push_back({ float(p.x), float(p.y), z });
    }
    return true;
}
// }}}

// {{{ the world update: measuring, painting, pulsing, dropping
class buddies_explore_world : public WorldScript
{
public:
    buddies_explore_world() : WorldScript("buddies_explore_world", { WORLDHOOK_ON_UPDATE }) { }

    void OnUpdate(uint32 diff) override
    {
        if (!BuddiesEnabled())
            return;
        MeasureSome();
        _sincePaint += diff;
        if (_sincePaint < PAINT_EVERY_MS)
            return;
        _sincePaint = 0;
        uint64 now = uint64(GameTime::GetGameTimeMS().count());
        BuddyExplore::Settings s;

        // owners: where they entered their area, and grids for the areas of
        // owners whose buddies explore by paint
        std::set<uint32> owners;
        for (auto const& pair : BuddyRosterPairs())
            owners.insert(pair.second);
        std::set<PaintKey> present;
        for (uint32 ownerGuid : owners)
        {
            Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(ownerGuid));
            if (!owner || !owner->IsInWorld() || owner->GetMap()->Instanceable())
                continue;
            Entered& en = sEntered[ownerGuid];
            if (en.mapId != owner->GetMapId() || en.areaId != owner->GetAreaId())
                en = { owner->GetMapId(), owner->GetAreaId(), owner->GetPositionX(), owner->GetPositionY() };
            bool wants = false;
            for (auto const& pair : BuddyRosterPairs())
                if (pair.second == ownerGuid)
                {
                    BuddyExploreMode m = BuddyExploreModeFor(ownerGuid, pair.first);
                    wants = wants || (m != BUDDY_EXPLORE_PINWHEEL && m != BUDDY_EXPLORE_MIXED);
                }
            {
                // a buddy needed rooms lately (indoors, or the pinwheel found nothing)
                std::lock_guard<std::mutex> lock(sWarnLock);
                auto f = sForcedAt.find(ownerGuid);
                wants = wants || (f != sForcedAt.end() && uint64(GameTime::GetGameTimeMS().count()) - f->second < FORCED_KEEP_MS);
            }
            if (!wants || BuddyTownArea(owner))
                continue;
            GridKey key;
            std::shared_ptr<GridEntry> grid = RequestGrid(owner, owner->GetAreaId(), key);
            if (!grid || grid->state.load() != GRID_READY)
                continue;
            std::lock_guard<std::mutex> lock(sPaintLock);
            PaintFor(ownerGuid, key, grid, en.x, en.y);
            present.insert(PaintKey(ownerGuid, std::get<0>(key), std::get<1>(key), std::get<2>(key)));
        }

        std::lock_guard<std::mutex> lock(sPaintLock);
        // buddies paint where they stand, in their owner's area, fighting or not
        for (auto const& pair : BuddyRosterPairs())
        {
            Player* bot = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(pair.first));
            Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(pair.second));
            if (!bot || !owner || !bot->IsInWorld() || bot->GetMapId() != owner->GetMapId() || bot->GetAreaId() != owner->GetAreaId())
                continue;
            for (auto& kv : sPaint)
                if (std::get<0>(kv.first) == pair.second && std::get<1>(kv.first) == bot->GetMapId()
                    && std::get<2>(kv.first) == bot->GetAreaId() && present.count(kv.first))
                    BuddyExplore::Deposit(kv.second.grid->grid, kv.second.paint, s, bot->GetPositionX(), bot->GetPositionY());
        }
        // the walls pulse; paint the owner has left for DROP_AFTER_MS is dropped
        for (auto it = sPaint.begin(); it != sPaint.end(); )
        {
            ClanPaint& cp = it->second;
            if (present.count(it->first))
            {
                cp.leftAt = 0;
                if (now - cp.lastPulse >= PULSE_EVERY_MS)
                {
                    BuddyExplore::WallPulse(cp.grid->grid, cp.paint);
                    cp.lastPulse = now;
                }
                ++it;
                continue;
            }
            if (!cp.leftAt)
                cp.leftAt = now;
            if (now - cp.leftAt >= DROP_AFTER_MS)
            {
                LOG_DEBUG("module", "mod-buddies: owner {} left area {} on map {} {} s ago; its exploring paint ({:.0f}% explored) is dropped",
                    std::get<0>(it->first), std::get<2>(it->first), std::get<1>(it->first), DROP_AFTER_MS / 1000,
                    100.0 * BuddyExplore::Coverage(cp.grid->grid, cp.paint));
                it = sPaint.erase(it);
                continue;
            }
            ++it;
        }
    }

private:
    uint32 _sincePaint = 0;
};
// }}}

// {{{ AddSC_buddies_explore
void AddSC_buddies_explore()
{
    new buddies_explore_world();
}
// }}}
