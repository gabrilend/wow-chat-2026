/*
 * buddies_forward_pass.h - one step of the fight's forward pass (issue
 * 625n): a snapshot and its minute of events in, the party's verdict out;
 * and an answer tried as if given, its worth the shortfall it takes away.
 * Plain arithmetic, apart from the server, so it can be tested on its own
 * (tests/buddy-forward-pass/, scripts/test-buddy-forward-pass).
 *
 * For a general audience: the owner, 2026-10-30: "each moment we supply
 * the entire state and it updates the fight curve according to the new,
 * and extended, and desired, state." This is that moment. From the
 * snapshot (buddies_fight_state.h) and the running sums of the last minute
 * it works out, in order: whom each enemy attacks (layer 3); how hard each
 * enemy really hits, before the armour and marks of whoever it is hitting;
 * how much of that each character lets through (its armour against the
 * enemy's level, its marks, by the enemy's mix of physical and magic:
 * layer 2); the healing reaching each; how long the fight has left (layer
 * 1); each character's fight curve and the party's shortfall (layer 4);
 * and which tank should hold the hardest-hitting enemy (layer 5). Then an
 * answer (a buff or debuff it would put on someone, a heal now, a taunt) is
 * tried on a copy, and its worth is how much shortfall it takes away
 * (layer 6, the first of its measures; the rest, the desired state's kill
 * time and gold cost, come next).
 */

#ifndef MOD_BUDDIES_FORWARD_PASS_H
#define MOD_BUDDIES_FORWARD_PASS_H

