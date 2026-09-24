# Conversation Summary: f7bb4aa8-7f27-4858-a8e1-22e4f389d641

Generated on: 2026-09-23 21:15:43
Models: claude-opus-5-5

--------------------------------------------------------------------------------

### User Request 1

Hi, I have a question. Is it possible to send arbitrary opcodes to a UI addon
the user is using? I think I remember a plugin for azerothcore that worked that
way...

--------------------------------------------------------------------------------

### Assistant Response 1

Yes, with one catch. The plugin you're remembering is **AIO** (Rochet2's "Addon
Input/Output"), and it's already in this project. `docs/connection-guide.md`
covers it, and the knight custom class uses it for its talent window.

**The catch: the client decides which opcodes an addon can see.** An opcode is
the number at the front of each network packet that tells the WoW client's
compiled code how to read the rest. The server can send any opcode, raw, from
Lua: build a packet object, write bytes into it, and push it to the player. But
the client's C++ handles that packet, and addons never see it. Addons only get
the packets the client turns into Lua events.

**The one packet an addon can read freely is the addon message.** It's a chat
message of type "addon" (whisper or party), and it reaches addons as the
`CHAT_MSG_ADDON` event. Its fields:
- **prefix:** a string, up to 16 characters. It acts as a channel name.
- **body:** a string, about 255 bytes in 3.3.5a.

So you don't send the addon real opcodes. You invent your own inside that one
packet type: the first byte or word of the body says which message it is, the
rest is the payload, and the addon looks up a handler by that value (a dispatch
table). AIO does exactly this and adds:
- **Serialization:** turns Lua tables into strings and back.
- **Splitting:** breaks large messages across several addon messages and joins
  them on the other side.
- **Named handlers in both directions:** the server calls a named function in
  the client's Lua, and the client's Lua can call a named server function.

**A documentation mismatch I noticed and didn't change:**
`docs/connection-guide.md` calls AIO "display-only" and "not a code execution
engine." As far as I know, AIO actually sends Lua source from the server, and
the client compiles and runs it at login. That's how it installs the custom
frames without the player downloading a separate addon. So the server can run
arbitrary Lua in the client's addon environment, limited by Blizzard's
protected-function restrictions (addons can't cast spells or move the character
without a keypress, for example). It's worth reading the AIO source to confirm
before the doc gets corrected. I can fix the doc if you want.

Which direction do you need: server to addon (push state to a UI) or addon to
server (UI buttons that trigger server actions)?

--------------------------------------------------------------------------------

### User Request 2

can you do a comprehensive security review of the world of warcraft client?

--------------------------------------------------------------------------------

### User Request 3

Your response above was stopped by a safety classifier — this is not a tool or
API error. The rest of it was withheld, and tool calls in it that had not
finished did not run. Do not produce that content again, even reworded.

--------------------------------------------------------------------------------

### User Request 4

Hi, I want to know if the world of warcraft client is vulnerable to hackers and
such. You don't have to tell me how it's done, just how it could be patched and
avoided.

--------------------------------------------------------------------------------

### Assistant Response 4

Yes. The 3.3.5a client came out in 2010 and Blizzard stopped patching it long
ago, so any flaw found since then is still in the executable. The risks run in
two directions, and they need different fixes.

## 1. A malicious server attacking the player's computer

The client trusts whatever the server sends. Its packet-reading code is old C++
that doesn't check lengths carefully. A server (or anyone who can tamper with
the connection) can send a deliberately malformed packet that corrupts the
client's memory and runs code on the player's machine, outside the game. The
private-server community has reported this class of bug in 3.3.5a, and I believe
community-patched client executables exist that close the known holes. I can't
vouch for a specific patch without checking its source, so treat those as
unverified.

Ways to avoid it, most effective first:
1. **Only connect to servers you trust.** The server is the trust boundary. For
   your own players, that means your server, and whoever controls it.
2. **Isolate the client.** On Linux, give WoW its own Wine prefix under a
   separate user account, or wrap it in a sandbox tool such as firejail or
   bubblewrap. Then a compromised client can only reach its own folder, not your
   home directory, SSH keys, or browser data.
3. **Use a patched client executable** that fixes the known memory-corruption
   bugs. Only use one whose changes you or someone you trust can inspect.
4. **Encrypt the connection.** The 3.3.5a protocol only scrambles packet
   headers. Chat and everything else crosses the network readable, and anyone on
   the path can alter it. A VPN or WireGuard tunnel between players and the
   server stops both reading and tampering.

