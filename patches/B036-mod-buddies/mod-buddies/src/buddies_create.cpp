
#include "buddies.h"
#include "buddies_spells.h"
#include "buddies_loot.h"
#include "buddies_gems.h"
#include "buddies_kit.h"
#include "CharacterCache.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "World.h"
#include "WorldSession.h"
#include <map>
#include <set>
#include <utility>
#include <vector>

static constexpr uint32 BUDDY_CREATE_EVERY_MS  = 5000;
static constexpr uint32 BUDDY_CREATE_PER_PASS  = 5;
static constexpr uint32 BUDDY_ACCOUNT_PATIENCE = 12;

static std::set<std::pair<uint32, uint8>>          sFailed;
static std::map<std::pair<uint32, uint8>, uint32> sWaiting;

static uint8 NameGroupFor(uint8 race, uint8 gender)
{
    static std::map<uint8, uint8> const firstOfPair = {
        { RACE_HUMAN,  0 }, { RACE_UNDEAD_PLAYER, 0 },
        { RACE_GNOME,  2 }, { RACE_DWARF,  4 }, { RACE_NIGHTELF, 6 }, { RACE_DRAENEI,  8 },
        { RACE_ORC,   10 }, { RACE_TROLL, 12 }, { RACE_TAUREN,  14 }, { RACE_BLOODELF, 16 },
    };
    auto it = firstOfPair.find(race);
    return uint8((it == firstOfPair.end() ? 0 : it->second) + (gender == GENDER_FEMALE ? 1 : 0));
}

static std::string PickName(uint8 race, uint8 gender)
{
    for (int tries = 0; tries < 5; ++tries)
    {
        QueryResult r = CharacterDatabase.Query(
            "SELECT n.name FROM playerbots_names n LEFT JOIN characters c ON c.name = n.name "
            "WHERE c.guid IS NULL AND n.gender = {} ORDER BY RAND() LIMIT 1", NameGroupFor(race, gender));
        if (!r)
            return "";
        std::string name = (*r)[0].Get<std::string>();
        if (ObjectMgr::CheckPlayerName(name, true) == CHAR_NAME_SUCCESS && !sObjectMgr->IsReservedName(name))
            return name;
    }
    return "";
}

struct BuddyLooks { uint8 skin = 0, face = 0, hairStyle = 0, hairColor = 0, facialHair = 0; bool ok = false; };

static BuddyLooks PickLooks(uint8 race, uint8 gender)
{
    std::vector<uint8> facialHairs;
    std::vector<std::pair<uint8, uint8>> faces, hairs;
    for (CharSectionsEntry const* s : sCharSectionsStore)
    {
        if (s->RaceID != race || s->SexID != gender)
            continue;
        if (s->BaseSection == SECTION_TYPE_FACE)             faces.emplace_back(s->VariationIndex, s->ColorIndex);
        else if (s->BaseSection == SECTION_TYPE_HAIR)        hairs.emplace_back(s->VariationIndex, s->ColorIndex);
        else if (s->BaseSection == SECTION_TYPE_FACIAL_HAIR) facialHairs.push_back(s->VariationIndex);
    }
    BuddyLooks looks;
    if (faces.empty() || hairs.empty())
        return looks;
    auto face = faces[urand(0, faces.size() - 1)];
    auto hair = hairs[urand(0, hairs.size() - 1)];
    bool noBeard = race == RACE_TAUREN || race == RACE_DRAENEI
                || (gender == GENDER_FEMALE && race != RACE_NIGHTELF && race != RACE_UNDEAD_PLAYER);
    looks.skin       = face.second;
    looks.face       = face.first;
    looks.hairStyle  = hair.first;
    looks.hairColor  = hair.second;
    looks.facialHair = (noBeard || facialHairs.empty()) ? 0 : facialHairs[urand(0, facialHairs.size() - 1)];
    looks.ok         = true;
    return looks;
}

struct SecondaryProfession
{
    uint32 skill;
    uint32 spell;
};
static SecondaryProfession const sSecondary[] = {
    { SKILL_COOKING,   2550 },
    { SKILL_FIRST_AID, 3273 },
    { SKILL_FISHING,   7620 },
};
static constexpr uint32 FISHING_POLE_ITEM = 6256;

