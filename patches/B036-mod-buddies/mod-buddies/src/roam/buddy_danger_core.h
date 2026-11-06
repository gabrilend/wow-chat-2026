/*
 * buddy_danger_core.h - how dangerous a clan's surroundings are, and how
 * near its owner a roaming buddy keeps because of it (issue 617e10, closer
 * in danger). Plain arithmetic, no server; checked by
 * scripts/test-buddy-danger.
 *
 * For a general audience: the owner, 2026-10-03: "when buddy-bots are in
 * dangerous areas, like the monsters are tougher than they expect, they
 * should stick closer to the player." And 2026-10-28: the roaming radius
 * "shrinks step by step as danger rises, down to the close-follow ring
 * (617s) at its worst, and widens again as fights go well"; what makes a
 * place dangerous is elites and packs, monsters above the buddies' level,
 * how fights went, and close calls, "when allies drop to low health and or
 * die" and "if the healer nearly runs out of mana", which make it "the
 * group's danger, not one buddy's".
 *
 * So one Reading per clan (its owner and buddies), fed by all of them:
 *   - what they see: the heaviest pack near a buddy as it picks a
 *     waypoint, weighed as the tank's pace weighs a pack (normals, three
 *     per elite, 10% more per level above the clan: roam/buddy_pace_core.h),
 *     against the clan's size;
 *   - how each fight ended: the share of the clan's health it cost, deaths;
 *   - close calls as they happen: an ally under CLOSE_HEALTH, an ally
 *     dead, the healer under CLOSE_MANA.
 * A reading above the present one is taken most of the way at once
 * (riseShare); it falls by half every halfLife seconds of quiet, and a
 * step further with each fight that goes well. Its step (0 calm, STEPS the
 * worst) sets the leash: the radius round the owner a roaming waypoint
 * must fall within, from the whole area at 0 down to the close-follow
 * ring at the worst, shrinking by the same share each step; and the most
 * levels above the buddy a monster may be to be sought out, elites
 * passed over from eliteStep on. The reading is cut into steps + 1 equal
 * parts (with four steps: 0.2, 0.4, 0.6, 0.8). The step climbs as soon as the reading
 * reaches it and falls back only once the reading is `stepSlack` below,
 * so a reading on an edge doesn't flicker the leash.
 * Every number is the agent's call (2026-11-06), to be judged in game.
 */

#ifndef BUDDY_DANGER_CORE_H
#define BUDDY_DANGER_CORE_H

#include "buddy_pace_core.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <string>

namespace BuddyDanger
{

// {{{ Settings
struct Settings
{
    int32_t steps          = 4;       // steps above calm; the last is the close-follow ring
    float   riseShare      = 0.7f;    // of the way up to a higher reading, taken at once
    float   halfLife       = 180.0f;  // seconds of quiet that halve the reading
    float   wellDoneFall   = 0.25f;   // a fight that went well takes this share off
    float   stepSlack      = 0.05f;   // below a step's edge by this before it is let go
    float   packEasy       = 1.0f;    // pack weight per clan member that is no danger
    float   packHard       = 3.0f;    // and that is the worst
    float   lostEasy       = 0.15f;   // share of the clan's health a fight cost that is no danger
    float   lostHard       = 0.60f;   // and that is the worst
    float   closeHealth    = 0.20f;   // an ally under this share of its health: a close call
    float   closeMana      = 0.10f;   // the healer under this share of its mana: a close call
    float   closeCall      = 0.75f;   // what a close call reads
    float   wellDoneLost   = 0.20f;   // a fight that cost under this share, with no close call, went well
    float   levelsCalm     = 3.0f;    // levels above the buddy a monster may be, when calm
    int32_t eliteStep      = 2;       // from this step on, elites are passed over
    float   ringYards      = 5.0f;    // the close-follow ring (617s, buddy_follow_core.h's ringYards)
    BuddyPace::Settings weigh;        // how a pack is weighed (elites, levels): the tank's own
};
// }}}

// {{{ Sight
// The heaviest pack a buddy sees as it picks a waypoint (the monsters
// standing together near it; their average level less the clan's), and
// the clan's size.
struct Sight { BuddyPace::Pack pack; uint32_t members = 1; };
// }}}

// {{{ FightEnd
// One fight's end: the clan's health it cost (its members' health lost
// over their health at most, together, 0 to 1), whether anyone died, and
// whether a close call came during it.
struct FightEnd { float lost = 0.0f; bool death = false; bool closeCall = false; };
// }}}

// {{{ Ramp
// 0 at or below `easy`, 1 at or above `hard`, a straight line between.
inline float Ramp(float x, float easy, float hard)
{
    if (hard <= easy) return x < easy ? 0.0f : 1.0f;
    return std::clamp((x - easy) / (hard - easy), 0.0f, 1.0f);
}
// }}}

// {{{ Reading
struct Reading
{
    float   value  = 0.0f;   // 0 calm to 1 the worst
    int32_t step   = 0;      // 0 to steps
    double  lastAt = 0.0;    // seconds, the last Tick

