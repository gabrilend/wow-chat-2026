# 916 - mod-soren-chat: LLM-Driven Bot Guidance and Conversation

## Status
- Created: 2026-06-03
- Phase: 3 (Social Systems) — also touches Phase 9 (Storytelling) for the chat layer
- Priority: Medium (target: vanilla profile)
- Supersedes: Issue 914 (Custom Chat Data Sources) and Issue 915 (Ollama Conversation Flow). Those tickets designed a JSON-with-Ollama-overlay approach; mod-soren-chat replaces that with a unified LLM-native module covering both chat and gameplay-policy guidance.

## Overview

A single AzerothCore module that gives playerbots LLM-driven behavior in two
dimensions:

- **Chat layer (social).** Bots speak in a way shaped by their race, class, and
  spec — replies to nearby players, ambient lines about their surroundings,
  reactions to in-game events. Always present, intentionally not the focus
  of in-house design work; structurally ports the prompt-design ideas from
  Hokken's mod-llm-chatter into our own Lua implementation.

- **Guidance layer (gameplay).** When any party member is within 100 yards
  of a real player, an LLM consultation sets behavioral policies for every
  bot in that party — which strategies to activate, which trigger→action
  weights to bump, target prioritization. The LLM doesn't pick individual
  actions; it edits mod-playerbots' strategy/multiplier state, and
  mod-playerbots' existing C++ engine executes from there. Tactical
  decisions stay where they're fast; strategic decisions get smart.

Both layers run on the same model runner (916d): **llama.cpp**, a C library
bundled with the project, running in one of three places — inside the
worldserver itself ("in-server"), in a separate small program on another
computer such as the three LAN mini-PCs ("beside"), or inside the W custom
client on the player's own GPU ("in-client"). Requests go through the same
in-process Lua bridge inside the worldserver whichever place answers them.
Waiting on the model is done in effil-jit worker threads so the worldserver
tick never blocks on network or model inference.

llama.cpp replaced Ollama on 2026-10-17 (owner: "replace it with llama.cpp.
It should be bundled using a library running either on the server, on a
separate program running on the user's computer, or in the custom-client").
Ollama was a daemon wrapped around the same kind of engine; using the library
directly removes that daemon and lets the model live where it is most useful.

This is on the vanilla profile. Per the vanilla design philosophy in issue
148, the goal is "default WotLK + playerbots, no wow-chat design layer" —
mod-soren-chat fits that envelope because it doesn't add content (no
ambush spawns, no custom classes, no custom Lua corpus), it just makes the
companion AI smarter. The companions are already vanilla's defining
feature; this makes them more interesting without adding any wow-chat
content.

## Why a Single Module

Earlier drafts considered splitting chat and guidance into separate
services (one being mod-llm-chatter, the other a custom guidance bridge).
The split was abandoned because:

- Both layers share the same model runner and its places
- Both layers share the same routing logic across those places
- Both layers share the same JSON parsing, retry, and timeout machinery
- Both layers share the same effil-jit worker pool
- Operational surface (one service start, one log, one config) is half
- The split was a vestige of mod-llm-chatter being a separate package; once
  we're writing everything in our own Lua anyway, the split has no value

The internal split between chat and guidance lives inside the module as
two prompt-builder modules + two response-parser modules sharing
infrastructure. If guidance traffic ever starves chat in practice,
splitting then is mechanical.

## Architecture

### High-Level Flow

```
Worldserver main thread (ALE Lua hooks):
  proximity hook fires per tick (cheap)
    → if party within 100yd of player and policy stale:
         push guidance request into effil channel
    → if bot has chat trigger condition met (player spoke, entered subzone, etc.):
         push chat request into effil channel
    → drain response channel:
         apply guidance directives via playerbots ChangeStrategy
         emit chat lines via bot->Say()

Effil-jit worker threads (one per place-and-slot):
  loop forever:
    pop request from channel (blocking)
    model runner (916d), synchronous, in worker thread:
      in-server → llama.cpp calls through ffi on this worker's own context
      beside    → HTTP POST /completion to that machine's llama-server
      in-client → addon messages to that player's W client, wait for reply
    validate against expected schema
    push validated result onto response channel

The places (any mix, set in 01-config.lua):
  in-server: libllama loaded once in the worldserver; one context per worker
  beside:    llama-server on each LAN mini-PC (192.168.1.11-13), -np 3 slots
  in-client: W clients that have offered their GPU (custom-client issue 907)
  model: one GGUF file per place (TBD via benchmark)
  Independent of each other; module round-robins requests
```

### Why Effil-Jit Workers vs. Separate Process

