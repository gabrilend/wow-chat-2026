/*
 * buddies_path.cpp - the switch between five ways for buddies to find
 * their way, in game (issue 617o7; what each part means is in
 * buddies_path.h). The ways' arithmetic is roam/buddy_path_ways.h; this
 * file fills its grid from the navigation mesh, sends the buddy to the
 * point it gives, refuses the steps the mesh refuses, and keeps the tally
 * the ".buddy path" command shows.
 */

#include "buddies.h"
#include "buddies_path.h"
#include "buddies_navmesh.h"
#include "roam/buddy_paint_paths.h"
#include "Chat.h"
#include "CommandScript.h"
#include "GameTime.h"
#include "Log.h"
#include "MotionMaster.h"
#include "MoveSpline.h"
#include "Player.h"
#include "ScriptMgr.h"
#include <algorithm>
#include <cctype>
#include <cmath>
#include <deque>
#include <filesystem>
#include <fstream>
#include <iterator>
#include "Config.h"
#include <mutex>
#include <unordered_map>

using namespace Acore::ChatCommands;
using BuddyPath::Way;

// {{{ the grid's size, and how often a buddy is given a new point
// CELL: yards between cell middles, the ways' own scale (their steps are 4
// yards, their probes 2 and 4); MARGIN: yards of ground round the buddy and
// its goal, room to go round what is between; MOST_CELLS: the grid's
// largest side (a far goal gets coarser cells, not a bigger grid: 80 by 80
// is 6,400 mesh questions, asked once a waypoint); RISE: how far up or down
// one cell's ground may be from its neighbour's (a 2-in-3 slope; steeper
// is not walked); ORDER_MS: a new point at most this often while the buddy
// is still walking to the last one (the ways take half-second steps, as
// in the offline test).
static constexpr float  CELL       = 3.0f;
static constexpr float  MARGIN     = 24.0f;
static constexpr int    MOST_CELLS = 80;
static constexpr float  RISE       = 2.0f;
static constexpr uint64 ORDER_MS   = 500;
// }}}

// {{{ the switch, by owner
static std::mutex sWayLock;
static std::unordered_map<uint32, Way> sWay;     // owner's character number -> way (absent: mesh)

bool BuddyPathWayFor(uint32 ownerGuid, Way& way)
{
    std::lock_guard<std::mutex> lock(sWayLock);
    auto it = sWay.find(ownerGuid);
    if (it == sWay.end())
        return false;
    way = it->second;
    return true;
}
// }}}

// {{{ each buddy's walk, and the tally by way
// heights: each open cell's ground (the mesh's), for the point the buddy is sent to
struct Walk
{
    Way              way = Way::Orbit;
    BuddyRoam::Point goal;
    uint32           mapId = 0;
    BuddyPath::Grid  grid;
    std::vector<float> heights;
    BuddyPath::Walker walker;
    uint64           started = 0, lastOrder = 0;
    uint32           orders = 0, refused = 0, plans = 0;
    // the painted map's walk (617o8): its region's map (by key), the
    // buddy's path on it, its lane and replanning jitter (its own, from its
    // character number), and where it stood last (for the crowd)
    uint64           paintKey = 0;
    BuddyPaint::Path ppath;
    bool             hasPath = false;
    double           lane = 0, jitter = 0, lastX = 0, lastY = 0, regionX = 0, regionY = 0;
};
struct Tally { uint32 walks = 0, arrived = 0, gaveUp = 0, refused = 0, stuck = 0, orbits = 0, kicks = 0, plans = 0; uint64 ms = 0; };
static std::mutex sWalkLock;
static std::unordered_map<uint32, Walk> sWalks;  // buddy's character number -> its walk
static Tally sTally[6];                          // by way (the Way's number)

void BuddyPathForget(uint32 buddyGuid)
{
    std::lock_guard<std::mutex> lock(sWalkLock);
    sWalks.erase(buddyGuid);
}

// a walk ended: into its way's tally
static void Count(Walk const& w, bool arrived, uint64 now)
{
    Tally& t = sTally[uint8(w.way)];
    ++t.walks;
    (arrived ? t.arrived : t.gaveUp) += 1;
    t.refused += w.refused;
    t.stuck   += uint32(w.walker.stuckCount);
    t.orbits  += uint32(w.walker.orbitCount);
    t.kicks   += uint32(w.walker.kickCount);
    t.plans   += uint32(w.walker.replanCount) + w.plans;
    t.ms      += now - w.started;
}
// }}}

