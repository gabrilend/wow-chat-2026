/*
 * buddy_roam_core.cpp - where a roaming buddy goes next, and how it walks
 * there (issue 617e2).
 *
 * For a general audience: this is the roaming model the owner shaped with
 * the animations (src/lua-basic/lib/buddy-roam.lua, its "waypoints"
 * reading with the owner's settings), written again in C++ so the server
 * can run it. A buddy circles the area's centre by waypoints: each one a
 * steady turn further round, at a distance out that wanders a little in or
 * out each time. The way to each waypoint is planned by testing the ground
 * every body width along the line and bending round anything that sticks
 * up. The world is only reached through the Ground questions of the header,
 * so a test can hold this file to the Lua model's answers on the drawn map
 * (scripts/test-buddy-roam-core).
 *
 * Numbers are worked in double precision, as the Lua model does, so the two
 * agree to far below a yard; only the results handed back are floats.
 *
 * Not yet here (noted in 617e2): the planner's preference for roads (the
 * model weighs a yard of road at 0.6); the server has no road data yet.
 */

#include "buddy_roam_core.h"

#include <algorithm>
#include <cmath>
#include <optional>
#include <utility>

namespace BuddyRoam
{

namespace
{

// {{{ constants
// Fixed parts of the design, kept here rather than in Settings because they
// are shapes of the method, not knobs (the Lua model holds them the same way).
constexpr double PI          = 3.14159265358979323846;
constexpr int    TURN_TRIES  = 12;   // bearings tried before giving up on a waypoint
constexpr int    SHARE_TRIES = 8;    // first waypoint: random distances tried per bearing
constexpr int    SLIDE_TRIES = 199;  // later waypoints: 1% slides tried (nearer, farther, ...)
constexpr double BOWS[]      = { 0.0, -0.15, 0.15, -0.3, 0.3 }; // bow height, share of the trip
constexpr float  LURE_MARGIN = 1.5f; // yards a lure point keeps clear (the model's walking margin)
// }}}

// {{{ planner types
// A detour: over the stretch [s0, s1] of the line the path stands `amp`
// yards off to `side` (+1 left, -1 right), easing out and back over `ramp`.
struct Detour
{
    double s0, s1, side, amp, ramp;
};

// One candidate path: the straight line from a to b (unit direction u,
// its normal n), bowed by `bow` of its length, plus its detours.
struct Curve
{
    double ax, ay, az, len, ux, uy, nx, ny, bow, body;
    std::vector<Detour> detours;
};

// A test point: `s` yards along the line; h the ground under the centre
// (what the slope cost reads), top the highest of centre and shoulders
// (what the obstacle test reads).
struct Sample
{
    double s, x, y, h, top;
};
// }}}

// {{{ CurvePoint
// Where on the path, `s` yards along the straight line: the line pushed
// sideways by the bow (k x length x sin(pi s / length)) and every detour
// (half-cosine ease out, the full bulge past the obstacle, ease back).
void CurvePoint(Curve const& c, double s, double& x, double& y)
{
    double off = c.bow * c.len * std::sin(PI * s / c.len);
    for (Detour const& d : c.detours)
    {
        double u;
        if (s < d.s0 - d.ramp || s > d.s1 + d.ramp)
            u = 0.0;                                            // outside the detour
        else if (s < d.s0)
            u = (1.0 - std::cos(PI * (s - d.s0 + d.ramp) / d.ramp)) / 2.0;  // easing out
        else if (s > d.s1)
            u = (1.0 - std::cos(PI * (d.s1 + d.ramp - s) / d.ramp)) / 2.0;  // easing back
        else
            u = 1.0;                                            // alongside the obstacle
        off = off + d.side * d.amp * u;
    }
    x = c.ax + c.ux * s + c.nx * off;
    y = c.ay + c.uy * s + c.ny * off;
}
// }}}

// {{{ SampleCurve
// The test points from `from` to `to` yards along the line, one per body
// width (the owner's "imaginary waypoints [...] based on the character's
// size"). Shoulders are half a body width either side across the path's
// own direction, so a wide body keeps them off a rock the centre line
// would just miss. Heights are asked from just above the last point read
// (the start's height for the first), so a bridge overhead is not taken
// for the ground.
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
            // at the very end of the line: the line's own direction
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
// }}}

// {{{ FirstStep
// The first obstacle along the test points: a height change between two
// neighbours that stands out from the changes either side by more than
// stepRise (a slope changes by about the same each step, so it never
// stands out; a crate's edge does), or a point outside the area's walls.
// Returns the stretch it covers: from the step up to the step back down
// (or to the last point, when it never comes back down), or nothing when
// the way is clear.
std::optional<std::pair<double, double>> FirstStep(Ground const& ground, std::vector<Sample> const& pts, Settings const& settings)
{
    size_t n = pts.size();
    std::vector<double> d(n, 0.0);                              // d[i]: rise from point i-1 to i (i >= 1)
    for (size_t i = 1; i < n; ++i)
        d[i] = pts[i].top - pts[i - 1].top;

    // a change's neighbours: the one before if there is one, else the one
    // after (and the other way round), as the Lua model reads them
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
            return std::make_pair(pts[i - 1].s, pts[i].s);     // through the area's wall
        if (sharp(i))
        {
            // the obstacle runs until a sharp change the other way
            for (size_t j = i + 1; j < n; ++j)
                if (sharp(j) && d[j] * d[i] < 0.0)
                    return std::make_pair(pts[i - 1].s, pts[j].s);
            return std::make_pair(pts[i - 1].s, pts[n - 1].s);
        }
    }
    return std::nullopt;
}
// }}}

// {{{ PathCost
// Walking cost of the test points: each stretch's length, raised by its
// grade squared (steep up or down both cost: "the gentlest path down a
// slope, or the flattest path up a hill"). Roads would lower it (not yet).
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
// }}}

// {{{ AddDetour
// Clear the obstacle on [s0, s1]: for each side, bulge out one body width
// at a time until the test points from the ease-in to the ease-out show no
// step, and keep the side whose whole path costs less (the left one on a
// tie). False when neither side clears within maxBulge yards: this
// candidate is given up, another bow may still get through.
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
// }}}

// {{{ StepY
// The owner's Y rule: from the last percent, add or take away (even odds)
// a whole number from yChangeMin to yChangeMax, kept within 1..100. Returns
// the new share of the way out (percent / 100). Draws two random numbers:
// the size first, then the direction (the Lua model's order).
double StepY(int32_t percent, Settings const& settings, Rng const& rng)
{
    int32_t change = settings.yChangeMin + int32_t(std::floor(rng() * double(settings.yChangeMax - settings.yChangeMin + 1)));
    int32_t sign   = rng() < 0.5 ? -1 : 1;
    int32_t next   = std::max(1, std::min(100, percent + sign * change));
    return double(next) / 100.0;
}
// }}}

// {{{ FindOpening
// Side tunnels: look up to half a turn either side of the bearing, a
// degree at a time; where the line from the centre runs openingYards or
// more beyond this bearing's, that is an opening (a tunnel's mouth, a
// doorway), and this one waypoint takes the middle of the longest run of
// such degrees. Half a turn either side covers the whole gap between a
// buddy's bearings, so every lap passes every opening once. The pinwheel's
// own bearing is not changed (the caller keeps it).
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
// }}}

// {{{ TurningPoint
// A buddy in a side tunnel can't walk straight to a waypoint round the
// corner. Every waypoint is placed on a line from the centre that stops at
// the first wall, so every waypoint is in sight of the centre, and so is
// every point a buddy walks through on the way to one. So: when the
// straight way is walled, walk toward the centre a yard at a time until
// the waypoint comes into view, and turn there.
// Returns true with `via` empty when the way is clear, true with `via` set
// when a turning point is needed, false when the buddy can't even see the
// centre (it has left the lines it should walk; the caller logs it).
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
    return false;                                               // not even the centre sees it
}
// }}}

