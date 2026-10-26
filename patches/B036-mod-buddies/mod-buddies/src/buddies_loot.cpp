
#include "buddies.h"
#include "buddies_loot.h"
#include "DatabaseEnv.h"
#include "Group.h"
#include "ItemTemplate.h"
#include "Log.h"
#include "LootRollAction.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "ScriptMgr.h"
#include "SpellMgr.h"
#include <mutex>
#include <shared_mutex>
#include <unordered_map>
#include <vector>

static constexpr uint8 PLAN_THIRDS[10][3] = {
    { 2, 1, 0 },
    { 2, 0, 1 },
    { 1, 2, 0 },
    { 0, 2, 1 },
    { 1, 0, 2 },
    { 0, 1, 2 },
    { 1, 1, 1 },
    { 3, 0, 0 },
    { 0, 3, 0 },
    { 0, 0, 3 },
};
static constexpr uint8 PLAN_THIRDS_EACH  = 7;

int8 BuddyPlanMainTree(uint8 profile)
{
    if (profile < 1 || profile > 10)
        return -1;
    uint8 const* t = PLAN_THIRDS[profile - 1];
    int8 best = 0;
    for (int8 i = 1; i < 3; ++i)
        if (t[i] > t[best])
            best = i;
    return best;
}
static constexpr uint8 ROLE_TANK         = 1;

static constexpr uint32 REFRESH_MS       = 10000;

struct BuddyLootFacts
{
    uint32 owner   = 0;
    uint8  profile = 0;
    uint8  role    = 0;
};

static std::shared_mutex                                  sLootLock;
static std::unordered_map<uint32, BuddyLootFacts>         sBuddyFacts;
static std::unordered_map<uint32, std::vector<uint32>>    sClanMembers;
static std::unordered_map<uint32, float>                  sItemLevels;

static float OfflineItemLevel(uint32 guid)
{
    QueryResult level = CharacterDatabase.Query("SELECT level FROM characters WHERE guid = {}", guid);
    if (!level)
    {
        LOG_ERROR("module", "mod-buddies: clan member {} is in buddy_roster but has no characters row; its item level counts as 0", guid);
        return 0.0f;
    }
    uint8 charLevel = (*level)[0].Get<uint8>();

    float  sum   = 0.0f;
    uint32 slots = 0;
    for (uint8 s = EQUIPMENT_SLOT_START; s < EQUIPMENT_SLOT_END; ++s)
        if (s != EQUIPMENT_SLOT_TABARD && s != EQUIPMENT_SLOT_RANGED && s != EQUIPMENT_SLOT_OFFHAND && s != EQUIPMENT_SLOT_BODY)
            ++slots;

    if (QueryResult rows = CharacterDatabase.Query(
            "SELECT ii.itemEntry, ci.slot FROM character_inventory ci JOIN item_instance ii ON ii.guid = ci.item "
            "WHERE ci.guid = {} AND ci.bag = 0 AND ci.slot < {}", guid, uint32(EQUIPMENT_SLOT_END)))
        do
        {
            uint8 slot = (*rows)[1].Get<uint8>();
            if (slot == EQUIPMENT_SLOT_TABARD || slot == EQUIPMENT_SLOT_RANGED || slot == EQUIPMENT_SLOT_OFFHAND || slot == EQUIPMENT_SLOT_BODY)
                continue;
            ItemTemplate const* proto = sObjectMgr->GetItemTemplate((*rows)[0].Get<uint32>());
            if (!proto)
            {
                LOG_ERROR("module", "mod-buddies: character {} wears item {}, which has no item_template row; it counts as 0",
                    guid, (*rows)[0].Get<uint32>());
                continue;
            }
            sum += proto->GetItemLevelIncludingQuality(charLevel);
        }
        while (rows->NextRow());

    return sum / float(slots);
}

