/*
 * basic_rules.cpp - server rules for the basic profile (issue 155) that need
 * compiled code: things the Lua engine cannot refuse or change.
 *
 * For a general audience: the basic profile is the level 1-60 game. Some of
 * its rules sit where only the server's own code can reach, such as deciding
 * whether a talent may be learned. This file holds those rules. It lives in
 * the project (src/cpp-basic/) and source patch B030 copies it into the
 * server's stock "Custom" scripts folder at build time, then removes it.
 *
 * Current rules:
 *   - Talent cap (issue 155g): tier 6 (30 points in the tree) keeps only its
 *     "capstones", the talents that cost a single point (fire mage
 *     Combustion, retribution Repentance); the multi-rank talents beside
 *     them and every deeper row are refused, as vanilla-era trees ended
 *     there. The client still draws the whole tree (its data files can't be
 *     changed); the server refuses and says why.
 *   - Creature multipliers (issue 155i): per-creature (or per-map) multipliers
 *     on a creature's melee damage, spell damage, healing and health, read
 *     from the world table basic_creature_multipliers (install step E026) at
 *     startup and on ".basic reload multipliers". Tuning a boss is one table
 *     row, not a recompile. Players and anything they control are never
 *     scaled.
 *   - World bosses (issue 155j): their state (alive or counting down), their
 *     return when the Lua countdown (src/lua-basic/world-boss-respawn.lua)
 *     calls ".basic worldboss respawn", Doom Lord Kazzak's demon swarm, and
 *     the battle bonus: +1% damage and health for every monster while any
 *     world boss lives.
 *   - Refused channels (issue 155x): nobody joins General, Trade,
 *     LocalDefense or WorldDefense. The refusal is source patch B038 (no
 *     script hook sees every join); this file reports the list at startup.

 */

#include "Chat.h"
#include "CommandScript.h"
#include "Config.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"
#include "DBCStructure.h"
#include "GameTime.h"
#include "GridTerrainData.h"
#include "Log.h"
#include "Map.h"
#include "MapMgr.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Random.h"
#include "RBAC.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "TemporarySummon.h"
#include "WorldSession.h"
#include <algorithm>
#include <atomic>
#include <cmath>
#include <map>
#include <mutex>
#include <set>
#include <shared_mutex>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

using namespace Acore::ChatCommands;

// -- {{{ talent cap
// Row n needs 5n points in the tree, so row 6 is the "30 points spent" row:
// Combustion and Repentance live there (client's Talent.dbc, 2026-09-23).
// Row 6 is the capstone row: its one-point talents are open, its multi-rank
// talents are sealed. Every row past it is sealed whole.
//
// Why "one point" picks the capstone (owner's rule, 2026-09-26): checked in
// Talent.dbc on 2026-09-26, 27 of the 30 class trees have exactly one
// one-point talent in row 6, and it is the tree's signature ability, not
// always in the middle column (affliction's Dark Pact sits right of centre).
// Three trees have two, and the owner chose to open both:
//   Restoration shaman - Mana Tide Totem and Cleanse Spirit
//   Enhancement shaman - Dual Wield and Stormstrike
//   Unholy death knight - Anti-Magic Zone and Ghoul Frenzy
// Hunter pet talents never reach this hook: pets learn through
// Player::LearnPetTalent, which does not ask it, so pet trees stay stock.
static constexpr uint32 BASIC_CAPSTONE_TALENT_ROW = 6;

class basic_rules_talent_cap : public PlayerScript
{
public:
    basic_rules_talent_cap() : PlayerScript("basic_rules_talent_cap", { PLAYERHOOK_CAN_LEARN_TALENT }) { }

    // Called by Player::LearnTalent before anything is spent. Returning false
    // refuses the talent. Bots learn through the same path, so they are
    // capped too; a refusal leaves their point unspent (their talent loops
    // are bounded, so nothing retries forever).
    bool OnPlayerCanLearnTalent(Player* player, TalentEntry const* talent, uint32 /*rank*/) override
    {
        // rows above the capstone row: stock
        if (talent->Row < BASIC_CAPSTONE_TALENT_ROW)
            return true;

        // the capstone row: a talent with no second rank (RankID[1] == 0)
        // costs one point and is a capstone, so it is open; a multi-rank
        // talent beside it falls through to the refusal
        if (talent->Row == BASIC_CAPSTONE_TALENT_ROW && talent->RankID[1] == 0)
            return true;

        // A real player gets told why; a bot has no one to read it.
        if (player->GetSession() && !player->GetSession()->IsBot())
            ChatHandler(player->GetSession()).SendSysMessage(
                "That talent is beyond this realm's limit: past 30 points in a tree, only the single-point capstone may be learned.");
        return false;
    }
};
// -- }}}

