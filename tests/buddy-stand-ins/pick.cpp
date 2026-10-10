// pick.cpp - checks the stand-in maker's choices (issue 617t1) against the
// plan: a tree that takes the role, wholly; the race and class drawn only
// from the side's pairs that can take the role; a kept stand-in used before
// a new one is made, never one above the level, never one in use; the
// pre-made build chosen by where its points lie.
#include "buddies_stand_ins_pick.h"
#include <cstdio>
#include <set>

static int passed = 0, failed = 0;
static void check(bool ok, char const* what)
{
    if (ok) ++passed;
    else { ++failed; std::printf("  FAIL: %s\n", what); }
}

// the module's own role table (buddies_roles.cpp, TREE_ROLES), as bits:
// 1 damage, 2 tank, 4 healer
static constexpr uint8_t D = 1, T = 2, H = 4;
static uint8_t const TREE_ROLES[12][3] = {
    { D, D, D }, { D, D, T }, { H, T, D }, { D, D, D }, { D, D, D }, { H, H, D },
    { T, D, D }, { D, D, H }, { D, D, D }, { D, D, D }, { D, D, D }, { D, uint8_t(T | D), H },
};
// the game's race and class pairs (3.3.5a playercreateinfo)
static std::vector<std::pair<uint8_t, uint8_t>> const PAIRS = {
    {1,1},{1,2},{1,4},{1,5},{1,6},{1,8},{1,9},          // human
    {2,1},{2,3},{2,4},{2,6},{2,7},{2,9},                // orc
    {3,1},{3,2},{3,3},{3,4},{3,5},{3,6},                // dwarf
    {4,1},{4,3},{4,4},{4,5},{4,6},{4,11},               // night elf
    {5,1},{5,4},{5,5},{5,6},{5,8},{5,9},                // undead
    {6,1},{6,3},{6,6},{6,7},{6,11},                     // tauren
    {7,1},{7,4},{7,6},{7,8},{7,9},                      // gnome
    {8,1},{8,3},{8,4},{8,5},{8,6},{8,7},{8,8},          // troll
    {10,2},{10,3},{10,4},{10,5},{10,6},{10,8},{10,9},   // blood elf
    {11,1},{11,2},{11,3},{11,5},{11,6},{11,7},{11,8},   // draenei
};
static uint8_t SideOf(uint8_t race) { return (race == 2 || race == 5 || race == 6 || race == 8 || race == 10) ? 1 : 0; }
static void RolesOf(uint8_t cls, uint8_t (&out)[3]) { for (int t = 0; t < 3; ++t) out[t] = TREE_ROLES[cls][t]; }

int main()
{
    using namespace BuddyStandIn;

    // trees for a role, with the module's roles: bit = 1 << role (0 damage, 1 tank, 2 healer)
    check(TreesForRole(TREE_ROLES[1], 1) == std::vector<uint8_t>{ 2 }, "a warrior tanks only in protection");
    check(TreesForRole(TREE_ROLES[5], 2) == std::vector<uint8_t>{ 0, 1 }, "a priest heals in discipline or holy");
    check(TreesForRole(TREE_ROLES[11], 1) == std::vector<uint8_t>{ 1 }, "a druid tanks in feral");
    check(TreesForRole(TREE_ROLES[11], 0) == std::vector<uint8_t>{ 0, 1 }, "a druid does damage in balance or feral");
    check(TreesForRole(TREE_ROLES[8], 1).empty(), "a mage can't tank");
    check(ShapeForTree(0) == 8 && ShapeForTree(1) == 9 && ShapeForTree(2) == 10, "all points in one tree are shapes 8, 9, 10");

    // pairs for a side and role
    auto hordeHealers = PairsFor(PAIRS, 1, 2, SideOf, RolesOf);
    std::set<uint8_t> classes;
    bool allHorde = true;
    for (auto const& p : hordeHealers) { classes.insert(p.second); allHorde = allHorde && SideOf(p.first) == 1; }
    check(allHorde, "Horde healers are all of Horde races");
    check(classes == std::set<uint8_t>{ 2, 5, 7, 11 }, "Horde healers are paladins, priests, shamans and druids");
    auto allianceTanks = PairsFor(PAIRS, 0, 1, SideOf, RolesOf);
    std::set<uint8_t> tankClasses;
    for (auto const& p : allianceTanks) tankClasses.insert(p.second);
    check(tankClasses == std::set<uint8_t>{ 1, 2, 6, 11 }, "Alliance tanks are warriors, paladins, death knights and druids");
    bool noBloodElfWarrior = true;
    for (auto const& p : PairsFor(PAIRS, 1, 1, SideOf, RolesOf))
        noBloodElfWarrior = noBloodElfWarrior && !(p.first == 10 && p.second == 1);
    check(noBloodElfWarrior, "only the game's pairs: no blood elf warrior (yet)");

    // the kept one to use
    std::vector<Kept> kept = {
        { 101, 1, 1, 1, 20, false },                    // human warrior tank, 20
        { 102, 1, 1, 1, 30, false },                    // the same, 30
        { 103, 1, 1, 1, 30, false },                    // the same, 30, made later
        { 104, 1, 1, 1, 40, false },                    // the same, 40
        { 105, 1, 1, 1, 35, true  },                    // the same, 35, in use
        { 106, 1, 1, 0, 35, false },                    // a damage warrior
    };
    check(PickKept(kept, 1, 1, 1, 35) == 102, "at 35: the highest kept at or below (30), the older of two");
    check(PickKept(kept, 1, 1, 1, 40) == 104, "at 40: the one at 40");
    check(PickKept(kept, 1, 1, 1, 19) == 0, "at 19: none (its level never goes down), so a new one");
    check(PickKept(kept, 1, 1, 0, 35) == 106, "a damage warrior is kept apart from the tanks");
    check(PickKept(kept, 3, 1, 1, 35) == 0, "a dwarf is not a human");
    kept[1].inWorld = true;
    check(PickKept(kept, 1, 1, 1, 35) == 103, "one in use is passed over");

    // the pre-made build by where its points lie
    std::vector<std::vector<uint8_t>> builds = {
        { 0, 0, 0, 1, 1 },                              // 0: mostly the first tree
        {},                                             // 1: no build under this number
        { 2, 2, 2, 2, 0 },                              // 2: mostly the third
        { 2, 2, 2, 2, 2 },                              // 3: wholly the third
    };
    check(PickSpecForTree(builds, 2) == 3, "the third tree: the build wholly in it");
    check(PickSpecForTree(builds, 0) == 0, "the first tree: the build mostly in it");
    check(PickSpecForTree(builds, 1) == 0, "the second tree: the only build with points there");
    check(PickSpecForTree({ {}, {} }, 0) == -1, "no builds: none");

    std::printf("%s: %d of %d checks passed\n", failed ? "FAILED" : "ok", passed, passed + failed);
    return failed ? 1 : 0;
}
