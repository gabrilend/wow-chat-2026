// next-quest-check.cpp - checks the next best quest and the buddies' lean
// toward it (roam/buddy_next_quest_core.h) against issue 617e18, with no
// server. Built and run by scripts/test-buddy-next-quest. Each check prints
// "ok" or "FAIL" and what it held; the exit status is the number of
// failures.
//
// A made-up starting valley, laid out in yards round the abbey steps at
// (0, 0), east along +x and north along +y: wolves to the east, a kobold
// mine north-east, a vineyard south, thieves west for later levels.

#include "buddy_next_quest_core.h"
#include <cstdio>
#include <string>

using namespace BuddyNextQuest;

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

static bool Near(float a, float b, float within = 0.01f) { return std::fabs(a - b) <= within; }
static bool Same(Point const& a, Point const& b) { return Yards(a, b) < 0.01f; }

static Quest Make(uint32_t id, char const* name, int level, int minLevel, uint32_t prev, Point giver, Point ender,
                  std::vector<Point> objectives = {})
{
    Quest q;
    q.id = id; q.name = name; q.level = level; q.minLevel = minLevel; q.prev = prev;
    q.giver = giver; q.ender = ender; q.objectives = objectives;
    return q;
}

// {{{ The valley
static std::vector<Quest> Valley()
{
    return {
        Make(1, "A Threat Within",          1, 1, 0, {   0.0f,   0.0f, 0.0f }, {  30.0f,   0.0f, 0.0f }),
        Make(2, "Wolves Across the Border", 2, 1, 0, {  30.0f,   0.0f, 0.0f }, {  30.0f,   0.0f, 0.0f },
             { { 120.0f, 10.0f, 0.0f }, { 140.0f, -20.0f, 0.0f } }),
        Make(3, "Kobold Camp Cleanup",      3, 1, 1, {  30.0f,   0.0f, 0.0f }, {  30.0f,   0.0f, 0.0f },
             { { 100.0f, 150.0f, 0.0f } }),
        Make(4, "Investigate Echo Ridge",   4, 2, 3, {  30.0f,   0.0f, 0.0f }, {  30.0f,   0.0f, 0.0f },
             { { 110.0f, 170.0f, 0.0f } }),
        Make(5, "Brotherhood of Thieves",   7, 6, 0, { -40.0f,   0.0f, 0.0f }, { -40.0f,   0.0f, 0.0f },
             { { -300.0f, 0.0f, 0.0f } }),
        Make(6, "Grape Manifest",           5, 4, 0, {   0.0f, -90.0f, 0.0f }, {   0.0f, -90.0f, 0.0f }),
    };
}
static std::vector<Place> Places()
{
    return {
        { "Northshire Vineyards",   {   0.0f, -200.0f, 0.0f }, true  },
        { "Echo Ridge Mine",        { 110.0f,  170.0f, 0.0f }, false },
        { "Goldshire",              {   0.0f, -600.0f, 0.0f }, false },
    };
}
// }}}

