
#include "buddies.h"
#include "buddies_roles.h"
#include "buddies_spells.h"
#include "buddies_kit.h"
#include "buddies_stand_ins_pick.h"
#include "AccountMgr.h"
#include "CharacterCache.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "CompanionAccounts.h"
#include "CryptoRandom.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "Random.h"
#include "RandomPlayerbotMgr.h"
#include "ScriptMgr.h"
#include "Util.h"
#include <array>
#include <map>
#include <shared_mutex>
#include <unordered_set>

using namespace Acore::ChatCommands;

static constexpr uint32 STAND_INS_PER_ACCOUNT = 200;
static constexpr uint64 STAND_IN_APPEAR_MS    = 30000;
static constexpr uint32 STAND_IN_CHECK_MS     = 500;

static std::unordered_set<uint32> sStandInAccounts;
static std::shared_mutex          sStandInAccountsLock;

static std::string StandInAccountName(uint32 n) { return "STANDIN" + std::to_string(n); }

bool BuddyIsStandInAccount(uint32 accountId)
{
    std::shared_lock<std::shared_mutex> read(sStandInAccountsLock);
    return sStandInAccounts.count(accountId) != 0;
}

bool BuddyIsNotAPlayer(uint32 accountId)
{
    return BuddyIsStandInAccount(accountId) || BuddyIsCompanionAccount(accountId);
}

static void RememberStandInAccount(uint32 id)
{
    {
        std::unique_lock<std::shared_mutex> write(sStandInAccountsLock);
        sStandInAccounts.insert(id);
    }
    CompanionAccounts::Mark(id);
}

static uint32 AccountWithRoom(std::string& why)
{
    for (uint32 n = 1; ; ++n)
    {
        std::string name = StandInAccountName(n);
        uint32 id = AccountMgr::GetId(name);
        if (!id)
        {
            std::array<uint8, 8> bytes;
            Acore::Crypto::GetRandomBytes(bytes);
            AccountOpResult result = AccountMgr::instance()->CreateAccount(name, ByteArrayToHexStr(bytes));
            if (result != AOR_OK)
                why = "could not create account " + name + " (account manager result " + std::to_string(uint32(result)) + ")";
            else
                why = "account " + name + " is being made; ask again in a moment";
            return 0;
        }
        RememberStandInAccount(id);
        QueryResult count = CharacterDatabase.Query("SELECT COUNT(*) FROM characters WHERE account = {}", id);
        if (!count || (*count)[0].Get<uint64>() < STAND_INS_PER_ACCOUNT)
            return id;
    }
}

static uint8 SideOfRace(uint8 race) { return Player::TeamIdForRace(race) == TEAM_HORDE ? 1 : 0; }

static std::vector<std::pair<uint8, uint8>> GamePairs()
{
    std::vector<std::pair<uint8, uint8>> pairs;
    for (uint8 race = 1; race <= RACE_DRAENEI; ++race)
        for (uint8 cls = 1; cls < MAX_CLASSES; ++cls)
            if (sObjectMgr->GetPlayerInfo(race, cls))
                pairs.emplace_back(race, cls);
    return pairs;
}


static std::map<std::string, uint8> const RACE_BY_NAME = {
    { "human", RACE_HUMAN }, { "orc", RACE_ORC }, { "dwarf", RACE_DWARF }, { "nightelf", RACE_NIGHTELF },
    { "undead", RACE_UNDEAD_PLAYER }, { "tauren", RACE_TAUREN }, { "gnome", RACE_GNOME }, { "troll", RACE_TROLL },
    { "bloodelf", RACE_BLOODELF }, { "draenei", RACE_DRAENEI },
};
static std::map<std::string, uint8> const CLASS_BY_NAME = {
    { "warrior", CLASS_WARRIOR }, { "paladin", CLASS_PALADIN }, { "hunter", CLASS_HUNTER }, { "rogue", CLASS_ROGUE },
    { "priest", CLASS_PRIEST }, { "deathknight", CLASS_DEATH_KNIGHT }, { "shaman", CLASS_SHAMAN }, { "mage", CLASS_MAGE },
    { "warlock", CLASS_WARLOCK }, { "druid", CLASS_DRUID },
};
static std::map<std::string, uint8> const ROLE_BY_NAME = {
    { "damage", uint8(BuddyRole::Damage) }, { "dps", uint8(BuddyRole::Damage) },
    { "tank", uint8(BuddyRole::Tank) }, { "healer", uint8(BuddyRole::Healer) }, { "heal", uint8(BuddyRole::Healer) },
};
static char const* const ROLE_NAMES[3] = { "damage", "tank", "healer" };

