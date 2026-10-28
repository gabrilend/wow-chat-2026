# Conversation Summary: 9f34a2ef-039a-4f5f-8723-b741d984044f

Generated on: 2026-10-27 13:11:42
Models: claude-opus-5-5

## Contents

1. 2026-10-26 21:55, after Request 2 - You asked for Linode deployment of every
   realm and password-locked chat journals. I wrote the plans and built and
   tested the journal lock, uncommitted. Next: answer the five questions,
   starting with whether public guest accounts should keep journals.
2. 2026-10-26 23:08, after Request 8 - Goal: run every realm at once on Linode
   machines, with locked journals and a public connection page. That page now
   generates in preview; next, I need your answer on where the build caches go
   and what "the authorization page" means.

--------------------------------------------------------------------------------

### User Request 1

can we make part of the build promotion from shadow to main that we also push it
to my linode instance and restart the server and all that? I want to be able to
run every single realm at once, so we should design all of our issue plans as if
each realm profile is built in parallel. I want the system to be running 24/7
and I want to put the connection details on my website. I want to hash chatlogs
to the journals of those who saw them, keyed only with the user's password. We
don't store a copy of their password in unencrypted text, and we don't have to
key it to open. Only they do, the people who observed it pass directly through
their chatlogs in-client. Any text message we send, we also possess as text
directory contents, hashed to the user of course. And, if the user creates an
rmail request, they can download it. We show them exactly how to do this in the
same section where we tell them how to connect. They will have seen it if they
can log in. Please make issue files and work on them. Be consciencious of other
intelligent agents working in the same directory - write to patch files in RAM
and combine yourself into the new topic while keeping a copy of the old, until
you confirm that it's permanent record. Then, with power you are endowed.

--------------------------------------------------------------------------------

### User Request 2

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
| `/home/ritz/programming/ai-stuff/scripts/adopt-left-behind-changes <repo> -- <path>...` | takes ownership, line by line, of uncommitted work a finished session left, leaving lines any other session still holds (see Committing) |

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
- **Nothing to commit, but the work is there**: an earlier session wrote it
  and ended, or the machine rebooted and emptied the ledgers. Look first with
  `adopt-left-behind-changes <repo> --dry-run -- <path>...`, then adopt and
  commit one batch at a time with `commit-own-changes <repo> -F - --
  <path>...`. Lines reported as **held** belong to another session. Take them
  (`--from <session>`) only if that session has finished, and ask the owner
  if unsure. Say in the commit message that the work was adopted and from
  whom. This is the route for a left-behind backlog, not the token.
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

### Assistant Response 2

> Reading the existing deployment (157) and rmail issues before writing new
> ones.

> Files claimed and originals backed up in RAM; now writing the issue files.

> Parent journal issue written; now the six sub-issues.

> Issues written. Now building the lock library; checking house style for a Lua
> lib and a test first.

> Lock library passes its 22 checks; testing the opener against the test's
> journal.

> Now the roadmap decision and the 1003 cross-link.

> Fixing the one-sided "blocks" links the validator found.

I've written the plans for all three requests and built the first working piece:
the lock that seals a player's journal to their password. Nothing has been sent
to Linode and nothing is committed yet. As you asked, I'm keeping the old copies
in memory until you confirm this should become permanent record.

**The one technical fact that shapes the journal design.** When a player logs
in, the game never shows the server their password. The client and server use a
challenge scheme called SRP6. The server stores only a random salt and a
"verifier" number worked out from the password. At login the client proves it
knows the password without ever sending it. The server sees the password in
plain text at only two moments: when the account is created, and when the player
changes their password in game.

So the lock is made at those two moments:
1. The password is stretched with Argon2id, a deliberately slow, memory-hungry
   function, into a key pair.
2. The server keeps only the public half. It can lock text with it but can't
   unlock anything.
3. Each journal file gets its own random key, which is locked to that public
   half.
4. Only someone typing the password can remake the private half and read the
   file.

Someone who stole the database could already guess passwords against the stored
verifier. The public key allows the same guessing and nothing more.

By "hash" I took you to mean lock: a hash can't be turned back into text. Hashes
are still used, as fingerprints that let anyone check a journal hasn't been
changed, without being able to read it.

