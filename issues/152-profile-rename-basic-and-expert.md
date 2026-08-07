# 152 - Rename the Profiles: vanilla → basic, release → expert

## Status
- Created: 2026-08-07
- Phase: 1 (Foundation — profile model)
- Related: 136 (canonical profile definitions — the spec this
  renames), 133 (profile transition system), 148 (the vanilla
  profile itself)
- Priority: Medium — nothing is broken, but the current names carry
  the wrong meaning and the cost of renaming grows with every new
  file that hard-codes a profile name.

## Source Report (verbatim, 2026-07-21)

> rename the vanilla profile to basic, and the release version to expert, to
> mirror the osr D&D releases. vanilla intending to be for a "demo" or otherwise
> constrained experience, and then release is the newly modified version.

## Why the Current Names Are Wrong

Two separate problems, and the rename fixes both.

**"vanilla" claims an era it does not occupy.** In WoW vocabulary,
"vanilla" means the 1.x client — pre-Burning Crusade, level cap 60.
This profile is a 3.3.5a WotLK server with a level cap of 40, a
starting level of 20, and a curated module set. Anyone who hears
"vanilla" expects Classic and gets something else. What the profile
actually *is* is the constrained entry experience: fewer moving
parts, a shorter ladder, the thing you hand someone who wants to see
what the server is without absorbing the whole design.

**"release" is doing two jobs at once.** In 136 it names a build
target — one of four profiles, alongside alpha and beta. In ordinary
software speech it names a *stage* of a development cycle, the thing
that comes after alpha and beta. The project uses both senses, which
means "is that in release?" is an ambiguous question. Freeing the
word by renaming the profile to `expert` lets the stage sense own it
outright.

The replacement names come from the OSR Dungeons & Dragons line —
the Basic Set and the Expert Set. Basic is complete and playable on
its own and covers the early levels. Expert extends it: same game,
more of it, for people who have already played the first one. That
is exactly the relationship between these two profiles, and it says
so without needing a footnote.

## Naming Semantics After the Rename

| Old | New | What it means |
|---|---|---|
| `vanilla` | `basic` | The constrained demo experience. Level cap 40, start at 20, playerbots, no wow-chat design layer. Complete and playable by itself. |
| `release` | `expert` | The extended experience. Level cap 80, the proven wow-chat features that have been promoted out of beta. |
| `beta` | `beta` | Unchanged. Still the staging ground where features are proven before promotion. |
| `alpha` | `alpha` | Unchanged. Still the frozen wow-chat-1 holiday relic. |

The promotion pipeline described in 136 keeps its shape — features
are written in beta, hardened, and promoted into the extended
profile. Only the destination's name changes.

## The Other Sense of Alpha and Beta

Recorded here because the rename is what makes it sayable without
collision. From the same session's notes:

> 1.0 won't have everything... is beta now (technically alpha but I
> didn't want to use too many branches) — alpha meaning, still adding
> features, beta means testing, then development cycle for each 1
> digit increment. decimal point digits are for patches. each
> development cycle has an alpha, beta, but no digit increments —
> just, alpha, beta, then release as-is.

So the version scheme is: a development cycle runs alpha (features
are still being added) → beta (no new features, testing only) →
release. The whole cycle ships as a single integer version. Decimal
digits are patches against a shipped integer version. There is no
1.1 that means "a bit more than 1.0 in features" — feature growth
moves the integer, and the decimals are repairs.

This is a *stage* vocabulary and it collides head-on with the
*profile* vocabulary in 136, where alpha and beta are two of four
build targets that all exist simultaneously. The collision is real
and unresolved. The rename removes one of the three collisions
(`release`) and leaves two. See Open Questions.

## Blast Radius

The profile name is a string that appears in file paths, directory
names, database names, config-patch gates, and the `.profile` file
that selects which of them is active. Everything below has to move
together or the build stops resolving.

**Do not estimate the count — measure it.** Before starting:

```bash
grep -rn "vanilla" /mnt/mtwo/games/azeroth-core/wow-chat-2026 \
  --exclude-dir=source-beta --exclude-dir=source-alpha \
  --exclude-dir=build-cache --exclude-dir=.git \
  --exclude-dir=llm-transcripts
```

and the same for `release`. The second sweep is the harder one,
because `release` also appears as an ordinary English word and as
CMake's `Release` build type — those must not be rewritten.

### Directories that move

| Current | New |
|---|---|
| `installed-files-vanilla/` | `installed-files-basic/` |
| `installed-files-release/` | `installed-files-expert/` |
| `src/lua-vanilla/` | `src/lua-basic/` |
| `sql/vanilla/` | `sql/basic/` |
| `docs/profiles/vanilla.md` | `docs/profiles/basic.md` |
| `docs/profiles/release.md` | `docs/profiles/expert.md` |
| `logs-vanilla` (symlink → `/tmp/wow-chat-2/logs-vanilla`) | `logs-basic` |
| `logs-release` (symlink) | `logs-expert` |
| `build-release/` | `build-expert/` |

