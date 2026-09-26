# 617m - Buddy Task Hunts: Crafting on Request

## Status
- Created: 2026-09-25
- Phase: 6
- Parent: 617
- Blocked by: 617k (buddies have professions), 917 (the player's words
  become bot actions), 916 (the language model cluster and its bindings)
- Related: 617h (buying missing materials at the auction house), 617l (clan
  chat, where requests are likely to be asked), 917d (a request that keeps
  going until it is done)
- Priority: Low (needs the language model work first)

## Origin

Verbatim, 2026-09-25, choosing that buddies craft on request and pay for
it themselves, and deferring it:

> option 2. This particular function requires the LLM work. This will allow
> us to create toolcalls for the decisionmaking that for example, if the
> player said "can you make me some runed copper bracers? I have two copper
> here." the buddy will look at her own inventory and treat the 2 copper as
> part of her supply. She might say "I need this other thing first, lemme go
> get it" and unless the player stops her she'll go on a task hunt mission
> (task hunt, new vocabular words) to gather the required materials. She'll
> think about the closest source of them, then consider if she can acquire
> them that way. Multi-step chains are evaluated as a unit, for things like
> processing stages of materials and such. Then, she executes on that until
> the task is complete, and she'll walk back to the player and deliver it,
> unless the player said it's low priority, it can wait, etc, then she'll
> mail it. But that's part of the LLM issue tickets. For now, we say no
> requests.

**Task hunt** (new term): an errand a buddy takes on to fetch everything a
requested craft needs, then make it and hand it over.

## Current Behavior

Not built, and deliberately not part of 617k: until this issue is built,
buddies take no requests and craft only by their own priorities (clan
upgrades first, then consumables at random).

## Intended Behavior

A clanmate asks a buddy, in plain words, to make something. The buddy pays
for it: her own materials, her own coin, her own time.

1. **Understanding the ask.** The language model layer (917) turns the
   request into the thing to make and how many, plus any materials the
   asker offers ("I have two copper here").
2. **Counting what's on hand.** The buddy's bags, plus what the asker
   offered, are counted as one supply.
3. **Planning the hunt.** For each missing material the buddy looks for the
   nearest source (gathering node, monster drop, vendor, auction house) and
   whether she can get it that way (skill level, monster level, coin). A
   chain of processing steps (ore to bar, bar to a part, part to the item)
   is judged as one unit: the whole chain is doable or the hunt is not.
4. **Saying so.** She tells the asker what she's off to do ("I need this
   other thing first, lemme go get it"), or why she can't.
5. **Hunting.** She carries the plan out step by step until the item is
   made. The asker can stop her at any point.
6. **Delivering.** She walks back to the asker and hands it over, or mails
   it when the asker said it can wait.

The model makes the decisions through tool calls (read inventory, look up a
recipe, find the nearest source, estimate the cost); the bot module carries
out the steps.

## Suggested Implementation Steps

1. List the tool calls a hunt needs, each answered from game data the
   server already holds (recipes from the spell data, node and monster
   spawns from the world database, vendor lists, 617h's auction prices).
2. The planner: expand a request into its material tree, subtract the
   supply, and pick a source for each missing leaf; judge each processing
   chain as one unit.
3. The hunt as a standing instruction (917d) that survives relogs and ends
   on delivery or when the asker cancels.
4. Delivery by hand or by mail, per the asker's words.

## Open Questions

- 917 describes its layer as "not an agent with its own goals": it carries
  requests and reports back. A task hunt plans its own route to fulfil a
  request. Is that still carrying a request (so 917 fits), or does it need
  its own planning layer beside 917?
- What does a hunt do when a step turns out impossible halfway (a node
  already taken, the price jumped): replan, or report and stop?
- Can one buddy hold several hunts at once, or one at a time with a queue?
