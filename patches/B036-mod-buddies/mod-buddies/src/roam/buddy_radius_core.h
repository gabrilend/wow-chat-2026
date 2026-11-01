/*
 * buddy_radius_core.h - radius triggers and the bulletin board (issue 165):
 * "when something comes within N yards of this object, run these actions",
 * and its first user, a buddy's board of everything within 70 yards. Plain
 * C++ with no server, so scripts/test-buddy-radius checks it alone; the
 * server's part (calling Moved from the place the server already tells
 * creatures that a unit moved, and naming real actions) feeds it ids and
 * places and runs what it returns.
 *
 * For a general audience, the owner (2026-10-03): "We register a particular
 * game-object as having a radius. This radius is the kind of radius that
 * triggers when another gameobject enters it's field. It runs these
 * functions, A, B, and C, with these arguments, 1, 2, and 3, every time an
 * object enters the radius." And 2026-10-30: "buddies should be aware of
 * everything within 70 yards of them. They should all be on the concern
 * list. So, radius triggers only to put things up on the mental bulletin
 * board, or remove them if they're far enough away. Though certain bosses
 * might have more important issues and flag carriers in PvP should be
 * entirely line-of-sight based".
 *
 * The pieces:
 *   a trigger    - a name, a radius, slack yards past it before "leaves"
 *                  fires (against flicker on the edge), a filter of what
 *                  counts, and the actions run, by name with arguments, on
 *                  entering and on leaving;
 *   the registry - each object's triggers and who is inside each; Moved
 *                  (one unit moved, near one object) gives back the actions
 *                  to run; a trigger or every trigger of an object can go;
 *   the board    - what a buddy is concerned with: pinned when it enters,
 *                  unpinned when it leaves; a boss pinned as sticky stays
 *                  whatever its distance until the fight ends; a flag
 *                  carrier is always on the board, its place the last seen.
 */

#ifndef BUDDY_RADIUS_CORE_H
#define BUDDY_RADIUS_CORE_H

#include <cmath>
#include <cstdint>
#include <map>
#include <set>
#include <string>
#include <vector>

namespace BuddyRadius
{

// {{{ what moved
// Kind bits of a unit, for filters.
enum : uint32_t { UNIT_PLAYER = 1, UNIT_BUDDY = 2, UNIT_CREATURE = 4 };

struct Unit
{
    uint64_t id    = 0;
    uint32_t kinds = 0;       // UNIT_* bits
    uint32_t entry = 0;       // a creature's entry (0 for players)
    float    x = 0, y = 0, z = 0;
};
// }}}

// {{{ Filter
// What counts: units with any of `kinds` (0: any unit), and, when `entry`
// is set, only creatures of that entry.
struct Filter
{
    uint32_t kinds = 0;
    uint32_t entry = 0;

    bool Passes(Unit const& u) const
    {
        if (kinds && !(u.kinds & kinds))
            return false;
        if (entry && u.entry != entry)
            return false;
        return true;
    }
};
// }}}

// {{{ Trigger
struct Action { std::string name; std::vector<std::string> args; };

struct Trigger
{
    std::string         name;
    float               radius = 0.0f;
    float               slack  = 0.0f;   // "leaves" fires past radius + slack
    Filter              filter;
    std::vector<Action> onEnter, onLeave;
};

// One action to run: which trigger's owner, which unit, the action.
struct Call { uint64_t owner; uint64_t unit; Action action; };
// }}}

// {{{ Registry
class Registry
{
public:
    void Add(uint64_t owner, Trigger const& t)
    {
        auto& list = _triggers[owner];
        for (auto& existing : list)
            if (existing.name == t.name)
            {
                existing = t;                  // the same name again replaces it
                return;
            }
        list.push_back(t);
    }

    void Remove(uint64_t owner)                // the object left the world
    {
        _triggers.erase(owner);
        for (auto it = _inside.begin(); it != _inside.end();)
            it = it->first.first == owner ? _inside.erase(it) : std::next(it);
    }

    void Remove(uint64_t owner, std::string const& name)
    {
        auto it = _triggers.find(owner);
        if (it == _triggers.end())
            return;
        auto& list = it->second;
        for (size_t i = 0; i < list.size(); ++i)
            if (list[i].name == name)
            {
                list.erase(list.begin() + long(i));
                break;
            }
        _inside.erase({ owner, name });
    }

    bool Has(uint64_t owner) const { return _triggers.count(owner) != 0; }

