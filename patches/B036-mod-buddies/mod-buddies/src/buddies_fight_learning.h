/*
 * buddies_fight_learning.h - what each fight taught, distilled from the raw
 * log to its crucial points and fingerprinted (issue 625e, steps 1 and 2);
 * plain text and arithmetic, apart from the server, so it can be tested on
 * its own (tests/buddy-fight-learning/, scripts/test-buddy-fight-learning).
 *
 * For a general audience: during a fight the whole of it is written to the
 * RAM drive as the replay log (buddies_fight_replay.h: every snapshot and
 * event). When the fight ends, Distill reads that log and keeps only what
 * is worth learning from (the owner, 2026-10-30: "finds the crucial
 * information datapoints, and clears most of the junk data like position
 * updates and damage values and such"):
 *   - the fight's length and how it ended (won, lost, or left);
 *   - its phases: the pull, then each time the boss's health crosses a band
 *     (75%, 50%, 25%) or its script says the phase changed;
 *   - through each phase, the share of the time each character in the
 *     party spent moving (625d's movement measure, started again at each
 *     phase);
 *   - each time movement rose (half the party or more moving, after less
 *     had been), what began just before: a cast the enemies began, an
 *     enemy that appeared, a mark an enemy put on the party, an enemy
 *     spell that hit two or more of them (fire on the ground);
 *   - who of the party died, when, in which phase.
 * Write turns that into a short block of plain text, one fight per block,
 * kept on disk by boss and by date (Path) and committed to git, so the
 * learning travels. Each block carries the fight's fingerprint: one number
 * made from everything the fight is made of (the boss's and its helpers'
 * creature rows, their spells, their scripts, the encounter's settings,
 * the tuning that touches them), and one per part, so a change can be
 * named. When the fingerprint no longer matches, what was learned is stale
 * and the boss is learned again from scratch (Changed).
 *
 * The block:
 *   fight ENTRY NAME DATE SEED            the boss's creature entry, its name
 *                                         ("_" for spaces), the day, the run's seed
 *   print HEX                             the fingerprint, whole
 *   part NAME HEX                         one per part, by name
 *   length SECONDS OUTCOME                won, lost or left
 *   phase N START LENGTH WHY...           pull, health P, script, cast SPELL
 *   moving N ID SHARE                     each character, each phase
 *   rise N T CUE...                       cast SPELL, summon ENTRY, mark SPELL, hit SPELL
 *   death N T ID                          one of the party
 *   end
 * Times in seconds from the pull, to a tenth; shares to a hundredth.
 */

#ifndef MOD_BUDDIES_FIGHT_LEARNING_H
#define MOD_BUDDIES_FIGHT_LEARNING_H

#include "buddies_fight_replay.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <map>
#include <set>
#include <sstream>
#include <string>
#include <vector>

namespace BuddyFightLearning
{
    using namespace BuddyFightState;
    using BuddyFightReplay::Step;

    // {{{ Settings
    // The agent's numbers (2026-11-06), for the owner to curate; tuning goes
    // to docs/balance-updates.md.
    struct Settings
    {
        std::vector<double> bands = { 75, 50, 25 };  // boss health percents a phase begins at
        double newCastAfter = -1;     // a boss spell first cast this long after the pull begins a phase (-1: off)
        double moveSpeed    = 1.0;    // yards a second between two snapshots: moving
        double riseShare    = 0.5;    // this share of the party moving, after less: movement rose
        double before       = 3.0;    // seconds before a rise in which what began is kept
    };
    // }}}

    // {{{ Fight
    // Who the fight was against, given by the server: the boss's creature
    // entry and name, its id in the log (0: the strongest enemy in the first
    // snapshot), the day, the run's seed, the times the boss's script said
    // its phase changed, and the creature entry of each enemy id the log
    // may hold (for summons; one not known is written "?").
    struct Fight
    {
        uint32_t entry = 0;
        std::string name;
        uint64_t boss = 0;
        std::string date;
        uint64_t seed = 0;
        std::vector<double> scriptPhases;
        std::map<uint64_t, uint32_t> entries;
    };
    // }}}

