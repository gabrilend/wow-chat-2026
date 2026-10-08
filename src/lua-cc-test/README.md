# src/lua-cc-test/

The Lua scripts of the cc-test profile: the custom client's test server
(issue 176). Install step E001 links this folder into
`installed-files-cc-test/bin/lua_scripts/custom/`, and mod-ale loads every
`.lua` file in it when the worldserver starts.

Empty on purpose, created 2026-10-08. The profile is stock AzerothCore plus
playerbots and ALE, so nothing runs here until the first test scene is
written. Test scenes (issue 176a) can be written in Lua; the first is a full
Alterac Valley match (issue 176a1).

The folder has to exist even while it holds nothing but this file: E001
stops with an error when a profile has no Lua folder, rather than starting a
server with no scripts and no sign that anything is missing.

Sibling folders:
- `src/lua-basic/` (the basic profile's scripts)
- `src/lua-beta/` (the wow-chat design corpus)
- `src/lua-vanilla/`, `src/lua-alpha/`
