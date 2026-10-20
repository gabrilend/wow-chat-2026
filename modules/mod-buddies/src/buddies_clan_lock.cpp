
#include "buddies.h"
#include "Chat.h"
#include "DatabaseEnv.h"
#include "Opcodes.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <unordered_map>

static std::unordered_map<uint16, char const*> const sRefused = {
    { CMSG_GUILD_INVITE,  "Your clan is you and your buddies; no one else can be invited into it." },
    { CMSG_GUILD_REMOVE,  "A buddy can't be sent away from your clan." },
    { CMSG_GUILD_LEAVE,   "You can't leave your clan; it is yours for good." },
    { CMSG_GUILD_DISBAND, "Your clan can't be disbanded." },
    { CMSG_GUILD_LEADER,  "You lead your clan, and always will." },
};

static bool IsClanGuild(uint32 guildId)
{
    if (!guildId)
        return false;
    return bool(CharacterDatabase.Query("SELECT 1 FROM buddy_clan WHERE clan_guild = {} LIMIT 1", guildId));
}

class buddies_clan_lock_server : public ServerScript
{
public:
    buddies_clan_lock_server() : ServerScript("buddies_clan_lock_server", { SERVERHOOK_CAN_PACKET_RECEIVE }) { }

    bool CanPacketReceive(WorldSession* session, WorldPacket const& packet) override
    {
        if (!BuddiesEnabled() || !session)
            return true;
        auto refused = sRefused.find(packet.GetOpcode());
        if (refused == sRefused.end())
            return true;
        Player* player = session->GetPlayer();
        if (!player || !IsClanGuild(player->GetGuildId()))
            return true;
        ChatHandler(session).SendSysMessage(refused->second);
        return false;
    }
};

void AddSC_buddies_clan_lock()
{
    new buddies_clan_lock_server();
}
