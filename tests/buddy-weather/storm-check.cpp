
#include "buddies_weather_storm.h"
#include "buddies_av_valley_data.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <map>

using namespace BuddyStorm;

static int passed = 0, failed = 0;
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}


int main(int argc, char** argv)
{
    Valley v = ValleyFromCells(AV_VALLEY_CELLS, sizeof(AV_VALLEY_CELLS) / sizeof(AV_VALLEY_CELLS[0]));
    if (argc == 4 && std::strcmp(argv[1], "--path") == 0)
    {
        std::mt19937 rng(unsigned(std::strtoul(argv[2], nullptr, 10)));
        Storm s = Start(v);
        long seconds = std::strtol(argv[3], nullptr, 10);
        for (long t = 0; t < seconds; ++t)
        {
            Step(s, v, rng);
            if (t % 10 == 0) std::printf("{\"s\":%ld,\"x\":%.1f,\"y\":%.1f}\n", t, s.x, s.y);
        }
        return 0;
    }

    std::mt19937 rng(42);
    Storm s = Start(v);
    bool inside = v.Inside(s.x, s.y);
    double turned = 0.0;
    int minX = 1 << 30, maxX = -(1 << 30);
    for (auto const& c : v.cells) { minX = std::min(minX, c.first); maxX = std::max(maxX, c.first); }
    int bands = 10;
    std::vector<double> timeIn(size_t(bands), 0.0), cellsIn(size_t(bands), 0.0);
    for (auto const& c : v.cells) cellsIn[size_t(std::min(bands - 1, (c.first - minX) * bands / (maxX - minX + 1)))] += 1.0;
    for (int t = 0; t < 86400; ++t)
    {
        float before = s.heading;
        Step(s, v, rng);
        inside = inside && v.Inside(s.x, s.y);
        turned += std::fabs(s.heading - before);
        auto c = Valley::Cell(s.x, s.y);
        timeIn[size_t(std::min(bands - 1, (c.first - minX) * bands / (maxX - minX + 1)))] += 1.0;
    }
    check(inside, "over a simulated day the storm never leaves the valley");
    double cellTotal = 0.0;
    for (double c : cellsIn) cellTotal += c;
    double worst = 1e9, best = 0.0;
    for (int b = 0; b < bands; ++b)
    {
        double share = (timeIn[size_t(b)] / 86400.0) / (cellsIn[size_t(b)] / cellTotal);
        worst = std::min(worst, share);
        best = std::max(best, share);
    }
    std::printf("  time over each tenth of the valley, against its share of the ground: %.2f to %.2f\n", worst, best);
    check(worst > 0.33 && best < 3.0, "every tenth of the valley has had its share of storm, within a factor of three");
    std::printf("  turning: %.3f radians a second on average\n", turned / 86400.0);
    check(turned / 86400.0 < 0.2, "it turns gently, not in jitters");

    auto near = Reach(59.0f), mid = Reach(75.0f), far = Reach(91.0f);
    check(near.first == 86 && near.second == 1.0f, "at 59 yards: the downpour with thunder, full strength");
    check(mid.first == 5 && mid.second < 1.0f && mid.second > 0.2f, "at 75 yards: the rain thinning");
    check(far.first == 0, "at 91 yards: the shared sky");

    std::printf("%s: %d of %d checks passed\n", failed ? "FAILED" : "ok", passed, passed + failed);
    return failed ? 1 : 0;
}
