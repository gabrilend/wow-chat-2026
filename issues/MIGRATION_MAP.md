# Issue Migration Map

Complete record of legacy `issues/` → `issues-beta/` number changes.
Source of truth for the final reference-sweep validation pass.

When migration cleanup completes, `issues-beta/` is renamed to `issues/`,
so cross-references in code/docs should use `issues/<new-number>-<slug>`
form (rename-stable). See `feedback_issue_numbering.md` in agent memory.

---

## Same-Number Migrations (Phase 1 actives, no renumber)

These were copied to `issues-beta/` keeping their existing slot.

| # | Title |
|---|---|
| 101 | verify-server-startup |
| 102 | test-playerbots-spawn |
| 106 | ingame-config-control-board |
| 106a | read-only-config-dashboard |
| 106b | runtime-config-modifications |
| 106c | config-persistence-layer |
| 107 | credential-manager-script |
| 111 | config-merge-script |

## Renumber Migrations

Format: **old → new** (slug, phase context if relevant)

### Phase 1 (Foundation)

| Old | New | Slug | Notes |
|-----|-----|------|-------|
| 145 | 116 | git-branch-consolidation | |
| 123 | 117 | visual-powerline-mapping-tool | |
| 166 | 118 | point-line-definition-tools | |
| 323 | 120 | parallel-update-status-spinners | |
| 321 | 121 | mysql-script-naming-aliases | |
| 327 | 122 | atomic-shadow-builds | (dup-327 split) |
| 327 | 123 | html-source-tree-export | (dup-327 split) |
| 328 | 124 | wimmelbilder-embedding-artwork | (dup-328 split, Phase 1) |
| 329 | 125 | algorism-priority-scheduler | (dup-329 split, Phase 1) |
| 333 | 126 | upstream-warning-fixes | |
| 334 | 127 | patch-system-improvements | |
| 411 | 128 | script-command-history | |
| 400 | 129 | release-to-beta-transition | superseded by 136 |
| 402 | 130 | verify-release-baseline | |
| 403 | 131 | incremental-patch-integration | |
| 404 | 132 | alpha-playerbots-working | invalidated by 136 |
| 405 | 133 | profile-transition-system | superseded by 136 |
| 406 | 134 | alpha-baseline-setup | |
| 408 | 135 | release-profile-build-fixes | |
| 412 | 136 | canonical-profile-definitions | **keystone** |
| 413 | 137 | shadow-conf-path-baked-into-binary | |
| 414 | 138 | sql-profile-switch-rollback | deferred |
| 167 | 139 | recreate-missing-sql-files | |
| 201 | 140 | branch-based-azerothcore-versioning | superseded by 136 |

### Phase 2 (Empty World)

| Old | New | Slug |
|-----|-----|------|
| 332 | 208 | ale-registry-corruption (dup-332 split) |
| 332 | 209 | ale-unit-methods-patch (dup-332 split) |

### Phase 4 (Treasure)

| Old | New | Slug |
|-----|-----|------|
| 148 | 402 | treasure-chest-shared-loot |
| 150 | 403 | ale-sell-item-hook |
| 149 | 404 | sold-items-to-treasure-pool |
| 151 | 405 | ability-tome-system |
| 152 | 406 | death-durability-system |
| 153 | 407 | chest-vulnerability-mechanic |
| 154 | 408 | multiplayer-chest-access |
| 160 | 409 | custom-empty-loot-chest-templates (dup-160 split, Phase 4) |
| 303 | 410 | chest-bound-hearthstones |
| 305 | 411 | zero-value-treasure-duplicates |
| 121 | 401 | bounty-board-currency-system (Phase 4 number reuse) |

### Phase 5 (Travelers)

| Old | New | Slug |
|-----|-----|------|
| 135 | 501 | custom-merchant-system |
| 137 | 502 | universal-class-trainers |
| 157 | 503 | dynamic-trainer-spawning |
| 320 | 504 | traveler-sit-with-player |
| (wandering-dogs) | 505 | creature-class-travelers |

### Phase 6 (Bot Behaviors)

