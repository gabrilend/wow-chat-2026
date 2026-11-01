// seat-check.cpp - checks buddies_healer_seat.h (issue 625i): who holds
// the healer's seat, when it is out of mana and when ready again, who takes
// it when the healer falls, and how the answers of the seat and of the
// others able to heal lean by it.

#include "buddies_forward_pass.h"
#include "buddies_healer_seat.h"

#include <cmath>
#include <cstdio>

using namespace BuddyForwardPass;

static int passed = 0, failed = 0;
// {{{ check
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}
// }}}

uint64_t const TANK = 1, PRIEST = 2, DRUID = 3, BOSS = 100;

// {{{ fight
// A warrior tank (6000 of 30000) under a level 80 boss hitting 12000 a
// second before armour; a Holy priest healer (role 2, 40 points in healing
// trees) healing it 4000 a second; a Balance druid with 10 points in
// Restoration doing damage. A minute of the boss left.
static void fight(Snapshot& s, Memory& m, double priestMana)
{
    s.t = 30;
    Member tank;   tank.id = TANK; tank.cls = 1; tank.role = 1; tank.armour = 10000; tank.level = 80; tank.health = 6000; tank.maxHealth = 30000;
    Member priest; priest.id = PRIEST; priest.cls = 5; priest.role = 2; priest.armour = 2000; priest.level = 80; priest.health = 15000; priest.maxHealth = 15000;
    priest.resourceKind = 0; priest.resource = priestMana; priest.maxResource = 20000; priest.healPoints = 40; priest.baseMana = 3863;
    Member druid;  druid.id = DRUID; druid.cls = 11; druid.role = 0; druid.armour = 3000; druid.level = 80; druid.health = 16000; druid.maxHealth = 16000;
    druid.resourceKind = 0; druid.resource = 15000; druid.maxResource = 18000; druid.healPoints = 10; druid.baseMana = 3496;
    s.party = { tank, priest, druid };
    Enemy boss; boss.id = BOSS; boss.rank = 3; boss.level = 80; boss.health = 60000; boss.maxHealth = 400000; boss.attacking = TANK;
    boss.threat = { { TANK, { 10000, 2, 0, true } }, { DRUID, { 6000, 2, 0, false } }, { PRIEST, { 3000, 2, 0, false } } };
    s.enemies = { boss };
    double through = 1.0 - BuddyMarks::ArmourReduction(10000, 80);
    for (int t = 1; t <= 30; ++t)
    {
        m.Add({ double(t - 1), HIT, BOSS, TANK, 0, 12000 * through, true });
        m.Add({ double(t - 1), HEAL, PRIEST, TANK, 0, 4000, false });
        m.Sample(t, 90000 - 1000.0 * t);
    }
    m.Forget(s.t);
}
// }}}

int main()
{
    Snapshot s; Memory m;
    fight(s, m, 15000);
    BuddySeat::Heal heal = BuddySeat::CheapestHeal(5, 3863);
    std::printf("   (the priest's cheapest heal: %.0f mana for %.0f health)\n", heal.cost, heal.amount);
    check(heal.cost > 0 && heal.amount > 0, "a priest's cheapest heal is read from the game's tables");
    check(BuddySeat::CheapestHeal(1, 0).cost == 0, "a warrior has none");

    // who holds it
    BuddySeat::Seat seat = BuddySeat::Now(s, m, {}, 60);
    check(seat.holder == 1 && !seat.oom, "the priest, the party's healer, holds the seat, with mana to spare");

    // out of mana, and back, with no flicker at the line
    s.party[1].resource = heal.cost * 0.5;
    seat = BuddySeat::Now(s, m, seat, 60);
    check(seat.holder == 1 && seat.oom, "under its cheapest heal's cost: out of mana (\"oom\"), still in the seat");
    s.party[1].resource = heal.cost * 1.5;
    seat = BuddySeat::Now(s, m, seat, 60);
    double ready = BuddySeat::ReadyAt(s.party[1], m.HealingPerSecond(PRIEST, 30), 60);
    check(seat.oom, "a heal and a half back: still out of mana (ready only with enough for the rest of the fight)");
    check(std::fabs(ready - std::min(20000.0, 4000.0 * 60 / (heal.amount / heal.cost))) < 1e-6, "ready at its own healing for the fight's last minute, at its heal's health a mana");
    s.party[1].resource = ready;
    seat = BuddySeat::Now(s, m, seat, 60);
    check(!seat.oom, "with that much: ready again");

    // the healer falls: the one able to heal with the most mana takes it
    Snapshot fallen = s;
    fallen.party[1].health = 0;
    BuddySeat::Seat taken = BuddySeat::Now(fallen, m, seat, 60);
    check(taken.holder == 2, "the priest fallen: the druid, with some Restoration and the most mana, takes the seat");
    fallen.party[2].healPoints = 0;
    check(BuddySeat::Now(fallen, m, seat, 60).holder == -1, "no one able to heal: the seat is empty");

    // the answers lean by the seat
    BuddySeat::Seat fine{ 1, false }, dry{ 1, true };
    auto druidFine = Leans(s, m, 2, 0, &fine), druidDry = Leans(s, m, 2, 0, &dry), priestDry = Leans(s, m, 1, 0, &dry), priestFine = Leans(s, m, 1, 0, &fine);
    std::printf("   (rejuvenation: seat fine %.3f, seat dry %.3f; the priest's flash heal: fine %.3f, dry %.3f)\n",
                druidFine["rejuvenation"], druidDry["rejuvenation"], priestFine["flash heal"], priestDry["flash heal"]);
    check(druidFine["rejuvenation"] == 1.0, "the seat fine: the druid's Rejuvenation doesn't lean (it does its own job)");
    check(druidDry["rejuvenation"] > 1.0, "the seat out of mana: the druid's Rejuvenation leans in to help");
    check(priestDry["flash heal"] == 0.05 && priestFine["flash heal"] > 1.0, "the priest out of mana stops casting its heals; with mana they lean toward the dying tank");
    check(druidFine["wrath"] == druidDry["wrath"], "the druid's damage spells don't change with the seat");

    // Innervate: on the seat while it is dry (625l), not otherwise
    std::map<std::string, int> to;
    auto inn = Leans(s, m, 2, 0, &dry, &to);
    check(to.count("innervate") && to["innervate"] == 1 && inn["innervate"] > 1.0, "the seat dry: the druid's Innervate leans in, on the priest");
    to.clear();
    Leans(s, m, 2, 0, &fine, &to);
    check(!to.count("innervate"), "the seat fine: no Innervate asked for");

    std::printf("\n%d passed, %d failed\n", passed, failed);
    return failed == 0 ? 0 : 1;
}
