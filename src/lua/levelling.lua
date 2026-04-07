-- levelling.lua
-- Awards bonus talent points at 33% and 66% XP progress within each level.
-- The 100% (level-up) talent point is handled by the server's Rate.Talent config.
--
-- Issue 120: talent-points-level-20-cap
--
-- This script works with mod-talent-bonus (C++) which hooks the server's
-- talent point calculation. The C++ module ensures the server EXPECTS our
-- bonus points during validation, preventing talent resets on login.
--
-- Division of labor:
-- - C++ (mod-talent-bonus): Modifies expected talent count for validation
-- - Lua (this file): Awards actual points with visual effect when threshold crossed
--
-- Visual: Green "reputation level gained" effect at 33%/66%
-- Visual: Yellow level-up effect at 100% (normal game behavior)

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
-- Called on login. Sets tracking flags based on current XP progress.
-- The C++ module (mod-talent-bonus) handles validation, so we don't need
-- to re-add points here. We just need to mark which thresholds are "spent"
-- so we don't double-award when the player gains more XP.
local function onLogin(event, player)
    local level = player:GetLevel()
    local currentXP = player:GetXP()
    local xpToLevel = player:GetUInt32Value(36) -- PLAYER_NEXT_LEVEL_XP = 36

    if xpToLevel <= 0 then return end

    local progress = currentXP / xpToLevel

    -- Mark thresholds as already awarded based on current XP position
    if progress >= THRESHOLD_33 then
        player:SetData(getThresholdKey(level, THRESHOLD_33), true)
    end

    if progress >= THRESHOLD_66 then
        player:SetData(getThresholdKey(level, THRESHOLD_66), true)
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
