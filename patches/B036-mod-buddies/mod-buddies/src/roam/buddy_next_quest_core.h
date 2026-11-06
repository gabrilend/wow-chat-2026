/*
 * buddy_next_quest_core.h - the next best quest for an owner, and the arc
 * of buddies leaning toward it (issue 617e18, step 1 and the arc's part of
 * step 3). Plain arithmetic over plain tables, no server; checked by
 * scripts/test-buddy-next-quest.
 *
 * For a general audience, the owner (2026-10-29): "the buddy-bots should
 * stand on their arc in the direction of the next best quest to work on.
 * They can also direct you to places you haven't been yet, if it's time to
 * move on. So, you know you can always follow your buddies to find
 * treasure and renown." The questing addons (Questie, QuestHelper) each
 * carry their own database of quest givers and objectives; the server has
 * the same facts in its world database, so the buddies need no addon.
 *
 * The choice, each path:
 *   quests in the owner's log come first: each one's target is its nearest
 *     objective not yet done, or, with every objective done, whoever takes
 *     it in (its ender);
 *   then quests the owner can take: not done, not in the log, the quest
 *     before it done, the owner's level at least its minimum; its target
 *     is its giver;
 *   a quest too low for the owner (its level `grayBelow` or more under
 *     theirs) is passed over, in the log or not;
 *   within each, the lowest cost wins: the walk to the target in yards,
 *     plus `yardsPerLevel` for each level the quest is off the owner's,
 *     less `togetherYards` for each other objective or giver within
 *     `togetherRadius` of the target (a route through several, as
 *     QuestHelper planned), less `chainYards` for a quest whose chain is
 *     already started;
 *   nothing left: the nearest place the owner hasn't explored ("time to
 *     move on");
 *   nothing there either: no hint.
 * The buddies then stand on their arc on the owner's side that faces the
 * target (LeanPlaces), and with the owner standing still one steps a few
 * yards that way and waits (Beckon); a hint, not a leash. Behind a switch, off until
 * turned on (the server's part).
 */

#ifndef BUDDY_NEXT_QUEST_CORE_H
#define BUDDY_NEXT_QUEST_CORE_H

#include "buddy_follow_core.h"
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <set>
#include <string>
#include <vector>

