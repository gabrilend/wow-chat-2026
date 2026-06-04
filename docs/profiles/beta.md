# Beta Profile

**One-line summary:** Active development tier — release baseline
plus every in-flight feature, all source patches applied, where
new wow-chat features are written and tested before graduating to
release.

## What you get

Everything release has, plus everything currently in flight. Beta
is where the project's experimental work happens. If a new ambush
behavior is being prototyped, a new custom class is being tuned,
a new ALE hook is being tested — beta is where it lives until it's
proven out enough to promote to release.

The wow-chat design layer is fully active here, including the
parts not yet promoted:

- All ambush spawn behaviors, including the experimental ones.
- All custom classes, including in-progress balance.
- All ALE hooks (the full B-patch set is applied).
- Whatever experimental modules are currently being tried.

If you find a regression on beta and the same character on release
works fine, that regression is the difference between the two.

## Installed modules

- **mod-ale** — Lua scripting engine, runs the wow-chat corpus
- **mod-playerbots** — AI companion bots
- **mod-aoe-loot** — area loot
- **mod-grownup** — character model size scales with level
- *Plus any beta-only experimental modules currently being tried*

The module set may expand with beta-only experiments and contract
again as experiments end. Check `scripts/install` for the current
authoritative `PROFILE_MODULES["beta"]` list.

All modules track upstream HEAD.

## Source patches

Beta runs **every B-patch in the repository** (currently 23 of
them, ALE feature additions, playerbots compile fixes, aoe-loot
integration, accuracy-level cap, talent bonus, symmetric aggro
radius). See `patches/patches.sh` for the authoritative
`PHASE_BEGIN_PATCHES["beta"]` list.

This makes beta the canonical "what does the project look like
with all custom changes applied" build. Release applies a curated
subset, vanilla applies almost none, alpha applies the minimum
compile-fix set.

## E-patches (post-compile setup)

Beta applies the wide E-patch set:

- E001 (Lua script symlinks, pointing at `src/lua-beta/`)
- E004 (RAM-backed log directory)
- E005 (DK levelstats — the database support for the DK class)
- E006 (config file initialization)
- E011-E017 (DK class system, drop-creatures, quest-spells, trainer
  spell level cap, class selector NPCs, empty loot chests,
  playerbots logout-texts migration fix)

The destructive E-patches (E012 drop-creatures, E014 trainer-spell
cap) are why beta's worldserver looks the way it does — almost
empty open world with the ambush system replacing static spawns.

## Promotion-pipeline position

Beta is where features START. A feature graduates to release once
it's been observed working under realistic load without crashing
or regressing other systems. The promotion process is manual:
edit the C-patch / B-patch / E-patch lists in
`patches/patches.sh` and `config/patches/*.sh` to add `release` to
the feature's profile list.

If you want to play with everything the project does, run beta.
If you want stability, run release.

## How to switch to beta

```bash
echo beta > .profile
./scripts/install --profile beta
./scripts/start-mysql
./scripts/authserver &
./scripts/worldserver
```

Beta shares the `acore_*` databases with release (same schema, same
MySQL port 3307, same auth/world ports 4362/4462) — they can't
run concurrently because they collide.

## Where to ask for help

- The promotion pipeline rules: [`issues/136-canonical-profile-definitions.md`](../../issues/136-canonical-profile-definitions.md)
- Stable wow-chat tier: [release.md](release.md)
- Stock WoW + bots: [vanilla.md](vanilla.md)
- Historical snapshot: [alpha.md](alpha.md)
- ALE Lua scripting reference: [`docs/scripting.md`](../scripting.md)
- The wow-chat design itself: [`docs/concept-catalog.md`](../concept-catalog.md)
- Profile system overview: [index.md](index.md)
