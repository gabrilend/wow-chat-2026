// seat-check.cpp - checks buddies_healer_seat.h (issue 625i): how much of
// a healer each member is, the seats kept to what the fight began with and
// changed only when a holder runs dry or falls, out of mana and ready
// again, how the answers lean by them, and Innervate given to whoever its
// mana would do the most for; and (2026-11-06) the dry member's way of
// fighting for its mana back, Judgement of Wisdom while the healers' mana is
// low, and a player's own "oom" and "ready" heard in the party's chat.

#include "buddies_forward_pass.h"
#include "buddies_healer_seat.h"

#include <cmath>
#include <cstdio>
#include <string>

using namespace BuddyForwardPass;
using BuddySeat::Seats;

static int passed = 0, failed = 0;
// {{{ check
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}
// }}}

uint64_t const TANK = 1, PRIEST = 2, DRUID = 3, PALADIN = 4, BOSS = 100;

// {{{ fight
// A warrior tank (6000 of 30000) under a level 80 boss hitting 12000 a
// second before armour; a Holy priest healer (role 2, 40 of 51 points in
// healing trees) healing it 4000 a second, its mana falling 300 a second; a
// Balance druid with a third of its points in Restoration; a Holy paladin
// (role 0 here, all its points in Holy). A minute of the boss left.
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
// }}}

