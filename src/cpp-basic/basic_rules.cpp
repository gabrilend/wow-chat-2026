
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
#include "LootMgr.h"
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
#include "World.h"
#include "WorldConfig.h"
#include "WorldSession.h"
#include <algorithm>
#include <atomic>
#include <cmath>
#include <iterator>
#include <map>
#include <mutex>
#include <set>
#include <shared_mutex>
#include <sstream>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

using namespace Acore::ChatCommands;

static constexpr uint32 BASIC_CAPSTONE_TALENT_ROW = 6;

class basic_rules_talent_cap : public PlayerScript
{
public:
    basic_rules_talent_cap() : PlayerScript("basic_rules_talent_cap", { PLAYERHOOK_CAN_LEARN_TALENT }) { }

    bool OnPlayerCanLearnTalent(Player* player, TalentEntry const* talent, uint32 ) override
    {
        if (talent->Row < BASIC_CAPSTONE_TALENT_ROW)
            return true;

        if (talent->Row == BASIC_CAPSTONE_TALENT_ROW && talent->RankID[1] == 0)
            return true;

        if (player->GetSession() && !player->GetSession()->IsHeadless())
            ChatHandler(player->GetSession()).SendSysMessage(
                "That talent is beyond this realm's limit: past 30 points in a tree, only the single-point capstone may be learned.");
        return false;
    }
};

static constexpr uint32 BASIC_DK_FIRST_LEVEL = 55;
static constexpr uint32 BASIC_DK_TALENTS_IN_ALL[] = {
        11,  24,  37,  49,  50,  51,
};
static constexpr uint32 BASIC_DK_CAUGHT_UP_LEVEL =
    BASIC_DK_FIRST_LEVEL + std::size(BASIC_DK_TALENTS_IN_ALL) - 1;
static_assert(BASIC_DK_TALENTS_IN_ALL[std::size(BASIC_DK_TALENTS_IN_ALL) - 1] == BASIC_DK_CAUGHT_UP_LEVEL - 9,
    "the death knight talent table must end at the stock count of its last level");

class basic_rules_dk_talent_points : public PlayerScript
{
public:
    basic_rules_dk_talent_points() : PlayerScript("basic_rules_dk_talent_points", { PLAYERHOOK_ON_CALCULATE_TALENTS_POINTS }) { }

    void OnPlayerCalculateTalentsPoints(Player const* player, uint32& talentPointsForLevel) override
    {
        if (!player->IsClass(CLASS_DEATH_KNIGHT, CLASS_CONTEXT_TALENT_POINT_CALC))
            return;

        static bool ledgerChecked = false, ledgerThere = false;
        if (!ledgerChecked)
        {
            ledgerChecked = true;
            ledgerThere   = bool(CharacterDatabase.Query("SHOW TABLES LIKE 'basic_718_souls'"));
            if (!ledgerThere)
                LOG_ERROR("server.loading", "basic: death knight talent points (718d): the soul ledger basic_718_souls is missing "
                    "(install step E041 not applied?); every death knight takes the skipper's table, story players included");
        }
        uint32 guid = player->GetGUID().GetCounter();
        if (ledgerThere)
        {
            if (QueryResult row = CharacterDatabase.Query("SELECT skipped FROM basic_718_souls WHERE dk = {}", guid))
            {
                if (row->Fetch()[0].Get<uint8>() == 0)
                    return;
            }
            else if (QueryResult owner = CharacterDatabase.Query("SELECT owner FROM buddy_roster WHERE buddy = {} LIMIT 1", guid))
            {
                uint32 ownerGuid = owner->Fetch()[0].Get<uint32>();
                QueryResult ownerRow = CharacterDatabase.Query("SELECT skipped FROM basic_718_souls WHERE dk = {}", ownerGuid);
                if (ownerRow && ownerRow->Fetch()[0].Get<uint8>() == 0)
                {
                    uint32 questPoints = 0;
                    for (uint32 questId : player->getRewardedQuests())
                        if (Quest const* quest = sObjectMgr->GetQuestTemplate(questId))
                            questPoints += quest->GetBonusTalents();
                    uint32 level    = player->GetLevel();
                    uint32 everyone = level > 9 ? level - 9 : 0;
                    uint32 points   = questPoints + (level > BASIC_DK_FIRST_LEVEL ? level - BASIC_DK_FIRST_LEVEL : 0);
                    talentPointsForLevel = std::min(points, everyone) + const_cast<Player*>(player)->GetBonusTalentCount();
                    return;
                }
            }
            else
                return;
        }

        uint32 level = player->GetLevel();
        uint32 points;
        if (level < BASIC_DK_FIRST_LEVEL)
            points = 0;
        else if (level <= BASIC_DK_CAUGHT_UP_LEVEL)
            points = BASIC_DK_TALENTS_IN_ALL[level - BASIC_DK_FIRST_LEVEL];
        else
            points = level - 9;

        points += const_cast<Player*>(player)->GetBonusTalentCount();
        talentPointsForLevel = points;
    }
};

