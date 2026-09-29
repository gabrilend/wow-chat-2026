# 155j - Weekly World Bosses: Kazzak, Doomwalker, Fel Reaver

## Status
- Created: 2026-09-24
- Phase: 1
- Parent: 155
- Blocked by: 155a, 155i (his damage and health are tuned per creature)
- Related: 155f, 155h, 155k, 617
- Priority: Medium

## Origin

Verbatim, 2026-09-24:

> Let's say that Doomlord Kazzak is intended to be the ultimate boss of this
> patch expansion thing. Let's say that his drop table can be expanded to
> include all raid items that are similar item level to the things he
> normally drops. He should spawn and be slayable once-per-week per server.
> Ideally, we'd take everyone who contributed and value their contribution
> somehow, damage and healing done, health damage taken, some other
> metric... Such that we find the exact contribution score. Then, that's
> their chance of getting a piece of loot. This piece of loot is tradable to
> anyone who was there for 2 hours. But they need to be in the zone and have
> dealt at least one single point of damage to him, or healed a single point
> of health from someone who dealt damage to him while he was alive and
> engaged in combat. NPC bots should never be considered for loot from
> Doomlord Kazzak. The NPC bots are not considered for contribution value.
> This is a separate issue file of course. Doomwalker is that like Doomlord
> Kazzak? Can we give loot to the Fel Reaver and make it an open world boss
> similar to Doomlord Kazzak? We should give it loot with appropriate ilevel
> for it's relative health and damage values. It doesn't have any
> mechanics, but I remember Kazzak does, is that right? Maybe it could be a
> Patchwerk style fight, a gear check, who can say...

Later the same day, verbatim:

> How about we say that the Fel Reaver has one mechanic from each boss.
> There'll be four: Kazzak's mark, which drains mana, explodes, and forces
> a tank swap if it lands on a tank. Doomwalker's earthquake and chain
> lighting should be considered one "mechanic". The charge is another
> mechanic, and getting stronger when killing a player is a fourth. The fel
> reaver should always enrage at 20% health. It should choose 2 mechanics
> from the prior list and copy them exactly. Each Kazzak mechanic should
> provide 1/2 of Kazzak's health and damage, and each Doomwalker mechanic
> should provide 1/2 of the Doomwalker's health and damage, so a competent
> raid leader might be able to tell before the fight starts if both Kazzak
> mechanics are active, or both Doomwalker mechanics are active, but if
> it's one-and-one then there's no way to tell. The Fel Reaver should drop
> Kharazhan items that are level 120 and below, only epics.

> items dropped should be number of people who contributed * default number
> of items / 40. Does that make sense to scale? The weekly reset time should
> just be, whenever I take the server down... And the weighted contribution,
> well, I'm not sure until we do some scaling. Depends on how powerful the
> heroes are. We'll have to do some sims when we build this feature, for now
> we won't be fighting Kazzak for a while so it's fine if we leave him
> unfinished.

> The three of them are the same tier. Kazzak is probably going to be
> hardest because of the 2 minute timer, we might need to make that into a
> 20% reset as well, and potentially remove the abilities that increase in
> power as heroes are slain.

Answers, verbatim, 2026-09-24:

> I'm not sure if we'll need to scale them. They are raid bosses, after
> all.

> Oh, my bad. Pretend I didn't say "tank swap" haha

> Always at least one item per kill. We should round up when we need to.
> I'm worried about a 20% enrage that always occurs because his damage
> values are so much higher than the doomwalker. If Capture Soul is removed
> from him, we should remove it from the Fel Reaver and replace it with
> some other type of ability.

> Fel Reaver's abilities are taken from Doomwalker and Kazzak. So whatever
> becomes of their abilities, so too does the Fel Reaver inherit.
> Doomwalker should use Kazzak's contribution rules. So should the Fel
> Reaver. They should all three spawn once per week (or however long it
> takes me to reset the server).

## Decisions, 2026-09-27 (Ritz): swarms, respawns, the battle bonus

Verbatim:

> I'm thinking about Kazzak enceteras strategy. he's going to be very high
> level, and the characters are level 60. So he's vastly empowered, and
> now he gets crushing blows too? Something about the design has to
> change. For one, the loot rules according to how many people are there.
> Meaning we can make vast swarms of parties, ready and meaning to
> engagement. For another, they are in the open world, which means they
> can be slain according to a vast battle arrangement. Can we change their
> respawn time to 2.5 hours? +/- some percentage, slower if players are in
> the area. While they are in alive in the world, all monsters get a 1%
> battle bonus.

