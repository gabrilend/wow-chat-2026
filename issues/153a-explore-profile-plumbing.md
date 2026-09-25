# 153a - Explore Profile Plumbing

## Status
- Created: 2026-09-03
- Phase: 1
- Parent: 153
- Priority: High — nothing else in the 153 cluster can be built or tested
  until a profile named `explore` resolves.

## Current Behavior

Four profiles exist. Each is a name that a set of machinery agrees on:

| What resolves on the name | Example for vanilla |
| ------------------------- | ------------------- |
| The source tree | `source-beta/` (shared with beta and release) |
| The installed tree | `installed-files-vanilla/` |
| The Lua directory E001 symlinks in | `src/lua-vanilla/` |
| The database set | the four `acore_*` databases for the profile |
| The build directory | `build-beta-shadow/`, `build-release/`, … |
| The log directory | `logs-vanilla` → `/tmp/wow-chat-2/logs-vanilla` |
| The config-patch gates | `CONFIG_PROFILES[...]="vanilla"` in `config/patches/C*.sh` |
| The source-patch list | the per-profile lists in `patches/patches.sh` |
| The active selector | the single word in `.profile` |

A profile that is missing from any one of these fails differently, and two of
the failure modes are silent. A config patch whose `CONFIG_PROFILES` gate names
no existing profile simply never runs, and the server boots with upstream
defaults; a missing Lua directory means E001 symlinks nothing and the
worldserver starts with no custom scripts. Both look like a working server.

## Intended Behavior

A fifth profile, `explore`, resolving everywhere the other four do.

Its starting point is a copy of vanilla's shape — same source tree, same
module set, same client compatibility — with the 153 cluster's departures
layered on by patch gates rather than by forking anything.

### What it shares and what it does not

| | Shares with vanilla | Differs |
| --- | --- | --- |
| Source tree | `source-beta` | — |
| Module set | mod-ale, mod-playerbots, mod-aoe-loot, AIO | possibly no aoe-loot; see Open Questions |
| Level cap patch | — | its own `C006*` gate |
| Lua directory | — | `src/lua-explore/`, new and initially near-empty |
| Databases | — | its own four, seeded from vanilla's then stripped by 153b |
| Bot population | — | its own floor and ceiling, far lower (153e) |

### The Lua directory question, settled here

`src/lua-explore/` is a real directory from the start rather than a symlink to
`src/lua-vanilla/`, even though it begins nearly empty. The vanilla directory
holds `auto-equip-starter-kit.lua`, which arms a character with weapons and
weapon proficiencies for a survival ladder that this profile does not have.
Sharing the directory would mean explore characters spawn kitted for combat
that never comes. Whether explore wants *any* starting kit is a question for
153b; the directory being its own thing is not.

## Suggested Implementation Steps

1. **Measure the surface before touching it.** The same sweep issue 152
   prescribes for the rename, run for `vanilla`, gives the list of every place
   a profile name is resolved. That list is the work — do not estimate it.

2. **Add `explore` to the canonical definitions** in `issues/136-canonical-profile-definitions.md`
   and `docs/profiles/`, so the profile is described before it is built.

3. **Create the trees.** `installed-files-explore/`, `src/lua-explore/`,
   `sql/explore/`, `logs-explore` as a symlink into the RAM tier, and whatever
   build directory the shared `source-beta` arrangement implies.

4. **Create and seed the four databases**, then hand them to 153b to strip.
   Seeding from a fresh AzerothCore world rather than from vanilla's is
   cleaner if vanilla has already had 203 applied — check which state
   vanilla's world database is actually in before copying it.

5. **Add the config-patch gates.** Every `config/patches/C*.sh` that currently
   names `vanilla` has to be read and decided on, one at a time — some apply
   (database connections, ports, realm setup), some must not (the playerbot
   population and level-cap patches, which 153e and the level-cap question
   replace). A patch left ungated is a patch that does not run, silently, so
   the audit is the deliverable here rather than the edit.

6. **Register the profile in the scripts** — `scripts/profiles`,
   `scripts/install`, `scripts/compile`, `scripts/update`, and the
   `PROFILE_MODULES` / `MODULE_REPOS` / `PROFILE_MODULE_COMMITS` arrays keyed
   by profile name in `scripts/install`.

7. **Boot it empty and read the generated config back.** The test is not that
   the server starts — it is that every value a `C*.sh` patch was supposed to
   set actually reads back as that value in `installed-files-explore/etc/`.
   A gate that stopped matching produces a running server with wrong numbers.

## Affected Files (anticipated)

- `.profile`, and everything that reads it
- `scripts/profiles`, `scripts/install`, `scripts/compile`, `scripts/update`,
  `scripts/authserver`, `scripts/worldserver`
- every `config/patches/C*.sh` carrying a `CONFIG_PROFILES` line
- `patches/patches.sh` — the per-profile source-patch lists
- `patches/E-patches.sh` — E001's Lua symlink target
- `issues/136-canonical-profile-definitions.md`, `docs/profiles/`,
  `docs/table-of-contents.md`, `CLAUDE.md`

## Related Issues

- **136** canonical profile definitions — the spec being extended
- **133** profile transition system — the switching machinery
- **152** profile rename — if it lands first, this profile is created under
  the new naming scheme and `explore` should be sanity-checked against
  `basic`/`expert` for tone
- **148** the vanilla cluster — the worked example of standing a profile up

## Open Questions

- **Does explore need mod-playerbots at all, or a different bot source?**
  153e wants rare, wandering, talkative companions. mod-playerbots is built to
  field a combat party. It may be the wrong tool, and a much simpler
  wandering-NPC implementation may be the right one — in which case the module
  comes out and 153e gets bigger.
- **Does mod-aoe-loot make sense with no combat?** It exists for corpse
  looting. Herb and ore nodes are gameobjects, not corpses. Probably comes out.
- **Fresh world database or a copy of vanilla's?** Copying inherits vanilla's
  148-family customisations — pretrained abilities, cloned starter items,
  removed flight paths — some of which explore wants and some of which it does
  not. Starting fresh means re-deciding each one deliberately, which is more
  work and a better record.
- **Is `explore` the right name?** It describes the activity. The other names
  describe either an era (`vanilla`, `alpha`, `beta`) or an audience
  (`basic`, `expert` per 152). A verb sits oddly beside either scheme.
