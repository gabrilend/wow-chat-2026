
#ifndef MOD_BUDDIES_FIGHT_REPLAY_H
#define MOD_BUDDIES_FIGHT_REPLAY_H

#include "buddies_fight_state.h"

#include <cstdio>
#include <sstream>
#include <string>
#include <vector>

namespace BuddyFightReplay
{
    using namespace BuddyFightState;

    struct Step { std::vector<Event> events; Snapshot snapshot; double shortfall = -1, left = -1; int leftKnown = -1; };

    inline std::string Under(std::string s) { for (char& c : s) if (c == ' ') c = '_'; return s.empty() ? "_" : s; }
    inline std::string Spaces(std::string s) { for (char& c : s) if (c == '_') c = ' '; return s; }

    inline std::string Write(std::vector<Event> const& events, Snapshot const& s, double shortfall = -1, double left = -1, int leftKnown = -1)
    {
        std::ostringstream o;
        o.precision(17);
        auto marks = [&](std::vector<Mark> const& ks) {
            for (Mark const& k : ks)
            {
                o << "K " << k.spell << ' ' << k.secondsLeft << ' ' << k.stacks << ' ' << k.by << ' ' << k.effects.size();
                for (BuddyMarks::AuraEffect const& e : k.effects) o << ' ' << e.aura << ' ' << e.amount << ' ' << e.misc << ' ' << e.periodMs;
                o << '\n';
            }
        };
        for (Event const& e : events)
            o << "E " << e.t << ' ' << int(e.kind) << ' ' << e.from << ' ' << e.to << ' ' << e.spell << ' ' << e.amount << ' ' << (e.physical ? 1 : 0) << '\n';
        o << "S " << s.t << '\n';
        for (BuddyPlan::Window const& w : s.windows) o << "W " << w.start << ' ' << w.length << ' ' << w.factor << '\n';
        for (Member const& m : s.party)
        {
            o << "M " << m.id << ' ' << m.owner << ' ' << m.health << ' ' << m.maxHealth << ' ' << m.resource << ' ' << m.maxResource << ' '
              << int(m.resourceKind) << ' ' << int(m.role) << ' ' << int(m.cls) << ' ' << m.armour << ' ' << m.level << ' '
              << m.x << ' ' << m.y << ' ' << m.z << ' ' << m.casting << ' ' << m.castLeft << ' ' << int(m.healPoints) << ' ' << int(m.talentPoints) << ' ' << m.baseMana << '\n';
            for (Cooldown const& c : m.cooldowns) o << "C " << c.spell << ' ' << Under(c.name) << ' ' << c.readyIn << '\n';
            marks(m.marks);
        }
        for (Enemy const& e : s.enemies)
        {
            o << "N " << e.id << ' ' << e.health << ' ' << e.maxHealth << ' ' << int(e.rank) << ' ' << e.level << ' ' << e.casting << ' ' << e.castLeft << ' ' << e.attacking
              << ' ' << e.castDamage << ' ' << e.castOn << '\n';
            marks(e.marks);
            for (ThreatEntry const& t : e.threat)
                o << "T " << t.who << ' ' << t.entry.threat << ' ' << t.entry.state << ' ' << t.entry.taunt << ' ' << (t.entry.melee ? 1 : 0) << '\n';
        }
        if (shortfall >= 0) o << "V " << shortfall << ' ' << left << ' ' << leftKnown << '\n';
        o << ".\n";
        return o.str();
    }

