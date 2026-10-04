# 617p - NPC Awareness: Buddies Notice and Use the People Around Them

## Status
- Created: 2026-10-03
- Phase: 6
- Parent: 617
- Blocked by: 617e4 (the town visit's errands), 617n (training)
- Related: 617e4a (town circles), 617h1 (the selling trip)
- Priority: Medium (needed before wow-chat's dynamic NPCs)

## Origin

The owner, 2026-10-03, after a buddy (Matis) had to be taught by hand
because a trainer spawned beside it was never used: "we should probably
make an issue file about this. The intended behavior is that they will
notice friendly NPCs within 100 yards and identify what capabilities that
NPC has - trainer, vendor, etc. If they can talk, they will go up and do
the talking animation, without standing at the same place as another
buddy-bot who is currently doing the same thing. So if we spawn a
trainer, they should walk up and train their abilities. The reason for
this is that when we apply the buddy-bot system to wow-chat, which is the
more custom version of wow-chat, we will have dynamically spawned NPCs
without any of the default ones. So they need to be able to handle
dynamic interactions, and, eventually, dynamic towns. But that won't be as
hard as you're thinking, no need to panic hehe :)"

## Current Behavior

Built 2026-10-03, changed the same day to the owner's visit-once answer;
compiles (syntax-checked), not yet tested in game.

- **Noticing** (`buddies_npcs.cpp`): every 5 seconds a roaming buddy with
  nothing else on looks at the creatures within 100 yards of itself. A
  person counts if it is alive, out of combat, owned by nobody, not
  hostile to the buddy, selectable, and offers a service or is humanoid.
  What it offers is read from the creature itself (service flags; for a
  class trainer, its lesson list), never from the spawn table.
- **Whom it goes to**: a need first, visited or not: lessons it can
  afford, then selling (bags past the selling share, 617h1), then repairs
  (an item under half durability, and money); the nearest person meeting
  it. Otherwise the nearest person not visited in the last 30 minutes.
  Each buddy remembers its visits in two buffers swapped every 15
  minutes server-wide (so for 15 to 30 minutes), from the moment it picks
  the person (so one it can't reach waits too).
- **Standing spots**: three per person, 3 yards in front of them,
  straight ahead and 0.7 radians to either side, claimed in a table shared
  by all buddies (held at most 90 seconds) and snapped onto the walkable
  mesh; a spot with no floor is released and that person skipped this
  time (no fallback spot).
- **On arrival** (`buddies_roam_strategy.cpp`, before the selling trip):
  it walks to its spot under the usual walking rules, gives up after 60
  seconds, faces the person, and then does everything they offer that it
  can use: lessons it can afford, selling what it doesn't need (any
  vendor), repairs of anything damaged (a repairer); with none of these,
  it chats (the talking gesture every 2 seconds for 4 to 9 seconds).
  Each step writes a trace line.
- Not done: meals bought, innkeepers, flight masters, bankers,
  auctioneers and profession trainers are not used.

## Intended Behavior

- **Noticing**: every few seconds a buddy out of combat looks at the
  friendly creatures within 100 yards and reads what each offers from the
  creature itself, not from the spawn table (so a creature spawned in game
  counts): class trainer, profession trainer, vendor, repairer,
  innkeeper, flight master, banker, auctioneer, quest giver, or just
  someone to talk to.
- **Using**: an offer the buddy needs now is used: lessons it can afford
  at a class trainer of its class (617n's rules: cheapest first, until the
  purse runs out), junk sold and meals bought at a vendor when its bags
  are past the selling share, repairs when its gear is worn down.
- **Visiting**: with no need, a buddy visits each person it notices once
  (remembered for 30 minutes) and decides on arrival what to do: sell
  what it doesn't need at a vendor, train at a trainer, repair at a
  repairer, or, with nothing to use, play the talking animation for a
  while.
- **One at a time**: each NPC has a few standing spots round it (in front,
  and to either side); a buddy takes a free one and holds it while it
  deals, so two buddies never stand in the same place at one NPC.
- **Anywhere**: in the country as well as in towns, so dynamic camps
  (wow-chat's spawned NPCs, and later its dynamic towns) work without any
  table of NPCs.

## Suggested Implementation Steps

1. The look: friendly creatures in range, each read for its offers from
   its own flags (the creature's NPC flags and trainer data).
2. The claims: standing spots round an NPC, claimed and released per
   buddy (as the beds' claims are held, `buddies_beds.cpp`).
3. The uses: training (617n's), selling and meals (617h1's), repair (the
   town visit's), and talking (the town visit's leisure), each a short
   errand run by the roam action or the town visit.
4. Trace lines for what was noticed and what was done.

## Open Questions

- (Answered 2026-10-03) Pulled away from the owner: "only if they need the
  NPC. For the RP talking, let's say that it only happens sometimes... Not
  sure how or when right now." So a need (training, selling, repair) may
  draw a buddy up to 100 yards; talking for its own sake is rare, and
  when is still open.
- (Answered 2026-10-03) Quest givers: "just pretend to talk".
- (Answered 2026-10-03, changes the design; not yet rebuilt) When to
  talk for its own sake: "3% doesn't seem like very much [...] I think
  they should visit each NPC at least once, and only test to see what
  they do the first time they arrive. If it's a vendor, they'll sell the
  stuff they don't need. If it's a trainer, they'll train up if they can.
  If it's just an NPC, they'll just talk to them. We should cycle out the
  remembered NPCs every 30 minutes or so. Is that a bad system? Maybe.
  Let's see how it goes." So: each buddy visits every person it notices
  once, deciding what to do only on arrival (sell, train, or talk), and
  remembers whom it has visited for about 30 minutes; the 3% roll goes.
- (Noted 2026-10-03) "Honestly the buddies are rarely right at your side
  haha, the 'areas' are pretty big that they roam in." So the 100 yards is
  round the buddy wherever it roams, not round its owner.

## Related Issues

- **617** parent; blocked by **617e4**, **617n**; related **617e4a**,
  **617h1**, **617d**
