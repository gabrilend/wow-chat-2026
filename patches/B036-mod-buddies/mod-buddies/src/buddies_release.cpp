
#include "buddies.h"
#include "buddies_release.h"
#include "Chat.h"
#include "GameTime.h"
#include "Map.h"
#include "Player.h"
#include "SpellMgr.h"
#include <mutex>
#include <unordered_map>

static constexpr uint32 FIRST_WAIT_MIN_MS = 1000;
static constexpr uint32 FIRST_WAIT_MAX_MS = 10000;
static constexpr float  RESURRECTOR_YARDS = 70.0f;
static constexpr uint32 ASK_MIN_MS        = 10000;
static constexpr uint32 ASK_MAX_MS        = 20000;
static constexpr uint64 NEW_DEATH_GAP_MS  = 5000;

static constexpr uint32 RESURRECTIONS[] = {
    2006,
    7328,
    2008,
    20484,
};

static char const* const ASKS[] = { "rez?", "rez me please?", "pls rez" };

struct Death
{
    uint64     diedAt    = 0;
    uint32     firstWait = 0;
    uint64     lastAsked = 0;
    ObjectGuid waitingOn;
    uint64     waitingSince = 0;
    uint32     askAfter  = 0;
    bool       asked     = false;
};
static std::mutex sDeathLock;
static std::unordered_map<uint32, Death> sDeath;

static bool KnowsResurrection(Player* p)
{
    for (uint32 first : RESURRECTIONS)
        for (uint32 id = first; id; id = sSpellMgr->GetNextSpellInChain(id))
            if (p->HasSpell(id))
                return true;
    return false;
}

static Player* NearestResurrector(Player* bot)
{
    Player* best = nullptr;
    float bestD = RESURRECTOR_YARDS;
    for (auto const& ref : bot->GetMap()->GetPlayers())
    {
        Player* p = ref.GetSource();
        if (!p || p == bot || !p->IsAlive() || !p->IsInWorld() || p->GetTeamId() != bot->GetTeamId())
            continue;
        float d = bot->GetDistance(p);
        if (d > bestD || !KnowsResurrection(p))
            continue;
        best = p;
        bestD = d;
    }
    return best;
}

int BuddyReleaseRule(Player* bot)
{
    if (BuddySceneHolds(bot->GetGUID().GetCounter()))
        return 0;
    if (!BuddyIsCompanionAccount(bot->GetSession()->GetAccountId()))
        return -1;
    uint64 now = GameTime::GetGameTimeMS().count();
    uint32 low = bot->GetGUID().GetCounter();

    std::lock_guard<std::mutex> lock(sDeathLock);
    Death& d = sDeath[low];
    if (!d.lastAsked || now - d.lastAsked > NEW_DEATH_GAP_MS)
    {
        d = Death();
        d.diedAt    = now;
        d.firstWait = urand(FIRST_WAIT_MIN_MS, FIRST_WAIT_MAX_MS);
    }
    d.lastAsked = now;

    if (now - d.diedAt < d.firstWait)
        return 0;

    Player* healer = NearestResurrector(bot);
    if (!healer)
    {
        sDeath.erase(low);
        return 1;
    }
    if (d.waitingOn != healer->GetGUID())
    {
        d.waitingOn    = healer->GetGUID();
        d.waitingSince = now;
        d.askAfter     = urand(ASK_MIN_MS, ASK_MAX_MS);
        d.asked        = false;
    }
    if (!d.asked && now - d.waitingSince >= d.askAfter)
    {
        d.asked = true;
        bot->Whisper(ASKS[urand(0, std::size(ASKS) - 1)], LANG_UNIVERSAL, healer);
    }
    return 0;
}
