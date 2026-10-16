# 627 - The Bots Think Only When Something Happens

## Status
- Created: 2026-10-15
- Phase: 6
- Related: 625 (buddies favour their talented abilities: the unknown-spell
  part), 617e4b (weapons by place: already acts only on a change of
  situation), 151 (bot population governor)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-15, on the hunter Montahmu asking for Trueshot Aura
forty thousand times in one evening:

> what do you mean "asked for"? Because it was the correct level, but
> couldn't learn it? Why was it asking in a loop? What were we doing in a
> loop that triggered it? Because we probably shouldn't be doing things in
> a loop if we're just... standing around. Everything like that should be
> triggered by something else, to keep it a game focused on user input
> and not a simulation focused on backgrounds.

> Wa! That sounds inefficient! Can you give me a plan for improving it's
> efficiency without severely compromising it structurally or
> accessibility-wise?

## Current Behavior

How the bot module thinks (read 2026-10-15, `mod-playerbots`, Engine.cpp):
every bot runs its engine about every tenth of a second
(`AiPlayerbot.ReactDelay = 100`, stretched by `DynamicReactDelay = 1` for
bots far from players). Each run asks every trigger of its strategies
whether it fires ("is Trueshot Aura missing?", "is a party member
hurt?"), and each fired trigger's action is tried in order of relevance:
USELESS (no need), IMPOSSIBLE (can't: a spell not known), FAILED (tried,
didn't work), or OK. Nothing remembers that an action was impossible, so
the next run asks again. Trueshot Aura is a talent Montahmu does not
have: the hunter's buff strategy names it, its trigger fires (no such
aura), the action is impossible, and that repeats ten times a second.

Every one of those steps is also written to `Playerbots.log`, because the
log level is debug (`Logger.playerbots=5` in worldserver.conf): 62 MB in
one evening for five buddies, each line formatted and written to disk.

## Intended Behavior

The same strategies, actions and chat commands (nothing a player or
another module uses changes), with less repeated work:
1. **Quiet log.** The bot log at info level by default; the step-by-step
   decision log turned on for one buddy when looking into it (the buddy
   module's `.buddy trace <name>` already does this kind of thing for its
   own steps).
2. **Impossible is remembered.** An action found impossible because its
   spell is not known is skipped until the bot's spells change (a spell
   learned or forgotten, talents reset or spent), then tried again once.
3. **Idle is slow.** A buddy out of combat, with nothing changed around
   it (no enemy near, no group change, no order, standing or walking a
   planned path), thinks once a second or so instead of ten times; any
   event (an enemy in range, damage, a whisper, its owner moving off)
   brings it back to full speed at once.
4. **Buffs on events.** Buff triggers (an aura missing) are asked when an
   aura ends, at login, after death, on joining a group, not every run.

## Suggested Implementation Steps

1. Answer the open questions.
2. A config patch: `Logger.playerbots` to 3 (info); measure the log and the
   world update times before and after (the server prints its update
   time diff every few minutes).
3. A reversible source patch to the engine: a per-bot set of actions found
   impossible for an unknown spell, cleared on the learn/forget/talent
   hooks; the engine skips set members without asking.
4. A per-bot "nothing happened" check before each run (no combat, no
   enemy in react distance, no new event in the bot's packet queue, no
   strategy change): when nothing happened, the run is skipped until a
   longer delay passes.
5. The buff triggers: an "aura removed" event for the bot and its group
   that marks buffs to be looked at, the triggers reading that mark.
6. Each step measured with the bot module's performance monitor
   (`playerbot pmon toggle` on the console).

## Open Questions

1. The decision log is how today's failures were found (the poisons, the
   totems, Trueshot Aura). Quiet by default with a per-buddy switch, or
   keep it on while buddies are new?
2. Steps 3-5 change the bot module's engine for every bot (a source
   patch). All bots, or buddies only?
