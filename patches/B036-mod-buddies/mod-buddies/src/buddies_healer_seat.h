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

    // {{{ Seat
    // Who holds the seat and whether it is out of mana:
    //   holder  a member's index (-1: no one able)
    //   oom     the holder, out of mana, recovering (it holds the seat
    //           still, so it can say "ready"; the others help meanwhile)
    struct Seat { int holder = -1; bool oom = false; };

    // whether a member can heal at all: points in a healing tree, alive
    inline bool CanHeal(Member const& m) { return m.healPoints > 0 && m.health > 0; }

    // whether it is out of mana: less than its cheapest heal
    inline bool Oom(Member const& m)
    {
        Heal h = CheapestHeal(m.cls, m.baseMana);
        return m.resourceKind == 0 && h.cost > 0 && m.resource < h.cost;
    }

    // the mana that makes it ready again: its own healing for the rest of
    // the fight, at its cheapest heal's health a mana; full at most, one
    // heal's worth at least
    inline double ReadyAt(Member const& m, double healingPerSecond, double left)
    {
        Heal h = CheapestHeal(m.cls, m.baseMana);
        if (h.cost <= 0 || h.amount <= 0) return m.maxResource;
        double need = healingPerSecond * left / (h.amount / h.cost);
        return std::min(m.maxResource, std::max(h.cost, need));
    }

    // The seat now, from the last (`was`): the party's healer (role 2) that
    // is alive keeps it, oom or not, and is oom until ready again; with none
    // alive, the member able to heal with the most mana takes it until the
    // fight ends. `left`: the fight's time left (the forward pass's).
    inline Seat Now(Snapshot const& s, Memory const& memory, Seat was, double left)
    {
        Seat seat;
        // the healer by role, alive (the most mana among several)
        for (size_t i = 0; i < s.party.size(); ++i)
        {
            Member const& m = s.party[i];
            if (m.role == 2 && m.health > 0 && (seat.holder < 0 || m.resource > s.party[seat.holder].resource)) seat.holder = int(i);
        }
        // none: the one able to heal with the most mana
        if (seat.holder < 0)
            for (size_t i = 0; i < s.party.size(); ++i)
            {
                Member const& m = s.party[i];
                if (CanHeal(m) && (seat.holder < 0 || m.resource > s.party[seat.holder].resource)) seat.holder = int(i);
            }
        if (seat.holder < 0) return seat;
        Member const& h = s.party[seat.holder];
        bool stillOom = was.oom && was.holder == seat.holder;
        if (stillOom) seat.oom = h.resource < ReadyAt(h, memory.HealingPerSecond(h.id, s.t), left);
        else seat.oom = Oom(h);
        return seat;
    }
    // }}}
}

#endif