Checked in the source: the server fights a world boss (a creature flagged
as a boss mob: Kazzak, Doomwalker, Azuregos, the Emerald dragons) as
exactly 3 levels above whoever it fights (`Creature::getLevelForTarget`,
`WorldBossLevelDiff` = 3), whatever its listed level; so against a level-60
character Kazzak rolls as level 63, too close to crush under the stock
rule (4+) or basic's (8+, B031). His danger is his level-73 health and
damage, not the level gap.

- **Loot by turnout**: loot scales with how many took part, so vast
  swarms of parties are the way to fight him (the contribution score of
  this issue decides who gets it).
- **Respawn**: about 2.5 hours, give or take a share (the number to
  choose), and slower while players are in his area.
- **The battle bonus**: while a world boss is alive, every monster gets a
  1% bonus (read: damage and health; open question).
- (Answered 2026-09-27) The 2.5-hour respawn **replaces** "once per week
  per server" ("yes").
- (Answered 2026-09-27) The battle bonus raises **both damage and health**
  ("both"). Whether it reaches every monster on the server or only the
  boss's continent: read as server-wide until said otherwise.
- (Answered 2026-09-27) **Respawn by hand, slowed by players**: "1% slower
  per player, recalculated every increment (5s or so) manual spawning
  through lua". The respawn is not the stock timer: a Lua script keeps
  each boss's countdown.

### Decisions, 2026-09-27 (Ritz): moment tokens, Kazzak's swarm

Relayed by the session's coordinator, the owner's words:

> if 100 players are there, then it'll never happen. [...] 2.5hour respawn
> variance between 2.5 hour minimum for nobody there, cumulatively built
> up by depositing 'moment tokens' for each player there, multiplied by
> 100 to transfer the percent.

