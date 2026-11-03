
#ifndef MOD_BUDDIES_LOCKOUTS_H
#define MOD_BUDDIES_LOCKOUTS_H

#include "buddies_ability_data.h"

#include <algorithm>
#include <cctype>
#include <cstdint>
#include <cstring>

namespace BuddyLockout
{
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

    inline bool SameName(char const* a, char const* b)
    {
        for (; *a && *b; ++a, ++b)
            if (std::tolower(static_cast<unsigned char>(*a)) != std::tolower(static_cast<unsigned char>(*b))) return false;
        return *a == *b;
    }

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

    inline uint32_t EffectiveCooldownMs(char const* name, uint32_t cooldownMs)
    {
        return std::max(cooldownMs, BlocksOwnMs(name, name));
    }

    inline bool Refuses(uint32_t aura, char const* name)
    {
        for (BuddyLockoutRow const& r : BUDDY_LOCKOUTS)
            if (r.aura == aura && Lists(r.blocks, name)) return true;
        return false;
    }
}

#endif
