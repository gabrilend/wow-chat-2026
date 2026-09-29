--------------------------------------------------------------------------------
-- world-boss-countdown.lua (issue 155j)
--
-- When a dead world boss is due back. Pure arithmetic, no server calls:
-- src/lua-basic/world-boss-respawn.lua runs it on the server, and
-- scripts/test-world-boss-countdown runs it offline.
--
-- The owner's rule (2026-09-27): a 2.5-hour respawn "with a 2.5 hour minimum
-- for nobody there, cumulatively built up by depositing 'moment tokens' for
-- each player there, multiplied by 100 to transfer the percent", with the
-- style note "I prefer adding a variable amount of number increments, once
-- per pass through a thing". So the countdown is two counters, each bumped
-- once per pass:
--   elapsed  seconds since the boss died (+5 each pass)
--   tokens   moment tokens (+1 per player present in the boss's area, each
--            pass)
-- and the boss is due when elapsed has reached 2.5 hours plus what the tokens
-- are worth: each token 1% of a pass (5 s / 100). One player present the
-- whole time: due at about 2 h 31.5 min; 50: 5 hours; 100 or more: never
-- (each pass then adds as much wait as it counts down).
--------------------------------------------------------------------------------

local Countdown = {}

Countdown.PASS_SECONDS  = 5       -- one pass of the countdown ("5s or so")
Countdown.BASE_SECONDS  = 9000    -- 2.5 hours: the wait with nobody there
Countdown.TOKEN_PERCENT = 1       -- each moment token holds the boss back this % of a pass

-- {{{ function Countdown.pass
-- One pass: time moves on by a pass, and every player present deposits a
-- moment token. players: whole number >= 0. Returns elapsed, tokens.
function Countdown.pass(elapsed, tokens, players)
    return elapsed + Countdown.PASS_SECONDS, tokens + players
end
-- }}}

-- {{{ function Countdown.held_back
-- Seconds the deposited tokens add to the wait. The one line that says what
-- a token is worth: a pass's seconds x the token's percent / 100.
function Countdown.held_back(tokens)
    return tokens * Countdown.PASS_SECONDS * Countdown.TOKEN_PERCENT / 100
end
-- }}}

-- {{{ function Countdown.due
-- Whether the boss is due back: the base wait and the tokens' worth both
-- reached. (An earlier reading divided each pass by 1 + 0.01 x players,
-- which made 100 players wait 5 hours; the owner chose the tokens, which
-- make 100 players wait forever.)
function Countdown.due(elapsed, tokens)
    return elapsed >= Countdown.BASE_SECONDS + Countdown.held_back(tokens)
end
-- }}}

return Countdown
