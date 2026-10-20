
#include "buddy_roam_core.h"

#include <algorithm>
#include <cmath>
#include <optional>
#include <utility>

namespace BuddyRoam
{

namespace
{

constexpr double PI          = 3.14159265358979323846;
constexpr int    TURN_TRIES  = 12;
constexpr int    SHARE_TRIES = 8;
constexpr int    SLIDE_TRIES = 199;
constexpr double BOWS[]      = { 0.0, -0.15, 0.15, -0.3, 0.3 };
constexpr float  LURE_MARGIN = 1.5f;

struct Detour
{
    double s0, s1, side, amp, ramp;
};

struct Curve
{
    double ax, ay, az, len, ux, uy, nx, ny, bow, body;
    std::vector<Detour> detours;
};

struct Sample
{
    double s, x, y, h, top;
};

void CurvePoint(Curve const& c, double s, double& x, double& y)
{
    double off = c.bow * c.len * std::sin(PI * s / c.len);
    for (Detour const& d : c.detours)
    {
        double u;
        if (s < d.s0 - d.ramp || s > d.s1 + d.ramp)
            u = 0.0;
        else if (s < d.s0)
            u = (1.0 - std::cos(PI * (s - d.s0 + d.ramp) / d.ramp)) / 2.0;
        else if (s > d.s1)
            u = (1.0 - std::cos(PI * (d.s1 + d.ramp - s) / d.ramp)) / 2.0;
        else
            u = 1.0;
        off = off + d.side * d.amp * u;
    }
    x = c.ax + c.ux * s + c.nx * off;
    y = c.ay + c.uy * s + c.ny * off;
}

std::vector<Sample> SampleCurve(Ground const& ground, Curve const& c, double from, double to)
{
    std::vector<Sample> pts;
    int n = std::max(1, int(std::ceil((to - from) / c.body)));
    double half = c.body / 2.0;
    double zHint = c.az;
    pts.reserve(size_t(n) + 1);
    for (int i = 0; i <= n; ++i)
    {
        double s = from + (to - from) * i / n;
        double x, y, x2, y2;
        CurvePoint(c, s, x, y);
        CurvePoint(c, std::min(c.len, s + 0.01), x2, y2);
        double tx = x2 - x, ty = y2 - y;
        double tl = std::sqrt(tx * tx + ty * ty);
        if (tl < 1e-9)
        {
            tx = c.ux;
            ty = c.uy;
            tl = 1.0;
        }
        double sx = -ty / tl * half, sy = tx / tl * half;
        double h   = ground.height(float(x), float(y), float(zHint));
        double top = std::max({ h, double(ground.height(float(x + sx), float(y + sy), float(zHint))),
                                   double(ground.height(float(x - sx), float(y - sy), float(zHint))) });
        pts.push_back({ s, x, y, h, top });
        zHint = h;
    }
    return pts;
}

std::optional<std::pair<double, double>> FirstStep(Ground const& ground, std::vector<Sample> const& pts, Settings const& settings)
{
    size_t n = pts.size();
    std::vector<double> d(n, 0.0);
    for (size_t i = 1; i < n; ++i)
        d[i] = pts[i].top - pts[i - 1].top;

    auto sharp = [&](size_t i)
    {
        bool hasPrev = i >= 2, hasNext = i + 1 < n;
        double prev = hasPrev ? d[i - 1] : (hasNext ? d[i + 1] : 0.0);
        double next = hasNext ? d[i + 1] : (hasPrev ? d[i - 1] : 0.0);
        double around = std::min(std::fabs(prev), std::fabs(next));
        return std::fabs(d[i]) - around > settings.stepRise;
    };

    for (size_t i = 1; i < n; ++i)
    {
        Point a{ float(pts[i - 1].x), float(pts[i - 1].y), float(pts[i - 1].h) };
        Point b{ float(pts[i].x), float(pts[i].y), float(pts[i].h) };
        if (!ground.seenThrough(a, b))
            return std::make_pair(pts[i - 1].s, pts[i].s);
        if (sharp(i))
        {
            for (size_t j = i + 1; j < n; ++j)
                if (sharp(j) && d[j] * d[i] < 0.0)
                    return std::make_pair(pts[i - 1].s, pts[j].s);
            return std::make_pair(pts[i - 1].s, pts[n - 1].s);
        }
    }
    return std::nullopt;
}

double PathCost(std::vector<Sample> const& pts, Settings const& settings)
{
    double cost = 0.0;
    for (size_t i = 1; i < pts.size(); ++i)
    {
        Sample const& a = pts[i - 1];
        Sample const& b = pts[i];
        double ds = std::sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y));
        double grade = ds > 0.0 ? (b.h - a.h) / ds : 0.0;
        cost = cost + ds * (1.0 + settings.slopeWeight * grade * grade);
    }
    return cost;
}