    inline std::vector<Step> Read(std::string const& text, std::string* error = nullptr)
    {
        std::vector<Step> out;
        Step cur;
        std::vector<Mark>* lastMarks = nullptr;
        std::vector<ThreatEntry>* lastThreat = nullptr;
        std::istringstream in(text);
        std::string line;
        int n = 0;
        auto fail = [&](char const* why) { if (error) *error = "line " + std::to_string(n) + ": " + why + ": " + line; return out; };
        while (std::getline(in, line))
        {
            ++n;
            if (line.empty()) continue;
            std::istringstream l(line);
            char what = 0;
            l >> what;
            if (what == 'E')
            {
                Event e{}; int kind = 0, phys = 0;
                if (!(l >> e.t >> kind >> e.from >> e.to >> e.spell >> e.amount >> phys)) return fail("an event short of its fields");
                e.kind = uint8_t(kind); e.physical = phys != 0;
                cur.events.push_back(e);
            }
            else if (what == 'S') { if (!(l >> cur.snapshot.t)) return fail("a snapshot without its time"); }
            else if (what == 'W')
            {
                BuddyPlan::Window w{};
                if (!(l >> w.start >> w.length >> w.factor)) return fail("a window short of its fields");
                cur.snapshot.windows.push_back(w);
            }
            else if (what == 'M')
            {
                Member m; int kind = 0, role = 0, cls = 0, healPoints = 0, talentPoints = 0;
                if (!(l >> m.id >> m.owner >> m.health >> m.maxHealth >> m.resource >> m.maxResource >> kind >> role >> cls >> m.armour >> m.level
                        >> m.x >> m.y >> m.z >> m.casting >> m.castLeft >> healPoints >> talentPoints >> m.baseMana)) return fail("a member short of its fields");
                m.healPoints = uint8_t(healPoints); m.talentPoints = uint8_t(talentPoints);
                m.resourceKind = uint8_t(kind); m.role = uint8_t(role); m.cls = uint8_t(cls);
                cur.snapshot.party.push_back(std::move(m));
                lastMarks = &cur.snapshot.party.back().marks;
                lastThreat = nullptr;
            }
            else if (what == 'C')
            {
                if (cur.snapshot.party.empty()) return fail("a cooldown before any member");
                Cooldown c; std::string name;
                if (!(l >> c.spell >> name >> c.readyIn)) return fail("a cooldown short of its fields");
                c.name = Spaces(name);
                cur.snapshot.party.back().cooldowns.push_back(c);
            }
            else if (what == 'K')
            {
                if (!lastMarks) return fail("a mark before any member or enemy");
                Mark k; size_t count = 0;
                if (!(l >> k.spell >> k.secondsLeft >> k.stacks >> k.by >> count)) return fail("a mark short of its fields");
                for (size_t i = 0; i < count; ++i)
                {
                    BuddyMarks::AuraEffect e{};
                    if (!(l >> e.aura >> e.amount >> e.misc >> e.periodMs)) return fail("a mark short of its effects");
                    e.stacks = 1;
                    k.effects.push_back(e);
                }
                lastMarks->push_back(std::move(k));
            }
            else if (what == 'N')
            {
                Enemy e; int rank = 0;
                if (!(l >> e.id >> e.health >> e.maxHealth >> rank >> e.level >> e.casting >> e.castLeft >> e.attacking >> e.castDamage >> e.castOn)) return fail("an enemy short of its fields");
                e.rank = uint8_t(rank);
                cur.snapshot.enemies.push_back(std::move(e));
                lastMarks = &cur.snapshot.enemies.back().marks;
                lastThreat = &cur.snapshot.enemies.back().threat;
            }
            else if (what == 'T')
            {
                if (!lastThreat) return fail("a threat entry before any enemy");
                ThreatEntry t{}; int melee = 0;
                if (!(l >> t.who >> t.entry.threat >> t.entry.state >> t.entry.taunt >> melee)) return fail("a threat entry short of its fields");
                t.entry.melee = melee != 0;
                lastThreat->push_back(t);
            }
            else if (what == 'V') { if (!(l >> cur.shortfall >> cur.left >> cur.leftKnown)) return fail("a verdict short of its fields"); }
            else if (what == '.')
            {
                out.push_back(std::move(cur));
                cur = Step{};
                lastMarks = nullptr; lastThreat = nullptr;
            }
            else return fail("a line of no known kind");
        }
        if (error) error->clear();
        return out;
    }

    template <class F>
    inline void Replay(std::vector<Step> const& steps, F each, double window = 60.0)
    {
        Memory memory(window);
        for (Step const& st : steps)
        {
            for (Event const& e : st.events) memory.Add(e);
            double health = 0;
            for (Enemy const& e : st.snapshot.enemies) health += e.health;
            memory.Forget(st.snapshot.t);
            memory.Sample(st.snapshot.t, health);
            for (Member const& m : st.snapshot.party) memory.SampleResource(m.id, st.snapshot.t, m.resource);
            each(st, memory);
        }
    }
}

#endif
