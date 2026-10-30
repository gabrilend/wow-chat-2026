/*
 * buddies_stand_ins_pick.h - the stand-in maker's choices, apart from the
 * server so they can be tested on their own (issue 617t1;
 * tests/buddy-stand-ins/pick.cpp, scripts/test-buddy-stand-ins).
 *
 * For a general audience: before a stand-in is brought in, three things
 * are chosen: its talent shape (one of the ten a buddy can have, 617g,
 * among those whose role is the one asked for: the owner, 2026-10-09,
 * "pick a spec profile, same as buddy-bots. It's okay if there's two of
 * one type in a squad"), which race and class it is when the asker leaves
 * that open, and whether a kept stand-in can be used instead of making a
 * new one. The rules are written here on plain numbers and lists; the
 * module hands them the game's race and class pairs and does the making.
 */

#ifndef MOD_BUDDIES_STAND_INS_PICK_H
#define MOD_BUDDIES_STAND_INS_PICK_H

#include <algorithm>
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

    // {{{ the shapes
    // Points in each tree in thirds, shape 1-10 (617g; the same table as
    // buddies_loot.cpp's PLAN_THIRDS and scripts/generate-basic-talent-
    // data's order, written out for every class alike).
    static constexpr uint8_t SHAPE_THIRDS[10][3] = {
        { 2, 1, 0 }, { 2, 0, 1 }, { 1, 2, 0 }, { 0, 2, 1 }, { 1, 0, 2 },
        { 0, 1, 2 }, { 1, 1, 1 }, { 3, 0, 0 }, { 0, 3, 0 }, { 0, 0, 3 },
    };
    // Each class's trees' one role (0 damage, 1 tank, 2 healer), as
    // scripts/generate-basic-talent-data's TREE_ROLE gives them (feral is a
    // tank tree there, where buddies_roles.cpp lets it do both): a shape's
    // role is read from these, so a stand-in's shape has the role a buddy's
    // would. scripts/test-buddy-stand-ins checks every class's ten against
    // the generated data.
    static constexpr uint8_t TREE_ROLE[12][3] = {
        { 0, 0, 0 },                                    // 0: none
        { 0, 0, 1 },                                    // warrior: arms, fury, protection
        { 2, 1, 0 },                                    // paladin: holy, protection, retribution
        { 0, 0, 0 },                                    // hunter
        { 0, 0, 0 },                                    // rogue
        { 2, 2, 0 },                                    // priest: discipline, holy, shadow
        { 0, 0, 0 },                                    // death knight (the generator gives all three damage)
        { 0, 0, 2 },                                    // shaman: elemental, enhancement, restoration
        { 0, 0, 0 },                                    // mage
        { 0, 0, 0 },                                    // warlock
        { 0, 0, 0 },                                    // 10: none
        { 0, 1, 2 },                                    // druid: balance, feral, restoration
    };
    // }}}

    // {{{ ShapeRole
    // A shape's role, as the generator writes it: the role of the tree
    // holding two thirds or all of the points; a third in each is damage.
    inline uint8_t ShapeRole(uint8_t cls, uint8_t shape)
    {
        if (cls >= 12 || shape < 1 || shape > 10)
            return 0;
        for (uint8_t t = 0; t < 3; ++t)
            if (SHAPE_THIRDS[shape - 1][t] >= 2)
                return TREE_ROLE[cls][t];
        return 0;
    }
    // }}}

    // {{{ ShapesForRole
    // The shapes (1-10) of a class whose role is the one asked for; empty
    // when none is (a mage tank).
    inline std::vector<uint8_t> ShapesForRole(uint8_t cls, uint8_t role)
    {
        std::vector<uint8_t> shapes;
        for (uint8_t shape = 1; shape <= 10; ++shape)
            if (ShapeRole(cls, shape) == role)
                shapes.push_back(shape);
        return shapes;
    }
    // }}}

    // {{{ PickKept
    // The kept stand-in to use for a race, class and role at a level: one
    // not in the world, at or below the level (its level never goes down,
    // 617t: "their level doesn't go down"), drawn by `roll` (any number,
    // the caller's random draw) among all that fit, so which one a player
    // meets is chance (the owner, 2026-10-29: "if you happen to see them,
    // they'll level with you. it's random."; until then the highest, oldest
    // one was always chosen). The fitting ones are taken in guid order, so
    // the same roll picks the same one. 0 when none fits and a new one must
    // be made.
    inline uint32_t PickKept(std::vector<Kept> const& kept, uint8_t race, uint8_t cls, uint8_t role, uint8_t level,
        uint32_t roll)
    {
        std::vector<uint32_t> fits;
        for (Kept const& k : kept)
        {
            if (k.inWorld || k.race != race || k.cls != cls || k.role != role || k.level > level)
                continue;                               // in use, another kind, or above the level asked
            fits.push_back(k.guid);
        }
        if (fits.empty())
            return 0;                                   // none fits: a new one is made
        std::sort(fits.begin(), fits.end());
        return fits[roll % fits.size()];
    }
    // }}}

    // A role asked for as "any" (the army of 64, 617e17: "fully random
    // talent spec profile distribution"): the race and class are drawn from
    // all the side's pairs, then the shape from all ten, each equally
    // likely, and the role is that shape's (ShapeRole). Asking by role
    // instead weights the draw toward the role, as a squad's seats need.
    static constexpr uint8_t ANY_ROLE = 3;

    // {{{ PairsFor
    // The race and class pairs a stand-in may be drawn from: the game's
    // pairs (the races and classes that can go together), of races on the
    // asked side, of classes with a shape of the role (every class, for
    // ANY_ROLE: each has ten shapes). `sideOfRace` answers 0 Alliance,
    // 1 Horde for a race id.
    template <class SideOfRace>
    std::vector<std::pair<uint8_t, uint8_t>> PairsFor(std::vector<std::pair<uint8_t, uint8_t>> const& gamePairs,
        uint8_t side, uint8_t role, SideOfRace sideOfRace)
    {
        std::vector<std::pair<uint8_t, uint8_t>> out;
        for (auto const& p : gamePairs)
        {
            if (sideOfRace(p.first) != side)
                continue;                               // the other side's race
            if (role != ANY_ROLE && ShapesForRole(p.second, role).empty())
                continue;                               // the class can't take the role
            out.push_back(p);
        }
        return out;
    }
    // }}}

}

#endif
