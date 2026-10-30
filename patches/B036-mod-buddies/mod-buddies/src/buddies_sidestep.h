/*
 * buddies_sidestep.h - where a buddy steps to round its target between
 * spells (issue 617s5); plain arithmetic, apart from the server, so it can
 * be tested on its own (tests/buddy-sidestep/sidestep-check.cpp,
 * scripts/test-buddy-sidestep).
 *
 * For a general audience: in a fight, right after a buddy casts an instant
 * spell (which it may cast on the move), it steps round its target along
 * the circle whose radius is its present distance, so a caster stays in
 * range and a melee buddy in reach. How far it steps has two answers from
 * the owner (2026-10-04), both built:
 *   1 by share: a share of that circle's length, melee 20-35%, ranged
 *     10-20% ("melee should do a larger proportion of the circle each
 *     time");
 *   2 by distance: 2-3 yards at 40 yards out, shrinking toward the target
 *     to a small step close in.
 * The direction is random each time.
 */

#ifndef MOD_BUDDIES_SIDESTEP_H
#define MOD_BUDDIES_SIDESTEP_H

#include <algorithm>
#include <cmath>

namespace BuddySidestep
{
    // {{{ the numbers (the owner's, 2026-10-04)
    static constexpr float MELEE_SHARE_MIN  = 0.20f, MELEE_SHARE_MAX  = 0.35f;
    static constexpr float RANGED_SHARE_MIN = 0.10f, RANGED_SHARE_MAX = 0.20f;
    static constexpr float FAR_YARDS        = 40.0f;   // where the by-distance step is 2-3 yards
    static constexpr float FAR_STEP_MIN     = 2.0f, FAR_STEP_MAX = 3.0f;
    // }}}

    // {{{ Step
    // The spot after one sidestep. (bx, by): the buddy; (tx, ty): its
    // target; melee: whether it fights in melee; how: 1 by share, 2 by
    // distance; u1, u2: random numbers in [0, 1) (the step's size, and its
    // direction: below a half, one way round, otherwise the other).
    // Returns the angle moved too (radians), for the checks.
    struct Spot { float x, y, turned; };
    inline Spot Step(float bx, float by, float tx, float ty, bool melee, int how, float u1, float u2)
    {
        float dx = bx - tx, dy = by - ty;
        float r = std::sqrt(dx * dx + dy * dy);
        if (r < 0.01f)
            return { bx, by, 0.0f };                    // on top of it: nowhere round to go
        float arc;                                       // yards along the circle
        if (how == 2)
        {
            // by distance: 2-3 yards at FAR_YARDS, shrinking in step with the
            // distance toward the target ("down to, near the target (0-3
            // yards), between the character's melee reach and the target's
            // centre": a small step close in)
            float far = FAR_STEP_MIN + (FAR_STEP_MAX - FAR_STEP_MIN) * u1;
            arc = far * std::min(1.0f, r / FAR_YARDS);
        }
        else
        {
            float lo = melee ? MELEE_SHARE_MIN : RANGED_SHARE_MIN, hi = melee ? MELEE_SHARE_MAX : RANGED_SHARE_MAX;
            arc = (lo + (hi - lo) * u1) * 2.0f * 3.14159265f * r;
        }
        float turn = arc / r * (u2 < 0.5f ? 1.0f : -1.0f);
        float a = std::atan2(dy, dx) + turn;
        return { tx + std::cos(a) * r, ty + std::sin(a) * r, turn };
    }
    // }}}
}

#endif
