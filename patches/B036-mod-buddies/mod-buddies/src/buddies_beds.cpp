
#include "buddies_beds.h"
#include "buddies_explore.h"
#include "Chat.h"
#include "CommandScript.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Log.h"
#include "Player.h"
#include "QueryResult.h"
#include "ScriptMgr.h"
#include <algorithm>
#include <cctype>
#include <cmath>
#include <mutex>
#include <unordered_map>

using namespace Acore::ChatCommands;

static std::mutex sBedLock;
static std::vector<BuddyBed> sBeds;
static bool sBedsLoaded = false;

struct BedClaim
{
    uint32 buddy = 0;
    uint32 clan  = 0;
    uint64 until = 0;
};
static std::unordered_map<uint32, BedClaim> sClaims;

static uint64 NowMs() { return uint64(GameTime::GetGameTimeMS().count()); }

static void LoadBedsLocked()
{
    sBeds.clear();
    QueryResult rows = WorldDatabase.Query("SELECT id, map, x, y, z, facing, area, tier, link FROM buddy_bed");
    if (rows)
        do
        {
            Field* f = rows->Fetch();
            BuddyBed bed;
            bed.id     = f[0].Get<uint32>();
            bed.map    = f[1].Get<uint32>();
            bed.x      = f[2].Get<float>();
            bed.y      = f[3].Get<float>();
            bed.z      = f[4].Get<float>();
            bed.facing = f[5].Get<float>();
            bed.area   = f[6].Get<uint32>();
            bed.tier   = f[7].Get<uint8>();
            bed.link   = f[8].Get<uint32>();
            sBeds.push_back(bed);
        } while (rows->NextRow());
    sBedsLoaded = true;
}

std::vector<BuddyBed> BuddyBedsInArea(uint32 map, uint32 area)
{
    std::lock_guard<std::mutex> lock(sBedLock);
    if (!sBedsLoaded)
        LoadBedsLocked();
    std::vector<BuddyBed> found;
    for (BuddyBed const& bed : sBeds)
        if (bed.map == map && bed.area == area)
            found.push_back(bed);
    return found;
}

bool BuddyClaimBed(uint32 bedId, uint32 buddyGuid, uint32 clanGuid, uint32 holdMs)
{
    std::lock_guard<std::mutex> lock(sBedLock);
    uint64 now = NowMs();
    auto it = sClaims.find(bedId);
    if (it != sClaims.end() && it->second.buddy != buddyGuid && it->second.until > now)
        return false;
    uint32 link = 0;
    for (BuddyBed const& bed : sBeds)
        if (bed.id == bedId)
            link = bed.link;
    if (link)
        for (BuddyBed const& other : sBeds)
        {
            if (other.link != link || other.id == bedId)
                continue;
            auto held = sClaims.find(other.id);
            if (held != sClaims.end() && held->second.until > now && held->second.clan != clanGuid)
                return false;
        }
    sClaims[bedId] = { buddyGuid, clanGuid, now + holdMs };
    return true;
}

bool BuddyBedIsEmptyDouble(BuddyBed const& bed)
{
    if (!bed.link)
        return false;
    std::lock_guard<std::mutex> lock(sBedLock);
    uint64 now = NowMs();
    for (BuddyBed const& other : sBeds)
    {
        if (other.link != bed.link)
            continue;
        auto held = sClaims.find(other.id);
        if (held != sClaims.end() && held->second.until > now)
            return false;
    }
    return true;
}

void BuddyReleaseBed(uint32 bedId, uint32 buddyGuid)
{
    std::lock_guard<std::mutex> lock(sBedLock);
    auto it = sClaims.find(bedId);
    if (it != sClaims.end() && it->second.buddy == buddyGuid)
        sClaims.erase(it);
}

