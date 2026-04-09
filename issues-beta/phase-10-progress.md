# Phase 10 Progress: External Integration (rmail)

## Effect

The game breathes beyond its borders. Messages flow in and out.

## Status: Not Started

## Goal

Bridge the isolated WoW server with the external world through rmail - a
file-based encrypted messaging system. Players interact with the game from
outside the client. Information becomes portable. Accounts become ephemeral.

---

## Issues

Phase 10 issues are **tracking issues** - they coordinate rmail implementations
that touch multiple phases. Each tracking issue references its component parts.

### Core Infrastructure (Phase 10 Primary)

| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 313 | rmail-dns-style-addresses | Open | Foundation: naming convention |
| 315 | rmail-login-flush-hook | Open | Foundation: queue priming |
| 317 | rmail-account-creation | Open | Foundation: account lifecycle |

### Service Implementations (Cross-Phase)

| Issue | Title | Status | Impl Phase | Notes |
|-------|-------|--------|------------|-------|
| 306 | rmail-ingame-bridge | Open | 10 | Mail service standalone |
| 314 | rmail-feedback-mailbox | Open | 10 | Feedback service standalone |
| 163 | custom-class-submission | Open | 7 | Classes service (port 4662) |
| 310 | narrator-subscription | Open | 9 | Narrator service (port 4862) |
| 164 | rmail-ingame-text-editor | Open | 10 | QoL: compose in-game |

### Issue Hierarchy

```
Phase 10 (Coordination)
│
├── 313: DNS-style addresses
│   └── Affects: ALL services
│
├── 315: Login flush hook
│   └── Affects: 306 (mail), 310 (narrator)
│
├── 317: Account creation
│   └── Standalone (port 4562)
│
├── 306: Mail bridge
│   ├── Depends: 313, 315
│   └── Standalone (port 4762)
│
├── 314: Feedback mailbox
│   └── Standalone (port 4962)
│
└── Cross-phase references:
    ├── Phase 7, Issue 163: Custom classes (port 4662)
    └── Phase 9, Issue 310: Narrator feed (port 4862)
```

## Completed: 0/6 (Phase 10 primary issues)

---

## Before State

The game server is an island:
- Accounts created manually via console or SQL
- In-game mail only accessible through WoW client
- No way to interact with game state from outside
- Characters and accounts persist indefinitely
- Information stays inside the game

## After State

The game server has porous boundaries:
- Accounts created/destroyed via rmail messages
- In-game mail forwarded to external inbox
- External messages delivered to in-game mailbox
- Account lifecycle tied to message lifecycle
- Information flows bidirectionally

---

## Completion Criteria

- [ ] Guest accounts with public credentials exist (24 permanent)
- [ ] rmail accounts created by sending message
- [ ] Deleting rmail message deletes account
- [ ] In-game mail forwarded to rmail subscribers
- [ ] External messages delivered to in-game mailbox
- [ ] DNS-style addresses work (wow.ritzmenardi.com/service)
- [ ] Login triggers queue flush for pending messages
- [ ] Feedback mailbox collects player messages

---

## Key Files

### To Create
```
game-mail/
├── accounts/
│   ├── inbox/
│   ├── outbox/
│   ├── config
│   └── scripts/
│       ├── account-create.lua      # on_receive
│       └── account-delete.lua      # on_delete
├── mail/
│   ├── inbox/
│   ├── outbox/
│   ├── config
│   ├── subscriptions.txt
│   ├── .pending-forwards.txt
│   └── scripts/
│       ├── mail-receive.lua        # on_receive
│       ├── mail-onsend.lua         # on_send
│       └── mail-onlogin.lua        # flush
├── narrator/
│   └── (similar structure)
└── feedback/
    ├── inbox/
    └── config
```

### Existing
- `docs/rmail-integration.md` - User guide
- `issues/306-rmail-ingame-bridge` - Mail bridge spec
- `issues/317-rmail-account-creation` - Account system spec

---

## Dependencies

- Phase 1 (foundation) - ALE must work for hooks
- Phase 9 (narrators) - Narrator subscription uses this infrastructure

---

## Service Architecture

| Service | Port | Purpose | Hooks |
|---------|------|---------|-------|
| accounts | 4562 | Account lifecycle | on_receive, on_delete |
| classes | 4662 | Custom class submission | on_receive |
| mail | 4762 | Game mail bridge | on_receive, on_send |
| narrator | 4862 | Speech subscription | on_receive, on_send |
| feedback | 4962 | Player feedback | on_receive only |

Port pattern: 4x62 where x increments per service.

---

## The rmail Protocol

### What It Is

rmail is file-based messaging:
- Inbox: files appear when messages arrive
- Outbox: write file to send message
- Contacts: list of known recipients with tokens
- Hooks: scripts triggered on events

