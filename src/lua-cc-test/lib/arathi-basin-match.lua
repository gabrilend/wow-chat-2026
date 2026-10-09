--------------------------------------------------------------------------------
-- arathi-basin-match.lua (issue 176a2a) - a match's beginning, end and the
-- minute between
--
-- For a general audience: a match starts the moment one person queues;
-- each one draws which side starts in the north-west (Trollbane Hall) and
-- which in the south-east (the Defiler's Den), so neither faction always
-- has the same corner (owner, 2026-10-08: "we should make the horde and
-- alliance spawn at a random side each time"); the first side to 1,600
-- resources wins; one minute later a fresh match starts in the same place
-- ("an interim of 1 minute maybe"). Plain data: the draw takes a function
-- returning 1 or 2, so a test or a sealed scene can fix it.
--
-- Open choice, both built (the report compares them):
--   opts.interim_players  "stay" | "out" (176a2a question 1): during the
--                         minute, players stay in the instance, or are sent
--                         out and invited back to the next match
--------------------------------------------------------------------------------

local Match = {}

Match.WIN         = 1600                            -- BG_AB_MAX_TEAM_SCORE
Match.INTERIM     = 60                              -- seconds between matches
Match.HOMES       = { "north-west home", "south-east home" }
Match.DEFAULTS    = { interim_players = "stay" }

-- {{{ function Match.new
-- A fresh match: homes drawn (draw(2) == 1: the alliance in the
-- north-west), scores at zero.
function Match.new(draw, opts)
    local pick = draw and draw(2) or 1
    local homes = (pick == 1) and { alliance = Match.HOMES[1], horde = Match.HOMES[2] }
                               or { alliance = Match.HOMES[2], horde = Match.HOMES[1] }
    return { homes = homes, score = { alliance = 0, horde = 0 }, winner = nil, ended_at = nil,
             opts = opts or {}, number = 1 }
end
-- }}}

-- {{{ function Match.add_score
-- Resources for a side at time `t` (seconds); the first to 1,600 wins and
-- the match ends there. Returns the winner once it has one.
function Match.add_score(m, side, amount, t)
    if m.winner then return m.winner end
    m.score[side] = math.min(Match.WIN, m.score[side] + amount)
    if m.score[side] >= Match.WIN then m.winner, m.ended_at = side, t end
    return m.winner
end
-- }}}

-- {{{ function Match.next
-- At time `t`: nil while the match runs or the minute isn't over; once it
-- is, the next match (homes drawn again, scores zero, the same options),
-- and where the players are meanwhile ("stay": in the instance; "out":
-- sent out, invited back now).
function Match.next(m, t, draw)
    if not m.winner or t < m.ended_at + Match.INTERIM then return nil end
    local nm = Match.new(draw, m.opts)
    nm.number = m.number + 1
    local where = (m.opts.interim_players or Match.DEFAULTS.interim_players) == "out" and "invited back" or "stayed in"
    return nm, where
end
-- }}}

return Match
