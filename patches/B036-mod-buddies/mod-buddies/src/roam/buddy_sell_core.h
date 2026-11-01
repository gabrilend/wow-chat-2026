/*
 * buddy_sell_core.h - whether a buddy goes to sell when told "go sell"
 * (issue 623, piece 5). Plain arithmetic, no server; checked by
 * scripts/test-buddy-sell.
 *
 * For a general audience, the owner (2026-10-30): "depends on how far the
 * vendor they're gonna walk to is. 50% is if the vendor is nearby, 80 or
 * 90% if it's far. How about if the player says "everyone go sell" then
 * all the buddy-bots do it?", and "sorry yes I meant continuous.", and of
 * what they say: "my inventory is 65% full, and it's pretty close, so I'm
 * just gonna go sell". So the share of its bag spaces taken by things it
 * would sell must reach a bar that rises smoothly with the walk to the
 * nearest vendor: NEAR_SHARE up to NEAR_YARDS, FAR_SHARE from FAR_YARDS,
 * in a straight line between; "everyone go sell" sends every hearer.
 * The yards and shares are the agent's call, to be judged in game.
 */

#ifndef BUDDY_SELL_CORE_H
#define BUDDY_SELL_CORE_H

#include <algorithm>

namespace BuddySell
{

constexpr float NEAR_SHARE = 0.5f;     // "50% is if the vendor is nearby"
constexpr float FAR_SHARE  = 0.9f;     // "80 or 90% if it's far"
constexpr float NEAR_YARDS = 200.0f;   // this close or closer: nearby
constexpr float FAR_YARDS  = 1500.0f;  // this far or farther: far

// {{{ Needed
// The share of bag spaces (0-1) holding sellable things it takes to go,
// for a vendor `yards` away.
inline float Needed(float yards)
{
    float t = std::clamp((yards - NEAR_YARDS) / (FAR_YARDS - NEAR_YARDS), 0.0f, 1.0f);
    return NEAR_SHARE + (FAR_SHARE - NEAR_SHARE) * t;
}
// }}}

// {{{ Goes
// Each path:
//   "everyone go sell"                - goes
//   the share reaches Needed(yards)   - goes
//   otherwise                         - stays
inline bool Goes(float share, float yards, bool everyone)
{
    return everyone || share >= Needed(yards);
}
// }}}

// {{{ HowFar
// The walk in words, for what the buddy says.
inline char const* HowFar(float yards)
{
    if (yards < 300.0f)  return "pretty close";
    if (yards < 1000.0f) return "a fair walk";
    return "a long way off";
}
// }}}

} // namespace BuddySell

#endif
