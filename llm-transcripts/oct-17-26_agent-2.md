# Conversation Summary: 1ca38611-9673-4322-8dc2-8d10922c6746

Generated on: 2026-10-17 15:17:58
Models: claude-opus-5-5

--------------------------------------------------------------------------------

### User Request 1

Hi, can you work on updating the docs and issue files that reference Ollama and
replace it with llama.cpp? It should be bundled using a library running either
on the server, on a separate program running on the user's computer, or in the
custom-client, which is located at /home/ritz/games/azeroth-core/custom-client/
- can you update the same types of files, there?

--------------------------------------------------------------------------------

### Assistant Response 1

> Found ~25 Ollama-referencing issue files in wow-chat-2026 and none in the
> custom client; reading the client's docs now to see where a llama.cpp
> placement fits.

> Rewrote the model-runner sub-issue (renamed to 916d-llama-cpp-model-runner);
> now updating the parent mod-soren-chat issue.

> Parent issue and library-vendoring issue done; now the worker pool, health,
> and startup-check sub-issues.

> Parent and plumbing sub-issues done; now the sibling issues (917, 918, 153
> family, 148, 912, progress files).

> Updating the 153g grounding issue, where llama.cpp as a library actually
> removes a listed obstacle (per-token control).

> Progress files and siblings updated; finishing the phase-9 note, the
> lore-generation issue (912), and the stale link in the declined 1101g.

> Server side done. Now the custom client: reading one of its recent issues for
> format.

> Client docs site rebuilt. Final sweep for leftover Ollama mentions:

I've updated the planning files in both projects: every issue that described
Ollama now describes llama.cpp, which can run in any of the three places you
named. These are design documents only, because no code in either project used
Ollama. Nothing is committed yet.

**The design.** llama.cpp is a C library that loads one model file (a `.gguf`,
which holds the weights, the tokenizer and the prompt template) and produces
text one token at a time. The bots' chat module sends every model request
through one call, and that call doesn't care which place answers:

- **On the server:** the game server loads the library directly. Its Lua engine
  is already built with LuaJIT, which can call C functions without any new C++.
  The model is loaded once, and each worker thread gets its own working memory:
  a cache of every token that conversation has read so far. Requests skip the
  network, but a crash inside the library takes the whole game server down with
  it.
- **A separate program:** llama.cpp's own small HTTP server runs on another
  computer, such as the three LAN mini-PCs. Each one splits its single loaded
  model into 3 parallel conversation slots, which is what Ollama's parallel
  setting used to do. The server polls its `/health` page, which answers 200
  when the model is loaded and 503 while it is still loading.
- **In the custom client:** the server sends a prompt to the player's client as
  addon messages (hidden chat packets). The client generates the reply on the
  player's GPU and sends it back the same way. The server then checks the reply
  the way it checks its own model's replies, so the client never decides
  anything.

One concrete gain: llama.cpp can be given a grammar that only lets the model
write output matching the guidance format exactly. Ollama's JSON option only
promised "some JSON". It also makes 153g's word-by-word image idea easier, since
the library hands over one token at a time.

**In wow-chat-2026:** the model-client sub-issue is renamed
`916d-llama-cpp-model-runner.md` and rewritten, and I fixed every link to its
old name. I also rewrote the parent chat-module issue, the library-install issue
(now a pinned llama.cpp build, copied from the way your neocities-modernization
project already builds it), and the worker-pool, health-check, startup-check and
prompt-builder issues. 148, 153, 153e, 153g, 610, 912, 917, 917c, 918 and the
phase files got wording updates.

Some Ollama mentions are deliberately kept:
- your verbatim quote in 918;
- the old titles of 914 and 915, which were superseded, so I only added a note
  to 915;
- the copied playerbots wiki page, which names someone else's module
  (mod-ollama-chat);
- your `notes/` files;
- the old `output/html-export/` pages, which I didn't regenerate.

**In custom-client:** nothing mentioned Ollama, so I added things instead:
- **New issue `907-the-model-in-the-client.md`:** the client's side of the third
  option, including how replies are generated one token per turn so drawing
  never waits.
- **Docs:** a library row in 002, a planned "thinking" row in the threads table
  in 001, and links in 009 and the phase-9 progress file. I rebuilt its HTML
  docs site.

That repo already had a lot of uncommitted work from another session, including
009, so I haven't committed there.

These questions are written into the issues and are still open, so the work
isn't finished until we go through them. The first two matter most:

1. **Which of the three should be built first, and is one of them the default?**
   Using the mini-PCs fits the hardware you already have and keeps a library
   crash out of the game server.
2. **The client rule says "No C++".** The client's own code stays C, but linking
   llama.cpp pulls a C++ library and its runtime into the program. Does the rule
   allow that?
3. **What does "the user's computer" mean for the separate program?** If it's a
   player's computer at home, the server probably can't connect to it through
   their router. So either the program connects out to the server, or that
   player uses the in-client option instead. Which did you mean?

--------------------------------------------------------------------------------