static uint8 Lookup(std::map<std::string, uint8> const& names, std::string text)
{
    std::string key;
    for (char c : text)
        if (c != ' ' && c != '-' && c != '_')
            key += char(std::tolower(static_cast<unsigned char>(c)));
    if (!key.empty() && key.find_first_not_of("0123456789") == std::string::npos)
        return uint8(std::stoul(key));
    auto it = names.find(key);
    return it == names.end() ? 0 : it->second;
}

struct StandInDue
{
    uint32 map;
    float  x, y, z, o;
    uint8  shape;
    uint8  role;
    bool   raised;
    uint64 asked;
};
static std::map<uint32, StandInDue> sDue;

uint32 BuddyBringStandIn(uint8 side, uint8 role, uint8 level, uint8 race, uint8 cls,
    uint32 map, float x, float y, float z, float o, std::string& said)
{
    if (role > 2 || side > 1 || level < 1 || level > DEFAULT_MAX_LEVEL)
    {
        said = "asked for side " + std::to_string(side) + ", role " + std::to_string(role) + ", level " + std::to_string(level)
            + ": side is alliance or horde, role tank, healer or damage, level 1 to " + std::to_string(DEFAULT_MAX_LEVEL);
        return 0;
    }

    std::vector<std::pair<uint8, uint8>> pairs;
    for (auto const& p : BuddyStandIn::PairsFor(GamePairs(), side, role, SideOfRace))
        if ((!race || p.first == race) && (!cls || p.second == cls))
            pairs.push_back(p);
    if (pairs.empty())
    {
        said = std::string("no ") + (side ? "Horde" : "Alliance") + " race and class pair"
            + (race ? " of race " + std::to_string(race) : "") + (cls ? " of class " + std::to_string(cls) : "")
            + " can take the role " + ROLE_NAMES[role];
        return 0;
    }
    auto pick = pairs[urand(0, uint32(pairs.size()) - 1)];
    race = pick.first;
    cls  = pick.second;

    std::vector<BuddyStandIn::Kept> kept;
    std::map<uint32, uint8> shapeOf;
    if (QueryResult rows = CharacterDatabase.Query(
            "SELECT guid, race, class, role, level, profile FROM buddy_stand_in WHERE race = {} AND class = {} AND role = {} AND level <= {}",
            race, cls, role, level))
        do
        {
            uint32 guid = (*rows)[0].Get<uint32>();
            bool inWorld = sDue.count(guid) || ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid));
            kept.push_back({ guid, (*rows)[1].Get<uint8>(), (*rows)[2].Get<uint8>(), (*rows)[3].Get<uint8>(), (*rows)[4].Get<uint8>(), inWorld });
            shapeOf[guid] = (*rows)[5].Get<uint8>();
        } while (rows->NextRow());
    uint32 guid  = BuddyStandIn::PickKept(kept, race, cls, role, level);
    uint8  shape = 0;
    bool   raised = false;
    std::string name;

    if (guid)
    {
        shape = shapeOf[guid];
        sCharacterCache->GetCharacterNameByGuid(ObjectGuid::Create<HighGuid::Player>(guid), name);
        for (auto const& k : kept)
            if (k.guid == guid && k.level < level)
                raised = true;
        if (raised)
        {
            CharacterDatabase.DirectExecute("UPDATE characters SET level = {}, xp = 0 WHERE guid = {}", level, guid);
            CharacterDatabase.DirectExecute("UPDATE buddy_stand_in SET level = {} WHERE guid = {}", level, guid);
            sCharacterCache->UpdateCharacterLevel(ObjectGuid::Create<HighGuid::Player>(guid), level);
        }
        said = "kept stand-in " + name + (raised ? ", raised to " + std::to_string(level) : "");
    }
    else
    {
        std::vector<uint8_t> shapes = BuddyStandIn::ShapesForRole(cls, role);
        shape = shapes[urand(0, uint32(shapes.size()) - 1)];
        std::string why;
        uint32 account = AccountWithRoom(why);
        if (!account)
        {
            said = why;
            return 0;
        }
        std::string forWhom = std::string("a ") + (side ? "Horde" : "Alliance") + " " + ROLE_NAMES[role] + " stand-in";
        guid = BuddyMakeCharacter(account, race, cls, level, shape, role, 0, true, "stand-in", forWhom, name, why);
        if (!guid)
        {
            said = "could not make a stand-in (race " + std::to_string(race) + ", class " + std::to_string(cls) + "): " + why;
            return 0;
        }
        CharacterDatabase.DirectExecute("INSERT INTO buddy_stand_in (guid, race, class, role, profile, level, made) "
            "VALUES ({}, {}, {}, {}, {}, {}, UNIX_TIMESTAMP())", guid, race, cls, role, shape, level);
        said = "new stand-in " + name;
    }

    CharacterDatabase.Execute("UPDATE buddy_stand_in SET uses = uses + 1, last_used = UNIX_TIMESTAMP() WHERE guid = {}", guid);
    sDue[guid] = { map, x, y, z, o, shape, role, raised, uint64(GameTime::GetGameTimeMS().count()) };
    sRandomPlayerbotMgr.AddPlayerBot(ObjectGuid::Create<HighGuid::Player>(guid), 0);
    said += std::string(" (") + ROLE_NAMES[role] + ", race " + std::to_string(race) + ", class " + std::to_string(cls)
        + ", shape " + std::to_string(shape) + ", level " + std::to_string(level) + ") is on its way";
    LOG_INFO("module", "mod-buddies: {}", said);
    return guid;
}

