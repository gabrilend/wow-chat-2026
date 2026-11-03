
#include "buddies_forward_pass.h"
#include "buddies_healer_seat.h"

#include <cmath>
#include <cstdio>

using namespace BuddyForwardPass;
using BuddySeat::Seats;

static int passed = 0, failed = 0;
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}

uint64_t const TANK = 1, PRIEST = 2, DRUID = 3, PALADIN = 4, BOSS = 100;

static void fight(Snapshot& s, Memory& m, double priestMana)
{
    s.t = 30;
    Member tank;   tank.id = TANK; tank.cls = 1; tank.role = 1; tank.armour = 10000; tank.level = 80; tank.health = 6000; tank.maxHealth = 30000; tank.talentPoints = 51;
    Member priest; priest.id = PRIEST; priest.cls = 5; priest.role = 2; priest.armour = 2000; priest.level = 80; priest.health = 15000; priest.maxHealth = 15000;
    priest.resourceKind = 0; priest.resource = priestMana; priest.maxResource = 20000; priest.healPoints = 40; priest.talentPoints = 51; priest.baseMana = 3863;
    Member druid;  druid.id = DRUID; druid.cls = 11; druid.role = 0; druid.armour = 3000; druid.level = 80; druid.health = 16000; druid.maxHealth = 16000;
    druid.resourceKind = 0; druid.resource = 15000; druid.maxResource = 18000; druid.healPoints = 17; druid.talentPoints = 51; druid.baseMana = 3496;
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
        m.SampleResource(PRIEST, t, priestMana + 300.0 * (30 - t));
        m.SampleResource(DRUID, t, 15000);
    }
    m.Forget(s.t);
}
static Member Paladin()
{
    Member p; p.id = PALADIN; p.cls = 2; p.role = 0; p.armour = 9000; p.level = 80; p.health = 20000; p.maxHealth = 20000;
    p.resourceKind = 0; p.resource = 12000; p.maxResource = 16000; p.healPoints = 51; p.talentPoints = 51; p.baseMana = 3500;
    return p;
}

int main()
{
    Snapshot s; Memory m;
    fight(s, m, 15000);
    BuddySeat::Heal heal = BuddySeat::CheapestHeal(5, 3863);
    check(heal.cost > 0 && heal.amount > 0, "a priest's cheapest heal is read from the game's tables");

    check(BuddySeat::HealerShare(s.party[1]) == 1.0, "the priest, 40 of 51 points healing (two thirds or more): a whole healer");
    check(std::fabs(BuddySeat::HealerShare(s.party[2]) - 1.0 / 3.0) < 1e-9, "the druid, a third of its points in Restoration: a third of a healer");
    check(BuddySeat::HealerShare(s.party[0]) == 0.0, "the warrior: none");
    Member young = s.party[1]; young.talentPoints = 0; young.healPoints = 0;
    check(BuddySeat::HealerShare(young) == 1.0, "a healer by role with no points spent yet (a low level): a whole healer");

    Seats seats = BuddySeat::Now(s, m, {}, 60);
    check(seats.holders == std::vector<int>{ 1 } && seats.want == 1.0 && !seats.short_, "the fight begins: the priest holds the seat; the party keeps one whole healer");
    Seats again = BuddySeat::Now(s, m, seats, 60);
    check(again.holders == seats.holders, "nothing happened: the seat doesn't change hands");
    Snapshot richer = s;
    richer.party[2].resource = 18000;
    check(BuddySeat::Now(richer, m, seats, 60).holders == std::vector<int>{ 1 }, "someone else with more mana doesn't take it: only running dry or falling changes it");

    s.party[1].resource = heal.cost * 0.5;
    Seats dry = BuddySeat::Now(s, m, seats, 60);
    check(BuddySeat::Has(dry.dry, 1) && !BuddySeat::Has(dry.holders, 1), "the priest under its cheapest heal: out of mana, out of the seat");
    check(dry.holders == std::vector<int>{ 2 } && dry.short_, "the druid takes a seat, but a third of a healer doesn't make the one the fight began with: short");

    Snapshot four = s; four.party.push_back(Paladin());
    Seats seats4 = BuddySeat::Now(four, m, seats, 60);
    check(seats4.holders == std::vector<int>{ 3 } && !seats4.short_, "a Holy paladin there: it takes the seat, a whole healer, nothing short");
    four.party[1].resource = heal.cost * 1.5;
    Seats later = BuddySeat::Now(four, m, seats4, 60);
    check(BuddySeat::Has(later.dry, 1), "a heal and a half back: still out of mana");
    four.party[1].resource = BuddySeat::ReadyAt(four.party[1], m.HealingPerSecond(PRIEST, 30), 60);
    later = BuddySeat::Now(four, m, later, 60);
    check(!BuddySeat::Has(later.dry, 1) && later.holders == std::vector<int>{ 3 }, "ready again: no longer dry, and the paladin keeps the seat (it hasn't run dry)");

    Snapshot fell = four; fell.party[3].health = 0;
    Seats after = BuddySeat::Now(fell, m, later, 60);
    check(after.holders == std::vector<int>{ 1 } && !after.short_, "the paladin falls: the priest, ready, takes the seat back");

    auto druidFilled = Leans(four, m, 2, 0, &seats4), druidShort = Leans(s, m, 2, 0, &dry), priestDry = Leans(s, m, 1, 0, &dry);
    std::printf("   (rejuvenation: seats filled %.3f, seats short %.3f; the dry priest's flash heal %.3f)\n",
                druidFilled["rejuvenation"], druidShort["rejuvenation"], priestDry["flash heal"]);
    check(druidFilled["rejuvenation"] == 1.0, "the seats filled by the paladin: the druid's Rejuvenation doesn't lean (it does its own job)");
    check(druidShort["rejuvenation"] > 1.0, "the seats short: the druid's Rejuvenation leans in");
    check(priestDry["flash heal"] == 0.05, "the dry priest stops casting its heals, so its mana comes back");

    Snapshot inn = s; Memory mi;
    fight(inn, mi, 3000);
    std::map<std::string, int> to;
    auto li = Leans(inn, mi, 2, 0, &seats, &to);
    std::printf("   (innervate: %.3f, on member %d)\n", li["innervate"], to.count("innervate") ? to["innervate"] : -1);
    check(to.count("innervate") && to["innervate"] == 1 && li["innervate"] > 1.0, "Innervate goes to the priest, whose mana runs out before the fight ends, and leans in by the healing it buys");
    Snapshot full = s; Memory mf;
    fight(full, mf, 19000);
    to.clear();
    Leans(full, mf, 2, 0, &seats, &to);
    check(!to.count("innervate"), "the priest's mana lasting the fight: Innervate is asked for no one");

    std::printf("\n%d passed, %d failed\n", passed, failed);
    return failed == 0 ? 0 : 1;
}
