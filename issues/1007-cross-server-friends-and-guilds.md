# 1007 - Friends and Guilds Across Every Server (and Later, Every Game)

## Status
- Created: 2026-09-25
- Phase: 10 (communication beyond the game: rmail and its neighbours)
- Related: rao-chat (`/mnt/mtwo/programs/rao-chat`, the model for
  guilds and friends here), 1001–1006 (rmail, the project's out-of-game messaging), 617l
  (clan guilds, which take a character's one in-game guild slot), 913f
  (another session's cross-node social relay, inside one clustered
  realm), 157 (the three-machine deployment)
- Priority: Low (parked: "We can put a pin in the rao-chat integration
  because it's still in development", 2026-09-25)

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

### rao-chat as the model (Ritz, 2026-09-25)

Pointed to while settling clan guilds (617l): "I said I wanted player
guilds to exist, I didn't intend to imply that they should be ordinary.
Check out rao-chat." rao-chat (`/mnt/mtwo/programs/rao-chat`, its
`notes/vision-planning.md`) is Ritz's chat with no central server: each
person runs a home server; a room is a label (the reader's own name for
it), a shared token and the (address, port) pairs of its members; holding
the token is being invited, and the token seals every message; rooms nest
in a tree where each child room has its own invitation and a member not in
the rooms above is flagged ("tiers of trust ... it encourages task focus to
specialize, rather than power to hierarchicalize"); you choose who hears
you (withholding), never who hears anyone else; a direct message is a room
with one other person.

Read onto the game (confirmed, Ritz 2026-09-25: "Yep that looks right"): a player guild is a rao-chat
room, a sub-guild a child room, a friend a direct-message room; a game
server takes part as a home server for its players, so the same guild
reaches every server, the rao-chat phone and web clients, and later other
games.

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
- The stock client's custom chat channels already have a name and an
  optional password (`/join name password`; the server answers "Wrong
  password for …"), close to rao-chat's label and token. Two differences:
  a channel's name is the same for everyone on the server (rao-chat's
  labels are each reader's own), and a channel has an owner and moderators
  (rao-chat has no one above anyone). Does a guild room show in game as a
  password channel (the server relaying it to the room's other home
  servers), accepting those two differences inside the game?
