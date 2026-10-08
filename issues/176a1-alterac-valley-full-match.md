# 176a1 - Test Scene: a Full Alterac Valley Match

## Status
- Created: 2026-10-08
- Phase: 1
- Parent: 176a (test scenes)
- Blocked by: 176 (the cc-test profile), 176a (the scene format and the
  runner)
- Related: 617t (stand-ins: what one is, how it is kept and reused),
  617i (buddies in battlegrounds), 155u (battleground rewards, queueing
  at battlemasters), 109 in the custom-client project (the client's half
  of test scenes)
- Priority: High (the first test scene; the others follow its shape)

## Origin

The owner, 2026-10-08:

> I would like the first one to be a fresh, initially created Alterac
> Valley match between 40 stand-ins and any players adding to their side.
> Later, we can do the same with the other battlegrounds, but for now just
> do Alterac Valley. We will work through their pathfinding in specific as
> we develop this first test-patch for the test-patch system of the new,
> custom client built by me and me alone with my computer in my bedroom
> where my bed is.

On how the scene is started:

> They should call the custom client when their each individual run
> script is run, from the scripts/connect-parameters.json directory.

On what drives a stand-in:

> stand-ins are not driven by player-bots per se, they are meant to have
> stats for combat and long-term progression such as level and character
> attributes. Also spec profile. But much of the other stuff can be
> elided. Until they're spawned as buddy-bots, they will level up as
> become randomly selected from to a buddy-bot become at max level.

On the size of each side:

> yes. the battle should be full even without players. The more players
> show up, the better for their side it does grow.

On what a player sees on entering: "cave."

## Current Behavior

Not built. No test scene exists, and the cc-test profile (176) that would
install one does not exist yet. On the other profiles an Alterac Valley
match only starts when enough people queue at a battlemaster, and only
players and their buddies (617i) fill it. Stand-ins are planned (617t)
but not built.

## Intended Behavior

**The scene.** A fresh Alterac Valley match, set up the way the
battleground starts: every tower, bunker, graveyard and captain in its
starting state, no reinforcements spent. It is created by the scene's own
setup, not by a queue filling, so it starts the same way every run.

**Full without players.** Each side has 40 stand-ins from the start, the
stock side size, so the battle is fought even when nobody joins. Players
who join are added to their faction's side on top of the 40, so a side
grows past 40 with every player who shows up. The owner, 2026-10-08:
"If more than a certain number of players join, say... 10 or 20, it
starts dropping the number of stand-ins to compensate. Then, at a certain
point, all new characters spawned are buddy-bots, selected from among the
connected players." So:
- the first 10 to 20 players (the number to be tuned) are added on top
  of the 40;
- past that, each further player means one stand-in fewer;
- past a later point, every character spawned to fill the side is a
  buddy-bot drawn from the buddies of the players connected, not a
  stand-in.

