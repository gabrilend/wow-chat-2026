// shares-check.cpp - checks one list from every tree a buddy has points in
// (buddies_tree_shares.h) against the owner's design, with no server (issue
// 625c). Built and run by scripts/test-buddy-tree-shares. Each check prints
// "ok" or "FAIL" and what it held; the exit status is the number of failures.

#include "buddies_talent_draw.h"
#include "buddies_tree_shares.h"

#include <cstdio>
#include <random>

using namespace BuddyShares;

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

// {{{ Fight
// A long fight of a 2/1 Restoration/Balance druid (druid tabs: 0 Balance,
// 1 Feral, 2 Restoration). Each step offers Restoration's six answers to
// "an ally hurt" (21.0 to 21.5, the module's own spacing) when someone is
// hurt (every step, or every other), and Balance's two damage answers in
// the same band; the draw (625) picks, each answer's weight its tree's.
// counted: whether the casts are counted (false: the lean never moves).
// Returns the Restoration share of the casts made when both trees offered.
struct Result { double restoShare; int mixed, total; };
static Result Fight(Shares const& s, int steps, bool counted, int hurtEvery, unsigned seed)
{
    std::mt19937 rng(seed);
    std::uniform_real_distribution<double> u(0.0, 1.0);
    Count c;
    int resto = 0, mixed = 0, total = 0;
    for (int step = 0; step < steps; ++step)
    {
        std::vector<Offered> answers;
        if (step % hurtEvery == 0)
            for (int i = 0; i < 6; ++i) answers.push_back({ 2, 21.0 + 0.1 * i });
        answers.push_back({ 0, 21.1 });   // Wrath
        answers.push_back({ 0, 21.0 });   // Starfire
        bool several = FromSeveralTrees(answers);
        int best = -1;
        double bestValue = -1;
        for (size_t i = 0; i < answers.size(); ++i)
        {
            double v = answers[i].relevance * BuddyTalentDraw::Factor(float(Weight(s, c, answers[i].tree)), u(rng));
            if (v > bestValue) { bestValue = v; best = int(i); }
        }
        ++total;
        if (several)
        {
            ++mixed;
            if (answers[best].tree == 2) ++resto;
            if (counted) c.Cast(answers[best].tree);
        }
    }
    return { mixed ? double(resto) / mixed : 0.0, mixed, total };
}
// }}}

