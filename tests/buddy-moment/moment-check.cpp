// moment-check.cpp - checks the moment's economy (buddies_moment.h) against
// the owner's design, with no server (issue 625d), by the issue's own cases:
// a druid with an ally at 20% casts mostly fast answers; at 80%, mostly
// cheap ones; low on mana, no overheals; with high regeneration, mana
// barely weighs; in a moving fight, standing still, cast-time answers
// first; Bloodlust up, cooldowns used. Built and run by
// scripts/test-buddy-moment. Each check prints "ok" or "FAIL" and what it
// held; the exit status is the number of failures.

#include "buddies_moment.h"

#include <cstdio>

using namespace BuddyMoment;

static int failures = 0, checks = 0;

// {{{ check
static void check(bool ok, char const* what)
{
    ++checks;
    if (!ok)
        ++failures;
    std::printf("%s %s\n", ok ? "ok  " : "FAIL", what);
}
// }}}

// {{{ the druid's answers to "an ally hurt" (made-up but shaped like the
// game's: Healing Touch slow, big and efficient; Regrowth middling; Nourish
// fast and dear; Rejuvenation instant, over time, efficient)
enum { HT, RG, NO, RJ };
static std::vector<Answer> Heals()
{
    Answer ht{ 3.0, 500, 3000, true, false, false };
    Answer rg{ 2.0, 400, 1800, true, false, false };
    Answer no{ 1.5, 300, 1300, true, false, false };
    Answer rj{ 0.0, 250, 1500, true, true,  false };
    return { ht, rg, no, rj };
}
static Moment Ally(double healthPct, double manaPct, double refill)
{
    Moment m;
    m.healthPct = healthPct;
    m.missing = (100.0 - healthPct) * 100.0;   // a 10,000-health ally
    m.manaPct = manaPct;
    m.refillSeconds = refill;
    return m;
}
static int Top(std::vector<double> const& w)
{
    int best = 0;
    for (size_t i = 1; i < w.size(); ++i) if (w[i] > w[best]) best = int(i);
    return best;
}
// }}}