**What's built and tested:**
- **The lock library.** A LuaJIT file that talks to libsodium, the same
  encryption library the server and a browser page would use. It makes the key
  from the password, writes journal files and opens them again.
- **A test of it:** 22 checks, all passing. The journal opens with the password
  in any letter case (the game ignores case), and with the right password among
  several. It refuses a wrong password, a changed byte, a removed line, a line
  added at the end, and a header pointed at another account. A file whose end
  was cut off, as after a server crash, is read up to the cut and marked as cut
  short.
- **A command-line opener.** It asks for the password without showing it and
  prints the lines like a chat window. I ran it on a test journal and it worked.

**Plans written, with nothing built yet:**
- **Linode host.** One rented machine runs MySQL, the login server and every
  realm's world server at once, all day. A service manager starts them at boot
  and restarts any that crash, with a growing pause between tries. Each restart
  is logged, not hidden.
- **Shipping on promote.** After a promote, that one profile is copied into a
  new folder on the host and players get the server's own 5-minute countdown.
  Only that realm restarts. If it doesn't come up, it switches back to the
  previous folder and the promote reports the failure.
- **Every profile built at once.** Today all profiles share one source tree, one
  build folder and one shadow install folder, so two builds at once would
  overwrite each other. The plan gives each profile its own copy of each, plus a
  lock. I added this as a project-wide decision in the roadmap.
- **The journal itself, in six parts:**
  - the lock;
  - recording at the one place the server hands each player's client its
    packets, so a line is recorded for exactly the players who saw it;
  - copies of rmail texts sent to a player;
  - fetching your journal by rmail;
  - opening it at home, either with the command-line tool or a browser page
    where the password never leaves the computer;
  - the website section that explains connecting and the journal together.

**Other agents:** I listed every file I touched in the shared claims list. I
didn't touch the compile, validate or promote scripts: they're shared files, and
you run the builds. The changes I made to existing issue files are saved as a
patch, with the originals beside it, in `tmp/shared-memory/journal-agent/`.

**Questions, most blocking first:**
1. **Guest accounts.** The public guest accounts' passwords are published, so a
   journal kept for one would open for anyone. It would also hold what other
   people said near whoever used it. Should guest accounts keep no journal?
2. **Accounts that already exist** have no key, because their password was never
   seen in plain text. My plan records nothing for them until the player changes
   their password in game, and tells them so at login. Does that match what you
   want?
3. **The Linode machine:**
   - which operating system it runs (this computer runs Void Linux, and the
     built programs may need matching libraries);
   - how much memory it has;
   - whether this computer already logs into it over ssh with a key;
   - whether `wow.ritzmenardi.com` moves there.
4. **Where your website lives** and how pages get onto it.
5. **Ship every promote, or only when asked?** A promote follows every
   successful compile, and each ship restarts a live realm with players on it.

The plan files also hold further questions for later, such as which kinds of
text count, how long journals are kept, and the port numbers.

Here's a puzzle for you: a journal locked to an old password stays locked to it
after a password change, because the server never had the old private key. What
would you want a player to experience when they ask for a year of journals
across three password changes?

Standing reminder: both disks still have no protection against bit rot. They're
ext4, which doesn't checksum file contents.

--------------------------------------------------------------------------------

### User Request 3

> 1. The password is stretched with Argon2id, a deliberately slow, memory-hungry
> function, into a key pair.

this should not be considered a form of security, for they can always just apply
more compute.

>                                                                                - Linode host. One rented machine runs MySQL, the login server and every realm's world server at once, all day.

ideally, three or more separate machines, each running their own duties.

> 1. Guest accounts. The public guest accounts' passwords are published, so a
> journal kept for one would open for anyone. It would also hold what other
> people said near whoever used it. Should guest accounts keep no journal?

yes, no journal, but also they can be kicked off whenever.

>      - whether wow.ritzmenardi.com moves there.

no that stays with my computer since it's me

>   4. Where your website lives and how pages get onto it.

/home/ritz/programming/ai-stuff/neocities-modernization/scripts/push-to-neocities

> 5. Ship every promote, or only when asked? A promote follows every successful
> compile, and each ship restarts a live realm with players on it.

only when something changed for that server

> 2. Accounts that already exist have no key, because their password was never
> seen in plain text. My plan records nothing for them until the player changes
> their password in game, and tells them so at login. Does that match what you
> want?

