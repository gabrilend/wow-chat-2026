# 916h - Guidance Prompt Builder

## Status
- Created: 2026-06-03
- Parent: Issue 916 (mod-soren-chat)
- Phase: 3
- Priority: High (defines the directive vocabulary — the contract between LLM and playerbots)
- Depends on: 916b (party state struct shape), 916g (calls this)

## Overview

Translates a party-state struct (from `SorenBindings.get_party_state`)
into a prompt string that asks the LLM for per-bot policy flags. Defines
the directive vocabulary the LLM is allowed to use. Output must be
strict JSON matching a fixed schema.

This is the most design-sensitive sub-issue in the bunch. The prompt
quality determines whether the LLM produces useful guidance or
hallucinated nonsense. The directive vocabulary determines what
expressive range the system has.

## Current Behavior

No guidance prompt builder exists. 916g would have nothing to call.

## Intended Behavior

After this sub-issue lands, `lua/05-prompt-guidance.lua` exposes:

```lua
local builder = require("mod-soren-chat.prompt-guidance")

local prompt = builder.build({
    party = {
        { name = "Tankzilla", class = "warrior", spec = "protection", level = 22,
          health_pct = 85, mana_pct = nil, role = "tank", in_combat = true,
          current_target = "Defias Pillager" },
        { name = "Healbot", class = "priest", spec = "discipline", level = 21,
          health_pct = 92, mana_pct = 67, role = "healer", in_combat = true,
          current_target = nil },
        { name = "Stabbo", class = "rogue", spec = "assassination", level = 22,
          health_pct = 95, mana_pct = nil, role = "dps", in_combat = true,
          current_target = "Defias Pillager" },
    },
    zone = "Westfall",
    subzone = "Moonbrook",
    enemy_summary = "3 Defias Pillagers, level 18-20, ranged-and-melee mix",
    party_recent_events = { "took 30% damage in 5 seconds", "interrupted a spell cast" },
})
-- returns a string ready to send to Ollama
```

## Directive Vocabulary

The LLM is constrained to output a JSON document with this structure:

```json
{
  "party_intent": "string, one short sentence describing overall plan",
  "directives": [
    {
      "bot": "name of bot in party",
      "strategies_add":    ["strategy_name", ...],
      "strategies_remove": ["strategy_name", ...],
      "multiplier_overrides": {
        "action_name": 0.0_to_2.0
      },
      "focus": "name of party member or enemy this bot should prioritise",
      "stance": "front_line | back_line | flanking | follow_tank"
    }
  ]
}
```

The vocabulary of `strategies_add` / `strategies_remove` is the
mod-playerbots strategy registry. The vocabulary of
`multiplier_overrides` is the action-name registry. Both are bounded —
the response validator (916i) will reject names not in those registries.

`stance` is a controlled enum mapped to behaviors in the SorenDirected
strategy (916j).

## Prompt Template

The system prompt frames the task in role-language:

```
You are the tactical planner for a party of World of Warcraft companion
bots. The party is engaging enemies in {zone} ({subzone}).

Your job: assign each bot a policy describing how they should fight.
You are NOT picking individual actions — the bots handle their own
moment-to-moment choices. You decide their priorities and posture.

Available strategies (combat): {known_combat_strategies}
Available stances: front_line, back_line, flanking, follow_tank

Output strict JSON matching this schema:
{schema}

Be concise. Each directive is a small set of changes from default
behavior. Bots not mentioned in your output keep default behavior.
```

The user prompt is the party state, formatted as a compact text block.

## Implementation Steps

1. Write `lua/05-prompt-guidance.lua`:
   - System prompt template with `{known_combat_strategies}` and
     `{schema}` substitution
   - User prompt assembler that takes the party-state struct and
     produces a compact text representation
   - Public `build(state)` function returning the final prompt string
2. Build the strategy registry lookup — at module load time, query
   mod-playerbots via 916b's `is_strategy_known` (or a new binding
   that returns the full set) to populate the available-strategies
   list. This is what gets substituted into the system prompt.
3. Define a controlled schema string (the JSON skeleton above) and
   substitute it into the system prompt for the LLM to see.
4. Write a smoke test that builds a prompt for a 3-bot party and dumps
   to stdout for human inspection. Iterate on the wording.
5. Send the smoke-test prompt to one of the boxes manually and inspect
   the LLM's output for vocabulary fit and JSON validity. Iterate on
   prompt phrasing until small models (llama3.2:1b) produce valid JSON
   reliably (target: >95% of attempts).

## Notes on Small-Model Behavior

llama3.2:1b and qwen2.5:1.5b are not naturally reliable at structured
output. Mitigations stacked together:

- Use Ollama's `format: "json"` option in the request (916d's call site)
  to force JSON output via grammar constraints. This is the single
  biggest reliability improvement.
- Keep the schema small and use short field names (no nested objects
  more than two levels deep)
- Provide one or two few-shot examples in the system prompt showing a
  valid response
- Constrain the directive vocabulary tightly — fewer choices mean
  fewer ways to be wrong

## Files to Create

- `source-beta/modules/mod-soren-chat/lua/05-prompt-guidance.lua`

## Open Questions

- How many actions/strategies are in mod-playerbots' registry? If it's
  hundreds, the system-prompt strategy list balloons. May need to
  filter to a curated subset of LLM-relevant strategies.
- Does the LLM need to know each bot's spell list, or is class+spec
  enough for it to reason about roles? Lean toward "class + spec is
  enough" — the LLM isn't picking spells.
- Should `party_recent_events` be a separate field or folded into the
  user prompt as free text? Free text gives the LLM more context per
  token but is harder to limit.
- What about non-combat policies? This ticket assumes combat. Add a
  non-combat prompt path later if needed (questing, travelling,
  resting).

## Related

- Parent: [916 - mod-soren-chat](916-mod-soren-chat.md)
- [916b - ALE bindings](916b-ale-bindings-playerbots.md) — provides
  party-state struct shape and strategy-name validation
- [916g - Proximity hook](916g-proximity-detection-hook.md) — calls
  this builder
- [916i - Response validator](916i-response-validator-and-directive-apply.md)
  — consumes the LLM's response, validates against this schema
- [916j - SorenDirected strategy](916j-sorendirected-strategy-class.md)
  — consumes the resolved policy state per bot
