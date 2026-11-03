# 157g - Linode Machines, One per Realm

## Status
- Created: 2026-10-26
- Parent: Issue 157 (three-machine-deployment)
- Phase: 1 (Foundation — the server runs)
- **Blocked by:** 157a, 157b, 157c, 136b, 157i, 157j (the roles file,
  the deploy tool, the database address in config, every profile running
  at once, the machines' own minimal Linux, the login database's door)
- **Blocks:** 157h, 157k, 1008f

## Origin

The owner, 2026-10-26:

> can we make part of the build promotion from shadow to main that we also
> push it to my linode instance and restart the server and all that? I want
> to be able to run every single realm at once, so we should design all of
> our issue plans as if each realm profile is built in parallel. I want the
> system to be running 24/7 and I want to put the connection details on my
> website.

And, answering this issue's first draft (which put everything on one
rented machine):

> ideally, three or more separate machines, each running their own duties.
> ...
> oh and we'll be spinning up multiple new machines, one for each profile.

On the operating system:

> anything we'd like. as close to minimal linux as we can, the better. I
> prefer runit over systemd, with individual modules replacing monolithic
> software. but that's just a preference thing...

On the address: `wow.ritzmenardi.com` "stays with my computer since it's
me". The Linode machines get names of their own: "we will come up with a
name...".

On the databases:

> each machine should have any database it contacts located on it's own
> machine, to increase the data processing speed and improve reliability.
>
> the auth database however can exist on it's own device, hardened
> against any outside connection, making it difficult to hack. We must
> also use an instruction oriented transmission format.

On the system: "we shouldn't use Void. We should roll our own Linux
system, with only the exact components we use. It should be
incomprehensibly lean, 100% minimal slack." (157i)

This changes 136b's decision of 2026-10-17 ("no more than one" realm at a
time). That decision was about the development machine, and it still holds
there. The rented machines are where every realm runs at once.

## Overview

The public game runs on rented Linode machines, each doing one duty, all
day:

| Machine | Count | Runs | Listens to the internet on |
|---|---|---|---|
| auth | one | the authserver (one login and one realm list for every realm, 136a) | the authserver port |
| login database | one, hardened | MySQL with `acore_auth` only, behind the instruction door (157j) | nothing: the login and realm machines reach the door over Linode's private network |
| realm | one per public profile | that profile's worldserver, its bots, its Lua scripts, its map data, its journal folder (1008b), and its own MySQL with its world, characters and playerbots databases, reached through a local socket | that realm's worldserver port |

A player's client asks the auth machine for the realm list, which names
each realm machine's address and port; the client then plays on that
realm's machine. Adding a realm is adding a machine and a line in the
roles file (157a); it never touches another realm's machine.

The development machine builds; the rented machines only run what they
are sent (157h). `wow.ritzmenardi.com` stays the owner's own computer.

## Current Behavior

- No Linode machine is named anywhere in the project.
- Every realm is built, installed and run on the development machine, one
  at a time (136b).
- Nothing restarts a server that crashed, and nothing starts the servers
  when a machine boots: `scripts/authserver` and `scripts/worldserver` are
  started by hand in a terminal.
- Ports: release, beta, vanilla, basic and cc-test all ask for worldserver
  port 4462 (config patch C010). On machines of their own they no longer
  collide, so 136b's port scheme matters only for this machine and for
  telling realms apart at a glance.

## Intended Behavior

**Operating system: our own, built by 157i.** Each machine boots an
image holding the kernel, runit, and exactly the files its one duty
loads, nothing more.

**Each server is a runit service.** A service is a folder,
`/etc/sv/<name>/`, holding:

- `run`: a short script that starts the server in the foreground (runit
  watches it; if it exits, runit starts it again after a second);
- `finish`: runs after each exit; writes a line to
  `logs-<profile>/restarts` (when, the exit status, the last 20 lines of
  the server log) and sleeps longer each time the server fails in a row,
  so a server that cannot start does not spin;
- `log/run`: `svlogd`, runit's own small logger, keeping rotated logs.

Linking the folder into `/var/service/` starts it now and at every boot.
The services: `wow-auth` (login machine); `wow-login-db` and
`wow-login-door` (login-database device); `wow-mysql` and
`wow-world-<profile>` (each realm machine). Their folders live in this
project, `config/services/`, and the deploy tool writes them onto the
machines; nothing is set up on a machine by hand.

**Memory sized per realm.** Each realm machine's plan is chosen from that
realm's measured use: worldserver at rest and with its bots on, measured
here by `scripts/measure-realm-memory` (the owner runs it: it starts
servers). A realm with many bots gets a bigger machine than cc-test.

**Reachable from outside, and nothing else.** Each machine's firewall
opens only its own duty's port and ssh. MySQL, SOAP and remote admin
listen on Linode's private network or 127.0.0.1 only.

**The connection details have one source.** The auth machine's name and
port, and each realm's name, machine and port, are written by
`scripts/write-connection-details` from the roles file and C010, into
`tmp/shared-memory/connection-details.md`, which 1008f puts on the
website. Nobody types a port into the website.

**Guest accounts** (1003's public names and passwords) "can be kicked off
whenever" (owner, 2026-10-26): a realm restarting or full does not wait
for them.

## Suggested Implementation Steps

1. Answer the open questions below.
2. The roles file (157a) gains a list of machines per role: one auth, the
   database(s), one realm machine per public profile, each with its
   Linode name, private address, ssh user.
3. The machine images, from 157i's tool; the login database's door,
   from 157j.
4. The runit service folders in `config/services/`, written by the deploy
   tool's `ship` action (157b).
5. Databases: once players are on the rented machines, those databases
   are the live ones. They are created once from the development
   machine's (157d's move, with a checksum of every table before and
   after), and after that the development machine never overwrites them.
   Updates reach them only as SQL the server applies itself (189d).
6. `scripts/write-connection-details`, with a first line saying what made
   the page.
7. Test: `scripts/test-every-realm-has-its-own-port` (136b's isolation
   test) over the public profiles, and a check that each realm machine in
   the roles file names exactly one profile.
8. Datapath: `docs/datapaths/deployment.md` (157's step 3), with the
   auth, database and realm machines and the login path across them.

## Open Questions

1. ~~The database~~. Answered 2026-10-26: each realm's databases on its
   own machine; the login database on a hardened device of its own (157j).
2. **Names.** The owner will choose the name players type into
   `realmlist.wtf`. Until then the roles file holds a placeholder, and
   the connection page is generated from it.
3. ~~Void on Linode~~. Answered 2026-10-26: our own system (157i).
4. ~~ssh~~. Answered 2026-10-26: no ssh; "rmail only. the recipient
   decides what to do with it." (157h)
5. ~~Which profiles are public~~. Answered 2026-10-28: "right now, none,
   I will tell you when we're getting ready for release." The roles file
   lists no public realm until then; the connection page stays a preview.

## Related
- `issues/157-three-machine-deployment.md` (parent), 157a, 157b, 157c, 157d
- `issues/136b-every-profile-running-at-once.md`: ports and databases per
  realm
- `issues/136c-every-profile-built-at-once.md`: building them in parallel
- `issues/157h-promotion-ships-to-the-host.md`: what puts a new build on
  a realm machine
- `issues/1008-journals-of-what-each-player-saw.md`: the journals live on
  the realm machines
- `issues/157i-a-linux-of-only-what-runs.md`,
  `issues/157j-the-login-database-behind-an-instruction-door.md`
- `issues/154-portable-dependency-bootstrap.md`
- `issues/158-player-machine-safety-before-public-release.md`