    // {{{ the distilled points
    struct Phase  { int n = 0; double start = 0, length = 0; std::string why; };
    struct Moving { int phase = 0; uint64_t id = 0; double share = 0; };
    struct Rise   { int phase = 0; double t = 0; std::vector<std::string> cues; };
    struct Death  { int phase = 0; double t = 0; uint64_t id = 0; };
    struct Part   { std::string name; uint64_t hash = 0; };
    struct Distilled
    {
        uint32_t entry = 0;
        std::string name, date;
        uint64_t seed = 0;
        uint64_t print = 0;
        std::vector<Part> parts;
        double length = 0;
        std::string outcome = "left";
        std::vector<Phase> phases;
        std::vector<Moving> moving;
        std::vector<Rise> rises;
        std::vector<Death> deaths;
    };
    // }}}

    // {{{ Hash, Print
    // FNV-1a, 64 bits: the same text gives the same number on every machine.
    inline uint64_t Hash(std::string const& text)
    {
        uint64_t h = 14695981039346656037ULL;
        for (unsigned char c : text) { h ^= c; h *= 1099511628211ULL; }
        return h;
    }
    inline std::string Hex(uint64_t h)
    {
        char b[17];
        std::snprintf(b, sizeof b, "%016llx", static_cast<unsigned long long>(h));
        return b;
    }
    // The fingerprint of the fight's parts (name -> its text, as the server
    // reads it: creature rows, spells, scripts, settings, tuning): one hash
    // per part, sorted by name, and the whole made from those, so the order
    // they are given in doesn't matter. Two parts of one name: the later wins.
    inline std::vector<Part> Parts(std::map<std::string, std::string> const& texts)
    {
        std::vector<Part> out;
        for (auto const& [name, text] : texts) out.push_back({ name, Hash(text) });
        return out;
    }
    inline uint64_t Whole(std::vector<Part> const& parts)
    {
        std::string all;
        for (Part const& p : parts) all += p.name + '\0' + Hex(p.hash) + '\n';
        return Hash(all);
    }
    // }}}

    // {{{ Changed
    // What differs between the parts a fight was learned with and the parts
    // now: "NAME changed", "NAME added", "NAME gone", sorted by name. Empty:
    // still the same fight; anything: what was learned is stale.
    inline std::vector<std::string> Changed(std::vector<Part> const& then, std::vector<Part> const& now)
    {
        std::map<std::string, uint64_t> a, b;
        for (Part const& p : then) a[p.name] = p.hash;
        for (Part const& p : now) b[p.name] = p.hash;
        std::vector<std::string> out;
        for (auto const& [name, h] : a)
        {
            auto it = b.find(name);
            if (it == b.end()) out.push_back(name + " gone");
            else if (it->second != h) out.push_back(name + " changed");
        }
        for (auto const& [name, h] : b)
            if (!a.count(name)) out.push_back(name + " added");
        std::sort(out.begin(), out.end());
        return out;
    }
    // }}}

    // {{{ helpers
    inline double Pct(Enemy const& e) { return e.maxHealth > 0 ? 100.0 * e.health / e.maxHealth : 0.0; }
    inline Enemy const* Find(Snapshot const& s, uint64_t id)
    {
        for (Enemy const& e : s.enemies) if (e.id == id) return &e;
        return nullptr;
    }
    inline Member const* FindMember(Snapshot const& s, uint64_t id)
    {
        for (Member const& m : s.party) if (m.id == id) return &m;
        return nullptr;
    }
    // The boss when none is named: a boss rank before a rare elite before
    // the rest, then the most health.
    inline uint64_t Strongest(Snapshot const& s)
    {
        auto order = [](uint8_t rank) { return rank == 3 ? 3 : rank == 2 ? 2 : rank == 0 ? 0 : 1; };
        Enemy const* best = nullptr;
        for (Enemy const& e : s.enemies)
            if (!best || order(e.rank) > order(best->rank) || (order(e.rank) == order(best->rank) && e.maxHealth > best->maxHealth))
                best = &e;
        return best ? best->id : 0;
    }
    inline double Tenth(double v) { return std::round(v * 10.0) / 10.0; }
    inline double Hundredth(double v) { return std::round(v * 100.0) / 100.0; }
    // }}}

