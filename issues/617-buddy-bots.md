# 617 - Buddy Bots: Every Character Brings Companions

## Status
- Created: 2026-09-23
- Phase: 6 (Companions — bot behaviors)
- Priority: High for basic (155): "players always have at least one buddy"
- First profile: basic
- Sub-issues: 617a-617z (the table under Current Behavior)
- Related: 620 (alt bots and random bots as owners, and meeting buddies)

## Origin

Verbatim, 2026-09-23, on the note that bots skip the starting-valley
rotation because the bot module creates them through its own path:

> we should modify that path so that whenever a player character is created,
> a bot is created as well, so players always have at least one buddy.

And, answering what the buddy is:

> Dedicated to your character, and every 10 levels another one joins your
> party. They don't join other people's party, and they do quests and stuff
> that are in the same regions as you. They instantly receive every quest that
> you do and complete it automatically whenever you do. They try and fight the
> same creatures in the same area that you do, but they might be on the other
> side of the patch of mobs and that's okay. You only share exp when you're
> close, and they don't try to stay near - they just attack mobs as if the NPC
> bot was fighting in that particular area on their own.

And on the buddy's class: **the player chooses.**

Answers to the design questions, verbatim, 2026-09-23:

> we should dynamically adjust which ones are in a party as you based on which
> are closest. Remember, they're just adventuring in the same zone as you.
> Same areas too. If you enter a dungeon, then enough join to make a dungeon
> party. We can choose them randomly, without replacement, cycling through to
> make sure everyone gets a chance to go.

> they arrive at your level.
>
> they are on a hidden linked account. Playerbots.

> an NPC menu, there should be one at the starting zone, and one that spawns
> near you and walks around, sits by a fire, tells jokes... But stays in the
> same area as you were when you leveled up. If you log out, then when you log
> back in they'll appear where you logged back in at. If there's more than two
> in an area (maybe 30 yards or so) then they won't spawn. I'm thinking it
> should be a suave human male with pale, almost ashen skin, black hair parted
> down the middle and chin length, with a black and white shirt on (not
> tuxedo, more like inverted, white shirt with black accents) and pale green
> pants. No cloak, helmet, weapon, or shoulderpads, but we can pick belts and
> boots. No gloves probably either. Though maybe he levels up with you idk not
> sure yet. We'll pick the exact outfit later. See the immortal issue files
> for a reference implementation about how to do the idle behavior, we want to
> be a little distinct from them but there might be some good ideas you can
> use in there.

> yes it comes back to life. It'll move to the areas that the player is in
> when it can. Also, deleting your character does delete it's buddies.

On raids and on groups with more than one player, verbatim, 2026-09-24:

> The player invites them manually so they can choose. If the player enters
> a dungeon, the group is randomly created. If they have a party, then the
> remaining slots are filled in the dungeon. If a player has a group with
> another player, or two players, etc, then the bots who fill the rest of the
> group are chosen randomly, to fit their group requirements. (to fit their
> group requirements might be out of scope, and that's okay, we might just
> turn off the auto-fill if there are more than one human players in a
> group.) - bots don't join other players group, like for example if there's
> two humans exploring a particular area and someone invites a bot that's not
> "theirs", then they'll send a message saying "sorry, I don't follow other
> masters" or something similar.

And on why raids matter: with seven buddies at 60, five players fill a
40-person raid. Basic runs **no random bots** (155b), so buddies are the
only bots in the world. For balance, buddies are assumed to play as well
as a competent player ("let's assume competent bots. We can adjust later if
needed.").

## Current Behavior

**Brought up to date 2026-10-28.** Buddies exist and play on basic. The
buddy module (`patches/B036-mod-buddies/mod-buddies/`, built into every
basic compile) and its Lua (`src/lua-basic/`, `patches/E066-sargobras/`)
do, in short:

- **Made and kept** (617a, 617a1-a6, completed or built): a hidden
  companion account per character; a roster of owed and filled slots
  (one at creation, one per ten levels); Sargobras offers each slot a
  class or a people (617b, completed); a buddy is made at its owner's
  level, dressed from the white gearsets with its class tools, bags like
  its owner's, gems and PvP jewellery, its skills raised (617a4, 617r2,
  617j2); stages remake, reclass and bring a buddy to the gear spec;
  hidden from /who and friends, locked from renaming and trading out.
- **Logged in and grouped** (617c, c1-c4): buddies log in and out with
  their owner; the closest four are asked into the owner's party; a
  dungeon draws a party without replacement, weighted toward a tank and a
  healer (617c3); other players' invitations are refused; loyalty
  overrides when an owner's party is full.
