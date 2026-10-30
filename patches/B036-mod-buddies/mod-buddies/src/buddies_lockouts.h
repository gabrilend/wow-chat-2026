/*
 * buddies_lockouts.h - what the game's lockouts mean for a buddy's plans
 * (issue 625f, the action economy); plain arithmetic over the generated
 * table (BUDDY_LOCKOUTS in buddies_ability_data.h, scripts/generate-ability-data),
 * apart from the server, so it can be tested on its own
 * (tests/buddy-lockouts/, scripts/test-buddy-lockouts).
 *
 * For a general audience: some abilities leave a mark on whoever they
 * reach that refuses them, and others, for a while. Bloodlust leaves Sated
 * (10 minutes) on everyone it hastes, so the party gets it once in 10
 * minutes though its own cooldown is 5. Divine Shield leaves Forbearance
 * (2 minutes) and the Avenging Wrath marker (30 seconds) on the paladin,
 * so Avenging Wrath waits 30 seconds after it; and Hand of Protection
 * leaves the same marks on whoever it protects, another paladin included,
 * whose own Divine Shield then waits (the owner, 2026-10-30: "consider a
 * paladin's forebearance similarly. But keep in mind some spells like
 * Blessing of Protection can put it on other targets, not just the casting
 * paladin."). So:
 *   a buddy plans each ability on the longer of its cooldown and the mark
 *   it leaves on itself (EffectiveCooldownMs);
 *   using one of its abilities refuses another of its own for so long
 *   (BlocksOwnMs: the cooldown timeline's blocked stretches, LineUp);
 *   a mark someone else left on it refuses its abilities until the mark
 *   runs out (Refuses: the server reads the marks on the buddy);
 *   a party member bearing a mark is no one to give that ability to
 *   (Refuses again, for buff targeting, 625l).
 */

#ifndef MOD_BUDDIES_LOCKOUTS_H
#define MOD_BUDDIES_LOCKOUTS_H

#include "buddies_ability_data.h"

#include <algorithm>
#include <cctype>
#include <cstdint>
#include <cstring>

namespace BuddyLockout
{
    // {{{ Lists
    // Whether `name` is one of the "|"-joined names in `joined`.
    inline bool Lists(char const* joined, char const* name)
    {
        size_t n = std::strlen(name);
        for (char const* p = joined; *p; )
        {
            char const* bar = std::strchr(p, '|');
            size_t len = bar ? size_t(bar - p) : std::strlen(p);
            if (len == n && std::strncmp(p, name, n) == 0) return true;
            if (!bar) break;
            p = bar + 1;
        }
        return false;
    }
    // }}}

    // {{{ SameName
    // Whether two names are the same apart from capitals (the table's aura
    // names are the game's, "Berserk"; ability names are lower case).
    inline bool SameName(char const* a, char const* b)
    {
        for (; *a && *b; ++a, ++b)
            if (std::tolower(static_cast<unsigned char>(*a)) != std::tolower(static_cast<unsigned char>(*b))) return false;
        return *a == *b;
    }
    // }}}

    // {{{ BlocksOwnMs
    // How long using `user` refuses `blocked` to the same character, in
    // milliseconds: the longest mark `user` leaves that refuses `blocked`
    // (0: none). Its own name twice is how long it refuses itself (Bloodlust:
    // 10 minutes); two names, how long one keeps the other waiting (Divine
    // Shield then Avenging Wrath: 30 seconds). A "while up" row (no `by`) is
    // the user's own buff refusing another while it lasts (Berserk refusing
    // Tiger's Fury for its 15 seconds); one that lasts until used (Presence
    // of Mind) can't be planned around and counts 0.
    inline uint32_t BlocksOwnMs(char const* user, char const* blocked)
    {
        uint32_t most = 0;
        for (BuddyLockoutRow const& r : BUDDY_LOCKOUTS)
        {
            bool leaves = r.by[0] ? Lists(r.by, user) : false;
            bool own    = !r.by[0] && SameName(r.name, user);
            if ((leaves || own) && Lists(r.blocks, blocked)) most = std::max(most, r.ms);
        }
        return most;
    }
    // }}}

    // {{{ EffectiveCooldownMs
    // The cooldown a buddy plans an ability on: the longer of its own and
    // the mark it leaves on whoever it reaches that refuses it again
    // (Bloodlust 300 seconds by its cooldown, 600 by Sated: 600).
    inline uint32_t EffectiveCooldownMs(char const* name, uint32_t cooldownMs)
    {
        return std::max(cooldownMs, BlocksOwnMs(name, name));
    }
    // }}}

    // {{{ Refuses
    // Whether a mark (by its aura's spell id) on a character refuses
    // `name` to that character: the server reads the marks on a buddy
    // (Forbearance from another paladin's Hand of Protection refuses the
    // buddy's Divine Shield until it runs out) and on each party member (no
    // Bloodlust worth counted for those Sated, no Hand of Protection for
    // those with Forbearance).
    inline bool Refuses(uint32_t aura, char const* name)
    {
        for (BuddyLockoutRow const& r : BUDDY_LOCKOUTS)
            if (r.aura == aura && Lists(r.blocks, name)) return true;
        return false;
    }
    // }}}
}

#endif