struct BasicCreatureMultipliers
{
    float melee  = 1.0f;
    float spell  = 1.0f;
    float heal   = 1.0f;
    float health = 1.0f;
};

static std::unordered_map<uint32, BasicCreatureMultipliers> sBasicMultByEntry;
static std::unordered_map<uint32, BasicCreatureMultipliers> sBasicMultByMap;

static uint32 LoadBasicCreatureMultipliers()
{
    sBasicMultByEntry.clear();
    sBasicMultByMap.clear();

    QueryResult result = WorldDatabase.Query("SELECT entry, map_id, melee, spell, heal, health FROM basic_creature_multipliers");
    if (!result)
    {
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

    void ModifyMeleeDamage(Unit* , Unit* attacker, uint32& damage) override
    {
        if (BasicCreatureMultipliers const* m = BasicMultipliersFor(attacker))
            damage = uint32(damage * m->melee);
    }

    void ModifySpellDamageTaken(Unit* , Unit* attacker, int32& damage, SpellInfo const* ) override
    {
        if (BasicCreatureMultipliers const* m = BasicMultipliersFor(attacker))
            damage = int32(damage * m->spell);
    }

    void ModifyPeriodicDamageAurasTick(Unit* , Unit* attacker, uint32& damage, SpellInfo const* spellInfo) override
    {
        if (spellInfo && spellInfo->IsPositive())
            return;
        if (BasicCreatureMultipliers const* m = BasicMultipliersFor(attacker))
            damage = uint32(damage * m->spell);
    }

    void ModifyHealReceived(Unit* first, Unit* second, uint32& heal, SpellInfo const* ) override
    {
        BasicCreatureMultipliers const* m = BasicMultipliersFor(second);
        if (!m)
            m = BasicMultipliersFor(first);
        if (m)
            heal = uint32(heal * m->heal);
    }
};

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


static constexpr uint32 WORLD_BOSS_KAZZAK        = 18728;
static constexpr float  BATTLE_BONUS_DAMAGE      = 1.01f;
static constexpr uint32 BATTLE_BONUS_HEALTH_DIV  = 100;
static constexpr uint32 BATTLE_BONUS_CHECK_MS    = 1000;

static std::vector<uint32> const SWARM_PACK      = { 19397, 19398, 19398 };
static constexpr float  SWARM_PACK_SPACING       = 60.0f;
static constexpr float  SWARM_KAZZAK_CLEAR       = 60.0f;
static constexpr float  SWARM_MEMBER_SPREAD      = 4.0f;
static constexpr uint32 SWARM_TRIES_PER_PACK     = 40;

static std::unordered_map<uint32, uint32> sWorldBossEntry;
static std::mutex        sWorldBossLock;
static std::set<uint32>  sWorldBossAlive;
static std::atomic<bool> sBattleBonusWanted { false };
static std::atomic<bool> sBattleBonusOn { false };

static std::mutex sBattleBonusLock;
static std::map<std::pair<Map const*, ObjectGuid>, uint32> sBattleBonusHealth;

static std::vector<ObjectGuid> sSwarm;
static uint32 sSwarmMap = 0;

static bool IsMonster(Unit const* unit)
{
    if (!unit || !unit->IsCreature() || unit->IsControlledByPlayer())
        return false;
    FactionTemplateEntry const* mine = unit->GetFactionTemplateEntry();
    static FactionTemplateEntry const* alliance = sFactionTemplateStore.LookupEntry(1);
    static FactionTemplateEntry const* horde    = sFactionTemplateStore.LookupEntry(2);
    return mine && alliance && horde && mine->IsHostileTo(*alliance) && mine->IsHostileTo(*horde);
}

static void BattleBonusHealth(Map const* map, Creature* creature, bool apply)
{
    auto key = std::make_pair(map, creature->GetGUID());
    uint32 amount = 0;
    {
        std::lock_guard<std::mutex> lock(sBattleBonusLock);
        auto it = sBattleBonusHealth.find(key);
        if (apply == (it != sBattleBonusHealth.end()))
            return;
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

static void BattleBonusEverywhere(bool apply)
{
    uint32 count = 0;
    sMapMgr->DoForAllMaps([apply, &count](Map* map)
    {
        for (auto const& pair : map->GetObjectsStore().GetElements()._elements._element)
            if (Creature* creature = pair.second)
                if (creature->IsInWorld() && IsMonster(creature))
                {
                    BattleBonusHealth(map, creature, apply);
                    ++count;
                }
    });
    LOG_INFO("server.loading", ">> basic: world boss battle bonus {} ({} monsters)", apply ? "ON" : "OFF", count);
}

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

static uint32 HumansInZone(uint32 mapId, uint32 zoneId)
{
    uint32 count = 0;
    std::shared_lock<std::shared_mutex> lock(*HashMapHolder<Player>::GetLock());
    for (auto const& [guid, player] : ObjectAccessor::GetPlayers())
        if (player && player->IsInWorld() && player->GetMapId() == mapId && player->GetZoneId() == zoneId
            && player->GetSession() && !player->GetSession()->IsHeadless())
            ++count;
    return count;
}

static void SpawnKazzakSwarm(Map* map, CreatureData const* kazzak, ChatHandler* handler)
{
    for (ObjectGuid const& guid : sSwarm)
        if (Map* old = sMapMgr->FindBaseNonInstanceMap(sSwarmMap))
            if (Creature* creature = old->GetCreature(guid))
                if (TempSummon* summon = creature->ToTempSummon())
                    summon->UnSummon();
    sSwarm.clear();
    sSwarmMap = map->GetId();

    uint32 zone = map->GetZoneId(PHASEMASK_NORMAL, kazzak->posX, kazzak->posY, kazzak->posZ);
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
                member->SetTempSummonType(TEMPSUMMON_DEAD_DESPAWN);
                if (i == 0)
                    member->setActive(true);
                sSwarm.push_back(member->GetGUID());
            }
            break;
        }
    }
    LOG_INFO("scripts", "basic: Kazzak's swarm: {} players in zone {}, {} of {} packs placed ({} demons)",
        HumansInZone(map->GetId(), zone), zone, placed.size(), packs, sSwarm.size());
    handler->PSendSysMessage("basic: Kazzak's swarm: {} of {} packs placed ({} demons).", placed.size(), packs, sSwarm.size());
}

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

