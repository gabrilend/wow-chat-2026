# 110 - Concept Catalog Consolidation

**Phase:** 1 (Foundation)
**Effect:** Context window usage reduced by 36%, faster agent loading
**Status:** Reopened (2026-08-07) — first pass completed 2026-04-05,
second pass open. See "Second Pass" at the end of this file.

---

## The Effect

The concept catalog (`docs/concept-catalog.md`) was trimmed from 1000 to 800 concepts, reducing token usage from ~28k to ~18k. Claude Code agents load faster on new sessions with more room for conversation context.

The catalog remains comprehensive while eliminating redundancy.

---

## What This Solved

### Before (Bloated Catalog)

**File Stats:**
- 4039 lines, 94KB
- ~28k tokens (14% of 200k context window)
- 1000 concepts across 10 parts

**Content Issues:**
- Part X (901-1000) almost entirely recap of earlier concepts
- Concepts repeated 3-5 times across parts (traveling salesman, ouroboros, timers)
- Generic programming concepts not project-specific (math stdlib, standard algorithms, markdown formatting)
- Claude Code agent guidance mixed with game concepts
- Heavy overlap between Part I (087-100) and Part VII (635-700) API functions

**Loading Impact:**
When Claude Code reads the catalog on session initialization:
```
Session Context Budget: 200k tokens
- Concept Catalog: 28k tokens (14%)
- Remaining for conversation: 172k tokens
```

With large conversations (debugging, multi-file edits), this 14% mattered.

### After (Consolidated Catalog)

**File Stats:**
- 2788 lines, 73KB (~18k tokens)
- 800 concepts (36% token reduction)
- Better organized, less redundancy

**Content Cleanup:**
1. Removed Part X recap content (100 concepts)
2. Merged duplicate concepts across parts
3. Grouped generic math/algorithms into fewer concepts
4. Removed non-project-specific content (markdown formatting, generic testing types)
5. Moved Claude Code guidance to CLAUDE.md where it belongs

**New Context Budget:**
```
Session Context Budget: 200k tokens
- Concept Catalog: 18k tokens (9%)
- Remaining for conversation: 182k tokens
```

10k more tokens available for debugging, code exploration, and complex conversations.

---

## Implementation Process

### 1. Audit and Analysis

Read through all 1000 concepts, identified:
- Exact duplicates (same wording across parts)
- Thematic duplicates (same concept, different angle)
- Generic content (standard library functions, markdown syntax)
- Agent instructions (better suited for CLAUDE.md)

### 2. Consolidation Strategy

**Remove Recap Section:**
- Part X (901-1000) was 90% recap
- Kept only unique concepts from this section
- Moved rest to git history

**Merge Duplicates:**
- Combined 5 instances of "traveling salesman problem" into one
- Merged timer/scheduler concepts (appeared in Parts I, V, VII)
- Consolidated API function documentation

**Abstract Generic Concepts:**
- Instead of listing each math function (sin, cos, tan, atan2, sqrt):
  - Combined into "Movement Math Functions (src/lua/movement.lua)"
- Instead of each algorithm (quicksort, binary search):
  - Combined into "Standard Algorithms Used"

**Relocate Agent Guidance:**
- Moved "when to use Task tool" to CLAUDE.md
- Moved "how to organize git commits" to CLAUDE.md
- Catalog now focuses on **game concepts**, not **agent instructions**

### 3. Verification

**Before consolidation:**
```bash
wc -l docs/concept-catalog.md
# 4039 docs/concept-catalog.md

du -h docs/concept-catalog.md
# 94K docs/concept-catalog.md
```

**After consolidation:**
```bash
wc -l docs/concept-catalog.md
# 2788 docs/concept-catalog.md

du -h docs/concept-catalog.md
# 73K docs/concept-catalog.md
```

**Reduction:**
- 31% fewer lines (4039 → 2788)
- 23% smaller file (94KB → 73KB)
- 36% fewer tokens (~28k → ~18k)

### 4. CLAUDE.md Update

Changed session initialization instruction:
```markdown
<!-- Before -->
On new session or context compaction: Read docs/concept-catalog.md
The catalog contains 1000 concepts...

<!-- After -->
On new session or context compaction: Read docs/concept-catalog.md
The catalog contains 800 concepts...
```

Removed `@import` syntax (not supported), replaced with explicit read instruction.

---

## Why This Matters

**Context Budget is Finite**

With 200k token limit, every token spent on initialization is one less for:
- Debugging complex issues
- Multi-file refactoring
- Exploring unfamiliar code
- Long conversations with user

A 10k token reduction (28k → 18k) is meaningful.

**Quality Over Quantity**

1000 concepts sounds impressive. But if 200 are duplicates and 100 are generic, the true count is 700.

Better to have 800 **unique, project-specific** concepts than 1000 mixed-quality ones.

**Fast Loading = Better UX**

When starting a new session:
- Read CLAUDE.md (2k tokens)
- Read concept-catalog.md (18k tokens)
- Ready to work (20k tokens total)

vs:
- Read CLAUDE.md (2k tokens)
- Read concept-catalog.md (28k tokens)
- Ready to work (30k tokens total)

The 10k difference means faster initialization and more room for conversation.

**Git History Preserves Everything**

The original 1000-concept version isn't deleted, it's in git:
```bash
git show HEAD^:docs/concept-catalog.md
```

If we need to reference removed content, it's there. No information lost.

---

## Related Phase 1 Issues

- 103 - configuration-documentation (also about documentation quality)
- 143 - concept-catalog-creation (original creation of catalog)

---

## Lessons Learned

### Duplication Creeps In

