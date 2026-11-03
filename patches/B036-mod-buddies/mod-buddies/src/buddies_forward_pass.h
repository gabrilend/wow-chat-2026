
#ifndef MOD_BUDDIES_FORWARD_PASS_H
#define MOD_BUDDIES_FORWARD_PASS_H

#include "buddies_curve.h"
#include "buddies_fight_state.h"
#include "buddies_healer_seat.h"
#include "buddies_window_buffs.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <limits>
#include <map>
#include <string>
#include <vector>

namespace BuddyForwardPass
{
    using namespace BuddyFightState;

    struct Verdict
    {
        BuddyPlan::Fight kind = BuddyPlan::Fight::Trash;
        double left = 0; bool leftKnown = false;
        std::vector<int> attention;
        std::vector<double> hits, incoming, taken, healing, timeToDeath, shortOf;
        double shortfall = 0;
        int strongest = -1;
        BuddyCurve::SwapPlan tanks{ -1, -1.0, -1, 0.0 };
    };

    struct Extra { int member; std::vector<BuddyMarks::AuraEffect> effects; double lasts; };

    inline int IndexOf(Snapshot const& s, uint64_t id)
    {
        for (size_t i = 0; i < s.party.size(); ++i) if (s.party[i].id == id) return static_cast<int>(i);
        return -1;
    }
    inline double ArmourTaken(Member const& m, Enemy const& e, double physicalShare)
    {
        return physicalShare * (1.0 - BuddyMarks::ArmourReduction(m.armour, e.level)) + (1.0 - physicalShare);
    }
    inline double MarksTaken(BuddyMarks::Modifiers const& mod, double physicalShare)
    {
        return BuddyMarks::Taken(mod, physicalShare);
    }
    inline double PartyHorizon(Snapshot const& s)
    {
        std::vector<double> cds;
        for (Member const& m : s.party)
            for (BuddyAbilityRow const& r : BUDDY_ABILITIES)
                if (r.cls == m.cls && r.cooldownMs >= 90000) cds.push_back(r.cooldownMs / 1000.0);
        return BuddyFight::Horizon(cds);
    }

    inline std::vector<BuddyPlan::Window> OpenWindows(Snapshot const& s, Memory const& memory)
    {
        std::vector<BuddyPlan::Window> out;
        double partyDealt = 0.0;
        for (Member const& m : s.party) partyDealt += memory.DealtPerSecond(m.id, s.t);
        if (partyDealt <= 0.0) return out;
        for (Member const& m : s.party)
        {
            double share = memory.DealtPerSecond(m.id, s.t) / partyDealt;
            for (Mark const& k : m.marks)
                for (BuddyWindow::Buff const& b : BuddyWindow::BUFFS)
                    if (b.spell == k.spell && k.secondsLeft > 0.0)
                    {
                        double g = (1.0 + b.gives.haste) * (1.0 + b.gives.damage);
                        if (g != 1.0 && share > 0.0) out.push_back({ 0.0, k.secondsLeft, 1.0 + share * (g - 1.0) });
                    }
        }
        return out;
    }