    // `unit` moved, and is now near `owner` at (ox, oy, oz). The actions to
    // run, in the triggers' order then each list's. Each path, per trigger:
    //   the unit is the owner itself, or fails the filter - nothing
    //   within the radius, not inside before              - enters: onEnter
    //   beyond radius + slack, inside before              - leaves: onLeave
    //   otherwise (inside and still in, outside and still
    //   out, or in the slack band)                         - nothing
    std::vector<Call> Moved(uint64_t owner, float ox, float oy, float oz, Unit const& unit)
    {
        std::vector<Call> calls;
        auto it = _triggers.find(owner);
        if (it == _triggers.end() || unit.id == owner)
            return calls;
        float d = std::sqrt((unit.x - ox) * (unit.x - ox) + (unit.y - oy) * (unit.y - oy) + (unit.z - oz) * (unit.z - oz));
        for (Trigger const& t : it->second)
        {
            if (!t.filter.Passes(unit))
                continue;
            std::set<uint64_t>& in = _inside[{ owner, t.name }];
            bool was = in.count(unit.id) != 0;
            if (!was && d <= t.radius)
            {
                in.insert(unit.id);
                for (Action const& a : t.onEnter)
                    calls.push_back({ owner, unit.id, a });
            }
            else if (was && d > t.radius + t.slack)
            {
                in.erase(unit.id);
                for (Action const& a : t.onLeave)
                    calls.push_back({ owner, unit.id, a });
            }
        }
        return calls;
    }

    // a unit gone from the world: out of every inside-set, no actions
    void Forget(uint64_t unit)
    {
        for (auto& [key, in] : _inside)
            in.erase(unit);
    }

    size_t Inside(uint64_t owner, std::string const& name) const
    {
        auto it = _inside.find({ owner, name });
        return it == _inside.end() ? 0 : it->second.size();
    }

private:
    std::map<uint64_t, std::vector<Trigger>> _triggers;
    std::map<std::pair<uint64_t, std::string>, std::set<uint64_t>> _inside;
};
// }}}

// {{{ the bulletin board
// What a buddy is concerned with. A pin: the unit, its kind bits, where it
// was last seen and when, and whether it is sticky (a boss for the length
// of its fight) or always kept (a flag carrier).
struct Pin
{
    uint64_t id = 0;
    uint32_t kinds = 0;
    float    x = 0, y = 0, z = 0;
    uint64_t seenMs = 0;
    bool     sticky = false;           // a boss in a fight: kept whatever the distance
    bool     always = false;           // a flag carrier: kept, its place the last seen
};

class Board
{
public:
    // the board trigger's two actions: "pin" and "unpin" (a sticky or
    // always-kept pin is not taken down by leaving the radius)
    void PinUnit(Unit const& u, uint64_t nowMs)
    {
        Pin& p = _pins[u.id];
        p.id = u.id;
        p.kinds = u.kinds;
        p.x = u.x; p.y = u.y; p.z = u.z;
        p.seenMs = nowMs;
    }
    void Unpin(uint64_t id)
    {
        auto it = _pins.find(id);
        if (it != _pins.end() && !it->second.sticky && !it->second.always)
            _pins.erase(it);
    }

    // a boss's fight began or ended
    void BossFight(uint64_t id, bool fighting)
    {
        auto it = _pins.find(id);
        if (it != _pins.end())
            it->second.sticky = fighting;
    }

    // a flag carrier: always on the board; seen, its place updated; not
    // seen, the last seen place kept
    void FlagCarrier(uint64_t id, bool seen, float x, float y, float z, uint64_t nowMs)
    {
        Pin& p = _pins[id];
        p.id = id;
        p.always = true;
        if (seen)
        {
            p.x = x; p.y = y; p.z = z;
            p.seenMs = nowMs;
        }
    }
    void FlagDropped(uint64_t id)
    {
        auto it = _pins.find(id);
        if (it != _pins.end())
            it->second.always = false;
    }

    std::vector<uint64_t> Ids() const
    {
        std::vector<uint64_t> out;
        for (auto const& [id, pin] : _pins)
            out.push_back(id);
        return out;
    }
    bool Has(uint64_t id) const { return _pins.count(id) != 0; }
    Pin const* Get(uint64_t id) const { auto it = _pins.find(id); return it == _pins.end() ? nullptr : &it->second; }
    size_t Size() const { return _pins.size(); }

private:
    std::map<uint64_t, Pin> _pins;
};

// The board's trigger as the buddy carries it: 70 yards, 5 of slack, any
// unit, "pin" on entering and "unpin" on leaving.
inline Trigger BoardTrigger(float radius = 70.0f, float slack = 5.0f)
{
    Trigger t;
    t.name    = "bulletin board";
    t.radius  = radius;
    t.slack   = slack;
    t.onEnter = { { "pin", {} } };
    t.onLeave = { { "unpin", {} } };
    return t;
}
// }}}

} // namespace BuddyRadius

#endif
