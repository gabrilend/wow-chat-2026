# Conversation Summary: 19f41c99-0829-49d7-b39b-aa0b09d55aed

Generated on: 2026-09-23 20:52:13
Models: claude-opus-5-5

--------------------------------------------------------------------------------

### User Request 1

Hi, can you investigate the possibility of writing load spreading technology for
the worldserver? We could perhaps store different instances on different
computers - I have three, one could be eastern kingdoms, one could be kalimdor,
and one could be Outland and instances. They're each connected to a router, so
it'd be a matter of running a scheduler on whichever had the fewest characters
online - this server would also run the authserver. This scheduler would receive
the incoming traffic (changing the ports it's listening to dynamically in
concert with it's friends so that the traffic gets delivered correctly) oh I
guess the router is gonna need to deliver to all three at once? that seems a
little chaotic. Investigate feasibility. Might need to do routing, where if a
server that's not being the scheduler or authserver anymore gets that traffic,
it redirects it to the real one and ideally updates the sender and tells them to
look in the correct direction. But that of course only works for our own tools.

--------------------------------------------------------------------------------

### Assistant Response 1

It's possible, but it's a big project. Your instinct about the router is
correct, and the answer is that the router should not send traffic to all three
machines. Here is how it would have to work and where it gets hard.

## How a player connects today

1. The game client opens a connection to the **authserver** on port 3724. It
   logs in and gets back a secret session key. The authserver then hands over
   the realm list, which says "the world is at address X, port 8085."
2. The client opens **one long-lived connection** to that address. Every packet
   header on it is scrambled with that session key.
3. Everything in the world runs inside **one worldserver process**: every
   continent, every instance, chat, groups, guilds, the auction house, the
   playerbots and the Lua scripts. It already spreads the maps across CPU cores
   (map-update threads), but only on one machine.

## The router problem

The router forwards port 8085 to exactly one machine. That's actually what you
want: a fixed front door. Moving the scheduler role between machines and
changing ports on the fly would mean reprogramming the router every time the
role moved, and a connection that's already open would break during the switch.
Pick one machine and keep it as the front door for good.

## Two ways to split the world

**A. The front door relays traffic.** The client only ever talks to the
front-door machine, which holds its connection. That machine reads the database
to get each player's session key, so it can unscramble packet headers, see which
map the player is on, and pass the packets to the worldserver on the right
back-end machine. This works with an unmodified client, because the client never
learns there are three machines. The catch is that the front door handles every
packet and needs to understand the packets that change map.

**B. The client is told to reconnect elsewhere.** The 3.3.5 protocol has a
"reconnect to this other address" message, which Blizzard used for its instance
servers. It's still listed in our source
(`source-beta/src/server/game/Server/Protocol/Opcodes.cpp:1424`), but it's
marked as never sent, and the client's replies to it go nowhere. That's the
"tell the sender to look in the correct direction" idea you described, and it
already exists at the protocol level for real clients, not just our own tools.
But nobody in the emulator community has confirmed that the 3.3.5a client
handles it cleanly. I'd want to test it before relying on it, and it breaks as
soon as the other machines aren't reachable from the internet.

Either way, the handoff happens at a loading screen: a boat, a zeppelin, a
portal, a hearthstone or an instance entrance. The steps are: save the character
on machine A, log it out there, log it in on machine B, and show a loading
screen in between. Continents only connect through loading screens, so the split
points already exist.

## The hard part: shared state

| What | Why it breaks when split |
|---|---|
| New item and character ID numbers | Each worldserver reads the highest ID from the database at startup and counts up in memory. Two servers writing to one character database would hand out the **same ID twice** and corrupt data. You'd need one shared counter, or separate number ranges for each machine. |
| Groups and raids across continents | The party lives in one server's memory. A party member on another machine would need syncing between machines. |
| Chat, whispers, the who list, guild chat, channels | These assume everyone is in one process. They'd need a relay between machines. |
| Playerbots | Each bot runs inside its owner's session. They'd have to move machines with their owner every time. |
| Lua memory (ambush timers, traveler state) | This lives in the Lua engine's memory and would be lost at each handoff unless it's saved first. |
| Mail, auction house, instance lockouts | These are in the database, but each server caches them. Two caches can drift apart. |

## Before building it

What's the actual bottleneck? The three-way split only pays off if one machine
can't keep up with the world simulation. My guess is that your load comes from
**playerbots** (each one is a full simulated player) and maybe the local AI chat
model, not from the number of human players. If so, there are much cheaper
options, in order of likely payoff:

1. Move MySQL to machine 2 and the AI model to machine 3, and keep the
   worldserver alone on machine 1. That takes a few config lines.
2. Tune the number of map-update threads and the playerbot limits.
3. Run separate realms, one per machine. The authserver already supports listing
   several. Characters can't cross between them, but you'd have it working in an
   afternoon.
4. The full continent split, option A above. That's months of C++ work, and the
   patch set would be large.

A question for you: when the server feels slow, is it one busy continent, or is
it everything at once? If it's everything, splitting by continent won't help,
because the load follows the players and their bots wherever they go. You could
have three machines and one of them doing all the work.

I haven't changed any files. If you want to pursue this, I can write it up as an
issue file, or measure where the worldserver actually spends its time first.

--------------------------------------------------------------------------------

### User Request 2

okay how about instead we say that each machine gets N "world update threads"
which update contribute to collectively updating one map at a time. They are
distributed according to the capabilities of the machine, and in our case
there'll be three machines with two performance profiles - one running the
authserver and scheduler, and one running the worldservers. The scheduler is in
charge of distributing worldserver threads between the three worldservers
(including to itself.) Then, we allocate maps to be controlled by each
worldserver according to the number of people logged in to both. Let's try your
option B. See if we can get it working in an emulator. Watch for attempted
network connections. See where they're going. Find out how to redirect them, and
then we've figured out the opcode. Then it's just a matter of patching the
server to re-direct players as we please. Dynamical load balancing, easy. I see
now why Blizzard invented phases. Let's try and bring people together, not
alienate them like sparks.

--------------------------------------------------------------------------------

### Assistant Response 2

> Looking for a stock 3.3.5a client to test with. So far I've only found the
> Ascension install. Checking whether its game executable is the original.

> Decoding what the client sends back after a redirect. The client code for the
> reply exists and computes a hash over the session key. Now looking for the
> part that receives the redirect.

> At 0x63336e the client checks for the redirect opcode inside its packet
> dispatcher. Reading the handler:

> The client's network layer intercepts five opcodes itself: pong, auth
> challenge, **0x50D redirect**, 0x50F and 0x511. Reading the redirect handler:

> The redirect packet's layout is readable from the handler. Checking what the
> client sends to the new server:

The client supports being redirected, and I've decoded both packets. Next I'll
write this into an issue file before any server patch. I'm loading the issue
workflow for that.

--------------------------------------------------------------------------------

### User Request 3

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

### Assistant Response 3

> There's already an issue for this: `issues/913-clustered-worldserver`.

> Issue 913 already covers the clustered worldserver as a paper design. I'll add
> a sub-issue for the redirect handoff, following the format of a neighbouring
> sub-issue.

> Now writing the sub-issue.

> Adding the sub-issue link and your thread-weighting idea to the parent issue:

The game client does support being told to reconnect somewhere else, and I've
worked out the full packet layout by disassembling the stock 3.3.5a game
executable. I haven't run the emulator experiment yet, because there's no client
on this machine that can start: the Ascension folder has an unmodified 3.3.5a
`Wow.exe`, but its `Data/` folder with the game archives is missing.

## How the redirect works, from the client code

1. **The server sends the redirect.** It carries the new server's address (4
   bytes), its port (2 bytes), a 4-byte tag number, and a 20-byte proof. The
   proof is a keyed hash (HMAC-SHA1) of the address and port, keyed with the
   player's 40-byte session key from login.
   - The client recomputes the proof. If it doesn't match, the client
     disconnects, so only a server that knows the session key can move a player.
   - If the client already has a redirect in progress, or is busy, it sends back
     a "redirect failed" reply containing the tag number.
   - Otherwise it opens a **second** connection to the new address and keeps the
     first one open for now.
