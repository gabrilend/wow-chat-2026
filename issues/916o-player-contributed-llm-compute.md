# 916o - Player-Contributed LLM Compute

## Status
- Created: 2026-10-04
- Parent: Issue 916 (mod-soren-chat)
- Phase: 3
- Priority: Low (the LAN cluster carries the load until this exists)
- Depends on: 916e (worker pool), 916f (cluster health rotation), 916k (persona)
- Related: 916n (debug commands and observability), 917 (ask the bots in plain text)

## Origin

Verbatim, 2026-10-04:

> could we add an issue file for the custom client that packages llama.cpp
> or similar into the client? then, we can "shard" or "distribute" llm
> compute tasks to all the players who wanted to contribute. We'd also have
> a UI gizmo that showed exactly what was being done on their machine. "oh
> an orc in Stranglethorn is talking to a Night Elf" very abstracted,
> nothing specific, but they'd still be able to see the text that was being
> generated. It'd show the processing task with as many little dials and
> gauges and bar charts and sliders that we can think of, because players
> love those kind of details. Plus we could let them fiddle with the way
> that characters are processed too - maybe even adding their own custom
> system prompts. In this way, each player gets to contribute to the nature
> of the collective. The system prompts that players can provide should not
> determine behavior (to the best of our ability) but rather the *nature* of
> the character who is being performed. Their qualities, and
>
> --- stack overflow ---

The thought was cut off there; the end of the last sentence is an open
question below.

Shortly before, about the unsorted note `vision-mindscape` ("a disembodied
mind journey through a problem space"): "it's also related to the LLM
personality system."

## Current Behavior

Nothing of this exists. Inference for bot chat and bot guidance is designed
(916) to run on three mini-computers on the LAN, reached from the
worldserver through a pool of worker threads (916e) that takes a dead box
out of rotation and re-probes it (916f). Every worker is a fixed, trusted
host named in configuration. Personas (916k) are generated on the server
and stored per bot; no player has any say in them.

## Intended Behavior

A player who opts in runs a small inference program alongside their game
client. It joins the same rotation the LAN boxes are in, as a lower-trust,
come-and-go worker, and takes a share of the bot conversation work.

**Why a companion program and not the client itself.** The 3.3.5a game
client is a closed binary. Its addons are sandboxed Lua with no network
access, no threads and no file writes outside saved variables, so an addon
cannot run a model. The inference therefore lives in a separate program
(llama.cpp's server, or similar) shipped in the same download as the client
and launched by the same launcher. The in-game part is only the display.

**Data path, end to end:**

1. The worldserver's pool decides a chat job can go to a contributor. A job
   is a prompt (text), a model name (text), a token limit (integer) and a
   job id (integer).
2. The contributor's companion program holds one outgoing connection to a
   small job broker on the server side. Outgoing, so no player opens a port
   or touches their router. It receives the job, runs it locally, and
   streams tokens back.
3. The broker hands the finished text to the worldserver pool exactly as a
   LAN worker would, so validation (916i) and rate limiting (916l) apply
   unchanged.
4. In parallel, the server sends the contributor's own game client a
   compact description of the job through addon messages (the server can
   push those to one player). The addon draws the gizmo from these.

**The gizmo (in-game addon window).** It shows what the player's machine is
doing, abstracted to who-and-where, never whose account:

- the scene, as "an orc in Stranglethorn is talking to a night elf" (race
  and zone, no character names, no player names)
- the generated text as it streams
- dials and gauges: tokens per second, prompt length versus context window,
  time-to-first-token, jobs done this session, the machine's share of all
  jobs served right now
- bar charts of recent job lengths and speeds; a history sparkline
- sliders the player owns: how many jobs at once (integer, 0 = paused), and
  the longest job they'll accept (tokens)

**Player-written character nature.** A contributor may write a "nature
prompt": text describing qualities (temperament, voice, what the character
notices, what they care about). It shapes how characters are performed. It
must not steer what they do. Two layers keep it that way:

- Placement: the nature text goes into the persona section of the prompt
  (916k), never into the guidance prompt (916h) that decides bot strategy.
  Guidance jobs are never sent to contributors at all.
- Validation: replies still pass the existing response validator (916i),
  which only accepts the expected shape (one in-character line). A nature
  prompt that tries to issue commands produces, at most, a strange line of
  speech.

Each nature prompt is stored with its author, and the characters it shaped
are recorded, so "each player contributes to the nature of the collective"
can be seen and traced.

**Trust.** Contributor machines are untrusted. A contributor sees only the
prompts it is sent, which must therefore never contain account names,
private messages or anything a player typed in a whisper. A contributor can
return anything; the validator is the gate, and a contributor whose output
fails validation repeatedly is quarantined like a dead LAN box (916f).

## Suggested Implementation Steps

1. Separate "chat" jobs from "guidance" jobs in the worker pool (916e) by a
   job-kind field, so only chat jobs are ever eligible for contributors.
2. Write the prompt scrubber: a pass over a built chat prompt (916k) that
   removes or refuses player names, account data and whisper text, with a
   test that feeds it prompts containing each.
3. Build the job broker beside the worldserver: accepts outgoing
   connections from companion programs, keeps a per-contributor record
   (contributor id: integer; jobs in flight: integer; recent failures:
   integer; tokens per second: number; last seen: time), and presents
   contributors to the pool as workers with health state (916f).
4. Build the companion program: wraps llama.cpp's server, connects out to
   the broker, runs jobs, streams tokens back. Ships with the client
   download and starts with the launcher.
5. Build the addon gizmo; the server sends job summaries (scene, token
   counts, timings) to the contributing player as addon messages.
6. Add nature prompts: storage (author, text, created), a way to submit them
   in game, placement into the persona section only, and the
   characters-shaped record.
7. Tests: a guidance job is never routed to a contributor; a scrubbed prompt
   never carries a planted player name; a contributor returning malformed
   output is quarantined; a nature prompt containing commands produces
   only a validated line of speech.

## Open Questions

1. The origin was cut off at "Their qualities, and" — what came next?
2. Should the nature prompt apply to the characters the contributor's own
   machine performs, to the contributor's own buddies, or be mixed into a
   shared pool that shapes everyone's bots?
3. The persona issue (916k) records that persona design is "not where you
   want to spend design energy". Does this issue reopen that, so that
   persona becomes a designed system?
4. Which model, and what is the smallest machine that should be allowed to
   contribute? This decides the download size and how many players can
   take part.
5. How does `vision-mindscape` ("a disembodied mind journey through a
   problem space") connect to the personality system? Is it about how one
   character thinks, or how the collective of nature prompts is navigated?
6. Should contributors see the text their machine generated for other
   players' conversations? The origin says yes, abstracted. Should the
   players in that conversation be told their lines may be shown, without
   names, to someone else?