class basic_rules_world_boss_world : public WorldScript
{
public:
    basic_rules_world_boss_world() : WorldScript("basic_rules_world_boss_world",
        { WORLDHOOK_ON_LOAD_CUSTOM_DATABASE_TABLE, WORLDHOOK_ON_UPDATE }) { }

    void OnLoadCustomDatabaseTable() override { LoadWorldBosses(); }

    void OnUpdate(uint32 diff) override
    {
        _sinceCheck += diff;
        if (_sinceCheck < BATTLE_BONUS_CHECK_MS)
            return;
        _sinceCheck = 0;
        bool wanted = sBattleBonusWanted;
        if (wanted == sBattleBonusOn)
            return;
        sBattleBonusOn = wanted;
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

    void OnUnitDeath(Unit* unit, Unit* ) override
    {
        Creature* creature = unit->ToCreature();
        if (!creature || !creature->GetSpawnId() || !sWorldBossEntry.count(creature->GetSpawnId()))
            return;
        SetWorldBossAlive(creature->GetSpawnId(), false);
        LOG_INFO("scripts", "basic: world boss {} (spawn {}) died; the respawn countdown starts",
            creature->GetName(), creature->GetSpawnId());
    }

    void ModifyMeleeDamage(Unit* , Unit* attacker, uint32& damage) override
    {
        if (sBattleBonusOn && IsMonster(attacker))
            damage = uint32(damage * BATTLE_BONUS_DAMAGE);
    }

    void ModifySpellDamageTaken(Unit* , Unit* attacker, int32& damage, SpellInfo const* ) override
    {
        if (sBattleBonusOn && IsMonster(attacker) && damage > 0)
            damage = int32(damage * BATTLE_BONUS_DAMAGE);
    }

    void ModifyPeriodicDamageAurasTick(Unit* , Unit* attacker, uint32& damage, SpellInfo const* spellInfo) override
    {
        if (spellInfo && spellInfo->IsPositive())
            return;
        if (sBattleBonusOn && IsMonster(attacker))
            damage = uint32(damage * BATTLE_BONUS_DAMAGE);
    }
};

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


struct BasicDropRates
{
    bool   on        = false;
    float  greenBlue = 1.0f;
    float  epic      = 1.0f;
    uint32 rareRolls = 1;
};
static BasicDropRates sBasicDrops;
static std::unordered_set<uint32> sBasicBossEntries;
static std::unordered_map<uint32, uint32> sBasicRefQuality;
static std::unordered_set<uint32> sBasicBandTables;

static void LoadBasicDrops()
{
    sBasicDrops = BasicDropRates();
    sBasicBossEntries.clear();
    sBasicRefQuality.clear();
    sBasicBandTables.clear();

    std::string gb   = sConfigMgr->GetOption<std::string>("Basic.Drops.GreenBlueRate", "", false);
    std::string ep   = sConfigMgr->GetOption<std::string>("Basic.Drops.EpicRate", "", false);
    std::string rr   = sConfigMgr->GetOption<std::string>("Basic.Drops.RareRolls", "", false);
    if (gb.empty() || ep.empty() || rr.empty())
    {
        LOG_ERROR("server.loading", ">> basic: Basic.Drops.GreenBlueRate, EpicRate and RareRolls are not all set (config patch C040 not run?); monster drops are stock");
        return;
    }
    sBasicDrops.greenBlue = std::stof(gb);
    sBasicDrops.epic      = std::stof(ep);
    sBasicDrops.rareRolls = uint32(std::max(1, std::stoi(rr)));
    sBasicDrops.on        = true;

    if (QueryResult r = WorldDatabase.Query("SELECT DISTINCT creditEntry FROM instance_encounters WHERE creditType = 0"))
        do sBasicBossEntries.insert(r->Fetch()[0].Get<uint32>()); while (r->NextRow());
    if (QueryResult r = WorldDatabase.Query("SELECT r.Entry, MIN(i.Quality), MAX(i.Quality) FROM reference_loot_template r "
                                            "JOIN item_template i ON i.entry = r.Item WHERE r.Reference = 0 GROUP BY r.Entry"))
        do
        {
            Field* f = r->Fetch();
            if (f[1].Get<uint32>() == f[2].Get<uint32>())
                sBasicRefQuality[f[0].Get<uint32>()] = f[1].Get<uint32>();
        } while (r->NextRow());
    if (QueryResult r = WorldDatabase.Query("SELECT DISTINCT ABS(l.Reference) FROM creature_loot_template l WHERE l.Reference <> 0 "
                                            "AND ABS(l.Reference) IN (SELECT Entry FROM reference_loot_template WHERE Reference <> 0)"))
        do sBasicBandTables.insert(r->Fetch()[0].Get<uint32>()); while (r->NextRow());

    LOG_INFO("server.loading", ">> basic: monster drops: greens and blues x{}, epics x{}, rares' loot rolled {} times; {} bosses kept stock, {} one-quality loot tables, {} level bands",
        sBasicDrops.greenBlue, sBasicDrops.epic, sBasicDrops.rareRolls, sBasicBossEntries.size(), sBasicRefQuality.size(), sBasicBandTables.size());
}

enum class BasicDropKind { Stock, Ordinary, Rare };

static BasicDropKind BasicDropKindOf(Loot const& loot, LootStore const& store)
{
    if (!sBasicDrops.on || &store != &LootTemplates_Creature)
        return BasicDropKind::Stock;
    ObjectGuid source = loot.sourceWorldObjectGUID;
    if (!source.IsCreature())
        return BasicDropKind::Stock;
    uint32 entry = source.GetEntry();
    if (sBasicBossEntries.count(entry))
        return BasicDropKind::Stock;
    CreatureTemplate const* t = sObjectMgr->GetCreatureTemplate(entry);
    if (!t || t->rank == CREATURE_ELITE_WORLDBOSS || (t->type_flags & CREATURE_TYPE_FLAG_BOSS_MOB))
        return BasicDropKind::Stock;
    if (t->rank == CREATURE_ELITE_RARE || t->rank == CREATURE_ELITE_RAREELITE)
        return BasicDropKind::Rare;
    return BasicDropKind::Ordinary;
}

class basic_rules_drops_load : public WorldScript
{
public:
    basic_rules_drops_load() : WorldScript("basic_rules_drops_load", { WORLDHOOK_ON_LOAD_CUSTOM_DATABASE_TABLE }) { }

