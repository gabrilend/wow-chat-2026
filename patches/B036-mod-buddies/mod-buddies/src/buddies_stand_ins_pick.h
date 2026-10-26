
#ifndef MOD_BUDDIES_STAND_INS_PICK_H
#define MOD_BUDDIES_STAND_INS_PICK_H

#include <cstdint>
#include <utility>
#include <vector>

namespace BuddyStandIn
{
    struct Kept
    {
        uint32_t guid;
        uint8_t  race, cls;
        uint8_t  role;
        uint8_t  level;
        bool     inWorld;
    };

    static constexpr uint8_t SHAPE_THIRDS[10][3] = {
        { 2, 1, 0 }, { 2, 0, 1 }, { 1, 2, 0 }, { 0, 2, 1 }, { 1, 0, 2 },
        { 0, 1, 2 }, { 1, 1, 1 }, { 3, 0, 0 }, { 0, 3, 0 }, { 0, 0, 3 },
    };
    static constexpr uint8_t TREE_ROLE[12][3] = {
        { 0, 0, 0 },
        { 0, 0, 1 },
        { 2, 1, 0 },
        { 0, 0, 0 },
        { 0, 0, 0 },
        { 2, 2, 0 },
        { 0, 0, 0 },
        { 0, 0, 2 },
        { 0, 0, 0 },
        { 0, 0, 0 },
        { 0, 0, 0 },
        { 0, 1, 2 },
    };

    inline uint8_t ShapeRole(uint8_t cls, uint8_t shape)
    {
        if (cls >= 12 || shape < 1 || shape > 10)
            return 0;
        for (uint8_t t = 0; t < 3; ++t)
            if (SHAPE_THIRDS[shape - 1][t] >= 2)
                return TREE_ROLE[cls][t];
        return 0;
    }

    inline std::vector<uint8_t> ShapesForRole(uint8_t cls, uint8_t role)
    {
        std::vector<uint8_t> shapes;
        for (uint8_t shape = 1; shape <= 10; ++shape)
            if (ShapeRole(cls, shape) == role)
                shapes.push_back(shape);
        return shapes;
    }

    inline uint32_t PickKept(std::vector<Kept> const& kept, uint8_t race, uint8_t cls, uint8_t role, uint8_t level)
    {
        Kept const* best = nullptr;
        for (Kept const& k : kept)
        {
            if (k.inWorld || k.race != race || k.cls != cls || k.role != role || k.level > level)
                continue;
            if (!best || k.level > best->level || (k.level == best->level && k.guid < best->guid))
                best = &k;
        }
        return best ? best->guid : 0;
    }

    template <class SideOfRace>
    std::vector<std::pair<uint8_t, uint8_t>> PairsFor(std::vector<std::pair<uint8_t, uint8_t>> const& gamePairs,
        uint8_t side, uint8_t role, SideOfRace sideOfRace)
    {
        std::vector<std::pair<uint8_t, uint8_t>> out;
        for (auto const& p : gamePairs)
        {
            if (sideOfRace(p.first) != side)
                continue;
            if (ShapesForRole(p.second, role).empty())
                continue;
            out.push_back(p);
        }
        return out;
    }

}

#endif