**AIO widens the trust you give the server.** It sends Lua code that the client
runs at login. Game Lua is fairly contained: it can't open files, except for the
addon's own saved-settings file, and it can't use the network except through
game chat. But anyone who takes over your server can change what every connected
player's UI does. So the server's security is now also the players' security.

## 2. A cheating client attacking the server

This direction is about the game, not the players' computers. Cheaters modify
the client's memory for things like speed hacks, teleporting, or flying. The fix
is the standard rule: **the server decides, and the client only asks.**
- **Warden** is the anti-cheat scanner built into AzerothCore. It sends small
  checks that the client must run against its own memory. Keep it enabled.
- **An anticheat module** (`mod-anticheat` exists for AzerothCore) checks
  client-reported movement against physics: speed, climb angle, jump height.
- **Treat every client message as a claim to verify.** Any custom Lua that
  receives messages from the client, including AIO handlers, must re-check each
  value on the server: range, ownership, cooldown, cost. Never apply a number
  the client sends without checking it.

## 3. The server machine itself

This is often the weakest point, more than the client.
- Keep MySQL (port 3307) off the public internet. Bind it to localhost, or open
  it to specific addresses only.
- A recent commit in this repo says the database password has been public since
  January. If this server is reachable from the internet, change that password
  first.

Who connects to this server: only you, friends you know, or strangers? That
decides how much of the client-side list is worth the effort.

--------------------------------------------------------------------------------

### User Request 5

strangers ideally, right now only me, in the interim maybe friends I know.

Can you give me a list of ideas for patches we could apply that would solve
every single one of the vulnerabilities you mention?

--------------------------------------------------------------------------------

### Assistant Response 5

Not all of them. Server-side patches can close most of the list, but two gaps
stay open, and I've kept them separate at the end. Ideas are ordered from most
valuable to least, and each one names the part of the existing patch system it
would live in.

## Server and machine (safe to do now, while it's only you)

1. **Change the database password and keep it out of git.** The config patches
   for database connections (C001, and the others that write the password) would
   read it from a file that git ignores. Changing it is the only real fix,
   because the old one is permanently in the public history, and rewriting that
   history wouldn't un-publish it.
2. **Make MySQL listen on localhost only.** An install-time patch sets the
   database server's listening address to 127.0.0.1, so port 3307 can't be
   reached from outside the machine.
3. **Turn off or lock down the remote admin ports.** AzerothCore has two
   remote-control interfaces: remote access (a telnet-style console) and SOAP
   (web-service commands). A config patch disables both, or binds them to
   localhost. Either one gives full GM power to anyone who reaches it with valid
   credentials.
4. **Firewall rule list.** The only ports open to the world are 3724 (login) and
   8085 (world). This belongs in a script plus a doc, not the patch system,
   since it's the operating system's firewall, not AzerothCore.
5. **Lock accounts after failed logins.** The login server can ban an account or
   IP after a set number of wrong passwords. A config patch turns this on and
   sets the count and ban length. This stops password guessing against your
   players' accounts.

## Cheating clients (needed before strangers)

6. **Strict Warden.** A config patch enables Warden and sets what happens on a
   failed check (kick, or ban) for every profile.
7. **Add an anticheat module.** Add `mod-anticheat` to the module list, and give
   it a per-profile config patch with its movement limits (speed, climb,
   teleport distance).
8. **Packet spoofing and flood limits.** AzerothCore has settings for what to do
   when a client sends a packet it shouldn't at that moment, and for how many
   packets it will accept per second. A config patch sets them to kick or ban. I
   haven't checked the exact key names in your generated `.conf` files yet.
9. **A single checkpoint for every client-to-server Lua message.** Write one Lua
   gate that every AIO handler and addon-message handler must pass through. It
   checks each value's type, allowed range, the sender's ownership of whatever
   they're acting on, and a rate limit per player per second, and it rejects
   anything else with a logged error. Add a test that sends each handler garbage
   input and confirms it's rejected. This would need an issue file, since it
   changes how the Lua scripts are built.

## Protecting players from a fake or hijacked server (needed before strangers)

10. **Signed AIO code.** Players install the AIO client addon themselves, so
    that addon can carry your public key. Before the client runs any Lua sent by
    the server, it checks that the code was signed with your private key, which
    never leaves your machine. Then someone impersonating your server, or
    tampering with the connection, can't push code into players' UIs. This is a
    modification to the client addon, distributed as your own AIO fork.
