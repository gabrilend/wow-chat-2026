# 157h - Promotion Ships to the Host

## Status
- Created: 2026-10-26
- Parent: Issue 157 (three-machine-deployment)
- Phase: 1
- **Blocked by:** 157g, 157b, 136c, 157i (the Linode machines, the deploy
  tool, each profile's build kept apart, the machines' own system)

## Origin

The owner, 2026-10-26: "can we make part of the build promotion from
shadow to main that we also push it to my linode instance and restart the
server and all that?"

Asked whether every promote should ship: "only when something changed
for that server".

On guest accounts: they "can be kicked off whenever".

Asked whether a running machine receives changed files (over ssh and
rsync) or whole new images: "rmail only. the recipient decides what to
do with it."

Asked what a machine does when a release is lost: "they should take
releases only from me, and they should (when I git push) and they should
never be lost. We just confirm, TCP style."

## Overview

Today a build goes compile → validate → promote: the new binaries are
built into a shadow folder, a test start proves they run, and only then
are they copied over the installed ones (`scripts/compile`,
`scripts/validate`, `scripts/promote`; issue 115). This adds a fourth
step: if the promoted profile differs from what its realm machine is
running, the difference is sent to that machine as an rmail message.
The machine itself decides whether and when to take it, restarts its
realm, and answers by rmail. Every other realm keeps running.

No machine carries ssh or rsync; no one logs into a machine to change
it. rmail is the only way in.

## Current Behavior

- `scripts/promote --profile P` copies `installed-files-shadow/` over
  `installed-files-P/`, keeping the user's edited `.conf` files, and
  stops there. It runs at the end of `scripts/validate`, which runs at the
  end of `scripts/compile`.
- There is no deploy tool yet (157b) and no Linode machine (157g).
- rmail (`/home/ritz/programs/r-mail/`) moves plain-text messages between
  two daemons over HTTP, each contact pair sharing a secret; a message
  with an attachment is offered to the recipient, who accepts or denies
  it, and is then sent in chunks.

## Intended Behavior

### When: on git push, from the owner only

A promote prepares a release; it is sent when the owner pushes. The
push hook (`.git/hooks/pre-push`, issue 190's chain; a shared file, so
added by whichever agent holds it) finds, for each profile, a promoted
build whose commit is in the push, and sends it. A build made from a
working tree with uncommitted changes is never sent (its fingerprint
records "dirty"), so every release is a commit anyone can check out.

Releases are signed with the owner's own signing key (libsodium's
public-key signatures, the key kept on the owner's computer only); each
machine's image carries the matching public half and takes nothing else,
whatever rmail contact it came through.

### Never lost: confirmed like TCP

Each machine has its own release sequence: 1, 2, 3, ... The sender keeps
every release it sent to a machine until that machine confirms it:

- The machine answers each release it receives with "got N" (and, once
  applied, the receipt below), and takes releases strictly in order.
- A release with a later number than the next expected is held, not
  applied, and the machine answers "got N-1, need N"; the gap is filled
  first, then the held one is applied.
- The sender resends a release not confirmed within a time, waiting
  longer each try, and never forgets it; `scripts/release-status` shows,
  per machine, the last number sent, the last confirmed, and anything
  waiting.
- A duplicate (a resend that crossed a late confirmation) is confirmed
  again and otherwise ignored.

So a release cannot be lost silently: it is either confirmed or still
being resent, and the owner can see which.

### Only when something changed

The promoted tree's fingerprint is a list of every file the realm machine
would receive (binaries, generated configs, Lua scripts, module configs,
map data) with a BLAKE2b hash of each, sorted by path, written to
`installed-files-P/.ship-fingerprint`. The development machine keeps the
fingerprint each machine last reported running (from its receipts,
below). After a promote, the two are compared:

- **the same:** nothing is sent; the promote says "P: unchanged on
  <machine>, not shipped".
- **different:** the files that differ are listed (first 20, and the
  count), and a release message is sent.

### The release message (sender: the development machine)