int main()
{
    // {{{ the shares
    int restoBalance[3] = { 10, 0, 20 };
    Shares rb = FromPoints(restoBalance, 2);
    check(std::fabs(rb.of[0] - 1.0 / 3) < 1e-9 && rb.of[1] == 0 && std::fabs(rb.of[2] - 2.0 / 3) < 1e-9,
          "a 2/1 Restoration/Balance druid: Balance a third, Restoration two thirds, Feral nothing");
    int level30[3] = { 8, 0, 16 };
    Shares mid = FromPoints(level30, 2);
    check(std::fabs(mid.of[0] - 1.0 / 3) < 1e-9 && std::fabs(mid.of[2] - 2.0 / 3) < 1e-9,
          "the same shape at a lower level (8 and 16 points): the same shares");
    int none[3] = { 0, 0, 0 };
    Shares low = FromPoints(none, 2);
    check(low.of[2] == 1.0 && low.of[0] == 0 && low.of[1] == 0, "no points yet: the role's tree, whole");
    check(Speaks(rb, 0) && Speaks(rb, 2) && !Speaks(rb, 1), "every tree with points speaks, one without doesn't");
    // }}}

    // {{{ the weights and the lean
    Count c;
    check(std::fabs(Weight(rb, c, 0) - 1.0 / 3) < 1e-9 && std::fabs(Weight(rb, c, 2) - 2.0 / 3) < 1e-9,
          "at a fight's start each tree's answers count by its share");
    check(Weight(rb, c, 1) == 0, "a tree with no points offers nothing");
    for (int i = 0; i < 3; ++i) c.Cast(0);   // three Balance casts in a row
    check(Behind(c, rb, 2) > 1.9 && Lean(c, rb, 2) > 1.0 && Lean(c, rb, 0) < 1.0,
          "after three Balance casts Restoration is two behind: it leans in, Balance leans away");
    for (int i = 0; i < 3; ++i) { c.Cast(2); c.Cast(2); c.Cast(0); }
    check(std::fabs(Behind(c, rb, 2) - 2.0) < 1e-9, "the debt is kept while the casts follow the shares");
    Count c2;
    for (int i = 0; i < 100; ++i) c2.Cast(0);
    check(Lean(c2, rb, 2) == LEAN_HIGH && Lean(c2, rb, 0) == LEAN_LOW, "a long run one way is held: the lean stays between its bounds");
    c.Reset();
    check(c.Total() == 0 && Lean(c, rb, 2) == 1.0 && Lean(c, rb, 0) == 1.0, "a new fight starts the count afresh");
    // }}}

    // {{{ casts in the trees' shares, over a long fight
    Result kept = Fight(rb, 3000, true, 1, 7);
    std::printf("     (counted: Restoration %.3f of %d casts)\n", kept.restoShare, kept.mixed);
    check(std::fabs(kept.restoShare - 2.0 / 3) < 0.03,
          "a 2/1 druid offered both trees' answers casts about two thirds Restoration (the owner's 2/3 and 1/3)");
    Result loose = Fight(rb, 3000, false, 1, 7);
    std::printf("     (not counted: Restoration %.3f)\n", loose.restoShare);
    check(std::fabs(loose.restoShare - 2.0 / 3) > 0.08,
          "without the running count, Restoration's six answers against Balance's two drift off the shares");
    Result half = Fight(rb, 6000, true, 2, 11);
    std::printf("     (hurt every other step: Restoration %.3f of %d mixed casts, %d in all)\n", half.restoShare, half.mixed, half.total);
    check(std::fabs(half.restoShare - 2.0 / 3) < 0.03 && half.mixed < half.total,
          "with someone hurt only half the time, the casts that could be either still keep the shares");
    std::vector<Offered> lone = { { 0, 21.1 }, { 0, 21.0 } }, both = { { 0, 21.1 }, { 2, 21.0 } };
    check(!FromSeveralTrees(lone) && FromSeveralTrees(both),
          "only a choice between trees counts: Balance alone (nobody hurt) is not owed back as heals later");
    // }}}

    // {{{ the role's tree first on a shared concern
    // a 2/1 Feral/Restoration druid: Feral (tab 1) is the role's tree
    std::vector<Offered> allyLow = { { 1, 21.0 }, { 2, 21.5 }, { 1, 21.2 }, { 2, 21.1 } };
    std::vector<double> f = RoleFirst(allyLow, 1);
    double r0 = 21.0 * f[0], r1 = 21.5 * f[1], r2 = 21.2 * f[2], r3 = 21.1 * f[3];
    check(f[0] == 1.0 && f[2] == 1.0 && r2 > r0, "the role tree's own answers are left as they are, in their order");
    check(r1 < r0 && r3 < r0, "the other tree's answers fall just below the role tree's lowest");
    check(r1 > r3 && std::fabs((r1 - r3) - 0.4) < 1e-9, "and keep their own order and spacing among themselves");
    check(std::fabs(r1 - (21.0 - ROLE_GAP)) < 1e-9 && r3 > 21.0 - ROLE_GAP - 0.4 - 1e-9,
          "and drop no further than their own spread below it (a concern below, at 20, is not passed)");
    bool neverAbove = true;
    for (double x : f) neverAbove = neverAbove && x <= 1.0;
    check(neverAbove, "nothing is ever lifted");
    std::vector<Offered> already = { { 1, 21.4 }, { 2, 21.0 } };
    std::vector<double> g = RoleFirst(already, 1);
    check(g[0] == 1.0 && g[1] == 1.0, "another tree's answers already below the role's are left alone");
    std::vector<Offered> level = { { 1, 21.0 }, { 2, 21.005 } };
    std::vector<double> e = RoleFirst(level, 1);
    check(21.005 * e[1] < 21.0 - ROLE_GAP + 1e-9, "another tree's answer level with the role's lowest is still put below it");
    std::vector<Offered> noRole = { { 2, 21.4 }, { 0, 21.0 } };
    std::vector<double> h = RoleFirst(noRole, 1);
    check(h[0] == 1.0 && h[1] == 1.0, "a concern the role's tree doesn't answer is left alone");
    // }}}

    // {{{ the feral druid and an ally at low health (the owner's words)
    Feral cat;
    cat.catPoints = 15; cat.bearPoints = 5; cat.secondsToBeat = 6; cat.allySeconds = 10;
    check(AllyLow(cat) == Answer::Strike, "cat talents: pounce on the ally's attackers");
    Feral bear = cat;
    bear.catPoints = 5; bear.bearPoints = 15;
    check(AllyLow(bear) == Answer::PullOff, "bear talents: pull them off");
    Feral strong = cat;
    strong.secondsToBeat = 30; strong.allySeconds = 8;
    check(AllyLow(strong) == Answer::Heal, "too strong to beat in time, the ally can hold on, not under attack: heal");
    Feral struck = strong;
    struck.underAttack = true;
    check(AllyLow(struck) == Answer::Strike, "the same while under attack: no heal");
    Feral dying = strong;
    dying.allySeconds = 2; dying.secondsToBeat = 30;
    check(AllyLow(dying) == Answer::Strike, "an ally that can't hold on for a heal: no heal");
    Feral noHeal = strong;
    noHeal.canHeal = false;
    check(AllyLow(noHeal) == Answer::Strike, "no heal it can cast: no heal");
    Feral tank = strong;
    tank.tank = true; tank.underAttack = true;
    check(AllyLow(tank) == Answer::PullOff, "a tank, the ally not: bear form and pull them off");
    tank.allyTank = true;
    check(AllyLow(tank) == Answer::Strike, "a tank, the ally a tank too: cat form");
    // }}}

    std::printf("%d checks, %d failed\n", checks, failures);
    return failures;
}