    void OnLoadCustomDatabaseTable() override { LoadBasicDrops(); }
};

class basic_rules_drops_roll : public GlobalScript
{
public:
    basic_rules_drops_roll() : GlobalScript("basic_rules_drops_roll", { GLOBALHOOK_ON_ITEM_ROLL, GLOBALHOOK_ON_AFTER_REF_COUNT }) { }

    bool OnItemRoll(Player const* , LootStoreItem const* item, float& chance, Loot& loot, LootStore const& store) override
    {
        BasicDropKind kind = BasicDropKindOf(loot, store);
        if (kind == BasicDropKind::Ordinary)
        {
            uint32 quality = 0;
            if (item->reference)
            {
                auto q = sBasicRefQuality.find(uint32(std::abs(item->reference)));
                if (q != sBasicRefQuality.end())
                    quality = q->second;
            }
            else if (ItemTemplate const* proto = sObjectMgr->GetItemTemplate(item->itemid))
                quality = proto->Quality;
            if (quality == ITEM_QUALITY_UNCOMMON || quality == ITEM_QUALITY_RARE)
                chance *= sBasicDrops.greenBlue;
            else if (quality == ITEM_QUALITY_EPIC)
                chance *= sBasicDrops.epic;
        }
        else if (kind == BasicDropKind::Rare && !item->reference && !item->groupid && chance > 0.0f && chance < 100.0f)
        {
            float miss = std::pow(1.0f - chance / 100.0f, float(sBasicDrops.rareRolls));
            chance = 100.0f * (1.0f - miss);
        }
        return true;
    }

