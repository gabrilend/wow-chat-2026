// passing-check.cpp - checks roam/buddy_passing_core.h (issue 617e11,
// passing each other): where two walkers meet, how each swerves, how they
// greet, and a buddy's round of its clan-mates at login. Built and run by
// scripts/test-buddy-passing; each check prints "ok" or "FAILED".

#include "roam/buddy_passing_core.h"

#include <cmath>
#include <cstdio>
#include <map>

using namespace BuddyPassing;

static int passed = 0, failed = 0;
// {{{ check
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}
// }}}

static bool near(double a, double b, double by = 1e-4) { return std::fabs(a - b) < by; }

// {{{ Shifted
// A walker moved `offset` yards aside (+ its left), as its bend stands at
// the meeting point.
static Walker Shifted(Walker w, float offset)
{
    float speed = std::hypot(w.vx, w.vy);
    if (speed < 1e-6f) return w;
    w.x += -w.vy / speed * offset;
    w.y +=  w.vx / speed * offset;
    return w;
}
// }}}

struct Lcg { unsigned s; double operator()() { s = s * 1103515245u + 12345u; return double((s >> 8) & 0xffffff) / double(0x1000000); } };

int main()
{
    float const NEED = 0.305f * 2.0f + ROOM;

    // {{{ meeting
    Walker a{ 0, 0, 2, 0 }, b{ 8, 0, -2, 0 };
    Meeting m = Meet(a, b);
    check(near(m.t, 2) && near(m.yards, 0), "head on, 8 yards apart at 2 a second each: they meet in 2 seconds");
    Walker far{ 20, 0, -2, 0 };
    check(!Swerve(a, far).needed, "meeting beyond the next three seconds: no swerve yet");
    Walker beside{ 0, 3, 2, 0 };
    check(!Swerve(a, beside).needed && near(Meet(a, beside).yards, 3), "walking side by side three yards apart: no swerve");
    // }}}

    // {{{ swerving
    Bend ba = Swerve(a, b), bb = Swerve(b, a);
    check(ba.needed && bb.needed && near(ba.offset, -NEED / 2) && near(bb.offset, -NEED / 2), "head on: each bends half the room needed, to its own right");
    Meeting after = Meet(Shifted(a, ba.offset), Shifted(b, bb.offset));
    check(after.yards >= NEED - 1e-4f, "and after both bends they pass a body and a little room apart");
    Walker cross{ 4, -5, 0, 2 };                                           // coming up from a's right, just behind it
    Bend bc = Swerve(a, cross);
    check(bc.needed && bc.offset > 0, "one crossing from the right: a bends left, away from it");
    Walker crossLeft{ 4, 5, 0, -2 };
    check(Swerve(a, crossLeft).offset < 0, "from the left: a bends right");
    Walker stand{ 4, 0.2f, 0, 0 };
    Bend bs = Swerve(a, stand);
    check(bs.needed && near(std::fabs(bs.offset), NEED - 0.2f) && bs.offset < 0, "someone standing just left of the line: the walker bends the whole way, to the right");
    check(!Swerve(stand, a).needed, "the one standing doesn't swerve");
    Walker overtake{ -3, 0, 4, 0 };
    Bend bo = Swerve(overtake, a), bo2 = Swerve(a, overtake);
    check(bo.needed && bo2.needed && Meet(Shifted(overtake, bo.offset), Shifted(a, bo2.offset)).yards >= NEED - 1e-4f,
          "one overtaking another: they part, the faster passing on the left");
    check(bo.offset > 0 && bo2.offset < 0, "(the faster left, the slower right)");
    Walker dead{ 4, 0, -2, 0 };
    check(Swerve(a, dead).offset < 0, "exactly head on: to its own right");
    Lcg r{ 617 };
    int better = 0, tries = 0;
    for (int k = 0; k < 2000; ++k)
    {
        Walker p{ float(r() * 10 - 5), float(r() * 10 - 5), float(r() * 4 - 2), float(r() * 4 - 2) };
        Walker q{ float(r() * 10 - 5), float(r() * 10 - 5), float(r() * 4 - 2), float(r() * 4 - 2) };
        Bend bp = Swerve(p, q), bq = Swerve(q, p);
        if (!bp.needed || !bq.needed) continue;
        ++tries;
        float before = Meet(p, q).yards, now = Meet(Shifted(p, bp.offset), Shifted(q, bq.offset)).yards;
        better += now > before;
    }
    std::printf("   (%d of %d random near-meetings pass wider after the bends)\n", better, tries);
    check(tries > 50 && better == tries, "every random near-meeting passes wider once both bend");
    // }}}

    // {{{ the bend's shape
    check(BendAt(10, 20, 1) == 0.0f && BendAt(30, 20, 1) == 0.0f, "nothing before or after the bend");
    check(near(BendAt(20, 20, -0.6f), -0.6f), "the whole offset at the meeting point");
    check(near(BendAt(18, 20, 1), 0.5f) && near(BendAt(22, 20, 1), 0.5f), "half of it halfway in and halfway out");
    bool smooth = true;
    for (float d = 14; d < 26; d += 0.01f) smooth = smooth && std::fabs(BendAt(d + 0.01f, 20, 1) - BendAt(d, 20, 1)) < 0.004f;
    check(smooth && BendAt(16.02f, 20, 1) < 0.0001f, "no jump, and it eases in gently");
    // }}}

    // {{{ greeting
    Passer low{ 10, false, false, 1, 101 }, high{ 20, false, false, 2, 202 }, mid{ 19, false, false, 3, 303 }, same{ 10, false, false, 4, 404 };
    Greeting g = Greet(low, high, 3);
    check(g.act == Act::Kneel && near(g.seconds, 3), "level 10 passing level 20: kneels for three seconds");
    check(Greet(high, low, 3).act == Act::None, "and the level 20 walks on");
    check(Greet(low, mid, 3).act == Act::Wave && Greet(mid, low, 3).act == Act::Wave, "level 10 and 19: both wave");
    check(Greet(mid, low, 3).delay == 0.0f && Greet(low, mid, 3).delay > 0.0f, "the higher waves first, the other a beat later");
    check(Greet(low, same, 3).delay == 0.0f && Greet(same, low, 3).delay > 0.0f, "the same level: the lower id first");
    check(Greet(low, high, 6).act == Act::None, "six yards apart: too far to greet");
    Passer fighting = high; fighting.fighting = true;
    check(Greet(low, fighting, 3).act == Act::None && Greet(fighting, low, 3).act == Act::None, "either one fighting: nothing");
    Passer mate = high; mate.clan = low.clan;
    check(Greet(low, mate, 3).act == Act::None, "clan-mates greet only at login, not in passing");
    Passer player = high; player.player = true;
    check(Greet(low, player, 3).act == Act::Kneel, "a buddy kneels to a player of double its level too");
    Passer lowPlayer = low; lowPlayer.player = true;
    check(Greet(lowPlayer, high, 3).act == Act::None && Greet(lowPlayer, mid, 3).act == Act::None, "a player is never made to greet");
    // }}}

    // {{{ the round at login
    std::vector<Mate> mates = { { 1, 9, 0 }, { 2, 3, 0 }, { 3, -4, 0 }, { 4, 9, 30 } };
    Lcg seq{ 11 };
    std::vector<Step> steps = Round(0, 0, mates, [&] { return seq(); });
    std::vector<uint64_t> order;
    for (Step const& s : steps) if (s.what == Do::Walk) order.push_back(s.to);
    check(order == std::vector<uint64_t>({ 2, 1, 3, 4 }), "nearest first, then the nearest to that one (not to where it started)");
    bool shape = true;
    for (size_t i = 0; i < steps.size(); ++i)
    {
        if (steps[i].what == Do::Walk) shape = shape && i + 1 < steps.size() && steps[i + 1].what == Do::Wave;
        if (steps[i].what == Do::Pause) shape = shape && steps[i].seconds >= PAUSE_MIN && steps[i].seconds <= PAUSE_MAX;
    }
    check(shape && steps.front().what == Do::Walk, "each: walk to them, wave, then a pause of a second or two (or a chat)");
    check(Round(0, 0, {}, [&] { return seq(); }).empty(), "no clan-mates online: no round");
    int chats = 0, talks = 0, greeted = 0;
    Lcg many{ 2026 };
    for (int k = 0; k < 20000; ++k)
    {
        std::vector<Step> one = Round(0, 0, { { 9, 5, 5 } }, [&] { return many(); });
        ++greeted;
        int t = 0;
        for (Step const& s : one) t += s.what == Do::Talk;
        if (t) { ++chats; talks += t; }
    }
    double chatShare = double(chats) / greeted, perChat = double(talks) / chats;
    std::printf("   (%.3f of greetings became chats, %.2f /talk emotes each)\n", chatShare, perChat);
    check(std::fabs(chatShare - 0.25) < 0.015, "now and then the pause becomes a chat (a quarter of the time)");
    check(std::fabs(perChat - 5.0) < 0.25, "a chat ends after each /talk one time in five: five emotes on average");
    // }}}

    std::printf("%d checks, %d failed\n", passed + failed, failed);
    return failed;
}