there is exactly one account right now. Well, maybe Aurelia, my girlfriend, but
we can reset hers it's fine. We spent like 10 minutes in it together.



<pasted_content id="9a5a">
>   3. The Linode machine:
>      - which operating system it runs (this computer runs Void Linux, and the built programs may need matching libraries);
>      - how much memory it has;
</pasted_content id="9a5a">


anything we'd like. as close to minimal linux as we can, the better. I prefer
runit over systemd, with individual modules replacing monolithic software.

but that's just a preference thing...

oh and we'll be spinning up multiple new machines, one for each profile.

--------------------------------------------------------------------------------

### Assistant Response 3

> Updating the plan files with your answers now.

> Rewriting the Linode plan for one machine per realm, plus machines for the
> shared duties.

> Now the lock library: switching to the light "interactive" stretch settings
> and correcting the wording.

> Now the remaining cross-references: rmail fetch, website, parent tables,
> roadmap.

I've put your answers into the plans. Nothing is committed yet and nothing has
gone to Linode.

**On stretching the password:** I agree, and the plans now say so. A journal is
exactly as safe as its password is hard to guess. Someone holding a journal file
can try passwords offline as fast as their computers allow. The Argon2id step
stays only because a password has to be turned into a 32-byte seed somehow, and
that is libsodium's way of doing it. I dropped it to the light "interactive"
settings: 64 MiB of memory, about 0.1 seconds per account. The settings are
stored in each journal file, so changing them later never breaks an old journal.
The 22 checks still pass.

**What changed in the plans:**
- **Machines:**
  - one login machine;
  - the database on its own machine;
  - one machine per realm, each running only that realm's world server.

  Adding a realm means adding a machine and a line in the list of machines. It
  never touches another realm's machine.
- **System:** Void Linux with runit. It's the same minimal, runit-based system
  this computer runs. Because it matches this computer's libraries, the built
  programs can be copied rather than rebuilt.
  - Each server is a small runit service folder. runit restarts a server when it
    exits.
  - A finish script logs each crash and waits longer each time a server fails in
    a row, so a server that can't start doesn't spin.
  - runit's own small logger keeps the logs.
- **Shipping only when something changed:** each promoted install gets a list of
  every file with a fingerprint (a hash) of each.
  - If the list matches what the realm's machine is running, nothing is sent and
    nothing restarts.
  - If it differs, only the changed files are sent, into a new release folder
    beside the old one, and only that realm restarts.
- **Guest accounts:** they keep no journal. A restart doesn't wait for them:
  with only guests online, the realm restarts at once.
- **Existing accounts:** yours and Aurelia's get their passwords reset when
  journals go live, so I dropped the planned login reminder.
- **`wow.ritzmenardi.com`** stays your computer. The rmail journal service there
  will collect each player's locked files from the realm machines over ssh.

**Questions, most blocking first:**
1. **Where each realm's characters live.** One database machine for everything
   means one place to back up. The other way is that each realm machine keeps
   its own world and characters, so a realm machine can be turned off or moved
   as a whole, and only the shared login database sits on the login machine.
   Which do you want?
2. **The name players type** into their client's realm list file, now that
   `wow.ritzmenardi.com` stays home. Another name under ritzmenardi.com, like
   `realms.ritzmenardi.com`, or Linode's own name for the login machine?
3. **The website deployer.** `scripts/push-to-neocities` doesn't exist. The one
   that does, `deploy-to-neocities`, only uploads that project's output into the
   site's `similar-different/` folder. Should the connection page get its own
   small deployer using that project's Neocities library, or go into that
   project's output? And which folder on the site?
4. **Void on Linode.** I believe Linode's list of ready-made systems doesn't
   include Void, which would mean uploading our own image. I haven't checked;
   it's worth a look in your Linode account before that part is built.

Changes to the files other agents might also touch are saved as a patch in
`tmp/shared-memory/journal-agent/`, with the originals beside it. Every file I
touched is in the claims list.

Standing reminder: the disks still have no protection against bit rot.

--------------------------------------------------------------------------------

### User Request 4

> 1. Where each realm's characters live. One database machine for everything
> means one place to back up. The other way is that each realm machine keeps its
> own world and characters, so a realm machine can be turned off or moved as a
> whole, and only the shared login database sits on
>      the login machine. Which do you want?

