-- levelling.lua
-- Awards bonus talent points at 33% and 66% XP progress within each level.
-- The normal 100% (level-up) talent point is handled by the server's Rate.Talent config.
--
-- Issue 120: talent-points-level-20-cap
--
-- Visual: Uses green "reputation level gained" effect for mid-level talent gains.
-- The yellow level-up effect at 100% is the normal game behavior.

-- {{{ Configuration
local THRESHOLD_33 = 0.33
local THRESHOLD_66 = 0.66

-- SMSG_SET_FACTION_STANDING opcode for green "level up" visual
local SMSG_SET_FACTION_STANDING = 0x124
-- }}}

-- {{{ sendGreenLevelUpEffect
-- Sends the green "reputation level gained" visual effect to the player.
-- Uses a minimal SMSG_SET_FACTION_STANDING packet with the visual flag set.
local function sendGreenLevelUpEffect(player)
    -- Packet structure:
    -- float  - bonus (0)
    -- uint8  - show visual effect (1 = show green animation)
    -- uint32 - faction count (0 = no actual reputation changes)
    local packet = CreatePacket(SMSG_SET_FACTION_STANDING, 9)
    packet:WriteFloat(0)     -- bonus modifier
    packet:WriteUByte(1)     -- show visual effect flag
    packet:WriteULong(0)     -- zero faction updates
    player:SendPacket(packet)
end
-- }}}

-- {{{ awardMidLevelTalent
-- Awards a talent point and shows the green visual effect.
local function awardMidLevelTalent(player, threshold)
    player:SetFreeTalentPoints(player:GetFreeTalentPoints() + 1)
    sendGreenLevelUpEffect(player)

    local percent = math.floor(threshold * 100)
    player:SendBroadcastMessage("You feel more capable. +1 talent point (" .. percent .. "%)")
end
-- }}}

-- {{{ getThresholdKey
-- Returns a unique key for tracking if a threshold was already awarded this level.
local function getThresholdKey(level, threshold)
    return "talent_" .. level .. "_" .. math.floor(threshold * 100)
end
-- }}}

-- {{{ onGiveXP
-- Called when player gains XP. Checks if they crossed 33% or 66% threshold.
local function onGiveXP(event, player, amount, victim)
    local level = player:GetLevel()
    local currentXP = player:GetXP()
    local xpToLevel = player:GetUInt32Value(36) -- PLAYER_NEXT_LEVEL_XP = 36

    if xpToLevel <= 0 then return end

    local progress = currentXP / xpToLevel

    -- Check 33% threshold
    local key33 = getThresholdKey(level, THRESHOLD_33)
    if progress >= THRESHOLD_33 and not player:GetData(key33) then
        player:SetData(key33, true)
        awardMidLevelTalent(player, THRESHOLD_33)
    end

    -- Check 66% threshold
    local key66 = getThresholdKey(level, THRESHOLD_66)
    if progress >= THRESHOLD_66 and not player:GetData(key66) then
        player:SetData(key66, true)
        awardMidLevelTalent(player, THRESHOLD_66)
    end
end
-- }}}

-- {{{ onLevelChange
-- Called when player levels up. Clears threshold tracking for the new level.
-- The actual talent point for leveling is handled by server's Rate.Talent config.
local function onLevelChange(event, player, oldLevel)
    local newLevel = player:GetLevel()

    -- Clear threshold flags for the new level (they start fresh)
    player:SetData(getThresholdKey(newLevel, THRESHOLD_33), nil)
    player:SetData(getThresholdKey(newLevel, THRESHOLD_66), nil)
end
-- }}}

-- {{{ onLogin
-- Called on login. Restores bonus talent points based on current XP progress.
--
-- The server's InitTalentForLevel() resets FreeTalentPoints to the base calculation
-- BEFORE this hook fires. We need to re-add bonus points for any thresholds
-- the player has already passed.
--
-- Example: Player at 50% XP should have +1 bonus (passed 33%, not 66%)
-- Example: Player at 80% XP should have +2 bonus (passed both 33% and 66%)
local function onLogin(event, player)
    local level = player:GetLevel()
    local currentXP = player:GetXP()
    local xpToLevel = player:GetUInt32Value(36) -- PLAYER_NEXT_LEVEL_XP = 36

    if xpToLevel <= 0 then return end

    local progress = currentXP / xpToLevel
    local bonusPoints = 0

    -- Calculate bonus points based on current XP progress
    -- Also set tracking flags so we don't double-award on next XP gain
    if progress >= THRESHOLD_33 then
        bonusPoints = bonusPoints + 1
        player:SetData(getThresholdKey(level, THRESHOLD_33), true)
    end

    if progress >= THRESHOLD_66 then
        bonusPoints = bonusPoints + 1
        player:SetData(getThresholdKey(level, THRESHOLD_66), true)
    end

    -- Re-add bonus points that the server's InitTalentForLevel() removed
    if bonusPoints > 0 then
        player:SetFreeTalentPoints(player:GetFreeTalentPoints() + bonusPoints)
    end
end
-- }}}

-- {{{ Event Registration
local PLAYER_EVENT_ON_GIVE_XP      = 12
local PLAYER_EVENT_ON_LEVEL_CHANGE = 13
local PLAYER_EVENT_ON_LOGIN        = 3

RegisterPlayerEvent(PLAYER_EVENT_ON_GIVE_XP,      onGiveXP)
RegisterPlayerEvent(PLAYER_EVENT_ON_LEVEL_CHANGE, onLevelChange)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN,        onLogin)
-- }}}
