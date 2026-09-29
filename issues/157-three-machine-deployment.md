# 157 - Three-Machine Deployment

## Status
- Created: 2026-09-23
- Phase: 1 (Foundation — the server runs)
- Priority: High. This is the cheap answer to "the server is slow", and it
  has to be measured before the expensive answer (913) is considered
- **Blocks:** 913b

## Overview

Three mini-computers sit on the same router. Each takes one role:

| Machine role | Runs | Listens on |
|---|---|---|
| database | the project's MySQL | 3307, LAN only |
| auth | authserver; later the 913e scheduler | 4362, forwarded from the router |
| world | worldserver, playerbots, Lua scripts | 4462, forwarded from the router |

The development machine keeps building. The mini-computers only run what
it ships to them. The game client connects to the auth machine, gets the
world machine's address from the realm list, and plays there. The world
and auth machines both reach the database over the LAN.

This does not split the world. Everything the worldserver does stays in one
process. It takes the database's disk and memory, and the authserver's
work, off the machine that runs the world.

## Current Behavior

- Everything runs on one machine. MySQL listens only on 127.0.0.1:3307
  (`mysql/conf/my.cnf`, `bind-address = 127.0.0.1`).
- Every database connection string is written with host 127.0.0.1 by the
  config patch `config/patches/C001-database-connections.sh`
  (`DB_HOST="127.0.0.1"`).
- The realm list's address is set to the machine's own public address by
  `scripts/update-realmlist-ip`, on the assumption that the authserver and
  the worldserver are the same machine.
- `installed-files-<profile>/bin/lua_scripts/custom` is a symlink into this
  machine's checkout (`/home/ritz/...`), which will not exist anywhere else.
- Issue 154 makes the project installable on a second computer, but has
  never been run on one.

## Intended Behavior

One command on the development machine deploys the active profile to the
three machines, starts each role, and reports each role's health: port
open, database reachable from auth and world, realm list pointing at the
world machine. Players outside the house reach the game through the
router exactly as before.

## Sub-issues

| ID | Name | Dependencies | Description |
|---|---|---|---|
| 157a | role-hosts-file | None | One file naming which machine plays which role: LAN address, ssh user, CPU architecture |
| 157b | deploy-tool | 157a | The one command: ship, start, stop, health-check each role over ssh |
| 157c | database-address-in-config | 157a | Config patches and scripts read the database host from the roles file instead of assuming 127.0.0.1 |
| 157d | database-machine | 157b, 157c | MySQL on its own box, listening on the LAN, grants for the two server machines only, data moved over |
| 157e | auth-machine-and-router | 157b, 157c | authserver on its box; realm list points at the world machine; router forwards two ports to two machines |
| 157f | world-machine | 157b, 157c | worldserver plus its map data, Lua scripts and module configs on its box |

**Why split:** each role can be brought up and checked on its own, and
the database move is the one step that carries risk to player data, so it
gets its own issue and its own test.

**Order:**
`157a → 157b, 157c (parallel) → 157d → 157e, 157f (parallel)`

## Implementation Steps

1. Complete the sub-issues in the order above.
2. Run 913b's measurement before and after, so the report shows what the
   split changed.
3. Write `docs/deployment.md`, the datapath for a login across three
   machines, and add it to `docs/table-of-contents.md`.

## Open Questions

1. What CPU architecture and operating system do the mini-computers run?
   If they match this machine (x86-64 Linux, same library versions), the
   built binaries can be copied. If not, each one builds from source
   through issue 154.
2. Are the mini-computers on fixed LAN addresses, or should the router
   reserve addresses for them?
3. Does the development machine stay a fourth place where the server can
   run (for testing), or does it only build from now on?

## Related
- `issues/154-portable-dependency-bootstrap.md`: installing the toolchain on a
  new machine
- `issues/completed/105-project-local-database`
- `issues/completed/113-authserver-ip-caching.md`
- `issues/107-credential-manager-script`
- `issues/913b-connectivity-reliance-improvements-required.md`
