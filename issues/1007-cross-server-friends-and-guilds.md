# 1007 - Friends and Guilds Across Every Server (and Later, Every Game)

## Status
- Created: 2026-09-25
- Phase: 10 (communication beyond the game: rmail and its neighbours)
- Related: 1001–1006 (rmail, the project's out-of-game messaging), 617l
  (clan guilds, which take a character's one in-game guild slot), 913f
  (another session's cross-node social relay, inside one clustered
  realm), 157 (the three-machine deployment)
- Priority: Low (an idea; "When I have more games built")

## Origin

Verbatim, 2026-09-25, while deciding that clan guilds take no other
players:

> In-game player guilds should exist though. They're useful abstractions!
> I think battle.net has guilds, it certainly has friends. Maybe...
> Maybe there's space for a similar, meta communication platform that
> lets users talk across all of our servers? When I have more games built,
> then maybe across all of our games... What can I say, Blizzard inspires
> me.

## Current Behavior

Nothing is built or designed. Each realm (release, beta, vanilla, basic,
alpha) has its own characters, friends lists and guilds, and they can't
see one another. rmail (1001–1006) carries messages between a player's
own machine and a server, not between players on different servers.

## Intended Behavior

A communication layer above the servers, in the spirit of Blizzard's
battle.net: a player's friends and guilds follow the *person* (the
account), not one character on one realm, so people can talk across all
of the project's servers, and later across other games Ritz builds.

To be designed with Ritz. Starting points:

- **Friends** at the account level: see which of your friends are online
  on any server, and message them.
- **Guilds above the realm**: a group of people that exists whatever
  server or game each member is playing.
- **No required addons** (roadmap, Project-wide decisions): inside the
  3.3.5 client this can only show up through what the client already has
  (whispers, chat channels, mail), until the custom client exists.

## Suggested Implementation Steps

1. Design with Ritz, one question at a time.
2. Then split into sub-steps here.

## Open Questions

- What is an identity here: the game account, an rmail address (1001), or
  something new that several accounts and games link to?
- Where does it run: its own service beside the auth server, or on
  rmail's server?
- How does it reach a player inside the 3.3.5 client with no addon: a
  custom chat channel relayed by the server, whispers from a named
  character, in-game mail?
- Does it carry only text, or presence too (who is online, where)?