- **Out in the world** (617e, e1-e8, o1-o5, e13): buddies roam their
  owner's sub-zone by the owner's pinwheel, on the navigation mesh, at a
  walker's slope; detour to herbs, ore and chests; eat real food; travel
  to the owner's sub-zone, along the owner's own track when no way is
  found; follow across seas and portals; visit towns (errands, then
  leisure, fishing, inns); follow in a formation behind the owner in
  dungeons and when told "follow me" (617y); single file where the way
  narrows.
- **Fighting** (617e5): help a clan-mate in trouble first; strike in
  dungeons a little before the owner is noticed.
- **Things and money** (617h, h1, j, j3, k, n): sell when told "go
  sell", auction by the owner's pricing, roll on loot by the clan's
  needs and always wear upgrades, weigh spirit against stamina, learn
  secondary professions and their class's lessons in town.
- **Talents** (617g): a plan for life (thirds of the trees), spent by the
  spender; named builds with required talents (635b).
- **Seen from above** (617e14, e16): recorders of positions, every zone as
  data, a renderer and animations, the movement benchmark, the fish-school
  sandbox page with live positions streamed from the server, and the
  judging machinery.

What is known to have run in game: making, kits, gems, stages, login,
the proximity party, roaming (Mozonn, Feldowinn's walks), town visits,
travel, the dungeon draw (Felicity's Uldaman group). What was written and
is in the build but not yet seen working: much of the rest; each
sub-issue's own Current Behavior says. (Many sub-issues still read "not
yet built or run" from the day they were written: every buddy module file
has been built into each basic compile since; "not yet seen in game" is
what those lines now mean.)

**Status of the sub-issues**, 2026-10-28:

| Status | Sub-issues |
|---|---|
| Completed | 617a1, a2, a3, a5, a6, b, e9, r1, s7 |
| Built (in the build) | 617a, a4, b1, c, c1, c2, c3, c4, d, e, e1, e2, e3, e4, e4a, e4b, e5, e6, e7, e8, e13 (following), e14, e14a, e14b, e14c, e14f, e16, e16a, e16b, f, g, h, h1, i, j, j2, j3, k, l, n, o, o1-o5, p, r, r2, r5, r6, t, t1, y |
| Planned, not built | 617o6, 617a4a, a7, b2, c5, e10, e11, e12, e14d, e14e, e15, e4c, e5b, g1, h2, j1, j4, m, q, r3, r4, r7, r8, s, s1-s6, s8, t2, t3, u, v, w, x, z |
| Set aside for now | 617e5a (the owner, 2026-09-29: "for the kraken let's just use playerbots for now") |


**Where it started** (2026-09-23): nothing like this existed. What the
bot module offered, and why none of it was the buddy:


- **Random bots** (`RandomPlayerbotMgr`): an ambient population on bot
  accounts, created by the module's own factory at startup, levelled and
  moved around the world by the module. Not tied to any player.
- **Add-class bots** (the `addclass` command in `PlayerbotMgr.cpp`): a pool
  of pre-made characters on reserved accounts. The command takes the first
  free one of a class, levels it to the player, and adds it to the player's
  group. It is shared, not persistent: a different character each time, and
  it goes back to the pool on logout.
- **Alt bots**: a player's own other characters, logged in as bots with
  `.playerbots bot add <name>`. Persistent and owned, but the player has to
  create them by hand, and they use the player's own character slots.

New characters on basic are created through the character-creation
handler, which B028 (155d) now patches. Bots never pass through it.

## Intended Behavior

- **One buddy at creation, one more every 10 levels**, each arriving **at
  the owner's level**. Each belongs to exactly one player character and
  persists with it. Buddies live on a **hidden account linked to the owner**
  and run as playerbots. **Deleting the owner deletes its buddies.**
- **Seven at level 60**, so five players and their buddies fill a 40-person
  raid. **Raids: the owner invites buddies by hand**, choosing which.
- **The player chooses each buddy's class or race** at an NPC (617b), the
  other drawn at random (2026-09-25; death knight owners choose nothing), one choice per
  buddy.
- **Party by proximity.** The group holds the owner and up to four buddies,
  and which four is re-chosen continually: the closest. Others keep
  adventuring nearby, ungrouped. **Entering a dungeon** fills a dungeon
  party. Buddies are drawn at random without replacement, cycling, so every
  buddy gets turns. If the owner already has a party, only the empty slots
  are filled. A party of two or more players is filled at random from all
  their buddies (fitting the group's role needs may be out of scope; the
  fallback is no auto-fill when more than one player is in the group).
  Buddies refuse every other player's invitation with a line like "sorry,
  I don't follow other masters".
- **Same zone, same areas, not following.** Buddies fight the same kinds of
  creatures in the owner's area on their own, maybe across the camp.
  Experience is shared only when close enough, which is the stock group
  rule: group members out of range get no share.
- **Quests mirror the owner.** When the owner accepts a quest, every buddy
  has it; when the owner turns it in, every buddy completes it and gets the
  reward.
- **Death**: a buddy resurrects like a player and makes its way back to the
  owner's areas when it can.

### A principle, 2026-10-28

The owner: "the buddy-bots will eventually be able to do everything the
players can." Where a buddy can't do what a player can (reach a herb on a
ledge, jump down a cliff, swim, fly), the buddy is what falls short, and
the gap is work to do, never a reason to steer round it.