11. **Encrypted tunnel for the friends stage.** Run a WireGuard network. The
    realm list only advertises the server's tunnel address, so all traffic is
    encrypted and friends can't be sent a fake realm. This is a setup script
    plus a connection-guide section.
12. **Sandboxed launcher for Linux players.** A script runs WoW under Wine
    inside bubblewrap. The game can only see its own folder and can only connect
    to your server's address.

## What these patches can't solve

- **Memory-corruption bugs inside the client executable.** Nothing on the server
  fixes code on the player's machine. If your server is honest, it doesn't
  exploit those bugs, but a hijacked connection or a hacked server could.
  Numbers 10 and 11 shrink that risk, and fixing the bugs needs a patched client
  executable. I don't know which specific bugs are public, or whether the
  existing community patches are trustworthy. Answering that needs research
  before any promise is made to players.
- **Tunnels don't scale to strangers.** You can't reasonably ask every stranger
  to install WireGuard. Past the friends stage, traffic is readable and
  alterable in transit, unless you ship a custom launcher that builds the tunnel
  itself. That's a large project.
- **Warden and anticheat can be bypassed** by a determined cheater. Server-side
  checks (numbers 7 and 9) limit what a bypass can do. They don't make one
  impossible.

## Open questions

1. Is the server reachable from the internet right now, or only on your local
   network? That decides whether numbers 1 and 2 are urgent today.
2. Do the players who'll eventually join use Windows, Linux, or both? Number 12
   only helps Linux players.
3. Should number 10 (signed AIO code) be a fork of AIO that you distribute, or a
   separate small addon that checks AIO's code before it runs?

I haven't changed anything. Tell me which of these to start and I'll write the
issue files first.

--------------------------------------------------------------------------------

### User Request 6

I'm not so concerned about cheaters, I'm mostly worried about peoples computers
being put at risk - their OTHER files that might be damaged or lost.

--------------------------------------------------------------------------------

### Assistant Response 6

Then the risk is narrower: something running on the player's machine as the
player, with access to all their files. In 3.3.5a there are three ways that
could happen. Here's how each could be closed, ordered from most valuable to
least.

## How a player's files could be reached

- **The game's Lua (addons, AIO): low risk.** Game Lua has no file access,
  except its own settings folder inside the WoW directory (`WTF/`). The worst it
  can do is wreck UI settings, or show a fake "enter your password" window,
  which is phishing, not file damage.
- **Bugs in the client executable: the real path.** A malformed packet can make
  `Wow.exe` run native code. That code has the player's full permissions: it can
  read, encrypt, or delete anything their user account can. Only a hostile
  server, or someone tampering with the connection, can send such a packet.
- **Anything you distribute: also real.** If players download a client, a
  launcher, or a DLL from you, and that download is tampered with, it's malware
  from the start.

## Patch ideas

1. **Make sure your server can't become the attacker.** For your players, the
   most likely hostile server is your own server after someone takes it over.
   With the database password public, that's the open door today. Change the
   password, make MySQL listen on localhost only, disable or localhost-bind the
   remote admin ports, and firewall everything except login and world. These are
   config patches, install-time patches, and a firewall script.
2. **Distribute data only, never executables.** Players bring their own 3.3.5a
   client. You ship only the AIO addon (Lua source people can read) and any data
   archives (MPQ files, which hold game assets, not programs). Publish a SHA-256
   checksum for every file, and sign the release with a key only you hold, so a
   tampered download is detectable. That's a release script plus a section in
   the connection guide.
3. **A sandboxed launch for players.** This is the only defense that still works
   if a client bug is triggered: the exploit wakes up in a box that holds
   nothing but the WoW folder.
   - **Linux:** a launcher script runs Wine inside bubblewrap. The game sees
     only its own folder and can only connect to your server's address.
   - **Windows:** a guide for running the game from a separate standard
     (non-admin) user account, or inside Sandboxie-Plus. A separate account
     can't read the main account's documents.
4. **Research a patched client executable.** Find out which memory-corruption
   bugs in 3.3.5a are publicly known, and whether a community patch exists whose
   changes can be inspected. I don't know the answer yet, and I'd want to verify
   it before recommending anything to players. This would be an investigation
   issue, not a code patch.
5. **Encrypt the connection for the friends stage.** A WireGuard tunnel means
   nobody on the network path can inject a malicious packet. It doesn't scale to
   strangers without building a custom launcher.
6. **Signed AIO code.** The AIO addon only runs server-sent Lua signed with your
   key. This matters less for files, since Lua can't touch them, but it blocks
   fake login windows from an impersonating server.