    inline Verdict Step(Snapshot const& s, Memory const& memory, std::vector<Extra> const& extras = {})
    {
        Verdict v;
        size_t P = s.party.size(), E = s.enemies.size();
        v.kind = FightKind(s);

        double enemiesHealth = 0;
        for (Enemy const& e : s.enemies) enemiesHealth += e.health;
        std::vector<BuddyPlan::Window> windows = s.windows, open = OpenWindows(s, memory);
        windows.insert(windows.end(), open.begin(), open.end());
        double under = 1.0;
        for (BuddyPlan::Window const& w : open) under *= w.factor;
        BuddyFight::Guess g = memory.FightLeft(s.t, enemiesHealth, windows, 10.0, under);
        v.leftKnown = g.known;
        v.left = g.known ? g.seconds : PartyHorizon(s);

        std::vector<BuddyMarks::Modifiers> now(P), tried(P);
        for (size_t i = 0; i < P; ++i) now[i] = tried[i] = ModifiersOf(s.party[i].marks);
        for (Extra const& x : extras)
            if (x.member >= 0 && static_cast<size_t>(x.member) < P)
                for (BuddyMarks::AuraEffect const& e : x.effects) BuddyMarks::Fold(tried[x.member], e);

        v.attention.assign(E, -1);
        for (size_t e = 0; e < E; ++e)
        {
            std::vector<BuddyThreat::Entry> list;
            int current = -1;
            for (ThreatEntry const& t : s.enemies[e].threat)
            {
                if (t.who == s.enemies[e].attacking) current = static_cast<int>(list.size());
                list.push_back(t.entry);
            }
            int at = BuddyThreat::Attention(list, current);
            v.attention[e] = at < 0 ? -1 : IndexOf(s, s.enemies[e].threat[at].who);
        }

        v.hits.assign(E, 0.0);
        for (size_t e = 0; e < E; ++e)
        {
            double dealt = memory.DealtPerSecond(s.enemies[e].id, s.t);
            double phys  = memory.PhysicalShare(s.enemies[e].id);
            int on = IndexOf(s, s.enemies[e].attacking);
            double through = on < 0 ? 1.0 : ArmourTaken(s.party[on], s.enemies[e], phys) * MarksTaken(now[on], phys);
            v.hits[e] = through > 0.05 ? dealt / through : dealt;
        }

        v.incoming.assign(P, 0.0); v.taken.assign(P, 1.0); v.healing.assign(P, 0.0); v.timeToDeath.assign(P, 0.0);
        v.strongest = -1;
        for (size_t e = 0; e < E; ++e) if (v.strongest < 0 || v.hits[e] > v.hits[v.strongest]) v.strongest = static_cast<int>(e);
        std::vector<double> physOn(P, 0.0);
        for (size_t i = 0; i < P; ++i)
        {
            double sum = 0, armourSum = 0, phys = 0;
            for (size_t e = 0; e < E; ++e)
                if (v.attention[e] == static_cast<int>(i))
                {
                    double p = memory.PhysicalShare(s.enemies[e].id);
                    sum += v.hits[e]; armourSum += v.hits[e] * ArmourTaken(s.party[i], s.enemies[e], p); phys += v.hits[e] * p;
                }
            if (sum <= 0.0 && v.strongest >= 0)
            {
                double p = memory.PhysicalShare(s.enemies[v.strongest].id);
                v.taken[i] = ArmourTaken(s.party[i], s.enemies[v.strongest], p);
                physOn[i] = p;
            }
            else if (sum > 0.0) { v.incoming[i] = sum; v.taken[i] = armourSum / sum; physOn[i] = phys / sum; }
            double healed = std::max(0.05, now[i].healed);
            v.healing[i] = memory.HealedPerSecond(s.party[i].id, s.t) / healed;
        }
        {
            std::vector<double> before(P, 0.0), moved(P, 0.0);
            for (size_t e = 0; e < E; ++e)
            {
                int was = IndexOf(s, s.enemies[e].attacking);
                if (was >= 0) before[was] += v.hits[e];
            }
            for (size_t e = 0; e < E; ++e)
            {
                int was = IndexOf(s, s.enemies[e].attacking), is = v.attention[e];
                if (was < 0 || is < 0 || was == is || before[was] <= 0.0) continue;
                double part = v.healing[was] * v.hits[e] / before[was];
                moved[was] -= part;
                moved[is]  += part;
            }
            for (size_t i = 0; i < P; ++i) v.healing[i] = std::max(0.0, v.healing[i] + moved[i]);
        }

        std::vector<BuddyCurve::Holder> holders(P);
        for (size_t i = 0; i < P; ++i)
        {
            Member const& m = s.party[i];
            holders[i] = { m.health, m.maxHealth, v.taken[i], {} };
            for (Mark const& k : m.marks)
            {
                BuddyMarks::Modifiers one = ModifiersOf({ k });
                double until = k.secondsLeft > 0 ? k.secondsLeft : std::numeric_limits<double>::infinity();
                holders[i].marks.push_back({ until, MarksTaken(one, physOn[i]), one.healed });
            }
            for (Extra const& x : extras)
                if (x.member == static_cast<int>(i))
                {
                    BuddyMarks::Modifiers one = BuddyMarks::Of(x.effects);
                    holders[i].marks.push_back({ x.lasts, MarksTaken(one, physOn[i]), one.healed });
                    holders[i].health    += one.absorb;
                    holders[i].maxHealth += one.absorb;
                    if (one.tickHealing > 0)
                        holders[i].health = std::min(holders[i].maxHealth, holders[i].health + one.tickHealing * std::min(x.lasts, v.left));
                }
        }
        std::vector<std::vector<BuddyCurve::Lump>> lumpsOn(P);
        for (Enemy const& e : s.enemies)
        {
            int on = e.castOn ? IndexOf(s, e.castOn) : -1;
            if (on >= 0 && e.castDamage > 0.0) lumpsOn[on].push_back({ std::max(0.0, e.castLeft), 0, e.castDamage });
        }
        v.shortfall = 0;
        v.shortOf.assign(P, 0.0);
        for (size_t i = 0; i < P; ++i)
        {
            BuddyCurve::Fight f{ v.incoming[i], v.healing[i], v.left };
            v.timeToDeath[i] = BuddyCurve::TimeToDeath(holders[i], f);
            std::vector<BuddyCurve::Stretch> held;
            if (v.incoming[i] > 0) held.push_back({ 0, v.left, 0, 0 });
            if (!held.empty() || !lumpsOn[i].empty()) v.shortOf[i] = BuddyCurve::Shortfall({ holders[i] }, held, f, lumpsOn[i]);
            v.shortfall += v.shortOf[i];
        }

        if (v.strongest >= 0 && v.attention[v.strongest] >= 0)
        {
            int holder = v.attention[v.strongest];
            std::vector<int> tanks;
            for (size_t i = 0; i < P; ++i)
                if ((s.party[i].role == 1 && s.party[i].health > 0) || static_cast<int>(i) == holder) tanks.push_back(static_cast<int>(i));
            BuddyCurve::Fight f{ v.hits[v.strongest], v.healing[holder], v.left };
            v.tanks = BuddyCurve::Swap(holders, tanks, holder, f);
        }
        return v;
    }

