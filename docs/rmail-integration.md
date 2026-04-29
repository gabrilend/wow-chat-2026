# rmail Integration Guide

rmail is a file-based encrypted messaging system used for server communication.
This guide explains how to set up rmail to interact with Everland Ghostsong.


## What You Can Do With rmail

| Purpose | Contact Entry | Port | Description |
|---------|---------------|------|-------------|
| Account Creation | `wow.ritzmenardi.com/accounts` | 4562 | Create personal game accounts |
| Custom Classes | `wow.ritzmenardi.com/classes` | 4662 | Submit custom class definitions |
| In-Game Mail | `wow.ritzmenardi.com/mail` | 4762 | Subscribe to character mailboxes |
| Narrator Feed | `wow.ritzmenardi.com/narrator` | 4862 | Subscribe to narrator speech and TTS |
| Feedback | `wow.ritzmenardi.com/feedback` | 4962 | Send feedback, bug reports, suggestions |


## Installing rmail

### Download

```bash
git clone https://github.com/gabrilend/r-mail.git
cd r-mail
./scripts/install.sh
```

The installer compiles dependencies (luasocket, crypto library) and creates
your mailbox directory at `~/mail/`.

### Mailbox Structure

After installation:

```
~/mail/
├── inbox/       # Messages you receive
├── outbox/      # Messages you send (write files here)
├── contacts     # Your contact list
└── config       # rmail configuration
```


## Setting Up Contacts

To communicate with the game server, add entries to your contacts file.

### Contact File Format

```
// ~/mail/contacts

// Account creation service
wow.ritzmenardi.com/accounts.ip    = wow.ritzmenardi.com
wow.ritzmenardi.com/accounts.port  = 4562
wow.ritzmenardi.com/accounts.token = "public-accounts-token-here"

// Custom class submission
wow.ritzmenardi.com/classes.ip    = wow.ritzmenardi.com
wow.ritzmenardi.com/classes.port  = 4662
wow.ritzmenardi.com/classes.token = "your-author-token-here"

// In-game mail subscription
wow.ritzmenardi.com/mail.ip    = wow.ritzmenardi.com
wow.ritzmenardi.com/mail.port  = 4762
wow.ritzmenardi.com/mail.token = "your-mail-token-here"

// Narrator TTS subscription
wow.ritzmenardi.com/narrator.ip    = wow.ritzmenardi.com
wow.ritzmenardi.com/narrator.port  = 4862
wow.ritzmenardi.com/narrator.token = "your-narrator-token-here"
```

Each contact entry has three fields:
- `.ip` - Server address (hostname or IP)
- `.port` - Port number for that service
- `.token` - Shared secret for encryption (both sides must match)

### Getting Tokens

**Account creation** uses a public token - see the server website or ask in Discord.

**Other services** require exchanging tokens with the server admin:
1. Generate a token: `openssl rand -hex 32`
2. Share with the admin out-of-band (Discord, email, etc.)
3. Admin adds your token to their server
4. You add the same token to your contacts file


## Sending Messages

Messages are plain text files in your outbox. The first line specifies the
recipient using the `to:` header.

### Basic Format

```
to: contact-name

message body here
```

The contact name must match an entry in your contacts file.

### Example: Create Account

Create a file in `~/mail/outbox/` with any filename:

```
to: wow.ritzmenardi.com/accounts

myusername
mypassword
```

- Line 1 after headers: your desired username
- Line 2: your desired password

rmail syncs automatically. You'll receive a confirmation in `~/mail/inbox/`.

### Example: Submit Custom Class

```
to: wow.ritzmenardi.com/classes
subject: CLASS: knight

knight = {}
knight.name        = "Knight"
knight.description = "A holy bodyguard"
knight.stat_growth = "paladin"

knight.schools = {}
knight.schools[1] = "Vitality"
knight.schools[2] = "Dedication"
knight.schools[3] = "Valor"

knight.abilities = {}
knight.abilities[139] = { level = 8, cost = 1500, school = 1 }
-- ... rest of class definition
```

You'll receive either `ACCEPTED: knight` or `REJECTED: knight` with validation
errors in your inbox.

### Example: Subscribe to Character Mail

```
to: wow.ritzmenardi.com/mail
subject: subscribe

Thrall
```

The body contains the character name to subscribe to. All mail sent to that
character will be forwarded to your rmail inbox.

### Example: Subscribe to Narrator

```
to: wow.ritzmenardi.com/narrator
subject: subscribe

McGee
```

Subscribe to a narrator NPC by name. Everything they say within 30 yards of
any player will be forwarded to your inbox, optionally with TTS audio.


## Running rmail

### Start the Daemon

