/*
 * buddies_stage.cpp - only the owner's current stage of buddies comes along
 * (issue 617a6).
 *
 * For a general audience: an owner is owed a buddy at level 1 and at every
 * tenth level after. If the owner's level goes down (by whatever means;
 * the owner, 2026-10-03: "we will add mechanics for that later"):
 *   - the buddies of slots above the owner's new level leave the world and
 *     wait; each comes back when the owner reaches its slot's level, made
 *     again at the owner's level like the others;
 *   - the buddies of slots the owner still has, if above the owner's
 *     level, are made again at the owner's level, as new buddies are made,
 *     their old gear and money mailed to them.
 * Either way a copy of the buddy as it was is kept first, for the later
 * level-scaling.
 *
 * The roster row's stage (04-buddy-roster.apply.sql):
 *   0 with its owner   ->  1 waiting      its slot is above the owner
 *   0 with its owner   ->  4 recording    its slot is kept, it is above
 *                                          the owner
 *   4 recording        ->  3 remake       recorded (the world pass)
 *   3 remake           ->  0              made again at its login
 *   1 waiting          ->  3 remake       the owner reached its slot's level
 * The login and the keeper bring in stages 0 and 3 only.
 */

#include "buddies.h"
#include "buddies_gems.h"
#include "buddies_kit.h"
#include "buddies_loot.h"
#include "buddies_spells.h"
#include "DatabaseEnv.h"
#include "Item.h"
#include "Mail.h"
#include "GameTime.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Playerbots.h"
#include "PlayerbotMgr.h"
#include "ScriptMgr.h"
#include "WorldSession.h"
#include <map>
#include <mutex>
#include <set>

// {{{ tuning
// The record is taken this long after the buddy's logout, so its logout
// save (queued on the characters database) is written before it is copied.
static constexpr uint32 RECORD_AFTER_MS = 5000;
static constexpr uint32 PASS_EVERY_MS   = 1000;
// }}}

enum BuddyStage : uint8 { STAGE_WITH_OWNER = 0, STAGE_STORED = 1, STAGE_REMAKE = 3, STAGE_RECORDING = 4 };

// A buddy being recorded: when, and whether it is then to be re-made at
// its next login (a lower slot) or to wait (a higher slot).
struct RecordDue { uint64 dueMs; bool remake; };
static std::mutex                    sRecordLock;
static std::map<uint32, RecordDue>   sRecordsDue;    // buddy guid -> its record

// {{{ Record
// The buddy as its saved rows are now, copied into the stage record in one
// transaction (an older record of it replaced).
static void Record(uint32 buddy)
{
    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    for (char const* table : { "buddy_stage_record", "buddy_stage_item", "buddy_stage_spell", "buddy_stage_talent" })
        trans->Append("DELETE FROM {} WHERE buddy = {}", table, buddy);
    trans->Append("INSERT INTO buddy_stage_record (buddy, level, xp, money, recorded) "
        "SELECT guid, level, xp, money, UNIX_TIMESTAMP() FROM characters WHERE guid = {}", buddy);
    trans->Append("INSERT INTO buddy_stage_item (buddy, item, bag, slot, entry, count, enchantments, `random`, durability) "
        "SELECT ci.guid, ci.item, ci.bag, ci.slot, ii.itemEntry, ii.count, ii.enchantments, ii.randomPropertyId, ii.durability "
        "FROM character_inventory ci JOIN item_instance ii ON ii.guid = ci.item WHERE ci.guid = {}", buddy);
    trans->Append("INSERT INTO buddy_stage_spell (buddy, spell) SELECT guid, spell FROM character_spell WHERE guid = {}", buddy);
    trans->Append("INSERT INTO buddy_stage_talent (buddy, spell, specMask) "
        "SELECT guid, spell, specMask FROM character_talent WHERE guid = {}", buddy);
    CharacterDatabase.CommitTransaction(trans);
    LOG_INFO("module", "mod-buddies: buddy {}'s level, items, spells and talents recorded (617a6)", buddy);
}
// }}}

// {{{ TakeOut
// The buddy leaves the world (if in it: its logout saves it) and is
// recorded once that save is in. `stage` is written at once, directly (the
// keeper reads it within seconds and must not ask the buddy back in).
static void TakeOut(Player* owner, uint32 buddy, uint8 stage, bool remake)
{
    CharacterDatabase.DirectExecute("UPDATE buddy_roster SET stage = {} WHERE buddy = {}", stage, buddy);
    ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(buddy);
    if (ObjectAccessor::FindConnectedPlayer(guid))
    {
        if (PlayerbotMgr* mgr = GET_PLAYERBOT_MGR(owner))
            mgr->LogoutPlayerBot(guid);
        else
            LOG_ERROR("module", "mod-buddies: owner {} has no bot manager; buddy {} should leave the world but stays "
                "until its owner logs out", owner->GetName(), buddy);
    }
    std::lock_guard<std::mutex> lock(sRecordLock);
    sRecordsDue[buddy] = { uint64(GameTime::GetGameTimeMS().count()) + RECORD_AFTER_MS, remake };
}
// }}}

