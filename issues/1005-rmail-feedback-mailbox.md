# 1005 - rmail Feedback Mailbox

Simple feedback collection via rmail. No automation, no hooks - just a mailbox
that collects messages for manual review.

## Current Behavior

No feedback channel exists. Players must use Discord or other external platforms
to communicate with the server operator.

## Intended Behavior

Players send messages to `wow.ritzmenardi.com/feedback` and they land in an inbox
for manual review. No automated processing, no guaranteed response time.

### Message Format

No specific format required:

```
to: wow.ritzmenardi.com/feedback

Whatever the player wants to say.
```

### What Players Might Send

- Bug reports
- Suggestions
- Questions
- Complaints
- Compliments
- Poetry
- Screenshots (as attachments)
- Anything else

### Response Model

- No automated responses
- Manual replies when time permits
- Some messages may never get responses (and that's okay)

## rmail Configuration

**Service Address:** `wow.ritzmenardi.com/feedback`

**Port:** `4962`

**Server-Side Contact Entry:**

```
// game-mail/contacts (feedback mailbox)
// Players add their own contact entry pointing here
// Token is public - anyone can send feedback
```

**Public Token:** Use a publicly shared token so anyone can send feedback
without requiring individual token exchange.

## Hook Architecture

### No Hooks Required

Unlike other services, feedback requires no `on_receive` hooks:

1. Message arrives in `game-mail/feedback/inbox/`
2. Operator reads messages manually
3. Operator replies manually (or doesn't)

### Optional: Notification Hook

If desired, a simple notification hook:

```lua
#!/usr/bin/env lua
-- {{{ feedback-notify.lua
-- on_receive hook - just logs that feedback arrived
-- No processing, no response generation

local sender   = arg[1]
local subject  = arg[2]
local filepath = arg[3]

-- Log to file
local log = io.open("/tmp/feedback-received.log", "a")
if log then
    log:write(os.date("%Y-%m-%d %H:%M:%S"))
    log:write(" Feedback from: " .. (sender or "unknown"))
    log:write(" Subject: " .. (subject or "(none)"))
    log:write("\n")
    log:close()
end

-- Optional: desktop notification
-- os.execute('notify-send "Feedback received" "' .. sender .. '"')
-- }}}
```

### Directory Structure

```
game-mail/
├── accounts/           # Port 4562 - account creation
│   ├── inbox/
│   ├── outbox/
│   └── config          # on_receive = validate-account.lua
│
├── classes/            # Port 4662 - custom class submission
│   ├── inbox/
│   ├── outbox/
│   └── config          # on_receive = validate-class.lua
│
├── mail/               # Port 4762 - in-game mail bridge
│   ├── inbox/
│   ├── outbox/
│   └── config          # on_receive = mail-bridge.lua
│
├── narrator/           # Port 4862 - narrator subscription
│   ├── inbox/
│   ├── outbox/
│   └── config          # on_receive = narrator-subscribe.lua
│
└── feedback/           # Port 4962 - feedback collection
    ├── inbox/          # Messages accumulate here
    ├── outbox/         # Manual replies go here
    └── config          # on_receive = feedback-notify.lua (optional)
```

## Suggested Implementation Steps

1. **Create feedback mailbox directory**
   ```bash
   mkdir -p game-mail/feedback/{inbox,outbox}
   ```

2. **Create minimal config**
   ```
   # game-mail/feedback/config
   name = feedback
   port = 4962

   # Optional notification
   # on_receive = /path/to/feedback-notify.lua
   ```

3. **Generate public token**
   ```bash
   openssl rand -hex 32 > game-mail/feedback/public-token.txt
   ```

4. **Add to contacts**
   ```
   # game-mail/feedback/contacts
   # Empty or contains contacts for replying
   ```

5. **Document the public token**
   - Add to website/Discord
   - Include in `docs/rmail-integration.md`

6. **Start the mailbox daemon**
   ```bash
   rmail game-mail/feedback
   ```

## Reading Feedback

### Manual Review

```bash
# List recent feedback
ls -lt game-mail/feedback/inbox/ | head -20

# Read a message
cat game-mail/feedback/inbox/<filename>

# Search for keyword
grep -l "bug" game-mail/feedback/inbox/*
```

### Replying

Create a file in `game-mail/feedback/outbox/`:

```
to: sender-contact-name
subject: Re: their subject

Your reply here.
```

The sender must have you in their contacts to receive the reply.

## Security Considerations

- Public token means anyone can send messages
- No way to verify sender identity (beyond rmail contact name)
- Could receive spam if token is widely shared
- Mitigation: change token periodically if abused

## Related Documents

- `docs/rmail-integration.md` - Player setup instructions
- `issues/313-rmail-dns-style-addresses` - Address format

## Related Issues

- Issue 317: Account creation (similar simple mailbox)
- Issue 313: DNS-style addresses (port allocation)

## Stats

- **Phase:** 3
- **Priority:** Low (quality of life)
- **Complexity:** Very Low (no automation)
- **Dependencies:** rmail installation
