/*
 * buddies.h - what the buddy module's files share (issue 617a).
 *
 * For a general audience: the module is split by job (the roster check,
 * the companion account, and later creation and the kit). This header is
 * the few facts they all need: whether buddies are switched on, and how a
 * companion account is named and recognised.
 */

#ifndef MOD_BUDDIES_H
#define MOD_BUDDIES_H

#include "Define.h"
#include "StringFormat.h"
#include <string>
#include <string_view>

// Whether the roster tables were found at startup (buddies_roster.cpp).
// Every buddy hook does nothing while this is false.
bool BuddiesEnabled();

// A companion account's name: "BUDDY" and the owner character's guid
// (5 + at most 10 digits, inside the server's 17-character limit). The name
// is the lasting link between an owner and its account, since the account's
// id is only known once the login database has written the new row.
std::string BuddyCompanionAccountName(uint32 ownerGuid);

// The companion account's id, looked up by name; 0 when it doesn't exist
// (yet). Also stores the id into buddy_clan once found.
uint32 BuddyCompanionAccountId(uint32 ownerGuid);

// Whether this account holds some owner's buddies. A companion account's
// characters are buddies: no clan, no account, no owed slots of their own.
bool BuddyIsCompanionAccount(uint32 accountId);

class Player;

// A buddy invited by its owner's side leaves whatever it is in (a
// battleground match, 617i, or another party: a far party, its owner's
// party, 617c4's override) and joins the inviter's group as one invited by
// hand; done by the party pass on the world's thread (buddies_party.cpp).
// Safe to call from any thread.
void BuddyPullIntoGroup(uint32 buddyGuid, uint32 inviterGuid);

// An invite of anyone into the inviter's full party, held: on the world's
// thread one buddy seated by distance steps out, at random, and the invite
// is then handled by the server as it arrived (buddies_party.cpp, 617c4).
// Safe to call from any thread.
class WorldPacket;
void BuddyHoldInviteForRoom(uint32 inviterGuid, WorldPacket const& packet);

// Log the owner's made buddies in soon, if the owner is online
// (buddies_login.cpp, 617c1): at the owner's login, and when creation
// makes a buddy while the owner is online.
void BuddyQueueLogin(uint32 ownerGuid);

// Makes and saves one character on an account, buddy or stand-in
// (buddies_create.cpp, 617a3, 617t1): name, looks, level, professions,
// every spell up to its level, the kit's gear by its talent shape (bags
// like `bagsLike`'s, 0 for none), the PvP necklace, rings and trinkets when
// `pvpJewellery` (stand-ins), sockets. Its guid and name, or 0 and why.
uint32 BuddyMakeCharacter(uint32 account, uint8 race, uint8 cls, uint8 level, uint8 shape, uint8 role,
    uint32 bagsLike, bool pvpJewellery, char const* kind, std::string const& forWhom, std::string& name, std::string& why);

// Whether this account holds stand-ins: characters that belong to nobody
// (buddies_stand_ins.cpp, 617t1). Cheap: an in-memory list.
bool BuddyIsStandInAccount(uint32 accountId);

// Neither a player's own account nor any player's: a companion account
// (buddies) or a stand-in account. The player-only steps (a hidden account
// of its own, owed slots, draws) skip these.
bool BuddyIsNotAPlayer(uint32 accountId);

// One stand-in of a side (0 Alliance, 1 Horde) and role (0 damage, 1 tank,
// 2 healer) at a level, race and class 0 for any, brought to a place
// (buddies_stand_ins.cpp, 617t1): a kept one if one fits, else a new one.
// Its guid (0 when it can't), and in `said` what was done or why not.
uint32 BuddyBringStandIn(uint8 side, uint8 role, uint8 level, uint8 race, uint8 cls,
    uint32 map, float x, float y, float z, float o, std::string& said);

// One wisp, the game masters' marker (buddies_town_circles.cpp): on the
// ground near x, y, z, friendly, untouchable, gone after `ms`. False when
// the server would not place it.
bool BuddyPlaceWisp(Player* gm, float x, float y, float z, float o, uint32 ms);

// The level a buddy slot is owed from (buddies_clan.cpp, 617a2): slot 1 at
// creation (level 1), then every tenth level. Also the level below which
// an owner's buddy in that slot is stored (617a6).
uint8 BuddySlotLevel(uint8 slot);

// The owner's buddies matched to its level now (buddies_stage.cpp, 617a6):
// those whose slot is above it wait (recorded, kept out of the world) until
// the owner reaches their own level; those of the slots it keeps, if above
// its level, are recorded and made again at its level. Run at the owner's
// login and at every level change.
void BuddyStageCheck(Player* owner);

// The selling trip may set off (617y): true once, after a player in the
// owner's group said "go sell" while this buddy's bags were full
// (buddies_orders.cpp); the trip takes the order as it starts.
bool BuddyTakeSellOrder(uint32 buddy);

// The movement trace (buddies_trace.cpp, 617e2): whether a game master has
// switched it on for this buddy with ".buddy trace <name>", and one line
// of it, written to the bot module's log so it sits among the bot's own
// action lines. BuddyTrace formats only when the buddy is traced, so a
// call costs one set lookup otherwise.
class Player;
bool BuddyTraced(Player const* bot);
void BuddyTraceLine(Player const* bot, std::string const& text);

template<typename... Args>
inline void BuddyTrace(Player const* bot, std::string_view fmt, Args&&... args)
{
    if (BuddyTraced(bot))
        BuddyTraceLine(bot, Acore::StringFormat(fmt, std::forward<Args>(args)...));
}

#endif
