
#ifndef MOD_BUDDIES_FIGHT_STATE_H
#define MOD_BUDDIES_FIGHT_STATE_H

#include "buddies_cooldown_plan.h"
#include "buddies_fight_length.h"
#include "buddies_marks.h"
#include "buddies_threat.h"

#include <algorithm>
#include <cstdint>
#include <deque>
#include <string>
#include <unordered_map>
#include <vector>

namespace BuddyFightState
{
    struct Mark { uint32_t spell; double secondsLeft; uint32_t stacks; uint64_t by; std::vector<BuddyMarks::AuraEffect> effects; };

    struct Cooldown { uint32_t spell; std::string name; double readyIn; };

    struct Member
    {
        uint64_t id = 0, owner = 0;
        double health = 0, maxHealth = 0, resource = 0, maxResource = 0;
        uint8_t resourceKind = 0, role = 0, cls = 0;
        double armour = 0; int level = 1;
        uint8_t healPoints = 0, talentPoints = 0; double baseMana = 0;
        double x = 0, y = 0, z = 0;
        uint32_t casting = 0; double castLeft = 0;
        std::vector<Cooldown> cooldowns;
        std::vector<Mark> marks;
    };

    struct ThreatEntry { uint64_t who; BuddyThreat::Entry entry; };

    struct Enemy
    {
        uint64_t id = 0;
        double health = 0, maxHealth = 0;
        uint8_t rank = 0;
        int level = 1;
        uint32_t casting = 0; double castLeft = 0;
        double castDamage = 0; uint64_t castOn = 0;
        uint64_t attacking = 0;
        std::vector<Mark> marks;
        std::vector<ThreatEntry> threat;
    };

    struct Snapshot
    {
        double t = 0;
        std::vector<BuddyPlan::Window> windows;
        std::vector<Member> party;
        std::vector<Enemy> enemies;
    };

    inline BuddyPlan::Fight FightKind(Snapshot const& s)
    {
        for (Enemy const& e : s.enemies)
            if (e.rank == 3 || e.rank == 2) return BuddyPlan::Fight::Boss;
        return BuddyPlan::Fight::Trash;
    }

    inline BuddyMarks::Modifiers ModifiersOf(std::vector<Mark> const& marks)
    {
        BuddyMarks::Modifiers m;
        for (Mark const& k : marks)
            for (BuddyMarks::AuraEffect e : k.effects) { e.stacks = k.stacks; BuddyMarks::Fold(m, e); }
        return m;
    }

    enum Kind : uint8_t { HIT = 0, HEAL = 1, MARK_ON = 2, MARK_OFF = 3, CAST_BEGIN = 4, CAST_END = 5, DEATH = 6 };
    struct Event { double t; uint8_t kind; uint64_t from, to; uint32_t spell; double amount; bool physical; };

    class Memory
    {
    public:
        explicit Memory(double window = 60.0) : _window(window) {}

        void Add(Event const& e)
        {
            if (_events.empty()) _first = e.t;
            _events.push_back(e);
            Count(e, +1.0);
        }

        void Forget(double now)
        {
            while (!_events.empty() && _events.front().t < now - _window)
            {
                Count(_events.front(), -1.0);
                _events.pop_front();
            }
            if (_events.empty()) _first = now;
        }

        double Covered(double now) const { return std::max(1.0, std::min(_window, now - _first)); }
        double TakenPerSecond(uint64_t id, double now) const  { auto it = _sums.find(id); return it == _sums.end() ? 0.0 : it->second.taken / Covered(now); }
        double HealedPerSecond(uint64_t id, double now) const { auto it = _sums.find(id); return it == _sums.end() ? 0.0 : it->second.healed / Covered(now); }
        double DealtPerSecond(uint64_t id, double now) const  { auto it = _sums.find(id); return it == _sums.end() ? 0.0 : it->second.dealt / Covered(now); }
        double HealingPerSecond(uint64_t id, double now) const { auto it = _sums.find(id); return it == _sums.end() ? 0.0 : it->second.healing / Covered(now); }
        double PhysicalShare(uint64_t id) const
        {
            auto it = _sums.find(id);
            if (it == _sums.end() || it->second.dealt <= 0.0) return 1.0;
            return std::max(0.0, std::min(1.0, it->second.dealtPhysical / it->second.dealt));
        }
        size_t Count() const { return _events.size(); }

        void Sample(double t, double enemiesHealth)
        {
            _samples.push_back({ t, enemiesHealth });
            while (!_samples.empty() && _samples.front().t < t - _window) _samples.pop_front();
        }
        void SampleResource(uint64_t id, double t, double value)
        {
            auto& d = _resources[id];
            d.push_back({ t, value });
            while (!d.empty() && d.front().t < t - _window) d.pop_front();
        }
        double ResourceFalling(uint64_t id, double now, double look = 10.0) const
        {
            auto it = _resources.find(id);
            if (it == _resources.end()) return 0.0;
            std::vector<BuddyFight::Sample> s(it->second.begin(), it->second.end());
            return BuddyFight::RateOf(s, now, look);
        }
        BuddyFight::Guess FightLeft(double now, double enemiesHealth, std::vector<BuddyPlan::Window> const& bursts, double look = 10.0, double measuredUnder = 1.0) const
        {
            std::vector<BuddyFight::Sample> s(_samples.begin(), _samples.end());
            return BuddyFight::TimeLeft(enemiesHealth, BuddyFight::RateOf(s, now, look) / std::max(1e-6, measuredUnder), bursts);
        }

    private:
        struct Sums { double taken = 0, healed = 0, dealt = 0, dealtPhysical = 0, healing = 0; };

        void Count(Event const& e, double sign)
        {
            if (e.kind == HIT)
            {
                _sums[e.to].taken   += sign * e.amount;
                _sums[e.from].dealt += sign * e.amount;
                if (e.physical) _sums[e.from].dealtPhysical += sign * e.amount;
            }
            else if (e.kind == HEAL)
            {
                _sums[e.to].healed    += sign * e.amount;
                _sums[e.from].healing += sign * e.amount;
            }
        }

        double _window, _first = 0.0;
        std::deque<Event> _events;
        std::deque<BuddyFight::Sample> _samples;
        std::unordered_map<uint64_t, std::deque<BuddyFight::Sample>> _resources;
        std::unordered_map<uint64_t, Sums> _sums;
    };
}

#endif
