
#ifndef MOD_BUDDIES_TALENT_DRAW_H
#define MOD_BUDDIES_TALENT_DRAW_H

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <map>
#include <string>
#include <vector>

namespace BuddyTalentDraw
{
    static constexpr float PER_POINT = 0.06f;
    static constexpr float NUDGE     = 0.015f;
    static constexpr float DRAW_LOW  = -2.0f;
    static constexpr float DRAW_HIGH =  4.0f;

    struct Touch
    {
        std::string ability;
        bool        broad;
        int         percent;
        int         ranks;
        int         points;
    };

    inline std::map<std::string, float> Weights(std::vector<Touch> const& touches, int measure, float broadShare)
    {
        std::map<std::string, float> w;
        for (Touch const& t : touches)
        {
            if (t.points <= 0 || t.ranks <= 0)
                continue;
            float raise = (measure == 2 && t.percent != 0)
                ? std::fabs(float(t.percent)) / 100.0f * float(t.points) / float(t.ranks)
                : PER_POINT * float(t.points);
            if (t.broad)
                raise *= broadShare;
            auto it = w.find(t.ability);
            w[t.ability] = (it == w.end() ? 1.0f : it->second) + raise;
        }
        return w;
    }

    inline float Factor(float weight, double u)
    {
        u = std::min(std::max(u, 1e-12), 1.0 - 1e-12);
        float g = float(-std::log(-std::log(u)));
        g = std::min(std::max(g, DRAW_LOW), DRAW_HIGH);
        return 1.0f + NUDGE * (std::log(std::max(weight, 0.01f)) + g);
    }
}

#endif
