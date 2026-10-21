# 617b - The Buddy Class Selector NPC

## Status
- Created: 2026-09-23
- Phase: 6
- Parent: 617
- Blocked by: 617a
- Sub-issues: 617b1 (buddy entrance), 617b2 (whisper Sargobras)
- Related: 620c (alt bots and random bots ask Sargobras by themselves)
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
`patches/E066-sargobras/.own/data/sargobras-jokes.lua`, plain data, one joke per entry,
meant to grow.

And his life cycle, verbatim, 2026-09-23:

> yes that's the only selector at level 1. The wandering one which stays near
> a player UNTIL THEY CHOOSE, then he just hangs out near a nearby fire (that
> he spawns) until no players are within sight range, then he despawns. His
> task is to let you choose a new companion - once you've done so, then he
> waits until nobody's looking, then turns into a black dragon and flies away.
> We can just despawn him though, it happens offscreen.

The valley Sargobras, 2026-10-13 (verbatim), after he was moved off the
quest giver he stood on in every valley:

> we will adjust dynamically later on. For now, just make Sargobras look
> at the player. Each player should see their own Sargobras, the rest
> should be invisible. And theirs should always be looking at them. At
> least until they choose a character, then he should look in that same
> direction until they hit level 2 and can't teleport with him anymore.
> Then he disappears in fire. Always in fire.

## Current Behavior

**The valley Sargobras moved, 2026-10-13** (generated spots, not yet
installed): each starting valley's Sargobras stands 4 yards from the
arrival point, turned aside until 5 yards clear of every creature
(before: straight ahead, on top of the valley's first quest giver in all
eight valleys), facing the arrival point. One shared spawn per valley,
seen by everyone.

