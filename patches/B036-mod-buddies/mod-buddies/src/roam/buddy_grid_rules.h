
#ifndef BUDDY_GRID_RULES_H
#define BUDDY_GRID_RULES_H

#include "buddy_explore_core.h"
#include <cmath>
#include <cstdint>

namespace BuddyGridRules
{
static constexpr float   CELL_YARDS      = 3.0f;
static constexpr int32_t MAX_CELLS       = 250000;
static constexpr float   MAX_GRADE       = 1.0f;
static constexpr float   MESH_SNAP_YARDS = 1.5f;
static constexpr float   MESH_RISE_YARDS = 3.0f;

inline bool Layout(float minX, float maxX, float minY, float maxY, BuddyExplore::Grid& g)
{
    float cell = CELL_YARDS;
    float w = maxX - minX + 2.0f * cell, h = maxY - minY + 2.0f * cell;
    bool standard = true;
    if (w * h / (cell * cell) > float(MAX_CELLS))
    {
        cell = std::ceil(std::sqrt(w * h / float(MAX_CELLS)) * 2.0f) / 2.0f;
        standard = false;
    }
    g.cell = cell;
    g.x0 = minX - cell, g.y0 = minY - cell;
    g.nx = int32_t(std::ceil((maxX - minX + 2.0f * cell) / cell));
    g.ny = int32_t(std::ceil((maxY - minY + 2.0f * cell) / cell));
    return standard;
}

inline bool Gentle(float zFrom, float zTo, double cell)
{
    return std::fabs(zTo - zFrom) <= float(cell) * MAX_GRADE;
}

enum : uint8_t { JOIN_EAST = 1, JOIN_WEST = 2, JOIN_NORTH = 4, JOIN_SOUTH = 8 };
}

#endif
