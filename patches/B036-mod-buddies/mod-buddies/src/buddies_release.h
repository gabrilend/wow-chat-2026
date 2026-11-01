/*
 * buddies_release.h - when a dead buddy releases its spirit (issue 632).
 * Source patch B066 declares the same function in the bot module's
 * auto-release check and asks it there; a mismatch between the two
 * declarations is a link error, not a silent difference.
 */

#ifndef MOD_BUDDIES_RELEASE_H
#define MOD_BUDDIES_RELEASE_H

class Player;

// {{{ BuddyReleaseRule
// For a dead bot: 1 release now, 0 wait, -1 not a buddy (the bot module's
// stock rules decide). A buddy waits its first 1 to 10 seconds, then for
// as long as someone of its side who knows a resurrection spell is within
// 70 yards (whispering them once after 10 to 20 seconds), then releases.
// Called from the map threads (bot updates).
int BuddyReleaseRule(Player* bot);
// }}}

#endif