We considered a standalone Lua service communicating with the worldserver
via a database queue table. Effil-jit lets us collapse that to in-process
worker threads:

- No IPC, no queue table, no schema migration
- effil channels are thread-safe queues with the same shape as a DB queue
- Worker thread crash is recoverable (effil supports restart)
- Operational surface is just the worldserver process
- Lua scripts hot-reload via ALE the same as everything else

### Why C++ Shim + ALE Lua, Not Pure C++ Module

The decision boundary is set by what API surface is needed:

- Calling `botAI->ChangeStrategy(...)` requires C++ access to the playerbots
  internal API; can't be done from pure Lua without bindings.
- Querying bot/player proximity requires C++ map iteration; same constraint.
- Everything else (HTTP, JSON, prompt building, queue management, retry
  policy, host routing, configuration) is naturally Lua and benefits from
  hot-reload.

So the C++ side is a thin binding layer (~200 lines) exposing the two
playerbots-internal operations to ALE. All the actual logic — prompt
templates, response validation, host routing, scheduling — lives in Lua
files loaded by ALE on worldserver start.

## Module Structure

```
modules/mod-soren-chat/
├── CMakeLists.txt              ← standard AzerothCore module CMake
├── conf/
│   └── mod_soren_chat.conf     ← runtime config: feature flags, model choice
├── src/                        ← C++ shim
│   ├── SorenChatLoader.cpp     ← AddSC_* registration
│   ├── SorenALEBindings.cpp    ← exposes playerbots API to ALE callers
│   ├── SorenALEBindings.h
│   └── (small, ~200 lines total)
└── lua/                        ← ALE-loaded scripts (numbered for read order)
    ├── 01-config.lua           ← hosts, models, thresholds, cadences
    ├── 02-model-runner.lua     ← llama.cpp in one of three places (916d)
    ├── 03-effil-workers.lua    ← spin up worker pool on startup
    ├── 04-prompt-chat.lua      ← chat prompt builder (port mod-llm-chatter)
    ├── 05-prompt-guidance.lua  ← guidance prompt builder (our design)
    ├── 06-response-parse.lua   ← JSON validation + schema enforcement
    ├── 07-proximity-hook.lua   ← detect party-near-player condition
    ├── 08-directive-apply.lua  ← call ChangeStrategy with LLM directives
    ├── 09-chat-emit.lua        ← bot says generated text via Player:Say
    └── 99-debug.lua            ← .soren commands for operators
```

The numbered prefix is the file-index-counter pattern from CLAUDE.md.
Files read in order tell the story: config, then plumbing, then the two
prompt domains, then parsing/validation, then the in-game hooks.

## Lua Library Dependencies

All from `/home/ritz/programming/ai-stuff/libs/lua/`:

- **luasocket** — TCP + HTTP. `socket.http.request` is enough for
  `llama-server`.
- **dkjson** — pure-Lua JSON parser. Slower than lua-cjson but no C deps,
  always works with LuaJIT.
- **effil-jit** — OS thread library with shared channels. Critical for
  off-main-thread inference work.

CMakeLists copies these into the runtime location during install. No
package manager involvement.

And one C library, not from that directory:

- **llama.cpp** — `libllama.so` (the model engine) and `llama-server`
  (the same engine with an HTTP front). Cloned at a pinned tag and built
  by a bash script into the install tree (916c), the way the sibling
  project neocities-modernization already does it (its
  `scripts/build-deps.sh`). The owner runs that build.

## Where the Model Runs

Three places, any mix of them at once (916d has the detail):

- **in-server.** The worldserver loads `libllama.so` through LuaJIT's
  `ffi` and the model file once; each effil worker owns its own context
  (its own key/value cache). No network. A library crash is a
  worldserver crash.
- **beside.** `llama-server` on another computer. Today that is the
  three LAN mini-PCs:
  - **box1**: 192.168.1.11:10101
  - **box2**: 192.168.1.12:20202
  - **box3**: 192.168.1.13:30303

  Each starts `llama-server` with its model file and `-np 3` slots (one
  model in memory, three conversations interleaved; subject to benchmark
  tuning per the ratchet table in 148-adjacent notes). It could equally
  be the owner's desktop. A player's own computer joins as 916o's
  companion program instead, which dials out to a job broker because the
  server cannot dial through a home router.
- **in-client.** A player on the W custom client lends their GPU: the
  server sends the prompt to their client as addon messages and gets the
  text back the same way (custom-client issue 907). The answer is
  checked like any other; the client never decides anything.

Fixed places (in-server, the LAN boxes) are trusted and take any request.
Places on players' machines (916o's companion program, in-client) are
contributed and untrusted: **chat requests only**, never guidance, with
every prompt scrubbed of names, account data and whisper text first
(916o).

