/*
 * buddies_kit_split.h - how a new buddy's bag slots are split over its bags
 * (issue 617a4). No server headers: the test builds it on its own.
 *
 * For a general audience: a buddy gets as many bag slots as its owner has,
 * in bags of sizes the game actually has. The owner's words (2026-09-25):
 * "They have the same number of bag slots as the player they spawn with,
 * choosing the lowest quality bags to match that number, spread evenly as
 * possible. Prefer four 8 slot bags over two 10 slots and two 6 slots."
 *
 * So: pick up to four bag sizes, from the sizes available, that add up to
 * the owner's total; among the ways to do that, the fewest-different one
 * wins (the smallest gap between the biggest and smallest bag), and with
 * equal gaps, more bags win (4 x 8 beats 10 + 10 + 6 + 6, and 8 + 8 beats
 * 16 alone). When no four sizes add up exactly, the largest total below it
 * is used, so a buddy never has more room than its owner.
 */

#ifndef MOD_BUDDIES_KIT_SPLIT_H
#define MOD_BUDDIES_KIT_SPLIT_H

#include <algorithm>
#include <cstdint>
#include <vector>

namespace BuddyKit
{

// {{{ SplitBagSlots
// `total`: the owner's bag slots (the backpack's 16 not counted).
// `sizes`: the bag sizes available (any order, duplicates ignored).
// Returns up to four sizes, largest first; empty when total is 0 or no
// size fits.
inline std::vector<uint32_t> SplitBagSlots(uint32_t total, std::vector<uint32_t> sizes)
{
    std::sort(sizes.begin(), sizes.end());
    sizes.erase(std::unique(sizes.begin(), sizes.end()), sizes.end());
    std::vector<uint32_t> best;
    uint32_t bestSum = 0, bestGap = 0;
    // every multiset of 1 to 4 sizes (small: a few dozen sizes at most)
    std::vector<uint32_t> pick;
    auto consider = [&]()
    {
        uint32_t sum = 0;
        for (uint32_t s : pick) sum += s;
        if (sum > total || sum == 0)
            return;
        uint32_t gap = pick.front() - pick.back();       // pick is kept largest first
        bool better = best.empty() || sum > bestSum ||
            (sum == bestSum && (gap < bestGap || (gap == bestGap && pick.size() > best.size())));
        if (better) { best = pick; bestSum = sum; bestGap = gap; }
    };
    size_t n = sizes.size();
    for (size_t a = n; a-- > 0; )
    {
        pick = { sizes[a] }; consider();
        for (size_t b = a + 1; b-- > 0; )
        {
            pick = { sizes[a], sizes[b] }; consider();
            for (size_t c = b + 1; c-- > 0; )
            {
                pick = { sizes[a], sizes[b], sizes[c] }; consider();
                for (size_t d = c + 1; d-- > 0; )
                {
                    pick = { sizes[a], sizes[b], sizes[c], sizes[d] }; consider();
                }
            }
        }
    }
    return best;
}
// }}}

} // namespace BuddyKit

#endif