int main()
{
    Snapshot s; Memory m;
    fight(s, m, 15000);
    BuddySeat::Heal heal = BuddySeat::CheapestHeal(5, 3863);
    check(heal.cost > 0 && heal.amount > 0, "a priest's cheapest heal is read from the game's tables");

    // how much of a healer each is
    check(BuddySeat::HealerShare(s.party[1]) == 1.0, "the priest, 40 of 51 points healing (two thirds or more): a whole healer");
    check(std::fabs(BuddySeat::HealerShare(s.party[2]) - 1.0 / 3.0) < 1e-9, "the druid, a third of its points in Restoration: a third of a healer");
    check(BuddySeat::HealerShare(s.party[0]) == 0.0, "the warrior: none");
    Member young = s.party[1]; young.talentPoints = 0; young.healPoints = 0;
    check(BuddySeat::HealerShare(young) == 1.0, "a healer by role with no points spent yet (a low level): a whole healer");

    // the fight's start: the healers by role, and what they come to
    Seats seats = BuddySeat::Now(s, m, {}, 60);
    check(seats.holders == std::vector<int>{ 1 } && seats.want == 1.0 && !seats.short_, "the fight begins: the priest holds the seat; the party keeps one whole healer");
    Seats again = BuddySeat::Now(s, m, seats, 60);
    check(again.holders == seats.holders, "nothing happened: the seat doesn't change hands");
    Snapshot richer = s;
    richer.party[2].resource = 18000;
    check(BuddySeat::Now(richer, m, seats, 60).holders == std::vector<int>{ 1 }, "someone else with more mana doesn't take it: only running dry or falling changes it");

    // the priest runs dry: a third of a healer isn't one, so everyone able leans in
    s.party[1].resource = heal.cost * 0.5;
    Seats dry = BuddySeat::Now(s, m, seats, 60);
    check(BuddySeat::Has(dry.dry, 1) && !BuddySeat::Has(dry.holders, 1), "the priest under its cheapest heal: out of mana, out of the seat");
    check(dry.holders == std::vector<int>{ 2 } && dry.short_, "the druid takes a seat, but a third of a healer doesn't make the one the fight began with: short");

    // with a Holy paladin in the party, the paladin makes it whole
    Snapshot four = s; four.party.push_back(Paladin());
    Seats seats4 = BuddySeat::Now(four, m, seats, 60);
    check(seats4.holders == std::vector<int>{ 3 } && !seats4.short_, "a Holy paladin there: it takes the seat, a whole healer, nothing short");
    // ready again only with its healing for the rest of the fight
    four.party[1].resource = heal.cost * 1.5;
    Seats later = BuddySeat::Now(four, m, seats4, 60);
    check(BuddySeat::Has(later.dry, 1), "a heal and a half back: still out of mana");
    four.party[1].resource = BuddySeat::ReadyAt(four.party[1], m.HealingPerSecond(PRIEST, 30), 60);
    later = BuddySeat::Now(four, m, later, 60);
    check(!BuddySeat::Has(later.dry, 1) && later.holders == std::vector<int>{ 3 }, "ready again: no longer dry, and the paladin keeps the seat (it hasn't run dry)");

    // a holder falls: refilled
    Snapshot fell = four; fell.party[3].health = 0;
    Seats after = BuddySeat::Now(fell, m, later, 60);
    check(after.holders == std::vector<int>{ 1 } && !after.short_, "the paladin falls: the priest, ready, takes the seat back");

    // the answers lean by the seats
    auto druidFilled = Leans(four, m, 2, 0, &seats4), druidShort = Leans(s, m, 2, 0, &dry), priestDry = Leans(s, m, 1, 0, &dry);
    std::printf("   (rejuvenation: seats filled %.3f, seats short %.3f; the dry priest's flash heal %.3f)\n",
                druidFilled["rejuvenation"], druidShort["rejuvenation"], priestDry["flash heal"]);
    check(druidFilled["rejuvenation"] == 1.0, "the seats filled by the paladin: the druid's Rejuvenation doesn't lean (it does its own job)");
    check(druidShort["rejuvenation"] > 1.0, "the seats short: the druid's Rejuvenation leans in");
    check(priestDry["flash heal"] == 0.05, "the dry priest stops casting its heals, so its mana comes back");

    // Innervate: on whoever its mana does the most for. The priest healing
    // 4000 a second, its mana falling 300 a second from 3000, runs dry in
    // 10 seconds of the minute left: the druid's 225% of 3496 base mana buys
    // it 26 more seconds of healing. The druid's own mana isn't falling.
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


    // {{{ out of mana: fighting the way that brings mana back (2026-11-06)
    check(BuddySeat::Dry(2).first == std::string("seal of wisdom") && BuddySeat::Dry(2).strike == BuddySeat::Strike::Melee,
          "a dry paladin: Seal of Wisdom, then strikes");
    check(BuddySeat::Dry(11).first == std::string("cat form") && BuddySeat::Dry(11).strike == BuddySeat::Strike::Melee,
          "a dry druid: cat form, then claws (\"feral scratch\")");
    check(BuddySeat::Dry(5).first == nullptr && BuddySeat::Dry(5).strike == BuddySeat::Strike::Wand, "a dry priest: its wand, no spell");
    check(BuddySeat::Dry(7).strike == BuddySeat::Strike::Melee && BuddySeat::Dry(1).strike == BuddySeat::Strike::None,
          "a dry shaman strikes; a warrior has no dry way of its own");
    bool named = true;
    for (uint8_t cls : { uint8_t(2), uint8_t(11) })
    {
        bool found = false;
        for (BuddyAbilityRow const& a : BUDDY_ABILITIES) found = found || (a.cls == cls && std::string(a.name) == BuddySeat::Dry(cls).first);
        named = named && found;
    }
    check(named, "the seal and the form are the generated table's own names");
    Snapshot pal = four; Memory mp = m;
    pal.party[3].resource = 1;                               // the paladin, holding the seat, runs dry
    Seats palDry = BuddySeat::Now(pal, mp, seats4, 60);
    check(BuddySeat::Has(palDry.dry, 3), "the paladin holding the seat runs dry");
    check(BuddySeat::DryLean(palDry, 3, 2, "seal of wisdom") == BuddySeat::DRY_FIRST && BuddySeat::DryLean(palDry, 3, 2, "flash of light") == 1.0,
          "the dry paladin leans to Seal of Wisdom, nothing else of its own changed here");
    check(BuddySeat::DryLean(palDry, 2, 11, "cat form") == 1.0, "a druid not dry: cat form doesn't lean for this");
    // }}}

    // {{{ Judgement of Wisdom while the healers' mana is low
    Snapshot js; Memory jm;
    fight(js, jm, 15000);
    Seats jseats = BuddySeat::Now(js, jm, {}, 60);
    check(std::string(BuddySeat::Judgement(js, jseats)) == "judgement of light", "the priest at three quarters mana: Judgement of Light");
    js.party[1].resource = 9000;
    check(std::string(BuddySeat::Judgement(js, jseats)) == "judgement of wisdom", "the priest under half its mana: Judgement of Wisdom");
    js.party[1].resource = 15000;
    Seats jdry = jseats; jdry.dry = { 2 };
    Seats jshort = jseats; jshort.short_ = true;
    check(std::string(BuddySeat::Judgement(js, jdry)) == "judgement of wisdom" && std::string(BuddySeat::Judgement(js, jshort)) == "judgement of wisdom",
          "anyone dry, or the seats short: Judgement of Wisdom");
    // }}}

    // {{{ a player's own words
    BuddySeat::Heard heard;
    heard.Hear(PRIEST, "OOM!");
    heard.Hear(DRUID, "I'm oom soon");
    heard.Hear(TANK, "slow down");
    check(heard.Said(PRIEST, BuddyPace::Word::Oom) && heard.said.size() == 1,
          "\"OOM!\" is heard; a longer line, and a word that isn't oom or ready, are not kept");
    Snapshot ws; Memory wm;
    fight(ws, wm, 15000);
    Seats wseats = BuddySeat::Now(ws, wm, {}, 60);
    Seats said = BuddySeat::Now(ws, wm, wseats, 60, &heard);
    check(BuddySeat::Has(said.dry, 1) && !BuddySeat::Has(said.holders, 1),
          "the priest says \"oom\" with three quarters of its mana bar: taken at its word, out of the seat");
    check(heard.said.empty(), "each word is heard once");
    Seats still = BuddySeat::Now(ws, wm, said, 60, &heard);
    check(BuddySeat::Has(still.dry, 1), "nothing more said: it stays out until its mana covers its healing for the rest of the fight");
    Snapshot fullBar = ws; fullBar.party[1].resource = fullBar.party[1].maxResource;
    check(!BuddySeat::Has(BuddySeat::Now(fullBar, wm, said, 60).dry, 1), "a full mana bar and nothing said: ready again by the reading");
    heard.Hear(PRIEST, "oom");
    check(BuddySeat::Has(BuddySeat::Now(fullBar, wm, said, 60, &heard).dry, 1), "but saying \"oom\" again keeps it out, whatever its bar");
    ws.party[1].resource = heal.cost * 2;
    Seats low = BuddySeat::Now(ws, wm, said, 60);
    check(BuddySeat::Has(low.dry, 1), "short of mana, saying nothing: still dry");
    heard.Hear(PRIEST, "ready");
    Seats back = BuddySeat::Now(ws, wm, low, 60, &heard);
    check(!BuddySeat::Has(back.dry, 1) && BuddySeat::Has(back.holders, 1) && !back.short_,
          "it says \"ready\": no longer dry at once, and the seats being short, it is seated again");
    heard.Hear(PRIEST, "ready");
    Seats waits = BuddySeat::Now(four, m, seats4, 60, &heard);
    check(!BuddySeat::Has(waits.dry, 1) && waits.holders == std::vector<int>{ 3 },
          "with the paladin holding the seat, the priest's \"ready\" leaves it waiting for one to come free");
    heard.Hear(DRUID, "oom");
    Snapshot ws2 = ws; ws2.party[1].resource = 1;
    Seats nobody = BuddySeat::Now(ws2, wm, wseats, 60, &heard);
    check(!BuddySeat::Has(nobody.holders, 2) && nobody.short_, "a member who just said \"oom\" isn't seated: short");
    // }}}

    std::printf("\n%d passed, %d failed\n", passed, failed);
    return failed == 0 ? 0 : 1;
}
