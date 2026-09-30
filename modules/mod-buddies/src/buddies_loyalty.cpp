/*
 * buddies_loyalty.cpp - a buddy joins only its own clan's groups (issue 617c4).
 *
 * For a general audience: buddies aren't servants. The owner, 2026-09-28:
 * "they aren't masters, they're clanmates, and there wouldn't be a
 * hierarchy except only the player can do certain things so we have them
 * do those things, like decide where to go and such. Otherwise they are
 * their own masters, owing alliegance to a clan as their family. You
 * don't choose family, but it is all you got." So a stranger can't invite
 * a buddy away from its clan. When a player asks to invite someone into a group,
 * this looks at who is being invited before the server handles it: if it
 * is a buddy, the request goes through only when the inviter is the
 * buddy's owner, or leads a group the owner is in (so a group can take its
 * members' buddies along, as arenas need, 617i). Anyone else is turned
 * back, and the buddy tells them so: "Thanks, but I stay with my clan."
 *
 * The buddies' own grouping (the proximity and far parties, 617c2) adds
 * members through the server directly, not through invite requests, so it
 * never passes here.
 */

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

// {{{ OwnerOf
// The owner of a buddy (its character guid, low part), or 0 when the
// character is not a buddy.
static uint32 OwnerOf(Player* maybeBuddy)
{
    if (!BuddyIsCompanionAccount(maybeBuddy->GetSession()->GetAccountId()))
        return 0;
    QueryResult row = CharacterDatabase.Query("SELECT owner FROM buddy_roster WHERE buddy = {}", maybeBuddy->GetGUID().GetCounter());
    return row ? (*row)[0].Get<uint32>() : 0;
}
// }}}

// {{{ MayInvite
// The inviter is the owner, or leads a group the owner is in.
static bool MayInvite(Player* inviter, uint32 owner)
{
    if (inviter->GetGUID().GetCounter() == owner)
        return true;
    Group* group = inviter->GetGroup();
    if (!group || !group->IsLeader(inviter->GetGUID()))
        return false;
    return group->IsMember(ObjectGuid::Create<HighGuid::Player>(owner));
}
// }}}

class buddies_loyalty_server : public ServerScript
{
public:
    buddies_loyalty_server() : ServerScript("buddies_loyalty_server", { SERVERHOOK_CAN_PACKET_RECEIVE }) { }

    // The server calls this read-only form. The invite request carries the
    // invited character's name first; a copy is read so the real request is
    // left untouched for its handler.
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
        if (!invited)
            return true;                                   // not online: the server's own answer applies
        uint32 owner = OwnerOf(invited);
        if (owner && MayInvite(inviter, owner) && invited->InBattleground())
        {
            // its owner's side invites a buddy that is in a match: it leaves
            // the match at once and joins the inviter's group (617i). This
            // request may be read off the world's thread, so the leaving and
            // the joining are done by the party pass (buddies_party.cpp);
            // the invite itself is held, having nothing to join yet.
            BuddyPullFromBattleground(invited->GetGUID().GetCounter(), inviter->GetGUID().GetCounter());
            return false;
        }
        if (!owner || MayInvite(inviter, owner))
            return true;                                   // not a buddy, or its owner's side asking
        invited->Whisper(REFUSAL, LANG_UNIVERSAL, inviter);
        return false;
    }
};

// {{{ AddSC_buddies_loyalty
void AddSC_buddies_loyalty()
{
    new buddies_loyalty_server();
}
// }}}
