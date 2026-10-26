
local DANCER                    = 1550036
local CREATURE_EVENT_ON_ADD     = 36
local EMOTE_STATE_DANCE         = 10
local EMOTE_STATE_NONE          = 0
local WAIT_MIN_MS, WAIT_MAX_MS  = 30 * 60 * 1000, 90 * 60 * 1000
local DANCE_MS                  = 60 * 1000

local wait_then_dance

local function dance(_, _, _, creature)
    creature:EmoteState(EMOTE_STATE_DANCE)
    creature:RegisterEvent(function(_, _, _, c)
        c:EmoteState(EMOTE_STATE_NONE)
        wait_then_dance(c)
    end, DANCE_MS, 1)
end

wait_then_dance = function(creature)
    creature:RegisterEvent(dance, math.random(WAIT_MIN_MS, WAIT_MAX_MS), 1)
end

RegisterCreatureEvent(DANCER, CREATURE_EVENT_ON_ADD, function(_, creature) wait_then_dance(creature) end)
