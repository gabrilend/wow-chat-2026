/*
 * buddy-town-baker.cpp - bakes every town's exploring grid ahead of time
 * (issue 617o3), so a buddy's first visit to a town walks by its distance
 * maps instead of waiting a minute while the server measures it.
 *
 * For a general audience: the server measures an area by asking, cell by
 * cell, where the ground is and whether the navigation mesh (its map of
 * every spot a character can stand) is there. For towns the same answers
 * come from the files on disk, without a running server: the mesh files
 * (mmaps/), the terrain files (maps/, heights and area numbers) and the
 * client's area table (dbc/AreaTable.dbc, which areas are towns). This
 * program lays out each town piece's grid exactly as the server does and
 * judges floor and steps by the same rules (roam/buddy_grid_rules.h,
 * roam/buddy_mesh_core.h, shared with the server), keeps the largest
 * stretch of joined floor (the town's streets; the server floods out from
 * its owner the same way), and writes one file per piece
 * (roam/buddy_town_file.h), with the mesh files it read and their sizes and
 * times, so the server can refuse a bake that the mesh has moved past.
 *
 * Lives outside modules/mod-buddies on purpose: the server build compiles
 * every source file in the module folder, and this one has its own main.
 *
 * Built and run by scripts/bake-buddy-towns, which gives it the area
 * pieces from the world database.
 *
 * Usage: buddy-town-baker <data dir> <pieces.tsv>
 *   pieces.tsv: map, area, piece, min x, max x, min y, max y per line
 *   (tab-separated), from the buddy_area_centre table.
 *   Writes <data dir>/buddy-towns/<map>-<area>-<piece>.btown
 *
 * One difference from the live measuring, accepted: the server reads ground
 * height and area numbers with buildings included (a building's own floor
 * and area), the baker from the terrain only. Town streets are terrain;
 * an inn's upper floor is reached in game by the live walking regardless.
 */

#include "buddy_explore_core.h"
#include "buddy_grid_rules.h"
#include "buddy_mesh_core.h"
#include "buddy_town_file.h"
#include "buddy_town_rules.h"
#include "DetourAlloc.h"
#include <sys/stat.h>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <deque>
#include <fstream>
#include <map>
#include <memory>
#include <set>
#include <sstream>
#include <string>
#include <vector>

static std::string sData;   // the data directory

// {{{ fail
[[noreturn]] static void fail(std::string const& what)
{
    std::fprintf(stderr, "buddy-town-baker: ERROR: %s\n", what.c_str());
    std::exit(1);
}
// }}}

// {{{ the town areas (dbc/AreaTable.dbc)
// Which areas are towns is the server's own rule (roam/buddy_town_rules.h:
// the client's town, capital and capital-subzone flags, starting valleys
// excepted). The table's record: id (field 0), flags (field 4).
static std::set<uint32_t> TownAreas()
{
    std::string path = sData + "/dbc/AreaTable.dbc";
    std::ifstream f(path, std::ios::binary);
    if (!f)
        fail("can't read " + path);
    char magic[4];
    uint32_t records, fields, recordSize, stringSize;
    f.read(magic, 4);
    f.read(reinterpret_cast<char*>(&records), 4);
    f.read(reinterpret_cast<char*>(&fields), 4);
    f.read(reinterpret_cast<char*>(&recordSize), 4);
    f.read(reinterpret_cast<char*>(&stringSize), 4);
    if (!f || std::memcmp(magic, "WDBC", 4) != 0 || fields < 5)
        fail(path + " is not a client table file");
    std::vector<uint32_t> rec(recordSize / 4);
    std::set<uint32_t> towns;
    for (uint32_t r = 0; r < records; ++r)
    {
        f.read(reinterpret_cast<char*>(rec.data()), recordSize);
        if (BuddyTownRules::IsTown(rec[0], rec[4]))
            towns.insert(rec[0]);
    }
    return towns;
}
// }}}

// {{{ the terrain (maps/*.map)
// One terrain tile: its heights (a 129x129 grid of corner heights and a
// 128x128 grid of cell middles, as floats or packed into 16 or 8 bits) and
// area numbers (one, or a 16x16 grid). The sums are the server's own
// (GridTerrainData::getHeightFrom*, getArea); the same port as
// scripts/generate-basic-titan-jeweler-spots.
struct Terrain
{
    bool   ok = false;
    std::vector<uint8_t> d;
    uint32_t heightOff = 0, areaOff = 0;
};
static constexpr double GRID = 533.33333;
static constexpr int    RES  = 128;

