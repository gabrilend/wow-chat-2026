
#include "buddies.h"
#include "buddies_steer.h"
#include "buddies_navmesh.h"
#include "Creature.h"
#include "GameTime.h"
#include "MotionMaster.h"
#include "MoveSpline.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldSession.h"
#include <algorithm>
#include <cmath>
#include <mutex>
#include <unordered_map>

float BuddySteerFacing(float from, float to, uint32 elapsedMs)
{
    float const tau  = 2.0f * float(M_PI);
    float delta      = std::fmod(to - from + float(M_PI), tau);
    if (delta < 0.0f)
        delta += tau;
    delta -= float(M_PI);
    float share = std::min(1.0f, float(elapsedMs) / float(BUDDY_TURN_MS));
    float out   = std::fmod(from + delta * share, tau);
    return out < 0.0f ? out + tau : out;
}

BuddyRoam::Point BuddySteerEdge(BuddyRoam::Point const& centre, BuddyRoam::Point const& from, float radius)
{
    float dx = from.x - centre.x, dy = from.y - centre.y;
    float d  = std::hypot(dx, dy);
    if (d < 0.01f)
        return { centre.x + radius, centre.y, centre.z };
    return { centre.x + dx / d * radius, centre.y + dy / d * radius, centre.z };
}

float BuddyNoticeRadius(Creature const* monster, Player const* bot)
{
    return monster->GetAggroRange(bot);
}

static constexpr uint32 ARC_BENDS     = 4;
static constexpr float  ARC_SNAP      = 1.5f;
struct Turn
{
    bool   inPlace = true;
    float  from = 0.0f, to = 0.0f;
    uint64 began = 0, until = 0;
};
static std::mutex sTurnLock;
static std::unordered_map<uint32, Turn> sTurns;

static uint64 NowMs() { return uint64(GameTime::GetGameTimeMS().count()); }

bool BuddyTurnBusy(Player const* bot)
{
    std::lock_guard<std::mutex> lock(sTurnLock);
    auto it = sTurns.find(bot->GetGUID().GetCounter());
    return it != sTurns.end() && NowMs() < it->second.until;
}

static float Delta(float a, float b)
{
    float const tau = 2.0f * float(M_PI);
    float d = std::fmod(b - a + float(M_PI), tau);
    if (d < 0.0f)
        d += tau;
    return d - float(M_PI);
}

bool BuddyTurnToward(Player* bot, float want)
{
    if (BuddyTurnBusy(bot))
        return true;
    float from = bot->GetOrientation();
    float d    = Delta(from, want);
    if (std::fabs(d) < BUDDY_TURN_MIN)
        return false;
    uint64 now = NowMs();
    Turn t;
    t.from = from, t.to = want, t.began = now, t.until = now + BUDDY_TURN_MS;

    if (!bot->movespline->Finalized())
    {
        float speed = bot->GetSpeed(bot->IsWalking() ? MOVE_WALK : MOVE_RUN);
        float step  = speed * float(BUDDY_TURN_MS) / 1000.0f / float(ARC_BENDS);
        Movement::PointsArray arc;
        BuddyRoam::Point at { bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ() };
        arc.push_back(G3D::Vector3(at.x, at.y, at.z));
        bool clear = true;
        for (uint32 k = 1; k <= ARC_BENDS && clear; ++k)
        {
            float h = from + d * float(k) / float(ARC_BENDS);
            BuddyRoam::Point next { at.x + std::cos(h) * step, at.y + std::sin(h) * step, at.z }, onMesh;
            clear = BuddyMeshSnap(bot->GetMap(), next, ARC_SNAP, 3.0f, onMesh) &&
                    BuddyMeshLineClear(bot->GetMap(), at, onMesh);
            at = onMesh;
            arc.push_back(G3D::Vector3(at.x, at.y, at.z));
        }
        if (clear)
        {
            t.inPlace = false;
            bot->GetMotionMaster()->MoveSplinePath(&arc);
            BuddyTrace(bot, "turn: {:.0f} degrees while moving, along a curve of {:.1f} yards",
                std::fabs(d) * 180.0f / float(M_PI), step * float(ARC_BENDS));
        }
        else
        {
            bot->StopMoving();
            BuddyTrace(bot, "turn: {:.0f} degrees; the curve would leave the mesh, so stopped to turn in place",
                std::fabs(d) * 180.0f / float(M_PI));
        }
    }
    else
        BuddyTrace(bot, "turn: {:.0f} degrees in place before setting off", std::fabs(d) * 180.0f / float(M_PI));

    std::lock_guard<std::mutex> lock(sTurnLock);
    sTurns[bot->GetGUID().GetCounter()] = t;
    return true;
}

class buddies_steer_player : public PlayerScript
{
public:
    buddies_steer_player() : PlayerScript("buddies_steer_player", { PLAYERHOOK_ON_UPDATE }) { }

    void OnPlayerUpdate(Player* player, uint32 ) override
    {
        if (!BuddiesEnabled() || !player->GetSession()->IsHeadless())
            return;
        float face = 0.0f;
        {
            std::lock_guard<std::mutex> lock(sTurnLock);
            auto it = sTurns.find(player->GetGUID().GetCounter());
            if (it == sTurns.end())
                return;
            Turn const t = it->second;
            uint64 now = NowMs();
            if (now >= t.until)
                sTurns.erase(it);
            if (!t.inPlace)
                return;
            face = BuddySteerFacing(t.from, t.to, uint32(std::min<uint64>(now - t.began, BUDDY_TURN_MS)));
        }
        if (std::fabs(Delta(player->GetOrientation(), face)) > 0.01f)
            player->SetFacingTo(face);
    }
};

void AddSC_buddies_steer()
{
    new buddies_steer_player();
}
