/*
 * buddies_sidestep.cpp - in a fight, a buddy steps round its target right
 * after casting an instant spell (issue 617s5).
 *
 * For a general audience: the owner (2026-10-04): a buddy moves round its
 * target "inbetween a spellcast, when they're casting an instant spell".
 * When a buddy in a fight casts a spell with no cast time, it is given one
 * step along the circle round its target at its present distance (the size
 * by buddies_sidestep.h's two answers), onto the navigation mesh; a step
 * the mesh refuses is tried the other way round, then skipped. Getting out
 * of known dangers stays the bot module's.
 *
 * Switch: Buddies.Sidestep (0 off, the default; 1 a share of the circle,
 * 2 by distance: the owner's two answers, for the owner to choose).
 */

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
    // {{{ the numbers
    // EVERY_MS: at most one sidestep a buddy this often (a run of instants
    //           shouldn't make it dance).
    // SNAP_YARDS, SNAP_RISE: how far a step may be moved onto the mesh.
    constexpr uint64 EVERY_MS   = 1500;
    constexpr float  SNAP_YARDS = 2.0f;
    constexpr float  SNAP_RISE  = 4.0f;
    // }}}

    // {{{ local function IsBuddy()
    bool IsBuddy(uint32 guid)
    {
        for (auto const& pair : BuddyRosterPairs())
            if (pair.first == guid)
                return true;
        return false;
    }
    // }}}

    // {{{ buddies_sidestep_player
    class buddies_sidestep_player : public PlayerScript
    {
    public:
        buddies_sidestep_player() : PlayerScript("buddies_sidestep_player", { PLAYERHOOK_ON_SPELL_CAST }) { }

        void OnPlayerSpellCast(Player* player, Spell* spell, bool /*skipCheck*/) override
        {
            int how = sConfigMgr->GetOption<int32>("Buddies.Sidestep", 0);
            if (how != 1 && how != 2)
                return;                                // off
            // each filter, and what failing it means:
            //   a buddy, fighting      - players and peace are left alone
            //   an instant, not channelled - a cast with a cast time must stand
            //   a target to circle     - nothing to step round
            //   not too soon           - at most one step every EVERY_MS
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
                // refused by the mesh: the other way round, then nothing
            }
        }

    private:
        std::unordered_map<uint32, uint64> _last;      // buddy guid -> its last sidestep
    };
    // }}}
}

// {{{ AddSC_buddies_sidestep
void AddSC_buddies_sidestep()
{
    new buddies_sidestep_player();
}
// }}}