each machine should have any database it contacts located on it's own machine,
to increase the data processing speed and improve reliability.

the auth database however can exist on it's own device, hardened against any
outside connection, making it difficult to hack. We must also use an instruction
oriented transmission format.

> 2. The name players type into their client's realm list file, now that
> wow.ritzmenardi.com stays home. Another name under ritzmenardi.com, like
> realms.ritzmenardi.com, or Linode's own name for the login machine?

we will come up with a name...

> 3. The website deployer. scripts/push-to-neocities doesn't exist. The one that
> does, deploy-to-neocities, only uploads that project's output into the site's
> similar-different/ folder. Should the connection page get its own small
> deployer using that project's Neocities library, or
>      go into that project's output? And which folder on the site?

nah there we just offer a static link to here.

> 4. Void on Linode. I believe Linode's list of ready-made systems doesn't
> include Void, which would mean uploading our own image. I haven't checked;
> it's worth a look in your Linode account before that part is built.

we shouldn't use Void. We should roll our own Linux system, with only the exact
components we use. It should be incomprehensibly lean, 100% minimal slack.

--------------------------------------------------------------------------------

### Assistant Response 4

> Writing these answers into the plans. First, checking two facts the answers
> rest on: what the world server binary actually loads, and how it talks to the
> login database.

> Recording that in the existing bit-rot plan once the four answers are in.
> Updating the Linode plan first.

I've written all four answers and the cloud-mirror request into the plans;
nothing is committed yet. All the issue links check out.

**Databases and the instruction door.** Each realm machine now keeps its own
world, characters and playerbots databases. They're reached through a local
socket, so no database port is open to anything else. The login database gets a
device of its own that takes no connections from the internet. It answers the
login and realm machines only through a fixed list of numbered instructions,
never SQL text.

I checked the source to see how much has to change:
- **Already numbered:** the server already reaches the login database through
  110 numbered statements. Each is a number plus typed values, so that numbering
  becomes the transmission format with nothing new to invent.
- **Still raw SQL:** 22 places in the server core, 7 in the playerbots module,
  and two of our own Lua scripts write SQL directly. Each has to become a
  numbered instruction of its own.
- **Refused:** an instruction that isn't on the list, or comes from a machine
  not allowed to send it, is refused and logged.

**Your own Linux.** Void is dropped. A tool here builds each machine's system:
1. It starts from that machine's one job and follows what each program loads,
   until nothing new turns up.
2. It copies exactly those files, plus the kernel and runit, into an image.
3. It writes a list of every file with its size and fingerprint, and reports the
   largest ones so leftover weight shows.
4. A test boots the image in a virtual machine here and waits for the server's
   port to answer.

As a starting measure, the world server loads 18 libraries. The biggest is ICU,
a text-handling library made of three files.

**The name** is left as a placeholder until you choose one. **The website**
carries only a fixed link to the connection page. I read "here" as your own
computer at `wow.ritzmenardi.com` serving that page.

**Bit rot.** I added the mirror tool to the existing bit-rot plan rather than
starting a new one:
- **What it pushes:** a chosen set of files to the cloud location, with a
  fingerprint list and repair data for that set. Only files that changed are
  sent.
- **What it compares:** on each run it fingerprints both copies before sending.
  Every path that differs, or exists on only one side, goes into a dated
  discrepancy file. Each line names the side that drifted from the last
  fingerprint both copies agreed on.
- **What it never does:** overwrite a disagreeing file in either direction. You
  read the report and run the repair yourself.

The bit-rot reminder stays in the project's instructions, because so far this is
design, not work.

**Questions, most blocking first:**
1. **Updates to a running machine:** send changed files, or send whole images?
   Sending files means each machine carries a small ssh server and rsync. Whole
   images mean each machine carries neither: every release is a new image and a
   reboot, with the databases on a second disk that survives the reboot. Whole
   images are leaner, and nothing on the machine can be changed from outside.
2. **The cloud location for the mirror:**
   - Linode's file storage: you pay per gigabyte, and checking a file there may
     mean reading it back.
   - A disk on one of our own rented machines: the fingerprinting runs there and
     nothing comes back.

   And which goes first: this project's databases and game data (about 10 GB),
   or whole disks (over a terabyte)?