// {{{ the grid, filled from the mesh
// A box round the buddy and its goal, cells CELL yards apart (coarser if
// the box would be more than MOST_CELLS across). Filled outward from the
// buddy's own cell, like water: a cell is open when the mesh has ground
// within half a cell of its middle, no more than RISE per cell up or down
// from the cell it was reached from, and a straight walk from that cell's
// middle to its own stays on the mesh. A cell the water never reached is
// closed, though there may be ground there: ground the buddy cannot walk
// to is no use to any way. False when the buddy's own cell has no mesh.
static bool FillGrid(Map const* map, BuddyRoam::Point const& at, BuddyRoam::Point const& goal, BuddyPath::Grid& g, std::vector<float>& heights)
{
    float minX = std::min(at.x, goal.x) - MARGIN, maxX = std::max(at.x, goal.x) + MARGIN;
    float minY = std::min(at.y, goal.y) - MARGIN, maxY = std::max(at.y, goal.y) + MARGIN;
    g.step = std::max(CELL, std::max(maxX - minX, maxY - minY) / float(MOST_CELLS - 1));
    g.x0 = minX, g.y0 = minY;
    g.w = int(std::ceil((maxX - minX) / g.step)) + 1;
    g.h = int(std::ceil((maxY - minY) / g.step)) + 1;
    size_t n = size_t(g.w * g.h);
    g.open.assign(n, 0);
    g.learned.assign(n, 0);
    heights.assign(n, at.z);

    int start = g.Cell({ at.x, at.y });
    BuddyRoam::Point onMesh;
    if (start < 0 || !BuddyMeshSnap(map, at, g.step * 0.5f, 4.0f, onMesh))
        return false;
    g.open[size_t(start)] = 1;
    heights[size_t(start)] = onMesh.z;
    std::deque<int> water { start };
    std::vector<uint8_t> asked(n, 0);
    asked[size_t(start)] = 1;
    while (!water.empty())
    {
        int q = water.front();
        water.pop_front();
        BuddyPath::P c = g.Centre(q);
        BuddyRoam::Point from { c.x, c.y, heights[size_t(q)] };
        // the four straight neighbours (diagonals are walked between them;
        // the ways forbid a diagonal past a closed side cell)
        static int const dc[4] = { 1, -1, 0, 0 }, dr[4] = { 0, 0, 1, -1 };
        for (int k = 0; k < 4; ++k)
        {
            int nc = q % g.w + dc[k], nr = q / g.w + dr[k];
            if (nc < 0 || nr < 0 || nc >= g.w || nr >= g.h)
                continue;
            int m = nr * g.w + nc;
            if (asked[size_t(m)])
                continue;
            BuddyPath::P mc = g.Centre(m);
            BuddyRoam::Point there;
            // one question per cell: the first neighbour to reach it decides
            // (another might have reached it over gentler ground; the ways'
            // refusals mend such a cell later)
            asked[size_t(m)] = 1;
            if (!BuddyMeshSnap(map, { mc.x, mc.y, from.z }, g.step * 0.5f, RISE * g.step / CELL, there))
                continue;                               // no ground near the middle: closed
            if (!BuddyMeshLineClear(map, from, there))
                continue;                               // a wall, a cliff or a gap from here: closed
            g.open[size_t(m)] = 1;
            heights[size_t(m)] = there.z;
            water.push_back(m);
        }
    }
    return true;
}
// }}}

// {{{ the painted map in game (617o8)
// One BuddyPaint map per region of the world: PAINT_REGION yards square with
// PAINT_MARGIN yards round it, a yard a cell (705 by 705, about half a million
// cells, about 13 MB), made when a buddy first walks there by the painted
// map, shared by every buddy there, and kept (at most PAINT_MAPS, the
// least recently used let go first). It starts knowing nothing, and learns
// the way the owner asked ("bots paint surfaces and collectively get better
// at navigating as we gather more data"), from the world's own answers:
//   each tick a buddy walks it, the cell it stands in is painted;
//   a step the navigation mesh refuses paints the spot where the straight
//   leaves the mesh (found by halving the straight four times), so every
//   buddy in the region plans round it from then on.
// A walk's region is the one holding the middle of its start and goal; a
// start or goal outside that region's map (a trip longer than about 190
// yards near a region's border) is given up and said why, as a waypoint
// the mesh refuses is.
static constexpr double PAINT_REGION = 512, PAINT_MARGIN = 96;
static constexpr size_t PAINT_MAPS = 6;
struct RegionPaint { BuddyPaint::Map M; uint64 usedAt = 0, crowdAt = 0; uint32 mapId = 0; int rc = 0, rr = 0; };
static std::unordered_map<uint64, RegionPaint> sPaint;   // by map and region column and row (sWalkLock)