namespace BuddyNextQuest
{
using BuddyRoam::Point;

// {{{ Settings
// The agent's numbers (2026-11-06), for the owner to curate; tuning goes
// to docs/balance-updates.md.
struct Settings
{
    int   grayBelow      = 6;      // levels under the owner's at which a quest is too low (the game's gray, about)
    float yardsPerLevel  = 60.0f;  // a level off the owner's costs as much as this much walking
    float togetherRadius = 60.0f;  // other objectives and givers this near the target lie together
    float togetherYards  = 40.0f;  // and each is worth this much less walking
    float chainYards     = 100.0f; // a quest whose chain is started is worth this much less walking
    float beckonYards    = 5.0f;   // the owner standing still: one buddy steps this far toward the target ("a few yards")
};
// }}}

// {{{ Quest
// One quest as the world database says: its id, name, level and the level
// it may be taken at, the quest before it (0: none), where its giver
// stands and where its ender (who takes it in) stands, and where its
// objectives are (each creature's or object's spawn points, all of the
// objectives together). Positions on one map.
struct Quest
{
    uint32_t           id       = 0;
    std::string        name;
    int                level    = 1;
    int                minLevel = 1;
    uint32_t           prev     = 0;
    Point              giver;
    Point              ender;
    std::vector<Point> objectives;
};
// }}}

// {{{ Owner
// The owner as the characters database says: level, where they stand, the
// quests they have done, and for each quest in their log the objective
// spots still to do (none: every objective done, it waits to be handed in).
struct LogEntry { uint32_t id = 0; std::vector<Point> left; };
struct Owner
{
    int                   level = 1;
    Point                 at;
    std::set<uint32_t>    done;
    std::vector<LogEntry> log;
};
// }}}

// {{{ Place
// A place the owner may or may not have explored (the explored areas the
// server keeps per character), by where it lies.
struct Place { std::string name; Point at; bool explored = false; };
// }}}

// {{{ Hint
//   kind    what the buddies point to: a quest in the log, one in the log
//           to hand in, one to take, an unexplored place, or nothing
//   quest   the quest's id (Log, HandIn, Take)
//   place   the place's index (Explore)
//   target  where they point
//   cost    the winning cost (yards, after the bonuses)
//   bearing radians from the owner to the target
enum class Kind : uint8_t { None, Log, HandIn, Take, Explore };
struct Hint
{
    Kind     kind    = Kind::None;
    uint32_t quest   = 0;
    int      place   = -1;
    Point    target;
    float    cost    = 0.0f;
    float    bearing = 0.0f;
};
// }}}

inline float Yards(Point const& a, Point const& b) { return std::hypot(a.x - b.x, a.y - b.y); }

// {{{ Together
// How many objectives and givers, other than the target itself, lie within
// togetherRadius of it: every quest the owner has or can take counts.
inline int Together(Point const& target, std::vector<Point> const& spots, Settings const& s)
{
    int n = 0;
    for (Point const& p : spots)
    {
        float d = Yards(p, target);
        if (d > 1e-3f && d <= s.togetherRadius)
            ++n;
    }
    return n;
}
// }}}

// {{{ Choose
inline Hint Choose(Owner const& o, std::vector<Quest> const& quests, std::vector<Place> const& places, Settings const& s)
{
    auto find = [&](uint32_t id) -> Quest const* {
        for (Quest const& q : quests) if (q.id == id) return &q;
        return nullptr;
    };
    auto tooLow = [&](Quest const& q) { return q.level <= o.level - s.grayBelow; };
    auto inLog  = [&](uint32_t id) { for (LogEntry const& e : o.log) if (e.id == id) return true; return false; };
    auto canTake = [&](Quest const& q) {
        return !o.done.count(q.id) && !inLog(q.id) && (q.prev == 0 || o.done.count(q.prev)) && q.minLevel <= o.level;
    };

    // every spot that may lie together with a target
    std::vector<Point> spots;
    for (LogEntry const& e : o.log)
        if (Quest const* q = find(e.id); q && !tooLow(*q))
        {
            if (e.left.empty())
                spots.push_back(q->ender);
            spots.insert(spots.end(), e.left.begin(), e.left.end());
        }
    for (Quest const& q : quests)
        if (canTake(q) && !tooLow(q))
            spots.push_back(q.giver);

    auto cost = [&](Quest const& q, Point const& target) {
        return Yards(o.at, target) + s.yardsPerLevel * float(std::abs(q.level - o.level))
             - s.togetherYards * float(Together(target, spots, s)) - (q.prev != 0 ? s.chainYards : 0.0f);
    };

    Hint h;
    // the log first: each quest's nearest objective left, or its ender
    for (LogEntry const& e : o.log)
    {
        Quest const* q = find(e.id);
        if (!q || tooLow(*q))
            continue;
        Point const* near = &q->ender;
        for (Point const& p : e.left)
            if (near == &q->ender || Yards(o.at, p) < Yards(o.at, *near))
                near = &p;
        float c = cost(*q, *near);
        if (h.kind == Kind::None || c < h.cost)
        {
            h.kind = e.left.empty() ? Kind::HandIn : Kind::Log; h.quest = q->id; h.target = *near; h.cost = c;
        }
    }
    // then the quests to take
    if (h.kind == Kind::None)
        for (Quest const& q : quests)
        {
            if (!canTake(q) || tooLow(q))
                continue;
            float c = cost(q, q.giver);
            if (h.kind == Kind::None || c < h.cost)
            {
                h.kind = Kind::Take; h.quest = q.id; h.target = q.giver; h.cost = c;
            }
        }
    // time to move on: the nearest place not yet explored
    if (h.kind == Kind::None)
        for (size_t i = 0; i < places.size(); ++i)
        {
            if (places[i].explored)
                continue;
            float c = Yards(o.at, places[i].at);
            if (h.kind == Kind::None || c < h.cost)
            {
                h.kind = Kind::Explore; h.place = int(i); h.target = places[i].at; h.cost = c;
            }
        }
    if (h.kind != Kind::None)
        h.bearing = std::atan2(h.target.y - o.at.y, h.target.x - o.at.x);
    return h;
}
// }}}

// {{{ LeanPlaces
// The arc follow's places (617e13), on the owner's side that faces the
// hint: the same half circle the buddies stand on behind the owner, turned
// so its middle points along `bearing`. With no trail, the follow core puts
// "behind" opposite the facing it is given, so the facing given is the
// bearing turned half round.
inline std::vector<BuddyFollow::Place> LeanPlaces(Point const& owner, float bearing, int n, BuddyFollow::Settings const& s)
{
    BuddyFollow::Trail none;
    return BuddyFollow::Places(none, owner, bearing + 3.14159265f, n, s);
}
// }}}

// {{{ Beckon
// The owner standing still: the spot one buddy steps to, beckonYards from
// the owner toward the target (no farther than the target itself), at the
// owner's height: the server puts it on the ground.
inline Point Beckon(Point const& owner, Point const& target, Settings const& s)
{
    float d = Yards(owner, target);
    if (d < 1e-4f)
        return owner;
    float k = std::min(s.beckonYards, d) / d;
    return { owner.x + (target.x - owner.x) * k, owner.y + (target.y - owner.y) * k, owner.z };
}
// }}}

// {{{ Compass, Words
// The hint said in words, when a buddy is whispered "where next?" (the
// owner, 2026-10-30: the hint is never spoken unasked).
inline char const* Compass(float bearing)
{
    static char const* const names[] = { "east", "north-east", "north", "north-west", "west", "south-west", "south", "south-east" };
    float turns = bearing / 6.2831853f;
    int   k     = int(std::lround(turns * 8.0f)) % 8;
    if (k < 0) k += 8;
    return names[k];
}
inline std::string Words(Hint const& h, Owner const& o, std::vector<Quest> const& quests, std::vector<Place> const& places)
{
    std::string yards = std::to_string(int(std::lround(Yards(o.at, h.target))));
    switch (h.kind)
    {
        case Kind::Log:
        case Kind::HandIn:
        case Kind::Take:
            for (Quest const& q : quests)
                if (q.id == h.quest)
                    return std::string(h.kind == Kind::Log ? "For \"" : h.kind == Kind::HandIn ? "To hand in \""
                                                                          : "There's work: \"")
                         + q.name + "\", " + yards + " yards " + Compass(h.bearing) + ".";
            break;
        case Kind::Explore:
            return "Somewhere new: " + places[size_t(h.place)].name + ", " + yards + " yards " + Compass(h.bearing) + ".";
        case Kind::None:
            break;
    }
    return "Nowhere I know of.";
}
// }}}

} // namespace BuddyNextQuest

#endif // BUDDY_NEXT_QUEST_CORE_H
