
#ifndef MOD_BUDDIES_SIDESTEP_H
#define MOD_BUDDIES_SIDESTEP_H

#include <algorithm>
#include <cmath>

namespace BuddySidestep
{
    static constexpr float MELEE_SHARE_MIN  = 0.20f, MELEE_SHARE_MAX  = 0.35f;
    static constexpr float RANGED_SHARE_MIN = 0.10f, RANGED_SHARE_MAX = 0.20f;
    static constexpr float FAR_YARDS        = 40.0f;
    static constexpr float FAR_STEP_MIN     = 2.0f, FAR_STEP_MAX = 3.0f;

    struct Spot { float x, y, turned; };
    inline Spot Step(float bx, float by, float tx, float ty, bool melee, int how, float u1, float u2)
    {
        float dx = bx - tx, dy = by - ty;
        float r = std::sqrt(dx * dx + dy * dy);
        if (r < 0.01f)
            return { bx, by, 0.0f };
        float arc;
        if (how == 2)
        {
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
}

#endif