// {{{ BuddyStageCheck
// The owner, 2026-10-03: "if the owner is 35 and the buddy bot is 35, then
// the owner gets dropped to level 20, then only their first 3 buddy-bots
// would stick around. The level 35 buddy-bot would hang out and wait until
// they got to level 35, and then they would start spawning again [...]
// only the higher slots wait. Everyone gets re-instantiated to the highest
// level tier that they could spawn as. So in your example the first three
// slots would get re-instantiated at level 20."
void BuddyStageCheck(Player* owner)
{
    if (!BuddiesEnabled() || BuddyIsNotAPlayer(owner->GetSession()->GetAccountId()))
        return;
    uint32 ownerGuid = owner->GetGUID().GetCounter();
    uint8  level     = owner->GetLevel();
    QueryResult rows = CharacterDatabase.Query("SELECT r.slot, r.buddy, r.stage, c.level FROM buddy_roster r "
        "JOIN characters c ON c.guid = r.buddy WHERE r.owner = {} AND r.buddy <> 0", ownerGuid);
    if (!rows)
        return;
    do
    {
        uint8  slot       = (*rows)[0].Get<uint8>();
        uint32 buddy      = (*rows)[1].Get<uint32>();
        uint8  stage      = (*rows)[2].Get<uint8>();
        uint8  buddyLevel = (*rows)[3].Get<uint8>();
        if (Player* online = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(buddy)))
            buddyLevel = online->GetLevel();           // in the world: its level now, not its last save's
        bool higherSlot = BuddySlotLevel(slot) > level;

        if (stage == STAGE_WITH_OWNER && higherSlot)
        {
            // a slot above the owner: it waits, as it is, recorded
            TakeOut(owner, buddy, STAGE_STORED, false);
            LOG_INFO("module", "mod-buddies: {} is level {}, below slot {} (level {}); its buddy {} (level {}) waits until "
                "{} is level {} again", owner->GetName(), level, slot, BuddySlotLevel(slot), buddy, buddyLevel, owner->GetName(), buddyLevel);
        }
        else if (stage == STAGE_WITH_OWNER && buddyLevel > level)
        {
            // a slot the owner still has, its buddy above the owner: recorded,
            // then made again at the owner's level at its next login (the
            // keeper logs it straight back in)
            TakeOut(owner, buddy, STAGE_RECORDING, true);
            LOG_INFO("module", "mod-buddies: {} is level {}; its buddy {} in slot {} (level {}) is recorded and made again "
                "at level {}", owner->GetName(), level, buddy, slot, buddyLevel, level);
        }
        else if (stage == STAGE_STORED && !higherSlot)
        {
            // the owner has reached a waiting buddy's slot: it is made again at
            // the owner's level, like every other ("treat them all the same,
            // and re-initialize the level 35 guy too when the player-partner
            // reaches level 30. At level 30."); it was recorded when it went
            // to wait. The keeper logs it in, and its login makes it again.
            CharacterDatabase.DirectExecute("UPDATE buddy_roster SET stage = {} WHERE buddy = {}", uint8(STAGE_REMAKE), buddy);
            LOG_INFO("module", "mod-buddies: {} reached level {}, slot {}'s; its waiting buddy {} (level {}) comes back, made again "
                "at level {}", owner->GetName(), level, slot, buddy, buddyLevel, level);
        }
        // otherwise: with its owner and fitting, still waiting, or being
        // recorded or made again (finished by the world pass and its login)
    } while (rows->NextRow());
}
// }}}

// {{{ MailOldGear
// What it wears and carries, bags included, and its money, mailed to
// itself (the owner, 2026-10-03: "Can we maybe mail them their old gear?
// It's okay if they forget abilities."), the way the server's mail sends
// items: out of the inventory, saved as the mail's. Several mails of at
// most 12 items; the bags' contents go before the bags (a bag must be
// empty to be mailed). Returns how many items were mailed.
static constexpr char const* KEPT_SUBJECT = "Kept for you";   // the mail errand takes from these only what it can use (buddies_town.cpp)
static constexpr uint32 KEPT_DAYS = 900;               // kept in the mail this long (the owner: "we should change the duration to be 900 days"; stock: 30)

