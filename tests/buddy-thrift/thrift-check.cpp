// thrift-check.cpp - checks buddies_thrift.h (issue 625h, steps 1 and 3):
// the bot module's lines smoothed, regeneration as time, the lean between
// fast and cheap answers, and the surplus that lets a healer's damage
// spells in. Built and run by scripts/test-buddy-thrift; each check prints
// "ok" or "FAILED"; the exit status is the number that failed.

#include "buddies_thrift.h"
#include "roam/buddy_pace_core.h"

#include <cmath>
#include <cstdio>
#include <string>

using namespace BuddyThrift;

static int passed = 0, failed = 0;
// {{{ check
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}
// }}}

static bool near(double a, double b, double by = 1e-6) { return std::fabs(a - b) < by; }

// {{{ Stepped
// The bot module's bands as they are today: the count of lines above the
// health, over four (a hard staircase), the reference the smooth one keeps
// to away from the lines.
static double Stepped(double healthPct)
{
    int n = 0;
    for (double band : BANDS) n += healthPct < band ? 1 : 0;
    return n / 4.0;
}
// }}}

int main()
{
    // {{{ the lines, smoothed
    check(near(Hurt(100), 0) && near(Hurt(0), 1), "full health is not hurt; no health is as hurt as can be");
    check(std::fabs(Hurt(44) - Hurt(46)) < 0.05 && std::fabs(Stepped(44) - Stepped(46)) > 0.2,
          "44% and 46% are treated almost alike (the stepped bands set them a whole band apart)");
    bool keeps = true;
    for (double h : { 5.0, 10.0, 15.0, 35.0, 55.0, 75.0, 95.0, 100.0 }) keeps = keeps && near(Hurt(h), Stepped(h));
    check(keeps, "away from the lines it is the bot module's own band (35%: three of four)");
    bool falling = true, smooth = true;
    for (double h = 0.0; h < 100.0; h += 0.01)
    {
        falling = falling && Hurt(h + 0.01) <= Hurt(h) + 1e-12;
        smooth  = smooth && Hurt(h) - Hurt(h + 0.01) < 0.0003;   // no jump anywhere: at most 0.03 a point
    }
    check(falling, "the more health, never the more hurt");
    check(smooth, "no jump anywhere between 0 and 100");
    check(near(Hurt(25), 0.875) && near(Hurt(45), 0.625), "on a line itself, halfway across its step");
    check(near(Saving(60), 0.5) && near(Saving(45), 1) && near(Saving(75), 0) && Saving(58) > 0.5 && Saving(62) < 0.5,
          "the save-mana switch at 60% slides from 50% to 70%");
    // }}}

    // {{{ regeneration as time
    Regen priest{ 50.0, 20.0, 0.3, 300.0 };   // 50 a 5, 20 a second from spirit, 30% while casting, a 300 drink
    check(near(PerSecond(priest, true, 2.0, false), 10.0 + 6.0), "in combat, within five seconds of a cast: mana per 5 and 30% of spirit");
    check(near(PerSecond(priest, true, 6.0, false), 10.0 + 20.0), "in combat, past five seconds: all of spirit");
    check(near(PerSecond(priest, true, 6.0, true), 30.0), "no drinking counted in combat");
    check(near(PerSecond(priest, false, 6.0, true), 330.0), "between fights, drinking: the fast kind");
    check(near(PerSecond(Regen{ 50.0, 20.0, 0.0, 0.0 }, true, 1.0, false), 10.0), "no Meditation: no spirit while casting");

    check(near(RefillSeconds(MANA, 4000, 10000, 30), 200), "6000 missing at 30 a second: 200 seconds");
    check(RefillSeconds(MANA, 10000, 10000, 0) == 0.0, "nothing missing: nothing to wait for");
    check(std::isinf(RefillSeconds(MANA, 0, 10000, 0)), "missing, and nothing coming back: endless");
    check(near(RefillSeconds(ENERGY, 40, 100, 0), 6), "energy by its own 10 a second");
    check(near(RefillSeconds(ENERGY, 40, 100, 20), 3), "energy faster when the caller says so (Adrenaline Rush)");
    check(RefillSeconds(RAGE, 0, 100, 0) == 0.0 && RefillSeconds(RUNIC, 0, 100, 0) == 0.0,
          "rage and runic power come from fighting: nothing to save");

    check(Thrift(10) == 0.0 && Thrift(30) == 0.0, "under 30 seconds a cost barely matters");
    check(Thrift(120) == 1.0 && Thrift(600) == 1.0, "past two minutes every cost counts");
    check(near(Thrift(75), 0.5), "halfway between, half");
    check(Thrift(31) < 0.001 && 1.0 - Thrift(119) < 0.001 && Hurt(95.5) < 0.0001,
          "no kink where a slide begins or ends: it leaves and meets the flat gently");
    bool rising = true;
    for (double s = 0; s < 200; s += 0.5) rising = rising && Thrift(s + 0.5) >= Thrift(s);
    check(rising, "the longer the refill, never the less a cost counts");
    check(std::isinf(RefillSeconds(MANA, 0, 1, 0)) && Thrift(RefillSeconds(MANA, 0, 1, 0)) == 1.0, "an endless refill: every cost counts");
    // }}}

    // {{{ the lean among answers
    // Flash Heal: 1.5 s, 3 health a mana; Greater Heal: 3 s, 5 a mana;
    // Renew: instant (the 1.5 s global cooldown), 6 a mana
    std::vector<Answer> heals = { { 1.5, 3.0 }, { 3.0, 5.0 }, { 1.5, 6.0 } };
    std::vector<Answer> fastVsCheap = { { 1.5, 3.0 }, { 3.0, 6.0 } };
    Weights dying = Weigh(5, 200), scratched = Weigh(92, 200), extravagant = Weigh(92, 5);
    check(dying.speed > 0.99 && dying.cost < 0.01, "a dying ally: speed counts, cost doesn't");
    check(scratched.speed < 0.05 && scratched.cost > 0.95, "a scratched ally, mana slow to come back: cost counts");
    check(extravagant.speed < 0.05 && extravagant.cost == 0.0, "a scratched ally, mana back in seconds: be extravagant");
    std::vector<double> d = Lean(fastVsCheap, dying), sc = Lean(fastVsCheap, scratched), ex = Lean(fastVsCheap, extravagant);
    check(d[0] > d[1] * 1.9, "dying: the fast heal leans in over the slow one");
    check(sc[1] > sc[0] * 1.9, "scratched: the cheap heal leans in over the dear one");
    check(ex[0] > 0.95 && ex[1] > 0.95, "extravagant: nothing much preferred");
    std::vector<double> all = Lean(heals, scratched);
    check(all[2] > all[1] && all[1] > all[0], "scratched among three: Renew, then Greater Heal, then Flash Heal");
    bool slides = true; double last = 0.0;
    for (double h = 100; h >= 0; h -= 0.5)
    {
        std::vector<double> l = Lean(fastVsCheap, Weigh(h, 200));
        double ratio = l[0] / l[1];
        slides = slides && ratio >= last - 1e-9;
        last = ratio;
    }
    check(slides, "the lean toward the fast heal grows smoothly as the ally's health falls");
    std::vector<double> free = Lean({ { 1.5, 3.0 }, { 1.5, std::numeric_limits<double>::infinity() } }, scratched);
    check(free[1] == 1.0 && free[0] < 0.01, "a free answer beats any that costs, when cost counts");
    // }}}

    // {{{ the surplus
    // a healer with 6000 mana, needing 40 a second, 10 coming back
    BuddyFight::Guess trash = BuddyFight::TimeLeft(3000, 150, {});          // 20 seconds
    BuddyFight::Guess boss  = BuddyFight::TimeLeft(300000, 1000, {});       // 300 seconds
    check(near(trash.seconds, 20) && near(boss.seconds, 300), "the guesses: trash 20 seconds, a boss 300");
    double trashSpare = Surplus(6000, 10, 40, trash), bossSpare = Surplus(6000, 10, 40, boss);
    check(near(trashSpare, 6000 - 30 * 20 * 4.0 / 3.0), "trash: 6000 less 30 a second over 20 seconds and a third");
    check(trashSpare > 0 && DamageLean(trashSpare, 300) > 0.99,
          "a trash fight: \"they can freely throw out damage spells\"");
    check(bossSpare < 0 && near(DamageLean(bossSpare, 300), AWAY),
          "a long fight: \"less likely to cast damage spells because they probably will need their mana\"");
    BuddyFight::Guess ending = BuddyFight::TimeLeft(30000, 1000, {});      // the boss nearly down: 30 seconds
    check(Surplus(1500, 10, 40, ending) > 0 && Surplus(1500, 10, 40, boss) < 0,
          "\"if the fight is ending sooner than their mana supply demands, then they can cast out damage spells as well\"");
    BuddyFight::Guess lusted = BuddyFight::TimeLeft(60000, 1000, { { 0, 40, 1.3 } });
    BuddyFight::Guess plain  = BuddyFight::TimeLeft(60000, 1000, {});
    check(Surplus(2000, 10, 40, lusted) > Surplus(2000, 10, 40, plain) && lusted.seconds < plain.seconds,
          "Bloodlust shortens the fight as a stretch, and leaves more to spare");
    // the margin: 2000 mana, 30 a second net, 60 seconds: 1800 without the
    // margin (spare), 2400 with it (not spare)
    BuddyFight::Guess minute = BuddyFight::TimeLeft(60000, 1000, {});
    check(Surplus(2000, 10, 40, minute, 0.0) > 0 && Surplus(2000, 10, 40, minute) < 0,
          "spare only with a margin: the guess may be a third too short");
    BuddyFight::Guess endless = BuddyFight::TimeLeft(60000, 0, {});
    check(Surplus(99999, 10, 40, endless) == 0.0 && near(DamageLean(0, 300), AWAY), "no end seen: nothing spare");
    check(Surplus(500, 50, 40, boss) == 500, "mana coming back faster than needed: all it holds is spare");
    check(near(DamageLean(-1000, 300), 0.05), "kept mana leans damage away as the healer's seat does (0.05), never to nothing");
    check(DamageLean(1e9, 0) == 1.0, "a free damage spell is never held back");
    check(near(DamageLean(450, 300), AWAY + (1 - AWAY) * 0.5), "half of three casts spare: halfway in");
    bool up = true;
    for (double s = -1000; s < 2000; s += 5) up = up && DamageLean(s + 5, 300) >= DamageLean(s, 300);
    check(up, "more to spare, never less damage");
    // }}}

    // {{{ between fights
    Rest r = Between(MANA, 55, false);
    check(r.drink && std::string(r.say) == "mana", "below 60% between fights: drinks, and says \"mana\"");
    check(BuddyPace::ReadWord(r.say) == BuddyPace::Word::Oom, "the tank's pace hears \"mana\" as a stop");
    r = Between(MANA, 80, true);
    check(r.drink && r.say == nullptr, "drinking, not yet full: drinks on, says nothing");
    r = Between(MANA, 100, true);
    check(!r.drink && std::string(r.say) == "ready", "full: stands, and says \"ready\"");
    check(BuddyPace::ReadWord(r.say) == BuddyPace::Word::Ready, "the tank's pace hears \"ready\" as go on");
    r = Between(MANA, 70, false);
    check(!r.drink && r.say == nullptr, "above 60%, not drinking: nothing");
    r = Between(RAGE, 0, false);
    check(!r.drink && r.say == nullptr, "rage doesn't drink");
    // }}}

    std::printf("%d checks, %d failed\n", passed + failed, failed);
    return failed;
}