    struct Answer
    {
        std::vector<Extra> extras;
        int healed = -1; double heal = 0;
        int taunter = -1, enemy = -1;
        double burstFactor = 1.0, burstLasts = 0.0;
        double gold = 0.0;
    };
    inline double Worth(Snapshot const& s, Memory const& memory, Answer const& a, Verdict* after = nullptr, Verdict const* known = nullptr)
    {
        Verdict before = known ? *known : Step(s, memory);
        Snapshot copy = s;
        if (a.burstLasts > 0.0 && a.burstFactor != 1.0) copy.windows.push_back({ 0.0, a.burstLasts, a.burstFactor });
        if (a.healed >= 0) copy.party[a.healed].health = std::min(copy.party[a.healed].maxHealth, copy.party[a.healed].health + a.heal);
        if (a.taunter >= 0 && a.enemy >= 0)
        {
            Enemy& e = copy.enemies[a.enemy];
            std::vector<BuddyThreat::Entry> list;
            int at = -1;
            for (size_t k = 0; k < e.threat.size(); ++k) { list.push_back(e.threat[k].entry); if (e.threat[k].who == copy.party[a.taunter].id) at = static_cast<int>(k); }
            if (at >= 0)
            {
                BuddyThreat::Taunt(list, at);
                for (size_t k = 0; k < e.threat.size(); ++k) e.threat[k].entry = list[k];
            }
        }
        Verdict v = Step(copy, memory, a.extras);
        if (after) *after = v;
        return before.shortfall - v.shortfall;
    }

    struct Score { double health, seconds; };
    inline Score Judge(Snapshot const& s, Memory const& memory, Answer const& a, double goldPerHour, Verdict const* known = nullptr)
    {
        Verdict before = known ? *known : Step(s, memory), after;
        double health = Worth(s, memory, a, &after, &before);
        double seconds = (before.leftKnown && after.leftKnown) ? before.left - after.left : 0.0;
        if (a.gold > 0.0 && goldPerHour > 0.0) seconds -= a.gold / (goldPerHour / 3600.0);
        return { health, seconds };
    }
    inline double Lean(Score const& sc, Verdict const& base)
    {
        double f = sc.health > 1.0 ? 1.0 + sc.health / std::max(1.0, base.shortfall)
                                   : 1.0 + sc.seconds / std::max(1.0, base.left);
        return std::max(0.05, f);
    }