    // {{{ Raise
    // A reading `to` heard: above the present one, most of the way up at once.
    void Raise(float to, Settings const& s)
    {
        if (to > value) value += (to - value) * s.riseShare;
        Restep(s);
    }
    // }}}

    // {{{ Edge
    // Where step `i` begins: the reading cut into steps + 1 equal parts, so
    // the worst step is reached before the reading is wholly 1 (a reading
    // rises toward a danger heard, never quite to it).
    static float Edge(int32_t i, Settings const& s)
    {
        return float(i) / float(s.steps + 1);
    }
    // }}}

    // {{{ Restep
    // The step from the value: up as soon as the value reaches a step's
    // edge, down only once it is `stepSlack` below the edge it climbed past.
    void Restep(Settings const& s)
    {
        int32_t up = std::min(s.steps, int32_t(std::floor(value * float(s.steps + 1) + 1e-6f)));
        if (up > step) step = up;
        while (step > 0 && value < Edge(step, s) - s.stepSlack) --step;
    }
    // }}}

    // {{{ Tick
    // Time passing: the value halves every `halfLife` seconds of quiet.
    void Tick(double now, Settings const& s)
    {
        if (now > lastAt && s.halfLife > 0.0f)
            value *= float(std::pow(0.5, (now - lastAt) / double(s.halfLife)));
        lastAt = std::max(lastAt, now);
        Restep(s);
    }
    // }}}

    // {{{ Saw
    // A buddy's sight as it picks a waypoint: the pack's weight per clan
    // member, from packEasy (no danger) to packHard (the worst).
    void Saw(Sight const& sight, Settings const& s)
    {
        float perMember = BuddyPace::Weight(sight.pack, s.weigh) / float(std::max<uint32_t>(1, sight.members));
        Raise(Ramp(perMember, s.packEasy, s.packHard), s);
    }
    // }}}

    // {{{ Close
    // A close call as it happens (an ally's health or the healer's mana
    // read each update, as shares 0 to 1, or a death): the worst for a
    // death, `closeCall` for the others, nothing otherwise.
    void Close(float allyHealth, float healerMana, bool death, Settings const& s)
    {
        if (death)                                                    Raise(1.0f, s);
        else if (allyHealth < s.closeHealth || healerMana < s.closeMana) Raise(s.closeCall, s);
    }
    // }}}

    // {{{ Fought
    // A fight's end: a death reads the worst; otherwise the health it cost,
    // from lostEasy to lostHard. A fight that cost under wellDoneLost, with
    // no close call and no death, went well: `wellDoneFall` off the value.
    void Fought(FightEnd const& f, Settings const& s)
    {
        if (!f.death && !f.closeCall && f.lost < s.wellDoneLost)
        {
            value *= 1.0f - s.wellDoneFall;
            Restep(s);
            return;
        }
        Raise(f.death ? 1.0f : std::max(Ramp(f.lost, s.lostEasy, s.lostHard), f.closeCall ? s.closeCall : 0.0f), s);
    }
    // }}}

    // {{{ Leash
    // The radius round the owner a roaming waypoint must fall within, for
    // an area `areaYards` across from its centre: the whole area at step 0,
    // the close-follow ring at the last, the same share off each step
    // between (an area no wider than the ring: the ring).
    float Leash(float areaYards, Settings const& s) const
    {
        if (areaYards <= s.ringYards) return std::max(areaYards, 0.0f);
        if (s.steps <= 0)             return areaYards;
        return areaYards * std::pow(s.ringYards / areaYards, float(step) / float(s.steps));
    }
    // }}}

    // {{{ Within
    // Whether a waypoint `yards` from the owner may stand (else the
    // pinwheel is asked again, nearer).
    bool Within(float yards, float areaYards, Settings const& s) const
    {
        return yards <= Leash(areaYards, s);
    }
    // }}}

    // {{{ LevelsAllowed
    // The most levels above the buddy a monster may be to be sought out:
    // levelsCalm at step 0, one fewer each step (below zero at the worst:
    // only monsters beneath it).
    float LevelsAllowed(Settings const& s) const
    {
        return s.levelsCalm - float(step);
    }
    // }}}

    // {{{ Seeks
    // Whether the monster approach may go for a monster `levelAbove` the
    // buddy (its level less the buddy's), elite or not.
    bool Seeks(float levelAbove, bool elite, Settings const& s) const
    {
        if (elite && step >= s.eliteStep) return false;
        return levelAbove <= LevelsAllowed(s);
    }
    // }}}

    // {{{ Trace
    // One line for the trace log: the reading, its step, the leash and the
    // monsters it may seek.
    std::string Trace(float areaYards, Settings const& s) const
    {
        char line[160];
        std::snprintf(line, sizeof line, "danger %.2f step %d/%d leash %.0f yd, monsters up to %+.0f levels%s",
                      double(value), int(step), int(s.steps), double(Leash(areaYards, s)), double(LevelsAllowed(s)),
                      step >= s.eliteStep ? ", no elites" : "");
        return line;
    }
    // }}}
};
// }}}

} // namespace BuddyDanger

#endif