### Why File-Based

```
THOUGHT: Files are the universal interface.

Every program can read files. Every program can write files.
No library dependencies. No protocol negotiation.
The filesystem IS the API.

A message is just bytes. A file is just bytes with a name.
The name is metadata. The contents are payload.
Directories are categories. Permissions are access control.

We already have all the infrastructure. We just use it differently.
```

### Encryption Model

Each contact has a shared token (symmetric key):
- Messages encrypted with AES-256-GCM
- Token shared out-of-band (Discord, email, etc.)
- No key exchange protocol needed
- Change token to revoke access

```
THOUGHT: Shared secrets are simpler than PKI.

Public key infrastructure solves a problem we don't have:
communicating with strangers. We're not strangers.
We're a small community playing a game together.

A shared secret is just a password. Everyone understands passwords.
The token is "the password to talk to this service."
No certificates. No revocation lists. No trust hierarchies.

If a token leaks, generate a new one. Tell your friends.
Human-scale security for human-scale systems.
```

---

## Account System (317)

### Two Pathways

**Guest Accounts (24 permanent)**
```
filament  / cherry-ribbon
verbose   / table-aperture
clock     / super-migration
...
```

**rmail Accounts (ephemeral)**
```
to: wow.ritzmenardi.com/accounts

myusername
mypassword
```

### Why Two Pathways

```
THOUGHT: Friction is a design choice.

Guest accounts have zero friction. Anyone can play immediately.
No registration. No email verification. No waiting.
Just pick a name from the list and log in.

But shared accounts mean shared characters. Your work isn't yours.
Someone else might delete your character. Or steal your gear.
That's the tradeoff for zero friction.

rmail accounts have friction. You need rmail installed.
You need to understand the system. You need to keep your message.
But the account is YOURS. Private. Persistent (as long as you want).

Different players want different things. Offer both.
```

### Bi-Directional Deletion

```
THOUGHT: Data sovereignty through message lifecycle.

Your account exists because your message exists.
Delete the message, delete the account.
This isn't a bug - it's the feature.

You control your data. Not through a settings page.
Not through a support ticket. Through the filesystem.
Delete a file. Done.

The mapping is simple: message → account.
No orphaned accounts. No forgotten data.
The system cleans itself.
```

### Protected Accounts

Guest accounts are protected from deletion:
```lua
local PROTECTED = {
    filament = true, verbose = true, ...
}
```

```
THOUGHT: Public infrastructure needs durability.

Guest accounts are shared infrastructure.
Like park benches. Like public restrooms.
They need to survive individual users.

If alice sends "filament / cherry-ribbon" to accounts,
and then deletes her message, filament shouldn't disappear.
Filament belongs to everyone.

The protected list is small. It's curated.
It exists to preserve the commons.
```

---

## Mail Bridge (306)

### Public Subscriptions

Anyone can subscribe to any character's mail.

```
THOUGHT: Privacy is opt-in, not default.

In the real world, mail is private because of effort.
You'd have to physically intercept the envelope.
Digital privacy is different. It requires active protection.

We chose not to protect it. Subscription is public.
This creates information gameplay. Espionage. Intelligence.
Guild leaders monitoring guild bank mail.
Rivals tracking each other's movements.

If you want privacy, don't use the system.
Or use it strategically. Send misinformation.
The system enables games within the game.
```

### Item Icons as Images

Mail with items → PNG attachments of item icons.

```
THOUGHT: Representing objects outside their native context.

An item in WoW is a database row. Entry ID, stats, enchants.
Outside WoW, that's meaningless numbers.

But an item also has an ICON. A visual representation.
Icons are just images. Images work everywhere.

So we translate: database row → PNG file.
The item becomes portable. You can see what you received.
Not the same as having it, but enough to understand it.

This is lossy translation. That's okay.
The goal isn't perfect fidelity. The goal is comprehension.
```

### on_send Chain

Messages self-drain through hook chains:
1. Write message to outbox
2. rmail delivers
3. on_send hook checks for more
4. Write next message
5. Repeat until queue empty

```
THOUGHT: Event-driven beats polling.

A daemon that polls every 30 seconds wastes cycles.
Most of the time, nothing changed. But it checks anyway.

Hooks only fire when something happens.
A message delivered → check for more.
No delivery → no check.

The system is quiet when idle. Active when needed.
Energy proportional to work.
```

---

## DNS-Style Addresses (313)

### Format

```
wow.ritzmenardi.com/accounts
wow.ritzmenardi.com/classes
wow.ritzmenardi.com/mail
```

### Why This Format