To the realm machine's rmail address, subject `release <profile>
<commit>`:

- the body: the commit, the new fingerprint list, the list of changed
  files, and the fingerprint list it replaces;
- the attachment: only the changed files (and a list of removed ones),
  as rmail's attachment.

### The recipient decides (the realm machine)

The realm machine runs an rmail daemon, reachable only from the
development machine's address (its firewall), and a receive hook, part
of its image (157i). On a release message the hook decides, by its own
rules, written in its image:

1. **Is it from the owner?** Its signature must check against the
   owner's public key carried in the image; anything else is denied and
   logged.
2. **Is it next, and does it fit?** Its number must be the next in this
   machine's sequence (else held or ignored, above), and the fingerprint
   list it replaces must equal what this machine is running. A mismatch
   there means the machine itself changed, not a lost release: it is
   denied, logged, and the reply says which files differ.
3. **When?** The attachment is accepted and unpacked into a new folder,
   `releases/<commit>/` (unchanged files linked from the running release,
   not copied). The realm warns its players with the server's own
   countdown (5 minutes, 1 minute, 10 seconds; it saves every character
   before it stops), or restarts at once if only guest accounts (1003)
   are online: guests "can be kicked off whenever".
4. **Swap and start.** `installed-files-P` becomes a link to the new
   folder; runit starts the realm again. The server applies any new SQL
   itself as it starts (189d).
5. **Check.** Process running, port open, realm row online, log reached
   "World initialized". If not within the set time, the link goes back
   to the previous release, the realm starts again, and the reply says
   so with both releases' last log lines.
6. **Reply.** An rmail message back: taken or denied (and why), the
   fingerprint it now runs, files changed, seconds the realm was down,
   each check passed or failed. This is the receipt, kept on the
   development machine as `tmp/shared-memory/ship-P.goodbye` and in the
   rmail inbox.

The login machine and the login database's device take releases the same
way, each only when its own files changed; their restarts warn every
realm first.

**Profiles built in parallel ship in parallel**: each promote sends to
its own realm machine, so two releases never meet on one machine. The
login machine is the one place two could; its hook takes one release at
a time and denies a second while one is being applied (the reply says
"busy, send again").

## Suggested Implementation Steps

1. The fingerprint: a tool that writes `.ship-fingerprint` for a tree and
   one that compares two and lists the differences. Tested on two scratch
   trees differing by one byte, one file added, one removed.
2. The sender: `scripts/promote` writes the fingerprint and marks the
   build ready; the push hook compares, signs, numbers and writes the
   release message into the development machine's rmail outbox, and the
   resend loop keeps every unconfirmed release going
   (`scripts/release-status` shows it). `scripts/promote` and the push
   hook are shared files; each change is claimed and made when no other
   agent holds it.
2a. Test the confirmation: with a scratch receiver, drop release 2 in
   transit; release 3 is held, 2 is resent and applied, then 3; a
   duplicate of 2 is confirmed and ignored.
3. The recipient's hook, in Lua (rmail's hooks are), with its rules as a
   table at the top.
4. rmail and LuaJIT as parts of the machine image (157i1).
5. Test with two rmail daemons on this machine and the realm machine's
   image in QEMU: an unchanged promote sends nothing; a changed one is
   taken and the realm restarts from it; one that does not fit is
   denied; a failing start rolls back; each reply arrives.
6. Datapath: `docs/datapaths/deployment.md` gains the promote →
   fingerprint → rmail → hook → restart → reply path.

## Open Questions

1. **How long a warning?** 5 minutes, 1 minute, 10 seconds is the
   proposal, skipped when only guests are online.
2. **What counts as a failed start.** How long to wait for "World
   initialized" before rolling back? How long does a world with its bots
   take to load on the development machine today?
4. ~~Losing the signing key~~. Answered 2026-10-27: "I will just log
   into linode and use their ssh console or whatever." Linode's console
   (Lish) reaches a machine's own console without any network service on
   the machine, so every image carries a console login (on the serial
   console only, for the owner's account) through which a new public key
   can be put in place. That login is part of each image (157i).
3. **The first image.** rmail carries every release after the first;
   the first image goes up through Linode's own image upload (by hand,
   once, or by the deploy tool through Linode's interface). Agreed?

## Related
- `issues/157g-linode-machines-one-per-realm.md`
- `issues/157b-deploy-tool.md`
- `issues/157i-a-linux-of-only-what-runs.md`
- `issues/136c-every-profile-built-at-once.md`
- `issues/1003-rmail-account-creation.md`: the guest accounts
- `issues/completed/115-shadow-build-setup.md`: the shadow → promote flow
- `issues/completed/189d-sql-as-patches.md`: the server applies its own SQL
