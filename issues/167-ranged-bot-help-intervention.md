# 167 - Ranged Bot "Help!" Behavior with Melee Intervention

## Status
- Created: 2026-04-06
- Phase: 2
- Priority: Medium
- Depends: 161 (bot wandering and combat repositioning)

## Current Behavior
- Ranged bots kite backward when enemies get close (per issue 161)
- No communication between ranged and melee bots about threats
- Ranged bots handle threats alone through kiting
- Melee bots continue attacking their current target

## Intended Behavior
When a ranged bot is overwhelmed (enemy too close, can't kite), it should "call for help"
and nearby melee bots should intervene by intercepting the threat.

### Help Conditions
Ranged bot calls for help when:
1. Enemy within 5 yards (melee range)
2. Kiting failed (wall, water, or terrain blocked retreat)
3. Multiple enemies closing in (2+ enemies within 10 yards)

### Intervention Behavior
Melee bot responds when:
1. Ranged bot calls for help within 30 yards
2. Melee bot is not currently tanking (no aggro on self)
3. Melee bot has taunt or intercept ability available

**Intervention priority:**
1. Taunt the threat off the ranged bot
2. Move between threat and ranged bot (body block)
3. Attack the threat to generate aggro

### Communication Flow
```
┌─────────────────────────────────────────────────────────────┐
│                    RANGED BOT                                │
│  - Check: enemy within 5 yards AND kite failed?             │
│  - Broadcast: "HELP" signal with threat GUID                 │
│  - Continue: attack while waiting for help                   │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ broadcast to party/nearby bots
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    MELEE BOT                                 │
│  - Receive: "HELP" signal                                    │
│  - Check: am I in range? am I tanking?                       │
│  - Respond: intercept and taunt threat                       │
│  - Resume: previous target after ranged is safe              │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Steps

### Step 1: Add help signal to SetData
```lua
-- Ranged bot sets when overwhelmed
bot:SetData("help_threat", threatGUID)
bot:SetData("help_time", GetGameTime())
```

### Step 2: Melee bot periodic scan
```lua
-- {{{ BotCombat.checkForHelpCalls
-- Melee bot scans for nearby ranged bots needing help
function BotCombat.checkForHelpCalls(bot)
    if not BotCombat.isMelee(bot) then return nil end
    if bot:IsTanking() then return nil end  -- already busy

    local nearby = bot:GetPlayersInRange(30)
    for _, other in ipairs(nearby) do
        if other:IsBot() and BotCombat.isRanged(other) then
            local threatGUID = other:GetData("help_threat")
            local helpTime = other:GetData("help_time") or 0

            -- Help call is fresh (within 5 seconds)
            if threatGUID and (GetGameTime() - helpTime) < 5 then
                return threatGUID
            end
        end
    end
    return nil
end -- }}}
```

### Step 3: Intervention action
```lua
-- {{{ BotCombat.intervene
-- Melee bot intercepts threat attacking ranged ally
function BotCombat.intervene(bot, threatGUID)
    local threat = GetPlayerByGUID(threatGUID) or GetCreatureByGUID(threatGUID)
    if not threat or not threat:IsAlive() then return false end

    -- Try taunt first
    if bot:HasSpell(355) then  -- Warrior Taunt
        bot:CastSpell(threat, 355)
    elseif bot:HasSpell(62124) then  -- Paladin Hand of Reckoning
        bot:CastSpell(threat, 62124)
    end

    -- Move to intercept position (between threat and ranged)
    local tx, ty = threat:GetPosition()
    local bx, by, bz = bot:GetPosition()

    -- Get 3 yards in front of threat (toward ranged)
    local angle = threat:GetFacing()
    local ix = tx + math.cos(angle) * 3
    local iy = ty + math.sin(angle) * 3
    local iz = bot:GetMap():GetHeight(ix, iy) or bz

    bot:MoveTo(0, ix, iy, iz, false)
    bot:Attack(threat)

    return true
end -- }}}
```

### Step 4: Clear help signal
```lua
-- Ranged bot clears when threat is handled
-- {{{ BotCombat.clearHelpSignal
function BotCombat.clearHelpSignal(bot)
    local threatGUID = bot:GetData("help_threat")
    if not threatGUID then return end

    local threat = GetCreatureByGUID(threatGUID)
    -- Clear if: threat dead, threat targeting someone else, or >15 yards away
    if not threat or not threat:IsAlive() then
        bot:SetData("help_threat", nil)
        bot:SetData("help_time", nil)
    elseif threat:GetVictim() ~= bot then
        bot:SetData("help_threat", nil)
        bot:SetData("help_time", nil)
    elseif bot:GetDistance(threat) > 15 then
        bot:SetData("help_threat", nil)
        bot:SetData("help_time", nil)
    end
end -- }}}
```

## Visual/Audio Feedback
- Ranged bot could /yell "Help!" or play distress emote
- Optional: brief highlight on melee bot when responding
- Combat log message: "[Bot] rushes to defend [Ranged]"

## Edge Cases

| Case | Handling |
|------|----------|
| Multiple ranged calling | Melee helps closest one first |
| No melee nearby | Ranged continues kiting/fighting alone |
| Melee already engaged | Only intervene if not actively tanking |
| Help call expires | Auto-clear after 5 seconds |
| Threat dies during intervention | Resume previous target |

## Testing
1. Put ranged bot against wall, spawn melee enemy - should call for help
2. Have melee bot nearby - should intercept and taunt
3. Multiple ranged bots calling - melee should help closest
4. Melee tanking a boss - should NOT abandon boss to help
5. Check performance with many bots (help scan is O(n))

## Related Issues
- 161: Bot wandering and combat repositioning (kiting behavior)
- 132: Healer bot ping-pong behavior (similar coordination pattern)
- 160: Behavior system integration

## Related Concepts
- Concept 401-420: Combat coordination
- Concept 301-330: Zone consensus (used for finding nearby bots)

## Notes
- This creates emergent "pack" behavior where bots protect each other
- Similar to MMO trinity dynamics (tank/healer/DPS) but lightweight
- Could extend to healers calling for help when focused
- SetData is session-scoped, so help state doesn't persist through logout
