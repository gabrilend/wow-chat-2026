/*
 * buddy_roam_core.h - where a roaming buddy goes next, and how it walks
 * there (issue 617e2).
 *
 * For a general audience: the owner designed how buddies roam a named
 * area (Fargodeep Mine, say) with animations drawn from a model written in
 * Lua (src/lua-basic/lib/buddy-roam.lua, docs/HTML/buddy-roaming.html).
 * This is that model in C++, so the server can run it. It knows nothing of
 * the server: the world reaches it through four questions it asks of the
 * ground (the Ground callbacks below), so the same code runs on the real
 * map in game and on the drawn map of the animations, where a test holds
 * it to the Lua model's answers.
 *
 * The pieces, in the owner's words (2026-09-27):
 *   the pinwheel  - each waypoint's bearing from the area's centre turns a
 *                   steady step ("10% of a circle per increment") in the
 *                   buddy's own direction;
 *   the Y rule    - its distance out is a percent 1..100 of the way to the
 *                   edge on that bearing, moved 1..20 in or out at even
 *                   odds ("an integer between 1 and 20 [...] added or
 *                   removed from that 1 in 100 number"), never nearer the
 *                   centre than 10 yards;
 *   crowding      - "we shouldn't place a waypoint within 5 yards of
 *                   another player or buddybot": then Y moves 10 toward 50;
 *   walls         - "move the 'edge' of the map to the closest of the
 *                   walls": the edge along a bearing is the first wall;
 *   the planner   - "imaginary waypoints [...] based on the character's
 *                   size", the height tested at each, obstacles curved
 *                   round, "the gentlest path down a slope, or the
 *                   flattest path up a hill";
 *   resting       - "a chance to sit down and eat food or regenerate health
 *                   every time they reach a waypoint [...] the % of your
 *                   health that's missing, divided by 2".
 */

#ifndef MOD_BUDDIES_ROAM_CORE_H
#define MOD_BUDDIES_ROAM_CORE_H

#include <cstdint>
#include <functional>
#include <vector>

namespace BuddyRoam
{

// {{{ Point
// A place in the world, in yards (x, y across, z up).
struct Point
{
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;
};
// }}}

// {{{ Ground
// The four questions the core asks of the world. In game they are answered
// from the map (buddies_roam_ground.cpp); in the test, from the drawn map.
struct Ground
{
    // Ground height at (x, y), searching down from zHint + 2 yards (so a
    // bridge overhead is not read as the ground). Returns a very low value
    // (below -100000) where there is no ground.
    std::function<float(float x, float y, float zHint)> height;

    // Whether a waypoint may stand at (x, y): inside the area, and
    // `clearance` yards clear of anything standing up from the ground
    // (in game: no sharp height step within that radius).
    std::function<bool(float x, float y, float z, float clearance)> clear;

    // Yards from the centre (cx, cy) along `bearing` (radians) to the first
    // wall or the area's edge ("the first wall along the line").
    std::function<float(float cx, float cy, float cz, float bearing)> edgeAlong;

