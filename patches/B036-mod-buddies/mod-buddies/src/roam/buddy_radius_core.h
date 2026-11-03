
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

enum : uint32_t { UNIT_PLAYER = 1, UNIT_BUDDY = 2, UNIT_CREATURE = 4 };

struct Unit
{
    uint64_t id    = 0;
    uint32_t kinds = 0;
    uint32_t entry = 0;
    float    x = 0, y = 0, z = 0;
};

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

struct Action { std::string name; std::vector<std::string> args; };

struct Trigger
{
    std::string         name;
    float               radius = 0.0f;
    float               slack  = 0.0f;
    Filter              filter;
    std::vector<Action> onEnter, onLeave;
};

struct Call { uint64_t owner; uint64_t unit; Action action; };

class Registry
{
public:
    void Add(uint64_t owner, Trigger const& t)
    {
        auto& list = _triggers[owner];
        for (auto& existing : list)
            if (existing.name == t.name)
            {
                existing = t;
                return;
            }
        list.push_back(t);
    }

    void Remove(uint64_t owner)
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

struct Pin
{
    uint64_t id = 0;
    uint32_t kinds = 0;
    float    x = 0, y = 0, z = 0;
    uint64_t seenMs = 0;
    bool     sticky = false;
    bool     always = false;
};

class Board
{
public:
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

    void BossFight(uint64_t id, bool fighting)
    {
        auto it = _pins.find(id);
        if (it != _pins.end())
            it->second.sticky = fighting;
    }

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

}

#endif
