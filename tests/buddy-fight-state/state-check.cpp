// state-check.cpp - checks buddies_fight_state.h (issue 625n): the
// minute of events and its running sums, checked against reading the
// whole minute again on a long made-up fight; the enemies' health read as
// the fight's time left; what kind of fight a snapshot is, and what the
// marks on someone add up to.

#include "buddies_fight_state.h"

#include <cmath>
#include <cstdio>

using namespace BuddyFightState;

static int passed = 0, failed = 0;
// {{{ check
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}
// }}}

static bool near(double a, double b, double by = 1e-6) { return std::fabs(a - b) < by; }

int main()
{
    uint64_t const TANK = 1, HEALER = 2, BOSS = 100, ADD = 101;

    // a steady fight: the boss hits the tank for 500 each second, the
    // healer heals it 300 each second
    Memory m;
    for (int s = 1; s <= 90; ++s)
    {
        m.Add({ double(s), HIT, BOSS, TANK, 0, 500, true });
        m.Add({ double(s), HEAL, HEALER, TANK, 0, 300, false });
    }
    m.Forget(90);
    check(near(m.TakenPerSecond(TANK, 90), 500, 10) && near(m.HealedPerSecond(TANK, 90), 300, 10), "after 90 seconds: 500 taken and 300 healed a second, over the last minute");
    check(m.Count() <= 2 * 61, "only the last minute is kept");
    check(near(m.DealtPerSecond(BOSS, 90), 500, 10) && near(m.PhysicalShare(BOSS), 1.0), "the boss deals 500 a second, all physical");

    // at a fight's start the rate covers only the time so far
    Memory start;
    start.Add({ 0, HIT, BOSS, TANK, 0, 1000, true });
    start.Add({ 2, HIT, BOSS, TANK, 0, 1000, true });
    start.Forget(4);
    check(near(start.TakenPerSecond(TANK, 4), 2000.0 / 4.0), "4 seconds in: 2000 over 4 seconds, not over a minute");
    Memory one;
    one.Add({ 10, HIT, BOSS, TANK, 0, 800, true });
    one.Forget(10);
    check(near(one.TakenPerSecond(TANK, 10), 800), "a single first hit counts over at least a second, not as a flood");

    // physical share by the dealer's own damage
    Memory mixed;
    mixed.Add({ 1, HIT, ADD, TANK, 0, 300, true });
    mixed.Add({ 2, HIT, ADD, TANK, 99, 700, false });
    check(near(mixed.PhysicalShare(ADD), 0.3), "an enemy that dealt 300 physical and 700 magic: 30% physical");
    check(near(mixed.PhysicalShare(999), 1.0), "an enemy not yet seen dealing any: counted as physical");

    // the running sums agree with reading the whole minute again, on a
    // long uneven made-up fight
    {
        Memory run;
        std::vector<Event> all;
        unsigned seed = 625;
        auto draw = [&](double lo, double hi) { seed = seed * 1103515245u + 12345u; return lo + (hi - lo) * ((seed >> 8) & 0xffff) / 65535.0; };
        double t = 0, worst = 0;
        for (int n = 0; n < 4000; ++n)
        {
            t += draw(0, 0.2);
            Event e{ t, draw(0, 1) < 0.6 ? HIT : HEAL, draw(0, 1) < 0.5 ? BOSS : ADD, draw(0, 1) < 0.7 ? TANK : HEALER, 0, draw(10, 900), draw(0, 1) < 0.5 };
            run.Add(e);
            all.push_back(e);
            if (n % 97 == 0)
            {
                run.Forget(t);
                double taken = 0, healed = 0;
                for (Event const& x : all)
                    if (x.t >= t - 60.0 && x.to == TANK) { if (x.kind == HIT) taken += x.amount; else healed += x.amount; }
                double covered = run.Covered(t);
                worst = std::max(worst, std::fabs(run.TakenPerSecond(TANK, t) - taken / covered));
                worst = std::max(worst, std::fabs(run.HealedPerSecond(TANK, t) - healed / covered));
            }
        }
        std::printf("   (largest difference from re-reading the minute: %.2g)\n", worst);
        check(worst < 1e-6, "4000 uneven events: the running sums match re-reading the whole minute");
    }

    // the enemies' health over the readings: the fight's time left
    Memory fight;
    for (int s = 0; s <= 10; ++s) fight.Sample(s, 20000 - 1000.0 * s);
    BuddyFight::Guess g = fight.FightLeft(10, 10000, {});
    check(g.known && near(g.seconds, 10, 1e-6), "10000 health left falling 1000 a second: 10 seconds");

    // the snapshot: what kind of fight, and what marks add up to
    Snapshot s;
    s.enemies = { Enemy{}, Enemy{} };
    s.enemies[0].rank = 1;
    s.enemies[1].rank = 0;
    check(FightKind(s) == BuddyPlan::Fight::Trash, "elites and normals: trash");
    s.enemies[1].rank = 2;
    check(FightKind(s) == BuddyPlan::Fight::Boss, "a rare elite among them: a boss fight");
    std::vector<Mark> marks = { { 871, 12, 1, TANK, BuddyMarks::OfAbility(1, "shield wall") }, { 999, 10, 3, BOSS, { { 87, 10, 127, 0, 1 } } } };
    BuddyMarks::Modifiers mod = ModifiersOf(marks);
    check(near(mod.takenPhysical, 0.4 * 1.3), "Shield Wall and a boss's +10% debuff at 3 stacks: 0.4 x 1.3");

    std::printf("\n%d passed, %d failed\n", passed, failed);
    return failed == 0 ? 0 : 1;
}