### Decisions, 2026-09-25 (Ritz)

- **One hidden buddy account per character**: "one buddy bot account per
  character created" (617a).
- **Buddies' levels drift**: each arrives at the owner's level and then
  levels on its own. "at level 10, the player gets a level 10 buddy in
  addition to their original buddy who might be level 8, 9, 11, etc."
- **Hearthstones** (617e): buddies bind where the owner binds, and follow
  the owner home by hearthstone rather than by walking.
- **Towns behave by what they have** (617e, 617h): "we should dynamically
  create behavior based on what the town has. Some towns don't even have
  repair stations."
- **Talents** (617g): each buddy keeps one profile for life; its talents
  within it are random and re-rolled when the owner respecs. Dual spec is
  removed from basic, and respecs get dearer without a cap (155r).
- **Load**: the proximity party and errands run in memory; buddies are
  alt bots, which save like players (every 15 minutes by default, and on
  logout and similar events). The bot module's guide names alt bots as the
  low-write choice; its heavy writers are random bots, which basic doesn't
  run. Ritz asked whether writes could be batched per player; nothing
  buddy-specific writes in a loop, so there is nothing to batch yet.

## Suggested Implementation Steps

| ID | Name | Dependencies | Description |
|---|---|---|---|
| 617a | buddy-roster-and-creation | None | The hidden linked account, the owner→buddies table, creating a buddy of a chosen class at the owner's level, deleting buddies with the owner |
| 617b | buddy-class-selector-npc | 617a | The NPC where a buddy's class is chosen: one at each starting valley, and a wandering one that appears near the owner at each 10th level and idles there |
| 617c | buddy-login-and-proximity-party | 617a | Buddies log in with the owner; the group is re-formed from the closest four; dungeon entry draws a party without replacement; other groups refused |
| 617d | buddy-quest-mirroring | 617c | Quest accept and turn-in mirror from owner to every buddy |
| 617e | buddy-area-adventuring | 617c | Buddies fight in the owner's zone and area independently, resurrect, and travel to the owner's area |
| 617f | buddy-selector-appearance | 617b | The selector NPC's look (the suave human) and whether his outfit levels with the owner |
| 617g | buddy-talent-plans | 155g | Generated talent plans (2/3–1/3 and thirds) for capped trees, balanced to equilibrium; a buddy keeps its plan for life |
| 617h | buddy-auction-house | 617e | Town errands by priority (repair, trainer, auction house, vendor), the auction pricing rules, then wandering the town |
| 617j | buddy-loot-rolls-and-upgrades | 617a, 617g | Owner and buddies share one gear pool; three-way-split buddies need or greed by the clan's average; upgrades are always equipped |
| 617k | buddy-professions | 617a, 155p | Buddies pick a random crafting profession and its gathering one; craft clan upgrades and consumables; sell surplus, buy clan upgrades |
| 617l | buddy-clan-guild | 617a | A guild per clan (owner and buddies), created automatically, named by the owner, used for clan chat |
| 617m | buddy-task-hunts | 617k, 917 | Crafting on request: the buddy counts her supply, plans where to get the rest, fetches it, crafts and delivers; needs the language model layer |
| 617i | buddy-battlegrounds | 617c, 617e | Buddies join and leave the owner's battleground queues, finish their matches, then return; an owner's invite pulls them out |
| 617n | buddy-spell-learning | 617a, 617e | Class trainer lessons in towns, cheapest first until the purse runs out; quest-reward and pet spells from a generated list; everything up to its level when made |
| 617o | buddy-navmesh-pathfinding | 617e | Plan and walk on the navigation mesh: no straight-line walks through walls, rooms measured on the mesh, baked distance maps for fixed goals, steering toward moving targets |
| 617p | npc-awareness | 617e4, 617n | Buddies notice friendly NPCs within 100 yards, read what each offers from the creature itself, and use it (train, sell, repair, talk), taking turns at standing spots; works with NPCs spawned in game |
| 617q | owner-renamed-partner | None | The word "owner" (a buddy's player) renamed "partner" in code, tables, logs, issues and docs |
| 617r | elite-outfits | 617g | Elites: full Tier 1 and Molten Core or dungeon outfits per buddy type (race, class, role), the bannermen; ".gearset elite buddies <partner>" dresses a partner's buddies (the ".elite" short form removed 2026-10-30); Growth's party built and checked, not yet worn in game |
| 617s | compass-formation | 617o | In follow mode buddies hold a ring round their owner at their own compass places, the tank in front; ring radius commands; sidesteps in a fight; one buddy sent to a clicked spot; six sub-issues, planned |
| 617t | dungeon-stand-ins | 617c3 | Fewer than four buddies: stand-in companions fill the dungeon group, exactly one tank and one healer, white gear in every slot (PvP jewellery where no white exists), sockets by class style; planned |
| 617o6 | layered-ways-drops-flight-water-and-gaps | 617o3, 617o5 | Ways baked in layers and searched together: one-way drops, flight anywhere in arcs, swimming, and gaps smoothed or orbited; planned |
| 617j3 | spirit-worth-in-gear-choice | 617j, 167 | Buddies weigh spirit by what it heals against stamina (B050), by their stats as they stand, so they keep the two in balance |

Execution order: `617a → (617b ∥ 617c) → (617d ∥ 617e) → (617h ∥ 617i ∥ 617j); 617b → 617f`.

Rationale for the split: 617a is data and the bot module's character
factory. 617b is a world NPC with its own idle behavior. 617c and 617e are
bot strategy (module C++), 617d is quest hooks, and 617f is art direction.
Each can be built and tested alone, and 617b/617f can proceed before any
bot code works.

## Related Issues

- **155** / **155d** basic and its creation-handler patch (B028), where
  the first buddy is born
- **601** find-monsters, **611** wandering, **613** orchestrator — beta's
  Lua bot behaviors; 617e may reuse their ideas
- **153e** rare naturalist companions (explore) — a different kind of
  companion on a different profile

## Open Questions

**Gathered 2026-10-28** from every 617 sub-issue: 137 entries, of which
many were the same question in several places, answered since, made moot
by later work, or things to look at in game rather than ask. Merged into
the 40 below (the sub-issue each came from in brackets); each answer is
written back into its sub-issue. Things to check in game are listed after.

### Movement

1. **Tuning numbers that are ours** (617e, e2, e6, e13): the obstacle step
   (0.6 yards), the planner's costs, the pull toward openings, the tie
   side, the exploring grid's cell size and measuring speed, the mixed
   exploring order, the follow formation's spacing past five and its
   5-second mingle roll. Set them by the movement benchmark and your
   judging (617e14f, 617e16b) instead of one by one?
    **Answered 2026-10-28:** set by the benchmark and the owner's judging,
    not asked one by one. Question 1 is answered.
2. **The compass formation** (617s, s1-s6, s8): planned before the
   following formation you designed on 2026-10-27 (617e13: a half circle
   behind, along your track). Does yours replace it, or do its parts the
   formation lacks (the tank in front, radius commands, sidesteps in a
   fight, sending one buddy to a clicked spot) stay planned on top?
    **Answered 2026-10-28:** "When moving distances, we should do an "arc
    follow" which means they trail behind you. When doing a "close follow"
    in combat or when specified, they circle around you." Two modes: the
    arc follow (617e13's half circle along the track) when travelling; the
    close follow (617s's ring round the owner) in combat or when asked.
3. **Closer in danger** (617e10): what makes a place dangerous (levels,
   elites, packs, how fights went), how close "closer" is (a fixed leash or
   a shrinking radius), and is the danger one buddy's or the clan's?
    **Answered 2026-10-28:** dangerous means elites and packs, monsters
    above the buddies' level, how fights went, close calls ("when allies
    drop to low health and or die"), and the healer nearly out of mana.
    Allies' close calls count, so the danger is the group's. How close
    "closer" is stays open.
    **And how close, 2026-10-28:** the roaming radius shrinks with the
    danger, step by step, down to the close-follow ring at its worst, and
    widens as fights go well. Question 3 is answered.
4. **Passing each other** (617e11): how many levels apart before the lower
   one kneels; do buddies also swerve round, wave at and kneel to players;
   do clan-mates greet every time they pass or only after time apart?
    **Answered 2026-10-28** (in part): the lower kneels to anyone at least
    double its level; players are passed, greeted and knelt to like anyone.
    Clan-mates' greetings stay open.
    **And clan-mates, 2026-10-28:** "Clanmates only greet each other when
    they log in. They should walk to each clan mate and greet them, wait a
    second or two, and then greet someone else. Sometimes that second or
    two becomes a chat that has a 20% chance of ending after every /talk
    emote." Question 4 is answered.
5. **Hand-drawn battle areas in towns** (617e12): inside a drawn area, does
   its rule replace the town circle's errands-first; is "almost no monsters
   or people" counted once when drawn or live; should buddies in town keep
   circling between targets?
6. **Hand-drawn areas, the first cut** (617e12): your Valley of Trials is
   the cave, the middle upper area and the town side; the first cut is the
   demons, the scorpids and the boars. Redraw to yours?
7. **Caves and tunnels** (617e12): told apart on the mesh by mouths (a
   cave one, a tunnel two or more) or by width against length; and a cave
   under a hill given a second layer of parts?
8. **Roads and flocks** (617e4c): roads read from the ground's road
   textures, from guards' and caravans' walking paths, from flight routes,
   or placed by hand; a road's danger a number or yes/no; is "quest mob"
   any quest's target or only the owner's quests'?
9. **What to bake ahead** (617e2, e3): the sub-zone edges are to be baked
   (decided 2026-10-27). Also routes between areas and in towns, and
   which nodes and chests are reachable (a one-time sweep)?
    **Asked back 2026-10-28:** "Need more context. What kind of baking?"
    Explained in the conversation; open.
    **2026-10-28, the owner:** "ore, herbs, and chests would always be
    reachable because otherwise how could a player reach them?" and "the
    buddy-bots will eventually be able to do everything the players can."
    So nothing is baked to avoid unreachable places: where a buddy can't
    reach what a player can (a jump, a drop, a swim, a flight, a gap in
    the navigation mesh), that is the buddies' movement to improve.
    **Answered 2026-10-28:** "The baking should be multiple layers": one-way
    drops, flight anywhere for flying mounts (in arcs), underwater routes,
    and gaps smoothed or orbited. In 617o6. Question 9 is answered.
10. **Left behind** (617e13): how far behind may a following buddy be
    before it counts as left behind (and is told, or fetched)?
    **Answered 2026-10-28:** "Never. But we must ensure they can navigate
    the map with ease." No distance counts as left behind: a follower
    always finds its way back; the work is in the way-finding (the track,
    617e13; the mesh, 617o).
11. **Crossings** (617e8): a mage buddy teleports whenever it can; should
    the owner's own way (the boat they took) come first, and the teleport
    only replace a summon or a teleport?
    **Answered 2026-10-28:** "They should build a route, as they would with
    any path finding task, and one of the paths that route might take us
    through their teleportation spells." A mage's teleport is one more way
    in the route search, chosen when the route through it is best.
    Question 11 is answered.
12. **A test character** (617e13, e14d): may a test log in characters of
    its own (a test account and a test clan), for scripted walks and for
    bots questing with no player?
    **Answered 2026-10-28:** "Only on a separate testing server. Not beta.
    We can use basic for now, they're all testing servers right now. But,
    we should not allow players to connect unless they're a GM account when
    we're doing these tests." A test clan on basic, with the realm locked to
    game masters while a test runs (1100e).
13. **Bots questing with no player** (617e14d): which bots (offline
    owners' buddies logged in for it, a test clan, or the bot module's
    random bots taught our roaming), and is "a kind of creature" its
    family (boar, wolf), its name, or its type (beast, undead)?
    **Answered 2026-10-28** (which bots): "test clan, we define the players
    position when we click": a test clan, its player's position set by a
    click on the map page (617e16). The kind of creature stays open.
    **Asked back 2026-10-28:** "When would bots ever quest without a
    player?" Never without a player: a test clan's player is a test
    character (a game master's), placed by a click; what was missing was
    a person watching, not a player. The kind of creature is then how the
    fences group monsters (by exact kind, as built 2026-10-28).
14. **Places conquered** (617e15): what holding a place gives (a mark, or
    something in play: safer rest, a camp), what pressure is (kills a
    minute, numbers, how deep they push), and does a place stay theirs?
    **Asked back 2026-10-28:** "I have no idea what this is about." It
    came from the owner's words of 2026-10-27 (in 617e15's Origin): "they
    should stand guard with their friends, and as they stay in a location,
    it becomes conquered, and theirs. But, the monsters fight back...":
    kept as a design to build, or as an image of how it should feel?
    **Answered 2026-10-28:** "Oh it's for dungeons and raids and such. The
    idea is a monster group will push forth and attack the player party
    periodically until they fight their way in to the boss. But that's a
    later feature, let's defer it for now." Deferred; 617e15 reshaped.
15. **Watching** (617e14a, e14c): everyone recorded on Debug builds (not
    only game masters), keeping the last hour? And your screen's size?
    **Answered 2026-10-28** (the recorder): everyone, on Debug builds, the
    file trimmed to the last hour. The screen size stays open.
    **And the size, 2026-10-28:** "Depends on what we're using them for":
    set per use (a judge's frames, a picture to look at), not one size.
    Question 15 is answered.
16. **The judge's yardstick** (617e14e, e16): frames compared with "school
    of fish" pictures the image pipeline paints (picture embeddings), as
    planned, judged on a strip of frames?
    **2026-10-28, the owner:** "The goal is to just describe a movement
    pattern and then try and get it working by having the human relate to
    the behavior pattern with imagery and analogy, rather than specified
    code." To be talked through; open.
    **And what is judged, 2026-10-29:** "we judge it based on the
    apparent pattern of the movement of the components": the movement
    over time (frame strips, trails), not still frames. In 617e16.
17. **The benchmark's targets** (617e14f): numbers you choose, or the
    first runs you score highly?

    **Answered 2026-10-28:** "No numbers. We're trying to get a feel." The
    measures are kept as descriptions of a run, not pass marks; the verdict
    is the owner's (and later a judge's that agrees with hers).
### Party and dungeons

18. **Several players in one group** (617c2): their buddies' far party,
    led by the lowest-numbered far buddy or the one far longest?
    **Answered 2026-10-28:** "The far buddies will quest outside of the
    dungeon entrance right? Protecting and exploring and maybe PvPing...
    The leader isn't too important, there might be two groups ... there
    will be 6 or more left out of the dungeon. So they should try and
    spread out amongst groups and cover different ground." The buddies
    left outside a dungeon form groups of their own, quest round the
    entrance, guard and explore, and spread so the groups cover different
    ground; the leader is any. Question 18 is answered.
19. **Raids** (617c3): does entering a raid bring every online buddy of
    every player in it, and must the raid reach a tank and healer sum?
    **Answered 2026-10-28:** invited by hand, as decided 2026-09-24; nothing
    is drawn into a raid.
20. **Shared party buffs** (617c5): plan round the owner's own auras and
    blessings; how a preference is said and how long it lasts; judgement
    order when paladins are fewer than judgements?
    **Answered 2026-10-28** (the planning part; the preference words and
    judgement order stay open): buddies plan round every player in the
    group, tell each other when one has the improved version or will
    switch, read the buffs already on the party and fill the gaps, and
    choose by the threats faced: a fire resistance aura when fire hurts
    the party, shadow for shadow; no Stoneskin when the enemy is a caster.
    In 617c5.
    **And how a wish is said, 2026-10-28:** whispered to one buddy (for
    that buddy, until logout). Judgement order stays open.
    **And judgements, 2026-10-28:** "We should dynamically evaluate this as
    the fight goes on. Light if the party needs health, wisdom if the party
    needs mana." Question 20 is answered.
21. **Tank-paced pulls** (617z, w): does the tank wait for health and mana
    before each pull; a route through each dungeon or the nearest unfought
    pack; may a damage player also say "go faster"; harmless packs walked
    past; does the tank say why it waits?
    **Answered 2026-10-28** (in part, as on 2026-10-12): "The healers should
    be able to say ready and oom or out of mana or mana and the tank slows
    down or stops. We discussed this before." Healers' words drive the
    pace: "ready" on, "oom", "out of mana" or "mana" slow or stop the tank
    (617z, with its 2026-10-12 design). The rest of 21 stays open.
    **And the next pack, 2026-10-28:** "We want to fight our way to each
    boss in the correct order - make sure if the boss isn't available or
    whatever that we target the correct one, for example the murloc in
    wailing caverns. Also, if there are multiple paths we could take, pick
    one at random. We can use the "skeletonized" path finding mechanism for
    that." The tank heads for each boss in the dungeon's order, fighting
    what stands in the way; a boss not yet there (Wailing Caverns' Mutanus,
    who comes only at the end of the escort) is waited for or skipped in
    the right way; where ways part, one is taken at random. What the
    "skeletonized" pathfinding is: asked back.
    **And slowing, 2026-10-28:** "Also any player should be able to say
    wait and it slows down the tank. Or go slower. Or similar." Any player
    may slow the tank.
    **And the rest, 2026-10-28:** the "skeletonized" pathfinding is the
    floor skeleton of the exploration comparison page
    (`docs/HTML/exploration-compare.html`, `scripts/build-exploration-compare-page`:
    the floor thinned to one square wide, then a graph of its knots, ends
    and forks, and the runs between); the tank's ways to the next boss are
    that graph's, a fork taken at random. No "go faster": "If the DPS wants
    to go faster, they should just pull more mobs. The tank will pick them
    up and be a little upset. They should sense how well they're doing and
    if they can handle it, they'll adjust to the new speed and pull
    accordingly." Harmless packs: "If they are hostile they are picked up
    and cleared by AoE on the way to the next patches." Question 21 is
    answered.
22. **Boss warnings** (617e5b): the boss mods' licence (CC BY-NC-SA 3.0:
    credit, never sold, the table shared alike) acceptable; which bosses
    first; what counts as failing a mechanic?
    **Asked back 2026-10-28:** "How compatible is it with the RGPL? Our
    goals ... are to make the system so distinct that it is sellable ...
    we probably can't use something that says we shouldn't sell it ...
    this is probably okay, because we need to create entirely new bosses
    anyway ... I need more details on the license." The details are in
    617e5b; the question stands until the owner decides.
    **2026-10-28, the owner, again:** "I need to know specifics about their
    license." The licence's full text, as DBM's own file states it, is now
    in 617e5b.
    **Decided 2026-10-28:** DBM is read as a reference, to learn what it
    watches; our own tracking is built for the buddies; DBM is credited.
    Which bosses first and what counts as a failure stay open.
    **And the rest, 2026-10-28:** "order doesn't matter, we want to build all
    of them"; failing counts being hit by what could be avoided and missed
    duties (interrupts, dispels, stacks). Question 22 is answered.
23. **Stand-ins** (617t, t2, t3): meta gems on white weapons; one level a
    match or ten-level brackets; the Ragefire scene's level, how stand-ins
    are brought, Birth as healer, her leatherworking; a stand-in becoming
    a buddy takes an owed slot or replaces one, and keeps its gear or not?

### Gear, loot and money

24. **Selling** (617h, e7): the full-bags rounds never sell tools, poles,
    wearable gear, ammo, quest items, the owner's epics; the cheapest half
    first; 20 meals, restocked below 10, a quarter of the purse a stop;
    white trade goods listed or not; may a full buddy leave the place
    without its owner?
    **Answered 2026-10-28, as a new design:** "They should always sell as
    much as they need. When they acquire an item they should place it on a
    list that determines what they want to do with it. These lists can be
    per bot and in lua, recalculated when the bot logs in. They should
    attempt to resolve any lists they have entries in when they are near a
    vendor, AH, profession trainer, etc. Bots should not receive quest
    items or... The players epics? Huh?" Each item a buddy gets goes on a
    list of what to do with it (sell, auction, learn, give, keep...); the
    lists are per buddy, in Lua, worked out again at login, and settled
    when the buddy is near the place that settles them. Quest items never
    reach buddies. ("The owner's epics" were the rare bind-on-equip epics
    a buddy mails to its owner, 155k; asked back below.) Into 617h2 and
    617u; 25 and 34 join it.
    **And the epics, 2026-10-28:** "we should treat items as normal and skip
    that behavior for now": a rare epic goes on the lists like any item;
    mailing it to the owner is set aside.
25. **What a buddy does with what it carries** (617h2): openable items,
    scrolls, recipes; and should buddies buy more (potions, auction gear,
    bags)?
    **Answered 2026-10-28:** openables opened at once; recipes it can use
    learned; buddies do buy more (potions, auction gear, bags); stat
    scrolls by the inscription overhaul's rules (155o: one scroll active at
    a time per character, 30 minutes, stacking with class buffs).
    Question 25 is answered.
26. **Room for what matters** (617j4): when a stack is "plenty", and
    destroy or sell next time; how often a guild line about an upgrade?
    **Answered 2026-10-28:** "It's the opposite actually, you should
    prioritize full stacks over partial. One or two of a thing is less
    valuable than 20." Small part-stacks go first, full stacks are kept.
    Upgrade news: "When it's a big upgrade. If they are congratulated they
    should say what they're replacing too. Each buddy-bot has a 10% chance
    to congratulate them." Question 26 is answered.
27. **Loot rules** (617j, j1): a third-in-each buddy scored as a blend;
    the class book needed or greeded; the 10% upgrade threshold kept; free
    for all or group loot; does the owner count in loot turns; how long a
    buddy waits for its owner's turn?
    **Answered 2026-10-28** (the rule): "Buddies don't pass. They are as
    intrinsic to your character as you are. They level up and gear up in
    tandem with the player." Buddies roll like players, on their own needs.
    The class book, the threshold and the turns' details stay open.
    **And the thirds and the bar, 2026-10-28:** a blend of all three trees,
    "but we have to make sure that we have stats that all three would want.
    I'm concerned that blending the weights might just mean everyone
    prioritizes things like stamina, that everyone wants. Also if the blend
    has a healing spec it should disprefer hit rating, this counts for the
    2-1 specs as well." And "for 0-10% improvement they should only take it
    if nobody else wants it." The class book and turns stay open.
    **And the book and the turns, 2026-10-28:** class books go on the item
    lists like any item, but "should always be given to clanmembers (no
    player preference) unless no clanmate needs them, then they are
    auctioned". The owner takes turns too; several clans in one group or
    raid are each one block in the turns; a corpse with only coins doesn't
    count as anyone's turn (the coins are shared, B062). Question 27 is
    answered.