int main()
{
    std::vector<Answer> heals = Heals();

    // {{{ 1 and 3: urgency and mana
    std::vector<double> low = Suit(heals, Ally(20, 70, 200));
    check(low[NO] > low[HT] && low[RJ] > low[HT] && low[NO] > low[RG],
          "an ally at 20%: the fast answers (Nourish, Rejuvenation) before the slow ones");
    check(low[NO] + low[RJ] > low[HT] + low[RG], "an ally at 20%: mostly fast answers");
    std::vector<double> high = Suit(heals, Ally(80, 70, 200));
    check(high[HT] == 0, "an ally at 80% (2,000 missing), mana at 70%: Healing Touch's 3,000 would overheal: refused");
    check(Top(high) == RJ && high[RJ] > high[NO], "an ally at 80%: the cheapest (Rejuvenation) first, Nourish's dear speed last");
    std::vector<double> full = Suit(heals, Ally(80, 95, 200));
    check(full[HT] > 0, "the same overheal at 95% mana is allowed (\"unless they're at 90% or above\")");
    std::vector<double> at90 = Suit(heals, Ally(80, 90, 200)), at89 = Suit(heals, Ally(80, 89.9, 200));
    check(at90[HT] > 0 && at89[HT] == 0, "the line is 90% exactly");
    check(low[HT] > 0, "an ally at 20% (8,000 missing): Healing Touch fits, nothing refused");
    Answer strike{ 1.5, 200, 3000, false, false, false };
    Moment hurtless = Ally(95, 50, 200);
    check(!Refused(strike, hurtless), "a damage answer is never an overheal");
    // }}}

    // {{{ healing ahead of the damage
    Moment tank = Ally(100, 60, 200);
    check(Refused(heals[RJ], tank) && Refused(heals[NO], tank), "a full-health tank, mana 60%: every heal would overheal: refused");
    tank.aboutToBeHit = true;
    std::vector<double> ahead = Suit(heals, tank);
    check(ahead[RJ] > 0 && ahead[NO] == 0 && ahead[HT] == 0,
          "the tank charging in: Rejuvenation goes on ahead of the blows; direct heals still wait");
    // }}}

    // {{{ high regeneration: mana barely weighs
    std::vector<double> slow = Suit(heals, Ally(70, 70, 200)), fast = Suit(heals, Ally(70, 70, 10));
    double slowGap = slow[RJ] / slow[NO], fastGap = fast[RJ] / fast[NO];
    std::printf("     (Rejuvenation over Nourish: %.3f refilling in 200 s, %.3f in 10 s)\n", slowGap, fastGap);
    check(slowGap > fastGap && fastGap < 1.15, "mana back in seconds: the cheap answer barely ahead (\"told to be extravagant\")");
    // }}}

    // {{{ 2: the action economy
    check(Busy(1) == 0 && Busy(2) == 0.5 && Busy(4) == 0.75, "busy: nothing with one concern, a half with two, three quarters with four");
    Moment calm = Ally(60, 70, 60), busy = calm;
    busy.concerns = 4;
    std::vector<double> c1 = Suit(heals, calm), c4 = Suit(heals, busy);
    check(c4[RJ] / c4[HT] > c1[RJ] / c1[HT], "four concerns firing: the instant over time counts for more against the slow heal");
    check(c4[NO] / c4[HT] > c1[NO] / c1[HT], "four concerns firing: the fast heal counts for more against the slow one");
    std::vector<double> a4 = Action(heals, busy);
    check(std::fabs(a4[RJ] / a4[NO] - 1.75) < 1e-9,
          "four concerns: an instant heal over time counts 1.75 against an equally fast direct one (it keeps working)");
    std::vector<double> a1 = Action(heals, calm);
    check(a1[0] == 1 && a1[1] == 1 && a1[2] == 1 && a1[3] == 1, "one concern: the action economy prefers nothing");
    // }}}

    // {{{ 4: movement
    Moment walking = Ally(40, 70, 60);
    walking.moving = true;
    std::vector<double> mv = Suit(heals, walking);
    check(mv[HT] == 0 && mv[RG] == 0 && mv[NO] == 0 && mv[RJ] > 0, "moving: only the instant");
    Moment still = Ally(40, 70, 60), stillInMovingFight = still;
    stillInMovingFight.movingShare = 0.6;
    std::vector<double> s0 = Suit(heals, still), s6 = Suit(heals, stillInMovingFight);
    check(s6[HT] / s6[RJ] > s0[HT] / s0[RJ] && s6[RJ] == s0[RJ],
          "standing still in a fight full of movement: the cast-time answers first, the instant saved");
    check(std::fabs(Movement(heals[HT], stillInMovingFight) - 1.6) < 1e-9, "60% of the phase spent moving: a cast-time answer counts 1.6");
    Moving tracker;
    tracker.Step(15, true);
    tracker.Step(5, false);
    tracker.Step(-5, true);
    check(std::fabs(tracker.Share() - 0.75) < 1e-9, "fifteen seconds moving and five still: three quarters of the phase moving (a step back in time ignored)");
    tracker.Phase();
    check(tracker.Share() == 0 && tracker.seen == 0, "a phase change starts the measure again");
    // }}}

    // {{{ 5: empowered moments
    Answer swiftness{ 0.0, 0, 0, false, false, true };
    Moment early = Ally(50, 70, 60);
    early.fightDone = 0.2;
    check(Empowered(swiftness, early) == HOLD, "a cooldown early in the fight, nothing up: held (leaned away from, not forbidden)");
    Moment lust = early;
    lust.empowered = true;
    check(Empowered(swiftness, lust) == EMPOWERED && Empowered(heals[RJ], lust) == 1.0,
          "Bloodlust up: the cooldown goes all in; other answers unchanged");
    Moment late = early;
    late.fightDone = 0.6;
    check(Empowered(swiftness, late) == 1.0, "past the fight's middle: used anyway");
    Moment unknown = early;
    unknown.fightDone = -1;
    check(Empowered(swiftness, unknown) == HOLD, "a fight with no length guessed yet: held");
    Moment dying = early;
    dying.critical = true;
    check(Empowered(swiftness, dying) == 1.0, "a critical concern: used anyway");
    Moment planned = lust;
    planned.planWeight = 0.4;
    check(Empowered(swiftness, planned) == 0.4, "a cooldown plan (625f), when there is one, decides");
    std::vector<Answer> withCd = heals;
    withCd.push_back({ 0.0, 0, 0, true, false, true });
    std::vector<double> e0 = Suit(withCd, early), e1 = Suit(withCd, lust);
    check(UrgencyAndMana(withCd, early)[4] == 1.0, "a cooldown that heals nothing itself isn't compared for speed or cost");
    check(e0[RJ] > 0 && e0[NO] > 0 && std::fabs(e1[4] / e1[RJ] - 16 * (e0[4] / e0[RJ])) < 1e-9,
          "in the suit too: Bloodlust raises the cooldown sixteen-fold against the rest, which it leaves standing");
    // }}}

    // {{{ the suit is the product
    Moment mix = Ally(30, 70, 100);
    mix.concerns = 3;
    mix.movingShare = 0.3;
    std::vector<double> um = UrgencyAndMana(heals, mix), act = Action(heals, mix), suit = Suit(heals, mix);
    bool product = true;
    for (size_t i = 0; i < heals.size(); ++i)
        product = product && std::fabs(suit[i] - um[i] * act[i] * Movement(heals[i], mix) * Empowered(heals[i], mix)) < 1e-12;
    check(product, "the suit is the five measures multiplied");
    // }}}

    std::printf("%d checks, %d failed\n", checks, failures);
    return failures;
}