```
THOUGHT: Self-documenting addresses.

"ghostsong-accounts" is arbitrary. A made-up name.
"wow.ritzmenardi.com/accounts" tells you:
- It's for wow
- It's hosted at ritzmenardi.com
- It's the accounts service

You could guess the others. /classes, /mail, /narrator.
The naming convention IS documentation.

URLs work because they're hierarchical and readable.
We borrowed the pattern. Not the protocol. Just the shape.
```

### Port Allocation Pattern

```
4562 - accounts
4662 - classes
4762 - mail
4862 - narrator
4962 - feedback
```

```
THOUGHT: Patterns reduce cognitive load.

4x62. x is the service index.
You see 4762, you know it's service 7.
You need narrator, you know it's 4862.

Humans are pattern-matching machines.
Give them a pattern, they'll remember.
Random numbers are harder than predictable sequences.
```

---

## Login Flush Hook (315)

### The Problem

Messages queue for offline recipients.
No trigger to attempt delivery when they come online.

### The Solution

Player login → flush script → write to outbox → rmail tries.

```
THOUGHT: Login is the natural heartbeat.

Players come and go. They log in. They log out.
Each login is a signal: "someone is present."

If alice subscribes to Thrall's mail, messages queue.
When alice logs in (to the game), she's probably at her computer.
Her rmail is probably running. Good time to try delivery.

We don't know FOR SURE she's online to rmail.
But login is a reasonable heuristic.
Better than nothing. Better than arbitrary timers.
```

### One Message Per Subscriber

The flush writes ONE message per subscriber:
```lua
if not attempted[subscriber] then
    writeToOutbox(...)
    attempted[subscriber] = true
end
```

```
THOUGHT: Prime the pump, let it drain.

We don't dump the entire queue. Just one message each.
The on_send hook handles the rest.

If alice has 50 pending messages:
- Flush writes 1 to outbox
- Delivery succeeds → on_send fires
- on_send writes message 2 to outbox
- Repeat until all 50 delivered

The chain is self-sustaining. We just start it.
One spark lights the fire.
```

---

## Feedback Mailbox (314)

### Simplest Service

```
game-mail/feedback/
├── inbox/     # Messages accumulate
└── config     # on_receive hook (maybe just logs)
```

No automation. No hooks that modify anything.
Messages go in. Human reads them eventually.

```
THOUGHT: Not everything needs to be automated.

Feedback is human-to-human communication.
A player has thoughts. They write them down.
A developer reads them later. Maybe responds.

The system just moves bytes. No intelligence required.
No parsing. No validation. No workflow.

Sometimes the right amount of automation is zero.
The value is in the transport, not the processing.
```

---

## Notes

### Implementation Order

1. **317 - Account Creation** - Foundation for everything
2. **313 - DNS Addresses** - Organize before adding services
3. **315 - Login Flush** - Infrastructure for mail/narrator
4. **306 - Mail Bridge** - First real service
5. **314 - Feedback** - Simple, low risk
6. **164 - Text Editor** - Quality of life

### Testing Strategy

Each service needs:
- Positive path: message arrives, action taken
- Negative path: malformed message, graceful failure
- Edge cases: offline recipient, duplicate request
- Deletion: message removed, side effects correct

### Security Audit

Before going live:
- Tokens are random and long (32+ bytes)
- Protected list is complete
- Deletion hooks check protected list
- No SQL injection in account creation
- Rate limiting on account creation?

---

## Thoughts Layer: Why rmail?

```
THOUGHT: Why not just use email?

Email is complicated. SMTP, IMAP, MX records, spam filters.
Running a mail server is a job. We don't want that job.

rmail is simple. Files in directories. Lua scripts.
We can understand all of it. We can debug all of it.
When something breaks, we can fix it.

Email is industrial infrastructure for planet-scale messaging.
rmail is a hand tool for a small community.
Right tool for the scale.
```

```
THOUGHT: Why bridge at all?

The game could be isolated. Many are.
Log in to play. Log out. Done.

But isolation limits creativity. You can only do what the
client allows. The client is closed source. We can't change it.

The server is ours. We can add hooks. We can expose data.
rmail is the seam where our code meets the world.

Every hook is a possibility. Every message is a connection.
The game becomes more than the game.
```

```
THOUGHT: Why ephemeral accounts?

Traditional accounts are permanent. Delete requires support ticket.
GDPR made this a legal requirement. Still friction.

What if the account IS the message?
The file is proof you created it. Delete file = delete account.
No support tickets. No waiting. Immediate effect.

This only works because rmail is bidirectional.
Sender deletion propagates to recipient.
The ecosystem supports the pattern.

Not all accounts should be ephemeral. Guest accounts persist.
But for those who want control, the option exists.
```

---

## Related Phases

- **Phase 7** - Custom class submission via rmail
- **Phase 9** - Narrator subscription via rmail