    // {{{ Distill
    // The raw log's steps to the crucial points. `parts`: the fight's parts
    // for the fingerprint (Parts).
    inline Distilled Distill(std::vector<Step> const& steps, Fight const& f, std::vector<Part> const& parts, Settings const& s = {})
    {
        Distilled d;
        d.entry = f.entry; d.name = f.name; d.date = f.date; d.seed = f.seed;
        d.parts = parts; d.print = Whole(parts);
        if (steps.empty()) return d;
        double const t0 = steps.front().snapshot.t;
        uint64_t const boss = f.boss ? f.boss : Strongest(steps.front().snapshot);

        std::set<uint64_t> enemies, party;
        for (Step const& st : steps)
        {
            for (Enemy const& e : st.snapshot.enemies) enemies.insert(e.id);
            for (Member const& m : st.snapshot.party) party.insert(m.id);
        }

        // {{{ the phases: one at each snapshot where anything changed
        std::vector<int> phaseAt(steps.size(), 1);
        {
            d.phases.push_back({ 1, 0.0, 0.0, "pull" });
            std::vector<double> bands = s.bands;
            std::sort(bands.rbegin(), bands.rend());
            size_t nextBand = 0;
            size_t nextScript = 0;
            std::vector<double> script = f.scriptPhases;
            std::sort(script.begin(), script.end());
            std::set<uint32_t> cast;
            Enemy const* first = Find(steps.front().snapshot, boss);
            while (first && nextBand < bands.size() && Pct(*first) <= bands[nextBand]) ++nextBand;   // pulled already under a band
            while (nextScript < script.size() && script[nextScript] <= t0) ++nextScript;
            for (size_t i = 0; i < steps.size(); ++i)
            {
                Snapshot const& sn = steps[i].snapshot;
                std::vector<std::string> why;
                if (i > 0)
                {
                    bool scripted = false;
                    while (nextScript < script.size() && script[nextScript] <= sn.t) { ++nextScript; scripted = true; }
                    if (scripted) why.push_back("script");
                    if (Enemy const* b = Find(sn, boss))
                    {
                        double crossed = -1;
                        while (nextBand < bands.size() && Pct(*b) <= bands[nextBand]) crossed = bands[nextBand++];
                        if (crossed >= 0)
                        {
                            std::ostringstream w; w << "health " << crossed;
                            why.push_back(w.str());
                        }
                    }
                }
                for (Event const& e : steps[i].events)
                    if (e.kind == CAST_BEGIN && e.from == boss && e.spell && cast.insert(e.spell).second
                        && s.newCastAfter >= 0 && i > 0 && e.t - t0 >= s.newCastAfter)
                        why.push_back("cast " + std::to_string(e.spell));
                if (!why.empty())
                {
                    std::string all;
                    for (std::string const& w : why) all += (all.empty() ? "" : " ") + w;
                    d.phases.push_back({ int(d.phases.size()) + 1, Tenth(sn.t - t0), 0.0, all });
                }
                phaseAt[i] = int(d.phases.size());
            }
        }
        // }}}

        // {{{ the length, each phase's, and the outcome
        double const end = steps.back().snapshot.t;
        d.length = Tenth(end - t0);
        for (size_t p = 0; p < d.phases.size(); ++p)
            d.phases[p].length = Tenth((p + 1 < d.phases.size() ? d.phases[p + 1].start : d.length) - d.phases[p].start);
        bool bossDied = false;
        for (size_t i = 0; i < steps.size(); ++i)
            for (Event const& e : steps[i].events)
                if (e.kind == DEATH)
                {
                    if (e.to == boss) bossDied = true;
                    else if (party.count(e.to))           // each death, one raised and fallen again twice
                    {
                        int phase = 1;                         // by its own time: a snapshot's events came before it
                        for (Phase const& p : d.phases) if (p.start <= e.t - t0) phase = p.n;
                        d.deaths.push_back({ phase, Tenth(e.t - t0), e.to });
                    }
                }
        Snapshot const& last = steps.back().snapshot;
        if (Enemy const* b = Find(last, boss); b && b->health <= 0) bossDied = true;
        bool allDown = !last.party.empty();
        for (Member const& m : last.party) if (m.health > 0) allDown = false;
        d.outcome = bossDied ? "won" : allDown ? "lost" : "left";
        // }}}

        // {{{ moving, and its rises
        std::map<std::pair<int, uint64_t>, std::pair<double, double>> seen;   // (phase, id) -> (time, moving)
        double lastShare = -1;
        for (size_t i = 0; i + 1 < steps.size(); ++i)
        {
            Snapshot const& a = steps[i].snapshot;
            Snapshot const& b = steps[i + 1].snapshot;
            double dt = b.t - a.t;
            if (dt <= 0) continue;
            int count = 0, moving = 0;
            for (Member const& m : a.party)
            {
                if (m.owner != 0 || m.health <= 0) continue;          // characters only, alive
                Member const* n = FindMember(b, m.id);
                if (!n) continue;
                bool moved = std::hypot(std::hypot(n->x - m.x, n->y - m.y), n->z - m.z) / dt > s.moveSpeed;
                auto& acc = seen[{ phaseAt[i], m.id }];
                acc.first += dt;
                if (moved) acc.second += dt;
                ++count;
                if (moved) ++moving;
            }
            double share = count ? double(moving) / count : 0.0;
            if (lastShare >= 0 && lastShare < s.riseShare && share >= s.riseShare)
            {
                Rise r; r.phase = phaseAt[i]; r.t = Tenth(a.t - t0);
                std::set<std::string> cues;
                std::map<uint32_t, std::set<uint64_t>> hitBy;
                for (size_t j = 0; j <= i + 1; ++j)
                    for (Event const& e : steps[j].events)
                    {
                        if (e.t < a.t - s.before || e.t > b.t || !enemies.count(e.from)) continue;
                        if (e.kind == CAST_BEGIN && e.spell) cues.insert("cast " + std::to_string(e.spell));
                        if (e.kind == MARK_ON && e.spell && party.count(e.to)) cues.insert("mark " + std::to_string(e.spell));
                        if (e.kind == HIT && e.spell && party.count(e.to)) hitBy[e.spell].insert(e.to);
                    }
                for (auto const& [spell, who] : hitBy)
                    if (who.size() >= 2) cues.insert("hit " + std::to_string(spell));
                for (size_t j = 1; j <= i + 1; ++j)
                {
                    if (steps[j].snapshot.t < a.t - s.before) continue;
                    for (Enemy const& e : steps[j].snapshot.enemies)
                    {
                        bool before = false;
                        for (size_t k = 0; k < j && !before; ++k) before = Find(steps[k].snapshot, e.id) != nullptr;
                        if (!before)
                        {
                            auto it = f.entries.find(e.id);
                            cues.insert("summon " + (it == f.entries.end() ? std::string("?") : std::to_string(it->second)));
                        }
                    }
                }
                r.cues.assign(cues.begin(), cues.end());
                d.rises.push_back(r);
            }
            lastShare = share;
        }
        for (auto const& [key, acc] : seen)
            d.moving.push_back({ key.first, key.second, Hundredth(acc.first > 0 ? acc.second / acc.first : 0.0) });
        // }}}
        return d;
    }
    // }}}