// -- {{{ creature multipliers
// One row of basic_creature_multipliers. 1 = stock.
struct BasicCreatureMultipliers
{
    float melee  = 1.0f;
    float spell  = 1.0f;
    float heal   = 1.0f;
    float health = 1.0f;
};

// Rows by creature template, and rows for a whole instance map (entry = 0).
static std::unordered_map<uint32, BasicCreatureMultipliers> sBasicMultByEntry;
static std::unordered_map<uint32, BasicCreatureMultipliers> sBasicMultByMap;

// -- {{{ LoadBasicCreatureMultipliers
// Reads the whole table. A missing table is reported as an error: it means
// install step E026 did not run, and every multiplier is then 1 (stock).
static uint32 LoadBasicCreatureMultipliers()
{
    sBasicMultByEntry.clear();
    sBasicMultByMap.clear();

    QueryResult result = WorldDatabase.Query("SELECT entry, map_id, melee, spell, heal, health FROM basic_creature_multipliers");
    if (!result)
    {
        // An empty table also lands here; say which case it is.
        QueryResult exists = WorldDatabase.Query("SHOW TABLES LIKE 'basic_creature_multipliers'");
        if (!exists)
            LOG_ERROR("server.loading", ">> basic: table basic_creature_multipliers is missing (install step E026 not run?); creature multipliers are OFF");
        else
            LOG_INFO("server.loading", ">> basic: 0 creature multiplier rows (every creature stock)");
        return 0;
    }

    uint32 count = 0;
    do
    {
        Field* f = result->Fetch();
        uint32 entry = f[0].Get<uint32>();
        uint32 mapId = f[1].Get<uint32>();
        BasicCreatureMultipliers m;
        m.melee  = f[2].Get<float>();
        m.spell  = f[3].Get<float>();
        m.heal   = f[4].Get<float>();
        m.health = f[5].Get<float>();
        // entry <> 0: a creature's own row; entry = 0: a map row
        if (entry)
            sBasicMultByEntry[entry] = m;
        else
            sBasicMultByMap[mapId] = m;
        ++count;
    } while (result->NextRow());

    LOG_INFO("server.loading", ">> basic: loaded {} creature multiplier rows ({} creatures, {} maps)",
        count, sBasicMultByEntry.size(), sBasicMultByMap.size());
    return count;
}
// -- }}}

// -- {{{ BasicMultipliersFor
// The row that applies to a unit, or nullptr for "stock". Order: the
// creature's own row; else its creature owner's row (a boss's adds and pets);
// else its map's row. Players and player-controlled units: always nullptr.
static BasicCreatureMultipliers const* BasicMultipliersFor(Unit const* unit)
{
    if (!unit || unit->IsControlledByPlayer())
        return nullptr;
    Creature const* creature = unit->ToCreature();
    if (!creature)
        return nullptr;

    auto own = sBasicMultByEntry.find(creature->GetEntry());
    if (own != sBasicMultByEntry.end())
        return &own->second;

    if (Unit* owner = creature->GetOwner())
        if (Creature const* ownerCreature = owner->ToCreature())
        {
            auto byOwner = sBasicMultByEntry.find(ownerCreature->GetEntry());
            if (byOwner != sBasicMultByEntry.end())
                return &byOwner->second;
        }

    auto byMap = sBasicMultByMap.find(creature->GetMapId());
    if (byMap != sBasicMultByMap.end())
        return &byMap->second;
    return nullptr;
}
// -- }}}

class basic_rules_creature_multipliers_load : public WorldScript
{
public:
    basic_rules_creature_multipliers_load() : WorldScript("basic_rules_creature_multipliers_load", { WORLDHOOK_ON_LOAD_CUSTOM_DATABASE_TABLE }) { }

    void OnLoadCustomDatabaseTable() override { LoadBasicCreatureMultipliers(); }
};

class basic_rules_creature_multipliers_damage : public UnitScript
{
public:
    basic_rules_creature_multipliers_damage() : UnitScript("basic_rules_creature_multipliers_damage", true, {
        UNITHOOK_MODIFY_MELEE_DAMAGE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
        UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK, UNITHOOK_MODIFY_HEAL_RECEIVED }) { }

    // Melee: called after the attacker's bonuses, before the target's armor.
    void ModifyMeleeDamage(Unit* /*target*/, Unit* attacker, uint32& damage) override
    {
        if (BasicCreatureMultipliers const* m = BasicMultipliersFor(attacker))
            damage = uint32(damage * m->melee);
    }

    // Direct spell damage.
    void ModifySpellDamageTaken(Unit* /*target*/, Unit* attacker, int32& damage, SpellInfo const* /*spellInfo*/) override
    {
        if (BasicCreatureMultipliers const* m = BasicMultipliersFor(attacker))
            damage = int32(damage * m->spell);
    }