| Old | New | Slug |
|-----|-----|------|
| 114 | 601 | behavior-find-monsters |
| 115 | 602 | behavior-discuss-with-npc |
| 116 | 603 | behavior-avoid-monsters |
| 117 | 604 | behavior-sit-and-rest |
| 118 | 605 | behavior-travel-to-unique-lands |
| 119 | 606 | behavior-orbit-player |
| 328 | 606b | getposition-nil-errors (dup-328 split, Phase 6 sub) |
| 125 | 607 | player-bot-behavior-commands |
| 132 | 608 | healer-bot-ping-pong-behavior |
| 133 | 609 | gesture-command-system-kneel-convoy |
| 160 | 610 | behavior-system-integration (dup-160 split, Phase 6) |
| 161 | 611 | bot-wandering-traveller-style (dup-161 split, Phase 6) |
| 162 | 612 | dungeon-rail-pathfinding (dup-162 split, Phase 6) |
| 329 | 612b | mmap-route-precomputation (dup-329 split, Phase 6 sub) |
| 164 | 613 | behavior-orchestrator-modes (dup-164 split, Phase 6) |
| 165 | 614 | activity-selection-boredom |
| 167 | 615 | ranged-bot-help-intervention (dup-167 split, Phase 6) |
| 168 | 616 | public-healer-frames-addon |

### Phase 7 (Custom Classes)

| Old | New | Slug |
|-----|-----|------|
| 140 | 701 | quest-spells-to-trainers |
| 142 | 702 | custom-spell-system |
| 143 | 703 | proc-gem-system |
| 144 | 704 | low-level-class-identity |
| 155 | 705 | custom-class-selection-npc |
| 159 | 706 | knight-custom-class |
| 161 | 707 | aio-tiered-talent-trainers (dup-161 split, Phase 7) |
| 162 | 708 | talent-tree-analysis-script (dup-162 split, Phase 7) |
| 163 | 709 | custom-class-lua-format (dup-163 split, Phase 7) |
| 163 | 710 | custom-class-resource-bars (dup-163 split, Phase 7) |
| 164 | 711 | custom-class-configuration-schema (dup-164 split, Phase 7) |
| 304 | 712 | conditional-class-selector-spawn |
| 345 | 713 | custom-talent-interface |
| 319 | 714 | chunked-talent-points |
| 347 | 715 | linear-ability-scaling |

### Phase 8 (Progression)

| Old | New | Slug |
|-----|-----|------|
| 139 | 801 | proportional-damage-rewards |
| 141 | 802 | talent-tier-limit |
| 156 | 803 | monster-accuracy-level-cap |
| 309 | 804 | invisible-level-progression |
| 322 | 805 | vavadane-shared-daily-reset-character |

### Phase 9 (Storytelling)

| Old | New | Slug |
|-----|-----|------|
| 122 | 901 | rebellious-attitudes-freedom-of-affairs |
| 126 | 902 | dungeon-room-spawn-zones |
| 127 | 903 | contextual-creature-spawns |
| 212 | 903b | regional-creature-spawn-themes (dup-212 split) |
| 212 | 903b1 | outland-demon-felorc-spawns (dup-212 split, supplemental) |
| 128 | 904 | embedding-based-creature-selection |
| 129 | 905 | portal-dimension-system |
| 131 | 906 | randomized-login-screen-freddi-fish |
| 302 | 907 | language-barrier-system |
| 307 | 908 | narrator-audience-facing |
| 308 | 909 | gutenberg-text-library |
| 310 | 910 | wandering-narrator-system |
| 311 | 911 | shepherd-flock-system |
| 312 | 912 | automated-lore-generation |
| 316 | 913 | clustered-worldserver |
| 330 | 914 | custom-chat-data-sources |
| 331 | 915 | ollama-conversation-flow |

### Phase 10 (rmail)

| Old | New | Slug |
|-----|-----|------|
| 313 | 1001 | rmail-dns-style-addresses |
| 315 | 1002 | rmail-login-flush-hook |
| 317 | 1003 | rmail-account-creation |
| 306 | 1004 | rmail-ingame-bridge |
| 314 | 1005 | rmail-feedback-mailbox |
| 164 | 1006 | rmail-ingame-text-editor (dup-164 split, Phase 10) |

---

## Already-Migrated (Pre-this-session)

Issues already in `issues-beta/completed/` from prior work:

