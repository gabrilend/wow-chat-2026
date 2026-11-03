
#include "buddy_far_party_core.h"
#include <cstdio>
#include <set>

using namespace BuddyFarParty;

static int failures = 0, checks = 0;

static void check(bool ok, char const* what)
{
    ++checks;
    if (!ok)
        ++failures;
    std::printf("%s %s\n", ok ? "ok  " : "FAIL", what);
}

static bool sizesAre(std::vector<uint32_t> const& s, std::vector<uint32_t> const& want) { return s == want; }

int main()
{
    check(sizesAre(GroupSizes(6),  { 3, 3 }),       "six: 3 and 3, not 5 and 1 (the owner's example)");
    check(sizesAre(GroupSizes(7),  { 4, 3 }),       "seven: 4 and 3");
    check(sizesAre(GroupSizes(5),  { 5 }),          "five: one full party");
    check(sizesAre(GroupSizes(11), { 4, 4, 3 }),    "eleven: 4, 4 and 3");
    check(sizesAre(GroupSizes(2),  { 2 }),          "two: one pair");
    check(GroupSizes(0).empty(),                     "none: no groups");
    bool neverSix = true;
    for (uint32_t m = 1; m <= 64; ++m)
        for (uint32_t s : GroupSizes(m))
            neverSix = neverSix && s <= PARTY_SIZE && s >= 1;
    check(neverSix, "up to an army of 64: no group over five, none empty");

    std::vector<Spot> row;
    for (int i = 0; i < 6; ++i)
        row.push_back({ float(i) * 10.0f, 0.0f });
    std::vector<std::vector<uint32_t>> g = Groups(row, 74.0f);
    bool halves = g.size() == 2 && g[0].size() == 3 && g[1].size() == 3;
    if (halves)
    {
        std::set<uint32_t> a(g[0].begin(), g[0].end());
        halves = (a == std::set<uint32_t>{ 0, 1, 2 } || a == std::set<uint32_t>{ 3, 4, 5 });
    }
    check(halves, "six in a row: two groups of neighbours, each end's three");

    std::vector<Spot> two = { { 0, 0 }, { 5, 0 }, { 10, 0 }, { 500, 0 }, { 505, 0 } };
    std::vector<std::vector<uint32_t>> c = Clusters(two, 74.0f);
    check(c.size() == 2 && c[0].size() == 3 && c[1].size() == 2, "far apart: two clusters (3 and 2), out of sharing range of each other");
    std::vector<std::vector<uint32_t>> g2 = Groups(two, 74.0f);
    bool apart = g2.size() == 2;
    for (auto const& grp : g2)
        for (uint32_t i : grp)
            for (uint32_t j : grp)
                apart = apart && std::fabs(two[i].x - two[j].x) <= 74.0f;
    check(apart, "every group within sharing range of itself");

    std::vector<Spot> chain = { { 0, 0 }, { 60, 0 }, { 120, 0 } };
    check(Clusters(chain, 74.0f).size() == 1, "a chain within reach link by link is one cluster");
    bool inRange = true;
    for (auto const& grp : Groups(chain, 74.0f))
        for (uint32_t i : grp)
            for (uint32_t j : grp)
                inRange = inRange && std::fabs(chain[i].x - chain[j].x) <= 74.0f;
    check(inRange && Groups(chain, 74.0f).size() == 2, "the chain's ends (120 yards apart) are put in different groups");

    check(Groups(row, 74.0f) == g, "the same positions give the same groups");

    std::printf("%d checks, %d failed\n", checks, failures);
    return failures;
}