    // Whether the straight line from a to b stays inside the area's own
    // walls (rocks standing on the floor don't count: they are walked
    // round, not seen past).
    std::function<bool(Point const& a, Point const& b)> seenThrough;
};
// }}}

// {{{ Rng
// The random numbers, 0 <= r < 1. The test drives the core and the Lua
// model with the same sequence (the gallery's seeded generator:
// s = (s * 1103515245 + 12345) mod 2^31, r = s / 2^31).
using Rng = std::function<double()>;
// }}}

// {{{ Settings
// The owner's numbers (2026-09-27), as in the Lua model's "waypoints"
// reading with the owner's settings. Tuning goes to docs/balance-updates.md.
struct Settings
{
    float    turn          = 6.2831853f / 10.0f; // radians per waypoint: a tenth of a circle
    int32_t  yChangeMin    = 1;                  // percent points, each waypoint
    int32_t  yChangeMax    = 20;
    float    nearYards     = 10.0f;              // no waypoint nearer the centre
    float    clearance     = 3.0f;               // yards a waypoint keeps off obstacles and the edge
    float    crowdYards    = 5.0f;               // someone this near a new waypoint moves Y
    int32_t  crowdShift    = 10;                 // percent points, toward 50
    float    openingYards  = 20.0f;              // a line this much longer within half a step is an opening
    // the planner
    float    stepRise      = 0.6f;               // yards a height change must stand out by to be an obstacle
    float    slopeWeight   = 6.0f;               // cost per yard of grade squared
    float    maxBulge      = 16.0f;              // yards a detour may bulge before that side is given up
    float    rampMin       = 3.0f;               // shortest ease into / out of a detour
    int32_t  maxDetours    = 8;
    // piercing the middle (2026-09-27): after two inward rolls in a row, a
    // Y at or under this sends the waypoint to the far side of the centre
    // and reverses the buddy's direction; 0 turns it off
    int32_t  piercePercent = 25;
    // the monster nudge (2026-09-27): a trip whose line misses a monster's
    // aggro radius by at most lureReach yards bends through a point
    // lureDepth of the radius in from its edge
    float    lureReach     = 25.0f;
    float    lureDepth     = 0.7f;
};
// }}}

// {{{ Mob
// A monster near the buddy that would attack it on sight: where it stands
// and its aggro radius against this buddy (the server's own figure).
struct Mob
{
    Point at;
    float aggro = 0.0f;
};
// }}}

// {{{ Area
// A named area as the core sees it: its centre, found once (in game: the
// average of the grid points sharing the area's id, buddies_roam_ground.cpp).
struct Area
{
    uint32_t id = 0;
    Point    centre;
};
// }}}

// {{{ Buddy
// One buddy's roaming state, kept between waypoints.
struct Buddy
{
    float              angle     = 0.0f;  // the pinwheel's own bearing (radians from the centre)
    int32_t            spin      = 1;     // +1 or -1, drawn once
    int32_t            yPercent  = 0;     // the Y rule's number, 1..100; 0 before the first waypoint
    float              body      = 0.61f; // yards wide (twice the race model's bounding radius)
    Point              waypoint;          // where it is going
    bool               hasWaypoint = false;
    std::vector<Point> path;              // the planned test points, start first, waypoint last
    size_t             pathIndex = 0;     // the next point to walk to
    uint32_t           crowdMoves = 0;    // how often the crowding rule moved its Y (for logs)
    int32_t            inward    = 0;     // inward Y rolls in a row (piercing)
    uint32_t           pierced   = 0;     // how often it crossed the middle (for logs)
    bool               lured     = false; // this trip bends through a monster's radius
    Point              lurePoint;         // where (for logs and drawing)
};
// }}}

// {{{ the calls
// Start a buddy on the area: its bearing is where it stands, its direction
// drawn at random.
void Begin(Buddy& buddy, Area const& area, Point const& at, Rng const& rng);

// Pick the buddy's next waypoint from where it stands and plan the path
// there. `others` are where the other buddies and the players nearby stand
// (the crowding rule). Returns false when no waypoint clear of obstacles
// exists in a full circle of bearings (the area is too small or too
// cluttered for the clearance), when the buddy can't see the area's centre
// to find a turning point, or when no path can be planned to the waypoint;
// the caller logs it and tries later. `angle`, `yPercent` and `crowdMoves`
// may have moved on even when it returns false.
// `mobs` are the monsters near the buddy (the nudge); may be empty.
bool NextWaypoint(Buddy& buddy, Area const& area, Point const& at, std::vector<Point> const& others,
                  std::vector<Mob> const& mobs, Ground const& ground, Settings const& settings, Rng const& rng);

// The planner alone: test points from `from` to `to` for a body `body`
// yards wide, round any obstacle, along the cheapest of five bows. Empty
// when no candidate gets through.
std::vector<Point> PlanPath(Point const& from, Point const& to, float body, Ground const& ground, Settings const& settings);

// The chance (0..0.5) to sit and eat or regenerate on reaching a waypoint:
// half the share of health missing.
float RestChance(float health, float maxHealth);
// }}}

} // namespace BuddyRoam

#endif
