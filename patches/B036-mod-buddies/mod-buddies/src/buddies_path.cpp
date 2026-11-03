
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

static constexpr float  CELL       = 3.0f;
static constexpr float  MARGIN     = 24.0f;
static constexpr int    MOST_CELLS = 80;
static constexpr float  RISE       = 2.0f;
static constexpr uint64 ORDER_MS   = 500;

static std::mutex sWayLock;
static std::unordered_map<uint32, Way> sWay;

bool BuddyPathWayFor(uint32 ownerGuid, Way& way)
{
    std::lock_guard<std::mutex> lock(sWayLock);
    auto it = sWay.find(ownerGuid);
    if (it == sWay.end())
        return false;
    way = it->second;
    return true;
}

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
    uint64           paintKey = 0;
    BuddyPaint::Path ppath;
    bool             hasPath = false;
    double           lane = 0, jitter = 0, lastX = 0, lastY = 0, regionX = 0, regionY = 0;
};
struct Tally { uint32 walks = 0, arrived = 0, gaveUp = 0, refused = 0, stuck = 0, orbits = 0, kicks = 0, plans = 0; uint64 ms = 0; };
static std::mutex sWalkLock;
static std::unordered_map<uint32, Walk> sWalks;
static Tally sTally[6];

void BuddyPathForget(uint32 buddyGuid)
{
    std::lock_guard<std::mutex> lock(sWalkLock);
    sWalks.erase(buddyGuid);
}

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
            asked[size_t(m)] = 1;
            if (!BuddyMeshSnap(map, { mc.x, mc.y, from.z }, g.step * 0.5f, RISE * g.step / CELL, there))
                continue;
            if (!BuddyMeshLineClear(map, from, there))
                continue;
            g.open[size_t(m)] = 1;
            heights[size_t(m)] = there.z;
            water.push_back(m);
        }
    }
    return true;
}

static constexpr double PAINT_REGION = 512, PAINT_MARGIN = 96;
static constexpr size_t PAINT_MAPS = 6;
struct RegionPaint { BuddyPaint::Map M; uint64 usedAt = 0, crowdAt = 0; uint32 mapId = 0; int rc = 0, rr = 0; };
static std::unordered_map<uint64, RegionPaint> sPaint;

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
        return;
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
            SavePaint(oldest->second);
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
        w.lane = double(h % 2001u) / 1000.0 - 1.0;
        w.jitter = double((h >> 11) % 1500u) / 1000.0;
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
    RegionPaint& rp = RegionFor(w.mapId, w.regionX, w.regionY, now, key);
    BuddyPaint::Map& M = rp.M;
    double t = double(now) / 1000.0;
    w.lastX = at.x; w.lastY = at.y;
    BuddyPaint::Walked(M, at.x, at.y);
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
         false,  true);
    return BuddyPathStep::Walking;
}

BuddyPathStep BuddyPathWalk(Player* bot, Way way, BuddyRoam::Point const& goal)
{
    uint64 now = uint64(GameTime::GetGameTimeMS().count());
    uint32 guid = bot->GetGUID().GetCounter();
    Map* map = bot->GetMap();
    BuddyRoam::Point at { bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ() };

    std::lock_guard<std::mutex> lock(sWalkLock);
    if (way == Way::Paint)
        return PaintWalk(bot, goal, now, guid, map, at);
    auto it = sWalks.find(guid);
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
    if (!bot->movespline->Finalized() && now - w.lastOrder < ORDER_MS)
        return BuddyPathStep::Walking;

    float speed = bot->GetSpeed(bot->IsWalking() ? MOVE_WALK : MOVE_RUN);
    BuddyPath::P to = w.walker.Next(w.grid, { at.x, at.y }, { goal.x, goal.y }, float(now - w.started) / 1000.0f, speed);
    w.lastOrder = now;

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
         false,  true);
    return BuddyPathStep::Walking;
}

class buddies_path_command : public CommandScript
{
public:
    buddies_path_command() : CommandScript("buddies_path_command") { }

    ChatCommandTable GetCommands() const override
    {
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
