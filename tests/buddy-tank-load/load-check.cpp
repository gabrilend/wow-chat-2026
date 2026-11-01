// load-check.cpp - checks buddies_tank_load.h (issue 625j step 4): whether
// the tank has room for one more enemy, said in the health it would have
// left at the fight's end.

#include "buddies_tank_load.h"

#include <cmath>
#include <cstdio>

using namespace BuddyTankLoad;

static int passed = 0, failed = 0;
// {{{ check
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}
// }}}

static bool near(double a, double b, double by = 1e-6) { return std::fabs(a - b) < by; }

uint64_t const TANK = 1, HEALER = 2, MAGE = 3, E1 = 100, E2 = 101;

// {{{ pack
// Two level 80 enemies on a warrior tank (10000 armour), each hitting 1000
// a second before armour, 20000 health each; a healer healing the tank 1400
// a second; the party bringing the pack's health down 1000 a second, so 40
// seconds left.
static void pack(Snapshot& s, Memory& m, double tankHealth)
{
    s.t = 30;
    Member tank;   tank.id = TANK; tank.cls = 1; tank.role = 1; tank.armour = 10000; tank.level = 80; tank.health = tankHealth; tank.maxHealth = 30000;
    Member healer; healer.id = HEALER; healer.cls = 5; healer.role = 2; healer.armour = 2000; healer.level = 80; healer.health = 15000; healer.maxHealth = 15000;
    Member mage;   mage.id = MAGE; mage.cls = 8; mage.armour = 1500; mage.level = 80; mage.health = 14000; mage.maxHealth = 14000;
    s.party = { tank, healer, mage };
    for (uint64_t id : { E1, E2 })
    {
        Enemy e; e.id = id; e.level = 80; e.health = 20000; e.maxHealth = 40000; e.attacking = TANK;
        e.threat = { { TANK, { 5000, 2, 0, true } }, { MAGE, { 2000, 2, 0, false } } };
        s.enemies.push_back(e);
    }
    double through = 1.0 - BuddyMarks::ArmourReduction(10000, 80);
    for (int t = 1; t <= 30; ++t)
    {
        m.Add({ double(t - 1), HIT, E1, TANK, 0, 1000 * through, true });
        m.Add({ double(t - 1), HIT, E2, TANK, 0, 1000 * through, true });
        m.Add({ double(t - 1), HEAL, HEALER, TANK, 0, 1400, false });
        m.Sample(t, 70000 - 1000.0 * t);
    }
    m.Forget(s.t);
}
// }}}

int main()
{
    double through = 1.0 - BuddyMarks::ArmourReduction(10000, 80);
    Snapshot s; Memory m;
    pack(s, m, 25000);
    Verdict v = Step(s, m);
    Load l = Of(s, v);
    std::printf("   (tank at 25000: loses %.0f a second now, %.0f with one more; %.0f s left, %.0f with one more; room %.0f)\n", l.lossNow, l.lossMore, l.leftNow, l.leftMore, l.room);
    check(l.tank == 0 && l.enemies == 2, "the tank holds both");
    check(near(l.lossNow, 2000 * through - 1400, 1e-3), "now: 2000 let through by armour, less 1400 healing");
    check(near(l.leftNow, 40, 1e-6) && near(l.leftMore, 60, 1e-6), "40 seconds left; 60 with a third like them (20000 more at 1000 a second)");
    check(near(l.rest, 30000), "as it is, the healing outpaces the damage: full at the end");
    check(near(l.room, 25000 - (3000 * through - 1400) * 60, 1e-3) && l.room > 0, "with one more: just above nothing at the end, room to pull");

    Snapshot low; Memory ml;
    pack(low, ml, 15000);
    Load ll = Of(low, Step(low, ml));
    check(ll.room < 0 && ll.rest > 0, "the same tank at 15000: holding fine as it is, but one more would kill it: hold");

    Snapshot none; Memory mn;
    pack(none, mn, 25000);
    for (Enemy& e : none.enemies) { e.attacking = 0; e.threat.clear(); }
    check(Of(none, Step(none, mn)).tank == -1, "no one holding any enemy: no load");

    std::printf("\n%d passed, %d failed\n", passed, failed);
    return failed == 0 ? 0 : 1;
}
