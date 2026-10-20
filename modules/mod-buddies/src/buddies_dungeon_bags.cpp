
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

static uint64 WorthOf(uint32 entry, uint32 count)
{
    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(entry);
    return proto ? uint64(proto->SellPrice) * count : 0;
}

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

static bool MakeRoom(PlayerbotAI* ai, Player* bot, uint32 entry, uint32 count, std::vector<Player*> const& mates)
{
    ItemPosCountVec dest;
    if (bot->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, entry, count) == EQUIP_ERR_OK)
        return true;
    std::vector<Item*> spare = BuddyDisposableItems(ai, bot);
    if (spare.empty())
    {
        BuddyTrace(bot, "bags: full in a dungeon, nothing I'd part with; item {} left lying", entry);
        return false;
    }
    std::sort(spare.begin(), spare.end(), [](Item* a, Item* b) {
        return WorthOf(a->GetEntry(), a->GetCount()) > WorthOf(b->GetEntry(), b->GetCount());
    });

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
            return true;
        }
        BuddyTrace(bot, "bags: full in a dungeon; gave {} x{} to {}", mostEntry, mostCount, mate->GetName());
        return true;
    }

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

class buddies_dungeon_bags_player : public PlayerScript
{
public:
    buddies_dungeon_bags_player() : PlayerScript("buddies_dungeon_bags_player", { PLAYERHOOK_ON_BEFORE_SEND_LOOT }) { }

    void OnPlayerBeforeSendLoot(Player* player, ObjectGuid , Loot* loot) override
    {
        if (!BuddiesEnabled() || !loot || !player->GetMap()->IsDungeon())
            return;
        PlayerbotAI* ai = GET_PLAYERBOT_AI(player);
        if (!ai || !BuddyIsCompanionAccount(player->GetSession()->GetAccountId()))
            return;
        std::vector<Player*> mates;
        bool matesFound = false;
        for (LootItem const& li : loot->items)
        {
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

void AddSC_buddies_dungeon_bags()
{
    new buddies_dungeon_bags_player();
}