The Lua bridge keeps one effil worker per place-and-slot; workers take
requests round-robin. Health is tracked per worker; a place that stops
answering is removed from rotation until it recovers. Losing one of three
places drops to 2/3 throughput, not 0.

## Connection to mod-playerbots Strategy System

mod-playerbots already exposes the lever we want via the `.playerbot
strategy +/-` command, which calls `botAI->ChangeStrategy("+name,-name",
BotState)` internally. The LLM output (after validation) gets translated
into a sequence of strategy edits per bot, applied by the C++ shim.

For policies that go beyond what existing strategies express (e.g., "heal
focus on Tankzilla specifically" rather than "heal whoever's lowest"),
mod-soren-chat ships its own `SorenDirected` strategy class that reads
per-bot policy state (set by the LLM) and produces matching action
multipliers. This is the only new strategy class needed; everything else
re-uses what mod-playerbots already has.

## Sub-Issues

Twelve sub-issues, organized in implementation order. Each is small enough
to land in one or two sessions.

### Foundation (no LLM yet)

- **916a — C++ shim skeleton.** CMakeLists, module registration, empty
  binding layer. Compiles and loads but does nothing. Verifies the build
  pipeline works for a new module on the vanilla profile.

- **916b — ALE bindings for playerbots.** Expose
  `botAI->ChangeStrategy(string, BotState)` and a proximity query
  (`is_bot_within_yards_of_player(bot, yards)`) as Lua-callable functions
  via ALE. Smoke test: write a one-line Lua script that toggles a bot's
  strategy from the console.

- **916c — Library vendoring.** CMakeLists.txt rule that copies
  luasocket, dkjson, and effil-jit from `/home/ritz/programming/ai-stuff/
  libs/lua/` into the install location, and the bash build of llama.cpp
  at a pinned tag into the install tree. No LuaRocks.

### Plumbing (no game integration yet)

- **916d — The model runner.** `02-model-runner.lua`: one synchronous
  call, prompt in, text out, with llama.cpp in one of three places
  (in-server through `ffi`, beside through `llama-server`'s HTTP,
  in-client through addon messages). Tested standalone with `luajit`
  against in-server and beside.

- **916e — effil worker pool.** `03-effil-workers.lua`: spin up one
  worker per place-and-slot on startup. Channel-based dispatch. Workers
  handle their own retries. Smoke test: queue 10 requests, verify all
  complete and balance across workers.

- **916f — Health tracking and rotation.** Extend the worker pool with
  per-place health state. Failed calls increment a counter; over
  threshold the place drops out of rotation, with periodic re-check.
  Smoke test: stop `llama-server` on box2, verify requests route around
  it; restart it, verify it rejoins.

### Guidance layer (the gameplay-relevant half)

- **916g — Proximity detection hook.** `07-proximity-hook.lua`: ALE
  hook fires per worldserver tick (throttled — every 500ms not every
  100ms), iterates bots-in-parties, checks if any party member is within
  100yd of a player. Uses hysteresis (enter at 100yd, exit at 130yd).
  Emits "guidance needed for party X" event.

- **916h — Guidance prompt builder.** `05-prompt-guidance.lua`: takes
  a party-state struct (members' classes, levels, HP/mana%, current
  target, zone, recent damage taken, party-leader's heading), produces
  a prompt that asks the LLM for per-bot policy flags. System prompt
  defines the directive vocabulary. Output schema: strict JSON with
  list of {bot_name, strategies_add, strategies_remove,
  multiplier_overrides}.

- **916i — Response validator and directive application.**
  `06-response-parse.lua` enforces schema (strategy names must exist in
  mod-playerbots' registry, multiplier values in [0.0, 2.0]). Invalid
  responses retry once with a "your output was malformed" follow-up,
  then fall back silently. `08-directive-apply.lua` applies validated
  directives via the C++ shim. Bots without LLM coverage keep default
  playerbots behavior.

- **916j — SorenDirected strategy class.** Add a new strategy to
  mod-playerbots (via B-patch so it survives upstream pulls) that reads
  per-bot policy state (set by 916i) and exposes Multipliers wired to
  it. This is the LLM's leverage point for policies that don't fit the
  existing strategy palette.

### Chat layer (the social half)

- **916k — Chat prompt builder + persona persistence.**
  `04-prompt-chat.lua`: ports the structural design of mod-llm-chatter's
  prompt system (race/class/spec → personality archetype, environmental
  awareness, response triggers). Each bot gets a permanent persona seed
  stored in a new `soren_chat_persona` table (acore_characters_vanilla).
  Triggers: nearby player chat, level-up, zone-entry, periodic ambient.
  Output: one sentence of plain text, shaped by 916l's chat grammar
  (was `{text: string}` before llama.cpp grammars).

- **916l — Chat emission and rate limiting.** `09-chat-emit.lua`: bot
  speaks via the appropriate channel (`/say` for nearby, `/whisper` for
  direct response). Per-bot cooldown (45s default) prevents spam. Output
  text gets light filtering (strip "As a [class], I..." patterns small
  models love).

### Operations

- **916m — Bash health check in scripts/worldserver.** Pre-flight check
  in the existing worldserver startup script that curls each "beside"
  place's `llama-server` `/health` endpoint and checks the in-server
  model file and library exist. Warns (doesn't block) on failures.
  Config sourced from the same env or file the Lua side reads.

- **916n — Debug commands and observability.** `99-debug.lua`: adds
  `.soren status`, `.soren queue`, `.soren reload`, `.soren benchmark`
  console commands for the GM operator. Periodic stats logged
  (requests/sec per host, p50/p99 latency, error rate, current queue
  depth). Operator can see at a glance if the cluster is healthy.

That's fourteen sub-issues total. The first six (916a-f) are foundation
work that produces nothing user-visible. The middle four (916g-j) are
the guidance layer — first user-visible value, bots adapt their
strategies to situations. The next two (916k-l) are the social layer.
The last two (916m-n) are operations.

## Implementation Order

The dependency graph allows substantial parallelism but a recommended
sequence is:

1. 916a (skeleton) — must come first
2. 916b, 916c, 916d in parallel — independent plumbing
3. 916e (workers) — depends on 916d
4. 916f (health) — depends on 916e
5. 916g (proximity) — depends on 916b
6. 916h (guidance prompt) + 916i (response/apply) — together; depends on 916b, 916e, 916g
7. 916j (SorenDirected strategy) — depends on a working mod-playerbots build with the B-patch system; can land any time after 916a
8. 916k + 916l (chat layer) — depends on 916e; lower priority than guidance
9. 916m (bash health check) — depends on cluster being real; can land any time
10. 916n (debug commands) — depends on most of the rest existing to be debuggable

Realistic ordering for a single-developer session timeline: aim to land
916a-f in one sprint (foundation week), then 916g-i + 916j in a second
sprint (guidance MVP), then 916k-l as a follow-up (chat polish), with
916m and 916n landing whenever they're convenient.

## Configuration Schema

`conf/mod_soren_chat.conf` (loaded by C++ shim) — minimal, mostly
feature flags. Most behavior tuning lives in `lua/01-config.lua` where
it's hot-reloadable.

```ini
SorenChat.Enable = 1
SorenChat.GuidanceEnabled = 1
SorenChat.ChatEnabled = 1
SorenChat.LuaConfigPath = "lua_scripts/custom/01-config.lua"
SorenChat.ModelHealthCheckOnStart = 1
```

`lua/01-config.lua`:

```lua
-- each place: placement (string: "in-server" | "beside" | "in-client"),
-- name (string), where (string: URL, or the model file for in-server),
-- slots (integer: workers this place gets)
M.model_places = {
    { placement = "beside",    name = "box1", where = "http://192.168.1.11:10101", slots = 3 },
    { placement = "beside",    name = "box2", where = "http://192.168.1.12:20202", slots = 3 },
    { placement = "beside",    name = "box3", where = "http://192.168.1.13:30303", slots = 3 },
    -- { placement = "in-server", name = "local", where = "models/<file>.gguf", slots = 2 },
}
M.in_client_enabled         = false   -- ask W clients that offered their GPU (custom-client 907)
M.request_timeout_ms        = 30000
M.proximity_yards           = 100
M.proximity_hysteresis      = 30
M.chat_cooldown_seconds     = 45
M.guidance_cadence_combat   = 5
M.guidance_cadence_noncombat = 20
M.host_failure_threshold    = 3
M.host_reprobe_seconds      = 60
```

## Database Schema

One new table for chat persona persistence:

```sql
-- acore_characters_vanilla.soren_chat_persona
CREATE TABLE soren_chat_persona (
    guid INT UNSIGNED NOT NULL,
    persona_seed VARCHAR(64) NOT NULL,
    origin_story TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (guid)
) DEFAULT CHARACTER SET UTF8MB4 COLLATE utf8mb4_unicode_ci;
```

Created in 916k. Populated lazily on first chat opportunity for each bot.
The persona_seed is short (an archetype name like "skeptical_warrior")
and the origin_story is a short LLM-generated paragraph used as system
prompt context. Both persist so the same bot sounds like the same bot
across sessions.

No guidance state in the database. Per-bot policy lives in memory
(populated by LLM responses, applied via ChangeStrategy, lost on bot
despawn — which is fine, the next planning cycle re-populates it).

## Open Questions

- **Model choice.** Llama 3.2 1B vs Qwen 2.5 1.5B vs Gemma 2 2B, as GGUF
  files at four-bit (`Q4_K_M`) — pick after cluster benchmark.
  Constraints: must fit in 8GB with OS + `llama-server` + N slots, and
  in the worldserver's memory for in-server, and in a player's GPU for
  in-client. Valid JSON is guaranteed by the grammar now (916h), so the
  measure becomes "names real strategies >95% of the time."

- **Which placement first, and is there a default?** beside (the LAN
  mini-PCs, the existing hardware), in-server (no network, but the
  model and any crash live inside the world), or in-client (the
  player's GPU, W client only). See 916d.

- **Guidance cadence in combat.** 5 seconds is a starting point. May be
  too aggressive for what's actually a strategic decision. Could go to
  10-15s in combat without obvious loss of responsiveness, because the
  LLM is setting policy not actions.

- **Chat persona generation.** When a bot first chats, do we generate
  its persona on-demand (slow first chat) or pre-generate all personas
  at server startup (slow startup)? Lean toward on-demand with a
  placeholder persona used until the LLM call returns.

- **What happens at server reload.** ALE supports hot-reloading Lua, but
  effil workers are real OS threads. Reloading the Lua scripts that
  defined the workers needs to either kill+restart workers or work with
  generation tracking. Solve in 916e.

## Related

- **148 — Vanilla profile design.** mod-soren-chat is being added to
  vanilla. Update vanilla's module list when 916a lands.
- **617e — Buddy area adventuring (basic profile).** Buddies waiting
  outside their owner's dungeon talk to passers-by at their campfire and
  say in-character lines (Ritz, 2026-09-25); that waits on this module's
  chat layer, and on this module being added to basic as well as vanilla.
- **148k — ALE auto-equip starter kit.** Established the pattern of
  small ALE Lua scripts hooking into events. mod-soren-chat is the
  bigger sibling.
- **914 — Custom Chat Data Sources** and **915 — Ollama Conversation
  Flow.** Superseded by 916. Both designed a JSON-with-Ollama-overlay
  approach to chat; 916 replaces that with LLM-native chat that
  shares infrastructure with the guidance layer. Both tickets should
  be marked superseded (not deleted) with a pointer to 916. (Their
  Ollama is replaced here by llama.cpp; their bodies keep the word as
  history.)
- **913 — Clustered Worldserver.** Spiritual sibling — both are
  cross-machine infrastructure. 913 is about scaling the worldserver;
  916 is about offloading LLM work.
- **917 — Ask the Bots in Plain Text.** Sibling. Rides this module's
  model runner, worker pool, and ALE bindings to turn plain-language
  player requests into playerbot commands.
- **918 — fg-sora-cluster.** Sibling, and the one that conflicts.
  918 wants three bots that generate thoughts *continuously*, one
  pinned per box, sharing a single persona — the player's. This
  module's model is the opposite on all three counts: event-driven
  bursts, round-robin routing, one distinct persona per bot in
  `soren_chat_persona`. Both cannot own three boxes at once. Whichever
  is built second inherits the resource decision.
- **mod-playerbots strategy/trigger/action architecture.** The lever
  916 pushes on. See playerbots docs at docs/playerbots/.

## Notes

The name "soren" is intentionally not descriptive. It's a name, not a
description, so the module can grow without the name fighting it.
mod-soren-chat could evolve into mod-soren if guidance becomes the
larger half, or if we add a third dimension (combat coordination
voice lines, dungeon-specific tactical commentary, narration of
ambush spawns). The name is a handle, not a contract.

## Shared Build Pass (neuron)

neuron's `docs/shared-with-wow-chat-2026.md`, pass 4. neuron already calls a
model — from **outside** the server (`src/050-api.lua`, `src/051-loop.lua`), for
changes a person agrees to. This module calls one from **inside** (916d, 916e),
for bot chatter that must not wait on anything outside. Not one piece of code;
what is shared is the formats:

- a voice or persona is one file shape (916k here, neuron 1001, and 918);
- checking a reply against a closed list of real names is one idea (916i
  against strategy names; neuron's registry against its words).

And 916b's bindings are shared outright — see its own section.

**Open question, the owner's:** which side owns which model calls? Perhaps
neuron for anything that changes the world with agreement and this module for
bots' own chatter — or one of them for both.
