# Conversation Summary: 7fed8a61-f944-46d2-b1a4-cbb50023fa71

Generated on: 2026-08-07 14:51:11

--------------------------------------------------------------------------------

### User Request 1

hi can we add issue files to add an addon that interprets (aided by data) the
state of a character and sends it to an llm cluster to do some operations using
a soramech style system that explains and guides to a player who is listening on
the other end of a generation pipeline? and they can guide it any of many which
ways, and they can watch after a family of them if they please. real life is for
living, video games are for fighting.


--------------------------------------------------------------------------------

### Assistant Response 1

Before I write these, three things I can't resolve from the repo — and one is
load-bearing.


I found the neighbors first: **issue 916 (mod-soren-chat)** already builds the
three-box Ollama cluster, the effil worker pool, the health rotation, and a
guidance layer that edits playerbot strategy state. **916 + fourteen sub-issues
a–n.** What you're describing sits on top of that cluster rather than beside
it — the addon is a new *consumer* of the same pipe, aimed at a listener
instead of at the bots. The vision doc already ends with "Raise more than one.
Pick the purest, truest one," which is the family part.


What I can't find anywhere in the repo is **"soramech"** — zero hits across
issues, notes, docs, and transcripts. `soren` is there (the module name, chosen
deliberately as "a name, not a description"); `soramech` is not.


**[Asked the user]**


*Q1 — Soramech:* What does "soramech style system" refer to? I have no match
for it in the repo or in what I know.

- Pilot-and-mech metaphor — The character is a machine; the player is a pilot
  who never touches the controls directly. They receive a telemetry feed (state,
  threats, resources) narrated to them, and answer with orders. The LLM is the
  cockpit instrumentation — it turns raw state into something a pilot can hear
  and act on.

- A system from elsewhere — An external project, game, or piece of writing I
  should go read before designing this. Tell me where it lives and I'll read it
  first — a path, a URL, or just describe it.

- Related to 'soren' in issue 916 — A variant or successor of the module name
  already in the tree — same family of naming, possibly the same system
  growing a second half.

→ **Selected:** A system from elsewhere


*Q2 — Listener:* Where is the listening player actually sitting? "Listening on
the other end of a generation pipeline" reads as audio to me, but the delivery
channel decides most of the architecture.

- Audio out of the client — Text-to-speech on the far end. Player is doing
  dishes, driving, at work. No screen. Guidance comes back by voice or by a
  small set of typed commands. This is the strongest reading of 'real life is
  for living'.

- In-client AIO panel — A text feed inside WoW itself, like the healer-frames
  addon in issue 616. Player is at the machine but not driving — reading a
  narrated stream and clicking guidance.

- Through rmail — The Phase 10 external bridge that already exists in design.
  State summaries flow out as mail; guidance flows back in as mail.
  Asynchronous, survives being away for hours.

- A web page — Browser dashboard on the LAN. Reads the family's state, plays
  generated audio, takes guidance. Independent of the WoW client entirely.

→ **Answered:** the interface can be designed on a per-user and per-session
basis. So... however they want to interact with it.


*Q3 — The family:* What is the player guiding — and what does "a family of
them" mean?

- Their own characters, run by bots — The player's real characters are driven
  by playerbots while the player listens. The 'family' is several of the
  player's own characters adventuring in parallel, each generating its own
  narrated feed.

- Their playerbot companions — The player still has one character; the family
  is the companion party. Guidance shapes the bots, and the feed narrates what
  the companions are up to when the player isn't looking.

- Both, indistinguishably — No distinction is made — anything with a name
  and a state generates a feed and accepts guidance, whether it's a character
  the player made or a bot that attached itself. The family grows by adoption.

→ **Answered:** Their own characters, run by bots". Read the answers carefully
— they may request clarification, changes, or that you not proceed — and
follow what they actually say.


Found it: `/home/ritz/programs/sora/soramech/` — box-and-wire dataflow maps,
JSON per box, a C thread-pool runner, built for LLM orchestration. That changes
the design substantially, and for the better: its routing kinds line up almost
one-to-one with what this needs.


Writing the parent first.


Now the sensor half — the four issues that carry the correctness.


Now the map itself.


Last four: the addon, the return path, applying it, and sessions.


Sixteen files written. Nothing committed — the working tree has other people's
uncommitted work in it, and these are blueprints, not an implementation.


## What the SoraMech find changed


Reading `/home/ritz/programs/sora/soramech/` turned this from "another Lua
service" into something much smaller, because four of the hard problems are
already runtime primitives there:


