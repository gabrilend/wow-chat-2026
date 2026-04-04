# Issue 144: Concept Catalog Consolidation

## Current Behavior

The `docs/concept-catalog.md` file contains 1000 concepts across 10 parts, totaling ~28k tokens. This consumes significant context when loaded via CLAUDE.md.

Analysis identified:
- Part X (901-1000) is almost entirely a recap of earlier concepts
- Concepts repeated 3-5 times across parts (traveling salesman, ouroboros, timers, etc.)
- Generic programming concepts not project-specific (math stdlib, standard algorithms, markdown formatting)
- Claude Code agent guidance mixed with game concepts
- Heavy overlap between Part I (087-100) and Part VII (635-700) API functions

## Intended Behavior

Consolidate to ~800 concepts by:
1. Removing Part X recap content
2. Merging duplicate concepts across parts
3. Grouping generic math/algorithms into fewer concepts
4. Removing non-project-specific content (markdown formatting, generic testing types)
5. Moving Claude Code guidance to CLAUDE.md where it belongs

Target: ~20k tokens or less (30% reduction)

## Implementation Steps

1. [x] Confirm original is committed in git
2. [ ] Create consolidated 800-concept version
3. [ ] Verify token count reduction
4. [ ] Commit new version
5. [ ] Update CLAUDE.md if needed

## Related Documents

- docs/concept-catalog.md (original 1000-concept version)
- CLAUDE.md (references catalog)

## Notes

The original 1000-concept version remains in git history for reference.
