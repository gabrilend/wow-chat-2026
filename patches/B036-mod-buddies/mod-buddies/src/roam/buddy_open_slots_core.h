/*
 * buddy_open_slots_core.h - the other follow mode, "nearest open slot"
 * (issue 617s8): the close follow's ring of places round the owner (617s2,
 * BuddyFollow::RingPlaces), but no buddy owns a compass place; each slot is
 * claimed by at most one buddy, and a buddy that reaches its waypoint lets
 * its claim go and claims the free slot nearest to where it stands. Plain
 * arithmetic, no server, so scripts/test-buddy-open-slots checks it alone
 * with the system compiler.
 *
 * For a general audience, the owner's words (2026-10-05): "To enable /
 * disable the NPCs following the compass, and instead moving to the
 * nearest unclaimed open waypoint each time they reach a waypoint, instead
 * of their assigned, compass based slot." One on/off switch at Chromie
 * (168): compass on (the ring's sharing, BuddyFollow::AssignRing, as
 * built) or off (this). The bot module's stock follow is not a choice.
 *
 * The rules, each path:
 *   a claim is a buddy's id against a slot's index; one buddy to a slot;
 *   the tank holds the front slot, 0, in this mode too (617s3), and a
 *     buddy holding it when a tank comes is displaced;
 *   a buddy walking to its waypoint keeps its claim (two buddies never
 *     trade claims mid-walk; 617s2: "the waypoints only move when the
 *     buddy-bot reaches one");
 *   a buddy that has reached its waypoint (within the ring's slack), or
 *     holds no claim (new, or its slot gone when the ring shrank), lets its
 *     claim go and claims the nearest free slot, measured by the caller's
 *     distance (the navigation mesh's path length in the server; a straight
 *     line by default); its waypoint is that slot's spot round where the
 *     owner is now, and stands still until reached;
 *   when several pick at once they share the free slots by least walking
 *     in all, as the arc follow's sharing does (one picker alone: simply
 *     its nearest);
 *   the owner standing still: a buddy at its waypoint finds its own slot,
 *     just let go, the nearest, so it stays (the ring is calm while the
 *     owner rests; decided 2026-11-06, open question 1).
 */

#ifndef BUDDY_OPEN_SLOTS_CORE_H
#define BUDDY_OPEN_SLOTS_CORE_H

#include "buddy_follow_core.h"
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <vector>

