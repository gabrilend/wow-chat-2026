/*
 * buddy_pace_core.h - the tank's pace in a dungeon (issue 617z): whether to
 * pull the next pack or wait, how wide to clear, and what the group's words
 * do to it. Plain arithmetic, no server, so scripts/test-buddy-pace checks
 * it alone with the system compiler; the server's part (the route to the
 * next boss, hearing the words, walking and pulling) feeds it numbers and
 * reads its answers.
 *
 * For a general audience, the owner's design (2026-10-12 and 2026-10-28):
 * before each pull the tank asks "could the healer carry me through this
 * fight?", from the healer's mana, how the group's recent fights went, and
 * how hard the next pack looks. Its confidence starts high ("the tank
 * should default to going faster"); a "wait" or "slow down" from anyone in
 * the group lowers it, and it "builds up confidence again which happens
 * over time"; a healer's "oom" or "mana" stops it until the healer says
 * "ready". There is no word for faster: "If the DPS wants to go faster,
 * they should just pull more mobs. The tank will pick them up and be a
 * little upset. They should sense how well they're doing and if they can
 * handle it, they'll adjust": a fight that went well raises it. And of the
 * route: "confident tanks clear more, nervous or scared tanks try to clear
 * the bare minimum and skirt the edges".
 *
 * The pieces (every number is the agent's call, 2026-10-31, in Settings):
 *   a pack's weight - normals count 1, elites 3, each level above the
 *                     group's average 10% more (below, 10% less);
 *   the record      - the last few fights: the healer's mana spent (a share
 *                     of the full bar, 0-100) and the pack's weight; the
 *                     expected cost of a pack is the record's mana per
 *                     weight times its weight (no record: defaultCostPerWeight);
 *   the decision    - pull when the healer's mana, less the expected cost,
 *                     keeps a reserve; the reserve grows as confidence falls
 *                     ((1 - confidence) x maxReserve); stopped: wait;
 *   confidence      - 0 to 1, from startConfidence; a slowing word takes
 *                     slowDrop off (not below minConfidence); it regains
 *                     regainPerMinute back up to startConfidence; a fight
 *                     the healer came out of above the reserve adds
 *                     wellDoneGain;
 *   clearing width  - clearMin to clearMax yards round the route, by
 *                     confidence.
 *
 * Added 2026-11-06 (the agent's calls, in Settings too):
 *   a player's pull - the tank picks up a pack someone else pulled, says
 *                     it's a little put out, and if the healer came out of
 *                     it above the reserve, its confidence rises at once to
 *                     at least what it would have needed to pull that pack
 *                     itself ("they'll adjust to the new speed and pull
 *                     accordingly");
 *   what it says    - "Waiting for mana." or "Waiting for ready." when it
 *                     holds (the owner, 2026-10-30, of the line: "sure.");
 *   harmless packs  - grey to the tank (the game's own grey level): walked
 *                     past, unless hostile, when they are swept up on the
 *                     way without asking the healer ("If they are hostile
 *                     they are picked up and cleared by AoE on the way");
 *   a healer buddy  - says "slow down" (whispered to the tank) when it
 *                     can't keep up: healerLowCount of its last healerWindow
 *                     fights ended with its mana under healerLowAfter, or a
 *                     fight where the group's health fell faster than it
 *                     could heal; then keeps quiet for healerQuiet fights.
 */

#ifndef BUDDY_PACE_CORE_H
#define BUDDY_PACE_CORE_H

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdint>
#include <deque>
#include <string>

