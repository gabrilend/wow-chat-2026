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


**2026-09-29:** the menu is one page: every class, then every people, each
with its own icon (a table at the top of `src/lua-basic/sargobras.lua`,
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
- **His behaviour** (`src/lua-basic/sargobras.lua`):
  - menu: "I know what kind of fighter I want" (the classes) or "... which
    people" (the races); the pick fills the owner's lowest owed slot, and he
    says what was chosen ("An Undead Mage. They'll find you soon.");
  - the wandering one comes at each tenth level (where the owner levelled)
    and at login, from level 10, while a slot is owed; not if more than two
    Sargobras are within 30 yards (then tried again every 30 seconds);
    only his owner may use him; he follows (stops at 7 yards, sets off past
    15), turns toward the owner at most every 5 seconds; after the last
    owed choice he lights a campfire, sits, tells a joke from
    `data/sargobras-jokes.lua` every 45-90 seconds to anyone within 30
    yards, and goes when no player is within 100 yards; he goes when his
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
