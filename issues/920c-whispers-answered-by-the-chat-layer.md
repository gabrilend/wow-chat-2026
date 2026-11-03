# 920c - Whispers Answered by the Chat Layer

## Status
- Created: 2026-10-20
- Phase: 9
- Parent: 920 (legendary friends in every friends list)
- Blocked by: 920a (persona sheets), 920b (the legends online), 916 (the
  chat layer: 916d model runner, 916e worker pool, 916h prompt builder,
  916i response validator, 916l emission and rate limit)
- Priority: Parked (with its parent, 920: the legends are Blizzard's characters; see 920's "Parked")

## Current Behavior

A whisper to a playerbot goes to the playerbot's own command handling
(whispers are how a player gives bots orders). Nothing turns a whisper into
a conversation.

## Intended Behavior

1. A player whispers a legend. ALE's whisper hook (`PLAYER_EVENT_ON_WHISPER`,
   event 19) sees that the receiver is a legend, keeps the message from the
   playerbot command handling, and hands it to the chat layer's worker pool
   (916e), so the world's tick never waits on the model.
2. The prompt (916h) is built from the legend's sheet (920a), that player's
   conversation so far with that legend, and what the player can be told
   about themselves (where they are, their level), within the sheet's rules
   on what the legend knows.
3. The answer is checked (916i: length, nothing the legend could not say)
   and whispered back from the legend to the player, split into several
   whispers when long, at a pace a person types (916l).
4. **Memory per player.** Each (player character, legend) pair keeps its
   own conversation: the last messages whole and a running summary of
   older ones, in a table of its own in the characters database. The same
   store is what 920d's window and 920e's phone read and write.
5. **Command words** (Terokk's, from his sheet's table, a dispatch of word
   → behaviour, no chain of conditions): a whisper that is one of them, such
   as "help", is not sent to the model; it runs that behaviour at once and
   Terokk answers in his own words. What each word does is for the owner to
   choose (open question 1).
6. **Temperate psychics** (Terokk, and any later legend whose sheet says
   so). The owner, 2026-10-20, verbatim:

   > with the temperate psychics, it should always and ever be one message
   > sent from the non-psychic, one response from the psychic. And it
   > should at all times be interpreted first, and ignored if it's
   > malicious. Only writing english words, and auto-generating a voice
   > that is unique to that sender. It should work like an HTTP server,
   > where you can only request or send data to certain endpoints. Or a
   > bytecode interpreter, which only has certain instructions that it can
   > use to operate. Also, the other end needs to know everything
   > presented by the user - who they are and what their mind is like, and
   > they get to forge their own opinion of their respect. Then, someday,
   > we can give them armies.

   What that makes, rule by rule:
   - **One in, one out.** A psychic never speaks first and never sends two
     replies to one message. A second message before the reply is held,
     not answered twice.
   - **Read before answered.** Each incoming message is first judged by a
     separate check (the validator's kind of pass, run on the input, 916i):
     a message judged malicious is dropped, unanswered, and logged with its
     reason.
   - **A closed instruction set.** What a psychic's reply may *do* is a
     short fixed list, like a server's endpoints or an interpreter's
     opcodes: `say` (English text to the sender), the sheet's command words
     (each a fixed behaviour), and nothing else. A reply is parsed into
     these instructions; anything else in it is discarded and counted. Only
     English words leave: a reply with other symbols or sounds (cawing) is
     refused by the validator.
   - **A voice per sender.** The psychic's way of speaking is generated
     afresh for each sender and kept with that pair's conversation (920c's
     store), so each player hears their own Terokk (open question 3).
   - **Knowing the sender.** The psychic is given everything the player
     has shown of themselves: their character, their conversation history
     with every legend, how they play. From it the psychic keeps its own
     **regard** for that sender (a number from 0 to 100 with a few words
     of why, stored per pair, changed only by the psychic itself after each
     exchange), which shapes how it answers.
   - **Someday, armies** (not built): a psychic's regard could one day let
     it act for a player in the world. Recorded, not designed.
7. **When the model is unreachable**, the legend does not answer from a
   canned list: the player gets a whisper saying the legend cannot be
   reached, and the server log says why. (A canned reply would be a
   fallback that hides the fault.)

## Suggested Implementation Steps

1. The whisper hook and its legend check, with a test that a whisper to a
   legend never reaches playerbot commands and a whisper to an ordinary bot
   still does.
2. The conversation store (a new characters-database table by an install
   step; one row per message: character id, legend id, time, who spoke,
   text) and the summary written every so many messages.
3. The prompt from the sheet and store; the reply path through 916i and
   916l.
4. Terokk's command table.
5. A test with the model runner faked by a fixed responder: whisper, see
   the reply arrive, check the store.

## Open Questions

1. **Terokk's command words.** The owner: "sometimes they listen to command
   words like "help" and "crooked crime" or whatever." What should "help"
   do (warn of the nearest ambush, point the way to a spirit healer)? Which
   other words, and what does each do?
2. Should a legend who is *not* a psychic ever whisper first (when the
   player has been silent for a day, or is about to die)? A psychic never
   does.
3. **"Auto-generating a voice that is unique to that sender"**: a way of
   writing (word choice, rhythm) made for each sender, or a spoken voice
   (generated speech audio, for the addon or the phone)?
