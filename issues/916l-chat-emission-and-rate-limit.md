# 916l - Chat Emission and Rate Limiting

## Status
- Created: 2026-06-03
- Parent: Issue 916 (mod-soren-chat)
- Phase: 3
- Priority: Medium
- Depends on: 916b (bindings), 916k (chat prompt builder produces output to emit)

## Overview

The consume side of the chat layer. When a chat response comes back from
the worker pool, this module sanitizes it, applies per-bot cooldown,
picks the right output channel (say, whisper, emote), and makes the bot
speak via the appropriate playerbots API.

Small but important — the difference between "bots talk" and "bots
spam" is mostly here.

## Current Behavior

After 916k, chat prompts are built and sent to the worker pool. After
916e, responses come back to the outbox. But nothing converts them into
in-game speech.

## Intended Behavior

After this sub-issue lands:

- `lua/09-chat-emit.lua` handles `type == "chat"` responses from the
  drain loop
- Per-bot cooldown enforced: minimum 45 seconds between any two chat
  emissions by the same bot
- Output sanitization removes problematic patterns small models love:
  - Leading "As a [class], I..." or "As an AI..." patterns
  - OOC markers ([OOC], (OOC))
  - URLs and modern internet references
  - Multi-paragraph responses (truncate to first sentence ending in
    `.!?`)
  - Surrounding quote marks
- Channel selection by trigger context:
  - `nearby_player_speaks` with addressee → whisper to that player
  - `entered_subzone`, `ambient`, `level_up` → `/say` (nearby)
  - `combat_victory` → `/yell` (party-wide audible)
  - `quest_complete` → `/say`

## Sanitization Rules

```lua
local function sanitize(text)
    -- Strip leading "As a X, I..." patterns
    text = text:gsub("^[Aa]s an? [^,]+, [Ii]%s*", "")
    text = text:gsub("^[Aa]s an? AI[^,]*, ?", "")
    -- Strip OOC markers
    text = text:gsub("%[OOC%].*", "")
    text = text:gsub("%(OOC%).*", "")
    -- Strip quotes around the whole thing
    text = text:gsub('^"(.*)"$', "%1")
    text = text:gsub("^'(.*)'$", "%1")
    -- Strip URLs
    text = text:gsub("https?://%S+", "")
    text = text:gsub("www%.%S+", "")
    -- Replace newlines with spaces
    text = text:gsub("[\r\n]+", " ")
    -- Take first sentence only (cheap heuristic)
    local first_sentence = text:match("^[^.!?]+[.!?]")
    if first_sentence then text = first_sentence end
    -- Trim
    text = text:match("^%s*(.-)%s*$")
    -- Length cap
    if #text > 200 then text = text:sub(1, 197) .. "..." end
    return text
end
```

## Cooldown Logic

Per-bot, in-memory:

```lua
local last_emission = {}  -- [bot_guid] = timestamp_ms

local function can_emit(bot_guid)
    local now = current_time_ms()
    local prev = last_emission[bot_guid] or 0
    return (now - prev) >= (config.chat_cooldown_seconds * 1000)
end

local function record_emission(bot_guid)
    last_emission[bot_guid] = current_time_ms()
end
```

In-memory is fine — losing the cooldown across worldserver restart is
acceptable. No DB row needed.

## Implementation Steps

1. Write `lua/09-chat-emit.lua`:
   - `handle_chat_response(response)` entry point called from drain
     loop
   - Sanitization function (per the rules above)
   - Cooldown check + record
   - Channel selection based on trigger context
   - Final emission via the appropriate playerbots/ALE API
2. Add the right binding (or use existing ALE Player API) for `Say`,
   `Yell`, `Whisper` calls from a bot. May need a 916b extension if
   playerbots requires a special path for bot-initiated speech.
3. Smoke test:
   - Trigger each chat type
   - Verify the right channel is used
   - Verify cooldown blocks rapid-fire (try forcing two triggers within
     5 seconds, confirm only one emits)
   - Verify sanitization catches "As an AI..." and OOC markers

## Output Channel Notes

- `Say` is heard by anyone within ~30yd
- `Yell` is heard within ~300yd (zone-wide for most situations)
- `Whisper` is private to one player
- `Emote` is for `*nods*` style — could route some persona archetype
  outputs through here, but for v0 stick to text channels

## Files to Create

- `source-beta/modules/mod-soren-chat/lua/09-chat-emit.lua`

## Files to Update

- `source-beta/modules/mod-soren-chat/lua/06-response-parse.lua` — add
  routing for `type == "chat"` responses
- `source-beta/modules/mod-soren-chat/src/SorenALEBindings.cpp` —
  possibly add `bot_say`, `bot_yell`, `bot_whisper` bindings if ALE's
  defaults don't work for playerbots

## Open Questions

- Does mod-ale's existing `Player:Say(text, lang)` work directly on a
  playerbot's Player object, or does playerbots have its own emission
  path? Likely the former works; if not, the binding extension is
  small.
- Whisper channel: when responding to a specific player's chat, do we
  whisper or say-nearby? Whisper is more direct but may feel
  out-of-flavor. Lean toward `/say` with the player's name prepended
  ("Hail, Aragorn — well met").
- Should rate limiting be global too (max N emissions per minute
  cluster-wide, not just per-bot), to prevent everyone-speaking-at-once
  patterns? Maybe in v0.5; per-bot cooldown handles most cases.

## Related

- Parent: [916 - mod-soren-chat](916-mod-soren-chat.md)
- [916b - ALE bindings](916b-ale-bindings-playerbots.md) — may need
  bot_say/bot_whisper additions
- [916i - Response validator](916i-response-validator-and-directive-apply.md) —
  drain loop routes chat responses here
- [916k - Chat prompt builder](916k-chat-prompt-and-persona.md) — pairs
  with this on the producer side
