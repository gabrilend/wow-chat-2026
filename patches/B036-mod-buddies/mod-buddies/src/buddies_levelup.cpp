
#include "buddies.h"
#include "buddies_gems.h"
#include "buddies_kit.h"
#include "buddies_loot.h"
#include "buddies_roles.h"
#include "buddies_spells.h"
#include "AiFactory.h"
#include "Chat.h"
#include "CommandScript.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "Formulas.h"
#include "Item.h"
#include "Log.h"
#include "Mail.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "World.h"
#include <cmath>
#include <map>

using namespace Acore::ChatCommands;

static constexpr uint16 WEAPON_SKILL_PER_LEVEL = 5;

static std::map<uint32, float> SkillShares(Player* p)
{
    std::map<uint32, float> share;
    for (SkillLineEntry const* e : sSkillLineStore)
    {
        if (!e || !p->HasSkill(e->id))
            continue;
        bool weaponish = e->categoryId == SKILL_CATEGORY_WEAPON || e->id == SKILL_DEFENSE;
        bool trade     = e->categoryId == SKILL_CATEGORY_PROFESSION || e->categoryId == SKILL_CATEGORY_SECONDARY;
        if (!weaponish && !trade)
            continue;
        uint16 max = p->GetPureMaxSkillValue(e->id);
        if (max == 0)
            continue;
        share[e->id] = float(p->GetPureSkillValue(e->id)) / float(max);
    }
    return share;
}

static constexpr uint8 EVEN_SHAPE = 7;
static uint8 ShapeOf(Player* p, uint8& role)
{
    if (QueryResult r = CharacterDatabase.Query("SELECT profile, role FROM buddy_roster WHERE buddy = {}", p->GetGUID().GetCounter()))
    {
        role = (*r)[1].Get<uint8>();
        return (*r)[0].Get<uint8>();
    }
    BuddyRoles roles = BuddyPlayerRoles(p);
    role = (roles & BuddyRoleBit(BuddyRole::Tank)) ? uint8(BuddyRole::Tank)
         : (roles & BuddyRoleBit(BuddyRole::Healer)) ? uint8(BuddyRole::Healer) : uint8(BuddyRole::Damage);
    std::map<uint8, uint32> tabs = AiFactory::GetPlayerSpecTabs(p);
    float total = float(tabs[0] + tabs[1] + tabs[2]);
    if (total <= 0.0f)
        return EVEN_SHAPE;
    uint8 best = EVEN_SHAPE;
    float bestD = 1e30f;
    for (uint8 shape = 1; shape <= 10; ++shape)
    {
        uint8 thirds[3];
        CollectorType types[3];
        if (!BuddyPlanShape(p->getClass(), shape, role, thirds, types))
            continue;
        float d = 0.0f;
        for (uint8 t = 0; t < 3; ++t)
            d += std::pow(3.0f * float(tabs[t]) / total - float(thirds[t]), 2.0f);
        if (d < bestD)
        {
            bestD = d;
            best  = shape;
        }
    }
    return best;
}

