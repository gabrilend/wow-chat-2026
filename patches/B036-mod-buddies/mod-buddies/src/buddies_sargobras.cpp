/*
 * buddies_sargobras.cpp - the character named Sargobras, made on his own
 * account and logged in whenever the world server runs (issues 617b2, 630).
 *
 * For a general audience: a whisper can only reach a character that is
 * logged in. The owner, 2026-10-30: "Sargobras needs his own account for
 * the functionality related to him being every guild's guild master", and
 * of the whisper: "we can interact with the buddy-making menus, not open
 * them." So one character named Sargobras exists on an account of his own
 * (SARGOBRAS, a password nobody is told), logged in as a bot with no
 * master. He is invisible, rooted on the developers' island no player
 * reaches, hidden from /who as buddies are, takes no bot commands (his
 * account is on the companion list B044 and B045 read), and is no owner:
 * the buddy module makes him no buddies. He exists to receive whispers;
 * Sargobras's own script (patches/E066-sargobras/sargobras.lua) hears them
 * and answers through the Sargobras creature present, or by whisper from
 * this character when none is.
 *
 * The world pass, every SARGOBRAS_LOOK_MS, one of these:
 *   no account yet           - it is made (through the login database's
 *                              queue: found on a later look)
 *   no character yet         - he is made (a human man, level 1, his kit
 *                              the starting outfit), named Sargobras
 *   the name taken by a character on another account
 *                            - an error, logged once; nothing more is done
 *                              (a player took his name: the owner decides)
 *   made, not in the world   - logged in as a bot with no master, asked
 *                              again at most every SARGOBRAS_RETRY_MS
 *   in the world             - nothing
 * At his login: invisible, rooted, sent to his spot.
 */

#include "buddies.h"
#include "buddies_sargobras.h"
#include "AccountMgr.h"
#include "CompanionAccounts.h"
#include "CryptoRandom.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
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
static constexpr uint32 SARGOBRAS_LOOK_MS      = 10000;   // the world pass looks this often
static constexpr uint32 SARGOBRAS_RETRY_MS     = 60000;   // a login asked for and not yet seen: asked again after this
// his spot: the developers' island (map 1), out of every player's way
static constexpr uint32 SPOT_MAP = 1;
static constexpr float  SPOT_X = 16222.1f, SPOT_Y = 16252.1f, SPOT_Z = 12.58f, SPOT_O = 0.0f;

static std::atomic<uint32> sAccount{ 0 };              // his account once known

bool BuddyIsSargobrasAccount(uint32 accountId)
{
    return accountId && accountId == sAccount.load();
}

// {{{ buddies_sargobras_world
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

        // the account
        uint32 account = AccountMgr::GetId(SARGOBRAS_ACCOUNT);
        if (!account)
        {
            std::array<uint8, 8> bytes;                 // a password nobody is told, as the buddies' accounts
            Acore::Crypto::GetRandomBytes(bytes);
            AccountOpResult result = AccountMgr::instance()->CreateAccount(SARGOBRAS_ACCOUNT, ByteArrayToHexStr(bytes));
            if (result != AOR_OK)
            {
                LOG_ERROR("module", "mod-buddies: could not create Sargobras's account {} (account manager result {}); "
                    "no whisperable Sargobras until it can be made", SARGOBRAS_ACCOUNT, uint32(result));
                _stopped = true;
            }
            return;                                    // made through the queue: found at a later look
        }
        sAccount = account;
        CompanionAccounts::Mark(account);              // hidden from /who and add-friend, no bot commands (B044, B045)

        // the character
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
            return;                                    // logged in at the next look
        }
        uint32 guid = (*row)[0].Get<uint32>();

        // in the world, or brought in
        if (ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid)))
            return;
        if (_askedAt && now - _askedAt < SARGOBRAS_RETRY_MS)
            return;
        _askedAt = now;
        sRandomPlayerbotMgr.AddPlayerBot(ObjectGuid::Create<HighGuid::Player>(guid), 0);   // no master: nobody's bot
    }

private:
    uint32 _since = 0;
    uint64 _askedAt = 0;
    bool   _stopped = false;                           // an error said once: nothing more is tried this run
};
// }}}

// {{{ buddies_sargobras_player
class buddies_sargobras_player : public PlayerScript
{
public:
    buddies_sargobras_player() : PlayerScript("buddies_sargobras_player", { PLAYERHOOK_ON_LOGIN }) { }

    // At his login: unseen, unmoving, on his island.
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
// }}}

void AddSC_buddies_sargobras()
{
    new buddies_sargobras_world();
    new buddies_sargobras_player();
}