| What this needs | SoraMech already has |

|---|---|

| Fan the loop across the family | `iterator` routing — round-robin over N output ports, atomic counter, parallel-safe |

| Split urgent from ordinary | `comparator` routing, with the else-branch *required* or the map won't start |

| Pick which cluster box gets this inference | `distributor` routing — least-busy pick |

| A long-running loop that never finishes | the shape it was built around: "thought after thought" |


The last one matters most: a map wired to feed itself is SoraMech's *primary*
case, not a special one.


And one mechanism I hadn't expected to get for free. Its input ports let a
value-emitting read box and a real producer share a port — the consumer takes
a queued value if one is waiting, and falls back to the read box when the slot
is empty. A read box is inexhaustible; it can be pulled every lap forever. So:
**the read box holds the standing order, a queued value is the player speaking,
and silence means the last thing they decided still holds.** That's "guide it
any of many which ways" falling out of port semantics rather than being built.


Two upstream constraints I wrote down because they'd otherwise bite silently:


- **A path-backed read box caches its file at graph load.** Point one at the
  fact feed and the pipeline narrates the first second of the session forever
  — plausibly, and without erroring. The fact ingest has to be a call box
  doing its own fresh I/O.

- **Runtime graph mutation isn't available** — SoraMech's own issue on it was
  implemented, rolled back in full, and is back in design. So "the player
  rewires the pipeline" means edit-and-restart. Which is exactly why the
  standing-order mechanism carries the weight.


## The shape


The family is **altbots** — your own characters handed to bot control, as
distinct from the config-generated rndbots that gear and roam themselves. That
distinction is load-bearing: rndbots would ignore guidance in favour of
self-management, so altbots are the only population where attending means
anything.


The pipeline is deliberately cut so the model knows nothing. Raw state →
**facts** (joined against `creature_template`, `item_template`, zone tables, so
every fact arrives already carrying its own words and licensing its own numbers)
→ salience → generation → a validator that rejects any proper noun or
number not traceable to the fact set. Your listener can't see the screen, so
they can't catch the model being wrong; the contract is structural rather than a
prompt instruction.


The first six issues produce a working attended mode with **no model in it at
all** — templated facts, spoken plainly, with alarms that interrupt. That
floor isn't scaffolding; it's what the validator falls back *to*, and what a
dead cluster degrades to.


## The judgment call I made


I filed this as a new **Phase 11 — Attendance**, not inside Phase 10. Phase 10
is a coordination phase for the mail bridge; attendance *uses* mail as one
interface but isn't about mail, and fifteen issues about narration and dataflow
would have made both harder to read. It also depends on every prior phase, which
is the capstone position. I updated the phase-structure summary table, added the
section, and wrote a Phase 11 progress page. If you'd rather it lived at 1007
inside Phase 10, nothing references these numbers yet.


Also worth knowing: the issue-to-concept cross-reference has no entries for the
whole 900/1000 range — the mod-soren-chat family from June never got added. I
didn't add 1101 alone to an already-lapsed doc. Happy to sweep the whole range
if you want it current.


## Where this stands


**Not done.** There are 76 open questions across the sixteen files, and per your
rule those are gates, not a closing section. Starting with the one that decides
how much work this actually is:


**Does an attended session need the WoW client running at all?** Altbots
conventionally need a master session — a logged-in player whose session owns
them. If you're fine with an anchor character parked in an inn keeping the
family logged in, this is buildable today with zero core changes. If attendance
should work with nothing running on your machine, someone has to build a
server-side session holder that keeps altbots alive with no master present — a
real patch against playerbot internals, and a new way for bots to outlive
whatever was supposed to clean them up.


Which is it?


--------------------------------------------------------------------------------

### User Request 2

<bash-input>pwd</bash-input>


--------------------------------------------------------------------------------

### User Request 3

<bash-stdout>/mnt/mtwo/games/azeroth-core/wow-chat-2026/issues</bash-stdout><bash-stderr></bash-stderr>


--------------------------------------------------------------------------------

### Assistant Response 3

You're in the directory with the new files. `ls 1101*` will show the parent plus
the fourteen sub-issues, and `phase-11-progress.md` is the status page alongside
them.


Still waiting on the anchor question when you're ready.


--------------------------------------------------------------------------------

### User Request 4

<bash-input>cwd ../</bash-input>


--------------------------------------------------------------------------------

### User Request 5

