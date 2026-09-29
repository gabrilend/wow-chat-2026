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
#include <string>

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

// Log the owner's made buddies in soon, if the owner is online
// (buddies_login.cpp, 617c1): at the owner's login, and when creation
// makes a buddy while the owner is online.
void BuddyQueueLogin(uint32 ownerGuid);

#endif
