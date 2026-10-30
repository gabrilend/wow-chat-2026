// pass-check.cpp - checks buddies_forward_pass.h (issue 625n): one step
// from a snapshot and its minute to the party's verdict, on a made-up boss
// fight, and answers tried as if given, each worth the shortfall it takes
// away.

#include "buddies_forward_pass.h"

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

static bool near(double a, double b, double by = 1e-6) { return std::fabs(a - b) < by; }

uint64_t const TANK = 1, OFFTANK = 2, HEALER = 3, ROGUE = 4, BOSS = 100;
double const RAW = 12000;                                                 // the boss's real damage a second

// {{{ fight
// A level 80 boss hitting a warrior tank (10000 armour, 6000 of 30000
// health) for 12000 a second before armour; a priest healing the tank 4000
// a second; a paladin off-tank (9000 armour, full at 28000) and a rogue
// behind. Thirty seconds recorded; the boss's 60000 health falling 1000 a
// second, so a minute left.
static void fight(Snapshot& s, Memory& m)
{
    s.t = 30;
    Member tank;    tank.id = TANK;       tank.cls = 1; tank.role = 1; tank.armour = 10000; tank.level = 80; tank.health = 6000;  tank.maxHealth = 30000;
    Member off;     off.id = OFFTANK;     off.cls = 2;  off.role = 1;  off.armour = 9000;   off.level = 80;  off.health = 28000;  off.maxHealth = 28000;
    Member healer;  healer.id = HEALER;   healer.cls = 5; healer.role = 2; healer.armour = 2000; healer.level = 80; healer.health = 15000; healer.maxHealth = 15000;
    Member rogue;   rogue.id = ROGUE;     rogue.cls = 4; rogue.armour = 4000; rogue.level = 80; rogue.health = 18000; rogue.maxHealth = 18000;
    s.party = { tank, off, healer, rogue };
    Enemy boss; boss.id = BOSS; boss.rank = 3; boss.level = 80; boss.health = 60000; boss.maxHealth = 400000; boss.attacking = TANK;
    boss.threat = { { TANK, { 10000, 2, 0, true } }, { OFFTANK, { 6000, 2, 0, true } }, { ROGUE, { 7000, 2, 0, true } }, { HEALER, { 3000, 2, 0, false } } };
    s.enemies = { boss };
    double through = 1.0 - BuddyMarks::ArmourReduction(10000, 80);
    for (int t = 1; t <= 30; ++t)
    {
        m.Add({ double(t - 1), HIT, BOSS, TANK, 0, RAW * through, true });
        m.Add({ double(t - 1), HEAL, HEALER, TANK, 0, 4000, false });
        m.Sample(t, 90000 - 1000.0 * t);
    }
    m.Forget(s.t);
}
// }}}

