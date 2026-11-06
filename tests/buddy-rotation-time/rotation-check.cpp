// rotation-check.cpp - checks the action economy's short-ability look
// ahead (buddies_rotation_time.h) against issue 625f, with no server.
// Built and run by scripts/test-buddy-rotation-time. Each check prints "ok"
// or "FAIL" and what it held; the exit status is the number of failures.
//
// The abilities are the game's own rows (buddies_ability_data.h): their
// cast times, global cooldowns and cooldowns as the game has them; the
// worths are made up, in one unit, as the talent draw would hand them.

#include "buddies_rotation_time.h"

#include <cstdio>
#include <cstring>

using namespace BuddyRotation;

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

static bool near(double a, double b, double eps = 1e-6) { return std::fabs(a - b) <= eps; }

static BuddyAbilityRow const& Row(int cls, char const* name)
{
    for (BuddyAbilityRow const& r : BUDDY_ABILITIES)
        if (r.cls == cls && std::strcmp(r.name, name) == 0)
            return r;
    std::printf("FAIL no row for %s\n", name);
    std::exit(99);
}

static bool InRange(Answer const& a)
{
    for (double w : a.weight)
        if (w < 0.0 || w > 1.0 + 1e-9)
            return false;
    return a.first < 0 || near(a.weight[size_t(a.first)], 1.0);
}

