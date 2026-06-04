# 136a - Unified Realmlist

## Status
- Created: 2026-06-04
- Phase: 1 (Foundation — profile model; see 136 parent)
- Parent: 136 (canonical-profile-definitions)
- Priority: Medium (affects user-facing client experience)

## Problem

Today every profile owns its own auth port (C010) and its own auth
database namespace (C001 — release/beta share `acore_auth`; vanilla
has `acore_auth_vanilla`; alpha has `acore_auth_alpha`). That isolation
is the right call for *world* and *characters* data — a vanilla
character must not appear under a release login — but it has a painful
side effect on the client:

When the user (or anyone they share an account with) switches the
project's active profile from one to another, the `realmlist.wtf`
on every client machine has to be edited to match the new auth port
(release/beta=4362, vanilla=4364, alpha=4363). The IP is always the
same, only the port changes. Every profile flip is a "go edit your
WoW directory" step that the user shouldn't have to remember.

The realm select screen is the natural place to surface "which profile
is up" — every WoW client already shows a list of realms with online
status icons. A user sees four realms in the list, three greyed-out
(offline), one active, clicks the active one, plays. No file edits.
That's the design this sub-issue lands.

## Current Behavior

- `acore_auth_vanilla.realmlist`: one row pointing to `127.0.0.1:8085`
  (AC's stock default — never updated to the configured worldserver
  port 4464).
