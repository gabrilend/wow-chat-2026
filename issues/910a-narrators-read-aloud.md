# 910a - Narrators Read Aloud

## Status
- Created: 2026-10-18
- Phase: 9
- Parent: 910 (wandering narrator system)
- Blocked by: 909 (the library and its books)
- Priority: Medium

## Origin

See 910. The owner, 2026-10-18, on what a narrator is: "as written.
players need to be able to whisper to them." (playerbots, not creatures).

## Current Behavior

**Built 2026-10-18 on the homework branch; tested without a server, not yet
tried in game.**
- `src/lua-beta/narrators.lua` (notes in `narrators.info.md`): narrators are
  bots numbered a multiple of `NARRATOR_EVERY` (20); a timer every two
  seconds has each narrator a real player hears say its next line, one
  part of a long sentence at a time, then pause 3 seconds plus 60 ms a
  character; a real player's /say quiets the narrators who hear them for
  20 seconds; logout forgets the reader; a library that cannot start is
  said once in the server log, naming install step E059, and the narrators
  stop.
- `scripts/test-narrators`: 13 checks with stand-ins for the engine and a
  test shelf. The first run found the base pause too short (at 1.5 seconds
  a short line came every tick); it is 3.
- `scripts/test-beta-lua-load` loads it as the engine does (3 event
  registrations, no errors).

Not yet: tried in game on beta (step 3), and question 1.

Before this, beta's random playerbots wandered and fought; none read aloud.

## Intended Behavior

- **Who narrates.** A fixed share of beta's random playerbots are
  narrators: those whose character number is a multiple of
  `NARRATOR_EVERY` (a number in the script; one in twenty to start). The
  rule needs no database and picks the same bots after every restart.
- **What they read.** Each narrator is its own reader in the library (909):
  started when it is first heard, with a random book from its first
  sentence, forgotten when it logs out. A sentence too long for one chat
  line is said in parts, one after another.
- **When they read.** Only when a real player (not a bot) is within
  hearing (`HEAR_YARDS`) on the same map: nobody else is listening, and a
  narrator talking to bots would fill the server with chat for no one. One
  part at a time, with a pause after it that grows with its length (about
  reading speed), so a listener can follow.
- **Falling quiet.** When a real player speaks in /say within hearing, the
  narrators near them stop for a while (`LISTEN_SECONDS`) and then go on
  from the same sentence: they are listening (910's interruption, before
  rumour mode exists).
- **Errors, not silence.** If the library cannot start (no books built,
  E059 not run), the script says so once in the server log, naming the
  install step, and stops trying, rather than failing every tick.

## Suggested Implementation Steps

1. `src/lua-beta/narrators.lua`: the narrator rule, a timer every couple of
   seconds over the online narrators, the reading with its pauses, the
   /say listening, logout clearing the reader; tuning numbers at the top.
2. `scripts/test-narrators`: the script with stand-ins for the engine's
   functions (players, bots, distance, say, chat, logout, the timer) and a
   two-book test shelf: a narrator reads only when a real player is near;
   bots alone hear nothing; parts of a long sentence come in order; a
   player's /say quiets nearby narrators for the set time and the story
   resumes at the same sentence; logout forgets the reader; a missing
   library is reported once.
3. In game (beta, after the books are built): stand near a narrator bot.

## Open Questions

1. One narrator in twenty bots: about ten of beta's two hundred. Right?