// {{{ the paint kept between runs
// The owner, 2026-10-29: "collectively get better at navigating as we
// gather more data"; decided the same day (the owner: "design all of our
// stuff and we'll curate it as we go"): what the buddies learn outlives a
// restart, and every buddy on the realm shares it. Each region's map is a
// file, <folder>/<map>-<column>-<row>.paint (BuddyPaint::Save's bytes),
// loaded when the region's map is made, saved every PAINT_SAVE_MS, when the
// map is let go, and when the world shuts down. The folder: the setting
// Buddies.PaintDir, else "buddy-paint/realm-<RealmID>" beside the server
// (its working folder, the installed bin/), so a realm branch, which runs
// its source's server with a realm of its own (136d), keeps its own paint.
// A file that is not this region's map is refused and said so (the map
// starts blank), never read wrongly.
static constexpr uint64 PAINT_SAVE_MS = 10 * 60 * 1000;
static std::filesystem::path PaintFile(uint32 mapId, int rc, int rr)
{
    std::string dir = sConfigMgr->GetOption<std::string>("Buddies.PaintDir", "");
    if (dir.empty()) dir = "buddy-paint/realm-" + std::to_string(sConfigMgr->GetOption<uint32>("RealmID", 1));
    return std::filesystem::path(dir) / (std::to_string(mapId) + "-" + std::to_string(rc) + "-" + std::to_string(rr) + ".paint");
}
static void SavePaint(RegionPaint const& rp)
{
    std::filesystem::path file = PaintFile(rp.mapId, rp.rc, rp.rr);
    std::error_code ec;
    std::filesystem::create_directories(file.parent_path(), ec);
    std::vector<uint8_t> bytes = BuddyPaint::Save(rp.M);
    std::ofstream out(file, std::ios::binary | std::ios::trunc);
    out.write(reinterpret_cast<char const*>(bytes.data()), std::streamsize(bytes.size()));
    if (!out)
        LOG_ERROR("module", "mod-buddies: the painted map of map {} region ({}, {}) could not be saved to {} ({}); what was learned since the last save is lost at a restart",
            rp.mapId, rp.rc, rp.rr, file.string(), ec ? ec.message() : "the write failed");
}
static void LoadPaint(RegionPaint& rp)
{
    std::filesystem::path file = PaintFile(rp.mapId, rp.rc, rp.rr);
    std::ifstream in(file, std::ios::binary);
    if (!in)
        return;                                      // nothing learned here yet: a blank map
    std::vector<uint8_t> bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    if (BuddyPaint::Load(rp.M, bytes))
        LOG_INFO("module", "mod-buddies: the painted map of map {} region ({}, {}) loaded from {}: {} cells walked, {} walls learned",
            rp.mapId, rp.rc, rp.rr, file.string(), rp.M.painted, rp.M.wallCells);
    else
        LOG_ERROR("module", "mod-buddies: {} is not the painted map of map {} region ({}, {}) ({} bytes, not this map's size and place); "
            "this region starts blank, and the file will be written over at the next save", file.string(), rp.mapId, rp.rc, rp.rr, bytes.size());
}
static void SaveAllPaint()
{
    std::lock_guard<std::mutex> lock(sWalkLock);
    for (auto const& [key, rp] : sPaint)
        SavePaint(rp);
}
// }}}
static RegionPaint& RegionFor(uint32 mapId, double x, double y, uint64 now, uint64& key)
{
    int rc = int(std::floor(x / PAINT_REGION)), rr = int(std::floor(y / PAINT_REGION));
    key = (uint64(mapId) << 40) | (uint64(uint32(rc + 0x80000) & 0xfffff) << 20) | uint64(uint32(rr + 0x80000) & 0xfffff);
    auto it = sPaint.find(key);
    if (it == sPaint.end())
    {
        if (sPaint.size() >= PAINT_MAPS)
        {
            auto oldest = std::min_element(sPaint.begin(), sPaint.end(),
                [](auto const& a, auto const& b) { return a.second.usedAt < b.second.usedAt; });
            SavePaint(oldest->second);                   // let go: what it learned is kept on disk
            sPaint.erase(oldest);
        }
        RegionPaint rp;
        int cells = int(PAINT_REGION + 2 * PAINT_MARGIN) + 1;
        rp.M = BuddyPaint::Make(cells, cells, 1.0, rc * PAINT_REGION - PAINT_MARGIN, rr * PAINT_REGION - PAINT_MARGIN);
        rp.mapId = mapId; rp.rc = rc; rp.rr = rr;
        LoadPaint(rp);
        it = sPaint.emplace(key, std::move(rp)).first;
    }
    it->second.usedAt = now;
    return it->second;
}

