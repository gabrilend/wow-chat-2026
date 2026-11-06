// danger-check.cpp - checks roam/buddy_danger_core.h (issue 617e10, closer
// in danger): the clan's reading rises fast and falls slowly, from what its
// members see, how fights end and close calls; its step shrinks the leash
// round the owner down to the close-follow ring and narrows the monsters a
// buddy seeks. Built and run by scripts/test-buddy-danger; each check
// prints "ok" or "FAILED"; the exit status is the number that failed.

#include "roam/buddy_danger_core.h"

#include <cmath>
#include <cstdio>
#include <string>

using namespace BuddyDanger;

static int passed = 0, failed = 0;
// {{{ check
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}
// }}}

static bool near(double a, double b, double by = 1e-4) { return std::fabs(a - b) < by; }

int main()
{
    Settings s;
    float const AREA = 200.0f;                                           // a sub-zone 200 yards from its centre

    // {{{ calm
    Reading r;
    check(r.step == 0 && near(r.Leash(AREA, s), AREA), "calm: the whole area");
    check(r.Seeks(3, false, s) && !r.Seeks(4, false, s) && r.Seeks(0, true, s), "calm: monsters up to three levels above, elites too");
    // }}}

    // {{{ what they see
    Sight easy{ { 3, 0, 0.0f }, 5 };                                    // three at level for a clan of five
    r.Saw(easy, s);
    check(r.value == 0.0f && r.step == 0, "three monsters at level for a clan of five: no danger");
    Sight pack{ { 6, 2, 2.0f }, 4 };                                    // six and two elites, two levels up, for four
    float weight = BuddyPace::Weight(pack.pack, s.weigh) / 4.0f;        // (6 + 6) x 1.21 / 4 = 3.63
    check(near(weight, 3.63, 1e-3), "elites, a pack and levels above, weighed as the tank weighs a pack");
    r.Saw(pack, s);
    check(near(r.value, 0.7) && r.step == 3, "a heavy pack seen: most of the way to the worst at once (rises fast)");
    float leash2 = r.Leash(AREA, s);
    check(leash2 < AREA && leash2 > s.ringYards, "the leash shrinks a step at a time");
    check(!r.Seeks(0, true, s) && r.Seeks(0, false, s) && !r.Seeks(1, false, s), "step 3: no elites, none above its own level");
    // }}}

    // {{{ falling slowly
    r.lastAt = 0;
    r.Tick(60, s);
    check(r.value < 0.7f && r.value > 0.55f && r.step == 3, "a minute of quiet: lower, but the leash holds (falls slowly)");
    r.Tick(180, s);
    check(near(r.value, 0.35) && r.step == 2, "three minutes: half, and the leash a step wider");
    r.Tick(300, s);
    check(near(r.value, 0.7 * std::pow(0.5, 300.0 / 180.0)) && r.step == 1, "five minutes: another step wider");
    r.Tick(2000, s);
    check(r.value < 0.01f && r.step == 0, "a long quiet: calm again, the whole area");
    // }}}

    // {{{ the steps: one by one, down to the ring, wider again as fights go well
    Reading w;
    float last = AREA + 1;
    bool narrowing = true;
    for (int i = 0; i < 12; ++i)
    {
        w.Raise(1.0f, s);
        float l = w.Leash(AREA, s);
        narrowing = narrowing && l <= last;
        last = l;
    }
    check(narrowing && w.step == s.steps && near(w.Leash(AREA, s), s.ringYards), "danger rising: the radius shrinks step by step, down to the close-follow ring");
    float ratio1 = Reading{ 0.0f, 1, 0 }.Leash(AREA, s) / Reading{ 0.0f, 0, 0 }.Leash(AREA, s);
    float ratio3 = Reading{ 0.0f, 4, 0 }.Leash(AREA, s) / Reading{ 0.0f, 3, 0 }.Leash(AREA, s);
    check(near(ratio1, ratio3), "each step takes the same share off");
    check(!w.Seeks(0, false, s) && w.Seeks(-1, false, s), "at the worst: only monsters beneath it");
    int before = w.step;
    for (int i = 0; i < 12; ++i) w.Fought({ 0.05f, false, false }, s);
    check(w.step < before && w.step == 0, "fights going well: wider again, step by step, back to the whole area");
    Reading once; once.Raise(1.0f, s); once.Raise(1.0f, s); once.Raise(1.0f, s);
    float v = once.value;
    once.Fought({ 0.05f, false, false }, s);
    check(near(once.value, v * 0.75), "one fight gone well: a quarter off");
    // }}}

    // {{{ how fights went, and close calls: the group's
    Reading f;
    f.Fought({ 0.10f, false, false }, s);
    check(f.value == 0.0f, "a cheap fight: no danger");
    f.Fought({ 0.6f, false, false }, s);
    check(near(f.value, 0.7), "a fight that cost the clan 60% of its health: the worst, most of the way at once");
    Reading d; d.Fought({ 0.1f, true, false }, s);
    check(near(d.value, 0.7), "a death: the worst");
    Reading c; c.Fought({ 0.1f, false, true }, s);
    check(near(c.value, 0.75 * 0.7), "a cheap fight with a close call in it did not go well");
    Reading h; h.Close(0.15f, 1.0f, false, s);
    check(near(h.value, 0.75 * 0.7), "an ally under 20% health: a close call (\"when allies drop to low health\")");
    Reading m; m.Close(1.0f, 0.05f, false, s);
    check(near(m.value, 0.75 * 0.7), "the healer under 10% mana: a close call (\"if the healer nearly runs out of mana\")");
    Reading n; n.Close(0.5f, 0.5f, false, s);
    check(n.value == 0.0f, "an ally at half health, the healer at half mana: nothing");
    Reading k; k.Close(1.0f, 1.0f, true, s);
    check(near(k.value, 0.7), "an ally dead: the worst");
    Reading low; low.Raise(0.9f, s); float high = low.value; low.Raise(0.3f, s);
    check(low.value == high, "a lower reading heard never pulls the value down");
    // }}}

    // {{{ the edges don't flicker
    Reading e; e.value = 0.21f; e.Restep(s);
    check(e.step == 1, "a fifth reached: step 1");
    e.value = 0.17f; e.Restep(s);
    check(e.step == 1, "just under the edge: the step holds");
    e.value = 0.14f; e.Restep(s);
    check(e.step == 0, "well under it: let go");
    Reading e2; e2.value = 0.79f; e2.Restep(s);
    check(e2.step == 3, "0.79: step 3 of 4");
    e2.value = 0.8f; e2.Restep(s);
    check(e2.step == 4, "0.8: step 4, the ring");
    // }}}

    // {{{ the leash
    Reading at; at.step = 2;
    float leash = at.Leash(AREA, s);
    check(near(leash, std::sqrt(AREA * s.ringYards), 1e-2), "halfway down the steps: halfway between the area and the ring, by share");
    check(at.Within(leash - 1, AREA, s) && !at.Within(leash + 1, AREA, s), "a waypoint beyond the leash is refused");
    check(near(Reading{ 0, 4, 0 }.Leash(3.0f, s), 3.0f), "an area smaller than the ring: the area");
    // }}}

    // {{{ the trace
    std::string t = at.Trace(AREA, s);
    std::printf("   (%s)\n", t.c_str());
    check(t.find("step 2/4") != std::string::npos && t.find("leash 32 yd") != std::string::npos && t.find("no elites") != std::string::npos,
          "the trace line names the step, the leash and the elites");
    // }}}

    std::printf("%d checks, %d failed\n", passed + failed, failed);
    return failed;
}
