
#include "buddy_sell_core.h"
#include <cmath>
#include <cstdio>
#include <string>

using namespace BuddySell;

static int failures = 0, checks = 0;

static void check(bool ok, char const* what)
{
    ++checks;
    if (!ok)
        ++failures;
    std::printf("%s %s\n", ok ? "ok  " : "FAIL", what);
}

int main()
{
    check(Needed(50.0f) == 0.5f, "a vendor nearby: half full is enough");
    check(Needed(5000.0f) == 0.9f, "a vendor far away: nine tenths");
    float mid = Needed((NEAR_YARDS + FAR_YARDS) / 2.0f);
    check(std::fabs(mid - 0.7f) < 1e-5f, "halfway between: halfway between (continuous)");
    bool rising = true;
    for (float y = 0.0f; y < 3000.0f; y += 10.0f)
        rising = rising && Needed(y + 10.0f) >= Needed(y);
    check(rising, "the bar never falls as the walk grows");
    check(Goes(0.65f, 100.0f, false), "65% full and pretty close: goes (the owner's own example)");
    check(!Goes(0.65f, 2000.0f, false), "65% full and a long way off: stays");
    check(Goes(0.1f, 2000.0f, true), "\"everyone go sell\": goes whatever the bags");
    check(std::string(HowFar(100.0f)) == "pretty close" && std::string(HowFar(2000.0f)) == "a long way off",
          "the walk in words");
    std::printf("%d checks, %d failed\n", checks, failures);
    return failures;
}