```bash
cd ~/mail
lua /path/to/r-mail/rmail.lua .
```

Or if you installed to the default location:

```bash
rmail ~/mail
```

rmail runs continuously, syncing messages with your contacts.

### Background Mode

```bash
rmail ~/mail &
```

### Check for New Messages

Messages appear in `~/mail/inbox/` as text files. Read them with any text
editor or use `ls -lt ~/mail/inbox/ | head` to see recent arrivals.


## Security Model

### Encryption

All messages are encrypted with AES-256-GCM using the shared token as the key.
Without the token, messages are unreadable gibberish.

### What the Server Sees

The game server can read messages you send to it (it has the token). It cannot:
- Read messages you send to other contacts
- Access files on your computer
- Execute code on your machine

rmail is a messaging protocol, not remote access.

### What You Control

- **Your outbox**: Delete a file to unsend/revoke
- **Your contacts**: Only contacts in your file can message you
- **Your tokens**: Change a token to revoke someone's access

### Account Lifecycle

For account creation specifically: your game account exists as long as your
rmail message exists. Delete the message from your outbox and the account
(with all characters) is deleted from the server.

This gives you complete control over your data.


## Troubleshooting

### "Connection refused"

- Check port number matches the service
- Verify server is running
- Check firewall allows outbound connections

### "Decryption failed"

- Token mismatch between you and server
- Verify token is identical on both sides
- Tokens are case-sensitive

### Message Not Arriving

- Check rmail daemon is running
- Verify contact entry is correct
- Look for errors in rmail logs

### "Unknown contact"

- Contact name in `to:` must exactly match your contacts file
- Check for typos in the contact name


## Services Reference

### Account Creation (Port 4562)

**Contact:** `wow.ritzmenardi.com/accounts`

**Message format:**
```
to: wow.ritzmenardi.com/accounts

username
password
```

**Response:** Confirmation or error message

**Lifecycle:** Account exists while message exists. Delete message = delete account.

**Rules:**
- Username: max 20 characters, any characters, case-insensitive
- Password: any length, any characters

---

### Custom Classes (Port 4662)

**Contact:** `wow.ritzmenardi.com/classes`

**Message format:**
```
to: wow.ritzmenardi.com/classes
subject: CLASS: classname

-- Lua class definition
classname = {}
classname.name = "Display Name"
-- ...
```

**Response:** `ACCEPTED: classname` or `REJECTED: classname` with errors

**Lifecycle:** Class available while message exists. Characters using your class
keep their snapshot even if you delete the message.

See `issues/709-custom-class-lua-format` for full specification.

---

### In-Game Mail (Port 4762)

**Contact:** `wow.ritzmenardi.com/mail`

**Subscribe:**
```
to: wow.ritzmenardi.com/mail
subject: subscribe

CharacterName
```

**Unsubscribe:**
```
to: wow.ritzmenardi.com/mail
subject: unsubscribe

CharacterName
```

**Send mail to character:**
```
to: wow.ritzmenardi.com/mail
subject: Mail Subject Here

CharacterName

Mail body text here.
```

**Notes:**
- Subscriptions are public - anyone can subscribe to any character
- Item attachments become PNG icon images
- Outbound mail is text-only (no items/gold)

See `issues/1004-rmail-ingame-bridge` for details.

---

### Narrator Feed (Port 4862)

**Contact:** `wow.ritzmenardi.com/narrator`

**Subscribe:**
```
to: wow.ritzmenardi.com/narrator
subject: subscribe

NarratorName
```

**Options:**
```
to: wow.ritzmenardi.com/narrator
subject: subscribe tts

NarratorName
```

Add `tts` to subject for audio files.

**Notes:**
- Receives everything narrator says within 30 yards of any player
- TTS option generates mp3 with narrator's speaking rhythm
- Multiple narrators can be subscribed separately

See `issues/910-wandering-narrator-system` for details.

---

### Feedback (Port 4962)

**Contact:** `wow.ritzmenardi.com/feedback`

**Message format:**
```
to: wow.ritzmenardi.com/feedback

Your message here. Bug reports, suggestions, questions, complaints,
compliments, poetry - whatever you want to share.
```

**Response:** None guaranteed. Messages go to a queue and get read eventually.

**Notes:**
- No specific format required - just write what's on your mind
- Include your character name if it's about an in-game issue
- Responses come when they come


## Related Documents

- `docs/connection-guide.md` - Basic connection setup
- `issues/1003-rmail-account-creation` - Account system details
- `issues/709-custom-class-lua-format` - Class definition specification
- `issues/1004-rmail-ingame-bridge` - Mail bridge implementation
- `issues/910-wandering-narrator-system` - Narrator subscription

---

*Last updated: 2026-04*
