# 157i - A Linux of Only What Runs

## Status
- Created: 2026-10-26
- Parent: Issue 157 (three-machine-deployment)
- Phase: 1 (Foundation — the server runs)
- **Blocked by:** 157i1 (each part built on its own, and cached)
- **Blocks:** 157g, 157h, 157k

## Origin

The owner, 2026-10-26, on which system the rented machines run:

> anything we'd like. as close to minimal linux as we can, the better. I
> prefer runit over systemd, with individual modules replacing monolithic
> software.

and, when Void Linux was proposed:

> we shouldn't use Void. We should roll our own Linux system, with only
> the exact components we use. It should be incomprehensibly lean, 100%
> minimal slack.

And on building it: "each component should have it's own compile
script. We should create utilities that are able to be cached, and only
recompiled when something part of them changes. And then, only that
part, not the unchanged whole." (157i1)

## Overview

Each rented machine boots a system built here, by a tool, that holds the
Linux kernel and the files its one duty uses, and nothing else: no
package manager, no compiler, no manual pages, no spare programs. What
"uses" means is measured, not guessed: the tool starts from the duty's
programs and follows what they load.

## Current Behavior

Nothing builds a system image. Measured 2026-10-26 on the development
machine: the worldserver binary loads 18 shared libraries (`ldd
installed-files-basic/bin/worldserver`): the C and C++ runtimes, OpenSSL,
the MySQL client library, readline and ncurses (for the console), ICU
(text handling, three libraries, the largest), and five compression
libraries. The authserver loads 17.

## Intended Behavior

### What goes in, per duty

| Part | Realm machine | Login machine | Login-database device (157j) |
|---|---|---|---|
| kernel | Linux, configured with only the virtual hardware Linode presents (virtio disk and network), ext4, IPv4/IPv6, and the firewall | same | same |
| first program (PID 1) | `runit-init` | same | same |
| supervision | `runsv`, `runsvdir`, `svlogd` (runit's small parts) | same | same |
| the duty | worldserver, its libraries, its configs, Lua scripts and LuaJIT, map data (dbc, maps, vmaps, mmaps) | authserver, its libraries, config | MySQL server and the instruction door (157j) |
| databases | MySQL server with this realm's world, characters and playerbots, reached through a local socket, no network port | none | `acore_auth` |
| network setup | a fixed address, written into the image | same | same |
| remote access | none over the network: releases arrive by rmail and the machine decides (157h); rmail's daemon answers only the development machine. One way in for the owner: a login on the serial console, which Linode's own console (Lish) reaches, for replacing a lost signing key (157h) | same | rmail from the development machine only, over the private network path 157h sets |

Everything else is left out. A program that is only needed once (making
the databases at first start) runs from the development machine through
the deploy tool, not from the image.

### How the list is made

Every program and library in an image is a part compiled here, by its
own script, and cached (157i1); nothing is taken from the development
machine's own system. `config/machine-images/<duty>.lua` names, per
duty, the starting points only: the programs to run and the data
folders to carry. The tool `scripts/build-machine-image <duty> [profile]`:

1. follows each program's library needs (the dynamic loader's own
   answer, as `ldd` prints it, run against the part outputs) until
   nothing new appears, and fails if a need is met by no part;
2. copies exactly those files from the part outputs, the data folders, the runit parts and the
   duty's service folder (157g) into a root folder in RAM
   (`tmp/shared-memory/machine-images/<duty>/`);
3. writes a manifest beside it: every file, its size and its BLAKE2b
   fingerprint, and the total;
4. packs the root folder and the kernel into a disk image Linode can
   boot.

The tool reports, per duty, the size of the image and the five largest
files, so slack is visible. Shrinking happens by changing the build
(for example a worldserver built without the console's readline, or ICU
data cut to the languages used), each such change an issue of its own.

### Proving it boots

`scripts/test-machine-image <duty>` boots the image in QEMU on this
machine, waits for the duty's port to answer, stops it, and writes a
goodbye receipt (seconds to answer, image size, file count).

## Suggested Implementation Steps

1. `config/machine-images/realm.lua`, `login.lua`, `login-database.lua`:
   the starting points.
2. `scripts/build-machine-image`: the closure, the root folder, the
   manifest. Test: for a small program with a known library list, the
   closure equals that list.
3. The kernel configuration, `config/machine-images/kernel.config`, built
   by a script from Linode's documented virtual hardware; the kernel is
   compiled by the owner (it is a long build).
4. runit as the first program, the service folders, the fixed network
   setup.
5. `scripts/test-machine-image` in QEMU.
6. Upload to Linode as a custom image (the deploy tool, 157b).

## Open Questions

1. ~~How do new releases reach a running machine?~~ Answered
   2026-10-26: "rmail only. the recipient decides what to do with it."
   Each image carries rmail and its receive hook, and no ssh (157h).
2. ~~The C library~~. Answered 2026-10-26: "excellent, better to support
   both". glibc and musl are each a part, and every part built against a
   C library is built once per C library (the C library's key is in its
   key, 157i1), so each image can be made either way and the two compared
   by size and by a running realm. Patches that musl needs (MySQL and
   AzerothCore may need some) are B-patches like any other, gated to the
   musl build.
3. ~~Linode's own kernel or ours~~. Ours: the kernel is a part like any
   other (157i1), configured with only what the machines use.

## Related
- `issues/157i1-each-part-built-on-its-own-and-cached.md`
- `issues/157k-realms-closed-until-you-log-in.md`: the firewall rules each
  image carries
- `issues/157g-linode-machines-one-per-realm.md`
- `issues/157h-promotion-ships-to-the-host.md`
- `issues/157j-the-login-database-behind-an-instruction-door.md`
- `issues/154-portable-dependency-bootstrap.md`
