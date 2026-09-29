# 617e4 - Town Visits

## Status
- Created: 2026-09-27
- Phase: 6
- Parent: 617e
- Blocked by: 617e1 (the roam strategy and its pass)
- Priority: High (owner, 2026-09-27: "can we build town behavior next?")

## Current Behavior

**Built 2026-09-27; compile-checked against the last beta build's
settings, not yet run** (`modules/mod-buddies/src/buddies_town.cpp`,
`buddies_town.h`; wired in `buddies_roam_strategy.cpp` and
`buddies_party.cpp`).

- **Two bot-module behaviours**, each a strategy with one always-due
  trigger and one action, taught to the bot module with "buddy roam" in
  the strategy file's three name lists:
  - **"buddy travel"** (relevance 3.5: above roaming, below fighting and
    looting), on everywhere: when a buddy stands in another named area than
    its owner on the same map, it runs toward the owner with the bot
    module's long walk (`NewRpgBaseAction::MoveFarTo`, navigation-mesh
    routed, re-aimed at the owner each step) until it is in the owner's
    area; roaming (617e1) stands aside meanwhile. A different map (another
    continent, an instance) is not walked: logged once per buddy, it stays
    put. **Unstuck** (2026-09-27): playerbots' own recovery (after 90
    seconds without progress, put at the destination) is switched off by
    resetting its stuck clock (`rpgInfo.stuckTs`, public) before each step;
    instead, no 10-yard gain toward the owner in 90 seconds (5 until the
    owner's "let's make it 10", logged in `docs/balance-updates.md`) moves the buddy
    to a random walkable spot within 30 yards (ground within 15 yards of
    its height, not under water, in its line of sight; 12 tries, logged),
    and it walks on.
  - **"buddy town"** (relevance 3.0), on in towns: walking (not running);
    on entering a town, a to-do list from the town's people within 150
    yards (same area id) by NPC flag, nearest of each: its **class trainer**
    when it has something to learn (a class-type trainer for its class
    with a spell it can be taught now), a **vendor** with odds equal to how
    full its bags are when it carries anything to sell (grey items, and
    what the bot module's own "item usage" judgement would sell to a
    vendor; things it would auction are kept for 617h), a **repairer** when
    anything worn is damaged. Each errand: walk to within 3.5 yards, face
    the NPC, a talking animation, then the errand **done silently** with the
    server's own calls (training `Trainer::TeachSpell`, paid; selling as
    the client's sell request; repairing `DurabilityRepairAll` with the
    reputation discount). The bot module's own sell, repair and trainer
    actions were not used: each whispers the owner every step, and the
    owner wants no chat.
  - **Leisure** when the list is done, by weights 60 / 30 / 10 / 15
    (townsperson, chair, sleep, fishing):
    - a **townsperson** within 60 yards (humanoid or with a service, not
      hostile, not a critter or pet): stand 2.5 yards off, facing it,
      talking animations (talk, question, exclamation, laugh, yes, no)
      every 3 to 7 seconds for 10 to 25 seconds; never a chat line;
    - a **chair** (chair-type game object in the area): the one with the
      most company (townspeople and buddies within 8 yards), random among
      ties; sit (the server seats a player on the chair's nearest free
      place), eat, laugh and talk animations, 1 to 3 minutes. **Shared
      timers**: sitting down sets the end of every buddy seated within 6
      yards to the newcomer's, so they leave together and a newcomer resets
      it for all;
    - **sleep**, only on a spot placed by hand for this town
      (`buddies_beds.cpp`, table `buddy_bed`, install step E045): the best
      free spot by comfort tier, **3 bed** (a mattress) before **2 cot**
      before **1 floor** (a rug, a bedroll, the ground), at random among
      equals, claimed so no other buddy takes it; walk to its recorded
      spot, face the recorded way, lie down 1 to 4 minutes. **Linked
      spots** (the table's `link` column; spots sharing a number are one
      bed, a double bed): a spot of a linked bed is refused while a buddy of
      another clan (another owner's) holds any spot of it, so clanmates
      share it and outsiders go to the cot, the rug or the next room. A
      town with no spots recorded has no sleeping (the floor by the
      innkeeper, built first, was dropped: "proper beds"). The owner places
      the spots in game, as a game master standing on each: `.buddy bed add
      <bed|cot|floor> [note]` (also 3/2/1), `.buddy bed list` (the area's
      spots, nearest first, with tier and link), `.buddy bed remove`
      (nearest within 10 yards), `.buddy bed link` (the nearest spot joins
      the next nearest's bed, or the two start one; both within 5 yards),
      `.buddy bed unlink` (the nearest within 5 yards stands alone again);
      `scripts/export-buddy-beds` copies the live rows, tier and link
      included, into the install file between its BEDS markers, so they are
      kept in the project (none recorded yet). The install step keeps
      placed spots: a table made before the tiers gains the two columns
      through guarded changes (each runs only when its column is missing;
      checked: an old row survives two applies as tier 1, unlinked);
    - **fishing**, where the town has water: water found within 60 yards
      (the bot module's own finder, `FindWaterRadial`) that lies inside the
      town's own named area, a shore spot from which it is in casting reach
      (`FindLandFromPosition`), the fishing skill and a pole. Walk there,
      the pole into the main hand (what it held is remembered and put back
      after), then 10 to 30 casts (drawn each visit): face the water, cast
      Fishing (7620), and when the bobber turns ready use it, which loots
      the catch (the bot module's own "store loot" keeps it); a cast that
      ends without a bite counts too. Ends when the casts are done, or after
      15 minutes.
    A pastime not reached within a minute is dropped; 3 to 8 seconds'
    pause between pastimes. Each buddy's town state is in a locked table.
- **The pass**: in towns `-follow, -buddy roam, -grind, +buddy travel,
  +buddy town`; in the open as 617e1 plus `+buddy travel, -buddy town`,
  and a buddy still walking is set running.
- **Ungrouped in towns** (`buddies_party.cpp`): while the owner is in a
  town, each buddy leaves the owner's group and its far party (only the
  buddies leave a group with other players in it); grouping by distance
  resumes outside.
- Every number above is in one constants block at the top of
  `buddies_town.cpp`; tuning goes to `docs/balance-updates.md`.

**Training money** is the buddy's own: no gold cheat is given, and a
buddy that can't pay learns nothing that visit.

**Mounts in town**: allowed. A mounted buddy in town walks its mount (the
town's walking applies mounted or not); players are not restricted (155w
withdrawn 2026-09-27; its dismount and cast refusal were removed from
`src/cpp-basic/basic_rules.cpp`).

**Rest without food** (`buddies_roam_strategy.cpp`, while roaming): a
buddy that rolls a rest and carries nothing to eat or drink lights a
campfire (Basic Campfire, 818, taught with Cooking; in this version the
spell has no reagents or tools, so every buddy can, where the server
allows the cast) and sits until its health (and mana, for mana users) are
full by ordinary regeneration, with no time cap: a fight ends it, and so
does the owner leaving the area (the roaming state starts afresh on the
owner's new area). Having no food is logged once per buddy. A meal with
food keeps its 2-minute guard (a serving that never starts, logged), since
eating should never take that long.

**Beds, empty doubles first**: within a comfort tier, a spot of a wholly
empty double bed is taken before a single spot, so a clanmate may join
(`BuddyBedIsEmptyDouble`, `buddies_beds.cpp`); comfort still comes first.

Not built: 617h's errands (auction house, mailbox), the hearthstone
behaviour (617e, 2026-09-25), walking between maps, towns entered by a
buddy left out of a dungeon (617c3).

Before: in a town or city (area flags town 0x00200000, capital 0x00000100,
capital subzone 0x00000008, checked on the owner's area) the roam pass
put a buddy back on playerbots' `follow`.

## Intended Behavior

Everything here is from the owner's decisions recorded in 617e (2026-09-23,
-25, -27); this issue builds them.

- **Buddies go where the owner goes** ("the buddy-bots will move to
  whatever area you're in and explore there. So if you move to town, then
  they move there as well"): when the owner's area changes, a buddy walks
  there as a player would (not a teleport), and starts that area's
  behaviour on arrival: roaming outside towns, this issue's visit inside.
- **Ungrouped in towns** (617c): a buddy leaves the owner's group and its
  far party on entering a town; the grouping pass resumes outside.
- **Walks, never runs**, in town.
- **The to-do list first**, built from what the town actually has ("some
  towns don't even have repair stations"): the services found among the
  town's NPCs by their flags (repair, the buddy's class trainer, vendor,
  mailbox, auction house), in 617h's order where it applies:
  - its class trainer first, when it has spells it could learn;
  - a vendor, with priority equal to how full its bags are, selling what
    the bot module already counts as junk;
  - repair when anything is worn;
  - others as 617h adds them.
  Each errand: walk to the NPC, face it, a talking animation, the errand
  done (playerbots' own sell / repair / learn actions where they exist).
- **Leisure when the list is done** (and whenever a buddy is in a town:
  left out of a dungeon, or with its owner there):
  - it walks to a random townsperson, stands facing it, plays talking
    animations (never a line in the chat window), then another;
  - sometimes it sits on a chair near other NPCs or buddies and stays a
    long while: eats, drinks, laughs, talks;
  - **shared timers**: buddies seated together all leave when the
    latest-to-arrive's timer ends; a newcomer resets it for everyone;
  - sometimes it sleeps on a bed.
- Numbers to tune (balance file): how long at a townsperson, the chance
  and length of sitting and sleeping, the chair search radius.

### Decisions, 2026-09-27 (Ritz): beds, fishing, getting unstuck, money, mounts

- **Proper beds, placed by hand**: "proper beds. But we can manually place
  those, I don't think there's data for them in the game yet." A table of
  bed spots (map, position, facing, the inn's area) that buddies sleep on,
  filled by a game-master command that records where the GM stands and
  faces; no sleeping on the floor. Until a town has beds, its buddies
  don't sleep.
- **Fishing in towns**: all buddies know cooking, first aid and fishing
  (617k); "one of the things they can do in towns is fish, if there's a
  body of water within it's borders. It's okay if they don't catch
  anything good, it's about the experience. They'll do at least 10 casts
  before moving on, up to 30." A leisure choice when the town has water
  a buddy can reach the edge of.
- **Getting unstuck**: "should teleport them to a random spot within 30
  yards, like the unstuck command." A buddy that makes no progress on a
  long walk for 90 seconds is moved to a random walkable spot within 30
  yards of where it stands (not to its destination), and walks on.
- **Training money is earned**: no gold cheat; a buddy trains when its own
  money allows.
- **No mounts in towns, for anyone**: "nah, even for players" (155w).

### Decisions, 2026-09-27 (Ritz): bed priority, fishing, unstuck, mounts, no food

> Can we also add a priority for the bed system? If someone's sleeping in
> the feather pillow mattress, but there's a cot off to the side and a rug
> on the ground, I'd prefer the cot over the rug. But if 3 people wanna
> sleep, then one's going on the ground. For future work, we should be
> able to connect sleeping spots to each other, so that if it's a
> double-bed, clanmembers can sleep together but outsiders wouldn't pick
> that particular spot, and would instead do the cot or the rug or the bed
> in the next room over.

> [unstuck:] let's make it 10

> [beds, who places them:] I'll place them

> [a buddy stuck again after being moved:] the player can always rescue
> them with a hearthstone cast.

> [no food:] they should still sit, ideally starting a fire, and wait until
> their health regenerates naturally.

> maybe mounts should be allowed in town actually, but they have to walk
> when mounted? No restrictions on player behavior.

- **Bed priority**: each bed spot has a comfort tier (a mattress above a
  cot above a rug on the ground); a buddy takes the best free spot, so
  with three sleepers and those three spots, the third sleeps on the rug.
  The game master gives the tier when placing it. **Linked spots**
  (future): spots joined into one bed (a double bed); a clanmate may take
  the second spot beside a clanmate, an outsider never takes a spot of a
  bed someone else's clan is using.
- **Unstuck**: less than 10 yards gained in 90 seconds (was 5).
- **Beds are placed by the owner**, in game, with the command.
- **Stuck again after the move**: the owner's hearthstone rescues it.
- **No food**: the buddy still rests: it sits, lights a campfire if it
  can (the cooking fire), and waits until its health (and mana) are back
  by the ordinary regeneration of sitting.
- **Mounts in town**: allowed; a buddy riding in town walks its mount.
  Players are not restricted at all: 155w's dismount and refusal are
  withdrawn.
- **Fishing** stays the module's own (the owner asked what playerbots'
  looks like: its "master fishing" fishes near the owner when the owner
  fishes, walks to water near them, prefers a fishing pool, casts, clicks
  the bobber, stops with no water near; its only chat is a whisper when it
  has no pole, which buddies now always have). Kept ours for the town's
  borders, the 10 to 30 casts, and putting the weapons back.

### Decisions, 2026-09-27 (Ritz): resting has no cap; empty double beds first

- "there's no cap on how long to rest. The player moving from the zone is
  enough to interrupt the rest." A buddy resting without food sits until
  health (and mana) are full, a fight starts, or its owner leaves the area.
- "yeah, maybe one of their clanmates will join them": a wholly empty
  double bed is preferred over a single spot of the same comfort, so a
  clanmate may take the other half.

## Suggested Implementation Steps

1. Area-change travel: when a buddy's area differs from the owner's, walk
   it to the owner's area (playerbots' long walk, `MoveFarTo`-style, mmap
   routed), then begin there.
2. The town's services: scan the town's creatures by NPC flags once per
   visit; build the buddy's to-do list; the errand walker (walk speed).
3. Leisure: townspeople visits, chairs (chair-type game objects), beds,
   the shared seat timers per chair group, the emotes (talk, laugh, eat,
   drink, sleep).
4. The pass: in towns, `-follow,-buddy roam,-grind,+buddy town`; outside,
   as 617e1.
5. In game: owner walks into Goldshire; buddies follow on foot, sell junk
   and train, then visit townspeople and the inn's chairs.

## Open Questions

- (Answered 2026-09-27) The long walk's teleport: replaced by a teleport
  to a random spot within 30 yards, "like the unstuck command".
- **Seated animations**: does a talking or eating animation played on a
  seated player look seated in the client, or stand it up for the
  animation? To check in game; if it stands up, seated buddies should use
  only the seated states.
- (Answered 2026-09-27) Beds: proper beds, placed by hand (built above).
- (Answered 2026-09-27) The trainer costs money: earned, no cheat.
- (Answered 2026-09-27) Town mounts: none, for anyone (155w).
- **Beds to record**: which inns first (Goldshire's Lion's Pride Inn is
  the owner's usual test town), and who places them (a GM session with
  `.buddy bed add`).
- **Fishing reach**: the shore spot is the first dry point back from the
  water found; if that spot can't reach water 10 to 20 yards out, the
  visit is dropped. How often that happens in real towns is to be seen in
  game.
- **The unstuck spot**: it is checked for ground, water and line of sight
  from the buddy, not for a path onward; a buddy moved into a nook may be
  stuck again 90 seconds later (and moved again).

## Related Issues

- **617e** parent; **617e1**; **617h** errand order; **617c2** ungrouping
