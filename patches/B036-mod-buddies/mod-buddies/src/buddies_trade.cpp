
#include "buddies.h"
#include "buddies_town.h"
#include "CompanionAccounts.h"
#include "DatabaseEnv.h"
#include "Item.h"
#include "Log.h"
#include "Opcodes.h"
#include "Player.h"
#include "Playerbots.h"
#include "TradeData.h"
#include "WorldPacket.h"
#include "WorldSession.h"

bool BuddyBeginTrade(Player* bot, Player* trader)
{
    if (!bot->GetSession() || !CompanionAccounts::Is(bot->GetSession()->GetAccountId()))
        return false;
    WorldPacket begin;
    bot->GetSession()->HandleBeginTradeOpcode(begin);

    QueryResult row = CharacterDatabase.Query("SELECT owner FROM buddy_roster WHERE buddy = {}", bot->GetGUID().GetCounter());
    if (!row || (*row)[0].Get<uint32>() != trader->GetGUID().GetCounter())
        return true;
    PlayerbotAI* ai = GET_PLAYERBOT_AI(bot);
    if (!ai)
        return true;

    uint8 place = 0;
    for (Item* item : BuddyEarmarkedItems(ai, bot))
    {
        if (place >= TRADE_SLOT_TRADED_COUNT)
            break;
        WorldPacket put(CMSG_SET_TRADE_ITEM, 3);
        put << uint8(place) << uint8(item->GetBagSlot()) << uint8(item->GetSlot());
        bot->GetSession()->HandleSetTradeItemOpcode(put);
        if (bot->GetTradeData() && bot->GetTradeData()->GetItem(TradeSlots(place)) == item)
            ++place;
    }
    if (place)
        LOG_DEBUG("module", "mod-buddies: {} put {} earmarked items into its owner's trade (623)", bot->GetName(), place);
    return true;
}