    // Damage-over-time ticks. The server also passes heal-over-time ticks
    // through this hook (SpellAuraEffects.cpp, the periodic heal handler);
    // those are left to ModifyHealReceived, so a positive spell is skipped.
    void ModifyPeriodicDamageAurasTick(Unit* /*target*/, Unit* attacker, uint32& damage, SpellInfo const* spellInfo) override
    {
        if (spellInfo && spellInfo->IsPositive())
            return;
        if (BasicCreatureMultipliers const* m = BasicMultipliersFor(attacker))
            damage = uint32(damage * m->spell);
    }

    // Healing done or received by a listed creature. The server's two call
    // sites pass the healer and the healed in opposite orders (Unit.cpp
    // HealBySpell: healer first; the periodic heal: healed first), so the
    // first of the two that has a row decides.
    void ModifyHealReceived(Unit* first, Unit* second, uint32& heal, SpellInfo const* /*spellInfo*/) override
    {
        BasicCreatureMultipliers const* m = BasicMultipliersFor(second);
        if (!m)
            m = BasicMultipliersFor(first);
        if (m)
            heal = uint32(heal * m->heal);
    }
};

// Health, at the end of choosing a creature's level (spawn, respawn, entry
// change). Creature rows only: a creature's map is not reliably set yet here.
class basic_rules_creature_multipliers_health : public AllCreatureScript
{
public:
    basic_rules_creature_multipliers_health() : AllCreatureScript("basic_rules_creature_multipliers_health") { }

    void OnCreatureSelectLevel(CreatureTemplate const* cinfo, Creature* creature) override
    {
        auto it = sBasicMultByEntry.find(cinfo->Entry);
        if (it == sBasicMultByEntry.end() || it->second.health == 1.0f)
            return;
        uint32 health = std::max<uint32>(1, uint32(creature->GetCreateHealth() * it->second.health));
        creature->SetCreateHealth(health);
        creature->SetMaxHealth(health);
        creature->SetHealth(health);
        creature->SetStatFlatModifier(UNIT_MOD_HEALTH, BASE_VALUE, float(health));
    }
};

// ".basic reload multipliers": re-read the table without a restart. Health
// changes apply to creatures as they next spawn.
class basic_rules_creature_multipliers_command : public CommandScript
{
public:
    basic_rules_creature_multipliers_command() : CommandScript("basic_rules_creature_multipliers_command") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable reloadTable =
        {
            { "multipliers", HandleReloadMultipliers, rbac::RBAC_PERM_COMMAND_RELOAD, Console::Yes },
        };
        static ChatCommandTable basicTable =
        {
            { "reload", reloadTable },
        };
        static ChatCommandTable commandTable =
        {
            { "basic", basicTable },
        };
        return commandTable;
    }

    static bool HandleReloadMultipliers(ChatHandler* handler)
    {
        uint32 rows = LoadBasicCreatureMultipliers();
        handler->PSendSysMessage("basic: reloaded {} creature multiplier rows.", rows);
        return true;
    }
};
// -- }}}

// -- {{{ world bosses (issue 155j)
// The world bosses (Doom Lord Kazzak, Doomwalker, Azuregos, the Emerald
// Dragons: the list is the world table basic_155j_world_bosses, E046) no
// longer respawn on the server's timer (E046 sets it to a year). The
// countdown that brings each one back is src/lua-basic/world-boss-respawn.lua
// (2.5 hours, held back by "moment tokens" the players in the boss's area
// deposit; owner, 2026-09-27: "manual spawning through lua"). This part does what the Lua engine
// can't:
//   the state   - which bosses are alive, kept in memory and in the
//                 characters table basic_world_boss_timer (E047): alive = 0
//                 when one dies (the server's death event; a Lua death event
//                 would replace the boss's own scripted fight), 1 when it is
//                 brought back;
//   the respawn - ".basic worldboss respawn <spawn>", called by the Lua when
//                 the countdown is done: the Lua engine cannot clear a
//                 respawn time or reach a boss whose ground is not loaded;
//   the swarm   - when Doom Lord Kazzak comes back, elite demon packs spread
//                 through his zone, one per player there (owner, 2026-09-27:
//                 "wayyyy too many demons that spawn with him, just
//                 everywhere... but they don't respawn, so they can be battled
//                 down. But they are strong, about one elite pack per
//                 person");
//   the battle bonus - while any world boss is alive, every monster deals 1%
//                 more damage and has 1% more health (owner, 2026-09-27:
//                 "While they are in alive in the world, all monsters get a 1%
//                 battle bonus" / "both"). Monsters: every creature not
//                 controlled by a player (players' pets and guardians are
//                 not monsters). Server-wide (not only the boss's continent).
//                 Only monsters hostile to both factions (owner, 2026-09-27:
//                 "just hostile monsters. If the NPC is only hostile to one
//                 of the factions, then no."): a town guard, hostile to the
//                 other faction only, gets nothing; nor does a neutral beast.

