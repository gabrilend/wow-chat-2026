
#ifndef MOD_BUDDIES_ROAM_CORE_H
#define MOD_BUDDIES_ROAM_CORE_H

#include <cstdint>
#include <functional>
#include <vector>

namespace BuddyRoam
{

struct Point
{
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;
};

struct Ground
{
    std::function<float(float x, float y, float zHint)> height;

    std::function<bool(float x, float y, float z, float clearance)> clear;

    std::function<float(float cx, float cy, float cz, float bearing)> edgeAlong;

    std::function<bool(Point const& a, Point const& b)> seenThrough;
};

using Rng = std::function<double()>;

struct Settings
{
    float    turn          = 6.2831853f / 10.0f;
    int32_t  yChangeMin    = 1;
    int32_t  yChangeMax    = 20;
    float    nearYards     = 10.0f;
    float    clearance     = 3.0f;
    float    crowdYards    = 5.0f;
    int32_t  crowdShift    = 10;
    float    openingYards  = 20.0f;
    float    stepRise      = 0.6f;
    float    slopeWeight   = 6.0f;
    float    maxBulge      = 16.0f;
    float    rampMin       = 3.0f;
    int32_t  maxDetours    = 8;
    int32_t  piercePercent = 25;
    float    lureReach     = 25.0f;
    float    lureDepth     = 0.7f;
};

struct Mob
{
    Point at;
    float aggro = 0.0f;
};

struct Area
{
    uint32_t id = 0;
    Point    centre;
};

struct Buddy
{
    float              angle     = 0.0f;
    int32_t            spin      = 1;
    int32_t            yPercent  = 0;
    float              body      = 0.61f;
    Point              waypoint;
    bool               hasWaypoint = false;
    std::vector<Point> path;
    size_t             pathIndex = 0;
    uint32_t           crowdMoves = 0;
    int32_t            inward    = 0;
    uint32_t           pierced   = 0;
    bool               lured     = false;
    Point              lurePoint;
};

void Begin(Buddy& buddy, Area const& area, Point const& at, Rng const& rng);

bool NextWaypoint(Buddy& buddy, Area const& area, Point const& at, std::vector<Point> const& others,
                  std::vector<Mob> const& mobs, Ground const& ground, Settings const& settings, Rng const& rng);

std::vector<Point> PlanPath(Point const& from, Point const& to, float body, Ground const& ground, Settings const& settings);

float RestChance(float health, float maxHealth);

}

#endif