static void RefreshLootFacts()
{
    std::unordered_map<uint32, BuddyLootFacts>      facts;
    std::unordered_map<uint32, std::vector<uint32>> clans;
    if (QueryResult rows = CharacterDatabase.Query("SELECT buddy, owner, profile, role FROM buddy_roster WHERE buddy <> 0"))
        do
        {
            BuddyLootFacts f;
            uint32 buddy = (*rows)[0].Get<uint32>();
            f.owner      = (*rows)[1].Get<uint32>();
            f.profile    = (*rows)[2].Get<uint8>();
            f.role       = (*rows)[3].Get<uint8>();
            facts[buddy] = f;
            std::vector<uint32>& members = clans[f.owner];
            if (members.empty())
                members.push_back(f.owner);
            members.push_back(buddy);
        }
        while (rows->NextRow());

    std::unordered_map<uint32, float> levels;
    {
        std::shared_lock<std::shared_mutex> read(sLootLock);
        levels = sItemLevels;
    }
    for (auto const& [owner, members] : clans)
        for (uint32 guid : members)
        {
            if (Player* p = ObjectAccessor::FindPlayerByLowGUID(guid))
                levels[guid] = p->GetAverageItemLevel();
            else if (levels.find(guid) == levels.end())
                levels[guid] = OfflineItemLevel(guid);
        }

    std::unique_lock<std::shared_mutex> write(sLootLock);
    sBuddyFacts.swap(facts);
    sClanMembers.swap(clans);
    sItemLevels.swap(levels);
}

static bool FactsFor(Player* player, BuddyLootFacts& out)
{
    std::shared_lock<std::shared_mutex> read(sLootLock);
    auto it = sBuddyFacts.find(player->GetGUID().GetCounter());
    if (it == sBuddyFacts.end())
        return false;
    out = it->second;
    return true;
}

static CollectorType TreeCollector(uint8 cls, int tab, uint8 role)
{
    switch (cls)
    {
        case CLASS_WARRIOR:
            return tab == WARRIOR_TAB_PROTECTION ? CollectorType::MELEE_TANK : CollectorType::MELEE_DMG;
        case CLASS_PALADIN:
            if (tab == PALADIN_TAB_HOLY)
                return CollectorType::SPELL_HEAL;
            return tab == PALADIN_TAB_PROTECTION ? CollectorType::MELEE_TANK : CollectorType::MELEE_DMG;
        case CLASS_DEATH_KNIGHT:
            return tab == DEATH_KNIGHT_TAB_BLOOD ? CollectorType::MELEE_TANK : CollectorType::MELEE_DMG;
        case CLASS_ROGUE:
            return CollectorType::MELEE_DMG;
        case CLASS_HUNTER:
            return CollectorType::RANGED;
        case CLASS_PRIEST:
            return tab == PRIEST_TAB_SHADOW ? CollectorType::SPELL_DMG : CollectorType::SPELL_HEAL;
        case CLASS_SHAMAN:
            if (tab == SHAMAN_TAB_RESTORATION)
                return CollectorType::SPELL_HEAL;
            return tab == SHAMAN_TAB_ENHANCEMENT ? CollectorType::MELEE_DMG : CollectorType::SPELL_DMG;
        case CLASS_DRUID:
            if (tab == DRUID_TAB_RESTORATION)
                return CollectorType::SPELL_HEAL;
            if (tab == DRUID_TAB_FERAL)
                return role == ROLE_TANK ? CollectorType::MELEE_TANK : CollectorType::MELEE_DMG;
            return CollectorType::SPELL_DMG;
        default:
            return CollectorType::SPELL_DMG;
    }
}

bool BuddyTalentPlan(Player* player, uint8 (&thirds)[3], CollectorType (&types)[3])
{
    if (!BuddiesEnabled())
        return false;
    BuddyLootFacts f;
    if (!FactsFor(player, f))
        return false;
    if (f.profile == 0)
        return false;
    if (f.profile > 10)
    {
        LOG_ERROR("module", "mod-buddies: buddy {} has talent plan {} in buddy_roster, outside 1-10; scored by its main tree",
            player->GetName(), f.profile);
        return false;
    }
    return BuddyPlanShape(player->getClass(), f.profile, f.role, thirds, types);
}

static constexpr float FIGHT_SECONDS = 30.0f;
static constexpr float HEALTH_PER_STAMINA = 10.0f;

float BuddySpiritWorth(Player* player)
{
    if (!BuddiesEnabled())
        return -1.0f;
    BuddyLootFacts f;
    if (!FactsFor(player, f))
        return -1.0f;
    float stamina = player->GetStat(STAT_STAMINA);
    float spirit  = player->GetStat(STAT_SPIRIT);
    float ticks   = FIGHT_SECONDS / 5.0f;
    float fromSpirit  = stamina / 100.0f * ticks;
    float fromStamina = HEALTH_PER_STAMINA + spirit / 100.0f * ticks;
    return fromSpirit / fromStamina;
}