namespace BuddyPace
{

// {{{ Settings
struct Settings
{
    size_t recordSize          = 5;      // fights remembered
    float  startConfidence     = 0.9f;   // "default to going faster"
    float  minConfidence       = 0.1f;
    float  slowDrop            = 0.3f;   // one "wait" or "slow down"
    float  regainPerMinute     = 0.05f;  // back toward startConfidence
    float  wellDoneGain        = 0.05f;  // a fight the healer came out of with mana to spare
    float  maxReserve          = 40.0f;  // mana (percent) a fully nervous tank keeps in hand
    float  defaultCostPerWeight = 10.0f; // mana (percent) per unit of pack weight, before any fight is remembered
    float  eliteWeight         = 3.0f;
    float  levelFactor         = 1.1f;   // per level above (or below) the group's average
    float  clearMin            = 10.0f;  // yards cleared either side of the route by the most nervous tank
    float  clearMax            = 30.0f;  // and by the most confident
    // a healer buddy's own "slow down" (2026-11-06)
    float  healerLowAfter      = 25.0f;  // mana (percent) a fight ending under counts as too low
    size_t healerWindow        = 3;      // fights it looks back over
    size_t healerLowCount      = 2;      // of them, this many too low: "slow down"
    size_t healerQuiet         = 3;      // fights it keeps quiet after saying it
};
// }}}

// {{{ Pack
// The next pack: how many normal and elite monsters, and their average
// level less the group's.
struct Pack { uint32_t normals = 0, elites = 0; float levelDiff = 0.0f; };

inline float Weight(Pack const& p, Settings const& s)
{
    return (float(p.normals) + s.eliteWeight * float(p.elites)) * std::pow(s.levelFactor, p.levelDiff);
}
// }}}

// {{{ the words
// What the group says, read from any player's line (lower case, words
// matched whole): "wait", "slow down", "go slower", "slower" slow the
// tank; "oom", "out of mana", "mana" stop it; "ready" lets it go on.
enum class Word : uint8_t { None, Slow, Oom, Ready };

inline Word ReadWord(std::string text)
{
    std::transform(text.begin(), text.end(), text.begin(), [](unsigned char c) { return char(std::tolower(c)); });
    // trim spaces and the punctuation a quick line carries
    auto keep = [](unsigned char c) { return std::isalnum(c) || c == ' '; };
    std::string t;
    for (char c : text)
        if (keep((unsigned char)c))
            t += c;
    while (!t.empty() && t.front() == ' ') t.erase(t.begin());
    while (!t.empty() && t.back() == ' ') t.pop_back();
    if (t == "wait" || t == "slow down" || t == "go slower" || t == "slower" || t == "slow")
        return Word::Slow;
    if (t == "oom" || t == "out of mana" || t == "mana")
        return Word::Oom;
    if (t == "ready" || t == "rdy")
        return Word::Ready;
    return Word::None;
}
// }}}

// {{{ Tank
struct FightCost { float healerManaPct = 0.0f; float packWeight = 0.0f; };

struct Tank
{
    float    confidence = 0.9f;
    bool     stopped    = false;       // a healer said "oom": waits for "ready"
    uint64_t lastMs     = 0;           // the last Tick
    std::deque<FightCost> record;

    explicit Tank(Settings const& s = Settings()) : confidence(s.startConfidence) { }

    // time passing: confidence regained toward the start
    void Tick(uint64_t nowMs, Settings const& s)
    {
        if (lastMs && nowMs > lastMs && confidence < s.startConfidence)
            confidence = std::min(s.startConfidence, confidence + s.regainPerMinute * float(nowMs - lastMs) / 60000.0f);
        lastMs = nowMs;
    }

    // a word heard. Each path:
    //   Slow  - confidence down by slowDrop (not below minConfidence)
    //   Oom   - stopped, and slowed as Slow
    //   Ready - no longer stopped
    //   None  - nothing
    void Heard(Word w, Settings const& s)
    {
        if (w == Word::Slow || w == Word::Oom)
            confidence = std::max(s.minConfidence, confidence - s.slowDrop);
        if (w == Word::Oom)
            stopped = true;
        if (w == Word::Ready)
            stopped = false;
    }

    // mana (percent) the healer keeps in hand at this confidence
    float Reserve(Settings const& s) const { return (1.0f - confidence) * s.maxReserve; }

    // a fight ended (the tank's own pull, or one someone else pulled and
    // it picked up): remembered; with the healer's mana left above the
    // reserve, it went well and confidence rises a little
    void Fought(FightCost const& f, float healerManaAfterPct, Settings const& s)
    {
        record.push_back(f);
        while (record.size() > s.recordSize)
            record.pop_front();
        if (healerManaAfterPct >= Reserve(s))
            confidence = std::min(1.0f, confidence + s.wellDoneGain);
    }

    // the mana (percent) a pack is expected to cost the healer
    float ExpectedCost(Pack const& p, Settings const& s) const
    {
        float mana = 0.0f, weight = 0.0f;
        for (FightCost const& f : record)
        {
            mana   += f.healerManaPct;
            weight += f.packWeight;
        }
        float perWeight = weight > 0.0f ? mana / weight : s.defaultCostPerWeight;
        return perWeight * Weight(p, s);
    }

