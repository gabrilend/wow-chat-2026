/*
 * buddies_release.cpp - when a dead buddy releases its spirit (issue 632).
 *
 * For a general audience: the owner, 2026-10-22: "after 1-10 seconds
 * after they die they click "release spirit" unless there's a person
 * nearby who maybe can rez them alive and on their side. If so, then they
 * wait." And 2026-10-30, on who and how long: "anyone on their side who
 * knows one. Within 70 yards probably", "it waits until they are out of
 * range. After 10-20 seconds it whispers them asking them for a rez. "rez?"
 * "rez me please?" "pls rez" etc."
 *
 * The bot module asks BuddyReleaseRule each time it considers releasing a
 * dead bot (source patch B066, in its auto-release check, about once a
 * second while the bot lies dead). The answer, for a buddy:
 *   the first 1 to 10 seconds after death (drawn per death)  - wait
 *   then, someone able to resurrect it within 70 yards       - wait; once it
 *                                                              has waited 10
 *                                                              to 20 seconds
 *                                                              on them, it
 *                                                              whispers them
 *                                                              once
 *   then, nobody able                                         - release
 * "Able": alive, of its side (the same team), not itself, knowing any rank
 * of a resurrection spell (a priest's Resurrection, a paladin's
 * Redemption, a shaman's Ancestral Spirit, a druid's Rebirth), buddies
 * included. Anyone not a buddy (owners, other bots) gets -1: the bot
 * module's stock rules decide.
 *
 * A death is told from the last by the gap between the bot module's
 * questions: more than NEW_DEATH_GAP_MS since the last one means it was
 * alive in between, so the timers start again.
 */

#include "buddies.h"
#include "buddies_release.h"
#include "Chat.h"
#include "GameTime.h"
#include "Map.h"
#include "Player.h"
#include "SpellMgr.h"
#include <mutex>
#include <unordered_map>

static constexpr uint32 FIRST_WAIT_MIN_MS = 1000;      // "after 1-10 seconds after they die"
static constexpr uint32 FIRST_WAIT_MAX_MS = 10000;
static constexpr float  RESURRECTOR_YARDS = 70.0f;     // "Within 70 yards probably"
static constexpr uint32 ASK_MIN_MS        = 10000;     // "After 10-20 seconds it whispers them"
static constexpr uint32 ASK_MAX_MS        = 20000;
static constexpr uint64 NEW_DEATH_GAP_MS  = 5000;      // the bot module asks about once a second while dead

// The first rank of each resurrection spell; the higher ranks are found
// along the spell's rank chain (the server's own SpellMgr).
static constexpr uint32 RESURRECTIONS[] = {
    2006,                                              // Resurrection (priest)
    7328,                                              // Redemption (paladin)
    2008,                                              // Ancestral Spirit (shaman)
    20484,                                             // Rebirth (druid)
};

static char const* const ASKS[] = { "rez?", "rez me please?", "pls rez" };

// {{{ the dead buddies
// Death: when it died (as first seen), its first wait, who it is waiting
// on and since when, and whether it has asked them.
struct Death
{
    uint64     diedAt    = 0;
    uint32     firstWait = 0;
    uint64     lastAsked = 0;                          // when the bot module last asked (a new death past the gap)
    ObjectGuid waitingOn;
    uint64     waitingSince = 0;
    uint32     askAfter  = 0;
    bool       asked     = false;
};
static std::mutex sDeathLock;
static std::unordered_map<uint32, Death> sDeath;       // buddy (low guid) -> its death; under sDeathLock
// }}}

// {{{ KnowsResurrection
static bool KnowsResurrection(Player* p)
{
    for (uint32 first : RESURRECTIONS)
        for (uint32 id = first; id; id = sSpellMgr->GetNextSpellInChain(id))
            if (p->HasSpell(id))
                return true;
    return false;
}
// }}}

// {{{ NearestResurrector
// The nearest player within RESURRECTOR_YARDS of `bot` able to resurrect it
// (see the file's header), or null.
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
// }}}

// {{{ BuddyReleaseRule
int BuddyReleaseRule(Player* bot)
{
    if (!BuddyIsCompanionAccount(bot->GetSession()->GetAccountId()))
        return -1;                                     // not a buddy: the bot module's own rules
    uint64 now = GameTime::GetGameTimeMS().count();
    uint32 low = bot->GetGUID().GetCounter();

    std::lock_guard<std::mutex> lock(sDeathLock);
    Death& d = sDeath[low];
    if (!d.lastAsked || now - d.lastAsked > NEW_DEATH_GAP_MS)
    {
        d = Death();                                   // a new death (or the first asked about)
        d.diedAt    = now;
        d.firstWait = urand(FIRST_WAIT_MIN_MS, FIRST_WAIT_MAX_MS);
    }
    d.lastAsked = now;

    if (now - d.diedAt < d.firstWait)
        return 0;                                      // its first moments: it lies still

    Player* healer = NearestResurrector(bot);
    if (!healer)
    {
        sDeath.erase(low);
        return 1;                                      // nobody to raise it: it releases
    }
    if (d.waitingOn != healer->GetGUID())
    {
        d.waitingOn    = healer->GetGUID();            // waiting on someone new: the asking clock starts again
        d.waitingSince = now;
        d.askAfter     = urand(ASK_MIN_MS, ASK_MAX_MS);
        d.asked        = false;
    }
    if (!d.asked && now - d.waitingSince >= d.askAfter)
    {
        d.asked = true;
        bot->Whisper(ASKS[urand(0, std::size(ASKS) - 1)], LANG_UNIVERSAL, healer);
    }
    return 0;                                          // someone could raise it: it waits
}
// }}}
