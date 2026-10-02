/*
 * buddies_loot.cpp - how buddies judge gear and roll on group loot (issue
 * 617j).
 *
 * For a general audience: a buddy and its owner are a clan sharing one
 * pool of gear. Three things follow from the owner's design (2026-09-24):
 *
 *   - "Upgrade" is decided by stat weights per talent tree: how much a
 *     tree values each stat. A buddy follows a talent plan (617g) that
 *     splits its points, so an item is scored by each tree it spends in,
 *     weighted by its share: a 2/3 holy, 1/3 protection paladin scores with
 *     holy's weights at two thirds and protection's at one third; a buddy
 *     with a third in each tree scores a third of each. The weights are the
 *     bot module's own level-80 table, used as is (no level-60 table
 *     exists). The bot module does the scoring; this file tells it the plan
 *     (source patch B046 makes it ask). Every place the bot module scores
 *     gear then agrees: equipping upgrades from loot, trades and mail,
 *     choosing quest rewards, and rolling.
 *   - Rolls: a buddy needs an upgrade and greeds what it could sell. A
 *     buddy with a third in each tree greeds even its upgrades, unless its
 *     gear is below its clan's average (average equipped item level of the
 *     owner and every buddy of the owner), then it needs them until it is
 *     above again. Class books (155q) go to the owner first.
 *   - Always equip upgrades: the bot module already equips an upgrade the
 *     moment it enters a bot's bags (loot, roll won, trade) and checks its
 *     bags now and then (mail), with AiPlayerbot.AutoEquipUpgradeLoot on
 *     (basic: on). Scored by the plan, that is the owner's rule.
 *
 * What is remembered: every made buddy's owner, plan and role, and every
 * clan member's average item level, refreshed every 10 seconds on the
 * world thread, read by the bot updates on the map threads. A character
 * online is measured as it stands; one offline is measured once from the
 * database (its gear cannot change while it is offline).
 */

#include "buddies.h"
#include "buddies_loot.h"
#include "DatabaseEnv.h"
#include "Group.h"
#include "ItemTemplate.h"
#include "Log.h"
#include "LootRollAction.h"                            // RollUniqueCheck
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerbotAI.h"                               // the *_TAB_* tree numbers
#include "ScriptMgr.h"
#include "SpellMgr.h"
#include <mutex>
#include <shared_mutex>
#include <unordered_map>
#include <vector>

// {{{ the plans
// buddy_roster.profile (1-10) -> points per tree in thirds. The generator
// (scripts/generate-basic-talent-data, src/lua-basic/data/buddy-talent-
// data.lua) writes the ten shapes in this same order for every class
// (checked 2026-10-02: all ten classes alike), so one table serves all.
// If the generator's order ever changes, this table must change with it.
static constexpr uint8 PLAN_THIRDS[10][3] = {
    { 2, 1, 0 },  //  1  2/3 first, 1/3 second
    { 2, 0, 1 },  //  2  2/3 first, 1/3 third
    { 1, 2, 0 },  //  3  1/3 first, 2/3 second
    { 0, 2, 1 },  //  4  2/3 second, 1/3 third
    { 1, 0, 2 },  //  5  1/3 first, 2/3 third
    { 0, 1, 2 },  //  6  1/3 second, 2/3 third
    { 1, 1, 1 },  //  7  a third in each: the clan-average roller
    { 3, 0, 0 },  //  8  all first
    { 0, 3, 0 },  //  9  all second
    { 0, 0, 3 },  // 10  all third
};
static constexpr uint8 PLAN_THIRDS_EACH  = 7;
static constexpr uint8 ROLE_TANK         = 1;           // buddy_roster.role: 0 damage, 1 tank, 2 healer

static constexpr uint32 REFRESH_MS       = 10000;       // how stale the remembered facts may be
// }}}

