# 155z11 - Weapon Presentations: a Blacksmith's Work Shown Off

## Status
- Created: 2026-10-22
- Phase: 1
- Parent: 155 (basic profile)
- Related: 155e1b (Geraldenge's sparring youths), 155p (white gear:
  doubled durability, never repaired, so it reaches 0 durability)
- Priority: Low
- State: planned; open questions first

## Origin

Verbatim, 2026-10-22:

> blacksmith's should be able to use a spell on someone that's just
> /flex'd while targeting you which consumes one of the items they are
> holding. Specifically, the 0 durability crafted equipment that they
> specifically had made. Then they both do a long cast time animation
> where one of them turns to the side and swings it, then they make
> chatting gestures to each other, another one strafes a little with it,
> then swings, or perhaps jumps a half-jump to the side. they talk back
> and forth a little, and the presenter might flex while holding the
> weapon. If they're a boy, they might take their shirt off, but that
> behavior can be disabled by talking to a specific NPC who lives in
> capital cities.
>
> the presenter gets a little bit of rested experience from doing it. The
> blacksmith should get +skill points with that tier's equipment (meaning,
> the skill points at each tier) "how well can you make beginner recipes"
> ha

## Current Behavior

Nothing like it. A crafted item worn to 0 durability is broken and, for
white gear on basic (155p), can't be repaired; it sits in the bags. The
client can't be given new spells without a client patch, but the server
sees every text emote a player uses (/flex among them) and whom they
were targeting (the Lua engine's text emote event), and can play
emotes, movement and speech on players and creatures, change rested
experience and raise a skill.

## Intended Behavior

1. **The invitation:** a player targets a blacksmith and uses /flex.
2. **The presentation:** the blacksmith, within a short while, accepts
   (open question 1 on how), and one item is consumed: a piece of
   equipment at 0 durability that this blacksmith made, held by the
   presenter (the one who flexed).
3. **The scene,** a long one, played on both: the presenter turns to the
   side and swings the weapon; the two make chatting gestures; the
   presenter strafes a little with it and swings again, or hops a half
   step to the side; they talk back and forth; the presenter may flex
   with the weapon in hand. A male presenter may take his shirt off for
   it; a player can turn that off by talking to an NPC who lives in the
   capitals (open question 3).
4. **The rewards:** the presenter gains a little rested experience; the
   blacksmith gains skill points in that item's tier ("how well can you
   make beginner recipes", open question 4).

## Suggested Implementation Steps

1. Answer the open questions.
2. Knowing who made an item: a crafted item carries its maker (the
   "Made by" line, the item's creator, kept by the server).
3. A Lua script on the text emote event: a /flex at a blacksmith opens the
   offer (open question 1), finds a 0-durability item in the presenter's
   bags made by that blacksmith, and plays the scene: a timeline of
   emotes, facing, small moves and lines on both players, the item
   destroyed at its end.
4. The shirt: unequipped into the bags for the scene and put back after,
   only for male presenters who haven't turned it off (a per-character
   setting, kept in a characters-database table the capitals' NPC writes).
5. The rewards: rested experience added on the presenter; the skill on
   the blacksmith (open question 4).
6. Tests: the item-finding rule (made by this blacksmith, 0 durability,
   held); in game, one presentation.

## Open Questions

1. **"use a spell":** the client can't learn a new spell. The blacksmith
   could answer the /flex with its own emote (say, /cheer or /bow at the
   presenter within 10 seconds) to start it, or a gossip-style prompt, or
   a hearthstone-like item blacksmiths carry. Which?
2. **"holding":** the item in the presenter's bags, or equipped in a hand
   at the moment?
3. **The shirt NPC:** a new NPC in each capital (a tailor, a priest, a
   guard?), and is the setting "never take my shirt off" (off by default
   for everyone, or on)?
4. **"+skill points with that tier's equipment":** the blacksmith's
   Blacksmithing skill rises (a few points, capped where the item's
   recipe goes grey?), or a separate measure of how well they make that
   tier's recipes (something the game has no place for: a hidden count
   that, say, improves the chance of a better result)?
5. **How much rested experience:** a fixed amount, or by the item's level?

## Answers, 2026-10-22

1. **"it's a recipe spell sorry, something in blacksmithing."** So the
   presentation is a Blacksmithing recipe in the profession window, cast
   on the presenter. The client shows only spells it already knows, so it
   would be an existing spell the client files list under Blacksmithing,
   given a new meaning on the server (its effect replaced by the scene).
   Open: an unused or rarely used blacksmithing spell to borrow (a list
   to draw up from the client's tables), or one you'd like it to look like?