**One match per tier.** The owner, 2026-10-08: "Alterac Valley is an
instance, so, as many as there are tiers." Each level tier has its own
copy of the valley, and its stand-ins are of that tier. A tier every ten
levels (owner, 2026-10-08: "can we have one tier for every 10 levels? 10,
20, 30, 40, 50, 60..."). The valley's own creatures (its guards,
captains, generals and the rest) are brought down to the tier too ("the
NPCs should shrink in capabilities and equipment to compensate (duh
they're stand-ins, they're equipped from the white quality gear)"): their
level, health, damage and gear match the tier, the way the stand-ins'
white gear (617t) matches theirs.

**Battles follow the stock rules.** Asked what ends a battle and what the
next one starts from: "same rules as alterac valley." A battle ends as
the stock one does (a side kills the other's general, or brings its
reinforcements to zero), and the next battle starts fresh, every tower,
bunker and graveyard back in its starting state.

**Fighting, then ten minutes in town.** The owner, 2026-10-08:

> wait 10 minutes, then start again. Allow players to talk to vendors
> in their stronghold. But the gates are barred until the battle
> resumes. Nobody knows what happens outside of the gates during this
> time, but everyone knows they're on the same server because every
> turn the goblins deliver via package balloons (allowed by Horde and
> Alliance) which show public messages that the other side sent them
> last time they were all in town. If you want, you can spend your time
> writing instead of shopping. Or you could leave out of the entrance
> tunnel... There's also some repeating quests in the valley around the
> stronghold and such. But the middle is a no-mans land. It's normal to
> not be able to accomplish everything you need to do each time. That
> keeps you coming back, which is an oppressive anti-feature that I'm
> including to build fun artificially. Please pardon and excuse me, but
> it sounds fun and I want that.

- After a battle, each side spends **ten minutes** inside its own
  stronghold with **the gates barred**. Players can buy from the
  stronghold's vendors.
- **Goblin balloons** come every turn, allowed by both factions. Each
  carries the public messages the other side wrote during their last
  time in town. That is how both sides know they share one server.
  Anyone on the receiving side can read them (owner, 2026-10-08: "anyone
  on the other side. The leaders of each side are told that it's for
  demoralizing messages only, but everyone says whatever they want. The
  goblins say one thing to one person and another to the other, which is
  sooooo typical goblin-speak of them."): each side's leaders are told
  the balloons are for demoralizing the enemy, everyone writes what they
  like anyway, and the goblins tell each side a different story about
  the service.
- **Writing instead of shopping:** a player can spend the ten minutes
  writing a message that the next balloon will carry.
- **Leaving:** a player can walk out through the entrance tunnel.
- **Repeating quests** are in the valley around each stronghold. The
  middle of the valley is a no-man's land.
- **Not enough time on purpose.** No one can get everything done in one
  turn, which is meant to bring them back.
- Then the gates open, but not onto the battle. The owner, 2026-10-08:

  > the gates are barred, so they can't leave the stronghold. Then,
  > there is another 10 minutes where they can quest in that area while
  > their team holds a defensive line on the boundary by your towers and
  > fortresses and commanders. The player is prevented from crossing this
  > line with an invisible wall - the NPCs are not pathable. Then, when
  > the battle starts, they're swapped out with the stand-ins they
  > represent, and they charge into battle. During the intermediate 10
  > minutes, the enemy is so far away that nothing can be seen. But, at
  > the count of "go" (it's when the horn booms on both sides back and
  > forth until both are silent) then everyone can charge forward and
  > slay their foes.

  So a turn has three parts:
  1. **The battle**, fought by the stock rules.
  2. **Ten minutes in the stronghold**, gates barred: vendors, writing
     for the balloons, or leaving by the entrance tunnel.
  3. **Ten minutes questing in the home ground.** The gates open onto
     the side's own part of the valley, out to its towers, fortresses and
     commanders. There the side's defenders hold a line. An invisible
     wall stops players crossing it, and the defenders can't be walked
     through. The enemy is too far off to be seen.
  Then the horns sound, one side and then the other, back and forth until
  both fall silent. That is "go": the defenders on the line are swapped
  for the stand-ins they stand for, and everyone charges.

**Hosting: private or public.** The owner, 2026-10-08: "you can make it
private or public. LAN (including virtual ones, easily set up
in-client) or IP style port forwarding. Or public, on some server which
may or may not be your computer." A player's own server can be private
(on a local network, including a virtual one set up from inside the
client, or reached by forwarding a port to an address) or public, and a
public server may be run on any machine.

**Stand-ins as data first.** A stand-in is a character record with what
combat and long-term progression need: its level, its attributes, and
its spec profile (its talents and the role they make). Little else is
kept. The playerbots module plays a stand-in once it is in the world.

**A player enters in the cave.** A player joining the scene starts in
their faction's entrance cave, where the stock battleground places them.

**The client is the player.** The scene has its own run script. Running
it starts the custom client, which connects to whichever server its own
`scripts/connect-parameters.json` names (the client's equivalent of the
original's `realmlist.wtf`: the client decides who it connects to), logs
in a test character and enters the match. The
client's queue of inputs and its log come from the client's half of test
scenes (109 in the custom-client project).

**Two ways to play it** (owner, 2026-10-08: "both are options"):
- **Alone, hosting it yourself.** The player runs the server on their
  own computer and plays a single-player Alterac Valley match as a
  character of any race, class and gender, with optional appearance
  settings. Friends can connect to that server and join.
- **On the owner's server.** The player connects to the server running
  every test patch built here, and takes control of a stand-in already
  in the match, playing with its level, levelling track and gear.

**Shirts by climate.** The owner, 2026-10-08: "can you make sure for
the alterac valley stand-ins they always wear a shirt? Because it is cold
there. And the ones in Stranglethorn shouldn't wear shirts, because
they'll sweat too much." Every stand-in in the valley wears a shirt; the
rule for shirts by zone lives with the stand-ins' gear (617t).

**Pathfinding is what this scene checks first.** Stand-ins walk out of
their caves, along the valley, to the towers and graveyards and the
enemy's base. Their logs record where they walk, so the test can show:
- that each stand-in leaves its cave and does not stay stuck at the start;
- that none falls through the ground, walks into a wall without stopping,
  or stands still for long while it has somewhere to go;
- how long the first stand-in takes to reach each objective.
Which of these the test expects, and the exact numbers, are worked out
with the owner while this scene is built.

**Run alone, then together.** Like every scene (176a), this one is run by
itself first and its result checked. Only then does it join the run of
every scene at once.

## Suggested Implementation Steps

1. Read the stock battleground's setup in the world database (its
   template and the start positions of each side), so the scene creates
   the match from the same values a queued match uses.
2. The stand-in record (level, attributes, spec profile), and making 40
   per side at a chosen level when the scene is set up.
3. The scene's setup: create the match, put both sides' stand-ins in
   their caves, and let the playerbots module play them.
4. Logs per stand-in to `tmp/shared-memory/test-scenes/alterac-valley/`:
   world-time, position, what it is doing, at a fixed interval.
5. The scene's run script, which starts the custom client; the client
   reads its own `scripts/connect-parameters.json` (custom-client
   project) to find the server.
6. Players joining: added on top of the 40, in their cave; or taking
   control of a stand-in already fighting.
7. The single-player way: a server on the player's own computer, the
   player's character of any race, class and gender, friends able to
   join.
8. The turn: the battle's end, ten minutes in town with the gates
   barred, then the battle again.
9. The goblin balloons and the messages written in town.
10. Fewer stand-ins as players pass 10 to 20, then buddy-bots in their
    place.
11. The first checks, from the pathfinding list above, agreed with the
    owner.

## Open Questions

1. (Answered 2026-10-08) **Where `scripts/connect-parameters.json`
   lives.** With the client, the way the original's `realmlist.wtf`
   does: "I think it should match the realmlist.wtf pattern. It's a good
   pattern. Let the client determine who they connect to. Suddenly,
   freedom everywhere." The client's own file names the server it
   connects to (its address and ports); the server never writes it. A
   scene's run script starts the client, and the client reads its file.
2. (Answered 2026-10-08) **How stand-ins level up.** Only when used, as
   617t says: "this is what I meant." The step may become one level a
   match, on parallel tracks of different speeds; that design lives in
   617t. For this scene: each stand-in that plays the match takes its
   step afterwards.
3. (Answered 2026-10-08) **What level the stand-ins are.** One match per
   tier, a tier every ten levels, its stand-ins and the valley's
   creatures of that tier (above).
4. (Answered 2026-10-08) **The match's end.** A battle, then ten
   minutes in town with the gates barred, then the battle again. Each
   battle ends by the stock rules and the next starts fresh (above).
5. (Answered 2026-10-08) **Players in the scene.** People can join,
   friends on a player's own server or anyone on a public one (above).
6. (Answered 2026-10-08) **Playing a stand-in.** The owner, 2026-10-08:
   "We should make it so players can play one too, any race-class that
   exists (which should probably end up being all of them eventually)."
   A player takes control of one of the 40 while the match runs; the
   side stays at 40 plus the other players who joined. Stand-ins come in
   every race and class the stock game allows, and in time the ones it
   forbids too ("yes. blood elf druid pls"): the blood elf druid is the
   first forbidden one wanted. A forbidden pair needs the server to know
   how to create it (its starting stats, spells and gear) and a client
   that accepts it; the stock 3.3.5a client refuses pairs its own data
   files don't list, the custom client need not.
7. (Answered 2026-10-08) **What controlling a stand-in means.** "both
   are options." On one's own computer, alone: any race, class and
   gender, with optional appearance settings, in a single-player Alterac
   Valley match on a server the player is hosting, which friends can
   join. Or on the owner's server, which runs every test patch built
   here, as one of its stand-ins.
8. (Answered 2026-10-08) **What the sealed test checks across the
   turns.** "it virtualizes the mechanism once, to verify that bots can
   level up and such... y'know, the normal test suite stuff that we're
   doing in addition to this, like where we check datatypes and stuff.
   Then, it tests the other mechanics very quickly but controll-ed-ly, to
   verify that everything works out." So the sealed test plays one whole
   turn with no shortcuts, checking what a turn changes (stand-ins
   levelled, records of the right shape), alongside the ordinary tests.
   Then it runs the other mechanisms (the gates, the balloons, the
   scaling with players, the restart) quickly, with shortened timers and
   fixed inputs, so each gives the same result every run.
9. (Answered 2026-10-08) **The balloon messages.** Anyone on the other
   side can read them (above). A message is delivered with the next
   balloon and kept for two hours after, a rolling window ("this, but 2
   hours, rolling").
10. (Answered 2026-10-08) **Which levels a tier takes in.** "11-20,
    yes." A tier is named by its top level and takes the nine below it
    (the 20 tier takes 11 to 20), and a profile has valleys only up to
    its own cap (two on a level-20 profile, eight on alpha).
11. **Ending the stock battle.** In the stock game a finished Alterac
    Valley closes its instance and sends everyone out. Keeping the
    valley open through the town time and the questing time changes how
    the server ends a battleground. Only for these turn-based valleys,
    or for every battleground once the others get their versions? The
    owner, 2026-10-08: "unclear. will assess momentarily. proceed as
    continued."