static uint32 ClearWorn(Player* p)
{
    std::vector<Item*> keep;
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        if (Item* item = p->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
        {
            if (item->GetTemplate()->Quality <= ITEM_QUALITY_NORMAL)
                p->DestroyItem(INVENTORY_SLOT_BAG_0, slot, true);
            else
                keep.push_back(item);
        }
    if (keep.empty())
        return 0;
    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    size_t next = 0;
    while (next < keep.size())
    {
        MailDraft draft("Kept for you", "What you wore before. It will fit again.");
        for (uint32 n = 0; n < MAX_MAIL_ITEMS && next < keep.size(); ++n, ++next)
        {
            Item* item = keep[next];
            p->MoveItemFromInventory(item->GetBagSlot(), item->GetSlot(), true);
            item->DeleteFromInventoryDB(trans);
            if (item->GetState() == ITEM_UNCHANGED)
                item->FSetState(ITEM_CHANGED);
            item->SaveToDB(trans);
            draft.AddItem(item);
        }
        draft.SendMailTo(trans, MailReceiver(p), MailSender(p), MAIL_CHECK_MASK_HAS_BODY);
    }
    p->SaveInventoryAndGoldToDB(trans);
    CharacterDatabase.CommitTransaction(trans);
    return uint32(keep.size());
}

static std::string LevelOne(Player* p, uint8 level, uint32 xp)
{
    bool buddy = BuddyIsCompanionAccount(p->GetSession()->GetAccountId());
    uint8 was = p->GetLevel();
    std::map<uint32, float> shares = SkillShares(p);
    uint32 mailed = ClearWorn(p);

    if (level != was)
    {
        p->GiveLevel(level);
        p->InitTalentForLevel();
    }
    p->SetUInt32Value(PLAYER_XP, xp);

    if (buddy)
    {
        BuddyForgetLessons(p);
        BuddyLearnEverything(p);
    }

    uint16 weaponMax = uint16(level) * WEAPON_SKILL_PER_LEVEL;
    for (auto const& [skill, share] : shares)
    {
        SkillLineEntry const* e = sSkillLineStore.LookupEntry(skill);
        if (!e || (e->categoryId != SKILL_CATEGORY_WEAPON && skill != SKILL_DEFENSE))
            continue;
        uint16 value = std::max<uint16>(1, uint16(std::lround(share * weaponMax)));
        p->SetSkill(uint16(skill), p->GetSkillStep(uint16(skill)), std::min(value, weaponMax), weaponMax);
    }
    uint32 trades = BuddyProfessionsByRatio(p, shares);

    uint8 role = 0;
    uint8 shape = ShapeOf(p, role);
    std::string problems = BuddyRegear(p, shape);
    problems += BuddyGemKit(p, shape, role);
    p->SaveToDB(false, false);

    std::string line = p->GetName() + ": level " + std::to_string(was) + " -> " + std::to_string(level)
        + ", " + std::to_string(shares.size() - trades) + " weapon skills and " + std::to_string(trades)
        + " professions kept at their share, " + std::to_string(mailed) + " worn items mailed, white gear of shape "
        + std::to_string(shape);
    if (!problems.empty())
        line += "; could not: " + problems;
    return line;
}

static uint64 TotalXp(uint8 level, uint32 xp)
{
    uint64 total = xp;
    for (uint8 l = 1; l < level; ++l)
        total += sObjectMgr->GetXPForLevel(l);
    return total;
}
static void FromTotal(uint64 total, uint8 cap, uint8& level, uint32& xp)
{
    level = 1;
    while (level < cap && total >= sObjectMgr->GetXPForLevel(level))
    {
        total -= sObjectMgr->GetXPForLevel(level);
        ++level;
    }
    xp = level < cap ? uint32(std::min<uint64>(total, sObjectMgr->GetXPForLevel(level) - 1)) : 0;
}
static double KillXp(uint8 level)
{
    ContentLevels content = level <= 60 ? CONTENT_1_60 : (level <= 70 ? CONTENT_61_70 : CONTENT_71_80);
    return std::max<double>(1.0, Acore::XP::BaseGain(level, level, content));
}

class buddies_levelup_command : public CommandScript
{
public:
    buddies_levelup_command() : CommandScript("buddies_levelup_command") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "levelto", HandleLevelTo, SEC_GAMEMASTER, Console::Yes },
        };
        return commandTable;
    }

    static bool HandleLevelTo(ChatHandler* handler, std::string name, uint8 level)
    {
        if (!normalizePlayerName(name))
        {
            handler->PSendSysMessage("\"{}\" is not a character name.", name);
            return false;
        }
        uint8 cap = uint8(sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL));
        if (level < 1 || level > cap)
        {
            handler->PSendSysMessage("Level {} is outside 1 to {} (this realm's highest).", uint32(level), uint32(cap));
            return false;
        }
        Player* owner = ObjectAccessor::FindPlayerByName(name);
        if (!owner || !owner->IsInWorld())
        {
            handler->PSendSysMessage("{} is not in the world; nothing was changed.", name);
            return false;
        }

        uint8  ownerWas   = owner->GetLevel();
        uint64 ownerTotal = TotalXp(ownerWas, owner->GetUInt32Value(PLAYER_XP));
        double killBefore = KillXp(ownerWas);
        double killAfter  = KillXp(level);
        uint64 ownerNew   = TotalXp(level, 0);

        handler->PSendSysMessage("{}", LevelOne(owner, level, 0));

        QueryResult rows = CharacterDatabase.Query("SELECT r.buddy, c.name FROM buddy_roster r JOIN characters c ON c.guid = r.buddy "
            "WHERE r.owner = {} AND r.buddy <> 0 ORDER BY r.slot", owner->GetGUID().GetCounter());
        if (rows)
            do
            {
                uint32 guid = (*rows)[0].Get<uint32>();
                std::string bname = (*rows)[1].Get<std::string>();
                Player* b = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid));
                if (!b || !b->IsInWorld())
                {
                    handler->PSendSysMessage("{}: not in the world, left as it is.", bname);
                    continue;
                }
                double kills = (double(TotalXp(b->GetLevel(), b->GetUInt32Value(PLAYER_XP))) - double(ownerTotal)) / killBefore;
                double total = std::max(0.0, double(ownerNew) + kills * killAfter);
                uint8 bl;
                uint32 bxp;
                FromTotal(uint64(total), cap, bl, bxp);
                handler->PSendSysMessage("{} ({:+.0f} kills from its owner)", LevelOne(b, bl, bxp), kills);
            } while (rows->NextRow());

        LOG_INFO("module", "mod-buddies: {} set {} to level {} (was {}) with .levelto", handler->GetNameLink(), name, uint32(level), uint32(ownerWas));
        return true;
    }
};

void AddSC_buddies_levelup()
{
    new buddies_levelup_command();
}
