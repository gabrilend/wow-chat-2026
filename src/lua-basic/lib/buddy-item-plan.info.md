# buddy-item-plan.lua

Decides what a buddy means to do with each item the moment it picks it up,
and when those plans change (issue 617h2). Pure decisions: touches no
server object, so an ALE script and the offline test
(`scripts/test-buddy-item-plan`) run the same code.

## The plans

Tried in this order; the first that fits is the item's plan (decided
2026-11-06 in 617h2):

| plan         | for                                                        | settled            |
|--------------|------------------------------------------------------------|--------------------|
| `keep`       | the hearthstone, a profession tool, a fishing pole, a weapon it keeps as a runner-up | never     |
| `wear`       | an upgrade (the caller's judgement: `item.wear = "now"`)   | at once            |
| `open`       | a bag of coins, a clam, a lockbox it can open              | at once            |
| `learn`      | a recipe its profession and skill can learn, not yet known | at once            |
| `feed`       | food its pet's diet takes                                  | when the pet eats  |
| `use`        | a consumable, or anything with a "Use:"                    | when it is needed  |
| `craft`      | a reagent of a recipe it knows                             | when it crafts     |
| `give`       | something a clan-mate wants, if it can be traded           | at a mailbox       |
| `disenchant` | a bound item its enchanting skill can disenchant           | at once            |
| `auction`    | unbound greens and better, trade goods, recipes it can't learn | at an auction house |
| `vendor`     | everything else a vendor pays for                          | at a vendor        |
| `junk`       | what nobody pays for                                       | when bags fill (623) |

## Functions

### `Plan.decide(item, buddy) -> plan, why, to`
The plan for one item for the buddy as it is now, a short reason, and for
`give` the clan-mate's name. The facts each table carries are listed at
the top of the file.

### `Plan.new(buddy) -> state`
A buddy's plans: `state.bag` (held items with their plans, in the order
picked up) and `state.wants` (each `saving` or `ready`).

### `Plan.pickup(state, item) -> entry, changes, wants, now`
Decides the new item's plan. `now` is true for a plan settled at once (the
caller does it in the game; the item never enters `state.bag`). Only a
recipe learned changes held plans (its reagents become `craft`):
`changes` lists each `{ entry, from, to }`. `wants` lists each want that
turned `ready` or back, a want being ready once the money on hand and the
planned sales (the vendor price, or the auction estimate, `item.auction`,
else three times the vendor price) cover it, cheapest want first.

### `Plan.login(buddy, items) -> state, done`
Works every plan out again from the bags' contents, in any order (plans
are not kept across a restart). `done` lists the items whose plan is now
settled at once (a recipe it has since become able to learn).

### `Plan.settle(state, place) -> deeds`
At `"vendor"`, `"auction"` or `"mailbox"`: every held item planned for
that place leaves the bag as a deed `{ act, entry }`, its value counted
into the money; at the auction house each ready want the money covers is
bought, `{ act = "buy", want }`.

### `Plan.room_order(state) -> list of entries`
With full bags (617j4): the held items that may be destroyed, least worth
first. Grey junk first; then part-stacks of common trade goods and food it
also holds a full stack of; then the rest, by plan (`junk`, `vendor`,
`auction`, `give`, `feed`, `craft`, `use`). Within each, part-stacks
before full stacks, then the cheapest (vendor price times the stack); ties
in bag order. Never listed: a `keep` plan, a need-won item
(`item.need_won`), a quest item.

### `Plan.make_room(state, item) -> entry | nil, why`
The buddy must take `item` and has no free slot: destroys (removes from
the bag) and returns the first of `room_order`. Returns nil when nothing
may go, or when `item` would itself come no later than that first (it is
left behind). An item settled at once (an upgrade, something to open or
learn) or one that may never go always gets room when anything may.

### `Plan.value(item, plan) -> copper`
What a whole stack is expected to bring under a plan (0 unless `auction`
or `vendor`).

## Where this fits

Not called by a game script yet: the C++ town errands (`buddies_town.cpp`)
still sell by their own rules. Hooking pickups and town stops to this
module, and the catalogue of every item a buddy can come by (built from the
world database), are 617h2's remaining steps.