28. **Gems** (617j2, r6): the gem choice stays in C++ (it needs the bot
    module's stat weights); right?
    **Answered 2026-10-28:** kept in C++.
29. **Weapons** (617e4b, g1, n): ranged weapons off in town too; players'
    weapons by the same rule; weapon talents follow the weapon for buddies
    only or players too, in combat too, the main hand only; weapon masters
    teach every kind affordable or up to the owner's count?
    **Answered 2026-10-28** (the talents): weapon talents follow the weapon
    for buddies only, re-spent out of combat, by the main hand. The rest of
    29 stays open.
    **And town, 2026-10-28:** ranged weapons and wands are put away in town
    too, as built; buddies only, not players.
    **And weapon masters, 2026-10-28:** every kind its class can use, if
    affordable. Question 29 is answered.
30. **Outfits** (617r, r5): a buddy with unspent points dressed by its
    plan; an outfit back after a remake; world drops also in Molten Core
    counted as Molten Core; the gallery's race and sex per card; where the
    game's model files go?
    **Answered 2026-10-28** (in part): an elite outfit comes back after a
    remake. The rest of 30 stays open.
    **And the rest, 2026-10-28:** a buddy with unspent points is dressed by
    its talent plan; Molten Core world drops: "this is just for one outfit,
    do whatever feels right" (boss drops only). The gallery's race and sex
    and the model files stay open.
31. **Starting valleys' vendors** (617a4a): the candidate list per valley
    confirmed?

    **2026-10-28:** no preference given; the report's candidates stand
    until changed.
### Who they are

32. **Whispering Sargobras** (617b2): which account; one with a patched
    faction or two named apart; does every Sargobras near answer or every
    one; a taken name; the default spec?
    **Answered 2026-10-28 (the spec):** "the spec should be picked in the
    same way that any other buddy. This whisper shortcut is just a way to
    interact with him from afar, or in an automated fashion." The whisper
    is his menus from afar, with the same rules.
    **Answered 2026-10-30 (the rest):** his own account, the unseen guild
    master's (630); one character with the faction rule patched for him;
    a single Sargobras answers, the lowest level tier first; buddy names
    are never asked for, drawn again until valid. Word for word in 617b2.
    Question 32 is answered.
33. **"Owner" or "partner"** (617q): "partner" or "player-partner" in
    names?
    **Answered 2026-10-28:** "player-partner". Question 33 is answered.
34. **Errands in Lua** (617u): why Lua: reloading while the server runs,
    or more?
35. **Kneeling at the fallen** (617v): kneel when the corpse is already
    empty?
    **Answered 2026-10-28:** skip an empty corpse. Question 35 is answered.
36. **Prestige** (617x): reborn where they stand or in a starting valley;
    more than once; a buddy's level after (its tier's); death knights;
    "someone familiar" the latest or a choice?
    **Answered 2026-10-28** (where): "they can do so by talking to a faction
    leader. The faction leader will congratulate them on their success and
    retirement, and then the screen will fade-to-black and they will
    re-appear at that faction leader's starting zone, with Sargobras ready
    to greet them with a smile." The rest of 36 stays open.
