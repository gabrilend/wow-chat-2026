/*
 * buddy_route_core.h - a buddy's way to its owner across maps as a route
 * search over every way (issue 617e8): walking, boats, zeppelins, portals
 * and a mage's own teleports, the quickest route taken. Plain arithmetic,
 * no server, so scripts/test-buddy-route checks it alone with the system
 * compiler; the server's crossing (buddies_crossing.cpp) is to give it the
 * ways it knows (the transports' routes and their next sailings, the
 * portals, the teleports the buddy knows and has a rune for) and carry out
 * the first leg of its answer.
 *
 * For a general audience, the owner, 2026-10-28: "They should build a
 * route, as they would with any path finding task, and one of the paths
 * that route might take us through their teleportation spells." And
 * 2026-10-30, of a buddy finding its owner's dock: "route search. Same
 * machinery." So a mage teleports only when that is the quickest way, not
 * whenever it can; a buddy aboard a ship gets off at the stop from which
 * the owner is reached soonest, not simply the one nearest the owner.
 *
 * The pieces:
 *   Place     a spot on a map (a dock, a portal's mouth, where it lands,
 *             the buddy, the owner)
 *   Link      one way between two places: a sailing (the wait for it and
 *             the ride), a portal (stepped through), a teleport (cast from
 *             anywhere)
 *   Route     the cheapest chain of legs, walking between any two places
 *             on the same map, by Dijkstra over the places the links name
 *   BestStop  for a buddy aboard: of the ship's stops ahead, the one from
 *             which the whole way to the owner ends soonest
 * Times are seconds. Walking is the straight line at run speed with a
 * detour allowance; the real walk is the mesh's (617o), not this file's.
 */

#ifndef BUDDY_ROUTE_CORE_H
#define BUDDY_ROUTE_CORE_H

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>
#include <vector>

namespace BuddyRoute
{
    // {{{ the numbers
    // RUN:     a character's run speed, yards a second
    // DETOUR:  how much longer a real walk is than the straight line
    // PREFER:  a way the owner itself took (the crossing record) counts
    //          this share of its time, so it wins ties and near-ties ("Same
    //          ship as the owner, when possible")
    constexpr double RUN    = 7.0;
    constexpr double DETOUR = 1.3;
    constexpr double PREFER = 0.9;
    // }}}

    // {{{ Place, Link
    struct Place { uint32_t map = 0; double x = 0, y = 0; };

    enum class Kind : uint8_t { Walk, Sail, Portal, Teleport };

    // One way: from `from` to `to`, taking `wait` (until the next sailing;
    // 0 for a portal) and then `seconds` (the ride, stepping through, a
    // teleport's cast). A teleport has no `from`: it is cast where the buddy
    // stands (`anywhere`). `owners`: the way the owner itself took.
    struct Link
    {
        Kind     kind = Kind::Sail;
        Place    from, to;
        double   wait = 0, seconds = 0;
        bool     anywhere = false;
        bool     owners = false;
        uint32_t id = 0;   // the caller's own (the transport's entry, the area trigger, the spell)
    };
    // }}}

    // {{{ Walk
    // Seconds to walk between two places: the straight line at RUN, times
    // DETOUR; on different maps, no walk (infinity).
    inline double Walk(Place const& a, Place const& b)
    {
        if (a.map != b.map) return std::numeric_limits<double>::infinity();
        return std::hypot(a.x - b.x, a.y - b.y) / RUN * DETOUR;
    }
    // }}}

    // {{{ Route
    // One leg of a route: walking (link -1) or a link (its index), from and
    // to, and its time.
    struct Leg { Kind kind; int link; Place from, to; double seconds; };
    struct Route { bool found = false; double seconds = 0; std::vector<Leg> legs; };

    inline double LinkSeconds(Link const& l) { return (l.wait + l.seconds) * (l.owners ? PREFER : 1.0); }

    // The quickest way from `start` to `goal` over `links`, walking between
    // any two places on one map. Places: the start, the goal, and each
    // link's ends (a teleport's landing only). A teleport may be cast from
    // any place reached. Not found: no chain of ways reaches the goal's map.
    // The route's time counts a preferred link at its own full time (the
    // preference only chooses).
    inline Route Find(Place const& start, Place const& goal, std::vector<Link> const& links)
    {
        // the places: 0 start, 1 goal, then each link's from (2 + 2i) and to
        // (3 + 2i); a teleport's unused `from` is a place like any other,
        // which a straight walk never gains by passing through
        size_t n = 2 + 2 * links.size();
        auto at = [&](size_t v) -> Place const& {
            if (v == 0) return start;
            if (v == 1) return goal;
            Link const& l = links[(v - 2) / 2];
            return (v - 2) % 2 == 0 ? l.from : l.to;
        };
        double const INF = std::numeric_limits<double>::infinity();
        std::vector<double> best(n, INF);
        std::vector<int> prev(n, -1), via(n, -2);   // via: -1 walked, else the link
        std::vector<bool> done(n, false);
        best[0] = 0;
        for (;;)
        {
            size_t u = n;
            for (size_t v = 0; v < n; ++v)
                if (!done[v] && best[v] < INF && (u == n || best[v] < best[u])) u = v;
            if (u == n || u == 1) break;
            done[u] = true;
            // walking to every place on the same map
            for (size_t v = 0; v < n; ++v)
                if (!done[v] && v != u)
                {
                    double t = best[u] + Walk(at(u), at(v));
                    if (t < best[v]) { best[v] = t; prev[v] = int(u); via[v] = -1; }
                }
            // a link whose start is here, and every teleport from anywhere
            for (size_t i = 0; i < links.size(); ++i)
            {
                Link const& l = links[i];
                bool here = l.anywhere || u == 2 + 2 * i;
                if (!here) continue;
                size_t v = 3 + 2 * i;
                double t = best[u] + LinkSeconds(l);
                if (t < best[v]) { best[v] = t; prev[v] = int(u); via[v] = int(i); }
            }
        }
        Route r;
        if (best[1] == INF) return r;
        r.found = true;
        for (int v = 1; v != 0; v = prev[v])
        {
            int u = prev[v];
            Leg leg;
            leg.link = via[v];
            leg.kind = via[v] < 0 ? Kind::Walk : links[via[v]].kind;
            leg.from = at(size_t(u));
            leg.to = at(size_t(v));
            leg.seconds = via[v] < 0 ? Walk(leg.from, leg.to) : links[via[v]].wait + links[via[v]].seconds;
            r.legs.insert(r.legs.begin(), leg);
        }
        for (Leg const& leg : r.legs) r.seconds += leg.seconds;
        return r;
    }
    // }}}

    // {{{ BestStop
    // A buddy aboard a ship (617e8's "ride it round"): the ship's stops
    // ahead, each with the seconds until it docks there, and the ways from
    // there. The stop from which the owner is reached soonest (its docking
    // plus the route from it); staying aboard to a later stop is just
    // another stop in the list. -1: no stop ahead reaches the owner.
    struct Stop { Place at; double arrives = 0; };
    inline int BestStop(std::vector<Stop> const& ahead, Place const& goal, std::vector<Link> const& links, double* seconds = nullptr)
    {
        int best = -1;
        double bestT = std::numeric_limits<double>::infinity();
        for (size_t i = 0; i < ahead.size(); ++i)
        {
            Route r = Find(ahead[i].at, goal, links);
            if (r.found && ahead[i].arrives + r.seconds < bestT) { bestT = ahead[i].arrives + r.seconds; best = int(i); }
        }
        if (seconds) *seconds = bestT;
        return best;
    }
    // }}}
}

#endif
