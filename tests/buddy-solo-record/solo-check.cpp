
#include "buddy_solo_core.h"
#include <cstdio>

using namespace BuddySolo;

static int failures = 0, checks = 0;

static void check(bool ok, char const* what)
{
    ++checks;
    if (!ok)
        ++failures;
    std::printf("%s %s\n", ok ? "ok  " : "FAIL", what);
}

static Fight F(float h, float d, float lost, float mana, float s, float gold) { return { h, d, lost, mana, s, gold }; }

int main()
{
    Kind k = KIND_COUNT;
    check(KindOf(1, k) && k == KIND_WARRIOR, "unit class 1 is a warrior's kind");
    check(KindOf(8, k) && k == KIND_MAGE,    "unit class 8 (a spellcaster) is a mage's kind");
    check(KindOf(2, k) && k == KIND_PALADIN && KindOf(4, k) && k == KIND_ROGUE, "2 a paladin's, 4 a rogue's");
    check(!KindOf(3, k), "any other value is no kind (the caller logs it)");

    Records r;
    check(r.Won(KIND_WARRIOR, F(1000, 30, 400, 200, 20, 0)), "the first win of a kind becomes its record");
    check(!r.Won(KIND_WARRIOR, F(2000, 50, 300, 250, 25, 0)), "more health and dps but less health lost: the record stands");
    check(r.best[KIND_WARRIOR].foeHealth == 1000.0f, "the record is still the first fight");
    check(r.Won(KIND_WARRIOR, F(1500, 40, 500, 300, 25, 50)), "more in every number: it replaces the record");
    check(!r.Won(KIND_WARRIOR, F(1500, 40, 500, 300, 25, 50)), "the very same fight again is not more: the record stands");
    check(!r.has[KIND_MAGE], "kinds are kept apart: no mage record from warrior fights");

    check(r.CanTake(KIND_WARRIOR, 1400, 35, 0), "alone, a warrior-kind foe within the record: it can take it");
    check(!r.CanTake(KIND_WARRIOR, 1600, 35, 0), "alone, more health than the record: it can't");
    check(r.CanTake(KIND_WARRIOR, 4000, 100, 3), "with 3 allies, three times the record: it can");
    check(!r.CanTake(KIND_WARRIOR, 4600, 100, 3), "with 3 allies, more than three times: it can't");
    check(!r.CanTake(KIND_MAGE, 10, 1, 0), "no record of a kind: never fought one alone, so no");

    r.Forget();
    check(!r.has[KIND_WARRIOR] && !r.CanTake(KIND_WARRIOR, 10, 1, 0), "forgotten (Sargobras set the level): no record, no courage");
    Records s;
    s.standIn = true;
    check(!s.Won(KIND_ROGUE, F(500, 20, 100, 0, 10, 0)) && !s.has[KIND_ROGUE], "a stand-in keeps no record");
    check(s.CanTake(KIND_MAGE, 1e9f, 1e9f, 0), "a stand-in is never afraid");

    std::printf("%d checks, %d failed\n", checks, failures);
    return failures;
}
