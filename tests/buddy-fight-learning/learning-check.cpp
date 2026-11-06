// learning-check.cpp - checks what each fight taught (buddies_fight_learning.h)
// against issue 625e, with no server. Built and run by
// scripts/test-buddy-fight-learning. Each check prints "ok" or "FAIL" and
// what it held; the exit status is the number of failures.
//
// A made-up boss fight a minute long, a snapshot each second: the boss
// (id 100) loses 1.5% a second; its script changes phase at 40 seconds;
// at 20 seconds an add (id 101) appears and three of the four characters
// run for five seconds after the boss began a cast, hit two of them with a
// spell and marked a third; one character dies at 45 seconds; at 52 two of
// the three left run for two seconds; the boss dies at 60. A hunter's pet
// (id 5, master 2) runs the whole time and is no character.

#include "buddies_fight_learning.h"
#include <cstdio>

using namespace BuddyFightLearning;

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

static bool Near(double a, double b, double within = 1e-9) { return std::fabs(a - b) <= within; }

// {{{ the made-up fight
static Member Char(uint64_t id, uint64_t owner, double x, double health)
{
    Member m; m.id = id; m.owner = owner; m.x = x; m.health = health; m.maxHealth = 100;
    return m;
}
static Enemy Foe(uint64_t id, uint8_t rank, double pct, double most)
{
    Enemy e; e.id = id; e.rank = rank; e.maxHealth = most; e.health = most * pct / 100.0;
    return e;
}
static Event Ev(double t, uint8_t kind, uint64_t from, uint64_t to, uint32_t spell)
{
    return Event{ t, kind, from, to, spell, 10.0, false };
}
static double const T0 = 1000.0;
static std::vector<Step> Fight1(std::vector<double> const& extraCasts = {}, bool addAtPull = false)
{
    std::vector<Step> steps;
    for (int k = 0; k <= 60; ++k)
    {
        Step st;
        st.snapshot.t = T0 + k;
        double run = std::clamp(k - 20, 0, 5) * 3.0;               // 2, 3, 4 run from 20 to 25
        double late = std::clamp(k - 52, 0, 2) * 3.0;              // 1, 2 run from 52 to 54
        st.snapshot.party.push_back(Char(1, 0, late, 100));
        st.snapshot.party.push_back(Char(2, 0, run + late, 100));
        st.snapshot.party.push_back(Char(3, 0, run, k >= 46 ? 0 : 100));
        st.snapshot.party.push_back(Char(4, 0, run, 100));
        st.snapshot.party.push_back(Char(5, 2, 2.0 * k, 100));
        st.snapshot.enemies.push_back(Foe(100, 3, k == 60 ? 0 : 100 - 1.5 * k, 50000));
        if (k >= 20 || addAtPull) st.snapshot.enemies.push_back(Foe(101, 1, 100, 80000));
        if (k >= 16) st.snapshot.enemies.push_back(Foe(102, 0, 100, 3000));   // came before the seconds before: no cue
        // the events since the snapshot before
        auto add = [&](double t, uint8_t kind, uint64_t from, uint64_t to, uint32_t spell) {
            if (t > T0 + k - 1 && t <= T0 + k) st.events.push_back(Ev(t, kind, from, to, spell));
        };
        add(T0 + 16.5, CAST_BEGIN, 100, 0, 6999);   // too early for the first rise
        add(T0 + 18.0, HIT, 100, 2, 7001);          // one spell on two of them: fire on the ground
        add(T0 + 18.0, HIT, 100, 3, 7001);
        add(T0 + 18.5, HIT, 100, 2, 7002);          // a spell on one: not
        add(T0 + 18.5, HIT, 100, 2, 0);             // plain attacks: not
        add(T0 + 18.6, HIT, 100, 3, 0);
        add(T0 + 19.0, MARK_ON, 100, 4, 7003);
        add(T0 + 19.2, MARK_ON, 100, 101, 7004);    // the boss's mark on its own add: not
        add(T0 + 19.0, MARK_ON, 2, 4, 1243);        // a friend's buff: not
        add(T0 + 19.0, CAST_BEGIN, 2, 100, 48);     // a friend's cast: not
        add(T0 + 19.5, CAST_BEGIN, 100, 0, 7000);
        add(T0 + 19.6, HEAL, 4, 2, 2050);
        add(T0 + 30.0, DEATH, 1, 101, 0);           // the add dies: no death in the party
        add(T0 + 45.2, DEATH, 100, 3, 0);
        add(T0 + 48.9, CAST_BEGIN, 100, 0, 7099);   // too early for the second rise
        add(T0 + 50.5, CAST_BEGIN, 100, 0, 7100);
        add(T0 + 60.0, DEATH, 2, 100, 0);
        for (double t : extraCasts) add(t, CAST_BEGIN, 100, 0, 7000);
        steps.push_back(st);
    }
    return steps;
}
static Fight Hogger()
{
    Fight f;
    f.entry = 448; f.name = "Hogger"; f.boss = 100; f.date = "2026-11-06"; f.seed = 42;
    f.scriptPhases = { T0 + 40.0 };
    f.entries = { { 101, 555 }, { 102, 556 } };
    return f;
}
static std::vector<Part> HoggerParts()
{
    return Parts({ { "creature 448", "448 Hogger 11 1 elite" }, { "spells", "7000 7001 7003 7100" }, { "script", "phase at 40s" } });
}
static Moving const* MovingOf(Distilled const& d, int phase, uint64_t id)
{
    for (Moving const& m : d.moving) if (m.phase == phase && m.id == id) return &m;
    return nullptr;
}
// }}}

