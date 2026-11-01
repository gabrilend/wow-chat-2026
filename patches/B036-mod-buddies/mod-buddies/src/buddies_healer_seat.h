/*
 * buddies_healer_seat.h - the party's healer's seat (issue 625i): who
 * holds it, when it runs out of mana and when it is ready again; plain
 * arithmetic over the forward pass's snapshot, apart from the server, so it
 * can be tested on its own (tests/buddy-healer-seat/,
 * scripts/test-buddy-healer-seat).
 *
 * For a general audience: one member heals the party. While it can, the
 * others do their own jobs. When it falls, or runs out of mana ("oom"),
 * the others with some healing in them step in, and the healer itself stops
 * casting so its mana comes back, until it says "ready". The owner,
 * 2026-10-30: "The person with at least some healing talents and the most
 * mana is designated as the new "healer" at least until the fight is
 * over"; "If the healer's mana is ever low, we can prioritize other healing
 * talented classes to throw out heals as well to help supplement"; "They
 * should say "oom" or "mana" in an appropriate chat channel, and others can
 * use that as the signal to jump in."
 *
 * The lines, from the game's own numbers (no fraction set by hand):
 *   oom    its mana is less than its cheapest heal costs: it can't heal
 *   ready  its mana covers its own healing for the rest of the fight (its
 *          healing a second over the minute, times the fight's time left,
 *          at its cheapest heal's health a mana), or it is full; until then,
 *          once oom it stays oom (no flicker at the line)
 */

#ifndef MOD_BUDDIES_HEALER_SEAT_H
#define MOD_BUDDIES_HEALER_SEAT_H

#include "buddies_ability_data.h"
#include "buddies_fight_state.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>

namespace BuddySeat
{
    using namespace BuddyFightState;

    // {{{ HealingTree
    // Whether a class's talent tree (0, 1 or 2, the game's tab order) is a
    // healing tree: a priest's Discipline and Holy, a paladin's Holy, a
    // shaman's and a druid's Restoration.
    inline bool HealingTree(uint8_t cls, uint8_t tab)
    {
        switch (cls)
        {
            case 5:  return tab == 0 || tab == 1;      // priest
            case 2:  return tab == 0;                   // paladin
            case 7:  return tab == 2;                   // shaman
            case 11: return tab == 2;                   // druid
            default: return false;
        }
    }
    // }}}

    // {{{ CheapestHeal
    // A class's cheapest direct heal (from the generated tables: its reach
    // row's heal, its ability row's cost), in mana for this member (a cost
    // in percent of base mana worked out on its base mana): its cost and the
    // health it heals (before bonuses). Cost 0: the class has none.
    struct Heal { double cost = 0, amount = 0; };
    inline Heal CheapestHeal(uint8_t cls, double baseMana)
    {
        Heal best;
        for (BuddyAbilityReachRow const& r : BUDDY_ABILITY_REACH)
        {
            if (r.cls != cls || r.heal <= 0) continue;
            for (BuddyAbilityRow const& a : BUDDY_ABILITIES)
                if (a.cls == cls && std::strcmp(a.name, r.name) == 0 && a.power == 0)
                {
                    double cost = a.costPct > 0 ? a.costPct * baseMana / 100.0 : double(a.cost);
                    if (cost > 0 && (best.cost == 0 || cost < best.cost)) best = { cost, double(r.heal) };
                }
        }
        return best;
    }
    // }}}

    // {{{ HealerShare
    // How much of a healer a member is (the owner, 2026-10-31: "we can count
    // 1/3rd specs as 1/3rd of a healer, off-specs (2/3rd and 1/3rd with
    // 1/3rd being healing talents) as 1/3rd of a healer, and full specs and
    // main specs (2/3rd healing talents 1/3rd non healing tree) as 1 whole
    // healer"): the share of its talent points in healing trees, to the
    // nearest third: two thirds or all, 1; a third, 1/3; none, 0. With no
    // points spent yet (a low level), a healer by role counts 1.
    inline double HealerShare(Member const& m)
    {
        if (m.talentPoints == 0) return m.role == 2 ? 1.0 : 0.0;
        double thirds = std::round(3.0 * m.healPoints / m.talentPoints);
        return thirds >= 2.0 ? 1.0 : thirds >= 1.0 ? 1.0 / 3.0 : 0.0;
    }
    // }}}