    void OnAfterRefCount(Player const* , LootStoreItem* item, Loot& loot, bool , uint16 , uint32& maxcount, LootStore const& store) override
    {
        if (BasicDropKindOf(loot, store) == BasicDropKind::Rare && sBasicBandTables.count(uint32(std::abs(item->reference))))
            maxcount *= sBasicDrops.rareRolls;
    }
};

static char const* const BASIC_SHOULDERS_SETTING = "basic-shoulders";

static bool BasicShouldersHidden(Player* player)
{
    return player && sWorld->getBoolConfig(CONFIG_PLAYER_SETTINGS_ENABLED)
        && player->GetPlayerSetting(BASIC_SHOULDERS_SETTING, 0).IsEnabled();
}

class basic_rules_hide_shoulders : public PlayerScript
{
public:
    basic_rules_hide_shoulders() : PlayerScript("basic_rules_hide_shoulders", { PLAYERHOOK_ON_AFTER_SET_VISIBLE_ITEM_SLOT, PLAYERHOOK_ON_LOGIN }) { }

    void OnPlayerAfterSetVisibleItemSlot(Player* player, uint8 slot, Item* item) override
    {
        if (slot != EQUIPMENT_SLOT_SHOULDERS || !item || !BasicShouldersHidden(player))
            return;
        player->SetUInt32Value(PLAYER_VISIBLE_ITEM_1_ENTRYID + (slot * 2), 0);
        player->SetUInt32Value(PLAYER_VISIBLE_ITEM_1_ENCHANTMENT + (slot * 2), 0);
    }

    void OnPlayerLogin(Player* player) override
    {
        if (BasicShouldersHidden(player))
            player->SetVisibleItemSlot(EQUIPMENT_SLOT_SHOULDERS, player->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_SHOULDERS));
    }
};

class basic_rules_hide_shoulders_command : public CommandScript
{
public:
    basic_rules_hide_shoulders_command() : CommandScript("basic_rules_hide_shoulders_command") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "shoulders", HandleShoulders, SEC_PLAYER, Console::No },
        };
        return commandTable;
    }

    static bool HandleShoulders(ChatHandler* handler)
    {
        Player* player = handler->GetSession()->GetPlayer();
        if (!sWorld->getBoolConfig(CONFIG_PLAYER_SETTINGS_ENABLED))
        {
            handler->SendSysMessage("Hiding shoulders needs EnablePlayerSettings = 1 (config patch C041); it is off on this server.");
            return false;
        }
        bool hide = !BasicShouldersHidden(player);
        player->UpdatePlayerSetting(BASIC_SHOULDERS_SETTING, 0, hide ? 1 : 0);
        player->SetVisibleItemSlot(EQUIPMENT_SLOT_SHOULDERS, player->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_SHOULDERS));
        handler->SendSysMessage(hide ? "Your shoulders are hidden. Type .shoulders again to show them." : "Your shoulders are shown again.");
        return true;
    }
};

void AddSC_basic_rules()
{
    new basic_rules_talent_cap();
    new basic_rules_dk_talent_points();
    new basic_rules_creature_multipliers_load();
    new basic_rules_creature_multipliers_damage();
    new basic_rules_creature_multipliers_health();
    new basic_rules_creature_multipliers_command();
    new basic_rules_world_boss_world();
    new basic_rules_world_boss_unit();
    new basic_rules_world_boss_creature();
    new basic_rules_world_boss_command();
    new basic_rules_refused_channels_report();
    new basic_rules_drops_load();
    new basic_rules_drops_roll();
    new basic_rules_hide_shoulders();
    new basic_rules_hide_shoulders_command();
}