// {{{ what is remembered
struct BuddyLootFacts
{
    uint32 owner   = 0;                                // the owner's character guid (low part)
    uint8  profile = 0;                                // buddy_roster.profile; 0 until chosen
    uint8  role    = 0;                                // buddy_roster.role
};

static std::shared_mutex                                  sLootLock;
static std::unordered_map<uint32, BuddyLootFacts>         sBuddyFacts;      // buddy guid -> facts
static std::unordered_map<uint32, std::vector<uint32>>    sClanMembers;     // owner guid -> owner and buddies
static std::unordered_map<uint32, float>                  sItemLevels;      // character guid -> average item level
// }}}

// {{{ OfflineItemLevel
// The server's average item level (Player::GetAverageItemLevel) worked out
// from the database for a character not in the world: the equipped items'
// levels (adjusted by quality, as the server does) summed over every
// equipment slot but shirt, tabard, off hand and ranged, divided by the
// number of those slots (15) whether filled or not.
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
                continue;                              // not counted by the server either
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
// }}}

// {{{ RefreshLootFacts
// World thread only (the map threads are idle while world scripts update).
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
                members.push_back(f.owner);            // the owner is the clan's first member
            members.push_back(buddy);
        }
        while (rows->NextRow());

    // Online members measured as they stand; offline ones once, kept until
    // they come online again.
    std::unordered_map<uint32, float> levels;
    {
        std::shared_lock<std::shared_mutex> read(sLootLock);
        levels = sItemLevels;
    }
    for (auto const& [owner, members] : clans)
        for (uint32 guid : members)
        {
            if (Player* p = ObjectAccessor::FindPlayerByLowGUID(guid))
                levels[guid] = p->GetAverageItemLevel();   // in the world: as it stands
            else if (levels.find(guid) == levels.end())
                levels[guid] = OfflineItemLevel(guid);     // offline and never measured: from the database
        }

    std::unique_lock<std::shared_mutex> write(sLootLock);
    sBuddyFacts.swap(facts);
    sClanMembers.swap(clans);
    sItemLevels.swap(levels);
}
// }}}

// {{{ FactsFor
// A buddy's remembered facts; false for anyone not a made buddy.
static bool FactsFor(Player* player, BuddyLootFacts& out)
{
    std::shared_lock<std::shared_mutex> read(sLootLock);
    auto it = sBuddyFacts.find(player->GetGUID().GetCounter());
    if (it == sBuddyFacts.end())
        return false;
    out = it->second;
    return true;
}
// }}}

// {{{ TreeCollector
// How a tree collects stats, by the bot module's own rules when it judges
// a bot by its talents (PlayerbotAI::IsHeal / IsTank / IsRanged, "by
// spec"), with one difference: the bot module counts a feral druid as a
// tank only while it is in bear form, a passing state; a buddy's plan
// says once and for all whether it tanks (its role).
static CollectorType TreeCollector(uint8 cls, int tab, uint8 role)
{
    switch (cls)
    {
        case CLASS_WARRIOR:
            return tab == WARRIOR_TAB_PROTECTION ? CollectorType::MELEE_TANK : CollectorType::MELEE_DMG;
        case CLASS_PALADIN:
            if (tab == PALADIN_TAB_HOLY)
                return CollectorType::SPELL_HEAL;      // the bot module's only ranged paladin
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
            return CollectorType::SPELL_DMG;           // balance
        default:
            return CollectorType::SPELL_DMG;           // mage, warlock
    }
}
// }}}

// {{{ BuddyTalentPlan
bool BuddyTalentPlan(Player* player, uint8 (&thirds)[3], CollectorType (&types)[3])
{
    if (!BuddiesEnabled())
        return false;                                  // module off: everyone scored as stock
    BuddyLootFacts f;
    if (!FactsFor(player, f))
        return false;                                  // not a buddy: stock
    if (f.profile == 0)
        return false;                                  // made before its plan was drawn: its own talents decide, as stock
    if (f.profile > 10)
    {
        LOG_ERROR("module", "mod-buddies: buddy {} has talent plan {} in buddy_roster, outside 1-10; scored by its main tree",
            player->GetName(), f.profile);
        return false;
    }
    for (int t = 0; t < 3; ++t)
    {
        thirds[t] = PLAN_THIRDS[f.profile - 1][t];
        types[t]  = TreeCollector(player->getClass(), t, f.role);
    }
    return true;
}
// }}}