int main()
{
    Settings s;

    // {{{ the fight distilled
    Distilled d = Distill(Fight1(), Hogger(), HoggerParts(), s);
    check(d.entry == 448 && d.name == "Hogger" && d.date == "2026-11-06" && d.seed == 42, "who, when, and the run's seed");
    check(Near(d.length, 60.0) && d.outcome == "won", "a minute long, won: the boss died");
    {
        bool ok = d.phases.size() == 5;
        double starts[] = { 0, 17, 34, 40, 50 }, lengths[] = { 17, 17, 6, 10, 10 };
        char const* whys[] = { "pull", "health 75", "health 50", "script", "health 25" };
        for (size_t i = 0; ok && i < 5; ++i)
            ok = d.phases[i].n == int(i) + 1 && Near(d.phases[i].start, starts[i]) && Near(d.phases[i].length, lengths[i]) && d.phases[i].why == whys[i];
        check(ok, "the phases: the pull, each health band as the boss crosses it (at 25% exactly too), the script's change");
    }
    {
        Moving const* a = MovingOf(d, 2, 2);
        Moving const* b = MovingOf(d, 2, 1);
        check(a && Near(a->share, 0.29) && MovingOf(d, 2, 3) && Near(MovingOf(d, 2, 3)->share, 0.29) && b && Near(b->share, 0.0),
              "the moving share through a phase: five seconds of seventeen, to a hundredth; the tank stood");
        check(MovingOf(d, 1, 2) && Near(MovingOf(d, 1, 2)->share, 0.0), "started again at each phase: none in the pull's phase");
        check(MovingOf(d, 5, 1) && Near(MovingOf(d, 5, 1)->share, 0.2) && MovingOf(d, 5, 4) && Near(MovingOf(d, 5, 4)->share, 0.0),
              "the last phase: two seconds of ten");
        bool pet = false;
        for (Moving const& m : d.moving) if (m.id == 5) pet = true;
        check(!pet, "a pet is no character: its moving isn't counted");
        check(MovingOf(d, 4, 3) && !MovingOf(d, 5, 3) && d.moving.size() == 19, "the dead aren't counted after they die");
    }
    {
        check(d.rises.size() == 2, "movement rose twice");
        if (d.rises.size() == 2)
        {
            std::vector<std::string> want = { "cast 7000", "hit 7001", "mark 7003", "summon 555" };
            check(d.rises[0].phase == 2 && Near(d.rises[0].t, 20.0), "the first at 20 seconds, in the second phase");
            check(d.rises[0].cues == want,
                  "what began just before: the boss's cast, its spell on two of them, its mark, the add that appeared");
            check(d.rises[1].phase == 5 && Near(d.rises[1].t, 52.0) && d.rises[1].cues == std::vector<std::string>{ "cast 7100" },
                  "the second: two of the three left running; only what began within the seconds before");
        }
    }
    check(d.deaths.size() == 1 && d.deaths[0].id == 3 && d.deaths[0].phase == 4 && Near(d.deaths[0].t, 45.2),
          "a death in the party: who, when, which phase; the boss's own isn't one");
    // }}}

    // {{{ the phases, other ways
    {
        Fight f = Hogger(); f.boss = 0;
        Distilled e = Distill(Fight1({}, true), f, HoggerParts(), s);
        check(e.phases.size() == 5 && e.outcome == "won", "no boss named: the boss-ranked enemy over a bigger elite");
        std::vector<Step> late = Fight1();
        for (Step& st : late) for (Enemy& x : st.snapshot.enemies) if (x.id == 100 && x.health > 0) x.health = std::min(x.health, 50000.0 * 0.6);
        e = Distill(late, Hogger(), HoggerParts(), s);
        check(e.phases.size() == 4 && e.phases[1].why == "health 50" && Near(e.phases[1].start, 34.0),
              "pulled under a band already: that band begins nothing");
        std::vector<Step> drop = Fight1();
        for (Step& st : drop) for (Enemy& x : st.snapshot.enemies) if (x.id == 100 && st.snapshot.t >= T0 + 10 && x.health > 0) x.health = std::min(x.health, 50000.0 * 0.4);
        e = Distill(drop, Hogger(), HoggerParts(), s);
        check(e.phases.size() == 4 && e.phases[1].why == "health 50" && Near(e.phases[1].start, 10.0) && e.phases[3].why == "health 25",
              "two bands crossed at once: one phase, by the lower band");
        Fight g = Hogger(); g.scriptPhases = { T0 + 34.0 };
        e = Distill(Fight1(), g, HoggerParts(), s);
        check(e.phases.size() == 4 && e.phases[2].why == "script health 50", "the script and a band at once: one phase, both said");
        Settings c = s; c.newCastAfter = 30;
        e = Distill(Fight1({ T0 + 55.5 }), Hogger(), HoggerParts(), c);
        bool cast = false;
        for (Phase const& p : e.phases) if (p.why == "cast 7100" && Near(p.start, 51.0)) cast = true;
        check(e.phases.size() == 7 && cast, "new casts on: a boss spell first cast after 30 seconds begins a phase (7099 and 7100)");
        e = Distill(Fight1({ T0 + 55.5 }), Hogger(), HoggerParts(), s);
        check(e.phases.size() == 5, "new casts off, as they are by default: casts begin no phase");
    }
    // }}}

    // {{{ moving, measured as speed
    {
        // four characters, a snapshot each half second for ten seconds: 1 and 2 run
        // from the pull to 2 s, nobody moves to 5 s, then 1 and 2 run again while 3
        // and 4 shuffle (0.8 yards a second: not moving)
        std::vector<Step> steps;
        double x1 = 0, x3 = 0;
        for (int k = 0; k <= 20; ++k)
        {
            Step st; st.snapshot.t = 500 + 0.5 * k;
            if (k > 0 && (k <= 4 || k > 10)) x1 += 0.8;
            if (k > 10) x3 += 0.4;
            st.snapshot.party = { Char(1, 0, x1, 100), Char(2, 0, x1, 100), Char(3, 0, x3, 100), Char(4, 0, x3, 100) };
            st.snapshot.enemies = { Foe(9, 3, 100, 1000) };
            steps.push_back(st);
        }
        Distilled e = Distill(steps, Hogger(), {}, s);
        check(MovingOf(e, 1, 1) && Near(MovingOf(e, 1, 1)->share, 0.7) && MovingOf(e, 1, 3) && Near(MovingOf(e, 1, 3)->share, 0.0),
              "moving is yards a second: 1.6 a second runs, 0.8 a second shuffles, however often the snapshots");
        check(e.rises.size() == 1 && Near(e.rises[0].t, 5.0),
              "running in at the pull is no rise; exactly half the party running is one");
    }
    // }}}

    // {{{ the outcome, other ways
    {
        std::vector<Step> lost = Fight1();
        lost.pop_back();
        for (Member& m : lost.back().snapshot.party) m.health = 0;
        Distilled e = Distill(lost, Hogger(), HoggerParts(), s);
        check(e.outcome == "lost" && Near(e.length, 59.0), "everyone down at the end: lost");
        lost.back().snapshot.party[4].health = 50;
        e = Distill(lost, Hogger(), HoggerParts(), s);
        check(e.outcome == "left", "anyone standing and the boss alive: left");
        std::vector<Step> quiet = Fight1();
        quiet.back().events.clear();
        e = Distill(quiet, Hogger(), HoggerParts(), s);
        check(e.outcome == "won", "the boss at no health at the end, its death not written: won");
        std::vector<Step> twice = Fight1();
        twice[50].events.push_back(Ev(T0 + 49.5, DEATH, 100, 3, 0));
        e = Distill(twice, Hogger(), HoggerParts(), s);
        check(e.deaths.size() == 2 && Near(e.deaths[1].t, 49.5) && e.deaths[1].phase == 4,
              "raised and fallen again: two deaths, each in the phase of its own time (half a second before the next)");
        e = Distill({}, Hogger(), HoggerParts(), s);
        check(e.phases.empty() && e.outcome == "left" && Near(e.length, 0.0) && e.print == Whole(HoggerParts()),
              "no log at all: nothing learned, but who and the fingerprint kept");
    }
    // }}}

    // {{{ written and read back
    {
        std::string text = Write(d);
        std::string err = "x";
        std::vector<Distilled> back = Read(text + "\n" + text, &err);
        check(err.empty() && back.size() == 2 && Write(back[0]) == text && Write(back[1]) == text,
              "a file of two blocks reads back to the same blocks");
        check(text.find("fight 448 Hogger 2026-11-06 42\n") == 0
              && text.find("phase 2 17 17 health 75\n") != std::string::npos
              && text.find("moving 2 2 0.29\n") != std::string::npos
              && text.find("rise 2 20 cast 7000 hit 7001 mark 7003 summon 555\n") != std::string::npos
              && text.find("death 4 45.2 3\n") != std::string::npos
              && text.find("length 60 won\n") != std::string::npos
              && text.substr(text.size() - 4) == "end\n",
              "the block's lines, as the issue's file says");
        check(text.find("part creature_448 ") != std::string::npos && text.find("print " + Hex(Whole(HoggerParts())) + "\n") != std::string::npos,
              "the fingerprint and its parts in the block");
        bool small = text.size() < 1500;
        check(small, "the junk cleared: a minute's fight in under 1500 bytes");
        Read("fight 1 a _ 0\nprint 12345\nend\n", &err);
        check(err.find("line 2") == 0, "a fingerprint not 16 hex digits: refused, the line named");
        Read("fight 1 a _ 0\nlength 5 won\n", &err);
        check(err.find("no end") != std::string::npos, "a block with no end: refused");
        Read("length 5 won\n", &err);
        check(err.find("outside") != std::string::npos, "a line outside a block: refused");
        Read("fight 1 a _ 0\nrise 1 2 cast\nend\n", &err);
        check(err.find("cue") != std::string::npos, "a cue short of its spell: refused");
        back = Read("fight 7 Mor'Ladim _ 0\nend\n", &err);
        check(err.empty() && back.size() == 1 && back[0].date.empty() && back[0].name == "Mor'Ladim", "no day: written \"_\", read as none");
    }
    // }}}

    // {{{ the fingerprint
    {
        check(Hex(Hash("")) == "cbf29ce484222325" && Hex(Hash("a")) == "af63dc4c8601ec8c", "the hash: FNV-1a, 64 bits");
        std::vector<Part> a = HoggerParts();
        std::vector<Part> b = Parts({ { "spells", "7000 7001 7003 7100" }, { "script", "phase at 40s" }, { "creature 448", "448 Hogger 11 1 elite" } });
        check(Whole(a) == Whole(b) && Changed(a, b).empty() && !Stale(d, b), "the same parts, given in another order: the same fight");
        std::vector<Part> c = Parts({ { "creature 448", "448 Hogger 11 1 elite" }, { "spells", "7000 7001 7003 7101" }, { "tuning", "x" } });
        std::vector<std::string> want = { "script gone", "spells changed", "tuning added" };
        check(Changed(a, c) == want && Stale(d, c), "a spell changed, the script gone, tuning added: each named, and stale");
        std::vector<Part> e = Parts({ { "creature 448", "448 Hogger 11 1 elite" }, { "spells", "7000 7001 7003 7100" }, { "script", "phase at 41s" } });
        check(Whole(e) != Whole(a) && Changed(a, e) == std::vector<std::string>{ "script changed" }, "one character of one part: a new fingerprint");
    }
    // }}}

    // {{{ where it's kept
    check(Path(448, "Hogger", "2026-11-06") == "learned/fights/448-hogger/2026-11-06.fights", "kept by boss and by day");
    check(Path(639, "Edwin VanCleef", "2026-11-06") == "learned/fights/639-edwin-vancleef/2026-11-06.fights"
          && Path(1, "Mor'Ladim!", "d") == "learned/fights/1-mor-ladim/d.fights" && Path(2, "", "d") == "learned/fights/2/d.fights"
          && Path(3, "'The  Rake", "d") == "learned/fights/3-the-rake/d.fights",
          "the name in lower case, anything else as one dash");
    // }}}

    std::printf("%d of %d checks held\n", checks - failures, checks);
    return failures;
}