static std::string GiveSecondaryProfessions(Player* buddy)
{
    for (SecondaryProfession const& p : sSecondary)
        if (!buddy->HasSkill(p.skill))
            buddy->learnSpell(p.spell, false);
    if (!buddy->HasItemCount(FISHING_POLE_ITEM, 1, false))
    {
        bool poleInHand = false;
        if (Item* held = buddy->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_MAINHAND))
            poleInHand = held->GetTemplate()->SubClass == ITEM_SUBCLASS_WEAPON_FISHING_POLE &&
                         held->GetTemplate()->Class == ITEM_CLASS_WEAPON;
        if (!poleInHand && !buddy->StoreNewItemInBestSlots(FISHING_POLE_ITEM, 1))
            return "no room in its bags for a fishing pole";
    }
    for (SecondaryProfession const& p : sSecondary)
        if (!buddy->HasSkill(p.skill))
            return "learning spell " + std::to_string(p.spell) + " did not give skill " + std::to_string(p.skill);
    return std::string();
}

struct CraftingProfession { uint32 skill; uint32 spell; uint32 tool; uint32 feedsFrom; };
struct GatheringProfession { uint32 skill; uint32 spell; uint32 tool; uint32 extra[2]; };
static CraftingProfession const sCrafting[] = {
    { SKILL_ALCHEMY,        2259,  0,     SKILL_HERBALISM },
    { SKILL_BLACKSMITHING,  2018,  5956,  SKILL_MINING    },
    { SKILL_ENCHANTING,     7411,  6218,  0               },
    { SKILL_ENGINEERING,    4036,  6219,  SKILL_MINING    },
    { SKILL_INSCRIPTION,    45357, 39505, SKILL_HERBALISM },
    { SKILL_JEWELCRAFTING,  25229, 20815, SKILL_MINING    },
    { SKILL_LEATHERWORKING, 2108,  0,     SKILL_SKINNING  },
    { SKILL_TAILORING,      3908,  0,     0               },
};
static GatheringProfession const sGathering[] = {
    { SKILL_HERBALISM, 2366, 0,    { 2383, 0    } },
    { SKILL_MINING,    2575, 2901, { 2580, 2656 } },
    { SKILL_SKINNING,  8613, 7005, { 0,    0    } },
};

static std::string GivePrimaryProfessions(Player* buddy)
{
    CraftingProfession const* craft = nullptr;
    for (CraftingProfession const& c : sCrafting)
        if (buddy->HasSkill(c.skill))
            craft = &c;
    if (!craft)
    {
        craft = &sCrafting[urand(0, uint32(std::size(sCrafting)) - 1)];
        buddy->learnSpell(craft->spell, false);
    }
    GatheringProfession const* gather = nullptr;
    for (GatheringProfession const& g : sGathering)
        if (buddy->HasSkill(g.skill))
            gather = &g;
    if (!gather)
    {
        for (GatheringProfession const& g : sGathering)
            if (g.skill == craft->feedsFrom)
                gather = &g;
        if (!gather)
            gather = &sGathering[urand(0, uint32(std::size(sGathering)) - 1)];
        buddy->learnSpell(gather->spell, false);
        for (uint32 extra : gather->extra)
            if (extra)
                buddy->learnSpell(extra, false);
    }
    std::string problems;
    for (uint32 tool : { craft->tool, gather->tool })
        if (tool && !buddy->HasItemCount(tool, 1, true) && !buddy->StoreNewItemInBestSlots(tool, 1))
            problems += "no room in its bags for tool " + std::to_string(tool) + "; ";
    if (!buddy->HasSkill(craft->skill))
        problems += "learning spell " + std::to_string(craft->spell) + " did not give skill " + std::to_string(craft->skill) + "; ";
    if (!buddy->HasSkill(gather->skill))
        problems += "learning spell " + std::to_string(gather->spell) + " did not give skill " + std::to_string(gather->skill) + "; ";
    return problems;
}

struct ArtisanRank { uint32 skill; uint32 spell; };
static ArtisanRank const sArtisan[] = {
    { SKILL_ALCHEMY, 11611 }, { SKILL_BLACKSMITHING, 9785 }, { SKILL_ENCHANTING, 13920 }, { SKILL_ENGINEERING, 12656 },
    { SKILL_INSCRIPTION, 45360 }, { SKILL_JEWELCRAFTING, 28895 }, { SKILL_LEATHERWORKING, 10662 }, { SKILL_TAILORING, 12180 },
    { SKILL_HERBALISM, 11993 }, { SKILL_MINING, 10248 }, { SKILL_SKINNING, 10768 },
    { SKILL_COOKING, 18260 }, { SKILL_FIRST_AID, 10846 }, { SKILL_FISHING, 18248 },
};
static constexpr uint16 ARTISAN_STEP = 4, ARTISAN_MAX = 300;

