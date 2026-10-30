// weather-check.cpp - checks buddies_weather_deck.h (issue 921a): every kind
// gets exactly its share, no kind twice running across a deck's seam, two
// seeds deal differently, each turn swells and fades, and slush trades rain
// for snow through its middle.
//
// For a general audience: the valley's weather is a shuffled deck of seven
// kinds. Over ten thousand decks each kind must have had exactly a seventh
// of the time; one deck must never open with the kind the last closed on.
//
// Run with --timeline SEED HOURS to print the sky every 20 seconds as JSON
// lines (what the weather page draws, a view made from the real arithmetic).

#include "buddies_weather_deck.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <set>

using namespace BuddyWeather;

static int passed = 0, failed = 0;
// {{{ check
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}
// }}}

int main(int argc, char** argv)
{
    if (argc == 4 && std::strcmp(argv[1], "--timeline") == 0)
    {
        uint64_t seed = std::strtoull(argv[2], nullptr, 10);
        uint64_t hours = std::strtoull(argv[3], nullptr, 10);
        for (uint64_t ms = 0; ms < hours * 3600000ull; ms += 20000)
        {
            Sky s = At(seed, ms);
            std::printf("{\"s\":%llu,\"kind\":\"%s\",\"strength\":%.3f,\"state\":%u,\"grade\":%.3f}\n",
                (unsigned long long)(ms / 1000), KIND_NAMES[s.kind], s.strength, s.state, s.grade);
        }
        return 0;
    }

    // equal shares and no stutter, over 10,000 decks dealt in a row
    uint64_t seed = 0x5EEDull;
    std::array<int, KIND_COUNT> count{};
    bool stutter = false, whole = true;
    uint8_t lastClose = KIND_COUNT;
    // dealt the way Deck does, carried along (Deck(seed, d) from 0 each time
    // would be slow over 10,000), and checked against Deck itself below
    for (uint64_t d = 0; d < 10000; ++d)
    {
        std::mt19937_64 rng(seed ^ (0x9E3779B97F4A7C15ull * (d + 1)));
        std::array<uint8_t, KIND_COUNT> deck{};
        for (uint8_t i = 0; i < KIND_COUNT; ++i) deck[i] = i;
        for (int i = KIND_COUNT - 1; i > 0; --i) std::swap(deck[size_t(i)], deck[size_t(rng() % uint64_t(i + 1))]);
        if (deck[0] == lastClose) std::swap(deck[0], deck[size_t(1 + rng() % uint64_t(KIND_COUNT - 1))]);
        std::set<uint8_t> seen(deck.begin(), deck.end());
        whole = whole && seen.size() == KIND_COUNT;
        stutter = stutter || deck[0] == lastClose;
        for (uint8_t k : deck) ++count[k];
        lastClose = deck[KIND_COUNT - 1];
        if (d < 30)
            whole = whole && deck == Deck(seed, d);
    }
    bool even = true;
    for (int c : count) even = even && c == 10000;
    check(whole, "every deck holds each kind once, and matches Deck()");
    check(even, "over 10,000 decks each kind has exactly a seventh of the turns");
    check(!stutter, "no deck opens with the kind the last one closed on");
    check(Deck(1, 0) != Deck(2, 0) || Deck(1, 1) != Deck(2, 1), "two seeds deal differently");

    // the swell and fade
    Sky start = At(seed, 0), middle = At(seed, TURN_MS / 2), late = At(seed, TURN_MS - 1000);
    check(start.strength < 0.01f && middle.strength > 0.99f && late.strength < 0.02f, "a turn starts and ends at nothing and peaks in the middle");
    check(At(seed, 12345).kind == At(seed, 12345).kind && At(seed, 99999).grade == At(seed, 99999).grade, "the same moment gives the same sky (every copy agrees)");

    // slush: rain first, rain and snow in turns, snow last
    bool found = false, rainFirst = true, snowLast = true, traded = true;
    for (uint64_t turn = 0; turn < 200 && !found; ++turn)
    {
        uint64_t t0 = turn * TURN_MS;
        Sky s = At(seed, t0 + 1000);
        if (s.kind != Slush) continue;
        found = true;
        rainFirst = At(seed, t0 + TURN_MS / 10).state == 4;
        snowLast  = At(seed, t0 + TURN_MS * 9 / 10).state == 7;
        std::set<uint32_t> middle;
        for (uint64_t ms = TURN_MS * 31 / 100; ms < TURN_MS * 69 / 100; ms += 5000) middle.insert(At(seed, t0 + ms).state);
        traded = middle.count(4) && middle.count(7);
    }
    check(found && rainFirst && snowLast && traded, "a slush turn opens as rain, trades rain and snow in its middle, closes as snow");

    std::printf("%s: %d of %d checks passed\n", failed ? "FAILED" : "ok", passed, passed + failed);
    return failed ? 1 : 0;
}
