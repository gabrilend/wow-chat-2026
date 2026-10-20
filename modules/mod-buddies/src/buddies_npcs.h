
#ifndef MOD_BUDDIES_NPCS_H
#define MOD_BUDDIES_NPCS_H

#include "Define.h"
#include "ObjectGuid.h"
#include "roam/buddy_roam_core.h"

class Creature;
class Player;
class PlayerbotAI;

enum class BuddyNpcUse : uint8 { None, Train, Sell, Repair, Visit };

struct BuddyNpcPick
{
    ObjectGuid       npc;
    BuddyNpcUse      use = BuddyNpcUse::None;
    BuddyRoam::Point spot;
};

bool BuddyNpcNotice(Player* bot, BuddyNpcPick& out);

void BuddyNpcRelease(Player* bot, ObjectGuid npc);

std::string BuddyNpcArrive(PlayerbotAI* ai, Player* bot, Creature* npc, bool& talk);

char const* BuddyNpcUseName(BuddyNpcUse use);

#endif