int main()
{
    Settings s;
    std::vector<Quest> const valley = Valley();
    std::vector<Place> const places = Places();

    // {{{ a fresh character on the abbey steps
    {
        Owner o; o.level = 1;
        Hint h = Choose(o, valley, places, s);
        check(h.kind == Kind::Take && h.quest == 1 && Same(h.target, valley[0].giver),
              "a fresh character: the quest to take at their feet, its giver the target");
        check(Words(h, o, valley, places) == "There's work: \"A Threat Within\", 0 yards east.",
              "said in words: there's work, the quest's name, the yards and the way");
    }
    // }}}

    // {{{ who may take what
    {
        Owner o; o.level = 1; o.done = { 1 }; o.at = { 30.0f, 0.0f, 0.0f };
        Hint h = Choose(o, valley, places, s);
        // 2 and 3 both stand at (30, 0); 3 follows 1 (done): the chain bonus
        check(h.kind == Kind::Take && h.quest == 3, "the quest before it done: the chain's next quest wins over a fresh one beside it");
        Owner p = o; p.done = {}; p.level = 3;  // 1 not done: 3 not takeable, though it would win
        Hint g = Choose(p, valley, places, s);
        check(g.quest == 2, "the quest before it not done: not offered");
        Owner q = o; q.done = { 1, 2, 3 }; q.level = 1;   // 4 needs level 2, the rest more
        Hint k = Choose(q, valley, places, s);
        check(k.kind == Kind::Explore, "under a quest's minimum level: not offered");
        q.level = 2;
        k = Choose(q, valley, places, s);
        check(k.kind == Kind::Take && k.quest == 4, "at its minimum level: offered");
        Owner r = o; r.done = { 1, 2, 3, 4 }; r.level = 5; r.at = { 0.0f, 0.0f, 0.0f };
        Hint m = Choose(r, valley, places, s);
        check(m.kind == Kind::Take && m.quest == 6, "done quests are not offered again");
        check(Near(m.cost, 90.0f + 0.0f), "the cost: the walk plus nothing for a quest at the owner's level");
        r.level = 7;
        m = Choose(r, valley, places, s);
        // 5: 40 yards + 0 levels = 40; 6: 90 + 2*60 = 210
        check(m.quest == 5 && Near(m.cost, 40.0f), "level fit and walk together: the nearer quest at the owner's level");
        r.level = 6;
        m = Choose(r, valley, places, s);
        // 5: 40 + 60 = 100; 6: 90 + 60 = 150
        check(m.quest == 5 && Near(m.cost, 100.0f), "a level off costs yardsPerLevel of walking");
    }
    // }}}

    // {{{ the log comes first
    {
        Owner o; o.level = 2; o.done = { 1 }; o.at = { 30.0f, 0.0f, 0.0f };
        o.log = { { 2, { { 140.0f, -20.0f, 0.0f }, { 120.0f, 10.0f, 0.0f } } } };
        Hint h = Choose(o, valley, places, s);
        check(h.kind == Kind::Log && h.quest == 2, "a quest in the log wins over a giver at the owner's feet");
        check(Same(h.target, { 120.0f, 10.0f, 0.0f }), "its target: the nearest objective left");
        o.log[0].left = { { 140.0f, -20.0f, 0.0f } };
        h = Choose(o, valley, places, s);
        check(Same(h.target, { 140.0f, -20.0f, 0.0f }), "an objective done drops out: the next one left");
        check(Words(h, o, valley, places) == "For \"Wolves Across the Border\", 112 yards east.",
              "said in words: for the quest, the yards and the way");
        o.log[0].left.clear();
        o.at = { 140.0f, -20.0f, 0.0f };
        h = Choose(o, valley, places, s);
        check(h.kind == Kind::HandIn && h.quest == 2 && Same(h.target, valley[1].ender),
              "every objective done: hand it in, its ender the target");
        check(Words(h, o, valley, places) == "To hand in \"Wolves Across the Border\", 112 yards west.",
              "said in words: to hand it in");
        // a quest the log names but the tables don't: passed over
        o.log = { { 999, { { 1.0f, 1.0f, 0.0f } } } };
        h = Choose(o, valley, places, s);
        check(h.kind == Kind::Take, "a log quest the tables don't know: passed over, the quests to take next");
    }
    // }}}

    // {{{ gray
    {
        Owner o; o.level = 8; o.done = { 1, 2, 3, 4 }; o.at = { 0.0f, 0.0f, 0.0f };
        // 6 is level 5: 3 under; grayBelow 6 -> gray at 2 or less
        Hint h = Choose(o, valley, places, s);
        check(h.quest == 5, "level 8: the thieves (7) over the grapes (5) though the grapes are no farther than double");
        o.level = 11;           // 6 at level 5: 6 under -> gray; 5 at level 7: 4 under -> not
        o.log = { { 6, { { 0.0f, -95.0f, 0.0f } } } };
        h = Choose(o, valley, places, s);
        check(h.kind == Kind::Take && h.quest == 5, "a gray quest in the log is passed over");
        o.log.clear();
        o.level = 10;           // 6: 5 under -> not gray
        o.done = { 1, 2, 3, 4, 5 };
        h = Choose(o, valley, places, s);
        check(h.quest == 6, "one level short of gray: still offered");
        o.level = 11;
        h = Choose(o, valley, places, s);
        check(h.kind == Kind::Explore, "gray at grayBelow levels under: nothing to take, time to move on");
    }
    // }}}

    // {{{ objectives together, a route through several
    {
        // two lone givers 100 yards out, east and west; three other givers near the west one
        std::vector<Quest> qs = {
            Make(10, "East",  3, 1, 0, {  100.0f,  0.0f, 0.0f }, {}),
            Make(11, "West",  3, 1, 0, { -105.0f,  0.0f, 0.0f }, {}),
            Make(12, "W1",    3, 1, 0, { -150.0f,  0.0f, 0.0f }, {}),
            Make(13, "W2",    3, 1, 0, { -105.0f, 50.0f, 0.0f }, {}),
            Make(14, "Far",   3, 1, 0, { -105.0f, -61.0f, 0.0f }, {}),
        };
        Owner o; o.level = 3;
        Hint h = Choose(o, qs, {}, s);
        // West: 105 - 2*40 = 25 (W1 at 45, W2 at 50; Far at 61 is out); W2: 116.0 - 40*1 ... East: 100
        check(h.quest == 11 && Near(h.cost, 25.0f), "a giver with others close by wins over a nearer lone one");
        Settings t = s; t.togetherRadius = 44.0f;
        h = Choose(o, qs, {}, t);
        check(h.quest == 10, "the others farther than togetherRadius: the nearer lone giver");
        Owner p = o; p.level = 20;    // every quest gray: their givers lie together with nothing
        std::vector<Quest> mix = qs;
        mix[2].level = 20; mix[3].level = 20;  // W1, W2 not gray now; West, East and Far gray
        mix[3].giver = { -105.0f, 70.0f, 0.0f };
        h = Choose(p, mix, {}, s);
        // W1: 150, West (gray) 45 away not counted; W2: 126.2, nothing near
        check(h.quest == 13 && Near(h.cost, 126.2f, 0.1f), "gray quests' givers don't lie together with anything");
        // objectives in the log count too
        Owner l = o; l.log = { { 10, { { 100.0f, 0.0f, 0.0f } } } };
        std::vector<Quest> lq = qs;
        lq.push_back(Make(15, "LogWest", 3, 1, 0, {}, {}, { { -110.0f, 0.0f, 0.0f } }));
        l.log.push_back({ 15, { { -110.0f, 0.0f, 0.0f } } });
        h = Choose(l, lq, {}, s);
        // LogWest: 110 - 40*3 (West giver 5, W1 40, W2 51) = -10; East: 100
        check(h.kind == Kind::Log && h.quest == 15, "givers near a log objective make it worth more");
    }
    // }}}

    // {{{ what lies together: what's left to do, and only that
    {
        // Here's objective 100 yards east, There's 110 west: Here wins, unless something lies by There's
        std::vector<Quest> qs = {
            Make(40, "Here",   3, 1, 0,  { -100.0f,  0.0f, 0.0f }, {}),
            Make(41, "There",  3, 1, 0,  {  500.0f,  0.0f, 0.0f }, {}),
            Make(42, "Shut",   3, 1, 99, { -110.0f,  30.0f, 0.0f }, {}),
            Make(43, "Done",   3, 1, 0,  { -110.0f, -30.0f, 0.0f }, {}),
            Make(44, "Ready",  6, 1, 0,  {  500.0f,  0.0f, 0.0f }, { -110.0f, 40.0f, 0.0f }),
        };
        Owner o; o.level = 3; o.done = { 43 };
        o.log = { { 40, { { 100.0f, 0.0f, 0.0f } } }, { 41, { { -110.0f, 0.0f, 0.0f } } } };
        Hint h = Choose(o, qs, {}, s);
        check(h.quest == 40 && Near(h.cost, 100.0f),
              "givers of quests in the log, done, or not yet open don't lie together with anything");
        Owner p = o; p.log[1].left.push_back({ -120.0f, 0.0f, 0.0f });
        h = Choose(p, qs, {}, s);
        check(h.quest == 41 && Near(h.cost, 70.0f), "another objective left by the target makes it worth more");
        Owner q = o; q.log.push_back({ 44, {} });
        h = Choose(q, qs, {}, s);
        // Ready itself: 116.3 + 180 - 40 (There's objective) = 256.3
        check(h.quest == 41 && Near(h.cost, 70.0f), "a quest to hand in: its ender lies together with the rest");
    }
    // }}}

    // {{{ chains already started
    {
        std::vector<Quest> qs = {
            Make(20, "Fresh", 3, 1, 0,  {  50.0f, 0.0f, 0.0f }, {}),
            Make(21, "Next",  3, 1, 19, { -140.0f, 0.0f, 0.0f }, {}),
        };
        Owner o; o.level = 3; o.done = { 19 };
        Hint h = Choose(o, qs, {}, s);
        check(h.quest == 21 && Near(h.cost, 40.0f), "a chain started is worth chainYards less walking");
        qs[1].giver.x = -160.0f;
        h = Choose(o, qs, {}, s);
        check(h.quest == 20, "but not more than that");
    }
    // }}}

    // {{{ time to move on
    {
        Owner o; o.level = 5; o.done = { 1, 2, 3, 4, 5, 6 };
        Hint h = Choose(o, valley, places, s);
        check(h.kind == Kind::Explore && h.place == 1 && Same(h.target, places[1].at),
              "nothing left to do: the nearest place not explored (the vineyards, nearer, are explored)");
        check(Words(h, o, valley, places) == "Somewhere new: Echo Ridge Mine, 202 yards north-east.",
              "said in words: somewhere new");
        std::vector<Place> seen = places;
        seen[1].explored = true;
        h = Choose(o, valley, seen, s);
        check(h.kind == Kind::Explore && h.place == 2, "that one explored too: the next nearest");
        seen[2].explored = true;
        h = Choose(o, valley, seen, s);
        check(h.kind == Kind::None, "everything done and explored: no hint");
        check(Words(h, o, valley, seen) == "Nowhere I know of.", "no hint in words");
        Owner p; p.level = 5; p.log = { { 6, { { 0.0f, -95.0f, 0.0f } } } }; p.done = { 1, 2, 3, 4, 5 };
        h = Choose(p, valley, places, s);
        check(h.kind == Kind::Log, "unexplored places wait while there are quests");
    }
    // }}}

    // {{{ the way, in words and radians
    {
        check(std::string(Compass(0.0f)) == "east" && std::string(Compass(1.5708f)) == "north"
              && std::string(Compass(-1.5708f)) == "south" && std::string(Compass(3.14159f)) == "west"
              && std::string(Compass(-3.14159f)) == "west",
              "east, north, south, west");
        check(std::string(Compass(0.7854f)) == "north-east" && std::string(Compass(-2.3562f)) == "south-west"
              && std::string(Compass(0.39f)) == "east" && std::string(Compass(0.40f)) == "north-east"
              && std::string(Compass(-0.7854f)) == "south-east" && std::string(Compass(2.3562f)) == "north-west",
              "the points between, split half way");
        Owner o; o.at = { 10.0f, 10.0f, 0.0f }; o.level = 3;
        std::vector<Quest> qs = { Make(30, "Up", 3, 1, 0, { 10.0f, 60.0f, 0.0f }, {}) };
        Hint h = Choose(o, qs, {}, s);
        check(Near(h.bearing, 1.5708f, 0.001f), "the bearing: from the owner to the target");
    }
    // }}}

    // {{{ the lean
    {
        BuddyFollow::Settings fs;
        Point owner = { 50.0f, 20.0f, 0.0f };
        for (float bearing : { 0.0f, 1.2f, -2.5f, 3.0f })
        {
            std::vector<BuddyFollow::Place> ps = LeanPlaces(owner, bearing, 5, fs);
            bool ahead = ps.size() == 5;
            for (BuddyFollow::Place const& p : ps)
            {
                float dx = p.at.x - owner.x, dy = p.at.y - owner.y;
                float along = dx * std::cos(bearing) + dy * std::sin(bearing);
                ahead = ahead && along >= fs.nearBack - 0.01f && along <= fs.farBack + 0.01f;
            }
            check(ahead, "every buddy on the owner's side facing the target, the arc's own distance out");
        }
        std::vector<BuddyFollow::Place> ps = LeanPlaces(owner, 0.0f, 3, fs);
        check(ps.size() == 3 && Near(ps[1].at.x, owner.x + fs.farBack) && Near(ps[1].at.y, owner.y)
              && Near(std::fabs(ps[0].at.y - owner.y), fs.side) && Near(ps[0].at.y - owner.y, owner.y - ps[2].at.y)
              && Near(ps[0].at.x, owner.x + fs.nearBack) && Near(ps[2].at.x, owner.x + fs.nearBack),
              "the arc's middle on the line to the target, its ends to each side");
        check(Near(ps[1].facing, 3.14159f, 0.001f) || Near(ps[1].facing, -3.14159f, 0.001f),
              "standing so, they face the owner as on any arc");
    }
    // }}}

    // {{{ beckon
    {
        Point owner = { 10.0f, 10.0f, 3.0f };
        Point b = Beckon(owner, { 10.0f, 110.0f, 9.0f }, s);
        check(Same(b, { 10.0f, 15.0f, 3.0f }) && Near(b.z, 3.0f),
              "standing still: one buddy steps beckonYards toward the target, at the owner's height (the server finds the ground)");
        b = Beckon(owner, { 13.0f, 10.0f, 3.0f }, s);
        check(Same(b, { 13.0f, 10.0f, 3.0f }), "a target nearer than that: no farther than the target");
        b = Beckon(owner, owner, s);
        check(Same(b, owner), "the target at the owner's feet: stays");
    }
    // }}}

    std::printf("%d of %d checks held\n", checks - failures, checks);
    return failures;
}
