# 148e - Add mod-account-achievements to Vanilla — DECLINED

## Status
- Created: 2026-06-01
- **Decision: Declined 2026-06-02.** Achievements are not a focus of
  this ruleset. Vanilla v1 ships with default per-character
  achievement behavior. Revisit if the player feedback ever indicates
  that re-earning achievements on alts is a friction worth solving.
- Phase: 1 (Foundation — profile model)
- Parent: 148 (vanilla profile)
- Priority: N/A (declined)

## Problem

WotLK achievements are per-character by default. On a server where
players are encouraged to roll alts (and vanilla's compressed level
cap of 40 actively rewards trying out multiple race/class combos),
having to re-earn every achievement on every alt creates a paperwork
burden that punishes the kind of play the ruleset is trying to
encourage.

mod-account-achievements moves achievement progress and earned
achievements from the character level to the account level. Any
character on the account sees the same achievement state.

## Intended Behavior

- A player earns "Reach Level 40" on their first character. Their
  second character logs in already showing that achievement as
  earned.
- Progressive achievements (e.g. "Kill 1000 wolves across all
  characters") aggregate across the account.
- Per-character milestones that still make sense per-character (e.g.
  "Reach max level *with this class*") remain per-character if the
  module's design supports that distinction. If it doesn't, accept
  the uniform account-level behaviour — the loss is small.

## Module Details

- **Upstream:** `https://github.com/azerothcore/mod-account-achievements`
  (verify at install time; several similarly-named modules exist).
- **Configuration:** typically minimal; on/off plus maybe a few
  exclusion lists.
- **Compatibility:** standalone module. Touches the achievement system
  which mod-playerbots also touches in passing (bots can complete
  achievements); verify no double-credit or null-deref issues at
  install time.

## Implementation Steps

1. Add the module to `PROFILE_MODULES["vanilla"]` in `scripts/install`.
2. Add the upstream URL to `MODULE_REPOS`.
3. Drop the config into vanilla's `etc/modules/` overlay; keep
   defaults.
4. Rebuild vanilla via `scripts/install --profile vanilla`.
5. In-game test: create two characters on one account. Earn an
   achievement on character A. Log into character B. Confirm
   achievement shows as earned. Confirm achievement points reflect
   the shared state.

## Open Questions

- How does this interact with the achievement-completion hooks that
  mod-playerbots may rely on for bot decision-making? Some bot
  behaviours key off "has the owner completed X" — confirm those
  still read correctly when the source-of-truth is account-level.
- Are there achievements that genuinely should stay per-character
  for narrative reasons (class-specific class-quest completions, for
  example)? If yes, document them as an exclusion list in the config.
