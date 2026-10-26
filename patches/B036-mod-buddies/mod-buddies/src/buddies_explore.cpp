
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

using BuddyGridRules::CELL_YARDS;
using BuddyGridRules::MAX_CELLS;
using BuddyGridRules::MAX_GRADE;
using BuddyGridRules::MESH_SNAP_YARDS;
using BuddyGridRules::MESH_RISE_YARDS;
static constexpr uint32 PROBES_PER_TICK = 600;
static constexpr float  PROBE_DROP      = 50.0f;
static constexpr uint32 PAINT_EVERY_MS  = 1000;
static constexpr uint32 PULSE_EVERY_MS  = 3000;
static constexpr uint32 DROP_AFTER_MS   = 15000;
static constexpr uint32 RETRY_FAILED_MS = 60000;
static constexpr float  INDOOR_BOX_YARDS = 100.0f;
static constexpr uint32 NO_PIECE        = 0xFFFFFFFFu;
static constexpr uint32 FORCED_KEEP_MS  = 60000;
static constexpr int32  DISC_SWEEPS     = 4000;
static constexpr double DISC_TOLERANCE  = 1e-6;

static std::mutex sSettingLock;
static std::unordered_map<uint32, BuddyExploreMode> sSetting;

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

enum GridState : int32 { GRID_MEASURING, GRID_COMPUTING, GRID_READY, GRID_FAILED };
struct GridEntry
{
    std::atomic<int32> state { GRID_MEASURING };
    BuddyExplore::Grid grid;
    uint32 mapId = 0, areaId = 0, phaseMask = 1, piece = 0;
    std::deque<int32>    queue;
    std::vector<uint8_t> probed;
    uint32  probes = 0, noGround = 0;
    uint32  noMesh = 0, walled = 0;
    std::vector<uint8_t> joins, tested;
    uint64  startedMs = 0, failedAt = 0;
    double  computeMs = 0.0;
    int32   sweeps = 0;
};
using GridKey = std::tuple<uint32, uint32, uint32>;
static std::mutex sGridLock;
static std::map<GridKey, std::shared_ptr<GridEntry>> sGrids;

static bool PieceAt(Player* owner, uint32 areaId, BuddyAreaPieceInfo& piece)
{
    if (BuddyAreaPieceAt(owner->GetMapId(), areaId, owner->GetPositionX(), owner->GetPositionY(), piece))
        return true;
    piece.piece = NO_PIECE;
    piece.minX = owner->GetPositionX() - INDOOR_BOX_YARDS, piece.maxX = owner->GetPositionX() + INDOOR_BOX_YARDS;
    piece.minY = owner->GetPositionY() - INDOOR_BOX_YARDS, piece.maxY = owner->GetPositionY() + INDOOR_BOX_YARDS;
    return true;
}

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
        if (found->second->state.load() != GRID_FAILED || now - found->second->failedAt < RETRY_FAILED_MS)
            return found->second;
        sGrids.erase(found);
    }
    auto e = std::make_shared<GridEntry>();
    e->mapId = owner->GetMapId(), e->areaId = areaId, e->phaseMask = owner->GetPhaseMask(), e->piece = piece.piece;
    e->startedMs = now;
    BuddyExplore::Grid& g = e->grid;
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
            bool all = true;
            for (auto const& nb : NB)
            {
                int32 jx = ix + nb[0], jy = iy + nb[1];
                if (jx < 0 || jy < 0 || jx >= g.nx || jy >= g.ny)
                    continue;
                int32 j = jy * g.nx + jx;
                uint8 dirBit = uint8(1u << (&nb - NB)), backBit = uint8(1u << ((&nb - NB) ^ 1));
                if (g.open[j])
                {
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
                        all = false;
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
                        continue;
                    }
                    BuddyRoam::Point onMesh;
                    if (!BuddyMeshSnap(map, { float(x), float(y), z }, MESH_SNAP_YARDS, MESH_RISE_YARDS, onMesh))
                    {
                        ++e->noMesh;
                        continue;
                    }
                    z = onMesh.z;
                    g.height[j] = z;
                    g.inside[j] = map->GetAreaId(e->phaseMask, float(x), float(y), z) == e->areaId ? 1 : 0;
                }
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

static constexpr size_t MAPS_KEPT    = 64;
static constexpr int32  GOAL_SEARCH  = 3;
static constexpr int32  UNREACHED    = -1;
struct DistMap
{
    std::vector<int32_t> dist;
    uint64               usedAt = 0;
};
using DistKey = std::tuple<uint32, uint32, uint32, int32>;
static std::mutex sDistLock;
static std::map<DistKey, std::shared_ptr<DistMap>> sDist;

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
    int32 const offset[4] = { 1, -1, g.nx, -g.nx };
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
    RequestGrid(owner, areaId, key);
    std::shared_ptr<GridEntry> e = ReadyGrid(key);
    if (!e)
        return false;
    BuddyExplore::Grid const& g = e->grid;
    int32 goalCell = FloorNear(g, goal.x, goal.y);
    int32 here     = FloorNear(g, bot->GetPositionX(), bot->GetPositionY());
    if (goalCell < 0 || here < 0)
        return false;
    std::shared_ptr<DistMap> m = DistFor(key, e, goalCell);
    if (m->dist[here] == UNREACHED)
        return false;
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
            break;
        at = bestJ;
    }
    double x, y;
    g.CellXY(at, x, y);
    next = { float(x), float(y), g.height[at] };
    return true;
}

static constexpr int32 HILL_RADIUS     = 3;
static constexpr float HILL_MIN_RISE   = 3.0f;
static constexpr int32 BLOB_MAX_CELLS  = 1500;

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
        return false;
    std::shared_ptr<DistMap> m = DistFor(key, e, start);
    if (m->dist[here] == UNREACHED)
        return false;
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
    int32 seed = g.CellOf(hit.x, hit.y);
    if (seed < 0)
        return false;
    if (g.open[seed])
    {
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
            return false;
        int32 ix = i % g.nx, iy = i / g.nx;
        static int32 const NB[4][2] = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } };
        for (auto const& nb : NB)
        {
            int32 jx = ix + nb[0], jy = iy + nb[1];
            if (jx < 0 || jy < 0 || jx >= g.nx || jy >= g.ny)
                return false;
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
    reach  = float(far + g.cell * 0.5);
    return true;
}

struct ClanPaint
{
    std::shared_ptr<GridEntry> grid;
    BuddyExplore::Paint paint;
    double ex = 0.0, ey = 0.0, farRef = 1.0;
    uint64 lastPulse = 0, leftAt = 0;
    std::unordered_map<uint32, BuddyExplore::Explorer> explorers;
};
using PaintKey = std::tuple<uint32, uint32, uint32, uint32>;
static std::mutex sPaintLock;
static std::map<PaintKey, ClanPaint> sPaint;
struct Entered { uint32 mapId = 0, areaId = 0; float x = 0.0f, y = 0.0f; };
static std::unordered_map<uint32, Entered> sEntered;
static std::mutex sWarnLock;
static std::set<std::tuple<uint32, uint32, uint32>> sWarned;
static std::map<uint32, uint64> sForcedAt;

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

bool BuddyExploreNext(Player* bot, Player* owner, uint32 areaId, std::vector<BuddyRoam::Point>& path, BuddyExploreMode forced)
{
    uint32 ownerGuid = owner->GetGUID().GetCounter(), guid = bot->GetGUID().GetCounter();
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

void AddSC_buddies_explore()
{
    new buddies_explore_world();
}
