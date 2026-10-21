/*
 * buddies_clan_lock.cpp - a clan guild can't be disbanded, left, handed
 * over, or opened to anyone else (issue 617l).
 *
 * For a general audience: a clan is one player and their buddies, kept in
 * an ordinary guild so the game's guild chat and roster work (617l). The
 * owner's words (2026-09-26): it "can't be disbanded, can't be quit. Can't
 * invite any other characters. It's just for a player and their
 * buddy-bots." The game has no switch for that, so this file stands at the
 * door where the player's guild requests come in, and turns back the five
 * that would break a clan, with a line saying why. Everything else a guild
 * does (chat, the message of the day, ranks, notes) passes untouched.
 *
 * How: the server offers modules a look at every request a player's game
 * sends, before it is handled, and lets them drop it. The guild requests
 * are recognised by their message number; a request is dropped only when
 * the sender's guild is a clan guild (its id is some owner's clan_guild in
 * buddy_clan). The check reads the database, which is fine for requests a
 * player makes by hand a few times a session.
 *
 * Not covered, on purpose: game-master commands (".guild delete" and the
 * like) go round this door, so an administrator can still fix a clan; and
 * requests a bot makes for itself come from the bot module, not from a
 * player's game, so they don't pass here either (buddies are never told to
 * leave by anyone but their owner, whose requests do pass here).
 */

#include "buddies.h"
#include "Chat.h"
#include "DatabaseEnv.h"
#include "Opcodes.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <unordered_map>

// {{{ refused requests
// Each refused guild request and the line the owner sees. A table rather
// than a chain of ifs: the request's number picks its line directly, and a
// request not in the table is not a clan concern.
static std::unordered_map<uint16, char const*> const sRefused = {
    { CMSG_GUILD_INVITE,  "Your clan is you and your buddies; no one else can be invited into it." },
    { CMSG_GUILD_REMOVE,  "A buddy can't be sent away from your clan." },
    { CMSG_GUILD_LEAVE,   "You can't leave your clan; it is yours for good." },
    { CMSG_GUILD_DISBAND, "Your clan can't be disbanded." },
    { CMSG_GUILD_LEADER,  "You lead your clan, and always will." },
};
// }}}

// {{{ IsClanGuild
// Whether this guild id is some owner's clan guild. 0 (no guild) never is.
static bool IsClanGuild(uint32 guildId)
{
    if (!guildId)
        return false;
    return bool(CharacterDatabase.Query("SELECT 1 FROM buddy_clan WHERE clan_guild = {} LIMIT 1", guildId));
}
// }}}

class buddies_clan_lock_server : public ServerScript
{
public:
    buddies_clan_lock_server() : ServerScript("buddies_clan_lock_server", { SERVERHOOK_CAN_PACKET_RECEIVE }) { }

    // The server calls this read-only form (ScriptMgr::CanPacketReceive).
    // Returning false drops the request before its handler runs.
    bool CanPacketReceive(WorldSession* session, WorldPacket const& packet) override
    {
        if (!BuddiesEnabled() || !session)
            return true;                                   // no buddies, or a login-stage packet (no session yet)
        auto refused = sRefused.find(packet.GetOpcode());
        if (refused == sRefused.end())
            return true;                                   // not one of the five
        Player* player = session->GetPlayer();
        if (!player || !IsClanGuild(player->GetGuildId()))
            return true;                                   // an ordinary guild: the game's own rules apply
        ChatHandler(session).SendSysMessage(refused->second);
        return false;
    }
};

// {{{ AddSC_buddies_clan_lock
void AddSC_buddies_clan_lock()
{
    new buddies_clan_lock_server();
}
// }}}
