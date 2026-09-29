/*
 * buddies_create.cpp - a chosen roster slot becomes a buddy character
 * (issue 617a3).
 *
 * For a general audience: when a player picks a buddy (617b), the choice
 * is written into that owed slot of the roster: a class, a race, a talent
 * shape. This file notices such a row, makes the character on the owner's
 * hidden account with that race and class, a random gender, name and face,
 * at the owner's current level, saves it, and writes the new character
 * into the row. From then on the row is "filled" and the buddy can be
 * logged in (617c).
 *
 * Why not the bot module's own factory: it picks the faction at random and
 * the race from that, so it can't make "a dwarf, for this Alliance owner".
 * Its steps are followed here with the race fixed: the name from the bot
 * module's name list (playerbots_names), the looks from the client's
 * CharSections.dbc, then the server's ordinary character creation.
 *
 * The level is set on the new character before its first save, as the
 * server's own level command does for a character that isn't logged in
 * ("everything else will be updated at login"): stats, talent points and
 * the like are worked out from the saved level when it first logs in.
 *
 * Every buddy knows cooking, first aid and fishing from the start, and
 * carries a fishing pole (owner, 2026-09-27: "They need real food. They
 * should all have cooking and first aid and fishing"; 617k). Buddies made
 * before that learn them at their next login.
 *
 * A row that can't be made (no name left, a race and class that can't go
 * together, a race of the other faction, no companion account) is logged
 * once as an error naming the owner, slot, race and class, left as it is,
 * and tried again after the owner's next login.
 */

#include "buddies.h"
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

// How often the roster is checked for chosen rows, and how many are made
// per check (each creation is a handful of database writes).
static constexpr uint32 BUDDY_CREATE_EVERY_MS  = 5000;
static constexpr uint32 BUDDY_CREATE_PER_PASS  = 5;
// A chosen row whose companion account isn't in the login database yet is
// waited for this many passes (a minute) before it counts as a failure.
static constexpr uint32 BUDDY_ACCOUNT_PATIENCE = 12;

// Rows that failed, by (owner, slot): skipped until the owner logs in.
// Rows waiting for their account: passes waited so far.
static std::set<std::pair<uint32, uint8>>          sFailed;
static std::map<std::pair<uint32, uint8>, uint32> sWaiting;

// {{{ NameGroupFor
// The bot module keeps its names in playerbots_names under a race-and-
// gender number (RandomPlayerbotFactory::NameRaceAndGender): humans and
// undead share the "generic" list; every other race has its own pair,
// male then female. Races the table doesn't know use the generic list.
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
// }}}

// {{{ PickName
// A random unused name from the bot module's list for this race and gender,
// passing the server's own name rules. Empty when none is left.
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
// }}}

// {{{ PickLooks
// A random face, hair style and colour, and facial hair for the race and
// gender, from the client's CharSections.dbc (the bot factory's method,
// including which races and genders take no facial hair).
struct BuddyLooks { uint8 skin = 0, face = 0, hairStyle = 0, hairColor = 0, facialHair = 0; bool ok = false; };

