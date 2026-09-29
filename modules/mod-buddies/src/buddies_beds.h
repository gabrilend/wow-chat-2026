/*
 * buddies_beds.h - the beds buddies sleep on, placed by hand (issue 617e4).
 *
 * For a general audience: inn beds are part of the buildings, so the game
 * doesn't know where they are. A game master stands on each bed and types
 * ".buddy bed add <bed|cot|floor>"; the spot is kept in the world table buddy_bed (install
 * step E045) and in the project (scripts/export-buddy-beds). A buddy
 * sleeping in town lies on one of its town's beds, one buddy to a bed; a
 * town with no beds recorded has no sleeping.
 *
 * Each spot has a comfort tier, and a buddy takes the best free one (owner,
 * 2026-09-27: "I'd prefer the cot over the rug. But if 3 people wanna
 * sleep, then one's going on the ground"); spots can be linked into one
 * bed, which a clan keeps to itself while using it ("clanmembers can sleep
 * together but outsiders wouldn't pick that particular spot").
 */

#ifndef MOD_BUDDIES_BEDS_H
#define MOD_BUDDIES_BEDS_H

#include "Define.h"
#include <vector>

// {{{ BuddyBed
// One placed bed: where the sleeper lies (world yards), the way it faces
// (radians) and the named area the bed stands in.
// tier: 3 bed (a mattress), 2 cot, 1 floor (a rug, a bedroll, the ground).
// link: 0 alone; spots sharing a link number are one bed (a double bed).
struct BuddyBed
{
    uint32 id     = 0;
    uint32 map    = 0;
    float  x      = 0.0f;
    float  y      = 0.0f;
    float  z      = 0.0f;
    float  facing = 0.0f;
    uint32 area   = 0;
    uint8  tier   = 1;
    uint32 link   = 0;
};

// The comfort tiers, and their names in the commands.
enum BuddyBedTier : uint8
{
    BUDDY_BED_FLOOR = 1,
    BUDDY_BED_COT   = 2,
    BUDDY_BED_BED   = 3,
};
// }}}

// The beds in this named area of this map (read from the table once, at
// first use, and again after every add or remove).
std::vector<BuddyBed> BuddyBedsInArea(uint32 map, uint32 area);

// One buddy to a spot. Claim returns false when another buddy holds it, or
// when the spot is part of a linked bed another clan is using (clan: the
// buddy's owner's guid); a claim not released within `holdMs` lapses (a
// buddy logged out asleep).
bool BuddyClaimBed(uint32 bedId, uint32 buddyGuid, uint32 clanGuid, uint32 holdMs);
void BuddyReleaseBed(uint32 bedId, uint32 buddyGuid);

// Whether this spot belongs to a double bed (a link) no one is lying in: the
// owner, 2026-09-27, "yeah, maybe one of their clanmates will join them" -
// such a spot is taken before a single spot of the same comfort. A spot
// that stands alone (link 0) is never "an empty double bed".
bool BuddyBedIsEmptyDouble(BuddyBed const& bed);

// The ".buddy bed" game-master commands (add, list, remove, link, unlink).
void AddSC_buddies_beds();

#endif