3. **Bot accounts.** The playerbots module creates its bot accounts in the login
   database. Should realm machines be allowed to write accounts through the
   door? Or should bot accounts be made once from here, leaving the realms only
   able to read?
4. **Does your computer already run a web server** for the connection page?

Here's a puzzle for you: the mirror compares two copies of a file, and if both
changed since they last agreed, two copies can't say which one is right. What
third witness would you trust: the repair data, a third copy, or something else?

--------------------------------------------------------------------------------

### User Request 5

for the custom linux, each component should have it's own compile script. We
should create utilities that are able to be cached, and only recompiled when
something part of them changes. And then, only that part, not the unchanged
whole.

> 1. Updates to a running machine: send changed files, or send whole images?
> Sending files means each machine carries a small ssh server and rsync. Whole
> images mean each machine carries neither: every release is a new image and a
> reboot, with the databases on a second disk that
>      survives the reboot. Whole images are leaner, and nothing on the machine can be changed from outside.

rmail only. the recipient decides what to do with it.

> 3. Bot accounts. The playerbots module creates its bot accounts in the login
> database. Should realm machines be allowed to write accounts through the door?
> Or should bot accounts be made once from here, leaving the realms only able to
> read?

handle it the same way we handle the buddy-bot accounts.

>   4. Does your computer already run a web server for the connection page?

no, but I have a website on neocities. We should host the connection page from
the same server that has the authirzation page. We should only tell them the
connection details once we've made a successful connection, so they don't learn
the backend IP's and ports and such until they're ready to be let in.

DDOS PROTECTION.

> Here's a puzzle for you: the mirror compares two copies of a file, and if both
> changed since they last agreed, two copies can't say which one is right. What
> third witness would you trust: the repair data, a third copy, or something
> else?

any observer looking and thinking "hmmm, that's not right..."

--------------------------------------------------------------------------------

### Assistant Response 5

> Checking how buddy-bot accounts are made, and how rmail moves messages, before
> writing these in.

> Now updating the existing plans to match.

All of today's answers are now in the plans; nothing is committed yet. The links
between plans check out and the lock test still passes all 22 checks.

**Each part built by its own script, and cached.** This is a new plan under the
custom-Linux plan. Every piece of the machines' system is compiled here by its
own script: the kernel, the C library, OpenSSL, MySQL, runit, LuaJIT, rmail and
the game servers. Caching works at two levels:
- **A whole part is skipped** when nothing it's made from changed. Its
  fingerprint covers its own script, its source, the compiler, and the
  fingerprints of the parts it's built against. So a change to OpenSSL rebuilds
  OpenSSL and only the parts that use it.
- **Inside a rebuilt part, only changed source files recompile.** Each part
  keeps its build folder between builds, and a compiler cache sits underneath.

Assembling an image only copies finished parts, so when every part is cached an
image takes seconds.

**Releases by rmail only.** No machine carries ssh or rsync.
- **Sending:** after a promote, if a profile changed, the build machine mails
  its machine only the changed files, with a list of every file's fingerprint.
- **The recipient's rules:**
  - it accepts only mail from the build machine;
  - it accepts only if the release follows the one it is running;
  - it warns players, or restarts at once if only guests are on;
  - it switches to the new folder, restarts, checks the realm came up, and
    switches back if it didn't;
  - it mails back a receipt.
- **The very first image** still has to go up through Linode's own image upload.

**Bot accounts, the buddy way.** The buddy module makes its hidden accounts
inside the realm: the name comes from the owner character's number, and the
password is 8 random bytes nobody is told. So realms get exactly one account
instruction, "make hidden account". The login-database device checks the name is
one of the hidden-account forms and makes the password itself. A realm can't
make an account with a name a person would use, or change any password. Hidden
accounts get no journal key.

**DDoS protection.** This is a new plan: realms closed until you log in.
- **Public:** only the login machine. It serves the connection page, which
  Neocities links to. The page names realms but no addresses or ports. The login
  machine limits login attempts and open connections per address.
- **Behind it:** each realm machine's firewall drops everything except addresses
  on a "let in" list whose entries expire by themselves. After a successful
  login, the login server tells every realm to let that address in for 10
  minutes. An open connection stays open after that. Someone who never logged in
  gets no answer from a realm, even if they know its address.