namespace BuddyOpenSlots
{
using BuddyRoam::Point;
using BuddyFollow::Place;
using BuddyFollow::Settings;

// {{{ Follower
// One buddy as this mode sees it. `id`, `at` and `tank` are given each
// update; `slot` and `waypoint` are kept by the server per buddy between
// updates (a new follower starts with slot -1).
struct Follower
{
    uint32_t id       = 0;        // the buddy's own (its guid's low part)
    Point    at;                  // where it stands now
    bool     tank     = false;    // the clan's tank: the front slot (617s3)
    int      slot     = -1;       // the slot it claims, -1 none
    Point    waypoint;            // where it walks: its slot's spot when claimed
};
// }}}

// {{{ Answer
// What each follower does now: walk to `to`, or stand there and turn to
// face the owner (`facing`).
struct Answer
{
    bool  walk   = false;
    Point to;
    float facing = 0.0f;
};
// }}}

// {{{ Straight
// The default distance, a straight line on the ground; the server passes
// the mesh's path length instead (617s2: slots are measured as ring follow
// walks).
inline float Straight(Point const& a, Point const& b) { return std::hypot(a.x - b.x, a.y - b.y); }
// }}}

// {{{ Share
// The pickers (indices into `fs`) share the free slots by least distance
// in all: every arrangement tried, any already longer than the best cut off
// (seven at the most, 5040 arrangements). Ties keep the first found, so
// the earlier picker in `fs` order wins an even split. A picker left
// without a slot (more pickers than free slots) gets -1.
template <class Dist>
inline void ShareSearch(std::vector<Follower> const& fs, std::vector<int> const& pickers, std::vector<int> const& free,
                        std::vector<Place> const& slots, Dist& dist, size_t k, std::vector<int>& now,
                        std::vector<bool>& taken, float sum, float& best, std::vector<int>& bestOf)
{
    if (sum >= best)
        return;
    if (k == pickers.size())
    {
        best   = sum;
        bestOf = now;
        return;
    }
    bool any = false;
    for (size_t f = 0; f < free.size(); ++f)
    {
        if (taken[f])
            continue;
        any = true;
        taken[f] = true;
        now[k]   = free[f];
        ShareSearch(fs, pickers, free, slots, dist, k + 1, now, taken,
                    sum + dist(fs[size_t(pickers[k])].at, slots[size_t(free[f])].at), best, bestOf);
        taken[f] = false;
    }
    if (!any)
    {
        now[k] = -1;
        ShareSearch(fs, pickers, free, slots, dist, k + 1, now, taken, sum, best, bestOf);
    }
}
// }}}

// {{{ Step
// One update of the mode: claims kept, let go and taken by the rules
// above, then each follower's answer. `slots` is the ring round the owner
// now (RingPlaces: one per follower present, the front on the owner's
// facing); `owner` is where the owner stands. Changes each follower's
// `slot` and `waypoint` in place.
template <class Dist>
inline std::vector<Answer> Step(std::vector<Follower>& fs, std::vector<Place> const& slots, Point const& owner,
                                Settings const& s, Dist dist)
{
    int n    = int(slots.size());
    int tank = -1;
    for (size_t i = 0; i < fs.size(); ++i)
        if (fs[i].tank && tank < 0)
            tank = int(i);

    // claims on slots the ring no longer has, and the front slot when a
    // tank is here, are let go; the tank takes the front
    for (size_t i = 0; i < fs.size(); ++i)
    {
        Follower& f = fs[i];
        if (f.slot >= n || (tank >= 0 && f.slot == 0 && int(i) != tank))
            f.slot = -1;
    }
    if (tank >= 0 && n > 0)
    {
        Follower& t = fs[size_t(tank)];
        if (t.slot != 0 || dist(t.at, t.waypoint) <= s.ringSlack)
            t.waypoint = slots[0].at;    // a new claim, or arrived: the front's spot as it is now
        t.slot = 0;
    }

    // who picks: arrived, or holding nothing
    std::vector<int> pickers;
    for (size_t i = 0; i < fs.size(); ++i)
    {
        if (int(i) == tank)
            continue;
        Follower& f = fs[i];
        if (f.slot < 0 || dist(f.at, f.waypoint) <= s.ringSlack)
        {
            f.slot = -1;
            pickers.push_back(int(i));
        }
    }

    // the free slots: held by nobody still walking
    std::vector<bool> held(size_t(std::max(n, 0)), false);
    for (Follower const& f : fs)
        if (f.slot >= 0)
            held[size_t(f.slot)] = true;
    std::vector<int> free;
    for (int k = 0; k < n; ++k)
        if (!held[size_t(k)])
            free.push_back(k);

    std::vector<int>  now(pickers.size(), -1), bestOf(pickers.size(), -1);
    std::vector<bool> taken(free.size(), false);
    float best = 1e30f;
    ShareSearch(fs, pickers, free, slots, dist, 0, now, taken, 0.0f, best, bestOf);
    for (size_t k = 0; k < pickers.size(); ++k)
    {
        Follower& f = fs[size_t(pickers[k])];
        f.slot = bestOf[k];
        if (f.slot >= 0)
            f.waypoint = slots[size_t(f.slot)].at;
    }

    // the answers
    std::vector<Answer> out(fs.size());
    for (size_t i = 0; i < fs.size(); ++i)
    {
        Follower const& f = fs[i];
        Answer& a = out[i];
        if (f.slot >= 0 && dist(f.at, f.waypoint) > s.ringSlack)
        {
            a.walk = true;
            a.to   = f.waypoint;
        }
        else
        {
            a.to     = f.at;
            a.facing = std::atan2(owner.y - f.at.y, owner.x - f.at.x);
        }
    }
    return out;
}

inline std::vector<Answer> Step(std::vector<Follower>& fs, std::vector<Place> const& slots, Point const& owner,
                                Settings const& s)
{
    return Step(fs, slots, owner, s, Straight);
}
// }}}

} // namespace BuddyOpenSlots

#endif // BUDDY_OPEN_SLOTS_CORE_H