    // pull the next pack, or wait. Each path:
    //   stopped (a healer's "oom", no "ready" since)      - wait
    //   the healer's mana less the expected cost keeps
    //   the reserve                                       - pull
    //   otherwise                                         - wait (mana comes back, then ask again)
    bool ShouldPull(float healerManaPct, Pack const& p, Settings const& s) const
    {
        if (stopped)
            return false;
        return healerManaPct - ExpectedCost(p, s) >= Reserve(s);
    }

    // yards cleared either side of the route
    float ClearYards(Settings const& s) const { return s.clearMin + confidence * (s.clearMax - s.clearMin); }

    // the confidence it would need to pull a pack itself with the healer
    // at this mana: the reserve it may keep is what the expected cost
    // leaves (between minConfidence and 1)
    float NeededFor(float healerManaPct, Pack const& p, Settings const& s) const
    {
        float spare = healerManaPct - ExpectedCost(p, s);
        return std::clamp(1.0f - spare / s.maxReserve, s.minConfidence, 1.0f);
    }

    // a pack someone else pulled, picked up: remembered like any fight;
    // the healer above the reserve after it, confidence at least what the
    // tank would have needed to pull it (the healer's mana as it began);
    // returns what the tank says, a little put out
    char const* PlayerPulled(FightCost const& f, float healerManaBeforePct, float healerManaAfterPct, Pack const& p, Settings const& s)
    {
        bool well = healerManaAfterPct >= Reserve(s);
        Fought(f, healerManaAfterPct, s);
        if (well)
            confidence = std::max(confidence, NeededFor(healerManaBeforePct, p, s));
        return "Fine, I'll take them.";
    }

    // what it says when it holds: nothing when it would pull
    char const* WaitLine(float healerManaPct, Pack const& p, Settings const& s) const
    {
        if (stopped)                          return "Waiting for ready.";
        if (!ShouldPull(healerManaPct, p, s)) return "Waiting for mana.";
        return nullptr;
    }
};
// }}}

// {{{ harmless packs
// The game's grey level for a character of `level` (a monster at or below
// it gives no experience: AzerothCore's own GetGrayLevel).
inline int32_t GreyLevel(int32_t level)
{
    if (level <= 5)  return 0;
    if (level <= 39) return level - 5 - level / 10;
    if (level <= 59) return level - 1 - level / 5;
    return level - 9;
}

// What the tank does with a pack on its way: Pull (asked as any pack:
// ShouldPull), WalkPast (grey to it and not hostile: "refuse to fight"),
// Sweep (grey and hostile: cleared by area attacks on the way, the healer
// not asked).
enum class Plan : uint8_t { Pull, WalkPast, Sweep };

inline Plan PackPlan(int32_t tankLevel, int32_t packLevel, bool hostile)
{
    if (packLevel > GreyLevel(tankLevel)) return Plan::Pull;
    return hostile ? Plan::Sweep : Plan::WalkPast;
}
// }}}

// {{{ HealerVoice
// A healer buddy's own judgement of when to whisper "slow down" to the
// tank (the owner, 2026-10-12: "healer buddies can say it to the tank if
// the tank is doing too dangerous and they can't keep up").
struct HealerVoice
{
    std::deque<float> after;   // its mana (percent) at each recent fight's end
    size_t quiet = 0;          // fights still to keep quiet for

    // a fight ended: its mana after it, and whether the group's health fell
    // faster than it could heal for a stretch of it (the server's reading).
    // Returns Word::Slow when it says "slow down", Word::None otherwise.
    Word Fought(float manaAfterPct, bool fellBehind, Settings const& s)
    {
        if (quiet > 0)                    // keeping quiet: these fights aren't counted
        {
            --quiet;
            return Word::None;
        }
        after.push_back(manaAfterPct);
        while (after.size() > s.healerWindow)
            after.pop_front();
        size_t low = 0;
        for (float m : after)
            low += m < s.healerLowAfter ? 1 : 0;
        if (!fellBehind && low < s.healerLowCount)
            return Word::None;
        quiet = s.healerQuiet;
        after.clear();
        return Word::Slow;
    }
};
// }}}

} // namespace BuddyPace

#endif
