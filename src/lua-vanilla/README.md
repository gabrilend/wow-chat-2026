# src/lua-vanilla/

Lua scripts loaded by the `vanilla` profile via ALE. Symlinked into
`installed-files-vanilla/bin/lua_scripts/custom/` by E001 when the
active profile is `vanilla`.

The vanilla profile uses ALE for the narrow set of behaviors it
needs — currently just the starter-equipment equip-on-creation hook
(148h / pending sub-issue). The wow-chat design layer (ambush,
travel, custom classes, etc.) lives in `src/lua-beta/` and is NOT
loaded on vanilla by design.

When the project grows additional vanilla-specific scripts, add
them here. Keep the directory deliberately small — the whole point
of vanilla is the minimal scripting surface.

Sibling directories:
- `src/lua-beta/` — wow-chat design corpus loaded on beta (was
  formerly `src/lua/` before the 2026-06-02 per-profile rename).
- `src/lua-alpha/` — placeholder for alpha-profile (mod-eluna)
  scripts. The original wow-chat-1 scripts referenced in `CLAUDE.md`
  live in `libs/wow-chat-1/`; whether they belong here or stay in
  libs/ is the alpha-profile owner's call.
