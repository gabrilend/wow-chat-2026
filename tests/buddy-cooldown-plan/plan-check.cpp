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

// {{{ ByScan
// The plain way, kept here as the reference the quick one is checked
// against: every use's worth summed step by step (UseWorth), and every
// moment within a cooldown tried for the next use. Gives the best plan's
// worth (the quick one may pick a different moment among equals).
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
// }}}

int main()
{
    // no windows: used at once, again each time it comes back (0, 120, 240)
    Plan p = Best({ 120, 0, 0 }, {}, 300, Fight::Boss);
    check(near(p.useNow, 3) && near(p.best, 3) && p.uses == 3 && near(p.nextUse, 0) && near(p.weight, 1),
          "no windows: used at once, three uses in 300 seconds of a 120-second cooldown");

    // Bloodlust in 10 seconds (x1.3), a 180-second cooldown, 300 seconds
    // left: holding costs no use (10 and 190 both fit), so it is held
    p = Best({ 180, 0, 0 }, { { 10, 40, 1.3 } }, 300, Fight::Boss);
    check(near(p.nextUse, 10) && near(p.best, 2.3) && near(p.useNow, 2.0) && p.uses == 2,
          "a window 10 seconds away that costs no use is waited for");
    check(near(p.weight, 2.0 / 2.3), "the weight of using it now is how much worse that plan is (2 of 2.3)");

    // the same window, a 120-second cooldown and 245 seconds left: holding
    // to 20 loses the third use (20, 140; 260 is past the end), so not held
    p = Best({ 120, 0, 0 }, { { 20, 30, 1.3 } }, 245, Fight::Boss);
    check(near(p.nextUse, 0) && near(p.best, 3) && near(p.weight, 1),
          "a hold that costs a whole use for a 1.3 window is not taken");

    // a lost use is counted at its own worth: a window worth 2.5 pays for it
    p = Best({ 100, 0, 0 }, { { 60, 10, 1.3 } }, 250, Fight::Boss);
    check(near(p.nextUse, 0) && near(p.best, 3), "60 seconds' hold for x1.3 loses a use: used now");
    p = Best({ 100, 0, 0 }, { { 60, 10, 2.5 } }, 250, Fight::Boss);
    check(near(p.nextUse, 60) && near(p.best, 3.5) && p.uses == 2, "the same hold for x2.5 is worth the lost use: held");

    // near the end, the window falls after it: used now
    p = Best({ 120, 0, 0 }, { { 10, 30, 1.3 } }, 5, Fight::Boss);
    check(near(p.nextUse, 0) && p.uses == 1 && near(p.weight, 1), "5 seconds left, the window after: used now");

    // a lasting buff is worth what the windows give over its own length
    p = Best({ 200, 0, 20 }, { { 30, 20, 1.5 } }, 100, Fight::Boss);
    check(near(p.nextUse, 30) && near(p.best, 1.5) && near(p.useNow, 1.0), "a 20-second buff waits to sit wholly inside a 20-second window");
    p = Best({ 200, 0, 20 }, { { 10, 10, 1.5 } }, 100, Fight::Boss);
    check(near(p.nextUse, 0) && near(p.best, 1.25),
          "a 20-second buff already half covering a 10-second window gains nothing by waiting: nothing held for nothing");

    // the fight's end, by the kind of fight (the owner: "for trash mobs,
    // yes it diminishes the value. But for a boss ... use everything."):
    // a boss is burned with a 20-second buff whatever is left
    p = Best({ 120, 0, 20 }, {}, 10, Fight::Boss);
    check(near(p.best, 1.0) && p.uses == 1 && near(p.nextUse, 0), "a boss with 10 seconds left: the 20-second buff is used, counted whole");
    // against trash only half of it lands (0.5), and it would still be
    // cooling 110 of its 120 seconds at the next pull (1/12 of a use kept),
    // against a whole use kept by not spending it: kept
    p = Best({ 120, 0, 20 }, {}, 10, Fight::Trash);
    check(p.uses == 0 && near(p.nextUse, -1) && near(p.best, 1.0), "trash with 10 seconds left: the 20-second buff is kept for the next pack");
    check(near(p.useNow, 0.5 + 1.0 / 12.0) && p.weight < 0.6, "and leans away from it (0.58 of 1)");
    // a single strike lands whole even against trash: used
    p = Best({ 120, 0, 0 }, {}, 5, Fight::Trash);
    check(p.uses == 1 && near(p.nextUse, 0), "trash with 5 seconds left: a single strike still lands whole, so it is used");
    // over a long trash fight the cooldown is used as usual; what is still
    // cooling at the end counts by how soon it is back (240's use is back
    // 60 seconds after a 300-second fight: half a use kept)
    p = Best({ 120, 0, 0 }, {}, 300, Fight::Trash);
    check(p.uses == 3 && near(p.best, 3.5), "a long trash fight: three uses, and half a use kept for after");
    check(near(Kept(0, 120, Fight::Boss), 0) && near(Kept(0, 120, Fight::Trash), 1) && near(Kept(60, 120, Fight::Trash), 0.5),
          "kept for after: nothing after a boss; after trash a whole use, less as it still cools");

    // not ready yet
    p = Best({ 120, 30, 0 }, {}, 300, Fight::Boss);
    check(near(p.nextUse, 30) && p.uses == 3, "ready in 30 seconds: used then, and at 150 and 270");
    p = Best({ 120, 30, 0 }, {}, 20, Fight::Boss);
    check(p.uses == 0 && near(p.nextUse, -1) && near(p.weight, 1), "ready only after the end: no use, no lean");

    // overlapping windows multiply (Bloodlust inside a weak phase)
    check(near(FactorAt({ { 0, 40, 1.3 }, { 10, 20, 1.5 } }, 15), 1.95), "overlapping windows multiply");

    // a buddy's own cooldowns line up: a 120-second one (x1.2 for 15
    // seconds) ready now waits 10 seconds for a 180-second one (x1.3 for 20
    // seconds) that is ready then, because inside it a use is worth more and
    // no use is lost (10 and 130 both fit in 200 seconds)
    std::vector<Own> own = { { { 180, 10, 20 }, 1.3 }, { { 120, 0, 15 }, 1.2 } };
    std::vector<Plan> both = LineUp(own, {}, 200, Fight::Boss);
    check(near(both[0].nextUse, 10) && near(both[1].nextUse, 10), "a buddy's two cooldowns are used together");
    // and its second use slides to 190, onto the long one's second use (a
    // boss: both count whole past the end, 1.3 each), rather than 130 (1.0)
    check(near(both[1].best, 2.6) && near(both[1].at[1], 190), "its second use slides onto the long one's second (10, 190: 2.6)");
    check(near(both[1].useNow, 2.4) && near(both[1].weight, 2.4 / 2.6), "used alone now it would be worth 2.4 of 2.6, and leans away");
    check(near(Best(own[1].cd, {}, 200, Fight::Boss).nextUse, 0), "on its own the same cooldown is used at once: the hold comes from lining up");
    p = Best(own[0].cd, {}, 200, Fight::Boss);
    check(p.uses == 2 && near(p.at[0], 10) && near(p.at[1], 190), "every use of the best plan is listed (10 and 190)");

    // from one boss to the next (the owner: "better to get the full use of
    // a BL on the next boss than waste it on an easier boss."): Bloodlust,
    // 40 seconds long, back for the party after Sated's 10 minutes, with a
    // minute of this boss left and the next pulled 2 minutes after it
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

    // the quick working out gives what trying every moment gives: 400
    // fights drawn at random (a fixed seed, so a failure can be run again),
    // trash and boss, half with a next fight of any worth and distance,
    // buffs and single strikes, up to four windows each
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
            // the quick plan's own uses add up to what it says it is worth
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
