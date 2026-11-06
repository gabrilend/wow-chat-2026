// faith-check.cpp - checks buddies_faith.h (issue 625l, a player's faith):
// the short list made on joining, faith lost by holding a long cooldown a
// whole length and given back by a prompt use, never past the baseline;
// and the forward pass's choice of whom Power Infusion goes on, held for
// a player's burn until holding it has cost them enough faith. Built and
// run by scripts/test-buddy-faith; each check prints "ok" or "FAILED".

#include "buddies_forward_pass.h"
#include "buddies_faith.h"

#include <cmath>
#include <cstdio>

using namespace BuddyForwardPass;
using BuddyFaith::Book;

static int passed = 0, failed = 0;
// {{{ check
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}
// }}}

static bool near(double a, double b, double by = 1e-9) { return std::fabs(a - b) < by; }

uint64_t const TANK = 1, HEALER = 2, PRIEST = 3, PLAYER_MAGE = 4, BUDDY_MAGE = 5, ROGUE = 6, BOSS = 100;
double const RAW = 12000;

// {{{ fight
// A boss on a warrior tank, a priest healing it; the buddy priest who gives
// Power Infusion; a player mage dealing 3000 a second, a buddy mage 2600,
// a rogue 4000 (energy: Power Infusion's cast haste is nothing to it). A
// minute of the boss left.
static void fight(Snapshot& s, Memory& m)
{
    s.t = 30;
    auto member = [](uint64_t id, uint8_t cls, uint8_t role, uint8_t kind, double hp) {
        Member x; x.id = id; x.cls = cls; x.role = role; x.resourceKind = kind; x.armour = 4000; x.level = 80;
        x.health = hp; x.maxHealth = hp; x.resource = 10000; x.maxResource = 20000; return x;
    };
    Member tank = member(TANK, 1, 1, 1, 30000); tank.armour = 10000;
    s.party = { tank, member(HEALER, 5, 2, 0, 15000), member(PRIEST, 5, 0, 0, 15000),
                member(PLAYER_MAGE, 8, 0, 0, 14000), member(BUDDY_MAGE, 8, 0, 0, 14000), member(ROGUE, 4, 0, 3, 18000) };
    Enemy boss; boss.id = BOSS; boss.rank = 3; boss.level = 80; boss.health = 60000; boss.maxHealth = 400000; boss.attacking = TANK;
    boss.threat = { { TANK, { 10000, 2, 0, true } }, { ROGUE, { 7000, 2, 0, true } }, { PLAYER_MAGE, { 5000, 2, 0, false } },
                    { BUDDY_MAGE, { 4000, 2, 0, false } }, { HEALER, { 3000, 2, 0, false } } };
    s.enemies = { boss };
    double through = 1.0 - BuddyMarks::ArmourReduction(10000, 80);
    for (int t = 1; t <= 30; ++t)
    {
        m.Add({ double(t - 1), HIT, BOSS, TANK, 0, RAW * through, true });
        m.Add({ double(t - 1), HEAL, HEALER, TANK, 0, 9000, false });
        m.Add({ double(t - 1), HIT, PLAYER_MAGE, BOSS, 0, 3000, false });
        m.Add({ double(t - 1), HIT, BUDDY_MAGE, BOSS, 0, 2600, false });
        m.Add({ double(t - 1), HIT, ROGUE, BOSS, 0, 4000, true });
        m.Sample(t, 90000 - 1000.0 * t);
    }
    m.Forget(s.t);
}
// }}}

// {{{ PiOn
// Whom the priest (party index 2) would give Power Infusion to, and its lean.
static int PiOn(Snapshot const& s, Memory const& m, Book const* faith, double* lean = nullptr)
{
    std::map<std::string, int> to;
    auto leans = Leans(s, m, 2, 0, nullptr, &to, faith);
    if (lean) *lean = leans["power infusion"];
    return to.count("power infusion") ? to["power infusion"] : -1;
}
// }}}

