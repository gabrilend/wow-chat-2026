# 1001 - rmail DNS-Style Address Support

Allow rmail contact names to use DNS-style addresses like `wow.ritzmenardi.com/accounts`
for improved readability and organization of multiple services on the same server.

## Current Behavior

rmail contacts use simple names:

```
// ~/mail/contacts
ghostsong.ip    = 192.168.1.100
ghostsong.port  = 8025
ghostsong.token = "abc123"
```

Messages are addressed with:

```
to: ghostsong
```

When a server hosts multiple services (accounts, classes, mail, narrator), users
must create separate contact entries with arbitrary names:

```
ghostsong-accounts.ip    = 192.168.1.100
ghostsong-accounts.port  = 4562
ghostsong-classes.ip     = 192.168.1.100
ghostsong-classes.port   = 4662
```

## Intended Behavior

Support DNS-style contact names that include hostname and path:

```
// ~/mail/contacts
wow.ritzmenardi.com/accounts.ip    = wow.ritzmenardi.com
wow.ritzmenardi.com/accounts.port  = 4562
wow.ritzmenardi.com/accounts.token = "public-token"

wow.ritzmenardi.com/classes.ip    = wow.ritzmenardi.com
wow.ritzmenardi.com/classes.port  = 4662
wow.ritzmenardi.com/classes.token = "author-token"
```

Messages addressed with:

```
to: wow.ritzmenardi.com/accounts
```

### Benefits

1. **Self-documenting** - Address includes server and purpose
2. **Organized** - Related services grouped by hostname
3. **Discoverable** - Users can guess service addresses
4. **Portable** - Same format works across servers

### Address Format

```
hostname/service
```

- `hostname` - DNS name or descriptive identifier
- `/` - Separator (literal forward slash)
- `service` - Service name (accounts, classes, mail, narrator, etc.)

The `.ip` field can be:
- Same as hostname (if DNS resolves)
- Different hostname (if using CNAME or alias)
- IP address (if no DNS)

### Contact File Parsing

Contact names can contain:
- Alphanumeric characters
- Dots (.)
- Forward slashes (/)
- Hyphens (-)

The parser should extract the full name before `.ip`, `.port`, or `.token`:

```
// Current parsing (stops at first dot)
ghostsong.ip = ...

// New parsing (handles compound names)
wow.ritzmenardi.com/accounts.ip = ...
```

### Port Assignments

Everland Ghostsong port allocation:

| Service | Port | Address |
|---------|------|---------|
| Account Creation | 4562 | `wow.ritzmenardi.com/accounts` |
| Custom Classes | 4662 | `wow.ritzmenardi.com/classes` |
| In-Game Mail | 4762 | `wow.ritzmenardi.com/mail` |
| Narrator Feed | 4862 | `wow.ritzmenardi.com/narrator` |
| Feedback | 4962 | `wow.ritzmenardi.com/feedback` |

Pattern: 4x62 where x increments per service.

## Suggested Implementation Steps

### Phase A: Parser Update

1. Update contacts file parser to handle compound names
   - Current: split on first `.` to get contact name
   - New: split on `.ip`, `.port`, `.token` suffixes
   - Contact name is everything before the suffix

2. Update contact lookup to match full compound names
   - `getContact("wow.ritzmenardi.com/accounts")` returns the contact
   - Partial matches should not work (security)

3. Test with existing simple names (backwards compatible)
   - `ghostsong.ip = ...` still works
   - `ghostsong` still resolves

### Phase B: Message Routing

4. Update message parser to handle compound `to:` addresses
   - `to: wow.ritzmenardi.com/accounts` extracts full contact name
   - Whitespace trimming still applies

5. Validate contact exists before queueing message
   - Clear error: "Unknown contact: wow.ritzmenardi.com/accounts"

### Phase C: Documentation

6. Update rmail documentation with new format
7. Provide example contacts files
8. Document port allocation pattern

## Backwards Compatibility

- Simple contact names (`ghostsong`) continue to work
- No changes to message format beyond contact name
- No changes to encryption or sync protocol
- Existing contacts files remain valid

## Security Considerations

- Contact name is not transmitted in cleartext
- Port number determines routing, not the path component
- Each service has its own token (can't access /classes with /accounts token)

## Related Documents

- `docs/rmail-integration.md` - Server integration guide
- `/home/ritz/programs/r-mail/README.md` - rmail documentation
- `/home/ritz/programs/r-mail/docs/contacts.md` - Contact file format

## Related Issues

- Issue 317: rmail account creation (uses port 4562)
- Issue 163: Custom class submission (uses port 4662)
- Issue 306: In-game mail bridge (uses port 4762)
- Issue 310: Narrator subscription (uses port 4862)

## Stats

- **Phase:** 3
- **Priority:** Medium (quality of life, organization)
- **Complexity:** Low (parser changes only)
- **Dependencies:** None (backwards compatible)