static BuddyLooks PickLooks(uint8 race, uint8 gender)
{
    std::vector<uint8> facialHairs;
    std::vector<std::pair<uint8, uint8>> faces, hairs;
    for (CharSectionsEntry const* s : sCharSectionsStore)
    {
        if (s->Race != race || s->Gender != gender)
            continue;
        if (s->GenType == SECTION_TYPE_FACE)             faces.emplace_back(s->Type, s->Color);
        else if (s->GenType == SECTION_TYPE_HAIR)        hairs.emplace_back(s->Type, s->Color);
        else if (s->GenType == SECTION_TYPE_FACIAL_HAIR) facialHairs.push_back(s->Type);
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
// }}}

// {{{ the secondary professions
// Each profession's apprentice spell carries the skill itself (a "skill"
// effect naming the skill line, Spell.dbc 2026-09-27): learning it sets the
// skill to 1 of 75 and teaches the recipes the game gives with the skill
// (first aid's Linen Bandage, cooking's Basic Campfire). None of them is
// cast by learning, so this works on a character not yet in the world.
struct SecondaryProfession
{
    uint32 skill;
    uint32 spell;
};
static SecondaryProfession const sSecondary[] = {
    { SKILL_COOKING,   2550 },   // Cooking (Apprentice)
    { SKILL_FIRST_AID, 3273 },   // First Aid (Apprentice)
    { SKILL_FISHING,   7620 },   // Fishing (Apprentice), also the cast itself
};
static constexpr uint32 FISHING_POLE_ITEM = 6256;   // Fishing Pole (the bot module's own choice too)

// Learns what it lacks of the three, and puts a pole in its bags when it
// has none (bags or hands). Returns what it could not do, empty when all
// is well, for the caller to log.
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
// }}}

// {{{ Fail
static void Fail(uint32 owner, uint8 slot, uint8 race, uint8 cls, std::string const& why)
{
    sFailed.insert({ owner, slot });
    sWaiting.erase({ owner, slot });
    LOG_ERROR("module", "mod-buddies: could not make owner {}'s buddy in slot {} (race {}, class {}): {}. "
        "The slot stays chosen; tried again after the owner's next login.", owner, slot, race, cls, why);
}
// }}}

// {{{ CreateBuddy
// One chosen row -> one saved character, written into the row.
static void CreateBuddy(uint32 owner, uint8 slot, uint8 cls, uint8 race)
{
    std::pair<uint32, uint8> key{ owner, slot };

    uint32 account = BuddyCompanionAccountId(owner);
    if (!account)
    {
        // The account is written through the login database's queue; give
        // it a minute before calling it a failure.
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

    uint8 gender = urand(0, 1) ? GENDER_MALE : GENDER_FEMALE;
    std::string name = PickName(race, gender);
    if (name.empty())
        return Fail(owner, slot, race, cls, "no unused name is left in playerbots_names for this race and gender");
    BuddyLooks looks = PickLooks(race, gender);
    if (!looks.ok)
        return Fail(owner, slot, race, cls, "CharSections.dbc has no face or hair for this race and gender");

    CharacterCreateInfo info(name, race, cls, gender, looks.skin, looks.face, looks.hairStyle, looks.hairColor, looks.facialHair);

    // A throwaway session on the companion account: Player needs one to be
    // built and saved, as the bot factory's creation does.
    WorldSession* session = new WorldSession(account, "", 0, nullptr, SEC_PLAYER, sWorld->getIntConfig(CONFIG_EXPANSION),
        time_t(0), LOCALE_enUS, 0, false, false, 0, true);
    Player* buddy = new Player(session);
    buddy->GetMotionMaster()->Initialize();
    if (!buddy->Create(sObjectMgr->GetGenerator<HighGuid::Player>().Generate(), &info))
    {
        buddy->CleanupsBeforeDelete();
        delete buddy;
        delete session;
        return Fail(owner, slot, race, cls, "the server refused to create the character (name '" + name + "')");
    }

    buddy->setCinematic(2);                         // never plays the intro
    buddy->SetAtLoginFlag(AT_LOGIN_NONE);
    if (cls == CLASS_DEATH_KNIGHT)
        buddy->learnSpell(50977, false);            // Death Gate, as the bot factory gives it
    if (ownerLevel > buddy->GetLevel())
        buddy->SetLevel(ownerLevel);                // the rest follows at first login
    std::string missing = GiveSecondaryProfessions(buddy);
    if (!missing.empty())
        LOG_ERROR("module", "mod-buddies: new buddy {} for owner {}: {}; it tries again at its first login",
            name, owner, missing);
    // the starting kit: white gear, food (and drink), level x 1 silver,
    // bags like the owner's (617a4); made now, before the first save
    std::string kitProblems = BuddyGiveStartingKit(buddy, owner);
    if (!kitProblems.empty())
        LOG_ERROR("module", "mod-buddies: new buddy {} for owner {} (level {}), starting kit incomplete: {}",
            name, owner, buddy->GetLevel(), kitProblems);

    uint32 guid = buddy->GetGUID().GetCounter();
    buddy->SaveToDB(true, false);
    sCharacterCache->AddCharacterCacheEntry(buddy->GetGUID(), account, buddy->GetName(), buddy->getGender(),
        buddy->getRace(), buddy->getClass(), buddy->GetLevel());
    buddy->CleanupsBeforeDelete();
    delete buddy;
    delete session;
    sWorld->UpdateRealmCharCount(account);

    CharacterDatabase.Execute("UPDATE buddy_roster SET buddy = {}, created = UNIX_TIMESTAMP() "
        "WHERE owner = {} AND slot = {} AND buddy = 0", guid, owner, slot);

    // Not into the clan here: a buddy joins its owner's clan 5 seconds after
    // it first appears in the world, and greets its owner (617l, owner
    // 2026-09-26: "First spawn the buddy-bot, then 5 seconds later invite to
    // the guild"; src/lua-basic/sargobras.lua).
    LOG_INFO("module", "mod-buddies: made {} ({}, race {}, class {}, level {}) for owner {}, slot {}",
        name, guid, race, cls, ownerLevel, owner, slot);

    // An owner who is online meets the new buddy now, not at the next login
    // (617c1). The roster write above is queued; the login waits a moment.
    if (ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(owner)))
        BuddyQueueLogin(owner);
}
// }}}

// Every few seconds: make up to a few chosen, unfilled rows.
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
        // Failed rows are skipped without counting toward the pass's limit
        // (the query fetched that many extra rows to make room for them).
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

// An owner's login clears its failures, so they are tried again. A buddy's
// login catches up the secondary professions (buddies made before 617k's
// decision, or one whose bags were full).
class buddies_create_player : public PlayerScript
{
public:
    buddies_create_player() : PlayerScript("buddies_create_player", { PLAYERHOOK_ON_LOGIN }) { }

    void OnPlayerLogin(Player* player) override
    {
        if (BuddiesEnabled() && BuddyIsCompanionAccount(player->GetSession()->GetAccountId()))
        {
            std::string missing = GiveSecondaryProfessions(player);
            if (!missing.empty())
                LOG_ERROR("module", "mod-buddies: buddy {}: {}", player->GetName(), missing);
            return;
        }
        uint32 owner = player->GetGUID().GetCounter();
        for (auto it = sFailed.begin(); it != sFailed.end(); )
            it = (it->first == owner) ? sFailed.erase(it) : std::next(it);
    }
};

// {{{ AddSC_buddies_create
void AddSC_buddies_create()
{
    new buddies_create_world();
    new buddies_create_player();
}
// }}}
