/*
 * buddies_loot_turns.h - whose turn it is to open a corpse, so that everyone
 * in a group with buddies loots about as often (issue 617j1, loot turns);
 * plain data and arithmetic, apart from the server, so it can be tested on
 * its own (tests/buddy-loot-turns/, scripts/test-buddy-loot-turns).
 *
 * For a general audience: the owner, 2026-10-03: buddies "should loot
 * corpses to try and maintain a proper ratio so that everyone has looted
 * roughly the same amount of times." And 2026-10-28: "Yes, the owner takes
 * turns too. If there are multiple clans represented in a group or raid,
 * they each will be treated as a monolith for the loot distribution. If
 * there are only coins on an item ... then that doesn't count as their loot
 * since it's split amongst everyone anyway." And: "Buddies don't pass."
 *
 * So the group keeps two counts of corpses opened: per clan (a player and
 * its buddies; a player without buddies is a clan of one) and per member.
 * A corpse is the turn of the clan that has opened fewest, and within it
 * of the member that has opened fewest; ties go to the nearest. A player's
 * turn is held for them WAIT seconds (a buddy "waits a moment for its
 * owner's turn"); after that the corpse goes to whoever is next as if the
 * players weren't there. A corpse with only coins on it is no one's turn
 * (anyone may open it, B062 shares the coins) and isn't counted. The
 * counts start again when the group changes (a buddy joining or leaving
 * by distance, 617c2). Under the free-for-all rule a buddy sets when it
 * forms a group, the turns decide every corpse; a player who leads may set
 * another rule, and then the game's own turns and rolls stand.
 * The numbers are the agent's calls (2026-11-06), to be judged in game.
 */

#ifndef MOD_BUDDIES_LOOT_TURNS_H
#define MOD_BUDDIES_LOOT_TURNS_H

#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <map>
#include <set>
#include <string>
#include <vector>

namespace BuddyLootTurns
{
    // {{{ the numbers
    //   WAIT  seconds a player's turn at a corpse is held for them before
    //         the corpse goes to the next (question 3: "How long does a
    //         buddy wait for its owner to take their turn?")
    constexpr double WAIT = 10.0;
    // }}}

    // {{{ Looter
    // One member who could open the corpse now (alive, near enough, allowed
    // by the game's rule: the server leaves out the others): its id, its
    // clan (the player's id for the player and its buddies), whether it is
    // a player, and how far it stands from the corpse.
    struct Looter { uint64_t id, clan; bool player; float yards; };
    // }}}

    // {{{ Corpse
    // A corpse the group may open: whether only coins are on it, and how
    // many seconds it has lain lootable.
    struct Corpse { bool coinsOnly; double age; };
    // }}}

    // {{{ Turns
    struct Turns
    {
        std::map<uint64_t, int> byClan, byMember;   // corpses opened
        std::set<uint64_t>      group;              // who the counts are for

        // {{{ Regroup
        // The group as it is now (every member's id): a different group
        // starts the counts again.
        void Regroup(std::vector<uint64_t> const& members)
        {
            std::set<uint64_t> now(members.begin(), members.end());
            if (now == group) return;
            group = now;
            byClan.clear();
            byMember.clear();
        }
        // }}}

        // {{{ Opened
        // A member opened a corpse (its loot window opened on it): counted
        // for it and its clan, unless only coins were on it.
        void Opened(uint64_t id, uint64_t clan, bool coinsOnly)
        {
            if (coinsOnly) return;
            ++byClan[clan];
            ++byMember[id];
        }
        // }}}

        // {{{ Count
        int Count(std::map<uint64_t, int> const& m, uint64_t key) const
        {
            auto it = m.find(key);
            return it == m.end() ? 0 : it->second;
        }
        // }}}

        // {{{ Whose
        // Whose turn the corpse is: 0 for no one's (only coins, or nobody
        // could open it). Among those who could open it (players left out
        // once it has lain WAIT seconds), the clan with the fewest opened,
        // then its member with the fewest; ties to the nearer (the nearest
        // member of each clan, for clans).
        uint64_t Whose(std::vector<Looter> const& looters, Corpse const& c) const
        {
            if (c.coinsOnly) return 0;
            bool waited = c.age >= WAIT;
            Looter const* best = nullptr;
            float bestClanNear = 0.0f;
            for (Looter const& l : looters)
            {
                if (waited && l.player) continue;
                float clanNear = l.yards;                         // the clan's nearest member that may open it
                for (Looter const& o : looters)
                    if (o.clan == l.clan && !(waited && o.player)) clanNear = std::min(clanNear, o.yards);
                if (!best) { best = &l; bestClanNear = clanNear; continue; }
                int lc = Count(byClan, l.clan), bc = Count(byClan, best->clan);
                if (lc != bc) { if (lc < bc) { best = &l; bestClanNear = clanNear; } continue; }
                if (l.clan != best->clan)
                {
                    if (clanNear < bestClanNear) { best = &l; bestClanNear = clanNear; }
                    continue;
                }
                int lm = Count(byMember, l.id), bm = Count(byMember, best->id);
                if (lm < bm || (lm == bm && l.yards < best->yards)) { best = &l; bestClanNear = clanNear; }
            }
            return best ? best->id : 0;
        }
        // }}}

        // {{{ Mine
        // What a buddy's loot behaviour asks before it walks to a corpse:
        // may I open it? Yes when it is its turn; a corpse of coins only is
        // anyone's who could open it.
        bool Mine(uint64_t me, std::vector<Looter> const& looters, Corpse const& c) const
        {
            uint64_t who = Whose(looters, c);
            if (who != 0)     return who == me;
            if (!c.coinsOnly) return false;
            for (Looter const& l : looters) if (l.id == me) return true;
            return false;
        }
        // }}}

        // {{{ Trace
        // One line for the trace log: whose turn, and the counts.
        std::string Trace(std::vector<Looter> const& looters, Corpse const& c) const
        {
            uint64_t who = Whose(looters, c);
            if (who == 0) return c.coinsOnly ? "loot turn: coins only, anyone's" : "loot turn: no one can open it";
            uint64_t clan = 0;
            for (Looter const& l : looters) if (l.id == who) clan = l.clan;
            char line[160];
            std::snprintf(line, sizeof line, "loot turn: %llu (clan %llu opened %d, it %d)",
                          (unsigned long long)who, (unsigned long long)clan, Count(byClan, clan), Count(byMember, who));
            return line;
        }
        // }}}
    };
    // }}}
}

#endif