2. **The new server sends its normal login challenge.** When the challenge
   arrives on the second connection, the client answers with a "redirect proof"
   instead of a normal login. The proof contains:
   - the account name;
   - an 8-byte anti-flood answer;
   - a SHA1 hash of the account name, the session key and the new server's
     random seed.
3. **The client switches encryption on** for the new connection, with the same
   header scrambling a normal login uses.

On our side, this means a second worldserver can check the proof against the
auth database both machines already share, and no relay machine is needed. That
also takes care of your router question: only the first login goes through the
fixed front door, and after that each player talks straight to the machine
running their map. For that to work, each machine needs a port the players can
reach, so the router forwards one extra port per machine.

About worker threads spread across machines updating one map together: that part
won't work over a network. Threads updating a map constantly read the same
memory (grids, creature lists, who can see whom), and across the LAN every one
of those reads would become a network round trip. Your other half of the idea
does work: the scheduler counts each machine's threads as its capacity and gives
it **whole maps** to match.

## Files written (nothing committed; the issue is still in progress)

- `issues/913a-client-redirect-handoff.md` is a new sub-issue under the existing
  clustered-worldserver issue. It has the packet tables, the binary addresses
  for re-checking, and the experiment plan: a GM command that sends the
  redirect, a small program listening on a spare port that logs what the client
  sends, and `tshark` watching both connections.