// {{{ LurePoint
// The monster nudge (2026-09-27, the owner: "move the tangent line between
// them and the mob's aggro radius somewhere interior to the radius [...]
// ensuring that the monsters will notice and attack"). Along the straight
// line from the buddy to its waypoint, the first monster (smallest share of
// the way along, the first listed on a tie) whose aggro radius the line
// misses by more than nothing and at most lureReach yards gets the trip
// bent through a point lureDepth of its radius out from it, toward the
// line's nearest point: a straight walker then passes inside the radius.
// The point must be a clear place to stand (LURE_MARGIN, as the model keeps
// a walker off rocks) in sight of both ends; else that monster is passed
// over. A line through the radius already brings the monster, so needs no
// bend. Returns true with `lure` set when a point is found.
bool LurePoint(Point const& at, Point const& wp, std::vector<Mob> const& mobs, Ground const& ground,
               Settings const& settings, Point& lure)
{
    double vx = double(wp.x) - at.x, vy = double(wp.y) - at.y;
    double len2 = vx * vx + vy * vy;
    if (len2 < 1e-9)
        return false;                                           // no trip to bend
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
            continue;                                           // already inside, too far off the line, or not first
        Point p;
        p.x = float(m.at.x + ux / ul * m.aggro * settings.lureDepth);
        p.y = float(m.at.y + uy / ul * m.aggro * settings.lureDepth);
        p.z = ground.height(p.x, p.y, at.z);
        if (!ground.clear(p.x, p.y, p.z, LURE_MARGIN) || !ground.seenThrough(at, p) || !ground.seenThrough(p, wp))
            continue;                                           // no place to stand there, or walled off: pass it over
        lure = p;
        bestT = t;
        found = true;
    }
    return found;
}
// }}}

} // namespace

