// turns-check.cpp - checks buddies_loot_turns.h (issue 617j1, loot turns):
// whose turn a corpse is, clans as one block each, the owner taking turns
// too, coins counting for no one, a player's turn held a moment, and the
// counts starting again with a new group. Built and run by
// scripts/test-buddy-loot-turns; each check prints "ok" or "FAILED".

#include "buddies_loot_turns.h"

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <tuple>

using namespace BuddyLootTurns;

static int passed = 0, failed = 0;
// {{{ check
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}
// }}}

// {{{ Referee
// Written from the issue, not the code: among those who may open it (no
// players once it has waited), the least by (clan's count, the clan's
// nearest member, the member's count, its own distance), first in the list
// on a whole tie.
static uint64_t Referee(Turns const& t, std::vector<Looter> const& ls, Corpse const& c)
{
    if (c.coinsOnly) return 0;
    bool waited = c.age >= WAIT;
    std::tuple<int, float, int, float> best{ 1 << 30, 0.0f, 0, 0.0f };
    uint64_t who = 0;
    for (Looter const& l : ls)
    {
        if (waited && l.player) continue;
        float near = 1e30f;
        for (Looter const& o : ls) if (o.clan == l.clan && !(waited && o.player)) near = std::min(near, o.yards);
        std::tuple<int, float, int, float> key{ t.Count(t.byClan, l.clan), near, t.Count(t.byMember, l.id), l.yards };
        if (who == 0 || key < best) { best = key; who = l.id; }
    }
    return who;
}
// }}}

static double rnd(unsigned& s) { s = s * 1103515245u + 12345u; return double((s >> 8) & 0xffffff) / double(0x1000000); }