int main()
{
    std::vector<BuddyFaith::Joiner> party = { { TANK, false, false }, { HEALER, false, true }, { PRIEST, false, true },
                                              { PLAYER_MAGE, true, true }, { BUDDY_MAGE, false, true }, { ROGUE, false, false } };
    std::vector<std::string> gives = { "power infusion", "innervate" };

    // {{{ the book alone
    {
        Book b; b.Make(gives, party);
        check(b.Listed(PLAYER_MAGE, "power infusion") && !b.Listed(ROGUE, "power infusion") && !b.Listed(TANK, "innervate"),
              "the short list: Power Infusion and Innervate for those who spend mana, not the rogue or the warrior");
        check(b.Listed(ROGUE, "bloodlust"), "a buff with no list made leaves everyone in");
        check(near(b.Faith(PLAYER_MAGE, "power infusion"), 1.0), "every player starts at the baseline");

        b.Saw(PLAYER_MAGE, "arcane power", 120, 0, 100);
        check(b.Saving(PLAYER_MAGE, 100) && b.Saving(PLAYER_MAGE, 219), "a long cooldown ready: saving it for a burn, for its own length");
        check(near(b.Weight(PLAYER_MAGE, "power infusion", 150), BuddyFaith::PLAYER_BURN), "saving: worth more, a player's burn being the one they see");
        b.Saw(PLAYER_MAGE, "arcane power", 120, 0, 219);
        check(near(b.Faith(PLAYER_MAGE, "power infusion"), 1.0), "held just under its length: no use lost yet");
        b.Saw(PLAYER_MAGE, "arcane power", 120, 0, 220);
        check(near(b.Faith(PLAYER_MAGE, "power infusion"), 0.8) && near(b.Faith(PLAYER_MAGE, "innervate"), 0.8),
              "held a whole length: a use lost, a step of faith gone for each buff it is listed for");
        check(!b.Saving(PLAYER_MAGE, 220), "past its length it is no longer saving, only holding");
        b.Saw(PLAYER_MAGE, "arcane power", 120, 0, 221);
        check(near(b.Faith(PLAYER_MAGE, "power infusion"), 0.8), "the same lost use isn't counted twice");
        b.Saw(PLAYER_MAGE, "arcane power", 120, 0, 460);
        check(near(b.Faith(PLAYER_MAGE, "power infusion"), 0.512), "held three lengths since it came back: three uses lost, 0.8 x 0.8 x 0.8");
        b.Saw(PLAYER_MAGE, "arcane power", 120, 115, 465);
        check(near(b.Faith(PLAYER_MAGE, "power infusion"), 0.512) && b.Burning(PLAYER_MAGE, 470) && !b.Burning(PLAYER_MAGE, 476),
              "used late: no faith back, but burning for ten seconds");
        b.Saw(PLAYER_MAGE, "arcane power", 120, 0, 585);
        b.Saw(PLAYER_MAGE, "arcane power", 120, 110, 590);
        check(near(b.Faith(PLAYER_MAGE, "power infusion"), 0.64), "used within fifteen seconds of coming back: a step of faith back");
        b.Saw(PLAYER_MAGE, "arcane power", 120, 0, 705);
        b.Saw(PLAYER_MAGE, "arcane power", 120, 110, 706);
        b.Saw(PLAYER_MAGE, "arcane power", 120, 0, 825);
        b.Saw(PLAYER_MAGE, "arcane power", 120, 110, 826);
        check(near(b.Faith(PLAYER_MAGE, "power infusion"), 1.0), "faith climbs back with prompt use...");
        b.Saw(PLAYER_MAGE, "arcane power", 120, 0, 945);
        b.Saw(PLAYER_MAGE, "arcane power", 120, 110, 946);
        check(near(b.Faith(PLAYER_MAGE, "power infusion"), 1.0), "...but never past the baseline: responsibility isn't counted up");

        Book c; c.Make(gives, party);
        c.Saw(PLAYER_MAGE, "icy veins", 60, 0, 0);
        c.Saw(PLAYER_MAGE, "icy veins", 60, 0, 600);
        check(near(c.Faith(PLAYER_MAGE, "power infusion"), 1.0) && !c.Saving(PLAYER_MAGE, 10),
              "a cooldown under 90 seconds is part of their rotation: not watched");
        c.Saw(BUDDY_MAGE, "arcane power", 120, 0, 0);
        c.Saw(BUDDY_MAGE, "arcane power", 120, 0, 1000);
        check(near(c.Faith(BUDDY_MAGE, "power infusion"), 1.0) && near(c.Weight(BUDDY_MAGE, "power infusion", 10), 1.0),
              "buddies are never marked down: they always use what is ready");
        check(near(c.Weight(ROGUE, "power infusion", 10), 0.0), "off the list: no weight at all");

        b.Saw(PLAYER_MAGE, "arcane power", 120, 0, 2000);
        b.Saw(PLAYER_MAGE, "arcane power", 120, 0, 2500);
        check(b.Faith(PLAYER_MAGE, "power infusion") < 0.5, "holding on and on: faith keeps falling");
        b.Make(gives, party);
        check(near(b.Faith(PLAYER_MAGE, "power infusion"), 1.0) && !b.Saving(PLAYER_MAGE, 2500),
              "the list made again (the party changed, a log-out): the baseline again");
    }
    // }}}

    // {{{ the forward pass's choice
    Snapshot s; Memory m;
    fight(s, m);
    double lean = 0, plain = 0;
    int k = PiOn(s, m, nullptr, &plain);
    check(k == 3, "no faith kept: Power Infusion on the player mage, who deals most among casters");
    Book b; b.Make(gives, party);
    check(PiOn(s, m, &b, &lean) == 3 && near(lean, plain), "a fresh book changes nothing while nobody saves or burns");

    b.Saw(PLAYER_MAGE, "arcane power", 120, 0, 25);
    k = PiOn(s, m, &b, &lean);
    check(k == 3 && near(lean, BuddyFaith::HOLD), "the player holds Arcane Power: Power Infusion is kept for their burn");
    b.Saw(PLAYER_MAGE, "arcane power", 120, 110, 30);
    k = PiOn(s, m, &b, &lean);
    check(k == 3 && near(lean, plain), "they burn: it goes on them now, leaning as before");

    Book late; late.Make(gives, party);
    late.Saw(PLAYER_MAGE, "arcane power", 120, 0, -215);                // ready since well before the pull
    late.Saw(PLAYER_MAGE, "arcane power", 120, 0, 25);                  // two whole lengths held
    check(near(late.Faith(PLAYER_MAGE, "power infusion"), 0.64), "two uses lost: faith 0.64");
    late.Saw(PLAYER_MAGE, "arcane power", 120, 0, 30);
    check(PiOn(s, m, &late, &lean) == 4 && lean > BuddyFaith::HOLD,
          "holding on: \"at a certain point it'll just make more sense to use it on a buddy-bot instead\"");
    Book once; once.Make(gives, party);
    once.Saw(PLAYER_MAGE, "arcane power", 120, 0, -100);
    once.Saw(PLAYER_MAGE, "arcane power", 120, 0, 25);                  // one whole length held: one use lost
    once.Saw(PLAYER_MAGE, "arcane power", 120, 119, 26);                // then used, late
    check(PiOn(s, m, &once, &lean) == 3 && near(lean, plain),
          "one use lost, but burning now: still the player (3000 x 0.8 x 1.25 against 2600)");
    Book over; over.Make(gives, party);
    over.Saw(PLAYER_MAGE, "arcane power", 120, 0, -110);
    over.Saw(PLAYER_MAGE, "arcane power", 120, 0, 14);
    over.Saw(PLAYER_MAGE, "arcane power", 120, 119, 15);                // burned fifteen seconds ago
    check(PiOn(s, m, &over, &lean) == 4, "the burn over, one lost use passes them by (3000 x 0.8 against 2600)");

    Book noPlayers; noPlayers.Make(gives, { { TANK, false, false }, { HEALER, false, true }, { PRIEST, false, true },
                                             { PLAYER_MAGE, false, true }, { BUDDY_MAGE, false, true }, { ROGUE, false, false } });
    noPlayers.Saw(PLAYER_MAGE, "arcane power", 120, 0, 25);
    check(PiOn(s, m, &noPlayers, &lean) == 3 && near(lean, plain), "a buddy with a cooldown ready isn't waited for");

    Book noMage; noMage.Make(gives, { { TANK, false, false }, { HEALER, false, true }, { PRIEST, false, true },
                                       { BUDDY_MAGE, false, true }, { ROGUE, false, false } });
    check(PiOn(s, m, &noMage, &lean) == 4, "someone not on the list (joined since it was made) isn't chosen");

    // Innervate, from a buddy druid in the priest's place: both mages'
    // mana falling 300 a second from 6000, dry in 20 seconds of the 60 left;
    // its mana buys the player mage's 3000 a second or the buddy's 2600
    {
        Snapshot d = s; Memory dm = m;
        d.party[2].cls = 11; d.party[2].baseMana = 3000;
        d.party[3].resource = 6000; d.party[4].resource = 6000;
        for (int t = 21; t <= 30; ++t)
        {
            dm.SampleResource(PLAYER_MAGE, t, 6000 + 300.0 * (30 - t));
            dm.SampleResource(BUDDY_MAGE,  t, 6000 + 300.0 * (30 - t));
        }
        std::map<std::string, int> to;
        Leans(d, dm, 2, 0, nullptr, &to);
        check(to.count("innervate") && to["innervate"] == 3, "Innervate, no faith kept: on the player mage, whose mana buys the most damage");
        Book inn; inn.Make(gives, party);
        inn.Saw(PLAYER_MAGE, "arcane power", 120, 0, -215);
        inn.Saw(PLAYER_MAGE, "arcane power", 120, 0, 30);
        to.clear();
        Leans(d, dm, 2, 0, nullptr, &to, &inn);
        check(to.count("innervate") && to["innervate"] == 4, "Innervate weighed by faith too: two lost uses pass the player by");
        Book off; off.Make(gives, { { TANK, false, false }, { HEALER, false, true }, { PRIEST, false, true }, { BUDDY_MAGE, false, true } });
        to.clear();
        Leans(d, dm, 2, 0, nullptr, &to, &off);
        check(to.count("innervate") && to["innervate"] == 4, "Innervate only for those on its list");
        Book none; none.Make(gives, { { TANK, false, false }, { HEALER, false, true }, { PRIEST, false, true } });
        to.clear();
        Leans(d, dm, 2, 0, nullptr, &to, &none);
        check(!to.count("innervate"), "no one whose mana runs short is on its list: Innervate is asked for no one");
    }
    // }}}

    std::printf("%d checks, %d failed\n", passed + failed, failed);
    return failed;
}
