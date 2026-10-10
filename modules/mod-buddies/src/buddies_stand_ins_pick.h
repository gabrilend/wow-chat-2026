/*
 * buddies_stand_ins_pick.h - the stand-in maker's choices, apart from the
 * server so they can be tested on their own (issue 617t1;
 * tests/buddy-stand-ins/pick.cpp, scripts/test-buddy-stand-ins).
 *
 * For a general audience: before a stand-in is brought in, three things
 * are chosen: which talent tree it puts everything into (one that takes
 * its role), which race and class it is when the asker leaves that open,
 * and whether a kept stand-in can be used instead of making a new one.
 * The rules are written here on plain numbers and lists; the module hands
 * them the game's tables (which trees take which role, which race and
 * class pairs exist) and does the making.
 */

#ifndef MOD_BUDDIES_STAND_INS_PICK_H
#define MOD_BUDDIES_STAND_INS_PICK_H

#include <cstdint>
#include <utility>
#include <vector>

namespace BuddyStandIn
{
    // {{{ Kept
    // One kept stand-in, as the characters database holds it.
    struct Kept
    {
        uint32_t guid;                                  // characters.guid
        uint8_t  race, cls;                             // the game's race and class ids
        uint8_t  role;                                  // 0 damage, 1 tank, 2 healer (the roster's numbers)
        uint8_t  level;                                 // its level now
        bool     inWorld;                               // in a scene or a dungeon right now
    };
    // }}}

    // {{{ TreesForRole
    // The talent trees (0-2) of a class that take a role, given each tree's
    // roles as bit sets (bit 1 << role, as BuddyTreeRoles answers): a
    // stand-in puts everything into one of them (617t: "wholly its role").
    // Empty when no tree of the class takes the role (a mage tank).
    inline std::vector<uint8_t> TreesForRole(uint8_t const (&treeRoles)[3], uint8_t role)
    {
        std::vector<uint8_t> trees;
        for (uint8_t t = 0; t < 3; ++t)
            if (treeRoles[t] & (1u << role))
                trees.push_back(t);
        return trees;
    }
    // }}}

    // {{{ ShapeForTree
    // The talent shape (617g's 1-10, buddy_roster.profile's numbers) of all
    // the points in one tree: 8, 9, 10 for the first, second, third.
    inline uint8_t ShapeForTree(uint8_t tree) { return uint8_t(8 + tree); }
    // }}}

    // {{{ PickKept
    // The kept stand-in to use for a race, class and role at a level: one
    // not in the world, at or below the level (its level never goes down,
    // 617t: "their level doesn't go down"), the highest such, the oldest
    // (lowest guid) on a tie so the same one is chosen every time. 0 when
    // none fits and a new one must be made.
    inline uint32_t PickKept(std::vector<Kept> const& kept, uint8_t race, uint8_t cls, uint8_t role, uint8_t level)
    {
        Kept const* best = nullptr;
        for (Kept const& k : kept)
        {
            if (k.inWorld || k.race != race || k.cls != cls || k.role != role || k.level > level)
                continue;                               // in use, another kind, or above the level asked
            if (!best || k.level > best->level || (k.level == best->level && k.guid < best->guid))
                best = &k;
        }
        return best ? best->guid : 0;
    }
    // }}}

    // {{{ PairsFor
    // The race and class pairs a stand-in may be drawn from: the game's
    // pairs (the races and classes that can go together), of races on the
    // asked side, of classes with a tree taking the role. `sideOfRace`
    // answers 0 Alliance, 1 Horde for a race id; `rolesOfClass` a class's
    // three trees' roles.
    template <class SideOfRace, class RolesOfClass>
    std::vector<std::pair<uint8_t, uint8_t>> PairsFor(std::vector<std::pair<uint8_t, uint8_t>> const& gamePairs,
        uint8_t side, uint8_t role, SideOfRace sideOfRace, RolesOfClass rolesOfClass)
    {
        std::vector<std::pair<uint8_t, uint8_t>> out;
        for (auto const& p : gamePairs)
        {
            if (sideOfRace(p.first) != side)
                continue;                               // the other side's race
            uint8_t treeRoles[3];
            rolesOfClass(p.second, treeRoles);
            if (TreesForRole(treeRoles, role).empty())
                continue;                               // the class can't take the role
            out.push_back(p);
        }
        return out;
    }
    // }}}

    // {{{ PickSpecForTree
    // Of the bot module's pre-made talent builds for a class (one list of
    // trees per build, a tree id for each talent point, the build at its
    // fullest level), the build putting the largest share of its points in
    // `tree`; ties go to the lower build number. -1 when no build has any
    // point there (or there are no builds). The bot module numbers its
    // builds freely ("arms pve", "fury pvp", ...), so the tree is read from
    // the points, not the name.
    inline int PickSpecForTree(std::vector<std::vector<uint8_t>> const& buildTrees, uint8_t tree)
    {
        int    best      = -1;
        double bestShare = 0.0;
        for (size_t s = 0; s < buildTrees.size(); ++s)
        {
            std::vector<uint8_t> const& points = buildTrees[s];
            if (points.empty())
                continue;                               // no build under this number
            size_t inTree = 0;
            for (uint8_t t : points)
                inTree += (t == tree);
            double share = double(inTree) / double(points.size());
            if (inTree && share > bestShare)
            {
                best      = int(s);
                bestShare = share;
            }
        }
        return best;
    }
    // }}}
}

#endif
