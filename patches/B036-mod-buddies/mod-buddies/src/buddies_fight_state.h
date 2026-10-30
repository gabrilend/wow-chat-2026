/*
 * buddies_fight_state.h - the fight as the forward pass reads it (issue
 * 625n): the snapshot, one picture of the whole fight, and a minute of
 * events with running summaries; plain data and arithmetic, apart from the
 * server, so it can be tested on its own (tests/buddy-fight-state/,
 * scripts/test-buddy-fight-state).
 *
 * For a general audience: a language model reads everything said so far;
 * a buddy reads the fight so far. That is two things. The snapshot is the
 * fight now: everyone's health, resource, casts, cooldowns and marks, each
 * enemy's threat list. The events are what has happened over the last
 * minute (the owner, 2026-10-30: "a minute is fine"): each hit, heal, mark
 * and death, kept in the order they came. As each event comes in, a few
 * running sums are updated (damage taken, healing received and damage dealt
 * per character, how much of an enemy's damage was physical), and as each
 * falls out of the minute it is taken back off them, so a rate is always
 * one division, never a re-read of the minute: the language model's cache.
 * The world thread fills both from the game (plain values copied, never
 * game objects), and worker threads read them.
 */

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
    // {{{ the snapshot
    // Mark: one buff or debuff on someone: its aura's spell id, seconds
    // left (0 for one that lasts until removed), stacks, who put it on, and
    // its effects as the game holds them (buddies_marks.h).
    struct Mark { uint32_t spell; double secondsLeft; uint32_t stacks; uint64_t by; std::vector<BuddyMarks::AuraEffect> effects; };

    // Cooldown: one of the long abilities it knows (a cooldown of 90
    // seconds or more), by the spell id it knows it at, its name in lower
    // case (as the generated tables name it: ranks have different ids, one
    // name), and seconds until ready (0: ready now). An ability it hasn't
    // learned isn't listed, so nothing is planned round it.
    struct Cooldown { uint32_t spell; std::string name; double readyIn; };

    // Member: one of the party, a pet included (`owner` its master's id; 0
    // for a character). Role: 0 damage, 1 tank, 2 healer. resourceKind: the
    // game's power type (0 mana, 1 rage, 3 energy, 6 runic power, 2 focus).
    // Armour and level: what its physical damage taken comes from
    // (buddies_marks.h, ArmourReduction).
    struct Member
    {
        uint64_t id = 0, owner = 0;
        double health = 0, maxHealth = 0, resource = 0, maxResource = 0;
        uint8_t resourceKind = 0, role = 0, cls = 0;
        double armour = 0; int level = 1;
        double x = 0, y = 0, z = 0;
        uint32_t casting = 0; double castLeft = 0;
        std::vector<Cooldown> cooldowns;
        std::vector<Mark> marks;
    };

    // ThreatEntry: one character on an enemy's threat list (buddies_threat.h).
    struct ThreatEntry { uint64_t who; BuddyThreat::Entry entry; };

    // Enemy: one of them. Rank: the game's creature rank (0 normal, 1 elite,
    // 2 rare elite, 3 boss, 4 rare); `attacking` whom it hits now (0 no one).
    // A cast in progress: its spell, seconds left, the damage it will deal
    // (its damage effects' values as the game works them out for this
    // caster, before the target's marks) and on whom (0: no one known).
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

    // Snapshot: the fight now. `t` seconds on a clock that only goes
    // forward; the windows open (Bloodlust running, a weak phase).
    struct Snapshot
    {
        double t = 0;
        std::vector<BuddyPlan::Window> windows;
        std::vector<Member> party;
        std::vector<Enemy> enemies;
    };

    // {{{ FightKind
    // A boss fight when any enemy is a boss or a rare elite (the owner,
    // 2026-10-30: "should be for rare elites in the open world as well, but
    // not regular elites."); a dungeon's own boss list (617c3) is read by
    // the server into the boss rank's place; otherwise trash.
    inline BuddyPlan::Fight FightKind(Snapshot const& s)
    {
        for (Enemy const& e : s.enemies)
            if (e.rank == 3 || e.rank == 2) return BuddyPlan::Fight::Boss;
        return BuddyPlan::Fight::Trash;
    }
    // }}}

    // {{{ ModifiersOf
    // What all the marks on someone add up to (buddies_marks.h), each
    // effect at its mark's stacks.
    inline BuddyMarks::Modifiers ModifiersOf(std::vector<Mark> const& marks)
    {
        BuddyMarks::Modifiers m;
        for (Mark const& k : marks)
            for (BuddyMarks::AuraEffect e : k.effects) { e.stacks = k.stacks; BuddyMarks::Fold(m, e); }
        return m;
    }
    // }}}
    // }}}

    // {{{ events
    // Event: one thing that happened. kind: 0 a hit, 1 a heal, 2 a mark on,
    // 3 a mark off, 4 a cast begun, 5 a cast ended, 6 a death. `from` did it
    // to `to`; `spell` with what (0 a plain attack); `amount` how much (a
    // hit's damage after armour and absorbs, a heal's healing that landed,
    // overhealing left out); `physical` whether a hit was physical.
    enum Kind : uint8_t { HIT = 0, HEAL = 1, MARK_ON = 2, MARK_OFF = 3, CAST_BEGIN = 4, CAST_END = 5, DEATH = 6 };
    struct Event { double t; uint8_t kind; uint64_t from, to; uint32_t spell; double amount; bool physical; };
    // }}}

    // {{{ Memory
    // A minute of events (`window` seconds) and the sums that ride with it.
    // Per character: damage taken, healing received, damage dealt; per
    // dealer, how much of its damage was physical. Events are added in the
    // order they happen; Forget takes off what has fallen out of the window
    // (called with the snapshot's time before reading). Rates divide by the
    // time covered: the window, or less at a fight's start (at least one
    // second, so a single first hit doesn't read as a flood).
    class Memory
    {
    public:
        explicit Memory(double window = 60.0) : _window(window) {}

        // {{{ Add
        void Add(Event const& e)
        {
            if (_events.empty()) _first = e.t;
            _events.push_back(e);
            Count(e, +1.0);
        }
        // }}}

        // {{{ Forget
        void Forget(double now)
        {
            while (!_events.empty() && _events.front().t < now - _window)
            {
                Count(_events.front(), -1.0);
                _events.pop_front();
            }
            if (_events.empty()) _first = now;
        }
        // }}}

        // {{{ the rates
        double Covered(double now) const { return std::max(1.0, std::min(_window, now - _first)); }
        double TakenPerSecond(uint64_t id, double now) const  { auto it = _sums.find(id); return it == _sums.end() ? 0.0 : it->second.taken / Covered(now); }
        double HealedPerSecond(uint64_t id, double now) const { auto it = _sums.find(id); return it == _sums.end() ? 0.0 : it->second.healed / Covered(now); }
        double DealtPerSecond(uint64_t id, double now) const  { auto it = _sums.find(id); return it == _sums.end() ? 0.0 : it->second.dealt / Covered(now); }
        // the share of a dealer's damage that was physical; an enemy not yet
        // seen dealing any counts as physical (most enemies' plain attacks)
        double PhysicalShare(uint64_t id) const
        {
            auto it = _sums.find(id);
            if (it == _sums.end() || it->second.dealt <= 0.0) return 1.0;
            return std::max(0.0, std::min(1.0, it->second.dealtPhysical / it->second.dealt));
        }
        size_t Count() const { return _events.size(); }
        // }}}

        // {{{ the enemies' health, for the fight's length
        // One reading per snapshot (the enemies' health together), the last
        // minute kept, read as a rate by the fight-length guess (625h).
        void Sample(double t, double enemiesHealth)
        {
            _samples.push_back({ t, enemiesHealth });
            while (!_samples.empty() && _samples.front().t < t - _window) _samples.pop_front();
        }
        // `measuredUnder`: what the windows open now multiplied the fall by
        // while it was measured (taken as open through the look back), so
        // the steady rate is the measured one over it and the windows are
        // counted once, where they still run
        BuddyFight::Guess FightLeft(double now, double enemiesHealth, std::vector<BuddyPlan::Window> const& bursts, double look = 10.0, double measuredUnder = 1.0) const
        {
            std::vector<BuddyFight::Sample> s(_samples.begin(), _samples.end());
            return BuddyFight::TimeLeft(enemiesHealth, BuddyFight::RateOf(s, now, look) / std::max(1e-6, measuredUnder), bursts);
        }
        // }}}

    private:
        struct Sums { double taken = 0, healed = 0, dealt = 0, dealtPhysical = 0; };

        // {{{ Count
        // One event into the sums (sign +1) or out of them (-1).
        void Count(Event const& e, double sign)
        {
            if (e.kind == HIT)
            {
                _sums[e.to].taken   += sign * e.amount;
                _sums[e.from].dealt += sign * e.amount;
                if (e.physical) _sums[e.from].dealtPhysical += sign * e.amount;
            }
            else if (e.kind == HEAL) _sums[e.to].healed += sign * e.amount;
        }
        // }}}

        double _window, _first = 0.0;
        std::deque<Event> _events;
        std::deque<BuddyFight::Sample> _samples;
        std::unordered_map<uint64_t, Sums> _sums;
    };
    // }}}
}

#endif
