
#include "buddies_curve.h"
#include "buddies_marks.h"

#include <cmath>
#include <cstdio>

using namespace BuddyMarks;

static int passed = 0, failed = 0;
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}

static bool near(double a, double b, double by = 1e-6) { return std::fabs(a - b) < by; }

int main()
{
    Modifiers wall = Of(OfAbility(1, "shield wall"));
    check(near(wall.takenPhysical, 0.4) && near(wall.takenMagic, 0.4), "Shield Wall: 60% less of every kind of damage taken");
    Modifiers both = Of({ OfAbility(1, "shield wall")[0], OfAbility(5, "pain suppression")[0] });
    check(near(both.takenPhysical, 0.4 * 0.6), "with Pain Suppression too: the two multiply (0.24)");
    check(near(Of(OfAbility(1, "mortal strike")).healed, 0.5), "Mortal Strike: half the healing lands");
    Modifiers lust = Of(OfAbility(7, "bloodlust"));
    check(near(lust.attackHaste, 1.3) && near(lust.castHaste, 1.3), "Bloodlust: attacks and casts each 30% faster (its two effects, one of each)");
    check(near(Of(OfAbility(1, "hamstring")).speed, 0.5), "Hamstring: half the speed");
    check(near(Of(OfAbility(1, "thunder clap")).attackHaste, 0.9), "Thunder Clap on an enemy: its attacks 10% slower");
    check(near(Of(OfAbility(9, "corruption")).tickDamage, 60), "Corruption: 180 every 3 seconds, 60 a second");
    check(near(Of(OfAbility(11, "rejuvenation")).tickHealing, 338.0 / 3.0), "Rejuvenation: 338 every 3 seconds");
    check(near(Of(OfAbility(5, "power word: shield")).absorb, 2230), "Power Word: Shield soaks 2230");
    check(near(Of(OfAbility(11, "faerie fire")).armourShare, 0.95), "Faerie Fire: 5% of the armour gone");

    check(near(Of({ { 87, 10, 127, 0, 3 } }).takenMagic, 1.3), "a debuff of +10% damage taken at 3 stacks: +30%");
    check(near(Of({ { 3, 100, 0, 2000, 2 } }).tickDamage, 100), "a ticking debuff of 100 every 2 seconds at 2 stacks: 100 a second");
    check(near(Of({ { 999, 50, 0, 0, 1 } }).takenPhysical, 1.0), "a type the curves don't read changes nothing");

    Modifiers magicOnly = Of({ { 87, -50, 126, 0, 1 } });
    check(near(Taken(magicOnly, 1.0), 1.0) && near(Taken(magicOnly, 0.0), 0.5) && near(Taken(magicOnly, 0.5), 0.75),
          "a magic-only shield: nothing against a warrior, half against a caster, a quarter against half of each");

    check(near(ArmourReduction(10000, 80), 10000.0 / (10000.0 + 467.5 * 80 - 22167.5)), "10000 armour against a level 80: the server's constant");
    check(near(ArmourReduction(2000, 40), 2000.0 / (2000.0 + 400 + 85 * 40)), "2000 armour against a level 40");
    check(near(ArmourReduction(1e9, 80), 0.75), "at most 75%");

    BuddyCurve::Holder tank{ 2000, 8000, 1.0, { { 12, Taken(wall, 1.0), 1.0 } } };
    double shortWith = BuddyCurve::Shortfall({ tank }, { { 0, 20, 0, 0 } }, { 500, 300, 20 });
    double shortWithout = BuddyCurve::Shortfall({ { 2000, 8000, 1.0 } }, { { 0, 20, 0, 0 } }, { 500, 300, 20 });
    check(near(shortWithout, 2000) && near(shortWith, 0), "Shield Wall turns the tank's curve: 2000 short without, none with (healed 100 a second for 12, then losing 200 for 8)");

    std::printf("\n%d passed, %d failed\n", passed, failed);
    return failed == 0 ? 0 : 1;
}