static Terrain const& TerrainAt(uint32_t map, int gx, int gy)
{
    static std::map<std::tuple<uint32_t, int, int>, Terrain> tiles;
    auto key = std::make_tuple(map, gx, gy);
    auto it = tiles.find(key);
    if (it != tiles.end())
        return it->second;
    Terrain& t = tiles[key];
    char name[64];
    std::snprintf(name, sizeof(name), "/maps/%03u%02d%02d.map", map, gx, gy);
    std::ifstream f(sData + name, std::ios::binary);
    if (!f)
        return t;                                      // no terrain here (sea, or outside the map)
    t.d.assign(std::istreambuf_iterator<char>(f), std::istreambuf_iterator<char>());
    if (t.d.size() < 44)
        return t;
    std::memcpy(&t.areaOff, &t.d[12], 4);
    std::memcpy(&t.heightOff, &t.d[20], 4);
    t.ok = true;
    return t;
}

static int TileOf(double v) { return int(std::floor(32.0 - v / GRID)); }

static float u16At(std::vector<uint8_t> const& d, size_t o) { uint16_t v; std::memcpy(&v, &d[o], 2); return float(v); }
static float f32At(std::vector<uint8_t> const& d, size_t o) { float v; std::memcpy(&v, &d[o], 4); return v; }

// The terrain height at (x, y), or false where there is none.
static bool Height(uint32_t map, double x, double y, float& z)
{
    Terrain const& t = TerrainAt(map, TileOf(x), TileOf(y));
    if (!t.ok || !t.heightOff)
        return false;
    std::vector<uint8_t> const& d = t.d;
    size_t off = t.heightOff;
    uint32_t flags; std::memcpy(&flags, &d[off + 4], 4);
    float base = f32At(d, off + 8), top = f32At(d, off + 12);
    if (flags & 1) { z = base; return true; }          // flat
    bool i16 = flags & 2, i8 = flags & 4;
    size_t size = i16 ? 2 : (i8 ? 1 : 4);
    size_t v9 = off + 16, v8 = v9 + 129 * 129 * size;
    auto at = [&](size_t start, size_t i) -> float {
        size_t o = start + i * size;
        return i16 ? u16At(d, o) : (i8 ? float(d[o]) : f32At(d, o));
    };
    double fx = RES * (32.0 - x / GRID), fy = RES * (32.0 - y / GRID);
    int xi = int(std::floor(fx)), yi = int(std::floor(fy));
    double rx = fx - xi, ry = fy - yi;
    xi %= RES, yi %= RES;
    if (xi < 0) xi += RES;
    if (yi < 0) yi += RES;
    float h1 = at(v9, xi * 129 + yi), h2 = at(v9, (xi + 1) * 129 + yi);
    float h3 = at(v9, xi * 129 + yi + 1), h4 = at(v9, (xi + 1) * 129 + yi + 1);
    float h5 = 2 * at(v8, xi * 128 + yi);
    double a, b, c;
    if (rx + ry < 1)
    {
        if (rx > ry) a = h2 - h1, b = h5 - h1 - h2, c = h1;
        else         a = h5 - h1 - h3, b = h3 - h1, c = h1;
    }
    else
    {
        if (rx > ry) a = h2 + h4 - h5, b = h4 - h2, c = h5 - h4;
        else         a = h4 - h3, b = h3 + h4 - h5, c = h5 - h4;
    }
    double h = a * rx + b * ry + c;
    if (i16) h = h * (top - base) / 65535.0 + base;
    else if (i8) h = h * (top - base) / 255.0 + base;
    z = float(h);
    return true;
}

// The terrain's area number at (x, y), 0 where none.
static uint32_t Area(uint32_t map, double x, double y)
{
    Terrain const& t = TerrainAt(map, TileOf(x), TileOf(y));
    if (!t.ok || !t.areaOff)
        return 0;
    size_t off = t.areaOff;
    uint16_t flags, gridArea;
    std::memcpy(&flags, &t.d[off + 4], 2);
    std::memcpy(&gridArea, &t.d[off + 6], 2);
    if (flags & 1)
        return gridArea;                               // one area for the whole tile
    int lx = int(16 * (32.0 - x / GRID)) & 15, ly = int(16 * (32.0 - y / GRID)) & 15;
    uint16_t a;
    std::memcpy(&a, &t.d[off + 8 + 2 * size_t(lx * 16 + ly)], 2);
    return a;
}
// }}}

// {{{ the mesh (mmaps/)
// One mesh per map, its tiles added as a town needs them, as the server's
// own loader does (MMapMgr::LoadNavMesh, LoadTile): the map file holds the
// mesh's parameters, each tile file a 56-byte header and the tile's data.
struct Mesh
{
    dtNavMesh*      nav = nullptr;
    dtNavMeshQuery* query = nullptr;
    std::set<std::pair<int, int>> tried;
};
static constexpr uint32_t MMAP_MAGIC = 0x4d4d4150;     // 'MMAP'
static constexpr uint32_t MMAP_VERSION = 19;           // the server's MapDefines.h; a mismatch stops the bake