<bash-stdout></bash-stdout><bash-stderr>/bin/bash: line 1: cwd: command not
found

</bash-stderr>


--------------------------------------------------------------------------------

### Assistant Response 5

`cd ../` — `cwd` isn't a command. (`cd` is a shell builtin; the directory
persists between these calls.)


--------------------------------------------------------------------------------

### User Request 6

but I want to change the working directory up a level so we're in the root of
the project :(


--------------------------------------------------------------------------------

### Assistant Response 6

`! cd ..` does it — that's the command, `cd`, not `cwd`. The directory sticks
between calls, so everything after that runs from the project root.


--------------------------------------------------------------------------------

### User Request 7

<bash-input>cd ..</bash-input>


--------------------------------------------------------------------------------

### User Request 8

<bash-stdout>(Bash completed with no
output)</bash-stdout><bash-stderr></bash-stderr>


--------------------------------------------------------------------------------

### Assistant Response 8

Root of the project now.


--------------------------------------------------------------------------------

### User Request 9

yay thanks


--------------------------------------------------------------------------------

### Assistant Response 9

You're welcome.


The anchor question is still sitting there whenever you want it — whether an
attended session can assume a character stays logged in, or whether the family
needs to survive with nothing running on your machine. Everything else in the
fifteen issues works either way; that one decides whether the first issue is a
roster table or a patch against playerbot internals.


--------------------------------------------------------------------------------

### User Request 10

  Does an attended session need the WoW client running at all? Altbots
  conventionally need a master session — a logged-in player whose session owns
  them. If you're fine with an anchor character parked in an inn keeping the
  family logged in, this is buildable today with zero core

  changes. If attendance should work with nothing running on your machine,
  someone has to build a server-side session holder that keeps altbots alive
  with no master present — a real patch against playerbot internals, and a new
  way for bots to outlive whatever was supposed to clean

  them up.



you'll be playing your own characters. They'll just act using playerbots AI,
which we can improve over time of course. The LLM just provides a different way
to guide them between tasks or whatever.


--------------------------------------------------------------------------------

### Assistant Response 10

That closes it, and it closes it in the cheap direction — no core patch. Let
me verify one thing first, because it decides whether your own logged-in
character can be one of the family or has to stand apart from it.


Confirmed in the source in this tree —
`source-beta/modules/mod-playerbots/conf/playerbots.conf.dist:186`:


```

# Player can be activated as a bot (selfbot)

# Selfbot permission level (0 = disabled, 1 = GM only (default), 2 = all players, 3 = activate on login)

AiPlayerbot.SelfBotLevel = 1

```


Level 3 is your design exactly: your own character runs bot AI from the moment
you log in. So the anchor isn't a parked character standing in an inn — **the
anchor is a ward like the rest of them.** Updating the files.


That's propagated through six files. What your answer changed:


**The anchor problem is gone, and it took a whole design branch with it.** No
headless session holder, no patch against playerbot internals, no bots outliving
their cleanup. The mechanism is a config value that already ships. First issue
is now a roster table and a config patch.


**The family got uniform.** I'd had the session-owning character standing apart
from the wards — parked in an inn, doing nothing, justifying itself. Now it's
a ward like the others: same AI, same guidance, same feed. The only thing
special about it is that logging it out ends the session, which is a lifecycle
fact rather than a design wrinkle.


**The three modes became a dial, and the dial is per-ward.** Driving, attending,
away — the player is logged in for all three; what moves is where their hands
are. And it can sit in different places for different characters at once. You
fight the fight in front of you and let the other four get on with it: one
driven, four attended, all five in the same feed. That's the common case, not an
edge.


**"Between tasks" set the cadence, and it isn't a timer.** This one propagated
furthest. A fight ends, a place is reached, a ward runs out of something and
stops — those are the moments an explanation is actionable and guidance can
change what happens next. Between them the bot AI is executing and has nothing
to ask about. So:


- Salience gained a boundary term: the same fact is worth more at a boundary
  than mid-task

- The five guidance altitudes reordered around task as the load-bearing one —
  mood and standing order are what shape how boundaries resolve when you say
  nothing

- Latency stopped mattering almost everywhere. A few seconds to compose a good
  sentence at a boundary costs nothing, which is exactly why the urgent path is
  split off and templated. It's the only part ever in a hurry.


And the framing you gave — *the LLM is a different way to guide them between
tasks* — is a smaller claim than what I'd written, in a good way.
Moment-to-moment competence is the bot AI's job and it improves on its own
schedule. This thing chooses at boundaries and says what happened. It should
never make a decision the bot AI was going to make faster and better.


One config question fell out that I couldn't decide for you: **selfbot level 2
or 3?** Level 3 activates on login — you log in and your character is already
going, so driving becomes the deliberate act. Level 2 makes driving the default
and attending deliberate. It's a one-line config patch either way, gated per
profile; the question is only which one a session should start as.


--------------------------------------------------------------------------------

### User Request 11

  The family got uniform. I'd had the session-owning character standing apart
  from the wards — parked in an inn, doing nothing, justifying itself. Now
  it's a ward like the others: same AI, same guidance, same feed. The only thing
  special about it is that logging it out ends the

  session, which is a lifecycle fact rather than a design wrinkle.


they should each be a single connection, collected into a single view for the
user.


  One config question fell out that I couldn't decide for you: selfbot level 2
  or 3? Level 3 activates on login — you log in and your character is already
  going, so driving becomes the deliberate act. Level 2 makes driving the
  default and attending deliberate. It's a one-line config

  patch either way, gated per profile; the question is only which one a session
  should start as.


um, I dunno.


  And the framing you gave — the LLM is a different way to guide them between
  tasks — is a smaller claim than what I'd written, in a good way.
  Moment-to-moment competence is the bot AI's job and it improves on its own
  schedule. This thing chooses at boundaries and says what happened.

  It should never make a decision the bot AI was going to make faster and
  better.


The AI is just a different input method to the same game.


--------------------------------------------------------------------------------

### Assistant Response 11

Three things there, and the first one reorganizes the family.


Eight files touched. What each of the three did:


**"Each a single connection, collected into a single view"** — this one
reorganized the family. I'd been treating it as a party with a session owner at
the top; it isn't. It's N independent participants plus a view assembled over
them for one person. mod-playerbots already gives every bot its own world
session, so the connections were already separate — what your sentence settled
is where the *family* lives, and the answer is: in the view, nowhere else.


Four things fall out of that immediately. Party size stops bounding it — five
is a party limit, a family isn't a party. Scattering stops breaking it —
different zones, continents, instances, the view only cares that each connection
reports. No member is load-bearing for the others. And in the world they're just
unrelated people; nothing marks them as a set, which means everything that makes
them *feel* like a family is the interface's invention. That's now written into
the interface issue as a requirement rather than a nicety, because it's doing
all the work.


It also moved code. The family is a construct of the roster and the view, so
nothing in the world layer needs to know families exist.


**"The AI is just a different input method to the same game"** — this is the
sharpest thing said so far and it went in near the top of the parent, because it
settles arguments the other issues would otherwise each have separately. Not a
companion, not a narrator, not an agent. The same class of thing as a keyboard
or a screen reader, over a game that's unchanged and unaware.


The strict version: it gets no special powers, it conveys intent rather than
forming it, it's judged on latency and error rate rather than on personality, it
combines rather than replaces — nobody chooses between keyboard and mouse, and
driving one character while attending four is that same fact — and it can be
unplugged with the game still running.


That last one is what the templated floor already was; now it has a reason
instead of just being cautious.


It also replaced a list I wasn't happy with. The "what guidance cannot do"
enumeration in the apply issue now sits under a single rule that generates it:
**guidance can do what hands can do, and no more.** Not because the forbidden
things are dangerous, but because a directive that outruns what a player at the
keyboard could do means this stopped being an input method and became a cheat.


**"Um, I dunno"** — fair, and my question was badly framed. It isn't a design
decision, it's a knob: one config value, flipped in a config patch, observable
in a minute of play. I've written it down as
ship-level-3-and-flip-it-if-starting-already-in-motion-feels-wrong, with the
flip recorded in the balance-updates log where knob-turning goes. Off the gate
list.


One thing your answer surfaced that I can't settle from reading: **when your
character logs out, what happens to the other wards' sessions?** Persist, drop
immediately, drop after a timeout — that's upstream behavior, not a decision
available to us, and "your family kept playing while you were logged out" and
"your family stopped" are genuinely different products. It's now step 5 of the
first issue: enroll three, log out, watch. Cheap to find out, expensive to guess
wrong.


--------------------------------------------------------------------------------

### User Request 12

I think we're focusing on the wrong things. This is just supposed to be an AI
orchestration layer for bots in a video game. You're supposed to be able to
interface with it using text. Everything that the player can do, including log
out their character, should be up to them, or up to the system they co-create
with the AI.


--------------------------------------------------------------------------------

### Assistant Response 12

You're right, and I built the wrong thing. I took "listening on the other end"
and made a narration product — salience scoring, alarm paths, catch-up
digests, speech, session lifecycle. That's a lot of machinery bolted onto
something that's meant to be a layer that orchestrates bots and takes text.


The center, as you've put it:


- **An orchestration layer for bots.** Not a narrator, not an attendance mode.

- **Text.** One interface. I turned your per-session answer into a
  five-transport sub-map contract; it wanted to be a text box.

- **The action space is the player's action space** — including logging a
  character out. My "what guidance cannot do" list was wrong. The parity rule
  that replaced it is the whole rule and needs no list under it, because the
  system holds your authority in full. You don't restrict yourself.

- **You and the AI co-create the system, and it acts with your authority.**
  That's the part I under-built, and it's what the SoraMech map is actually for.
  The map *is* the co-created thing — boxes and wires the two of you build up
  over time. Everything is either you doing it or the system you built doing it.


Roughly six issues instead of fifteen:


1. **The orchestration map** — reads state, issues bot commands, runs
   continuously

2. **State as text** — bot and world state joined against game data, rendered
   for a model to read

3. **The text interface** — you type at it, it types back

4. **The action surface** — everything a player can do, reachable as commands

5. **Standing orchestration** — what persists between your messages

6. **Co-creation** — how the map grows as the two of you work out what you
   want


Gone: the salience ledger, the interrupt path and latency budgets, speech,
sessions and digests, the interface sub-map contract, the addon's sensor half.


One question before I cut. The fifteen files are uncommitted and from this
session. Rewrite them in place down to this shape, or move the over-scoped ones
to `declined/` with a note and write the smaller set fresh? Your rule is that
tickets are never deleted — I won't. I just don't know which of those two
you'd count as honoring it.


--------------------------------------------------------------------------------

### User Request 13

  - An orchestration layer for bots. Not a narrator, not an attendance mode.


there is also a narrator. What's an attendance mode?


  - You and the AI co-create the system, and it acts with your authority. That's
    the part I under-built, and it's what the SoraMech map is actually for. The
    map is the co-created thing — boxes and wires the two of you build up over
    time. Everything is either you doing it or the

  system you built doing it.


eh don't worry about soramech for now.


  4. The action surface — everything a player can do, reachable as commands


no, the AI should write those commands. The player should just ask.


  6. Co-creation — how the map grows as the two of you work out what you want


what map?


  One question before I cut. The fifteen files are uncommitted and from this
  session. Rewrite them in place down to this shape, or move the over-scoped
  ones to declined/ with a note and write the smaller set fresh? Your rule is
  that tickets are never deleted — I won't. I just don't

  know which of those two you'd count as honoring it.


move to declined/


--------------------------------------------------------------------------------

### Assistant Response 13

"Attendance mode" was my invention — a term I made up and then named a phase
after. It's gone, along with the phase. And you're right that there's a
narrator: the wandering narrator, the audience-facing one, the lore generation.
I shouldn't have said "not a narrator" as though narration didn't belong here; I
meant this isn't that.


Moving the fifteen now.


Now reverting the phase-structure and table-of-contents edits, since Phase 11
was built on a term I invented.


Reverted. Now the smaller set, as a sibling of the existing LLM work rather than
a new phase.


Done. Five files where there were fifteen, filed as a sibling of the existing
LLM work rather than a phase of their own.


**917 — Ask the bots in plain text**, with four under it:


- **What it can see** — bot state as text, IDs joined against the world
  database so names are names

- **The text channel** — where you type, where the reply comes back

- **Writing the commands** — request plus state to a command list, validated,
  issued, reported

- **What it keeps doing** — standing instructions, and the set of them
  accumulating into the thing you built together


The correction that mattered most was the fourth point. I had the player
learning a directive vocabulary, which is the same mistake as the command
vocabulary, just with friendlier words. You ask; it writes. That also made the
action surface disappear as an issue — mod-playerbots already responds to chat
commands, so there's no new control path to build. It writes the same commands
you'd have typed, which makes parity automatic rather than a rule I had to write
down and then contradict with a forbidden list.


The old set is in `declined/` intact, and 917 points at it, since the
state-reading and command-validation parts might be worth mining even though the
frame around them was wrong.


Nothing committed — the working tree still has other people's changes in it.


--------------------------------------------------------------------------------