// One tick of a buddy's walk by the painted map (sWalkLock held). As
// BuddyPathWalk's other ways: Walking, Arrived, or GaveUp (no way at all,
// even squeezing out; or not there in BUDDY_PATH_GIVE_UP_MS).
static BuddyPathStep PaintWalk(Player* bot, BuddyRoam::Point const& goal, uint64 now, uint32 guid, Map* map, BuddyRoam::Point const& at)
{
    auto it = sWalks.find(guid);
    if (it == sWalks.end() || it->second.way != Way::Paint || it->second.mapId != map->GetId() ||
        std::hypot(it->second.goal.x - goal.x, it->second.goal.y - goal.y) > 1.0f)
    {
        Walk w;
        w.way = Way::Paint, w.goal = goal, w.mapId = map->GetId(), w.started = now;
        w.regionX = (at.x + goal.x) / 2.0; w.regionY = (at.y + goal.y) / 2.0;
        RegionPaint& rp = RegionFor(w.mapId, w.regionX, w.regionY, now, w.paintKey);
        if (BuddyPaint::CellOf(rp.M, at.x, at.y) < 0 || BuddyPaint::CellOf(rp.M, goal.x, goal.y) < 0)
        {
            BuddyTrace(bot, "path: paint: the goal ({:.1f}, {:.1f}) and the buddy are not on one region's map ({:.0f} yards apart); waypoint given up",
                goal.x, goal.y, std::hypot(goal.x - at.x, goal.y - at.y));
            Count(w, false, now);
            sWalks.erase(guid);
            return BuddyPathStep::GaveUp;
        }
        uint32 h = guid * 2654435761u;
        w.lane = double(h % 2001u) / 1000.0 - 1.0;               // its own side of every route, -1 to 1
        w.jitter = double((h >> 11) % 1500u) / 1000.0;           // its own replanning offset, 0 to 1.5 seconds
        BuddyTrace(bot, "path: paint to ({:.1f}, {:.1f}, {:.1f}), {:.0f} yards; the region's map: {} cells painted, {} walls learned, {} plans",
            goal.x, goal.y, goal.z, std::hypot(goal.x - at.x, goal.y - at.y), rp.M.painted, rp.M.wallCells, rp.M.stats.plans);
        it = sWalks.insert_or_assign(guid, std::move(w)).first;
    }
    Walk& w = it->second;
    if (std::hypot(goal.x - at.x, goal.y - at.y) < BUDDY_PATH_ARRIVED)
    {
        BuddyTrace(bot, "path: paint: arrived in {:.1f} s, {} points ordered, {} refused, {} plans",
            float(now - w.started) / 1000.0f, w.orders, w.refused, w.plans);
        Count(w, true, now);
        sWalks.erase(it);
        return BuddyPathStep::Arrived;
    }
    if (now - w.started > BUDDY_PATH_GIVE_UP_MS)
    {
        BuddyTrace(bot, "path: paint: not there in {} s ({:.0f} yards left); waypoint given up", BUDDY_PATH_GIVE_UP_MS / 1000, std::hypot(goal.x - at.x, goal.y - at.y));
        Count(w, false, now);
        sWalks.erase(it);
        return BuddyPathStep::GaveUp;
    }
    if (!bot->movespline->Finalized() && now - w.lastOrder < ORDER_MS)
        return BuddyPathStep::Walking;

    uint64 key;
    RegionPaint& rp = RegionFor(w.mapId, w.regionX, w.regionY, now, key);   // made again if it was let go
    BuddyPaint::Map& M = rp.M;
    double t = double(now) / 1000.0;
    w.lastX = at.x; w.lastY = at.y;
    BuddyPaint::Walked(M, at.x, at.y);
    // the crowd, once a second a region: every buddy walking there by the painted map
    if (now >= rp.crowdAt)
    {
        std::vector<BuddyPaint::CrowdBot> crowd;
        for (auto const& [g2, w2] : sWalks)
            if (w2.way == Way::Paint && w2.paintKey == key)
                crowd.push_back({ w2.lastX, w2.lastY, w2.hasPath ? &w2.ppath : nullptr });
        BuddyPaint::Crowd(M, crowd);
        rp.crowdAt = now + 1000;
    }
    if (BuddyPaint::NeedsPlan(M, w.hasPath ? &w.ppath : nullptr, goal.x, goal.y, t, w.jitter))
    {
        w.hasPath = BuddyPaint::Plan(M, at.x, at.y, goal.x, goal.y, w.ppath);
        ++w.plans;
        if (w.hasPath) { w.ppath.at = t; BuddyPaint::CrowdRoute(M, w.ppath, at.x, at.y); }
    }
    if (!w.hasPath)
    {
        BuddyTrace(bot, "path: paint: no way on the region's map, even squeezing out; waypoint given up");
        Count(w, false, now);
        sWalks.erase(it);
        return BuddyPathStep::GaveUp;
    }
    BuddyPaint::Pt to = BuddyPaint::Follow(M, w.ppath, at.x, at.y, w.lane);
    w.lastOrder = now;

    // the world's word: onto the mesh, and a straight walk there that stays
    // on it. Refused: where the straight leaves the mesh is painted for every
    // buddy in the region (the last clear and first refused fractions of the
    // straight, halved four times: within a sixteenth of it), the buddy stops
    // and plans again. Refused paints nothing beside the buddy's own cell; a
    // refusal that taught nothing so paints its spot anyway (not the
    // buddy's own cell), so no buddy pushes at the same thing for ever.
    BuddyRoam::Point onMesh;
    if (!BuddyMeshSnap(map, { float(to.x), float(to.y), at.z }, 1.5f, 4.0f, onMesh) || !BuddyMeshLineClear(map, at, onMesh))
    {
        double lo = 0, hi = 1;
        for (int k = 0; k < 4; ++k)
        {
            double mid = (lo + hi) / 2;
            BuddyRoam::Point pm { float(at.x + (to.x - at.x) * mid), float(at.y + (to.y - at.y) * mid), at.z }, sm;
            if (BuddyMeshSnap(map, pm, 1.0f, 4.0f, sm) && BuddyMeshLineClear(map, at, sm)) lo = mid; else hi = mid;
        }
        double rx = at.x + (to.x - at.x) * hi, ry = at.y + (to.y - at.y) * hi;
        if (!BuddyPaint::Refused(M, rx, ry, nullptr, at.x, at.y))
            BuddyPaint::PaintWallIn(M, rx, ry, rx, ry, BuddyPaint::CellOf(M, at.x, at.y), false);
        ++w.refused; w.hasPath = false;
        if (!bot->movespline->Finalized())
            bot->StopMoving();
        BuddyTrace(bot, "path: paint: step to ({:.1f}, {:.1f}) refused by the mesh at ({:.1f}, {:.1f}); painted", to.x, to.y, rx, ry);
        return BuddyPathStep::Walking;
    }
    ++w.orders;
    float facing = std::atan2(onMesh.y - at.y, onMesh.x - at.x);
    bot->GetMotionMaster()->MovePoint(0, onMesh.x, onMesh.y, onMesh.z, FORCED_MOVEMENT_NONE, 0.0f, facing,
        /*generatePath*/ false, /*forceDestination*/ true);
    return BuddyPathStep::Walking;
}
// }}}