static Mesh& MeshOf(uint32_t map)
{
    static std::map<uint32_t, Mesh> meshes;
    Mesh& m = meshes[map];
    if (m.nav)
        return m;
    char name[64];
    std::snprintf(name, sizeof(name), "/mmaps/%03u.mmap", map);
    FILE* f = std::fopen((sData + name).c_str(), "rb");
    if (!f)
        fail("no mesh for map " + std::to_string(map) + " (" + sData + name + ")");
    dtNavMeshParams params;
    bool ok = std::fread(&params, sizeof(params), 1, f) == 1;
    std::fclose(f);
    m.nav = dtAllocNavMesh();
    if (!ok || dtStatusFailed(m.nav->init(&params)))
        fail("can't start the mesh of map " + std::to_string(map));
    m.query = dtAllocNavMeshQuery();
    if (dtStatusFailed(m.query->init(m.nav, 65535)))
        fail("can't start a mesh query for map " + std::to_string(map));
    return m;
}

// Add the tile (gx, gy) of a map's mesh; its fingerprint goes into `tiles`
// when it exists. False when there is no such tile file (no mesh there).
static bool AddTile(uint32_t map, int gx, int gy, std::vector<BuddyTownFile::Tile>& tiles)
{
    Mesh& m = MeshOf(map);
    char name[64];
    std::snprintf(name, sizeof(name), "/mmaps/%03u%02d%02d.mmtile", map, gx, gy);
    std::string path = sData + name;
    struct stat st;
    if (::stat(path.c_str(), &st) != 0)
        return false;
    tiles.push_back({ uint32_t(gx), uint32_t(gy), uint64_t(st.st_size), int64_t(st.st_mtime) });
    if (!m.tried.insert({ gx, gy }).second)
        return true;                                   // already in the mesh
    FILE* f = std::fopen(path.c_str(), "rb");
    if (!f)
        fail("can't read " + path);
    uint32_t head[4];
    unsigned char rest[40];
    if (std::fread(head, 4, 4, f) != 4 || std::fread(rest, 1, 40, f) != 40 || head[0] != MMAP_MAGIC)
        fail(path + ": not a mesh tile");
    if (head[2] != MMAP_VERSION)
        fail(path + ": mesh generator version " + std::to_string(head[2]) + ", the server expects " + std::to_string(MMAP_VERSION));
    unsigned char* data = static_cast<unsigned char*>(dtAlloc(head[3], DT_ALLOC_PERM));
    if (std::fread(data, head[3], 1, f) != 1)
        fail(path + ": cut short");
    std::fclose(f);
    dtTileRef ref = 0;
    if (dtStatusFailed(m.nav->addTile(data, int(head[3]), DT_TILE_FREE_DATA, 0, &ref)))
        fail(path + ": the mesh refused the tile");
    return true;
}
// }}}

// {{{ Bake
// One town piece: floor, joins, the largest joined stretch, the file.
struct Counts { uint32_t floor = 0, kept = 0, joins = 0; };

