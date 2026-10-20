#include "buddies_stand_ins_pick.h"
#include <cstdio>
#include <set>
#include <string>

static int passed = 0, failed = 0;
static void check(bool ok, char const* what)
{
    if (ok) ++passed;
    else { ++failed; std::printf("  FAIL: %s\n", what); }
}

static std::vector<std::pair<uint8_t, uint8_t>> const PAIRS = {
    {1,1},{1,2},{1,4},{1,5},{1,6},{1,8},{1,9},
    {2,1},{2,3},{2,4},{2,6},{2,7},{2,9},
    {3,1},{3,2},{3,3},{3,4},{3,5},{3,6},
    {4,1},{4,3},{4,4},{4,5},{4,6},{4,11},
    {5,1},{5,4},{5,5},{5,6},{5,8},{5,9},
    {6,1},{6,3},{6,6},{6,7},{6,11},
    {7,1},{7,4},{7,6},{7,8},{7,9},
    {8,1},{8,3},{8,4},{8,5},{8,6},{8,7},{8,8},
    {10,2},{10,3},{10,4},{10,5},{10,6},{10,8},{10,9},
    {11,1},{11,2},{11,3},{11,5},{11,6},{11,7},{11,8},
};
static uint8_t SideOf(uint8_t race) { return (race == 2 || race == 5 || race == 6 || race == 8 || race == 10) ? 1 : 0; }

int main(int argc, char** argv)
{
    using namespace BuddyStandIn;

    if (argc > 1 && std::string(argv[1]) == "--shapes")
    {
        char const* const names[3] = { "damage", "tank", "healer" };
        for (uint8_t cls : { 1, 2, 3, 4, 5, 6, 7, 8, 9, 11 })
            for (uint8_t shape = 1; shape <= 10; ++shape)
                std::printf("%u %u %s\n", cls, shape, names[ShapeRole(cls, shape)]);
        return 0;
    }

    check(ShapesForRole(1, 1) == std::vector<uint8_t>{ 5, 6, 10 }, "a warrior tanks in shapes 5, 6, 10 (two thirds or all protection)");
    check(ShapesForRole(2, 2) == std::vector<uint8_t>{ 1, 2, 8 }, "a paladin heals in 1, 2, 8 (two thirds or all holy; a third each is damage)");
    check(ShapesForRole(5, 0) == std::vector<uint8_t>{ 5, 6, 7, 10 }, "a priest does damage with two thirds or all in shadow, or a third in each");
    check(ShapesForRole(8, 1).empty(), "a mage can't tank");
    check(ShapesForRole(3, 0).size() == 10, "every hunter shape is damage");

    auto hordeHealers = PairsFor(PAIRS, 1, 2, SideOf);
    std::set<uint8_t> classes;
    bool allHorde = true;
    for (auto const& p : hordeHealers) { classes.insert(p.second); allHorde = allHorde && SideOf(p.first) == 1; }
    check(allHorde, "Horde healers are all of Horde races");
    check(classes == std::set<uint8_t>{ 2, 5, 7, 11 }, "Horde healers are paladins, priests, shamans and druids");
    auto allianceTanks = PairsFor(PAIRS, 0, 1, SideOf);
    std::set<uint8_t> tankClasses;
    for (auto const& p : allianceTanks) tankClasses.insert(p.second);
    check(tankClasses == std::set<uint8_t>{ 1, 2, 11 }, "Alliance tanks are warriors, paladins and druids (a buddy death knight's shapes are all damage)");
    bool noBloodElfWarrior = true;
    for (auto const& p : PairsFor(PAIRS, 1, 1, SideOf))
        noBloodElfWarrior = noBloodElfWarrior && !(p.first == 10 && p.second == 1);
    check(noBloodElfWarrior, "only the game's pairs: no blood elf warrior (yet)");

    std::vector<Kept> kept = {
        { 101, 1, 1, 1, 20, false },
        { 102, 1, 1, 1, 30, false },
        { 103, 1, 1, 1, 30, false },
        { 104, 1, 1, 1, 40, false },
        { 105, 1, 1, 1, 35, true  },
        { 106, 1, 1, 0, 35, false },
    };
    check(PickKept(kept, 1, 1, 1, 35) == 102, "at 35: the highest kept at or below (30), the older of two");
    check(PickKept(kept, 1, 1, 1, 40) == 104, "at 40: the one at 40");
    check(PickKept(kept, 1, 1, 1, 19) == 0, "at 19: none (its level never goes down), so a new one");
    check(PickKept(kept, 1, 1, 0, 35) == 106, "a damage warrior is kept apart from the tanks");
    check(PickKept(kept, 3, 1, 1, 35) == 0, "a dwarf is not a human");
    kept[1].inWorld = true;
    check(PickKept(kept, 1, 1, 1, 35) == 103, "one in use is passed over");


    std::printf("%s: %d of %d checks passed\n", failed ? "FAILED" : "ok", passed, passed + failed);
    return failed ? 1 : 0;
}