- `issues/913-clustered-worldserver` now has a section on assigning maps by
  thread capacity, and a link to the new sub-issue.

## Still unknown (listed as open questions in the issue)

- The byte order of the address and port in the redirect packet.
- What the client waits for after sending its proof, and who closes the first
  connection.
- Whether the client accepts a redirect during a loading screen, which is
  exactly when we'd want to move someone.
- How the playerbots follow their owner, since they have no connection to
  redirect.

First question: where is a complete 3.3.5a client? Is it on one of the other two
machines, or can its `Data/` folder be copied here? Once it's here, I'll write
the patch that sends the redirect, and you run the compile.

--------------------------------------------------------------------------------

### User Request 4

/home/ritz/games/azeroth-core/client/

--------------------------------------------------------------------------------

### Assistant Response 4

> This client's `Wow.exe` isn't byte-identical to the stock one I analysed.
> Checking where they differ:

> Lua can send the redirect packet. The proof inside it needs HMAC-SHA1, so I'm
> looking for which Lua the server runs and whether a SHA1 library is already
> around:

> Writing the Lua probe next. First I'm checking the ports and the method names
> ALE uses for writing packets:

> HMAC-SHA1 through LuaJIT's C bridge gives the published test-vector result,
> and the socket library loads. Writing the worldserver side:

> ALE passes every player's commands to this hook, not only administrators', so
> the script has to check the rank itself:

> Writing the listening post, which plays the part of the second server:

> The body read hid a disconnect by turning a failed read into an empty string.
> Fixing that:

> Writing a test: a pretend client that does what `Wow.exe` does after a
> redirect, checked against the listener.

> The listener test passes. Checking that the worldserver will actually load the
> probe:

> Both pieces are in place. Updating the issue so it matches what was built:

> The listener needs the session key before the redirect is sent, but right now
> the probe only prints the key at the moment it sends. Adding a `.redirect key`
> subcommand that only prints it:

Everything is ready for you to run against the real client. Nothing has been run
with the game yet. Only the pretend client has been tested against the listener,
and that test passes.

**What I built:**
- **A `.redirect` chat command** (`src/lua-vanilla/redirect-probe.lua`). It's a
  Lua script the worldserver loads, so there's nothing to compile. Only
  administrator accounts can use it.
  - `.redirect key` prints this login's session key on the worldserver console
    and does nothing else.
  - `.redirect 127.0.0.1 4463` sends your client the redirect. Two optional
    extra words choose the byte order for the address and the port; each is
    `net` or `host`.
  - It signs the address with your session key, using the server's own crypto
    library.
  - The tag number inside is `C0FFEE13`, so a refusal is easy to spot in a
    capture.
- **The pretend second server** (`src/tools/redirect-listener.lua`). It greets
  the client the way a worldserver does, checks the client's proof, unscrambles
  later packet headers, and logs everything to
  `tmp/shared-memory/redirect-listener.log`.
- **A test** (`scripts/test-redirect-listener`). A pretend client that follows
  the disassembled behaviour goes through the full exchange with the listener,
  including scrambling in both directions.

**To run the experiment:**
1. Start the authserver and the vanilla worldserver, then log in on an
   administrator account. If the worldserver was already running, type `.reload
   ale` so it picks up the new script.
2. In game, type `.redirect key`, then copy the 80-digit key from the
   worldserver console.
3. In terminal A, start the listener:
   `luajit
   /mnt/mtwo/games/azeroth-core/wow-chat-2026/src/tools/redirect-listener.lua
   --port 4463 --key <KEY> --answer auth-ok`
4. In terminal B, watch every connection the client tries to open, wherever it
   goes:
   `sudo tshark -i any -f "tcp[tcpflags] & tcp-syn != 0 and not port 3307"`
5. In game, type `.redirect 127.0.0.1 4463`.

