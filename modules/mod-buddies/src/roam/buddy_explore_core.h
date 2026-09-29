/*
 * buddy_explore_core.h - exploring an area as painting (issue 617e6).
 *
 * For a general audience: the owner compared four ways a buddy could
 * explore a named area, in animations drawn from the Lua model
 * (src/lua-basic/lib/buddy-roam.lua, the "paint" reading; the gallery's
 * animations 19 and 21), and asked for all of them in game "to see what
 * kind of mechanics they create". The first, the pinwheel, is the roaming
 * core (buddy_roam_core.h). This file is the other three, and what they
 * share:
 *
 *   the ground grid  - the area cut into square cells, each either part of
 *                      the area or not, walkable or not, with its ground
 *                      height, its distance to the area's edge and its
 *                      distance to the nearest wall;
 *   paint            - what the clan has seen: each buddy lays paint on the
 *                      cells it can see, most where it stands, less out to
 *                      60 yards; the walls paint a fringe within 5 yards of
 *                      themselves every 3 seconds, so buddies shy from them
 *                      and walk tunnels down the middle;
 *   rooms            - wide places (at least 14 yards across) and the
 *                      tunnels (narrow places) between them;
 *   the disc         - the area mapped onto a circle ("a circle that's been
 *                      squished to fit" the area's borders);
 *   the choosers     - least paint (go where the least has been seen;
 *                      the owner's favourite), the room orbit (the pinwheel
 *                      round the middle of the room a buddy is in, until the
 *                      paint draws it on), and the squished circle (the
 *                      pinwheel run on the disc);
 *   paths            - over the grid's cells, cheaper through unpainted
 *                      ground, pulled straight where a straight line can
 *                      be walked.
 *
 * Nothing here knows the server. The server fills the grid from the real
 * map (buddies_explore.cpp); the test fills it from the Lua model's grid of
 * a drawn arena and holds this code to the model's answers
 * (tests/buddy-roam-core/explore-check.cpp).
 *
 * Numbers are doubles throughout, and every loop visits cells in the same
 * order as the model, so the two agree to the last bit where the model is
 * discrete and to rounding where it is not.
 */

#ifndef MOD_BUDDIES_EXPLORE_CORE_H
#define MOD_BUDDIES_EXPLORE_CORE_H

#include <cstdint>
#include <functional>
#include <utility>
#include <vector>

namespace BuddyExplore
{

// {{{ Settings
// The model's numbers (buddy-roam.lua, the PAINT table and the "paint"
// reading's defaults). Tuning goes to docs/balance-updates.md.
struct Settings
{
    double  vision      = 60.0;   // yards a buddy paints out to
    int32_t rays        = 90;     // sight lines per deposit (every 4 degrees)
    int32_t nearPaint   = 12;     // paint at the buddy's own spot per sight line; falls off as (1 - d / vision)^2, at least 1
    double  wallReach   = 5.0;    // yards from a wall its paint reaches
    int32_t wallPaint   = 400;    // a wall pulse's level at the wall itself, falling to 0 at wallReach (squared)
    double  roomMin     = 7.0;    // yards from the area's edge: ground this deep is a room's core
    double  roomLeave   = 0.8;    // a room this explored lets the paint draw a buddy onward
    double  saturate    = 200.0;  // paint p counts as p / (p + saturate) toward "painted"
    double  disc        = 6.0;    // yards round a candidate its paint is judged over
    double  pathMargin  = 1.5;    // yards a path keeps off walls
    double  close       = 20.0;   // yards: ground seen from this near counts as explored
    double  farWeight   = 0.3;    // how much farther from the entrance counts, against paint
    double  pathWeight  = 3.0;    // how much dearer a painted cell is to walk through
    double  clearance   = 3.0;    // yards a waypoint keeps off walls
    double  nearYards   = 10.0;   // the room orbit's floor: no waypoint nearer a room's middle (or the room's reach, if less)
    double  turn        = 6.283185307179586 / 10.0;  // the pinwheel's step: a tenth of a circle
    int32_t yChangeMin  = 1;      // the owner's Y rule: a whole number 1..100 moved by yChangeMin..yChangeMax
    int32_t yChangeMax  = 20;
};
// }}}

// {{{ Grid
// The area as square cells `cell` yards across, the first cell's corner at
// (x0, y0), nx across and ny down; a cell's number is iy * nx + ix. Filled by
// whoever makes the grid (the server from the map, the test from the
// model): inside, open, edge, wall, height, then Prepare() does the rest.
struct Place
{
    bool                 isRoom = true;
    int32_t              id     = 0;      // the room's or tunnel's number (1-based)
    std::vector<int32_t> cells;           // its walkable cells, in cell order
    double               cx = 0.0, cy = 0.0;  // its middle
};
struct Grid
{
    double  x0 = 0.0, y0 = 0.0, cell = 3.0;
    int32_t nx = 0, ny = 0;
    // per cell (n = nx * ny)
    std::vector<uint8_t> inside;   // part of the area
    std::vector<uint8_t> open;     // walkable: inside, and not in a rock or wall
    std::vector<double>  edge;     // yards to the area's edge (inside cells; -1 otherwise)
    std::vector<double>  wall;     // yards to the nearest wall or rock (open cells; -1 otherwise)
    std::vector<float>   height;   // ground height (the server's; 0 on a drawn map)
    // Prepare() fills these
    std::vector<int32_t> openList;                         // the open cells, in cell order
    std::vector<std::pair<int32_t, uint16_t>> wallCells;   // cells a wall pulse reaches, and its level there
    std::vector<int32_t> room;     // 1-based room number, 0 = none
    std::vector<int32_t> tunnel;   // 1-based tunnel number, 0 = none
    std::vector<Place>   rooms, tunnels;
    std::vector<Place>   places;   // every room, then every tunnel with walkable cells
    // DiscMap() fills these
    std::vector<double>  du, dv;   // each inside cell's place on the unit disc
    std::vector<uint8_t> hasDisc;  // 1 where du, dv are set
    std::vector<uint8_t> rim;      // 1 on the area's border
    std::vector<int32_t> discClear;// cells a disc waypoint may take (open, clearance off walls)