// {{{ the clan's rules for rolls
// A class book (155q's, and the stock Ahn'Qiraj ones they copy): a book
// that teaches a spell when read.
static bool IsClassBook(ItemTemplate const* proto)
{
    return proto->Class == ITEM_CLASS_RECIPE && proto->SubClass == ITEM_SUBCLASS_BOOK
        && proto->Spells[1].SpellTrigger == ITEM_SPELLTRIGGER_LEARN_SPELL_ID && proto->Spells[1].SpellId > 0;
}

// Whether `who` would learn something from the book: its class and race
// may read it, it knows the talent the book may need, and it knows
// neither the rank taught nor any higher one (Ritz, 2026-09-25).
static bool NeedsBook(Player* who, ItemTemplate const* proto)
{
    if (!(proto->AllowableClass & who->getClassMask()))
        return false;                                  // another class's book
    if (proto->AllowableRace && !(proto->AllowableRace & who->getRaceMask()))
        return false;                                  // the other faction's version
    if (proto->RequiredSpell && !who->HasSpell(proto->RequiredSpell))
        return false;                                  // lacks the talent it builds on
    for (uint32 spell = uint32(proto->Spells[1].SpellId); spell; spell = sSpellMgr->GetNextSpellInChain(spell))
        if (who->HasSpell(spell))
            return false;                              // knows this rank or a higher one
    return true;
}

// The clan's average item level (owner and all the owner's buddies, as
// last measured); false if the clan is not remembered.
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
// }}}

// {{{ BuddyLootRollVote
RollVote BuddyLootRollVote(Player* bot, ItemTemplate const* proto, int32 /*randomProperty*/, RollVote judged, RollVote configured)
{
    if (!BuddiesEnabled())
        return configured;                             // module off: the bot module's vote
    BuddyLootFacts f;
    if (!FactsFor(bot, f))
        return configured;                             // not a buddy: the bot module's vote

    // Class books: the owner first, then the buddy itself, then the
    // auction house (unbound, so worth greeding).
    if (IsClassBook(proto))
    {
        Player* owner = ObjectAccessor::FindPlayerByLowGUID(f.owner);
        Group*  group = bot->GetGroup();
        if (owner && group && group->IsMember(owner->GetGUID()) && NeedsBook(owner, proto))
            return PASS;                               // the owner needs it and can roll for it
        if (NeedsBook(bot, proto))
            return NEED;                               // the buddy would learn from it
        return GREED;                                  // for the owner later, or the auction house
    }

    switch (judged)
    {
        case NEED:
        {
            if (RollUniqueCheck(proto, bot))
                return PASS;                           // a unique item it already holds (the bot module's own check)
            if (f.profile != PLAN_THIRDS_EACH)
                return NEED;                           // an upgrade for its plan: need
            float clan = 0.0f;
            if (!ClanItemLevel(f.owner, clan))
            {
                LOG_ERROR("module", "mod-buddies: buddy {} rolls on {} but its clan (owner {}) is not remembered yet; greeds",
                    bot->GetName(), proto->ItemId, f.owner);
                return GREED;
            }
            // a third in each tree: greed upgrades, unless behind the clan
            return bot->GetAverageItemLevel() < clan ? NEED : GREED;
        }
        case GREED:
        case DISENCHANT:
            return judged;                             // something to sell, use or break down: as judged
        default:
            return PASS;                               // nothing for it
    }
}
// }}}

// {{{ buddies_loot_world
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
// }}}

// {{{ AddSC_buddies_loot
void AddSC_buddies_loot()
{
    new buddies_loot_world();
}
// }}}
