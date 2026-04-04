# Issue 145: Git Branch Consolidation

## Current Behavior

Three git branches exist with fragmented features:

| Branch  | Behaviors | Random Walk Ambush | Recent Docs | Status |
|---------|-----------|-------------------|-------------|--------|
| beta    | ✓ (deleted from tree) | ✗ | ✓ | HEAD, active work |
| alpha   | ✗ | ✓ | ✗ | 1 unique commit |
| release | ✗ | ✗ | ✗ | Oldest, unused |

### Branch Graph
```
beta (HEAD)─────816938a─...─2a0811b
                                │
                            a80bec3 (common ancestor)
                                │
alpha──────────────────────e5bf800 (ambush.lua random walk)
                                │
                            3616a19
                                │
                            fb04a15 (merge)
                           /        \
                    dd96835          90f4568 ← behaviors added here
                           \        /
                            1fc133a
                                │
release─────────────────────────┘ (oldest)
```

### Behaviors (in beta, deleted from working tree)
- gestures.lua (405 lines) - Kneeling, beckoning, sitting commands
- convoy.lua (450 lines) - Ouroboros convoy with traveling salesman
- level-affinity.lua (379 lines) - Level-based bot clustering (50%/75% rules)
- zone-consensus.lua (382 lines) - Collective player facing for idle drift
- find-monsters.lua (194 lines) - Combat targeting
- avoid-monsters.lua (267 lines) - Danger awareness
- sit-and-rest.lua (230 lines) - Resource recovery
- orbit-player.lua (267 lines) - Formation positioning
- init.lua (93 lines) - Loads all behaviors in order

**Total:** 2,667 lines

### Random Walk Ambush (in alpha only)
Located in alpha's commit e5bf800, adds dynamic spawn interval:
- Base interval: 40 seconds
- Each spawn, interval varies by +/- 2-4 seconds from *previous* value
- Floor: 10 seconds (only goes up when hit)
- Soft cap: 100 seconds (33% chance up, 67% down)
- Hard cap: 200 seconds (20% up, 80% down)

Makes spawns feel less mechanical - sometimes frantic, sometimes calm.

## Intended Behavior

Consolidate all features onto the alpha branch (experimental/cutting edge):
- Alpha contains: behaviors + random walk ambush + all recent docs
- Release preserved as tag for history (June 2023 known good)
- Beta branch deleted after merge

This aligns with the profile system in scripts/azerothcore:
- alpha = cutting edge, experimental
- beta = current testing (will become alpha after merge)
- release = stable baseline

## Implementation Steps

1. [ ] Switch to alpha branch
2. [ ] Merge beta into alpha (brings behaviors + docs)
3. [ ] Resolve any merge conflicts
4. [ ] Restore behaviors to working tree: `git restore src/lua/behaviors/`
5. [ ] Verify all features present
6. [ ] Tag release branch as v0.1-june2023 for history
7. [ ] Delete beta and release branches
8. [ ] Update CLAUDE.md to reflect single-branch workflow

## Stash Commands Reference

The stash mentioned in issue 200 is now empty - work was committed to branches.

## Related Documents

- issues/200-incremental-feature-restore - Original feature restore tracking
- scripts/azerothcore - Profile system (alpha/beta/release server builds)
- CLAUDE.md - Branch references to update

## Notes

Git branches (alpha/beta/release) track Lua code and project files.
Server profiles (alpha/beta/release) track AzerothCore builds.
These are separate systems that happen to share naming.
