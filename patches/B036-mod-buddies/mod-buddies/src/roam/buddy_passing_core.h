/*
 * buddy_passing_core.h - two walkers passing each other: whether they would
 * meet, how each swerves, and how they greet; and a buddy's round of its
 * clan-mates at login (issue 617e11, passing each other). Plain
 * arithmetic, no server; checked by scripts/test-buddy-passing.
 *
 * For a general audience: the owner, 2026-10-07, on two buddies crossing
 * paths in the open: "ideally, swerve. Maybe wave at each other, or if
 * they're high level compared to a low level, stop and kneel for 3 seconds
 * (when neither is in combat)". And 2026-10-28: the lower one kneels to
 * anyone at least double its level; players are passed, greeted and knelt
 * to like anyone else; "Clanmates only greet each other when they log in.
 * They should walk to each clan mate and greet them, wait a second or two,
 * and then greet someone else. Sometimes that second or two becomes a chat
 * that has a 20% chance of ending after every /talk emote."
 *
 * The pieces:
 *   Meet    - where two walkers on straight lines come nearest in the next
 *             `horizon` seconds, and how near;
 *   Swerve  - if that is closer than their two bodies (and a little room),
 *             each bends half of the shortfall aside, away from where the
 *             other will be (head on: each to its own right), the bend a
 *             half-cosine out and back round the meeting point, as the
 *             path planner bends round a rock (BendAt);
 *   Greet   - as they pass within GREET_YARDS, neither fighting and not
 *             clan-mates: the lower kneels for KNEEL_SECONDS to one at
 *             least double its level, otherwise both wave, the higher (or
 *             the lower id at the same level) first and the other a beat
 *             later; a player is greeted and knelt to, never made to;
 *   Round   - at login, a buddy's round of its clan-mates: nearest first,
 *             each greeted with a wave, then a pause of one to two
 *             seconds that now and then becomes a chat of /talk emotes,
 *             each with a one-in-five chance of being the last.
 * The numbers not given by the owner are the agent's calls (2026-11-06),
 * to be judged in game.
 */

#ifndef BUDDY_PASSING_CORE_H
#define BUDDY_PASSING_CORE_H

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <functional>
#include <vector>

