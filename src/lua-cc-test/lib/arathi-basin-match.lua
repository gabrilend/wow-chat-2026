
local Match = {}

Match.WIN         = 1600
Match.INTERIM     = 60
Match.HOMES       = { "north-west home", "south-east home" }
Match.DEFAULTS    = { interim_players = "stay" }

function Match.new(draw, opts)
    local pick = draw and draw(2) or 1
    local homes = (pick == 1) and { alliance = Match.HOMES[1], horde = Match.HOMES[2] }
                               or { alliance = Match.HOMES[2], horde = Match.HOMES[1] }
    return { homes = homes, score = { alliance = 0, horde = 0 }, winner = nil, ended_at = nil,
             opts = opts or {}, number = 1 }
end

function Match.add_score(m, side, amount, t)
    if m.winner then return m.winner end
    m.score[side] = math.min(Match.WIN, m.score[side] + amount)
    if m.score[side] >= Match.WIN then m.winner, m.ended_at = side, t end
    return m.winner
end

function Match.next(m, t, draw)
    if not m.winner or t < m.ended_at + Match.INTERIM then return nil end
    local nm = Match.new(draw, m.opts)
    nm.number = m.number + 1
    local where = (m.opts.interim_players or Match.DEFAULTS.interim_players) == "out" and "invited back" or "stayed in"
    return nm, where
end

return Match