- `acore_auth.realmlist`: one row pointing to `wow.ritzmenardi.com:4462`
  (release/beta's intended values).
- Authserver port: 4362 (release/beta) or 4364 (vanilla) — set by C010.
- Worldserver port: 4462 (release/beta) or 4464 (vanilla) — set by C010.
- Client `realmlist.wtf`: must match the active profile's auth port.

So a user with `set realmlist 127.0.0.1:4362` cannot reach a vanilla
authserver listening on 4364, period. The connection refuses at the
TCP layer before any realm-list packet is exchanged.

## Intended Behavior

- One shared `acore_auth` database. All profiles authenticate against it.
  Account credentials portable across profiles; the user logs in once
  and sees every realm.
- One shared authserver port `4362` and worldserver port `4462`. Only
  one of each runs at a time — the active profile owns the ports.
- `acore_auth.realmlist` has one row per profile. All rows point to
  `127.0.0.1:4462` (or the configured public IP for the worldserver).
- The active profile's realm row has `flag = 0` (online); the others
  have `flag = 2` (offline). The client shows all four; only the
  online one is selectable. The greyed-out three communicate
  "these profiles exist, that one is up right now."
- Client `realmlist.wtf` stays at `127.0.0.1:4362` forever. Profile
  switches happen server-side and are visible to the client via the
  realm-status icons.

Trade-off accepted: account state (banned, expansion access, GM level)
becomes shared across profiles. For a single-developer box that's the
correct trade — fewer moving pieces. World data and character data
stay per-profile via the existing `acore_world_<profile>` /
`acore_characters_<profile>` namespacing, so playing a vanilla
character doesn't disturb release content. Alpha can opt out of
the unification by keeping its own MySQL instance on 3308 (the
existing fully-isolated stack).

## Implementation

### 1. C001 — collapse vanilla's auth namespace into the shared one
`config/patches/C001-database-connections.sh`: vanilla case sets
`DB_AUTH="acore_auth"` (no suffix). World, characters, and playerbots
keep their `_vanilla` suffix. Alpha unchanged.

### 2. C010 — collapse vanilla's port pair into the shared one
`config/patches/C010-network-ports.sh`: vanilla case sets
`AUTHSERVER_PORT=4362` and `WORLDSERVER_PORT=4462`. Alpha keeps
4363/4463. Comments updated to reflect the new policy.

### 3. C019 — new patch: per-profile RealmID
`config/patches/C019-realm-id.sh`: maps each profile to its row id
in the unified realmlist table and writes it to
`worldserver.conf:RealmID`. Bidirectional with the row seed below.

```
release → RealmID = 1
beta    → RealmID = 2
vanilla → RealmID = 3
alpha   → RealmID = 4   (alpha stays separate; included for completeness)
```

### 4. `scripts/set-active-realm` — new script
Takes a profile name; flips `flag` on `acore_auth.realmlist`:
- All rows → `flag = 2` (offline)
- The active profile's row → `flag = 0` (online)

Idempotent. Run on every authserver/worldserver launch.

### 5. `scripts/worldserver` and `scripts/authserver` integration
Both scripts call `set-active-realm $PROFILE` before exec'ing the
binary. They also `pkill -f <binary> || true` first so a leftover
process from a previous profile doesn't squat the shared port.

### 6. Realmlist seed
A one-time-per-fresh-DB seed inserts the four realm rows into
`acore_auth.realmlist` if they don't already exist:

```sql
INSERT IGNORE INTO realmlist (id, name, address, localAddress, localSubnetMask, port, gamebuild)
VALUES
  (1, 'Everland Ghostsong (release)', '127.0.0.1', '127.0.0.1', '255.255.255.0', 4462, 12340),
  (2, 'Everland Ghostsong (beta)',    '127.0.0.1', '127.0.0.1', '255.255.255.0', 4462, 12340),
  (3, 'Everland Ghostsong (vanilla)', '127.0.0.1', '127.0.0.1', '255.255.255.0', 4462, 12340),
  (4, 'Everland Ghostsong (alpha)',   '127.0.0.1', '127.0.0.1', '255.255.255.0', 4462, 12340);
```

Wraps into `scripts/set-active-realm` so the seed runs lazily on
first call. Pre-existing rows with conflicting names are preserved
by `INSERT IGNORE`.

### 7. Migrate the existing `acore_auth_vanilla` if non-empty
On a fresh-installed box `acore_auth_vanilla` only carries the AC
auto-default realm row and whatever account got created during the
"Database does not exist, create it?" prompt. Acceptable losses:
the auto-default realm row (we replace it via the seed above), the
test account if any (user can recreate). The DB itself can be dropped
after migration as a cleanup pass.

## Files To Update / Add

| Path | Action | Note |
|---|---|---|
| `config/patches/C001-database-connections.sh` | modify | vanilla DB_AUTH → `acore_auth` |
| `config/patches/C010-network-ports.sh` | modify | vanilla port pair → 4362/4462 |
| `config/patches/C019-realm-id.sh` | add | profile → RealmID mapping |
| `scripts/set-active-realm` | add | flag-flip + lazy seed |
| `scripts/worldserver` | modify | call set-active-realm + pkill predecessor |
| `scripts/authserver` | modify | same as worldserver |
| `installed-files-vanilla/etc/worldserver.conf` | live-apply | re-run C001/C010/C019 |
| `installed-files-vanilla/etc/authserver.conf` | live-apply | re-run C001/C010 |
| `acore_auth.realmlist` | seed | 4 rows |
| `acore_auth_vanilla` | drop | cleanup; data was disposable |

## Implementation Steps

1. Modify C001 vanilla case to use `acore_auth`.
2. Modify C010 vanilla case to use 4362/4462.
3. Write C019 with the profile → RealmID mapping.
4. Write `scripts/set-active-realm` (flag flip + idempotent seed).
5. Modify `scripts/worldserver` to call set-active-realm and pkill.
6. Modify `scripts/authserver` similarly.
7. Apply C001/C010/C019 against the live vanilla install (sed against
   installed-files-vanilla/etc/*.conf).
8. Seed `acore_auth.realmlist` with the four rows.
9. Drop `acore_auth_vanilla` (or leave it idle).
10. Boot vanilla; confirm four realms visible in client realm list,
    "Everland Ghostsong (vanilla)" online, the other three greyed.
11. Switch to release profile (`./scripts/profiles --set release`,
    boot release); confirm the realm list now shows "release" online,
    "vanilla" greyed.

## Open Questions

- **Worldserver port collision** when switching profiles fast: a
  not-yet-shut-down worldserver from the previous profile may hold
  4462. The `pkill -f worldserver || true` in the new profile's
  worldserver script handles this, but it's a hard kill — any
  in-flight saves get interrupted. Worth a graceful shutdown command
  later (the AC `.server shutdown` GM command, or a SIGTERM).
- **Account portability across profiles**: a banned account in
  release shouldn't necessarily be banned in vanilla, but with shared
  `acore_auth.account_banned` it would be. For a single-developer box
  this is fine; if the project ever multi-tenants this design needs
  revisiting.
- **`realmlist.gamebuild = 12340`**: hardcoded as the WotLK 3.3.5a
  build. All profiles use the same client build today. If we ever
  ship a profile against a different build (alpha against 12340 too,
  or some hypothetical TBC profile), the column needs to vary per
  row.
- **Public-IP scenario**: the user's actual public IP gets written
  into `realmlist.address` by `scripts/update-realmlist-ip` for the
  release row. For the unified design, that script needs to update
  every row's `address`, not just `WHERE id = 1`. Small modification.
