/*
 * buddies_talent_draw.h - a buddy's talents turned into a weight for each
 * ability, and the weighted draw among one concern's answers (issue 625);
 * plain arithmetic, apart from the server, so it can be tested on its own
 * (tests/buddy-talent-draw/draw.cpp, scripts/test-buddy-talent-draw).
 *
 * For a general audience: the bot module answers each concern (an ally
 * hurt, enemies close) with a fixed list of abilities, each with a priority
 * number, and always takes the first it can. A buddy should lean on the
 * abilities its talents improve, more often, not always. So each ability
 * gets a weight from the talents that touch it (625a's table), and each
 * time the bot chooses, every answer's priority is nudged by a random draw
 * scaled by its weight: within one concern's answers (which sit about one
 * point apart) the nudges decide, and an ability twice as weighted wins
 * about twice as often; across concerns (several points apart: fleeing at
 * 39 before healing at 21) the nudges are too small to change the order.
 */

#ifndef MOD_BUDDIES_TALENT_DRAW_H
#define MOD_BUDDIES_TALENT_DRAW_H

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <map>
#include <string>
#include <vector>

namespace BuddyTalentDraw
{
    // {{{ the numbers
    // PER_POINT: the raise one talent point gives an ability it touches
    //            (measure 1); five points in a talent, +30%.
    // NUDGE:     how far one unit of the random draw moves a priority, as a
    //            share of it: 1.5%, so a draw moves an answer at priority 21
    //            by about a third of a point per unit.
    // DRAW_LOW, DRAW_HIGH: the draw is held between these (a Gumbel draw,
    //            whose highest wins in proportion to the weights; held so
    //            one wild draw can't leap a concern: at most -3% to +6%,
    //            and 34 * 1.06 = 36 stays under fleeing's 39 * 0.97 = 37.8).
    static constexpr float PER_POINT = 0.06f;
    static constexpr float NUDGE     = 0.015f;
    static constexpr float DRAW_LOW  = -2.0f;
    static constexpr float DRAW_HIGH =  4.0f;
    // }}}

    // {{{ Touch
    // One talent touching one ability, from the table: the ability's name
    // (lower case), broad (a whole school or every weapon attack), the
    // percent the talent's top rank states (0 for a flat amount), and the
    // talent's rank count and the points the buddy has in it.
    struct Touch
    {
        std::string ability;
        bool        broad;
        int         percent;
        int         ranks;
        int         points;
    };
    // }}}

    // {{{ Weights
    // Each ability's weight: 1, raised by every talent touching it.
    // measure 1: PER_POINT for each point. measure 2: the talent's own
    // effect where it states a percent (its share at the buddy's rank:
    // percent * points / ranks), and PER_POINT a point where it states a
    // flat amount. A broad talent counts broadShare of that (1 or 0.5).
    // An ability no talent touches is absent: its weight is 1.
    inline std::map<std::string, float> Weights(std::vector<Touch> const& touches, int measure, float broadShare)
    {
        std::map<std::string, float> w;
        for (Touch const& t : touches)
        {
            if (t.points <= 0 || t.ranks <= 0)
                continue;                               // not learned: it touches nothing yet
            float raise = (measure == 2 && t.percent != 0)
                ? std::fabs(float(t.percent)) / 100.0f * float(t.points) / float(t.ranks)
                : PER_POINT * float(t.points);
            if (t.broad)
                raise *= broadShare;
            auto it = w.find(t.ability);
            w[t.ability] = (it == w.end() ? 1.0f : it->second) + raise;
        }
        return w;
    }
    // }}}

    // {{{ Factor
    // The multiplier for one answer this time: u is a random number in
    // (0, 1). The Gumbel draw -ln(-ln u), held to DRAW_LOW..DRAW_HIGH, plus
    // the weight's logarithm, scaled by NUDGE. Among answers of equal
    // priority the highest factor wins with a chance in proportion to the
    // weights (the Gumbel-max rule); an unweighted answer still wins
    // sometimes ("we will always use some of them sometime").
    inline float Factor(float weight, double u)
    {
        u = std::min(std::max(u, 1e-12), 1.0 - 1e-12);
        float g = float(-std::log(-std::log(u)));
        g = std::min(std::max(g, DRAW_LOW), DRAW_HIGH);
        return 1.0f + NUDGE * (std::log(std::max(weight, 0.01f)) + g);
    }
    // }}}
}

#endif
