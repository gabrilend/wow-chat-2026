
#ifndef MOD_BUDDIES_KIT_SPLIT_H
#define MOD_BUDDIES_KIT_SPLIT_H

#include <algorithm>
#include <cstdint>
#include <vector>

namespace BuddyKit
{

inline std::vector<uint32_t> SplitBagSlots(uint32_t total, std::vector<uint32_t> sizes)
{
    std::sort(sizes.begin(), sizes.end());
    sizes.erase(std::unique(sizes.begin(), sizes.end()), sizes.end());
    std::vector<uint32_t> best;
    uint32_t bestSum = 0, bestGap = 0;
    std::vector<uint32_t> pick;
    auto consider = [&]()
    {
        uint32_t sum = 0;
        for (uint32_t s : pick) sum += s;
        if (sum > total || sum == 0)
            return;
        uint32_t gap = pick.front() - pick.back();
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

}

#endif
