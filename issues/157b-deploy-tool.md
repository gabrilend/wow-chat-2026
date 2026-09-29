# 157b - Deploy Tool

## Status
- Created: 2026-09-23
- Parent: Issue 157 (three-machine-deployment)
- Phase: 1
- **Blocked by:** 157a
- **Blocks:** 157d, 157e, 157f

## Overview

One command that copies the built server to the machines named in the
roles file, starts or stops each role there, and says whether each role
is healthy. Nothing is set up on a mini-computer by hand; if a step is
needed, it goes into this tool.

## Current Behavior

- `scripts/azerothcore`, `scripts/start-mysql` and `scripts/stop-mysql`
  start the roles on the local machine only.

## Intended Behavior

`scripts/deploy [DIR] <action> [role]` with these actions:

| Action | What it does |
|---|---|
| `ship` | rsync the role's part of `installed-files-<profile>/` (and, for world, the map data and Lua scripts) to that machine over ssh |
| `start` / `stop` | run the role's existing start script on its machine |
| `status` | per role: process running, port listening, database reachable from it; one line each, stating what was checked and what passed |
| `logs` | copy the role's current log into the local `tmp/shared-memory/deploy/<role>/` |

Roles set to `local` in the roles file run locally with no ssh, so the
tool works today on one machine.

## Implementation Steps

1. Build `status` first. It is read-only, so it's safe to run anytime.
2. `ship`, with a dry-run mode that lists what would be copied.
3. `start` / `stop`, calling the existing scripts on the far machine.
4. `logs`.
5. A test that runs every action against a roles file with all roles set
   to `local`.

## Open Questions

1. Do the mini-computers already accept ssh from the development machine
   with a key?

## Related
- `issues/157a-role-hosts-file.md`
- `scripts/azerothcore`, `scripts/start-mysql`
