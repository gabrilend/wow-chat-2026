// follow-check.cpp - checks the following core (roam/buddy_follow_core.h)
// against the owner's design, with no server (issue 617e13). Built and run
// by scripts/test-buddy-follow-core. Each check prints "ok" or "FAIL" and
// what it held; the exit status is the number of failures (0: all held).

#include "buddy_follow_core.h"
#include <algorithm>
#include <cstdio>
#include <set>
#include <numeric>

using namespace BuddyFollow;

static int failures = 0, checks = 0;

// {{{ check
static void check(bool ok, char const* what)
{
    ++checks;
    if (!ok)
        ++failures;
    std::printf("%s %s\n", ok ? "ok  " : "FAIL", what);
}
// }}}

static bool near(float a, float b, float eps = 0.01f) { return std::fabs(a - b) <= eps; }

int main()
{
    Settings s;

    // {{{ the owner's table of offsets
    check(Offsets(1) == std::vector<float>{ -1.0f },                       "one follower: a yard to the side");
    check(Offsets(2) == std::vector<float>{ -1.0f, 1.0f },                 "two: opposite sides, the same distance");
    check(Offsets(3) == std::vector<float>{ -1.0f, 0.0f, 1.0f },           "three: one walks on the line");
    check(Offsets(4) == std::vector<float>{ -1.0f, -0.5f, 0.5f, 1.0f },    "four: halfway between the line and a yard");
    {
        std::vector<float> seven = Offsets(7);
        bool ok = seven.size() == 7 && near(seven.front(), -1.0f) && near(seven.back(), 1.0f) && near(seven[3], 0.0f);
        for (size_t k = 1; ok && k < seven.size(); ++k)
            ok = seven[k] > seven[k - 1];
        check(ok, "seven: evenly from one side to the other, the middle on the line");
    }
    // }}}

    // {{{ a straight trail: the owner walked east along y = 0, now at (20, 0)
    Trail straight;
    for (int x = 0; x <= 20; ++x)
        straight.Add({ float(x), 0.0f, 0.0f }, s);
    check(straight.points.size() == 11, "the trail keeps a point every 2 yards (11 over 20 yards)");
    Point owner{ 20.0f, 0.0f, 0.0f };
    {
        std::vector<Place> p = Places(straight, owner, 0.0f, 3, s);
        // right of east is south (y < 0), left is north
        check(near(p[0].at.x, 19.0f) && near(p[0].at.y, -1.0f), "three: the right one a yard back, a yard to the right");
        check(near(p[1].at.x, 18.0f) && near(p[1].at.y,  0.0f), "three: the middle one two yards back, on the line");
        check(near(p[2].at.x, 19.0f) && near(p[2].at.y,  1.0f), "three: the left one a yard back, a yard to the left");
        bool facing = true;
        for (Place const& q : p)
            facing = facing && near(q.facing, std::atan2(owner.y - q.at.y, owner.x - q.at.x));
        check(facing, "every place faces the owner");
        std::vector<Place> four = Places(straight, owner, 0.0f, 4, s);
        check(near(four[1].at.x, 18.5f) && near(four[1].at.y, -0.5f), "four: the half-yard places a yard and a half back");
        bool within = true;
        for (Place const& q : four)
        {
            float back = owner.x - q.at.x;
            within = within && back >= 1.0f - 0.01f && back <= 2.0f + 0.01f && std::fabs(q.at.y) <= 1.0f + 0.01f;
        }
        check(within, "every place is 1 to 2 yards behind and within a yard of the trail");
    }
    // }}}

    // {{{ more than five: layered arcs, 3 then 2 then 2 (the owner, 2026-10-30)
    {
        std::vector<ArcSpot> a5 = ArcSpots(5, s);
        bool table = a5.size() == 5;
        for (size_t k = 0; table && k < a5.size(); ++k)
            table = near(a5[k].lateral, Offsets(5)[k]) && near(a5[k].extraBack, 0.0f);
        check(table, "five or fewer: one arc, the owner's table, nobody farther back");

        std::vector<ArcSpot> a7 = ArcSpots(7, s);
        int front = 0, second = 0, third = 0;
        for (ArcSpot const& q : a7)
        {
            front  += near(q.extraBack, 0.0f);
            second += near(q.extraBack, s.layerStep);
            third  += near(q.extraBack, 2.0f * s.layerStep);
        }
        check(a7.size() == 7 && front == 3 && second == 2 && third == 2, "seven: three in the front arc, two behind, two behind them");
        check(near(a7[3].lateral, -0.5f) && near(a7[4].lateral, 0.5f), "seven: the second arc stands in the front arc's gaps (-0.5, +0.5)");

        std::vector<ArcSpot> a10 = ArcSpots(10, s);
        check(a10.size() == 10 && near(a10.back().extraBack, 4.0f * s.layerStep), "ten: the last size (two) repeats, a fourth and fifth arc behind");

        std::vector<Place> p7 = Places(straight, owner, 0.0f, 7, s);
        float closest = 1e9f;
        bool behind = true, halfCircle = true;
        for (size_t i = 0; i < p7.size(); ++i)
        {
            behind     = behind && p7[i].at.x < owner.x;
            halfCircle = halfCircle && std::fabs(p7[i].at.y) <= s.side + 0.01f;
            for (size_t j = i + 1; j < p7.size(); ++j)
                closest = std::min(closest, std::hypot(p7[i].at.x - p7[j].at.x, p7[i].at.y - p7[j].at.y));
        }
        check(behind && halfCircle, "seven: every place behind the owner, none wider than the half circle's yard");
        check(closest >= 0.9f, "seven: no two places closer than a body (0.9 yards)");
    }
    // }}}

    // {{{ a bend: east to (10, 0), then north to (10, 10); the owner at (10, 10)
    {
        Trail bend;
        for (int x = 0; x <= 10; ++x) bend.Add({ float(x), 0.0f, 0.0f }, s);
        for (int y = 1; y <= 10; ++y) bend.Add({ 10.0f, float(y), 0.0f }, s);
        Point o{ 10.0f, 10.0f, 0.0f };
        std::vector<Place> p = Places(bend, o, float(M_PI) / 2.0f, 3, s);
        // walking north, right is east (x > 10)
        check(near(p[1].at.x, 10.0f) && near(p[1].at.y, 8.0f), "on a bend: the middle place is on the trail, 2 yards back");
        check(near(p[0].at.x, 11.0f) && near(p[0].at.y, 9.0f), "on a bend: the sides are square to the trail where it is");
        // the owner just past the corner: 1 yard north of it, so 2 yards
        // back lands on the eastward leg
        Trail corner;
        for (int x = 0; x <= 10; ++x) corner.Add({ float(x), 0.0f, 0.0f }, s);
        Point o2{ 10.0f, 1.0f, 0.0f };
        Place mid = PlaceFor(corner, o2, float(M_PI) / 2.0f, 0.0f, s);
        check(near(mid.at.x, 9.0f) && near(mid.at.y, 0.0f), "round a corner: back is measured along the trail, not straight");
    }
    // }}}

    // {{{ no trail yet: behind is opposite the owner's facing
    {
        Trail none;
        Place p = PlaceFor(none, { 5.0f, 5.0f, 0.0f }, 0.0f, 0.0f, s);
        check(near(p.at.x, 3.0f) && near(p.at.y, 5.0f), "with no trail, behind is opposite the way the owner faces");
    }
    // }}}

    // {{{ a teleport starts a new trail
    {
        Trail t;
        for (int x = 0; x <= 10; ++x) t.Add({ float(x), 0.0f, 0.0f }, s);
        t.Add({ 500.0f, 500.0f, 0.0f }, s);
        check(t.points.size() == 1, "a jump of more than 40 yards starts the trail again (the way between was never walked)");
        Trail longer;
        for (int x = 0; x <= 1000; ++x) longer.Add({ float(x), 0.0f, 0.0f }, s);
        check(longer.points.size() == s.trailKeep, "the trail keeps its last 150 points");
    }
    // }}}

    // {{{ who takes which place: nobody crosses
    {
        std::vector<Place> p = Places(straight, owner, 0.0f, 3, s);
        // followers standing south, middle, north of the trail, far back
        std::vector<Point> f = { { 5.0f, 4.0f, 0.0f }, { 5.0f, -4.0f, 0.0f }, { 4.0f, 0.0f, 0.0f } };
        std::vector<int> a = Assign(f, p);
        check(a[0] == 2 && a[1] == 0 && a[2] == 1, "the one to the north takes the north place, the south one the south");
        // brute force: the choice is the cheapest of all six orders
        std::vector<int> order = { 0, 1, 2 };
        float best = 1e30f;
        do {
            float sum = 0.0f;
            for (int k = 0; k < 3; ++k) sum += std::hypot(f[k].x - p[order[k]].at.x, f[k].y - p[order[k]].at.y);
            best = std::min(best, sum);
        } while (std::next_permutation(order.begin(), order.end()));
        float got = 0.0f;
        for (int k = 0; k < 3; ++k) got += std::hypot(f[k].x - p[a[k]].at.x, f[k].y - p[a[k]].at.y);
        check(near(got, best, 0.001f), "and it walks no farther in all than the best of every order");
    }
    // }}}

    // {{{ rest or follow
    {
        Place place{ { 18.0f, 0.0f, 0.0f }, 0.0f };
        State st;
        Decision d = Decide(st, { 0.0f, 0.0f, 0.0f }, owner, place, 0, 0.5, 0.5, s);
        check(d.act == Act::Walk && st.mode == Mode::Follow, "a new follower walks to its place");
        d = Decide(st, { 17.5f, 0.0f, 0.0f }, owner, place, 1000, 0.5, 0.5, s);
        check(d.act == Act::Face && st.mode == Mode::Rest, "within a yard of its place it rests, facing the owner");
        Point moved{ 27.0f, 0.0f, 0.0f };          // 9.5 yards from the follower
        Place newPlace{ { 25.0f, 0.0f, 0.0f }, 0.0f };
        d = Decide(st, { 17.5f, 0.0f, 0.0f }, moved, newPlace, 2000, 0.5, 0.5, s);
        check(st.mode == Mode::Rest && d.act == Act::Nothing, "the owner 9.5 yards off: still at rest");
        Point far{ 28.0f, 0.0f, 0.0f };            // 10.5 yards
        d = Decide(st, { 17.5f, 0.0f, 0.0f }, far, newPlace, 3000, 0.5, 0.5, s);
        check(st.mode == Mode::Follow && d.act == Act::Walk, "the owner past 10 yards: it follows again");

        // at rest, many looks: about one in ten mingles, each within 3 yards of its place
        State rest;
        rest.mode = Mode::Rest;
        int mingles = 0, looks = 0;
        bool close = true;
        uint32_t seed = 12345;
        for (int k = 0; k < 10000; ++k)
        {
            seed = seed * 1103515245u + 12345u;
            double roll  = double(seed % 1000000u) / 1000000.0;
            seed = seed * 1103515245u + 12345u;
            double angle = double(seed % 1000000u) / 1000000.0;
            Decision r = Decide(rest, { 18.0f, 0.0f, 0.0f }, owner, place, uint64_t(k) * s.mingleEvery, roll, angle, s);
            if (r.act == Act::Mingle)
            {
                ++mingles;
                close = close && std::hypot(r.to.x - place.at.x, r.to.y - place.at.y) <= s.mingleYards + 0.01f;
            }
            if (r.act == Act::Mingle || r.act == Act::Face)
                ++looks;
        }
        char line[160];
        std::snprintf(line, sizeof line, "at rest, %d of %d looks mingled (about one in ten)", mingles, looks);
        check(looks == 10000 && mingles > 850 && mingles < 1150, line);
        check(close, "every mingle stays within 3 yards of its place");
        State early;
        early.mode = Mode::Rest;
        early.nextLookMs = 5000;
        check(Decide(early, { 18.0f, 0.0f, 0.0f }, owner, place, 4000, 0.0, 0.0, s).act == Act::Nothing,
              "between looks nothing new happens");
    }
    // }}}

    // {{{ single file
    {
        std::vector<Place> col = ColumnPlaces(straight, owner, 0.0f, 3, s);
        check(near(col[0].at.x, 18.0f) && near(col[1].at.x, 15.5f) && near(col[2].at.x, 13.0f)
              && near(col[0].at.y, 0.0f) && near(col[2].at.y, 0.0f), "single file: on the track, 2 yards behind, then every 2.5");
        Trail bend;
        for (int x = 0; x <= 10; ++x) bend.Add({ float(x), 0.0f, 0.0f }, s);
        for (int y = 1; y <= 4; ++y) bend.Add({ 10.0f, float(y), 0.0f }, s);
        std::vector<Place> round = ColumnPlaces(bend, { 10.0f, 4.0f, 0.0f }, float(M_PI) / 2.0f, 3, s);
        check(near(round[0].at.x, 10.0f) && near(round[0].at.y, 2.0f) && near(round[2].at.x, 7.0f) && near(round[2].at.y, 0.0f),
              "single file round a corner: the column bends with the track");
    }
    // }}}

    // {{{ the order's words
    {
        std::string name;
        bool hard = true;
        check(ReadOrder("follow me", name, hard) == Order::Follow && name.empty() && !hard, "\"follow me\": follow the speaker");
        check(ReadOrder("Follow Zugsqonuw please.", name, hard) == Order::Follow && name == "zugsqonuw", "\"follow <name>\": follow that one, any case, a please dropped");
        check(ReadOrder("follow", name, hard) == Order::None, "a bare \"follow\" means nothing");
        check(ReadOrder("go away", name, hard) == Order::GoAway && !hard, "\"go away\": back to their own business");
        check(ReadOrder("GO AWAY!", name, hard) == Order::GoAway && hard, "\"go away!\": and not again until the speaker logs out");
        check(ReadOrder("shoo!", name, hard) == Order::GoAway && !hard, "\"shoo\" sends them off, never the hard way");
        check(ReadOrder("follow the road home", name, hard) == Order::None, "ordinary chat with \"follow\" in it is no order");
        check(ReadOrder("Circle me!", name, hard) == Order::Circle, "\"circle me\": the close follow (617s2)");
        check(ReadOrder("close follow please", name, hard) == Order::Circle, "\"close follow\": the close follow too");
        check(ReadOrder("Stop following me!", name, hard) == Order::GoAway && !hard, "\"stop following me\": they go, never the hard way");
        check(ReadOrder("stop", name, hard) == Order::GoAway && !hard, "\"stop\" alone: they go");
        check(ReadOrder("stop the cart", name, hard) == Order::None, "\"stop\" in ordinary chat is no order");
    }
    // }}}

    // {{{ the ring (617s2, 617s3)
    {
        Point owner{ 100.0f, 100.0f, 0.0f };
        Settings rs;
        float r = rs.ringYards;
        for (int i = 0; i < 6; ++i) r = RingRadius(r, true, rs);
        check(rs.ringYards == 5.0f && r == 25.0f, "\".buddy wider\" steps out from 5 and stops at 25");
        check(RingRadius(20.0f, false, rs) == 5.0f, "\".buddy closer\" goes back to 5 at once");
        std::vector<Place> ring = RingPlaces(owner, 0.0f, 4, 4.0f);
        bool even = ring.size() == 4;
        for (Place const& p : ring)
            even = even && std::fabs(std::sqrt((p.at.x - 100.0f) * (p.at.x - 100.0f) + (p.at.y - 100.0f) * (p.at.y - 100.0f)) - 4.0f) < 0.01f;
        check(even, "the ring: four places, each four yards from the owner");
        check(std::fabs(ring[0].at.x - 104.0f) < 0.01f && std::fabs(ring[0].at.y - 100.0f) < 0.01f, "the first place is on the owner's facing (the front)");
        // four followers all standing behind the owner; the third is the tank
        std::vector<Point> at = { {95, 99, 0}, {95, 101, 0}, {94, 100, 0}, {96, 100, 0} };
        std::vector<int> spot = AssignRing(at, ring, 2);
        check(spot[2] == 0, "the tank takes the front place, wherever it stands");
        std::set<int> used(spot.begin(), spot.end());
        check(used.size() == 4 && !used.count(-1), "every follower gets its own place");
        std::vector<int> noTank = AssignRing(at, ring, -1);
        check(std::set<int>(noTank.begin(), noTank.end()).size() == 4, "with no tank the places are shared all the same");
    }
    // }}}

    std::printf("%d checks, %d failed\n", checks, failures);
    return failures;
}
