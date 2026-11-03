
#include "buddies_cooldown_plan.h"

#include <cmath>
#include <cstdio>

using namespace BuddyPlan;

static int passed = 0, failed = 0;
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}

static bool near(double a, double b) { return std::fabs(a - b) < 1e-6; }

static double ByScan(Cooldown const& cd, std::vector<Window> const& windows, double fightLeft, Ending const& ending)
{
    if (fightLeft <= 0.0) return 0.0;
    int end   = static_cast<int>(std::ceil(fightLeft / STEP));
    int gap   = std::max(1, static_cast<int>(std::ceil(cd.cooldown / STEP)));
    int ready = static_cast<int>(std::ceil(std::max(0.0, cd.readyIn) / STEP));
    if (ready >= end) return Kept((ready - end) * STEP, cd.cooldown, ending);
    std::vector<double> worth(end), best(end + gap + 1, 0.0);
    for (int i = 0; i < end; ++i) worth[i] = UseWorth(windows, i * STEP, cd.lasts, fightLeft, ending.fight);
    for (int k = end; k <= end + gap; ++k) best[k] = Kept((k - end) * STEP, cd.cooldown, ending);
    for (int i = end - 1; i >= 0; --i)
    {
        double top = Kept(0.0, cd.cooldown, ending);
        for (int j = i; j < end && j <= i + gap; ++j) top = std::max(top, worth[j] + best[j + gap]);
        best[i] = top;
    }
    return best[ready];
}

