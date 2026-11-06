/*
 * buddies_tree_shares.h - one list from every tree a buddy has points in
 * (issue 625c): each tree's answers weighted by its share, the casts kept
 * to the trees' shares over a fight, and the role's tree speaking first on
 * a concern two trees answer; plain arithmetic, apart from the server, so
 * it can be tested on its own (tests/buddy-tree-shares/,
 * scripts/test-buddy-tree-shares).
 *
 * For a general audience: the bot module guesses one tree from a bot's
 * talents and plays that tree's list only, so a druid with two thirds of
 * its points in Restoration and a third in Balance never casts Wrath. The
 * owner, 2026-10-29: "they should cast about 2/3rds of their spells as
 * resto spells, and 1/3rd as balance spells." So every tree with points
 * speaks, each tree's answers count by its share, and a running count of
 * the fight's casts leans toward whichever tree is behind its share. When
 * two trees answer the same concern, the role's tree goes first ("role tree
 * should win"), and the druid's own case is told here as the owner told it.
 *
 * What it gives the talent draw (buddies_talent_draw.h): a weight for each
 * answer, multiplied into the talent weight before the draw's Factor. The
 * draw holds its nudge, so a weight never leaps an answer over another
 * concern; RoleFirst only ever lowers, and only within one concern.
 */

#ifndef MOD_BUDDIES_TREE_SHARES_H
#define MOD_BUDDIES_TREE_SHARES_H

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <vector>

namespace BuddyShares
{
    // {{{ the numbers
    // GAIN:      how hard the running count leans: the lean is
    //            e^(GAIN * casts behind), so one cast behind leans 1.5 to 1,
    //            three behind about 3.3 to 1
    // LEAN_LOW, LEAN_HIGH: the lean is held between these, so a long stretch
    //            where one tree had nothing to offer (no one hurt) doesn't
    //            make its first answer afterwards all but certain
    // ROLE_GAP:  how far below the role tree's lowest answer another tree's
    //            answers to the same concern are put, in relevance (the
    //            module's answers stand 0.1 apart; concerns several points)
    static constexpr double GAIN      = 0.4;
    static constexpr double LEAN_LOW  = 0.2;
    static constexpr double LEAN_HIGH = 5.0;
    static constexpr double ROLE_GAP  = 0.01;
    // }}}

    // {{{ Shares
    // Each tree's share of the points spent (the game's tab order 0, 1, 2).
    // The talent shapes (617g) are thirds; any split works. No points spent
    // (a low level): the role's tree, whole, so a level-5 healer is a healer.
    struct Shares { double of[3] = { 0, 0, 0 }; };

    inline Shares FromPoints(int const points[3], int roleTree)
    {
        Shares s;
        int total = 0;
        for (int t = 0; t < 3; ++t) total += std::max(points[t], 0);
        if (total == 0)
        {
            if (roleTree >= 0 && roleTree < 3) s.of[roleTree] = 1.0;
            return s;
        }
        for (int t = 0; t < 3; ++t) s.of[t] = double(std::max(points[t], 0)) / double(total);
        return s;
    }

    // whether a tree speaks at all: it has points (or is the role's, before any)
    inline bool Speaks(Shares const& s, int tree) { return tree >= 0 && tree < 3 && s.of[tree] > 0; }
    // }}}

    // {{{ Count
    // The casts of this fight, per tree; started afresh with each fight.
    // Only casts the buddy chose from more than one tree's answers are
    // counted (Offered), so a stretch where one tree alone could answer
    // (nobody hurt: no Restoration answer offered) is not owed back later
    // with a run of heals no one needs.
    struct Count
    {
        double casts[3] = { 0, 0, 0 };
        void Cast(int tree) { if (tree >= 0 && tree < 3) casts[tree] += 1.0; }
        double Total() const { return casts[0] + casts[1] + casts[2]; }
        void Reset() { casts[0] = casts[1] = casts[2] = 0; }
    };

    // How many casts a tree is behind its share (negative: ahead).
    inline double Behind(Count const& c, Shares const& s, int tree)
    {
        if (tree < 0 || tree >= 3) return 0;
        return s.of[tree] * c.Total() - c.casts[tree];
    }

    // The running count's lean for an answer of this tree, held to
    // LEAN_LOW..LEAN_HIGH; 1 when the tree is on its share.
    inline double Lean(Count const& c, Shares const& s, int tree)
    {
        double lean = std::exp(GAIN * Behind(c, s, tree));
        return std::min(std::max(lean, LEAN_LOW), LEAN_HIGH);
    }
    // }}}

