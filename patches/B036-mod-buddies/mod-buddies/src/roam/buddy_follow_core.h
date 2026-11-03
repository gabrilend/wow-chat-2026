
#ifndef BUDDY_FOLLOW_CORE_H
#define BUDDY_FOLLOW_CORE_H

#include "buddy_roam_core.h"
#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdint>
#include <deque>
#include <string>
#include <vector>

namespace BuddyFollow
{
using BuddyRoam::Point;

struct Settings
{
    float    trailStep    = 2.0f;
    uint32_t trailKeep    = 150;
    float    side         = 1.0f;
    float    nearBack     = 1.0f;
    float    farBack      = 2.0f;
    float    ringYards    = 5.0f;
    float    ringStep     = 5.0f;
    float    ringMost     = 25.0f;
    float    ringSlack    = 1.5f;
    float    restYards    = 10.0f;
    float    arriveYards  = 1.0f;
    double   mingleChance = 0.10;
    uint32_t mingleEvery  = 5000;
    float    mingleYards  = 3.0f;
    float    narrowYards  = 1.5f;
    float    columnSpacing = 2.5f;
    std::vector<int> layerSizes = { 3, 2, 2 };
    float    layerStep    = 1.5f;
};

struct Trail
{
    std::deque<Point> points;

    void Add(Point const& at, Settings const& s, float jump = 40.0f)
    {
        if (!points.empty())
        {
            Point const& last = points.back();
            float d = std::hypot(at.x - last.x, at.y - last.y);
            if (d > jump)
                points.clear();
            else if (d < s.trailStep)
                return;
        }
        points.push_back(at);
        while (points.size() > s.trailKeep)
            points.pop_front();
    }
};

inline std::vector<float> Offsets(int n)
{
    switch (n)
    {
        case 0:  return {};
        case 1:  return { -1.0f };
        case 2:  return { -1.0f, 1.0f };
        case 3:  return { -1.0f, 0.0f, 1.0f };
        case 4:  return { -1.0f, -0.5f, 0.5f, 1.0f };
        case 5:  return { -1.0f, -0.5f, 0.0f, 0.5f, 1.0f };
        default: break;
    }
    std::vector<float> out;
    for (int k = 0; k < n; ++k)
        out.push_back(-1.0f + 2.0f * float(k) / float(n - 1));
    return out;
}

struct ArcSpot
{
    float lateral   = 0.0f;
    float extraBack = 0.0f;
};

inline std::vector<ArcSpot> ArcSpots(int n, Settings const& s)
{
    std::vector<ArcSpot> out;
    if (n <= 5)
    {
        for (float lateral : Offsets(n))
            out.push_back({ lateral, 0.0f });
        return out;
    }
    int layer = 0;
    while (int(out.size()) < n)
    {
        int want = s.layerSizes.empty() ? 3
                 : s.layerSizes[std::min<size_t>(size_t(layer), s.layerSizes.size() - 1)];
        int m = std::min(std::max(want, 1), n - int(out.size()));
        for (int i = 0; i < m; ++i)
        {
            float lateral;
            if (layer == 0)
                lateral = m == 1 ? 0.0f : -1.0f + 2.0f * float(i) / float(m - 1);
            else
                lateral = -1.0f + 2.0f * (float(i) + 0.5f) / float(m);
            out.push_back({ lateral, float(layer) * s.layerStep });
        }
        ++layer;
    }
    return out;
}

struct Place
{
    Point at;
    float facing = 0.0f;
};

inline Place PlaceFor(Trail const& trail, Point const& owner, float ownerFacing, float lateral, Settings const& s,
                      float extraBack = 0.0f)
{
    float back = s.nearBack + (s.farBack - s.nearBack) * (1.0f - std::fabs(lateral)) + extraBack;
    Point from = owner, at = owner;
    float dirX = -std::cos(ownerFacing), dirY = -std::sin(ownerFacing);
    float left = back;
    bool found = false;
    for (auto it = trail.points.rbegin(); it != trail.points.rend(); ++it)
    {
        float dx = it->x - from.x, dy = it->y - from.y;
        float d = std::hypot(dx, dy);
        if (d < 1e-4f)
            continue;
        if (d >= left)
        {
            at   = { from.x + dx / d * left, from.y + dy / d * left, from.z + (it->z - from.z) * (left / d) };
            dirX = dx / d;
            dirY = dy / d;
            found = true;
            break;
        }
        left -= d;
        from  = *it;
        dirX  = dx / d;
        dirY  = dy / d;
    }
    if (!found)
        at = { from.x + dirX * left, from.y + dirY * left, from.z };
    float fx = -dirX, fy = -dirY;
    float side = lateral * s.side;
    Place p;
    p.at     = { at.x - fy * side, at.y + fx * side, at.z };
    p.facing = std::atan2(owner.y - p.at.y, owner.x - p.at.x);
    return p;
}

inline std::vector<Place> Places(Trail const& trail, Point const& owner, float ownerFacing, int n, Settings const& s)
{
    std::vector<Place> out;
    for (ArcSpot const& a : ArcSpots(n, s))
        out.push_back(PlaceFor(trail, owner, ownerFacing, a.lateral, s, a.extraBack));
    return out;
}

inline std::vector<Place> ColumnPlaces(Trail const& trail, Point const& owner, float ownerFacing, int n, Settings const& s)
{
    std::vector<Place> out;
    for (int k = 0; k < n; ++k)
    {
        Settings at = s;
        at.farBack = s.farBack + float(k) * s.columnSpacing;
        out.push_back(PlaceFor(trail, owner, ownerFacing, 0.0f, at));
    }
    return out;
}

inline void AssignSearch(std::vector<Point> const& followers, std::vector<Place> const& places, size_t f,
                         std::vector<int>& now, std::vector<bool>& taken, float sum, float& best, std::vector<int>& bestOf)
{
    if (sum >= best)
        return;
    if (f == followers.size())
    {
        best   = sum;
        bestOf = now;
        return;
    }
    bool any = false;
    for (size_t p = 0; p < places.size(); ++p)
    {
        if (taken[p])
            continue;
        any = true;
        taken[p] = true;
        now[f]   = int(p);
        AssignSearch(followers, places, f + 1, now, taken, sum + std::hypot(followers[f].x - places[p].at.x, followers[f].y - places[p].at.y),
                     best, bestOf);
        taken[p] = false;
    }
    if (!any)
    {
        now[f] = -1;
        AssignSearch(followers, places, f + 1, now, taken, sum, best, bestOf);
    }
}

inline std::vector<int> Assign(std::vector<Point> const& followers, std::vector<Place> const& places)
{
    std::vector<int>  now(followers.size(), -1), bestOf(followers.size(), -1);
    std::vector<bool> taken(places.size(), false);
    float best = 1e30f;
    AssignSearch(followers, places, 0, now, taken, 0.0f, best, bestOf);
    return bestOf;
}

enum class Mode : uint8_t { Rest, Follow };
struct State
{
    Mode     mode       = Mode::Follow;
    uint64_t nextLookMs = 0;
};

enum class Act : uint8_t { Walk, Mingle, Face, Nothing };
struct Decision
{
    Act   act = Act::Nothing;
    Point to;
    float facing = 0.0f;
};

inline Decision Decide(State& st, Point const& me, Point const& owner, Place const& place, uint64_t nowMs,
                       double roll, double angle, Settings const& s)
{
    Decision d;
    float toOwner = std::hypot(owner.x - me.x, owner.y - me.y);
    float toPlace = std::hypot(place.at.x - me.x, place.at.y - me.y);
    if (st.mode == Mode::Rest && toOwner > s.restYards)
        st.mode = Mode::Follow;
    if (st.mode == Mode::Follow)
    {
        if (toPlace > s.arriveYards)
        {
            d.act = Act::Walk;
            d.to  = place.at;
            return d;
        }
        st.mode       = Mode::Rest;
        st.nextLookMs = nowMs + s.mingleEvery;
        d.act    = Act::Face;
        d.facing = std::atan2(owner.y - me.y, owner.x - me.x);
        return d;
    }
    if (nowMs < st.nextLookMs)
        return d;
    st.nextLookMs = nowMs + s.mingleEvery;
    if (roll < s.mingleChance)
    {
        float a = float(angle) * 6.2831853f;
        d.act = Act::Mingle;
        d.to  = { place.at.x + std::cos(a) * s.mingleYards, place.at.y + std::sin(a) * s.mingleYards, place.at.z };
        return d;
    }
    d.act    = Act::Face;
    d.facing = std::atan2(owner.y - me.y, owner.x - me.x);
    return d;
}

inline std::vector<Place> RingPlaces(Point const& owner, float ownerFacing, int n, float radius)
{
    std::vector<Place> out;
    for (int i = 0; i < n; ++i)
    {
        float a = ownerFacing + 6.2831853f * float(i) / float(std::max(n, 1));
        Place p;
        p.at     = { owner.x + std::cos(a) * radius, owner.y + std::sin(a) * radius, owner.z };
        p.facing = std::atan2(owner.y - p.at.y, owner.x - p.at.x);
        out.push_back(p);
    }
    return out;
}

inline float RingRadius(float now, bool wider, Settings const& s)
{
    return wider ? std::min(now + s.ringStep, s.ringMost) : s.ringYards;
}

inline std::vector<int> AssignRing(std::vector<Point> const& followers, std::vector<Place> const& places, int tank)
{
    if (tank < 0 || tank >= int(followers.size()) || places.empty())
        return Assign(followers, places);
    std::vector<Point> rest;
    std::vector<int> restIndex;
    for (int i = 0; i < int(followers.size()); ++i)
        if (i != tank) { rest.push_back(followers[size_t(i)]); restIndex.push_back(i); }
    std::vector<Place> others(places.begin() + 1, places.end());
    std::vector<int> sub = Assign(rest, others);
    std::vector<int> out(followers.size(), -1);
    out[size_t(tank)] = 0;
    for (size_t k = 0; k < sub.size(); ++k)
        out[size_t(restIndex[k])] = sub[k] < 0 ? -1 : sub[k] + 1;
    return out;
}

enum class Order : uint8_t { None, Follow, GoAway, Circle };
inline Order ReadOrder(std::string const& raw, std::string& name, bool& hard)
{
    std::string msg = raw;
    while (!msg.empty() && std::isspace(static_cast<unsigned char>(msg.back())))
        msg.pop_back();
    bool bang = !msg.empty() && msg.back() == '!';
    std::transform(msg.begin(), msg.end(), msg.begin(), [](unsigned char c) { return std::isalpha(c) ? char(std::tolower(c)) : ' '; });
    std::vector<std::string> words;
    std::string w;
    for (char c : msg + " ")
    {
        if (c != ' ')
            w += c;
        else if (!w.empty())
        {
            words.push_back(w);
            w.clear();
        }
    }
    words.erase(std::remove(words.begin(), words.end(), "please"), words.end());
    name.clear();
    hard = false;
    if (words.size() == 2 && words[0] == "follow")
    {
        name = words[1] == "me" ? "" : words[1];
        return Order::Follow;
    }
    if (words.size() == 2 && words[0] == "go" && words[1] == "away")
    {
        hard = bang;
        return Order::GoAway;
    }
    if (words.size() == 1 && words[0] == "shoo")
        return Order::GoAway;
    if ((words.size() == 1 && words[0] == "stop")
        || (words.size() == 3 && words[0] == "stop" && words[1] == "following" && words[2] == "me"))
        return Order::GoAway;
    if (words.size() == 2 && ((words[0] == "circle" && words[1] == "me") || (words[0] == "close" && words[1] == "follow")))
        return Order::Circle;
    return Order::None;
}
}

#endif