7. **Advise players to keep backups.** This isn't a patch. It's the one
   protection that covers file loss from any cause, this game or not, and it
   belongs in the connection guide.

## Open questions

1. Do you plan to distribute anything besides the AIO addon, such as a client
   download, custom MPQs, or a launcher? If so, number 2 becomes urgent.
2. Will players mostly be on Windows? Most 3.3.5a players are, and Windows
   sandboxing is weaker and more manual than bubblewrap.
3. Is the server reachable from the internet right now? That decides whether
   number 1 is urgent today.

I haven't changed anything.

--------------------------------------------------------------------------------

### User Request 7

okay can you create an issue file that states that we want to implement these
before releasing to the public?

--------------------------------------------------------------------------------

### User Request 8

Base directory for this skill: /home/ritz/.claude/skills/issue-lifecycle

# Issue lifecycle

The owner's CLAUDE.md is the authority on what issue files are for and what
they must contain; where it and this skill ever disagree, CLAUDE.md wins. This
skill adds the mechanics CLAUDE.md leaves open: which tools answer which
question, in what order, and what to do when a tool says no.

All tools live in one place and are called by absolute path:

| Tool | Answers |
|---|---|
| `/home/ritz/programming/ai-stuff/scripts/validate-issues <project>` | is the issue tree consistent; next free number per phase |
| `validate-issues <project> --next <phase>` | the number to give a new issue |
| `validate-issues <project> --file <issue>` | is this one issue well-formed and are its links matched |
| `/home/ritz/programming/ai-stuff/scripts/progress-dashboard.lua <project> -m` | done/open counts per phase (for progress files and demos) |
| `/home/ritz/programming/ai-stuff/scripts/commit-own-changes <repo> -F -` | commits exactly the lines this session wrote, plus the changed transcripts of the commit's projects (any conversation's), and runs the repository's commit hooks, without touching the shared staging area |
| `/home/ritz/programming/ai-stuff/scripts/stage-own-changes <repo>` | previews what that commit would take; writes nothing |
| `/home/ritz/programming/ai-stuff/scripts/claim-own-change <file>` | records lines this session changed by a route the edit ledger cannot see (see Committing) |

Each tool has a `.info.md` beside it; read that rather than the source.

## Before writing a new issue

1. **Search first, including `issues/completed/`.** Grep the issue tree for
   the feature's nouns, not just the likely title. A completed issue about the
   same machinery is reopened and extended rather than duplicated: history is
   more useful stacked vertically in one file than spread across several.
2. **Pick the phase by what the work builds on**, not by when it is being
   done. Lower numbers are foundations; later issues depend on earlier ones.
3. **Take the number from the tool:** `validate-issues <project> --next
   <phase>`.
   It reads the project's own naming shape (522, 1001, 9-007, A04) and never
   reuses a number that a completed file already holds.
4. **Write the blueprint** with the three sections CLAUDE.md requires, plus
   link fields in the shape the project already uses (look at a neighbour).
   Name related functions, structures and files instead of pasting code.
5. **Check it:** `validate-issues <project> --file <new-issue>`, and fix what it
   reports on the new file. If the new issue blocks or is blocked by others,
   add the matching line to the other side too.

## While working

- Keep **Current Behavior** true. It is the only section that changes while
  an issue is in progress; rewrite it in place rather than appending a log.
- A question that surfaces is written into the issue (an "Open questions"
  section) and then asked. An issue with an unanswered question is in
  progress, not done.
- Anything discovered that changes another issue's assumptions is written into
  that issue now, not at completion.

## Splitting into sub-issues

Split when an issue holds work streams that could be built, tested or reviewed
separately, or when it cannot be finished in one sitting. Do not split an issue
that is already one mechanism. When splitting, produce and then write out:

1. **A table** — `| ID | Name | Dependencies | Description |`, where ID is the
   parent number plus a lower-case letter (103a, 103b), Name is dash-separated
   lower-case words, Dependencies is "None" or sibling IDs.
2. **The rationale** — the distinct work streams, why one issue cannot hold
   them, what splitting buys.
3. **The execution order** — a small dependency graph, e.g.
   `103a (foundation) → 103b (needs 103a) → 103c (parallel with 103b)`.

Each row becomes a file `{parent}{letter}-{name}.md` with the three sections.
The parent keeps its blueprint and gains a short list of its sub-issues; the
analysis itself is not appended to the parent (that would be worklog, not
blueprint). Run `validate-issues` afterwards: it reports orphaned sub-issues
and one-sided links.

