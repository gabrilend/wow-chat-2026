
#ifndef BUDDY_SELL_CORE_H
#define BUDDY_SELL_CORE_H

#include <algorithm>

namespace BuddySell
{

constexpr float NEAR_SHARE = 0.5f;
constexpr float FAR_SHARE  = 0.9f;
constexpr float NEAR_YARDS = 200.0f;
constexpr float FAR_YARDS  = 1500.0f;

inline float Needed(float yards)
{
    float t = std::clamp((yards - NEAR_YARDS) / (FAR_YARDS - NEAR_YARDS), 0.0f, 1.0f);
    return NEAR_SHARE + (FAR_SHARE - NEAR_SHARE) * t;
}

inline bool Goes(float share, float yards, bool everyone)
{
    return everyone || share >= Needed(yards);
}

inline char const* HowFar(float yards)
{
    if (yards < 300.0f)  return "pretty close";
    if (yards < 1000.0f) return "a fair walk";
    return "a long way off";
}

}

#endif