static void FirstMoments(Player* standIn, StandInDue const& due)
{
    std::string problems;
    if (due.raised)
    {
        BuddyLearnEverything(standIn);
        problems += BuddyRegear(standIn, due.shape);
        problems += BuddyGivePvpJewellery(standIn, due.shape, due.role);
    }
    if (standIn->GetFreeTalentPoints())
        problems += std::to_string(standIn->GetFreeTalentPoints()) + " talent points unspent (is src/lua-basic/buddy-talents.lua "
            "loaded? on cc-test, through src/lua-cc-test/buddy-talents.lua); ";
    if (PlayerbotAI* ai = GET_PLAYERBOT_AI(standIn))
        ai->ResetStrategies();
    if (!standIn->TeleportTo(due.map, due.x, due.y, due.z, due.o))
        problems += "could not move to map " + std::to_string(due.map) + " (" + std::to_string(int(due.x)) + ", "
            + std::to_string(int(due.y)) + ", " + std::to_string(int(due.z)) + "); ";
    if (!problems.empty())
        LOG_ERROR("module", "mod-buddies: stand-in {}: {}", standIn->GetName(), problems);
    else
        LOG_INFO("module", "mod-buddies: stand-in {} is in the world (shape {}, map {})", standIn->GetName(), due.shape, due.map);
}

class buddies_stand_ins_world : public WorldScript
{
public:
    buddies_stand_ins_world() : WorldScript("buddies_stand_ins_world", { WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_UPDATE }) { }