int main()
{
    Plan p = Best({ 120, 0, 0 }, {}, 300, Fight::Boss);
    check(near(p.useNow, 3) && near(p.best, 3) && p.uses == 3 && near(p.nextUse, 0) && near(p.weight, 1),
          "no windows: used at once, three uses in 300 seconds of a 120-second cooldown");

    p = Best({ 180, 0, 0 }, { { 10, 40, 1.3 } }, 300, Fight::Boss);
    check(near(p.nextUse, 10) && near(p.best, 2.3) && near(p.useNow, 2.0) && p.uses == 2,
          "a window 10 seconds away that costs no use is waited for");
    check(near(p.weight, 2.0 / 2.3), "the weight of using it now is how much worse that plan is (2 of 2.3)");

    p = Best({ 120, 0, 0 }, { { 20, 30, 1.3 } }, 245, Fight::Boss);
    check(near(p.nextUse, 0) && near(p.best, 3) && near(p.weight, 1),
          "a hold that costs a whole use for a 1.3 window is not taken");

    p = Best({ 100, 0, 0 }, { { 60, 10, 1.3 } }, 250, Fight::Boss);
    check(near(p.nextUse, 0) && near(p.best, 3), "60 seconds' hold for x1.3 loses a use: used now");
    p = Best({ 100, 0, 0 }, { { 60, 10, 2.5 } }, 250, Fight::Boss);
    check(near(p.nextUse, 60) && near(p.best, 3.5) && p.uses == 2, "the same hold for x2.5 is worth the lost use: held");

    p = Best({ 120, 0, 0 }, { { 10, 30, 1.3 } }, 5, Fight::Boss);
    check(near(p.nextUse, 0) && p.uses == 1 && near(p.weight, 1), "5 seconds left, the window after: used now");

    p = Best({ 200, 0, 20 }, { { 30, 20, 1.5 } }, 100, Fight::Boss);
    check(near(p.nextUse, 30) && near(p.best, 1.5) && near(p.useNow, 1.0), "a 20-second buff waits to sit wholly inside a 20-second window");
    p = Best({ 200, 0, 20 }, { { 10, 10, 1.5 } }, 100, Fight::Boss);
    check(near(p.nextUse, 0) && near(p.best, 1.25),
          "a 20-second buff already half covering a 10-second window gains nothing by waiting: nothing held for nothing");

    p = Best({ 120, 0, 20 }, {}, 10, Fight::Boss);
    check(near(p.best, 1.0) && p.uses == 1 && near(p.nextUse, 0), "a boss with 10 seconds left: the 20-second buff is used, counted whole");
    p = Best({ 120, 0, 20 }, {}, 10, Fight::Trash);
    check(p.uses == 0 && near(p.nextUse, -1) && near(p.best, 1.0), "trash with 10 seconds left: the 20-second buff is kept for the next pack");
    check(near(p.useNow, 0.5 + 1.0 / 12.0) && p.weight < 0.6, "and leans away from it (0.58 of 1)");
    p = Best({ 120, 0, 0 }, {}, 5, Fight::Trash);
    check(p.uses == 1 && near(p.nextUse, 0), "trash with 5 seconds left: a single strike still lands whole, so it is used");
    p = Best({ 120, 0, 0 }, {}, 300, Fight::Trash);
    check(p.uses == 3 && near(p.best, 3.5), "a long trash fight: three uses, and half a use kept for after");
    check(near(Kept(0, 120, Fight::Boss), 0) && near(Kept(0, 120, Fight::Trash), 1) && near(Kept(60, 120, Fight::Trash), 0.5),
          "kept for after: nothing after a boss; after trash a whole use, less as it still cools");

    p = Best({ 120, 30, 0 }, {}, 300, Fight::Boss);
    check(near(p.nextUse, 30) && p.uses == 3, "ready in 30 seconds: used then, and at 150 and 270");
    p = Best({ 120, 30, 0 }, {}, 20, Fight::Boss);
    check(p.uses == 0 && near(p.nextUse, -1) && near(p.weight, 1), "ready only after the end: no use, no lean");

    check(near(FactorAt({ { 0, 40, 1.3 }, { 10, 20, 1.5 } }, 15), 1.95), "overlapping windows multiply");

    std::vector<Own> own = { { { 180, 10, 20 }, 1.3 }, { { 120, 0, 15 }, 1.2 } };
    std::vector<Plan> both = LineUp(own, {}, 200, Fight::Boss);
    check(near(both[0].nextUse, 10) && near(both[1].nextUse, 10), "a buddy's two cooldowns are used together");
    check(near(both[1].best, 2.6) && near(both[1].at[1], 190), "its second use slides onto the long one's second (10, 190: 2.6)");
    check(near(both[1].useNow, 2.4) && near(both[1].weight, 2.4 / 2.6), "used alone now it would be worth 2.4 of 2.6, and leans away");
    check(near(Best(own[1].cd, {}, 200, Fight::Boss).nextUse, 0), "on its own the same cooldown is used at once: the hold comes from lining up");
    p = Best(own[0].cd, {}, 200, Fight::Boss);
    check(p.uses == 2 && near(p.at[0], 10) && near(p.at[1], 190), "every use of the best plan is listed (10 and 190)");

    Cooldown lust{ 600, 0, 40 };
    p = Best(lust, {}, 60, Ending(Fight::Boss, 1.5, 120));
    check(p.uses == 0 && near(p.best, 1.5), "a harder boss next (a use worth 1.5 there): Bloodlust is saved for it");
    check(near(p.useNow, 1.0 + 1.5 * (1.0 - 420.0 / 600.0)) && p.weight < 1, "spent here it is worth 1, and would still be 7 minutes from back at the next pull");
    p = Best(lust, {}, 60, Ending(Fight::Boss, 1.0, 120));
    check(p.uses == 1 && near(p.nextUse, 0), "the next boss no harder: spent here, a whole use now beats waiting");
    p = Best(lust, {}, 60, Ending(Fight::Boss, 1.5, 600));
    check(p.uses == 1 && near(p.nextUse, 0), "the next boss 10 minutes off: spent here, it is back in time");
    p = Best(lust, {}, 60, Fight::Boss);
    check(p.uses == 1 && near(p.best, 1.0), "no boss known to follow: everything is used");

    {
        unsigned seed = 625;
        auto draw = [&](double lo, double hi) { seed = seed * 1103515245u + 12345u; return lo + (hi - lo) * ((seed >> 8) & 0xffff) / 65535.0; };
        int agree = 0, tried = 0, planAgrees = 0;
        double worst = 0.0;
        for (int r = 0; r < 400; ++r)
        {
            Cooldown cd{ draw(90, 600), draw(0, 60), draw(0, 1) < 0.3 ? 0.0 : draw(5, 40) };
            std::vector<Window> ws;
            int count = static_cast<int>(draw(0, 4.99));
            for (int k = 0; k < count; ++k) ws.push_back({ draw(-20, 400), draw(5, 60), draw(1.05, 2.5) });
            double left  = draw(5, 700);
            Fight  kind  = draw(0, 1) < 0.5 ? Fight::Trash : Fight::Boss;
            Ending fight = draw(0, 1) < 0.5 ? Ending(kind) : Ending(kind, draw(0, 2), draw(0, 300));
            Plan   q     = Best(cd, ws, left, fight);
            double s     = ByScan(cd, ws, left, fight);
            ++tried;
            worst = std::max(worst, std::fabs(q.best - s));
            if (std::fabs(q.best - s) < 1e-6) ++agree;
            double sum = 0.0, after = -1.0;
            for (double t : q.at) { sum += UseWorth(ws, t, cd.lasts, left, fight.fight); after = t; }
            int end = static_cast<int>(std::ceil(left / STEP)), gap = std::max(1, static_cast<int>(std::ceil(cd.cooldown / STEP)));
            int back = after < 0 ? static_cast<int>(std::ceil(std::max(0.0, cd.readyIn) / STEP)) : static_cast<int>(std::lround(after / STEP)) + gap;
            sum += back >= end ? Kept((back - end) * STEP, cd.cooldown, fight) : Kept(0.0, cd.cooldown, fight);
            if (std::fabs(sum - q.best) < 1e-6) ++planAgrees;
        }
        std::printf("   (largest difference from trying every moment: %.2g)\n", worst);
        check(agree == tried, "400 random fights: the quick working out's best is what trying every moment gives");
        check(planAgrees == tried, "400 random fights: each plan's own uses add up to its worth");
    }

    std::printf("\n%d passed, %d failed\n", passed, failed);
    return failed == 0 ? 0 : 1;
}
