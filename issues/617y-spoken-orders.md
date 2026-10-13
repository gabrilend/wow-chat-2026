# 617y - Spoken Orders: "go sell", "follow me", "follow so-and-so"

## Status
- Created: 2026-10-12
- Phase: 6
- Parent: 617 (buddy bots)
- Related: 617h1 (the selling trip), 617a5 and source patch B045 (buddies
  take no bot-module chat commands), 617m (language-model buddies), 917
  (tool calls)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-12:

> can we add a mechanic where after a bot says "my inventory is full" we
> can say "go sell" to them and any bot that has a full inventory will
> return to the nearest town and sell their goods? it might be most or
> all of them, and then the player probably should follow them back or
> they'll get eaten or slain. it's important to always stay by your
> peers, which is why you should also be able to say "follow me" or
> "follow so-and-so" and then the buddy bot who hears you will do that
> thing. eventually we can add llm capabilities, and make it narrate
> itself. Then, we use the embedding model to parse what it said into one
> of the tool call possibilities instead of training it to speak like a
> robot.

## Current Behavior

- **Full bags:** the server now running (built 2026-10-03) has a full
  buddy keep looting while the bot module whispers "My bags are full" at
  each failed pickup. Written since then and in the next build: the
  selling trip (617h1), where a buddy past full walks to the nearest town
  and sells on its own, and B048, which stops the whisper.
- **Orders:** buddies ignore every bot-module chat command (B045, owner
  2026-09-25: buddies run on their own rules; the language-model layer
  reaches the same actions later as tool calls, 617m / 917).

## Intended Behavior

Spoken orders, heard by buddies within hearing (say, party, or a whisper
to one), each a small fixed action:
- **"go sell"**: every buddy that hears it and has full bags (past the
  selling trip's threshold) leaves on its selling trip now, to the nearest
  town. Its owner should follow, or the buddies may die on the road ("it's
  important to always stay by your peers").
- **"follow me"**: the buddy that hears it follows the speaker, instead
  of roaming, until told otherwise.
- **"follow <name>"**: the buddy follows that player or buddy.

Later (617m): the buddy narrates itself in its own words through a
language model, and what it says is matched to one of these actions (a
tool call) by an embedding model, rather than the buddy being trained to
speak in commands.

## Suggested Implementation Steps

1. Answer the open questions.
2. The hearing: the Lua chat hook (as Sargobras listens for a clan name)
   matching the phrases, the speaker the buddy's owner (or any player:
   open question 2).
3. "go sell": start the selling trip at once for each hearer with full
   bags (617h1's entry point, from the buddy module through a Lua call or
   a roster flag it watches).
4. "follow": a follow state in the buddy module's strategy, in place of
   roaming, with how it ends (open question 3).
5. Tests offline; then in game.

## Open Questions

1. The selling trip already sends a full buddy to town by itself in the
   next build. Is "go sell" still wanted on top (sooner, or all at once),
   or should the trip wait for the order instead of starting by itself?
2. Who may give orders: only a buddy's own owner, or any player it
   hears (a party member)?
3. How does "follow" end: "stop", the owner logging out, a town, a
   dungeon, after a time?
4. Spoken to whom: everyone in /say range hears "follow me"; should only
   buddies addressed by name (or the speaker's target) obey?
