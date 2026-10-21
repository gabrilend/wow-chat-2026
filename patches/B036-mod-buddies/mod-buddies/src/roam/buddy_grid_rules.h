/*
 * buddy_grid_rules.h - the exploring grid's rules, shared by the server and
 * the town baker (issues 617e6, 617o2, 617o3).
 *
 * For a general audience: an area's exploring grid is measured live in the
 * server (buddies_explore.cpp) or baked ahead of time for towns
 * (tools/buddy-town-baker/ at the project root). Both must lay out the same cells and judge
 * floor and steps the same way, or a baked town would be a different grid
 * from the one the server would have measured. So the layout and the rules
 * live here, once, with no server code in them, and both include this.
 * The mesh questions themselves are in buddy_mesh_core.h.
 */

#ifndef BUDDY_GRID_RULES_H
#define BUDDY_GRID_RULES_H

#include "buddy_explore_core.h"
#include <cmath>
#include <cstdint>

namespace BuddyGridRules
{
// Cell size: 3 yards. The model's drawn hall used 2; in the world 3 keeps a
// good-sized named area (500 by 500 yards) at under 28,000 cells, still
// splits a 6-yard tunnel into two cells a path can walk (paths keep 1.5
// yards off walls), and is about a body and a stride. Areas so big they
// would pass MAX_CELLS get bigger cells instead.
static constexpr float   CELL_YARDS      = 3.0f;
static constexpr int32_t MAX_CELLS       = 250000;
static constexpr float   MAX_GRADE       = 1.0f;   // rise over run a buddy walks (45 degrees); more is a wall
static constexpr float   MESH_SNAP_YARDS = 1.5f;   // a cell is floor when the mesh is within this of its middle, sideways (half a cell) ...
static constexpr float   MESH_RISE_YARDS = 3.0f;   // ... and within this up or down of the ground found there (617o2)

// {{{ Layout
// The grid over an area piece's borders (its 33-yard squares' edges) and
// one cell more on every side. Returns false when the cell size had to grow
// past CELL_YARDS to stay under MAX_CELLS (the caller may say so); the grid
// is laid out either way.
inline bool Layout(float minX, float maxX, float minY, float maxY, BuddyExplore::Grid& g)
{
    float cell = CELL_YARDS;
    float w = maxX - minX + 2.0f * cell, h = maxY - minY + 2.0f * cell;
    bool standard = true;
    if (w * h / (cell * cell) > float(MAX_CELLS))
    {
        cell = std::ceil(std::sqrt(w * h / float(MAX_CELLS)) * 2.0f) / 2.0f;   // up to the next half yard
        standard = false;
    }
    g.cell = cell;
    g.x0 = minX - cell, g.y0 = minY - cell;
    g.nx = int32_t(std::ceil((maxX - minX + 2.0f * cell) / cell));
    g.ny = int32_t(std::ceil((maxY - minY + 2.0f * cell) / cell));
    return standard;
}
// }}}

// {{{ Gentle
// Whether a step between two neighbouring cells is gentle enough to walk
// (the mesh's line test is asked separately).
inline bool Gentle(float zFrom, float zTo, double cell)
{
    return std::fabs(zTo - zFrom) <= float(cell) * MAX_GRADE;
}
// }}}

// The joins' bits, per cell: which neighbours a buddy can step to.
enum : uint8_t { JOIN_EAST = 1, JOIN_WEST = 2, JOIN_NORTH = 4, JOIN_SOUTH = 8 };
}

#endif
