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
 *   - Talent cap (issue 155g): no talent in tier 6 or deeper (30+ points in
 *     the tree), as vanilla-era trees ended around there. Covers the tier-6
 *     "capstones" (fire mage Combustion, retribution Repentance), the talents
 *     beside them, and every deeper row. The client still draws the whole
 *     tree (its data files can't be changed); the server refuses and says why.
 *   - Creature multipliers (issue 155i): per-creature (or per-map) multipliers
 *     on a creature's melee damage, spell damage, healing and health, read
 *     from the world table basic_creature_multipliers (install step E026) at
 *     startup and on ".basic reload multipliers". Tuning a boss is one table
 *     row, not a recompile. Players and anything they control are never
 *     scaled.
 */

#include "Chat.h"
#include "CommandScript.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "DBCStructure.h"
#include "Log.h"
#include "Player.h"
#include "RBAC.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include <algorithm>
#include <unordered_map>

using namespace Acore::ChatCommands;

// -- {{{ talent cap
// Row index of the first refused tier. Row n needs 5n points in the tree, so
// row 6 is the "30 points spent" row: Combustion and Repentance live there
// (checked in the client's Talent.dbc, 2026-09-23).
static constexpr uint32 BASIC_FIRST_CAPPED_TALENT_ROW = 6;

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
        if (talent->Row < BASIC_FIRST_CAPPED_TALENT_ROW)
            return true;

        // A real player gets told why; a bot has no one to read it.
        if (player->GetSession() && !player->GetSession()->IsBot())
            ChatHandler(player->GetSession()).SendSysMessage(
                "That talent is beyond this realm's limit: talents needing 30 or more points in a tree are sealed.");
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

// -- {{{ AddSC_basic_rules
// Registered from src/server/scripts/Custom/custom_script_loader.cpp by B030.
void AddSC_basic_rules()
{
    new basic_rules_talent_cap();
    new basic_rules_creature_multipliers_load();
    new basic_rules_creature_multipliers_damage();
    new basic_rules_creature_multipliers_health();
    new basic_rules_creature_multipliers_command();
}
// -- }}}
