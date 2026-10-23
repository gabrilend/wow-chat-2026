--------------------------------------------------------------------------------
-- profession-mentors.lua (issue 155e1, with 155p1's eccentric visitor)
--
-- The Profession Mentors (install step E068: creatures 1550031-1550038, one
-- per capital that lacks a profession's trainer) are visitors from afar.
-- One of them dances: the goblin in Thunder Bluff (capital 6 in the
-- generator's list, creature 1550036). The owner, 2026-10-13, of the
-- eccentric visitor: "so happy to be there that once every hour at a random
-- time +/- 30 minutes, they'll dance for a minute, then go back to
-- standing around learning"; then, 2026-10-22: "only the goblin trainer
-- dances. And he dances for a set amount of time each time." So: he waits
-- 30 to 90 minutes, dances for exactly a minute, and waits again.
--------------------------------------------------------------------------------

local DANCER                    = 1550036             -- E068: 1550030 + Thunder Bluff's number (6) in the generator's capital list
local CREATURE_EVENT_ON_ADD     = 36                  -- mod-ale Hooks.h: (event, creature), when it enters the world
local EMOTE_STATE_DANCE         = 10                  -- SharedDefines.h: EMOTE_STATE_DANCE, held until changed
local EMOTE_STATE_NONE          = 0
local WAIT_MIN_MS, WAIT_MAX_MS  = 30 * 60 * 1000, 90 * 60 * 1000   -- "every hour ... +/- 30 minutes"
local DANCE_MS                  = 60 * 1000                         -- "a set amount of time each time": always a minute

local wait_then_dance

-- {{{ local function dance
-- Dance now, stop a minute later, then wait again. Events registered on a
-- creature end with it (a despawn or a grid unload drops them), and its
-- next add to the world starts the wait afresh, so nothing piles up.
local function dance(_, _, _, creature)
    creature:EmoteState(EMOTE_STATE_DANCE)
    creature:RegisterEvent(function(_, _, _, c)
        c:EmoteState(EMOTE_STATE_NONE)
        wait_then_dance(c)
    end, DANCE_MS, 1)
end
-- }}}

-- {{{ wait_then_dance
wait_then_dance = function(creature)
    creature:RegisterEvent(dance, math.random(WAIT_MIN_MS, WAIT_MAX_MS), 1)
end
-- }}}

RegisterCreatureEvent(DANCER, CREATURE_EVENT_ON_ADD, function(_, creature) wait_then_dance(creature) end)
