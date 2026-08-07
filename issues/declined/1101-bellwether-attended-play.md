# 1101 - Bellwether: Attended Play for a Family of Altbots

## Status
- Created: 2026-08-01
- Phase: 11 (Attendance) — **new phase, proposed by this issue**
- Priority: High (this is the capstone play mode; everything else feeds it)
- Depends on: 916 family (the LLM cluster and the directive-apply path),
  mod-playerbots altbot support, AIO, ALE, SoraMech (external project)

## Overview

The player stops driving and starts attending.

Their own characters — enrolled as altbots — keep adventuring. The server
reads what is happening to each of them, joins that state against the
game's own data until it is sentence-ready, and hands the result to the
LLM cluster. The cluster explains it to a player who is not looking at
the screen. The player answers however they like. Their answer becomes
standing policy for the family until they change it.

> real life is for living, video games are for fighting.

That line is the whole design brief. The player is doing something else.
They hear their family fighting. When something matters, they say what to
do about it, and go back to their life.

## The AI Is an Input Method

User directive, 2026-08-01: *the AI is just a different input method to
the same game.*

Not a companion, not a narrator, not an agent playing on someone's
behalf. An input method — the same class of thing as a keyboard, a
mouse, a gamepad, a screen reader. The game underneath is unchanged and
unaware that anything unusual is happening.

That framing is strict, and it decides arguments the rest of these
issues would otherwise have to have one at a time:

- **It gets no special powers.** Anything reachable through it is
  reachable with hands, and anything reachable with hands should
  eventually be reachable through it. Where those two diverge, that is a
  defect in the input method, not a feature of it.
- **It conveys intent; it doesn't form it.** Moment-to-moment competence
  belongs to the bot AI. Strategy belongs to the player. This sits
  between them carrying messages both ways.
- **It is judged the way input methods are judged** — latency,
  expressiveness, error rate, how often it does the thing you meant.
  Not on personality, and not on how impressive the sentences are.
- **It combines rather than replaces.** Nobody chooses between keyboard
  and mouse. Driving one character while attending four is the same
  fact about input methods, not a special mode.
- **It can be unplugged and the game keeps running.** That is what the
  templated floor is: the game still playable, still legible, with the
  clever part switched off.

## What "Attended" Means

The player is logged in throughout. That is settled (1101a): they are
playing their own characters, and the characters act on playerbot AI.
What varies is where their hands and their attention are.

| Mode | Player is | Input rate | What the pipeline owes them |
|------|-----------|-----------|-----------------------------|
| **Driving** | Hands on one character | Continuous | Nothing — the game is the interface |
| **Attending** | Logged in, looking elsewhere | Occasional, at their choosing | An explanation they can act on without looking |
| **Away** | Logged in, gone | None | A digest when they come back |

Attending is the middle one and the one nothing in the project serves
yet. Away is already served — the family keeps playing whether anyone
watches or not. Driving is served by the WoW client. The gap is the
player who wants to *know* without *watching*.

The three are a dial, not a switch, and the dial can sit in different
places per ward. A player fights the fight in front of them and lets the
other four get on with it: one character driven, four attended, all five
in the same feed.

### Guidance Happens Between Tasks

User directive, 2026-08-01: *the LLM just provides a different way to
guide them between tasks or whatever.*

That sets the cadence, and it is not a timer. The natural moment for
both an explanation and a piece of guidance is a **task boundary** — a
fight ends, a zone is reached, an objective completes, a ward runs out
of something and stops. Between those, the bot AI is executing and has
nothing to ask about.

Three consequences worth carrying into the sub-issues:

- **Salience should prefer boundaries.** A fact that arrives at a task
  boundary is worth more than the same fact mid-task, because it is
  actionable — the ward is about to decide something anyway.
- **The model is not in the loop.** Moment-to-moment competence is the
  bot AI's job, and that job gets better on its own schedule. This
  system chooses between tasks and phrases what happened. It never
  makes a decision the bot AI was going to make faster and better.
- **Latency stops mattering, except for alarms.** A few seconds to
  compose a good sentence at a boundary costs nothing. That is why the
  urgent path (1101f) is split off and templated: it is the only part
  that is ever in a hurry.

## Why a SoraMech Map, Not Another Lua Service

The generation pipeline is written as a SoraMech map — a directory of
JSON boxes wired together, run by `soramech-pool`. Not because a Lua
service couldn't do it, but because SoraMech's shape is already the
shape of this problem:

