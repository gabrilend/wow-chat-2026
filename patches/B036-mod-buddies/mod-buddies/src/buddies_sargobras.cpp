
#include "buddies.h"
#include "buddies_sargobras.h"
#include "AccountMgr.h"
#include "CompanionAccounts.h"
#include "CryptoRandom.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Guild.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Playerbots.h"
#include "RandomPlayerbotMgr.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "Util.h"
#include <array>
#include <atomic>

static constexpr char const* SARGOBRAS_ACCOUNT = "SARGOBRAS";
static constexpr char const* SARGOBRAS_NAME    = "Sargobras";
static constexpr uint32 SARGOBRAS_LOOK_MS      = 10000;
static constexpr uint32 SARGOBRAS_RETRY_MS     = 60000;
static constexpr uint32 SPOT_MAP = 1;
static constexpr float  SPOT_X = 16222.1f, SPOT_Y = 16252.1f, SPOT_Z = 12.58f, SPOT_O = 0.0f;

static std::atomic<uint32> sAccount{ 0 };

bool BuddyIsSargobrasAccount(uint32 accountId)
{
    return accountId && accountId == sAccount.load();
}

class buddies_sargobras_world : public WorldScript
{
public:
    buddies_sargobras_world() : WorldScript("buddies_sargobras_world", { WORLDHOOK_ON_UPDATE }) { }

    void OnUpdate(uint32 diff) override
    {
        if (!BuddiesEnabled() || _stopped)
            return;
        _since += diff;
        if (_since < SARGOBRAS_LOOK_MS)
            return;
        _since = 0;
        uint64 now = GameTime::GetGameTimeMS().count();

        uint32 account = AccountMgr::GetId(SARGOBRAS_ACCOUNT);
        if (!account)
        {
            std::array<uint8, 8> bytes;
            Acore::Crypto::GetRandomBytes(bytes);
            AccountOpResult result = AccountMgr::instance()->CreateAccount(SARGOBRAS_ACCOUNT, ByteArrayToHexStr(bytes));
            if (result != AOR_OK)
            {
                LOG_ERROR("module", "mod-buddies: could not create Sargobras's account {} (account manager result {}); "
                    "no whisperable Sargobras until it can be made", SARGOBRAS_ACCOUNT, uint32(result));
                _stopped = true;
            }
            return;
        }
        sAccount = account;
        CompanionAccounts::Mark(account);

        QueryResult row = CharacterDatabase.Query("SELECT guid, account FROM characters WHERE name = '{}'", SARGOBRAS_NAME);
        if (row && (*row)[1].Get<uint32>() != account)
        {
            LOG_ERROR("module", "mod-buddies: the name {} belongs to character {} on account {}, not Sargobras's account {}; "
                "no whisperable Sargobras (rename or delete that character, then restart)",
                SARGOBRAS_NAME, (*row)[0].Get<uint32>(), (*row)[1].Get<uint32>(), account);
            _stopped = true;
            return;
        }
        if (!row)
        {
            std::string name, why;
            uint32 guid = BuddyMakeCharacter(account, RACE_HUMAN, CLASS_WARRIOR, 1, 1, 0, 0, false, "Sargobras",
                "the whisperable Sargobras", name, why, SARGOBRAS_NAME, 0);
            if (!guid)
            {
                LOG_ERROR("module", "mod-buddies: could not make the character {}: {}; no whisperable Sargobras", SARGOBRAS_NAME, why);
                _stopped = true;
                return;
            }
            LOG_INFO("module", "mod-buddies: made the character {} (guid {}) on his own account, to receive whispers (617b2)", name, guid);
            return;
        }
        uint32 guid = (*row)[0].Get<uint32>();

        if (Player* him = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid)))
        {
            LeaveBotGuild(him);
            return;
        }
        if (_askedAt && now - _askedAt < SARGOBRAS_RETRY_MS)
            return;
        _askedAt = now;
        sRandomPlayerbotMgr.AddPlayerBot(ObjectGuid::Create<HighGuid::Player>(guid), 0);
    }

private:
    void LeaveBotGuild(Player* him)
    {
        Guild* g = him->GetGuild();
        if (!g)
            return;
        std::string name = g->GetName();
        if (g->GetMemberCount() <= 1)
            g->Disband();
        else
            g->DeleteMember(him->GetGUID(), false, false, false);
        LOG_INFO("module", "mod-buddies: {} taken out of the guild \"{}\" the bot module put him in (630 decides his guilds)",
            SARGOBRAS_NAME, name);
    }

    uint32 _since = 0;
    uint64 _askedAt = 0;
    bool   _stopped = false;
};

class buddies_sargobras_player : public PlayerScript
{
public:
    buddies_sargobras_player() : PlayerScript("buddies_sargobras_player", { PLAYERHOOK_ON_LOGIN }) { }

    void OnPlayerLogin(Player* player) override
    {
        if (!BuddyIsSargobrasAccount(player->GetSession()->GetAccountId()))
            return;
        player->SetVisible(false);
        player->SetControlled(true, UNIT_STATE_ROOT);
        player->TeleportTo(SPOT_MAP, SPOT_X, SPOT_Y, SPOT_Z, SPOT_O);
        LOG_INFO("module", "mod-buddies: {} is in the world, unseen, to receive whispers (617b2)", player->GetName());
    }
};

void AddSC_buddies_sargobras()
{
    new buddies_sargobras_world();
    new buddies_sargobras_player();
}
