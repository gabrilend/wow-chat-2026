# 157a - Role Hosts File

## Status
- Created: 2026-09-23
- Parent: Issue 157 (three-machine-deployment)
- Phase: 1
- **Blocks:** 157b, 157c

## Overview

One file says which machine plays which role. Every script that needs to
reach the database, ship files, or set the realm list reads it, so moving a
role to a different machine is a one-line change.

## Current Behavior

- There is no such file. Host addresses are written into individual
  scripts and config patches as 127.0.0.1.

## Intended Behavior

`config/deploy-hosts.lua`, a Lua table. Configuration lives in code
structure, per the project's style:

| Field | Datatype | Meaning |
|---|---|---|
| role name (key) | string: `database`, `auth`, `world` | which job the machine does |
| `lan_address` | string, dotted IPv4 | address on the home network |
| `ssh_user` | string | account the deploy tool logs in as |
| `install_dir` | string, absolute path | where the project lives on that machine |
| `arch` | string, e.g. `x86_64` | checked against the build machine before shipping binaries |

A role named `local` means the development machine itself, so the file
also describes today's single-machine setup, with all three roles set to
`local`.

## Implementation Steps

1. Write the file, with all three roles set to `local` to start with.
2. A reader tool that prints one field for one role. Bash scripts call it
   instead of parsing Lua themselves.
3. A validator that rejects duplicate addresses for different roles only
   when that's a mistake. Two roles on one machine is allowed.

## Open Questions

1. The machines' LAN addresses and ssh users: to be filled in by the owner.

## Related
- `issues/157-three-machine-deployment.md`
