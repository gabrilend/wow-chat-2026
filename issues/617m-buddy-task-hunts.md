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

### Sources, money and skill (Ritz, 2026-09-25)

> materials can be purchased from the auction house, or nearby vendors if
> appropriate. The auction house should be considered if the request needs
> to be completed quickly and they're in town, weighted against the
> distance to acquire the other goods. There's no flight paths, so keep
> that in mind, we probably can't use the default playerbots proximity
> rules because they might assume flight paths. If the bot can't afford it
> of course they'll need to gather it themselves. If their skill is too low
> and the recipe is learned from a trainer, then they can say "I'll have to
> level up my blacksmithing first, do you mind waiting?" and then they will
> work on it while the player is online until it's at the required level,
> then they will find the materials and produce the item. Proximity to
> source and auction house price are two weights on the scale to consider.

- **Sources**: gathering, monster drops, nearby vendors, and the auction
  house.
- **Choosing a source**: two weights on one scale: the distance to the
  source and the auction house price. The auction house counts for more
  when the asker is in a hurry and the buddy is already in town.
- **Distance is walking distance.** There are no flight paths. The bot
  module's own travel graph links flight masters into its routes (its
  travel manager builds a flight-path graph), so its distance estimates
  can't be used as they are: they must be measured on foot.
- **Can't afford it**: she gathers it herself.
- **Skill too low** (and the recipe comes from a trainer): she asks, "I'll
  have to level up my blacksmithing first, do you mind waiting?"; then
  levels the skill while the asker is online, and only then starts the
  hunt.
- **A step fails** (Ritz: "She re-attempts."): she tries again rather than
  giving up.
- **Several hunts at once** (Ritz: "In principle I'd say it's okay to hold
  multiple at once, and thread the tasks together seamlessly according to
  distance or total effort or something - this is how players would handle
  multiple concerns at once."): allowed, with the steps of all her hunts
  interleaved into one route by distance or effort. How many she can hold
  depends on the memory the language model issues give buddies.

### What the model does, and what code does (Ritz, 2026-09-25)

"The model routes between behaviors, it doesn't apply behavior."

- **The language model** understands the request and turns it into one new
  buddy command, and it speaks her lines in character. The command's shape
  (Ritz, 2026-09-25: "what to make, for whom, and a source defined for each
  of the required materials, one argument per material (with stacks
  counting as one entry), where one of the sources can be their
  backpack"):
  - what to make;
  - for whom, and how it reaches them (Ritz: "it's for person A, and I
    will hand deliver it."): handed over in person, or mailed when it can
    wait;
  - then one entry per material per source, each naming where that
    material comes from: her backpack (which, per the example, includes
    what the asker hands over), a gathering node, a monster, a vendor, or
    the auction house. A stack is one entry. A material drawn from two
    places is two entries (2 bars from the backpack, 4 from the auction
    house). A processed material is one entry per stage (mine the ore;
    smelt the bars), so each stage is its own step.

  So the model routes each material to a source behavior; it doesn't walk
  or buy anything itself. It picks only from the **source table** code
  hands it (Ritz, 2026-09-25): per material, every source she could use,
  with its walking distance, its price, and whether she can succeed there
  (and if not, why). Distance and price are the two weights; the model
  weighs them with what the asker said ("quickly").
- **Ordinary code in the buddy module** builds the source table, then
  carries out the command: weaving several hunts into one route and
  walking the steps. Hunts keep going when the model cluster is slow once
  the command is written. This keeps 917's rule that its layer carries
  requests rather than having goals of its own.

### Changing a hunt in flight (Ritz, 2026-09-25)

> we should be able to update it in-flight as well, so make sure even if we
> weave together multiple requests, we can remove one atomically and
> re-create the list with it's modified requirements. "Actually I'm running
> out of time before the raid, can you just buy the pearl on the auction
> house?"

- Each hunt is kept as its own command; the woven route is only derived
  from them, never edited directly.
- A change replaces one hunt's command whole (the model writes the new
  one: here, the pearl's entry now says "auction house"), and the route is
  re-woven from the current set. Removing a hunt is the same with no
  replacement. Either happens all at once: no step of the old command runs
  after the new one is in place.
- Materials already fetched for the old command are in her backpack, so
  the new command can name the backpack for them.

### Performance of the source table (Ritz, 2026-09-25)

"we should pay special attention to the performance demands of gathering
so much data." A table for one recipe touches every node spawn, monster
loot list and vendor list that has any of its materials, plus the auction
house and walking distances. See the open question below.

### A step that can't succeed (Ritz, 2026-09-25)

Before starting, the planner checks that every step can be done. A step
that can't is not attempted; she says why and, where there is one, offers
the thing that would make it possible:

- Out of her reach (a drop from monsters far above her level, or only
  inside a dungeon): "Sorry, I can't do that right now because of ABC. Do
  you want to [do-thing-that-resolves-the-task]?", e.g. "do you want to
  level up some more with me?" or "do you want to do that dungeon?"
- No source at all (no vendor, none at the auction house, nothing she can
  gather): "I don't see any [item] on the auction house, and I'm not sure
  where to get them."
- Recipe not learned: "I don't have that recipe trained yet, sorry" (a line
  that fits other situations too).

Steps that can succeed but fail this time (a node taken, an auction bought
first, a vendor sold out, a death on the road, full bags) are re-attempted.

## Suggested Implementation Steps

1. The craft command (item; recipient and delivery; one entry per
   material per source, one per processing stage), usable without the
   model (by a chat command) so hunts can be tested before 917 exists.
   Replacing or removing one command at once, re-weaving the route.
2. The source table, in code: expand a recipe into its material tree and,
   for each material, list the sources she could use with their walking
   distance and auction or vendor price, all from data the server already
   holds (recipes from the spell data, node and monster spawns from the
   world database, vendor lists, 617h's auction prices); mark sources that
   can't succeed, with the reason and the offer that would fix it.
3. The model's part (917c): recognise a craft request, pick a source per
   material from the table, write the command; voice her replies.
4. The hunt as a standing instruction (917d) that survives relogs and ends
   on delivery or when the asker cancels.
5. Delivery by hand or by mail, per the asker's words.

## Open Questions

- (Answered 2026-09-25) Who plans: code does; the model routes the request
  to a buddy command and speaks. 917's rule holds.
- (Answered 2026-09-25) The model picks only from the source table code
  hands it.
- (Answered 2026-09-25) A material split across sources is two entries.
- (Answered 2026-09-25) Delivery (in person or by mail) is part of the
  "for whom" argument.
- (Answered 2026-09-25) A processed material is one entry per stage (mine
  the ore; smelt the bars).
- How is the source table kept cheap? Proposed: the unchanging parts
  (which nodes, monsters and vendors give each item) are built once at
  server start as item-to-source lists; per request only the live parts
  are read (auction prices, from the auction house the server already
  holds in memory) and distances are straight-line, with a real walking
  path computed only for the sources the model picks.
- Processing stages as separate entries: the earlier rule "a chain is
  judged as one unit" now means the table marks a stage as impossible if
  a stage it feeds is (no forge she can reach makes the ore pointless).
  Right reading?
- (Answered 2026-09-25) A failed step is re-attempted.
- (Answered 2026-09-25) Steps that can never succeed are caught before the
  hunt starts; she says why and offers what would fix it.
- (Answered 2026-09-25) Several hunts at once, interleaved by distance or
  effort; the limit waits on the buddies' memory design.
