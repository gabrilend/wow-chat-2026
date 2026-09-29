// bag-split.cpp - checks the starting kit's bag split (issue 617a4) against
// the owner's rule: the owner's total, up to four bags, as even as the
// sizes allow, more bags on a tie, never more room than the owner has.
#include "buddies_kit_split.h"
#include <cstdio>
#include <vector>

static int passed = 0, failed = 0;
static void check(bool ok, char const* what, uint32_t total)
{
    if (ok) ++passed;
    else { ++failed; std::printf("  FAIL: %s (total %u)\n", what, total); }
}

int main()
{
    using BuddyKit::SplitBagSlots;
    // the owner's own example: four 8s, not 10 + 10 + 6 + 6
    std::vector<uint32_t> ex = SplitBagSlots(32, { 6, 8, 10 });
    check(ex == std::vector<uint32_t>{ 8, 8, 8, 8 }, "32 slots from 6/8/10 is four 8-slot bags", 32);
    check(SplitBagSlots(0, { 6, 8 }).empty(), "no slots, no bags", 0);
    check(SplitBagSlots(4, { 6, 8 }).empty(), "too few slots for any bag, no bags", 4);
    check((SplitBagSlots(16, { 8, 16 }) == std::vector<uint32_t>{ 8, 8 }), "16 from 8/16 is two 8s (more bags on a tie)", 16);

    // every total 0..144 over the sizes a stock game sells, low levels to 20
    std::vector<uint32_t> stock = { 4, 6, 8, 10, 12, 14, 16, 18, 20 };
    for (uint32_t t = 0; t <= 144; ++t)
    {
        std::vector<uint32_t> s = SplitBagSlots(t, stock);
        uint32_t sum = 0;
        for (uint32_t v : s) sum += v;
        check(s.size() <= 4, "at most four bags", t);
        check(sum <= t, "never more room than the owner", t);
        // with sizes 4..20 in steps of 2, every even total from 4 to 80 is
        // reachable exactly, and an odd one comes one short
        if (t >= 4 && t <= 80)
            check(sum == t - (t % 2), "the owner's total (even) reached", t);
        if (!s.empty())
            check(s.front() - s.back() <= 2 || sum > 80 - 1, "as even as possible (gap at most 2)", t);
    }
    std::printf("bag-split: %d passed, %d failed\n", passed, failed);
    return failed ? 1 : 0;
}
