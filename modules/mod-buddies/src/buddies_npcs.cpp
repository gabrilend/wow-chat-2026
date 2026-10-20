
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

static constexpr float  NOTICE_YARDS   = 100.0f;
static constexpr float  SPOT_YARDS     = 3.0f;
static constexpr float  SPOT_SPREAD    = 0.7f;
static constexpr uint32 CLAIM_MS       = 90000;
static constexpr float  WORN_SHARE     = 0.5f;
static constexpr uint64 SWAP_MS        = 900000;

struct VisitBuffers
{
    std::unordered_set<uint64> people[2];
    uint64                     turn[2] = { UINT64_MAX, UINT64_MAX };
};
static std::mutex sVisitLock;
static std::unordered_map<uint32, VisitBuffers> sVisited;

static int Swap(VisitBuffers& v, uint64 turn)
{
    int cur = int(turn % 2), old = 1 - cur;
    if (v.turn[cur] != turn)
    {
        v.people[cur].clear();
        v.turn[cur] = turn;
    }
    if (v.turn[old] != turn - 1)
    {
        v.people[old].clear();
        v.turn[old] = turn - 1;
    }
    return cur;
}

struct Claim { uint32 buddy = 0; uint64 until = 0; };
static std::mutex sClaimLock;
static std::unordered_map<uint64, std::array<Claim, 3>> sClaims;

static uint64 NowMs() { return uint64(GameTime::GetGameTimeMS().count()); }

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

static bool AnyDamage(Player* bot)
{
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        if (Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            if (item->GetUInt32Value(ITEM_FIELD_DURABILITY) < item->GetUInt32Value(ITEM_FIELD_MAXDURABILITY))
                return true;
    return false;
}

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
        if (!c->IsAlive() || c->IsInCombat() || !c->GetCharmerOrOwnerGUID().IsEmpty() || c->IsHostileTo(bot) ||
            c->HasUnitFlag(UNIT_FLAG_NOT_SELECTABLE) || (!c->GetNpcFlags() && c->GetCreatureType() != CREATURE_TYPE_HUMANOID))
            continue;
        BuddyNpcUse use = NeedMet(bot, c, full, worn);
        if (use == BuddyNpcUse::None)
        {
            uint64 raw = c->GetGUID().GetRawValue();
            if (visited.people[0].count(raw) || visited.people[1].count(raw))
                continue;
            use = BuddyNpcUse::Visit;
        }
        float d = bot->GetExactDist(c);
        if (!best || uint8(use) < uint8(bestUse) || (use == bestUse && d < bestDist))
            best = c, bestUse = use, bestDist = d;
    }
    if (!best)
        return false;
    visited.people[cur].insert(best->GetGUID().GetRawValue());
    int spot = ClaimSpot(best, bot->GetGUID().GetCounter());
    if (spot < 0)
        return false;
    float a = best->GetOrientation() + (spot == 0 ? 0.0f : (spot == 1 ? SPOT_SPREAD : -SPOT_SPREAD));
    BuddyRoam::Point want { best->GetPositionX() + std::cos(a) * SPOT_YARDS, best->GetPositionY() + std::sin(a) * SPOT_YARDS,
                            best->GetPositionZ() }, onMesh;
    if (!BuddyMeshSnap(bot->GetMap(), want, 2.0f, 4.0f, onMesh))
    {
        BuddyNpcRelease(bot, best->GetGUID());
        return false;
    }
    out.npc  = best->GetGUID();
    out.use  = bestUse;
    out.spot = onMesh;
    return true;
}

std::string BuddyNpcArrive(PlayerbotAI* ai, Player* bot, Creature* npc, bool& talk)
{
    std::string done;
    if (HasAffordableLesson(bot, npc))
        done += std::to_string(BuddyTrainAtTrainer(bot, npc)) + " lessons; ";
    if (npc->IsVendor())
    {
        float before = BuddyBagFullness(bot);
        BuddySellAtVendor(ai, bot, npc);
        done += "sold: bags " + std::to_string(int(before * 100)) + "% full, now " + std::to_string(int(BuddyBagFullness(bot) * 100)) + "%; ";
    }
    if (npc->HasNpcFlag(UNIT_NPC_FLAG_REPAIR) && AnyDamage(bot) && bot->GetMoney() > 0)
    {
        bot->DurabilityRepairAll(true, bot->GetReputationPriceDiscount(npc), false);
        done += "gear repaired; ";
    }
    talk = done.empty();
    return talk ? "a chat" : done;
}

char const* BuddyNpcUseName(BuddyNpcUse use)
{
    static char const* const names[] = { "nothing", "lessons", "selling", "repairs", "a first visit" };
    return names[uint8(use)];
}