static constexpr uint32 WORLD_BOSS_KAZZAK        = 18728;   // Doom Lord Kazzak
static constexpr float  BATTLE_BONUS_DAMAGE      = 1.01f;   // x monster damage while a world boss lives
static constexpr uint32 BATTLE_BONUS_HEALTH_DIV  = 100;     // + max health / this (1%), at least 1
static constexpr uint32 BATTLE_BONUS_CHECK_MS    = 1000;    // how often the world thread looks for a change

// Kazzak's swarm (placeholders, tunable in docs/balance-updates.md): each
// pack an elite Mo'arg Overseer leading two elite Gan'arg Peons, the elite
// demons of his own corner of Hellfire Peninsula.
static std::vector<uint32> const SWARM_PACK      = { 19397, 19398, 19398 };
static constexpr float  SWARM_PACK_SPACING       = 60.0f;   // yards between packs
static constexpr float  SWARM_KAZZAK_CLEAR       = 60.0f;   // yards kept clear round Kazzak
static constexpr float  SWARM_MEMBER_SPREAD      = 4.0f;    // yards from the pack's middle to each member
static constexpr uint32 SWARM_TRIES_PER_PACK     = 40;      // random spots tried for each pack

static std::unordered_map<uint32, uint32> sWorldBossEntry;  // spawn id -> creature entry; written once at startup
static std::mutex        sWorldBossLock;                    // guards sWorldBossAlive (death events come from map threads)
static std::set<uint32>  sWorldBossAlive;                   // spawn ids alive
static std::atomic<bool> sBattleBonusWanted { false };      // some world boss alive (set wherever the state changes)
static std::atomic<bool> sBattleBonusOn { false };          // the bonus as applied (changed on the world thread only)

// The creatures carrying the health bonus, and how much each was given, so
// removing it takes back exactly that. Keyed by map and guid (creature guids
// are only unique within a map). Creatures are added from map threads,
// which run side by side, hence the lock.
static std::mutex sBattleBonusLock;
static std::map<std::pair<Map const*, ObjectGuid>, uint32> sBattleBonusHealth;

// Kazzak's current swarm, to clear leftovers before the next one.
static std::vector<ObjectGuid> sSwarm;
static uint32 sSwarmMap = 0;

// -- {{{ IsMonster
// Everything the battle bonus reaches: a creature no player controls whose
// faction is hostile to the Alliance's players and to the Horde's (read
// from the faction templates of a human and an orc player, 1 and 2, by the
// same rule the server uses to colour a creature's name red). A creature
// hostile to one side only (a guard), or to neither (a neutral beast, a
// vendor), is not a monster here. This reads the factions as they stand in
// the game data, not a player's reputation standing.
static bool IsMonster(Unit const* unit)
{
    if (!unit || !unit->IsCreature() || unit->IsControlledByPlayer())
        return false;
    FactionTemplateEntry const* mine = unit->GetFactionTemplateEntry();
    static FactionTemplateEntry const* alliance = sFactionTemplateStore.LookupEntry(1);   // human player
    static FactionTemplateEntry const* horde    = sFactionTemplateStore.LookupEntry(2);   // orc player
    return mine && alliance && horde && mine->IsHostileTo(*alliance) && mine->IsHostileTo(*horde);
}
// -- }}}

// -- {{{ BattleBonusHealth
// Give (apply) or take back (!apply) the 1% health. A flat addition, not a
// percentage: the server resets a creature's percent health modifiers
// whenever a percent-health aura on it ends (SpellAuraEffects.cpp,
// SetStatPctModifier from the auras alone), which would wipe a percent
// bonus silently; flat additions are added and subtracted by everyone. The
// creature keeps its share of health (a full-health monster stays full).
static void BattleBonusHealth(Map const* map, Creature* creature, bool apply)
{
    auto key = std::make_pair(map, creature->GetGUID());
    uint32 amount = 0;
    {
        std::lock_guard<std::mutex> lock(sBattleBonusLock);
        auto it = sBattleBonusHealth.find(key);
        if (apply == (it != sBattleBonusHealth.end()))
            return;                                             // already given / never given
        if (apply)
        {
            amount = std::max<uint32>(1, creature->GetMaxHealth() / BATTLE_BONUS_HEALTH_DIV);
            sBattleBonusHealth[key] = amount;
        }
        else
        {
            amount = it->second;
            sBattleBonusHealth.erase(it);
        }
    }
    uint32 oldMax = creature->GetMaxHealth();
    uint32 health = creature->GetHealth();
    creature->HandleStatFlatModifier(UNIT_MOD_HEALTH, TOTAL_VALUE, float(amount), apply);
    uint32 newMax = creature->GetMaxHealth();
    if (creature->IsAlive() && oldMax)
        creature->SetHealth(std::max<uint32>(1, uint32(uint64(health) * newMax / oldMax)));
}
// -- }}}