**Bit rot.** Your answer, "any observer looking and thinking 'hmmm, that's not
right...'", is now the third witness. The discrepancy report goes onto a
documentation page and to you by rmail. Anyone can mark a line "that's not
right" or "that's right", with their name and the time. A repair names the marks
it acted on.

**Questions, most blocking first:**
1. **"The authorization page."** I took it to mean the login machine itself, the
   one the game client logs into, with the connection page served from that same
   machine. Or did you mean a web page where someone signs in with their account
   first, and only then sees the address to put in their client?
2. **The C library.** Now that every part is compiled here, it's an open choice:
   - **glibc** is what the game server is tested with.
   - **musl** is much smaller, but MySQL and the server may need patches to
     build against it.

   Start with glibc and try musl later?
3. **The compiler.** Should it be a part too, so the whole chain is built here?
   That makes the first build long.
4. **The cache folders** will be many gigabytes. Should they go on `/mnt/kaun`,
   or on the other disk?

Here's a puzzle for you: a realm machine takes releases only when they follow
the one it's running. Say a release mail is lost, and the next one arrives built
on a release that machine never got. The machine refuses it and asks for a whole
release. What should it do while it waits: keep running the old release, or tell
its players something is behind?

--------------------------------------------------------------------------------

### User Request 6

for the connection page, can we create a scrollable listing that lists all our
profiles? It should be frutiger aero themed, similar to
/home/ritz/documents/ai-stuff/ - anyway for each profile it should expand and
list details and changes, only the important ones. Each entry points to the same
connection details, but in this way users can see each of them detailed.

>   2. The C library. Now that every part is compiled here, it's an open choice:
>      - musl is much smaller, but MySQL and the server may need patches to build against it.

excellent, better to support both

> 3. The compiler. Should it be a part too, so the whole chain is built here?
> That makes the first build long.

yeah

> 4. The cache folders will be many gigabytes. Should they go on /mnt/kaun, or
> on the other disk?

which cache folders?

> Here's a puzzle for you: a realm machine takes releases only when they follow
> the one it's running. Say a release mail is lost, and the next one arrives
> built on a release that machine never got. The machine refuses it and asks for
> a whole release. What should it do while it waits:
>   keep running the old release, or tell its players something is behind?

they should take releases only from me, and they should (when I git push) and
they should never be lost. We just confirm, TCP style.

--------------------------------------------------------------------------------

### Assistant Response 6

> Looking at the style reference and the profile pages the listing will be
> generated from.

> Each profile page has a "What you get" section; checking its shape so the
> generator can read it.

> The generator will read each profile page's own "What you get" and "What you
> do not get" lists, using the points its authors already bolded as the
> important ones. Writing it now.

> Page written: six realms, one leftover internal reference reported (beta's
> page names its setup step in a sentence). Taking a screenshot to check how it
> looks.

Closed view looks right. Alpha shows no summary and Beta's starts lowercase;
checking their pages, and rendering one realm opened.

--------------------------------------------------------------------------------

### User Request 7

[Image: original 900x2200, displayed at 818x2000. Multiply coordinates by 1.10
to map to original image.]

--------------------------------------------------------------------------------

### User Request 8

[Image: original 900x2200, displayed at 818x2000. Multiply coordinates by 1.10
to map to original image.]

--------------------------------------------------------------------------------

### Assistant Response 8

> Colon fix confirmed: "Northrend: no basic character can use it." now reads
> whole. Filling in the two pictures' notes, then updating the plans with your
> other answers.

> Now the plan updates: musl and glibc both, the compiler as a part, and
> releases confirmed TCP-style on git push.

The connection page is built and generated from the realms' own pages, and your
other answers are in the plans. Nothing is committed yet.

**The connection page.** The generator writes it to
`tmp/shared-memory/connection-page/index.html`:
- All six realms are listed in realm order inside a scrolling glass panel. I
  borrowed the Aero look from your hall-of-president-spirits project: a
  sky-to-grass gradient, frosted glass, aqua gel buttons and drifting bubbles.
  The bubbles stay still for readers who ask their system for reduced motion.
- Opening a realm shows "What is here" and "Left out on purpose", taken from
  that realm's own documentation page. The important points are the ones its
  authors already put in bold; for a point with no bold opening, its first
  sentence stands in. Each point opens to its detail, and each realm ends with a
  button down to the one "How to connect" section.
