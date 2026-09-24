# src/lua-basic/

Lua scripts loaded by the `basic` profile (issue 155) via ALE. Linked into
`installed-files-basic/bin/lua_scripts/custom/` by E001 when the active
profile is `basic`.

Basic is the level 1–60 development baseline: stock game plus playerbots
and the quality-of-life layer. It starts with no scripts. Vanilla's only
script equips the level-20 starter kit, which basic deliberately does not
have, so this directory is its own rather than a link to
`src/lua-vanilla/`.

Custom classes (the 700s issues) are the first feature expected to land
here.

This directory must exist even while empty: E001 treats a missing
per-profile Lua directory as an error, because a missing directory means
the profile was never set up or `.profile` is misspelled.

Sibling directories:
- `src/lua-vanilla/` — vanilla's starter-kit hook.
- `src/lua-beta/` — the wow-chat design corpus.
- `src/lua-alpha/` — placeholder for alpha (mod-eluna) scripts.
