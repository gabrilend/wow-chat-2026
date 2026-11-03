# 1008f - How to Connect and Read Your Journal

## Status
- Created: 2026-10-26
- Parent: Issue 1008 (journals-of-what-each-player-saw)
- Phase: 10
- **Blocked by:** 157g, 157k, 1008d, 1008e

## Overview

The owner, 2026-10-26: "I want to put the connection details on my
website. ... We show them exactly how to do this in the same section
where we tell them how to connect. They will have seen it if they can
log in."

One section of the owner's website tells a player everything: how to
point their client at the server, which realms there are, how to get an
account, that what they see in game is written into their own locked
journal (and what they say, into the journals of those who see it), and
how to fetch and open theirs. Anyone who managed to log in followed
this section, so every player has read where their journal is.

The owner, 2026-10-26, on the page's shape:

> for the connection page, can we create a scrollable listing that lists
> all our profiles? It should be frutiger aero themed, similar to
> /home/ritz/documents/ai-stuff/ - anyway for each profile it should
> expand and list details and changes, only the important ones. Each
> entry points to the same connection details, but in this way users can
> see each of them detailed.

## Current Behavior

`scripts/write-connection-page` is built and writes the page into
`tmp/shared-memory/connection-page/index.html`:

- Six realms, in realm-id order, in a scrolling glass panel; each opens
  to show its summary, "What is here" and "Left out on purpose", taken
  from the profile page's own "What you get" and "What you do NOT get"
  lists. A point's lead is its bold opening (the authors' own mark of
  importance) or its first sentence; the rest opens beneath it. Each
  realm ends with a button to the one "How to connect" section.
- The look is the Aero style of the hall-of-president-spirits project
  (`src/020-page-styles.lua` there): sky-to-grass gradient, frosted
  glass panels, aqua gel buttons, floating bubbles (still when the
  reader asks for reduced motion).
- Internal references are taken out of the realms' text (issue numbers,
  setup step names, file paths); any that remain are printed as warnings
  so the source page can be mended. One remains today: beta's page names
  its setup step in a sentence of its own.
- No addresses or ports for realms (157k). The login machine's name is
  required (`--address`); without a chosen name, `--preview` writes the
  page with a banner saying it cannot be used yet, and without either the
  tool stops with an error.
- `--screenshot [REALM]` photographs the page (wide and phone width) with
  a headless Firefox and files the pictures in `development-history/`
  under the next number, with notes.

- **Side by side** (the owner, 2026-10-27: "a comparison table or
  something? only for the major features that are shared. We can have a
  record that says "and many more features!" with every profile selected
  except alpha"): realms as columns, major shared features as rows
  (levels, the empty world with ambushes, AI playerbots, no flight paths,
  slower movement and heavier falls, death knights), and the owner's last
  row. Every filled cell quotes the words in that realm's page that prove
  it; the tool stops with an error if a quote is no longer there. The rows
  are the `COMPARISON` table at the top of the script.
- The realm list grows with the page: opening a realm scrolls the whole
  page (the owner, 2026-10-27), not a box inside it.

Not built: the account section, with the guest accounts and a way to make
your own (below; waits on 1003), and the journal section (waits on
1008b-e); serving the page from the login machine (157k).

The owner, 2026-10-27, on who sees what: "anyone can see the connection
details but we need a way to make an account for them. Also we should tell
them about the guest accounts on the login page." So the page is public
(the login machine's name on it is no secret), and it gains:

- **Guest accounts**: the public names and passwords (1003's pathway 1),
  generated from the same source that creates them (1003's SQL), with a
  line saying what a guest account is: shared, no journal, "can be kicked
  off whenever".
- **Your own account**: how to make one (question 3).

## Intended Behavior

The section is generated, not typed: `scripts/write-connection-page`
writes it from

- 157g's connection details (address, authserver port, each realm's
  name, kind and port, from the roles file and C010);
- the realms' current status (online, players), read from
  `acore_auth.realmlist` on the host when the page is regenerated;
- 1008d's rmail address and format, 1008e's opener page.

It contains, in this order:

1. The `set realmlist <login machine's name>` line for `realmlist.wtf`,
   with where that file is in a 3.3.5a client.
2. The realms, by name and kind only: no addresses, no ports (157k).
3. Getting an account (1003's rmail way, and the guest accounts).
4. **Your journal**: what is written (the kinds, from 1008b), that only
   your password opens it, that the server cannot read it, how to ask
   for it by rmail, and the link to the opener page.

The page is regenerated after every ship (157h), so a new realm or port
appears without anyone editing the website.

## Suggested Implementation Steps

1. Answer where the website lives and how it is published (question 1).
2. `scripts/write-connection-page`, with a first line saying what made
   the page.
3. A test that every port and address on the page matches C010 and the
   roles file.

## Open Questions

1. ~~Where the page itself is served~~. Answered 2026-10-26: the
   Neocities site carries a fixed link; the page is served by "the same
   server that has the authorization page", the login machine (157k).
   It names only the login machine: realm addresses and ports are never
   on it, "so they don't learn the backend IP's and ports and such until
   they're ready to be let in."
2. ~~The style~~. Answered 2026-10-26: Frutiger Aero, like the
   hall-of-president-spirits pages; built.
3. ~~How a player makes their own account~~. Answered 2026-10-28:
   "ideally, the form would create an rmail message and send it to my
   "create account" task mailbox... or similar... But the HTML rmail
   functionality is still in progress." So the page's form writes an
   rmail message (1003's format: name, then password) to the account
   mailbox, and 1003's account creation does the rest; one path, rmail,
   whichever way the message was written. Waits on rmail from a web page,
   which is being built in the rmail project.

## Related
- `issues/157g-linode-machines-one-per-realm.md`
- `issues/1008d-asking-for-your-journal-by-rmail.md`,
  `issues/1008e-opening-a-journal-at-home.md`
- `issues/1003-rmail-account-creation.md`
