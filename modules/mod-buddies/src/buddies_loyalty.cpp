
#include "buddies.h"
#include "DatabaseEnv.h"
#include "Group.h"
#include "ObjectAccessor.h"
#include "Opcodes.h"
#include "Player.h"
#include "QueryResult.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"

static char const* const REFUSAL = "Thanks, but I stay with my clan.";

static uint32 OwnerOf(Player* maybeBuddy)
{
    if (!BuddyIsCompanionAccount(maybeBuddy->GetSession()->GetAccountId()))
        return 0;
    QueryResult row = CharacterDatabase.Query("SELECT owner FROM buddy_roster WHERE buddy = {}", maybeBuddy->GetGUID().GetCounter());
    return row ? (*row)[0].Get<uint32>() : 0;
}

static bool OwnersSide(Player* inviter, uint32 owner)
{
    if (inviter->GetGUID().GetCounter() == owner)
        return true;
    Group* group = inviter->GetGroup();
    return group && group->IsMember(ObjectGuid::Create<HighGuid::Player>(owner));
}

static bool MayInviteNow(Player* inviter)
{
    Group* group = inviter->GetGroup();
    return !group || group->IsLeader(inviter->GetGUID()) || group->IsAssistant(inviter->GetGUID());
}

class buddies_loyalty_server : public ServerScript
{
public:
    buddies_loyalty_server() : ServerScript("buddies_loyalty_server", { SERVERHOOK_CAN_PACKET_RECEIVE }) { }

    bool CanPacketReceive(WorldSession* session, WorldPacket const& packet) override
    {
        if (!BuddiesEnabled() || !session || packet.GetOpcode() != CMSG_GROUP_INVITE)
            return true;
        Player* inviter = session->GetPlayer();
        if (!inviter)
            return true;
        WorldPacket copy(packet);
        std::string name;
        copy >> name;
        Player* invited = ObjectAccessor::FindPlayerByName(name, false);
        uint32 owner = invited ? OwnerOf(invited) : 0;
        if (!owner)
        {
            Group* g = inviter->GetGroup();
            if (g && !g->isRaidGroup() && g->GetMembersCount() >= MAXGROUPSIZE && MayInviteNow(inviter))
            {
                BuddyHoldInviteForRoom(inviter->GetGUID().GetCounter(), packet);
                return false;
            }
            return true;
        }
        if (!OwnersSide(inviter, owner))
        {
            invited->Whisper(REFUSAL, LANG_UNIVERSAL, inviter);
            return false;
        }
        if (!MayInviteNow(inviter))
            return true;
        BuddyPullIntoGroup(invited->GetGUID().GetCounter(), inviter->GetGUID().GetCounter());
        return false;
    }
};

void AddSC_buddies_loyalty()
{
    new buddies_loyalty_server();
}
