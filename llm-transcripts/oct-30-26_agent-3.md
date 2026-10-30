# Conversation Summary: e143dbfe-ff43-48be-8bd4-4d54fd7a325d

Generated on: 2026-10-30 12:59:01
Models: claude-opus-5-5

## Contents

1. 2026-10-30 11:39, after Request 7 - We're answering open questions so the
   next basic compile can carry Sargobras, pathfinding and questing work; your
   answers so far are written into the issues and onto a 22-item todo list.
   Next: answer the ten waiting questions, starting with buddies offering to
   trade.
2. 2026-10-30 12:19, after Request 9 - Goal: answer the open questions blocking
   basic's next compile, focused on Sargobras, pathfinding and questing. Your
   answers are written into the issues, uncommitted. Next: tell me whether
   "someone familiar" means picking from every past version of a buddy.
3. 2026-10-30 12:31, after Request 10 - We're answering the open questions
   blocking the next basic compile, with every answer written word for word into
   its issue and added to the todo list. Next: answer the two pending questions,
   what "discrete" means for selling and how "someone familiar" works.
4. 2026-10-30 12:41, after Request 11 - We're answering open questions on what
   blocks the next basic compile, focused on Sargobras, pathfinding and
   questing. Every answer so far is in its issue file, and nothing is committed.
   Next: commit just my changes when you say so.
5. 2026-10-30 12:48, after Request 12 - We're answering open questions on
   buddies, Sargobras and pathfinding for basic's next compile, with every
   answer recorded word for word in the issues and nothing committed yet. Next
   is your answers to the ten questions on dangerous selling trips, item plans
   and bots with buddies.

--------------------------------------------------------------------------------

### User Request 1

<pasted_content id="415d">
let's focus on answering questions related to this for now:

  http://127.0.0.1:8642/answer-pages/talents.html
</pasted_content id="415d">

--------------------------------------------------------------------------------

### Assistant Response 1

The talents page has exactly ten unanswered questions. Each one below has the
background you need and my suggestion. I'll copy each of your answers word for
word into the issue it came from.

(Reminder: guarding the disks against bit rot is still not started. Both disks
are ext4, which never checks whether a file's contents have silently changed.)

## Background

**How a buddy chooses today.** Each situation the bot watches for is a
"concern", such as "an ally is below 45% health" or "3+ enemies within 8 yards".
When a concern fires, it offers a short list of answers, and each answer has a
fixed score. For a restoration druid with a low-health ally, the scores are:

- tree form: 21.5
- Swiftmend: 21.4
- Wild Growth: 21.3
- Nourish: 21.2
- Regrowth: 21.1
- Healing Touch: 21.0

Every tenth of a second, the buddy takes the highest-scoring answer it can cast
right now. Talents change nothing about this.

**What is already decided:**
- A buddy picks among one concern's answers by weighted chance, not always the
  top one.
- An answer's weight is its place in the list times its talent weight.
- The talent weight comes from talent points spent on talents that touch the
  ability. Counting how many talents mention an ability was dropped, because a
  druid would end up casting only Healing Touch.
- Set bonuses count the same way talents do.
- Each talent is read four ways:
  1. the game's own hidden flags (exact, and the server uses them)
  2. broad targets like "all Shadow spells"
  3. the talent's icon
  4. its tooltip words
- Broad talents get raised, so they don't spread thin across many abilities.

## The ten questions

**How strong the talent pull is**

1. **How much does a talent raise an ability's weight?** Either a fixed amount
   per talent point, or by the talent's own effect (a talent adding 15% damage
   raises the weight by 15%).
   *My suggestion:* a fixed amount per point. It's predictable, and talents that
   cut cost or cooldown have no clean percentage.

2. **How much do the broad talents ("all your Shadow spells") count on each
   ability they cover?** Either as much as a talent that names one ability, or
   half of that.
   *My suggestion:* the full amount. That's what "increase in value the
   relationships that are a little unseen" asks for.

3. **Do the icon and the words count on their own?** That is, a link only they
   find, which the game's hidden flags don't show. Or do they only double-check
   the other two readings?
   *My suggestion:* only as a check, with word-only links listed for you to
   approve by eye first.

**Where it lives**

4. **Every bot, or only buddies?** Every bot would mean a patch to the bot
   module. Buddies only would mean the buddy module's own score multiplier,
   which the engine already supports.
   *My suggestion:* buddies only, behind a switch that starts off. Random bots
   can come later.

5. **Which class do you describe first?** The druid is the one the examples have
   used so far, because its three trees answer the same concerns three different
   ways.
   *My suggestion:* the druid.

**Weapons chosen by talents**

6. **A buddy's first weapon:** random among what its class can use, or weighted
   by its talent plan?
   *My suggestion:* weighted by the plan, so a sword-specialization warrior
   starts holding a sword.

7. **"Stronger weapon":** judged by the buddy's stat weights (damage and stats
   together), or by weapon damage per second alone?
   *My suggestion:* stat weights. Those same weights already steer gems and
   loot, so one measure covers all gear.

8. **Fast or slow weapons.** One option is a small offline calculator. For each
   talent shape and each speed band (fast, middling, slow), it adds up the
   expected damage of that shape's own abilities against a standard target, and
   writes a table of the preferred speed for each hand. Nothing would run in
   game. Is that worth building, or is damage per second plus the weapon-type
   preference enough?
   *My suggestion:* build it later. Damage per second is enough until buddies
   visibly hold the wrong speed.

**Fights and memory**

9. **How does a buddy know a boss's weak phase before the fight?** From the boss
   warnings' own tables, from what earlier fights taught, or both?
   *My suggestion:* both. The warning tables come first, and what fights taught
   adjusts the timing.

10. **Where do the "what each fight taught" logs live?** In the RAM drive
    (cheap, but lost at a reboot) or on disk in the project (kept, but growing)?
    And for how long?
    *My suggestion:* on disk, one small file per fight. RAM would lose the learning, which defeats the point.

Answer as many or as few as you like, in any order. "Agree" on a number takes my
suggestion.

--------------------------------------------------------------------------------

### User Request 2

<pasted_content id="415d">
> 9. How does a buddy know a boss's weak phase before the fight? From the boss
> warnings' own
>      tables, from what earlier fights taught, or both?
>      My suggestion: both. The warning tables come first, and what fights taught adjusts the
     timing.
</pasted_content id="415d">


we are going to build custom bosses eventually so we should build a system that
learns. I think it's okay if the bots all learn at once, together, and remember.
Then we can cache it and eventually turn off the system that learns for that
specific boss once we really have it nailed down. The idea being that it would
do so automatically.



<pasted_content id="415d">
> 10. Where do the "what each fight taught" logs live? In the RAM drive (cheap,
> but lost at a
>       reboot) or on disk in the project (kept, but growing)? And for how long?
>       My suggestion: on disk, one small file per fight. RAM would lose the learning, which defeats
      the point.
</pasted_content id="415d">


on disk, or maybe in RAM with a step after the boss that examines them, finds
the crucial information datapoints, and clears most of the junk data like
position updates and damage values and such.



<pasted_content id="415d">
> 6. A buddy's first weapon: random among what its class can use, or weighted by
> its talent plan?
>      My suggestion: weighted by the plan, so a sword-specialization warrior starts holding a
     sword.
</pasted_content id="415d">


yeah weighted by the plan! Remember we need to calculate dynamically because
sometimes we make buddies or stand-ins with odd levels like 56 and 23



<pasted_content id="415d">
> 8. Fast or slow weapons. One option is a small offline calculator. For each
> talent shape and
>      each speed band (fast, middling, slow), it adds up the expected damage of that shape's own
>      abilities against a standard target, and writes a table of the preferred speed for each hand.
>      Nothing would run in game. Is that worth building, or is damage per second plus the
>      weapon-type preference enough?
>      My suggestion: build it later. Damage per second is enough until buddies visibly hold the
>      wrong speed.
</pasted_content id="415d">


how about instead we use the talent picking heuristic system that determines how
often we use certain abilities, and cause certain abilities that contain certain
texts like "weapon damage" or "weapon swing" or similar to favor faster or
slower weapons depending on the type of ability it is and how often you use it
and what it procs and... actually a lot of stuff, can you give me a short report
on that?

--------------------------------------------------------------------------------

### Assistant Response 2

> Writing your four answers into the issues, then the weapon-speed report.

> Now the edits: question 9 (weak phase).

> Question 10 (where the fight logs live):

> Questions 6 and 8 in the gear issue:

I've written your answers to questions 6, 8, 9 and 10 into the issues word for
word, along with my reading of each. Nothing is committed yet. While they're
uncommitted, those three issue files are marked as claimed by this session in
the shared claims list, so other agents leave them alone.

## Short report: which weapon speed each kind of ability wants

I checked these rules in the server's own code. The good news is that your idea
doesn't need tooltip words to work. Each ability's spell record already states
how it uses the weapon, so the words can stay as a cross-check.

| Kind of ability | Leans | Why |
|---|---|---|
| Plain auto-attack swings | neither | Damage per swing grows with speed, so damage per second stays the same either way. |
| Abilities that add weapon damage (Mortal Strike, Sinister Strike, Backstab, Stormstrike, Obliterate) | slow | The weapon's own damage roll is bigger on a slow weapon with the same damage per second. Most of these count attack power at a fixed speed for the weapon type (dagger 1.7, other one-hander 2.4, two-hander 3.3, ranged 2.8), so only the weapon's roll favours slow. |
| "On next swing" abilities (Heroic Strike, Cleave, Maul, Raptor Strike) | slow | A flat bonus is added to a swing that is already bigger. |
| Fixed-chance effects on each hit (Deadly Poison, Combat Potency on the off hand) | fast | More hits mean more chances to trigger. |
| Effects measured in "procs per minute" (Crusader-style enchants) | neither on swings, slow on abilities | The server's chance per hit is weapon speed × rate ÷ 60. On swings the speed cancels out. An instant ability is one hit at any speed, so a slow weapon's higher chance per hit is a pure gain. |
| Extra attacks with a forced wait between them (Sword Specialization, Windfury Weapon) | slow | The wait limits how often they fire, so the size of each one decides, and size grows with speed. I haven't checked yet which of these actually have a wait. The proc table in the world database records it. |

