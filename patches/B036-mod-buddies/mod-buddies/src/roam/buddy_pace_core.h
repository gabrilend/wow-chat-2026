
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

struct Settings
{
    size_t recordSize          = 5;
    float  startConfidence     = 0.9f;
    float  minConfidence       = 0.1f;
    float  slowDrop            = 0.3f;
    float  regainPerMinute     = 0.05f;
    float  wellDoneGain        = 0.05f;
    float  maxReserve          = 40.0f;
    float  defaultCostPerWeight = 10.0f;
    float  eliteWeight         = 3.0f;
    float  levelFactor         = 1.1f;
    float  clearMin            = 10.0f;
    float  clearMax            = 30.0f;
};

struct Pack { uint32_t normals = 0, elites = 0; float levelDiff = 0.0f; };

inline float Weight(Pack const& p, Settings const& s)
{
    return (float(p.normals) + s.eliteWeight * float(p.elites)) * std::pow(s.levelFactor, p.levelDiff);
}

enum class Word : uint8_t { None, Slow, Oom, Ready };

inline Word ReadWord(std::string text)
{
    std::transform(text.begin(), text.end(), text.begin(), [](unsigned char c) { return char(std::tolower(c)); });
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

struct FightCost { float healerManaPct = 0.0f; float packWeight = 0.0f; };

struct Tank
{
    float    confidence = 0.9f;
    bool     stopped    = false;
    uint64_t lastMs     = 0;
    std::deque<FightCost> record;

    explicit Tank(Settings const& s = Settings()) : confidence(s.startConfidence) { }

    void Tick(uint64_t nowMs, Settings const& s)
    {
        if (lastMs && nowMs > lastMs && confidence < s.startConfidence)
            confidence = std::min(s.startConfidence, confidence + s.regainPerMinute * float(nowMs - lastMs) / 60000.0f);
        lastMs = nowMs;
    }

    void Heard(Word w, Settings const& s)
    {
        if (w == Word::Slow || w == Word::Oom)
            confidence = std::max(s.minConfidence, confidence - s.slowDrop);
        if (w == Word::Oom)
            stopped = true;
        if (w == Word::Ready)
            stopped = false;
    }

    float Reserve(Settings const& s) const { return (1.0f - confidence) * s.maxReserve; }

    void Fought(FightCost const& f, float healerManaAfterPct, Settings const& s)
    {
        record.push_back(f);
        while (record.size() > s.recordSize)
            record.pop_front();
        if (healerManaAfterPct >= Reserve(s))
            confidence = std::min(1.0f, confidence + s.wellDoneGain);
    }

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

    bool ShouldPull(float healerManaPct, Pack const& p, Settings const& s) const
    {
        if (stopped)
            return false;
        return healerManaPct - ExpectedCost(p, s) >= Reserve(s);
    }

    float ClearYards(Settings const& s) const { return s.clearMin + confidence * (s.clearMax - s.clearMin); }
};

}

#endif
