// pace-check.cpp - checks the tank's pace (roam/buddy_pace_core.h) against
// the owner's design, with no server (issue 617z). Built and run by
// scripts/test-buddy-pace. Each check prints "ok" or "FAIL" and what it
// held; the exit status is the number of failures.

#include "buddy_pace_core.h"
#include <cstdio>
#include <cmath>
#include <string>

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

    // {{{ a player's pull, picked up (2026-11-06)
    Tank p(s);
    p.Fought({ 40.0f, 6.0f }, 0.0f, s);                                  // a hard fight remembered: 6.7% a unit of weight
    p.Heard(Word::Slow, s);
    p.Heard(Word::Slow, s);                                              // a nervous tank: 0.3
    Pack pulled{ 6, 2, 0.0f };                                           // weight 12
    check(!p.ShouldPull(70.0f, pulled, s), "a nervous tank with a hard fight behind it wouldn't pull a big pack at 70% mana");
    char const* said = p.PlayerPulled({ 30.0f, 12.0f }, 70.0f, 40.0f, pulled, s);
    check(said && std::string(said).find("Fine") == 0, "a player pulls it: the tank picks it up, a little put out");
    check(p.ShouldPull(70.0f, pulled, s), "the healer came out well: it adjusts to the new speed, and would pull it now");
    check(p.confidence > 0.3f + s.wellDoneGain + 0.01f, "its confidence rose to meet it, more than a fight gone well alone gives");
    float exact = 1.0f - (70.0f - p.ExpectedCost(pulled, s)) / s.maxReserve;
    check(std::fabs(p.confidence - exact) < 1e-5f, "exactly to what that pull needs, no further");
    Tank q(s);
    q.Heard(Word::Slow, s);
    q.Heard(Word::Slow, s);
    float nervousAt = q.confidence;
    q.PlayerPulled({ 75.0f, 12.0f }, 80.0f, 5.0f, pulled, s);
    check(q.confidence == nervousAt && !q.ShouldPull(80.0f, pulled, s), "the healer drained by it: no new speed learned");
    check(q.record.size() == 1, "either way the fight is remembered");
    Tank r(s);
    float high = r.confidence;
    r.PlayerPulled({ 3.0f, 3.0f }, 100.0f, 97.0f, three, s);
    check(r.confidence >= high, "a small pull never lowers a confident tank");
    // }}}

    // {{{ what it says when it holds
    Tank say(s);
    check(say.WaitLine(100.0f, three, s) == nullptr, "pulling: nothing to say");
    check(std::string(say.WaitLine(10.0f, three, s)) == "Waiting for mana.", "short of mana: \"Waiting for mana.\"");
    say.Heard(Word::Oom, s);
    check(std::string(say.WaitLine(100.0f, three, s)) == "Waiting for ready.", "stopped by oom: \"Waiting for ready.\"");
    // }}}

    // {{{ harmless packs
    check(GreyLevel(5) == 0 && GreyLevel(20) == 13 && GreyLevel(39) == 31 && GreyLevel(40) == 31 && GreyLevel(59) == 47 && GreyLevel(60) == 51 && GreyLevel(80) == 71,
          "the game's grey levels (20: 13, 40: 31, 60: 51, 80: 71)");
    check(PackPlan(20, 14, false) == Plan::Pull, "a level-14 pack for a level-20 tank: pulled as any");
    check(PackPlan(20, 13, false) == Plan::WalkPast, "grey and not hostile: walked past (\"they refuse to fight\")");
    check(PackPlan(20, 13, true) == Plan::Sweep, "grey and hostile: swept up on the way by area attacks");
    // }}}

    // {{{ a healer buddy's own "slow down"
    HealerVoice h;
    check(h.Fought(60.0f, false, s) == Word::None && h.Fought(20.0f, false, s) == Word::None, "one fight ending low: nothing yet");
    check(h.Fought(15.0f, false, s) == Word::Slow, "two of the last three ending under 25%: \"slow down\"");
    check(ReadWord("slow down") == Word::Slow, "(the same words the tank hears from anyone)");
    check(h.Fought(10.0f, false, s) == Word::None && h.Fought(10.0f, false, s) == Word::None && h.Fought(10.0f, false, s) == Word::None,
          "then quiet for three fights: it said its piece, the tank rebuilds over time");
    check(h.Fought(10.0f, false, s) == Word::None, "and a fresh start after: one low fight isn't enough");
    check(h.Fought(10.0f, false, s) == Word::Slow, "two again: says it again");
    HealerVoice behind;
    check(behind.Fought(70.0f, true, s) == Word::Slow, "health falling faster than it can heal: says it at once");
    HealerVoice fine;
    bool silent = true;
    for (int i = 0; i < 20; ++i) silent = silent && fine.Fought(i % 3 == 0 ? 20.0f : 60.0f, false, s) == Word::None;
    check(silent, "one low fight in three, never behind: never says it");
    Tank heard(s);
    float c0 = heard.confidence;
    HealerVoice whisper;
    heard.Heard(whisper.Fought(10.0f, true, s), s);
    check(heard.confidence < c0, "the tank hears it as any \"slow down\"");
    // }}}

    std::printf("%d checks, %d failed\n", checks, failures);
    return failures;
}
