/*
 * buddies_npcs.cpp - buddies notice the people around them and use them
 * (issue 617p; the rules in plain words are in buddies_npcs.h).
 *
 * What a person offers is read from the creature: its service flags (the
 * game's own: trainer, vendor, repairer, gossip, quest giver) and, for a
 * trainer, its lesson list. Nothing here reads the world's spawn table.
 * The standing spots are claimed in one table shared by every buddy (the
 * bot module runs bots on more than one thread, so it is locked), held
 * until released or for CLAIM_MS.
 */

#include "buddies.h"
#include "buddies_npcs.h"
#include "buddies_navmesh.h"
#include "buddies_spells.h"
#include "buddies_town.h"
#include "CellImpl.h"
#include "Creature.h"
#include "GameTime.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Item.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Trainer.h"
#include <array>
#include <cmath>
#include <list>
#include <mutex>
#include <unordered_map>
#include <unordered_set>

// {{{ tuning
static constexpr float  NOTICE_YARDS   = 100.0f;   // the owner: "within 100 yards"
static constexpr float  SPOT_YARDS     = 3.0f;     // a standing spot this far in front of the person
static constexpr float  SPOT_SPREAD    = 0.7f;     // radians either side of straight in front for the side spots
static constexpr uint32 CLAIM_MS       = 90000;    // a spot is held this long at most
static constexpr float  WORN_SHARE     = 0.5f;     // gear this worn (an item at half durability) wants repairs
static constexpr uint64 SWAP_MS        = 900000;   // the visit buffers swap this often, server-wide (15 minutes)
// }}}

// {{{ the visited
// The owner, 2026-10-03: "How about we build a double-buffer system, and a
// server-wide 15 minute timer. when the timer expires, then we swap
// buffers and clear the older of the two. New entries go to the newly
// emptied buffer, and buddy-bots treat both buffers as valid. The buffers
// are per-buddy, but they're swapped globally."
//
// The timer is the server's own clock cut into 15-minute turns (turn =
// game time / SWAP_MS, the same for every buddy). Turn n writes into
// buffer n % 2; the other buffer holds turn n - 1. The swap is done
// lazily: a buffer stamped with an older turn than it should hold is
// emptied the first time its buddy looks in the new turn. That is the same
// as emptying every buddy's at the turn, without touching buddies that
// aren't looking. A visit is remembered for 15 to 30 minutes.
struct VisitBuffers
{
    std::unordered_set<uint64> people[2];              // raw guids of the people visited
    uint64                     turn[2] = { UINT64_MAX, UINT64_MAX };   // the turn each holds
};
static std::mutex sVisitLock;
static std::unordered_map<uint32, VisitBuffers> sVisited;   // buddy guid -> its buffers

// The buddy's buffers brought up to this turn: the current one emptied if
// it still holds an older turn, the other kept only if it holds the turn
// before. Returns the current buffer's index.
static int Swap(VisitBuffers& v, uint64 turn)
{
    int cur = int(turn % 2), old = 1 - cur;
    if (v.turn[cur] != turn)
    {
        v.people[cur].clear();                         // the newly emptied buffer
        v.turn[cur] = turn;
    }
    if (v.turn[old] != turn - 1)
    {
        v.people[old].clear();                         // older than the turn before: gone too
        v.turn[old] = turn - 1;
    }
    return cur;
}
// }}}

// {{{ the claims
struct Claim { uint32 buddy = 0; uint64 until = 0; };
static std::mutex sClaimLock;
static std::unordered_map<uint64, std::array<Claim, 3>> sClaims;   // person (raw guid) -> its three spots

static uint64 NowMs() { return uint64(GameTime::GetGameTimeMS().count()); }

// A free spot at the person for this buddy (its own claim kept), claimed;
// -1 when all three are taken.
static int ClaimSpot(Creature const* npc, uint32 buddy)
{
    std::lock_guard<std::mutex> lock(sClaimLock);
    auto& spots = sClaims[npc->GetGUID().GetRawValue()];
    uint64 now = NowMs();
    for (int i = 0; i < 3; ++i)
        if (spots[i].buddy == buddy && spots[i].until > now)
            return i;
    for (int i = 0; i < 3; ++i)
        if (!spots[i].buddy || spots[i].until <= now)
        {
            spots[i] = { buddy, now + CLAIM_MS };
            return i;
        }
    return -1;
}

void BuddyNpcRelease(Player* bot, ObjectGuid npc)
{
    std::lock_guard<std::mutex> lock(sClaimLock);
    auto it = sClaims.find(npc.GetRawValue());
    if (it == sClaims.end())
        return;
    for (Claim& c : it->second)
        if (c.buddy == bot->GetGUID().GetCounter())
            c = Claim();
}
// }}}

// {{{ what a person offers, and what the buddy needs
static bool HasAffordableLesson(Player* bot, Creature* npc)
{
    if (!npc->IsTrainer())
        return false;
    Trainer::Trainer* trainer = sObjectMgr->GetTrainer(npc->GetEntry());
    if (!trainer || trainer->GetTrainerType() != Trainer::Type::Class || !trainer->IsTrainerValidForPlayer(bot))
        return false;
    float discount = bot->GetReputationPriceDiscount(npc);
    for (Trainer::Spell const& sp : trainer->GetSpells())
        if (trainer->CanTeachSpell(bot, &sp) && bot->HasEnoughMoney(int32(sp.MoneyCost * discount)))
            return true;
    return false;
}

