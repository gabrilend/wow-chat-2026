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
3. **Planning the hunt.** For each missing material the model picks a
   source (gathering node, monster drop, vendor, auction house) from the
   source table, one entry per processing stage (ore to bar, bar to a
   part, part to the item).
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
  hands it (Ritz, 2026-09-25): per material, every source that exists in
  the game's data, with its distance and its price. Distance and price are
  the two weights; the model weighs them with what the asker said
  ("quickly"). The table makes no judgement of whether a source is wise
  (see "Mistakes are hers").
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
- **Re-weaving** (Ritz, 2026-09-25): with hunts A, B and C woven as
  ABACCBAB, an update to A takes A out, and the route is rebuilt with the
  new A (perhaps ACABACBB). Ritz first described two passes (weave B and C
  alone, then fit the new A in) and asked whether the middle pass could be
  skipped. It can: weaving the new set in one pass from scratch is at
  least as good as the two-pass route, since the two-pass route is one of
  the orders the single pass considers. The one thing kept fixed is the
  step she is in the middle of (half a walk to a vein is finished, not
  thrown away), and stage order within a hunt (mine before smelt).

### Three active hunts, the rest on a backlog (Ritz, 2026-09-25)

> how about more than 3 requests (the 4th, 5th, etc) get added to a
> backlog, and if they share any materials required with any of the active
> tasks, then the required number of materials to gather / buy / craft /
> whatever is increased to account for it. Then, when a task is completed
> and it's 4 in the backlog instead of 5, with 2 active and 2 on the
> shelf, when we add the third one we'll just make the source be the
> backpack for the materials we managed to grab along the way. The cost is
> just, mining 12 copper ore instead of 6.

- At most **3 hunts are active** (woven into the route); any further
  requests wait on a **backlog**, in order. This keeps the route short
  enough to weave well.
- A backlogged hunt that needs a material an active hunt is already
  fetching adds its count to that active step (mine 12 copper ore instead
  of 6).
- When an active hunt finishes, the next backlogged one becomes active;
  for materials already fetched on its behalf, its source becomes the
  backpack.

### Out of reach (Ritz, 2026-09-25)

- A source is **out of her reach** when it lies in a zone whose level is
  more than 3 above the buddy's own (zone levels from the list 617k
  builds). Then she says Ritz's line instead of going: "Sorry, I can't do
  that right now because of ABC. Do you want to
  [do-thing-that-resolves-the-task]?", e.g. "do you want to level up some
  more with me?" or, for a source inside a dungeon, "do you want to do
  that dungeon?"
- **Never Outland.** A buddy never goes into Outland for a hunt: on basic,
  Outland has no herb or ore nodes, no fishing pools or gas clouds, and
  its own beasts can't be skinned (155n), and every profession stops at
  300, whose materials come from Azeroth. The level rule alone would not
  cover it: Outland's first zones sit near level 60 on basic.

### Performance of the source table (Ritz, 2026-09-25)

"we should pay special attention to the performance demands of gathering
so much data." A table for one recipe touches every node spawn, monster
loot list and vendor list that has any of its materials, plus the auction
house and walking distances. Built in three tiers by how often each part
changes (agreed 2026-09-25):

1. **At server start, once**: item-to-source lists for the unchanging
   parts: for every material used by any recipe, the node spawn spots, the
   monsters whose loot (following reference loot tables) contains it, and
   the vendors that sell it. A lookup is then one index read, not a scan
   of the spawn, loot and vendor tables.
2. **Per request**: auction prices (read from the auction house the server
   already holds in memory), and sources ranked by straight-line distance.
3. **Only for the sources the model picks**: the real walking path on the
   navigation mesh (one to five paths per hunt, not dozens).

Requests are occasional, never a tight loop. If straight-line ranking
misleads near mountains and water, a later knob is a small penalty for a
line crossing a zone boundary or a large height change.

### Mistakes are hers (Ritz, 2026-09-25)

> As for marking tasks impossible, I don't think we should allow that as a
> possibility at all. Everything should be fairly rigidly defined in the
> game, if the model mis-produces a task list or something then the bot
> will just make a mistake. "oops, I forgot to check the auction house
> before I left Orgrimmar to go mining" or whatever.

- The source table lists what the game's data says exists, and nothing
  more: no "can't" marks, no pruning.
- If the model routes badly, the buddy carries out the bad route and
  notices in character when it goes wrong ("oops, I forgot to check the
  auction house before I left Orgrimmar to go mining").
- Facts the game states flatly still stop a request before it starts:
  - no source anywhere in the game's data (no vendor, nothing at the
    auction house, no node or drop): "I don't see any [item] on the
    auction house, and I'm not sure where to get them.";
  - recipe not learned: "I don't have that recipe trained yet, sorry" (a
    line that fits other situations too).

Steps that fail this time (a node taken, an auction bought first, a vendor
sold out, a death on the road, full bags) are re-attempted.

## Suggested Implementation Steps

1. The craft command (item; recipient and delivery; one entry per
   material per source, one per processing stage), usable without the
   model (by a chat command) so hunts can be tested before 917 exists.
   Replacing or removing one command at once, re-weaving the route.
2. The source table, in code: expand a recipe into its material tree and,
   for each material, list the sources she could use with their distance
   and auction or vendor price, in the three tiers above (item-to-source
   lists built at start from the spell data, spawn, loot and vendor
   tables; auction prices and straight-line ranking per request; walking
   paths only for picked sources). No feasibility marks.
   Re-weaving: one pass over the current set of hunts, keeping the step in
   progress and each hunt's stage order.
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
- (Answered 2026-09-25, Ritz: "Great looks delicious.") The source table
  is kept cheap in three tiers; see "Performance of the source table".
- (Answered 2026-09-25) Nothing is marked impossible; the "chain is one
  unit" rule is dropped. A bad route is the buddy's in-character mistake.
- (Answered 2026-09-25) Re-weaving after an update is one pass over the
  new set, keeping the step in progress.
- (Answered 2026-09-25) A failed step is re-attempted.
- (Answered 2026-09-25) Out of reach: a zone more than 3 levels above the
  buddy, or inside a dungeon; she asks instead of going. Never Outland.
- (Answered 2026-09-25) At most 3 active hunts; more wait on a backlog,
  whose shared materials are fetched early by the active steps.
- Outland exceptions: some materials for recipes at or below 300 do come
  from Outland on basic. Wrath uncommon and rare gems drop from about 1,000
  Outland monster loot tables (155p), and Outland gems drop there too; both
  also have Azeroth sources (the titan jewelers' crystal trade; prospecting
  mithril and thorium). And when the owner is already in Outland, the
  nearest vendor for thread, flux or vials is an Outland one. Does "never
  Outland" mean never *travel into* Outland for a hunt (so a buddy already
  there with her owner may use its vendors and monsters), or never use an
  Outland source at all?
- (Answered 2026-09-25) Several hunts at once, interleaved by distance or
  effort; the limit waits on the buddies' memory design.