    void OnStartup() override
    {
        if (!BuddiesEnabled())
            return;
        uint32 n = 0;
        if (QueryResult rows = LoginDatabase.Query("SELECT id FROM account WHERE username LIKE 'STANDIN%'"))
            do
            {
                RememberStandInAccount((*rows)[0].Get<uint32>());
                ++n;
            } while (rows->NextRow());
        LOG_INFO("module", "mod-buddies: {} stand-in accounts", n);
    }

    void OnUpdate(uint32 diff) override
    {
        _sinceLast += diff;
        if (_sinceLast < STAND_IN_CHECK_MS || sDue.empty())
            return;
        _sinceLast = 0;
        uint64 now = uint64(GameTime::GetGameTimeMS().count());
        for (auto it = sDue.begin(); it != sDue.end(); )
        {
            Player* standIn = ObjectAccessor::FindPlayer(ObjectGuid::Create<HighGuid::Player>(it->first));
            if (standIn && standIn->IsInWorld() && GET_PLAYERBOT_AI(standIn))
            {
                FirstMoments(standIn, it->second);
                it = sDue.erase(it);
                continue;
            }
            if (now - it->second.asked > STAND_IN_APPEAR_MS)
            {
                LOG_ERROR("module", "mod-buddies: stand-in {} did not appear in the world within {} seconds; "
                    "given up (is the bot module enabled? see its log for the login)", it->first, STAND_IN_APPEAR_MS / 1000);
                it = sDue.erase(it);
                continue;
            }
            ++it;
        }
    }

private:
    uint32 _sinceLast = 0;
};

class buddies_stand_ins_player : public PlayerScript
{
public:
    buddies_stand_ins_player() : PlayerScript("buddies_stand_ins_player", { PLAYERHOOK_ON_DELETE }) { }

    void OnPlayerDelete(ObjectGuid guid, uint32 accountId) override
    {
        if (BuddiesEnabled() && BuddyIsStandInAccount(accountId))
            CharacterDatabase.Execute("DELETE FROM buddy_stand_in WHERE guid = {}", guid.GetCounter());
    }
};

