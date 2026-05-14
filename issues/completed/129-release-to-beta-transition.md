# 129 - Release to Beta Transition

**Status:** Superseded by issue 136 (canonical-profile-definitions). The
profile model in this issue (release=wow-chat-1 vanilla, alpha=+playerbots,
beta=+custom) is no longer accurate. See 136 for current definitions.
Kept for traceability.

## Status
- Created: 2026-04-09
- Phase: Foundation
- Priority: Critical

## Three-Tier Branch Model

```
release = wow-chat-1 vanilla (baseline, no playerbots complexity)
alpha   = wow-chat-1 + working playerbots (TONIGHT's GOAL)
beta    = alpha + readme features (custom Lua, patches, etc.)
```

## Build Strategy

- Source patched in intermediary (git checkout + patches)
- Build in shadow realm (build-{profile}/)
- Only promote to installed-files if compile succeeds
- Rewrite patches until they work

## Known-Good Baseline

```
Branch: release
Commit: 1fc133a feat(108,109): Auto-detect thread count, improve update command
```

This baseline includes:
- [x] Project initialization and structure
- [x] wow-chat-1 Lua scripts migration
- [x] Local MySQL installation
- [x] Configuration system with profiles
- [x] Build scripts (azerothcore update/compile)
- [x] Credential management

## Beta Features to Integrate

Features from beta branch that need systematic integration:

### Core Systems (C++)
| Feature | Issue | Status | Notes |
|---------|-------|--------|-------|
| mod-talent-bonus | 205 | Pending | Bonus talent validation |
| ALE Unit methods | 332 | Pending | SetWalk, IsWalking, IsHostileTo, IsFriendlyTo |
| ALE sell item hook | 150 | Pending | PLAYER_EVENT_ON_SELL_ITEM |
| Accuracy level cap | 156 | Pending | Cap hit/miss at ±3 levels |
| ALE gameobject wildcard | 325 | Pending | Entry 0 wildcard registration |
| Playerbots ALE login hook | 306 | Pending | sALE->OnLogin for bots |

### Lua Systems
| Feature | Issue | Status | Notes |
|---------|-------|--------|-------|
| Ambush spawn system | 203 | Pending | Monster spawns around players |
| Travel system | - | Pending | Traveler NPC wandering |
| Treasure system | 153 | Pending | Chest spawns with vulnerability |
| Bot behaviors | 161 | Pending | Wander, orbit, convoy, etc. |
| Levelling system | 205 | Pending | Talent points at 33%/66% XP |

### Database
| Feature | Issue | Status | Notes |
|---------|-------|--------|-------|
| Death Knight stats | 206 | Pending | Level 1-20 scaling |
| Custom class NPCs | 155 | Pending | Class selector spawns |

## Migration Strategy

### Phase 1: Shadow Clone
1. Create new worktree from release branch
2. Apply patches one-by-one
3. Test each patch before proceeding
4. Document any issues encountered

### Phase 2: Patch Refinement
1. Fix any broken patches
2. Update patch documentation
3. Create idempotent apply/unapply functions
4. Test full patch cycle

### Phase 3: Integration Testing
1. Start server with all patches
2. Verify playerbots spawn and function
3. Test Lua systems (ambush, travel, treasure)
4. Validate custom features

### Phase 4: Documentation
1. Update all issue files with results
2. Create migration script
3. Document lessons learned
4. Archive beta branch state

## Shadow Build Location

```
/home/ritz/games/azeroth-core/wow-chat-2026-shadow/
```

## Related Files

- `patches/*.sh` - Individual patch files
- `patches/patches.sh` - Patch orchestration
- `issues-beta/` - Beta-specific issue tracking
- `docs/patches/patch-registry.md` - Patch documentation

## Success Criteria

1. Server starts without errors
2. Playerbots spawn and respond to commands
3. ALE Lua engine loads all scripts
4. All beta features functional
5. Process documented and repeatable

## Notes

- Everything is preserved in git - nothing is lost
- Each step should be a commit
- If something breaks, we can bisect
- Documentation updates are as important as code changes
