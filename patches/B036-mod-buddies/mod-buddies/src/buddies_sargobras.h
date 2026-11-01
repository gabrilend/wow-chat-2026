/*
 * buddies_sargobras.h - the character named Sargobras, on his own account
 * (issues 617b2, 630): the one a whisper to Sargobras reaches.
 */

#ifndef MOD_BUDDIES_SARGOBRAS_H
#define MOD_BUDDIES_SARGOBRAS_H

#include "Define.h"

// {{{ BuddyIsSargobrasAccount
// Whether `accountId` is Sargobras's own account (SARGOBRAS). He is no
// owner, no buddy and no stand-in: the buddy module leaves him alone
// (BuddyIsNotAPlayer says true for him), and a whisper to him gets no
// buddy's placeholder answer. False until the account is known (a moment
// after the server starts).
bool BuddyIsSargobrasAccount(uint32 accountId);
// }}}

#endif
