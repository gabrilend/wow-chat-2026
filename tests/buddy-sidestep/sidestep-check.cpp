// sidestep-check.cpp - checks buddies_sidestep.h (issue 617s5): a sidestep
// keeps the buddy's distance to its target; by share, melee steps 20-35% of
// the circle and ranged 10-20%; by distance, 2-3 yards at 40 yards out and
// a small step (under 3 yards) close in; both directions happen.

#include "buddies_sidestep.h"

#include <cstdio>
#include <random>

using namespace BuddySidestep;

static int passed = 0, failed = 0;
// {{{ check
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}
// }}}

int main()
{
    std::mt19937 rng(5);
    std::uniform_real_distribution<float> u(0.0f, 1.0f);
    bool keeps = true, meleeShare = true, rangedShare = true, farStep = true, nearStep = true;
    int left = 0, right = 0;
    for (int i = 0; i < 5000; ++i)
    {
        float r = 3.0f + 37.0f * u(rng), a = 6.28f * u(rng);
        float bx = 100.0f + std::cos(a) * r, by = 50.0f + std::sin(a) * r;
        for (int how : { 1, 2 })
            for (bool melee : { true, false })
            {
                Spot s = Step(bx, by, 100.0f, 50.0f, melee, how, u(rng), u(rng));
                float d = std::sqrt((s.x - 100.0f) * (s.x - 100.0f) + (s.y - 50.0f) * (s.y - 50.0f));
                keeps = keeps && std::fabs(d - r) < 0.01f;
                float share = std::fabs(s.turned) / 6.2831853f;
                if (how == 1 && melee)  meleeShare  = meleeShare  && share >= 0.199f && share <= 0.351f;
                if (how == 1 && !melee) rangedShare = rangedShare && share >= 0.099f && share <= 0.201f;
                (s.turned > 0 ? left : right)++;
            }
    }
    // by distance at exactly 40 yards: 2 to 3 yards of arc; at 4 yards: under 3
    for (int i = 0; i < 500; ++i)
    {
        Spot f = Step(140.0f, 50.0f, 100.0f, 50.0f, false, 2, u(rng), u(rng));
        float arcFar = std::fabs(f.turned) * 40.0f;
        farStep = farStep && arcFar >= 1.99f && arcFar <= 3.01f;
        Spot n = Step(104.0f, 50.0f, 100.0f, 50.0f, true, 2, u(rng), u(rng));
        nearStep = nearStep && std::fabs(n.turned) * 4.0f < 3.0f;
    }
    check(keeps, "a sidestep keeps the buddy's distance to its target");
    check(meleeShare, "by share: melee steps 20-35% of the circle");
    check(rangedShare, "by share: ranged steps 10-20% of the circle");
    check(farStep, "by distance: at 40 yards a step of 2 to 3 yards");
    check(nearStep, "by distance: close in (4 yards), a step under 3 yards");
    check(left > 1000 && right > 1000, "it steps both ways round");
    std::printf("%s: %d of %d checks passed\n", failed ? "FAILED" : "ok", passed, passed + failed);
    return failed ? 1 : 0;
}
