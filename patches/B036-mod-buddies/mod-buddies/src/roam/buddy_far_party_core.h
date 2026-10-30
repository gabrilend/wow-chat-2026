/*
 * buddy_far_party_core.h - how buddies who can't join their owner's party
 * group among themselves: by who is near whom, split evenly (issue 617c2).
 * Plain arithmetic, no server, so scripts/test-buddy-far-party checks it
 * alone with the system compiler; the server's party pass (buddies_party.cpp)
 * is to feed it positions and carry out its answer.
 *
 * For a general audience, the owner's design (2026-10-30): "if buddy-bots
 * can't join your party but totally would for some reason, they can create
 * a group amongst themselves if they are within EXP sharing range. They can
 * dynamically join and leave them according to the same rules we built for
 * players. They should try and group up together and stay within each
 * other's questing exp sharing zone. If there's for example 6 of them,
 * they should make two groups of 3 instead of one group of 1 and one group
 * of 5." And, earlier (2026-10-28): "The leader isn't too important".
 *
 * The pieces:
 *   who belongs together - buddies chained within `reach` yards of each
 *                          other (the experience-sharing range: a group's
 *                          kill shares with members within 74 yards of the
 *                          slain creature) form one cluster;
 *   how many groups      - a cluster of m makes ceil(m / 5) groups (a
 *                          party holds five);
 *   how big              - as even as can be: six make 3 and 3, seven 4
 *                          and 3, eleven 4, 4 and 3, never 5 and 1;
 *   who goes where       - members sorted around the cluster's middle by
 *                          bearing and cut into runs of those sizes, so each
 *                          group is a slice of neighbours, not a scatter;
 *   the leader           - the group's first member (any leader will do).
 */

#ifndef BUDDY_FAR_PARTY_CORE_H
#define BUDDY_FAR_PARTY_CORE_H

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <vector>

namespace BuddyFarParty
{

constexpr uint32_t PARTY_SIZE = 5;

// {{{ GroupSizes
// The sizes for m buddies: ceil(m / 5) groups, as even as can be, larger
// ones first. 0 makes none; a lone buddy is a "group" of one (the caller
// leaves it ungrouped: the server disbands a party of one).
inline std::vector<uint32_t> GroupSizes(uint32_t m)
{
    std::vector<uint32_t> sizes;
    if (m == 0)
        return sizes;
    uint32_t groups = (m + PARTY_SIZE - 1) / PARTY_SIZE;
    for (uint32_t g = 0; g < groups; ++g)
        sizes.push_back(m / groups + (g < m % groups ? 1 : 0));
    return sizes;
}
// }}}

struct Spot { float x = 0.0f, y = 0.0f; };

// {{{ Clusters
// The buddies chained within `reach` of each other: each cluster a list of
// indexes into `at`, in index order, clusters in order of their first member.
inline std::vector<std::vector<uint32_t>> Clusters(std::vector<Spot> const& at, float reach)
{
    uint32_t n = uint32_t(at.size());
    std::vector<int32_t> of(n, -1);
    std::vector<std::vector<uint32_t>> out;
    for (uint32_t s = 0; s < n; ++s)
    {
        if (of[s] >= 0)
            continue;
        int32_t id = int32_t(out.size());
        out.push_back({});
        std::vector<uint32_t> todo{ s };
        of[s] = id;
        while (!todo.empty())
        {
            uint32_t a = todo.back();
            todo.pop_back();
            out[id].push_back(a);
            for (uint32_t b = 0; b < n; ++b)
                if (of[b] < 0 && std::hypot(at[a].x - at[b].x, at[a].y - at[b].y) <= reach)
                {
                    of[b] = id;
                    todo.push_back(b);
                }
        }
        std::sort(out[id].begin(), out[id].end());
    }
    return out;
}
// }}}

// {{{ SplitWide
// A group whose members aren't all within `reach` of each other (a chain:
// each near the next, the ends farther apart) is halved along its wider
// direction, again until every group is within reach throughout ("stay
// within each other's questing exp sharing zone"). Each path:
//   every pair within reach      - kept as it is
//   one member                   - kept (nothing to split)
//   otherwise                    - sorted along x or y (whichever spreads
//                                  more), halved, each half split again
inline void SplitWide(std::vector<Spot> const& at, std::vector<uint32_t> group, float reach,
                      std::vector<std::vector<uint32_t>>& out)
{
    bool within = true;
    float x0 = 1e30f, x1 = -1e30f, y0 = 1e30f, y1 = -1e30f;
    for (uint32_t a : group)
    {
        x0 = std::min(x0, at[a].x); x1 = std::max(x1, at[a].x);
        y0 = std::min(y0, at[a].y); y1 = std::max(y1, at[a].y);
        for (uint32_t b : group)
            within = within && std::hypot(at[a].x - at[b].x, at[a].y - at[b].y) <= reach;
    }
    if (within || group.size() < 2)
    {
        out.push_back(group);
        return;
    }
    bool alongX = (x1 - x0) >= (y1 - y0);
    std::sort(group.begin(), group.end(), [&](uint32_t a, uint32_t b) {
        float pa = alongX ? at[a].x : at[a].y, pb = alongX ? at[b].x : at[b].y;
        return pa != pb ? pa < pb : a < b;
    });
    size_t half = group.size() / 2;
    SplitWide(at, std::vector<uint32_t>(group.begin(), group.begin() + half), reach, out);
    SplitWide(at, std::vector<uint32_t>(group.begin() + half, group.end()), reach, out);
}
// }}}

// {{{ Groups
// Every far party: each cluster cut into GroupSizes slices around its
// middle, by bearing (ties by index, so the answer is the same each time),
// and any slice not within reach throughout split again (SplitWide).
// Each group a list of indexes into `at`, its first the leader.
inline std::vector<std::vector<uint32_t>> Groups(std::vector<Spot> const& at, float reach)
{
    std::vector<std::vector<uint32_t>> out;
    for (std::vector<uint32_t> members : Clusters(at, reach))
    {
        float cx = 0.0f, cy = 0.0f;
        for (uint32_t i : members) { cx += at[i].x; cy += at[i].y; }
        cx /= float(members.size());
        cy /= float(members.size());
        std::sort(members.begin(), members.end(), [&](uint32_t a, uint32_t b) {
            float ba = std::atan2(at[a].y - cy, at[a].x - cx), bb = std::atan2(at[b].y - cy, at[b].x - cx);
            return ba != bb ? ba < bb : a < b;
        });
        size_t k = 0;
        for (uint32_t size : GroupSizes(uint32_t(members.size())))
        {
            SplitWide(at, std::vector<uint32_t>(members.begin() + k, members.begin() + k + size), reach, out);
            k += size;
        }
    }
    return out;
}
// }}}

} // namespace BuddyFarParty

#endif