bool BuddyPlanShape(uint8 cls, uint8 profile, uint8 role, uint8 (&thirds)[3], CollectorType (&types)[3])
{
    if (profile == 0 || profile > 10)
        return false;
    for (int t = 0; t < 3; ++t)
    {
        thirds[t] = PLAN_THIRDS[profile - 1][t];
        types[t]  = TreeCollector(cls, t, role);
    }
    return true;
}

static bool IsClassBook(ItemTemplate const* proto)
{
    return proto->Class == ITEM_CLASS_RECIPE && proto->SubClass == ITEM_SUBCLASS_BOOK
        && proto->Spells[1].SpellTrigger == ITEM_SPELLTRIGGER_LEARN_SPELL_ID && proto->Spells[1].SpellId > 0;
}

static bool NeedsBook(Player* who, ItemTemplate const* proto)
{
    if (!(proto->AllowableClass & who->getClassMask()))
        return false;
    if (proto->AllowableRace && !(proto->AllowableRace & who->getRaceMask()))
        return false;
    if (proto->RequiredSpell && !who->HasSpell(proto->RequiredSpell))
        return false;
    for (uint32 spell = uint32(proto->Spells[1].SpellId); spell; spell = sSpellMgr->GetNextSpellInChain(spell))
        if (who->HasSpell(spell))
            return false;
    return true;
}

static bool ClanItemLevel(uint32 owner, float& out)
{
    std::shared_lock<std::shared_mutex> read(sLootLock);
    auto clan = sClanMembers.find(owner);
    if (clan == sClanMembers.end())
        return false;
    float  sum = 0.0f;
    uint32 n   = 0;
    for (uint32 guid : clan->second)
    {
        auto level = sItemLevels.find(guid);
        if (level == sItemLevels.end())
        {
            LOG_ERROR("module", "mod-buddies: clan member {} of owner {} has no measured item level; left out of the clan average",
                guid, owner);
            continue;
        }
        sum += level->second;
        ++n;
    }
    if (n == 0)
        return false;
    out = sum / float(n);
    return true;
}

RollVote BuddyLootRollVote(Player* bot, ItemTemplate const* proto, int32 , RollVote judged, RollVote configured)
{
    if (!BuddiesEnabled())
        return configured;
    BuddyLootFacts f;
    if (!FactsFor(bot, f))
        return configured;

    if (IsClassBook(proto))
    {
        Player* owner = ObjectAccessor::FindPlayerByLowGUID(f.owner);
        Group*  group = bot->GetGroup();
        if (owner && group && group->IsMember(owner->GetGUID()) && NeedsBook(owner, proto))
            return PASS;
        if (NeedsBook(bot, proto))
            return NEED;
        return GREED;
    }

    switch (judged)
    {
        case NEED:
        {
            if (RollUniqueCheck(proto, bot))
                return PASS;
            if (f.profile != PLAN_THIRDS_EACH)
                return NEED;
            float clan = 0.0f;
            if (!ClanItemLevel(f.owner, clan))
            {
                LOG_ERROR("module", "mod-buddies: buddy {} rolls on {} but its clan (owner {}) is not remembered yet; greeds",
                    bot->GetName(), proto->ItemId, f.owner);
                return GREED;
            }
            return bot->GetAverageItemLevel() < clan ? NEED : GREED;
        }
        case GREED:
        case DISENCHANT:
            return judged;
        default:
            return PASS;
    }
}

class buddies_loot_world : public WorldScript
{
public:
    buddies_loot_world() : WorldScript("buddies_loot_world", { WORLDHOOK_ON_UPDATE }) { }

    void OnUpdate(uint32 diff) override
    {
        if (!BuddiesEnabled())
            return;
        _sinceRefresh += diff;
        if (_refreshed && _sinceRefresh < REFRESH_MS)
            return;
        _sinceRefresh = 0;
        _refreshed    = true;
        RefreshLootFacts();
    }

private:
    uint32 _sinceRefresh = 0;
    bool   _refreshed    = false;
};

void AddSC_buddies_loot()
{
    new buddies_loot_world();
}
