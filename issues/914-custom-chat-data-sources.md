# 914 - Custom Chat Data Sources

## Status
- Created: 2026-04-08
- Phase: 3
- Priority: Medium
- Milestone: Social Systems

## Overview

Replace playerbots' built-in random chat with a custom system that pulls responses from JSON data files. This allows full control over what bots say, when they say it, and how messages are selected.

## Current Behavior

Playerbots has a built-in random chat system that makes bots say things like:
- "Hello"
- Random emotes
- Combat callouts
- Generic RPG phrases

Configuration in `playerbots.conf`:
- `PlayerbotAI.RandomBotSayRandom` - enable/disable
- Various chat frequency settings

The data sources are hardcoded in C++ or pulled from database tables.

## Intended Behavior

### Custom JSON Data Structure

```
data/chat/
  greetings.json       - hello, goodbye, acknowledgments
  combat.json          - battle cries, victory, defeat
  exploration.json     - reactions to environment, discoveries
  social.json          - small talk, questions, observations
  emotes.json          - /wave, /bow, /dance triggers
  reactions.json       - responses to player actions
  personality/
    friendly.json      - warm, helpful responses
    gruff.json         - short, curt responses
    curious.json       - questioning, interested responses
    nervous.json       - worried, anxious responses
```

### JSON Format

```json
{
  "category": "greetings",
  "triggers": ["login", "nearby_player", "approached"],
  "messages": [
    {
      "text": "Well met, traveler.",
      "weight": 10,
      "conditions": {
        "min_level": 1,
        "max_level": 20,
        "factions": ["alliance", "horde"],
        "time_of_day": ["morning", "afternoon"]
      }
    },
    {
      "text": "Hail!",
      "weight": 20
    },
    {
      "text": "*nods*",
      "weight": 30,
      "is_emote": true
    }
  ]
}
```

### Selection Algorithm

1. Event triggers message selection (e.g., "nearby_player")
2. Filter messages by conditions (level, faction, time)
3. Apply weights for random selection
4. Consider bot personality modifier
5. Apply cooldown (don't repeat same message too soon)
6. Output via appropriate channel (say, emote, yell)

### Personality System

Each bot has a personality trait that modifies message selection:

```lua
bot_personalities = {
    [botGuid] = {
        type = "friendly",  -- or gruff, curious, nervous, silent
        chattiness = 0.7,   -- 0.0 to 1.0, multiplier for chat frequency
        last_spoke = 0,     -- timestamp
        cooldown = 30,      -- seconds between messages
    }
}
```

### Hot-Reload Support

- JSON files loaded on server start
- `.reload chat` command to reload without restart
- Changes take effect immediately

## Investigation Steps

1. [ ] Find playerbots' current chat implementation in C++
2. [ ] Identify hook points for intercepting/replacing chat
3. [ ] Design JSON schema for message categories
4. [ ] Implement JSON loader in Lua
5. [ ] Create personality assignment system
6. [ ] Implement weighted message selection
7. [ ] Add cooldown tracking
8. [ ] Create initial JSON data files
9. [ ] Test with various bot personalities

## Key Files to Investigate

**Playerbots sources:**
- `modules/mod-playerbots/src/Bot/PlayerbotAI.cpp` - main bot AI
- `modules/mod-playerbots/src/Bot/PlayerbotTextMgr.cpp` - text handling
- `modules/mod-playerbots/src/strategy/actions/SayAction.cpp` - say implementation

**New files to create:**
- `src/lua/bot-chat.lua` - chat system implementation
- `data/chat/*.json` - message data files
- `src/lua/personality.lua` - personality assignment

## Configuration

```lua
-- config/chat-config.lua
CHAT_CONFIG = {
    enabled = true,
    base_frequency = 0.1,      -- base chance per tick to speak
    cooldown_min = 30,         -- minimum seconds between messages
    cooldown_max = 120,        -- maximum seconds between messages
    personality_weights = {
        friendly = 30,
        gruff = 20,
        curious = 25,
        nervous = 15,
        silent = 10,
    },
}
```

## Related Issues

- Issue 331: Ollama conversation flow (extends this with AI generation)
- Issue 161: Bot wandering (chat triggers during travel)
- Issue 165: Activity selection (chat varies by activity)

## Notes

The goal is to make bot chat feel natural and varied without being annoying. Key principles:
- Less is more (bots shouldn't chatter constantly)
- Context matters (combat chat differs from exploration)
- Personality creates memorable characters
- Cooldowns prevent spam
- Silent type exists for those who prefer quiet bots
