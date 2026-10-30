// lockout-check.cpp - checks buddies_lockouts.h and the cooldown
// timeline's blocked stretches (issue 625f): the game's lockouts, read
// from its tables and the server's scripts, decide how long a buddy plans
// each ability on, which of its own abilities keep others waiting, and
// what a mark left by someone else refuses.

#include "buddies_cooldown_plan.h"
#include "buddies_lockouts.h"

#include <cmath>
#include <cstdio>
#include <cstring>

using namespace BuddyLockout;
using namespace BuddyPlan;

static int passed = 0, failed = 0;
// {{{ check
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}
// }}}

static bool near(double a, double b) { return std::fabs(a - b) < 1e-6; }

// {{{ cooldownOf
// An ability's own cooldown from the generated table, by class and name.
static uint32_t cooldownOf(uint8_t cls, char const* name)
{
    for (BuddyAbilityRow const& r : BUDDY_ABILITIES) if (r.cls == cls && std::strcmp(r.name, name) == 0) return r.cooldownMs;
    return 0;
}
// }}}

int main()
{
    // planned on the longer of the cooldown and the mark left on oneself
    check(cooldownOf(7, "bloodlust") == 300000, "Bloodlust's own cooldown in the game's table: 5 minutes");
    check(EffectiveCooldownMs("bloodlust", cooldownOf(7, "bloodlust")) == 600000, "planned on Sated's 10 minutes");
    check(EffectiveCooldownMs("heroism", cooldownOf(7, "heroism")) == 600000, "Heroism on Exhaustion's 10 minutes");
    check(EffectiveCooldownMs("divine shield", cooldownOf(2, "divine shield")) == cooldownOf(2, "divine shield"),
          "Divine Shield on its own 5 minutes (Forbearance's 2 are shorter)");
    check(EffectiveCooldownMs("power word: shield", 4000) == 15000, "Power Word: Shield on one target: Weakened Soul's 15 seconds");

    // one of a buddy's own abilities keeping another waiting
    check(BlocksOwnMs("divine shield", "avenging wrath") == 30000, "Divine Shield keeps Avenging Wrath waiting 30 seconds (the marker)");
    check(BlocksOwnMs("avenging wrath", "divine shield") == 30000, "and Avenging Wrath keeps Divine Shield waiting 30");
    check(BlocksOwnMs("hand of protection", "divine shield") == 120000, "Hand of Protection on oneself: Forbearance, 2 minutes");
    check(BlocksOwnMs("berserk", "tiger's fury") == 15000, "Berserk refuses Tiger's Fury while it is up (15 seconds)");
    check(BlocksOwnMs("presence of mind", "arcane power") == 0, "Presence of Mind lasts until used: not planned around");
    check(BlocksOwnMs("bloodlust", "avenging wrath") == 0, "unrelated abilities don't wait on each other");

    // marks someone else left (another paladin's Hand of Protection)
    check(Refuses(25771, "divine shield") && Refuses(25771, "hand of protection"), "Forbearance refuses Divine Shield and Hand of Protection");
    check(!Refuses(25771, "avenging wrath"), "Forbearance alone doesn't refuse Avenging Wrath (the marker, 30 seconds, does)");
    check(Refuses(61987, "avenging wrath"), "the Avenging Wrath marker refuses Avenging Wrath");
    check(Refuses(57724, "heroism") && Refuses(57723, "bloodlust"), "Sated refuses Heroism too, and Exhaustion Bloodlust");

    // the timeline: a blocked stretch holds no use
    Plan p = Best({ 180, 0, 20 }, {}, 200, Fight::Boss, { { 0, 30, 0 } });
    check(near(p.nextUse, 30) && near(p.weight, 0), "blocked for 30 seconds: first used at 30, and can't be used now");
    p = Best({ 180, 0, 20 }, {}, 200, Fight::Boss, { { 50, 30, 0 } });
    check(near(p.nextUse, 0), "a stretch blocked later doesn't hold back a use now");

    // a paladin's Divine Shield and Avenging Wrath, 200 seconds of a boss
    // left, each keeping the other waiting 30 seconds. The shield's worth
    // (from the health economy) is stood in here by a plain use. Shield
    // first: it is used at once, the wrath waits to 30 and has no time for
    // a second (worth 2 together). Wrath first: it is used at 0 and 180,
    // and the shield at 30, clear of both (worth 3). The set worth more is
    // kept.
    std::vector<Own> paladin = {
        { { 300, 0, 12 }, 1.0, { { 1, BlocksOwnMs("divine shield", "avenging wrath") / 1000.0 } } },
        { { 180, 0, 20 }, 1.2, { { 0, BlocksOwnMs("avenging wrath", "divine shield") / 1000.0 } } },
    };
    std::vector<Plan> both = LineUp(paladin, {}, 200, Fight::Boss);
    check(both[1].uses == 2 && near(both[1].at[0], 0) && near(both[1].at[1], 180), "Avenging Wrath gets both its uses (0 and 180)");
    check(near(both[0].nextUse, 30) && near(both[0].weight, 0), "Divine Shield waits out the wrath's 30 seconds, and can't be used now");
    check(near(Together(paladin, both, {}, 200, Fight::Boss), 3.0), "together worth 3, against 2 with the shield first");
    std::vector<Plan> clash = both;
    clash[0].at = { 10 };
    check(Together(paladin, clash, {}, 200, Fight::Boss) < 0, "a set with the shield inside the wrath's lockout is impossible");

    std::printf("\n%d passed, %d failed\n", passed, failed);
    return failed == 0 ? 0 : 1;
}
