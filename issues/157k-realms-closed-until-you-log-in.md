# 157k - Realms Closed Until You Log In

## Status
- Created: 2026-10-26
- Parent: Issue 157 (three-machine-deployment)
- Phase: 1
- **Blocked by:** 157g, 157i
- **Blocks:** 1008f

## Origin

The owner, 2026-10-26:

> We should host the connection page from the same server that has the
> authirzation page. We should only tell them the connection details once
> we've made a successful connection, so they don't learn the backend IP's
> and ports and such until they're ready to be let in.
>
> DDOS PROTECTION.

## Overview

Only one address is public: the login machine's. Everything behind it
(each realm machine's address and port, the login database's device) is
never published, never shown on a page, and closed to anyone who has not
just logged in. A flood aimed at the game can reach only the login
machine; the realms keep running for those already playing.

## Current Behavior

- In the game's own protocol, the client learns each realm's address
  and port from the realm list, and the authserver sends the realm list
  only after a successful login (the password proof, SRP6). So the
  addresses already reach only people who logged in; but anyone who
  learns one (a player passing it on) can send traffic at it.
- Today every realm's port is open to the whole internet (forwarded at
  the home router).

## Intended Behavior

### Public: the login machine only

The login machine runs the authserver and serves one small page: how to
point a client at it (`set realmlist <login machine's name>`), how to get
an account, and the journal section (1008f). The Neocities site has a
fixed link to this page. Nothing on the page names a realm machine.

The login machine limits each address: so many login attempts per
minute, so many open connections; an address over the limit is dropped
by the firewall for a while. This is the one machine a flood can reach,
so it carries nothing else.

### Behind: realms open only to those let in

Each realm machine's firewall drops everything to its game port except
addresses on its "let in" list. The list is a kernel firewall set whose
entries expire by themselves (nftables sets with timeouts).

1. A player logs in at the login machine (the password proof succeeds).
2. The authserver sends each realm machine a "let in <address> for 10
   minutes" instruction (157j's format, over Linode's private network).
3. The realm machine adds the address to its set.
4. The client, given the realm list, connects to the realm; the
   connection, once open, stays open regardless of the entry's timer.
5. The entry expires; a new login adds it again.

An address that never logged in cannot reach a realm at all, so knowing a
realm's address is no use to a flood.

## Suggested Implementation Steps

1. Firewall rules per machine role, as files in
   `config/machine-images/firewall/<role>.nft`, carried in the image.
2. B-patch in the authserver: after a successful login, send "let in"
   to every realm machine in its list.
3. On each realm machine: a small listener (private network only) that
   accepts "let in" from the login machine's address only, and adds the
   set entry.
4. The login machine's page server: the smallest static file server
   that will do, a part of its own (157i1).
5. Test in QEMU: an address that did not log in gets no answer from the
   realm port; after a login it connects; after the timer, a new
   connection is refused again while the open one keeps playing.

## Open Questions

1. ~~"The authorization page."~~ Answered 2026-10-27: "anyone can see
   the connection details but we need a way to make an account for them.
   Also we should tell them about the guest accounts on the login page."
   The page is public, served by the login machine; account making is
   1008f's question 3.
2. **How long a "let in" lasts.** 10 minutes is the proposal: long
   enough to choose a realm and a character.

## Related
- `issues/157g-linode-machines-one-per-realm.md`
- `issues/157j-the-login-database-behind-an-instruction-door.md`: the
  instruction format the "let in" uses
- `issues/1008f-how-to-connect-and-read-your-journal.md`: the page
- `issues/158-player-machine-safety-before-public-release.md`