// {{{ BuddyPathWalk
BuddyPathStep BuddyPathWalk(Player* bot, Way way, BuddyRoam::Point const& goal)
{
    uint64 now = uint64(GameTime::GetGameTimeMS().count());
    uint32 guid = bot->GetGUID().GetCounter();
    Map* map = bot->GetMap();
    BuddyRoam::Point at { bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ() };

    std::lock_guard<std::mutex> lock(sWalkLock);
    if (way == Way::Paint)
        return PaintWalk(bot, goal, now, guid, map, at);       // its own map, kept per region (617o8)
    auto it = sWalks.find(guid);
    // a new walk: no walk yet, another goal (more than a yard off), another way, another map
    if (it == sWalks.end() || it->second.way != way || it->second.mapId != map->GetId() ||
        std::hypot(it->second.goal.x - goal.x, it->second.goal.y - goal.y) > 1.0f)
    {
        Walk w;
        w.way = way, w.goal = goal, w.mapId = map->GetId(), w.started = now;
        w.walker.Reset(way);
        w.walker.seed = guid * 2654435761u + uint32(now);
        if (!FillGrid(map, at, goal, w.grid, w.heights))
        {
            BuddyTrace(bot, "path: {}: no mesh under the buddy at ({:.1f}, {:.1f}, {:.1f}); waypoint given up",
                BuddyPath::WayName(way), at.x, at.y, at.z);
            Count(w, false, now);
            sWalks.erase(guid);
            return BuddyPathStep::GaveUp;
        }
        size_t open = size_t(std::count(w.grid.open.begin(), w.grid.open.end(), uint8_t(1)));
        BuddyTrace(bot, "path: {} to ({:.1f}, {:.1f}, {:.1f}), {:.0f} yards; grid {} by {} cells of {:.1f} yards, {} open",
            BuddyPath::WayName(way), goal.x, goal.y, goal.z, std::hypot(goal.x - at.x, goal.y - at.y),
            w.grid.w, w.grid.h, w.grid.step, open);
        it = sWalks.insert_or_assign(guid, std::move(w)).first;
    }
    Walk& w = it->second;

    if (std::hypot(goal.x - at.x, goal.y - at.y) < BUDDY_PATH_ARRIVED)
    {
        BuddyTrace(bot, "path: {}: arrived in {:.1f} s, {} points ordered, {} refused",
            BuddyPath::WayName(way), float(now - w.started) / 1000.0f, w.orders, w.refused);
        Count(w, true, now);
        sWalks.erase(it);
        return BuddyPathStep::Arrived;
    }
    if (now - w.started > BUDDY_PATH_GIVE_UP_MS)
    {
        BuddyTrace(bot, "path: {}: not there in {} s ({:.0f} yards left); waypoint given up",
            BuddyPath::WayName(way), BUDDY_PATH_GIVE_UP_MS / 1000, std::hypot(goal.x - at.x, goal.y - at.y));
        Count(w, false, now);
        sWalks.erase(it);
        return BuddyPathStep::GaveUp;
    }
    // still walking to the last point, and not long since: wait
    if (!bot->movespline->Finalized() && now - w.lastOrder < ORDER_MS)
        return BuddyPathStep::Walking;

    float speed = bot->GetSpeed(bot->IsWalking() ? MOVE_WALK : MOVE_RUN);
    BuddyPath::P to = w.walker.Next(w.grid, { at.x, at.y }, { goal.x, goal.y }, float(now - w.started) / 1000.0f, speed);
    w.lastOrder = now;

    // the world's word on the step: onto the mesh, and a straight walk there
    // that stays on it. Refused: not walked (the server would walk it
    // straight through a wall), the way told, the buddy stopped where it is.
    int q = w.grid.Cell(to);
    float guess = q >= 0 ? w.heights[size_t(q)] : at.z;
    BuddyRoam::Point onMesh;
    if (!BuddyMeshSnap(map, { to.x, to.y, guess }, 1.5f, 4.0f, onMesh) || !BuddyMeshLineClear(map, at, onMesh))
    {
        ++w.refused;
        w.walker.Fell(w.grid, { at.x, at.y }, to);
        if (!bot->movespline->Finalized())
            bot->StopMoving();
        BuddyTrace(bot, "path: {}: step to ({:.1f}, {:.1f}) refused by the mesh", BuddyPath::WayName(way), to.x, to.y);
        return BuddyPathStep::Walking;
    }
    ++w.orders;
    float facing = std::atan2(onMesh.y - at.y, onMesh.x - at.x);
    bot->GetMotionMaster()->MovePoint(0, onMesh.x, onMesh.y, onMesh.z, FORCED_MOVEMENT_NONE, 0.0f, facing,
        /*generatePath*/ false, /*forceDestination*/ true);
    return BuddyPathStep::Walking;
}
// }}}

