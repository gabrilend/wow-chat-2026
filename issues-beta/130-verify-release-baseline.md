# 130 - Verify Release Baseline

## Status
- Created: 2026-04-09
- Parent: 129-release-to-beta-transition (was 400)
- Phase: Foundation
- Priority: High

## Current Behavior

Release branch exists at commit 1fc133a but hasn't been verified recently.
Unknown if it still builds and runs correctly.

## Intended Behavior

Confirm release branch provides working baseline:
- Server compiles without errors
- Authserver starts
- Worldserver starts
- Can login with WoW client
- Playerbots module functional (basic)

## Verification Steps

1. [ ] Checkout release branch in shadow worktree
2. [ ] Run full build: `./scripts/azerothcore update`
3. [ ] Start MySQL: `./scripts/start-mysql`
4. [ ] Start authserver: `./scripts/azerothcore authserver`
5. [ ] Start worldserver: `./scripts/azerothcore worldserver`
6. [ ] Connect with WoW client
7. [ ] Create character and enter world
8. [ ] Test basic playerbot: `.bot add`

## Expected State at Release

| Component | Expected Status |
|-----------|-----------------|
| mod-ale | Working (basic Lua scripting) |
| mod-playerbots | Working (bot spawning) |
| mod-aoe-loot | Working |
| Custom Lua | wow-chat-1 scripts only |
| Custom SQL | None |
| Patches | None applied |

## Documentation

Record any issues found in this file. If release doesn't build:
1. Check git log for what changed
2. Look for missing dependencies
3. Document fix and add to migration guide

## Success Criteria

- [ ] Compile succeeds
- [ ] Authserver starts without errors
- [ ] Worldserver starts without errors
- [ ] Client can connect and login
- [ ] Character can enter world
- [ ] Basic playerbot command works
