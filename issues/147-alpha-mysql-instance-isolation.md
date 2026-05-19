# 147 - Alpha MySQL Instance Isolation

## Status
- Created: 2026-05-14
- Phase: 1 (Foundation — infrastructure)
- Priority: Low (alpha is a holiday relic; this lights up only when alpha needs to coexist with release)

## Problem

The C001 (database-connections) patch declares that the **alpha** profile
talks to MySQL on **port 3308**, while release and beta share port 3307.
This is the right separation policy — alpha runs an old AzerothCore core
with an incompatible schema, so the two profiles' databases must never
share an instance.

But the **project-local MySQL install at `mysql/installed-files/` only
listens on port 3307**. There is no MySQL process bound to 3308 today, so
trying to start an alpha build will fail to connect.

This issue tracks the work needed to make the alpha MySQL endpoint real.

## Two Implementation Paths

### Path A — Multi-port on the existing MySQL

MySQL supports binding to multiple ports through `extra-port` in `my.cnf`
or by configuring multiple `[mysqld]` listeners. The same `mysqld`
process serves both 3307 and 3308; databases are still namespaced by
suffix (`acore_world` vs `acore_world_alpha`).

**Pros:** One MySQL process, one set of binaries, simpler ops.
**Cons:** Crash on one profile takes down the other. Hard to upgrade
alpha's old-schema needs independently of release's modern-schema needs.

### Path B — Second MySQL instance

A separate `mysql-alpha/` install dir with its own `mysqld`, its own
config, its own data dir. Bound to 3308. Possibly an older MySQL version
appropriate to the AzerothCore vintage alpha tracks.

**Pros:** Full isolation — alpha can crash, get corrupted, get rolled
back, without touching release. Lets alpha live in its own era
(potentially with a period-appropriate MySQL release).
**Cons:** Two MySQL installs to maintain, two backup jobs, ~2x the disk
and RAM footprint.

**Recommendation: Path B**, consistent with alpha being a wholly-isolated
holiday relic. The cost is small (alpha runs ~1 week per year by intent)
and the isolation is the point.

## Current Behavior

- `mysql/installed-files/` listens on 3307 only.
- C001 has been updated to declare port 3308 for alpha, but the endpoint
  doesn't exist, so a fresh alpha worldserver fails to connect.
- Release and beta are unaffected (still on 3307, still functional).

## Intended Behavior

Following Path B:

- A second project-local MySQL at `mysql-alpha/installed-files/` listens
  on 3308.
- Initialized with the alpha-era databases:
  `acore_auth_alpha`, `acore_world_alpha`, `acore_characters_alpha`.
- `scripts/start-mysql` and `scripts/stop-mysql` learn a `--profile`
  flag (or default to starting both instances when no flag given).
- The boot sequence for the alpha profile starts mysql-alpha alongside
  the worldserver.

## Suggested Implementation Steps

1. **Choose the MySQL version** for the alpha era. If alpha tracks
   AzerothCore from before 2023, MySQL 5.7 may be the appropriate match.
   Otherwise the same 8.x as the release install.
2. **Set up `mysql-alpha/`** parallel to `mysql/`: download, extract,
   `mysql_install_db`, custom `my.cnf` with `port=3308` and the alpha
   data dir.
3. **Initialize alpha databases**: create `acore_auth_alpha`,
   `acore_world_alpha`, `acore_characters_alpha` with the appropriate
   alpha-era SQL schemas.
4. **Extend MySQL scripts**:
   - `scripts/start-mysql` accepts `--profile alpha|release|beta` (or
     `--all`) and starts the matching instance.
   - `scripts/stop-mysql` likewise.
   - `scripts/mysql-client` connects to the right port automatically
     based on `${PROFILE}`.
5. **Update `scripts/authserver` and `scripts/worldserver`** to ensure
   the right MySQL is running before launching the server (the
   "auto-start MySQL" logic from completed issue 143).
6. **Document in CLAUDE.md** that alpha uses port 3308 and a separate
   MySQL instance.

## Affected Files

- New: `mysql-alpha/` directory tree
- Modified: `scripts/start-mysql`, `scripts/stop-mysql`,
  `scripts/mysql-client`, `scripts/authserver`, `scripts/worldserver`
- Documentation: `CLAUDE.md`

## Related Issues

- **136** canonical-profile-definitions — establishes alpha as the
  isolated holiday-relic tier; this issue implements the database side
  of that isolation.
- **C001 (config/patches/C001-database-connections.sh)** — declares the
  port split that this issue makes real.
- **C010 (config/patches/C010-network-ports.sh)** — does the equivalent
  port split for the server ports (release/beta on 4362/4462, alpha on
  4363/4463); the database split mirrors that pattern.
- **143** auto-start-mysql-in-server-scripts (completed) — the boot
  pattern that needs to extend to a second MySQL instance.

## Notes

This issue lights up only when someone tries to actually run the alpha
profile. Since alpha is intended for ~1 week per year of nostalgia play,
the work can sit on the shelf until that week approaches. C001 and C010
already declare the intent; this just makes the declaration true.

The deferred nature is intentional. The cost of doing it now (a second
MySQL, more disk, more maintenance) outweighs the benefit until alpha
actually runs.
