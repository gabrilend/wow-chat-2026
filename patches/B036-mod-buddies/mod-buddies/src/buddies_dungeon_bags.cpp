/*
 * buddies_dungeon_bags.cpp - full bags inside a dungeon (issue 617h1).
 *
 * For a general audience: out in the world a buddy with full bags walks
 * to a vendor (the selling trip). Inside a dungeon it can't, so when it
 * opens a body or a chest and its bags can't hold something it may take,
 * it makes room the way its owner asked (2026-10-03): first it hands its
 * most valuable "would sell it anyway" item to another of its owner's
 * buddies in the same dungeon who has room; failing that, it destroys its
 * least valuable such item, unless the thing it is trying to loot is
 * worth even less, in which case it leaves the loot where it lies.
 *
 * "Would sell it anyway" is what the town visit would sell or auction
 * (buddies_town.cpp: greys, and what the bot module judges "vendor" or
 * "auction"); "worth" is a vendor's price for the whole stack.
 *
 * The moment used is the server's own, just before a loot window is sent
 * (a stock script hook), so the bot module's looting that follows finds
 * the room made. It runs on the dungeon's map thread, where the buddy and
 * its clan-mates in that dungeon all live.
 */

#include "buddies.h"
#include "buddies_town.h"
#include "DatabaseEnv.h"
#include "Item.h"
#include "Log.h"
#include "LootMgr.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Playerbots.h"
#include "PlayerbotAI.h"
#include "ScriptMgr.h"
#include "WorldSession.h"
#include <algorithm>
#include <vector>

// {{{ worth
// A vendor's price for the whole stack, in copper.
static uint64 WorthOf(uint32 entry, uint32 count)
{
    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(entry);
    return proto ? uint64(proto->SellPrice) * count : 0;
}
// }}}

// {{{ clan-mates here
// The owner's other buddies, alive, on this very dungeon map.
static std::vector<Player*> MatesHere(Player* bot)
{
    std::vector<Player*> mates;
    QueryResult owner = CharacterDatabase.Query("SELECT owner FROM buddy_roster WHERE buddy = {}", bot->GetGUID().GetCounter());
    if (!owner)
        return mates;
    QueryResult rows = CharacterDatabase.Query("SELECT buddy FROM buddy_roster WHERE owner = {} AND buddy <> 0 AND buddy <> {}",
        (*owner)[0].Get<uint32>(), bot->GetGUID().GetCounter());
    if (rows)
        do
            if (Player* m = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>((*rows)[0].Get<uint32>())))
                if (m->IsInWorld() && m->IsAlive() && m->GetMap() == bot->GetMap())
                    mates.push_back(m);
        while (rows->NextRow());
    return mates;
}
// }}}

// {{{ MakeRoom
// Room for `count` of `entry` in the buddy's bags, by the owner's rule.
// Returns true when it now fits (the loot will be taken), false when the
// loot is to be left.
static bool MakeRoom(PlayerbotAI* ai, Player* bot, uint32 entry, uint32 count, std::vector<Player*> const& mates)
{
    ItemPosCountVec dest;
    if (bot->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, entry, count) == EQUIP_ERR_OK)
        return true;                                   // it fits already
    std::vector<Item*> spare = BuddyDisposableItems(ai, bot);
    if (spare.empty())
    {
        BuddyTrace(bot, "bags: full in a dungeon, nothing I'd part with; item {} left lying", entry);
        return false;
    }
    std::sort(spare.begin(), spare.end(), [](Item* a, Item* b) {
        return WorthOf(a->GetEntry(), a->GetCount()) > WorthOf(b->GetEntry(), b->GetCount());
    });

    // 1. the most valuable spare item to a clan-mate with room
    Item*  most      = spare.front();
    uint32 mostEntry = most->GetEntry(), mostCount = most->GetCount();
    for (Player* mate : mates)
    {
        ItemPosCountVec mateDest;
        if (mate->CanStoreNewItem(NULL_BAG, NULL_SLOT, mateDest, mostEntry, mostCount) != EQUIP_ERR_OK)
            continue;
        int32 random = most->GetItemRandomPropertyId();
        bot->DestroyItem(most->GetBagSlot(), most->GetSlot(), true);
        if (!mate->StoreNewItem(mateDest, mostEntry, true, random))
        {
            LOG_ERROR("module", "mod-buddies: buddy {} handed {} x{} to {}, whose bags then refused it; it is lost",
                bot->GetName(), mostEntry, mostCount, mate->GetName());
            return true;                               // the room is made all the same
        }
        BuddyTrace(bot, "bags: full in a dungeon; gave {} x{} to {}", mostEntry, mostCount, mate->GetName());
        return true;
    }

    // 2. the least valuable spare item destroyed, unless the loot is worth less
    Item*  least       = spare.back();
    uint64 leastWorth  = WorthOf(least->GetEntry(), least->GetCount());
    uint64 lootWorth   = WorthOf(entry, count);
    if (lootWorth < leastWorth)
    {
        BuddyTrace(bot, "bags: full in a dungeon; item {} (worth {}) is worth less than anything I'd drop; left lying", entry, lootWorth);
        return false;
    }
    BuddyTrace(bot, "bags: full in a dungeon, no clan-mate has room; destroyed {} x{} (worth {}) for item {} (worth {})",
        least->GetEntry(), least->GetCount(), leastWorth, entry, lootWorth);
    bot->DestroyItem(least->GetBagSlot(), least->GetSlot(), true);
    return bot->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, entry, count) == EQUIP_ERR_OK;
}
// }}}

class buddies_dungeon_bags_player : public PlayerScript
{
public:
    buddies_dungeon_bags_player() : PlayerScript("buddies_dungeon_bags_player", { PLAYERHOOK_ON_BEFORE_SEND_LOOT }) { }

    void OnPlayerBeforeSendLoot(Player* player, ObjectGuid /*lootGuid*/, Loot* loot) override
    {
        if (!BuddiesEnabled() || !loot || !player->GetMap()->IsDungeon())
            return;                                    // out in the world: the selling trip's job
        PlayerbotAI* ai = GET_PLAYERBOT_AI(player);
        if (!ai || !BuddyIsCompanionAccount(player->GetSession()->GetAccountId()))
            return;
        // Each item is judged on the bags as they are when its turn comes;
        // two items that each fit alone but not together get room for the
        // first only, and the second stays on the body for the next look.
        std::vector<Player*> mates;
        bool matesFound = false;
        for (LootItem const& li : loot->items)
        {
            // only what this buddy may take now: not taken, not under a
            // roll, not won by someone else, allowed for it
            if (li.is_looted || li.is_blocked || (li.rollWinnerGUID && li.rollWinnerGUID != player->GetGUID()) ||
                !li.AllowedForPlayer(player, loot->sourceWorldObjectGUID))
                continue;
            if (!matesFound)
            {
                mates = MatesHere(player);
                matesFound = true;
            }
            MakeRoom(ai, player, li.itemid, li.count, mates);
        }
    }
};

// {{{ AddSC_buddies_dungeon_bags
void AddSC_buddies_dungeon_bags()
{
    new buddies_dungeon_bags_player();
}
// }}}