    inline bool Better(Score const& x, Score const& y)
    {
        if (std::fabs(x.health - y.health) > 1.0) return x.health > y.health;
        return x.seconds > y.seconds + 1e-6;
    }

    inline std::string Lower(char const* s) { std::string o(s); std::transform(o.begin(), o.end(), o.begin(), [](unsigned char c) { return std::tolower(c); }); return o; }

    inline std::map<std::string, double> PlanWeights(Snapshot const& s, Memory const& memory, int b, Verdict const& base)
    {
        std::map<std::string, double> out;
        Member const& me = s.party[b];
        std::vector<std::string> names;
        std::vector<BuddyPlan::Own> own;
        for (BuddyAbilityRow const& r : BUDDY_ABILITIES)
        {
            if (r.cls != me.cls || r.cooldownMs < 90000) continue;
            for (BuddyWindow::Buff const& buff : BuddyWindow::BUFFS)
            {
                if (Lower(buff.name) != r.name) continue;
                bool knows = false;
                double ready = 0.0;
                for (Cooldown const& c : me.cooldowns) if (c.name == r.name) { knows = true; ready = c.readyIn; }
                if (!knows) continue;
                double lasts = 0.0;
                for (BuddyAbilityReachRow const& x : BUDDY_ABILITY_REACH) if (x.cls == r.cls && std::string(x.name) == r.name) lasts = x.lastsMs / 1000.0;
                double gain = (1.0 + buff.gives.haste) * (1.0 + buff.gives.damage);
                own.push_back({ { BuddyLockout::EffectiveCooldownMs(r.name, r.cooldownMs) / 1000.0, ready, lasts }, gain, {} });
                names.push_back(r.name);
            }
        }
        for (size_t i = 0; i < own.size(); ++i)
            for (size_t k = 0; k < own.size(); ++k)
                if (i != k)
                {
                    uint32_t ms = BuddyLockout::BlocksOwnMs(names[i].c_str(), names[k].c_str());
                    if (ms > 0) own[i].blocks.push_back({ k, ms / 1000.0 });
                }
        if (own.empty()) return out;
        std::vector<BuddyPlan::Plan> plans = BuddyPlan::LineUp(own, OpenWindows(s, memory), base.left, BuddyPlan::Ending(base.kind));
        for (size_t i = 0; i < own.size(); ++i) out[names[i]] = plans[i].weight;
        return out;
    }

