
#include "buddies_sidestep.h"
#include "buddies_navmesh.h"
#include "buddies_roam.h"
#include "Config.h"
#include "GameTime.h"
#include "MotionMaster.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellInfo.h"
#include <unordered_map>

namespace
{
    constexpr uint64 EVERY_MS   = 1500;
    constexpr float  SNAP_YARDS = 2.0f;
    constexpr float  SNAP_RISE  = 4.0f;

    bool IsBuddy(uint32 guid)
    {
        for (auto const& pair : BuddyRosterPairs())
            if (pair.first == guid)
                return true;
        return false;
    }

    class buddies_sidestep_player : public PlayerScript
    {
    public:
        buddies_sidestep_player() : PlayerScript("buddies_sidestep_player", { PLAYERHOOK_ON_SPELL_CAST }) { }

        void OnPlayerSpellCast(Player* player, Spell* spell, bool ) override
        {
            int how = sConfigMgr->GetOption<int32>("Buddies.Sidestep", 0);
            if (how != 1 && how != 2)
                return;
            if (!player->IsInCombat() || !IsBuddy(player->GetGUID().GetCounter()))
                return;
            if (spell->GetCastTime() > 0 || spell->GetSpellInfo()->IsChanneled())
                return;
            Unit* target = player->GetVictim();
            if (!target || target == player)
                return;
            uint64 now = GameTime::GetGameTimeMS().count();
            uint64& last = _last[player->GetGUID().GetCounter()];
            if (now - last < EVERY_MS)
                return;
            last = now;

            bool melee = PlayerbotAI::IsMelee(player);
            float u1 = float(rand_norm()), u2 = float(rand_norm());
            for (int tries = 0; tries < 2; ++tries)
            {
                BuddySidestep::Spot s = BuddySidestep::Step(player->GetPositionX(), player->GetPositionY(),
                    target->GetPositionX(), target->GetPositionY(), melee, how, u1, tries == 0 ? u2 : 1.0f - u2);
                BuddyRoam::Point onMesh;
                if (BuddyMeshSnap(player->GetMap(), { s.x, s.y, player->GetPositionZ() }, SNAP_YARDS, SNAP_RISE, onMesh))
                {
                    player->GetMotionMaster()->MovePoint(0, onMesh.x, onMesh.y, onMesh.z);
                    return;
                }
            }
        }

    private:
        std::unordered_map<uint32, uint64> _last;
    };
}

void AddSC_buddies_sidestep()
{
    new buddies_sidestep_player();
}