37. **Reset a buddy** (617a7): planned with its questions first; are they
    still yours to answer (in the sub-issue)?

### Settled by later work, kept for the record

38. **How following ends** (617y): answered 2026-10-23 ("go away", "go
    away!") and built 2026-10-27.
39. **The sub-zone's edges** (617e13): answered 2026-10-28: a sub-zone, for
    questing, is where one kind of monster spawns (the fences, 617e16).
40. **Kraken and tanks** (617e5a): set aside: the bot module's own fighting
    for now.

### To check in game (not questions)

- Seated animations stay seated; fishing reach in real towns; whether an
  unstuck spot leads anywhere (617e4).
- Stepping on and off decks in straight legs; island docks (617e8).
- Whether Carago walked into the Ammen Vale building (617o1).
- The following formation, the follow orders, travel along the track,
  single file, the slope limit (617e13, y; 2026-10-27's build).
- The map stream and the page's live players (617e16a).

### Answered before 2026-10-28

- (Answered 2026-09-23) Group cap: proximity party of four, dungeon draws
  without replacement. Arrival level: the owner's. Home: a hidden linked
  playerbot account. Class choice: an NPC. Death: resurrect and return.
  Owner deleted: buddies deleted.
- (Answered 2026-09-24) Raids: invited by hand. Multi-player dungeon
  parties: filled at random, or not auto-filled at all if role-fitting is
  too much. Refusal: a spoken line.
- Remaining questions live in the sub-issues. The design survey's gaps
  (gathered and asked 2026-09-25), with where each answer went:
  - (Answered) Starting kit, hiding from /who and friends, no renaming, bot
    chat commands off, no faction or race change, remembering across
    restarts: 617a.
  - (Answered) Logout mid-errand: buddies log out too, and resume: 617c.
  - (Answered) The owner far away: buddies go to the same means of travel
    and rejoin: 617e.
  - (Answered) Talent profiles random, a tank and a healer guaranteed:
    617g. Sargobras offers a class or a race: 617b. 617j's "30-point cap"
    corrected to basic's tier rule.
  - (Answered) Guild banks: the objects removed (built, E039): 617l.
  - (Answered) Death knight owners get death knight buddies (617b); the
    owner doesn't count toward the guarantee (617g); price memory is
    shared per faction pool, neutral its own (617a).
  - (Answered) Tasks stored as JSON; the data model agreed (617a). Death
    knight clans skip the guarantee, tank-swap and self-heal (617g).
