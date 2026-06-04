# src/lua-alpha/

Placeholder for alpha-profile Lua scripts (mod-eluna era).

Created 2026-06-02 during the per-profile Lua-dir rename. As of
that date, alpha's `PHASE_END_PATCHES` does NOT include E001, so
this directory isn't yet symlinked into `installed-files-alpha/`.
The original alpha-era scripts live in `libs/wow-chat-1/` per
`CLAUDE.md` ("Reference: libs/wow-chat-1/ - original Lua scripts
from previous version - do not alter").

If the alpha profile gains a need for its own Lua hooks, the
mechanism is in place:
1. Drop the scripts here.
2. Add `E001` to `PHASE_END_PATCHES["alpha"]` in `patches/patches.sh`.
3. Reboot the alpha worldserver — mod-eluna will load this dir as
   `lua_scripts/custom/`.

Sibling directories:
- `src/lua-beta/` — wow-chat design corpus loaded on beta via ALE.
- `src/lua-vanilla/` — minimal vanilla scripts (currently just the
  starter-equipment hook, pending sub-issue 148k).

ALE vs eluna: scripts written for ALE generally also work under
eluna (the APIs overlap substantially), but the few ALE-only
additions in this project (extra Unit methods from B007,
PLAYER_EVENT_ON_SELL_ITEM from B006, etc.) won't have eluna
counterparts. Don't drop ALE-specific scripts here without
porting them.