// {{{ the command
// ".buddy path <way>": the way for the speaker's buddies; "mesh" turns the
// switch off. ".buddy path" alone: the way picked, and each way's tally
// since the server started (every buddy's, not only the speaker's).
class buddies_path_command : public CommandScript
{
public:
    buddies_path_command() : CommandScript("buddies_path_command") { }

    ChatCommandTable GetCommands() const override
    {
        // multi-word names join the ".buddy" table the beds file starts
        static ChatCommandTable commandTable =
        {
            { "buddy path", HandlePath, SEC_PLAYER, Console::No },
        };
        return commandTable;
    }

    static bool HandlePath(ChatHandler* handler, Optional<std::string> word)
    {
        Player* owner = handler->GetPlayer();
        uint32 ownerGuid = owner->GetGUID().GetCounter();
        if (word)
        {
            std::string w = *word;
            std::transform(w.begin(), w.end(), w.begin(), [](unsigned char c) { return char(std::tolower(c)); });
            Way way;
            if (w == "mesh")
            {
                std::lock_guard<std::mutex> lock(sWayLock);
                sWay.erase(ownerGuid);
                handler->PSendSysMessage("Your buddies now walk the server's own way (the navigation mesh's path search), as before.");
                return true;
            }
            if (!BuddyPath::WayFromName(w, way))
            {
                handler->PSendSysMessage("'{}' is not a way: use orbit, flow, astar, potential, learn, paint, or mesh (the server's own, as before).", *word);
                return true;
            }
            {
                std::lock_guard<std::mutex> lock(sWayLock);
                sWay[ownerGuid] = way;
            }
            static char const* const about[] = {
                "straight at the point; stuck, they back out (twice as far each time) and walk round what blocks",
                "downhill on the walking distance to the point, spread over the ground once",
                "a whole route planned by A*, pulled tight",
                "pulled by the point, pushed by walls near, kicked out of a dip",
                "A* over only what they have bumped into; each bump teaches",
                "the painted map: one map a region, shared, painted by every step and every refusal; space kept from walls (less near the goal), lanes, the crowd, arcs",
            };
            handler->PSendSysMessage("Your buddies now find their way by {}: {}. Each new waypoint starts a fresh walk; \".buddy path\" shows how each way has done.",
                BuddyPath::WayName(way), about[uint8(way)]);
            return true;
        }
        Way way;
        bool on = BuddyPathWayFor(ownerGuid, way);
        handler->PSendSysMessage("Your buddies' way: {}.", on ? BuddyPath::WayName(way) : "mesh (the server's own)");
        std::lock_guard<std::mutex> lock(sWalkLock);
        handler->PSendSysMessage("way       walks arrived gave-up  mean-s refused stuck orbits kicks plans  (every buddy, since the server started; {} walking now)", sWalks.size());
        for (Way k : { Way::Orbit, Way::Flow, Way::AStar, Way::Potential, Way::Learn, Way::Paint })
        {
            Tally const& t = sTally[uint8(k)];
            float mean = t.walks ? float(t.ms) / 1000.0f / float(t.walks) : 0.0f;
            handler->PSendSysMessage("{:<9} {:>5} {:>7} {:>7} {:>7.1f} {:>7} {:>5} {:>6} {:>5} {:>5}",
                BuddyPath::WayName(k), t.walks, t.arrived, t.gaveUp, mean, t.refused, t.stuck, t.orbits, t.kicks, t.plans);
        }
        return true;
    }
};

// the painted maps saved every PAINT_SAVE_MS and when the world shuts down
class buddies_path_world : public WorldScript
{
public:
    buddies_path_world() : WorldScript("buddies_path_world", { WORLDHOOK_ON_UPDATE, WORLDHOOK_ON_SHUTDOWN }) { }
    void OnUpdate(uint32 diff) override
    {
        _since += diff;
        if (_since < PAINT_SAVE_MS) return;
        _since = 0;
        SaveAllPaint();
    }
    void OnShutdown() override { SaveAllPaint(); }
private:
    uint64 _since = 0;
};

void AddSC_buddies_path()
{
    new buddies_path_command();
    new buddies_path_world();
}
// }}}
