/*
 * buddy_follow_core.h - how buddies follow their owner: along the owner's
 * own track, side by side on a half circle behind, and at rest until the
 * owner walks off (issue 617e13; docs/pathfinding-questing-and-dungeons.md,
 * "Following"). No server code, so scripts/test-buddy-follow-core checks it
 * alone with the system compiler, and the server's follow action
 * (buddies_follow.cpp) only feeds it positions and carries out its answers.
 *
 * For a general audience, the owner's design (2026-10-27): "when following
 * our trail, we should always have them walk to within 1 yard of the trail
 * and then follow it in parallel. If there are other buddy-bots in range,
 * [...] they'll move to the opposite side (same distance from the line)
 * [...] if there's 3 then one will walk directly on your line, if there are
 * 4 then they will position themselves halfway between the line and 1 yard
 * away - we're essentially creating a semi-circle 1-2 yards behind the
 * player, "behind" meaning the direction the player came from. For
 * following, they'll only continue following the player when they move
 * farther than 10 yards away. Otherwise they have a 10% chance to
 * mingle-wander, otherwise they just stand and turn toward you like
 * Sargobras."
 *
 * The pieces:
 *   the trail   - the owner's positions, one every TRAIL_STEP yards, the
 *                 newest last: the way the owner came, which the owner's
 *                 feet proved walkable;
 *   the offsets - how far each follower walks to the side of the trail,
 *                 by how many follow (the owner's table for 1 to 4);
 *   the places  - each offset turned into a spot: the point of the trail
 *                 1 to 2 yards back from the owner (back along the trail,
 *                 so round a corner the places bend with it), then that
 *                 far to the side, square to the trail there;
 *   who goes where - the least walking in all, so followers don't cross;
 *   rest or follow - the 10-yard rule, and at rest the mingling chance.
 */

#ifndef BUDDY_FOLLOW_CORE_H
#define BUDDY_FOLLOW_CORE_H

#include "buddy_roam_core.h"
#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdint>
#include <deque>
#include <string>
#include <vector>

namespace BuddyFollow
{
using BuddyRoam::Point;

// {{{ Settings
// The owner's numbers (2026-10-27), and the two of ours marked so.
// Tuning goes to docs/balance-updates.md.
struct Settings
{
    float    trailStep    = 2.0f;    // yards between the trail's points (ours)
    uint32_t trailKeep    = 150;     // points kept: 300 yards of track (ours)
    float    side         = 1.0f;    // yards to the side at the most ("within 1 yard of the trail")
    float    nearBack     = 1.0f;    // yards behind for the outermost places ("1-2 yards behind")
    float    farBack      = 2.0f;    // yards behind for a place on the trail itself
    float    restYards    = 10.0f;   // following starts again only past this ("farther than 10 yards away")
    float    arriveYards  = 1.0f;    // at its place: following ends, rest begins (ours: the trail's own width)
    double   mingleChance = 0.10;    // at rest, the chance each look to mingle ("a 10% chance")
    uint32_t mingleEvery  = 5000;    // ms between those looks (proposed, not yet the owner's: 635's open question)
    float    mingleYards  = 3.0f;    // how far a mingle wanders from its place (ours)
    // single file (idea 4 of the pathfinding report: "on a narrow path (a
    // bridge, a ramp, a tunnel ...), buddies walk in a column behind the
    // owner, a few yards apart, and fan out again on open ground")
    float    narrowYards  = 1.5f;    // a passage narrower than this from its middle to a wall: single file (ours: the
                                     // formation's own half-width, `side`, and half a body)
    float    columnSpacing = 2.5f;   // yards between followers in single file ("a few yards apart"; ours)
};
// }}}

// {{{ Trail
// The owner's track. Add() is given the owner's position often (each
// update); a point is kept only TRAIL_STEP yards from the last, so standing
// still adds nothing and the trail is even. A jump (a teleport, a summon:
// more than `jump` yards in one update) starts a new trail, since the way
// between was never walked.
struct Trail
{
    std::deque<Point> points;        // oldest first, the owner's newest kept position last