Two readings were put to the owner: dividing each 5-second pass by
1 + 0.01 × the players present (100 players: 5 hours), or depositing
tokens (100 players: never). **Answered: the tokens** ("sounds good to
me"), with a style note:

> I prefer adding a variable amount of number increments, once per pass
> through a thing. 'let's wait until there's fifteen hundred soramech
> records to process, then we do them all at once in cached machinery.

- **The countdown**: every pass (5 seconds) adds 5 seconds to the time
  since the death and one **moment token** per player (not bot) standing
  in the boss's area; the boss is due back when the time reaches **2.5
  hours plus the tokens' worth**, each token worth 1% of a pass (5 s /
  100). One player present throughout: about 2 h 31.5 min; 50: 5 hours;
  100 or more: never. No random share on top ("don't add random jitter
  [...] until clarified"): the only variation is the crowd.

> can we make it so when Kazzak spawns there's like, wayyyy too many
> demons that spawn with him, just everywhere... but they don't respawn,
> so they can be battled down. But they are strong, about one elite pack
> per person, so if you wanna survive you need heals and throughput.

- **Kazzak's swarm**: when Doom Lord Kazzak comes back, one elite demon
  pack per player (not bot) in his zone, spread through the zone on dry
  ground, away from him and from each other; the demons never respawn.
  Decided (the owner left it open): a demon despawns with its corpse; the
  swarm outlives Kazzak (it is there to be battled down) and what is left
  of it is cleared when he next comes back; a pack of three (placeholder,
  tunable): an elite Mo'arg Overseer (19397) leading two elite Gan'arg
  Peons (19398), the elite demons of his own corner of Hellfire Peninsula.

### Decisions, 2026-09-27 (Ritz): no cap, Kazzak's size, who gets the bonus

Relayed by the coordinator, verbatim:

> [the swarm's 200-pack cap:] no cap. demons will be long slain by the time
> he's done.

> Can we scale up his model 4x and have him take steps that have an
> animation speed proportional to how 'right' it feels when his legs move a
> step forward at his immense size? Large enough to be 6 people tall, at
> least. gotta design a new kind of hitbox for him, but we'll figure that
> out later once the custom client can support his enormous girth.

> suddenly, sunwell. thanks, Arthas.

> [the battle bonus:] just hostile monsters. If the NPC is only hostile to
> one of the factions, then no.

> [moment tokens, the boss's area or the whole zone:] no. Just the empty
> sub-area.

- **No cap on the swarm**: one pack per player, however many.
- **Kazzak four times his size**, walking and running at twice his speeds
  (Current Behavior says why). Measured from the client's model files: his
  model stands about 13 units tall from its lowest to its highest point
  (wings and horns included) against a human's 2.13, and his display
  already scales it by 4.5, so by the files he already stands far above six
  players; the four times is the owner's figure and is built. How tall he
  looks, and whether the steps feel right, is to be judged in game.
- **The battle bonus only for monsters hostile to both factions**.
- **Moment tokens count the boss's own sub-area** (as built).

## Current Behavior

**Built 2026-09-27; tested offline, not yet run** (needs the owner's build
and install): the hand respawn, Kazzak's swarm, the battle bonus.

- **The list** (install step E046, `sql/basic/db_world.src/
  29-world-boss-respawn`): world table `basic_155j_world_bosses` names
  the seven world boss spawns: Doom Lord Kazzak (18728), Doomwalker
  (17711), Azuregos (6109), and the Emerald Dragons Ysondre, Lethon,
  Emeriss, Taerar (14887-14890), the creatures the server itself treats as
  world bosses. Each has one fixed spawn in the stock database (the
  dragons don't rotate between spots there: each has its own spot and a
  ~10-day timer), so each keeps its own countdown. Their stock delay is
  set to a year (saved for the revert), so only the countdown brings one
  back. The Fel Reaver is not listed: it is not a world boss until step 2
  below.
- **Kazzak's size** (the same install step, E046; stock values saved in
  `basic_155j_kazzak_stock` for the revert):
  - his model's scale 1 -> 4 (`creature_template_model.DisplayScale`, on top
    of the 4.5 his display carries);
  - his reach kept stock: the server multiplies a creature's melee reach
    and body radius by its scale (`Creature::SetObjectScale`), which would
    have let him hit, and be hit, from about 64 yards; his display's model
    row (17887, his alone) is divided by 4, so after the scale his reach is
    the stock 15.75 and his radius 9, and players hit him standing where
    they always did. A hitbox fitting his size waits for the custom client;
  - his walk 5 -> 10 yards a second, run 10 -> 20: the client plays a walk
    or run at the rate that keeps the feet planted (movement speed over
    the animation's own speed times the model's size), so speed sets how
    fast his legs cycle. Walkers keep the same gait when speed grows with
    the square root of size, so four times the size gets twice the speed.
    Known from the model files: his walk animation covers 2.5 model units a
    second in 3.33 seconds a cycle, his run 6.94 in 1.2. Believed, not
    verified: that the client scales playback by his size as stated. To
    judge in game: how the steps feel, and his run at 20 yards a second
    (players run about 5.6 on basic).
- **The state** (install step E047, `sql/basic/db_characters.src/
  05-world-boss-timers`): characters table `basic_world_boss_timer`: per
  spawn, alive, the seconds since death, the moment tokens. It survives a
  restart.
- **The countdown** (`src/lua-basic/world-boss-respawn.lua`, its rule in
  `src/lua-basic/lib/world-boss-countdown.lua`): a pass every 5 seconds
  over the dead bosses, counting players (not bots, `player:IsBot()`) in
  each boss's area; when one is due it calls `.basic worldboss respawn
  <spawn>`. The rule is one function (`Countdown.held_back`), so a change
  of reading is one line. Checked by `scripts/test-world-boss-countdown`
  (16 checks: steady crowds of 0 to 150, a crowd that leaves, and the
  server script run with the engine faked; a planted bug in the token's
  worth fails 11 of them).
- **Deaths, the respawn, the swarm, the bonus** (`src/cpp-basic/
  basic_rules.cpp`, compiled in by B030):
  - a death is noticed by the server's own death event (a Lua death event
    on a boss would replace its scripted fight with the Lua engine's), and
    marks the boss dead in the table;
  - `.basic worldboss respawn <spawn>` brings a boss back whatever state
    its ground is in (its body in the world: respawned in place; ground
    loaded but body gone: queued for now; ground not loaded: its respawn
    time cleared, so it loads alive) and marks it alive; `.basic worldboss
    status` lists them;
  - Kazzak's swarm as decided above, with no cap; the zone's borders come from the area
    table of 617e2 (E044); each pack's leader is kept "active", so its
    ground stays loaded while it lives (summoned creatures vanish with
    unloaded ground);
  - **the battle bonus**: while any listed boss is alive, every monster
    hostile to both factions (its faction hostile to a human player's and an
    orc player's; guards, vendors and neutral beasts get nothing) deals 1%
    more damage (melee, spells, damage over time) and has 1% more health,
    server-wide. The health is a flat
    addition remembered per creature and taken back exactly when the last
    boss dies (a percent bonus would be wiped by the server whenever a
    percent-health aura ends on the creature).
- Tests: C++ compile-checked against the last beta build; SQL in
  `scripts/test-basic-sql-in-ram` (apply, re-apply, revert: the creature
  table checksums as before) and `scripts/validate-basic-state` (seven
  listed, each a spawn, each off the stock respawn; the countdown table's
  columns).

Still blocked (155a, 155i): the contribution score, the loot rules, the
Fel Reaver's rework, the bosses' tuning.

Before 2026-09-27, stock:

Stock (read 2026-09-24 from the world database and the boss scripts):

- **Doom Lord Kazzak** (Hellfire Peninsula, one spawn): level 73, about
  850,000 health, melee about 11,100 per second before armor. Scripted
  (`boss_doomlord_kazzak`): Shadow Bolt Volley, Cleave, Thunderclap, Void
  Bolt, **Mark of Kazzak** (drains the target's mana, then explodes on
  them), **Twisted Reflection** (heals him when he damages the marked
  player), **Capture Soul** (he gains power when he kills a player),
  Frenzy (every 30 seconds from the first minute), and **Berserk at 3
  minutes** (the stock script's timer; the owner remembered 2). Mark of
  Kazzak only picks players who use mana, so a warrior tank is never
  marked. Drops 2 of a pool of 10 epics, all item
  level 120 (loot table 18728 → reference 26043, count 2).
- **Doomwalker** (Shadowmoon Valley, one spawn): the same kind of boss, an
  open-world raid boss of the same era. Level 73, about 1.6 million health,
  melee about 5,600 per second. Scripted: Earthquake, Chain Lightning,
  Sunder Armor, Overrun (charges and knocks down), Enrage below 20%, and
  Mark of Death (a player he kills is marked; he kills marked players
  instantly if they come back). Drops from a pool of 10 epics, item level
  120.
- **Fel Reaver** (Hellfire Peninsula, two spawns): not a boss. An elite
  level 70 that walks a patrol path; about 105,000 health, melee about
  1,000 per second, no boss script. Its loot is the ordinary level-70
  world-drop table (reference 6002), like any elite of its level.
- Raid items of item level 115–125 on this client: Karazhan (115–125),
  Gruul's Lair (125), Magtheridon's Lair (125). That is "similar item
  level" to Kazzak's 120.

## Intended Behavior

**Kazzak, Doomwalker and a reworked Fel Reaver are one tier**, the top of
basic, each a once-per-restart world boss (the week resets whenever the
server is restarted).

**Doom Lord Kazzak**
- Spawns once per restart; killable once.
- Loot: **his own 10 items** (Ritz, 2026-09-24: "Kazzak has his own items
  too. Only the Fel Reaver gets a new loot table."), required level 60.
  The earlier widened pool is dropped.
- **Items per kill = contributors × 2 ÷ 40, rounded up** (2 is his stock
  count, 40 the raid he was built for): at least one item every kill; 5
  contributors give 1, 60 give 3.
- **Contribution**: damage to him, healing on players who damaged him, and
  damage taken from him; the weights are set later by simulation. A
  player's share is their chance of receiving an item.
- **Eligible**: a player (never a bot) in the zone who did at least 1
  damage to him, or healed at least 1 health on someone who had, while he
  was alive and in combat. Bots never count and never receive loot.
- **Trading**: tradable for 2 hours among that kill's eligible players.
- **Maybe** (Ritz: "might"): remove the ability that grows as players die
  (Capture Soul). The 3-minute Berserk stays for now: an always-on 20%
  enrage worried the owner, because Kazzak's damage is far above
  Doomwalker's.
- **Scaling**: possibly none. Ritz: "They are raid bosses, after all."
  They are level 73 and built for level-70 raids; a level-60 raid's first
  attempt decides.
- **Left unfinished for now** (Ritz: "we won't be fighting Kazzak for a
  while"): the contribution weights wait for simulations.

**Doomwalker**: same tier as Kazzak; spawns once per restart; uses
Kazzak's contribution, eligibility, items-per-kill and trading rules; drops
his own 10 items, required level 60.

**Fel Reaver** becomes a world boss built from the other two:
- A pool of four mechanics, each copied exactly from its source:
  1. Kazzak's **Mark**: drains mana, then explodes (stock; it only picks
     players who use mana).
  2. Doomwalker's **Earthquake + Chain Lightning** (one mechanic).
  3. Doomwalker's **charge** (Overrun).
  4. Kazzak's **growing stronger when he kills a player** (Capture Soul).
     If Capture Soul is removed from Kazzak, it is removed here too and
     replaced by another ability. The Fel Reaver always inherits whatever
     its source bosses' abilities become.
- Each spawn picks **2 of the 4**. Each Kazzak mechanic adds half of
  Kazzak's health and damage, each Doomwalker mechanic half of
  Doomwalker's. So both-Kazzak and both-Doomwalker spawns can be told
  apart by health before the pull; any one-and-one spawn looks the same.
  At stock values: both Kazzak = 850,000 health and ~11,100 melee per
  second; both Doomwalker = 1,590,000 and ~5,650; one of each = 1,220,000
  and ~8,390. On basic these come from Kazzak's and Doomwalker's tuned
  values (155i), not stock.
- Always **enrages at 20% health**.
- Drops **Karazhan epics of item level 120 and below**, required level 60.
- **Both stock spawns stay: two Fel Reavers**, each once per restart, each
  drawing its own 2 mechanics. Both use Kazzak's contribution,
  eligibility, items-per-kill and trading rules.

## Suggested Implementation Steps

1. (Done 2026-09-27, replacing "once per restart") The hand respawn:
   the countdown with moment tokens, the respawn command, the battle bonus,
   Kazzak's swarm (Current Behavior).
2. Fel Reaver: a boss script that draws 2 of the 4 mechanics at spawn,
   calls the same spells as Kazzak's and Doomwalker's scripts, sets health
   and damage from their tuned values, and enrages at 20%.
3. Contribution counter: a script on the boss adds up each player's damage
   to him, healing on eligible players and damage taken, per kill.
4. Loot: on death, a weighted draw per item among eligible players, by
   contribution share. Items bound on pickup with the stock "tradable for 2
   hours to people present" rule narrowed to the eligible list.
5. Loot-pool generator: every raid item of item level 115–125, required
   level set to 60, written as the boss's loot table.
6. Test: a scripted kill on the RAM server with two players and two bots;
   bots get no share, and the draw follows the recorded contributions.

## Related Issues

- **155** parent; **155i** per-creature multipliers
- **155f**, **155h** — the tiers below him
- **155k** Outland world gear — where Fel Reaver's loot would sit
- **617** buddies — excluded from contribution

## Open Questions

- (Answered 2026-09-27) The respawn reading: moment tokens (100 players
  present: never), no random share.
- (Answered 2026-09-27) Tokens count the boss's own sub-area ("Just the
  empty sub-area").
- (Answered 2026-09-27) The battle bonus reaches only monsters hostile to
  both factions. Server-wide, as built.
- **Kazzak's swarm**: the pack (an Overseer and two Peons), its size (3),
  and whether the swarm should instead despawn when Kazzak dies. (No cap:
  answered 2026-09-27.)
- (Answered 2026-09-27) **Kazzak's size and speed**: "we will tune", for
  both the fourfold scale (he already stands far above six players before
  it) and the 20-yards-a-second run. Kept as built; set by watching him in
  game, each change logged in `docs/balance-updates.md`.
- **The Emerald Dragons and Azuregos**: included as world bosses (the
  server treats them as such). Right? And should the dragons rotate
  between their four spots (as on retail) rather than each keeping its
  own?

- **Levels.** Stock: Kazzak and Doomwalker 73, Fel Reaver 70, while
  Magisters' Terrace's Kael'thas is proposed at 78 (155f) with lower loot
  (item level 100 epics against these bosses' 115–120). Ritz: "That
  feels... wrong somehow". Proposal: the three world bosses share one
  level above every dungeon boss (80), Kael'thas drops to 77, so level
  reads as tier. **Answered 2026-09-24: no.** "I think they would be
  impossible at level 80. Let's leave them as they are and see if that's
  fine." Stock levels stay (Kazzak and Doomwalker 73, Fel Reaver 70);
  revisit after the first attempts.
- (Answered 2026-09-24) If Capture Soul goes, the Fel Reaver's pool takes
  whatever replaces it on Kazzak.
- (Answered 2026-09-24) At least one item per kill, rounded up. Berserk
  kept for now. All three spawn once per restart and share Kazzak's
  contribution rules. The Fel Reaver inherits its sources' abilities. No
  tank swap. Scaling perhaps unneeded. Reset: whenever the server
  restarts. Contribution weights: by simulation, later. Doomwalker and
  Kazzak keep their own items; only the Fel Reaver gets a new table. Two
  Fel Reavers.