static uint32 MailOldGear(Player* bot)
{
    std::vector<Item*> items;
    for (uint8 b = INVENTORY_SLOT_BAG_START; b < INVENTORY_SLOT_BAG_END; ++b)
        if (Bag* bag = bot->GetBagByPos(b))
            for (uint32 j = 0; j < bag->GetBagSize(); ++j)
                if (Item* item = bag->GetItemByPos(uint8(j)))
                    items.push_back(item);
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
        if (Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            items.push_back(item);                     // worn, the bags themselves, and the backpack

    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    uint32 money = bot->GetMoney();
    size_t next = 0;
    do
    {
        MailDraft draft(KEPT_SUBJECT, "What you had before. It will fit again.");
        for (uint32 n = 0; n < MAX_MAIL_ITEMS && next < items.size(); ++n, ++next)
        {
            Item* item = items[next];
            bot->MoveItemFromInventory(item->GetBagSlot(), item->GetSlot(), true);
            item->DeleteFromInventoryDB(trans);
            if (item->GetState() == ITEM_UNCHANGED)
                item->FSetState(ITEM_CHANGED);         // saved with its new keeper, the mail
            item->SaveToDB(trans);
            draft.AddItem(item);
        }
        if (money)
        {
            draft.AddMoney(money);                     // with the first mail
            money = 0;
        }
        draft.SendMailTo(trans, MailReceiver(bot), MailSender(bot), MAIL_CHECK_MASK_HAS_BODY, 0, KEPT_DAYS);
    } while (next < items.size());
    bot->SetMoney(0);
    bot->SaveInventoryAndGoldToDB(trans);
    CharacterDatabase.CommitTransaction(trans);
    return uint32(items.size());
}
// }}}

// {{{ Remake
// A buddy whose slot the owner kept, above the owner's level, just logged
// in: made again at the owner's level as a new buddy is made: what it had
// mailed to itself (MailOldGear), its lessons forgotten, its level set, its
// talents reset (the talent spender, buddy-talents.lua, spends them again
// on the reset; a hunter gets a new pet the same way, buddies_spells.cpp),
// then taught everything up to that level and given the starting kit and
// its gems (617j2), as buddy creation does (buddies_create.cpp). Bank,
// professions, reputation and quests are left as they were. An owner who
// has climbed back to the buddy's level meanwhile: nothing to do.
static void Remake(Player* bot, uint32 owner, uint8 profile, uint8 role)
{
    uint32 guid = bot->GetGUID().GetCounter();
    uint8 level = 0;
    if (QueryResult o = CharacterDatabase.Query("SELECT level FROM characters WHERE guid = {}", owner))
        level = (*o)[0].Get<uint8>();
    if (!level)
    {
        LOG_ERROR("module", "mod-buddies: buddy {}'s owner {} has no characters row; not made again, left waiting to be",
            bot->GetName(), owner);
        return;
    }
    if (bot->GetLevel() <= level)
    {
        CharacterDatabase.DirectExecute("UPDATE buddy_roster SET stage = {} WHERE buddy = {}", uint8(STAGE_WITH_OWNER), guid);
        LOG_INFO("module", "mod-buddies: buddy {} (level {}) was to be made again, but its owner is level {} now; kept as it is",
            bot->GetName(), bot->GetLevel(), level);
        return;
    }

    uint32 items = MailOldGear(bot);
    uint32 forgotten = BuddyForgetLessons(bot);

    uint8 was = bot->GetLevel();
    bot->GiveLevel(level);
    bot->SetUInt32Value(PLAYER_XP, 0);
    bot->InitTalentForLevel();
    bot->resetTalents(true);

    uint32 lessons = BuddyLearnEverything(bot);
    std::string problems;
    lessons += BuddyRaiseProfessions(bot, problems);   // its professions to its new level (617k)
    problems += BuddyGiveStartingKit(bot, owner, profile);   // its gear by talent shape (617r2)
    problems += BuddyGemKit(bot, profile, role);       // its sockets filled, as at its making (617j2)
    bot->SaveToDB(false, false);
    // with its owner again; written directly, so a second login can't remake it twice
    CharacterDatabase.DirectExecute("UPDATE buddy_roster SET stage = {} WHERE buddy = {}", uint8(STAGE_WITH_OWNER), guid);
    LOG_INFO("module", "mod-buddies: buddy {} made again: level {} -> {}, {} items and its money mailed to it, {} spells forgotten, "
        "{} learned, starting kit given{}{}", bot->GetName(), was, level, items, forgotten, lessons,
        problems.empty() ? "" : "; kit incomplete: ", problems);
}
// }}}

class buddies_stage_player : public PlayerScript
{
public:
    buddies_stage_player() : PlayerScript("buddies_stage_player", { PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LEVEL_CHANGED }) { }

    // An owner: its buddies matched to its level, before the keeper asks
    // them in (3 seconds later, buddies_login.cpp). A buddy due to be made
    // again: made again.
    void OnPlayerLogin(Player* player) override
    {
        if (!BuddiesEnabled())
            return;
        if (!BuddyIsCompanionAccount(player->GetSession()->GetAccountId()))
            return BuddyStageCheck(player);
        QueryResult row = CharacterDatabase.Query("SELECT owner, stage, profile, role FROM buddy_roster WHERE buddy = {}",
            player->GetGUID().GetCounter());
        if (row && (*row)[1].Get<uint8>() == STAGE_REMAKE)
            Remake(player, (*row)[0].Get<uint32>(), (*row)[2].Get<uint8>(), (*row)[3].Get<uint8>());
    }

    void OnPlayerLevelChanged(Player* player, uint8 oldLevel) override
    {
        BuddyStageCheck(player);
        LevelJumped(player, oldLevel);
    }

private:
    // A buddy whose level moved by more than one at once (a game master's
    // level command, a level tool, 185) is taught and dressed for the new
    // level by the same steps as being made again, its gear and gems
    // included. One level up in play is not a jump: those lessons are
    // bought at a trainer in town (617n). The owner, 2026-10-15: "anything
    // that changes a buddy-bots level or class should be teaching them the
    // relevant abilities already" and, of a chat command doing it, "this
    // shouldn't be doable via chat command".
    static void LevelJumped(Player* bot, uint8 oldLevel)
    {
        uint8 level = bot->GetLevel();
        if (!BuddiesEnabled() || !bot->IsInWorld() || (level <= oldLevel + 1 && level >= oldLevel))
            return;                                    // not in the world yet, or one level up in play
        if (!BuddyIsCompanionAccount(bot->GetSession()->GetAccountId()))
            return;
        QueryResult row = CharacterDatabase.Query("SELECT owner, stage, profile, role FROM buddy_roster WHERE buddy = {}",
            bot->GetGUID().GetCounter());
        if (!row || (*row)[1].Get<uint8>() != STAGE_WITH_OWNER)
            return;                                    // not a roster buddy, or being made again (Remake does it all)
        uint32 owner   = (*row)[0].Get<uint32>();
        uint8  profile = (*row)[2].Get<uint8>();
        uint8  role    = (*row)[3].Get<uint8>();
        uint32 forgotten = level < oldLevel ? BuddyForgetLessons(bot) : 0;   // going down: the higher lessons go
        uint32 lessons = BuddyLearnEverything(bot);
        std::string problems;
        if (level > oldLevel)
            lessons += BuddyRaiseProfessions(bot, problems);   // up: its professions practised to the new level (617k)
        problems += BuddyRegear(bot, profile);
        if (level >= BUDDY_PVP_JEWELLERY_FROM)
            problems += BuddyGivePvpJewellery(bot, profile, role);
        problems += BuddyGemKit(bot, profile, role);
        LOG_INFO("module", "mod-buddies: buddy {} (owner {}) jumped level {} -> {}: {} spells forgotten, {} learned, re-dressed{}{}",
            bot->GetName(), owner, oldLevel, level, forgotten, lessons, problems.empty() ? "" : "; ", problems);
    }
};

// The records, each taken once its buddy's logout save is in; a buddy to
// be made again is then let back in (stage 3: the keeper logs it in).
class buddies_stage_world : public WorldScript
{
public:
    buddies_stage_world() : WorldScript("buddies_stage_world", { WORLDHOOK_ON_UPDATE }) { }

    void OnUpdate(uint32 diff) override
    {
        _since += diff;
        if (_since < PASS_EVERY_MS)
            return;
        _since = 0;
        uint64 now = uint64(GameTime::GetGameTimeMS().count());
        std::lock_guard<std::mutex> lock(sRecordLock);
        for (auto it = sRecordsDue.begin(); it != sRecordsDue.end(); )
        {
            if (it->second.dueMs > now) { ++it; continue; }
            if (ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(it->first)))
            {
                it->second.dueMs = now + RECORD_AFTER_MS;  // still logging out: its save isn't in yet
                ++it;
                continue;
            }
            Record(it->first);
            if (it->second.remake)
                CharacterDatabase.Execute("UPDATE buddy_roster SET stage = {} WHERE buddy = {} AND stage = {}",
                    uint8(STAGE_REMAKE), it->first, uint8(STAGE_RECORDING));   // queued after the record: in order
            it = sRecordsDue.erase(it);
        }
    }

private:
    uint32 _since = 0;
};

// {{{ AddSC_buddies_stage
void AddSC_buddies_stage()
{
    new buddies_stage_player();
    new buddies_stage_world();
}
// }}}