// -- {{{ BattleBonusEverywhere
// Every creature in every map (continents and instances). Called on the
// world thread, which runs only when no map is updating (MapMgr::Update
// waits for its workers), so the creatures can be changed safely.
static void BattleBonusEverywhere(bool apply)
{
    uint32 count = 0;
    sMapMgr->DoForAllMaps([apply, &count](Map* map)
    {
        for (auto const& pair : map->GetObjectsStore().GetElements()._elements._element)   // the map's creatures
            if (Creature* creature = pair.second)
                if (creature->IsInWorld() && IsMonster(creature))
                {
                    BattleBonusHealth(map, creature, apply);
                    ++count;
                }
    });
    LOG_INFO("server.loading", ">> basic: world boss battle bonus {} ({} monsters)", apply ? "ON" : "OFF", count);
}
// -- }}}

// -- {{{ SetWorldBossAlive
// The one place the alive state changes: memory, the wanted bonus, and the
// characters table (alive; the countdown and its moment tokens are zeroed
// for the Lua to start).
static void SetWorldBossAlive(uint32 spawnId, bool alive)
{
    {
        std::lock_guard<std::mutex> lock(sWorldBossLock);
        if (alive)
            sWorldBossAlive.insert(spawnId);
        else
            sWorldBossAlive.erase(spawnId);
        sBattleBonusWanted = !sWorldBossAlive.empty();
    }
    CharacterDatabase.Execute("REPLACE INTO basic_world_boss_timer (guid, alive, elapsed, tokens) VALUES ({}, {}, 0, 0)",
        spawnId, alive ? 1 : 0);
}
// -- }}}

// -- {{{ LoadWorldBosses
// The list from the world table, the state from the characters table; a
// listed boss without a state row is taken as alive and given one. Missing
// tables are errors (install steps E046 / E047 not run): nothing is managed.
static void LoadWorldBosses()
{
    sWorldBossEntry.clear();
    QueryResult list = WorldDatabase.Query("SELECT guid, entry FROM basic_155j_world_bosses");
    if (!list)
    {
        LOG_ERROR("server.loading", ">> basic: basic_155j_world_bosses is missing or empty (install step E046 not run?); "
            "world bosses are not respawned by hand and the battle bonus is OFF");
        return;
    }
    do
        sWorldBossEntry[(*list)[0].Get<uint32>()] = (*list)[1].Get<uint32>();
    while (list->NextRow());

    if (!CharacterDatabase.Query("SHOW TABLES LIKE 'basic_world_boss_timer'"))
    {
        LOG_ERROR("server.loading", ">> basic: basic_world_boss_timer is missing (install step E047 not run?); "
            "{} world bosses listed but their state can't be kept", sWorldBossEntry.size());
        sWorldBossEntry.clear();
        return;
    }
    std::set<uint32> known;
    std::lock_guard<std::mutex> lock(sWorldBossLock);
    sWorldBossAlive.clear();
    if (QueryResult state = CharacterDatabase.Query("SELECT guid, alive FROM basic_world_boss_timer"))
        do
        {
            uint32 spawnId = (*state)[0].Get<uint32>();
            known.insert(spawnId);
            if ((*state)[1].Get<uint8>() && sWorldBossEntry.count(spawnId))
                sWorldBossAlive.insert(spawnId);
        } while (state->NextRow());
    for (auto const& [spawnId, entry] : sWorldBossEntry)
        if (!known.count(spawnId))
        {
            sWorldBossAlive.insert(spawnId);
            CharacterDatabase.Execute("INSERT IGNORE INTO basic_world_boss_timer (guid, alive) VALUES ({}, 1)", spawnId);
        }
    sBattleBonusWanted = !sWorldBossAlive.empty();
    LOG_INFO("server.loading", ">> basic: {} world bosses listed, {} alive", sWorldBossEntry.size(), sWorldBossAlive.size());
}
// -- }}}

// -- {{{ HumansInZone
// Players (not bots) in a zone of a map, counted on the world thread.
static uint32 HumansInZone(uint32 mapId, uint32 zoneId)
{
    uint32 count = 0;
    std::shared_lock<std::shared_mutex> lock(*HashMapHolder<Player>::GetLock());
    for (auto const& [guid, player] : ObjectAccessor::GetPlayers())
        if (player && player->IsInWorld() && player->GetMapId() == mapId && player->GetZoneId() == zoneId
            && player->GetSession() && !player->GetSession()->IsBot())
            ++count;
    return count;
}
// -- }}}

