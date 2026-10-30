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

// {{{ row
// An ability's generated row, by class and name.
static BuddyAbilityRow const* row(uint8_t cls, char const* name)
{
    for (BuddyAbilityRow const& r : BUDDY_ABILITIES) if (r.cls == cls && std::string(r.name) == name) return &r;
    return nullptr;
}
// }}}

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
    // the same, with each ability's profile read from the game's data (no hand-set shares)
    auto* fireball = row(8, "fireball"); auto* sinister = row(4, "sinister strike");
    auto* corruption = row(9, "corruption"); auto* bolt = row(9, "shadow bolt"); auto* holyLight = row(2, "holy light");
    check(fireball && sinister && corruption && bolt && holyLight, "the generated data holds Fireball, Sinister Strike, Corruption, Shadow Bolt, Holy Light");
    if (fireball && sinister && corruption && bolt && holyLight)
    {
        float dm = WindowFactor(lust, { ProfileOf(*fireball, 1.0f) });
        float dr = WindowFactor(lust, { ProfileOf(*sinister, 0.75f), Ability{ AUTO_ATTACK.haste, AUTO_ATTACK.damage, AUTO_ATTACK.healing, AUTO_ATTACK.crit, 0.25f } });
        float dw = WindowFactor(lust, { ProfileOf(*corruption, 0.5f), ProfileOf(*bolt, 0.5f) });
        float dh = WindowFactor(wrath, { ProfileOf(*holyLight, 1.0f) });
        std::printf("  from the game's data: fire mage %.3f, rogue %.3f, affliction warlock %.3f, holy paladin %.3f\n", dm, dr, dw, dh);
        check(std::fabs(dm - 1.30f) < 1e-4, "from the data: Fireball's cast time makes Bloodlust worth its full 30%");
        check(std::fabs(dr - 1.075f) < 1e-4, "from the data: Sinister Strike's energy isn't hastened, only the auto attacks");
        check(std::fabs(dw - 1.15f) < 1e-4, "from the data: Corruption's ticks aren't hastened, Shadow Bolt's cast is");
        check(std::fabs(dh - 1.20f) < 1e-4, "from the data: Holy Light heals, so Avenging Wrath's healing counts");
    }
    std::printf("%s: %d of %d checks passed\n", failed ? "FAILED" : "ok", passed, passed + failed);
    return failed ? 1 : 0;
}