When building a catalog over time, concepts get added without checking for duplicates. Parts I-IX were written independently, leading to overlap.

**Lesson:** Periodic deduplication audits prevent bloat.

### Generic vs Specific

Listing every standard library function (sin, cos, tan, sqrt) doesn't add value. The catalog should focus on **project-specific patterns**, not language basics.

**Lesson:** Document what's unique to this codebase, not what's in the Lua manual.

### Recaps Are Redundant

Part X was added as a "summary" but became a list of duplicates. Recaps are useful in linear documents (books, tutorials) but wasteful in reference docs.

**Lesson:** Reference docs should be DRY (Don't Repeat Yourself).

### Agent Instructions ≠ Game Concepts

The concept catalog mixed:
- Game systems (ambush spawn, traveler behavior)
- Agent instructions (how to use Task tool, when to commit)

This was confusing. Agent instructions belong in CLAUDE.md.

**Lesson:** Separate "what the game does" from "how agents should work."

### File Size Isn't the Metric

A 94KB file isn't huge. But **token count** is what matters for LLM context.

- File size: 94KB → 73KB (23% reduction)
- Token count: ~28k → ~18k (36% reduction)

Token reduction was better than file size reduction because of how content was restructured.

**Lesson:** Optimize for tokens, not bytes.

---

## Phase 1 Contribution

This issue enables **Phase 1: Foundation** by ensuring:
> "Documentation is efficient and agents load quickly"

The catalog is a critical reference for understanding the codebase. Keeping it lean means agents can initialize faster and spend more context on problem-solving rather than loading documentation.

This is infrastructure work—invisible to players, but essential for developer productivity.

---

# Second Pass — Deduplicate CLAUDE.md Against the Catalog

**Opened:** 2026-08-07
**Status:** Open

## Source Report (verbatim, 2026-04-02)

> Okay great... Now, can you look at the CLAUDE.md file and the
> concept-catalogue.md file in docs/ and remove everything from the CLAUDE.md
> except things that aren't in the concept-catalogue? we're including the
> concept catalogue, so it doesn't make sense to include concepts twice.

## The Problem This Time

The first pass moved content *out of* the catalog and *into* CLAUDE.md
— agent instructions, git conventions, the Task-tool guidance. That
was the right direction for those items, and the lesson recorded above
still holds: agent instructions are not game concepts.

But the move went one way and nobody swept the other. CLAUDE.md still
carries game-concept material that the catalog also carries, and both
files are read at session start, so the duplicated passages are paid
for twice out of the same context budget.

The overlap is not speculative. Three CLAUDE.md sections have direct
catalog counterparts:

| CLAUDE.md section | Catalog concept |
|---|---|
| Coding Style (Lua) → Vertical Alignment | 633 — Vertical Alignment |
| Coding Style (Lua) → Dense Math, Few Functions | 634 — Dense Math, Few Functions |
| Ambush Spawn System → Spawn Interval (Random Walk) | 146 — Random Walk Spawn Interval |
| Ambush Spawn System → Grace Period | 146 (same entry, second half) |
| Visual Powerline Mapping (whole section) | 638–646 — Powerline Mapping, Generation, Principles, Skooch, Editor-Rendered |

The CLAUDE.md versions are longer, with worked code examples. The
catalog versions are one or two lines each. So the duplication is
lopsided — it is not the same text twice, it is the full treatment and
the index entry.

## The Question That Decides the Shape

Whether the catalog entry or the CLAUDE.md section is the survivor is
not obvious, and the answer differs per item.

- **Coding style** is instruction — it tells whoever is writing Lua
  how to write it. That is CLAUDE.md's job, and a one-line catalog
  entry cannot substitute for the worked example. Likely outcome:
  CLAUDE.md keeps it, the catalog entry becomes a pointer.
- **Ambush spawn constants** are configuration facts that live in
  `src/lua-beta/ambush.lua` as actual source. Both documents are
  copies, and copies of numbers go stale. Likely outcome: both point
  at the source file, and neither restates the values. This also
  satisfies the project rule against hard-coding statistics into
  documentation.
- **Powerline mapping** is a tool specification with its own issue
  (117). Likely outcome: CLAUDE.md keeps the two-sentence version and
  points at 117; the catalog keeps its index entries.

## Implementation Steps

1. Read CLAUDE.md section by section and check each against the
   catalog. The five rows above are the confirmed overlaps; the sweep
   may find more, and `docs/concept-catalog-2.md` (larger than the
   original catalog) has not been checked at all.
2. For each overlap, decide which document owns it using the
   instruction-versus-concept split: does this text tell someone what
   to *do*, or does it name something that *exists*? Instructions stay
   in CLAUDE.md. Named things stay in the catalog.
3. For anything that is a copy of a value that lives in source, remove
   the value from both and point at the source file.
4. Replace the losing copy with a one-line pointer rather than
   deleting outright, so a reader who looks in the wrong place still
   gets sent to the right one.
5. Re-measure both files. The first pass's metric was token count, not
   line count, and the same applies here.

## Open Questions

- **What is `docs/concept-catalog-2.md` and does it participate?**
  It is larger than `concept-catalog.md` (3423 lines against 2788) and
  CLAUDE.md's session-initialization instruction names only the
  original. If it is a successor, the initialization instruction is
  pointing at the wrong file and that is a bigger problem than the
  duplication. If it is a draft, it should say so at the top.
- **Should CLAUDE.md still be read in full at session start?** The
  first pass framed the budget as CLAUDE.md plus catalog. If the
  catalog is the reference and CLAUDE.md is the instruction set, the
  instruction set is the one that has to be read every time and the
  reference is the one that could be consulted on demand.
