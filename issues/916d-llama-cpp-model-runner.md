# 916d - The Model Runner (llama.cpp, in one of three places)

## Status
- Created: 2026-06-03 (as "Ollama HTTP Client"); redesigned 2026-10-17
  for llama.cpp
- Parent: Issue 916 (mod-soren-chat)
- Phase: 3
- Priority: High
- Depends on: 916c (luasocket, dkjson and the built llama.cpp library
  must be installed)

## Overview

One Lua module, `02-model-runner.lua`, that turns a prompt into text.
Everything that asks a language model anything — the chat layer, the
guidance layer, 917's plain-text commands, 918's mirror companions,
153g's grounding — calls this one module and does not know where the
model actually runs.

The model is run by **llama.cpp**, a C library (`libllama`, with the
`ggml` math library under it) that loads one model file into memory and
produces tokens from it. It replaces Ollama, which was a separate
daemon wrapped around the same kind of engine. llama.cpp is used as a
library, bundled with the project, in one of three places:

| Placement | Where the model's memory lives | Who can use it | How the runner reaches it |
|-----------|-------------------------------|----------------|---------------------------|
| **in-server** | inside the worldserver process, on the server machine's CPU/GPU | every player, any client | direct function calls into `libllama` through LuaJIT's `ffi` |
| **beside** | inside a separate small program on another computer (the LAN mini-PCs, the owner's desktop, or a player's own computer) | every player, any client | HTTP to that program |
| **in-client** | inside the W custom client, on the player's own GPU | only players on the W client | addon messages to and from that player's client |

Single request, no retries, no health tracking here. Spreading requests
across places belongs to the worker pool (916e); noticing a place has
stopped answering belongs to 916f. This sub-issue is only "given a
placement, a prompt and limits, return the text or an error saying why
not."

## Current Behavior

No runner exists in mod-soren-chat. luasocket is installed (via 916c)
but nothing wraps it. Nothing in this project has built llama.cpp yet;
a built copy exists in a sibling project
(`/home/ritz/programming/ai-stuff/neocities-modernization/libs/llama.cpp/`,
`bin/`, `lib/`, `include/`), made by that project's
`scripts/build-deps.sh` (its issue 10-049, which also replaced Ollama
with llama.cpp). That script is the prior art for 916c's build step.

## Intended Behavior

### The one call

```lua
local runner = require("mod-soren-chat.model-runner")

-- Blocks the calling thread until text, an error, or the timeout.
-- Called only from inside an effil worker (916e), never from the
-- worldserver's own thread.
local result, err = runner.generate({
    placement   = "beside",                -- "in-server" | "beside" | "in-client"
    where       = "http://192.168.1.11:10101", -- beside: the program's address
                                           -- in-client: the player's GUID
                                           -- in-server: the worker's context number
    prompt      = "You are a paladin in Stormwind. Say hello.",
    grammar     = nil,                     -- optional GBNF text (see below)
    max_tokens  = 80,
    temperature = 0.7,
    timeout_ms  = 30000,
})
-- result = { text = string, tokens = integer, millis = number }
```

The result table is the same shape from every placement: `text`
(string, the generated words), `tokens` (integer, how many tokens were
produced), `millis` (number, how long producing them took). The caller
never branches on placement.

### Constrained output (grammars)

llama.cpp can restrict which tokens it is allowed to pick at each step
to the ones a grammar permits, written in its GBNF notation (a small
rule language: `root ::= "{" ws "\"bot\"" ...`). With a grammar the
model *cannot* produce text that fails to parse. This replaces Ollama's
`format: "json"`. 916h writes the guidance grammar; 916k's chat replies
need none. All three placements accept the same grammar text.

### Placement 1 — in-server

ALE is built with LuaJIT (`scripts/compile` passes
`-DLUA_VERSION=luajit`), so a Lua state can call C functions in a
shared library directly through `ffi`, with no C++ added to the module.

- On worldserver start, `ffi.load` opens `libllama.so` from the install
  tree, and the model file (a `.gguf` — llama.cpp's single-file format
  holding the weights, the tokenizer and the chat template) is loaded
  **once**. The weights are read-only after loading, so all workers can
  share them.
- Each effil worker creates its **own context** from that model. A
  context is the model's working memory for one conversation: the
  key/value cache, an array the size of `context length × layers ×
  width` that remembers every token already read. Separate contexts mean
  workers never touch each other's memory and need no locks.
- Effil threads cannot pass `ffi` pointers between them. The model's
  address is passed to each worker as a plain number (a 48-bit address
  fits exactly in a Lua double) and cast back to a pointer inside the
  worker. Record this in a comment where it is done: it is the one place
  a raw address crosses a thread.
- A generation is: turn the prompt into tokens, feed them in one batch,
  then repeatedly ask the sampler (temperature, grammar) for the next
  token, feed it back, and stop at an end token or `max_tokens`.
- Trade-off, stated plainly: a crash inside the library is a crash of
  the worldserver. A bad model file, a GPU driver fault, or memory
  exhaustion takes the world down with it. That is the price of no
  network hop.

### Placement 2 — beside (a separate program)

llama.cpp ships `llama-server`, the same library with a small HTTP
front on it. One runs on each machine that lends its processor:

- Started with the model file and a number of **slots** (`-np 3`): the
  slots share one loaded model and split one context between them, so
  three conversations run interleaved on one machine. This replaces
  `OLLAMA_NUM_PARALLEL`.
- Request: `POST /completion` with `prompt`, `n_predict` (the
  `max_tokens`), `temperature`, `grammar` (or `json_schema`, which the
  server turns into a grammar), `cache_prompt: true` (reuse the cached
  start of a repeated system prompt).
- Response: `content` (the text), `tokens_predicted`,
  `timings.predicted_ms`. Those fill the result table.
- `GET /health` answers 200 when the model is loaded and 503 while it is
  still loading. 916f and 916m use it.
- Network direction matters. The worldserver dials the program, so the
  program must be reachable from the server: true for the LAN
  mini-PCs, usually false for a player's computer at home behind a
  router. A player's own computer as a "beside" place needs either the
  program to dial out to the server, or the in-client placement instead.
  Recorded as an open question.

### Placement 3 — in-client

The W custom client links `libllama` itself (that project's issue 907,
`/home/ritz/games/azeroth-core/custom-client/issues/907-the-model-in-the-client.md`).
The server still decides everything; the client only lends its GPU:

- The worker sends the request to that player as addon messages
  (`Player:SendAddonMessage`, a whisper-to-self chat packet carrying a
  prefix and a payload). A 3.3.5a chat packet holds about 250 bytes, so
  a prompt goes in numbered pieces under the prefix `SOREN`, with a
  request number.
- The client generates and answers the same way; the server hears the
  pieces through ALE's addon-message hook (server event 30,
  `ADDON_EVENT_ON_MESSAGE`), joins them by request number, and hands the
  text to the worker as its result.
- The answer is untrusted text from a player's machine. It goes through
  the same checks as any answer (916i's closed list of real strategy
  names, 916l's text filter) and can never do more than a model answer
  from the server could.
- Only a player on the W client can be asked. A player on the stock
  client has no place to run it, so their bots use one of the other two
  placements.

## Implementation Steps

1. Write `lua/02-model-runner.lua` with one function per placement
   behind a dispatch table keyed by the placement name (`in-server`,
   `beside`, `in-client`), and `generate` choosing from it. An unknown
   placement is an error naming the three that exist.
2. `beside`: the HTTP request through luasocket, the JSON through
   dkjson, the luasocket timeout set in seconds (it does not take
   milliseconds). A non-200 status returns the status and the body's
   `error.message`.
3. `in-server`: the `ffi.cdef` of the handful of `llama.h` functions
   used (load model, new context, tokenize, batch decode, sampler chain
   with temperature and grammar, token to text, free), copied from the
   `include/llama.h` of the pinned build so they match exactly.
4. `in-client`: the piece-splitting and joining, keyed by request
   number, with a timeout that reports how many pieces arrived.
5. Each error says which placement, which `where`, and how far the
   request got (sent / first token / partial text), so a reader knows
   where in the pipe it stopped.
6. Smoke test `test-model-runner.lua`, run with `luajit` outside the
   worldserver: one tiny prompt through `in-server` (loading the model
   in the test itself) and one through `beside` against a running
   `llama-server`; both must return the same result-table shape.
   `in-client` is tested from the client's side (its issue 907).
7. Comment at the top of the file: the result table's fields and types,
   and the `llama-server` request and response fields used.

## Files to Create

- `source-beta/modules/mod-soren-chat/lua/02-model-runner.lua`
- the smoke test under `src/lua-vanilla/`

## Open Questions

- **Which placement is the default?** The three LAN mini-PCs make
  "beside" the natural first one, and it keeps a library crash out of
  the worldserver. "in-server" removes the network but puts the model's
  memory and any crash inside the world. Undecided.
- **A player's computer as "beside".** If the program runs on a
  player's home computer, should it dial out to the server (a
  persistent connection the server answers on) rather than wait to be
  dialed? Or is a player's computer always "in-client" instead?
- **in-server binding: `ffi` or the C++ shim?** `ffi` needs no C++ and
  hot-reloads with ALE; the 916a/916b shim could own the model instead
  and expose one Lua function, which keeps raw addresses out of Lua.
  Leaning `ffi`.
- **Model file.** Ollama tags (`llama3.2:1b`, `qwen2.5:1.5b`) become
  GGUF files (for example a 1B instruct model at `Q4_K_M`, four-bit
  weights, roughly 0.8 GB). Which one is still the benchmark's job
  (916, Open Questions).
- **Streaming.** `llama-server` can stream tokens and the in-server loop
  produces them one at a time anyway. Chat could start speaking before
  the reply ends. Not in v0.

## Related

- Parent: [916 - mod-soren-chat](916-mod-soren-chat.md)
- [916c - Vendored libs](916c-vendored-lua-libraries.md) — installs
  luasocket, dkjson and the built llama.cpp
- [916e - Effil worker pool](916e-effil-worker-pool.md) — calls this
  module from inside worker threads, one context or one slot per worker
- [916f - Health rotation](916f-cluster-health-rotation.md) — `/health`
  for "beside", context failures for "in-server", silence for "in-client"
- W client issue 907 (the model in the client) — the client half of
  placement 3
- llama.cpp: <https://github.com/ggml-org/llama.cpp> — `include/llama.h`
  (the library), `tools/server/README.md` (the `llama-server` fields),
  `grammars/README.md` (GBNF)
