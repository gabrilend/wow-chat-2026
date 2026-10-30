/*
 * buddies_window_buffs.h - what an empowering buff gives, and what it is
 * worth to one buddy's own abilities (issue 625f, the action economy);
 * plain arithmetic, apart from the server, so it can be tested on its own
 * (tests/buddy-window-buffs/window-check.cpp, scripts/test-buddy-window-buffs).
 *
 * For a general audience: a cooldown used inside Bloodlust is worth more
 * than one used outside it, but not by the same amount for everyone (the
 * owner, 2026-10-30: "Bloodlust for example can't be 1.3x because some
 * classes use haste rating more and value it more strongly. Focus on the
 * buff it provides and have it interface with the ability economy."). So
 * each buff is written down as what it provides (haste, damage, healing,
 * critical chance, cost), read from the game's own spell table, and each
 * ability as how much of its worth each of those moves (a cast-time spell
 * all of its haste, an energy-bound strike little, a damage-over-time none
 * in this version of the game). A buddy's window factor is its abilities'
 * factors, each weighed by its share of the buddy's casts.
 *
 * The buffs' gifts are the game's own numbers. How much each ability is
 * moved by them is, for now, set by hand per kind of ability: a stand-in
 * for the ability's own cast time, global cooldown, resource and ticks,
 * to be read from its data instead (the owner, 2026-10-30: "We want their
 * value to come cleanly from the roots of the weights that determine
 * their output"; strategems/everything-is-damage-and-health.md).
 */

#ifndef MOD_BUDDIES_WINDOW_BUFFS_H
#define MOD_BUDDIES_WINDOW_BUFFS_H

#include <cstdint>
#include <vector>

namespace BuddyWindow
{
    // {{{ Provides
    // What a buff gives, as shares (0.30 = 30%). costCut: less resource per
    // cast (negative: more); regen: resource back, as a share of the pool
    // over the buff (for the resource economy, 625h, not the window factor).
    struct Provides
    {
        float haste = 0.0f, damage = 0.0f, healing = 0.0f, crit = 0.0f, costCut = 0.0f, regen = 0.0f;
    };
    // }}}

    // {{{ the buffs
    // Read from the client's Spell.dbc on 2026-10-30 (aura, amount):
    //   Bloodlust 2825, Heroism 32182: melee, ranged and casting haste 30%
    //   Power Infusion 10060: casting speed 20%, cost -20%
    //   Icy Veins 12472: casting speed 20%
    //   Berserking 26297: haste 20%
    //   Arcane Power 12042: damage +20%, cost +20%
    //   Avenging Wrath 31884: damage +20%, healing +20%
    //   Death Wish 12292: physical damage +20%
    //   Recklessness 1719: critical chance +100% (its next abilities; a
    //     window of a few strikes, counted here as +50% over the window)
    //   Innervate 29166: mana regeneration +225% (resource only)
    struct Buff { uint32_t spell; char const* name; Provides gives; };
    static Buff const BUFFS[] = {
        {  2825, "Bloodlust",       { 0.30f, 0.00f, 0.00f, 0.00f,  0.00f, 0.00f } },
        { 32182, "Heroism",         { 0.30f, 0.00f, 0.00f, 0.00f,  0.00f, 0.00f } },
        { 10060, "Power Infusion",  { 0.20f, 0.00f, 0.00f, 0.00f,  0.20f, 0.00f } },
        { 12472, "Icy Veins",       { 0.20f, 0.00f, 0.00f, 0.00f,  0.00f, 0.00f } },
        { 26297, "Berserking",      { 0.20f, 0.00f, 0.00f, 0.00f,  0.00f, 0.00f } },
        { 12042, "Arcane Power",    { 0.00f, 0.20f, 0.00f, 0.00f, -0.20f, 0.00f } },
        { 31884, "Avenging Wrath",  { 0.00f, 0.20f, 0.20f, 0.00f,  0.00f, 0.00f } },
        { 12292, "Death Wish",      { 0.00f, 0.20f, 0.00f, 0.00f,  0.00f, 0.00f } },
        {  1719, "Recklessness",    { 0.00f, 0.00f, 0.00f, 0.50f,  0.00f, 0.00f } },
        { 29166, "Innervate",       { 0.00f, 0.00f, 0.00f, 0.00f,  0.00f, 2.25f } },
    };
    // }}}

    // {{{ Ability
    // How much of an ability's worth each provision moves (0 to 1):
    //   haste:   a cast-time or global-cooldown-bound spell 1; a strike
    //            bound by energy or rage, about a quarter (only the auto
    //            attacks between speed up); damage or healing over time 0
    //            (its ticks aren't hastened in this version of the game)
    //   damage, healing: 1 for what the ability does, 0 for what it doesn't
    //   crit:    1 for a hit that can strike critically (a critical doubles
    //            it), 0 for one that can't
    // share: the ability's part of the buddy's casts in the window.
    struct Ability { float haste, damage, healing, crit, share; };
    // }}}

    // {{{ Factor
    // One ability's worth inside the window against outside it.
    inline float Factor(Provides const& p, Ability const& a)
    {
        return (1.0f + p.haste * a.haste) * (1.0f + p.damage * a.damage + p.healing * a.healing) * (1.0f + p.crit * a.crit);
    }
    // }}}

    // {{{ WindowFactor
    // A buddy's window factor: its abilities' factors weighed by their
    // shares of its casts (shares need not add to one; they are normalised).
    inline float WindowFactor(Provides const& p, std::vector<Ability> const& abilities)
    {
        float sum = 0.0f, shares = 0.0f;
        for (Ability const& a : abilities)
        {
            sum    += Factor(p, a) * a.share;
            shares += a.share;
        }
        return shares > 0.0f ? sum / shares : 1.0f;
    }
    // }}}
}

#endif
