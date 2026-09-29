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
#include "roam/buddy_explore_core.h"
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
// Cell size: 3 yards. The model's drawn hall used 2; in the world 3 keeps a
// good-sized named area (500 by 500 yards) at under 28,000 cells, still
// splits a 6-yard tunnel into two cells a path can walk (paths keep 1.5
// yards off walls), and is about a body and a stride. Areas so big they
// would pass MAX_CELLS get bigger cells instead (logged).
static constexpr float  CELL_YARDS      = 3.0f;
static constexpr int32  MAX_CELLS       = 250000;
static constexpr uint32 PROBES_PER_TICK = 600;     // ground measurements per world tick while a grid is measured
static constexpr float  MAX_GRADE       = 1.0f;    // rise over run a buddy walks (45 degrees); more is a wall
static constexpr float  PROBE_DROP      = 50.0f;   // yards below a cell's neighbour its ground is looked for
static constexpr uint32 PAINT_EVERY_MS  = 1000;    // each buddy paints this often
static constexpr uint32 PULSE_EVERY_MS  = 3000;    // the walls' pulse (the owner: "a pulse every 3 seconds or so")
static constexpr uint32 DROP_AFTER_MS   = 15000;   // paint dropped this long after the owner leaves the area
static constexpr uint32 RETRY_FAILED_MS = 60000;   // a grid whose measuring failed is tried again after this
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
    uint64  startedMs = 0, failedAt = 0;
    double  computeMs = 0.0;
    int32   sweeps = 0;
};
using GridKey = std::tuple<uint32, uint32, uint32>;   // map, area, piece
static std::mutex sGridLock;
static std::map<GridKey, std::shared_ptr<GridEntry>> sGrids;

// Start measuring the grid of the area piece the owner stands in (the
// cell under the owner is the first floor). Null when the area has no row
// in the area table (logged there) or the owner stands off it.
static std::shared_ptr<GridEntry> RequestGrid(Player* owner, uint32 areaId, GridKey& key)
{
    BuddyAreaPieceInfo piece;
    if (!BuddyAreaPieceAt(owner->GetMapId(), areaId, owner->GetPositionX(), owner->GetPositionY(), piece))
        return nullptr;
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
    // the piece's borders (its 33-yard squares' edges) and one cell more
    float cell = CELL_YARDS;
    float w = piece.maxX - piece.minX + 2.0f * cell, h = piece.maxY - piece.minY + 2.0f * cell;
    if (w * h / (cell * cell) > float(MAX_CELLS))
    {
        cell = std::ceil(std::sqrt(w * h / float(MAX_CELLS)) * 2.0f) / 2.0f;   // up to the next half yard
        LOG_INFO("module", "mod-buddies: area {} on map {} is {:.0f} by {:.0f} yards; its exploring grid uses {:.1f}-yard cells "
            "to stay under {} cells", areaId, e->mapId, w, h, cell, MAX_CELLS);
    }
    g.cell = cell;
    g.x0 = piece.minX - cell, g.y0 = piece.minY - cell;
    g.nx = int32(std::ceil((piece.maxX - piece.minX + 2.0f * cell) / cell));
    g.ny = int32(std::ceil((piece.maxY - piece.minY + 2.0f * cell) / cell));
    size_t n = size_t(g.nx) * size_t(g.ny);
    g.inside.assign(n, 0), g.open.assign(n, 0), g.height.assign(n, 0.0f);
    g.edge.assign(n, -1.0), g.wall.assign(n, -1.0);
    e->probed.assign(n, 0);
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
        "measured with {} probes ({} without ground) in {:.1f} s, worked out in {:.0f} ms ({} disc passes)",
        e->areaId, e->mapId, uint32(g.openList.size()), g.Count(), uint32(g.rooms.size()), uint32(g.tunnels.size()),
        e->probes, e->noGround, double(uint64(GameTime::GetGameTimeMS().count()) - e->startedMs) / 1000.0, e->computeMs, e->sweeps);
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
                if (g.open[j])
                    continue;
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
                    g.height[j] = z;
                    g.inside[j] = map->GetAreaId(e->phaseMask, float(x), float(y), z) == e->areaId ? 1 : 0;
                }
                // part of the area and a gentle enough change from here: walkable,
                // and its own neighbours are measured in turn; too steep from here
                // may still be walked onto from another side
                if (g.inside[j] && std::fabs(g.height[j] - zi) <= float(g.cell) * MAX_GRADE)
                {
                    g.open[j] = 1;
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
bool BuddyExploreNext(Player* bot, Player* owner, uint32 areaId, std::vector<BuddyRoam::Point>& path)
{
    uint32 ownerGuid = owner->GetGUID().GetCounter(), guid = bot->GetGUID().GetCounter();
    BuddyExploreMode mode = BuddyExploreModeFor(ownerGuid, guid);
    if (mode == BUDDY_EXPLORE_PINWHEEL || mode == BUDDY_EXPLORE_MIXED)
        return false;
    GridKey key;
    std::shared_ptr<GridEntry> entry;
    {
        // the grid is requested from here the first time; measuring then
        // goes on in the world update
        BuddyAreaPieceInfo piece;
        if (!BuddyAreaPieceAt(owner->GetMapId(), areaId, owner->GetPositionX(), owner->GetPositionY(), piece))
            return false;
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
            if (!wants || BuddyAreaIsTown(owner->GetAreaId()))
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