    // {{{ Write, Read
    inline std::string Number(double v)
    {
        std::ostringstream o;
        o << v;
        return o.str();
    }
    inline std::string Write(Distilled const& d)
    {
        std::ostringstream o;
        o << "fight " << d.entry << ' ' << BuddyFightReplay::Under(d.name) << ' ' << (d.date.empty() ? "_" : d.date) << ' ' << d.seed << '\n';
        o << "print " << Hex(d.print) << '\n';
        for (Part const& p : d.parts) o << "part " << BuddyFightReplay::Under(p.name) << ' ' << Hex(p.hash) << '\n';
        o << "length " << Number(d.length) << ' ' << d.outcome << '\n';
        for (Phase const& p : d.phases) o << "phase " << p.n << ' ' << Number(p.start) << ' ' << Number(p.length) << ' ' << p.why << '\n';
        for (Moving const& m : d.moving) o << "moving " << m.phase << ' ' << m.id << ' ' << Number(m.share) << '\n';
        for (Rise const& r : d.rises)
        {
            o << "rise " << r.phase << ' ' << Number(r.t);
            for (std::string const& c : r.cues) o << ' ' << c;
            o << '\n';
        }
        for (Death const& x : d.deaths) o << "death " << x.phase << ' ' << Number(x.t) << ' ' << x.id << '\n';
        o << "end\n";
        return o.str();
    }

