# Release Profile

**One-line summary:** The wow-chat custom design at its
proven-working tier — modern AzerothCore + AI playerbots + ALE Lua
engine, only the features that have graduated from beta.

## What you get

The production server intended for ongoing public play. The
wow-chat design layer is loaded, but only the parts that have been
hardened on beta and promoted up. Release is always a strict subset
of what beta does, which is what makes it the "guaranteed-working"
tier.

The wow-chat design itself is documented across many issue files
and the concept catalog
([`docs/concept-catalog.md`](../concept-catalog.md)). Briefly:

- **Empty world by default.** Monsters spawn around players via
  the ambush system rather than as static populations. Treasure
  spawns and traveler NPCs wander.
- **AI companion playerbots.** Same playerbots system as the other
  profiles, integrated with the ambush + travel logic.
- **ALE Lua engine.** The full wow-chat Lua corpus
  (`src/lua-beta/`) runs on this profile via mod-ale.
- **Per-level talent points and ability training.** Ability tomes
  granted by quests rather than only by trainers (see issue 405).

The release-specific cut of the wow-chat design is "what we know
works." For the in-flight experimental cut, switch to beta.

## Installed modules

- **mod-ale** — Lua scripting engine, runs the wow-chat corpus
- **mod-playerbots** — AI companion bots
- **mod-aoe-loot** — area loot for convenience
- **mod-grownup** — character model size scales with level

All four modules track upstream HEAD; release stays current with
upstream AzerothCore improvements.

## Promotion-pipeline position

Release sits at the bottom of the alpha → beta → release pipeline
(though chronologically it's the top — features graduate UP into
release from beta after proving out). A feature is in release if
and only if:

1. It exists in beta.
2. It has been observed working without crashes or regressions for
   long enough to trust.
3. It was explicitly promoted (config patches scope it to
   `release`, B-patches list it in `PHASE_BEGIN_PATCHES["release"]`,
   E-patches list it in `PHASE_END_PATCHES["release"]`).

If a feature is in beta and not yet in release, that's a
deliberate choice — it's still proving out. Don't run release if
you want the latest experimental thing; run beta.

## How to switch to release

```bash
echo release > .profile
./scripts/install --profile release
./scripts/start-mysql
./scripts/authserver &
./scripts/worldserver
```

Release uses the shared `acore_*` databases on MySQL port 3307,
authserver port 4362, worldserver port 4462.

## Where to ask for help

- The promotion pipeline rules: [`issues/136-canonical-profile-definitions.md`](../../issues/136-canonical-profile-definitions.md)
- Active development tier: [beta.md](beta.md)
- Stock WoW + bots experience: [vanilla.md](vanilla.md)
- Historical snapshot: [alpha.md](alpha.md)
- The wow-chat design system overview: [`docs/concept-catalog.md`](../concept-catalog.md)
- Profile system overview: [index.md](index.md)