    inline std::map<std::string, double> Leans(Snapshot const& s, Memory const& memory, int b, double goldPerHour, BuddySeat::Seats const* seats = nullptr,
                                               std::map<std::string, int>* targets = nullptr)
    {
        std::map<std::string, double> out;
        if (b < 0 || static_cast<size_t>(b) >= s.party.size()) return out;
        Verdict base = Step(s, memory);
        Member const& me = s.party[b];
        int worst = -1;
        for (size_t i = 0; i < s.party.size(); ++i)
            if (base.shortOf[i] > 0.0 && (worst < 0 || base.shortOf[i] > base.shortOf[worst])) worst = static_cast<int>(i);
        if (worst < 0)
            for (size_t i = 0; i < s.party.size(); ++i)
                if (base.incoming[i] > 0.0 && (worst < 0 || base.timeToDeath[i] < base.timeToDeath[worst])) worst = static_cast<int>(i);
        double partyDealt = 0.0;
        for (Member const& m : s.party) partyDealt += memory.DealtPerSecond(m.id, s.t);
        double myShare = partyDealt > 0.0 ? memory.DealtPerSecond(me.id, s.t) / partyDealt : 0.0;

        for (BuddyAbilityReachRow const& r : BUDDY_ABILITY_REACH)
        {
            if (r.cls != me.cls) continue;
            Answer a;
            int target = r.self ? b : (worst >= 0 ? worst : b);
            std::vector<BuddyMarks::AuraEffect> effects = BuddyMarks::OfAbility(r.cls, r.name);
            if (!effects.empty() && r.lastsMs > 0) a.extras = { { target, effects, r.lastsMs / 1000.0 } };
            if (r.heal == -1) { a.healed = target; a.heal = me.maxHealth; }
            else if (r.heal > 0) { a.healed = target; a.heal = r.heal; }
            for (BuddyWindow::Buff const& buff : BuddyWindow::BUFFS)
                if (Lower(buff.name) == r.name)
                {
                    BuddyMarks::Modifiers gives = BuddyMarks::Of(effects);
                    auto gainOf = [&](Member const& m) {
                        double haste = m.resourceKind == 0 ? gives.castHaste : gives.attackHaste;
                        return haste * gives.dealt - 1.0;
                    };
                    auto shareOf = [&](Member const& m) { return partyDealt > 0.0 ? memory.DealtPerSecond(m.id, s.t) / partyDealt : 0.0; };
                    double add = 0.0;
                    if (r.area) for (Member const& m : s.party) add += shareOf(m) * gainOf(m);
                    else if (r.self) add = myShare * gainOf(me);
                    else
                        for (size_t k = 0; k < s.party.size(); ++k)
                        {
                            double gives = shareOf(s.party[k]) * gainOf(s.party[k]);
                            if (s.party[k].health > 0 && gives > add)
                            {
                                add = gives;
                                if (targets) (*targets)[r.name] = int(k);
                            }
                        }
                    a.burstFactor = 1.0 + add;
                    a.burstLasts  = r.lastsMs / 1000.0;
                    a.extras.clear();
                }
            double lean = Lean(Judge(s, memory, a, goldPerHour, &base), base);
            BuddyMarks::Modifiers m = BuddyMarks::Of(effects);
            bool healing = r.heal != 0 || m.tickHealing > 0 || m.absorb > 0;
            if (seats && healing)
            {
                if (BuddySeat::Has(seats->dry, b)) lean = 0.05;
                else if (!BuddySeat::Has(seats->holders, b) && BuddySeat::CanHeal(me) && !seats->short_) lean = 1.0;
            }
            out[r.name] = lean;
        }
        if (me.cls == 11)
        {
            double mana = 0.0;
            for (BuddyWindow::Buff const& buff : BuddyWindow::BUFFS) if (Lower(buff.name) == "innervate") mana = buff.gives.regen * me.baseMana;
            double enemies = 0.0;
            for (Enemy const& e : s.enemies) enemies += e.health;
            double pace = base.leftKnown && base.left > 0 ? enemies / base.left : 0.0;
            Score best{ 0.0, 0.0 };
            int bestAt = -1;
            for (size_t k = 0; mana > 0 && k < s.party.size(); ++k)
            {
                Member const& m = s.party[k];
                double falling = memory.ResourceFalling(m.id, s.t);
                if (m.health <= 0 || m.resourceKind != 0 || falling <= 0.0) continue;
                double outAt = m.resource / falling;
                if (outAt >= base.left) continue;
                double extra = std::min(mana / falling, base.left - outAt);
                Score sc{ std::min(base.shortfall, memory.HealingPerSecond(m.id, s.t) * extra),
                          pace > 0 ? memory.DealtPerSecond(m.id, s.t) * extra / pace : 0.0 };
                if (bestAt < 0 || Better(sc, best)) { best = sc; bestAt = int(k); }
            }
            if (bestAt >= 0)
            {
                out["innervate"] = Lean(best, base);
                if (targets) (*targets)["innervate"] = bestAt;
            }
        }
        for (auto const& [name, weight] : PlanWeights(s, memory, b, base))
        {
            auto it = out.find(name);
            out[name] = (it == out.end() ? 1.0 : it->second) * weight;
        }
        if (base.strongest >= 0)
            for (BuddyThreatLeverRow const& r : BUDDY_THREAT_LEVERS)
                if (r.cls == me.cls && BuddyLockout::Lists(r.kinds, "taunt"))
                {
                    Answer a;
                    a.taunter = b;
                    a.enemy = base.strongest;
                    out[r.name] = Lean(Judge(s, memory, a, goldPerHour, &base), base);
                }
        return out;
    }
}

#endif