Per project rule, a directory move must have both the before and
after states tracked in git — use `git mv` so the rename is a single
tracked operation rather than a delete plus an add.

### Databases that get renamed

MySQL has no `RENAME DATABASE`. Each one is a create-new,
copy-tables, drop-old sequence, or a dump-and-reload:

- `acore_world_vanilla` → `acore_world_basic`
- `acore_characters_vanilla` → `acore_characters_basic`
- `acore_auth_vanilla` → `acore_auth_basic`
- `acore_playerbots_vanilla` → `acore_playerbots_basic`
- the four `*_release` equivalents → `*_expert`

Characters live in these. The migration must be non-destructive and
verified before the old databases are dropped.

### Scripts that resolve profile names

`scripts/profiles`, `scripts/install`, `scripts/compile`,
`scripts/update`, `scripts/authserver`, `scripts/worldserver`, and
anything else that reads `.profile` or switches on its value. The
`PROFILE_MODULES`, `MODULE_REPOS`, and `PROFILE_MODULE_COMMITS`
associative arrays in `scripts/install` are keyed by profile name.

### Patch gates

Every `config/patches/C*.sh` declares a `CONFIG_PROFILES` list, and
several are gated specifically on `vanilla` (C012, C014, C020, the
C007 family). `patches/patches.sh` holds the per-profile patch lists.
Both need the new names, and both are the kind of file where a
missed rename fails silently — a patch whose gate no longer matches
any profile simply never applies, and the server boots with default
values instead of erroring.

### The `.profile` file

One line, currently `vanilla`. It is the switch. It changes last, so
the tree is consistent before anything selects the new name.

## Suggested Implementation Steps

1. Run both grep sweeps and save the output. That list is the work.
2. Separate the `release` hits into three buckets: the profile name,
   the English word, and CMake's `Release` build type. Only the
   first bucket is in scope. Getting this wrong breaks the build in
   a way that looks unrelated to the rename.
3. Rename directories with `git mv`, one at a time, committing each
   so the history shows the move rather than a delete/add pair.
4. Update the scripts, then the patch gates, then the docs.
5. Migrate the databases. Verify row counts match on both sides
   before dropping anything. Keep the old databases until a
   character has been logged in successfully on the renamed set.
6. Flip `.profile` last.
7. Full clean build and boot on `basic`, then on `expert`. A
   config-patch gate that stopped matching shows up as a wrong value
   at runtime, not as a build error — so the check is reading the
   generated `.conf` files, not just seeing the server start.
8. Update `docs/table-of-contents.md` for the renamed profile pages.
9. Update `CLAUDE.md`'s Profiles section.

## What Does Not Get Renamed

- **Issue files.** Issues are immutable. `148-vanilla-profile-default-wotlk-playerbots.md`
  and its two dozen `148*-vanilla-*` siblings keep their names and
  their contents. They are the record of how the profile was built
  under the name it had at the time. This issue is the pointer that
  connects the old name to the new one.
- **LLM transcripts.** Same reasoning — they are an append-only
  record.
- **`source-beta/` and `source-alpha/`.** These are named after the
  *source trees*, and both surviving profiles that share `source-beta`
  keep sharing it. 136 is explicit that the modules/source directory
  name should say which source it backs. Renaming `source-beta` would
  break that relationship for a cosmetic gain.

## Cross-References

- `issues/136-canonical-profile-definitions.md` — the canonical
  profile spec. After this rename lands, 136's definitions get the
  new names and a note that the old ones are historical.
- `issues/133-profile-transition-system.md` — the switching machinery.
- `issues/148-vanilla-profile-default-wotlk-playerbots.md` — the
  profile being renamed; keeps its filename.
- `docs/profiles/index.md` — the user-facing profile overview, which
  is where a player meets these names.
- `.profile` — the one-line switch.

## Open Questions

- **Do `alpha` and `beta` keep their names?** The report only names
  two profiles. Leaving alpha and beta alone means the profile set
  reads `basic / expert / beta / alpha` — two names from D&D, two
  from software release stages. That is not obviously wrong (beta
  and alpha genuinely are staging targets, not player-facing
  experiences), but it is worth deciding on purpose. The alternative
  is a full four-name scheme.
- **Does the stage/profile collision get resolved here or
  separately?** After this rename, `alpha` and `beta` still mean two
  things each. A version string like "basic 2.0-beta" is
  unambiguous; the bare word "beta" is not.
- **Is `expert` the right word for a level-80 profile with the
  proven wow-chat features?** In D&D, Expert is a superset of Basic
  for players who finished the first box. Here, the extended profile
  is not strictly a superset — it drops some of basic's identity
  (level cap 40, curated starting kits) rather than adding to it.
  The analogy may be close enough to be useful anyway.
- **When?** This is a rename with a database migration in it, and it
  wants a quiet moment with no characters mid-session. Doing it
  before the 148 family finishes validating means renaming a moving
  target; doing it after means more files to sweep.
- **What happens to the `shadow` build tree?** `build-shadow/` and
  `installed-files-shadow/` exist alongside the profile trees and
  are not profiles. Confirm they are untouched by this.
