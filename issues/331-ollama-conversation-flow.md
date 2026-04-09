# 331 - Ollama Conversation Flow

## Status
- Created: 2026-04-08
- Phase: 3
- Priority: Low (experimental)
- Milestone: Social Systems
- Depends: Issue 330 (custom chat data sources)

## Overview

Extend the bot chat system with occasional AI-generated responses via Ollama. When a conversation opportunity arises, there's a small chance (configurable, default 10%) to generate a unique response instead of pulling from static JSON. Requests are queued and silently dropped if the queue is full, ensuring the system never blocks gameplay.

## Design Principles

1. **Non-blocking** - Ollama calls are async, never stall the game loop
2. **Graceful degradation** - If Ollama unavailable, fall back to JSON
3. **Queue-limited** - Fixed queue size, excess requests dropped silently
4. **Rate-limited** - Maximum requests per minute to prevent spam
5. **Context-aware** - Prompts include relevant game state

## Architecture

```
┌─────────────────┐
│  Chat Trigger   │
│  (event/timer)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     90%     ┌─────────────────┐
│  Should use AI? │────────────▶│  JSON Selection │
│  (10% chance)   │             │  (Issue 330)    │
└────────┬────────┘             └─────────────────┘
         │ 10%
         ▼
┌─────────────────┐     full    ┌─────────────────┐
│  Queue Space?   │────────────▶│  Silent Drop    │
│                 │             │  (no error)     │
└────────┬────────┘             └─────────────────┘
         │ available
         ▼
┌─────────────────┐
│  Build Context  │
│  (game state)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Queue Request  │
│  (async)        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Ollama Worker  │
│  (background)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Callback with  │
│  Response       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Bot Says       │
│  (delayed)      │
└─────────────────┘
```

## Queue System

```lua
OllamaQueue = {
    max_size = 5,           -- maximum pending requests
    current = {},           -- pending request table
    rate_limit = 10,        -- max requests per minute
    requests_this_minute = 0,
    minute_start = 0,
}

-- {{{ OllamaQueue.enqueue
-- Returns true if queued, false if dropped
function OllamaQueue.enqueue(request)
    -- Rate limit check
    local now = os.time()
    if now - OllamaQueue.minute_start >= 60 then
        OllamaQueue.minute_start = now
        OllamaQueue.requests_this_minute = 0
    end

    if OllamaQueue.requests_this_minute >= OllamaQueue.rate_limit then
        return false  -- silently drop
    end

    -- Queue size check
    if #OllamaQueue.current >= OllamaQueue.max_size then
        return false  -- silently drop
    end

    -- Enqueue
    table.insert(OllamaQueue.current, request)
    OllamaQueue.requests_this_minute = OllamaQueue.requests_this_minute + 1
    return true
end
-- }}}
```

## Context Building

```lua
-- {{{ buildConversationContext
-- Build context string for Ollama prompt
function buildConversationContext(bot, trigger, nearby_players)
    local ctx = {
        bot_name = bot:GetName(),
        bot_class = bot:GetClassName(),
        bot_level = bot:GetLevel(),
        bot_race = bot:GetRaceName(),
        zone = bot:GetZoneName(),
        subzone = bot:GetSubZoneName(),
        time_of_day = getTimeOfDay(),  -- "morning", "afternoon", "evening", "night"
        weather = getWeather(bot),      -- "clear", "rain", "snow", "fog"
        in_combat = bot:IsInCombat(),
        health_pct = bot:GetHealthPct(),
        nearby_players = {},
        trigger = trigger,              -- "greeting", "farewell", "observation", etc.
    }

    for _, player in pairs(nearby_players) do
        table.insert(ctx.nearby_players, {
            name = player:GetName(),
            class = player:GetClassName(),
            level = player:GetLevel(),
        })
    end

    return ctx
end
-- }}}
```

## Prompt Templates

```lua
PROMPTS = {
    greeting = [[
You are {bot_name}, a level {bot_level} {bot_race} {bot_class} in World of Warcraft.
You are in {zone}. The time is {time_of_day}.
A player named {player_name} is nearby.
Generate a brief, in-character greeting (1-2 sentences max).
Stay in character. No modern references. Be concise.
]],

    observation = [[
You are {bot_name}, a level {bot_level} {bot_race} {bot_class}.
You are exploring {subzone} in {zone}. The weather is {weather}.
Generate a brief observation about your surroundings (1 sentence).
Stay in character. Be atmospheric but concise.
]],

    combat_victory = [[
You are {bot_name}, a {bot_class} who just won a battle.
Generate a brief victory line (1 sentence max).
Match the personality of a {bot_race} {bot_class}.
]],
}
```

