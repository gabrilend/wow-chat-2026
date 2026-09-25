# 158 - Player Machine Safety Before Public Release

## Status
- Created: 2026-09-23
- Phase: 1 (Foundation — the server runs)
- Priority: High. **Gates public release.** Nothing here blocks development
  or playing alone; all of it must be done before strangers connect.
- **Blocked by:** 107 (the database password must be rotated first; it is
  the open door through which this server could be turned against players)

## Overview

The concern is not cheating. It is a player's *other* files — documents,
photos, keys, anything their user account can reach — being read, encrypted
or deleted because they played on this server.

There are three routes by which that could happen, ranked by how real they
are:

| Route | How it reaches files | Real risk? |
|---|---|---|
| Game Lua (addons, AIO) | Cannot. Game Lua has no file access beyond the addon's own saved-settings folder (`WTF/` inside the game directory). Worst case: wrecked UI settings, or a fake "enter your password" window (phishing). | Low |
| Memory-corruption bugs in the 3.3.5a client (`Wow.exe`) | A malformed packet from the server makes the client run native code with the player's full permissions. Only a hostile server, or someone tampering with the connection, can send one. | Yes |
| Anything we distribute | A tampered client, launcher, DLL or archive is malware from the moment it is run. | Yes |

The 3.3.5a client was released in 2010 and is no longer patched by its
publisher, so any flaw found since remains in the executable. For *our*
players, the most likely hostile server is **our own server after someone
takes it over** — which is why hardening the server comes first.

## Current Behavior

Checked against the vanilla profile's generated configs
(`installed-files-vanilla/etc/`) on 2026-09-23. Re-derive with
`grep -nE '^(BindIP|Ra\.|SOAP\.|WrongPass\.)' installed-files-<profile>/etc/*.conf`.

- **Database password: public.** See issue 107. Anyone who reads the GitHub
  repository has it.
- **MySQL: already localhost-only.** `mysql/conf/my.cnf` sets
  `bind-address = 127.0.0.1` (issue 157 will change this for the LAN; that
  change must keep it off the public internet).
- **Remote telnet console (RA): disabled**, but its listen address is
  `0.0.0.0`, so re-enabling it would expose it to the world.
- **SOAP remote command interface: enabled**, listening on `127.0.0.1` only.
  Safe from outside, but anything on this machine can issue GM commands
  through it with valid credentials.
- **Login and world servers listen on `0.0.0.0`** (ports 4362 and 4462,
  forwarded from the router per issue 157). This is required; they are the
  game.
- **Failed-login lockout: off** (`WrongPass.MaxCount = 0`). Passwords can be
  guessed without limit.
- **No firewall script** exists in the project.
- **Distribution:** players are told to download the AIO client addon from
  Rochet2's GitHub (`docs/connection-guide.md`). No checksums or signatures
  are published for anything.
- **Transport:** the 3.3.5a protocol only scrambles packet headers; chat
  and everything else crosses the network readable and alterable.
- **AIO:** the server sends Lua source that the client addon runs at login,
  unverified. `docs/connection-guide.md` describes AIO as "display-only" and
  "not a code execution engine", which appears to be inaccurate (see Open
  Questions).
- **No player-side sandboxing guidance** exists.

## Intended Behavior

Before the realm is advertised to strangers, all of the following hold:

1. **The server cannot easily become the attacker.** Password rotated
   (107); MySQL, SOAP and RA reachable only from this machine or the LAN;
   only the login and world ports open to the internet; accounts lock after
   repeated wrong passwords.
2. **We distribute data, never executables.** Players bring their own
   3.3.5a client. We ship only readable Lua (the AIO addon) and data
   archives (MPQ files hold assets, not programs). Every released file has
   a published SHA-256 checksum and a signature made with a key only the
   owner holds.
3. **Players are told how to sandbox the game**, and Linux players are given
   a launcher that does it for them: the game sees only its own folder and
   can only connect to this server's address. A client exploit then wakes
   up in a box holding nothing but WoW.
4. **The known client bugs are researched.** We know which memory-corruption
   flaws in 3.3.5a are public, and whether an inspectable community patch
   exists that can be recommended.