- Issue numbers, setup-step names and file paths are taken out of the text.
  Anything left over is printed as a warning. Today there's one: beta's page
  names its setup step "E012" in a sentence of its own, so that line needs
  mending on beta's page, which I didn't touch.
- No realm addresses or ports appear anywhere. The login machine's name is
  required. Since none is chosen yet, `--preview` writes the page with a banner
  saying it can't be used to connect; with neither option the tool stops with an
  error.
- `--screenshot basic` photographs the page at desktop and phone width, with the
  Basic realm opened. It files each picture in a new `development-history/`
  folder under the next number, with notes. The first two pictures are there.

The account and journal sections aren't on the page yet, because those features
aren't built.

**Your other answers, now in the plans:**
- **musl and glibc both.** Every part that uses a C library is built once per
  library, so either kind of image can be made and the two compared.
- **The compiler as a part.** It's built first, once from this machine's
  compiler and then from itself. From then on, every other part's fingerprint
  includes our compiler, not this machine's.
- **Releases from you only, on git push, confirmed TCP style:**
  - A promote prepares a release, and your push sends it.
  - Every release is signed with a key that stays on your computer, and each
    machine carries the public half. A build with uncommitted changes is never
    sent.
  - Each machine numbers its releases and confirms each one. A release that
    arrives early is held until the gap is filled. Anything unconfirmed is
    resent until it's confirmed.
  - A planned tool, `scripts/release-status`, will show per machine what was
    sent, what was confirmed and what's still waiting.

**Which cache folders:** the ones the parts builder will make. None exist yet:
- **each part's finished output,** one folder per fingerprint, so an unchanged
  part is never built again;
- **each part's build folder,** kept so a changed part recompiles only its
  changed files;
- **the compiler cache's folder.**

For scale, today's one game-server build folder is 5.4 GB. There would be one
like it for each large part (the kernel, MySQL, the compiler, each server), and
twice over for the two C libraries. The disk `/mnt/kaun` is 40% used. Should
they go there, or on your other disk?

**Still open:** "the authorization page". I've taken it to mean the login
machine, the one the game client logs into, serving this page too. Or did you
picture a web page where people sign in first and only then see the connection
details?

Here's a puzzle for you: every release is signed with a key that lives only on
your computer. If that computer's disk rots, the key goes with it, and no
machine will ever accept a release again. Where would you keep the second copy
of a key whose whole job is to be the only one?

--------------------------------------------------------------------------------

### User Request 9

the connection page looks great, we'll probably only need minor tweaks to it.
For example when you open a profile it scrolls within the iframe and it should
scroll the whole page. But it looks good. Let's focus on the other work.

Can we also add a comparison table or something? only for the major features
that are shared. We can have a record that says "and many more features!" with
every profile selected except alpha lol

> For scale, today's one game-server build folder is 5.4 GB. There would be one
> like it for each large part (the kernel, MySQL, the compiler,
> each server), and twice over for the two C libraries. The disk /mnt/kaun is
> 40% used. Should they go there, or on your other disk?

kaun is fine.

> Still open: "the authorization page". I've taken it to mean the login machine,
> the one the game client logs into, serving this page too. Or
> did you picture a web page where people sign in first and only then see the
> connection details?

nah anyone can see the connection details but we need a way to make an account
for them. Also we should tell them about the guest accounts on the login page.



<pasted_content id="9a5a">
> Here's a puzzle for you: every release is signed with a key that lives only on
> your computer. If that computer's disk rots, the key goes
> with it, and no machine will ever accept a release again. Where would you keep
> the second copy of a key whose whole job is to be the only
  one?
</pasted_content id="9a5a">


I will just log into linode and use their ssh console or whatever.

okay. What's left unbuilt? Any open questions?

--------------------------------------------------------------------------------

### Assistant Response 9

> Fixing the scroll and adding the comparison table first. The table's cells
> need evidence from the realms' own pages, so I'm looking for the shared
> features there.

> Every cell will carry a quotation from its realm's page, and the generator
> stops with an error if the quote isn't there, so the table can't drift from
> the pages.

> Table works. Two cells wrap ("40–80", "cc-test"), so I'm keeping them on one
> line, then filling in the new pictures' notes.

> Now recording the answers in the plans.

The page now scrolls as a whole, and it has a "Side by side" table before "How
to connect". Each filled cell quotes the words in that realm's own page that
prove it, and the generator stops with an error if that quote disappears. The
last row, "and many more features!", is ticked for every realm but alpha.

