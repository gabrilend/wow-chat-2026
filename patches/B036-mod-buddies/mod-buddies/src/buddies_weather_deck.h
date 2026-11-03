
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
    enum Kind : uint8_t { Fine, Fog, LightSnow, Snow, HeavySnow, LightSlush, Slush, KIND_COUNT };
    static constexpr char const* KIND_NAMES[KIND_COUNT] = { "fine", "fog", "light snow", "snow", "heavy snow", "light slush", "slush" };

    static constexpr uint64_t TURN_MS           = 6 * 60 * 1000;
    static constexpr float    SLUSH_RAIN_END    = 0.30f;
    static constexpr float    SLUSH_SNOW_FROM   = 0.70f;
    static constexpr uint64_t SLUSH_SWAP_MIN_MS = 20000;
    static constexpr uint64_t SLUSH_SWAP_MAX_MS = 40000;

    inline std::array<uint8_t, KIND_COUNT> Deck(uint64_t seed, uint64_t d)
    {
        std::array<uint8_t, KIND_COUNT> deck{};
        uint8_t lastClose = KIND_COUNT;
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

    struct Sky
    {
        uint8_t kind     = Fine;
        float   strength = 0.0f;
        uint32_t state   = 0;
        float   grade    = 0.0f;
    };

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
}

#endif