bool AddDetour(Ground const& ground, Curve& c, double s0, double s1, Settings const& settings)
{
    std::optional<Detour> best;
    double bestCost = 0.0;
    for (double side : { 1.0, -1.0 })
    {
        double amp = c.body;
        while (amp <= settings.maxBulge)
        {
            Detour d{ s0, s1, side, amp, std::max(double(settings.rampMin), 2.0 * amp) };
            c.detours.push_back(d);
            double from = std::max(0.0, s0 - d.ramp), to = std::min(c.len, s1 + d.ramp);
            bool clear = !FirstStep(ground, SampleCurve(ground, c, from, to), settings);
            if (clear)
            {
                double cost = PathCost(SampleCurve(ground, c, 0.0, c.len), settings);
                if (!best || cost < bestCost)
                {
                    best = d;
                    bestCost = cost;
                }
            }
            c.detours.pop_back();
            if (clear)
                break;
            amp = amp + c.body;
        }
    }
    if (!best)
        return false;
    c.detours.push_back(*best);
    return true;
}

double StepY(int32_t percent, Settings const& settings, Rng const& rng)
{
    int32_t change = settings.yChangeMin + int32_t(std::floor(rng() * double(settings.yChangeMax - settings.yChangeMin + 1)));
    int32_t sign   = rng() < 0.5 ? -1 : 1;
    int32_t next   = std::max(1, std::min(100, percent + sign * change));
    return double(next) / 100.0;
}

double FindOpening(Area const& area, double angle, Ground const& ground, Settings const& settings)
{
    double cx = area.centre.x, cy = area.centre.y, cz = area.centre.z;
    double base = ground.edgeAlong(float(cx), float(cy), float(cz), float(angle));
    int half = int(std::floor(double(settings.turn) * (180.0 / PI) / 2.0));
    std::optional<int> runFrom, bestFrom;
    int bestLen = 0;
    for (int k = -half; k <= half + 1; ++k)
    {
        bool open = k <= half &&
            double(ground.edgeAlong(float(cx), float(cy), float(cz), float(angle + k * (PI / 180.0)))) >= base + settings.openingYards;
        if (open && !runFrom)
            runFrom = k;
        if (!open && runFrom)
        {
            if (k - *runFrom > bestLen)
            {
                bestFrom = runFrom;
                bestLen = k - *runFrom;
            }
            runFrom.reset();
        }
    }
    if (!bestFrom)
        return angle;
    return angle + (double(*bestFrom) + double(bestLen - 1) / 2.0) * (PI / 180.0);
}

bool TurningPoint(Point const& at, Point const& wp, Area const& area, Ground const& ground, std::optional<Point>& via)
{
    via.reset();
    if (ground.seenThrough(at, wp))
        return true;
    Point centre = area.centre;
    if (!ground.seenThrough(at, centre))
        return false;
    double len = std::sqrt(double(centre.x - at.x) * (centre.x - at.x) + double(centre.y - at.y) * (centre.y - at.y));
    int steps = int(std::ceil(len));
    for (int d = 1; d <= steps; ++d)
    {
        double k = std::min(1.0, d / len);
        Point p;
        p.x = float(at.x + (centre.x - at.x) * k);
        p.y = float(at.y + (centre.y - at.y) * k);
        p.z = ground.height(p.x, p.y, at.z);
        if (ground.seenThrough(p, wp))
        {
            via = p;
            return true;
        }
    }
    return false;
}