I've recorded your other answers in the plans:
- **Cache folders** go on kaun, and I used the same answer for the per-profile
  build folders.
- **The page is public.** It will list the guest accounts, read from the same
  SQL that creates them, plus a way to make your own account.
- **A lost signing key** is fixed through Linode's console. So every machine
  image carries one console login for you, which is the only way in that isn't
  rmail.

Nothing is committed: your rule is to commit when an issue is complete, and none
is.

## Built
- **The journal lock:** it seals a journal so only the player's password opens
  it. A 22-check test passes, and there's a command-line tool to open a journal.
- **The connection page generator:** it writes the realm list, the comparison
  table and the connect steps. It also photographs the page into
  `development-history/` (four pictures so far, with notes). One leftover
  internal reference remains in beta's own page, a sentence naming its setup
  step; I left that page alone.

## Not built yet
**Building**
- Separate build folders and a build lock for each profile, so profiles can
  build at the same time.
- The parts builder: a compile script per part (the compiler, glibc, musl,
  kernel, MySQL, runit, LuaJIT, rmail, the servers), with two-level caching.
- The image assembler, and a test that boots each image in a virtual machine.

**Machines**
- The list of which machine does which job.
- The Linode machines themselves, with their runit services.
- The login-database device and its instruction door.
- The firewall that lets in only players who just logged in.
- Releases by rmail: signed, numbered, confirmed and resent until confirmed.

**Journals**
- Making the key when an account is created (a server patch plus a new table).
- Recording what each client saw, inside the world server.
- Copies of rmail texts in the journal.
- The rmail address that sends a player their journal.
- The browser page that opens a journal.

**Connection page**
- The account section with the guest accounts, and the journal section.
- Serving the page from the login machine.

**Bit rot**
- The fingerprint lists and repair data.
- The cloud mirror and its discrepancy reports.
- Observers' "that's not right" marks.

## Open questions, most blocking first
1. **Making your own account:** by rmail, by a form on the connection page, or
   both? The form would show the login machine the password once, which is also
   when the journal key gets made.
2. **Which realms go public?** All six, or not cc-test (the custom client's test
   server) or alpha?
3. **The cloud location for the bit-rot mirror:** Linode's file storage (paid
   per gigabyte; checking a file may mean reading it back), or a disk on one of
   our own rented machines? And mirror this project's databases and game data
   first, or whole disks?
4. **Bit rot, what first:** fingerprints and repair data on the disks as they
   are, or moving to a filesystem that checksums file contents (btrfs or ZFS)?
   And where does the secret key for signed fingerprints live?
5. **Building at once on this machine:** should several profiles actually
   compile at the same time here, or is it enough that their folders are kept
   apart so order doesn't matter?
6. **Login-database speed:** one round trip per login lookup, or should each
   realm keep a short-lived copy of the account rows it uses?
7. **Who may ask for a journal:** anyone who names the account, or only the
   rmail address that made it? The files are locked, but their names and dates
   show when someone played. And is there a size limit on an rmail message?
8. **Which text goes in a journal:** conversation menus, quest text, and mail
   read in game? Leave out addon messages?
9. **Linking an rmail address to an account:** rmail messages go to an address,
   not an account. Should the journal use the account-creation pairing?
10. **Journals over time:**
    - An old journal stays locked to an old password. Is that fine?
    - How long are journals kept, and can a player ask for theirs to be deleted?
    - Should the server tell players at first login that what they say lands in other players' journals?
11. **Passwords with accented letters:** refuse them at account creation, so the
    server, the tools and the browser always make the same key?
12. **Small numbers I've proposed:**
    - restart warnings at 5 minutes, 1 minute and 10 seconds;
    - how long a realm gets to start before rolling back (how long does a world with its bots take to load today?);
    - "let in" lasting 10 minutes;
    - the first image uploaded by hand through Linode.

The name players type into their realm list is still yours to choose; the page
shows "name not chosen yet" until then.

Here's a puzzle for you: the table can only say what the pages prove, so "AI
playerbots in the world" is blank for Basic. Basic will have each player's own
buddies but no wandering bots. Is a buddy the same feature as a playerbot, or a
different row?

--------------------------------------------------------------------------------

