# 1008d - Asking for Your Journal by rmail

## Status
- Created: 2026-10-26
- Parent: Issue 1008 (journals-of-what-each-player-saw)
- Phase: 10
- **Blocked by:** 1008b, 1001
- **Blocks:** 1008f

## Overview

The owner, 2026-10-26: "if the user creates an rmail request, they can
download it."

A player sends an rmail message to `wow.ritzmenardi.com/journal`; the
reply carries their locked journal files and the list of fingerprints.
The files are useless without the password, so the reply can be sent
without the server knowing who is asking.

## Current Behavior

Nothing answers at that address.

## Intended Behavior

The rmail address stays on the owner's computer (`wow.ritzmenardi.com`
stays there, owner 2026-10-26), while each realm's journals are on that
realm's machine (157g). The `/journal` service gathers the files from
every realm machine over ssh (the deploy tool's connection, 157b), read
only, then replies. The files are locked, so nothing readable crosses.

Message format (1003's style: one value per line, whitespace trimmed):

```
account name
from date (optional, YYYY-MM-DD)
to date (optional)
```

The reply: one archive (`<account>-journal-<from>-<to>.tar`) of every
journal file of that account in the range, from every realm and from
rmail (1008c), with a `fingerprints` file listing each file's BLAKE2b
hash, and a first line saying what made the archive, when, and how to
open it (1008e's page).

A request for an account that has no journal key gets a reply saying so
and how to start one (change the password in game).

## Suggested Implementation Steps

1. The rmail service at `/journal` (1001's addressing), in Lua.
2. Test: request, receive, open with 1008e's tool.

## Open Questions

1. ~~Who may ask~~. Answered 2026-10-28: "the person who is tied to the
   account should." Only the rmail contact tied to the account (1008c:
   the address that asked for it, changeable on the account page) is
   answered; a request from any other contact is refused and logged, and
   reveals nothing (not even whether the account exists).
2. ~~Size~~. Settled by rmail's own limits
   (`/home/ritz/programs/r-mail/docs/.templates/attachments.md`): an
   attachment is sent in 5 MB chunks, up to 4 GiB per file, and the
   recipient is asked before it is sent. A reply bigger than that is
   split by month.

## Related
- `issues/1001-rmail-dns-style-addresses.md`, `issues/1005-rmail-feedback-mailbox.md`
- `issues/1008e-opening-a-journal-at-home.md`
