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

Both layers run on the same Ollama cluster (three mini-computers on the LAN)
through the same in-process Lua bridge inside the worldserver. Inference is
done in effil-jit worker threads so the worldserver tick never blocks on
network or model inference.

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

- Both layers share the same Ollama cluster
- Both layers share the same network routing logic across three hosts
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

Effil-jit worker threads (3 workers, one per Ollama box):
  loop forever:
    pop request from channel (blocking)
    socket.http POST to assigned Ollama box (synchronous, in worker thread)
    dkjson parse response
    validate against expected schema
    push validated result onto response channel

Three Ollama boxes on LAN (192.168.1.11-13):
  Ollama daemon with OLLAMA_NUM_PARALLEL=3
  llama3.2:1b or qwen2.5:1.5b loaded (model TBD via benchmark)
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
    ├── 02-ollama-client.lua    ← luasocket HTTP wrapper + dkjson parse
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

- **luasocket** — TCP + HTTP. `socket.http.request` is enough for Ollama.
- **dkjson** — pure-Lua JSON parser. Slower than lua-cjson but no C deps,
  always works with LuaJIT.
- **effil-jit** — OS thread library with shared channels. Critical for
  off-main-thread inference work.

CMakeLists copies these into the runtime location during install. No
package manager involvement.

## Three-Box Cluster Configuration

Per design discussion, three mini-PCs running Ollama on:

- **box1**: 192.168.1.11:10101
- **box2**: 192.168.1.12:20202
- **box3**: 192.168.1.13:30303

Each runs Ollama with `OLLAMA_NUM_PARALLEL=3` (subject to benchmark
tuning per the ratchet table in 148-adjacent notes). The Lua bridge
maintains one effil worker per box; each worker owns its box's HTTP
connection and round-robins requests via simple counter.

Health is tracked per-worker; a box that fails health checks is removed
from rotation until it recovers. The cluster degrades gracefully — losing
one box drops to 2/3 throughput, not 0.

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

- **916c — Lua library vendoring.** CMakeLists.txt rule that copies
  luasocket, dkjson, and effil-jit from `/home/ritz/programming/ai-stuff/
  libs/lua/` into the install location. No LuaRocks.

### Plumbing (no game integration yet)

- **916d — Ollama HTTP client.** `02-ollama-client.lua`: synchronous
  POST to a single Ollama box, parse JSON response, return Lua table.
  Tested standalone via `lua5.1 -l ollama-client -e 'print(ask("hello"))'`.

- **916e — effil worker pool.** `03-effil-workers.lua`: spin up 3
  workers on startup, each pinned to a Ollama host. Channel-based
  dispatch. Workers handle their own HTTP retries. Smoke test: queue 10
  requests, verify all complete and balance across workers.

- **916f — Health tracking and rotation.** Extend the worker pool with
  per-host health state. Failed HTTP calls increment a counter; over
  threshold the host drops out of rotation, with periodic re-check. Smoke
  test: kill ollama on box2, verify requests route around it; restart
  box2, verify it rejoins.

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
  Output schema: simple, just `{text: string}`.

- **916l — Chat emission and rate limiting.** `09-chat-emit.lua`: bot
  speaks via the appropriate channel (`/say` for nearby, `/whisper` for
  direct response). Per-bot cooldown (45s default) prevents spam. Output
  text gets light filtering (strip "As a [class], I..." patterns small
  models love).

### Operations

- **916m — Bash health check in scripts/worldserver.** Pre-flight check
  in the existing worldserver startup script that curls all three
  Ollama boxes' `/api/tags` endpoint. Warns (doesn't block) on failures.
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
SorenChat.OllamaHealthCheckOnStart = 1
```

`lua/01-config.lua`:

```lua
M.ollama_hosts = {
    { name = "box1", url = "http://192.168.1.11:10101", model = "llama3.2:1b" },
    { name = "box2", url = "http://192.168.1.12:20202", model = "llama3.2:1b" },
    { name = "box3", url = "http://192.168.1.13:30303", model = "llama3.2:1b" },
}
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

- **Model choice.** llama3.2:1b vs qwen2.5:1.5b vs gemma2:2b — pick after
  cluster benchmark. Constraints: must fit in 8GB with OS+Ollama+N
  parallel slots, must do passable structured output. Lean toward the
  smallest model that produces valid JSON >95% of the time.

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
- **148k — ALE auto-equip starter kit.** Established the pattern of
  small ALE Lua scripts hooking into events. mod-soren-chat is the
  bigger sibling.
- **914 — Custom Chat Data Sources** and **915 — Ollama Conversation
  Flow.** Superseded by 916. Both designed a JSON-with-Ollama-overlay
  approach to chat; 916 replaces that with LLM-native chat that
  shares infrastructure with the guidance layer. Both tickets should
  be marked superseded (not deleted) with a pointer to 916.
- **913 — Clustered Worldserver.** Spiritual sibling — both are
  cross-machine infrastructure. 913 is about scaling the worldserver;
  916 is about offloading LLM work.
- **mod-playerbots strategy/trigger/action architecture.** The lever
  916 pushes on. See playerbots docs at docs/playerbots/.

## Notes

The name "soren" is intentionally not descriptive. It's a name, not a
description, so the module can grow without the name fighting it.
mod-soren-chat could evolve into mod-soren if guidance becomes the
larger half, or if we add a third dimension (combat coordination
voice lines, dungeon-specific tactical commentary, narration of
ambush spawns). The name is a handle, not a contract.