- **Long-running cyclic maps are its primary purpose**, not a special
  case. A map wired to feed itself turns indefinitely — "thought after
  thought" is the phrasing in its own overview. That is the attendance
  loop exactly.
- **The routing kinds line up one-to-one** with what this pipeline
  needs. See the table below. Three of the four hard problems here are
  already solved as runtime primitives.
- **The map directory IS the program.** The player is guiding a pipeline;
  being able to open the pipeline and see it as boxes is not a nicety,
  it's the difference between guiding a system and guiding a black box.
- **The JSONL transcript comes free.** One event per line, per run,
  ready to feed downstream. That is the observability story with no work.
- **Language-agnostic drivers.** The fact extractor wants to be Lua (it
  lives next to ALE's world queries); the salience ledger may want to be
  C; the transports are shell scripts. The map doesn't care.

### Routing kinds, mapped to this pipeline

| SoraMech routing kind | What it does | What it does *here* |
|-----------------------|--------------|---------------------|
| `iterator` | round-robin over N output ports | fan the lap across the family, one ward per port |
| `comparator` | pick a branch by numeric threshold | urgency split — a ward at 20% health takes the alarm branch |
| `distributor` | least-busy pick | pick which of the three cluster boxes gets this inference |
| `weighted` | probability-weighted pick | ambient colour: which flavour of remark gets made when nothing is urgent |
| `plain` | fan to every wire | send one utterance to every active interface at once |

The `distributor` kind is worth calling out: issue 916f specifies
per-host health tracking and rotation as bespoke Lua. As a SoraMech map,
least-busy host selection is a routing kind on a box. It is already
built, already threaded, already tested.

### The mechanism that makes guidance work

SoraMech input ports have a semantic that this design leans on hard.
From its map model: a port may have both call-box producers and read-box
predecessors; the consumer takes a queued value if one is waiting, and
falls back to the read box only when the slot is empty. A read box is
inexhaustible — it can never be starved, and it can be pulled on every
lap forever.

So:

- The **read box on a guidance port holds the standing order.** "Stay
  together. Don't fight anything more than two levels up."
- A **queued value on the same port is the player speaking.** It wins
  for that fire, and only that fire.
- **Silence is not absence.** When the player says nothing, the standing
  order is still there, still being pulled, every lap.

That is "they can guide it any of many which ways" falling out of the
runtime's port semantics rather than being built. The player's silence
has a meaning, and the meaning is the last thing they decided.

## The Family Is an Account of Altbots

mod-playerbots distinguishes two populations, and the distinction is
load-bearing here:

- **Rndbots** — generated from `.conf` settings. They gear themselves,
  apply talents, and roam the world autonomously. They need no guidance
  because they are already self-managing.
- **Altbots** — characters *the player created*, on their own account (or
  a linked account), handed to bot control with `.playerbots bot add
  name1,name2,name3` or a whole account at once with `.playerbots bot
  addaccount [accountname]`. Altbots do **not** self-gear and do **not**
  roam.

The family is altbots. That is not an arbitrary choice — it is the only
population where guidance means anything, because rndbots would ignore
it in favour of their own self-management, and because these are the
player's own characters. The vision document's closing promise is
already this feature:

> Raise more than one. Pick the purest, truest one.

### Each Ward Is Its Own Connection; the Family Is a View

User directive, 2026-08-01: *they should each be a single connection,
collected into a single view for the user.*

So a family is not a party, not a master with followers, not a squad
under a leader. It is N independent participants in the world, plus a
view assembled over them for one person's benefit. This is closer to how
things already work than a party abstraction would be — mod-playerbots
gives each bot its own world session, so the connections are already
separate. What this settles is where the *family* lives: in the view,
and nowhere else.

Consequences worth carrying into every sub-issue:

- **Party size doesn't bound it.** Five is a party limit. A family isn't
  a party, so it isn't five.
- **Scattering doesn't break it.** Different zones, different
  continents, different instances. The view doesn't care where they are;
  it only cares that each connection reports.
- **No member is privileged.** There is no master whose loss drops the
  others, and no ward that matters more structurally than the rest. The
  one the player has their hands on is just the one they have their
  hands on.
- **In the world they are just people.** Nothing in the game marks them
  as a set. The set exists for the person watching, which is exactly
  what a view is.
- **The family is a construct of the roster and the interface**, not of
  game state. That decides where the code goes: 1101a owns the roster,
  1101j and 1101k own the view, and nothing in the world layer needs to
  know a family exists.

Cross-account families are supported upstream through
`AiPlayerbot.AllowTrustedAccountBots` plus the `.playerbots account
setKey` / `account link` pair. A player can attend a family drawn from
several accounts, or two players can attend a shared family. Out of
scope for the first pass, in scope for the design.

## The Interface Is Chosen Per User, Per Session

User directive, 2026-08-01: the interface can be designed on a per-user
and per-session basis — however they want to interact with it.

This is why the transports are not a fixed list in this issue. An
interface is a **SoraMech sub-map**: a set of sink boxes (where the
utterance goes) and source boxes (where guidance comes back from),
encapsulated as one box on the parent canvas. A session names the
interface sub-map it wants at start-up, and the pipeline above it does
not change.

Same family, same facts, same voice; the player picks the window.
Someone driving to work gets speech and answers by voice. Someone at
their desk with the client open gets an in-client panel. Someone away
for a day gets rmail. Someone who wants none of it gets a text file and
`tail -f`.

## The Anti-Hallucination Contract

The listener cannot see the screen. That means they cannot catch the
model being wrong. A model that invents a creature name, a number, or a
death is not producing flavour — it is lying to someone who has no way
to check, about characters they care about.

So the pipeline is built around one rule, enforced structurally rather
than by prompt discipline:

**The narrator may only speak facts it was handed.**

Facts are extracted deterministically (1101c), before any model sees
anything. Every proper noun and every number in an utterance must trace
back to a fact in the set that produced it, or the utterance is rejected
(1101i). The model's job is to choose what matters and say it well — not
to know anything.

## Flow

```
worldserver (ALE)
  ward state reader  ─────────────────────────────►  raw snapshot per ward
                                                        │
  fact extractor (joined against world data)  ◄─────────┘
       creature entry → name, rank, level
       zone id        → zone and subzone names
       item id        → name, quality, slot
                                                        │
  salience ledger  ◄────────────────────────────────────┘
       what changed, what's worth saying, what's gone stale
                                                        │
                                                    facts out
                                                        │
soramech-pool  (maps/bellwether/)                       ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  ingest ──► iterator (one port per ward)                     │
  │               │                                              │
  │               ├─► comparator: urgent? ──yes──► alarm line    │
  │               │                                (no inference)│
  │               └─no──► prompt build ──► distributor ──► box1  │
  │                                              ├──────► box2  │
  │                                              └──────► box3  │
  │                            │                                 │
  │                       validator ──► reject? retry once,      │
  │                            │        then templated fallback  │
  │                            ▼                                 │
  │                  interface sub-map (per session)             │
  │                     speech │ panel │ rmail │ file            │
  └──────────────────────────────┬───────────────────────────────┘
                                 ▼
                            [ the player ]
                                 │
                          guidance, whenever
                                 │
  guidance parse ◄───────────────┘
       freeform words → bounded directives
                                 │
  standing orders  ──► read-box defaults, queued overrides
                                 │
  directive apply  ──► mod-playerbots ChangeStrategy / SorenDirected
                                 │
                                 ▼
                          the family fights on
```

## What Lives Where

SoraMech is an external project and stays that way — unforked,
unvendored, upstream. This repo's patch-system philosophy applies
unchanged: we do not hard-fork third-party source.

| Thing | Lives in | Why |
|-------|----------|-----|
| SoraMech runtime, editor, drivers | `/home/ritz/programs/sora/soramech/` | upstream, untouched |
| The Bellwether map | this repo, `maps/bellwether/` | it's our program, written in their format |
| Fact extractor, state reader | this repo, ALE Lua | they need world-DB access |
| The addon | this repo, AIO | client half |
| Cluster HTTP, host health | reused from the 916 family | already specified there |

The map directory is SoraMech's stable interface — its own overview says
server and runner "share nothing but the files." We write files in that
format. That is the whole integration.

## Sub-Issues

Fourteen, in dependency order. The first four produce no LLM output at
all — they produce *facts*, which is most of the work and all of the
correctness.

### The sensor (no LLM, no map)

- **1101a — Family enrollment and staying in the world.** Who is in the
  family, how they get there, and the hard part: keeping altbots alive
  while the attending player isn't playing. Altbots conventionally
  require a master session.

- **1101b — Ward state reader.** One struct per ward per tick: position,
  zone, health, resource, level, combat state, target, party, deaths,
  loot, current bot strategy set. Raw values only, no interpretation.

- **1101c — Fact extraction, aided by data.** The "aided by data" half of
  the request. Turns entry IDs into names by joining against the world
  database. Emits typed, sentence-ready facts. This is the file that
  makes the difference between "creature 1234 at 0.42" and "the Defias
  Pillager has Tessa down to a third."

- **1101d — Salience and the event ledger.** Not everything is worth
  saying to someone who is driving. Change detection, a salience score, a
  ledger of unspoken facts that ages, and a budget of how much a listener
  can absorb per minute.

### The map

- **1101e — The Bellwether map skeleton and family fanout.** Map
  directory, meta, the cyclic re-arming shape, the drivers, and the
  `iterator` fanout across the family. Facts in, facts printed. No
  intelligence yet.

- **1101f — The urgency branch and the interrupt path.** `comparator`
  routing on urgency. Death, a ward below a health threshold, a ward
  stuck or lost, a ward idle too long — these skip generation entirely
  and speak a fixed line immediately. The alarm path must never wait on
  inference.

- **1101g — Inference boxes and cluster routing.** The call box that
  POSTs to Ollama, `distributor` routing across the three hosts,
  timeouts, and what a lap does when a host dies mid-flight.

### The voice

- **1101h — The explaining voice: prompt and persona.** Turning facts
  into something a listener can act on. Explains *why*, not just what.
  Per-ward voice consistency across sessions.

- **1101i — Utterance validator.** Enforces the anti-hallucination
  contract. Rejects any proper noun or number not traceable to the fact
  set. Retry once, then a templated line built from facts alone — and a
  logged warning, because a fallback is a warning and a warning is an
  error.

### The window

- **1101j — Interfaces as sub-maps.** The per-user, per-session
  mechanism. Ships with a text stream, speech, and the in-client panel;
  rmail and a web page follow.

- **1101k — The Bellwether addon (AIO client half).** The in-client
  presence: family roster, utterance log, guidance controls, and the
  things only the client can see. Also the "I'm back at the screen"
  transition.

### The return path

- **1101l — Guidance capture, vocabulary, and standing orders.** The
  "many which ways" part — the player can answer at five different
  altitudes, and each lands somewhere different in the system. Plus the
  read-box/queued-value mechanism that makes silence mean something.

- **1101m — Applying guidance to the wards.** Reuses the 916 directive
  path. Levers, not arbitrary control.

- **1101n — Session lifecycle, catch-up digest, and observability.**
  Starting, going away, coming back, "what did I miss," ending. Plus
  `.bell status` and what the JSONL transcript is asked to answer.

## Implementation Order

1. **1101a** — without a family there is nothing to attend
2. **1101b, 1101c** — the sensor; 1101c is the correctness-critical one
3. **1101d** — salience; can be crude at first (a fixed priority table)
4. **1101e** — the map skeleton; first end-to-end run, no LLM
5. **1101j (text stream only)** — the cheapest possible window, so the
   rest can be developed by watching it
6. **1101f** — urgency; deliverable value before any generation exists
7. **1101g, 1101h, 1101i** — the generation layer, together
8. **1101l, 1101m** — the return path; the first point at which this is
   a *game* rather than a broadcast
9. **1101k** — the addon
10. **1101n** — sessions and observability
11. **1101j (remaining interfaces)** — speech, rmail, web

Steps 1–6 produce a working attended mode with no LLM in it at all:
templated facts, spoken plainly, with alarms. That is the honest floor,
and it should be shippable on its own. Everything after it is the model
making that floor pleasant.

## Known Upstream Constraints

Two SoraMech facts that shape the design and are not negotiable from
this side:

- **Path-backed read boxes cache at graph load.** A `read` box with a
  `path` reads the file once when the graph loads and caches it for the
  run — editing the file mid-run has no effect. Since the map is
  long-running, the fact feed **cannot** be a path-backed read box. It
  has to be a `call` box that does its own fresh I/O on every fire.
  Getting this wrong produces a map that narrates the first second of
  the session forever.

- **Runtime graph mutation is not available.** SoraMech's issue 419
  (runtime graph mutation) is open, in its phase 4, after a phase-3
  implementation was rolled back in full. So the "player rewires the
  pipeline live" altitude of guidance means *edit the map and restart
  the run*, not *mutate the running graph*. This is exactly why the
  standing-order mechanism matters: it gives live re-guidance without
  needing mutation.

## Open Questions

These are gates, not decoration. Each needs an answer before the
sub-issue that depends on it can be called done.

- **The name.** "Bellwether" is a working handle — the sheep that wears
  the bell, so the shepherd hears the flock without watching it, which
  is the mechanic exactly. It also rhymes with issue 911's shepherd and
  flock. But 916's note establishes that names here are handles, not
  contracts, and this one may not be yours. What should it be called?

- **Is the cluster in 916 the same hardware as SoraMech's "SoraMind
  Alpine cluster"?** 916 specifies three mini-PCs at 192.168.1.11–13 on
  ports 10101/20202/30303. SoraMech's vision names an Alpine cluster as
  its primary inference target. If they are the same three boxes, the
  two systems are contending for the same slots and need one shared
  budget. If they are different, this issue needs to say which it uses.

- **Where does `soramech-pool` run?** Same host as the worldserver, or
  on the cluster? Its own vision lists a remote runner as a future
  direction, not a present capability.

- **How does the player answer when they're driving?** Speech-to-text is
  the obvious answer and the project has no speech stack yet. Is there
  an acceptable fallback — a phone keyboard, a few physical buttons, an
  rmail reply — or does attendance-by-voice need a whole ASR issue of
  its own?

- ~~**Does an attended session need the WoW client running at all?**~~
  **Answered 2026-08-01:** the player is logged in and playing their own
  characters; the characters act on playerbot AI. Selfbot permission
  level (`AiPlayerbot.SelfBotLevel`) is the mechanism and it already
  exists. No headless session holder, no core patch. See 1101a.

- **How many wards can one player actually attend?** Not a technical
  limit — a human one. Two feels natural, five feels like a spreadsheet.
  This number sets the salience budget in 1101d.

- **What happens when a ward dies while the player is away?** Resurrect
  and continue, sit and wait, or is the death the point? Issue 806's
  permadeath design and issue 406's death-durability system both have
  opinions here that this needs to respect.

- **Which profile?** Vanilla is active and 916 targets it. Vanilla's
  design philosophy is "default WotLK + playerbots, no wow-chat design
  layer" — this feature adds no content, only a window, so it arguably
  fits the same envelope 916 argued itself into. Worth confirming rather
  than assuming.

## Related

- [916 - mod-soren-chat](916-mod-soren-chat.md) — the cluster, the effil
  workers, the health rotation, and the directive-apply path. Bellwether
  is a second consumer of the same pipe, aimed at a listener instead of
  at the bots. Substantial reuse, and one point of overlap worth
  resolving: 916f's bespoke host rotation versus SoraMech's
  `distributor` routing kind.
- [911 - Shepherd and Flock System](911-shepherd-flock-system) — the
  older sibling in spirit. A shepherd who wanders with a flock, and a
  player who can permanently become one of the flock and watch the world
  through its eyes with no input accepted. Bellwether is the inverse:
  all input, no eyes.
- [908 - Narrator Audience Facing](908-narrator-audience-facing) and
  [910 - Wandering Narrator System](910-wandering-narrator-system) —
  in-world narration to players who are present. Bellwether narrates to
  a player who is absent.
- [912 - Automated Lore Generation](912-automated-lore-generation) —
  the other generative pipeline; shares the cluster.
- [616 - Public Healer Frames Addon](616-public-healer-frames-addon.md)
  — the existing AIO addon precedent, including the SecureActionButton
  and combat-lockdown research that 1101k will need.
- [1004 - rmail In-game Bridge](1004-rmail-ingame-bridge) — one of the
  interface sub-maps in 1101j is an rmail transport, and it should reuse
  this rather than invent a second mail path.
- `notes/wow-chat-secretary` and `notes/wow-chat-secretary-2` — the
  standing house position on what an LLM is allowed to touch: *"An LLM
  should have levers to pull, not timestamps to clobber and crush."*
  1101m is that principle applied to a game character.
- SoraMech, at `/home/ritz/programs/sora/soramech/` — read `notes/vision`
  and `docs/002-map-model.md` before writing any box.
- mod-playerbots altbot commands — `docs/playerbots/Playerbot-Commands.md`

## Notes

The request that produced this issue, kept verbatim because the phrasing
is the specification:

> an addon that interprets (aided by data) the state of a character and
> sends it to an llm cluster to do some operations using a soramech
> style system that explains and guides to a player who is listening on
> the other end of a generation pipeline? and they can guide it any of
> many which ways, and they can watch after a family of them if they
> please. real life is for living, video games are for fighting.

Three phrases in there are doing structural work and should survive
refactoring:

**"aided by data"** — the model is not the interpreter. The world
database is. The model only chooses and phrases.

**"any of many which ways"** — guidance is not one channel with one
grammar. It is five altitudes, from a mood to a rewire, and the system
accepts all of them.

**"watch after"** — not *control*, not *manage*. You watch after a
family. They are doing the living; you are keeping an eye out.
</content>
</invoke>
