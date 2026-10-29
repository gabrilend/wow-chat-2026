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

A profile is defined in several places by hand (the update, install and
profiles scripts' tables, `_profile_db_name` in the install helpers, the
patch groups, its config patches), and built from source by the owner's
compile. There is no way to make a new realm from an existing one's
state.

## Intended Behavior

- **A branch is a new realm made from a living one, on demand**:
  `scripts/branch-realm SOURCE NAME` takes the source profile's installed
  server (linked, not copied, where it can be: the binaries are the
  same) and its databases as they are at that moment (world, characters,
  bots: copied table by table into `acore_*_<name>`), gives it a realm
  entry of its own (its own port), its own config (the source's, with the
  databases, port and realm id changed), and records it as a branch of
  SOURCE.
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
