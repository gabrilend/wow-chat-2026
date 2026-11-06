/*
 * buddies_stat_blend.h - how a buddy with points in more than one tree
 * values each stat, whether a small upgrade is worn, and where a class book
 * goes (issue 617j, the owner's answers of 2026-10-28); plain arithmetic,
 * apart from the server, so it can be tested on its own
 * (tests/buddy-stat-blend/, scripts/test-buddy-stat-blend).
 *
 * For a general audience: a buddy with a third of its points in each tree
 * scores items by a blend of its trees' stat weights. The owner, word for
 * word: "we have to make sure that we have stats that all three would want.
 * I'm concerned that blending the weights might just mean everyone
 * prioritizes things like stamina, that everyone wants. Also if the blend
 * has a healing spec it should disprefer hit rating, this counts for the
 * 2-1 specs as well." So each tree's weights count by its share, but a
 * stat a tree only tolerates (well under what it wants most) counts for
 * little, so a stat every tree tolerates can't win by being shared; and a
 * blend with a healing tree marks hit rating down. And the upgrade bar:
 * "for 0-10% improvement they should only take it if nobody else wants
 * it." And class books: "class books should always be given to
 * clanmembers (no player preference) unless no clanmate needs them, then
 * they are auctioned."
 *
 * The weights per tree are the bot module's own (its stats-weight
 * calculator, level 80's, used as is: 2026-09-24); the server (source patch
 * B046's scorer) reads them per tree and hands them here.
 */

#ifndef MOD_BUDDIES_STAT_BLEND_H
#define MOD_BUDDIES_STAT_BLEND_H

#include <algorithm>
#include <cstdint>
#include <map>
#include <vector>

namespace BuddyBlend
{
    // {{{ the numbers
    // WANTED:     a stat a tree weighs at this share of its own most-wanted
    //             stat or more is wanted by that tree; below, tolerated
    // TOLERATED:  what a tolerated stat counts for, as a share of its own
    //             weight (stamina, armour: liked a little by everyone)
    // HIT_HEALER: hit rating's blended weight in a blend with a healing
    //             tree, as a share (heals never miss)
    // UPGRADE:    the score an item must reach, over what is worn, to be
    //             worn whoever else wants it (the bot module's own 1.1:
    //             `AiPlayerbot.EquipUpgradeThreshold`)
    constexpr double WANTED     = 0.6;
    constexpr double TOLERATED  = 0.25;
    constexpr double HIT_HEALER = 0.5;
    constexpr double UPGRADE    = 1.10;
    // }}}

    // {{{ Tree
    // One tree the buddy has points in: its share of the points, whether it
    // is a healing tree, and its stat weights (the bot module's stat type,
    // its STATS_TYPE_ number, -> weight).
    using Weights = std::map<int, double>;
    struct Tree { double share = 0; bool healing = false; Weights weights; };
    // }}}

    // {{{ Wanted
    // A tree's weight for a stat as it counts in a blend: its own weight
    // when the tree wants it (WANTED of its top weight or more), TOLERATED
    // of it otherwise.
    inline double Wanted(Tree const& t, int stat)
    {
        auto it = t.weights.find(stat);
        if (it == t.weights.end() || it->second <= 0) return 0.0;
        double top = 0.0;
        for (auto const& w : t.weights) top = std::max(top, w.second);
        return it->second >= WANTED * top ? it->second : TOLERATED * it->second;
    }
    // }}}

    // {{{ Blend
    // The buddy's weights: each stat the sum over its trees of share x
    // Wanted; hit rating (`hitStat`, the bot module's STATS_TYPE_HIT) times
    // HIT_HEALER when any tree with points is a healing one. A buddy with
    // all its points in one tree keeps that tree's weights unchanged.
    inline Weights Blend(std::vector<Tree> const& trees, int hitStat)
    {
        std::vector<Tree const*> spoken;
        for (Tree const& t : trees) if (t.share > 0) spoken.push_back(&t);
        if (spoken.size() == 1) return spoken.front()->weights;
        Weights out;
        bool healer = false;
        for (Tree const* t : spoken)
        {
            healer = healer || t->healing;
            for (auto const& w : t->weights) out[w.first] += t->share * Wanted(*t, w.first);
        }
        if (healer && out.count(hitStat)) out[hitStat] *= HIT_HEALER;
        return out;
    }

    // An item's score by weights: the sum of its stats times their weights.
    inline double Score(Weights const& weights, std::map<int, double> const& stats)
    {
        double s = 0.0;
        for (auto const& st : stats)
        {
            auto it = weights.find(st.first);
            if (it != weights.end()) s += it->second * st.second;
        }
        return s;
    }
    // }}}

    // {{{ Wear
    // Whether a buddy wears an item scoring `candidate` against `worn`: at
    // UPGRADE or more, yes; better but less, only when nobody else in the
    // clan wants it; no better, no. Nothing worn in that slot: any item that
    // scores is an upgrade.
    inline bool Wear(double candidate, double worn, bool someoneElseWants)
    {
        if (candidate <= 0) return false;
        if (worn <= 0) return true;
        double ratio = candidate / worn;
        if (ratio >= UPGRADE) return true;
        return ratio > 1.0 && !someoneElseWants;
    }
    // }}}

    // {{{ Book
    // Where a class book goes: to a clan member who can learn it and hasn't
    // (players and buddies alike, "no player preference"), the first such
    // in the clan's order; none, to the auction house (-1).
    struct Member { bool canLearn = false, knows = false; };
    inline int BookTo(std::vector<Member> const& clan)
    {
        for (size_t i = 0; i < clan.size(); ++i)
            if (clan[i].canLearn && !clan[i].knows) return int(i);
        return -1;
    }
    // }}}
}

#endif