## Ollama Integration

```lua
-- {{{ callOllama
-- Async HTTP call to local Ollama instance
-- Uses ALE's HTTP capabilities or external curl
function callOllama(prompt, callback)
    local request = {
        model = OLLAMA_CONFIG.model,  -- e.g., "llama3.2:3b"
        prompt = prompt,
        stream = false,
        options = {
            temperature = 0.7,
            max_tokens = 50,  -- keep responses short
        }
    }

    -- Implementation depends on ALE HTTP support
    -- Fallback: write prompt to file, external process reads and responds
    -- or use WebFetch if available

    asyncHttpPost(OLLAMA_CONFIG.endpoint, request, function(response)
        if response and response.response then
            callback(sanitizeResponse(response.response))
        else
            callback(nil)  -- trigger fallback to JSON
        end
    end)
end
-- }}}

-- {{{ sanitizeResponse
-- Clean up Ollama response for in-game use
function sanitizeResponse(text)
    -- Remove quotes if present
    text = text:gsub('^"', ''):gsub('"$', '')
    -- Remove newlines
    text = text:gsub('\n', ' ')
    -- Truncate if too long
    if #text > 200 then
        text = text:sub(1, 197) .. "..."
    end
    -- Remove any OOC markers
    text = text:gsub('%[OOC%].*', '')
    text = text:gsub('%(OOC%).*', '')
    return text:match("^%s*(.-)%s*$")  -- trim
end
-- }}}
```

## Configuration

```lua
OLLAMA_CONFIG = {
    enabled = true,
    endpoint = "http://localhost:11434/api/generate",
    model = "llama3.2:3b",          -- small, fast model
    ai_chance = 0.10,               -- 10% chance to use AI
    queue_size = 5,                 -- max pending requests
    rate_limit = 10,                -- max requests per minute
    timeout = 5000,                 -- ms to wait for response
    fallback_on_error = true,       -- use JSON if Ollama fails
}
```

## Implementation Steps

1. [ ] Research ALE HTTP capabilities (WebFetch, curl, etc.)
2. [ ] Implement async request queue
3. [ ] Create prompt templates for each trigger type
4. [ ] Build context gathering functions
5. [ ] Implement Ollama API caller
6. [ ] Add response sanitization
7. [ ] Integrate with Issue 330 chat system
8. [ ] Add queue monitoring/stats commands
9. [ ] Test with various Ollama models
10. [ ] Tune AI chance and rate limits

## Monitoring Commands

```
#chatqueue       - Show current queue size and stats
#chataichance    - Show/set AI response chance
#chataitest      - Force an AI response for testing
#chatailast      - Show last AI-generated response
```

## Failure Modes

| Scenario | Behavior |
|----------|----------|
| Ollama not running | Fall back to JSON, log warning once |
| Queue full | Silent drop, no error |
| Rate limit hit | Silent drop, no error |
| Timeout | Fall back to JSON for this request |
| Invalid response | Fall back to JSON, log warning |
| Offensive content | Filter and fall back to JSON |

## Content Filtering

```lua
-- Simple blocklist for obviously bad responses
BLOCKED_PATTERNS = {
    "http",           -- no URLs
    "www%.",          -- no websites
    "discord",        -- no modern services
    "%$",             -- no currency symbols
    "lol",            -- no internet speak
    "omg",
    "brb",
}

function isResponseSafe(text)
    local lower = text:lower()
    for _, pattern in ipairs(BLOCKED_PATTERNS) do
        if lower:find(pattern) then
            return false
        end
    end
    return true
end
```

## Related Issues

- Issue 330: Custom chat data sources (prerequisite)
- Issue 329: Algorism priority scheduler (queue concepts similar)
- Issue 165: Activity selection (chat context varies by activity)

## Notes

This is experimental. The goal is occasional "magic moments" where a bot says something surprisingly fitting, not constant AI chatter. The 10% default and queue limits ensure:
- Most responses are fast (JSON)
- AI responses feel special when they happen
- System never impacts gameplay performance
- Ollama downtime is invisible to players

Start with a small, fast model (llama3.2:3b or similar). Quality matters less than speed and staying in character. A mediocre response delivered quickly beats a perfect response that arrives too late.