int main()
{
    Snapshot s; Memory m;
    fight(s, m);
    Verdict v = Step(s, m);
    double through = 1.0 - BuddyMarks::ArmourReduction(10000, 80);
    double loss = RAW * through - 4000;

    check(v.kind == BuddyPlan::Fight::Boss, "a boss among the enemies: a boss fight");
    check(v.leftKnown && near(v.left, 60, 1e-6), "the boss's 60000 health falling 1000 a second: a minute left");
    check(v.attention[0] == 0, "the boss attacks the tank");
    check(near(v.hits[0], RAW, 1e-3), "the boss's real damage read back through the tank's armour: 12000 a second");
    check(near(v.taken[0], through) && near(v.healing[0], 4000), "the tank lets through 60% by armour, and is healed 4000 a second");
    check(near(v.timeToDeath[0], 6000 / loss), "the tank, losing 3244 a second, dies in under 2 seconds");
    check(near(v.shortfall, loss * 60 - 6000, 1e-3), "the party's curve points at a dead tank: the shortfall is a minute of that loss less its health");
    check(v.strongest == 0, "the boss is the hardest hitter");

    // answers, tried as if given: each worth the shortfall it takes away
    Answer wall;  wall.extras = { { 0, BuddyMarks::OfAbility(1, "shield wall"), 12 } };
    Answer loh;   loh.healed = 0; loh.heal = 28000;
    Answer taunt; taunt.taunter = 1; taunt.enemy = 0;
    double wWall = Worth(s, m, wall), wLoh = Worth(s, m, loh);
    Verdict afterTaunt;
    double wTaunt = Worth(s, m, taunt, &afterTaunt);
    std::printf("   (worths: Shield Wall %.0f, Lay on Hands %.0f, the off-tank's taunt %.0f)\n", wWall, wLoh, wTaunt);
    check(wWall > 0 && wLoh > 0, "Shield Wall and Lay on Hands both turn the curve");
    check(near(wLoh, 24000, 1e-3), "Lay on Hands is worth what it adds before the tank's health is full: 24000");
    check(afterTaunt.attention[0] == 1 && near(afterTaunt.healing[1], 4000) && near(afterTaunt.healing[0], 0),
          "the off-tank's taunt: the boss turns to the paladin, and the healing follows it");
    check(near(afterTaunt.hits[0], RAW, 1e-3), "a tried taunt doesn't change what the boss has done: still 12000 real");

    // a debuff on the tank (+100% damage taken for 20 seconds, the kind a
    // boss stacks on its tank): the taunt is worth more, and the tanks'
    // plan hands the boss to the paladin
    Snapshot marked = s;
    marked.party[0].marks = { { 9999, 20, 1, BOSS, { { 87, 100, 127, 0, 1 } } } };
    Memory m2;
    {
        double through2 = through * 2.0;
        for (int t = 1; t <= 30; ++t)
        {
            m2.Add({ double(t - 1), HIT, BOSS, TANK, 0, RAW * through2, true });
            m2.Add({ double(t - 1), HEAL, HEALER, TANK, 0, 4000, false });
            m2.Sample(t, 90000 - 1000.0 * t);
        }
        m2.Forget(30);
    }
    Verdict vm = Step(marked, m2);
    check(near(vm.hits[0], RAW, 1e-3), "the boss's real damage read back through the debuff too: still 12000");
    double wTauntMarked = Worth(marked, m2, taunt);
    check(wTauntMarked > wTaunt, "with the tank debuffed, the off-tank's taunt is worth more");
    check(vm.tanks.holder == 1 || vm.tanks.to == 1, "the tanks' plan hands the boss to the paladin");

    // the desired state beyond victory: seconds of the group's time
    // Bloodlust, the party's damage x1.3 for 40 seconds: the boss's 60000
    // falls 1300 a second for 40 (52000), the last 8000 in 8: 48 seconds,
    // not 60
    Answer lust; lust.burstFactor = 1.3; lust.burstLasts = 40;
    Score sl = Judge(s, m, lust, 0);
    check(near(sl.seconds, 12, 1e-6), "Bloodlust brings the end 12 seconds sooner");
    check(sl.health > 0, "and a shorter fight leaves the dying tank less short too");

    // a healing potion (4000 health, 2000 copper at the cheapest the buddy
    // could get another), the group earning 36 gold an hour (100 copper a
    // second): 20 seconds of its time
    double const PER_HOUR = 360000;
    Answer potion; potion.healed = 0; potion.heal = 4000; potion.gold = 2000;
    Answer nothing;
    Score sp = Judge(s, m, potion, PER_HOUR), sn = Judge(s, m, nothing, PER_HOUR);
    check(sp.health > 0 && Better(sp, sn), "the tank dying: the potion is drunk, whatever it costs (health first)");
    Memory calm;
    for (int t = 1; t <= 30; ++t)
    {
        calm.Add({ double(t - 1), HIT, BOSS, TANK, 0, RAW * through, true });
        calm.Add({ double(t - 1), HEAL, HEALER, TANK, 0, 9000, false });
        calm.Sample(t, 90000 - 1000.0 * t);
    }
    calm.Forget(30);
    Score cp = Judge(s, calm, potion, PER_HOUR), cn = Judge(s, calm, nothing, PER_HOUR);
    check(near(cp.health, 0) && near(cp.seconds, -20, 1e-6), "the tank healed faster than hurt: the potion saves no one and costs 20 seconds of earning");
    check(Better(cn, cp), "so it isn't drunk");
    check(near(Judge(s, calm, potion, 0).seconds, 0), "a group with nothing earned yet: gold can't be weighed, and counts nothing");

    // each buddy's answers, leaned by the share of the gap they close: the
    // warrior tank (0), the paladin off-tank (1), the priest healer (2)
    auto warrior = Leans(s, m, 0, PER_HOUR), paladin = Leans(s, m, 1, PER_HOUR), priest = Leans(s, m, 2, PER_HOUR);
    std::printf("   (leans: shield wall %.3f; lay on hands %.3f, hand of reckoning %.3f; pain suppression %.3f, power word: shield %.3f, flash heal %.3f)\n",
                warrior["shield wall"], paladin["lay on hands"], paladin["hand of reckoning"], priest["pain suppression"], priest["power word: shield"], priest["flash heal"]);
    check(near(warrior["shield wall"], 1.0 + wWall / v.shortfall, 1e-6), "the tank's Shield Wall leans by the share of the shortfall it takes away");
    check(paladin["lay on hands"] > 1.0 && priest["pain suppression"] > 1.0 && priest["power word: shield"] > 1.0 && priest["flash heal"] > 1.0,
          "the paladin's Lay on Hands and the priest's Pain Suppression, shield and Flash Heal all lean toward the dying tank");
    check(paladin["hand of reckoning"] > 1.0, "the paladin's taunt leans in too: the boss is better on it than on a tank under 2 seconds from dead");
    check(near(warrior["taunt"], 1.0), "the tank's own taunt changes nothing (it holds the boss already): no lean");
    check(warrior.count("mortal strike") && near(warrior["mortal strike"], 1.0), "Mortal Strike's mark lands on an enemy's healing, which these curves don't hold: no lean");
    auto calmPriest = Leans(s, calm, 2, PER_HOUR);
    check(near(calmPriest["flash heal"], 1.0) && near(calmPriest["pain suppression"], 1.0), "the tank healed faster than hurt: no lean toward the emergencies");

    // windows already open: Bloodlust on the rogue, who deals all the
    // party's damage, 40 seconds left of it. The boss's health was seen
    // falling 1000 a second with Bloodlust on, so 769 without: 40 seconds at
    // 1000 (40000), the last 20000 at 769, 26 more: 66 seconds, not 60
    {
        Snapshot w = s; Memory mw;
        for (int t = 1; t <= 30; ++t)
        {
            mw.Add({ double(t - 1), HIT, BOSS, TANK, 0, RAW * through, true });
            mw.Add({ double(t - 1), HEAL, HEALER, TANK, 0, 4000, false });
            mw.Add({ double(t - 1), HIT, ROGUE, BOSS, 0, 1000, true });
            mw.Sample(t, 90000 - 1000.0 * t);
        }
        mw.Forget(30);
        check(OpenWindows(w, mw).empty(), "no empowering buff on anyone: no window open");
        w.party[3].marks = { { 2825, 40, 1, ROGUE, {} } };
        auto open = OpenWindows(w, mw);
        check(open.size() == 1 && near(open[0].factor, 1.3) && near(open[0].length, 40), "Bloodlust on the rogue doing all the damage: the party's damage x1.3 for its 40 seconds");
        Verdict vw = Step(w, mw);
        check(near(vw.left, 40 + 20000 / (1000 / 1.3), 1e-6), "the fall measured under Bloodlust counted once: 66 seconds left, not 60");
        w.party[3].marks = {};
        w.party[1].marks = { { 31884, 20, 1, OFFTANK, {} } };
        check(OpenWindows(w, mw).empty(), "Avenging Wrath on the paladin, who has dealt nothing: no window on the party's damage");
    }

    // the cooldown timeline in the leans: a mage (in the rogue's place)
    // with Arcane Power ready now and Icy Veins ready in 10 seconds, a
    // minute of the boss left: Arcane Power waits to go with Icy Veins (its
    // 15 seconds inside Icy Veins' 20: worth 1.2 against 1 alone, and no
    // second use fits either way), so it leans away to 1/1.2 now
    {
        Snapshot w = s;
        w.party[3].cls = 8;
        w.party[3].cooldowns = { { 12042, "arcane power", 0 }, { 12472, "icy veins", 10 } };
        auto pw = PlanWeights(w, m, 3, Step(w, m));
        std::printf("   (mage: arcane power %.3f, icy veins %.3f)\n", pw["arcane power"], pw["icy veins"]);
        check(near(pw["arcane power"], 1.0 / 1.2, 1e-6), "Arcane Power ready now waits 10 seconds for Icy Veins: it leans away to 1/1.2");
        check(near(Leans(w, m, 3, PER_HOUR)["arcane power"], 1.0 / 1.2, 1e-6), "and the mage's lean for it says so");
        w.party[3].cooldowns = { { 12472, "icy veins", 0 } };
        pw = PlanWeights(w, m, 3, Step(w, m));
        check(!pw.count("arcane power") && near(pw["icy veins"], 1.0), "a mage who never learned Arcane Power doesn't hold Icy Veins for it");
    }

    // an enemy's cast in progress: the boss 2 seconds from landing 20000
    // on the priest (15000 health, no one hitting it), in the calm fight
    // (the tank holding): the priest's own Pain Suppression and shield lean
    // toward the priest now
    {
        Snapshot c = s;
        c.enemies[0].casting = 99999; c.enemies[0].castLeft = 2; c.enemies[0].castDamage = 20000; c.enemies[0].castOn = HEALER;
        Verdict vc = Step(c, calm);
        check(near(vc.shortOf[2], 5000, 1e-6), "the priest, 15000 against a 20000 cast: 5000 short");
        auto lc = Leans(c, calm, 2, PER_HOUR);
        std::printf("   (the cast coming: pain suppression %.3f, power word: shield %.3f)\n", lc["pain suppression"], lc["power word: shield"]);
        check(lc["pain suppression"] > 1.5 && lc["power word: shield"] > 1.0, "Pain Suppression (40% off) and the shield lean hard toward the priest about to be hit");
        c.enemies[0].castOn = 0;
        check(near(Step(c, calm).shortOf[2], 0), "a cast on no one known: nothing coming at the priest");
    }

    std::printf("\n%d passed, %d failed\n", passed, failed);
    return failed == 0 ? 0 : 1;
}
