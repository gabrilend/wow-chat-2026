# 157a - Role Hosts File

## Status
- Created: 2026-09-23
- Parent: Issue 157 (three-machine-deployment)
- Phase: 1
- **Blocks:** 157b, 157c, 157g
- State: built 2026-11-06 (every role "local"; the machines are the owner's to fill in)

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

## Decisions, 2026-11-06 (an agent, building it)

Built: the roles file, `config/deploy-hosts.lua`, with all three roles
`"local"`; the reader, `scripts/deploy-host [DIR] <role> <field>` (and
`--check`), over the checker `scripts/lib/deploy-hosts.lua`; and the quick
test `scripts/test-deploy-hosts` (the project's file, every mistake the
checker names, the tool's answers and refusals on small project folders;
33 of 33 mutants caught). Question 1 (the machines' addresses and users)
stays the owner's: the file says so, and nothing changes until it is
filled in.

1. **A local role** is the string `"local"`; a machine is a table of
   exactly the four fields. Asked for a local role's fields, the reader
   answers this machine's: address `127.0.0.1` (as 157c expects), an empty
   ssh user (no ssh: 157b runs local roles directly), the project folder,
   and `uname -m`. An extra field, `local`, answers `yes` or `no`, so
   157b can ask it directly.
2. **When a shared address is a mistake** (step 3): two or three roles on
   one address are one machine, which is allowed; it is a mistake only
   when they name different architectures (one machine has one). A
   loopback address (127.x) for a machine is refused too: that role should
   be `"local"`.
3. **Safety**: the file is run with nothing to call, so it can only build
   its table; a compiled (bytecode) file is refused; any mistake makes the
   reader answer nothing, so a bash script never acts on half a file.
4. **Field rules**: dotted IPv4 with no leading zeros; user names of
   lower-case letters, digits, `_` and `-` (up to 32, not starting with a
   digit); install folders absolute, not `/`, without `..` or spaces;
   architectures x86_64, aarch64, armv7l, i686 (more are one line in
   `Hosts.ARCHES`).