    int32_t Count() const { return nx * ny; }
    // the cell under (x, y), or -1 off the grid
    int32_t CellOf(double x, double y) const;
    void    CellXY(int32_t i, double& x, double& y) const;
};
// }}}

// {{{ Paint
// A clan's paint on one area's grid. Counts are 16 bits and only grow; at
// 65,536 a count wraps round to a small number and that patch looks
// unexplored for a while. The owner accepted this (2026-09-27: "they'll wrap
// around at 60 thousand or whenever an integer wraps [...] Might look a
// little janky randomly, but that's okay, leave a note about it"): this is
// the note. The arithmetic is done in uint16_t on purpose, wrap and all.
struct Paint
{
    std::vector<uint16_t> buddy;   // laid by buddies
    std::vector<uint16_t> wallp;   // laid by the walls' pulses
    std::vector<uint8_t>  close;   // seen from within Settings.close yards (the "explored" measure)
    void Reset(Grid const& g);
};
// }}}

using Rng = std::function<double()>;

// {{{ Explorer
// One buddy's state between waypoints, for all three choosers.
struct Explorer
{
    double  x = 0.0, y = 0.0;      // where it stands
    int32_t id = 0;                // its number in the clan (from 1): whose turn to paint
    int32_t spin = 1;              // +1 or -1
    // the squished circle
    double  dang = 0.0, dshare = 0.5;
    // the room orbit
    int32_t room = 0;              // the room it orbits (1-based), 0 before the first
    double  rshare = 0.5;
    double  rang = 0.0;
    bool    rangSet = false;
    int32_t heading = 0;           // the place the paint draws it to (1-based index into places), 0 = none
    // the last goal
    bool    hasGoal = false;
    double  gx = 0.0, gy = 0.0;
};
// }}}

// {{{ Point2
struct Point2
{
    double x = 0.0, y = 0.0;
};
// }}}

// {{{ building
// After inside/open/edge/wall are filled: the open list, the wall pulse's
// cells and levels, and the rooms and tunnels. Resizes the other vectors.
void Prepare(Grid& g, Settings const& s);

// For a grid made from samples (the server's): each inside cell's distance
// to the nearest outside cell, and each open cell's distance to the nearest
// cell that isn't open, in yards, measured centre to centre less half a
// cell (the edge of that cell). The drawn maps have exact distances from
// their outlines and don't use this.
void ComputeDistances(Grid& g);

// The squished circle. `rimPoint(i)` gives each border cell's place on the
// circle (cos, sin of its angle round it); the other inside cells are moved
// again and again to the average of their four neighbours (`sweeps`
// over-relaxed passes; with `tolerance` > 0 it stops early once no cell
// moves more than that in a pass). Returns the passes made. RimAngles()
// below traces a grid's own border for grids that have no outline.
int32_t DiscMap(Grid& g, std::function<std::pair<double, double>(int32_t)> const& rimPoint, int32_t sweeps, double tolerance);

// The border cells in order round the outer border, and each one's angle:
// 2 pi x (distance along the border) / (the border's length). For grids
// made from samples, which have no outline to measure along.
std::vector<std::pair<int32_t, double>> RimAngles(Grid const& g);
// }}}

// {{{ painting
void Deposit(Grid const& g, Paint& p, Settings const& s, double x, double y);
void WallPulse(Grid const& g, Paint& p);
double PaintedNear(Grid const& g, Paint const& p, Settings const& s, double x, double y);
double Coverage(Grid const& g, Paint const& p);
// the farthest open cell's distance from the entrance (the "far" measure's yardstick)
double FarRef(Grid const& g, double ex, double ey);
// }}}

// {{{ choosing and walking
// Each chooser sets e.hasGoal, e.gx, e.gy (and its own state), drawing
// random numbers exactly as the model does. `ex, ey` is where the owner
// entered the area; `farRef` is FarRef() of it. False only when nothing can
// be chosen at all (no rooms, no disc).
bool PickLeast(Grid const& g, Paint const& p, Settings const& s, Explorer& e, double ex, double ey, double farRef, Rng const& rng);
bool PickDisc (Grid const& g, Paint const& p, Settings const& s, Explorer& e, double ex, double ey, double farRef, Rng const& rng);
bool PickRooms(Grid const& g, Paint const& p, Settings const& s, Explorer& e, double ex, double ey, double farRef, Rng const& rng);
// a disc explorer's start: its angle and radius from where it stands
void BeginDisc(Grid const& g, Explorer& e);

// The way from a to b over walkable cells kept pathMargin off walls, A*
// with eight neighbours, each step dearer through painted cells by
// `weight`; pulled straight where a line can be walked. The points exclude
// the start and end at b. Empty when there is no way.
std::vector<Point2> GridPath(Grid const& g, Paint const& p, Settings const& s,
                             double ax, double ay, double bx, double by, double weight);
// }}}

} // namespace BuddyExplore

#endif
