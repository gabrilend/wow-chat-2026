# 916d - Ollama HTTP Client (Lua)

## Status
- Created: 2026-06-03
- Parent: Issue 916 (mod-soren-chat)
- Phase: 3
- Priority: High
- Depends on: 916c (luasocket and dkjson must be installed)

## Overview

A small Lua module that wraps Ollama's HTTP API behind a clean
synchronous call. Single host, no retries, no health tracking. Those
concerns belong to the worker pool (916e) and the health system (916f).
This sub-issue is just "given a host URL, a prompt, and a model, return
the parsed response or nil + error message."

## Current Behavior

No HTTP client exists in mod-soren-chat. luasocket is installed (via
916c) but no wrapper.

## Intended Behavior

After this sub-issue lands, `02-ollama-client.lua` exposes:

```lua
local client = require("mod-soren-chat.ollama-client")

-- Synchronous call. Blocks the calling thread until response or timeout.
-- Returns the parsed response table or nil + error string.
local response, err = client.generate({
    url = "http://192.168.1.11:10101",
    model = "llama3.2:1b",
    prompt = "You are a paladin in Stormwind. Say hello.",
    timeout_ms = 30000,
    options = { temperature = 0.7, num_predict = 80 },
})

if response then
    print(response.response)  -- the generated text
    print(response.eval_duration / 1e9 .. " seconds")
end
```

Synchronous is correct here because this module gets called from inside
an effil worker (916e), which runs on its own OS thread. The worker
thread blocking on the HTTP call doesn't block the worldserver tick.

## API Contract

The Ollama `/api/generate` endpoint:
- POST JSON body: `{ "model": "...", "prompt": "...", "stream": false,
  "options": { ... } }`
- Returns JSON: `{ "model", "created_at", "response", "done",
  "context", "total_duration", "load_duration", "prompt_eval_count",
  "prompt_eval_duration", "eval_count", "eval_duration" }`
- We parse `.response` for the text, `.eval_duration` for latency
  metrics
- Set `stream=false` always (we don't want token streaming for this use
  case)

## Implementation Steps

1. Write `lua/02-ollama-client.lua`:
   ```lua
   local http = require("libs.luasocket.socket.http")
   local ltn12 = require("libs.luasocket.ltn12")
   local json = require("libs.dkjson")

   local M = {}

   function M.generate(opts)
       local body = json.encode({
           model = opts.model,
           prompt = opts.prompt,
           stream = false,
           options = opts.options or {},
       })

       local response_body = {}
       local _, status_code = http.request({
           url = opts.url .. "/api/generate",
           method = "POST",
           headers = {
               ["Content-Type"] = "application/json",
               ["Content-Length"] = tostring(#body),
           },
           source = ltn12.source.string(body),
           sink = ltn12.sink.table(response_body),
           -- luasocket timeout is in seconds, not ms
           create = function()
               local s = require("libs.luasocket.socket").tcp()
               s:settimeout((opts.timeout_ms or 30000) / 1000)
               return s
           end,
       })

       if status_code ~= 200 then
           return nil, "HTTP " .. tostring(status_code)
       end

       local joined = table.concat(response_body)
       local parsed, _, err = json.decode(joined)
       if err then return nil, "JSON parse error: " .. err end
       return parsed
   end

   return M
   ```
2. Add a smoke test script (`test-ollama-client.lua`) that calls one
   host with a tiny prompt and prints the response
3. Run the smoke test against one of the three boxes; confirm a real
   response comes back
4. Document the response schema in a comment at the top of the file

## Files to Create

- `source-beta/modules/mod-soren-chat/lua/02-ollama-client.lua`
- (optional) smoke test under `src/lua-vanilla/`

## Open Questions

- luasocket's `socket.http.request` timeout setting interacts with
  `create` callback; the exact incantation needs verification against
  the luasocket version we have. The code above is a reasonable first
  pass.
- Streaming responses (`stream=true`) would let us start parsing tokens
  before the full response lands. Useful for chat where partial output
  could be emitted. Not in scope for v0; revisit if latency becomes a
  problem.
- We don't handle non-2xx HTTP responses cleanly beyond returning the
  status code. Add per-status retry logic? Probably not at this layer
  — leave it to 916f (health tracking).

## Related

- Parent: [916 - mod-soren-chat](916-mod-soren-chat.md)
- [916c - Vendored libs](916c-vendored-lua-libraries.md) — provides
  luasocket and dkjson
- [916e - Effil worker pool](916e-effil-worker-pool.md) — calls this
  module from inside worker threads
- Ollama API docs: <https://github.com/ollama/ollama/blob/main/docs/api.md>
