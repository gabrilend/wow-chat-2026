// plan-check.cpp - checks buddies_cooldown_plan.h (issue 625f, "most
// valuable uptime"): a cooldown is held only when the plan with the hold is
// worth more over the rest of the fight; short holds for big windows are
// taken, holds that cost a whole use are not, unless the window is worth
// more than the use; nothing is held for nothing, and near the end
// everything is used.

#include "buddies_cooldown_plan.h"

#include <cmath>
#include <cstdio>

using namespace BuddyPlan;

static int passed = 0, failed = 0;
// {{{ check
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}
// }}}

static bool near(double a, double b) { return std::fabs(a - b) < 1e-6; }

int main()
{
    // no windows: used at once, again each time it comes back (0, 120, 240)
    Plan p = Best({ 120, 0, 0 }, {}, 300);
    check(near(p.useNow, 3) && near(p.best, 3) && p.uses == 3 && near(p.nextUse, 0) && near(p.weight, 1),
          "no windows: used at once, three uses in 300 seconds of a 120-second cooldown");

    // Bloodlust in 10 seconds (x1.3), a 180-second cooldown, 300 seconds
    // left: holding costs no use (10 and 190 both fit), so it is held
    p = Best({ 180, 0, 0 }, { { 10, 40, 1.3 } }, 300);
    check(near(p.nextUse, 10) && near(p.best, 2.3) && near(p.useNow, 2.0) && p.uses == 2,
          "a window 10 seconds away that costs no use is waited for");
    check(near(p.weight, 2.0 / 2.3), "the weight of using it now is how much worse that plan is (2 of 2.3)");

    // the same window, a 120-second cooldown and 245 seconds left: holding
    // to 20 loses the third use (20, 140; 260 is past the end), so not held
    p = Best({ 120, 0, 0 }, { { 20, 30, 1.3 } }, 245);
    check(near(p.nextUse, 0) && near(p.best, 3) && near(p.weight, 1),
          "a hold that costs a whole use for a 1.3 window is not taken");

    // a lost use is counted at its own worth: a window worth 2.5 pays for it
    p = Best({ 100, 0, 0 }, { { 60, 10, 1.3 } }, 250);
    check(near(p.nextUse, 0) && near(p.best, 3), "60 seconds' hold for x1.3 loses a use: used now");
    p = Best({ 100, 0, 0 }, { { 60, 10, 2.5 } }, 250);
    check(near(p.nextUse, 60) && near(p.best, 3.5) && p.uses == 2, "the same hold for x2.5 is worth the lost use: held");

    // near the end, the window falls after it: used now
    p = Best({ 120, 0, 0 }, { { 10, 30, 1.3 } }, 5);
    check(near(p.nextUse, 0) && p.uses == 1 && near(p.weight, 1), "5 seconds left, the window after: used now");

    // a lasting buff is worth what the windows give over its own length
    p = Best({ 200, 0, 20 }, { { 30, 20, 1.5 } }, 100);
    check(near(p.nextUse, 30) && near(p.best, 1.5) && near(p.useNow, 1.0), "a 20-second buff waits to sit wholly inside a 20-second window");
    p = Best({ 200, 0, 20 }, { { 10, 10, 1.5 } }, 100);
    check(near(p.nextUse, 0) && near(p.best, 1.25),
          "a 20-second buff already half covering a 10-second window gains nothing by waiting: nothing held for nothing");

    // the fight's end cuts a lasting buff short
    p = Best({ 120, 0, 20 }, {}, 10);
    check(near(p.best, 0.5) && p.uses == 1, "a 20-second buff with 10 seconds left is worth half a use");

    // not ready yet
    p = Best({ 120, 30, 0 }, {}, 300);
    check(near(p.nextUse, 30) && p.uses == 3, "ready in 30 seconds: used then, and at 150 and 270");
    p = Best({ 120, 30, 0 }, {}, 20);
    check(p.uses == 0 && near(p.nextUse, -1) && near(p.weight, 1), "ready only after the end: no use, no lean");

    // overlapping windows multiply (Bloodlust inside a weak phase)
    check(near(FactorAt({ { 0, 40, 1.3 }, { 10, 20, 1.5 } }, 15), 1.95), "overlapping windows multiply");

    // a buddy's own cooldowns line up: a 120-second one (x1.2 for 15
    // seconds) ready now waits 10 seconds for a 180-second one (x1.3 for 20
    // seconds) that is ready then, because inside it a use is worth more and
    // no use is lost (10 and 130 both fit in 200 seconds)
    std::vector<Own> own = { { { 180, 10, 20 }, 1.3 }, { { 120, 0, 15 }, 1.2 } };
    std::vector<Plan> both = LineUp(own, {}, 200);
    check(near(both[0].nextUse, 10) && near(both[1].nextUse, 10), "a buddy's two cooldowns are used together");
    // and its second use slides to 185, to overlap the long one's second
    // use at 190 (10 of its 15 seconds inside: 1.2), rather than 130 (1.0)
    check(near(both[1].best, 2.5) && near(both[1].at[1], 185), "its second use slides to meet the long one's second (10, 185: 2.5)");
    check(near(both[1].useNow, 2.3) && near(both[1].weight, 2.3 / 2.5), "used alone now it would be worth 2.3 of 2.5, and leans away");
    check(near(Best(own[1].cd, {}, 200).nextUse, 0), "on its own the same cooldown is used at once: the hold comes from lining up");
    p = Best(own[0].cd, {}, 200);
    check(p.uses == 2 && near(p.at[0], 10) && near(p.at[1], 190), "every use of the best plan is listed (10 and 190)");

    std::printf("\n%d passed, %d failed\n", passed, failed);
    return failed == 0 ? 0 : 1;
}