bool LurePoint(Point const& at, Point const& wp, std::vector<Mob> const& mobs, Ground const& ground,
               Settings const& settings, Point& lure)
{
    double vx = double(wp.x) - at.x, vy = double(wp.y) - at.y;
    double len2 = vx * vx + vy * vy;
    if (len2 < 1e-9)
        return false;
    bool found = false;
    double bestT = 0.0;
    for (Mob const& m : mobs)
    {
        double t = ((double(m.at.x) - at.x) * vx + (double(m.at.y) - at.y) * vy) / len2;
        t = std::max(0.0, std::min(1.0, t));
        double qx = at.x + vx * t, qy = at.y + vy * t;
        double ux = qx - m.at.x, uy = qy - m.at.y;
        double ul = std::sqrt(ux * ux + uy * uy);
        double miss = ul - m.aggro;
        if (miss <= 0.0 || miss > settings.lureReach || (found && t >= bestT))
            continue;
        Point p;
        p.x = float(m.at.x + ux / ul * m.aggro * settings.lureDepth);
        p.y = float(m.at.y + uy / ul * m.aggro * settings.lureDepth);
        p.z = ground.height(p.x, p.y, at.z);
        if (!ground.clear(p.x, p.y, p.z, LURE_MARGIN) || !ground.seenThrough(at, p) || !ground.seenThrough(p, wp))
            continue;
        lure = p;
        bestT = t;
        found = true;
    }
    return found;
}

}

void Begin(Buddy& buddy, Area const& area, Point const& at, Rng const& rng)
{
    buddy.spin        = rng() < 0.5 ? 1 : -1;
    buddy.angle       = float(std::atan2(double(at.y) - area.centre.y, double(at.x) - area.centre.x));
    buddy.yPercent    = 0;
    buddy.hasWaypoint = false;
    buddy.path.clear();
    buddy.pathIndex   = 0;
}

