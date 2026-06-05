# 148m - Vanilla XP and Talent Tuning

## Status
- Created: 2026-06-04
- Phase: 8 (Progression — pacing knobs; logged under 148 parent because
  the values are vanilla-specific)
- Parent: 148 (vanilla profile)
- Priority: Medium (gameplay-feel; doesn't block launch)

## Problem

Vanilla profile caps the player at level 40, starts them at level 20
(C007c). That gives 20 levels of intended progression — about
40-something play hours at standard XP rates and standard talent
gain. Two pacing problems with the default behavior:

1. **XP is too fast.** At AC's default `Rate.XP.Kill = 1.0` plus the
   project's existing `C005-exp-rate-2x` doubling, level 20→40 burns
   through in a small handful of sessions. For a profile that's
   meant to feel like an extended endgame plateau, the climb should
   take longer — slowing per-kill XP is the cheapest available
   knob.

2. **Talent progression is too thin.** Default WoW gives 1 talent
   point per level after 10. From level 20 to 40 that's 20 points,
   which forms roughly one full tree but leaves no room to dip into
   a second tree. Vanilla's design intent is for players to *feel*
   talented at the level cap — closer to a late-vanilla / TBC-era
   "I have most of my tree filled out and some flex" feeling than
   the default Classic curve.

## Current Behavior

- `worldserver.conf:Rate.XP.Kill` inherits the project-wide value
  (C005 doubles to 2.0). No vanilla-specific override.
- Talent points awarded by AC's engine via the standard WoW formula:
  1 point per level after 10. At level 20 the character has ~11
  points; reaching level 40 grants 20 more for a total of 31.

## Intended Behavior

- **XP rate**: `Rate.XP.Kill = 0.8` for vanilla. Net rate after C005
  doubling: 1.6× (instead of 2.0×) — modest slowdown that
  compounds across the 20→40 climb without feeling punitive.
- **Talent progression**: each level gained between 21 and 40
  (inclusive) grants 3 talent points instead of the WoW-default 1.
  Level 20 start state unchanged (whatever the default arithmetic
  gives — around 11 points). Each subsequent level-up adds 3,
  yielding `11 + 20*3 = 71` points at level 40.

  Net effect: a level-40 vanilla character is well past the "one
  full tree" threshold and into "two trees co-existing" territory.
  Build space opens up significantly.

The values intentionally combine to soften, not eliminate, the
progression climb — XP is slower so each level-up takes longer, but
each level-up grants more, so the dopamine cadence stays roughly
the same. Climbing more slowly with bigger payouts per step.

## Disablement Mechanism — Two layers

### Layer A: Rate.XP.Kill (single sed in worldserver.conf)

New C-patch, `config/patches/C021-vanilla-xp-rate-multiplier.sh`,
sed-replaces the existing `Rate.XP.Kill` line under vanilla. Runs
after C005's "all profiles double XP" so the vanilla override wins.
Order is fine because `declare -F` puts `config_vanilla_*` after
`config_exp_rate_2x` alphabetically — same pattern used by C014 to
override the playerbot defaults.

### Layer B: Talent point grants (ALE hook on level-up)

`Rate.Talent` in worldserver.conf is a global multiplier but
applies to talent points overall — multiplying by 3 would give
3 talent points at *every* level (10, 11, 12, ...), not just
21-40. We want a level-gated bonus, not a flat multiplier, so
`Rate.Talent` alone isn't precise enough.

The level-gated form needs script-side logic. ALE hook on
`PLAYER_EVENT_ON_LEVEL_CHANGED` (event 33) fires after the engine
has already granted the default 1 talent point. The hook reads
the new level and:

- If `new_level >= 21 and new_level <= 40`: call
  `player:SetFreeTalentPoints(player:GetFreeTalentPoints() + 2)`
  — adds two more points on top of the default one for a total
  of three per level-up in the range.
- Else: no-op.

Lua script lives at `src/lua-vanilla/talent-points-bonus.lua`.
Mirrors the shape of `src/lua-vanilla/auto-equip-starter-kit.lua`:
one `RegisterPlayerEvent` call at file end, one handler function
above it.

## Files To Add

| Path | Action | Note |
|---|---|---|
| `config/patches/C021-vanilla-xp-rate-multiplier.sh` | add | sed Rate.XP.Kill = 0.8 in vanilla worldserver.conf |
| `src/lua-vanilla/talent-points-bonus.lua` | add | ALE hook granting +2 points at level-ups 21-40 |

## Files To Update

| Path | Action | Note |
|---|---|---|
| `installed-files-vanilla/etc/worldserver.conf` | live-apply | re-run C021 |
| `installed-files-vanilla/bin/lua_scripts/custom/` | implicit | E001 already symlinks `src/lua-vanilla/` here so the new script is picked up on next worldserver boot |

## Implementation Steps

1. Write C021 with the sed pattern.
2. Write `talent-points-bonus.lua` using the auto-equip-starter-kit
   script as the template for `RegisterPlayerEvent` shape.
3. Apply C021 against the live vanilla install.
4. Boot worldserver; level a test character past 21; verify the
   talent UI shows +3 points granted (1 from the engine, +2 from
   the script) and that XP from kills is at the new rate.

## Open Questions

- **Per-class scaling.** Hunters and Rogues talent-tree-cost-per-tier
  differently from casters; 3 points per level might overfill those
  trees faster than others. Track separately if balance feedback
  shows a class drowning in points before others.
- **Interaction with bots.** Playerbots gain levels via the bot
  AI's leveling logic; the hook fires for bots too. Bots get the
  same +2 bonus, so the bot fleet at level 40 also has 71 talent
  points. That seems fine — keeps bots and players on the same
  power tier.
- **Rate.Talent global**: should we use it after all, accepting that
  it multiplies at ALL levels? At Rate.Talent = 3 the level-10
  player gets 3 points instead of 1, and a level-20 character has
  ~33 points instead of 11. That bends the early game too — not a
  hard veto, just a different shape. The script-hook version
  preserves the "level 20 start state is unchanged" property.
- **Beta interaction.** Beta uses the chunked talent system from
  205 (10 points at levels 5, 8, 11, 14, 17, 20). The vanilla
  script-hook design is independent of beta's chunking — beta
  doesn't load `src/lua-vanilla/`, so there's no conflict.