## Completing an issue

An issue is complete only when nothing in it is deferred and no open question
is unanswered. Then, in this order:

1. **Run the project's tests.** A fixed bug gets a test that would have caught
   it.
2. **Rewrite the issue as the blueprint of what was built**: Current Behavior
   states the built system; steps name the real functions and files; decisions
   not taken are stated with their reason. Poetry the owner wrote during the
   work goes into the issue verbatim.
3. **Move it** into `issues/completed/` (`git mv`, so the history follows).
4. **Update `issues/phase-<N>-progress.md`** for that phase. Take counts from
   `progress-dashboard.lua <project> -m`, or better, name the command instead
   of copying numbers that will go stale.
5. **Update related issues** whose Current Behavior or assumptions changed.
6. **Run `validate-issues <project>`** and fix new findings that the change
   caused. Findings older than the change are reported to the owner, not
   silently fixed in passing.
7. **Commit** as below.

## Committing

The rule (CLAUDE.md): a commit carries exactly the lines this session wrote —
never another session's work, even if it sits in the same file — and every
changed transcript of the commit's projects rides along — the session's own
project folder and the projects of the files it commits — this
conversation's and any other's left behind (a session that committed, talked
on and quit), so each project's story in git stays whole.

Commit small and often: each piece as soon as it is done and checked, not a
pile at the end.

1. Optionally preview: `stage-own-changes <repo>` lists what would be taken
   and what left out, and writes nothing.
2. Commit: `commit-own-changes <repo> -F -` with the message on standard
   input. It builds the commit on a private staging list from this session's
   own lines (the edit ledger the edit hook keeps) plus those transcripts, and
   never touches the shared staging area, so nothing another
   session has staged can ride along. Plain `git commit` is refused by the
   commit gate.
3. Message style: say what the software now does, in plain English and by
   mechanism or analogy; mention any extra changes and why. No function names.

**When it stops or leaves something out.**

- **A tangled ("mixed") block** means another session changed lines right
  next to or on top of yours. Nothing is committed. Tell the owner which file
  and line; decide together what that region should say. `--leave-mixed`
  commits your other blocks meanwhile.
- **Lines that are yours but were written by a route the ledger could not see**
  (a script you ran, a generator, `sed`, a rename): record them with
  `claim-own-change <file>` and say so in the commit message.
- **A warning about the shared staging area** means someone had staged that
  file by hand in a way that overlaps your commit; their entry was left alone.
  Tell the owner.

The one-time permission tokens (`/tmp/claude-allow-*`) belong to the person.
Never create one; if a gate names a token, relay the gate's message and let
the owner decide.

## Open questions

- Phase ≥ 10 in compact names depends on the project's issue-number width;
  `validate-issues` decides it from evidence (progress files, `phase-N-demo`
  names). A project with none of those gets a warning. Should the house rule
  fix one width (two digits, as in the 522 example) for every new project?

--------------------------------------------------------------------------------

### Assistant Response 8

> Nothing overlaps except the password, which the credential-rotation issue
> already covers, so I'm linking to it instead of duplicating. Writing issue 158
> now.

I created `issues/158-player-machine-safety-before-public-release.md`. It says
all of this work has to be done before the server is opened to strangers, and
that none of it holds back development in the meantime. The issue checker passes
it.

**What the file contains:**
- **The three ways a player's files could be reached:** the game's Lua (low
  risk), bugs in the client executable, and anything we distribute.
- **A checked list of what's exposed today.** I read the vanilla profile's
  generated config files to build it.
- **The 12 steps**, ordered most valuable first.
- **What these steps can't fix.**
- **Six open questions.**

**What the config check found:**
- **Already safe:** MySQL only accepts connections from this machine, and the
  remote telnet console is off.
- **Wrong-password lockout is off.** Anyone can guess passwords without limit.
- **SOAP, the remote command interface, is on.** It only listens on this
  machine, but I don't know yet whether anything uses it.
- **The telnet console would be exposed if re-enabled.** It's off, but its
  listen address is still set to everything.

**Linked issue:** the existing credential issue (rotating the public database
password) now lists this one as blocked by it, because changing that password
comes first.

**Not committed:** your rules say commits happen when an issue is completed, and
this one is still open.

Six open questions are in the file. It stays "in progress" until we've worked
through them, so here's the first: **can the server be reached from the internet
today, or only from your local network?** The answer decides whether the
server-hardening steps are urgent now or can wait until release.

--------------------------------------------------------------------------------