bool NextWaypoint(Buddy& buddy, Area const& area, Point const& at, std::vector<Point> const& others,
                  std::vector<Mob> const& mobs, Ground const& ground, Settings const& settings, Rng const& rng)
{
    double cx = area.centre.x, cy = area.centre.y, cz = area.centre.z;
    double angle = buddy.angle;
    for (int turn = 0; turn < TURN_TRIES; ++turn)
    {
        angle = angle + double(settings.turn) * buddy.spin;
        buddy.angle = float(angle);
        double bearing = settings.openingYards > 0.0f ? FindOpening(area, angle, ground, settings) : angle;
        double reach = double(ground.edgeAlong(float(cx), float(cy), float(cz), float(bearing))) - settings.clearance;

        bool slide = buddy.hasWaypoint;
        double drawn = 0.0;
        if (slide)
        {
            drawn = StepY(buddy.yPercent, settings, rng);
            if (settings.piercePercent > 0)
            {
                buddy.inward = drawn < double(buddy.yPercent) / 100.0 ? buddy.inward + 1 : 0;
                if (buddy.inward >= 2 && drawn * 100.0 <= double(settings.piercePercent) + 1e-9)
                {
                    angle       = angle + PI;
                    buddy.angle = float(angle);
                    buddy.spin  = -buddy.spin;
                    buddy.inward = 0;
                    bearing     = angle;
                    reach       = double(ground.edgeAlong(float(cx), float(cy), float(cz), float(bearing))) - settings.clearance;
                    ++buddy.pierced;
                }
            }
            double d = std::max(double(settings.nearYards), drawn * reach);
            double x = cx + std::cos(bearing) * d, y = cy + std::sin(bearing) * d;
            bool nearSomeone = false;
            for (Point const& o : others)
                if ((o.x - x) * (o.x - x) + (o.y - y) * (o.y - y) < double(settings.crowdYards) * settings.crowdYards)
                    nearSomeone = true;
            if (nearSomeone)
            {
                int32_t pct  = int32_t(std::floor(drawn * 100.0 + 0.5));
                int32_t sign = pct < 50 ? 1 : pct > 50 ? -1 : (rng() < 0.5 ? 1 : -1);
                drawn = double(pct + sign * settings.crowdShift) / 100.0;
                ++buddy.crowdMoves;
            }
        }

        bool found = false;
        double share = 0.0, fx = 0.0, fy = 0.0;
        int tries = slide ? SLIDE_TRIES : SHARE_TRIES;
        for (int k = 1; k <= tries; ++k)
        {
            if (slide)
            {
                int32_t sign = k % 2 == 0 ? -1 : 1;
                share = drawn + double((k / 2) * sign) / 100.0;
                if (share < 0.01 || share > 1.0)
                    continue;
            }
            else
                share = rng();
            double d = std::max(double(settings.nearYards), share * reach);
            double x = cx + std::cos(bearing) * d, y = cy + std::sin(bearing) * d;
            if (ground.clear(float(x), float(y), at.z, settings.clearance))
            {
                found = true;
                fx = x;
                fy = y;
                break;
            }
        }
        if (!found)
            continue;

        buddy.yPercent = int32_t(std::floor((slide ? drawn : share) * 100.0 + 0.5));
        buddy.waypoint.x = float(fx);
        buddy.waypoint.y = float(fy);
        buddy.waypoint.z = ground.height(float(fx), float(fy), at.z);
        buddy.hasWaypoint = true;

        std::optional<Point> via;
        if (!TurningPoint(at, buddy.waypoint, area, ground, via))
            return false;
        buddy.lured = false;
        if (!via && !mobs.empty())
        {
            Point lure;
            if (LurePoint(at, buddy.waypoint, mobs, ground, settings, lure))
            {
                via = lure;
                buddy.lured = true;
                buddy.lurePoint = lure;
            }
        }
        if (via)
        {
            std::vector<Point> leg1 = PlanPath(at, *via, buddy.body, ground, settings);
            std::vector<Point> leg2 = PlanPath(*via, buddy.waypoint, buddy.body, ground, settings);
            if (leg1.empty() || leg2.empty())
                return false;
            leg1.insert(leg1.end(), leg2.begin() + 1, leg2.end());
            buddy.path = std::move(leg1);
        }
        else
        {
            buddy.path = PlanPath(at, buddy.waypoint, buddy.body, ground, settings);
            if (buddy.path.empty())
                return false;
        }
        buddy.pathIndex = 1;
        return true;
    }
    return false;
}

std::vector<Point> PlanPath(Point const& from, Point const& to, float body, Ground const& ground, Settings const& settings)
{
    double len = std::sqrt(double(to.x - from.x) * (to.x - from.x) + double(to.y - from.y) * (to.y - from.y));
    if (len < 1e-6)
        return { from, to };
    double ux = (double(to.x) - from.x) / len, uy = (double(to.y) - from.y) / len;

    std::optional<std::vector<Sample>> chosen;
    double chosenCost = 0.0;
    for (double bow : BOWS)
    {
        Curve c{ from.x, from.y, from.z, len, ux, uy, -uy, ux, bow, body, {} };
        bool ok = true;
        for (int round = 0; round <= settings.maxDetours; ++round)
        {
            auto step = FirstStep(ground, SampleCurve(ground, c, 0.0, len), settings);
            if (!step)
                break;
            if (int32_t(c.detours.size()) >= settings.maxDetours || !AddDetour(ground, c, step->first, step->second, settings))
            {
                ok = false;
                break;
            }
        }
        std::vector<Sample> pts = SampleCurve(ground, c, 0.0, len);
        if (ok && FirstStep(ground, pts, settings))
            ok = false;
        if (!ok)
            continue;
        double cost = PathCost(pts, settings);
        if (!chosen || cost < chosenCost)
        {
            chosen = std::move(pts);
            chosenCost = cost;
        }
    }
    std::vector<Point> out;
    if (!chosen)
        return out;
    out.reserve(chosen->size());
    for (Sample const& p : *chosen)
        out.push_back({ float(p.x), float(p.y), float(p.h) });
    return out;
}

float RestChance(float health, float maxHealth)
{
    return (1.0f - health / maxHealth) / 2.0f;
}

}
