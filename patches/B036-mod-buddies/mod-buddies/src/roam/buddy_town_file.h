/*
 * buddy_town_file.h - a baked town's exploring grid on disk (issue 617o3),
 * written by the town baker (tools/buddy-town-baker/ at the project root) and read by the
 * server (buddies_explore.cpp) in place of measuring the town live.
 *
 * For a general audience: one file per piece of a town area,
 * <data dir>/buddy-towns/<map>-<area>-<piece>.btown. It holds the grid's
 * layout, each cell's floor and height, and which neighbours each cell
 * joins, plus the list of navigation mesh files it was baked from with
 * their sizes and times. The server checks that list against the files on
 * disk: a bake from other mesh files is refused (logged as an error) and
 * the town is measured live instead, so a stale bake is never walked.
 *
 * Layout (little-endian, as both ends run on the same kind of machine):
 *   "BTWN", version (u32), map, area, piece (u32 each),
 *   x0, y0, cell (f64 each), nx, ny (i32 each),
 *   tile count (u32), then per tile: x, y (u32 each), size (u64), mtime (i64),
 *   then per cell, in cell order: inside (u8), open (u8), height (f32), joins (u8)
 */

#ifndef BUDDY_TOWN_FILE_H
#define BUDDY_TOWN_FILE_H

#include <cstdint>
#include <cstdio>
#include <string>
#include <vector>

namespace BuddyTownFile
{
static constexpr char     MAGIC[4] = { 'B', 'T', 'W', 'N' };
static constexpr uint32_t VERSION  = 1;

struct Tile
{
    uint32_t x = 0, y = 0;
    uint64_t size = 0;
    int64_t  mtime = 0;
};

struct Town
{
    uint32_t map = 0, area = 0, piece = 0;
    double   x0 = 0.0, y0 = 0.0, cell = 0.0;
    int32_t  nx = 0, ny = 0;
    std::vector<Tile>    tiles;
    std::vector<uint8_t> inside, open, joins;
    std::vector<float>   height;
};

inline std::string Name(std::string const& dataDir, uint32_t map, uint32_t area, uint32_t piece)
{
    char buf[64];
    std::snprintf(buf, sizeof(buf), "/buddy-towns/%03u-%u-%u.btown", map, area, piece);
    return dataDir + buf;
}

// {{{ Write
inline bool Write(std::string const& path, Town const& t)
{
    FILE* f = std::fopen(path.c_str(), "wb");
    if (!f)
        return false;
    size_t n = size_t(t.nx) * size_t(t.ny);
    uint32_t tiles = uint32_t(t.tiles.size());
    bool ok = std::fwrite(MAGIC, 1, 4, f) == 4
        && std::fwrite(&VERSION, 4, 1, f) == 1
        && std::fwrite(&t.map, 4, 1, f) == 1 && std::fwrite(&t.area, 4, 1, f) == 1 && std::fwrite(&t.piece, 4, 1, f) == 1
        && std::fwrite(&t.x0, 8, 1, f) == 1 && std::fwrite(&t.y0, 8, 1, f) == 1 && std::fwrite(&t.cell, 8, 1, f) == 1
        && std::fwrite(&t.nx, 4, 1, f) == 1 && std::fwrite(&t.ny, 4, 1, f) == 1
        && std::fwrite(&tiles, 4, 1, f) == 1;
    for (Tile const& tile : t.tiles)
        ok = ok && std::fwrite(&tile.x, 4, 1, f) == 1 && std::fwrite(&tile.y, 4, 1, f) == 1
                && std::fwrite(&tile.size, 8, 1, f) == 1 && std::fwrite(&tile.mtime, 8, 1, f) == 1;
    ok = ok && std::fwrite(t.inside.data(), 1, n, f) == n && std::fwrite(t.open.data(), 1, n, f) == n
            && std::fwrite(t.height.data(), 4, n, f) == n && std::fwrite(t.joins.data(), 1, n, f) == n;
    return std::fclose(f) == 0 && ok;
}
// }}}

// {{{ Read
// False when the file is missing, unreadable, or not this format and
// version; `why` says which.
inline bool Read(std::string const& path, Town& t, std::string& why)
{
    FILE* f = std::fopen(path.c_str(), "rb");
    if (!f)
    {
        why = "no file";
        return false;
    }
    char magic[4];
    uint32_t version = 0, tiles = 0;
    bool ok = std::fread(magic, 1, 4, f) == 4 && magic[0] == 'B' && magic[1] == 'T' && magic[2] == 'W' && magic[3] == 'N'
        && std::fread(&version, 4, 1, f) == 1 && version == VERSION
        && std::fread(&t.map, 4, 1, f) == 1 && std::fread(&t.area, 4, 1, f) == 1 && std::fread(&t.piece, 4, 1, f) == 1
        && std::fread(&t.x0, 8, 1, f) == 1 && std::fread(&t.y0, 8, 1, f) == 1 && std::fread(&t.cell, 8, 1, f) == 1
        && std::fread(&t.nx, 4, 1, f) == 1 && std::fread(&t.ny, 4, 1, f) == 1
        && std::fread(&tiles, 4, 1, f) == 1 && t.nx > 0 && t.ny > 0 && tiles < 4096;
    if (!ok)
    {
        std::fclose(f);
        why = "not a version " + std::to_string(VERSION) + " town file";
        return false;
    }
    t.tiles.resize(tiles);
    for (Tile& tile : t.tiles)
        ok = ok && std::fread(&tile.x, 4, 1, f) == 1 && std::fread(&tile.y, 4, 1, f) == 1
                && std::fread(&tile.size, 8, 1, f) == 1 && std::fread(&tile.mtime, 8, 1, f) == 1;
    size_t n = size_t(t.nx) * size_t(t.ny);
    t.inside.resize(n), t.open.resize(n), t.height.resize(n), t.joins.resize(n);
    ok = ok && std::fread(t.inside.data(), 1, n, f) == n && std::fread(t.open.data(), 1, n, f) == n
            && std::fread(t.height.data(), 4, n, f) == n && std::fread(t.joins.data(), 1, n, f) == n;
    std::fclose(f);
    if (!ok)
        why = "cut short";
    return ok;
}
// }}}
}

#endif
