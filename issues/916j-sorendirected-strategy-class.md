# 916j - SorenDirected Strategy Class

## Status
- Created: 2026-06-03
- Parent: Issue 916 (mod-soren-chat)
- Phase: 3
- Priority: Medium-High (needed for policies that don't fit existing strategies)
- Depends on: 916a (skeleton), 916i (per-bot policy state shape)

## Overview

Add a new strategy class to mod-playerbots that reads LLM-set per-bot
policy state and produces matching action multipliers. The strategy
itself is in C++ inside mod-playerbots' strategy directory; the per-bot
policy table is shared between this strategy and the Lua side via
mod-soren-chat's bindings.

Implemented as a B-patch against mod-playerbots so it survives upstream
pulls, matching the project's existing pattern.

## Why This Strategy Is Needed

Most LLM directives can be expressed as toggling existing strategies on
or off (`+save_mana`, `-aggressive_heal`). But the LLM sometimes wants
to express things the existing strategy palette doesn't cover directly:

- "Focus heals on Tankzilla specifically" — `save_mana` is too coarse
  (suppresses healing of low-priority targets) but doesn't bias toward
  one party member
- "Prioritise interrupting casters over normal DPS rotation" —
  AggressiveStrategy doesn't have this dimension
- "Use flanking stance" — no existing strategy expresses positional
  intent

These all express as: when this strategy is active, scale these
specific actions' relevance based on per-bot policy state set by the
LLM. That's exactly what a Multiplier-based strategy does.

## Intended Behavior

A new strategy named `soren_directed` that can be toggled like any
other:

```
.playerbot strategy +soren_directed,co
```

When active, the strategy's multipliers read from a per-bot policy
table (populated by 916i) and bias action relevance:

- If `focus = "Tankzilla"` and this bot is a healer, heal-tank action
  variants get multiplied by ~1.5, heal-others get multiplied by ~0.7
- If `stance = "back_line"`, movement actions toward melee range get
  multiplied by 0.5, retreat-style movement gets 1.5
- If `multiplier_overrides = { "cast_fireball": 1.5 }`, the named action
  gets that exact multiplier
- If no policy is set for this bot, all multipliers return 1.0 (no
  bias, default behavior wins)

The LLM enables `soren_directed` for bots it has policies for; bots
without active policies keep default strategies untouched.

## Implementation Approach

This is a B-patch against mod-playerbots since the strategy lives
inside mod-playerbots' source tree. The patch:

- Adds `SorenDirectedStrategy.h` and `.cpp` to
  `modules/mod-playerbots/src/Ai/Base/Strategy/`
- Registers the strategy in `StrategyContext.h`
- The strategy declares a small public API for mod-soren-chat to push
  per-bot policy structs into it (an extern C++ function, namespaced
  to avoid collision)

The strategy file structure mirrors `ConserveManaStrategy`
(`HealerAutoSaveManaStrategy`) as a reference template:

```cpp
class SorenDirectedMultiplier : public Multiplier {
public:
    SorenDirectedMultiplier(PlayerbotAI* botAI)
        : Multiplier(botAI, "soren directed") {}

    float GetValue(Action* action) override;
};

class SorenDirectedStrategy : public Strategy {
public:
    SorenDirectedStrategy(PlayerbotAI* botAI) : Strategy(botAI) {}
    void InitMultipliers(std::vector<Multiplier*>& multipliers) override;
    std::string const getName() override { return "soren_directed"; }
};
```

The Multiplier's `GetValue` reads the per-bot policy from a global
table (keyed by bot GUID) that mod-soren-chat owns:

```cpp
float SorenDirectedMultiplier::GetValue(Action* action) {
    auto policy = SorenChat::GetPolicyForBot(bot->GetGUID());
    if (!policy) return 1.0f;

    // Check explicit multiplier overrides first
    auto override_it = policy->multiplier_overrides.find(action->getName());
    if (override_it != policy->multiplier_overrides.end())
        return override_it->second;

    // Apply stance-based modifiers
    if (policy->stance == Stance::BackLine && action_is_melee_approach(action))
        return 0.5f;
    if (policy->stance == Stance::BackLine && action_is_retreat(action))
        return 1.5f;

    // Apply focus-based modifiers
    if (policy->focus_guid != 0 && action_targets(action, policy->focus_guid))
        return 1.5f;
    // ... etc

    return 1.0f;
}
```

## Implementation Steps

1. Write the B-patch file
   `patches/B025-soren-directed-strategy.sh`. The patch creates two new
   files in mod-playerbots and modifies the `StrategyContext.h` to
   register the strategy.
2. Add B025 to vanilla's `PHASE_BEGIN_PATCHES` in
   `patches/patches.sh`.
3. Write the strategy's C++ files (which the B-patch installs):
   - `SorenDirectedStrategy.h`
   - `SorenDirectedStrategy.cpp`
4. Define the policy struct in mod-soren-chat's C++ side
   (`SorenChatPolicy.h`) with fields matching 916i's schema. Expose
   `SorenChat::SetPolicyForBot(guid, policy)` and
   `SorenChat::GetPolicyForBot(guid)`.
5. Wire the Lua side (916i's `08-directive-apply.lua`) to call
   `SorenBindings.set_policy(guid, policy_table)` after a successful
   validation — add this binding in 916b's binding set.
6. Smoke test:
   - Manually set a policy via Lua console
   - Toggle `+soren_directed` on a bot
   - Observe behavior changes that match the policy

## Files to Create (via B-patch B025)

- `source-beta/modules/mod-playerbots/src/Ai/Base/Strategy/SorenDirectedStrategy.h`
- `source-beta/modules/mod-playerbots/src/Ai/Base/Strategy/SorenDirectedStrategy.cpp`
- (registration patch to existing `StrategyContext.h`)

## Files to Create (in mod-soren-chat)

- `source-beta/modules/mod-soren-chat/src/SorenChatPolicy.h`
- `source-beta/modules/mod-soren-chat/src/SorenChatPolicyStore.cpp`

## Files to Update

- `patches/patches.sh` — add B025 to vanilla, beta, release lists
- `source-beta/modules/mod-soren-chat/src/SorenALEBindings.cpp` —
  add `set_policy` binding (917b extension)

## Open Questions

- How does the Multiplier know whether an action "is_melee_approach" or
  "is_retreat"? Likely via type-checking the Action's runtime class
  (dynamic_cast to known categories) or by string-matching action
  names. The simpler form (name string list) is good enough for v0.
- Multiplier interaction with other strategies' multipliers: if
  `save_mana` returns 0.0 and `soren_directed` returns 1.5 for the
  same action, what's the resolved value? mod-playerbots' multiplier
  composition likely multiplies them (0.0 × 1.5 = 0.0). Verify in
  source.
- Per-bot policy lifecycle from C++ side: when does the policy get
  cleared? Tied to the Lua-side "leave LLM zone" event (916g). The
  binding for clearing is just `SorenBindings.set_policy(guid, nil)`.

## Related

- Parent: [916 - mod-soren-chat](916-mod-soren-chat.md)
- [916b - ALE bindings](916b-ale-bindings-playerbots.md) — needs
  `set_policy` binding added
- [916i - Directive application](916i-response-validator-and-directive-apply.md) —
  calls `set_policy` after validation
- mod-playerbots `ConserveManaStrategy` — reference template for the
  Strategy + Multiplier pattern
- Issue 126 (upstream warning fixes) — established the B-patch pattern
  for modifying mod-playerbots source