    void Add(Point const& at, Settings const& s, float jump = 40.0f)
    {
        if (!points.empty())
        {
            Point const& last = points.back();
            float d = std::hypot(at.x - last.x, at.y - last.y);
            if (d > jump)
                points.clear();
            else if (d < s.trailStep)
                return;
        }
        points.push_back(at);
        while (points.size() > s.trailKeep)
            points.pop_front();
    }
};
// }}}

// {{{ Offsets
// The sideways offsets, in units of Settings::side, for n followers:
// negative is the right of the trail and positive its left, seen walking
// along it the way the owner went. The owner's table:
//   1: -1        2: -1, +1        3: -1, 0, +1        4: -1, -0.5, +0.5, +1
// Five fills the gap the table leaves in four: -1, -0.5, 0, +0.5, +1. Past
// five (a full clan is seven) the owner has not said; ours: evenly from -1
// to +1, which keeps the table's ends and its middle. Asked in 617e13.
inline std::vector<float> Offsets(int n)
{
    switch (n)
    {
        case 0:  return {};
        case 1:  return { -1.0f };
        case 2:  return { -1.0f, 1.0f };
        case 3:  return { -1.0f, 0.0f, 1.0f };
        case 4:  return { -1.0f, -0.5f, 0.5f, 1.0f };
        case 5:  return { -1.0f, -0.5f, 0.0f, 0.5f, 1.0f };
        default: break;
    }
    std::vector<float> out;
    for (int k = 0; k < n; ++k)
        out.push_back(-1.0f + 2.0f * float(k) / float(n - 1));
    return out;
}
// }}}

// {{{ Place
// A follower's spot and the way it faces.
struct Place
{
    Point at;
    float facing = 0.0f;             // radians, toward the owner
};
// }}}

// {{{ PlaceFor
// The spot for sideways offset `lateral` (units of side). How far back:
// on the half circle, so the trail's middle is farthest back (farBack) and
// the outermost places nearest (nearBack): back = nearBack + (farBack -
// nearBack) * (1 - |lateral|). Back is measured along the trail from the
// owner, through its points newest to oldest, so on a bend the place lies
// on the bend. Sideways is square to the trail at that point. With no trail
// yet (the owner just arrived), behind is opposite the owner's facing.
inline Place PlaceFor(Trail const& trail, Point const& owner, float ownerFacing, float lateral, Settings const& s)
{
    float back = s.nearBack + (s.farBack - s.nearBack) * (1.0f - std::fabs(lateral));
    // walk back along owner -> newest -> ... -> oldest
    Point from = owner, at = owner;
    float dirX = -std::cos(ownerFacing), dirY = -std::sin(ownerFacing);   // the way back
    float left = back;
    bool found = false;
    for (auto it = trail.points.rbegin(); it != trail.points.rend(); ++it)
    {
        float dx = it->x - from.x, dy = it->y - from.y;
        float d = std::hypot(dx, dy);
        if (d < 1e-4f)
            continue;
        if (d >= left)
        {
            at   = { from.x + dx / d * left, from.y + dy / d * left, from.z + (it->z - from.z) * (left / d) };
            dirX = dx / d;
            dirY = dy / d;
            found = true;
            break;
        }
        left -= d;
        from  = *it;
        dirX  = dx / d;
        dirY  = dy / d;
    }
    if (!found)                       // the trail is shorter than `back`: on along its last direction
        at = { from.x + dirX * left, from.y + dirY * left, from.z };
    // the way forward is -dir; its left is (dirY, -dirX) turned: forward (fx, fy) -> left (-fy, fx)
    float fx = -dirX, fy = -dirY;
    float side = lateral * s.side;
    Place p;
    p.at     = { at.x - fy * side, at.y + fx * side, at.z };
    p.facing = std::atan2(owner.y - p.at.y, owner.x - p.at.x);
    return p;
}
// }}}

// {{{ Places
// Every follower's spot, in the order of Offsets (right to left).
inline std::vector<Place> Places(Trail const& trail, Point const& owner, float ownerFacing, int n, Settings const& s)
{
    std::vector<Place> out;
    for (float lateral : Offsets(n))
        out.push_back(PlaceFor(trail, owner, ownerFacing, lateral, s));
    return out;
}
// }}}

// {{{ ColumnPlaces
// Single file: every follower on the track itself, the first farBack
// behind the owner and each next columnSpacing behind that, measured along
// the track (so the column bends with it).
inline std::vector<Place> ColumnPlaces(Trail const& trail, Point const& owner, float ownerFacing, int n, Settings const& s)
{
    std::vector<Place> out;
    for (int k = 0; k < n; ++k)
    {
        Settings at = s;
        at.farBack = s.farBack + float(k) * s.columnSpacing;     // lateral 0 stands farBack behind
        out.push_back(PlaceFor(trail, owner, ownerFacing, 0.0f, at));
    }
    return out;
}
// }}}

// {{{ Assign
// Who takes which spot: the arrangement that walks the least in all. In a
// plane such an arrangement never has two paths crossing (were two to
// cross, swapping their ends would be shorter), so neighbours keep their
// sides and nobody walks across another. Not the closest pair first: the
// test caught that rule sending the follower north of the trail to the
// middle place and the middle one to the north place, their paths crossed
// (the travel arc's ArrivalPlace in buddies_town.cpp uses it still). Found
// by trying every arrangement, cutting off any already longer than the
// best: a clan is at most seven, 5040 arrangements at the most. Returns,
// per follower, its spot's index (-1 when there are more followers than
// spots).
inline void AssignSearch(std::vector<Point> const& followers, std::vector<Place> const& places, size_t f,
                         std::vector<int>& now, std::vector<bool>& taken, float sum, float& best, std::vector<int>& bestOf)
{
    if (sum >= best)
        return;
    if (f == followers.size())
    {
        best   = sum;
        bestOf = now;
        return;
    }
    bool any = false;
    for (size_t p = 0; p < places.size(); ++p)
    {
        if (taken[p])
            continue;
        any = true;
        taken[p] = true;
        now[f]   = int(p);
        AssignSearch(followers, places, f + 1, now, taken, sum + std::hypot(followers[f].x - places[p].at.x, followers[f].y - places[p].at.y),
                     best, bestOf);
        taken[p] = false;
    }
    if (!any)                         // more followers than spots: this one has none
    {
        now[f] = -1;
        AssignSearch(followers, places, f + 1, now, taken, sum, best, bestOf);
    }
}

inline std::vector<int> Assign(std::vector<Point> const& followers, std::vector<Place> const& places)
{
    std::vector<int>  now(followers.size(), -1), bestOf(followers.size(), -1);
    std::vector<bool> taken(places.size(), false);
    float best = 1e30f;
    AssignSearch(followers, places, 0, now, taken, 0.0f, best, bestOf);
    return bestOf;
}
// }}}

// {{{ the rest-or-follow rule
// A follower's state, kept by the server per buddy.
enum class Mode : uint8_t { Rest, Follow };
struct State
{
    Mode     mode       = Mode::Follow;   // a new follower goes to its place first
    uint64_t nextLookMs = 0;              // when, at rest, it next rolls the mingling chance
};

// What the follower does now:
//   Walk    - to its place (following);
//   Mingle  - a short wander to `to`, near its place (at rest);
//   Face    - stand, and turn toward the owner (at rest);
//   Nothing - at rest, nothing new this moment (keep doing what it does).
enum class Act : uint8_t { Walk, Mingle, Face, Nothing };
struct Decision
{
    Act   act = Act::Nothing;
    Point to;                          // Walk, Mingle: where
    float facing = 0.0f;               // Face: which way
};

// The rule, each path:
//   following, and not yet within arriveYards of its place - walk there;
//   following, and arrived                                  - rest, and face the owner;
//   at rest, the owner more than restYards away             - follow again (walk to its place);
//   at rest, the owner near, a look due                     - roll: mingle (mingleChance) or face the owner;
//   at rest, the owner near, no look due                    - nothing new.
// `roll` and `angle` are the caller's random numbers: roll in [0, 1) for the
// chance, angle in [0, 1) for which way a mingle goes.
inline Decision Decide(State& st, Point const& me, Point const& owner, Place const& place, uint64_t nowMs,
                       double roll, double angle, Settings const& s)
{
    Decision d;
    float toOwner = std::hypot(owner.x - me.x, owner.y - me.y);
    float toPlace = std::hypot(place.at.x - me.x, place.at.y - me.y);
    if (st.mode == Mode::Rest && toOwner > s.restYards)
        st.mode = Mode::Follow;
    if (st.mode == Mode::Follow)
    {
        if (toPlace > s.arriveYards)
        {
            d.act = Act::Walk;
            d.to  = place.at;
            return d;
        }
        st.mode       = Mode::Rest;
        st.nextLookMs = nowMs + s.mingleEvery;
        d.act    = Act::Face;
        d.facing = std::atan2(owner.y - me.y, owner.x - me.x);
        return d;
    }
    if (nowMs < st.nextLookMs)
        return d;
    st.nextLookMs = nowMs + s.mingleEvery;
    if (roll < s.mingleChance)
    {
        float a = float(angle) * 6.2831853f;
        d.act = Act::Mingle;
        d.to  = { place.at.x + std::cos(a) * s.mingleYards, place.at.y + std::sin(a) * s.mingleYards, place.at.z };
        return d;
    }
    d.act    = Act::Face;
    d.facing = std::atan2(owner.y - me.y, owner.x - me.x);
    return d;
}
// }}}

// {{{ ReadOrder
// The words of a spoken follow order (617y, the owner 2026-10-23: "we have
// to say "follow me" not just follow. We should be able to say "follow
// so-and-so" ... "go away" ... and if they say "go away!" then they won't
// follow that person until they log out again"; 617e13: "shoo"). Any case;
// punctuation and a "please" are dropped. Each answer:
//   "follow me"         - Follow, name empty
//   "follow <name>"     - Follow, name the lower-cased name
//   "go away", "shoo"   - GoAway; hard when "go away" ends in "!"
//   anything else       - None (a bare "follow" among them)
enum class Order : uint8_t { None, Follow, GoAway };
inline Order ReadOrder(std::string const& raw, std::string& name, bool& hard)
{
    std::string msg = raw;
    while (!msg.empty() && std::isspace(static_cast<unsigned char>(msg.back())))
        msg.pop_back();
    bool bang = !msg.empty() && msg.back() == '!';
    std::transform(msg.begin(), msg.end(), msg.begin(), [](unsigned char c) { return std::isalpha(c) ? char(std::tolower(c)) : ' '; });
    std::vector<std::string> words;
    std::string w;
    for (char c : msg + " ")
    {
        if (c != ' ')
            w += c;
        else if (!w.empty())
        {
            words.push_back(w);
            w.clear();
        }
    }
    words.erase(std::remove(words.begin(), words.end(), "please"), words.end());
    name.clear();
    hard = false;
    if (words.size() == 2 && words[0] == "follow")
    {
        name = words[1] == "me" ? "" : words[1];
        return Order::Follow;
    }
    if (words.size() == 2 && words[0] == "go" && words[1] == "away")
    {
        hard = bang;
        return Order::GoAway;
    }
    if (words.size() == 1 && words[0] == "shoo")
        return Order::GoAway;
    return Order::None;
}
// }}}
}

#endif