class buddies_stand_ins_command : public CommandScript
{
public:
    buddies_stand_ins_command() : CommandScript("buddies_stand_ins_command") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "buddy standin make",    HandleMake,    SEC_GAMEMASTER, Console::No  },
            { "buddy standin at",      HandleAt,      SEC_GAMEMASTER, Console::Yes },
            { "buddy standin list",    HandleList,    SEC_GAMEMASTER, Console::Yes },
            { "buddy standin dismiss", HandleDismiss, SEC_GAMEMASTER, Console::Yes },
        };
        return commandTable;
    }

    static bool Kind(ChatHandler* handler, std::string const& sideText, std::string const& roleText,
        Optional<std::string> const& raceText, Optional<std::string> const& classText,
        uint8& side, uint8& role, uint8& race, uint8& cls)
    {
        std::string s = sideText;
        for (char& c : s) c = char(std::tolower(static_cast<unsigned char>(c)));
        if (s == "alliance" || s == "a")    side = 0;
        else if (s == "horde" || s == "h")  side = 1;
        else
        {
            handler->PSendSysMessage("The side is alliance or horde (got '{}').", sideText);
            return false;
        }
        std::string roleKey = roleText;
        for (char& c : roleKey) c = char(std::tolower(static_cast<unsigned char>(c)));
        auto r = ROLE_BY_NAME.find(roleKey);
        if (r == ROLE_BY_NAME.end())
        {
            handler->PSendSysMessage("The role is tank, healer or damage (got '{}').", roleText);
            return false;
        }
        role = r->second;
        race = raceText ? Lookup(RACE_BY_NAME, *raceText) : 0;
        cls  = classText ? Lookup(CLASS_BY_NAME, *classText) : 0;
        if ((raceText && !race) || (classText && !cls))
        {
            handler->PSendSysMessage("Unknown race or class (got '{}', '{}'); races: human, orc, dwarf, nightelf, undead, "
                "tauren, gnome, troll, bloodelf, draenei; classes: warrior, paladin, hunter, rogue, priest, deathknight, "
                "shaman, mage, warlock, druid; or their numbers.", raceText ? *raceText : "", classText ? *classText : "");
            return false;
        }
        return true;
    }

    static bool HandleMake(ChatHandler* handler, std::string sideText, std::string roleText, uint8 level,
        Optional<std::string> raceText, Optional<std::string> classText)
    {
        Player* gm = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
        if (!gm)
            return false;
        uint8 side, role, race, cls;
        if (!Kind(handler, sideText, roleText, raceText, classText, side, role, race, cls))
            return false;
        std::string said;
        float x = gm->GetPositionX() + 2.0f * std::cos(gm->GetOrientation());
        float y = gm->GetPositionY() + 2.0f * std::sin(gm->GetOrientation());
        uint32 guid = BuddyBringStandIn(side, role, level, race, cls, gm->GetMapId(), x, y, gm->GetPositionZ(),
            gm->GetOrientation() + float(M_PI), said);
        handler->PSendSysMessage("{}", said);
        return guid != 0;
    }

    static bool HandleAt(ChatHandler* handler, std::string sideText, std::string roleText, uint8 level,
        uint32 map, float x, float y, float z, Optional<std::string> raceText, Optional<std::string> classText)
    {
        uint8 side, role, race, cls;
        if (!Kind(handler, sideText, roleText, raceText, classText, side, role, race, cls))
            return false;
        std::string said;
        uint32 guid = BuddyBringStandIn(side, role, level, race, cls, map, x, y, z, 0.0f, said);
        handler->PSendSysMessage("{}", said);
        return guid != 0;
    }

    static bool HandleList(ChatHandler* handler)
    {
        QueryResult rows = CharacterDatabase.Query(
            "SELECT s.guid, c.name, s.race, s.class, s.role, s.profile, s.level, s.uses FROM buddy_stand_in s "
            "JOIN characters c ON c.guid = s.guid ORDER BY s.role, s.class, s.level DESC");
        if (!rows)
        {
            handler->PSendSysMessage("No stand-ins are kept yet.");
            return true;
        }
        uint32 n = 0, inWorld = 0;
        do
        {
            uint32 guid = (*rows)[0].Get<uint32>();
            bool here = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid)) != nullptr;
            uint8 role = (*rows)[4].Get<uint8>();
            handler->PSendSysMessage("{} {}: race {}, class {}, {} (shape {}), level {}, used {} times{}",
                guid, (*rows)[1].Get<std::string>(), (*rows)[2].Get<uint8>(), (*rows)[3].Get<uint8>(),
                role < 3 ? ROLE_NAMES[role] : "?", (*rows)[5].Get<uint8>(), (*rows)[6].Get<uint8>(),
                (*rows)[7].Get<uint32>(), here ? ", in the world" : "");
            ++n;
            inWorld += here;
        } while (rows->NextRow());
        handler->PSendSysMessage("{} kept, {} in the world.", n, inWorld);
        return true;
    }

    static bool HandleDismiss(ChatHandler* handler, std::string who)
    {
        uint32 n = 0;
        if (QueryResult rows = CharacterDatabase.Query(
                "SELECT s.guid, c.name FROM buddy_stand_in s JOIN characters c ON c.guid = s.guid"))
            do
            {
                std::string name = (*rows)[1].Get<std::string>();
                if (who != "all" && name != who)
                    continue;
                ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>((*rows)[0].Get<uint32>());
                sDue.erase(guid.GetCounter());
                if (ObjectAccessor::FindConnectedPlayer(guid))
                {
                    sRandomPlayerbotMgr.LogoutPlayerBot(guid);
                    ++n;
                }
            } while (rows->NextRow());
        handler->PSendSysMessage("{} stand-in{} dismissed (kept for the next asker).", n, n == 1 ? "" : "s");
        return true;
    }
};

void AddSC_buddies_stand_ins()
{
    new buddies_stand_ins_world();
    new buddies_stand_ins_player();
    new buddies_stand_ins_command();
}
