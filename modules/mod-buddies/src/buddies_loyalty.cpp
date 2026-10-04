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
 * is a buddy, it joins only when the inviter is the buddy's owner, or is
 * in a group the owner is in (so a group can take its members' buddies
 * along, as arenas need, 617i), and may invite (leads it, or assists).
 * Anyone else is turned back, and the buddy tells them so: "Thanks, but I
 * stay with my clan." An allowed invite always works, even when the buddy
 * is in a party already (617c4, 2026-10-03): the party pass moves it into
 * the inviter's group as one invited by hand, so the distance grouping
 * leaves it there.
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

// {{{ OwnersSide
// The inviter is the owner, or in a group the owner is in (the owner,
// 2026-10-03: "Sue invites Tracy, and Kyle is Tracy's buddy bot. Sue can
// invite Kyle").
static bool OwnersSide(Player* inviter, uint32 owner)
{
    if (inviter->GetGUID().GetCounter() == owner)
        return true;
    Group* group = inviter->GetGroup();
    return group && group->IsMember(ObjectGuid::Create<HighGuid::Player>(owner));
}
// }}}

// {{{ MayInviteNow
// The server's own rule for who may invite into a group: anyone without
// one (they will lead the new one), or its leader or an assistant.
static bool MayInviteNow(Player* inviter)
{
    Group* group = inviter->GetGroup();
    return !group || group->IsLeader(inviter->GetGUID()) || group->IsAssistant(inviter->GetGUID());
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
        uint32 owner = invited ? OwnerOf(invited) : 0;
        if (!owner)
        {
            // anyone else into a full party: held, so a buddy seated by
            // distance can step out first (617c4: "remove one of the
            // dynamically added buddy-bots at random to make space")
            Group* g = inviter->GetGroup();
            if (g && !g->isRaidGroup() && g->GetMembersCount() >= MAXGROUPSIZE && MayInviteNow(inviter))
            {
                BuddyHoldInviteForRoom(inviter->GetGUID().GetCounter(), packet);
                return false;
            }
            return true;                                   // not a buddy: the server's own invite
        }
        if (!OwnersSide(inviter, owner))
        {
            invited->Whisper(REFUSAL, LANG_UNIVERSAL, inviter);
            return false;                                  // a stranger: refused
        }
        if (!MayInviteNow(inviter))
            return true;                                   // not leader or assistant: the server says so itself
        // Its owner's side: the buddy is seated in the inviter's group
        // whatever it is in now (a match, 617i; a far party or its owner's
        // party, 617c4's override), as one invited by hand. This request
        // may be read off the world's thread, so the leaving and joining
        // are done by the party pass (buddies_party.cpp); the invite itself
        // is held (the server would refuse a buddy already grouped).
        BuddyPullIntoGroup(invited->GetGUID().GetCounter(), inviter->GetGUID().GetCounter());
        return false;
    }
};

// {{{ AddSC_buddies_loyalty
void AddSC_buddies_loyalty()
{
    new buddies_loyalty_server();
}
// }}}
