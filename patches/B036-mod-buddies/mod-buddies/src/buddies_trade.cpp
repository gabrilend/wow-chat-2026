/*
 * buddies_trade.cpp - what a buddy puts into a trade it accepts (issue 623,
 * piece 3).
 *
 * For a general audience: the owner, 2026-10-30: "they should just accept
 * trades when asked to trade. If a player asks to trade with a buddy-bot,
 * they should give any items that are "earmarked" for the player to them.
 * So upgrades and stuff." Who may trade with a buddy at all is the bot
 * module's rule as source patch B058 widened it (its owner, its group, its
 * clan). When the trade window opens, the bot module asks this file first
 * (source patch B068, in its "begin trade" step):
 *   not a buddy                 - false: the bot module goes on as stock
 *   a buddy, the trader its owner
 *                               - the window opened, and its earmarked
 *                                 items (what the mailbox errand would
 *                                 mail: BuddyEarmarkedItems) put in, up to
 *                                 the six tradable places, as a player's
 *                                 client puts them (the server's own
 *                                 set-trade-item step, with its checks);
 *                                 true
 *   a buddy, anyone else allowed (a clan mate)
 *                               - the window opened, nothing put in (what
 *                                 is earmarked is the owner's); true
 * True also skips the bot module's whispered list of the bot's whole
 * inventory, which buddies never send (they don't chat, 617e4).
 * Not built: food and water asked for ("If the player asks for food or
 * water we can give them to them as well, but the buddy-bot will always
 * split stacks of them to ensure they have some too").
 */

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

// {{{ BuddyBeginTrade
// Declared the same way in the bot module's TradeStatusAction.cpp by
// source patch B068.
bool BuddyBeginTrade(Player* bot, Player* trader)
{
    if (!bot->GetSession() || !CompanionAccounts::Is(bot->GetSession()->GetAccountId()))
        return false;                                  // not a buddy: stock
    WorldPacket begin;
    bot->GetSession()->HandleBeginTradeOpcode(begin);

    QueryResult row = CharacterDatabase.Query("SELECT owner FROM buddy_roster WHERE buddy = {}", bot->GetGUID().GetCounter());
    if (!row || (*row)[0].Get<uint32>() != trader->GetGUID().GetCounter())
        return true;                                   // a clan mate, not its owner: nothing put in
    PlayerbotAI* ai = GET_PLAYERBOT_AI(bot);
    if (!ai)
        return true;

    uint8 place = 0;
    for (Item* item : BuddyEarmarkedItems(ai, bot))
    {
        if (place >= TRADE_SLOT_TRADED_COUNT)
            break;                                     // six at a time; the rest at the next trade or by mail
        WorldPacket put(CMSG_SET_TRADE_ITEM, 3);
        put << uint8(place) << uint8(item->GetBagSlot()) << uint8(item->GetSlot());
        bot->GetSession()->HandleSetTradeItemOpcode(put);
        if (bot->GetTradeData() && bot->GetTradeData()->GetItem(TradeSlots(place)) == item)
            ++place;                                   // refused (bound, a quest item): the place stays free
    }
    if (place)
        LOG_DEBUG("module", "mod-buddies: {} put {} earmarked items into its owner's trade (623)", bot->GetName(), place);
    return true;
}
// }}}
