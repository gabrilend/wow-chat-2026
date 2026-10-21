/*
 * buddies_roles.cpp - what part a character plays in a group (issue 617c3;
 * the rules in plain words are in buddies_roles.h).
 *
 * The points per tree are counted by the bot module's own counter
 * (AiFactory::GetPlayerSpecTabs: each talent's rank, in the active spec,
 * added to its tree), so a buddy and the bot module never disagree about
 * where a character's points are.
 */

#include "buddies_roles.h"
#include "AiFactory.h"
#include "Player.h"
#include "Random.h"
#include "SharedDefines.h"

// {{{ the roles of each class's trees
// Left to right as the talent window shows them; a set of roles each.
static constexpr BuddyRoles D  = BuddyRoleBit(BuddyRole::Damage);
static constexpr BuddyRoles T  = BuddyRoleBit(BuddyRole::Tank);
static constexpr BuddyRoles H  = BuddyRoleBit(BuddyRole::Healer);
static constexpr BuddyRoles TREE_ROLES[MAX_CLASSES][3] = {
    { D, D,     D },                                   // 0: none
    { D, D,     T },                                   // warrior: arms, fury, protection
    { H, T,     D },                                   // paladin: holy, protection, retribution
    { D, D,     D },                                   // hunter
    { D, D,     D },                                   // rogue
    { H, H,     D },                                   // priest: discipline, holy, shadow
    { T, D,     D },                                   // death knight: blood, frost, unholy
    { D, D,     H },                                   // shaman: elemental, enhancement, restoration
    { D, D,     D },                                   // mage
    { D, D,     D },                                   // warlock
    { D, D,     D },                                   // 10: none
    { D, T | D, H },                                   // druid: balance, feral (both), restoration
};
// }}}

// {{{ BuddySpecTrees
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
// }}}

// {{{ BuddySpecTree
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
// }}}

// {{{ BuddyTreeRoles
BuddyRoles BuddyTreeRoles(uint8 cls, uint8 tree)
{
    return cls < MAX_CLASSES && tree < 3 ? TREE_ROLES[cls][tree] : D;
}
// }}}

// {{{ BuddyPlayerRoles
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
// }}}
