# 132 - Alpha: Get Playerbots Working

**Status:** Invalidated by issue 136 (canonical-profile-definitions).
Per the canonical model, alpha **does not include playerbots** — it
uses mod-eluna and the wow-chat-1 corpus. Kept for traceability.

## Status
- Created: 2026-04-09
- Priority: TONIGHT
- Target: Alpha branch working with playerbots

## Goal

**Alpha = wow-chat-1 + working playerbots**

Nothing fancy. Server runs. Bots spawn. Bots follow commands. Done.

## Three-Tier Model

| Branch | Definition | Status |
|--------|------------|--------|
| release | wow-chat-1 vanilla | Baseline |
| alpha | wow-chat-1 + playerbots | **TONIGHT** |
| beta | alpha + readme features | Later |

## Steps to Alpha

### 1. Start from release
```bash
git checkout release
```

### 2. Build clean
```bash
./scripts/azerothcore update --force
```

### 3. Test vanilla works
- Server starts
- Can login
- World loads

### 4. Verify playerbots module present
```bash
ls source-release/modules/mod-playerbots/
```

### 5. Test bot commands
```
.bot add
.bot remove
```

## What Alpha Does NOT Need

- No B002 patch (ALE login hook) - that's beta
- No custom Lua behaviors - that's beta
- No mod-talent-bonus - that's beta
- No custom SQL - that's beta

## What Alpha DOES Need

- mod-playerbots compiling
- mod-ale compiling (for future)
- mod-aoe-loot compiling
- Basic bot spawning working

## Patches Required for Alpha

Only patches that fix BUILD ERRORS:

| Patch | Needed? | Reason |
|-------|---------|--------|
| B001 | Maybe | AOE loot namespace fix |
| B002 | NO | Beta feature |
| B003 | NO | Beta feature |
| B004 | Maybe | Warning fixes help |
| B005 | NO | Beta feature |
| B006 | NO | Beta feature |
| B007 | NO | Beta feature |
| B008 | NO | Beta feature |

## Success Criteria

- [ ] `./scripts/azerothcore worldserver` starts
- [ ] Login with client works
- [ ] `.bot add` spawns a bot
- [ ] Bot follows player
- [ ] No crashes for 5 minutes

## Notes

Keep it simple. Get it working. Document what breaks.