int main()
{
    int const WARRIOR = 1, PRIEST = 5, MAGE = 8;

    // {{{ the game's own numbers
    Cast fireball = FromRow(Row(MAGE, "fireball"), 10.0);
    Cast flay     = FromRow(Row(PRIEST, "mind flay"), 6.0);
    Cast missiles = FromRow(Row(MAGE, "arcane missiles"), 9.0);
    check(near(fireball.cast, 3.5) && near(fireball.gcd, 1.5) && near(fireball.cooldown, 0.0) && !fireball.channeled,
          "Fireball from the data: a 3.5-second cast on the 1.5-second global cooldown, no cooldown of its own");
    check(flay.channeled && near(flay.cast, 3.0), "Mind Flay: a channel, its 3 seconds read from its aura's length");
    check(near(missiles.cast, 0.0) && near(FromRow(Row(MAGE, "arcane missiles"), 9.0, 0.0, 5.0).cast, 5.0),
          "Arcane Missiles: no aura length in the table, so the caller's 5 seconds");
    Cast hs = FromRow(Row(WARRIOR, "heroic strike"), 2.0);
    check(near(hs.gcd, 0.0), "Heroic Strike: off the global cooldown (on the next swing)");
    // }}}

    // {{{ cast time against worth: a long cast earns its time
    {
        Cast scorch = FromRow(Row(MAGE, "scorch"), 4.0);
        Moment m;
        Answer a = Weigh({ fireball, scorch }, m);
        check(a.first == 0 && a.weight[1] < 1.0 && a.weight[1] > 0.9 && InRange(a),
              "standing still, Fireball (10 in 3.5 s) over Scorch (4 in 1.5 s); Scorch close behind");
        Moment moving; moving.moveIn = 2.0;
        a = Weigh({ fireball, scorch }, moving);
        check(a.first == 1 && a.weight[0] < a.weight[1], "movement in 2 seconds: Fireball wouldn't finish, Scorch first");
        Moment fast = moving; fast.moveIn = 2.5; fast.haste = 0.75;
        check(near(CastTime(fireball, 0.75), 2.0) && Landed(fireball, 0.0, fast) == 10.0 && Landed(fireball, 0.0, Moment{}) == 10.0
              && Landed(fireball, 0.0, Moment{ 0, 0, 2.5, 2, -1, -1, 6 }) == 0.0,
              "with 75% haste Fireball takes 2 seconds and lands before movement at 2.5; without, it doesn't");
        check(Landed(fireball, 4.0, moving) == 10.0 && Landed(fireball, 3.0, moving) == 0.0,
              "a cast begun once the movement is over lands; one begun during it is lost");
        check(Landed(FromRow(Row(MAGE, "ice lance"), 3.0), 2.5, moving) == 3.0, "an instant goes on while moving");
    }
    // }}}

    // {{{ the global cooldown's floor
    {
        Cast lance = FromRow(Row(MAGE, "ice lance"), 3.0);
        check(near(GcdTime(lance, 1.0), 1.0) && near(GcdTime(lance, 0.2), 1.25) && near(GcdTime(hs, 1.0), 0.0),
              "haste shortens the global cooldown to the game's 1-second floor, no lower; none stays none");
    }
    // }}}

    // {{{ putting abilities on cooldown is valued
    {
        Cast ms   = FromRow(Row(WARRIOR, "mortal strike"), 6.0);   // instant, 6-second cooldown
        Cast filler{ 0.0, 1.5, 0.0, 0.0, 5.0, false };              // an instant worth a little less, no cooldown
        Moment m; m.fightLeft = 60.0;
        Answer a = Weigh({ ms, filler }, m);
        check(a.first == 0 && a.weight[1] < 1.0 && a.weight[1] > 0.9,
              "Mortal Strike (6) over a filler (5): first, its cooldown started sooner leaves more uses");
        check(near(a.best, 6.0 + 15.0 + 1.0 * 54.0 / 6.0),
              "worth: the look ahead's casts, then each later use's gain over the filler's slot, once a cooldown");
        Moment last; last.fightLeft = 1.4;
        a = Weigh({ ms, filler }, last);
        check(a.first == 0 && near(a.weight[1], 5.0 / 6.0) && near(a.best, 6.0),
              "with no time for a second use, only the one cast counts");
        Cast even = ms; even.worth = 5.0;
        a = Weigh({ even, filler }, m);
        check(near(a.weight[0], 1.0) && near(a.weight[1], 1.0), "worth the same as the filler: no hurry either way, the two even");
        Cast weak = ms; weak.worth = 4.9;
        a = Weigh({ weak, filler }, m);
        check(a.first == 1 && a.weight[0] < 1.0, "worth less than the filler: the filler first, the cooldown no prize in itself");
        Cast later = ms; later.readyIn = 3.0;
        a = Weigh({ later, filler }, m);
        check(a.weight[0] == 0.0 && a.first == 1, "Mortal Strike cooling for 3 more seconds: weight 0, the filler first");
    }
    // }}}

    // {{{ waiting for a big ability about to come back
    {
        Cast blast = FromRow(Row(MAGE, "fire blast"), 6.0, 0.2);     // instant, 8-second cooldown, ready in 0.2 s
        Moment m; m.fightLeft = 30.0;
        Answer a = Weigh({ fireball, blast }, m);
        check(a.first == -1 && near(a.waitFor, 0.2) && a.weight[1] == 0.0 && a.weight[0] < 1.0,
              "Fire Blast back in 0.2 s: waiting for it beats starting a 3.5-second Fireball; Fireball leans away");
        Cast nothing = blast; nothing.worth = 0.0;
        Moment shortFight; shortFight.fightLeft = 2.0;
        a = Weigh({ FromRow(Row(MAGE, "ice lance"), 3.0), nothing }, shortFight);
        check(a.first == 0 && near(a.waitFor, 0.0) && near(a.best, 6.0),
              "two Ice Lances fit in a 2-second fight either way: waiting 0.2 s for nothing ties with casting now, and the tie casts now");
        Cast far = blast; far.readyIn = 3.0;
        a = Weigh({ fireball, far }, m);
        check(a.first == 0 && near(a.waitFor, 0.0), "back in 3 seconds: Fireball now");
        Moment soon = m; soon.gcdLeft = 0.1;
        a = Weigh({ fireball, blast }, soon);
        check(a.first == -1 && near(a.waitFor, 0.1), "the global cooldown running 0.1 s: the wait is the 0.1 s after it");
        Cast arcane{ 0.0, 1.5, 6.0, 0.0, 6.0, false }, big{ 0.0, 1.5, 20.0, 1.7, 20.0, false };
        a = Weigh({ arcane, big, fireball }, m);
        double planned = 6.0 + 20.0 + 10.0 * 2.8 / 3.5                                   // a cast, a wait, the big one, a Fireball cut by the edge
                       + (6.0 - 1.5 * 10.0 / 3.5) * (30.0 - 6.0) / 6.0                    // the later uses' gains over the filler
                       + (20.0 - 1.5 * 10.0 / 3.5) * (30.0 - 21.7) / 20.0;
        check(a.first == 0 && near(a.best, planned, 1e-6),
              "a wait in the middle of a plan: the 6-second instant, then hold 0.2 s for the big one rather than start a Fireball");
        Cast slow{ 2.0, 1.5, 6.0, 0.0, 8.0, false };
        a = Weigh({ slow }, m);
        Cast slowSoon = slow; slowSoon.readyIn = 0.5;
        Answer b = Weigh({ slowSoon }, m);
        check(near(a.best, 8.0 + 8.0 * (30.0 - 8.0) / 6.0) && near(b.best, 8.0 + 8.0 * (30.0 - 8.5) / 6.0),
              "a cooldown runs from when the cast lands, not when it begins (cast now, or after a wait)");
        Moment busy = m; busy.gcdLeft = 0.5;
        a = Weigh({ fireball, blast }, busy);
        check(a.first == 1 && near(a.weight[1], 1.0), "with the global cooldown running 0.5 s, Fire Blast is ready by then: it goes first");
    }
    // }}}

    // {{{ the target dying, the fight ending
    {
        Cast lance  = FromRow(Row(MAGE, "ice lance"), 3.0);
        Moment m; m.targetLeft = 1.0; m.fightLeft = 20.0;
        check(Landed(fireball, 0.0, m) == 0.0 && Landed(lance, 0.0, m) == 3.0 && Landed(fireball, 1.0, m) == 10.0,
              "the target dead in 1 s: a Fireball begun now is wasted, Ice Lance lands, a Fireball begun after is on the next enemy");
        Moment end; end.fightLeft = 2.0;
        Answer a = Weigh({ fireball, lance }, end);
        check(a.first == 1 && a.weight[0] == 0.0, "the fight over in 2 s: Fireball can't land in time, Ice Lance first");
        Cast flay2 = flay;
        Moment cut; cut.moveIn = 1.5;
        check(near(Landed(flay2, 0.0, cut), 3.0) && near(Landed(flay2, 0.0, Moment{ 0, 0, -1, 2, 2.0, -1, 6 }), 4.0)
              && near(Landed(flay2, 1.0, Moment{ 0, 0, 0.5, 2, -1, -1, 6 }), 0.0),
              "a channel keeps the part before movement or the target's death; none begun during movement");
    }
    // }}}

    // {{{ off the global cooldown: slipped in between
    {
        Cast ms = FromRow(Row(WARRIOR, "mortal strike"), 5.0);
        Cast slam = FromRow(Row(WARRIOR, "slam"), 4.0);
        Moment m;
        Answer with = Weigh({ ms, slam, hs }, m), without = Weigh({ ms, slam }, m);
        check(near(with.weight[2], 1.0) && near(with.weight[0], without.weight[0]) && near(with.weight[1], without.weight[1])
              && near(with.best, without.best),
              "Heroic Strike ready: weight 1, and the race between Mortal Strike and Slam is untouched");
        Cast hsLater = hs; hsLater.readyIn = 1.0;
        check(Weigh({ ms, slam, hsLater }, m).weight[2] == 0.0, "not ready: weight 0");
        check(with.first == 0 && InRange(with), "Mortal Strike first, every weight between 0 and 1, the first's 1");
    }
    // }}}

    // {{{ the look ahead's edge: a long cast begun at the end earns only its time there
    {
        Moment m;
        check(near(Within(5.0, 2.0, m), 0.5) && near(Within(0.0, 3.5, m), 1.0) && near(Within(7.0, 1.5, m), 0.0),
              "a 2-second slot begun 1 second before the end counts half");
        Cast pyro = FromRow(Row(MAGE, "pyroblast"), 14.0);
        Cast scorch = FromRow(Row(MAGE, "scorch"), 4.0);
        Answer a = Weigh({ pyro, scorch }, m);
        check(a.first == 0 && near(a.best, 14.0 + 14.0 / 5.0) && near(a.weight[1], (4.0 + 14.0 * 4.5 / 5.0) / 16.8),
              "Pyroblast (14 in 5 s) a little ahead of Scorch (4 in 1.5 s) by the second; Scorch, Scorch, Scorch, Pyroblast "
              "would read 26 if a cast begun at the edge counted whole");
    }
    // }}}

    // {{{ nothing at all
    {
        Answer a = Weigh({}, Moment{});
        check(a.first == -1 && a.best == 0.0 && a.weight.empty(), "no abilities: nothing chosen, nothing worth");
    }
    // }}}

    std::printf("%d of %d checks held\n", checks - failures, checks);
    return failures;
}
