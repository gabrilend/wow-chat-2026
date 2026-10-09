# src/lua-cc-test/

The Lua scripts of the cc-test profile: the custom client's test server
(issue 176). Install step E001 links this folder into
`installed-files-cc-test/bin/lua_scripts/custom/`, and mod-ale loads every
`.lua` file in it when the worldserver starts.

Created 2026-10-08. The profile is stock AzerothCore plus playerbots, ALE and
the buddy module; nothing here acts in the world yet. Test scenes (issue
176a) can be written in Lua; the first planned are a full Alterac Valley
match (176a1) and an Arathi Basin match (176a2).

What is here, all plain rules with no game objects, checked by
scripts/test-arathi-basin-rules:

- lib/arathi-basin-routes.lua: where an Arathi Basin squad goes next (176a2c)
- lib/arathi-basin-bonuses.lua: each base's growing bonus (176a2e)
- data/arathi-basin-roads.lua: the roads, written by
  scripts/generate-arathi-basin-roads from the playerbots module's paths

The Lua engine loads every .lua file here at startup; these only return
tables, so loading them does nothing on its own.

The folder has to exist even while it holds nothing but this file: E001
stops with an error when a profile has no Lua folder, rather than starting a
server with no scripts and no sign that anything is missing.

Sibling folders:
- `src/lua-basic/` (the basic profile's scripts)
- `src/lua-beta/` (the wow-chat design corpus)
- `src/lua-vanilla/`, `src/lua-alpha/`