#include "buddies_curve.h"
#include "buddies_fight_state.h"
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

    // {{{ Verdict
    // What a step works out, per party:
    //   kind        boss or trash (FightKind)
    //   left, leftKnown  the fight's time left, and whether the enemies'
    //               health is falling at all (when not, `left` is the
    //               horizon: three of the longest regularly used cooldown
    //               among the party's classes, 625h)
    //   attention   per enemy: the member it attacks (an index; -1 no one)
    //   hits        per enemy: its damage a second before armour and marks
    //   incoming    per member: what the enemies attacking it deal a second,
    //               before its armour and marks
    //   taken       per member: the share of that it lets through, armour
    //               only (its marks ride on its curve, ending when they do)
    //   healing     per member: healing a second reaching it, before its
    //               healing marks (they too ride on its curve)
    //   timeToDeath per member, holding what it holds now
    //   shortfall   the party's, in health: 0 is a curve toward victory
    //   shortOf     per member: its own part of it
    //   strongest   the hardest-hitting enemy (an index; -1 none)
    //   tanks       which tank should hold it, and when it changes hands
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
    // }}}

    // {{{ Extra
    // A mark tried on a member that isn't on it yet (an answer's buff or
    // debuff): its effects, for `lasts` seconds.
    struct Extra { int member; std::vector<BuddyMarks::AuraEffect> effects; double lasts; };
    // }}}

    // {{{ helpers
    inline int IndexOf(Snapshot const& s, uint64_t id)
    {
        for (size_t i = 0; i < s.party.size(); ++i) if (s.party[i].id == id) return static_cast<int>(i);
        return -1;
    }
    // the share of an enemy's damage a member lets through by armour alone:
    // the physical part reduced by its armour against the enemy's level
    inline double ArmourTaken(Member const& m, Enemy const& e, double physicalShare)
    {
        return physicalShare * (1.0 - BuddyMarks::ArmourReduction(m.armour, e.level)) + (1.0 - physicalShare);
    }
    // what a member's marks multiply an enemy's damage by, by its mix
    inline double MarksTaken(BuddyMarks::Modifiers const& mod, double physicalShare)
    {
        return BuddyMarks::Taken(mod, physicalShare);
    }
    // the horizon while the end can't be seen: from the party's classes'
    // cooldowns (the game's table), the regularly used ones (625h)
    inline double PartyHorizon(Snapshot const& s)
    {
        std::vector<double> cds;
        for (Member const& m : s.party)
            for (BuddyAbilityRow const& r : BUDDY_ABILITIES)
                if (r.cls == m.cls && r.cooldownMs >= 90000) cds.push_back(r.cooldownMs / 1000.0);
        return BuddyFight::Horizon(cds);
    }
    // }}}

    // {{{ OpenWindows
    // The empowering buffs on the party now, as windows on its damage (the
    // fight's end comes sooner while they last): each buff in the window
    // table (buddies_window_buffs.h: Bloodlust, Heroism, Avenging Wrath ...)
    // on a member, its haste and damage on that member's share of the
    // party's damage over the minute, for the time it has left. Bloodlust on
    // all five counts whole; Avenging Wrath on one paladin, its share.
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
    // }}}

    // {{{ Step
    // One step: the snapshot and the minute in, the verdict out. `extras`:
    // marks tried on top (Try); they change the curves, not what the minute
    // says has happened.
    inline Verdict Step(Snapshot const& s, Memory const& memory, std::vector<Extra> const& extras = {})
    {
        Verdict v;
        size_t P = s.party.size(), E = s.enemies.size();
        v.kind = FightKind(s);

        // layer 1: the fight's time left
        double enemiesHealth = 0;
        for (Enemy const& e : s.enemies) enemiesHealth += e.health;
        std::vector<BuddyPlan::Window> windows = s.windows, open = OpenWindows(s, memory);
        windows.insert(windows.end(), open.begin(), open.end());
        double under = 1.0;
        for (BuddyPlan::Window const& w : open) under *= w.factor;          // they were on while the fall was measured
        BuddyFight::Guess g = memory.FightLeft(s.t, enemiesHealth, windows, 10.0, under);
        v.leftKnown = g.known;
        v.left = g.known ? g.seconds : PartyHorizon(s);

        // layer 2: each member's marks as they stand (what the minute was
        // made under) and as tried (with the extras)
        std::vector<BuddyMarks::Modifiers> now(P), tried(P);
        for (size_t i = 0; i < P; ++i) now[i] = tried[i] = ModifiersOf(s.party[i].marks);
        for (Extra const& x : extras)
            if (x.member >= 0 && static_cast<size_t>(x.member) < P)
                for (BuddyMarks::AuraEffect const& e : x.effects) BuddyMarks::Fold(tried[x.member], e);

        // layer 3: whom each enemy attacks, from its threat list
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

        // each enemy's real damage: what it dealt over the minute, given back
        // what its target's armour and marks took off it. The target is the
        // one it was hitting (the snapshot's), not the one it would turn to:
        // the minute was dealt to that one (a tried taunt changes whom it
        // attacks next, not what it has done)
        v.hits.assign(E, 0.0);
        for (size_t e = 0; e < E; ++e)
        {
            double dealt = memory.DealtPerSecond(s.enemies[e].id, s.t);
            double phys  = memory.PhysicalShare(s.enemies[e].id);
            int on = IndexOf(s, s.enemies[e].attacking);
            double through = on < 0 ? 1.0 : ArmourTaken(s.party[on], s.enemies[e], phys) * MarksTaken(now[on], phys);
            v.hits[e] = through > 0.05 ? dealt / through : dealt;               // nearly all stopped (a shield): read as dealt
        }

        // per member: what comes at it, what gets through by armour, the
        // healing reaching it before its healing marks
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
            if (sum <= 0.0 && v.strongest >= 0)                                // not attacked: as if it held the hardest hitter
            {
                double p = memory.PhysicalShare(s.enemies[v.strongest].id);
                v.taken[i] = ArmourTaken(s.party[i], s.enemies[v.strongest], p);
                physOn[i] = p;
            }
            else if (sum > 0.0) { v.incoming[i] = sum; v.taken[i] = armourSum / sum; physOn[i] = phys / sum; }
            double healed = std::max(0.05, now[i].healed);
            v.healing[i] = memory.HealedPerSecond(s.party[i].id, s.t) / healed;
        }
        // the healing follows the attention (the healers heal whoever is
        // being hit): an enemy now attacking someone other than whom it was
        // hitting over the minute (a tried taunt) takes its part of the old
        // target's healing to the new one, by its share of what the old one
        // was taking
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

        // layer 4: each member's fight curve, marks riding on it until they
        // wear off (the ones tried for their own length)
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
                    // a shield soaks as health would, on top of full health: it
                    // raises the ceiling too (healing could then refill its part,
                    // which a shield doesn't: a small kindness, noted)
                    holders[i].health    += one.absorb;
                    holders[i].maxHealth += one.absorb;
                }
        }
        // the enemies' casts in progress: each a lump of damage landing on
        // its target when the cast ends, cut by the marks on it then
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

        // layer 5: which tank should hold the hardest hitter
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
    // }}}

    // {{{ Try
    // An answer tried as if given, on a copy: a buff or debuff it would put
    // on a member (`extras`), a heal landing now (`heal` on `healed`), a
    // taunt by `taunter` on `enemy` (its threat raised to the top, its
    // taunt on). Its worth is how much shortfall it takes away, in health:
    // the first measure of the desired state (625n).
    // Also: `burst`, the party's damage multiplied by `burstFactor` for
    // `burstLasts` seconds from now (Bloodlust: its window factor for the
    // party, buddies_window_buffs.h), which brings the fight's end sooner;
    // `gold`, what the answer uses up, in copper, at whatever price the buddy
    // could get another for (a potion, a reagent; the owner: "for whatever
    // price the bot can acquire it by.").
    struct Answer
    {
        std::vector<Extra> extras;
        int healed = -1; double heal = 0;
        int taunter = -1, enemy = -1;
        double burstFactor = 1.0, burstLasts = 0.0;
        double gold = 0.0;
    };
    // `known`: the verdict without the answer, when already worked out (it
    // is the same for every answer tried at one moment: Leans passes it)
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
    // }}}

    // {{{ Judge
    // An answer against the desired state (625n: "besides victory, bots
    // prefer lower gold cost (use fewer consumables) and faster time (3
    // minute kill instead of 4)"), in two parts compared in order:
    //   health   the shortfall it takes away: victory first
    //   seconds  the group's time it saves: seconds off the fight's end (only
    //            when the end can be seen), less the gold it uses up as the
    //            seconds the group takes to earn that much back, at its own
    //            gold per hour (`goldPerHour`, copper an hour, measured by
    //            the server from what the group has gained; 0, nothing earned
    //            yet: gold can't be weighed and counts nothing)
    // So a potion that keeps someone alive is always drunk (health first),
    // and one drunk when no one is dying costs time for nothing.
    struct Score { double health, seconds; };
    inline Score Judge(Snapshot const& s, Memory const& memory, Answer const& a, double goldPerHour, Verdict const* known = nullptr)
    {
        Verdict before = known ? *known : Step(s, memory), after;
        double health = Worth(s, memory, a, &after, &before);
        double seconds = (before.leftKnown && after.leftKnown) ? before.left - after.left : 0.0;
        if (a.gold > 0.0 && goldPerHour > 0.0) seconds -= a.gold / (goldPerHour / 3600.0);
        return { health, seconds };
    }
    // {{{ Lean
    // An answer's lean for the draw, from its score: the share of the gap
    // from extended to desired it closes. The gap is first the party's
    // shortfall (health), then the fight's time left (seconds): an answer
    // that saves health leans by the share of the shortfall it takes away
    // (all of it: x2); one that saves none leans by the share of the time
    // left it saves (an end 12 seconds sooner in a minute: x1.2), or away by
    // the share it costs (a potion for nothing). Nothing either way: 1, the
    // bot module's own order. Never below 0.05, so no answer is shut out.
    inline double Lean(Score const& sc, Verdict const& base)
    {
        double f = sc.health > 1.0 ? 1.0 + sc.health / std::max(1.0, base.shortfall)
                                   : 1.0 + sc.seconds / std::max(1.0, base.left);
        return std::max(0.05, f);
    }
    // }}}

    // Better: whether `x` comes before `y`: more health first, then more
    // seconds (a hair's difference in health counts as none).
    inline bool Better(Score const& x, Score const& y)
    {
        if (std::fabs(x.health - y.health) > 1.0) return x.health > y.health;
        return x.seconds > y.seconds + 1e-6;
    }
    // }}}

    inline std::string Lower(char const* s) { std::string o(s); std::transform(o.begin(), o.end(), o.begin(), [](unsigned char c) { return std::tolower(c); }); return o; }

    // {{{ PlanWeights
    // One buddy's long empowering cooldowns (a cooldown of 90 seconds or
    // more, in the window table: Avenging Wrath, Icy Veins, Arcane Power,
    // Bloodlust ...) that it knows (the snapshot's cooldowns list them), lined
    // up by the cooldown timeline (625f, LineUp): each
    // planned on the longer of its cooldown and its lockout on itself, ready
    // when the snapshot says (now, if it isn't waiting), lasting its aura's
    // time, multiplying the buddy's worth by its haste and damage; the
    // lockouts between them as blocks; the windows open now as outside
    // windows; over the fight's time left, ending as a boss or trash fight
    // ends. Out: each one's weight (1: use it now; less: holding is better).
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
                if (!knows) continue;                                          // not learned: nothing planned round it
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
    // }}}

    // {{{ Leans
    // Every answer one buddy (`b`, a member's index) could give now, tried
    // and leaned (issue 625n, layer 6), by its abilities' names in lower case
    // as the bot module names its casts. From the game's tables (the
    // generated BUDDY_ABILITY_REACH, BUDDY_ABILITY_AURAS, BUDDY_THREAT_LEVERS
    // and the window buffs):
    //   a mark or heal that reaches only its caster on the buddy itself; one
    //   that reaches another on whoever falls furthest short (no one short:
    //   whoever's curve ends soonest among those attacked; no one attacked:
    //   the buddy itself);
    //   a heal of -1, the caster's whole health (Lay on Hands);
    //   a taunt on the hardest hitter;
    //   an empowering buff (Bloodlust, Avenging Wrath) as a burst: its haste
    //   and damage on the party's damage when it reaches others, on the
    //   buddy's own share of the party's damage when only itself.
    // Abilities that answer none of these aren't listed (the draw leaves
    // them at 1). Heals are counted before the caster's healing bonuses, so
    // they lean a little less than they will land: noted, not yet read.
    inline std::map<std::string, double> Leans(Snapshot const& s, Memory const& memory, int b, double goldPerHour)
    {
        std::map<std::string, double> out;
        if (b < 0 || static_cast<size_t>(b) >= s.party.size()) return out;
        Verdict base = Step(s, memory);
        Member const& me = s.party[b];
        // whom an answer that reaches another goes to: whoever falls
        // furthest short (a healer about to take a big cast counts, hit or
        // not); no one short, whoever's curve ends soonest among those hit
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
                    double g = (1.0 + buff.gives.haste) * (1.0 + buff.gives.damage);
                    a.burstFactor = r.self ? 1.0 + myShare * (g - 1.0) : g;
                    a.burstLasts  = r.lastsMs / 1000.0;
                }
            out[r.name] = Lean(Judge(s, memory, a, goldPerHour, &base), base);
        }
        // the long empowering cooldowns, through the cooldown timeline (625f):
        // each one's lean times its weight, how much worse using it now is
        // than its best plan (held for a window, or lined up with the
        // buddy's others, the lockouts between them counted)
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
    // }}}
}

#endif
