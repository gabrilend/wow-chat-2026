// pace-check.cpp - checks the tank's pace (roam/buddy_pace_core.h) against
// the owner's design, with no server (issue 617z). Built and run by
// scripts/test-buddy-pace. Each check prints "ok" or "FAIL" and what it
// held; the exit status is the number of failures.

#include "buddy_pace_core.h"
#include <cstdio>

using namespace BuddyPace;

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

int main()
{
    Settings s;

    // {{{ the words
    check(ReadWord("wait") == Word::Slow && ReadWord("Slow down!") == Word::Slow && ReadWord("go slower") == Word::Slow,
          "wait, slow down, go slower slow the tank (any case, punctuation ignored)");
    check(ReadWord("OOM") == Word::Oom && ReadWord("out of mana") == Word::Oom && ReadWord("mana") == Word::Oom,
          "oom, out of mana, mana stop it");
    check(ReadWord("ready") == Word::Ready, "ready lets it go on");
    check(ReadWord("go faster") == Word::None && ReadWord("I'm waiting for mana here") == Word::None,
          "no word for faster; a longer line holding a word is not the word");
    // }}}

    // {{{ the pack's weight
    Pack three{ 3, 0, 0.0f }, oneElite{ 0, 1, 0.0f }, higher{ 3, 0, 2.0f };
    check(Weight(three, s) == 3.0f && Weight(oneElite, s) == 3.0f, "three normals weigh as one elite");
    check(Weight(higher, s) > Weight(three, s), "a pack above the group's level weighs more");
    // }}}

    // {{{ confidence: fast by default, slowed by words, regained over time
    Tank t(s);
    check(t.confidence == s.startConfidence, "a tank starts confident (\"default to going faster\")");
    check(t.ShouldPull(100.0f, three, s), "a full healer and a plain pack: pull");
    float before = t.confidence;
    t.Heard(Word::Slow, s);
    check(t.confidence < before, "\"slow down\" lowers its confidence");
    check(t.Reserve(s) > (1.0f - before) * s.maxReserve, "a lower confidence keeps more mana in reserve");
    t.Tick(1000, s);
    t.Tick(1000 + 60000 * 10, s);
    check(t.confidence == s.startConfidence, "ten minutes later it is back to its usual confidence, not above");
    for (int i = 0; i < 10; ++i)
        t.Heard(Word::Slow, s);
    check(t.confidence == s.minConfidence, "many slowing words: never below the floor");
    // }}}

    // {{{ oom and ready
    Tank u(s);
    u.Heard(Word::Oom, s);
    check(!u.ShouldPull(100.0f, three, s), "after \"oom\" it waits, whatever the mana");
    u.Heard(Word::Ready, s);
    check(u.ShouldPull(100.0f, three, s), "\"ready\" lets it pull again");
    // }}}

    // {{{ the healer's mana against the expected cost
    Tank v(s);
    check(!v.ShouldPull(20.0f, three, s), "a healer at 20% and a pack expected to cost 30%: wait");
    v.Fought({ 10.0f, 3.0f }, 90.0f, s);
    check(v.ExpectedCost(three, s) == 10.0f, "the record says such a pack costs 10%");
    check(v.ShouldPull(20.0f, three, s), "with that record, 20% is enough for it");
    Pack big{ 6, 2, 0.0f };
    check(v.ExpectedCost(big, s) == 40.0f, "a pack four times as heavy is expected to cost 40%");
    check(!v.ShouldPull(35.0f, big, s), "at 35% mana that pack waits");
    check(v.ShouldPull(50.0f, big, s), "at 50% a confident tank takes it (10% left, more than its small reserve)");
    // }}}

    // {{{ going faster: a fight that went well raises it
    Tank w(s);
    w.Heard(Word::Slow, s);
    float slowed = w.confidence;
    w.Fought({ 15.0f, 6.0f }, 70.0f, s);
    check(w.confidence > slowed, "a bigger pull someone else made, the healer still well off: a little more confident");
    float beforeDrain = w.confidence;
    w.Fought({ 60.0f, 6.0f }, 5.0f, s);
    check(w.confidence == beforeDrain, "a fight that drained the healer below the reserve adds no confidence");
    // }}}

    // {{{ clearing width
    Tank calm(s), nervous(s);
    for (int i = 0; i < 3; ++i)
        nervous.Heard(Word::Slow, s);
    check(calm.ClearYards(s) > nervous.ClearYards(s), "a confident tank clears wider than a nervous one");
    check(nervous.ClearYards(s) >= s.clearMin && calm.ClearYards(s) <= s.clearMax, "the width stays between its bounds");
    // }}}

    std::printf("%d checks, %d failed\n", checks, failures);
    return failures;
}
