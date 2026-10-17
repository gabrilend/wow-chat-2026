# 136b - Every Profile Running at Once

## Status
- Created: 2026-10-17
- Phase: 1 (Foundation — profile model; see 136 parent)
- Parent: 136 (canonical-profile-definitions)
- Builds on: 136a (unified realmlist: one login, one realm row per profile)
- Priority: High for beta (installing beta empties release's world today)

## Origin

From the 2026-10-17 audit of the beta build. Beta and release share one
world database, so beta's install step that clears the world of creatures
(E012) clears release's too, and release never puts them back. Asked how
the two should switch, the owner answered with the larger design:

> we are going to be able to run multiple at once. When the player
> connects, for each server we have running it shows them in the realm
> select list. Ideally, eventually, we'd run them all at once. They should
> each offer a different experience, and we'll create as many as we can
> think of just because we love the players and want to show more.

So the fix is not a better switch between beta and release. Each profile
becomes a realm that can run beside the others.

## Current Behavior

**Login and realm list (shared, as 136a wants).** Every profile on the
3307 database server logs in through `acore_auth`. Each has its own realm
id (config patch C019: release 1, beta 2, vanilla 3, alpha 4, basic 5,
cc-test 6), so each worldserver writes its own row's status.

**The game's own realm-status handling already supports several realms.**
When the authserver starts it marks every realm offline
(`source-beta/src/server/apps/authserver/Main.cpp`, "Mark every realm
offline on startup"). Each running worldserver clears the offline flag on
its own row every uptime tick (`World.cpp`, "Re-assert this realm as
online"). A client's realm list therefore greys out whatever isn't running,
with nothing more from us.

**Ports (one at a time).** Config patch C010 gives release, beta, vanilla,
basic and cc-test the same pair: worldserver 4462, authserver 4362 (alpha:
4463/4363, on its own database server). Two worldservers on one machine
can't both listen on 4462, so only one of those five runs at a time. Other
listening ports are shared the same way: the SOAP console (C021,
127.0.0.1:7878), and the remote-admin console if it is ever switched on.

**Databases.** Config patch C001:

| Profile  | world                 | characters                 | playerbots                 |
|----------|-----------------------|----------------------------|----------------------------|
| release  | `acore_world`         | `acore_characters`         | `acore_playerbots`         |
| beta     | `acore_world`         | `acore_characters`         | `acore_playerbots`         |
| vanilla  | `acore_world_vanilla` | `acore_characters_vanilla` | `acore_playerbots_vanilla` |
| basic    | `acore_world_basic`   | `acore_characters_basic`   | `acore_playerbots_basic`   |
| cc-test  | `acore_world_cc_test` | `acore_characters_cc_test` | `acore_playerbots_cc_test` |
| alpha    | `acore_world_alpha` (port 3308) | `acore_characters_alpha` | (none)            |

Release and beta share all three, so they share characters too, and beta's
destructive world steps (E012 clears creatures, E014 cuts trainer spells)
change release's world. The `acore_world` there now is beta's: it holds
E012's snapshot table (`wow_chat_e012_snapshot_creature`), which E012's
revert would use to put the creatures back.

**Installed trees and logs** are already per profile
(`installed-files-<profile>/`, `logs-<profile>`), so two servers don't
write into each other's files.

## Intended Behavior

- Every profile has its own world, characters and playerbots databases.
  Release and beta are split: one keeps the existing `acore_*` set, the
  other gets a fresh `_<profile>` set seeded the way basic's and cc-test's
  were (open question 1: which one keeps the old set).
- Every profile's worldserver has its own port, and its realm row in
  `acore_auth.realmlist` names that port. One authserver, on 4362, serves
  every realm; the client's realmlist never changes (136a).
- Every other listening port a worldserver opens is per profile too (SOAP,
  and remote admin if used), or switched off where a profile doesn't need
  it, so no two running servers ask for the same one.
- Starting a profile's worldserver doesn't need any other profile stopped.
  The realm list shows every realm, online or greyed out, as the game
  already does.
- A test checks the whole table, so a new profile can't reuse another's
  port or databases: for every pair of profiles on the same database
  server, no port and no database name is shared (auth excepted, which is
  meant to be shared).

## Suggested Implementation Steps

1. **Decide the ports** (open question 2) and write them as one table in
   C010, keyed by profile, with the reason for the scheme in a comment.
2. **C001:** give the profile that moves (question 1) its own `_<profile>`
   databases, in the same table style as basic and cc-test.
3. **C021 (SOAP):** one port per profile, or SOAP only where something
   uses it (the CLI console scripts do; check `scripts/gm-command`).
4. **Realm rows:** the install step that writes `realmlist` (C011 /
   136a's work) writes this profile's row with this profile's port, and
   leaves the other rows alone.
5. **Seeding:** the new databases are created and filled by the install
   script's existing path (`scripts/install`, the `CREATE DATABASE IF NOT
   EXISTS` block, then the server's own auto-setup), as basic's were.
   Check that beta's E-patches (E005, E011–E017) run against the new world
   and never against the old one.
6. **Release's world back to stock:** if release keeps `acore_world`,
   E012's revert runs once against it (its snapshot table is there), or
   release's world is re-imported fresh (question 3).
7. **Test:** `scripts/test-profile-isolation` — reads C001, C010 and C021
   for every profile (the real patch scripts, on scratch copies, as
   `scripts/test-profile-config-gates` does) and fails on any shared port
   or database. Add it to the compile's quick tests.
8. **Docs:** the profile pages (`docs/profiles/*.md`) state each profile's
   port and databases; `docs/profiles/index.md` gets the "running several
   at once" section and drops "they can't run concurrently".

## Open Questions

1. When release and beta are split, which keeps the existing `acore_*`
   databases (and the characters in them)? Beta was the last one
   installed, so the world in them is beta's.
2. What port scheme? For example 4462 + (realm id − 1) × 10 (release 4462,
   beta 4472, vanilla 4482, basic 4502, cc-test 4512), which leaves room
   between them for each profile's other ports. Or something else you
   prefer.
3. Release's world: undo beta's changes with E012's saved snapshot, or
   import a fresh one?
4. How many can this machine run at once? Each worldserver loads its own
   maps and bots (beta's 500 random bots among them); this decides which
   profiles are on by default and which are started on demand.

## Related

- 136 (parent), 136a (unified realmlist; its "only one runs at a time"
  becomes "each runs on its own port" once this lands)
- 138 (sql-profile-switch-rollback): switching becomes less needed when
  nothing has to be switched off
- 147 (alpha-mysql-instance-isolation): alpha's separate database server
- 157 (three-machine deployment): where each realm runs when they are
  spread over machines
- 176 (cc-test profile): its question 4 asked whether cc-test gets its own
  port; this answers it for every profile
- `docs/profiles/beta-roadmap.md`: this is step 1 of bringing beta back