    // {{{ Weight
    // An answer's weight from the trees: its tree's share (a Balance answer
    // counts a third of what it does for a full-Balance druid) times the
    // running count's lean. A tree with no points gives 0: its answers are
    // not offered at all.
    inline double Weight(Shares const& s, Count const& c, int tree)
    {
        if (!Speaks(s, tree)) return 0;
        return s.of[tree] * Lean(c, s, tree);
    }

    // Whether this moment's answers come from more than one tree, so the
    // cast chosen counts toward the shares (Count above).
    struct Offered { int tree; double relevance; };
    inline bool FromSeveralTrees(std::vector<Offered> const& answers)
    {
        for (Offered const& a : answers)
            if (a.tree != answers.front().tree) return true;
        return false;
    }
    // }}}

    // {{{ RoleFirst
    // One concern's answers, tagged by tree: when the role's tree answers
    // it, every other tree's answers are put just below the role tree's
    // lowest (the owner, 2026-10-29: "role tree should win"), keeping their
    // own order and spacing (all moved down by one amount, so the highest
    // lands ROLE_GAP below the role tree's lowest). The factor for each
    // answer, in the same order: 1 for the role's own and when the others
    // are already below; never above 1, so nothing is lifted, and none
    // drops further below the role tree's lowest than the others' own
    // spread, so they stay within the concern's band.
    inline std::vector<double> RoleFirst(std::vector<Offered> const& answers, int roleTree)
    {
        std::vector<double> factor(answers.size(), 1.0);
        double lowestRole = -1, highestOther = -1;
        for (Offered const& a : answers)
            if (a.tree == roleTree) lowestRole = lowestRole < 0 ? a.relevance : std::min(lowestRole, a.relevance);
            else highestOther = std::max(highestOther, a.relevance);
        if (lowestRole < 0 || highestOther < lowestRole - ROLE_GAP) return factor;   // nothing to reorder
        double down = highestOther - (lowestRole - ROLE_GAP);
        for (size_t i = 0; i < answers.size(); ++i)
            if (answers[i].tree != roleTree && answers[i].relevance > down)
                factor[i] = (answers[i].relevance - down) / answers[i].relevance;
        return factor;
    }
    // }}}

    // {{{ AllyLow: the feral druid's answer to an ally at low health
    // The owner, 2026-10-29, word for word: "role tree should win, if we're
    // 2/3rds feral and 1/3rd resto, we should address the "ally at low
    // health" concern in a specific way, favoring our feral instincts
    // first. If we have cat talents, we should try and pounce on their
    // attackers. If we have bear talents, we try and pull them off. If they
    // are too powerful to defeat easily, and our ally can hold on but needs
    // healing and we're not under attack, then we can heal them, otherwise
    // if we're a tank and they are not, then we should bear form and pull
    // them off, otherwise if we're a tank and they are, then we can
    // catform."
    //   secondsToBeat   how long the druid needs to beat what is hitting the
    //                   ally (its damage a second against their health)
    //   allySeconds     how long the ally lasts at the damage it is taking
    //   HOLD_SECONDS    "can hold on": long enough for a heal to land after
    //                   leaving the form (a global cooldown out, a cast)
    enum class Answer { Strike, PullOff, Heal };
    static constexpr double HOLD_SECONDS = 4.0;

    struct Feral
    {
        int    catPoints = 0, bearPoints = 0;   // points in the feral talents of each side
        bool   tank = false;                    // the druid's role (its plan's, not its form)
        bool   allyTank = false;
        bool   canHeal = true;                  // knows a heal and has the mana for it
        bool   underAttack = false;             // something is hitting the druid
        double secondsToBeat = 0, allySeconds = 0;
    };

    inline bool TooStrong(Feral const& f) { return f.secondsToBeat > f.allySeconds; }
    inline bool HoldsOn(Feral const& f) { return f.allySeconds >= HOLD_SECONDS; }

    inline Answer AllyLow(Feral const& f)
    {
        if (f.canHeal && TooStrong(f) && HoldsOn(f) && !f.underAttack)
            return Answer::Heal;                                    // they can't be beaten in time; the ally can wait for a heal
        if (f.tank)
            return f.allyTank ? Answer::Strike : Answer::PullOff;   // bear to pull them off a soft ally; cat beside a tank
        return f.bearPoints > f.catPoints ? Answer::PullOff : Answer::Strike;
    }
    // }}}
}

#endif