// -- {{{ SpawnKazzakSwarm
// One elite pack per player in Kazzak's zone, at random walkable spots in
// the zone (its borders from the area table buddy_area_centre, E044; a spot
// must be on dry ground in the same zone, away from Kazzak and the other
// packs). The packs never respawn: each member despawns when its corpse
// does. A pack's leader is made an "active" creature, which keeps its piece
// of ground loaded while it lives; otherwise a pack summoned where no player
// stands would vanish when that ground unloads (summoned creatures are not
// kept). The swarm outlives Kazzak (it is there to be battled down); what is
// left of it is cleared when he next comes back.
static void SpawnKazzakSwarm(Map* map, CreatureData const* kazzak, ChatHandler* handler)
{
    for (ObjectGuid const& guid : sSwarm)                         // leftovers of the last swarm
        if (Map* old = sMapMgr->FindBaseNonInstanceMap(sSwarmMap))
            if (Creature* creature = old->GetCreature(guid))
                if (TempSummon* summon = creature->ToTempSummon())
                    summon->UnSummon();
    sSwarm.clear();
    sSwarmMap = map->GetId();

    uint32 zone = map->GetZoneId(PHASEMASK_NORMAL, kazzak->posX, kazzak->posY, kazzak->posZ);
    // no cap (owner, 2026-09-27: "no cap. demons will be long slain by the
    // time he's done."): one pack for every player, however many come
    uint32 packs = HumansInZone(map->GetId(), zone);
    if (!packs)
    {
        handler->PSendSysMessage("basic: Kazzak's swarm: no players in his zone ({}), no packs.", zone);
        return;
    }
    QueryResult box = WorldDatabase.Query("SELECT MIN(min_x), MAX(max_x), MIN(min_y), MAX(max_y) FROM buddy_area_centre "
        "WHERE map = {} AND area = {}", map->GetId(), zone);
    if (!box || (*box)[0].IsNull())
    {
        LOG_ERROR("scripts", "basic: Kazzak's swarm: no borders for zone {} on map {} in buddy_area_centre (E044 not run?); "
            "{} packs owed, none placed", zone, map->GetId(), packs);
        handler->PSendSysMessage("basic: Kazzak's swarm: zone {} has no borders in buddy_area_centre; no packs.", zone);
        return;
    }
    float minX = (*box)[0].Get<float>(), maxX = (*box)[1].Get<float>();
    float minY = (*box)[2].Get<float>(), maxY = (*box)[3].Get<float>();

    std::vector<Position> placed;
    for (uint32 pack = 0; pack < packs; ++pack)
    {
        for (uint32 attempt = 0; attempt < SWARM_TRIES_PER_PACK; ++attempt)
        {
            float x = frand(minX, maxX), y = frand(minY, maxY);
            float z = map->GetHeight(PHASEMASK_NORMAL, x, y, MAX_HEIGHT);
            // a spot is refused: no ground; another zone; under water;
            // too near Kazzak or another pack
            if (z <= INVALID_HEIGHT || map->GetZoneId(PHASEMASK_NORMAL, x, y, z) != zone
                || map->IsInWater(PHASEMASK_NORMAL, x, y, z, 2.0f))
                continue;
            Position spot(x, y, z, frand(0.0f, 2.0f * float(M_PI)));
            if (spot.GetExactDist2d(kazzak->posX, kazzak->posY) < SWARM_KAZZAK_CLEAR)
                continue;
            if (std::any_of(placed.begin(), placed.end(), [&spot](Position const& p) { return p.GetExactDist2d(&spot) < SWARM_PACK_SPACING; }))
                continue;
            placed.push_back(spot);
            for (size_t i = 0; i < SWARM_PACK.size(); ++i)
            {
                float angle = 2.0f * float(M_PI) * float(i) / float(SWARM_PACK.size());
                float mx = x + std::cos(angle) * SWARM_MEMBER_SPREAD, my = y + std::sin(angle) * SWARM_MEMBER_SPREAD;
                float mz = map->GetHeight(PHASEMASK_NORMAL, mx, my, z + 5.0f);
                if (mz <= INVALID_HEIGHT)
                    mz = z;
                TempSummon* member = map->SummonCreature(SWARM_PACK[i], Position(mx, my, mz, spot.GetOrientation()));
                if (!member)
                {
                    LOG_ERROR("scripts", "basic: Kazzak's swarm: creature {} could not be summoned at ({}, {}, {}) on map {}",
                        SWARM_PACK[i], mx, my, mz, map->GetId());
                    continue;
                }
                member->SetTempSummonType(TEMPSUMMON_DEAD_DESPAWN);  // gone with its corpse, never back
                if (i == 0)
                    member->setActive(true);                        // keeps the pack's ground loaded
                sSwarm.push_back(member->GetGUID());
            }
            break;
        }
    }
    LOG_INFO("scripts", "basic: Kazzak's swarm: {} players in zone {}, {} of {} packs placed ({} demons)",
        HumansInZone(map->GetId(), zone), zone, placed.size(), packs, sSwarm.size());
    handler->PSendSysMessage("basic: Kazzak's swarm: {} of {} packs placed ({} demons).", placed.size(), packs, sSwarm.size());
}
// -- }}}