**How the system adds it up:** each ability's lean is multiplied by how often
the buddy uses it (the talent weights). The sum gives each hand its own lean:
fast, middling or slow. I wrote it in as a tie-breaker that comes after
strength, so a buddy never passes up a clearly stronger weapon because of its
speed.

## New questions your answers raised

- **Speed versus strength:** should a slightly weaker weapon at the right speed
  ever beat a stronger one at the wrong speed? Or is speed only a tie-breaker?
- **When a boss counts as learned:** what tells the system to stop learning a
  boss? For example, the same weak phase in the last few fights, the timings
  barely moving, or a set number of fights. And should you be able to switch a
  boss's learning back on?
- **Keeping the distilled fight notes:** forever (they're small), or only until
  that boss's plan is cached? And should they go into git, so the learning
  travels to other machines?

Questions 1 to 5 and 7 from the first set are still open. The one that shapes
the most is 4: should talents steer only your buddies, or every bot on the
server?

--------------------------------------------------------------------------------

### User Request 3

okay new plan can you ask me the questions specifically related to the stuff
that is blocking us from compiling basic? We just focus on basic, and only the
things that are crucial, and broken or incompletely implemented. We should
de-prioritize professions and stuff like the Dark Portal fight, that stuff can
come later. We should increase in priority the Sargobras stuff and buddy-bot
pathfinding and questing routines. Just open questions for now.

--------------------------------------------------------------------------------

### Assistant Response 3

> Gathering open questions from the Sargobras, pathfinding and questing issues.

Nothing I can find stops basic from compiling. Basic last built cleanly on
10-27. Release builds from the same source and was built and put live on 10-29.
A failure in the size-by-level module (it makes characters grow with level)
broke the beta build on 10-28, but the release build after it went through, so
that seems fixed. Twenty-four issues are written and waiting for a compile.

So the real blockers are open questions on the work that isn't finished yet.
Here are the ten that matter most under your new priorities.

## Sargobras: whispering him from afar

Background: whispering Sargobras will open his buddy-making menus from a
distance, so you can make a buddy without walking to him. You've already said
the buddy's spec is chosen by the usual rules. What's left is which character
answers the whisper. A whisper in this game is addressed to a character name,
and two characters on one realm can't share a name.

1. **Which account does the whisperable Sargobras live on?** The stand-in
   account (already a bot account with no owner), or a new account of his own?
   *My call:* a new account of his own, so he can't get mixed up with the
   stand-ins.
2. **Both factions:** one Sargobras with the faction rule patched so both sides
   can whisper him? Or two characters, Alliance and Horde, with slightly
   different names?
   *My call:* one, with the faction rule patched for him only.
3. **"All of them respond":** every Sargobras near the person whispering, or
   every Sargobras in the world?
   *My call:* only the ones near them.
4. **A buddy name that's already taken:** pick a random name instead, or refuse
   and ask again?
   *My call:* refuse and ask again, saying why.

## Pathfinding: the painted map

Background: buddies keep one shared map per area that gets "painted" as they
walk it. It is saved to disk and improves over days, and each bot keeps a wanted
distance from the others.

5. **The numbers.** Do these feel natural, or should any change?
   - each bot wants 4 yards of space (relaxed within 10 yards of its goal)
   - unexplored ground costs 15% more to walk on
   - a follower aims 6 yards ahead
   - a bot turns at most 240° per second

   *My call:* keep them for this compile and judge them by eye in game.
6. **A tiny pocket of an area.** In one test, 36 bots were all sent into a
   260-square-yard pocket by the Firegut fence and stood 2 yards apart. Should a
   pocket that small be skipped, with the bots going on to the next part? Or
   should it take only as many bots as fit, with the rest going elsewhere?
   *My call:* take only as many as fit, at 4 yards each, and send the rest on.
7. **Five ways to find a path, side by side.** When you compare them, what
   decides which is better: getting stuck least, the least wasted walking, the
   most even spread, or how it looks to you?
   *My call:* how it looks to you first, with the measured numbers shown beside
   each picture.
8. **Stuck on the way to a dock or portal.** A buddy counts as stuck when it
   gains less than 10 yards toward you in 90 seconds. While it's walking to a
   dock or portal, the thing that matters is the dock, so right now the rule is
   switched off there. Should it measure progress toward the dock instead?
   *My call:* yes.

## Questing and following

9. **More than five followers in the arc follow.** When moving distances,
   buddies trail behind you in an arc. You gave spacing for one to five buddies,
   but a clan is seven. Spread evenly, seven end up a third of a yard apart,
   which is narrower than a body. Should the arc grow wider, or should the extra
   buddies form a second row behind the first?
   *My call:* a second row.
10. **Which monsters count as "quest monsters" when buddies spread through a
    questing area?** Any quest's target, or only targets of quests you or your
    buddies actually have?
    *My call:* only quests someone in the group has, so the buddies spread over the monsters that move your quests along.

One thing I'll ask a second time later, in different words: when you picture the
painted map working well, what would you expect to see from above?

--------------------------------------------------------------------------------

### User Request 4

<pasted_content id="415d">
  Why: The weapon's own damage roll is bigger on a slow weapon with the same
  damage per second.
> Most of these count attack power at a fixed speed for the weapon type (dagger
> 1.7, other
> one-hander 2.4, two-hander 3.3, ranged 2.8), so only the weapon's roll favours
> slow.
</pasted_content id="415d">


whoa, fixed speed? That doesn't seem right. Things like heroic strike add flat
damage bonuses, is that what you're thinking of?

> - Speed versus strength: should a slightly weaker weapon at the right speed
> ever beat a stronger
>     one at the wrong speed? Or is speed only a tie-breaker?

speed is so important but sometimes you can deal more damage with a faster
weapon because it gives attack power or strength or similar. Depending on how
much the class favors weapon swing related things, we can prefer the "weaker"
weapon, because the way that we weight weapon speed will naturally give us the
"weaker, slower" weapon as a result sometimes, and not others. We're updating
the stat weights based on abilities learned (from the trainer) and talents
picked, and it should be dynamic to each buddy-bot. Can we also write in that if
they need to choose abilities to train (because they don't have enough coin,
they can't get all of them or something) then they'll pick ones that their stat
weights most align with?



<pasted_content id="415d">
> - When a boss counts as learned: what tells the system to stop learning a
> boss? For example, the
>     same weak phase in the last few fights, the timings barely moving, or a set number of fights.
>     And should you be able to switch a boss's learning back on?
</pasted_content id="415d">


we will turn it off manually when we've tested every boss thoroughly.

> - Keeping the distilled fight notes: forever (they're small), or only until
> that boss's plan is
>     cached? And should they go into git, so the learning travels to other machines?

learning travels, but we can remove them once we've built the plan. They are
consumed, yet stored in git. Also, if the fight changes, we want to re-create
them from scratch, so make sure we fingerprint anything related to the boss so
we can both deterministically re-create the fight (not common) and also notice
when things related to the fight have changed.

> Background: whispering Sargobras will open his buddy-making menus from a
> distance, so you can
>   make a buddy without walking to him.

we can interact with the buddy-making menus, not open them.

> 1. Which account does the whisperable Sargobras live on? The stand-in account
> (already a bot
>      account with no owner), or a new account of his own?

Sargobras needs his own account for the functionality related to him being every
guild's guild master. Can you find that and use that for guidance?

> 2. Both factions: one Sargobras with the faction rule patched so both sides
> can whisper him? Or
>      two characters, Alliance and Horde, with slightly different names?

one character, patched faction rule.

> 3. "All of them respond": every Sargobras near the person whispering, or every
> Sargobras in the
     world?

a single sargobras responds. If there are Sargobrases from multiple level tiers,
then the lowest level one is utilized first.

> 4. A buddy name that's already taken: pick a random name instead, or refuse
> and ask again?

we don't get to pick buddy names. How does the auto-generation already handle
this? My instinct is that we should just try again until we get a valid name.

>   5. The numbers. Do these feel natural, or should any change?
>
>      - each bot wants 4 yards of space (relaxed within 10 yards of its goal)

yes but on un-even terrain (lots of obstacles) the personal space bubble is
reduced until they navigate through that to a more open area. This might be
overwritten with the movement map caching we're going to do with the stand-in
walking around the map taking screenshots of everything until we've fully
painted the world, similar to photogrammetry style but not as detailed. So long
as we get two angles of the same area, that should be good, and we don't have to
do things like the tops of mountains and such for now. Right now for pathfinding
we're kinda building a bunch of systems and tools that we can combine into an
ultimate pathfinding solution once we've build all the mechanics, so focus on
making levers that can be pulled and data sources that we can pull from.

>      - unexplored ground costs 15% more to walk on

this would make sense if we were trying to find the fastest way to walk
somewhere, but it doesn't look very natural. Bots should be more like people,
and they will be once we've built out their "visual map" of the area. Except
"vmaps" are already taken, hmmmm....

     - a follower aims 6 yards ahead

not sure about this, what does that mean?

     - a bot turns at most 240° per second

sure I guess



<pasted_content id="415d">
> 6. A tiny pocket of an area. In one test, 36 bots were all sent into a
> 260-square-yard pocket by
>      the Firegut fence and stood 2 yards apart. Should a pocket that small be skipped, with the
>      bots going on to the next part? Or should it take only as many bots as fit, with the rest
>      going elsewhere?
</pasted_content id="415d">


sounds like they were clumped up for some reason. Why were they all trying to
touch the same waypoint? Also, creatures in WoW can pass through each other so
it's probably not too big of a concern.

> 7. Five ways to find a path, side by side. When you compare them, what decides
> which is better:
>      getting stuck least, the least wasted walking, the most even spread, or how it looks to you?

how it looks for me. Can we switch them in Lua? Once we have a running server
I'll watch in-game and you can try the different methods one-by-one. We'll see
if they appear natural.



<pasted_content id="415d">
> 8. Stuck on the way to a dock or portal. A buddy counts as stuck when it gains
> less than 10
>      yards toward you in 90 seconds. While it's walking to a dock or portal, the thing that
>      matters is the dock, so right now the rule is switched off there. Should it measure progress
>      toward the dock instead?
</pasted_content id="415d">


this is a fallback, if buddies are getting stuck, we should find out why, and
fix that error instead. Our pathfinding must be rock-solid, and right now it is
nascent. Don't worry if it's broken now, because we'll steadily improve it until
it's fine.



<pasted_content id="415d">
> 9. More than five followers in the arc follow. When moving distances, buddies
> trail behind you
>      in an arc. You gave spacing for one to five buddies, but a clan is seven. Spread evenly,
>      seven end up a third of a yard apart, which is narrower than a body. Should the arc grow
>      wider, or should the extra buddies form a second row behind the first?
</pasted_content id="415d">


wider but no more than half a circle. Make it dynamic too because we'll use
semi-circle arc positioning in many situations. Could also add a second layer
arc, so it's like... maybe 3 in the closest radius, then 2 more behind, then
another 2 behind them.

> 10. Which monsters count as "quest monsters" when buddies spread through a
> questing area? Any
>       quest's target, or only targets of quests you or your buddies actually have?

any monsters that are in the same spawn-zone as the player. Remember, there are
overlapping spawn-zones.

can you record these and add each of their issues to the todo list and then ask
me 10 more open questions with sufficient context?

--------------------------------------------------------------------------------

### Assistant Response 4

> Checking in the game's spell file which abilities really use the fixed-speed
> rule, before answering your challenge.

> Recording the answers now. First, the Sargobras whisper issue:

> Now the weapon-speed answer and the correction (Stormstrike does not use the
> fixed-speed rule; the file says so):

> Now training choices in the spell-learning issue:

> Fight notes (git, consumed, fingerprinted):

> Now the painted map. Checking what "6 yards ahead" is and why the Firegut bots
> clumped:

> Now the intended behavior for the space bubble and unknown premium:

> Still recording. Next, marking the Sargobras question in the main buddy issue
> as answered:

> Answers recorded. Adding each issue's build work to the todo list:

I've written all your answers into their issues word for word and added 11 build
items to the todo list. Nothing is committed yet.

## On "fixed speed"

It isn't Heroic Strike. I checked the game's spell file. Heroic Strike uses the
plain "add weapon damage" effect, and its flat bonus lands on your next real
swing. The fixed-speed rule is a separate effect kind. When an ability uses it,
the server counts the attack-power part of the hit as if the weapon had a fixed
speed: 1.7 for a dagger, 2.4 for other one-handers, 3.3 for a two-hander, 2.8
for ranged. The weapon's own damage roll is still the real weapon's.

Player abilities with the fixed-speed kind:

- Warrior: Mortal Strike, Overpower, Whirlwind, Devastate
- Rogue: Sinister Strike, Backstab, Ambush, Hemorrhage
- Paladin: Crusader Strike
- Death knight: Obliterate, Plague Strike
- Hunter: Aimed Shot

One correction to my last report: Stormstrike is the plain kind, not
fixed-speed. I've fixed that in the issue.

## Why the Firegut bots clumped

They weren't all chasing one waypoint. The test page put the player in a pocket
about 16 yards across, then treated that pocket as the whole area to spread
over. In your earlier picture of the same spot, the area was 47,569 square
yards. So all 36 bots got targets inside the pocket. The bug is in how the test
page picks the area. It's on the todo list.

## Ten more open questions

**Sargobras**

1. **A whisper that isn't a command.** In October you said that once a player
   has added Sargobras as a friend, any message to him opens his dialogue menu.
   Today you said whispers work his menus without opening them. When someone
   whispers him something that isn't a command, should his menu appear, or
   should he reply with the list of commands he understands?
2. **"Sargobras has logged off."** When you log in as the only member of your
   guild online, the game sometimes shows the guild's own "Sargobras has logged
   off" line, as if he left the moment you arrived. How often: every lone login,
   one in a few, or once a day per character?
3. **Bot players choosing buddies.** Bots that play as owners also get buddies
   from Sargobras. Should a bot's controlling player be able to whisper the
   choice for it ("Sargobras: paladin")? Or does the bot always choose for
   itself?

**Pathfinding**

4. **The point a bot steers toward.** A bot's planned route is a chain of
   one-yard squares. It doesn't step from square to square. It steers toward a
   point on the route 6 yards ahead of itself, like a driver looking down the
   road instead of at the bumper. A farther point gives rounder, lazier corners
   that cut inside bends. A nearer point traces every turn exactly and looks
   twitchy. Should 6 yards stay, become a lever, or change with the ground
   (nearer in clutter, farther in the open)?
5. **A name for the "visual map".** This is the stand-in walking the world
   taking pictures from at least two angles to paint the ground ahead of time.
   "vmaps" is taken: it's the server's existing line-of-sight data. Some
   options: "sight map", "the survey", "the album", "eye map". Or a name of your
   own?
6. **Trails.** Should ground that has been walked often get cheaper to walk, so
   worn paths form the way deer trails do? In tests, the cost settings changed
   coverage less than ordinary run-to-run variation did. So the answer would
   come from watching, not from numbers.
7. **The "forces only" way.** One of the five ways uses no map at all. Bots are
   pushed away from walls and pulled toward their goal. It can't get around a
   long wall or climb out of a dip. Should it stay pure, as a demonstration of
   what forces alone do? Or should it get a memory, where squares it has stood
   in push it away so it can't sink back into the same dip?
8. **Ties on flat ground.** On a flat floor, going around an obstacle on the
   left costs exactly the same as on the right, so the last bit of computer
   rounding picks the side. Should a tie always go to a fixed side, such as the
   buddy's own circling direction, so the choice is made on purpose?
9. **The town-visit unstuck hop.** Today, a buddy in town that gains less than
   10 yards in 90 seconds is hopped to a random spot within 30 yards. By your
   answer about docks, that's a fallback that hides the real fault. Should it be
   removed, so a stuck buddy stays stuck and gets reported loudly with where and
   why?

**Questing and travel**

10. **An island buddy.** You're on a dock and your buddy is on the same
    continent, but it is neither at your dock nor at another stop of your ship.
    It walks toward your dock, which may have no land route (for example
    Rut'theran Village, the island across from Darnassus). Should it look for
    the nearest stop of that ship instead? Or should it plan a full route over
    walking, boats and portals, like the route search you described for crossing
    between continents?

--------------------------------------------------------------------------------

### User Request 5

<pasted_content id="415d">
> It isn't Heroic Strike. I checked the game's spell file. Heroic Strike uses
> the plain "add
> weapon damage" effect, and its flat bonus lands on your next real swing. The
> fixed-speed rule is
> a separate effect kind. When an ability uses it, the server counts the
> attack-power part of the
> hit as if the weapon had a fixed speed: 1.7 for a dagger, 2.4 for other
> one-handers, 3.3 for a
> two-hander, 2.8 for ranged. The weapon's own damage roll is still the real
> weapon's.
>
>   Player abilities with the fixed-speed kind:
>
>   - Warrior: Mortal Strike, Overpower, Whirlwind, Devastate
>   - Rogue: Sinister Strike, Backstab, Ambush, Hemorrhage
>   - Paladin: Crusader Strike
>   - Death knight: Obliterate, Plague Strike
>   - Hunter: Aimed Shot
</pasted_content id="415d">


that seems dumb and wrong. We should use the actual weapon speed.



<pasted_content id="415d">
> 1. A whisper that isn't a command. In October you said that once a player has
> added Sargobras as
>      a friend, any message to him opens his dialogue menu. Today you said whispers work his menus
>      without opening them. When someone whispers him something that isn't a command, should his
>      menu appear, or should he reply with the list of commands he understands?
</pasted_content id="415d">


oh, um hmmmmmm... let's defer that for now. We can just have the players click
on him for now.



<pasted_content id="415d">
> 2. "Sargobras has logged off." When you log in as the only member of your
> guild online, the game
>      sometimes shows the guild's own "Sargobras has logged off" line, as if he left the moment
>      you arrived. How often: every lone login, one in a few, or once a day per character?
</pasted_content id="415d">


I realized this would never trigger since guilds are just clans? Maybe we should
wait until we develop a system where a player can be in another player's guild.
So, defer this as well.



<pasted_content id="415d">
> 3. Bot players choosing buddies. Bots that play as owners also get buddies
> from Sargobras.
>      Should a bot's controlling player be able to whisper the choice for it ("Sargobras:
>      paladin")? Or does the bot always choose for itself?
</pasted_content id="415d">


the bot always chooses for itself.



<pasted_content id="415d">
> 4. The point a bot steers toward. A bot's planned route is a chain of one-yard
> squares. It
>      doesn't step from square to square. It steers toward a point on the route 6 yards ahead of
>      itself, like a driver looking down the road instead of at the bumper. A farther point gives
>      rounder, lazier corners that cut inside bends. A nearer point traces every turn exactly and
>      looks twitchy. Should 6 yards stay, become a lever, or change with the ground (nearer in
>      clutter, farther in the open)?
</pasted_content id="415d">


nearer in clutter, farther in the open.



<pasted_content id="415d">
> 5. A name for the "visual map". This is the stand-in walking the world taking
> pictures from at
>      least two angles to paint the ground ahead of time. "vmaps" is taken: it's the server's
>      existing line-of-sight data. Some options: "sight map", "the survey", "the album", "eye map".
>      Or a name of your own?
</pasted_content id="415d">


smap works



<pasted_content id="415d">
> 6. Trails. Should ground that has been walked often get cheaper to walk, so
> worn paths form the
>      way deer trails do? In tests, the cost settings changed coverage less than ordinary
>      run-to-run variation did. So the answer would come from watching, not from numbers.
</pasted_content id="415d">


yes, but this waits on the smaps to identify trails and such.



<pasted_content id="415d">
> 7. The "forces only" way. One of the five ways uses no map at all. Bots are
> pushed away from
>      walls and pulled toward their goal. It can't get around a long wall or climb out of a dip.
>      Should it stay pure, as a demonstration of what forces alone do? Or should it get a memory,
>      where squares it has stood in push it away so it can't sink back into the same dip?
</pasted_content id="415d">


it's a routine that we should enter at certain points to navigate through the
terrain it is suited to, and switched out of if we need to do something like get
around a long wall our climb out of a dip. How we determine those states is
solvable, for example a small dip can be detected by saying "oh are a bunch of
points 1, 3, and 5 yards away from me much higher proportionally than the Y
value I possess?" or similar, but it might have problems with being stuck in a
canyon, which are plentiful in World of Warcraft.



<pasted_content id="415d">
> 8. Ties on flat ground. On a flat floor, going around an obstacle on the left
> costs exactly the
>      same as on the right, so the last bit of computer rounding picks the side. Should a tie
>      always go to a fixed side, such as the buddy's own circling direction, so the choice is made
     on purpose?
</pasted_content id="415d">


it should randomly pick within like a 10% margin. So if it's marginally equal it
should just pick one randomly. Or defer to the smap.



<pasted_content id="415d">
> 9. The town-visit unstuck hop. Today, a buddy in town that gains less than 10
> yards in 90
>      seconds is hopped to a random spot within 30 yards. By your answer about docks, that's a
>      fallback that hides the real fault. Should it be removed, so a stuck buddy stays stuck and
>      gets reported loudly with where and why?
</pasted_content id="415d">


yeah. we'll sweep it up in the logs and work on it when we can.



<pasted_content id="415d">
> 10. An island buddy. You're on a dock and your buddy is on the same continent,
> but it is neither
>       at your dock nor at another stop of your ship. It walks toward your dock, which may have no
>       land route (for example Rut'theran Village, the island across from Darnassus). Should it
>       look for the nearest stop of that ship instead? Or should it plan a full route over walking,
>       boats and portals, like the route search you described for crossing between continents?
</pasted_content id="415d">


route search. Same machinery.

--------------------------------------------------------------------------------

### Assistant Response 5

> Writing a new issue for weapon speed in instant attacks (none exists yet),
> then recording the other nine answers.

> Now the Sargobras answers (1-3):

> Pathfinding answers (4-8) into the painted map, five ways and roaming core
> issues:

I've recorded all ten answers word for word. I also added four more build items
to the todo list (fifteen in total). Nothing is committed yet.

Two things came up while recording:

- **The town-visit unstuck hop is still in the buddy module's town code.** The
  issue now says it is to be removed, with stuck buddies logged instead, and the
  removal is on the todo list.
- **Using real weapon speed is a game rule change, so it got a new issue of its
  own** under combat rules: "Instant Attacks Count Attack Power by the Real
  Weapon Speed".

**About offering it upstream:** AzerothCore aims to play the way 3.3.5a did, and
the fixed speed is how 3.3.5a played. So they'd likely refuse a change to the
default. A server setting that starts off is the shape they'd most likely
accept. If we build it that way here, our patch and the contribution are the
same code: the patch adds the setting, and basic's config turns it on. I've
written it into the new issue that way.

## Ten more open questions

**Real weapon speed**

1. **Who gets it: every player on basic, or only buddies and bots?** It changes
   every warrior, rogue, paladin, death knight and hunter instant attack. For
   example, at 3,000 attack power, Mortal Strike with a 3.8-speed two-hander
   adds 814 damage from attack power instead of 707, about 107 more per hit.
   Daggers barely change: they're 1.4 to 1.8 against the fixed 1.7.
   *My call:* every player, so buddies and players play by one rule.
2. **When to offer it upstream:** right away as an off-by-default setting, or
   after it has been played on basic for a while?
   *My call:* after playing it, so we can include what we learned about how it
   plays.

**The forces-only routine**

3. **Telling a canyon from a dip.** Your test (ground at 1, 3 and 5 yards well
   above the buddy's own height) catches both, but a buddy in a canyon should
   keep walking along it. One way: a dip has high ground ringing it on all
   sides, a canyon only on two opposite sides, open along its length. Or wait
   for the smap to say which is which?
   *My call:* the ring test now, as a lever, with the smap correcting it later.

**The smap**

4. **What takes the pictures?** The stand-in is a bot, so it has no eyes.
   Something has to draw the world from where it stands. The options:
   - the custom client's windowless picture mode, moved to each of the
     stand-in's spots
   - an ordinary game client driven by a script
   - drawing straight from the map files (heights, ground textures, models), the
     way the zone view from above already works

   *My call:* the custom client. It draws exactly what players see, and it
   already makes pictures without a window.
5. **Which ground first?** Basic's starting valleys and their zones, or wherever
   the logs show buddies getting stuck most?
   *My call:* stuck spots first. Each one is a known fault waiting for data.

**Roads (buddies walking between questing areas)**

6. **Where do roads come from?**
   - the road textures drawn in the map files
   - the paths that wandering guards and caravans walk
   - flight-path routes
   - points placed by hand with a tool
   - a mix of these

   *My call:* the road textures first, since every road a player sees is one,
   with the guard and caravan paths to confirm.
7. **Is a road's danger a number or a yes/no?** As a number, a road through
   quest land could be "a little" dangerous, counted from how many danger layers
   overlap there and how strongly.
   *My call:* a number.

**Caves and tunnels (read from the server's walking mesh, which covers cave
floors too)**

8. **What makes a passage a tunnel rather than a cave?** One mouth against two
   or more (a dead end against a through-way), or long and narrow against
   opening into rooms, or both?
   *My call:* mouths decide, and width against length only describes the shape.
9. **A cave under a hill shares its map squares with the hillside above it.**
   Should each square get a second layer (one area on the surface, another
   below), or should a cave be kept as an exception described by its mouth and
   floor outline?
   *My call:* a second layer. It's one rule that also covers cellars and crypts.

**Following**

10. **The mingle.** When you stop, following buddies rest within 10 yards of
    you. Each one rolls a one-in-ten chance to wander a little, every 5 seconds.
    Five seconds was our guess. Does it feel right, or should it be slower or
    faster?
    *My call:* keep 5 seconds as a lever and judge it in game.

--------------------------------------------------------------------------------

### User Request 6

<pasted_content id="415d">
> About offering it upstream: AzerothCore aims to play the way 3.3.5a did, and
> the fixed speed is
> how 3.3.5a played. So they'd likely refuse a change to the default. A server
> setting that starts
> off is the shape they'd most likely accept. If we build it that way here, our
> patch and the
> contribution are the same code: the patch adds the setting, and basic's config
> turns it on. I've
>   written it into the new issue that way.
</pasted_content id="415d">


okay but that's not how 3.3.5a was, I remember getting a slower weapon and
dealing more damage with it than a faster weapon on my ret paladin with Seal of
Command procs. Though Seal of Command was changed towards the end of Wrath I
think. Can you tell me when it switched to the cleave mechanic?

  Real weapon speed

>   1. Who gets it: every player on basic, or only buddies and bots?

everyone.

> 2. When to offer it upstream: right away as an off-by-default setting, or
> after it has been
>      played on basic for a while?

obviously once we've tested it and make it rockhard and bulletproof.

  3. Telling a canyon from a dip.

this fiddly stuff is why for complex problems like this, which COULD be
engineered at great difficulty, are better suited to a natural processing
technique like the smaps, which build a sight based categorization of terrain
that can only improve with additional smap input. Once it's built, it's solved,
and we *grew* a solution out of the clay of the earth, rather than specified
with harsh tolerances.

> 4. What takes the pictures? The stand-in is a bot, so it has no eyes.
> Something has to draw the
>      world from where it stands.

might be custom client work, but we can do it with a UI addon that we spin up
and then a sandboxed client that we use. I think we have a plan for headless
client usage somewhere...? Maybe it was this haha

> 5. Which ground first? Basic's starting valleys and their zones, or wherever
> the logs show
>      buddies getting stuck most?

it does not matter at all, we must do all of them. But starting zones is a good
idea, so... Durotar, not the Valley of Trials. Maybe also the capitals.

  6. Where do roads come from?

smaps.

>   7. Is a road's danger a number or a yes/no?

determined from surrounding monsters and such, not baked into the smap, because
monster positions might change, but the terrain is more static.

>   8. What makes a passage a tunnel rather than a cave?

they are both treated as caves. If a buddy-bot needs to pass through a tunnel
(for example Timbermaw Hold) there's a node-based routing system that will get
them to their destination without calculating the exact path. Timbermaw Hold
always has one entrance and one exit, so the node-system would say "... stuff in
felwood or whatever, then timbermaw hold entrance, then timbermaw hold, then
timbermaw hold exit, then winterspring path, then Everlook, etc"

>   9. A cave under a hill shares its map squares with the hillside above it.

keep track of x, y, and z coordinates. We should have a "map" that is
"unrollable" into higher dimensions. For example when entering a cave, we should
conceptually walk into another dimension, with the distance from the entrance /
exit as the value in that dimension. So if it was dimension Q for example
increases in Q value would mean you're getting farther from the entrance.
Decreases in Q value would mean you're getting closer to an exit. Doesn't matter
which exit, it's just... AN exit.

consider a spiral staircase. If the entrance and exit share the SAME X/Y space,
they'd also share the same Q space value because they're both 0 at the entrance
and exit, but the top of the spiral staircase is at the same space as the bottom
of the spiral staircase. This is why it's important to store the Z value as
well. The Z value *would* differentiate the top and bottom, which is why we need
it.



<pasted_content id="415d">
> 10. The mingle. When you stop, following buddies rest within 10 yards of you.
> Each one rolls a
>       one-in-ten chance to wander a little, every 5 seconds. Five seconds was our guess. Does it
>       feel right, or should it be slower or faster?
</pasted_content id="415d">


naturalizing NPC behavior is a complex topic. We should just build a bunch of
activities they could do and try to make them feel natural.

--------------------------------------------------------------------------------

### Assistant Response 6

> The game's own data settles it. Recording next.

> Still recording; fixing one passage in the five-ways issue.

> Adding the new work to the todo list, then the next ten questions.

## Seal of Command

According to the warcraft wiki, the change came in patch 3.2.0 (August 4, 2009).
Seal of Command became 36% of weapon damage as extra Holy damage on every swing.
Patch 3.2.2 (September 22, 2009) refined it: the extra damage jumps to up to 2
more targets, but only when the attack that triggered it hits a single target.
Before 3.2.0 it was a chance on each hit.

Your memory and the fixed-speed rule are both right. I checked the game's own
spell data and proc table. In 3.3.5a, Seal of Command triggers on every hit
(chance 100) and uses the plain weapon-damage effect at the weapon's real speed.
Divine Storm is the plain kind too. Of a Retribution paladin's attacks, only
Crusader Strike uses the fixed speed, so a slow two-hander won. That's in the
real-weapon-speed issue now.

## Recorded

- **Real weapon speed:** applies to everyone; offered upstream only once it's
  tested and solid.
- **The smap:** has its own issue now, with your words as its origin. Pictures
  come from a sandboxed client running a UI addon, or the custom client's
  headless mode (that's the plan you remembered, from the test scenes work). It
  starts with all of Durotar, then the capitals. Roads come from it. Telling a
  canyon from a dip and breaking ties wait on it. I didn't build the
  hand-written height test.
- **Road danger:** worked out live from the monsters nearby, never baked into
  the smap.
- **Caves and tunnels:** both are caves. A tunnel like Timbermaw Hold is crossed
  by route nodes (entrance, inside, exit) without planning an exact path through
  it. A cave's places are stored by x, y, z plus Q, the walking distance to the
  nearest exit.
- **The mingle:** becomes one of a set of rest activities, judged by feel.

The todo list now has 19 items, and nothing is committed.

## Ten more open questions

**The smap**

1. **Which model reads the pictures?** The image pipeline already has a part
   that matches pictures with words (its CLIP part), or a larger picture-reading
   model could run offline.
   *My call:* the CLIP part first, since it's already installed, with a larger
   model only where it's unsure.
2. **How many picture spots per zone?** One every 20 yards on the walkable
   ground, or denser where the ground changes (cliffs, rivers, town edges)?
   *My call:* every 20 yards, then add spots wherever two angles disagree.
3. **Does Q (depth from the nearest exit) also cover buildings, crypts and
   instances?** Or only natural caves?
   *My call:* everything with a roof. A crypt is a cave with walls.

**Rest activities**

4. **Name a few things you picture buddies doing while you stand still.** For
   example: sitting, stretching, inspecting their gear, fishing if there's
   water, poking at the nearest crate, talking to each other. Whatever comes to
   mind is enough to start building.

**Fighting in towns** (your October words: in town, buddies should treat
fighting monsters and talking to people as equally important, mostly picking
whatever is nearest)

5. **When a buddy's errand is due (trainer, vendor, repair), does it still come
   first in town?** Or does it wait while the buddy fights and talks with
   whatever is nearest?
   *My call:* errands first when due, then nearest-thing.
6. **How often is "sometimes talk"?** For example, one target in five being a
   townsperson instead of a monster.
   *My call:* none, chosen by nearness alone as you said, so it varies with the
   town.
7. **Can an area wrap around another one?** The first cut of the Valley of
   Trials has the boars' area wrapping around both sides of the scorpids. You
   drew three areas: the cave, the middle upper area, and the town side. Is a
   wrapping area fine, or must each area be one solid piece on one side?
   *My call:* fine, since spawn zones overlap anyway.

**Questing**

8. **Pointing the way to the next quest:** buddies already hint by where they
   stand. Should they also say it sometimes, like "the murlocs we need are down
   by the shore"?
   *My call:* yes, rarely, once per new objective.

**Sargobras**

9. **A bot owner's Sargobras.** When a bot player meets Sargobras to choose its
   buddies, should he still sit by a campfire and tell jokes afterward, even
   though no person is there to hear him? Or should he leave at once?
   *My call:* leave at once, since nothing is gained by staying.

**Areas**

10. **Quiet areas.** An area marked as having almost no monsters and almost no
    friendly people: is that counted once when the area is drawn, or live as
    creatures come and go?
    *My call:* live, the same reasoning as road danger: creatures move, ground doesn't.

Sources:
- [Seal of Command –
  warcraft.wiki.gg](https://warcraft.wiki.gg/wiki/Seal_of_Command)

--------------------------------------------------------------------------------

### User Request 7

let's defer the smap until after the next compile, because it has a lengthy data
generation phase. We don't have to write that into the issue files we can just
keep it in mind.

  2. How many picture spots per zone?

as many as we need to paint the whole picture. If we take an additional picture
and it doesn't give us new information even though it's from a new angle, then
it's probably fine. If two attempts disagree, then it might be an angle thing,
so we should approach that area from multiple extra angles until we can figure
it out. Maybe also we zoom in the character until they can see the details more
clearly about that specific area.

> 3. Does Q (depth from the nearest exit) also cover buildings, crypts and
> instances?

yes, yes, and yes.



<pasted_content id="415d">
> 4. Name a few things you picture buddies doing while you stand still. For
> example: sitting,
>      stretching, inspecting their gear, fishing if there's water, poking at the nearest crate,
>      talking to each other. Whatever comes to mind is enough to start building.
</pasted_content id="415d">


let's put this on hold until after the next compile, because it's just flavor.

> 5. When a buddy's errand is due (trainer, vendor, repair), does it still come
> first in town? Or
>      does it wait while the buddy fights and talks with whatever is nearest?

they should fight their way to their errands, as if they were bots travelling
toward a distant ally on the other side of a zone or something.

> 6. How often is "sometimes talk"? For example, one target in five being a
> townsperson instead of
     a monster.

it is rare that monsters will be in capital cities, but it's more common for
them to be in regular towns. Typically there will be guards to assist, so if the
guards are fighting something then the buddy-bots should help out until there's
no monsters around, then they can converse. Though, in some cases the monsters
continuously spawn, so we should make sure that they do eventually prioritize
their errands over fighting, to get them done. Think like... the entrance room
in ICC. The monsters there spawn continuously, but a bot from a party parked in
front of a boss waiting for them to "go sell" will appreciate it if they
complete their business and then immediately return.



<pasted_content id="415d">
> 7. Can an area wrap around another one? The first cut of the Valley of Trials
> has the boars'
>      area wrapping around both sides of the scorpids. You drew three areas: the cave, the middle
>      upper area, and the town side. Is a wrapping area fine, or must each area be one solid piece
>      on one side?
</pasted_content id="415d">


with multiple spawn-zones, we defer to the sub-zone text - for example if you
enter a cave it shrinks the map to very small that they can wander in because
they must stay in the same sub-zone. But they can wander anywhere inside that
sub-zone that has the same monster spawns as the player is in.

> 8. Pointing the way to the next quest: buddies already hint by where they
> stand. Should they
>      also say it sometimes, like "the murlocs we need are down by the shore"?

nah



<pasted_content id="415d">
> 9. A bot owner's Sargobras. When a bot player meets Sargobras to choose its
> buddies, should he
>      still sit by a campfire and tell jokes afterward, even though no person is there to hear him?
>      Or should he leave at once?
</pasted_content id="415d">


the bot listens.

> 10. Quiet areas. An area marked as having almost no monsters and almost no
> friendly people: is
>       that counted once when the area is drawn, or live as creatures come and go?

danger should be assessed spontaneously.

--------------------------------------------------------------------------------

### Assistant Response 7

> Answers recorded; updating the todo list to mark the deferrals.

The answers are recorded word for word. The todo list now has 22 items. The smap
and the resting activities are marked as waiting until after the next compile,
and I've left that deferral out of the issue files, as you asked. Nothing is
committed yet.

## Ten more open questions

**Buddies offering to trade when you stand still.** This is written and waiting
for the compile, but its four questions were never answered. The idea: when you
stand still long enough, a buddy opens a trade window with you.

1. **What does a buddy put in the window?** Items that would be upgrades for
   you, things it doesn't need (trade goods, greens), gold, or nothing, leaving
   you to fill it by asking?
   *My call:* upgrades for you first, then its spare trade goods.
2. **How long is "standing still too long", and how long does the offer stay
   open?**
   *My call:* 20 seconds still, open for 30.
3. **Does it say something as it opens the window,** such as a line out loud or
   a whisper?
   *My call:* a short whisper, so you know why the window opened.
4. **When you put an item in its window, does it always accept, or judge it?**
   For example, accepting an upgrade and refusing junk.
   *My call:* it judges by its own stat weights, the same weights that pick its
   gear.

**Buddies in town**

5. **Between targets in town, should buddies drift from nearest thing to nearest
   thing, or also keep circling** the way they do while roaming?
   *My call:* drift only. The circling is for open ground.
6. **The town circle.** Today a town visit has a circle of errand spots
   (trainer, vendor, repair) that buddies walk between. Your answer last round
   (fight your way to errands, help the guards, then talk) seems to replace
   "errands first, nothing else". Does that answer cover it, or should the
   circle stay a separate rule?
   *My call:* your answer covers it, and I'll write it that way.

**Talents steering abilities** (still open from the first round, asked a little
differently)

7. **How strongly does one talent point pull a buddy toward an ability?** A
   fixed nudge per point, or as much as the talent changes the ability (a talent
   adding 15% damage pulls 15%)?
   *My call:* a fixed nudge. Talents that cut cost or cooldown have no clean
   percentage.
8. **Do talents steer only your buddies, or every bot on the server?** Every bot
   would mean a patch to the bot module.
   *My call:* buddies only for now, behind a switch.

**Stand-ins and prestige**

9. **A stand-in becoming a buddy.** When a stand-in from a battleground or
   dungeon joins you as a buddy, does it fill one of your owed buddy slots or
   replace an existing buddy? And does it keep its gear?
   *My call:* it fills an owed slot and keeps its gear.
10. **Prestige more than once?** You decided that a player retires by talking to
    a faction leader and reappears in that faction's starting zone, with
    Sargobras waiting. Can a player do that again and again, or only once?
    *My call:* again and again, each time noted on the character.

--------------------------------------------------------------------------------

### User Request 8

buddy-bots should mail upgrades to you. They shouldn't open trades with the
player, they should just accept trades when asked to trade. If a player asks to
trade with a buddy-bot, they should give any items that are "earmarked" for the
player to them. So upgrades and stuff. If the player asks for food or water we
can give them to them as well, but the buddy-bot will always split stacks of
them to ensure they have some too.

buddy-bots should only mail things when they're in town. Not just capital
cities, but wherever a mailbox is found. There's a mailbox in the DK starting
zone that's outside of a town so keep that in mind.

if the buddy-bot says to the player "my bags are full" they might also say "my
bags are full, can I give you something" and then they should walk to the player
and follow them in the dynamic arcs and such until combat starts again, or until
they get a resolution to their concern, which is their full inventory. If the
player trades with them, they can pass off some stuff, but if they trade and
then say "go sell" then whichever bots (that heard the "go sell" message) that
have above a certain threshold of inventory spots taken by sellable things will
go and sell them. If they give the player a couple items it's likely that they
still need to sell, but, they might be able to push it off a bit. If their
inventory is full, their "inventory economy" will encourage them to give items
away, to the player or to other buddy-bots. If the other buddy-bots are in range
and they want to give an upgrade or a consumable or whatever, then they should
just do that automatically through lua or whatever instead of using the trade
window bot-to-bot. But they should still walk to each other, face each other,
and do the talking emote with a random 0-1 second delay, then once it's done
they should both go their separate ways, having exchanged items of note.



<pasted_content id="415d">
> 5. Between targets in town, should buddies drift from nearest thing to nearest
> thing, or also
>      keep circling the way they do while roaming?
>      My call: drift only. The circling is for open ground.
</pasted_content id="415d">




<pasted_content id="415d">
> 6. The town circle. Today a town visit has a circle of errand spots (trainer,
> vendor, repair)
>      that buddies walk between. Your answer last round (fight your way to errands, help the
>      guards, then talk) seems to replace "errands first, nothing else". Does that answer cover it,
>      or should the circle stay a separate rule?
</pasted_content id="415d">


the errands are chosen semi-randomly. so it won't be a circle, otherwise the
buddy-bots will always choose the same tasks each time. They should instead
build a list of all the things they have to do, and then ping-pong between them.
If there are monsters along the way, they can fight them, but that's rare.

> 7. How strongly does one talent point pull a buddy toward an ability? A fixed
> nudge per point,
>      or as much as the talent changes the ability (a talent adding 15% damage pulls 15%)?

we will handle this in the ability economy system.



<pasted_content id="415d">
> 8. Do talents steer only your buddies, or every bot on the server? Every bot
> would mean a patch
>      to the bot module.
>      My call: buddies only for now, behind a switch.
</pasted_content id="415d">


why is it different? It should be every bot. All the things we make should be A.
sandboxed to a particular player, like how the original wow-chat was designed,
and B. fully idempotent / functional style, with the only state available being
the state that is stored on the player, which gets memory freed whenever they
log out.



<pasted_content id="415d">
> 9. A stand-in becoming a buddy. When a stand-in from a battleground or dungeon
> joins you as a
>      buddy, does it fill one of your owed buddy slots or replace an existing buddy? And does it
>      keep its gear?
</pasted_content id="415d">


fills an owed slot and keeps it's gear. Remember, it's only for the correct
race/class type. If you ask for a shaman and there's an appropriately levelled
troll shaman, then it'll select that one.



<pasted_content id="415d">
> 10. Prestige more than once? You decided that a player retires by talking to a
> faction leader
>       and reappears in that faction's starting zone, with Sargobras waiting. Can a player do that
>       again and again, or only once?
</pasted_content id="415d">


again and again

--------------------------------------------------------------------------------

### Assistant Response 8

> Rewriting the trade issue's intended behavior with your redesign:

> Now the errand ping-pong, talents for every bot, stand-ins and prestige:

> Another session is working on the talent system right now: it built both
> talent-weight options behind a setting and created new sub-issues on the
> ability economy. I'll keep my edits there minimal.

I've recorded all your answers word for word. The todo list now has 25 items,
and nothing is committed yet.

- **Trade issue:** rewritten around your redesign. Buddies never open trades.
  They mail earmarked upgrades from any mailbox, including the one in the death
  knight starting zone. They accept your trades, splitting food and water stacks
  so they keep some. Full bags trigger "can I give you something" and
  arc-following. "go sell" sends only the buddies over a threshold of sellable
  items. Buddy-to-buddy handovers happen by script, with the walk, face and talk
  emote around them.
- **Your rule about sandboxing every feature to a player** is now in the main
  issue about every bot playing by the house rules, as how all features are
  built. Talents steer every bot, not just buddies.
- **Correction:** I described the "town circle" wrongly last round. It's the
  circle that marks where a town is, not a loop of errands. Your answer still
  landed in the right place: errands are now drawn in a semi-random, weighted
  order.
- **Another session is working on the talent system right now.** It has built
  both talent-weight options behind a server setting and is writing new issues
  about the ability economy. I only added your two answers to its main issue and
  left the rest alone. Neither of us had a claim on that file, so you may want
  to tell that session your talent answers are in there.

## Ten more open questions

**In town**

1. **When a buddy in town finishes with one target and looks for the next**,
   does it just go to whatever is nearest? Or does it also keep up the slow
   circling it does on open ground?
   *My call:* nearest only. Circling in a crowd looks odd.

**Trading and mailing**

2. **When you hand a buddy something in a trade,** does it take everything, or
   judge each item? For example, it could keep an upgrade and hand junk back.
   *My call:* it takes everything, since you chose to give it.
3. **The "go sell" threshold.** What share of a buddy's bag spaces filled with
   sellable things makes it go?
   *My call:* half.
4. **What counts as "earmarked for you" besides upgrades?** For example, quest
   items for your quests, recipes you can learn, or bags bigger than yours.
   *My call:* all three.
5. **Should buddies mail money too,** such as anything above what they need for
   training and repairs? Or only items?
   *My call:* items only. Their money pays for their own training and repairs.

**Stand-ins**

6. **What is "appropriately levelled" for a stand-in filling a slot?** Exactly
   the slot's level, within a few levels, or within a 10-level bracket?
   *My call:* within 3 levels, so it fits the group.

**Prestige** (retiring at a faction leader and starting again)

7. **What level is a buddy after you're reborn?** Back at the level it first
   joined you (the level-30 buddy is 30 again), or does it stay at its old level
   and wait for you?
   *My call:* back to its joining level, so the group stays even.
8. **Can a death knight be reborn?** And if so, as what, given it starts at
   level 55?
   *My call:* yes, starting again at 55 in its own starting zone.
9. **After several rebirths, which old buddy can come back as "someone
   familiar"?** Only the latest one, or your choice of any buddy that slot has
   had?
   *My call:* your choice, offered by Sargobras.

**Following**

10. **Leaving a boat or zeppelin.** Buddies step aboard and ashore in a straight
    line, because the walking mesh doesn't cover decks. A gangway with a bend,
    or a zeppelin tower's platform, may need more than one leg. Do you want this
    watched in game first, or should I plan multi-leg boarding now from the
    recorded boardings?
    *My call:* watch first, then fix only what breaks.

--------------------------------------------------------------------------------

### User Request 9

<pasted_content id="415d">
> - Another session is working on the talent system right now. It has built both
> talent-weight
>     options behind a server setting and is writing new issues about the ability economy. I only
>     added your two answers to its main issue and left the rest alone. Neither of us had a claim on
>     that file, so you may want to tell that session your talent answers are in there.
</pasted_content id="415d">


we can take it off the todo list if someone else is working on it. But let's
swing back around when they're done and make sure they implemented it according
to what we in particular needed from it.

> 1. When a buddy in town finishes with one target and looks for the next, does
> it just go to
>      whatever is nearest? Or does it also keep up the slow circling it does on open ground?

it should pick one randomly. 50% chance to pick the nearest on their todo list,
50% chance to pick the farthest. unless the farthest is more than 4x the
distance to the nearest, then they do the nearest.

> 3. The "go sell" threshold. What share of a buddy's bag spaces filled with
> sellable things makes
     it go?

depends on how far the vendor they're gonna walk to is. 50% is if the vendor is
nearby, 80 or 90% if it's far. How about if the player says "everyone go sell"
then all the buddy-bots do it?

> 4. What counts as "earmarked for you" besides upgrades? For example, quest
> items for your
>      quests, recipes you can learn, or bags bigger than yours.

buddy-bots should not take quest items. Their quests are completed when the
player completes them, so there's no reason for the buddy-bots to take them.
They should leave them on corpses and leave the nodes behind.

> 5. Should buddies mail money too, such as anything above what they need for
> training and
>      repairs? Or only items?

maybe once or twice as a treat. Every once in a while. They'll usually just send
like 1c and say "I found a lucky penny for you." or 10g pieces for a level 60
and say "this fell out of some rich guy's pocket while I was walking close
behind him in Stormwind, don't worry about it" says the rogue, that sort of
thing.

> 6. What is "appropriately levelled" for a stand-in filling a slot? Exactly the
> slot's level,
>      within a few levels, or within a 10-level bracket?

within 3 levels, and they should be adjusted to match.

> 7. What level is a buddy after you're reborn? Back at the level it first
> joined you (the
>      level-30 buddy is 30 again), or does it stay at its old level and wait for you?

buddies will rejoin you once you hit the requisite level. This is why it's so
important to keep them dormant in stasis.

> 8. Can a death knight be reborn? And if so, as what, given it starts at level
> 55?

yes, with sargobras soul already given. We will need new functionality for the
prestige path, because Sargobras takes the "skip story/do the story" check
before requesting a soul. So we'll need a new menu just for prestigers (not a
new option, but a new menu) that just has two options, "I want to skip the
story" or "I want to see the story". Then it immediately jumps to as if the soul
was given. Make sure we don't lose track of WHICH soul the original one was, so
we can recreate the character if need be.

> 9. After several rebirths, which old buddy can come back as "someone
> familiar"? Only the latest
>      one, or your choice of any buddy that slot has had?

all of them I think...? Explain more?



<pasted_content id="415d">
> 10. Leaving a boat or zeppelin. Buddies step aboard and ashore in a straight
> line, because the
>       walking mesh doesn't cover decks. A gangway with a bend, or a zeppelin tower's platform, may
>       need more than one leg. Do you want this watched in game first, or should I plan multi-leg
>       boarding now from the recorded boardings?
</pasted_content id="415d">


we can record several entry paths per location where this is required. We'll
need a tool or utility that records positions, momentum, facing, etc, everything
else we can get and then we can run it through a manual LLM scrutiny test to
clean up things like "standing still at the start of the routine" and such, to
clarify the result to just the specificly needed waypoints. Then, when a
buddy-bot needs to enter a zeppelin or whatever, they'll select a path onto the
boat (preferring nearby ones) that another character is not currently using, and
if we run out of available paths then we try again with a +1 to the "how many
characters can be walking on this path" constraint.

--------------------------------------------------------------------------------

### Assistant Response 9

> Now the errand order (nearest or farthest), stand-in levels and prestige:

> Now boarding paths (question 10):

Recorded, and the todo list is updated:

- I removed the three talent-family items (weapon score, stat weights, boss
  learning) and added one item to check the other session's work against what we
  need once it's done: the weapon-speed lean, per-buddy stat weights, lessons
  chosen by stat weights, boss learning, and every bot sandboxed per player.
- **Errand order:** a coin toss between the nearest and the farthest errand
  left, with the nearest taken when the farthest is more than 4 times as far.
- **Selling:** buddies go at 50% full when the vendor is near, rising to
  80–90% when it's far. "everyone go sell" sends them all.
- **Loot and mail:** buddies leave quest items on corpses and quest nodes
  untouched. Now and then they mail a little money with a line in their own
  voice.
- **Stand-ins:** must be within 3 levels and get set to the slot's level when
  they join.
- **Prestige:** buddies wait dormant and rejoin when you reach their level. A
  reborn death knight gets its own two-line menu (skip or see the story), then
  carries on as if the soul had been given. The record of the original soul is
  kept.
- **Boarding:** several recorded entry paths per place, cleaned down to the
  needed waypoints, each buddy taking the nearest free one. When all are taken,
  one more walker is allowed per path.

## "Someone familiar," explained

At each rebirth, a buddy keeps its name, gender and, where it can, its race, but
it picks a new class, spec and professions. The exception is when you ask
Sargobras for "someone familiar". Then it comes back as it was before the
rebirth.

So one buddy slot builds up a history. Say a buddy named Kessa:

- **First life:** Blood Elf paladin
- **After rebirth 1:** Tauren druid (Blood Elves can't be druids, so her race
  changed)
- **After rebirth 2:** you ask for "someone familiar"

The question is what Sargobras offers at that point:
- **Latest only:** Kessa comes back as the druid.
- **All of them:** Sargobras lists each past version (the paladin, the druid)
  and you pick one. Choosing the paladin would also bring back her Blood Elf
  race.

"All of them" means keeping a record of every past version of each slot, which
is cheap: a few small fields per version.

**Is that what you meant by "all of them"?** A list of every past version to
pick from?

## Two left from this round

1. **When you hand a buddy something in a trade,** does it keep everything you
   give it? Or does it look each item over, keeping what it can use and handing
   the rest back?
2. **Where does "near" end for the selling threshold?** A distance in yards to
   the vendor, or a walking time (say, under a minute is near)?

--------------------------------------------------------------------------------

### User Request 10

buddy-bots should only change race / gender if the players race / gender
changes. So, I think Sargobras should only offer racially appropriate classes.
If the player gets a race-change, then all the buddy-bots will attempt to change
races if they can, randomly. If however it's a paladin and a blood elf or
whatever, or a draenei shaman, then they won't be able to change race until they
change class first.

If they ever change back, they should return to the same appearance that they
had originally.

the buddy-bot, if given stuff, should not give it back. Eventually we can
request things, but that requires LLM capability we don't have the hardware for
yet. Not at scale, at least.

"near" should be discrete, instead of relying on breakpoints and magic numbers,
it should scale and be dynamically calculatable at any time with any conditions.

--------------------------------------------------------------------------------

### Assistant Response 10

I've recorded all three answers word for word. Nothing is committed yet.

- **Race and gender:** this is now a general rule in the buddy roster issue. A
  buddy's race and gender change only when yours do, and Sargobras offers only
  classes its race can play. When you change race, each buddy tries a random
  race its class allows. Class-locked ones, like a blood elf paladin or a
  draenei shaman, wait until they've changed class. Each buddy's original look
  is kept, so changing back restores it exactly. This overturns the prestige
  issue's old line about buddies changing race to fit a new class, and the issue
  now says so.
- **Trades:** a buddy keeps whatever you give it. Asking it for things back
  waits until language-model capability is practical at scale.
- **When to go sell:** there's no near/far boundary any more. My proposal: a
  buddy goes when the sellable things it carries are at least as many as it
  would loot during the walk there and back. The loot rate is measured on that
  buddy, and the walk time comes from the path.
  - A nearby vendor means a short trip, so a few items justify it. That's about
    your 50%.
  - A far vendor needs a lot, about your 80–90%.
  - Full bags always send it.
  - Nothing in it is a fixed number.

## Two questions on those answers

1. **"Discrete."** You wrote that "near" should be discrete, then described
   something that scales and can be calculated at any time. I read that as
   continuous, with no steps, which is what I wrote. Is that what you meant? Or
   do you want a few distinct steps, each one calculated rather than fixed?
2. **"Someone familiar."** Since a buddy keeps its race now, its past versions
   differ only in class, spec and professions. For example: a priest, then a
   mage after the first rebirth, then you ask for someone familiar. Does
   Sargobras bring back only the latest version (the mage), or list every past
   version for you to choose (the priest or the mage)?

--------------------------------------------------------------------------------

### User Request 11

make sure that if we race change, then all the buddies will as well if they are
able to. So, don't pick the same race they currently are, because it's a race
*change*, not a race "random draw" or whatever.

um that "when to go sell" rule isn't a good idea. If the buddy-bots inventory is
full, they ask if they can go. when the party hears "go sell" then they can say
like "my inventory is 65% full, and it's pretty close, so I'm just gonna go
sell" and only take longer trips if it's full or near to it.

1. sorry yes I meant continuous.

2. class and professions should change at the same time. Sargobras only brings
   the most recent version back. We just store one profile probably, then an
   appearance set for each race they've visited.

--------------------------------------------------------------------------------

### Assistant Response 11

> Now "someone familiar" in the prestige issue:

All three answers are recorded word for word:

- **Race change:** when you change race, every buddy that is able changes too,
  always to a different race from the one it has now. Class-locked buddies (a
  blood elf paladin, a draenei shaman) wait until they change class. Each buddy
  keeps one appearance per race it has been, so changing back restores that
  look.
- **Selling:**
  - I dropped my loot-rate rule.
  - A buddy with full bags asks whether it can go and sell.
  - On "go sell", each buddy weighs how full its bags are against how far its
    vendor is, on a continuous scale. About half full is enough for a close
    vendor; a far trip needs nearly full bags.
  - The buddy says what it decided and why, like "my inventory is 65% full, and
    it's pretty close, so I'm just gonna go sell".
  - "everyone go sell" still sends them all.
- **"Someone familiar":** Sargobras brings back only the most recent version.
  Class and professions always change together. Each buddy stores one profile
  plus an appearance for each race it has visited. I updated the prestige
  issue's record step to match.

This round's questions are all answered. Nothing is committed, and the todo list
holds 27 items to build.

Most of those issue files already had uncommitted changes from other sessions
before today. When you want a commit, I'll stage only the lines I changed. I'm
still marked as holding these files in the shared claims list, and I'll clear
those marks once they're committed.

--------------------------------------------------------------------------------

### User Request 12

keep in mind that if we're in the depths of Outland or similar, a buddy-bot
might not be able to make it back alone to go sell. So they might refuse, if
they're the only one, and say "I'm scared" and then sufficient buddy-bots can
join them until they feel safe enough to make it. Prioritizing those with the
fewest remaining inventory slots, or rather, those who have the most to sell.
Remember, everytime a buddy-bot picks up an item, they decide immediately what
they want to do with it, and only update this plan if a new items plan would
change based on whether or not they did something different with it, like hold
onto it (a pearl for a recipe they know for example) or if they sold it (finally
have enough money to buy that 2h axe from the AH) etc.

Can you ask me 10 additional questions?

--------------------------------------------------------------------------------

### Assistant Response 12

Recorded:

- **"I'm scared":** a buddy whose way to the vendor is too dangerous alone
  refuses and says "I'm scared". Buddies with the most to sell join it until the
  group feels safe for the way, judged live, and then they go together.
- **Item plans:** each item gets its plan the moment it's picked up. A plan is
  revisited only when a newer item's plan depends on it, like the pearl for a
  recipe or the money for the two-handed axe. The plans are what the selling,
  earmarking and full-bags asking all read.

Both are in their issues word for word and on the todo list.

## Ten more open questions

**Going to sell when it's dangerous**

1. **How does a buddy judge "safe enough"?** One way: compare the group's
   combined strength (levels and roles) against the strongest monsters along the
   route, as seen right now. Or something else you picture?
   *My call:* group strength against the route's live danger, with a healer
   counting extra.
2. **Who stays with you?** If several buddies leave to sell, should enough
   always stay with you, so you're never left alone deep in Outland? Or can they
   all go if they all need to?
   *My call:* at least half stay, and whoever has the least to sell stays first.
3. **The hearthstone.** Buddies keep their hearthstones. Should a scared buddy
   hearth to town to sell when its hearthstone is ready, instead of walking?
   Then it rejoins you the way it would after any separation.
   *My call:* yes, when it's ready. It's what a player would do.
4. **Scared with no one to go with.** If no one can join it, does the buddy stop
   picking up low-value things until a trip becomes possible? Or does it keep
   looting and give things away to make room?
   *My call:* it keeps looting the most valuable things and drops plans for the
   cheapest.

**Item plans**

5. **The list of plans.** I wrote: wear it, keep it for a recipe, keep it to
   use, earmark it for you, give it to a clan-mate, sell to a vendor, auction
   it. Should "disenchant it" be added for buddies with enchanting, or anything
   else?
   *My call:* add disenchanting.
6. **Seeing the plans.** Should you be able to see a buddy's plans for what it
   carries, for example a command that lists each item and what it's for? Or is
   that only for logs?
   *My call:* a game master command, useful for checking the plans in game.

**Bots with buddies of their own** (by your rule that everything works for every
bot)

7. **How is a bot's clan named?** From a list of names, from the bot's own name
   ("Matis's Kin"), or chosen by the bot itself?
   *My call:* from its own name.
8. **When an alt bot leaves your party to adventure alone, do its buddies go
   with it** as its own group?
   *My call:* yes, the same as yours do with you.
9. **Random bots:** do they get buddies too, or are they owners with no buddies?
   There can be hundreds of random bots, and each buddy is a whole extra
   character on the server.
   *My call:* allowed by the same rules, behind a cap you set for server load.

**Exploring**

10. **The four ways of exploring a place.** Today each buddy is given one of
    four exploring patterns in turn, by its character number. Should you be able
    to pick the pattern per buddy instead, or should it stay automatic?
    *My call:* automatic, with a command to override it for testing.

--------------------------------------------------------------------------------

### User Request 13

if a buddy-bot is full inventory but not selling, they should still loot the
bodies but leave the items behind. If they need to need/greed an upgrade item
(need specifically, if inventory is full they pass on greed) then they can
destroy their least valuable item to make space. Something they already intended
to get rid of anyway.



<pasted_content id="415d">
> 1. How does a buddy judge "safe enough"? One way: compare the group's combined
> strength (levels
>      and roles) against the strongest monsters along the route, as seen right now. Or something
>      else you picture?
</pasted_content id="415d">


they should, always, have a general conception of what kinds of foes they alone
can defeat. We will use this mental model. They should also note who would be
travelling back with them, and build up an impromptu party so they walk
together. They should try and generally walk in formation for this but it's okay
if they drift apart, so long as they are able to help each other when needed.

> 2. Who stays with you? If several buddies leave to sell, should enough always
> stay with you, so
>      you're never left alone deep in Outland? Or can they all go if they all need to?

they might leave you in the dust.



<pasted_content id="415d">
> 3. The hearthstone. Buddies keep their hearthstones. Should a scared buddy
> hearth to town to
>      sell when its hearthstone is ready, instead of walking? Then it rejoins you the way it would
>      after any separation.
</pasted_content id="415d">


a scared buddy will be scared on the return trip as well. They should return
together. If one hearths, they should all hearth, and ride back to you if
needed. This also isn't just outland, a player could be level 30 and questing in
the hinterlands if they want.



<pasted_content id="415d">
> 5. The list of plans. I wrote: wear it, keep it for a recipe, keep it to use,
> earmark it for
>      you, give it to a clan-mate, sell to a vendor, auction it. Should "disenchant it" be added
>      for buddies with enchanting, or anything else?
</pasted_content id="415d">


yeah. any use you can think of.

> 6. Seeing the plans. Should you be able to see a buddy's plans for what it
> carries, for example
>      a command that lists each item and what it's for? Or is that only for logs?

nah. They might tell the player if asked when we set up llm capabilities but
that's for later.

> 7. How is a bot's clan named? From a list of names, from the bot's own name
> ("Matis's Kin"), or
>      chosen by the bot itself?

the bot chooses. We can build a system for that later. For now, just give it a
name from the same way we generate buddy-bot names.

> 8. When an alt bot leaves your party to adventure alone, do its buddies go
> with it as its own
     group?

yes, it is a player.

> 9. Random bots: do they get buddies too, or are they owners with no buddies?
> There can be
>      hundreds of random bots, and each buddy is a whole extra character on the server.

they get buddy-bots too. We won't have too many of them.



<pasted_content id="415d">
> 10. The four ways of exploring a place. Today each buddy is given one of four
> exploring patterns
>       in turn, by its character number. Should you be able to pick the pattern per buddy instead,
>       or should it stay automatic?
</pasted_content id="415d">

--------------------------------------------------------------------------------

### User Request 14

if a buddy-bot is full inventory but not selling, they should still loot the
bodies but leave the items behind. If they need to need/greed an upgrade item
(need specifically, if inventory is full they pass on greed) then they can
destroy their least valuable item to make space. Something they already intended
to get rid of anyway.



<pasted_content id="415d">
> 1. How does a buddy judge "safe enough"? One way: compare the group's combined
> strength (levels
>      and roles) against the strongest monsters along the route, as seen right now. Or something
>      else you picture?
</pasted_content id="415d">

they should, always, have a general conception of what kinds of foes they alone
can defeat. We will use this mental model. They should also note who would be
travelling back with them, and build up an impromptu party so they walk
together. They should try and generally walk in formation for this but it's okay
if they drift apart, so long as they are able to help each other when needed.

> 2. Who stays with you? If several buddies leave to sell, should enough always
> stay with you, so
>      you're never left alone deep in Outland? Or can they all go if they all need to?

they might leave you in the dust.



<pasted_content id="415d">
> 3. The hearthstone. Buddies keep their hearthstones. Should a scared buddy
> hearth to town to
>      sell when its hearthstone is ready, instead of walking? Then it rejoins you the way it would
>      after any separation.
</pasted_content id="415d">

a scared buddy will be scared on the return trip as well. They should return
together. If one hearths, they should all hearth, and ride back to you if
needed. This also isn't just outland, a player could be level 30 and questing in
the hinterlands if they want.



<pasted_content id="415d">
> 5. The list of plans. I wrote: wear it, keep it for a recipe, keep it to use,
> earmark it for
>      you, give it to a clan-mate, sell to a vendor, auction it. Should "disenchant it" be added
>      for buddies with enchanting, or anything else?
</pasted_content id="415d">

yeah. any use you can think of.

> 6. Seeing the plans. Should you be able to see a buddy's plans for what it
> carries, for example
>      a command that lists each item and what it's for? Or is that only for logs?

nah. They might tell the player if asked when we set up llm capabilities but
that's for later.

> 7. How is a bot's clan named? From a list of names, from the bot's own name
> ("Matis's Kin"), or
>      chosen by the bot itself?

the bot chooses. We can build a system for that later. For now, just give it a
name from the same way we generate buddy-bot names.

> 8. When an alt bot leaves your party to adventure alone, do its buddies go
> with it as its own
     group?

yes, it is a player.

> 9. Random bots: do they get buddies too, or are they owners with no buddies?
> There can be
>      hundreds of random bots, and each buddy is a whole extra character on the server.

they get buddy-bots too. We won't have too many of them.



<pasted_content id="415d">
> 10. The four ways of exploring a place. Today each buddy is given one of four
> exploring patterns
>       in turn, by its character number. Should you be able to pick the pattern per buddy instead,
>       or should it stay automatic?
</pasted_content id="415d">


eventually they will adjust themselves to get through certain terrain according
to which movement profile they think would work the best. I navigate a trail
differently than pavement.

--------------------------------------------------------------------------------

### Assistant Response 14

I've recorded all the answers word for word:

- **Full bags, no trip possible:** the buddy still loots its kills but leaves
  the items in them. In a loot roll it passes where it would greed. Where it
  would need an upgrade, it destroys its least valuable item, one it already
  meant to get rid of, to make room.
- **Going to sell:** each buddy always has a sense of which foes it alone can
  beat, and weighs the way's live danger against that. Buddies that go form an
  impromptu party and walk loosely in formation, close enough to help each
  other. They may leave you in the dust. They come back together, just as scared
  on the return trip. If one hearths, they all hearth, then ride back to you if
  needed. This applies anywhere you're beyond their strength, like a level 30 in
  the Hinterlands, not just Outland.
- **Item plans:** they cover every use an item can have, disenchanting included.
  You won't see them until buddies can talk about them through the language
  model.
- **Bots with buddies:** a bot's clan is named the way buddy names are drawn for
  now, and the bot will choose its own name later. An alt bot's buddies go with
  it, since it is a player. Random bots get buddies too.
- **Exploring patterns:** buddies will eventually pick their way of moving by
  the ground they're on. Until then, it stays by character number.

The todo list now has 29 items, and nothing is committed.

Your answers raised two new questions:

1. **Where does a buddy's sense of "foes I can beat" come from?** It could be
   worked out from levels, gear and the monster's rank (normal, elite), or
   learned from its own fights, which are already going to be written down. Or
   both, starting from levels and adjusted by experience?
   *My call:* both.
2. **How many random bots are "not too many"?** Each one with buddies adds
   several characters to the server. Should there be a cap on the total, or will
   you just keep the random-bot count low?
   *My call:* no extra cap. The random-bot count you already set governs it.

--------------------------------------------------------------------------------