| Old | New | Slug |
|-----|-----|------|
| 103 | 103 | configuration-documentation (was: document-configuration-options) |
| 104 | 104 | lua-script-ownership (was: migrate-lua-scripts-from-wowchat1) |
| 105 | 105 | project-local-database (was: setup-local-mysql-installation) |
| 108 | 108 | adaptive-build-parallelism (was: thread-count-variable) |
| 109 | 109 | incremental-rebuild-detection (was: add-build-mode-to-azerothcore-script) |
| 144 | 110 | concept-catalog-consolidation |
| 326 | 112 | patch-staleness-detection |
| 346 | 113 | authserver-ip-caching |
| 318 | 114 | remove-profile-system |
| 401 | 115 | shadow-build-setup |
| 407 | 119 | config-value-orchestrator |
| 112 | 201 | database-integrity-cleanup (was: fix-drop-creatures-cascading-errors) |
| 130 | 202 | lua-engine-initialization (was: ale-initialization-hook-fix) |
| 136 | 203 | drop-all-creatures-except-spirit-healers |
| 110 | 204 | random-spawn-point-feature |
| 120 | 205 | talent-points-level-20-cap |
| 138 | 206 | death-knight-level-1-scaling |
| 147 | 207 | clear-traveller-data-on-despawn |
| 124 | 303 | randomize-ambush-spawn-interval |
| 146 | 304 | clear-ambush-data-on-death |
| 158 | 305 | ambush-aggro-and-corpse-movement |
| 325 | 307 | ale-gameobject-wildcard |
| 113 | 301 | investigate-ambush-monsters-not-spawning |
| 301 | 302 | ocean-shark-hazard |
| 324 | 306 | nil-bot-periodic-event-crash |

---

## Disposition (No New Number)

| File | Disposition |
|------|-------------|
| `issues/100-route-to-v1.md` | Meta — kept at root as v1.0 release manifest |
| `issues/200-incremental-feature-restore` | Meta — kept at root as testing critical-path runbook |
| `issues/TONIGHT.md` | Kept until everything in it is done, then delete |
| `issues/next-issue-please` | Empty — deleted |
| `issues/wandering-dogs` | Verbatim text moved into 505; original deleted |

---

## Dangerous Number Collisions

Numbers that exist in *multiple phases* — searching for these by number
alone will produce false positives in the final sweep. Always check
context.

| # | Phases | Use |
|---|--------|-----|
| 110 | 1 (catalog), 2 (random-spawn), legacy 110 → 204 | |
| 112 | 1 (patch-staleness), 2 (db-integrity, legacy was 112) | |
| 113 | 1 (auth-ip-cache), 3 (investigate-ambush, legacy was 113) | |
| 130 | 1 (verify-release-baseline), 2 (lua-engine-init was legacy 130) | |
| 136 | 1 (canonical-profile keystone), 2 (drop-creatures was legacy 136) | |
| 144 | 1 (catalog was legacy 144), 7 (low-level-class was legacy 144) | |
| 167 | 1 (recreate-missing-sql), 6 (ranged-bot-help was legacy 167) | |
| 318 | 1 (remove-profile, completed) | |
| 401 | 1 (shadow-build was legacy 401), 4 (bounty-board, completed) | |
| 411 | 1 (script-command-history was legacy 411), 4 (zero-value-dups) | |
| 412 | 1 (canonical-profile in legacy was 412 → now 136) | |
| 160 | 4 (chest-templates), 6 (behavior-system-integration) — both legacy 160 |
| 161 | 6 (bot-wandering), 7 (aio-tiered-trainers) — both legacy 161 |
| 162 | 6 (dungeon-rail), 7 (talent-tree-analysis) — both legacy 162 |
| 163 | 7 (lua-format), 7 (resource-bars), 10 (custom-class-submission) — all legacy 163 |
| 164 | 6 (orchestrator), 7 (config-schema), 10 (text-editor) — all legacy 164 |
| 212 | 9 (regional-themes), 9 (outland-demon-felorc) — both legacy 212 |
| 327 | 1 (atomic-shadow), 1 (html-source-tree-export) — both legacy 327 |
| 328 | 1 (wimmelbilder), 6 (getposition-nil) — both legacy 328 |
| 329 | 1 (algorism), 6 (mmap-route) — both legacy 329 |
| 332 | 2 (registry-corruption), 2 (unit-methods-patch) — both legacy 332 |

---

## Final-Sweep Procedure

For each row in this map, the final-sweep step is:

1. Grep all project text files for the **old number** (e.g., `\b145\b`).
2. Filter out:
   - The legacy `issues/<old>-<slug>` file itself
   - This `MIGRATION_MAP.md` file
   - Coincidental numbers (creature IDs, line numbers, dates, etc.)
3. For each remaining hit, classify:
   - Issue reference → update to new number
   - Coincidental → leave alone
4. Re-run the grep to verify cleanup is complete.

Recommended exclusion paths during search:
`output/`, `source-beta/`, `source-alpha/`, `installed-files-*/`,
`mysql/`, `build-*/`, `patches/`, `modules-*/`, `llm-transcripts/`,
`docs/wiki/`, `.git/`.

High-risk targets to scan early:
- `docs/concept-issue-map.md` (literally an issue cross-reference doc)
- `docs/concept-catalog.md`
- `src/lua/*.lua`
- `docs/patches/*.md`
- `notes/`