// -- {{{ RespawnWorldBoss
// Bring a listed boss back, whatever state its ground is in:
//   its body is in the world  - respawn it where it stands;
//   its ground is loaded but the body was taken away (the server's newer
//                               respawn queue removes some dead creatures) -
//                               queue its respawn for now;
//   its ground is not loaded  - clear its respawn time, so it loads alive
//                               when a player comes near.
// Returns what was done, for the command's reply.
static std::string RespawnWorldBoss(uint32 spawnId, ChatHandler* handler)
{
    CreatureData const* data = sObjectMgr->GetCreatureData(spawnId);
    if (!data)
        return "no such spawn in the world database";
    Map* map = sMapMgr->CreateBaseMap(data->mapid);
    std::string done;
    bool found = false;
    auto bounds = map->GetCreatureBySpawnIdStore().equal_range(spawnId);
    for (auto it = bounds.first; it != bounds.second; ++it)
    {
        found = true;
        if (!it->second->IsAlive())
            it->second->Respawn(true);
    }
    if (found)
    {
        map->RemoveCreatureRespawnTime(spawnId);
        done = "respawned where it stands";
    }
    else if (map->IsGridLoaded(data->posX, data->posY))
    {
        time_t now = GameTime::GetGameTime().count();
        map->SaveCreatureRespawnTime(spawnId, now);
        done = "respawn queued for now (its ground is loaded, its body was removed)";
    }
    else
    {
        map->RemoveCreatureRespawnTime(spawnId);
        done = "respawn time cleared (its ground is not loaded; it loads alive)";
    }
    SetWorldBossAlive(spawnId, true);
    if (sWorldBossEntry[spawnId] == WORLD_BOSS_KAZZAK)
        SpawnKazzakSwarm(map, data, handler);
    return done;
}
// -- }}}

class basic_rules_world_boss_world : public WorldScript
{
public:
    basic_rules_world_boss_world() : WorldScript("basic_rules_world_boss_world",
        { WORLDHOOK_ON_LOAD_CUSTOM_DATABASE_TABLE, WORLDHOOK_ON_UPDATE }) { }

    void OnLoadCustomDatabaseTable() override { LoadWorldBosses(); }

    // The world thread: switch the battle bonus on or off when the wanted
    // state changed (a boss died or came back).
    void OnUpdate(uint32 diff) override
    {
        _sinceCheck += diff;
        if (_sinceCheck < BATTLE_BONUS_CHECK_MS)
            return;
        _sinceCheck = 0;
        bool wanted = sBattleBonusWanted;
        if (wanted == sBattleBonusOn)
            return;
        sBattleBonusOn = wanted;               // first, so creatures added from now on get it too
        BattleBonusEverywhere(wanted);
    }

private:
    uint32 _sinceCheck = 0;
};

class basic_rules_world_boss_unit : public UnitScript
{
public:
    basic_rules_world_boss_unit() : UnitScript("basic_rules_world_boss_unit", true, {
        UNITHOOK_ON_UNIT_DEATH, UNITHOOK_MODIFY_MELEE_DAMAGE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
        UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK }) { }

    // Every kill passes here (Unit::Kill), game-master kills included.
    void OnUnitDeath(Unit* unit, Unit* /*killer*/) override
    {
        Creature* creature = unit->ToCreature();
        if (!creature || !creature->GetSpawnId() || !sWorldBossEntry.count(creature->GetSpawnId()))
            return;                                             // not a listed world boss
        SetWorldBossAlive(creature->GetSpawnId(), false);
        LOG_INFO("scripts", "basic: world boss {} (spawn {}) died; the respawn countdown starts",
            creature->GetName(), creature->GetSpawnId());
    }

    void ModifyMeleeDamage(Unit* /*target*/, Unit* attacker, uint32& damage) override
    {
        if (sBattleBonusOn && IsMonster(attacker))
            damage = uint32(damage * BATTLE_BONUS_DAMAGE);
    }

    void ModifySpellDamageTaken(Unit* /*target*/, Unit* attacker, int32& damage, SpellInfo const* /*spellInfo*/) override
    {
        if (sBattleBonusOn && IsMonster(attacker) && damage > 0)
            damage = int32(damage * BATTLE_BONUS_DAMAGE);
    }

    // Heal-over-time ticks pass through this hook too; a positive spell is
    // left alone (as the multipliers above do).
    void ModifyPeriodicDamageAurasTick(Unit* /*target*/, Unit* attacker, uint32& damage, SpellInfo const* spellInfo) override
    {
        if (spellInfo && spellInfo->IsPositive())
            return;
        if (sBattleBonusOn && IsMonster(attacker))
            damage = uint32(damage * BATTLE_BONUS_DAMAGE);
    }
};

