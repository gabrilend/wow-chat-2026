/*
 * buddies_npcs.h - buddies notice the people around them and use them
 * (issue 617p).
 *
 * For a general audience: wherever a buddy roams, every few seconds it
 * looks at the friendly people within 100 yards of it (the owner,
 * 2026-10-03: "when we apply the buddy-bot system to wow-chat [...] we
 * will have dynamically spawned NPCs without any of the default ones"),
 * reading what each offers from the creature itself, so a person spawned
 * in game counts as much as one in the world's tables. It visits each
 * person once (the owner, 2026-10-03: "they should visit each NPC at least
 * once, and only test to see what they do the first time they arrive. If
 * it's a vendor, they'll sell the stuff they don't need. If it's a
 * trainer, they'll train up if they can. If it's just an NPC, they'll just
 * talk to them. We should cycle out the remembered NPCs every 30 minutes
 * or so."), and remembers whom it has visited for 15 to 30 minutes (two
 * buffers, swapped server-wide every 15 minutes). A need
 * comes first, visited or not: lessons it can afford, selling when its
 * bags are full, repairs when its gear is worn. Each person has three
 * standing spots in front of them; a buddy claims one, so two buddies
 * never stand in the same place.
 */

#ifndef MOD_BUDDIES_NPCS_H
#define MOD_BUDDIES_NPCS_H

#include "Define.h"
#include "ObjectGuid.h"
#include "roam/buddy_roam_core.h"

class Creature;
class Player;
class PlayerbotAI;

// Why the buddy goes to a person: a need (lessons, selling, repairs), or
// a first visit. What it does there is decided on arrival
// (BuddyNpcArrive), whatever it went for.
enum class BuddyNpcUse : uint8 { None, Train, Sell, Repair, Visit };

struct BuddyNpcPick
{
    ObjectGuid       npc;
    BuddyNpcUse      use = BuddyNpcUse::None;
    BuddyRoam::Point spot;                      // the claimed standing spot, on the mesh
};

// {{{ BuddyNpcNotice
// The person within 100 yards the buddy should go to now, why, and a
// standing spot claimed for it; false when there is nobody. A need wins
// (lessons, then selling, then repairs; the nearest person meeting it),
// whether visited lately or not; otherwise the nearest person it hasn't
// visited lately (in either of its two visit buffers). The person is
// remembered as visited when picked, so one it can't reach isn't tried
// again soon either.
bool BuddyNpcNotice(Player* bot, BuddyNpcPick& out);
// }}}

// {{{ BuddyNpcRelease
// Gives up the buddy's standing spot at that person (done, or given up).
void BuddyNpcRelease(Player* bot, ObjectGuid npc);
// }}}

// {{{ BuddyNpcArrive
// At the person: everything it offers that the buddy can use now:
// lessons it can afford, selling what it doesn't need (a vendor), repairs
// of anything damaged (a repairer). `talk` is set when none of these
// applied: the caller plays a chat over a few seconds. Returns a few
// words for the trace.
std::string BuddyNpcArrive(PlayerbotAI* ai, Player* bot, Creature* npc, bool& talk);
// }}}

char const* BuddyNpcUseName(BuddyNpcUse use);

#endif
