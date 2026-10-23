# 910a - Narrators Read Aloud

## Status
- State: completed 2026-10-23: built; its in-game check taken as done (the owner, 2026-10-23: "let's mark all the issues that are just waiting on a visual check as complete")
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
  20 seconds. Each narrator's book and how many sentences in are saved in
  the characters database after every new sentence (table
  `beta_910a_narrator_reading`, made by install step E061 from
  `sql/beta/db_characters.src/02-narrator-reading.apply.sql`); logout lets
  the reader go from memory, and the next time it is heard it goes on
  from the saved sentence. A saved book no longer built, or a place past
  its end, starts over. No books (E059) or no table (E061) is said once in
  the server log, naming the install step, and the narrators stop.
- `scripts/test-narrators` (stand-ins for the engine, a pretend database
  and a test shelf) checks all of the above. Its first run found the base
  pause too short (at 1.5 seconds a short line came every tick); it is 3.
- `scripts/test-beta-lua-load` loads it as the engine does, without errors.

Not yet: E061 run on beta's database, and tried in game (step 3).

Question 1 answered (the owner, 2026-10-18: "sure okay"): one in twenty.

Before this, beta's random playerbots wandered and fought; none read aloud.

## Intended Behavior

- **Who narrates.** A fixed share of beta's random playerbots are
  narrators: those whose character number is a multiple of
  `NARRATOR_EVERY` (a number in the script; one in twenty to start). The
  rule needs no database and picks the same bots after every restart.
- **What they read.** Each narrator is its own reader in the library (909):
  started when it is first heard, with a random book from its first
  sentence. Its place (the book and how many sentences in, one integer)
  is kept in the characters database, so a logout or a restart does not
  send it back to the beginning. The owner, 2026-10-18: "if we forget our
  place, then we won't ever complete a book, and instead just repeat the
  beginnings. I think we should continue from where we were - it's just an
  integer in the database, "how many sentences in"". A sentence too long
  for one chat line is said in parts, one after another.
- **Ageing.** Beta's random bots are re-randomized now and then by the bot
  module (gear, talents, place); they keep their character and its number,
  so a narrator stays a narrator and keeps its place.
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
  E059 not run) or the table for saved places is missing (E061 not run),
  the script says so once in the server log, naming the install step, and
  stops trying, rather than failing every tick or reading without saving.

## Suggested Implementation Steps

1. `src/lua-beta/narrators.lua`: the narrator rule, a timer every couple of
   seconds over the online narrators, the reading with its pauses, the
   /say listening, logout clearing the reader; tuning numbers at the top.
   The saved place: install step E061 in `patches/E-patches.sh` (listed
   for beta in `patches/patches.sh`) registers
   `sql/beta/db_characters.src/` with the database updater, whose apply
   file makes the table (narrator's character number, book number,
   sentences said); the script checks the table at the first start,
   restores the place after starting the reader, and saves after each new
   sentence.
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
   **Answered** 2026-10-18: "sure okay."