static std::string MaxDeathKnightProfessions(Player* buddy)
{
    if (buddy->getClass() != CLASS_DEATH_KNIGHT)
        return std::string();
    for (ArtisanRank const& a : sArtisan)
        if (buddy->HasSkill(a.skill) && buddy->GetMaxSkillValue(a.skill) < ARTISAN_MAX)
        {
            buddy->learnSpell(a.spell, false);
            buddy->SetSkill(a.skill, ARTISAN_STEP, ARTISAN_MAX, ARTISAN_MAX);
        }
    return std::string();
}

static void Fail(uint32 owner, uint8 slot, uint8 race, uint8 cls, std::string const& why)
{
    sFailed.insert({ owner, slot });
    sWaiting.erase({ owner, slot });
    LOG_ERROR("module", "mod-buddies: could not make owner {}'s buddy in slot {} (race {}, class {}): {}. "
        "The slot stays chosen; tried again after the owner's next login.", owner, slot, race, cls, why);
}

uint32 BuddyMakeCharacter(uint32 account, uint8 race, uint8 cls, uint8 level, uint8 shape, uint8 role,
    uint32 bagsLike, bool pvpJewellery, char const* kind, std::string const& forWhom, std::string& name, std::string& why)
{
    uint8 gender = urand(0, 1) ? GENDER_MALE : GENDER_FEMALE;
    name = PickName(race, gender);
    if (name.empty())
    {
        why = "no unused name is left in playerbots_names for this race and gender";
        return 0;
    }
    BuddyLooks looks = PickLooks(race, gender);
    if (!looks.ok)
    {
        why = "CharSections.dbc has no face or hair for this race and gender";
        return 0;
    }

    CharacterCreateInfo info(name, race, cls, gender, looks.skin, looks.face, looks.hairStyle, looks.hairColor, looks.facialHair);

    WorldSession* session = new WorldSession(account, "", 0, nullptr, SEC_PLAYER, sWorld->getIntConfig(CONFIG_EXPANSION),
        time_t(0), LOCALE_enUS, 0, false, false, 0);
    Player* made = new Player(session);
    made->GetMotionMaster()->Initialize();
    if (!made->Create(sObjectMgr->GetGenerator<HighGuid::Player>().Generate(), &info))
    {
        made->CleanupsBeforeDelete();
        delete made;
        delete session;
        why = "the server refused to create the character (name '" + name + "')";
        return 0;
    }

    made->setCinematic(2);
    made->SetAtLoginFlag(AT_LOGIN_NONE);
    if (cls == CLASS_DEATH_KNIGHT)
        made->learnSpell(50977, false);
    if (level > made->GetLevel())
        made->SetLevel(level);
    std::string missing = GiveSecondaryProfessions(made) + GivePrimaryProfessions(made)
        + MaxDeathKnightProfessions(made);
    if (!missing.empty())
        LOG_ERROR("module", "mod-buddies: new {} {} for {}: {}; it tries again at its first login",
            kind, name, forWhom, missing);
    uint32 lessons = BuddyLearnEverything(made);
    LOG_INFO("module", "mod-buddies: new {} {} (level {}) knows {} spells from trainers and quests", kind, name, made->GetLevel(), lessons);
    std::string professionProblems;
    uint32 practised = BuddyRaiseProfessions(made, professionProblems);
    LOG_INFO("module", "mod-buddies: new {} {}: {} profession skills and recipes for level {}{}{}", kind, name, practised,
        made->GetLevel(), professionProblems.empty() ? "" : "; ", professionProblems);
    std::string kitProblems = BuddyGiveStartingKit(made, bagsLike, shape);
    if (!kitProblems.empty())
        LOG_ERROR("module", "mod-buddies: new {} {} for {} (level {}), starting kit incomplete: {}",
            kind, name, forWhom, made->GetLevel(), kitProblems);
    if (pvpJewellery)
    {
        std::string jewelProblems = BuddyGivePvpJewellery(made, shape, role);
        if (!jewelProblems.empty())
            LOG_ERROR("module", "mod-buddies: new {} {} for {}, PvP jewellery incomplete: {}", kind, name, forWhom, jewelProblems);
    }
    std::string gemProblems = BuddyGemKit(made, shape, role);
    if (!gemProblems.empty())
        LOG_ERROR("module", "mod-buddies: new {} {} for {}, kit gems incomplete: {}", kind, name, forWhom, gemProblems);

    uint32 guid = made->GetGUID().GetCounter();
    made->SaveToDB(true, false);
    sCharacterCache->AddCharacterCacheEntry(made->GetGUID(), account, made->GetName(), made->getGender(),
        made->getRace(), made->getClass(), made->GetLevel());
    made->CleanupsBeforeDelete();
    delete made;
    delete session;
    sWorld->UpdateRealmCharCount(account);
    return guid;
}

