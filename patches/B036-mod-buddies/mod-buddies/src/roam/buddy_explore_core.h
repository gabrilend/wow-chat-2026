
#ifndef MOD_BUDDIES_EXPLORE_CORE_H
#define MOD_BUDDIES_EXPLORE_CORE_H

#include <cstdint>
#include <functional>
#include <utility>
#include <vector>

namespace BuddyExplore
{

struct Settings
{
    double  vision      = 60.0;
    int32_t rays        = 90;
    int32_t nearPaint   = 12;
    double  wallReach   = 5.0;
    int32_t wallPaint   = 400;
    double  roomMin     = 7.0;
    double  roomLeave   = 0.8;
    double  saturate    = 200.0;
    double  disc        = 6.0;
    double  pathMargin  = 1.5;
    double  close       = 20.0;
    double  farWeight   = 0.3;
    double  pathWeight  = 3.0;
    double  clearance   = 3.0;
    double  nearYards   = 10.0;
    double  turn        = 6.283185307179586 / 10.0;
    int32_t yChangeMin  = 1;
    int32_t yChangeMax  = 20;
};

struct Place
{
    bool                 isRoom = true;
    int32_t              id     = 0;
    std::vector<int32_t> cells;
    double               cx = 0.0, cy = 0.0;
};
struct Grid
{
    double  x0 = 0.0, y0 = 0.0, cell = 3.0;
    int32_t nx = 0, ny = 0;
    std::vector<uint8_t> inside;
    std::vector<uint8_t> open;
    std::vector<double>  edge;
    std::vector<double>  wall;
    std::vector<float>   height;
    std::vector<int32_t> openList;
    std::vector<std::pair<int32_t, uint16_t>> wallCells;
    std::vector<int32_t> room;
    std::vector<int32_t> tunnel;
    std::vector<Place>   rooms, tunnels;
    std::vector<Place>   places;
    std::vector<double>  du, dv;
    std::vector<uint8_t> hasDisc;
    std::vector<uint8_t> rim;
    std::vector<int32_t> discClear;

    int32_t Count() const { return nx * ny; }
    int32_t CellOf(double x, double y) const;
    void    CellXY(int32_t i, double& x, double& y) const;
};

struct Paint
{
    std::vector<uint16_t> buddy;
    std::vector<uint16_t> wallp;
    std::vector<uint8_t>  close;
    void Reset(Grid const& g);
};

using Rng = std::function<double()>;

struct Explorer
{
    double  x = 0.0, y = 0.0;
    int32_t id = 0;
    int32_t spin = 1;
    double  dang = 0.0, dshare = 0.5;
    int32_t room = 0;
    double  rshare = 0.5;
    double  rang = 0.0;
    bool    rangSet = false;
    int32_t heading = 0;
    bool    hasGoal = false;
    double  gx = 0.0, gy = 0.0;
};

struct Point2
{
    double x = 0.0, y = 0.0;
};

void Prepare(Grid& g, Settings const& s);

void ComputeDistances(Grid& g);

int32_t DiscMap(Grid& g, std::function<std::pair<double, double>(int32_t)> const& rimPoint, int32_t sweeps, double tolerance);

std::vector<std::pair<int32_t, double>> RimAngles(Grid const& g);

void Deposit(Grid const& g, Paint& p, Settings const& s, double x, double y);
void WallPulse(Grid const& g, Paint& p);
double PaintedNear(Grid const& g, Paint const& p, Settings const& s, double x, double y);
double Coverage(Grid const& g, Paint const& p);
double FarRef(Grid const& g, double ex, double ey);

bool PickLeast(Grid const& g, Paint const& p, Settings const& s, Explorer& e, double ex, double ey, double farRef, Rng const& rng);
bool PickDisc (Grid const& g, Paint const& p, Settings const& s, Explorer& e, double ex, double ey, double farRef, Rng const& rng);
bool PickRooms(Grid const& g, Paint const& p, Settings const& s, Explorer& e, double ex, double ey, double farRef, Rng const& rng);
void BeginDisc(Grid const& g, Explorer& e);

std::vector<Point2> GridPath(Grid const& g, Paint const& p, Settings const& s,
                             double ax, double ay, double bx, double by, double weight);

}

#endif
