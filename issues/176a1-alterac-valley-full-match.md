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
grows past 40 with every player who shows up. No stand-in leaves to make
room.

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
8. The first checks, from the pathfinding list above, agreed with the
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
3. **What level the stand-ins are.** One level for all 80, a spread of
   levels, or the profile's maximum level?
4. **The match's end.** Is the scene finished when the battle is won,
   after a fixed time, or when the pathfinding checks have their answers?
5. **Players in the scene.** Is "players" here only test characters the
   custom client logs in, or can a person join the running scene too?
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
