// route-check.cpp - checks the route search across maps
// (roam/buddy_route_core.h) against the owner's design, with no server
// (issue 617e8). Built and run by scripts/test-buddy-route. Each check prints
// "ok" or "FAIL" and what it held; the exit status is the number of failures.
//
// The places are made up but shaped like the world: map 0 the Eastern
// Kingdoms, 1 Kalimdor, 530 Outland; a dock on each side of a sailing.

#include "buddy_route_core.h"

#include <cstdio>

using namespace BuddyRoute;

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

static bool near(double a, double b) { return std::fabs(a - b) < 1e-6; }

static Link Sail(Place from, Place to, double wait, double ride, uint32_t id = 0)
{
    Link l; l.kind = Kind::Sail; l.from = from; l.to = to; l.wait = wait; l.seconds = ride; l.id = id;
    return l;
}
static Link Teleport(Place to, double cast)
{
    Link l; l.kind = Kind::Teleport; l.to = to; l.seconds = cast; l.anywhere = true;
    return l;
}

int main()
{
    Place menethilDock{ 0, 0, 0 }, theramoreDock{ 1, 0, 0 };
    Place buddy{ 0, 70, 0 }, owner{ 1, 140, 0 };

    // {{{ walking on one map
    Route w = Find(Place{ 0, 0, 0 }, Place{ 0, 70, 0 }, {});
    check(w.found && w.legs.size() == 1 && w.legs[0].kind == Kind::Walk && near(w.seconds, 70 / RUN * DETOUR),
          "on the owner's map: one walk, 70 yards at run speed with the detour allowance (13 s)");
    check(std::isinf(Walk(menethilDock, theramoreDock)), "no walking between maps");
    // }}}

    // {{{ a boat
    std::vector<Link> boat = { Sail(menethilDock, theramoreDock, 60, 120, 176231) };
    Route b = Find(buddy, owner, boat);
    check(b.found && b.legs.size() == 3 && b.legs[0].kind == Kind::Walk && b.legs[1].kind == Kind::Sail && b.legs[2].kind == Kind::Walk,
          "the owner across the sea: walk to the dock, sail, walk to the owner");
    check(b.legs[1].link == 0 && near(b.legs[1].seconds, 180) && near(b.seconds, 70 / RUN * DETOUR + 180 + 140 / RUN * DETOUR),
          "the sailing counts its wait and its ride; the route's time is its legs'");
    check(!Find(buddy, Place{ 530, 0, 0 }, boat).found, "no way to the owner's map: not found");
    // }}}

    // {{{ the mage's own teleport: taken only when it is the quickest
    std::vector<Link> withTeleport = boat;
    withTeleport.push_back(Teleport(Place{ 1, 200, 0 }, 10));   // lands 60 yards from the owner
    Route t = Find(buddy, owner, withTeleport);
    check(t.found && t.legs.front().kind == Kind::Teleport && t.legs.size() == 2,
          "a mage whose teleport lands near the owner: it teleports from where it stands and walks the rest");
    std::vector<Link> farTeleport = boat;
    farTeleport.push_back(Teleport(Place{ 1, 3000, 0 }, 10));   // lands across the continent
    Route f = Find(buddy, owner, farTeleport);
    check(f.found && f.legs[1].kind == Kind::Sail, "a teleport landing far across the continent loses to the boat (\"not teleport whenever possible\")");
    // }}}

    // {{{ two sailings, and a portal
    Place stormwindPortal{ 0, 500, 0 }, hellfire{ 530, 0, 0 };
    Link portal; portal.kind = Kind::Portal; portal.from = stormwindPortal; portal.to = hellfire; portal.seconds = 5;
    std::vector<Link> world = { Sail(theramoreDock, menethilDock, 30, 120), portal };
    Route chain = Find(Place{ 1, 50, 0 }, Place{ 530, 20, 0 }, world);
    check(chain.found && chain.legs.size() == 5 && chain.legs[1].kind == Kind::Sail && chain.legs[3].kind == Kind::Portal,
          "Kalimdor to Outland: walk, sail to the Eastern Kingdoms, walk to the portal, step through, walk on");
    // }}}

    // {{{ the owner's own way, when about as quick
    Place otherDock{ 0, 90, 0 }, otherLanding{ 1, 150, 0 };
    std::vector<Link> two = { Sail(menethilDock, theramoreDock, 60, 120, 1), Sail(otherDock, otherLanding, 80, 120, 2) };
    Route quick = Find(buddy, owner, two);
    check(quick.legs[1].link == 1, "two boats: the quicker (nearer dock, landing by the owner)");
    two[0].owners = true;
    Route same = Find(buddy, owner, two);
    check(same.legs[1].link == 0, "the owner's own boat, nearly as quick, is taken instead (\"same ship as the owner, when possible\")");
    check(near(same.seconds, 70 / RUN * DETOUR + 180 + 140 / RUN * DETOUR), "the preferred boat's time is still counted in full");
    two[0].wait = 400;
    check(Find(buddy, owner, two).legs[1].link == 1, "the owner's boat when it is much slower: not taken");
    // }}}

    // {{{ aboard: the stop from which the owner is reached soonest
    Place nearOwner{ 1, 150, 0 }, farFromOwner{ 1, 2000, 0 };
    std::vector<Stop> ahead = { { farFromOwner, 30 }, { nearOwner, 200 } };
    double total = 0;
    int s = BestStop(ahead, owner, {}, &total);
    check(s == 1 && near(total, 200 + 10 / RUN * DETOUR), "aboard: ride on to the stop by the owner rather than walk across the continent");
    std::vector<Stop> late = { { Place{ 1, 500, 0 }, 30 }, { nearOwner, 600 } };
    check(BestStop(late, owner, {}) == 0, "but get off early and walk when the stop by the owner is ten minutes away (not merely the nearest stop)");
    std::vector<Stop> elsewhere = { { Place{ 530, 0, 0 }, 30 } };
    check(BestStop(elsewhere, owner, {}) == -1, "no stop ahead from which the owner can be reached: -1");
    // }}}

    std::printf("%d checks, %d failed\n", checks, failures);
    return failures;
}
