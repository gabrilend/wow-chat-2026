
local Countdown = {}

Countdown.PASS_SECONDS  = 5
Countdown.BASE_SECONDS  = 9000
Countdown.TOKEN_PERCENT = 1

function Countdown.pass(elapsed, tokens, players)
    return elapsed + Countdown.PASS_SECONDS, tokens + players
end

function Countdown.held_back(tokens)
    return tokens * Countdown.PASS_SECONDS * Countdown.TOKEN_PERCENT / 100
end

function Countdown.due(elapsed, tokens)
    return elapsed >= Countdown.BASE_SECONDS + Countdown.held_back(tokens)
end

return Countdown