**How to read the result:**
- **The client connects to port 4463 and the listener logs `digest MATCHES`.**
  The default byte order is right and the client's proof is what the disassembly
  said. What the listener logs after the "login accepted" reply is the next
  unknown: what the client waits for, and whether it drops the old connection.
- **Terminal B shows a connection attempt to 1.0.0.127, or to port 28433.** The
  byte order is backwards. Log in again and retry with `host` or `net` on the
  end of the command.
- **Nothing is dialled and the client disconnects.** The client rejected the
  proof, so the signing of the address is wrong.

Each login gets one redirect attempt: a second one while the first is still
pending gets refused. So log in again before each retry.

I haven't committed anything. The issue stays in progress until the rest of the
handshake is understood, and a commit waits until it's complete.

What do you expect the client to do with the original connection once the new
one says "login accepted": close it, or keep both open until the old server
hangs up?

--------------------------------------------------------------------------------

### User Request 5

can you make issue files and then we can block them on "connectivity reliance
improvements required" because the server is slow. Then we should unblock the
parts that deploy the system to another server, in this case my 3 mini-computers
in my room. One can do the authserver, one can do the worldserver, and one can
do the mysql database. At least until we design better software, but that's
gated on there being a need for it (connectivity reliance improvements)

--------------------------------------------------------------------------------

### Assistant Response 5

> I'll check how the database address and the realm address are set today, so
> the deployment issues describe the real starting point:

> I have what I need. Writing the files now: a gate issue (913b), the cluster
> pieces blocked on it (913c–913h), and the three-machine deployment (157 plus
> 157a–157f).

> Now the deployment issues:

> Adding the matching "blocks" line on the other side of each link, and updating
> both parents:

> I'll use the Edit tool with absolute paths instead.

I've written 14 issue files. The clustered-worldserver work is now shelved
behind a gate issue, "connectivity reliance improvements required", and the
three-machine deployment is unblocked. Nothing is committed, because your rules
commit only when an issue is completed.

**Three-machine deployment (unblocked):**

| Issue | What it builds |
|---|---|
| **157 three-machine-deployment** | Parent. One mini-computer each for MySQL, the authserver and the worldserver. The development machine keeps building and ships to them. |
| 157a role-hosts-file | One file saying which machine plays which role (address, ssh user, architecture). It starts out with all three roles set to "this machine", so nothing changes until you fill it in. |
| 157b deploy-tool | One command to ship, start, stop, check status and fetch logs for each role over ssh. |
| 157c database-address-in-config | The config patches and helper scripts read the database machine's address from that file. Today they're hard-coded to 127.0.0.1. |
| 157d database-machine | Moves MySQL with a dump, restore and row-count comparison. Only the two server machines are allowed to connect. |
| 157e auth-machine-and-router | The router forwards the auth port and the world port to two different machines. The realm list points at the world machine. |
| 157f world-machine | Ships the map data and Lua scripts as real files. Today the Lua scripts arrive through a link into this machine's checkout, which won't exist on the mini-computer. |

Order: 157a → 157b and 157c → 157d → 157e and 157f.

The database move (157d) says the password must be changed before MySQL starts
listening on the network. It has been public since January. That was harmless
while MySQL only listened on its own machine, but it matters once the database
is on the LAN.

**The gate (913b):** it builds a measuring tool that samples the world-update
time, per-thread CPU, database query time and network round trips. It ends with
a verdict of "required" or "not required". It's blocked by 157, so it measures
after the database and authserver are off the world machine; otherwise it would
be measuring the wrong bottleneck.

**Behind the gate (913c–913h):**
- the second worldserver accepting a redirected player;
- separate ID-number ranges for each worldserver;
- the scheduler that places maps by thread capacity;
- relaying chat, guilds and groups between machines;
- bots following their owner to the new machine;
- one owner each for mail, the auction house and similar shared services.

The redirect experiment (913a) is **not** gated, because it's already built and
costs one login to run. Say if you'd rather shelve it too.

**Already wrong before today:** the validator flags the old 913 parent file for
having no `.md` extension and a differently named steps section. I left both
alone.

Questions that decide how 157 starts:
1. What CPU architecture and operating system do the mini-computers run? If they
   match this machine, the built programs can be copied as-is. If not, each
   machine builds from source through issue 154.
2. Do they have fixed LAN addresses, and do they already accept ssh from this
   machine with a key?
3. For the gate: what counts as slow? An average world update over some number
   of milliseconds, or the worst update in a minute?

--------------------------------------------------------------------------------

