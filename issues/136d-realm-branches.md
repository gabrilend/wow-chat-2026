# 136d - Realm Branches

## Status
- Created: 2026-10-28
- Phase: 1 (Foundation)
- Parent: 136 (the profiles' definitions)
- Related: 136b (every profile running at once), 1100e (the realm locked
  to game masters while testing), 617o7 and 617e17 (the first branch: the
  pathfinding test realm)
- Priority: High
- State: in progress (planning)

## Origin

The owner, 2026-10-28, asking for a test profile for the pathfinding work:
"Can you spin up a test-profile real quick and build out everything by
copying the build from a different compilation, and then applying the
modification patches you need to get it modified to your position?" And,
asked whether to copy basic or reuse a realm:

> this system should be flexible, able to create branches off of any
> living database. Like git, but dynamic instead of stored.

## Current Behavior

**Built 2026-10-28.** `scripts/branch-realm SOURCE NAME` makes a branch:
the source's three databases (world, characters, bots; their names read
from the source's installed settings) dumped in one transaction each and
streamed straight into new ones named for the branch, and a realm-list row
copied from the source's with the next free id, offline, game masters
only. A failure drops every database that run made and says what was
copied before it. The branch is a line in `config/branches` (name, source,
realm id, when made); `--list` shows them, `--drop NAME` deletes a
branch's databases, its realm row and its line. Nothing of the server is
copied: `scripts/worldserver --profile NAME` runs the source's installed
server with environment settings the server reads in place of its files'
(`AC_WORLD_DATABASE_INFO` and the other two connections, each the
source's own with only the database name changed, so no password is
written anywhere new; `AC_REALM_ID`; `AC_LOGS_DIR`, logs-NAME; and
`AC_BUDDIES_TEST_REALM=1`, which opens the buddy module's test-only
commands), and `scripts/set-active-realm` finds a branch's realm id in
the branch list. One realm runs at a time: the launcher stops any other
world server first.

The first branch, `pathtest` from basic (realm 7), took 25 minutes
(1,513 s), most of it the world database. The first try failed on MySQL's
own transaction ids carried in the dump (ERROR 3546), now left out of it.

Its test, `scripts/test-branch-realm` (2026-10-29), runs by hand, not
among the compile's quick tests, since it writes to the live MySQL. It
makes a pretend realm (three databases of three rows each, settings files
in a folder of its own under tmp/, a realm entry), branches it, and checks:
- the rows are copied;
- the branch gets a realm entry of its own, offline and for game masters
  only;
- the branch's line is in the list;
- a second branch onto the same name is refused, with nothing made;
- dropping the branch removes all of it and leaves the source as it was.

It then removes everything it made. 13 checks, all passing.

Not built: making a branch faster (copying the world database's files
rather than replaying it row by row).

## Intended Behavior

- **A branch is a new realm made from a living one, on demand**:
  `scripts/branch-realm SOURCE NAME` copies the source profile's
  databases as they are at that moment (world, characters, bots, into
  `acore_*_<name>`), gives it a realm entry of its own (game masters only,
  for testing), and records it in `config/branches` (name, source, realm
  id, when). Nothing of the server is copied: a branch runs its source's
  installed server, told by environment overrides (the server reads
  `AC_<SETTING>` for any setting, module settings included: its databases,
  its realm id, its logs folder) that it is the branch. (The server reads
  module settings from the folder compiled into it, so a copied settings
  file alone would have left the branch on its source's bot database;
  found 2026-10-28 in `Config.cpp`'s `GetConfigPath`.)
- **Running one**: `scripts/worldserver --profile NAME` finds NAME in the
  branch list and starts its source's server with the overrides;
  `scripts/set-active-realm NAME` flips its realm online. One realm runs at
  a time on this computer (the launcher stops any other first), so a
  branch runs instead of its source, on the same ports.
- **Dynamic, not stored**: a branch is cheap to make and to throw away
  (`scripts/branch-realm --drop NAME`), made again from the source's
  living state whenever wanted; nothing about it is written into the
  profile tables by hand. The profile tools read the branch list
  (`config/branches`: name, source, made when) and treat a branch as its
  source for everything a build needs (its patch lists, its Lua folder).
- **Changes on top**: the branch's own install steps (config, SQL, Lua)
  can be applied to it after the copy; a C++ change still needs a build,
  which the branch takes from its source's next compile.
- Locked to game masters while testing (`scripts/test-lock`).

## Suggested Implementation Steps

1. The branch list and the tool: link the install, copy the databases
   (MySQL's own copy, `mysqldump | mysql`, per database), write the
   realm entry and config.
2. The profile tools read the branch list (a branch's profile name
   resolves to its source for patch lists and Lua).
3. `--drop`, `--list`; a quick test on a tiny made-up profile.
4. The first branch: `pathtest` from basic.

## Open Questions

1. **"dynamic instead of stored"**: read here as made on demand from the
   living source and thrown away freely, rather than kept as stored
   snapshots. Or should a branch stay live-linked to its source (reading
   the source's world while keeping only its own characters)?