// {{{ Begin
void Begin(Buddy& buddy, Area const& area, Point const& at, Rng const& rng)
{
    // the direction is drawn first, as the Lua model draws it
    buddy.spin        = rng() < 0.5 ? 1 : -1;
    buddy.angle       = float(std::atan2(double(at.y) - area.centre.y, double(at.x) - area.centre.x));
    buddy.yPercent    = 0;
    buddy.hasWaypoint = false;
    buddy.path.clear();
    buddy.pathIndex   = 0;
}
// }}}

// {{{ NextWaypoint
// The owner's pinwheel. For each try the bearing turns one step; the
// waypoint's bearing is that, or the middle of an opening near it. Its
// distance out:
//   first waypoint  - a random share of the way (up to SHARE_TRIES draws),
//                     the first one clear of obstacles taken;
//   later waypoints - the Y rule draws once; someone within crowdYards of
//                     that spot moves it crowdShift toward 50 (once, and
//                     the moved Y is carried on: the nudge spreads buddies
//                     out); a blocked spot slides along the bearing 1% at a
//                     time, nearer first, and only this waypoint moves: the
//                     rule's own Y stays as drawn (carrying the slid value
//                     on pushed the walk outward round a rock near the
//                     centre, measured 2026-09-27).
// After two inward rolls in a row, a Y at or under piercePercent sends the
// waypoint across the middle and reverses the buddy (see the block).
// No clear spot on a bearing turns it one more step (TURN_TRIES in all).
// Then the way there: straight, by a turning point, or bent through a
// monster's aggro radius (LurePoint), planned leg by leg.
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

        bool slide = buddy.hasWaypoint;                         // the first waypoint has no Y to step from
        double drawn = 0.0;
        if (slide)
        {
            drawn = StepY(buddy.yPercent, settings, rng);
            // piercing the middle (2026-09-27, the owner: "pierce through the
            // center and reverse their orientation [...] To make an S shape,
            // or a figure 8"): count inward rolls in a row; the second or
            // later that lands at or under piercePercent puts this waypoint
            // on the far side of the centre at the same Y and turns the buddy
            // the other way round. The count starts again after. Draws no
            // random numbers. Off when piercePercent is 0.
            if (settings.piercePercent > 0)
            {
                buddy.inward = drawn < double(buddy.yPercent) / 100.0 ? buddy.inward + 1 : 0;
                if (buddy.inward >= 2 && drawn * 100.0 <= double(settings.piercePercent) + 1e-9)
                {
                    angle       = angle + PI;
                    buddy.angle = float(angle);
                    buddy.spin  = -buddy.spin;
                    buddy.inward = 0;
                    bearing     = angle;                        // straight across: no opening pull
                    reach       = double(ground.edgeAlong(float(cx), float(cy), float(cz), float(bearing))) - settings.clearance;
                    ++buddy.pierced;
                }
            }
            // crowding: someone within crowdYards of where the drawn Y lands
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
                    continue;                                   // slid off either end of the bearing
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
            continue;                                           // this bearing is blocked: turn again

        buddy.yPercent = int32_t(std::floor((slide ? drawn : share) * 100.0 + 0.5));
        buddy.waypoint.x = float(fx);
        buddy.waypoint.y = float(fy);
        buddy.waypoint.z = ground.height(float(fx), float(fy), at.z);
        buddy.hasWaypoint = true;

        // the way there, leg by leg when a turning point is needed
        std::optional<Point> via;
        if (!TurningPoint(at, buddy.waypoint, area, ground, via))
            return false;
        // a monster near the way bends it (only a straight way: a turning
        // point already bends it)
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
        buddy.pathIndex = 1;                                    // the first point is where it stands
        return true;
    }
    return false;
}
// }}}

// {{{ PlanPath
// Every bow gets its detours, one obstacle at a time from the start toward
// the end; the cheapest bow that clears wins (the first on a tie). A trip
// of no length is just its two ends.
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
            ok = false;                                         // a detour made a new obstacle it couldn't clear
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
        return out;                                             // no bow gets through: the caller logs it
    out.reserve(chosen->size());
    for (Sample const& p : *chosen)
        out.push_back({ float(p.x), float(p.y), float(p.h) });
    return out;
}
// }}}

// {{{ RestChance
// Half the share of health missing: full health never rests, at 60% health
// one waypoint in five, near death one in two. maxHealth must be above 0
// (a living unit's always is).
float RestChance(float health, float maxHealth)
{
    return (1.0f - health / maxHealth) / 2.0f;
}
// }}}

} // namespace BuddyRoam
