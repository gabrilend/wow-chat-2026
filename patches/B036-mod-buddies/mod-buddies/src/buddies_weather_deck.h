/*
 * buddies_weather_deck.h - Alterac Valley's shared sky as a shuffled deck
 * of weathers (issue 921a); plain arithmetic, apart from the server, so it
 * can be tested on its own (tests/buddy-weather/weather-check.cpp,
 * scripts/test-buddy-weather).
 *
 * For a general audience: the owner asked for weather that is "non
 * deterministic yet still equally distributed". So the kinds of weather are
 * dealt like a deck of cards: each kind once per deck, in an order drawn
 * from a seed nobody can predict (taken fresh when the server starts), then
 * the deck is shuffled again. Over any whole number of decks every kind has
 * had exactly the same time. A new deck never opens with the kind the last
 * one closed on. Each kind's turn lasts six minutes and swells from nothing
 * to full and fades back (half a sine). Slush, rain freezing as it falls
 * (the owner: "the rain freezes to slush"), has no weather of its own in
 * the game, so a slush turn opens as rain, trades rain and snow back and
 * forth through its middle, and closes as snow.
 *
 * Everything is worked out from the seed and the time alone, so every copy
 * of the valley, asking at the same moment, gets the same sky.
 */

#ifndef MOD_BUDDIES_WEATHER_DECK_H
#define MOD_BUDDIES_WEATHER_DECK_H

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <random>
#include <vector>

namespace BuddyWeather
{
    // {{{ the kinds
    // The deck's kinds (921a, 2026-10-30: the rain became slush), and the
    // game's weather states each is shown as (Weather.h WeatherState):
    // fine 0, fog 1, light rain 3, medium rain 4, light snow 6, medium snow
    // 7, heavy snow 8.
    enum Kind : uint8_t { Fine, Fog, LightSnow, Snow, HeavySnow, LightSlush, Slush, KIND_COUNT };
    static constexpr char const* KIND_NAMES[KIND_COUNT] = { "fine", "fog", "light snow", "snow", "heavy snow", "light slush", "slush" };
    // }}}

    // {{{ the numbers
    // TURN_MS:        a kind's turn: 6 minutes (921, question 1: a deck of 7
    //                 runs 42 minutes, about one long match).
    // SLUSH_RAIN_END, SLUSH_SNOW_FROM: a slush turn is rain before the first,
    //                 snow after the second, trading between them in between.
    // SLUSH_SWAP_MIN_MS, SLUSH_SWAP_MAX_MS: how long each spell of rain or
    //                 snow lasts in the trading (20 to 40 seconds).
    static constexpr uint64_t TURN_MS           = 6 * 60 * 1000;
    static constexpr float    SLUSH_RAIN_END    = 0.30f;
    static constexpr float    SLUSH_SNOW_FROM   = 0.70f;
    static constexpr uint64_t SLUSH_SWAP_MIN_MS = 20000;
    static constexpr uint64_t SLUSH_SWAP_MAX_MS = 40000;
    // }}}

    // {{{ Deck
    // The kinds of deck number d (0 first) for a seed: shuffled; if it
    // would open with the kind the deck before closed on, that kind is
    // swapped to a random later place. Worked out from deck 0 on, since
    // each deck's opening depends on the last one's close.
    inline std::array<uint8_t, KIND_COUNT> Deck(uint64_t seed, uint64_t d)
    {
        std::array<uint8_t, KIND_COUNT> deck{};
        uint8_t lastClose = KIND_COUNT;                     // none before deck 0
        for (uint64_t k = 0; k <= d; ++k)
        {
            std::mt19937_64 rng(seed ^ (0x9E3779B97F4A7C15ull * (k + 1)));
            for (uint8_t i = 0; i < KIND_COUNT; ++i)
                deck[i] = i;
            for (int i = KIND_COUNT - 1; i > 0; --i)
                std::swap(deck[size_t(i)], deck[size_t(rng() % uint64_t(i + 1))]);
            if (deck[0] == lastClose)
                std::swap(deck[0], deck[size_t(1 + rng() % uint64_t(KIND_COUNT - 1))]);
            lastClose = deck[KIND_COUNT - 1];
        }
        return deck;
    }
    // }}}

    // {{{ Sky
    // What the sky is at a moment: the kind dealt, its strength (0 to 1,
    // half a sine over the turn), and how the game shows it: a weather
    // state and a grade (the client's intensity, 0 to 1).
    struct Sky
    {
        uint8_t kind     = Fine;
        float   strength = 0.0f;
        uint32_t state   = 0;
        float   grade    = 0.0f;
    };
    // }}}

    // {{{ At
    // The sky at `ms` milliseconds since the seed's moment.
    inline Sky At(uint64_t seed, uint64_t ms)
    {
        uint64_t turn = ms / TURN_MS;
        uint64_t into = ms % TURN_MS;
        auto deck = Deck(seed, turn / KIND_COUNT);
        Sky s;
        s.kind     = deck[size_t(turn % KIND_COUNT)];
        float f    = float(into) / float(TURN_MS);
        s.strength = std::sin(3.14159265f * f);
        s.grade    = std::max(0.0f, std::min(1.0f, s.strength));
        // each kind, and how it is shown:
        //   fine         - no weather (state 0, grade 0)
        //   fog          - fog at the turn's strength
        //   light snow, snow, heavy snow - the game's three snows
        //   light slush, slush - rain, then rain and snow in turns, then snow
        //                  (light: the light rain and snow; slush: the medium)
        switch (s.kind)
        {
            case Fine:      s.state = 0; s.grade = 0.0f; break;
            case Fog:       s.state = 1; break;
            case LightSnow: s.state = 6; break;
            case Snow:      s.state = 7; break;
            case HeavySnow: s.state = 8; break;
            case LightSlush:
            case Slush:
            {
                uint32_t rain = s.kind == Slush ? 4 : 3, snow = s.kind == Slush ? 7 : 6;
                if (f < SLUSH_RAIN_END)
                    s.state = rain;
                else if (f >= SLUSH_SNOW_FROM)
                    s.state = snow;
                else
                {
                    // the trading: spells of 20 to 40 seconds, drawn from the
                    // seed and the turn, starting with snow
                    std::mt19937_64 rng(seed ^ (0xC2B2AE3D27D4EB4Full * (turn + 1)));
                    uint64_t at = uint64_t(SLUSH_RAIN_END * float(TURN_MS)), was = 0;
                    bool snowNow = true;
                    while (true)
                    {
                        uint64_t spell = SLUSH_SWAP_MIN_MS + rng() % (SLUSH_SWAP_MAX_MS - SLUSH_SWAP_MIN_MS + 1);
                        if (into < at + spell) { was = snowNow; break; }
                        at += spell;
                        snowNow = !snowNow;
                    }
                    s.state = was ? snow : rain;
                }
                break;
            }
        }
        return s;
    }
    // }}}
}

#endif
