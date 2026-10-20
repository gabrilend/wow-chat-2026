
#ifndef MOD_BUDDIES_H
#define MOD_BUDDIES_H

#include "Define.h"
#include "StringFormat.h"
#include <string>
#include <string_view>

bool BuddiesEnabled();

std::string BuddyCompanionAccountName(uint32 ownerGuid);

uint32 BuddyCompanionAccountId(uint32 ownerGuid);

bool BuddyIsCompanionAccount(uint32 accountId);

class Player;

void BuddyPullIntoGroup(uint32 buddyGuid, uint32 inviterGuid);

class WorldPacket;
void BuddyHoldInviteForRoom(uint32 inviterGuid, WorldPacket const& packet);

void BuddyQueueLogin(uint32 ownerGuid);

uint32 BuddyMakeCharacter(uint32 account, uint8 race, uint8 cls, uint8 level, uint8 shape, uint8 role,
    uint32 bagsLike, bool pvpJewellery, char const* kind, std::string const& forWhom, std::string& name, std::string& why);

bool BuddyIsStandInAccount(uint32 accountId);

bool BuddyIsNotAPlayer(uint32 accountId);

uint32 BuddyBringStandIn(uint8 side, uint8 role, uint8 level, uint8 race, uint8 cls,
    uint32 map, float x, float y, float z, float o, std::string& said);

bool BuddyPlaceWisp(Player* gm, float x, float y, float z, float o, uint32 ms);

uint8 BuddySlotLevel(uint8 slot);

void BuddyStageCheck(Player* owner);

bool BuddyTakeSellOrder(uint32 buddy);

class Player;
bool BuddyTraced(Player const* bot);
void BuddyTraceLine(Player const* bot, std::string const& text);

template<typename... Args>
inline void BuddyTrace(Player const* bot, std::string_view fmt, Args&&... args)
{
    if (BuddyTraced(bot))
        BuddyTraceLine(bot, Acore::StringFormat(fmt, std::forward<Args>(args)...));
}

#endif
