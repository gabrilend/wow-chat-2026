/*
 * mod-talent-bonus
 *
 * Adds bonus talent points at 33% and 66% XP progress within each level.
 * This hooks into the server's talent point calculation so the bonus points
 * are included in validation, preventing talent resets on login.
 *
 * Issue 120: talent-points-level-20-cap
 *
 * How it works:
 * - Server calls CalculateTalentsPoints() on login/levelup
 * - This hook adds +1 at 33% XP, +1 at 66% XP to the calculated total
 * - Server validates usedTalents <= expectedTalents (now includes our bonus)
 * - No talent reset occurs because our bonus is part of the expected count
 *
 * The Lua script (levelling.lua) handles:
 * - Awarding the actual talent points when thresholds are crossed
 * - Playing the green visual effect
 * - Tracking which thresholds have been awarded this level
 */

#include "ScriptMgr.h"
#include "Player.h"

// {{{ Configuration
constexpr float THRESHOLD_33 = 0.33f;
constexpr float THRESHOLD_66 = 0.66f;
// }}}

// {{{ TalentBonusScript
class TalentBonusScript : public PlayerScript
{
public:
    TalentBonusScript() : PlayerScript("TalentBonusScript") { }

    // {{{ OnPlayerCalculateTalentsPoints
    // Called when server calculates expected talent points.
    // We add bonus points for XP thresholds so validation includes them.
    void OnPlayerCalculateTalentsPoints(Player const* player, uint32& talentPointsForLevel) override
    {
        uint32 xpToLevel = player->GetUInt32Value(PLAYER_NEXT_LEVEL_XP);
        if (xpToLevel == 0)
            return;

        float progress = static_cast<float>(player->GetXP()) / static_cast<float>(xpToLevel);

        // Add bonus points based on XP progress
        if (progress >= THRESHOLD_33)
            talentPointsForLevel += 1;

        if (progress >= THRESHOLD_66)
            talentPointsForLevel += 1;
    }
    // }}}
};
// }}}

// {{{ Script Registration
void AddTalentBonusScripts()
{
    new TalentBonusScript();
}
// }}}