static bool GearWorn(Player* bot)
{
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        if (Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
        {
            uint32 most = item->GetUInt32Value(ITEM_FIELD_MAXDURABILITY);
            if (most && item->GetUInt32Value(ITEM_FIELD_DURABILITY) < uint32(most * WORN_SHARE))
                return true;
        }
    return false;
}

// The need this person meets for the buddy now, None for none.
static BuddyNpcUse NeedMet(Player* bot, Creature* npc, bool full, bool worn)
{
    if (HasAffordableLesson(bot, npc))
        return BuddyNpcUse::Train;
    if (full && npc->IsVendor())
        return BuddyNpcUse::Sell;
    if (worn && npc->HasNpcFlag(UNIT_NPC_FLAG_REPAIR) && bot->GetMoney() > 0)
        return BuddyNpcUse::Repair;
    return BuddyNpcUse::None;
}

// Anything worn that has lost durability at all.
static bool AnyDamage(Player* bot)
{
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        if (Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            if (item->GetUInt32Value(ITEM_FIELD_DURABILITY) < item->GetUInt32Value(ITEM_FIELD_MAXDURABILITY))
                return true;
    return false;
}
// }}}

// {{{ BuddyNpcNotice
bool BuddyNpcNotice(Player* bot, BuddyNpcPick& out)
{
    std::list<Creature*> near;
    Acore::AllWorldObjectsInRange check(bot, NOTICE_YARDS);
    Acore::CreatureListSearcher<Acore::AllWorldObjectsInRange> searcher(bot, near, check);
    Cell::VisitObjects(bot, searcher, NOTICE_YARDS);

    bool   full = BuddyBagFullness(bot) >= BuddyFullBagsShare();
    bool   worn = GearWorn(bot);
    uint64 now  = NowMs();
    uint32 me   = bot->GetGUID().GetCounter();
    std::lock_guard<std::mutex> visitLock(sVisitLock);
    VisitBuffers& visited = sVisited[me];
    int cur = Swap(visited, now / SWAP_MS);

    Creature* best = nullptr;
    BuddyNpcUse bestUse = BuddyNpcUse::None;
    float bestDist = NOTICE_YARDS + 1.0f;
    for (Creature* c : near)
    {
        // a person: friendly, alive and free, offering a service or a
        // humanoid to talk to (quest givers too: "just pretend to talk")
        if (!c->IsAlive() || c->IsInCombat() || !c->GetCharmerOrOwnerGUID().IsEmpty() || c->IsHostileTo(bot) ||
            c->HasUnitFlag(UNIT_FLAG_NOT_SELECTABLE) || (!c->GetNpcFlags() && c->GetCreatureType() != CREATURE_TYPE_HUMANOID))
            continue;
        BuddyNpcUse use = NeedMet(bot, c, full, worn);
        if (use == BuddyNpcUse::None)
        {
            uint64 raw = c->GetGUID().GetRawValue();
            if (visited.people[0].count(raw) || visited.people[1].count(raw))
                continue;                               // in either buffer: visited lately, and not needed
            use = BuddyNpcUse::Visit;
        }
        float d = bot->GetExactDist(c);
        // a need first (lessons, selling, repairs), then a first visit; then the nearer
        if (!best || uint8(use) < uint8(bestUse) || (use == bestUse && d < bestDist))
            best = c, bestUse = use, bestDist = d;
    }
    if (!best)
        return false;
    visited.people[cur].insert(best->GetGUID().GetRawValue());   // remembered from the pick: unreachable ones wait too
    int spot = ClaimSpot(best, bot->GetGUID().GetCounter());
    if (spot < 0)
        return false;                                   // three buddies there already: another time
    float a = best->GetOrientation() + (spot == 0 ? 0.0f : (spot == 1 ? SPOT_SPREAD : -SPOT_SPREAD));
    BuddyRoam::Point want { best->GetPositionX() + std::cos(a) * SPOT_YARDS, best->GetPositionY() + std::sin(a) * SPOT_YARDS,
                            best->GetPositionZ() }, onMesh;
    if (!BuddyMeshSnap(bot->GetMap(), want, 2.0f, 4.0f, onMesh))
    {
        BuddyNpcRelease(bot, best->GetGUID());          // no floor at that spot (a wall, a counter): not this person, this time
        return false;
    }
    out.npc  = best->GetGUID();
    out.use  = bestUse;
    out.spot = onMesh;
    return true;
}
// }}}

// {{{ BuddyNpcArrive
// "only test to see what they do the first time they arrive": every
// service of the person the buddy can use now, in this order.
std::string BuddyNpcArrive(PlayerbotAI* ai, Player* bot, Creature* npc, bool& talk)
{
    std::string done;
    if (HasAffordableLesson(bot, npc))
        done += std::to_string(BuddyTrainAtTrainer(bot, npc)) + " lessons; ";
    if (npc->IsVendor())
    {
        // "If it's a vendor, they'll sell the stuff they don't need"
        float before = BuddyBagFullness(bot);
        BuddySellAtVendor(ai, bot, npc);
        done += "sold: bags " + std::to_string(int(before * 100)) + "% full, now " + std::to_string(int(BuddyBagFullness(bot) * 100)) + "%; ";
    }
    if (npc->HasNpcFlag(UNIT_NPC_FLAG_REPAIR) && AnyDamage(bot) && bot->GetMoney() > 0)
    {
        bot->DurabilityRepairAll(true, bot->GetReputationPriceDiscount(npc), false);
        done += "gear repaired; ";
    }
    talk = done.empty();                                // "If it's just an NPC, they'll just talk to them"
    return talk ? "a chat" : done;
}

char const* BuddyNpcUseName(BuddyNpcUse use)
{
    static char const* const names[] = { "nothing", "lessons", "selling", "repairs", "a first visit" };
    return names[uint8(use)];
}
// }}}
