# 810 - The Long Run: Maraudon and Dire Maul as One Raid

## Status
- Created: 2026-10-04
- Phase: 8
- Profile: basic
- Priority: Low
- Related: 617s6 (moving buddies by group), 617o (navigation mesh), 155z2
  (lanes: the pacing idea's cousin)

## Origin

Verbatim, 2026-10-04:

> question... Is the various Maraudon and Dire Maul dungeons connected or
> on the same map in any way? Can we create a connection between them? I'm
> thinking we could make the entire dungeon collection into a raid, where
> if you're going faster (proportionally) than the other side, you get a
> tougher enemy to fight until you slow down, and the other starts keeping
> pace with you. Then you can speed up until you face something that you
> can't. Then, you are expected to swap characters, which you can do by
> simply moving them into a different raid group. You teleport to the
> centroid between your allies, on the closest spot on the pathable grid
> that is also within an un-obstructed 10-yard straight-line path.
>
> Note, it should never hurt you when your allies are doing well. It
> should challenge them more, as they escalate their fights. So, emphasize
> the level difference over spans.

## Current Behavior

Not built. Maraudon (map 349, entrance in Desolace) and Dire Maul (map
429, entrance in Feralas) are separate instance maps with no connection;
their zones border each other. Each has several wings (Maraudon: the
orange and purple wings and the inner caverns; Dire Maul: east, west and
north).

## Intended Behavior

One raid across both: a raid group's sub-groups run different wings at
once, joined by portals between the two instances.

- **Pacing by progress**: each side's progress is its share of its own
  wing done (bosses or packs cleared, proportionally). A side ahead of the
  others meets tougher enemies (raised levels) until the others catch up;
  a side behind is never made harder by its allies' speed. The difficulty
  rises in level steps over spans of progress ("emphasize the level
  difference over spans").
- **Swapping characters**: moving a character into another sub-group
  moves it to that group (owner, 2026-10-04: "at most 10 yards to the
  point of the nearest group member. So they are teleported 10 yards away,
  at the closest spot to their spot."): it appears within 10 yards of the
  new group's member nearest the middle of that group, on the walkable
  spot (navigation mesh) closest to that member with a clear straight line
  to them.
- A side that meets what it can't beat is expected to swap characters,
  not to stall the others.

### Terms, and more rulings, 2026-10-04

"what's the difference between 'parallel' and 'raids'? characters are
split between entrances, or perhaps in a sister dungeon progressing at
the same time, with a shared party chat and coordination... and the
ability to easily switch groups, so you can put the correct attackers and
defenders to the right tasks." There is one thing, the joined run: a raid
group whose parties progress at the same time, sharing raid chat, any
character movable between parties (the swap above), the pacing between
them. The words in the table say only how a dungeon holds it: "parallel"
= its own map has separate paths, one party each; "single" = one route,
so it joins a run only beside a sister dungeon or by doubling (below);
"a raid" (Uldaman, Sunken Temple) = the owner's word for the same joined
run, there by whole-dungeon size.

**Players together first** (owner, 2026-10-07): "players should be
initially placed into groups with each other ... with the buddy-bots
filling any empty space? It's more fun to play with players. They can
adjust the groups later as the raid goes on." When a joined run forms,
its players are packed into parties together before any buddy is placed.
Buddies then fill the empty seats. Players move characters between
parties afterwards with the swap above.

- **The Stockade** ("can we spawn the players on the inside, one in each
  wing, depending on which raid group they're in? They can meet up in the
  middle. There should be twice as many enemies in the middle sections."):
  each party appears inside at the far end of its own wing, by its party
  number; they meet in the middle; the middle sections hold twice their
  stock enemies.
- **Zul'Farrak**: "a loop, so, let's say it's serial" (single).
- **Razorfen Downs**: single, "but if you wanted we could double the player
  count and double the number of creature monsters".
- **Scholomance**: "a dungeon for now".
- **Blackrock Spire**: "UBRS and LBRS are combined, and each one is level
  adjusted such that LBRS has the same level range as UBRS, which is the
  range from their current minimum to their current maximum. And each one
  will be affected by the buff/debuff system." One run across both
  halves, each spanning the levels from the lowest of either to the
  highest of either, both under the pacing.
- **Blackrock Depths** (owner, 2026-10-04: "can we have one path be prison
  and ring of law, then they fight their way to the tavern and everyone
  inside is hostile. The second party starts in the tavern, and everyone
  is friendly. Second party goes through forges and vaults. Inner city and
  throne are a third route, for a total of 15 players. We need to make
  sure there's the same amount of item drops on each route ... We should
  drop more items from characters who have large loot pools. Also, rare
  elites should always spawn, and they should be included in these
  calculations. ... Each BRD boss should give a minimum of 1.0 items per
  fight"): three parties of five.
  - Route 1, prison and Ring of Law, fighting into the tavern, whose people
    are hostile to this party: Gerstahn 1, Lord Roccor 2, Houndmaster
    Grebmar 1, the Ring of Law champion 2, Hurley Blackbreath 1, Phalanx
    1, Plugger Spazzring 1, Ribbly Screwspigot 1: 10 drops.
  - Route 2, starting in the tavern among friends, through the forges and
    the vaults: Bael'Gar, Fineous Darkvire, Lord Incendius, General
    Angerforge, Golem Lord Argelmach, Warder Stilgiss, Verek and Watchman
    Doomgrip 1 each, Pyromancer Loregrain (rare, always there) 2: 10 drops.
  - Route 3, the inner city and the throne: Ambassador Flamelash 1, the
    Seven 2, Magmus 1, Princess Moira 1, Emperor Thaurissan 3, Panzor the
    Invincible (rare, always there) 2: 10 drops.
  Proposed drops per kill, every boss at least 1, the most varied (the
  Emperor: 11 possible; the Seven: 8; Roccor: 6; the rares' large shared
  pools) more, each route 10. Drawn from a scratch count of the loot
  tables (expected green-or-better drops per kill and possible items per
  boss); bosses placed on routes from memory of the map, to be checked.
  Open: the tavern being hostile to one party and friendly to another at
  once (questions below).

## Suggested Implementation Steps

1. Portals linking the two instances' entrances (an instance-to-instance
   teleport), the raid sized for several sub-groups.
2. Progress per side, and the level steps it drives (applied to monsters
   not yet engaged, when a side pulls ahead).
3. The sub-group move: centroid, mesh, the 10-yard clear line.
4. A test raid of two sub-groups, one deliberately faster.

## Open Questions

1. (Answered in part 2026-10-04) "each tier is joined to the same one. So
   Maraudon has many parallel paths through it, right? Same for Dire Maul.
   Also Scarlet Monastery. You could argue Razorfen Kraul and Downs.
   Possibly others... WC is parallelizable, go left at the T or right, team
   up for the murloc fight... But SFK is not parallelizable, there's only
   one route through. Can you ask me about various dungeons and I'll
   provide a final ruling?" So: a raid is a tier of dungeons joined
   together, its sides the parallel paths through them; each dungeon is
   put to the owner for a ruling (the table below, answers pending).

   | Dungeon | Parallel paths (from memory of the stock maps) | Ruling |
   |---|---|---|
   | Ragefire Chasm | one route | single (owner) |
   | Wailing Caverns | left or right at the fork, together for Mutanus | parallel (owner) |
   | The Deadmines | one route | single (owner) |
   | Shadowfang Keep | one route | not parallel (owner) |
   | Blackfathom Deeps | mostly one route, a few side rooms | single (owner) |
   | The Stockade | two halls off one corridor | parallel (owner) |
   | Gnomeregan | front and back entrances meet partway | parallel (owner) |
   | Razorfen Kraul | branching tunnels | parallel once its labyrinth is populated (owner; 811) |
   | Scarlet Monastery | four separate wings: Graveyard, Library, Armory, Cathedral | parallel (owner) |
   | Razorfen Downs | mostly one route | single; or doubled players and monsters (owner) |
   | Uldaman | two entrances, then mostly one route | a raid (owner) |
   | Zul'Farrak | an open courtyard, bosses in any order | single (owner: a loop, serial) |
   | Maraudon | three wings: orange, purple, inner | parallel (owner) |
   | Sunken Temple | ring of rooms, a few in any order | a raid (owner) |
   | Blackrock Depths | many branches, much in any order | parallel (owner: "definitely") |
   | Lower Blackrock Spire | branches, a few in any order | parallel (owner) |
   | Upper Blackrock Spire | one route | joined with Lower Blackrock Spire, one level range (owner) |
   | Dire Maul | three wings: east, west, north | parallel (owner) |
   | Scholomance | a ring of rooms, several in any order | a dungeon for now (owner) |
   | Stratholme | two halves: living and undead sides | parallel (owner: "yesssss") |

2. How large is a level step, and over what span of progress? (Owner,
   2026-10-04, on the labyrinth: "not sure about the scaling on it...")
4. (Answered 2026-10-04) The tavern: hostile to route 1's party, friendly
   to route 2's, at once ("yes they'll probably never be in the same room
   at the same time so"): its people's attitude is per party.
5. (Answered in part 2026-10-04) The pacing step: "should be very harder to
   encourage pacing": a lead makes monsters much harder, steep enough that
   pulling ahead stops paying. The exact step is still to choose.
6. (Answered 2026-10-04) Shared need/greed across the whole joined run:
   "ideally, yes". Each item a run drops is rolled on by every member of
   the run, wherever they are: another room, another instance ("different
   instance too"), even another server ("Might even be on a different
   server": the clustered worldservers of 913). The winner gets it in
   their bags. Per person the loot is the same on average (15 times the
   items for 15 times the people); items land with whoever wants them
   most across all routes; each person sees about three times as many
   roll windows.
7. The pacing step (owner: "what do you mean 10 points? Like... 10 percent
   more of the way through the raid? Maybe every 20 percent... How about
   it starts at 10 % and scales up to 20% over the course of the dungeon.
   So early bosses have less of a penalty, but later bosses are much
   stronger unless your allies are also attacking their core."): progress
   is the share of a route done; a side ahead of the slowest by a lead
   makes its monsters not yet fighting stronger by 10% near the start of
   the dungeon, rising to 20% near the end. Open: is that 10-20% per step
   of lead (every 10 points ahead?) or for any lead at all? (Owner: "I don't
   knoooooowwwww".) Proposed as the first setting to try, then tuned in
   the balance log: per 10 points of lead ahead of the slowest side,
   monsters not yet fighting gain 10% health and damage near the start of
   the dungeon, rising to 20% near the end; stats rather than levels,
   because level gaps also change hit and crit chances (and basic caps
   those gaps at 3, B005), which makes levels a lumpier dial.
8. Where is a section's edge, when parallel routes share corridors (as
   in Blackrock Depths)? The set of rooms on a route, a list of the
   server's subzones, or the stretch up to that party's next boss? Buddies
   help allies only inside their own section (617e5), so the buddies need
   the edge as data. (Owner, 2026-10-07: decided here, when this issue is
   built.)
3. Its level and loot place on the ladder?
