// blend-check.cpp - checks how a buddy with points in several trees values
// each stat, whether a small upgrade is worn, and where a class book goes
// (buddies_stat_blend.h), against the owner's answers of 2026-10-28, with no
// server (issue 617j). Built and run by scripts/test-buddy-stat-blend. Each
// check prints "ok" or "FAIL" and what it held; the exit status is the
// number of failures.
//
// The weights are made up but shaped like the bot module's druid trees:
// each tree wants its own few stats, and all three like stamina a little.

#include "buddies_stat_blend.h"

#include <cmath>
#include <cstdio>

using namespace BuddyBlend;

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

enum Stat { STAMINA, AGILITY, STRENGTH, INTELLECT, SPIRIT, SPELL_POWER, HIT, CRIT, HASTE, MP5 };

static Tree Balance(double share) { return { share, false, { { SPELL_POWER, 1.0 }, { HIT, 0.9 }, { CRIT, 0.6 }, { HASTE, 0.6 }, { INTELLECT, 0.3 }, { STAMINA, 0.4 } } }; }
static Tree Feral(double share)   { return { share, false, { { AGILITY, 1.0 }, { STRENGTH, 0.8 }, { HIT, 0.8 }, { CRIT, 0.7 }, { STAMINA, 0.4 } } }; }
static Tree Resto(double share)   { return { share, true,  { { SPELL_POWER, 1.0 }, { SPIRIT, 0.7 }, { HASTE, 0.7 }, { MP5, 0.7 }, { INTELLECT, 0.5 }, { STAMINA, 0.4 } } }; }

static bool near(double a, double b) { return std::fabs(a - b) < 1e-9; }

int main()
{
    double third = 1.0 / 3.0;

    // {{{ the owner's worry: stamina winning by being shared
    std::vector<Tree> thirds = { Balance(third), Feral(third), Resto(third) };
    Weights plain;
    for (Tree const& t : thirds) for (auto const& w : t.weights) plain[w.first] += t.share * w.second;
    check(plain[STAMINA] > plain[AGILITY], "a plain average of the three trees puts stamina, liked a little by all, above agility (the worry)");
    Weights b = Blend(thirds, HIT);
    check(b[AGILITY] > b[STAMINA] && b[STRENGTH] > b[STAMINA] && b[SPIRIT] > b[STAMINA],
          "the blend: agility, strength and spirit, each wanted by one tree, above stamina, only tolerated by all");
    check(near(b[STAMINA], 0.4 * TOLERATED), "stamina counts a quarter of its weight in each tree");
    check(b[SPELL_POWER] > b[AGILITY], "spell power, wanted by two trees, above agility, wanted by one");
    std::map<int, double> tank{ { STAMINA, 40 } }, cat{ { AGILITY, 20 } };
    check(Score(b, cat) > Score(b, tank), "so an item of 20 agility beats one of 40 stamina for a thirds druid");
    check(near(Score(b, cat), 20 * b[AGILITY]) && Score(b, {}) == 0, "an item's score is its stats by the weights; no stats, nothing");
    // }}}

    // {{{ hit rating with a healing tree
    double hitWithout = Blend({ Balance(2 * third), Feral(third) }, HIT)[HIT];
    check(near(hitWithout, 2 * third * 0.9 + third * 0.8), "a 2/1 Balance/Feral druid: hit counts as its trees want it");
    check(near(b[HIT], (third * 0.9 + third * 0.8) * HIT_HEALER), "a thirds druid, a healing tree among them: hit marked down by half");
    Weights rb = Blend({ Resto(2 * third), Balance(third) }, HIT);
    check(near(rb[HIT], third * 0.9 * HIT_HEALER), "a 2/1 Restoration/Balance druid: marked down too");
    Weights br = Blend({ Balance(2 * third), Resto(third) }, HIT);
    check(near(br[HIT], 2 * third * 0.9 * HIT_HEALER), "and a 2/1 Balance/Restoration one, the healing third counting (\"this counts for the 2-1 specs as well\")");
    // }}}

    // {{{ one tree, and trees without points
    Weights whole = Blend({ Feral(1.0) }, HIT);
    check(whole == Feral(1.0).weights, "all points in one tree: its weights unchanged");
    Weights restoOnly = Blend({ Resto(1.0), Feral(0.0) }, HIT);
    check(restoOnly == Resto(1.0).weights, "a tree with no points is no part of the blend (and a single healing tree keeps its own hit weight)");
    check(Wanted(Feral(1.0), INTELLECT) == 0 && Wanted(Feral(1.0), STRENGTH) == 0.8 && near(Wanted(Feral(1.0), STAMINA), 0.1),
          "wanted: strength (0.8 of the top) counts whole; stamina (0.4) a quarter; a stat the tree doesn't weigh, nothing");
    Tree edge{ 1.0, false, { { AGILITY, 1.0 }, { CRIT, 0.6 }, { SPIRIT, -0.5 } } };
    check(Wanted(edge, CRIT) == 0.6, "a stat at exactly 0.6 of the top is wanted");
    check(Wanted(edge, SPIRIT) == 0, "a stat a tree weighs below nothing counts nothing, not against");
    // }}}

    // {{{ the upgrade bar
    check(Wear(110, 100, true), "10% better: worn, whoever else wants it");
    check(!Wear(105, 100, true), "5% better while a clanmate wants it: left for them");
    check(Wear(105, 100, false), "5% better and nobody else wants it: worn");
    check(!Wear(100, 100, false) && !Wear(95, 100, false), "no better: not worn");
    check(Wear(10, 0, true) && !Wear(0, 0, false), "an empty slot: anything that scores; nothing that scores nothing");
    // }}}

    // {{{ class books
    std::vector<Member> clan = { { true, true }, { false, false }, { true, false }, { true, false } };
    check(BookTo(clan) == 2, "a class book goes to the first clan member who can learn it and hasn't");
    std::vector<Member> playerFirst = { { true, false }, { true, false } };
    check(BookTo(playerFirst) == 0, "players and buddies alike, in the clan's order (no player preference)");
    std::vector<Member> none = { { true, true }, { false, false } };
    check(BookTo(none) == -1, "no clanmate needs it: to the auction house");
    // }}}

    std::printf("%d checks, %d failed\n", checks, failures);
    return failures;
}
