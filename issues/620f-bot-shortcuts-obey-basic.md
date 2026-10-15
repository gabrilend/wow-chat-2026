# 620f - Bot Shortcuts Obey Basic

## Status
- Created: 2026-10-14
- Phase: 6
- Parent: 620
- Blocked by: 620a
- Blocks: 620g
- Related: 155 (basic profile) and its rules: 155g (vanilla talent cap),
  155k (Outland gear ladder), 155o (Inscription without glyphs), 155r (no
  dual spec), 155s (Northrend closed), 155w (no mounts in towns), 155d
  (rotating starting valleys); 617a4 (buddy starting kit), 617r2 (buddy
  kit from a gearset)
- Priority: Medium

## Origin

The owner, 2026-10-14: playerbots should respect "all the other features
we've added". Many of basic's features are things a player does **not**
get; the bot module has ways to give bots those things anyway.

## Current Behavior

The bot module's shortcuts, set by `playerbots.conf` and not adjusted for
basic, apart from switching random bots off (C023):

| Shortcut | What it can hand out that basic withholds |
|---|---|
| automatic gear ("autogear", and "autogear bis" from the module's best-in-slot table) | gear off basic's level-60 ladder, Wrath raid gear |
| random bot set-up on login and level-up (gear, talents, spells, glyphs, mounts) | glyphs (155o), dual spec (155r), flying and epic mounts at the wrong levels, spells past basic's rules |
| the "maintenance" command | every spell, talents filled, consumables |
| teleports to random-bot zones | Northrend (closed on basic, 155s) |
| random bot creation | race-home starting zones (basic rotates valleys, 155d; basic.md says bots are left out of the rotation on purpose) |

What already holds bots to basic, because it is enforced by the server
itself for everyone: the refused channels (155x, B038), the talent cap
(155g, `basic_rules.cpp`), the respec cost (155r, B035), riding levels
(E020).

## Intended Behavior

No bot on basic has anything a player could not have at the same level by
playing:

- Every shortcut in the table is either switched off on basic (a config
  patch, gated `basic`) or held to the rule it would break (a B-patch
  where no setting exists).
- Gear from automatic gearing is chosen only from items a basic character
  can get (the ladder; 617r's gearsets are the natural source).
- One check, run after a bot's set-up, compares the bot against basic's
  rules and logs any difference, so a new shortcut in a bot module update
  is caught (a warning, treated as an error).

## Suggested Implementation Steps

1. Read every `AiPlayerbot.*` setting in the generated `playerbots.conf`
   for basic and list each that hands out something (gear, spells,
   talents, glyphs, mounts, teleports, money).
2. One config patch (`config/patches/C0xx-basic-bot-shortcuts.sh`)
   switching off or limiting each; tested by
   `scripts/test-profile-config-gates`.
3. B-patches only where no setting exists (glyphs on random bots, dual
   spec on random bots).
4. The after-set-up check (mod-buddies or `basic_rules.cpp`): talent
   count, spec count, glyphs, gear item levels against the ladder.
5. Test: an alt bot given "autogear" and "maintenance" at level 30 on
   basic; the check's log for a random bot (cc-test).
6. Note the bot case in each rule's own issue (155g, 155k, 155o, 155r,
   155s, 155w).

## Open Questions

- Should the "autogear" and "maintenance" commands be **removed** on
  basic, or **limited** (autogear picks from the ladder, maintenance only
  repairs and refills)?
- Starting valleys: should random bots join the rotation after all, now
  that they would be players in every other way?
