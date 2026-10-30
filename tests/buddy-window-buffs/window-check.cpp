// window-check.cpp - checks buddies_window_buffs.h (issue 625f): the same
// buff is worth different amounts to different buddies, by what it gives
// and what their abilities are moved by.

#include "buddies_window_buffs.h"

#include <cmath>
#include <cstdio>
#include <string>

using namespace BuddyWindow;

static int passed = 0, failed = 0;
// {{{ check
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}
// }}}

static Provides of(char const* name)
{
    for (Buff const& b : BUFFS) if (std::string(b.name) == name) return b.gives;
    return Provides{};
}

int main()
{
    Provides lust = of("Bloodlust"), wrath = of("Avenging Wrath");
    // a fire mage casting Fireball: all of its worth hastened
    std::vector<Ability> mage = { { 1.0f, 1.0f, 0.0f, 1.0f, 1.0f } };
    // a rogue's energy-bound strikes: only the auto attacks between speed up
    std::vector<Ability> rogue = { { 0.25f, 1.0f, 0.0f, 1.0f, 1.0f } };
    // an affliction warlock: half its worth in damage over time (not hastened), half Shadow Bolt
    std::vector<Ability> lock = { { 0.0f, 1.0f, 0.0f, 0.0f, 0.5f }, { 1.0f, 1.0f, 0.0f, 1.0f, 0.5f } };
    // a holy paladin's heals
    std::vector<Ability> holy = { { 1.0f, 0.0f, 1.0f, 1.0f, 1.0f } };
    float m = WindowFactor(lust, mage), r = WindowFactor(lust, rogue), w = WindowFactor(lust, lock), h = WindowFactor(wrath, holy);
    std::printf("  Bloodlust: fire mage %.3f, rogue %.3f, affliction warlock %.3f; Avenging Wrath on a holy paladin's heals %.3f\n", m, r, w, h);
    check(std::fabs(m - 1.30f) < 1e-4, "Bloodlust is worth its full 30% to a caster whose casts it hastens");
    check(r > 1.0f && r < 1.10f, "to an energy-bound rogue, much less (its auto attacks only)");
    check(std::fabs(w - 1.15f) < 1e-4, "to an affliction warlock, half: its damage over time isn't hastened");
    check(std::fabs(h - 1.20f) < 1e-4, "Avenging Wrath's healing counts for a healer's heals");
    check(WindowFactor(of("Innervate"), mage) == 1.0f, "Innervate gives no window: its mana is the resource economy's");
    std::printf("%s: %d of %d checks passed\n", failed ? "FAILED" : "ok", passed, passed + failed);
    return failed ? 1 : 0;
}
