# 617b - The Buddy Class Selector NPC

## Status
- Created: 2026-09-23
- Phase: 6
- Parent: 617
- Blocked by: 617a
- Priority: High

## Origin

Verbatim, 2026-09-23 (the full answer is in 617):

> an NPC menu, there should be one at the starting zone, and one that spawns
> near you and walks around, sits by a fire, tells jokes... But stays in the
> same area as you were when you leveled up. If you log out, then when you log
> back in they'll appear where you logged back in at. If there's more than two
> in an area (maybe 30 yards or so) then they won't spawn.

His name is **Sargobras** (Ritz, 2026-09-23). His jokes "should come from a
written list, but we have to add to it every once in a while": the list is
`src/lua-basic/data/sargobras-jokes.lua`, plain data, one joke per entry,
meant to grow.

And his life cycle, verbatim, 2026-09-23:

> yes that's the only selector at level 1. The wandering one which stays near
> a player UNTIL THEY CHOOSE, then he just hangs out near a nearby fire (that
> he spawns) until no players are within sight range, then he despawns. His
> task is to let you choose a new companion - once you've done so, then he
> waits until nobody's looking, then turns into a black dragon and flies away.
> We can just despawn him though, it happens offscreen.

## Current Behavior

No such NPC. Reference patterns in this project:

- **911's immortal shepherds**: a wandering NPC that is spawned at the
  player's logout position on login if not already in the world, and that
  won't despawn while a condition holds. The owner points at these as
  prior art for idle behavior, to be "a little distinct from".
- **705's custom-class selector NPCs**: a gossip NPC offering a choice,
  one per race, entries 900001–900011 (beta).
- The Phase 5 travellers: wandering NPCs driven by Lua.

## Intended Behavior

- **At every starting valley**: a stationary selector for the first buddy.
  (Every new character is owed one; 617a.)
- **Level 1**: only the stationary selector at the starting valley.
- **At each 10th level**: Sargobras spawns near the owner and stays near
  the owner, walking about and telling jokes, **until the owner chooses**.
  His menu offers the classes of the owner's faction; choosing one fills the
  owed slot (617a).
- **After the choice**: he spawns a campfire nearby and goes "on break":
  relaxed and aloof, lounging by the fire and telling his jokes, until no
  player is within sight range (the server's visibility distance, about
  100 yards outdoors), then despawns. (Ritz, 2026-09-23: "when he's
  waiting around the campfire, that's when he should tell jokes. He should
  be 'on break' so he should seem relaxed and aloof.") (In the story he
  turns into a black dragon and flies away; it happens offscreen, so a
  despawn is enough.)
- **Persistence**: while a slot is owed, he reappears near the owner at
  each login, wherever that is.
- **Crowding**: he does not spawn if more than two selectors are already
  within about 30 yards (several players levelling together).
- Only the owner can use their selector.

Built in Lua on basic's ALE (`src/lua-basic/`): a gossip NPC plus timed
idle behavior, calling 617a's creation function through a small bridge.

### Decision, 2026-09-25 (Ritz): where Sargobras stands

"He spawns where you levelled, and then he walks toward you to follow. He
stops when he's about 7 yards away, and he starts following you again if
you move 15 yards away. If you rotate around him, he will slowly (lerp
style) rotate toward you, but he'll only initiate such movement once every
5 seconds or so." So: spawn at the level-up spot; walk to about 7 yards;
stand until the owner is 15 yards away, then follow again; turn smoothly
to face the owner, starting a turn at most every 5 seconds.

### Decision, 2026-09-25 (Ritz): a class or a race; death knights skip him

"When talking to Sargobras, you can either request a specific class, or a
specific race, and he'll pick randomly for the option you didn't pick."
- His menu offers two paths: **pick a class** (the race is then drawn at
  random among the owner's faction's races that can play it) or **pick a
  race** (the class is then drawn at random among the classes that race
  can play). This replaces "his menu offers the classes" above.
- A random pick honours the tank-and-healer guarantee (617g): while the
  clan's buddies lack a tank or a healer, a random class is drawn from the
  classes that can fill the missing role.

"death knight players get death knight buddies. They don't get to pick
anything, Sargobras doesn't even show up for them. A random race and class
is chosen."
- For an owner who is a death knight, Sargobras never appears (neither the
  valley selector, which a death knight never visits, nor the one at every
  10th level). Each owed buddy is created straight away: a death knight
  of a random race (answered below).

## Suggested Implementation Steps

1. The NPC template (look per 617f) and its gossip menu: one line per class
   the owner's faction can play.
2. Spawn rules: valley spawns (static rows beside each Visiting Mentor,
   155e) and level-up spawns (Lua on level change: every 10th level, owner
   has an owed slot, fewer than three selectors within 30 yards).
3. Idle loop: wander within the area, sit by a campfire (spawn a temporary
   campfire object, or use one nearby), tell a joke to nearby players at
   intervals.
4. Login respawn while a slot is owed.
5. The bridge from the gossip choice to 617a's creation function.

## Related Issues

- **617**, **617a**, **617f** (his look)
- **911** shepherds, **705** class selectors — prior art
- **155e** Visiting Mentors — the valley selectors can stand beside them

## Open Questions

- (Answered 2026-09-23) Name: Sargobras. Jokes: a written list that grows.
- (Answered 2026-09-23) Level 1: the stationary valley selector only.
- (Answered 2026-09-23) Sight range: the server's visibility distance.
- (Answered 2026-09-25) Sargobras offers a class or a race; the other is
  drawn at random. Death knight owners never meet him.
- (Answered 2026-09-25) A death knight owner's buddies are all death
  knights, each of a random race ("death knight buddies for death knight
  players"). Basic's rule that no playerbot plays a death knight (148a)
  covers random bots; buddies are the exception.
- A clan of death knights can't meet the healer guarantee (617g): death
  knights can tank but can't heal. Does the guarantee skip death knight
  clans (a tank only), or does one buddy come as a healer class anyway?
