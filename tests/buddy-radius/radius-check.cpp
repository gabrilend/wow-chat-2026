// radius-check.cpp - checks the radius triggers and the bulletin board
// (roam/buddy_radius_core.h) against issue 165, with no server. Built and
// run by scripts/test-buddy-radius. Each check prints "ok" or "FAIL" and
// what it held; the exit status is the number of failures.

#include "buddy_radius_core.h"
#include <cstdio>

using namespace BuddyRadius;

static int failures = 0, checks = 0;

// {{{ check
static void check(bool ok, char const* what)
{
    ++checks;
    if (!ok)
        ++failures;
    std::printf("%s %s\n", ok ? "ok  " : "FAIL", what);
}
// }}}

static Unit U(uint64_t id, uint32_t kinds, float x, uint32_t entry = 0) { Unit u; u.id = id; u.kinds = kinds; u.entry = entry; u.x = x; return u; }

int main()
{
    // {{{ enters, leaves, the slack band
    Registry r;
    Trigger t;
    t.name = "door"; t.radius = 10.0f; t.slack = 3.0f;
    t.onEnter = { { "open", { "1", "2" } }, { "greet", {} } };
    t.onLeave = { { "close", {} } };
    r.Add(1, t);
    auto c = r.Moved(1, 0, 0, 0, U(7, UNIT_PLAYER, 20.0f));
    check(c.empty(), "a unit outside the radius: nothing");
    c = r.Moved(1, 0, 0, 0, U(7, UNIT_PLAYER, 9.0f));
    check(c.size() == 2 && c[0].action.name == "open" && c[0].action.args.size() == 2 && c[1].action.name == "greet",
          "entering runs the enter actions in order, with their arguments");
    c = r.Moved(1, 0, 0, 0, U(7, UNIT_PLAYER, 5.0f));
    check(c.empty(), "moving about inside: nothing more");
    c = r.Moved(1, 0, 0, 0, U(7, UNIT_PLAYER, 12.0f));
    check(c.empty(), "in the slack band (10 to 13 yards): still inside, nothing");
    c = r.Moved(1, 0, 0, 0, U(7, UNIT_PLAYER, 9.5f));
    check(c.empty(), "back in from the slack band: no second enter");
    c = r.Moved(1, 0, 0, 0, U(7, UNIT_PLAYER, 14.0f));
    check(c.size() == 1 && c[0].action.name == "close", "past radius plus slack: leaves");
    c = r.Moved(1, 0, 0, 0, U(7, UNIT_PLAYER, 9.0f));
    check(c.size() == 2, "and coming in again enters again");
    // }}}

    // {{{ filters, the owner itself, removal
    Registry f;
    Trigger only;
    only.name = "wolves"; only.radius = 10.0f;
    only.filter.kinds = UNIT_CREATURE; only.filter.entry = 299;
    only.onEnter = { { "howl", {} } };
    f.Add(1, only);
    check(f.Moved(1, 0, 0, 0, U(8, UNIT_PLAYER, 1.0f)).empty(), "a player fails a creatures-only filter");
    check(f.Moved(1, 0, 0, 0, U(9, UNIT_CREATURE, 1.0f, 300)).empty(), "a creature of another entry fails it");
    check(f.Moved(1, 0, 0, 0, U(10, UNIT_CREATURE, 1.0f, 299)).size() == 1, "the named entry passes");
    check(f.Moved(1, 0, 0, 0, U(1, UNIT_CREATURE, 0.0f, 299)).empty(), "the owner moving near itself fires nothing");
    f.Remove(1, "wolves");
    check(!f.Moved(1, 0, 0, 0, U(11, UNIT_CREATURE, 1.0f, 299)).size(), "a trigger removed by name fires no more");
    Registry g;
    g.Add(5, BoardTrigger());
    g.Moved(5, 0, 0, 0, U(12, UNIT_PLAYER, 1.0f));
    g.Remove(5);
    check(!g.Has(5) && g.Inside(5, "bulletin board") == 0, "an object leaving the world takes its triggers and their inside-sets");
    Registry h;
    h.Add(5, BoardTrigger());
    h.Moved(5, 0, 0, 0, U(13, UNIT_PLAYER, 1.0f));
    h.Forget(13);
    check(h.Inside(5, "bulletin board") == 0, "a unit leaving the world leaves every inside-set, silently");
    // }}}

    // {{{ the bulletin board
    Registry br;
    Board board;
    br.Add(100, BoardTrigger());
    auto run = [&](std::vector<Call> const& calls, Unit const& u, uint64_t now) {
        for (Call const& call : calls)
        {
            if (call.action.name == "pin")   board.PinUnit(u, now);
            if (call.action.name == "unpin") board.Unpin(u.id);
        }
    };
    Unit boar = U(20, UNIT_CREATURE, 60.0f, 3098), boss = U(21, UNIT_CREATURE, 50.0f, 11520);
    run(br.Moved(100, 0, 0, 0, boar), boar, 1000);
    check(board.Has(20), "a boar within 70 yards goes up on the board");
    boar.x = 74.0f;
    run(br.Moved(100, 0, 0, 0, boar), boar, 2000);
    check(board.Has(20), "at 74 yards (in the 5-yard slack) it stays");
    boar.x = 80.0f;
    run(br.Moved(100, 0, 0, 0, boar), boar, 3000);
    check(!board.Has(20), "at 80 yards it comes down");
    run(br.Moved(100, 0, 0, 0, boss), boss, 4000);
    board.BossFight(21, true);
    boss.x = 200.0f;
    run(br.Moved(100, 0, 0, 0, boss), boss, 5000);
    check(board.Has(21), "a boss in its fight stays on the board whatever its distance");
    board.BossFight(21, false);
    board.Unpin(21);
    check(!board.Has(21), "the fight over, it comes down when out of range");
    board.FlagCarrier(22, true, 40.0f, 0, 0, 6000);
    board.FlagCarrier(22, false, 0, 0, 0, 7000);
    Pin const* p = board.Get(22);
    check(p && p->x == 40.0f && p->seenMs == 6000, "a flag carrier out of sight keeps its last seen place");
    run(br.Moved(100, 0, 0, 0, U(22, UNIT_PLAYER, 300.0f)), U(22, UNIT_PLAYER, 300.0f), 8000);
    board.Unpin(22);
    check(board.Has(22), "a flag carrier is always on the board, far or near");
    board.FlagDropped(22);
    board.Unpin(22);
    check(!board.Has(22), "once the flag is dropped it is an ordinary pin");
    // }}}

    std::printf("%d checks, %d failed\n", checks, failures);
    return failures;
}
