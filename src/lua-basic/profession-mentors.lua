--------------------------------------------------------------------------------
-- profession-mentors.lua (issue 155e1, with 155p1's eccentric visitor)
--
-- The Profession Mentors (install step E068: creatures 1550031-1550038, one
-- per capital that lacks a profession's trainer) are visitors from afar,
-- "so happy to be there that once every hour at a random time +/- 30
-- minutes, they'll dance for a minute, then go back to standing around
-- learning" (the owner, 2026-10-13, of the eccentric jewelcrafter the
-- mentor became on 2026-10-22). This script gives each mentor that habit:
-- when it is added to the world it waits 30 to 90 minutes, dances for a
-- minute, and starts waiting again.
--------------------------------------------------------------------------------

local MENTOR_FIRST, MENTOR_LAST = 1550031, 1550038   -- E068's creature_template entries
local CREATURE_EVENT_ON_ADD     = 36                  -- mod-ale Hooks.h: (event, creature), when it enters the world
local EMOTE_STATE_DANCE         = 10                  -- SharedDefines.h: EMOTE_STATE_DANCE, held until changed
local EMOTE_STATE_NONE          = 0
local WAIT_MIN_MS, WAIT_MAX_MS  = 30 * 60 * 1000, 90 * 60 * 1000   -- "every hour ... +/- 30 minutes"
local DANCE_MS                  = 60 * 1000                         -- "dance for a minute"

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

for entry = MENTOR_FIRST, MENTOR_LAST do
    RegisterCreatureEvent(entry, CREATURE_EVENT_ON_ADD, function(_, creature) wait_then_dance(creature) end)
end