class buddies_beds_command : public CommandScript
{
public:
    buddies_beds_command() : CommandScript("buddies_beds_command") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable bedTable =
        {
            { "add",    HandleAdd,    SEC_GAMEMASTER, Console::No },
            { "list",   HandleList,   SEC_GAMEMASTER, Console::No },
            { "remove", HandleRemove, SEC_GAMEMASTER, Console::No },
            { "link",   HandleLink,   SEC_GAMEMASTER, Console::No },
            { "unlink", HandleUnlink, SEC_GAMEMASTER, Console::No },
        };
        static ChatCommandTable buddyTable =
        {
            { "bed", bedTable },
            { "explore", HandleExplore, SEC_PLAYER, Console::No },
        };
        static ChatCommandTable commandTable =
        {
            { "buddy", buddyTable },
        };
        return commandTable;
    }

    static uint8 TierByWord(std::string word)
    {
        static std::unordered_map<std::string, uint8> const tiers = {
            { "bed", BUDDY_BED_BED }, { "cot", BUDDY_BED_COT }, { "floor", BUDDY_BED_FLOOR },
            { "3", BUDDY_BED_BED },   { "2", BUDDY_BED_COT },   { "1", BUDDY_BED_FLOOR },
        };
        std::transform(word.begin(), word.end(), word.begin(), [](unsigned char c) { return char(std::tolower(c)); });
        auto it = tiers.find(word);
        return it == tiers.end() ? 0 : it->second;
    }
    static char const* TierName(uint8 tier)
    {
        static char const* const names[] = { "?", "floor", "cot", "bed" };
        return tier <= BUDDY_BED_BED ? names[tier] : "?";
    }

    static bool HandleExplore(ChatHandler* handler, std::string word)
    {
        return BuddyExploreHandleCommand(handler, word);
    }

    static bool HandleAdd(ChatHandler* handler, std::string tierWord, Optional<Tail> note)
    {
        Player* gm = handler->GetPlayer();
        uint8 tier = TierByWord(tierWord);
        if (!tier)
        {
            handler->PSendSysMessage("'{}' is not a bed tier: use bed (a mattress), cot, or floor (a rug, a bedroll, the ground).", tierWord);
            return true;
        }
        std::string text = note ? std::string(*note) : std::string();
        WorldDatabase.EscapeString(text);
        WorldDatabase.DirectExecute("INSERT INTO buddy_bed (map, x, y, z, facing, area, tier, note) VALUES ({}, {}, {}, {}, {}, {}, {}, '{}')",
            gm->GetMapId(), gm->GetPositionX(), gm->GetPositionY(), gm->GetPositionZ(), gm->GetOrientation(), gm->GetAreaId(), tier, text);
        {
            std::lock_guard<std::mutex> lock(sBedLock);
            LoadBedsLocked();
        }
        handler->PSendSysMessage("buddy {} added here (map {}, area {}, facing {:.2f}). Run scripts/export-buddy-beds to keep it in the project.",
            TierName(tier), gm->GetMapId(), gm->GetAreaId(), gm->GetOrientation());
        return true;
    }

    static std::vector<BuddyBed> NearestFirst(Player* gm)
    {
        std::vector<BuddyBed> beds = BuddyBedsInArea(gm->GetMapId(), gm->GetAreaId());
        std::sort(beds.begin(), beds.end(), [gm](BuddyBed const& a, BuddyBed const& b)
            { return gm->GetExactDist(a.x, a.y, a.z) < gm->GetExactDist(b.x, b.y, b.z); });
        return beds;
    }

    static bool HandleLink(ChatHandler* handler)
    {
        Player* gm = handler->GetPlayer();
        std::vector<BuddyBed> beds = NearestFirst(gm);
        if (beds.size() < 2 || gm->GetExactDist(beds[1].x, beds[1].y, beds[1].z) > 5.0f)
        {
            handler->SendSysMessage("Linking needs two buddy bed spots within 5 yards of you.");
            return true;
        }
        uint32 link = beds[1].link ? beds[1].link : beds[0].link;
        if (!link)
        {
            QueryResult top = WorldDatabase.Query("SELECT COALESCE(MAX(link), 0) + 1 FROM buddy_bed");
            link = top ? (*top)[0].Get<uint32>() : 1;
        }
        WorldDatabase.DirectExecute("UPDATE buddy_bed SET link = {} WHERE id IN ({}, {})", link, beds[0].id, beds[1].id);
        {
            std::lock_guard<std::mutex> lock(sBedLock);
            LoadBedsLocked();
        }
        handler->PSendSysMessage("buddy beds {} and {} are now one bed (link {}).", beds[0].id, beds[1].id, link);
        return true;
    }

    static bool HandleUnlink(ChatHandler* handler)
    {
        Player* gm = handler->GetPlayer();
        std::vector<BuddyBed> beds = NearestFirst(gm);
        if (beds.empty() || gm->GetExactDist(beds[0].x, beds[0].y, beds[0].z) > 5.0f)
        {
            handler->SendSysMessage("No buddy bed spot within 5 yards of you.");
            return true;
        }
        WorldDatabase.DirectExecute("UPDATE buddy_bed SET link = 0 WHERE id = {}", beds[0].id);
        {
            std::lock_guard<std::mutex> lock(sBedLock);
            LoadBedsLocked();
        }
        handler->PSendSysMessage("buddy bed {} stands alone again.", beds[0].id);
        return true;
    }

    static bool HandleList(ChatHandler* handler)
    {
        Player* gm = handler->GetPlayer();
        std::vector<BuddyBed> beds = NearestFirst(gm);
        handler->PSendSysMessage("{} buddy bed spot(s) in area {}:", beds.size(), gm->GetAreaId());
        for (BuddyBed const& bed : beds)
            handler->PSendSysMessage("  {} {} at {:.1f} yards (facing {:.2f}){}", TierName(bed.tier), bed.id,
                gm->GetExactDist(bed.x, bed.y, bed.z), bed.facing, bed.link ? " linked " + std::to_string(bed.link) : std::string());
        return true;
    }

    static bool HandleRemove(ChatHandler* handler)
    {
        Player* gm = handler->GetPlayer();
        BuddyBed const* nearest = nullptr;
        std::vector<BuddyBed> beds = BuddyBedsInArea(gm->GetMapId(), gm->GetAreaId());
        for (BuddyBed const& bed : beds)
            if (!nearest || gm->GetExactDist(bed.x, bed.y, bed.z) < gm->GetExactDist(nearest->x, nearest->y, nearest->z))
                nearest = &bed;
        if (!nearest || gm->GetExactDist(nearest->x, nearest->y, nearest->z) > 10.0f)
        {
            handler->SendSysMessage("No buddy bed within 10 yards in this area.");
            return true;
        }
        uint32 id = nearest->id;
        WorldDatabase.DirectExecute("DELETE FROM buddy_bed WHERE id = {}", id);
        {
            std::lock_guard<std::mutex> lock(sBedLock);
            LoadBedsLocked();
            sClaims.erase(id);
        }
        handler->PSendSysMessage("buddy bed {} removed. Run scripts/export-buddy-beds to keep the change in the project.", id);
        return true;
    }
};

void AddSC_buddies_beds()
{
    new buddies_beds_command();
}
