# 184 - Play As Any Creature Model

## Status
- Created: 2026-10-12
- Phase: 1
- Related: 173 (the custom client), 173t (creatures from the world
  database), 617f (Sargobras's look: the server answering the client's
  look question), 718a (death knights serving another faction)
- Priority: Low (a long-term goal, owner: "But that's a long-term goal.")
- State: a goal; nothing to build yet

## Origin

Verbatim, 2026-10-12:

> can we add as an eventual goal the ability to play as any kind of
> character model found in the game? Anything with a diverse enough set
> of animations. There are some that we can transcribe, like for undead
> creatures we could use the "dead" animation when falling asleep, and it
> should play their dying animation. Then, when they re-awaken, it plays
> it in reverse. But that's a long-term goal.

## Current Behavior

A character is drawn as its race's body. The server can already change
the body a player is drawn with (a "display id", as the game master's
morph command does), and every client then draws that creature model in
the player's place; but a creature model has fewer animations than a
playable race's (no emotes, often no sitting, swimming or mounted ones),
and the client plays only the animations the model has.

## Intended Behavior

A player may play as any creature model with a diverse enough set of
animations. Where a model lacks an animation a player needs, one it has
stands in, transcribed by meaning. The owner's example: an undead
creature falling asleep plays its dying animation and stays in the dead
pose; waking, it plays the dying animation in reverse.

## Suggested Implementation Steps

1. An inventory: for every creature model in the client's data
   (CreatureModelData.dbc, AnimationData.dbc, and the animations each
   model file holds), which animations it has; a generator writes the
   table, and a score says which models are "diverse enough".
2. The transcription table: each player animation (sleep, sit, emote,
   swim, mount, ...) mapped to a stand-in each model family has (dead for
   sleep, and so on), and which need playing in reverse.
3. Choosing a body: how a player picks one (open question 1), set by the
   server's display change.
4. Playing a stand-in, and a reversed one: the stock client plays an
   animation only forwards and only when the server or the client's own
   rules ask; reverse playback and arbitrary stand-ins are the custom
   client's (173) to draw.

## Open Questions

1. How is a body chosen: at character creation, from an NPC, earned (a
   creature defeated, a quest)?
2. Is the body only a look, or does it bring the creature's size, speed
   (166's body-based speeds), reach and abilities?
3. Which client: the stock one (looks only, the animations each model
   has) or the custom client (stand-ins and reversed animations)?