static Counts Bake(uint32_t map, uint32_t area, uint32_t piece, float minX, float maxX, float minY, float maxY)
{
    BuddyExplore::Grid g;
    BuddyGridRules::Layout(minX, maxX, minY, maxY, g);
    int32_t n = g.Count();
    BuddyTownFile::Town t;
    t.map = map, t.area = area, t.piece = piece;
    t.x0 = g.x0, t.y0 = g.y0, t.cell = g.cell, t.nx = g.nx, t.ny = g.ny;
    t.inside.assign(n, 0), t.open.assign(n, 0), t.joins.assign(n, 0), t.height.assign(n, 0.0f);

    // the mesh tiles under the grid
    for (int gx = TileOf(g.x0 + g.nx * g.cell); gx <= TileOf(g.x0); ++gx)
        for (int gy = TileOf(g.y0 + g.ny * g.cell); gy <= TileOf(g.y0); ++gy)
            AddTile(map, gx, gy, t.tiles);
    Mesh& m = MeshOf(map);
    dtQueryFilter const filter = BuddyMeshCore::BuddyFilter();

    // floor: the town's own area, terrain there, and the mesh within reach
    std::vector<uint8_t> floor(n, 0);
    Counts c;
    for (int32_t i = 0; i < n; ++i)
    {
        double x, y;
        g.CellXY(i, x, y);
        float z;
        if (Area(map, x, y) != area || !Height(map, x, y, z))
            continue;
        t.inside[i] = 1;
        BuddyRoam::Point onMesh;
        if (!BuddyMeshCore::Snap(m.query, filter, { float(x), float(y), z }, BuddyGridRules::MESH_SNAP_YARDS,
                                 BuddyGridRules::MESH_RISE_YARDS, onMesh))
            continue;
        floor[i] = 1;
        t.height[i] = onMesh.z;
        ++c.floor;
    }

    // joins: east and north of each floor cell (west and south are the
    // same pairs seen from the other cell), gentle and clear on the mesh
    for (int32_t i = 0; i < n; ++i)
    {
        if (!floor[i])
            continue;
        int32_t ix = i % g.nx, iy = i / g.nx;
        double xi, yi;
        g.CellXY(i, xi, yi);
        int32_t const nb[2]       = { ix + 1 < g.nx ? i + 1 : -1, iy + 1 < g.ny ? i + g.nx : -1 };
        uint8_t const bit[2]      = { BuddyGridRules::JOIN_EAST, BuddyGridRules::JOIN_NORTH };
        uint8_t const backBit[2]  = { BuddyGridRules::JOIN_WEST, BuddyGridRules::JOIN_SOUTH };
        for (int k = 0; k < 2; ++k)
        {
            int32_t j = nb[k];
            if (j < 0 || !floor[j] || !BuddyGridRules::Gentle(t.height[i], t.height[j], g.cell))
                continue;
            double xj, yj;
            g.CellXY(j, xj, yj);
            if (!BuddyMeshCore::LineClear(m.query, filter, { float(xi), float(yi), t.height[i] },
                                          { float(xj), float(yj), t.height[j] }, BuddyMeshCore::LINE_ON_MESH, BuddyMeshCore::LINE_RISE))
                continue;
            t.joins[i] |= bit[k], t.joins[j] |= backBit[k];
            ++c.joins;
        }
    }

    // the largest stretch of joined floor is the town; islands (a roof, a
    // ledge no step reaches) are left out, as the live flood leaves them
    int32_t const offset[4] = { 1, -1, g.nx, -g.nx };
    std::vector<int32_t> part(n, -1);
    int32_t best = -1, bestSize = 0;
    for (int32_t s = 0, label = 0; s < n; ++s)
    {
        if (!floor[s] || part[s] >= 0)
            continue;
        int32_t size = 0;
        std::deque<int32_t> q { s };
        part[s] = label;
        while (!q.empty())
        {
            int32_t i = q.front();
            q.pop_front();
            ++size;
            for (int d = 0; d < 4; ++d)
                if ((t.joins[i] & (1u << d)) && part[i + offset[d]] < 0)
                {
                    part[i + offset[d]] = label;
                    q.push_back(i + offset[d]);
                }
        }
        if (size > bestSize)
            best = label, bestSize = size;
        ++label;
    }
    for (int32_t i = 0; i < n; ++i)
    {
        if (best >= 0 && part[i] == best)
        {
            t.open[i] = 1;
            ++c.kept;
        }
        else
            t.joins[i] = 0;
    }

    // nothing walkable found (no mesh under it): no file, so the server
    // measures it live rather than reading an empty town; an old file goes
    std::string out = BuddyTownFile::Name(sData, map, area, piece);
    if (!c.kept)
    {
        std::remove(out.c_str());
        return c;
    }
    if (!BuddyTownFile::Write(out, t))
        fail("can't write " + out);
    return c;
}
// }}}

// {{{ main
int main(int argc, char** argv)
{
    if (argc != 3)
    {
        std::fprintf(stderr, "Usage: buddy-town-baker <data dir> <pieces.tsv>\n");
        return 1;
    }
    sData = argv[1];
    std::set<uint32_t> towns = TownAreas();
    std::ifstream in(argv[2]);
    if (!in)
        fail(std::string("can't read ") + argv[2]);
    std::string line;
    uint32_t baked = 0, cells = 0;
    while (std::getline(in, line))
    {
        std::istringstream row(line);
        uint32_t map, area, piece;
        float minX, maxX, minY, maxY;
        if (!(row >> map >> area >> piece >> minX >> maxX >> minY >> maxY))
            fail("unreadable piece row: " + line);
        if (!towns.count(area))
            continue;
        Counts c = Bake(map, area, piece, minX, maxX, minY, maxY);
        std::printf("  map %3u area %5u piece %u: %u floor cells, %u kept, %u joins\n", map, area, piece, c.floor, c.kept, c.joins);
        if (!c.kept)
            std::printf("    (nothing kept: no mesh found under this town piece; no file written, the server measures it live)\n");
        baked += c.kept ? 1 : 0;
        cells += c.kept;
    }
    std::printf("baked %u town pieces, %u walkable cells, into %s/buddy-towns/\n", baked, cells, sData.c_str());
    return 0;
}
// }}}
