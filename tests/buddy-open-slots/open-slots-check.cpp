// open-slots-check.cpp - checks the "nearest open slot" follow mode
// (roam/buddy_open_slots_core.h) against issue 617s8, with no server. Built
// and run by scripts/test-buddy-open-slots. Each check prints "ok" or
// "FAIL" and what it held; the exit status is the number of failures.
//
// A small walk is played out: the owner walks, turns and stands; seven
// buddies (one a tank) step toward their waypoints a yard and a bit each
// update, and every update the claims are checked against the rules.

#include "buddy_open_slots_core.h"
#include <cstdio>
#include <set>

using namespace BuddyOpenSlots;

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

// {{{ Walk
// Each follower answered "walk" moves up to `speed` yards toward its target.
static void Walk(std::vector<Follower>& fs, std::vector<Answer> const& as, float speed)
{
    for (size_t i = 0; i < fs.size(); ++i)
    {
        if (!as[i].walk)
            continue;
        float dx = as[i].to.x - fs[i].at.x, dy = as[i].to.y - fs[i].at.y, d = std::hypot(dx, dy);
        float t  = d <= speed ? 1.0f : speed / d;
        fs[i].at.x += dx * t;
        fs[i].at.y += dy * t;
    }
}
// }}}

static bool Distinct(std::vector<Follower> const& fs)
{
    std::set<int> seen;
    for (Follower const& f : fs)
        if (f.slot >= 0 && !seen.insert(f.slot).second)
            return false;
    return true;
}

