# 617b2 - Whisper Sargobras

## Status
- Created: 2026-10-14
- Phase: 6
- Parent: 617b (Sargobras)
- Blocks: 620c (bots ask Sargobras by whispering him)
- Related: 617t1 (the stand-in account, a bot account with no owner),
  617a5 (companion accounts hidden from /who, B044), 617y (spoken
  orders, the other chat-driven buddy feature), 617l (the clan's name)
- Priority: Medium

## Origin

The owner, 2026-10-14:

> let's add whisper shortcuts to Sargobras, making him a stand-in or buddy
> account that can be whispered. He should also have a dialogue option -
> the buddy-bot character is invisible, and they always have the same
> location. Any Sargobras will answer so there's exactly one Sargobras that
> you can whisper. But, all of them, specific in that moment, would
> respond. So, the bots, upon logging in or acquiring a Sargobras event,
> will wait ~15-30 seconds while they talk to Sargobras, and then they will
> automatically send a whisper to him and he'll execute the action. The
> player can also whisper Sargobras if they use specific chat commands.
> /whisper Sargobras priest creates a holy priest named felicity for the
> player to adventure with.

## Current Behavior

Not built. Sargobras exists only as creatures (the valley one, 6170001;
the wandering one, 6170002 and 6170003 with his hat), driven by dialogue
menus in `patches/E066-sargobras/sargobras.lua`. A whisper can only be sent to a
logged-in character, so today "/whisper Sargobras" answers "No player
named 'Sargobras' is currently playing." Choosing a buddy means walking up
to one of the creatures and clicking a dialogue line.

Facts that shape the design:

- **Cross-faction whispers are refused** on basic:
  `AllowTwoSide.Interaction.Chat = 0` in `worldserver.conf`. One
  whisperable character belongs to one faction, so the other faction
  could not reach him.
- `sargobras.lua` already listens to player chat (event 18); ALE also has
  a whisper event that names the receiver.
- The buddy module already logs in bot characters on hidden accounts
  (companion accounts, 617a2) and on the stand-in account (617t1, "no
  owner, no placement"), and B044 hides companion accounts from /who and
  add-friend.

## Intended Behavior

**One Sargobras to whisper.** A character named Sargobras, logged in as a
bot on the stand-in account (or an account of his own; see open
questions) whenever the world server runs. He is invisible and never
moves: he stands at one fixed spot out of the way, takes no bot commands,
fights nothing, and is hidden from /who and add-friend as buddies are.
He exists only to receive whispers.

**Every Sargobras near you answers.** A whisper to him is handled as if
said to all the Sargobras creatures present for the whisperer at that
moment (the valley one beside them, their wandering one): each of them
speaks the answer aloud in /say, as he does when a dialogue line is
clicked, and the action is done once. With no Sargobras creature near,
the invisible one answers by whisper.

**The commands** (the same choices the dialogue offers, in words):

| Whisper | Does |
|---|---|
| `priest` (any class name) | chooses a buddy of that class for the lowest owed slot, by the same rules the dialogue line uses (`lib/buddy-choice.lua`); the spec comes from the class's default spec profile (a priest: Holy) |
| `shadow priest` (spec, then class) | the same, with that spec profile |
| `troll` (any race name) | chooses by race, as the race dialogue lines do |
| `priest Felicity` (a name after it) | the same, and the buddy is given that name if it is free |
| `help` | lists the commands |
| `owed` | says how many buddies the whisperer is owed |

A whisperer owed nothing gets his usual "nothing owed" answer. A
whisper he does not understand gets a joke and the help line.

**In the friends list, by choice only.** The owner, 2026-10-20 (while
designing the legendary friends, 920):

> Sargobras is also an option that never is included with new
> character's friends list. But players can add him, and he'll always be
> offline unless he's currently spawned for a player. If players send him
> any message at all (while he's online of course) it'll open his dialogue
> menu. Even though they're potentially very far away. This is to prevent
> him getting lost on zeppelins causing a problem.

- He is never among 920's two random legends; a player adds him by name
  (`/friend Sargobras`), and B044's add-friend hiding must let his name
  through.
- **Online only while a Sargobras is spawned for that player.** The
  whisperable character is in the world all the time (whispers need it),
  but what each player's friends list shows is sent to that player alone:
  the server's friend-status message (the one it sends when a friend logs
  in or out) is sent per player, "online" while that player has a wandering
  or valley Sargobras present for them, "offline" otherwise. A whisper
  from a player for whom he is "offline" is answered with the client's
  usual "No player named 'Sargobras' is currently playing."
- **Any message opens his dialogue, from any distance.** While he is
  online for a player, any whisper (not only the commands above) opens his
  dialogue menu on that player's screen, built as a menu the player
  object itself sends (ALE's player-sent menus are not refused for
  distance, as a creature's would be), with the same lines as the creature
  beside them. The commands above still work as shortcuts. A Sargobras
  left behind when his owner rode a zeppelin is still reachable this way.
- **Not now:** a way for a separated wandering Sargobras to catch up by
  walking the path his owner took (nearest point on the owner's recorded
  route, then along it), instead of appearing beside them, possibly inside
  the zeppelin. Proposed and set aside by the owner the same day ("actually
  nvm let's skip that for now"); it would suit `docs/roaming-pattern.md` as
  a pattern for other projects when it comes back.

**A dialogue option.** Each Sargobras creature gets one more line,
"Can I call on you from afar?", whose answer explains the whispers.

**Bots use the same door (620c).** A bot owner, at login or when a
Sargobras is summoned for it, walks to the nearest Sargobras, faces him and
"talks" (the talking gesture) for 15 to 30 seconds, then whispers him
its choice; he answers aloud and the buddy is made. One path for humans
and bots: the whisper.

## Suggested Implementation Steps

1. **The character:** make Sargobras on the chosen account at install (an
   E-patch, like the stand-ins' rows, E056); log him in with the buddy
   module at server start, place him at the fixed spot, make him
   invisible to everyone (a permanent invisibility aura or the
   per-player unselectable rule, 164) and inert (no bot strategies).
2. **Cross-faction:** let a whisper whose receiver is Sargobras through
   the faction check while leaving `AllowTwoSide.Interaction.Chat` off
   for everyone else (a small B-patch at the whisper's faction test), or
   two characters, one per faction (see open questions).
3. **The commands:** in `sargobras.lua`, a whisper handler that splits the
   message into words and looks them up in dispatch tables (classes,
   specs, races, keywords), then calls the same choose function the
   dialogue uses. Every Sargobras creature near the whisperer says the
   answer.
4. **Names:** the requested name checked with the server's own name rules
   and against existing characters; taken or invalid names get a joke and
   a random name instead (see open questions).
5. **Tests:** an offline test of the word parsing beside
   `scripts/test-buddy-choice`; in game, `/w Sargobras shadow priest
   Felicity` from each faction, near a wanderer and far from any.
6. Update 617b's Current Behavior.

## Open Questions

- **Which account:** the stand-in account (already a bot account with no
  owner), or a new account of his own?
- **Both factions:** one Sargobras with a patched faction check, or two
  characters (Alliance and Horde) both named so whispers find the right
  one? Names are unique on a realm, so two would need different names.
- **"All of them respond"**: is it every Sargobras near the whisperer
  (as written above), or every Sargobras creature in the world?
- **A name that is taken:** a random name instead, or refuse and ask
  again?
- **Default spec:** "priest" alone gives a holy priest in your example.
  Is that the class's first spec always, or the role the whisperer's group
  lacks most?