int main()
{
    // {{{ one clan: the owner and three buddies
    uint64_t const OWNER = 10, B1 = 11, B2 = 12, B3 = 13;
    std::vector<Looter> clan = { { OWNER, OWNER, true, 4 }, { B1, OWNER, false, 2 }, { B2, OWNER, false, 6 }, { B3, OWNER, false, 8 } };
    Turns t; t.Regroup({ OWNER, B1, B2, B3 });
    check(t.Whose(clan, { false, 0 }) == B1, "nobody has looted: the nearest (a buddy at 2 yards)");
    t.Opened(B1, OWNER, false);
    check(t.Whose(clan, { false, 0 }) == OWNER, "then the owner, nearest of those who haven't: the owner takes turns too");
    check(!t.Mine(B1, clan, { false, 0 }) && !t.Mine(B2, clan, { false, 3 }), "a buddy doesn't open a corpse that is the owner's turn");
    check(t.Whose(clan, { false, WAIT }) == B2 && t.Mine(B2, clan, { false, WAIT }),
          "after a moment unclaimed, it goes to the next (the owner's turn held ten seconds)");
    check(t.Whose(clan, { false, 9.9 }) == OWNER && t.Whose(clan, { false, 10.0 }) == B2, "held for ten seconds exactly");
    check(t.Whose({ { OWNER, OWNER, true, 4 } }, { false, 12 }) == 0 && !t.Mine(OWNER, { { OWNER, OWNER, true, 4 } }, { false, 12 }),
          "past the wait with only players in reach: no buddy's turn (players loot as they like)");
    check(t.Whose(clan, { true, 0 }) == 0 && t.Mine(B3, clan, { true, 0 }) && t.Mine(OWNER, clan, { true, 0 }),
          "a corpse of coins only: no one's turn, anyone may open it");
    check(!t.Mine(99, clan, { true, 0 }), "...anyone who could open it, that is");
    t.Opened(B3, OWNER, true);
    check(t.Count(t.byMember, B3) == 0 && t.Count(t.byClan, OWNER) == 1, "and opening it counts for no one");
    int each[4] = { 0, 0, 0, 0 };
    Turns even; even.Regroup({ OWNER, B1, B2, B3 });
    for (int k = 0; k < 40; ++k)
    {
        uint64_t who = even.Whose(clan, { false, 0 });
        even.Opened(who, OWNER, false);
        ++each[who - OWNER];
    }
    check(each[0] == 10 && each[1] == 10 && each[2] == 10 && each[3] == 10, "forty corpses: ten each (\"roughly the same amount of times\")");
    // }}}

    // {{{ two clans: each one block
    uint64_t const P2 = 20, C1 = 21;
    std::vector<Looter> raid = clan;
    raid.push_back({ P2, P2, true, 3 });
    raid.push_back({ C1, P2, false, 9 });
    Turns r; r.Regroup({ OWNER, B1, B2, B3, P2, C1 });
    int clanA = 0, clanB = 0, p2 = 0, c1 = 0;
    for (int k = 0; k < 30; ++k)
    {
        uint64_t who = r.Whose(raid, { false, 0 });
        uint64_t of = who >= 20 ? P2 : OWNER;
        r.Opened(who, of, false);
        (of == P2 ? clanB : clanA)++;
        if (who == P2) ++p2;
        if (who == C1) ++c1;
    }
    check(clanA == 15 && clanB == 15, "two clans, five and two strong: fifteen corpses each, a clan one block");
    check(p2 == 8 && c1 == 7, "within the small clan, its two take turns");
    Turns tie; tie.Regroup({ OWNER, B1, B2, B3, P2, C1 });
    check(tie.Whose(raid, { false, 0 }) == B1, "clans level: the clan nearest the corpse, its own nearest member");
    tie.Opened(B1, OWNER, false);
    check(tie.Whose(raid, { false, 0 }) == P2, "then the other clan");
    std::vector<Looter> solo = { { P2, P2, true, 3 }, { B1, OWNER, false, 2 } };
    Turns lone; lone.Regroup({ P2, B1 });
    lone.Opened(B1, OWNER, false);
    check(lone.Whose(solo, { false, 0 }) == P2, "a player without buddies is a clan of one");
    check(lone.Whose(solo, { false, 30 }) == B1, "and their turn too is held only a moment");
    check(lone.Whose({}, { false, 0 }) == 0 && !lone.Mine(B1, {}, { false, 0 }), "nobody able to open it: no one's");
    // }}}

    // {{{ a new group
    Turns g; g.Regroup({ OWNER, B1 });
    g.Opened(B1, OWNER, false); g.Opened(B1, OWNER, false);
    g.Regroup({ B1, OWNER });
    check(g.Count(g.byMember, B1) == 2, "the same group in another order: the counts kept");
    g.Regroup({ OWNER, B1, B2 });
    check(g.byMember.empty() && g.byClan.empty(), "a buddy joins: the counts start again");
    // }}}

    // {{{ the trace
    std::string line = t.Trace(clan, { false, 0 });
    std::printf("   (%s)\n", line.c_str());
    check(line == "loot turn: 10 (clan 10 opened 1, it 0)", "the trace line names whose turn and the counts");
    check(t.Trace(clan, { true, 0 }) == "loot turn: coins only, anyone's", "and says when it is anyone's");
    // }}}

    // {{{ random groups against the referee, and fairness over a run
    unsigned seed = 617;
    int agree = 0, runs = 0, fair = 0;
    for (int run = 0; run < 400; ++run)
    {
        int clans = 1 + int(rnd(seed) * 3);
        std::vector<Looter> ls;
        std::vector<uint64_t> ids;
        for (int k = 0; k < clans; ++k)
        {
            uint64_t head = 100 * (k + 1);
            int buddies = int(rnd(seed) * 5);
            for (int b = 0; b <= buddies; ++b)
            {
                ls.push_back({ head + b, head, b == 0, float(rnd(seed) * 30) });
                ids.push_back(head + b);
            }
        }
        Turns tt; tt.Regroup(ids);
        std::map<uint64_t, int> got;
        for (int k = 0; k < 60; ++k)
        {
            for (Looter& l : ls) l.yards = float(rnd(seed) * 30);
            Corpse c{ rnd(seed) < 0.15, rnd(seed) < 0.2 ? 12.0 : 0.0 };
            ++runs;
            agree += tt.Whose(ls, c) == Referee(tt, ls, c);
            uint64_t who = tt.Whose(ls, { c.coinsOnly, 0.0 });      // the players come for their turns
            if (who == 0)
            {
                if (!c.coinsOnly) continue;
                Looter const& any = ls[size_t(rnd(seed) * ls.size()) % ls.size()];
                tt.Opened(any.id, any.clan, true);
                continue;
            }
            uint64_t clanOf = (who / 100) * 100;
            tt.Opened(who, clanOf, false);
            ++got[clanOf];
        }
        int lo = 1 << 30, hi = 0;
        for (int k = 0; k < clans; ++k) { int n = got[100 * (k + 1)]; lo = std::min(lo, n); hi = std::max(hi, n); }
        fair += hi - lo <= 1;
    }
    std::printf("   (%d of %d corpses agree with the referee; %d of 400 runs within one)\n", agree, runs, fair);
    check(agree == runs, "every corpse of 400 random groups goes where the referee says");
    check(fair == 400, "over sixty corpses, everyone coming for their turns: every clan's count within one of every other's");
    // }}}

    std::printf("%d checks, %d failed\n", passed + failed, failed);
    return failed;
}