**Planned, 2026-10-13:** a Sargobras of one's own in the valley, seen by
that player alone (everyone else's invisible to them); he always turns to
face his player; once a buddy is chosen he holds that facing; at the
player's level 2 (when going with him is no longer offered) he vanishes
in fire, as the death knights' Sargobras does. Open questions at the end (2026-10-13).

**One Sargobras per tier, 2026-09-30** (owner: "Remember, one sargobras per
tier! Eventually they're gonna have different outfits."): an owner owed
several slots gets a wandering Sargobras for each, each keeping his own
place in a ring round the owner; each serves his own slot, and goes on
break once it is chosen. The owner's own Sargobras don't count toward the
crowding rule.

**2026-09-29:** the menu is one page: every class, then every people, each
with its own icon (a table at the top of `patches/E066-sargobras/sargobras.lua`,
first pass, by feel). His three texts (6170001-6170003) are one pool of
eight cryptic lines, three of them the owner's own ("You know why you
are here.", "Justice is always forgiven eventually.", "The kind mind, to
the future is aligned."), picked at random by the client. A new buddy's
entrance from behind him is 617b1.

**Built 2026-09-26; tested offline, not yet run** (needs the owner's build
and install).

- **The choice** (`src/lua-basic/lib/buddy-choice.lua`, no server calls):
  the menu's lists (the faction's classes without death knights, its
  races), the role the guarantee needs at a slot, and a pick turned into
  class, race, talent shape and role, with the rules of this issue and
  617g. `scripts/test-buddy-choice`: both factions, death-knight and other
  owners, every slot, 300 random clans each; about 64,000 checks by a
  referee written from the decisions; checked against two broken copies
  (guarantee off, guarantee at every slot), each caught.
- **Races and classes** (`src/lua-basic/data/race-class-data.lua`, from
  `scripts/generate-basic-race-class-data`: the world's playercreateinfo
  and the client's ChrRaces/ChrClasses.dbc).
- **The two Sargobras** (`sql/basic/db_world.src/26-buddy-selector`,
  install step E043; spawns from `scripts/generate-basic-buddy-selector-sql`):
  creature 6170001 in each of the eight starting valleys, 4 yards in front
  of where newcomers arrive and facing it; creature 6170002, never saved,
  summoned by the script. Both Lord Gregor Lescovar's stand-in look (617f).
  Tested in `scripts/test-basic-sql-in-ram` (apply, re-apply, exact revert)
  and `scripts/validate-basic-state`.
- **His behaviour** (`patches/E066-sargobras/sargobras.lua`):
  - menu: "I know what kind of fighter I want" (the classes) or "... which
    people" (the races); the pick fills the owner's lowest owed slot, and he
    says what was chosen ("An Undead Mage. They'll find you soon.");
  - the wandering one comes at each tenth level (where the owner levelled)
    and at login, from level 10, while a slot is owed; not if more than two
    Sargobras are within 30 yards (then tried again every 30 seconds);
    only his owner may use him; he is level (his tier's level + 1), and
    only tiers the owner has reached are summoned; he keeps to a circle
    round the owner (5-10 yards, a spot the owner can walk straight to,
    checked on the navigation mesh), standing still and facing its centre
    while the owner is in it, or the owner while they're out of it, and
    walks (never runs) along the mesh to a new circle once the owner is
    past 15 yards, going instead if the owner is now below his tier
    (2026-10-12, which replaced the server's own follow: it made him walk
    away from an owner coming to talk); after the last
    owed choice he lights a campfire under the chooser (it burns, harder
    per tier), walks off at an angle to a seat 3 yards from it, faces it,
    sits untargetable, tells a joke from `data/sargobras-jokes.lua` every
    45-90 seconds to anyone within 30 yards, and goes when the fire does; he goes when his
    owner logs out or changes map;
  - death-knight owners never see him and are owed nothing by level: they
    get **exactly four** buddies, death knights of random races, when they
    accept the soul trade with the Sargobras at the gate of Acherus (718),
    and never any more (owner, 2026-09-26: "4 buddy-bots per Death Knight
    [...] never any more [...] when they accept a soul-trade with
    Sargobras in Acherus, to be allowed to continue their life as an
    immortal"). A death knight that traded before this was installed gets
    them at its next login;
  - the clan's name (617l): with no guild yet, each pick opens the client's
    pop-up box and the typed name founds the clan.
  - Loaded with the engine's calls faked: it registers its seven hooks.
- **Turning** is a stepped linear interpolation (owner, 2026-09-26: "we
  need to linearly interpolate a rotation amount [...] once every N
  frames, where N is the number we pick that 'feels fine' that's as high
  as possible so there's less performance demands on the server"): a step
  every 200 ms at 90 degrees a second, both first guesses to tune in game
  (`docs/balance-updates.md`).
- **Known limit**: the wandering one follows by walking to a point 7
  yards short of the owner, so on steep ground he may stop a little off.

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
idle behavior. It hands the choice over by writing it into the owed
`buddy_roster` row (class, race, and the talent shape and role drawn by
617g's shape draw); the buddy module (617a3) creates the character from
that row. Neither side calls the other (decided 2026-09-26 when 617a was
split).

### Decision, 2026-09-25 (Ritz): where Sargobras stands

"He spawns where you levelled, and then he walks toward you to follow. He
stops when he's about 7 yards away, and he starts following you again if
you move 15 yards away. If you rotate around him, he will slowly (lerp
style) rotate toward you, but he'll only initiate such movement once every
5 seconds or so." So: spawn at the level-up spot; walk to about 7 yards;
stand until the owner is 15 yards away, then follow again; turn smoothly
to face the owner, starting a turn at most every 5 seconds.

### Decision, 2026-10-04 (Ritz): walk with me, and give me some slack

"Sargobras follows too quickly. sargobras isn't walking when I walk, he
runs, then stops, then runs... also, he follows too closely, you should
have to walk a bit (just back from where you've come)." The first design
sent him once a second, at his own running speed, to a point 7 yards from
where the owner stood at that instant: a walking owner saw him sprint,
stop and wait, and sprint again. Now he is handed to the server's own
follow movement, which copies the owner's walk or run on every step, and
keeps him behind the owner (several tiers' Sargobras fan out behind).
When owner and Sargobras have both stopped he lets go, so the owner has
to walk off past 25 yards before he follows again. Distances: 10 yards
trailing (was 7), 25 yards slack (was 15); recorded in
`docs/balance-updates.md`. Checked offline by `scripts/test-sargobras-follow`.

### Decision, 2026-10-12 (Ritz): circles, not a leash; his level; "??"

Verbatim: "I'm having a problem with Sargobras running away when I try to
talk to him. He's supposed to stand still unless you're more than like,
15 yards away, and he should stand 5-10 yards away from you. He should
slowly walk to his new waypoints as well. But if you're within the radius
that his waypoint was placed to expect, then he shouldn't move at all, and
if you move away from it he should just turn to face you until you're 15
yards away from him. So... waypoints create a circle that they're
positioned around, (this can all be duplicated for multiple Sargobrases
btw), and he stares at the center of the circle. If you leave the circle
(whose radius is the radius that he's standing from you - if you're on a
bridge or a thin cliff or something, the radius should be smaller, use
the navmesh and if there isn't a direct route to the player for the place
he picks, then pull him in closer until there is) then he turns to face
you. As soon as you're more than 15 yards away, he starts walking toward a
new waypoint that's created on a new circle near you. When he reaches it,
he turns to face the center of the circle if you're inside it, otherwise
he faces you until you're 15 yards away from the waypoint."

And, same day: "can we make sure that when he paths to a new location
near you, he always walks, and also that he uses the navmesh instead of
walking straight towards it? Also, when he gets a new waypoint, if your
level isn't above the level that particular Sargobras spawned for, he
should disappear." And his level: "Can we make them the same level that
the character level they're spawning for is? For example if you hit level
30 then he should be level 31. If you hit level 40 he should be level 41.
He wants you to know that he's always stronger than you." The first
Sargobras (the valley one) and Acherus's show "??" (a boss rank; the
client draws a boss's level as "??" whatever the number), as the Lich King
in Acherus already does.

Why he ran away: the 2026-10-04 design handed him to the server's own
follow, which keeps him 10 yards behind the owner; walking up to him to
talk moved the spot he was kept at, so he walked off to it.

**The circle.** A waypoint is a circle round the owner's feet as they were
when it was made, with a radius drawn from 5 to 10 yards, and his spot on
its rim, on the side he comes from. He walks there (always walking, along
the navigation mesh). Then, while the owner is within 15 yards of him:
- the owner inside the circle: he faces its centre and doesn't move;
- the owner outside it: he turns to face them, and doesn't move.
Past 15 yards a new circle is made round the owner and he walks to it.
Several Sargobras (one per owed tier) each keep their own circle, their
spots fanned round it so they don't stand in one place.

**No watching the walk; teleports; no instances** (same day: "I'd prefer
if he didn't poll, and instead just walked until he got to the
checkpoint. At that point we can have a pseudo-recursive system where
upon arriving, he checks to see if needs to do anything else [...] Can we
add a hook to things like... teleports and loading screen zone changes
that checks to see if there are any Sargobrases, and if so, to reset them
to the new position? He should not spawn in dungeons or battlegrounds or
arenas."). His walk is handed to the server, which tells the script when
he arrives (the creature "point reached" event); arriving, he at once
looks at what to do next. One timer stands him where he got to if he
never arrives (30 s). Standing still he still looks once a second, as no
event tells a script that a player moved. An owner more than 100 yards
from a standing Sargobras (a teleport inside the map, a flight) gets him
summoned anew beside them; after a loading screen the old ones go with
the old map and the owed ones are summoned anew in the new place, never
inside a dungeon, raid, battleground or arena.

**A direct route.** The spot must be one the owner could walk straight to:
the walk along the navigation mesh from the owner to it is no more than a
quarter longer than the straight line (plus a yard). If not (a bridge, a
thin cliff), the spot is pulled in toward the owner a yard and a half at a
time, then tried a little to either side, down to 2 yards. The question is
asked through a new Lua call, `unit:GetWalkablePathLength(x, y, z)` (source
patch B051, on basic); until the server is built with it, line of sight is
used instead and that is logged as an error once.

**His hat.** "can we make the normal Sargobrases that spawn for players
have a 10% chance to spawn with a hat? Specifically, Don Rigoberto's Lost
Hat." One wandering Sargobras in ten is creature 6170003 instead of
6170002: the same in every way, but his outfit (buddies_outfits.cpp) has
the hat (item 21615) on his head. A creature's look is per creature type,
so the hat needs its own; it shows from the next compile.

**"I'm flexible."** (owner, same day: "can we add an option to Sargobras
that says "I'm flexible." and he says "good, you shall find others like
you soon." and it creates a totally random buddy-bot... but the spec is
the one that's 1/3rd in all three talent trees. Of any class.") Offered
beside the classes and peoples; it draws any class of the owner's faction
but the death knight (one whose even shape no same-class clan-mate holds
yet) and a race of the faction that plays it, always in shape 7 (a third
in each tree), and he says "Good, you shall find others like you soon."
without naming what came (`lib/buddy-choice.lua`, pick "flexible").

**His tier, his level.** Sargobras for the tier owed at level 10 is level
11, at 20 is 21, and so on (the slot's level plus one). On every new
waypoint, an owner below his tier's level (de-levelled) makes him go; he
comes back when the tier is reached again. Only tiers the owner's level
has reached are summoned.

### Decision, 2026-10-04 (Ritz): the fire under you, and how he sits

"should despawn according to his 'finished talking to a player, should
despawn myself with these conditions' rules. If I remember correctly, he
turns, walks away at an angle, and sits at the fire that he lit underneath
the player when they chose an option. Oh by the way can we ensure that the
fire he lights is underneath the player? and make it increase in damage for
each tier of buddy-bot he's summoning. also make sure he faces the fire
before he sits. You can accomplish all of this with rotations, angles, and
high-school geometry. Then he despawns after the fire does, and he becomes
un-targettable to anyone while he's sitting."

When a tier's choice is made, the campfire is lit at the chooser's feet.
He walks (not runs) to a seat 3 yards from the fire, on a ring round it,
swung about 57 degrees round from the line he came in on, so he walks off
at an angle rather than straight back. There he turns toward the fire in
small steps, sits only once he faces it, and can't be selected by anyone
while he sits. The fire burns whoever stands in it each second for 2% of
their health per tier he serves (his slot: 1 for the level-1 buddy, 2 for
level 10, ...), dealt by the burning player to themself so Sargobras is
never in a fight. He tells jokes as before, and goes when the fire does
(120 seconds), replacing "goes when no player is within 100 yards".

A reload of the Lua engine used to leave every wandering Sargobras ownerless
and standing forever; the script now removes ownerless ones near players on
load and summons each owed player's afresh, as at login. Numbers in
`docs/balance-updates.md`; checked offline by `scripts/test-sargobras-follow`
(part 2).

### Decision, 2026-09-25 (Ritz): a class or a race; death knights skip him

"When talking to Sargobras, you can either request a specific class, or a
specific race, and he'll pick randomly for the option you didn't pick."
- His menu offers two paths: **pick a class** (the race is then drawn at
  random among the owner's faction's races that can play it) or **pick a
  race** (the class is then drawn at random among the classes that race
  can play). This replaces "his menu offers the classes" above.
- The tank-and-healer guarantee (617g, revised 2026-09-26) never refuses a
  pick, and only acts at the last two slots (levels 50 and 60), while the
  clan still lacks a tank or a healer. A picked class is always given, with
  its talent shape steered toward the missing role if it can fill it. A
  picked race has its class drawn from those that can fill the role.
  Earlier slots draw freely.

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
- (Answered 2026-09-25) Death knight clans ignore the guarantee; they
  tank-swap and heal themselves instead (617g).
- (Answered 2026-10-13: "yes. currently, you can talk to him and ask to
  adventure somewhere else": his offer to take a newcomer to adventure
  elsewhere, which ends at level 2.) "until they hit level 2 and can't
  teleport with him anymore": what is the teleport? Today a newcomer chooses a buddy from
  him and stays in the valley. Is there a ride with him out of the
  valley (to the next town, the buddy's home) offered at level 1 only?
- (Open, 2026-10-13) His own Sargobras for each newcomer: the shared
  valley spawn stays (hidden from everyone), and a personal one is
  summoned for each player as they arrive? Or the shared one is shown
  to one player at a time?