// Creatures entering the world while the bonus is on get it; leaving, they
// are forgotten (their bonus leaves with them).
class basic_rules_world_boss_creature : public AllCreatureScript
{
public:
    basic_rules_world_boss_creature() : AllCreatureScript("basic_rules_world_boss_creature") { }

    void OnCreatureAddWorld(Creature* creature) override
    {
        if (sBattleBonusOn && IsMonster(creature))
            BattleBonusHealth(creature->GetMap(), creature, true);
    }

    void OnCreatureRemoveWorld(Creature* creature) override
    {
        std::lock_guard<std::mutex> lock(sBattleBonusLock);
        sBattleBonusHealth.erase(std::make_pair(creature->GetMap(), creature->GetGUID()));
    }
};

// ".basic worldboss respawn <spawn>" (the Lua countdown's call; console
// allowed) and ".basic worldboss status".
class basic_rules_world_boss_command : public CommandScript
{
public:
    basic_rules_world_boss_command() : CommandScript("basic_rules_world_boss_command") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable worldBossTable =
        {
            { "respawn", HandleRespawn, rbac::RBAC_PERM_COMMAND_RESPAWN, Console::Yes },
            { "status",  HandleStatus,  rbac::RBAC_PERM_COMMAND_RESPAWN, Console::Yes },
        };
        static ChatCommandTable basicTable =
        {
            { "worldboss", worldBossTable },
        };
        static ChatCommandTable commandTable =
        {
            { "basic", basicTable },
        };
        return commandTable;
    }

    static bool HandleRespawn(ChatHandler* handler, uint32 spawnId)
    {
        if (!sWorldBossEntry.count(spawnId))
        {
            handler->PSendSysMessage("basic: spawn {} is not a listed world boss (basic_155j_world_bosses).", spawnId);
            return false;
        }
        std::string done = RespawnWorldBoss(spawnId, handler);
        handler->PSendSysMessage("basic: world boss spawn {} (creature {}): {}.", spawnId, sWorldBossEntry[spawnId], done);
        LOG_INFO("scripts", "basic: world boss spawn {} (creature {}): {}", spawnId, sWorldBossEntry[spawnId], done);
        return true;
    }

    static bool HandleStatus(ChatHandler* handler)
    {
        std::lock_guard<std::mutex> lock(sWorldBossLock);
        for (auto const& [spawnId, entry] : sWorldBossEntry)
            handler->PSendSysMessage("  spawn {} creature {}: {}", spawnId, entry, sWorldBossAlive.count(spawnId) ? "alive" : "dead");
        handler->PSendSysMessage("basic: battle bonus {}; {} monsters carry its health.", sBattleBonusOn ? "ON" : "OFF", sBattleBonusHealth.size());
        return true;
    }
};
// -- }}}

// -- {{{ refused channels (issue 155x)
// The refusal is B038, in Channel::JoinChannel: a player's own join, the
// server's move between zone channels, and the bot module's joins all end
// there, and no script hook sees them all. This reports, once at startup,
// what B038 will refuse, so the log says whether the setting (C031) arrived.
// Names from the client's ChatChannels.dbc.
static std::unordered_map<uint32, char const*> const BASIC_CHANNEL_NAMES = {
    { 1, "General" }, { 2, "Trade" }, { 22, "LocalDefense" }, { 23, "WorldDefense" },
    { 25, "GuildRecruitment" }, { 26, "LookingForGroup" },
};

class basic_rules_refused_channels_report : public WorldScript
{
public:
    basic_rules_refused_channels_report() : WorldScript("basic_rules_refused_channels_report", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        std::string list = sConfigMgr->GetOption<std::string>("Basic.RefusedChannels", "", false);
        if (list.empty())
        {
            LOG_ERROR("server.loading", ">> basic: Basic.RefusedChannels is not set (config patch C031 not run?); every channel is open");
            return;
        }
        std::istringstream in(list);
        std::string names;
        for (uint32 id; in >> id; )
        {
            auto name = BASIC_CHANNEL_NAMES.find(id);
            names += (names.empty() ? "" : ", ") + std::string(name != BASIC_CHANNEL_NAMES.end() ? name->second : "unknown") + " (" + std::to_string(id) + ")";
        }
        LOG_INFO("server.loading", ">> basic: channels nobody joins (B038): {}", names);
    }
};
// -- }}}

// -- {{{ AddSC_basic_rules
// Registered from src/server/scripts/Custom/custom_script_loader.cpp by B030.
void AddSC_basic_rules()
{
    new basic_rules_talent_cap();
    new basic_rules_creature_multipliers_load();
    new basic_rules_creature_multipliers_damage();
    new basic_rules_creature_multipliers_health();
    new basic_rules_creature_multipliers_command();
    new basic_rules_world_boss_world();
    new basic_rules_world_boss_unit();
    new basic_rules_world_boss_creature();
    new basic_rules_world_boss_command();
    new basic_rules_refused_channels_report();
}
// -- }}}
