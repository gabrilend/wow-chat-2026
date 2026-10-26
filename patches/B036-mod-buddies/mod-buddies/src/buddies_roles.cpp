
#include "buddies_roles.h"
#include "AiFactory.h"
#include "Player.h"
#include "Random.h"
#include "SharedDefines.h"

static constexpr BuddyRoles D  = BuddyRoleBit(BuddyRole::Damage);
static constexpr BuddyRoles T  = BuddyRoleBit(BuddyRole::Tank);
static constexpr BuddyRoles H  = BuddyRoleBit(BuddyRole::Healer);
static constexpr BuddyRoles TREE_ROLES[MAX_CLASSES][3] = {
    { D, D,     D },
    { D, D,     T },
    { H, T,     D },
    { D, D,     D },
    { D, D,     D },
    { H, H,     D },
    { T, D,     D },
    { D, D,     H },
    { D, D,     D },
    { D, D,     D },
    { D, D,     D },
    { D, T | D, H },
};

uint8 BuddySpecTrees(Player* player)
{
    std::map<uint8, uint32> points = AiFactory::GetPlayerSpecTabs(player);
    uint32 most = 0;
    for (uint8 t = 0; t < 3; ++t)
        most = std::max(most, points[t]);
    if (!most)
        return 0;
    uint8 trees = 0;
    for (uint8 t = 0; t < 3; ++t)
        if (points[t] == most)
            trees |= uint8(1u << t);
    return trees;
}

int8 BuddySpecTree(Player* player)
{
    uint8 trees = BuddySpecTrees(player);
    int8  picks[3];
    uint8 n = 0;
    for (uint8 t = 0; t < 3; ++t)
        if (trees & (1u << t))
            picks[n++] = int8(t);
    return n ? picks[urand(0, n - 1)] : int8(-1);
}

BuddyRoles BuddyTreeRoles(uint8 cls, uint8 tree)
{
    return cls < MAX_CLASSES && tree < 3 ? TREE_ROLES[cls][tree] : D;
}

BuddyRoles BuddyPlayerRoles(Player* player)
{
    uint8 trees = BuddySpecTrees(player);
    if (!trees)
        return D;
    BuddyRoles roles = 0;
    for (uint8 t = 0; t < 3; ++t)
        if (trees & (1u << t))
            roles |= BuddyTreeRoles(player->getClass(), t);
    return roles;
}