    // Every block in a file of them, in order. A line it can't read stops
    // the reading there and says which (`error`, empty when all were read).
    inline std::vector<Distilled> Read(std::string const& text, std::string* error = nullptr)
    {
        std::vector<Distilled> out;
        Distilled cur;
        bool open = false;
        std::istringstream in(text);
        std::string line;
        int n = 0;
        auto fail = [&](char const* why) { if (error) *error = "line " + std::to_string(n) + ": " + why + ": " + line; return out; };
        auto hex = [](std::string const& h, uint64_t& v) {
            if (h.size() != 16 || h.find_first_not_of("0123456789abcdef") != std::string::npos) return false;
            v = std::stoull(h, nullptr, 16);
            return true;
        };
        while (std::getline(in, line))
        {
            ++n;
            if (line.empty()) continue;
            std::istringstream l(line);
            std::string what;
            l >> what;
            if (what == "fight")
            {
                if (open) return fail("a fight inside a fight");
                cur = Distilled{}; open = true;
                std::string name, date;
                if (!(l >> cur.entry >> name >> date >> cur.seed)) return fail("a fight short of its fields");
                cur.name = BuddyFightReplay::Spaces(name); cur.date = date == "_" ? "" : date;
                continue;
            }
            if (!open) return fail("a line outside a fight");
            if (what == "print")
            {
                std::string h;
                if (!(l >> h) || !hex(h, cur.print)) return fail("a fingerprint not 16 hex digits");
            }
            else if (what == "part")
            {
                Part p; std::string name, h;
                if (!(l >> name >> h) || !hex(h, p.hash)) return fail("a part short of its fields");
                p.name = BuddyFightReplay::Spaces(name);
                cur.parts.push_back(p);
            }
            else if (what == "length") { if (!(l >> cur.length >> cur.outcome)) return fail("a length short of its fields"); }
            else if (what == "phase")
            {
                Phase p;
                if (!(l >> p.n >> p.start >> p.length)) return fail("a phase short of its fields");
                std::getline(l >> std::ws, p.why);
                cur.phases.push_back(p);
            }
            else if (what == "moving")
            {
                Moving m;
                if (!(l >> m.phase >> m.id >> m.share)) return fail("a moving share short of its fields");
                cur.moving.push_back(m);
            }
            else if (what == "rise")
            {
                Rise r;
                if (!(l >> r.phase >> r.t)) return fail("a rise short of its fields");
                std::string kind, what2;
                while (l >> kind)
                {
                    if (!(l >> what2)) return fail("a cue short of its spell or entry");
                    r.cues.push_back(kind + ' ' + what2);
                }
                cur.rises.push_back(r);
            }
            else if (what == "death")
            {
                Death x;
                if (!(l >> x.phase >> x.t >> x.id)) return fail("a death short of its fields");
                cur.deaths.push_back(x);
            }
            else if (what == "end") { out.push_back(cur); open = false; }
            else return fail("a line of no known kind");
        }
        if (open) { line.clear(); return fail("a fight with no end"); }
        if (error) error->clear();
        return out;
    }
    // }}}

    // {{{ Stale
    // A block learned from a fight that has since changed: its fingerprint
    // isn't the fight's now.
    inline bool Stale(Distilled const& d, std::vector<Part> const& now) { return d.print != Whole(now); }
    // }}}

    // {{{ Path
    // Where a fight's block is kept in the project, by boss and by day:
    // learned/fights/ENTRY-name/DATE.fights, the name in lower case with
    // anything but letters and digits as "-". The day's fights of one boss
    // go into one file, one block after another.
    inline std::string Path(uint32_t entry, std::string const& name, std::string const& date)
    {
        std::string slug;
        for (char c : name)
        {
            char k = (c >= 'A' && c <= 'Z') ? char(c - 'A' + 'a') : c;
            bool ok = (k >= 'a' && k <= 'z') || (k >= '0' && k <= '9');
            if (ok) slug += k;
            else if (!slug.empty() && slug.back() != '-') slug += '-';
        }
        while (!slug.empty() && slug.back() == '-') slug.pop_back();
        return "learned/fights/" + std::to_string(entry) + (slug.empty() ? "" : "-" + slug) + "/" + date + ".fights";
    }
    // }}}
}

#endif