int main()
{
    Settings s;
    float const R = 5.0f;

    // {{{ a long walk with turns: one buddy to a slot, the tank in front, no trade mid-walk
    {
        std::vector<Follower> fs(7);
        for (size_t i = 0; i < fs.size(); ++i)
        {
            fs[i].id = uint32_t(100 + i);
            fs[i].at = { -3.0f + float(i), -8.0f, 0.0f };
        }
        fs[4].tank = true;
        Point owner{ 0.0f, 0.0f, 0.0f };
        float facing = 0.0f;
        bool distinct = true, tankFront = true, keptMidWalk = true, nearestOnPick = true, allClaimed = true;
        int  repicks = 0;
        for (int u = 0; u < 400; ++u)
        {
            if (u < 120)       { owner.x += 0.8f; }                                    // east
            else if (u < 200)  { facing = 1.5708f; owner.y += 0.8f; }                  // a turn north
            else if (u < 260)  { facing = 3.1416f; owner.x -= 0.8f; }                  // west
            // then stands still, facing west
            std::vector<Follower> before = fs;
            std::vector<Place> ring = BuddyFollow::RingPlaces(owner, facing, int(fs.size()), R);
            std::vector<Answer> as = Step(fs, ring, owner, s);
            distinct  = distinct && Distinct(fs);
            tankFront = tankFront && fs[4].slot == 0;
            for (size_t i = 0; i < fs.size(); ++i)
            {
                allClaimed = allClaimed && fs[i].slot >= 0;
                bool wasWalking = before[i].slot >= 0 && Straight(before[i].at, before[i].waypoint) > s.ringSlack;
                if (i != 4 && wasWalking && (fs[i].slot != before[i].slot || fs[i].waypoint.x != before[i].waypoint.x
                                              || fs[i].waypoint.y != before[i].waypoint.y))
                    keptMidWalk = false;
                if (i != 4 && !wasWalking && before[i].slot >= 0 && fs[i].slot != before[i].slot)
                    ++repicks;
            }
            // a lone picker took the nearest slot nobody else held
            int lone = -1, count = 0;
            for (size_t i = 0; i < fs.size(); ++i)
                if (i != 4 && !(before[i].slot >= 0 && Straight(before[i].at, before[i].waypoint) > s.ringSlack)) { lone = int(i); ++count; }
            if (count == 1)
            {
                std::set<int> others;
                for (size_t i = 0; i < fs.size(); ++i) if (int(i) != lone) others.insert(fs[i].slot);
                float mine = Straight(fs[size_t(lone)].at, ring[size_t(fs[size_t(lone)].slot)].at);
                for (int k = 0; k < int(ring.size()); ++k)
                    if (!others.count(k) && Straight(fs[size_t(lone)].at, ring[size_t(k)].at) < mine - 1e-4f)
                        nearestOnPick = false;
            }
            Walk(fs, as, 1.2f);
        }
        check(distinct,      "400 updates of walking and turning: never two buddies on one slot");
        check(allClaimed,    "with one slot per buddy, every buddy always holds one");
        check(tankFront,     "the tank holds the front slot throughout (617s3)");
        check(keptMidWalk,   "a buddy still walking to its waypoint keeps its claim and its waypoint");
        check(nearestOnPick, "a buddy picking alone takes the free slot nearest to where it stands");
        check(repicks > 0,   "buddies arriving while the owner walks do move on to other slots (the mode is not the compass)");

        // the owner has stood still for 140 updates: the ring is calm
        std::vector<Follower> settled = fs;
        std::vector<Place> ring = BuddyFollow::RingPlaces(owner, facing, int(fs.size()), R);
        bool calm = true, standing = true;
        for (int u = 0; u < 50; ++u)
        {
            std::vector<Answer> as = Step(fs, ring, owner, s);
            for (size_t i = 0; i < fs.size(); ++i)
            {
                calm     = calm && fs[i].slot == settled[i].slot;
                standing = standing && !as[i].walk;
            }
            Walk(fs, as, 1.2f);
        }
        check(calm,     "the owner standing still: each buddy keeps its slot (its own, just let go, is the nearest)");
        check(standing, "and nobody walks: they stand and face the owner");
        bool onRing = true;
        for (Follower const& f : fs)
            onRing = onRing && Straight(f.at, ring[size_t(f.slot)].at) <= s.ringSlack;
        check(onRing,   "every buddy stands within the ring's slack of its own slot");
    }
    // }}}

    // {{{ standing answers face the owner
    {
        std::vector<Follower> fs(1);
        fs[0].id = 1;
        Point owner{ 10.0f, 0.0f, 0.0f };
        std::vector<Place> ring = BuddyFollow::RingPlaces(owner, 0.0f, 1, R);
        fs[0].at = ring[0].at;
        std::vector<Answer> as = Step(fs, ring, owner, s);
        check(!as[0].walk && std::fabs(std::fabs(as[0].facing) - 3.1416f) < 0.01f,
              "a buddy already on its slot east of the owner stands and faces west, toward them");
    }
    // }}}

    // {{{ the first claims: pickers share by least walking in all
    {
        Point owner{ 0.0f, 0.0f, 0.0f };
        std::vector<Place> ring = BuddyFollow::RingPlaces(owner, 0.0f, 2, R);   // east (0) and west (1)
        std::vector<Follower> fs(2);
        fs[0].id = 1; fs[0].at = { -6.0f, 0.0f, 0.0f };     // west of the owner
        fs[1].id = 2; fs[1].at = {  4.0f, 0.0f, 0.0f };     // east of the owner
        Step(fs, ring, owner, s);
        check(fs[0].slot == 1 && fs[1].slot == 0, "two new buddies: each takes the slot on its own side (least walking in all)");
        check(fs[0].waypoint.x == ring[1].at.x && fs[1].waypoint.x == ring[0].at.x, "and its waypoint is that slot's spot");
    }
    // }}}

    // {{{ the tank displaces whoever holds the front
    {
        Point owner{ 0.0f, 0.0f, 0.0f };
        std::vector<Place> ring = BuddyFollow::RingPlaces(owner, 0.0f, 2, R);
        std::vector<Follower> fs(2);
        fs[0].id = 1; fs[0].at = ring[0].at; fs[0].slot = 0; fs[0].waypoint = ring[0].at;
        fs[1].id = 2; fs[1].at = { -20.0f, 0.0f, 0.0f }; fs[1].tank = true;
        std::vector<Answer> as = Step(fs, ring, owner, s);
        check(fs[1].slot == 0 && fs[0].slot == 1, "a tank arriving takes the front slot; its holder takes the free one");
        check(as[0].walk && as[1].walk, "both walk to their new slots");

        std::vector<Follower> mid(2);                                // the holder still on its way to the front
        mid[0].id = 1; mid[0].at = { -20.0f, 5.0f, 0.0f }; mid[0].slot = 0; mid[0].waypoint = ring[0].at;
        mid[1].id = 2; mid[1].at = { -20.0f, -5.0f, 0.0f }; mid[1].tank = true;
        Step(mid, ring, owner, s);
        check(mid[1].slot == 0 && mid[0].slot == 1, "the front's holder is displaced even mid-walk: the tank's place is the front");

        std::vector<Follower> two(3);                                // two tanks: the first listed holds the front
        std::vector<Place> ring3 = BuddyFollow::RingPlaces(owner, 0.0f, 3, R);
        for (int i = 0; i < 3; ++i) { two[size_t(i)].id = uint32_t(i + 1); two[size_t(i)].tank = i != 0; }
        two[0].at = ring3[0].at; two[1].at = ring3[1].at; two[2].at = ring3[2].at;
        Step(two, ring3, owner, s);
        check(two[1].slot == 0 && two[2].slot != 0 && Distinct(two),
              "two tanks: the first listed takes the front, the second picks like anyone else");
    }
    // }}}

    // {{{ the ring shrinks and grows
    {
        Point owner{ 0.0f, 0.0f, 0.0f };
        std::vector<Place> ring3 = BuddyFollow::RingPlaces(owner, 0.0f, 3, R);
        std::vector<Follower> fs(3);
        for (int i = 0; i < 3; ++i) { fs[size_t(i)].id = uint32_t(i + 1); fs[size_t(i)].at = { 30.0f, 30.0f, 0.0f }; }
        for (int i = 0; i < 3; ++i) { fs[size_t(i)].slot = i; fs[size_t(i)].waypoint = ring3[size_t(i)].at; }
        fs.erase(fs.begin());                       // buddy 1 leaves: two slots now
        std::vector<Place> ring2 = BuddyFollow::RingPlaces(owner, 0.0f, 2, R);
        Step(fs, ring2, owner, s);
        check(fs[0].slot == 1 && fs[1].slot == 0,
              "one leaves: the buddy walking to slot 1 keeps it; the one whose slot 2 is gone takes the free slot 0");
        Follower late; late.id = 9; late.at = { 0.0f, -4.0f, 0.0f };
        fs.push_back(late);
        Step(fs, ring3, owner, s);
        check(fs[2].slot == 2 && Distinct(fs), "one joins: it takes the one slot left free");
    }
    // }}}

    // {{{ the caller's distance decides: a wall between a buddy and the nearer slot
    {
        Point owner{ 0.0f, 0.0f, 0.0f };
        std::vector<Place> ring = BuddyFollow::RingPlaces(owner, 0.0f, 2, R);   // east (5, 0) and west (-5, 0)
        std::vector<Follower> open(1), walled(1);
        open[0].id = 1; open[0].at = { 1.0f, 6.0f, 0.0f };                        // 7.2 yards from east, 8.5 from west
        walled = open;
        Step(open, ring, owner, s);
        check(open[0].slot == 0, "in the open, a buddy north of the owner and a little east takes the east slot");
        auto wall = [](Point const& p, Point const& q) {      // a wall along x = 3: going round it costs 40 yards
            float d = std::hypot(p.x - q.x, p.y - q.y);
            return ((p.x < 3.0f) != (q.x < 3.0f)) ? d + 40.0f : d;
        };
        std::vector<Answer> as = Step(walled, ring, owner, s, wall);
        check(walled[0].slot == 1 && as[0].walk && as[0].to.x < 0.0f,
              "with a wall at x = 3 the mesh distance sends it to the west slot, though east is nearer in a line");
    }
    // }}}

    // {{{ no slots at all
    {
        std::vector<Follower> fs(1);
        fs[0].id = 1; fs[0].at = { 10.0f, 10.0f, 0.0f };          // far from its (unset) waypoint
        std::vector<Answer> as = Step(fs, {}, Point{}, s);
        check(fs[0].slot == -1 && !as[0].walk, "an empty ring: nobody claims anything or walks");
    }
    // }}}

    std::printf("%d of %d checks held\n", checks - failures, checks);
    return failures;
}