namespace BuddyPassing
{

// {{{ the numbers
constexpr float HORIZON        = 3.0f;   // seconds ahead two walkers are projected ("the next few seconds")
constexpr float ROOM           = 0.5f;   // yards kept between two bodies as they pass
constexpr float EASE           = 4.0f;   // yards before and after the meeting point the bend takes
constexpr float GREET_YARDS    = 5.0f;   // "as two buddies pass within a few yards"
constexpr float KNEEL_SECONDS  = 3.0f;   // the owner's "kneel for 3 seconds"
constexpr float KNEEL_RATIO    = 2.0f;   // "at least double its level"
constexpr float ANSWER_SECONDS = 0.8f;   // the second wave, a beat after the first
constexpr float PAUSE_MIN      = 1.0f;   // "wait a second or two"
constexpr float PAUSE_MAX      = 2.0f;
constexpr float CHAT_CHANCE    = 0.25f;  // a pause that becomes a chat ("sometimes")
constexpr float CHAT_END       = 0.2f;   // "a 20% chance of ending after every /talk emote"
constexpr float TALK_SECONDS   = 2.0f;   // one /talk emote's length
// }}}

// {{{ Walker
// One walker now: where it is and its velocity (yards, yards a second,
// across the ground), and its body's radius (half the roam core's `body`).
struct Walker { float x = 0, y = 0, vx = 0, vy = 0, radius = 0.305f; };
// }}}

// {{{ Meeting
// When (seconds from now, 0 to the horizon) two walkers come nearest, how
// near, and where each is then.
struct Meeting { float t, yards, ax, ay, bx, by; };

inline Meeting Meet(Walker const& a, Walker const& b, float horizon = HORIZON)
{
    float dx = b.x - a.x, dy = b.y - a.y, wx = b.vx - a.vx, wy = b.vy - a.vy;
    float ww = wx * wx + wy * wy;
    float t  = ww > 1e-9f ? std::clamp(-(dx * wx + dy * wy) / ww, 0.0f, horizon) : 0.0f;
    float ax = a.x + a.vx * t, ay = a.y + a.vy * t, bx = b.x + b.vx * t, by = b.y + b.vy * t;
    return { t, std::hypot(bx - ax, by - ay), ax, ay, bx, by };
}
// }}}

// {{{ Swerve
// How far `a` bends aside to pass `b`: 0 when they won't come within their
// two bodies and ROOM; otherwise half of the shortfall (the other bends the
// other half), signed: + to a's left, - to its right, away from where b
// will be at the meeting. In line (b straight ahead or behind) they keep
// right and pass on the left: two head on both bend to their own right; of
// two going the same way, the faster bends left and the slower right. A
// standing walker (no velocity) doesn't
// swerve; the walker passing it bends the whole shortfall.
struct Bend { bool needed; float t, offset; };

inline Bend Swerve(Walker const& a, Walker const& b, float horizon = HORIZON)
{
    float speed = std::hypot(a.vx, a.vy);
    if (speed < 1e-6f) return { false, 0.0f, 0.0f };
    Meeting m = Meet(a, b, horizon);
    float need = a.radius + b.radius + ROOM - m.yards;
    if (need <= 0.0f) return { false, m.t, 0.0f };
    bool  bStands = std::hypot(b.vx, b.vy) < 1e-6f;
    float share   = bStands ? need : need / 2.0f;
    float cross   = a.vx * (m.by - m.ay) - a.vy * (m.bx - m.ax);    // > 0: b to a's left
    float side    = cross > 0.0f ? -1.0f : 1.0f;
    if (std::fabs(cross) < 1e-4f * speed)                              // in line: keep right, pass on the left
    {
        bool sameWay = a.vx * b.vx + a.vy * b.vy > 0.0f;
        side = sameWay && speed > std::hypot(b.vx, b.vy) ? 1.0f : -1.0f;
    }
    return { true, m.t, side * share };
}
// }}}

// {{{ BendAt
// The sideways offset `along` yards down the path, for a bend of `offset`
// whose middle is `at` yards down it: a half-cosine from nothing, EASE
// yards before, to the whole offset at the middle and back to nothing EASE
// yards after (smooth at both ends, as the planner eases round a rock).
inline float BendAt(float along, float at, float offset, float ease = EASE)
{
    float u = (along - at) / ease;
    if (u <= -1.0f || u >= 1.0f) return 0.0f;
    return offset * 0.5f * (1.0f + std::cos(3.14159265f * u));
}
// }}}

// {{{ Passer
// One of two passing: its level, whether it is fighting, whether it is a
// player (never made to greet), its clan (the owner's id), and its id.
struct Passer { int32_t level = 1; bool fighting = false; bool player = false; uint64_t clan = 0, id = 0; };
// }}}

// {{{ Greet
// What `a` does as it passes `b` `yards` away: nothing (too far, either
// fighting, clan-mates, or `a` a player), kneel for KNEEL_SECONDS (`b` at
// least double its level), nothing while `b` kneels to it, or wave, `delay`
// seconds after they come level: the higher level first, at the same level
// the lower id, the other a beat later.
enum class Act : uint8_t { None, Wave, Kneel };
struct Greeting { Act act; float delay, seconds; };

inline Greeting Greet(Passer const& a, Passer const& b, float yards)
{
    if (yards > GREET_YARDS || a.fighting || b.fighting || a.player) return { Act::None, 0, 0 };
    if (a.clan != 0 && a.clan == b.clan)                             return { Act::None, 0, 0 };
    if (float(b.level) >= KNEEL_RATIO * float(a.level))              return { Act::Kneel, 0, KNEEL_SECONDS };
    if (float(a.level) >= KNEEL_RATIO * float(b.level))              return { Act::None, 0, 0 };
    bool first = a.level != b.level ? a.level > b.level : a.id < b.id;
    return { Act::Wave, first ? 0.0f : ANSWER_SECONDS, 0 };
}
// }}}

// {{{ Round
// A buddy's round of its clan-mates at login (the owner, 2026-10-28):
// steps in order, each a walk to a clan-mate, a wave, and a pause of
// PAUSE_MIN to PAUSE_MAX seconds; with CHAT_CHANCE the pause is a chat
// instead, /talk emotes of TALK_SECONDS each, each with CHAT_END chance of
// being the last. The order: the nearest first, then the nearest to it,
// and so on. `rng` gives numbers 0 <= r < 1.
enum class Do : uint8_t { Walk, Wave, Pause, Talk };
struct Step { Do what; uint64_t to; float seconds; };
struct Mate { uint64_t id; float x, y; };

inline std::vector<Step> Round(float x, float y, std::vector<Mate> mates, std::function<double()> const& rng)
{
    std::vector<Step> out;
    while (!mates.empty())
    {
        size_t near = 0;
        for (size_t i = 1; i < mates.size(); ++i)
            if (std::hypot(mates[i].x - x, mates[i].y - y) < std::hypot(mates[near].x - x, mates[near].y - y)) near = i;
        Mate m = mates[near];
        mates.erase(mates.begin() + long(near));
        out.push_back({ Do::Walk, m.id, 0.0f });
        out.push_back({ Do::Wave, m.id, 0.0f });
        if (rng() < CHAT_CHANCE)
            do out.push_back({ Do::Talk, m.id, TALK_SECONDS });
            while (rng() >= CHAT_END);
        else
            out.push_back({ Do::Pause, m.id, PAUSE_MIN + float(rng()) * (PAUSE_MAX - PAUSE_MIN) });
        x = m.x; y = m.y;
    }
    return out;
}
// }}}

} // namespace BuddyPassing

#endif
