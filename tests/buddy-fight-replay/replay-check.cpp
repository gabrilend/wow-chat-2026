
#include "buddies_fight_replay.h"
#include "buddies_forward_pass.h"

#include <cmath>
#include <cstdio>

using namespace BuddyFightReplay;

static int passed = 0, failed = 0;
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}

int main()
{
    uint64_t const TANK = 1, HEALER = 2, MAGE = 3, BOSS = 100;
    double const through = 1.0 - BuddyMarks::ArmourReduction(10000, 80);

    std::string written;
    std::vector<double> played;
    Memory live;
    double bossHealth = 120000;
    for (int t = 1; t <= 40; ++t)
    {
        std::vector<BuddyFightState::Event> events = {
            { t - 0.5, BuddyFightState::HIT, BOSS, TANK, 0, 12000 * through * (t >= 10 && t < 22 ? 0.4 : 1.0), true },
            { t - 0.4, BuddyFightState::HEAL, HEALER, TANK, 2061, 3000, false },
            { t - 0.3, BuddyFightState::HIT, MAGE, BOSS, 42833, 2500, false },
        };
        bossHealth -= 2500;
        for (auto const& e : events) live.Add(e);

        Snapshot s;
        s.t = t;
        Member tank;  tank.id = TANK; tank.cls = 1; tank.role = 1; tank.armour = 10000; tank.level = 80; tank.health = 20000; tank.maxHealth = 30000;
        tank.cooldowns = { { 871, "shield wall", t >= 10 ? 300.0 - (t - 10) : 0.0 } };
        if (t >= 10 && t < 22) tank.marks.push_back({ 871, double(22 - t), 1, TANK, { { 87, -60, 127, 0, 1 } } });
        if (t >= 20) tank.marks.push_back({ 9999, 30.0, 1, BOSS, { { 87, 5 * (t - 19), 127, 0, 1 } } });
        Member healer; healer.id = HEALER; healer.cls = 5; healer.role = 2; healer.armour = 2000; healer.level = 80; healer.health = 15000; healer.maxHealth = 15000;
        Member mage;   mage.id = MAGE; mage.cls = 8; mage.armour = 1500; mage.level = 80; mage.health = 14000; mage.maxHealth = 14000;
        s.party = { tank, healer, mage };
        Enemy boss; boss.id = BOSS; boss.rank = 3; boss.level = 80; boss.health = bossHealth; boss.maxHealth = 120000; boss.attacking = TANK;
        boss.threat = { { TANK, { 50000.0 + t, 2, 0, true } }, { MAGE, { 30000, 2, 0, false } }, { HEALER, { 9000, 2, 0, false } } };
        s.enemies = { boss };

        live.Forget(s.t);
        live.Sample(s.t, bossHealth);
        BuddyForwardPass::Verdict v = BuddyForwardPass::Step(s, live);
        played.push_back(v.shortfall);
        written += Write(events, s, v.shortfall, v.left, v.leftKnown ? 1 : 0);
    }

    std::string error;
    std::vector<BuddyFightReplay::Step> steps = Read(written, &error);
    check(error.empty() && steps.size() == 40, "40 written steps read back, every line understood");
    check(steps[15].snapshot.party[0].marks.size() == 1 && steps[15].snapshot.party[0].marks[0].effects[0].amount == -60,
          "Shield Wall's -60% is on the tank at second 16, as written");
    check(steps[0].snapshot.party[0].cooldowns[0].name == "shield wall", "a name with a space comes back with its space");
    int same = 0, i = 0;
    double worst = 0;
    Replay(steps, [&](BuddyFightReplay::Step const& st, Memory const& m) {
        BuddyForwardPass::Verdict v = BuddyForwardPass::Step(st.snapshot, m);
        worst = std::max(worst, std::fabs(v.shortfall - st.shortfall));
        if (std::fabs(v.shortfall - played[i]) < 1e-6 * std::max(1.0, played[i])) ++same;
        ++i;
    });
    std::printf("   (largest difference from the verdicts written in the game: %.3g)\n", worst);
    check(same == 40, "replayed, every step's verdict is the one the fight gave as it was played");

    std::string broken = written.substr(0, written.find("\n.\n") + 3) + "M 1 2 3\n";
    Read(broken, &error);
    check(error.find("a member short of its fields") != std::string::npos && error.find("line ") == 0, "a member line cut short is named, with its line number");
    Read("Q nonsense\n", &error);
    check(error.find("no known kind") != std::string::npos, "a line of no known kind is named");

    std::printf("\n%d passed, %d failed\n", passed, failed);
    return failed == 0 ? 0 : 1;
}