5. **For the friends stage, the connection is encrypted** (WireGuard), so
   nobody on the network path can inject a malicious packet.
6. **Server-sent AIO code is signed**; the player's AIO addon holds the
   public key and refuses unsigned code, so an impersonating server cannot
   push fake login windows.
7. **The connection guide advises backups** — the one protection that covers
   file loss from any cause.

## Implementation Steps

Ordered most valuable to least. Each names where it lives in the patch
system (`config/patches/C*.sh` for config values, `patches/E-patches.sh` for
install-time setup — see the `upstream-patch-system` skill before adding).

1. **Finish issue 107** (rotate the database password; credentials read from
   git-ignored files).
2. **Config patch: remote admin lockdown.** Set `Ra.IP` to `127.0.0.1` so
   the disabled console stays local if ever enabled; decide whether SOAP is
   used by anything (grep `scripts/`) and disable it if not.
3. **Config patch: failed-login lockout.** Set `WrongPass.MaxCount`,
   `WrongPass.BanTime` and `WrongPass.BanType` in `authserver.conf` for every
   profile.
4. **Firewall script** (`scripts/`, not the patch system — it configures
   the operating system). Opens only the login and world ports; states
   which firewall tool it expects and fails loudly if absent. Must agree
   with issue 157's three-machine layout.
5. **Release script**: produces the player download (AIO addon + any MPQs),
   writes a SHA-256 checksum file, and signs it. Add a "verify your
   download" section to `docs/connection-guide.md`.
6. **Sandboxed Linux launcher** (`scripts/`): runs the client under Wine
   inside bubblewrap, with only the game folder mounted and network limited
   to the server's address.
7. **Windows sandboxing guide** in `docs/`: play from a separate standard
   (non-administrator) user account, or inside Sandboxie-Plus.
8. **Research issue (sub-issue)**: catalogue publicly known 3.3.5a client
   memory-corruption flaws and any community patches; record whether each
   patch's changes can be inspected. No recommendation to players until
   verified.
9. **WireGuard setup script and guide** for the friends stage; the realm
   list advertises the tunnel address.
10. **Signed AIO code**: a fork of the AIO client addon (or a small
    companion addon — see Open Questions) that verifies a signature before
    running server-sent Lua; server-side signing at load time.
11. **Backups advice** in `docs/connection-guide.md`.
12. **Correct the AIO description** in `docs/connection-guide.md` once
    verified (no issue file needed — documentation only).

Likely split into lettered sub-issues when work starts: server hardening
(2–4), distribution (5), sandboxing (6–7), client research (8), transport
(9), AIO signing (10).

## What This Cannot Solve

- **Bugs inside the client executable.** Nothing on the server fixes code on
  the player's machine. Steps 1–4 and 9–10 make it unlikely anyone can send
  the malicious packet; step 6–7 limit the damage if they do; step 8 is the
  only route to actually closing the bugs.
- **Encrypted transport does not scale to strangers.** Asking every stranger
  to install WireGuard is unreasonable. Past the friends stage, traffic is
  readable and alterable in transit unless a custom launcher builds the
  tunnel itself — a large project, not in scope here.

## Open Questions

1. Is the server reachable from the internet today, or only the local
   network? Decides whether steps 1–4 are urgent now or only before release.
2. Will we distribute anything besides the AIO addon — a client download,
   custom MPQs, a launcher? If yes, step 5 becomes urgent.
3. Will players mostly be on Windows? Windows sandboxing is weaker and more
   manual than bubblewrap, so the guide in step 7 matters more.
4. Signed AIO: a fork of AIO we distribute, or a separate small addon that
   checks AIO's code before it runs?
5. Does AIO really run server-sent Lua on the client, contradicting the
   connection guide's "display-only" description? Verify from AIO's source
   before step 10 is designed.
6. Is anything using SOAP today? If not, disabling it removes a local GM
   command path.

## Related

- Issue 107 — credential rotation (blocks this)
- Issue 157 — three-machine deployment (changes which ports and addresses
  are exposed; the firewall and bind-address work must agree with it)
- `docs/connection-guide.md` — player-facing instructions to be extended
- `mysql/conf/my.cnf` — database listen address
- `config/patches/C001-database-connections.sh` — writes the credential