    // {{{ Seats
    // The party's healer seats:
    //   want     how much healing the party keeps: its healers' shares when
    //            the fight began (the owner: "we should have as many healers
    //            as we had when the fight started")
    //   holders  who heals now (members' indexes)
    //   dry      members out of mana, recovering (they stop casting heals
    //            until ready again, and may hold a seat again then)
    //   short_   the seats couldn't be filled back to `want`: everyone able
    //            to heal leans in
    struct Seats { double want = -1; std::vector<int> holders, dry; bool short_ = false; };

    // whether a member can heal at all: points in a healing tree (or a
    // healer by role before any points), alive
    inline bool CanHeal(Member const& m) { return (m.healPoints > 0 || (m.talentPoints == 0 && m.role == 2)) && m.health > 0; }

    // out of mana: less than its cheapest heal costs
    inline bool Oom(Member const& m)
    {
        Heal h = CheapestHeal(m.cls, m.baseMana);
        return m.resourceKind == 0 && h.cost > 0 && m.resource < h.cost;
    }

    // ready again (out of the dry ones): its mana covers its own healing for
    // the rest of the fight, at its cheapest heal's health a mana, or full
    inline double ReadyAt(Member const& m, double healingPerSecond, double left)
    {
        Heal h = CheapestHeal(m.cls, m.baseMana);
        if (h.cost <= 0 || h.amount <= 0) return m.maxResource;
        double need = healingPerSecond * left / (h.amount / h.cost);
        return std::min(m.maxResource, std::max(h.cost, need));
    }

    inline bool Has(std::vector<int> const& v, int i) { return std::find(v.begin(), v.end(), i) != v.end(); }

    // The seats now, from the last (`was`, want -1 at a fight's start). A
    // holder keeps its seat until it runs out of mana or dies (the owner:
    // "we should only update this role when the current healer runs out of
    // mana or dies"); then members able to heal, not dry, whole healers
    // before thirds and the most mana among equals, are seated until the
    // shares are back to what the fight began with.
    // Members are indexed as in the snapshot (the party's order is the
    // server's, the same from step to step within a fight).
    inline Seats Now(Snapshot const& s, Memory const& memory, Seats was, double left)
    {
        Seats seats;
        seats.want = was.want;
        if (seats.want < 0)
        {
            // the fight's start: the healers by role, and what they come to
            seats.want = 0;
            for (size_t i = 0; i < s.party.size(); ++i)
                if (s.party[i].role == 2 && s.party[i].health > 0) { seats.holders.push_back(int(i)); seats.want += HealerShare(s.party[i]); }
        }
        else
            for (int i : was.holders)
                if (i >= 0 && size_t(i) < s.party.size() && s.party[i].health > 0) seats.holders.push_back(i);
        // the dry stay dry until ready; a holder newly out of mana joins them
        for (int i : was.dry)
            if (i >= 0 && size_t(i) < s.party.size() && s.party[i].health > 0 &&
                s.party[i].resource < ReadyAt(s.party[i], memory.HealingPerSecond(s.party[i].id, s.t), left)) seats.dry.push_back(i);
        for (auto it = seats.holders.begin(); it != seats.holders.end(); )
            if (Oom(s.party[*it])) { seats.dry.push_back(*it); it = seats.holders.erase(it); }
            else ++it;
        // filled back to what the fight began with
        auto have = [&]() { double h = 0; for (int i : seats.holders) h += HealerShare(s.party[i]); return h; };
        while (have() + 1e-9 < seats.want)
        {
            int best = -1;
            for (size_t i = 0; i < s.party.size(); ++i)
            {
                Member const& m = s.party[i];
                if (!CanHeal(m) || HealerShare(m) <= 0 || Has(seats.holders, int(i)) || Has(seats.dry, int(i)) || Oom(m)) continue;
                // whole healers before thirds (a third seated first would
                // leave the party short while a whole healer stood by), then
                // the most mana among equal shares
                double share = HealerShare(m), bestShare = best < 0 ? -1 : HealerShare(s.party[best]);
                if (best < 0 || share > bestShare + 1e-9 ||
                    (std::fabs(share - bestShare) <= 1e-9 && m.resource > s.party[best].resource)) best = int(i);
            }
            if (best < 0) { seats.short_ = true; break; }
            seats.holders.push_back(best);
        }
        return seats;
    }
    // }}}
}

#endif
