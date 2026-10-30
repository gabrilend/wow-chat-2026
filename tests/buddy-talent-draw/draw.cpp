// draw.cpp - checks buddies_talent_draw.h (issue 625): a buddy's talents
// make weights, and the weighted draw favours weighted answers within a
// concern without ever leaping across concerns.
//
// For a general audience: a restoration druid at low health has six
// answers a tenth of a point apart (21.0 to 21.5). With no talents, each
// should win sometimes; with talents in Healing Touch, Healing Touch should
// win more, about in proportion; and fleeing a melee enemy (39) must always
// beat healing a critical ally (34), whatever the draws.

#include "buddies_talent_draw.h"
#include "buddies_talent_touches_data.h"

#include <cstdio>
#include <random>
#include <set>

using namespace BuddyTalentDraw;

static int passed = 0, failed = 0;
// {{{ check
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}
// }}}

// {{{ wins
// How often each answer wins over many choices: answers are (priority,
// weight); the winner is the highest priority times its factor.
static std::vector<int> wins(std::vector<std::pair<float, float>> const& answers, int rounds, unsigned seed)
{
    std::mt19937 rng(seed);
    std::uniform_real_distribution<double> u(0.0, 1.0);
    std::vector<int> count(answers.size(), 0);
    for (int r = 0; r < rounds; ++r)
    {
        size_t best = 0;
        float bestScore = -1.0f;
        for (size_t i = 0; i < answers.size(); ++i)
        {
            float s = answers[i].first * Factor(answers[i].second, u(rng));
            if (s > bestScore) { bestScore = s; best = i; }
        }
        ++count[best];
    }
    return count;
}
// }}}

int main()
{
    // weights: Healing Touch touched by a five-rank talent with 5 points (+30% by points),
    // Rejuvenation by a three-rank talent stating 15% with 3 points
    std::vector<Touch> touches = {
        { "healing touch", false,  0, 5, 5 },
        { "rejuvenation",  false, 15, 3, 3 },
        { "wrath",         true,  10, 5, 0 },       // not learned
        { "shred",         true,  10, 5, 5 },
    };
    auto byPoints = Weights(touches, 1, 1.0f);
    auto byEffect = Weights(touches, 2, 1.0f);
    auto halfBroad = Weights(touches, 2, 0.5f);
    check(std::fabs(byPoints["healing touch"] - 1.30f) < 1e-4, "by points: five points raise Healing Touch 30%");
    check(std::fabs(byEffect["rejuvenation"] - 1.15f) < 1e-4, "by effect: a talent stating 15% raises Rejuvenation 15%");
    check(std::fabs(byEffect["healing touch"] - 1.30f) < 1e-4, "by effect: a flat talent falls to the per-point raise, as defined");
    check(byPoints.find("wrath") == byPoints.end(), "an unlearned talent raises nothing");
    check(std::fabs(byEffect["shred"] - 1.10f) < 1e-4 && std::fabs(halfBroad["shred"] - 1.05f) < 1e-4, "a broad talent counts in full, or half");

    // the druid's low-health list: tree form, Swiftmend, Wild Growth, Nourish, Regrowth, Healing Touch
    std::vector<std::pair<float, float>> plain = { {21.5f, 1}, {21.4f, 1}, {21.3f, 1}, {21.2f, 1}, {21.1f, 1}, {21.0f, 1} };
    auto w0 = wins(plain, 20000, 7);
    bool everyone = true;
    for (int c : w0) everyone = everyone && c > 20000 / 6 / 3;
    check(everyone, "with no talents every answer wins sometimes");
    std::printf("  no talents:      %5d %5d %5d %5d %5d %5d\n", w0[0], w0[1], w0[2], w0[3], w0[4], w0[5]);

    auto talented = plain;
    talented[5].second = 2.0f;                      // Healing Touch twice as weighted
    auto w1 = wins(talented, 20000, 7);
    std::printf("  Healing Touch x2: %5d %5d %5d %5d %5d %5d\n", w1[0], w1[1], w1[2], w1[3], w1[4], w1[5]);
    check(w1[5] > w0[5] * 1.5 && w1[5] < w0[5] * 2.6, "twice the weight wins about twice as often");
    check(w1[0] > 0 && w1[1] > 0, "the others still win sometimes");

    // across concerns: fleeing (39) against healing a critical ally (34, weighted high)
    auto w2 = wins({ {39.0f, 1.0f}, {34.0f, 3.0f} }, 20000, 11);
    check(w2[1] == 0, "a weighted heal at 34 never beats fleeing at 39");

    // the generated table reaches the module: Starlight Wrath's two spells are in it
    std::set<std::string> starlight;
    for (auto const& row : BUDDY_TALENT_TOUCHES) if (std::string(row.ability) == "starfire" || std::string(row.ability) == "wrath") starlight.insert(row.ability);
    check(starlight.size() == 2, "the generated table names Wrath and Starfire");

    std::printf("%s: %d of %d checks passed\n", failed ? "FAILED" : "ok", passed, passed + failed);
    return failed ? 1 : 0;
}