static void CreateBuddy(uint32 owner, uint8 slot, uint8 cls, uint8 race)
{
    std::pair<uint32, uint8> key{ owner, slot };

    uint32 account = BuddyCompanionAccountId(owner);
    if (!account)
    {
        if (++sWaiting[key] >= BUDDY_ACCOUNT_PATIENCE)
            Fail(owner, slot, race, cls, "the owner's companion account " + BuddyCompanionAccountName(owner) + " does not exist");
        return;
    }
    sWaiting.erase(key);

    QueryResult ownerRow = CharacterDatabase.Query("SELECT race, level FROM characters WHERE guid = {}", owner);
    if (!ownerRow)
        return Fail(owner, slot, race, cls, "the owner character no longer exists");
    uint8 ownerRace  = (*ownerRow)[0].Get<uint8>();
    uint8 ownerLevel = (*ownerRow)[1].Get<uint8>();

    if (Player::TeamIdForRace(race) != Player::TeamIdForRace(ownerRace))
        return Fail(owner, slot, race, cls, "the race is not of the owner's faction");
    if (!sObjectMgr->GetPlayerInfo(race, cls))
        return Fail(owner, slot, race, cls, "that race can't be that class");

    QueryResult plan = CharacterDatabase.Query("SELECT profile, role FROM buddy_roster WHERE owner = {} AND slot = {}", owner, slot);
    uint8 profile = plan ? (*plan)[0].Get<uint8>() : 0;
    uint8 role    = plan ? (*plan)[1].Get<uint8>() : 0;
    std::string name, why;
    uint32 guid = BuddyMakeCharacter(account, race, cls, ownerLevel, profile, role, owner, ownerLevel >= BUDDY_PVP_JEWELLERY_FROM, "buddy",
        "owner " + std::to_string(owner), name, why);
    if (!guid)
        return Fail(owner, slot, race, cls, why);

    CharacterDatabase.Execute("UPDATE buddy_roster SET buddy = {}, created = UNIX_TIMESTAMP() "
        "WHERE owner = {} AND slot = {} AND buddy = 0", guid, owner, slot);

    LOG_INFO("module", "mod-buddies: made {} ({}, race {}, class {}, level {}) for owner {}, slot {}",
        name, guid, race, cls, ownerLevel, owner, slot);

    if (ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(owner)))
        BuddyQueueLogin(owner);
}

class buddies_create_world : public WorldScript
{
public:
    buddies_create_world() : WorldScript("buddies_create_world", { WORLDHOOK_ON_UPDATE }) { }

    void OnUpdate(uint32 diff) override
    {
        _sinceLast += diff;
        if (_sinceLast < BUDDY_CREATE_EVERY_MS || !BuddiesEnabled())
            return;
        _sinceLast = 0;

        QueryResult rows = CharacterDatabase.Query(
            "SELECT owner, slot, class, race FROM buddy_roster WHERE buddy = 0 AND class <> 0 AND race <> 0 "
            "ORDER BY owner, slot LIMIT {}", BUDDY_CREATE_PER_PASS + uint32(sFailed.size()));
        if (!rows)
            return;
        uint32 tried = 0;
        do
        {
            uint32 owner = (*rows)[0].Get<uint32>();
            uint8  slot  = (*rows)[1].Get<uint8>();
            if (sFailed.count({ owner, slot }))
                continue;
            CreateBuddy(owner, slot, (*rows)[2].Get<uint8>(), (*rows)[3].Get<uint8>());
            ++tried;
        } while (tried < BUDDY_CREATE_PER_PASS && rows->NextRow());
    }

private:
    uint32 _sinceLast = 0;
};

class buddies_create_player : public PlayerScript
{
public:
    buddies_create_player() : PlayerScript("buddies_create_player", { PLAYERHOOK_ON_LOGIN }) { }

    void OnPlayerLogin(Player* player) override
    {
        if (BuddiesEnabled() && BuddyIsNotAPlayer(player->GetSession()->GetAccountId()))
        {
            std::string missing = GiveSecondaryProfessions(player) + GivePrimaryProfessions(player)
                + MaxDeathKnightProfessions(player);
            if (!missing.empty())
                LOG_ERROR("module", "mod-buddies: buddy {}: {}", player->GetName(), missing);
            return;
        }
        uint32 owner = player->GetGUID().GetCounter();
        for (auto it = sFailed.begin(); it != sFailed.end(); )
            it = (it->first == owner) ? sFailed.erase(it) : std::next(it);
    }
};

void AddSC_buddies_create()
{
    new buddies_create_world();
    new buddies_create_player();
}
